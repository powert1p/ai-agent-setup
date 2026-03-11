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
cp "$SOURCE/coding-pitfalls.md" "$TARGET/coding-pitfalls.md"
echo "  CLAUDE.md, workflow.md, coding-pitfalls.md"

# 4. Rules
cp "$SOURCE/rules/"*.md "$TARGET/rules/"
echo "  Rules ($(ls "$SOURCE/rules/"*.md | wc -l | tr -d ' ') files)"

# 5. Agents
cp "$SOURCE/agents/"*.md "$TARGET/agents/"
echo "  Agents ($(ls "$SOURCE/agents/"*.md | wc -l | tr -d ' ') files)"

# 6. Commands
cp "$SOURCE/commands/"*.md "$TARGET/commands/"
echo "  Commands ($(ls "$SOURCE/commands/"*.md | wc -l | tr -d ' ') files)"

# 7. Hooks
cp "$SOURCE/hooks/"*.sh "$TARGET/hooks/"
chmod +x "$TARGET/hooks/"*.sh
echo "  Hooks"

# 8. Scripts
cp "$SOURCE/scripts/"* "$TARGET/scripts/"
chmod +x "$TARGET/scripts/"*.sh 2>/dev/null || true
echo "  Scripts"

# 9. Skills
cp -r "$SOURCE/skills/"* "$TARGET/skills/"
echo "  Skills ($(ls -d "$SOURCE/skills/"*/ 2>/dev/null | wc -l | tr -d ' ') skills)"

# 10. settings.json — не перезаписываем если есть
if [ -f "$TARGET/settings.json" ]; then
    echo "  settings.json уже существует — не перезаписан"
    echo "    Сверь вручную: diff $TARGET/settings.json $SOURCE/settings.json"
else
    cp "$SOURCE/settings.json" "$TARGET/settings.json"
    echo "  settings.json"
fi

# 11. mcp.json — не перезаписываем если есть
if [ -f "$TARGET/mcp.json" ]; then
    echo "  mcp.json уже существует — не перезаписан"
    echo "    Сверь вручную: diff $TARGET/mcp.json $SOURCE/mcp.json"
else
    sed "s|\\\$HOME|$HOME|g" "$SOURCE/mcp.json" > "$TARGET/mcp.json"
    echo "  mcp.json (paths adapted for $HOME)"
fi

# 12. Проверки
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
echo "  2. Plugins install automatically on first launch"
echo ""
echo "Plugins to install manually if needed:"
echo "  superpowers, superpowers-chrome, episodic-memory (superpowers-marketplace)"
echo "  frontend-design, code-review, pr-review-toolkit, claude-md-management (claude-plugins-official)"
echo "  agent-teams (claude-code-workflows)"
