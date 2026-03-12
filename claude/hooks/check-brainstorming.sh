#!/bin/bash
# Stop hook: блокирует остановку если brainstorming не был вызван
INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Если brainstorming уже был вызван — пропускаем
if [ -f "/tmp/claude-brainstorm-${SESSION}" ]; then
  exit 0
fi

# Счётчик блоков — макс 3, потом пропускаем чтобы не зациклить
COUNTER_FILE="/tmp/claude-brainstorm-blocks-${SESSION}"
BLOCKS=0
if [ -f "$COUNTER_FILE" ]; then
  BLOCKS=$(cat "$COUNTER_FILE")
fi

if [ "$BLOCKS" -ge 3 ]; then
  # 3 блока не помогли — пропускаем
  exit 0
fi

# Инкремент счётчика
echo $((BLOCKS + 1)) > "$COUNTER_FILE"

# Блокируем
echo '{"decision":"block","reason":"БЛОК: Brainstorming НЕ вызван. Твой СЛЕДУЮЩИЙ tool call ОБЯЗАН быть Skill(brainstorming). НЕ пиши текст — сразу вызови Skill tool. Это НЕ рекомендация, это программный блок."}'
