---
allowed-tools: Bash(git:*)
description: Smart commit с AI-generated message
model: haiku
---

## Context

- Status: !`git status --short`
- Diff: !`git diff --staged --stat`
- Recent: !`git log --oneline -5`

## Task

Создай один коммит из staged изменений. Если ничего не staged — добавь все изменённые файлы (кроме .env, credentials, секретов).

Формат сообщения: `type: краткое описание`
Types: feat / fix / docs / refactor / test / ci / spec

Пиши на английском, коротко, по существу. Добавь:
Co-Authored-By: Claude <noreply@anthropic.com>
