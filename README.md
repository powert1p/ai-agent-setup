# AI Agent Setup

Claude Code configuration: rules, skills, agents, hooks, commands.

## Install

```bash
git clone https://github.com/powert1p/ai-agent-setup.git
cd ai-agent-setup
./install.sh
```

Backs up existing `~/.claude/` before overwriting.

## What's included

| Component | Count | Description |
|-----------|-------|-------------|
| CLAUDE.md | 1 | Global instructions |
| workflow.md | 1 | Adaptive depth workflow |
| Rules | 7 | autonomy, backend, frontend, security, sql, tests, self-improving |
| Agents | 5 | implementer, tester, reviewer, researcher, data-engineer |
| Commands | 7 | /commit, /test, /code-review, /pm, /retro, /plan-big, /plan-sprints |
| Skills | 21 | UI/UX, Python, FastAPI, PostgreSQL, Tailwind, security, PRD, etc. |
| Hooks | 2 | autonomy-guard, skill-logger |
| Scripts | 4 | autonomy-guard, bash-guard, source-guard, agent-init |
| MCP servers | 6 | sequential-thinking, context7, github, repomix, task-master, memory |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- Node.js (for MCP servers via npx)
- Environment variables:
  - `GITHUB_TOKEN` — for GitHub MCP server
  - `ANTHROPIC_API_KEY` — for task-master-ai

## Plugins (manual install)

From `superpowers-marketplace`: superpowers, superpowers-chrome, episodic-memory
From `claude-plugins-official`: frontend-design, code-review, pr-review-toolkit, claude-md-management
From `claude-code-workflows`: agent-teams

## Update

```bash
cd ai-agent-setup && git pull && ./install.sh
```

settings.json and mcp.json are NOT overwritten if they already exist.
