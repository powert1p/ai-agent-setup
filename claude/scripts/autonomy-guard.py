#!/usr/bin/env python3
"""
Autonomy Guard — Stop hook для Claude Code.
Ловит паттерны вопросов к пользователю и блокирует остановку,
возвращая Claude назад к работе.

Не срабатывает:
- Если stop_hook_active=true (предотвращение бесконечного цикла)
- Если сообщение содержит бизнес-вопрос (доменная логика)
- Если сообщение содержит деструктивные операции (DROP/DELETE)
- Если сообщение содержит "deploy" (требует подтверждения)
"""

import json
import re
import sys

# Паттерны вопросов, которые агент НЕ должен задавать пользователю
# (технические решения, разрешения на продолжение, выбор подхода)
QUESTION_PATTERNS = [
    # English permission-seeking
    r"(?i)\bshould I (proceed|continue|go ahead|start|fix|create|implement|deploy|push|commit)",
    r"(?i)\bshall I\b",
    r"(?i)\bdo you want me to\b",
    r"(?i)\bwould you like me to\b",
    r"(?i)\bwould you prefer\b",
    r"(?i)\bwhich (approach|option|method|way)\b.*\?",
    r"(?i)\bis this (approach|plan|okay|ok|acceptable)\b.*\?",
    r"(?i)\bwhat do you think\b.*\?",
    r"(?i)\bwhat would you prefer\b",
    r"(?i)\bcan I proceed\b",
    r"(?i)\bready to (proceed|continue|start)\b.*\?",
    r"(?i)\blet me know (if|when|how)\b",
    r"(?i)\bwhat('s| is) your (preference|opinion|thought)\b",
    r"(?i)\bplease (confirm|approve|verify)\b",

    # Russian permission-seeking
    r"(?i)\bхочешь\b.*\?",
    r"(?i)\bхотите\b.*\?",
    r"(?i)\bпродолжать\b.*\?",
    r"(?i)\bпродолжить\b.*\?",
    r"(?i)\bпродолжим\b.*\?",
    r"(?i)\bодобря(ешь|ете)\b",
    r"(?i)\bподтвер(ди|дите)\b.*\?",
    r"(?i)\bнужно ли\b.*\?",
    r"(?i)\bстоит ли\b.*\?",
    r"(?i)\bкакой вариант\b.*\?",
    r"(?i)\bкакой подход\b.*\?",
    r"(?i)\bчто (предпочитаешь|предпочитаете|думаешь|думаете)\b.*\?",
    r"(?i)\bмогу (ли я|продолжить)\b",
    r"(?i)\bнужн(о|а) (ваш[аеио]|тво[еёия]) (одобрени|подтверждени|разрешени)",
    r"(?i)\bкак (вы |ты )?(считаете|считаешь|думаете|думаешь)\b.*\?",
    r"(?i)\bпредлагаю\b.*\.\s*(как|что|ок|подходит)\b.*\?",
    r"(?i)\bвыбери(те)?\b.*\?",
    r"(?i)\b(запустить|пушить|деплоить|коммитить)\b.*\?",
    r"(?i)\bот тебя\b.*\bнужн",
    r"(?i)\bчто (от|для) (меня|тебя)\b.*нужн",

    # "Что делаем?" и варианты меню
    r"(?i)\bчто делаем\b.*\?",
    r"(?i)\bчто (будем|дальше)\b.*\?",
    r"(?i)\bкуда (двигаемся|движемся|идём)\b.*\?",
    r"(?i)\bс чего начн[её]м\b.*\?",
    r"(?i)\bстартуем\b.*\?",
    r"(?i)\bначн[её]м\b.*\?",
    r"(?i)\bчто[- ]то друго[ей]\b.*\?",

]

# Исключения — эти паттерны РАЗРЕШАЮТ вопросы (бизнес-логика, деструктивные ops)
ALLOW_PATTERNS = [
    r"(?i)\bDROP\s+(TABLE|COLUMN|DATABASE|SCHEMA)\b",
    r"(?i)\bDELETE\s+FROM\b(?!.*WHERE)",
    r"(?i)\bTRUNCATE\b",
    r"(?i)(deploy|деплой|release|релиз).*(prod|production|staging)",
    r"(?i)\bdepl(oy|оить)\b.*prod",
    r"(?i)\bбизнес[- ]логик",
    r"(?i)\bдоменн(ая|ый|ые|ое)\b",
    r"(?i)\bPROJECT\.md\b",
    # PM-режим: заказчику можно задавать продуктовые вопросы
    r"(?i)\b(pm|project manager|проджект менеджер)\b",
    r"(?i)\b(хотелк|фич|функционал|раздел|блок|приоритет|дедлайн|scope)\b",
    r"(?i)\b(что (хочешь|нужно|важно)|для кого|какую проблему)\b",
    r"(?i)\b(два варианта|вариант [AB]|что ближе|что предпочитаешь)\b",
    # "запустить X?" — продуктовый контекст (не deploy)
    r"(?i)\b(запустить|запустим)\b.*(фич|блок|экспорт|отчёт|дайджест|кнопк|workspace|задач)",
    # Superpowers workflow — контекстные маркеры активных скиллов
    r"(?i)##\s*(Design|Brainstorm|Approach|Option|Spec|Plan|Summary|Proposal)",
    r"(?i)(option|вариант|approach|подход)\s+[A-C1-3]\b",
    r"(?i)\b(brainstorm|design doc|design review|spec review)\b",
    r"(?i)\bUsing\s+(brainstorming|writing-plans|test-driven|verification|systematic-debugging|code-review)\b",
    r"(?i)brainstorming\s+skill",
    r"(?i)##\s*(Clarifying|Understanding|Exploring|Design|Question)",
    r"(?i)(предлагаю|propose|recommend)\s+\d+\s+(approach|option|вариант|подход)",
    r"(?i)\b(Phase|Gate|Step)\s+\d+\b",
]


def main():
    hook_input = json.loads(sys.stdin.read())

    # Предотвращение бесконечного цикла
    if hook_input.get("stop_hook_active"):
        sys.exit(0)

    last_message = hook_input.get("last_assistant_message", "")
    if not last_message:
        sys.exit(0)

    # Проверяем исключения — если есть деструктивная/бизнес тема, разрешаем вопрос
    for pattern in ALLOW_PATTERNS:
        if re.search(pattern, last_message):
            sys.exit(0)

    # Ищем запрещённые паттерны вопросов
    matched_pattern = None
    for pattern in QUESTION_PATTERNS:
        match = re.search(pattern, last_message)
        if match:
            matched_pattern = match.group(0)
            break

    if not matched_pattern:
        # Нет запрещённых вопросов — разрешаем остановку
        sys.exit(0)

    # Нашли запрещённый вопрос — блокируем остановку
    result = {
        "decision": "block",
        "reason": (
            f"[AUTONOMY GUARD] Ты задал вопрос вместо действия: \"{matched_pattern}\"\n\n"
            "ПРАВИЛА:\n"
            "- Технические решения — ТВОИ. Не спрашивай.\n"
            "- git push/commit — ДЕЛАЙ, не спрашивай.\n"
            "- Выбор подхода — ВЫБЕРИ сам (проще = лучше).\n"
            "- Deploy (railway up) — СПРОСИ ЧЕЛОВЕКА. Это единственное исключение.\n"
            "- Исправление бага — ИСПРАВЛЯЙ, не спрашивай.\n\n"
            "ПРОДОЛЖАЙ РАБОТУ. Прими решение сам и выполни."
        ),
    }
    json.dump(result, sys.stdout)
    sys.exit(0)


if __name__ == "__main__":
    main()
