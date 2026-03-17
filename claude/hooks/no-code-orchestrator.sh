#!/bin/bash
# PreToolUse hook: блокирует Edit/Write для оркестратора (root session).
# Subagents имеют другой session_id — не блокируются.
# Bypass: ORCHESTRATOR_CAN_CODE=1

INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // ""')

# Логирование — всегда пишем чтобы понять срабатывает ли хук
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) PRE_TOOL_USE session=$SESSION tool=$TOOL path=$FILE_PATH" >> /tmp/claude-hook-debug.log

# Bypass через env
if [ "$ORCHESTRATOR_CAN_CODE" = "1" ]; then
  exit 0
fi

# Запоминаем root session (первая сессия = оркестратор)
ROOT_FILE="/tmp/claude-root-session"
if [ ! -f "$ROOT_FILE" ]; then
  echo "$SESSION" > "$ROOT_FILE"
fi
ROOT_SESSION=$(cat "$ROOT_FILE")

# Subagent — пропускаем
if [ "$SESSION" != "$ROOT_SESSION" ]; then
  exit 0
fi

# Whitelist путей (не код — разрешаем)
if echo "$FILE_PATH" | grep -qiE '(\.md$|\.claude/|/docs/|/plans/|/specs/|/tmp/|/Downloads/|settings\.json|hooks/|CLAUDE|workflow|PROJECT)'; then
  exit 0
fi

# Блокируем
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "ОРКЕСТРАТОР НЕ КОДИТ. Делегируй: Agent tool → implementer. Ты координатор — планируй, не пиши код."
  }
}'
