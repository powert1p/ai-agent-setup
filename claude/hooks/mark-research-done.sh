#!/bin/bash
# PostToolUse hook: маркирует сессию как "ресерч сделан" после WebSearch/context7.

INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
touch "/tmp/claude-research-done-${SESSION}"
exit 0
