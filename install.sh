#!/bin/bash
# Установка системы AI-агентов
# Запуск: ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude"

echo "🔧 Установка AI-агент системы..."
echo "---"

# 1. Создать папки
mkdir -p "$TARGET/templates" "$TARGET/scripts"
echo "✓ Папки: ~/.claude/"

# 2. Скопировать файлы
cp "$SCRIPT_DIR/claude/CLAUDE.md" "$TARGET/CLAUDE.md"
cp "$SCRIPT_DIR/claude/templates/PROJECT.md" "$TARGET/templates/PROJECT.md"
cp "$SCRIPT_DIR/claude/scripts/agent-init.sh" "$TARGET/scripts/agent-init.sh"
chmod +x "$TARGET/scripts/agent-init.sh"
echo "✓ Файлы скопированы"

# 3. Alias
SHELL_RC="$HOME/.zshrc"
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if ! grep -q 'alias agent-init=' "$SHELL_RC" 2>/dev/null; then
    echo '' >> "$SHELL_RC"
    echo '# AI Agent Init — инициализация проекта для всех AI-агентов' >> "$SHELL_RC"
    echo 'alias agent-init="bash ~/.claude/scripts/agent-init.sh"' >> "$SHELL_RC"
    echo "✓ Alias добавлен в $(basename "$SHELL_RC")"
else
    echo "· Alias уже есть"
fi

echo ""
echo "✅ Готово!"
echo ""
echo "Перезапусти терминал или выполни:"
echo "  source $SHELL_RC"
echo ""
echo "Потом в любом проекте:"
echo "  mkdir my-project && cd my-project && agent-init"
