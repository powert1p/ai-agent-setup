#!/usr/bin/env python3
"""
Source Guard — PreToolCall hook для Claude Code.
Блокирует Edit/Write на source-файлах (.py, .ts, .tsx, .js, .jsx)
от coordinator'а. Implementer teammates должны делать это.

Пропускает: .md, .json, .yml, .yaml, .sql, .toml, .cfg, .txt, .sh, .env
"""

import json
import sys
import os

# Расширения source-файлов, которые coordinator НЕ должен редактировать
SOURCE_EXTENSIONS = {
    ".py", ".ts", ".tsx", ".js", ".jsx",
    ".css", ".scss", ".less",
    ".html", ".svelte", ".vue",
}

# Расширения, которые coordinator МОЖЕТ редактировать
ALLOWED_EXTENSIONS = {
    ".md", ".json", ".yml", ".yaml", ".sql", ".toml",
    ".cfg", ".txt", ".sh", ".env", ".ini", ".lock",
    ".gitignore", ".dockerignore",
}

# Пути, которые всегда разрешены (конфиги, скрипты агентов)
ALLOWED_PATH_PATTERNS = [
    "/.claude/",
    "/docs/",
    "/migrations/",
    "/.github/",
    "/scripts/",
    "conftest.py",      # тестовые конфиги
    "settings.json",
    "package.json",
    "tsconfig.json",
    "pyproject.toml",
    "requirements.txt",
    "Dockerfile",
    "docker-compose",
]


def main():
    try:
        hook_input = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        # Если не удалось прочитать — пропускаем (не блокируем)
        sys.exit(0)

    tool_name = hook_input.get("tool_name", "")
    tool_input = hook_input.get("tool_input", {})

    # Интересуют только Edit и Write
    if tool_name not in ("Edit", "Write"):
        sys.exit(0)

    file_path = tool_input.get("file_path", "")
    if not file_path:
        sys.exit(0)

    # Проверяем разрешённые пути
    for pattern in ALLOWED_PATH_PATTERNS:
        if pattern in file_path:
            sys.exit(0)

    # Проверяем расширение
    _, ext = os.path.splitext(file_path)
    ext = ext.lower()

    # Разрешённые расширения — пропускаем
    if ext in ALLOWED_EXTENSIONS:
        sys.exit(0)

    # Source-файлы — блокируем
    if ext in SOURCE_EXTENSIONS:
        filename = os.path.basename(file_path)
        result = {
            "decision": "block",
            "reason": (
                f"[SOURCE GUARD] Coordinator НЕ редактирует source-файлы напрямую.\n"
                f"Файл: {filename}\n\n"
                "ПРАВИЛО: Edit/Write на .py/.ts/.tsx → spawn implementer teammate.\n"
                "Ты — COORDINATOR. Твоя работа: спавнить агентов, мониторить, коммитить.\n"
                "Используй Task tool с subagent_type='implementer' для изменений кода."
            ),
        }
        json.dump(result, sys.stdout)
        sys.exit(0)

    # Неизвестное расширение — пропускаем (не блокируем)
    sys.exit(0)


if __name__ == "__main__":
    main()
