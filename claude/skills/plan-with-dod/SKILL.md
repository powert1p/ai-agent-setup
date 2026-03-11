---
name: plan-with-dod
description: Add risks and Definition of Done to implementation plans. Use after writing-plans.
---

# Plan with DoD

Дополняет superpowers:writing-plans. Вызывается ПОСЛЕ writing-plans, НЕ вместо.

## Что делать

Для каждого чанка в плане добавь:

### 1. Риски (что может сломаться)
- Внешние зависимости (API, БД, сторонние сервисы)
- Конфликты с существующим кодом
- Edge cases которые легко пропустить
- Формат: 1-2 строки на риск, конкретно

### 2. Definition of Done (критерии готовности)

Чеклист из autonomy.md, адаптированный под конкретный чанк:

#### Code
- [ ] Код без синтаксических ошибок
- [ ] Все существующие тесты проходят
- [ ] Новые тесты написаны (happy + error + edge)
- [ ] SQL параметризованный. Никаких f-string
- [ ] Нет hardcoded секретов

#### Data Pipeline (если применимо)
- [ ] Миграция idempotent (IF NOT EXISTS, ON CONFLICT)
- [ ] SQL проверен через MCP: NOT NULL, NOT 0

#### Frontend (если применимо)
- [ ] TypeScript типы совпадают с Pydantic schemas
- [ ] React Query (НЕ useState+useEffect для данных)
- [ ] `npx tsc --noEmit` проходит
- [ ] Playwright верификация: snapshot + console + screenshot

## Формат вывода

```markdown
### Чанк N: [название из writing-plans]

**Риски:**
- [риск 1]
- [риск 2]

**DoD:**
- [ ] [критерий 1]
- [ ] [критерий 2]
- [ ] [критерий 3]
```

## Правила
- НЕ дублировать содержание writing-plans (задачи, шаги)
- Только добавить риски + DoD
- DoD должен быть проверяемым (команда, запрос, скриншот)
- Если чанк тривиальный (1 файл, <10 LOC) — DoD = "тесты проходят"
