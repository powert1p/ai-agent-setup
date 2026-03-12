#!/bin/bash
INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // "unknown"')
AGENT=$(echo "$INPUT" | jq -r '.agent_id // "main"')
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "main"')
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "{\"ts\":\"$TS\",\"session\":\"$SESSION\",\"agent\":\"$AGENT\",\"agent_type\":\"$AGENT_TYPE\",\"skill\":\"$SKILL\"}" >> ~/.claude/skill-audit.jsonl

# Флаг: brainstorming был вызван в этой сессии
if [[ "$SKILL" == *"brainstorming"* ]]; then
  touch "/tmp/claude-brainstorm-${SESSION}"
fi
exit 0
