---
allowed-tools: Bash
description: Запуск всех тестов (pytest + tsc)
model: haiku
---

## Context

- Changed files: !`git diff --name-only HEAD`
- Project root: !`ls package.json requirements.txt pyproject.toml 2>/dev/null`

## Task

Запусти тесты проекта:

1. Если есть Python: `.venv/bin/pytest tests/ -x -q`
2. Если есть frontend: `cd frontend && npx tsc --noEmit`

Покажи результат. Если падают — покажи ошибки кратко (первые 20 строк каждого failure).
