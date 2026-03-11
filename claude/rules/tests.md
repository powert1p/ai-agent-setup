---
globs: "**/test_*.py,**/*.test.*,**/*.spec.*,**/tests/**"
---

# Test Rules

## Main Rule
**NEVER delete or modify existing tests to make them pass.**
Test fails — fix the code, not the test. Exception: test covers removed functionality.

## TDD
For new features — test first, then implement:
1. Write test for expected behavior (it will fail)
2. Implement code to make it pass
3. Refactor if needed

## What to Test
- **Happy path** — main scenario
- **Errors** — invalid input, 404, 403
- **Edge cases** — null, empty array, 0, boundary values

## Python (pytest)
- Mock only external boundaries (DB, HTTP, filesystem)
- Use fixtures from conftest.py
- Naming: `test_action_scenario_expected_result`

## TypeScript (vitest/jest)
- React Testing Library for components
- Test behavior, not implementation

## Don't
- Tests for coverage sake — test real behavior
- Don't bind to specific SQL — test the result, not the query
- sleep/setTimeout in tests

## Data Pipeline Tests
- Unit тесты с моками проверяют ЛОГИКУ (математика, маппинг полей)
- Для data pipeline задач (loaders, MV, миграции) — обязательна верификация через MCP
- Мок с идеальными данными не ловит: NULL deal_id, пустые JOIN, missing FK
- После каждого изменения pipeline: execute_sql → проверить реальные данные
