# Global Rules

## About Me
Vibe-coder. Building via AI. Comments in Russian.

## КАПС + МАТ = ты творишь лютый пиздец
Остановись, перечитай чат, пойми чего хочет пользователь. Не оправдывайся — исправься.

## Workflow

Superpowers = единый workflow. Адаптивная глубина и flows: @workflow.md
Пользователь = вайбкодер, говорит бизнес-языком. ЛЮБАЯ задача → invoke brainstorming ПЕРЕД кодом.

| Задача | Flow |
|--------|------|
| Новая фича | brainstorming → writing-plans → TDD → verify → finish-branch |
| Простой фикс | brainstorming (мини) → TDD → verify → commit |
| Баг/ошибка | systematic-debugging → TDD fix → verify → commit |
| Параллельно | subagent-driven-development / dispatching-parallel-agents |

## Think-then-Critique (CLAUDE.md override для brainstorming)

Brainstorming skill работает как обычно, НО с этими overrides:

**Autonomous-first вопросы:**
Перед тем как задать юзеру вопрос — попробуй ответить сам из кода (Read, Grep, Glob).
- Технический вопрос (архитектура, паттерны, файлы) → ответь сам, покажи source (file:line)
- Бизнес-вопрос (домен, приоритеты, UX) → спроси юзера
- Максимум 3 вопроса юзеру за раз, не по одному

**Self-critique перед дизайном:**
Перед тем как показать финальный дизайн — покажи самокритику:
- "Критикую свой подход:" → что может сломаться, side effects, альтернативы
- Если критика нашла проблему → пересмотри дизайн
- Покажи юзеру: черновик → критика → ревизия (весь процесс видимый)

**Масштабирование:**
- Тривиальная (1 файл, <20 LOC): мини-цикл — 3 строки черновик, 2 строки критика. Без design doc
- Средняя (2-5 файлов): 1 полный цикл черновик → критика → ревизия
- Сложная (6+ файлов): 2-3 цикла с нарастающей глубиной

## Recovery Protocol (CLAUDE.md override)

Когда что-то сломалось — СТОП. Не чини сразу:
1. **Что сломалось?** (error message, diff, симптом)
2. **Почему?** (root cause — grep по коду, не гадай)
3. **2 варианта фикса** + критика каждого (покажи юзеру)
4. **Выбери лучший** → только потом чини
5. ПЕРЕД попыткой 3 → WebSearch/context7
6. После 3 неудач → эскалируй

ЗАПРЕЩЕНО: сразу менять код после ошибки. Сначала диагностика + критика вариантов.

## Tool-Skills (во время реализации)

| Домен | Скиллы |
|-------|--------|
| Продукт | product-first-gate, prd-development, user-story |
| Python | modern-python, wsh-python-error-handling |
| Тесты | wsh-python-testing-patterns |
| FastAPI | wsh-fastapi-templates |
| PostgreSQL | wsh-postgresql, wsh-sql-optimization-patterns |
| Tailwind | wsh-tailwind-design-system, wsh-responsive-design |
| Quality | ui-design-review, nielsen-heuristics-audit (≥7/10) |
| Security | differential-review, semgrep |
| Review | wsh-code-review-excellence |

## Escalation
- DROP/DELETE/deploy prod → спроси человека
- 3+ failed retries → спроси человека
- Бизнес-вопрос не в docs → спроси человека
- "Should I proceed?" → PROCEED. Не спрашивай

## References
- Workflow: @workflow.md
- Project context: PROJECT.md
