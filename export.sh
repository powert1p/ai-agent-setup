#!/bin/bash
# Экспорт текущей конфигурации ~/.claude/ → репо ai-agent-setup
# Запуск: cd ai-agent-setup && ./export.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/claude"
SOURCE="$HOME/.claude"

echo "=== Export: ~/.claude/ → ai-agent-setup/claude/ ==="
echo ""

# 0. Проверка что мы в правильном репо
if [ ! -f "$SCRIPT_DIR/install.sh" ]; then
    echo "ОШИБКА: запусти из директории ai-agent-setup"
    exit 1
fi

# 1. Создать директории в репо если нет
mkdir -p "$TARGET"/{rules,agents,commands,hooks,scripts,skills}

# 2. Основные файлы
cp "$SOURCE/CLAUDE.md" "$TARGET/CLAUDE.md"
cp "$SOURCE/workflow.md" "$TARGET/workflow.md"
[ -f "$SOURCE/coding-pitfalls.md" ] && cp "$SOURCE/coding-pitfalls.md" "$TARGET/coding-pitfalls.md"
echo "  CLAUDE.md, workflow.md, coding-pitfalls.md"

# 3. Rules
cp "$SOURCE/rules/"*.md "$TARGET/rules/"
echo "  Rules ($(ls "$SOURCE/rules/"*.md | wc -l | tr -d ' ') files)"

# 4. Agents
cp "$SOURCE/agents/"*.md "$TARGET/agents/"
echo "  Agents ($(ls "$SOURCE/agents/"*.md | wc -l | tr -d ' ') files)"

# 5. Commands
if ls "$SOURCE/commands/"*.md 1>/dev/null 2>&1; then
    cp "$SOURCE/commands/"*.md "$TARGET/commands/"
    echo "  Commands ($(ls "$SOURCE/commands/"*.md | wc -l | tr -d ' ') files)"
else
    echo "  Commands: нет .md файлов — пропущено"
fi

# 6. Hooks
cp "$SOURCE/hooks/"*.sh "$TARGET/hooks/"
echo "  Hooks ($(ls "$SOURCE/hooks/"*.sh | wc -l | tr -d ' ') files)"

# 7. Scripts
cp "$SOURCE/scripts/"* "$TARGET/scripts/"
echo "  Scripts"

# 8. Skills (директории с SKILL.md)
for skill_dir in "$SOURCE/skills/"*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p "$TARGET/skills/$skill_name"
    cp -r "$skill_dir"* "$TARGET/skills/$skill_name/"
done
echo "  Skills ($(ls -d "$SOURCE/skills/"*/ 2>/dev/null | wc -l | tr -d ' ') skills)"

# 9. settings.json (без machine-specific paths)
cp "$SOURCE/settings.json" "$TARGET/settings.json"
echo "  settings.json"

# 10. settings.local.json → шаблон (убираем machine-specific данные)
if [ -f "$SOURCE/settings.local.json" ]; then
    cp "$SOURCE/settings.local.json" "$TARGET/settings.local.json"
    echo "  settings.local.json"
fi

# 11. MCP template (подставляем переменные вместо секретов)
if [ -f "$SOURCE/mcp.json" ]; then
    cp "$SOURCE/mcp.json" "$TARGET/mcp.json"
    echo "  mcp.json"
fi

echo ""

# === СЕКРЕТ-СКАНЕР ===
echo "=== Security check ==="
SECRETS_FOUND=0

# Паттерны секретов
while IFS= read -r line; do
    if [ -n "$line" ]; then
        SECRETS_FOUND=1
    fi
done < <(grep -rn \
    -e 'gho_[A-Za-z0-9_]\{20,\}' \
    -e 'ghp_[A-Za-z0-9_]\{20,\}' \
    -e 'lin_api_[A-Za-z0-9_]\{20,\}' \
    -e 'postgresql://[^"]*@[^"]*' \
    -e 'sk-ant-[A-Za-z0-9_]\{20,\}' \
    -e 'ANTHROPIC_API_KEY.*=.*[A-Za-z0-9]' \
    "$TARGET/" 2>/dev/null || true)

if [ "$SECRETS_FOUND" -eq 1 ]; then
    echo ""
    echo "  ⚠️  СЕКРЕТЫ НАЙДЕНЫ в экспортированных файлах!"
    echo ""
    grep -rn \
        -e 'gho_[A-Za-z0-9_]\{20,\}' \
        -e 'ghp_[A-Za-z0-9_]\{20,\}' \
        -e 'lin_api_[A-Za-z0-9_]\{20,\}' \
        -e 'postgresql://[^"]*@[^"]*' \
        -e 'sk-ant-[A-Za-z0-9_]\{20,\}' \
        "$TARGET/" 2>/dev/null | sed 's|'"$SCRIPT_DIR/"'||g' | while read -r match; do
        echo "    $match"
    done
    echo ""
    echo "  ОЧИСТИ СЕКРЕТЫ перед коммитом!"
    echo "  Замени на переменные: \$GITHUB_TOKEN, \$DATABASE_URL и т.д."
    echo ""
else
    echo "  Секреты не найдены ✅"
fi

# === DIFF ===
echo ""
echo "=== Changes ==="
cd "$SCRIPT_DIR"
git add -A
git diff --cached --stat
echo ""
echo "Проверь diff: git diff --cached"
echo "Коммит: git commit -m 'sync: export from $(hostname)'"
echo "Push: git push"
