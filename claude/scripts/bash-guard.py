#!/usr/bin/env python3
"""
bash-guard.py — PreToolCall hook для Bash tool.

Блокирует команды которые записывают в source-файлы (.py, .ts, .tsx, .js, .jsx, .css, .html, .vue, .svelte).
Координатор НЕ должен модифицировать исходный код через Bash — только через subagent implementer.

Логика:
- Нужно ОДНОВРЕМЕННО: признак записи И source-расширение в команде
- Ложные блокировки хуже пропусков — приоритет минимизации false positive
"""

import json
import sys


# Source-расширения которые нельзя трогать через Bash
SOURCE_EXTENSIONS = (
    ".py", ".ts", ".tsx", ".js", ".jsx",
    ".css", ".html", ".vue", ".svelte",
)

# Паттерны команд которые записывают в файлы
WRITE_PATTERNS = [
    "sed -i",       # sed inplace edit
    "tee ",         # tee пишет в файл
    "tee\t",        # tee с табом
]

# Redirect-паттерны
REDIRECT_PATTERNS = [
    " > ",
    " >> ",
    "\t> ",
    "\t>> ",
]


def has_write_operation(command: str) -> bool:
    """Проверяет есть ли в команде операция записи в файл."""
    for pattern in WRITE_PATTERNS:
        if pattern in command:
            return True

    for pattern in REDIRECT_PATTERNS:
        if pattern in command:
            return True

    # python -c с open() и write — запись через Python inline
    if "python" in command and "-c" in command:
        if "open(" in command and (
            "write(" in command or
            "writelines(" in command or
            '"w"' in command or
            "'w'" in command or
            '"a"' in command or
            "'a'" in command
        ):
            return True

    return False


def extract_redirect_target(command: str) -> str:
    """Извлекает путь-цель redirect оператора."""
    for op in [" >> ", " > ", "\t>> ", "\t> "]:
        idx = command.find(op)
        if idx != -1:
            after = command[idx + len(op):].strip()
            target = ""
            for ch in after:
                if ch in (" ", "\t", ";", "&", "|", "\n", '"', "'"):
                    break
                target += ch
            return target
    return ""


def target_is_source_file(target: str) -> bool:
    """Проверяет что цель redirect — source-файл."""
    if not target:
        return False
    lower = target.lower()
    for ext in SOURCE_EXTENSIONS:
        if lower.endswith(ext):
            return True
    return False


def command_writes_to_source(command: str) -> bool:
    """Главная проверка: команда ОДНОВРЕМЕННО содержит запись И source-расширение в цели."""
    if not has_write_operation(command):
        return False

    # sed -i: проверяем есть ли source-расширение в аргументах
    if "sed -i" in command:
        for ext in SOURCE_EXTENSIONS:
            if ext in command:
                return True
        return False

    # tee: проверяем аргумент
    if "tee " in command or "tee\t" in command:
        for ext in SOURCE_EXTENSIONS:
            if ext in command:
                return True
        return False

    # python -c: проверяем есть ли source-расширение в строке
    if "python" in command and "-c" in command:
        if "open(" in command:
            for ext in SOURCE_EXTENSIONS:
                if ext in command:
                    return True
        return False

    # redirect: проверяем расширение цели
    target = extract_redirect_target(command)
    if target_is_source_file(target):
        return True

    return False


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    tool_name = data.get("tool_name", "")
    if tool_name != "Bash":
        sys.exit(0)

    tool_input = data.get("tool_input", {})
    if not isinstance(tool_input, dict):
        sys.exit(0)

    command = tool_input.get("command", "")
    if not isinstance(command, str) or not command.strip():
        sys.exit(0)

    if command_writes_to_source(command):
        result = {
            "decision": "block",
            "reason": (
                "[BASH GUARD] Coordinator НЕ модифицирует source-файлы через Bash.\n"
                "Команда содержит запись в source-файл.\n\n"
                "ПРАВИЛО: Используй Task tool с subagent_type='implementer' для изменений кода."
            ),
        }
        print(json.dumps(result))
        sys.exit(0)

    sys.exit(0)


if __name__ == "__main__":
    main()
