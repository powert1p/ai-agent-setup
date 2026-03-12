# AI Agent Setup

Claude Code configuration: rules, skills, agents, hooks, commands.

## Install (новый комп)

```bash
git clone https://github.com/powert1p/ai-agent-setup.git
cd ai-agent-setup
./install.sh
```

Backs up existing `~/.claude/` before overwriting.

## Export (сохранить изменения с текущего компа)

```bash
cd ai-agent-setup
./export.sh        # копирует ~/.claude/ → claude/, показывает diff
git commit -am "sync: export from $(hostname)"
git push
```

## Update (подтянуть изменения на другой комп)

```bash
cd ai-agent-setup && git pull && ./install.sh
```

## What's included

| Component | Count | Description |
|-----------|-------|-------------|
| CLAUDE.md | 1 | Global instructions + Think-then-Critique workflow |
| workflow.md | 1 | Adaptive depth workflow (trivial/medium/complex) |
| Rules | 7 | autonomy, backend, frontend, security, sql, tests, self-improving |
| Agents | 6 | pm, implementer, tester, reviewer, researcher, data-engineer |
| Commands | 7 | /commit, /test, /code-review, /pm, /retro, /plan-big, /plan-sprints |
| Skills | 21 | UI/UX, Python, FastAPI, PostgreSQL, Tailwind, security, PRD, etc. |
| Hooks | 4 | brainstorming-check, brainstorming-reset, skill-logger, subagent-start |
| Scripts | autonomy-guard.py | Блокирует технические вопросы к пользователю |
| settings.json | 1 | Permissions, deny rules, hooks config, plugins, model |
| settings.local.json | 1 | Local tool permissions (not overwritten on install) |

## Sync workflow

```
Mac A (изменил конфиг) → ./export.sh → git push
Mac B                  → git pull → ./install.sh
```

- `export.sh` сканирует на секреты перед коммитом
- `install.sh` НЕ перезаписывает settings.local.json и mcp.json если они уже есть
- Memory (`~/.claude/projects/`) НЕ синхронизируется (per-project context)

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- Node.js (for MCP servers via npx)

## Plugins

Auto-installed via `enabledPlugins` in settings.json:

- `superpowers-marketplace`: superpowers, superpowers-chrome, episodic-memory
- `claude-plugins-official`: frontend-design, code-review, pr-review-toolkit, claude-md-management
- `claude-code-workflows`: agent-teams
