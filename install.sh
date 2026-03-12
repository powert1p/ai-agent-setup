#!/bin/bash
# Установка конфигурации Claude Code
# Запуск: git clone https://github.com/powert1p/ai-agent-setup.git && cd ai-agent-setup && ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/claude"
TARGET="$HOME/.claude"

echo "=== Claude Code Agent Setup ==="
echo ""

# 1. Бэкап существующей конфигурации
if [ -d "$TARGET" ] && [ "$(ls -A "$TARGET" 2>/dev/null)" ]; then
    BACKUP="$TARGET.backup.$(date +%Y%m%d-%H%M%S)"
    echo "Бэкап существующей конфигурации -> $BACKUP"
    cp -r "$TARGET" "$BACKUP"
    echo "  done"
fi

# 2. Создать структуру директорий
mkdir -p "$TARGET"/{rules,agents,commands,hooks,scripts,skills,memory,projects}
echo "  Директории созданы"

# 3. Копировать основные файлы
cp "$SOURCE/CLAUDE.md" "$TARGET/CLAUDE.md"
cp "$SOURCE/workflow.md" "$TARGET/workflow.md"
[ -f "$SOURCE/coding-pitfalls.md" ] && cp "$SOURCE/coding-pitfalls.md" "$TARGET/coding-pitfalls.md"
echo "  CLAUDE.md, workflow.md, coding-pitfalls.md"

# 4. Rules
cp "$SOURCE/rules/"*.md "$TARGET/rules/"
echo "  Rules ($(ls "$SOURCE/rules/"*.md | wc -l | tr -d ' ') files)"

# 5. Agents
cp "$SOURCE/agents/"*.md "$TARGET/agents/"
echo "  Agents ($(ls "$SOURCE/agents/"*.md | wc -l | tr -d ' ') files)"

# 6. Commands
if ls "$SOURCE/commands/"*.md 1>/dev/null 2>&1; then
    cp "$SOURCE/commands/"*.md "$TARGET/commands/"
    echo "  Commands ($(ls "$SOURCE/commands/"*.md | wc -l | tr -d ' ') files)"
else
    echo "  Commands: нет файлов — пропущено"
fi

# 7. Hooks
cp "$SOURCE/hooks/"*.sh "$TARGET/hooks/"
chmod +x "$TARGET/hooks/"*.sh
echo "  Hooks"

# 8. Scripts
cp "$SOURCE/scripts/"* "$TARGET/scripts/"
chmod +x "$TARGET/scripts/"*.py 2>/dev/null || true
chmod +x "$TARGET/scripts/"*.sh 2>/dev/null || true
echo "  Scripts"

# 9. Skills
cp -r "$SOURCE/skills/"* "$TARGET/skills/"
echo "  Skills ($(ls -d "$SOURCE/skills/"*/ 2>/dev/null | wc -l | tr -d ' ') skills)"

# 10. settings.json — перезаписываем (содержит permissions, model, deny rules)
cp "$SOURCE/settings.json" "$TARGET/settings.json"
echo "  settings.json"

# 11. settings.local.json — НЕ перезаписываем (содержит локальные tool permissions)
if [ -f "$SOURCE/settings.local.json" ]; then
    if [ -f "$TARGET/settings.local.json" ]; then
        echo "  settings.local.json уже существует — не перезаписан"
        echo "    Сверь вручную: diff $TARGET/settings.local.json $SOURCE/settings.local.json"
    else
        cp "$SOURCE/settings.local.json" "$TARGET/settings.local.json"
        echo "  settings.local.json"
    fi
fi

# 12. mcp.json — не перезаписываем если есть
if [ -f "$TARGET/mcp.json" ]; then
    echo "  mcp.json уже существует — не перезаписан"
    echo "    Сверь вручную: diff $TARGET/mcp.json $SOURCE/mcp.json"
else
    sed "s|\\\$HOME|$HOME|g" "$SOURCE/mcp.json" > "$TARGET/mcp.json"
    echo "  mcp.json (paths adapted for $HOME)"
fi

# 13. Проверки
echo ""
echo "=== Checks ==="

MISSING_VARS=()
[ -z "$GITHUB_TOKEN" ] && MISSING_VARS+=("GITHUB_TOKEN")
[ -z "$ANTHROPIC_API_KEY" ] && MISSING_VARS+=("ANTHROPIC_API_KEY")

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "  Missing env vars:"
    for var in "${MISSING_VARS[@]}"; do
        echo "    export $var=<your-value>"
    done
else
    echo "  Env vars OK"
fi

if ! command -v npx &>/dev/null; then
    echo "  npx not found — MCP servers won't work. Install Node.js"
else
    echo "  npx OK"
fi

echo ""
echo "=== Done! ==="
echo ""
echo "Next steps:"
echo "  1. Open Claude Code in any project"
echo "  2. Plugins install automatically via enabledPlugins in settings.json"
echo "  3. To sync changes back to repo: ./export.sh"
echo ""
echo "If plugins didn't auto-install:"
echo "  superpowers, superpowers-chrome, episodic-memory (superpowers-marketplace)"
echo "  frontend-design, code-review, pr-review-toolkit, claude-md-management (claude-plugins-official)"
echo "  agent-teams (claude-code-workflows)"
