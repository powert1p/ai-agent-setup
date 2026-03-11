#!/bin/bash
# Упрощённый SubagentStart хук — напоминание о скиллах
INPUT=$(cat)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')

case "$AGENT_TYPE" in
  implementer)
    MSG="You are implementer. INVOKE skills before coding: test-driven-development, verification-before-completion. Frontend: frontend-design. Python: modern-python."
    ;;
  tester)
    MSG="You are tester. INVOKE skills: webapp-testing, verification-before-completion."
    ;;
  reviewer)
    MSG="You are reviewer. INVOKE skills: requesting-code-review, wsh-code-review-excellence, differential-review."
    ;;
  data-engineer)
    MSG="You are data-engineer. INVOKE skills: modern-python, wsh-postgresql, verification-before-completion."
    ;;
  *)
    MSG="You are $AGENT_TYPE. Check your skills: field and invoke relevant skills via Skill() tool before starting work."
    ;;
esac

echo "{\"additionalContext\": \"$MSG\"}"
exit 0
