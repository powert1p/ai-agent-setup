# Development Workflow

Автономный после одобрения дизайна. Без участия человека кроме: деструктивные DB-операции, деплой, 3+ failed retries, бизнес-вопросы.

## Адаптивная глубина

| Сложность | Критерий | Что делать |
|-----------|----------|------------|
| Тривиальная | 1 файл, <20 LOC, очевидный фикс | «Делаю: [что] чтобы [зачем]» → TDD |
| Средняя | 2-5 файлов, ясные требования | invoke brainstorming → TDD |
| Сложная | 6+ файлов, новая фича, неясный scope | invoke brainstorming → writing-plans → TDD |
| Обсуждение | Вопрос без задачи | Ответь на языке продукта |

**Системные файлы** (CLAUDE.md, workflow.md, settings.json, hooks, autonomy-guard) — ВСЕГДА минимум средняя сложность.

## ЖЁСТКОЕ ПРАВИЛО: brainstorming = entry point

Для ЛЮБОЙ средней/сложной задачи **ПЕРВОЕ ДЕЙСТВИЕ** = `Skill('brainstorming')`.
- ЗАПРЕЩЕНО до brainstorming: Read, Bash, Grep, Glob, Agent, Write, Edit
- ЗАПРЕЩЕНО: "подумаю вслух 3-5 строк" вместо вызова скилла
- Brainstorming скилл сам задаёт вопросы, сам ведёт диалог
- Агент НЕ заменяет brainstorming своими вопросами — скилл ведёт

## Flows (superpowers)

### Feature (сложная задача)
1. brainstorming → explore context → propose options → user approval → design doc
2. writing-plans → bite-sized tasks с TDD steps
3. test-driven-development → RED → GREEN → REFACTOR (per task)
4. verification-before-completion → evidence before claims
5. requesting-code-review → review loop
6. finishing-a-development-branch → merge/PR

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

## Gates
- Brainstorming (средние + сложные): invoke Skill('brainstorming') ПЕРЕД кодом
- TDD: НЕТ кода без failing test
- Verification: НЕТ "готово" без evidence
- 3 failures → escalate

## Error Recovery
1. Ошибка → исправь
2. Другой подход → исправь
3. ПЕРЕД попыткой 3 → WebSearch/context7
4. После 3 неудач → эскалируй
