#!/bin/bash
# agent-init — инициализация проекта для всех AI-агентов
# Запуск: agent-init (в корне проекта)

set -e

PROJECT_NAME=$(basename "$(pwd)")
TEMPLATE_DIR="$HOME/.claude/templates"

echo "🚀 Инициализация: $PROJECT_NAME"
echo "---"

# 1. Git
if [ ! -d .git ]; then
    git init
    echo "✓ Git"
else
    echo "· Git уже есть"
fi

# 2. .gitignore
if [ ! -f .gitignore ]; then
    cat > .gitignore << 'GITIGNORE'
.env
.env.*
!.env.example
*.pem
*.key
credentials.*
secrets.*
node_modules/
vendor/
.venv/
venv/
__pycache__/
*.pyc
.DS_Store
.idea/
*.iml
dist/
build/
GITIGNORE
    echo "✓ .gitignore"
else
    echo "· .gitignore уже есть"
fi

# 3. PROJECT.md
if [ ! -f PROJECT.md ]; then
    if [ -f "$TEMPLATE_DIR/PROJECT.md" ]; then
        sed "s/\[Название проекта\]/$PROJECT_NAME/" "$TEMPLATE_DIR/PROJECT.md" > PROJECT.md
        echo "✓ PROJECT.md"
    else
        echo "⚠ Шаблон не найден: $TEMPLATE_DIR/PROJECT.md"
        exit 1
    fi
else
    echo "· PROJECT.md уже есть"
fi

# 4. AGENTS.md
cat > AGENTS.md << 'AGENTS'
# Правила для AI-агентов

Владелец — вайб-кодер. Пиши просто, объясняй что делаешь. Комментарии на русском.

## Главное
1. Прочитай PROJECT.md — там план, архитектура, контекст
2. Если PROJECT.md нет — запусти `agent-init` в корне проекта
3. Не пиши код пока не понял контекст
4. После каждой задачи: обнови PROJECT.md (отметь [x], запиши решения) → git commit

## Код
- Ошибки не глотать. Секреты в env. SQL параметризованный
- Слои: handler → service → repository
- Ищи существующие утилиты перед написанием новых
- Качество > скорость. Думай о продакшне
- Не делегируй владельцу то что можешь сделать сам
AGENTS
echo "✓ AGENTS.md"

# 5. Симлинки
ln -sf AGENTS.md CLAUDE.md
ln -sf AGENTS.md .cursorrules
ln -sf AGENTS.md .windsurfrules
mkdir -p .github
ln -sf ../AGENTS.md .github/copilot-instructions.md
echo "✓ Симлинки (CLAUDE.md, .cursorrules, .windsurfrules, .github/copilot-instructions.md)"

# 6. Git identity
GIT_USER=$(git config user.name 2>/dev/null || true)
GIT_EMAIL=$(git config user.email 2>/dev/null || true)

if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ]; then
    echo ""
    echo "⚠ Git user не настроен:"
    if [ -z "$GIT_USER" ]; then
        read -p "  Имя: " GIT_USER
        git config --global user.name "$GIT_USER"
    fi
    if [ -z "$GIT_EMAIL" ]; then
        read -p "  Email: " GIT_EMAIL
        git config --global user.email "$GIT_EMAIL"
    fi
    echo "✓ Git user: $GIT_USER <$GIT_EMAIL>"
fi

# 7. Коммит
if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "init: project setup with AI agent rules"
    echo "✓ Первый коммит"
fi

echo ""
echo "✅ $PROJECT_NAME готов!"
echo "  PROJECT.md — заполни план и контекст проекта"
echo "  AGENTS.md  — правила для всех AI-агентов"
