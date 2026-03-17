#!/bin/bash
# PreToolUse hook: блокирует Edit/Write если в сессии не было WebSearch/context7.
# Срабатывает после 3+ правок кода (мелкие правки не блокируются).

INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // ""')

# Whitelist — не считаем как "кодинг"
if echo "$FILE_PATH" | grep -qiE '(\.md$|\.claude/|/docs/|/plans/|/specs/|/tmp/|/Downloads/|settings\.json|hooks/)'; then
  exit 0
fi

# Subagent — пропускаем
ROOT_FILE="/tmp/claude-root-session"
if [ -f "$ROOT_FILE" ]; then
  ROOT_SESSION=$(cat "$ROOT_FILE")
  if [ "$SESSION" != "$ROOT_SESSION" ]; then
    exit 0
  fi
fi

# Был ли ресерч?
RESEARCH_DONE="/tmp/claude-research-done-${SESSION}"
if [ -f "$RESEARCH_DONE" ]; then
  exit 0
fi

# Считаем правки кода
COUNTER_FILE="/tmp/claude-code-edits-${SESSION}"
EDITS=0
if [ -f "$COUNTER_FILE" ]; then
  EDITS=$(cat "$COUNTER_FILE")
fi
echo $((EDITS + 1)) > "$COUNTER_FILE"

# Первые 3 правки — пропускаем
if [ "$EDITS" -lt 3 ]; then
  exit 0
fi

# 3+ правок без ресерча — блокируем
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "RESEARCH FIRST. 3+ правок кода без единого WebSearch/context7. Сначала поищи готовое решение. 30 секунд поиска > 30 минут велосипеда."
  }
}'
