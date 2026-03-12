#!/bin/bash
# Stop hook: блокирует остановку если brainstorming не был вызван
INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Если brainstorming уже был вызван — пропускаем
if [ -f "/tmp/claude-brainstorm-${SESSION}" ]; then
  exit 0
fi

# Если уже блокировали один раз (stop_hook_active=true) — пропускаем чтобы не зациклить
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

# Блокируем: brainstorming не был вызван
echo '{"decision":"block","reason":"СТОП. Brainstorming НЕ был вызван. ОБЯЗАТЕЛЬНО: invoke Skill(brainstorming) СЕЙЧАС. Это программный блок, не рекомендация."}'
