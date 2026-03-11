# Development Workflow

Автономный после одобрения дизайна. Без участия человека кроме: деструктивные DB-операции, деплой, 3+ failed retries, бизнес-вопросы.

## Адаптивная глубина

| Сложность | Критерий | Что делать |
|-----------|----------|------------|
| Тривиальная | 1 файл, <20 LOC, очевидный фикс | «Делаю: [что] чтобы [зачем]» → TDD |
| Средняя | 2-5 файлов, ясные требования | invoke brainstorming → TDD |
| Сложная | 6+ файлов, новая фича, неясный scope | PM → brainstorming → writing-plans → TDD |
| Обсуждение | Вопрос без задачи | Ответь на языке продукта |

**Системные файлы** (CLAUDE.md, workflow.md, settings.json, hooks, autonomy-guard) — ВСЕГДА минимум средняя сложность.

## Два режима работы с PM

### Режим 1: PM-first solo (рутина, 1-2 фичи)

Последовательный. PM и оркестратор работают по очереди.

```
Есет → /pm → PM собирает требования → brief + spec в файлы
     → Оркестратор читает spec → декомпозирует → раздаёт агентам
     → Агенты работают → результат
```

Когда использовать:
- Одна конкретная фича или фикс
- Ясные требования
- Не нужна координация между агентами

Как запускать:
1. `/pm [хотелка]` — PM собирает ТЗ, создаёт spec
2. Оркестратор: `Прочитай docs/specs/X-spec.md и создай план`
3. Dev-агенты работают параллельно в worktrees

### Режим 2: Agent Teams (сложные задачи, мультикомпонентные фичи)

Параллельный. PM = teammate в команде, общается через mailbox.

```
Есет → Team Lead (оркестратор)
  → teammate "pm" — собирает требования, пишет spec
  → teammate "researcher" — разведка codebase
  → teammate "implementer" — кодит по spec
  → teammate "tester" — тестирует
  → teammate "reviewer" — ревьюит
```

Когда использовать:
- 6+ файлов, мультикомпонентная фича
- Нужна координация: PM ↔ researcher ↔ implementer
- Рефакторинг / исследование / сложная интеграция

Как запускать:
```
Создай команду для [задача].
Teammate "pm" — собери требования у заказчика
Teammate "researcher" — изучи codebase
Teammate "implementer" — реализуй по spec
Teammate "tester" — напиши и прогони тесты
```

## ЖЁСТКОЕ ПРАВИЛО: brainstorming = entry point

Для ЛЮБОЙ средней/сложной задачи **ПЕРВОЕ ДЕЙСТВИЕ** = `Skill('brainstorming')`.
- ЗАПРЕЩЕНО до brainstorming: Read, Bash, Grep, Glob, Agent, Write, Edit
- ЗАПРЕЩЕНО: "подумаю вслух 3-5 строк" вместо вызова скилла
- Brainstorming скилл сам задаёт вопросы, сам ведёт диалог
- Агент НЕ заменяет brainstorming своими вопросами — скилл ведёт

## Flows (superpowers)

### Feature (сложная задача)
1. PM → сбор требований → brief + spec (Режим 1 или 2)
2. brainstorming → explore context → propose options → user approval → design doc
3. writing-plans → bite-sized tasks с TDD steps
4. test-driven-development → RED → GREEN → REFACTOR (per task)
5. verification-before-completion → evidence before claims
6. requesting-code-review → review loop
7. finishing-a-development-branch → merge/PR

### Medium (средняя задача)
1. invoke brainstorming → понять intent, задать вопросы, одобрение
2. test-driven-development → red-green-refactor
3. verification-before-completion
4. Commit

### Simple (1 файл, тривиальная)
1. test-driven-development → red-green-refactor
2. verification-before-completion
3. Commit

### Bug
1. systematic-debugging → root cause → hypothesis → implement
2. TDD fix → red-green-refactor
3. verification → commit

## Агенты (6 ролей, 3-4 скилла каждый)

| Агент | Роль | Skills (YAML) |
|-------|------|---------------|
| pm | Бизнес-аналитик | product-first-gate, prd-development, user-story, epic-breakdown-advisor |
| implementer | Кодер (TDD) | superpowers:TDD, superpowers:verification, modern-python |
| tester | Тестировщик | superpowers:TDD, superpowers:verification, wsh-python-testing-patterns |
| reviewer | Ревьюер | superpowers:requesting-code-review, differential-review, wsh-code-review-excellence |
| researcher | Разведка (read-only) | — |
| data-engineer | Data/SQL | superpowers:TDD, superpowers:verification, modern-python |

## Gates
- PM (сложные): сбор требований ПЕРЕД brainstorming
- Brainstorming (средние + сложные): invoke Skill('brainstorming') ПЕРЕД кодом
- TDD: НЕТ кода без failing test
- Verification: НЕТ "готово" без evidence
- 3 failures → escalate

## Error Recovery
1. Ошибка → исправь
2. Другой подход → исправь
3. ПЕРЕД попыткой 3 → WebSearch/context7
4. После 3 неудач → эскалируй
