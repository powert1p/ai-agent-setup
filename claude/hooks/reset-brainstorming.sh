#!/bin/bash
# UserPromptSubmit: сброс флага brainstorming на каждое новое сообщение
INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Удаляем флаг — brainstorming должен быть вызван заново
rm -f "/tmp/claude-brainstorm-${SESSION}"
# Сбрасываем счётчик блоков
rm -f "/tmp/claude-brainstorm-blocks-${SESSION}"

echo '{"additionalContext": "ОБЯЗАТЕЛЬНО: invoke Skill(brainstorming) ПЕРВЫМ ДЕЙСТВИЕМ. Твой ПЕРВЫЙ tool call = Skill(brainstorming). НЕ пиши текст до вызова Skill."}'
