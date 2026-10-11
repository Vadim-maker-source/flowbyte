from app.schemas.content import ExerciseRead, LessonRead, ModuleRead, ModuleSummary


_MODULES = [
    {
        "id": "conditions",
        "title": "Условия и решения",
        "description": "if, else, сравнения и составные условия на Python.",
        "lessons": [
            (
                "lesson-1",
                1,
                "Если что-то произошло",
                [
                    ("prediction-door", "prediction", 20),
                    ("prediction-low-energy", "prediction", 20),
                    ("fix-rain-condition", "fix_logic", 20),
                    ("reorder-first-if", "reorder", 25),
                ],
            ),
            (
                "lesson-2",
                2,
                "Два пути",
                [
                    ("fix-energy", "fix_logic", 25),
                    ("prediction-temperature", "prediction", 25),
                    ("prediction-access", "prediction", 25),
                    ("prediction-energy-boundary", "prediction", 25),
                ],
            ),
            (
                "lesson-3",
                3,
                "Сравниваем значения",
                [
                    ("prediction-score-threshold", "prediction", 25),
                    ("bug-equality-operator", "bug_hunt", 30),
                    ("prediction-not-equal", "prediction", 25),
                    ("prediction-temperature-limit", "prediction", 25),
                ],
            ),
            (
                "lesson-4",
                4,
                "Несколько условий",
                [
                    ("prediction-and-launch", "prediction", 30),
                    ("prediction-or-alarm", "prediction", 30),
                    ("reorder-elif-chain", "reorder", 30),
                    ("bug-access-and", "bug_hunt", 30),
                ],
            ),
        ],
    },
    {
        "id": "loops",
        "title": "Циклы и автоматизация",
        "description": "for, while, break и continue на Python.",
        "lessons": [
            (
                "lesson-5",
                5,
                "Повтори это",
                [
                    ("prediction-three-steps", "prediction", 25),
                    ("reorder-loop", "reorder", 25),
                    ("fix-loop-count", "bug_hunt", 25),
                    ("prediction-range-bounds", "prediction", 25),
                ],
            ),
            (
                "lesson-6",
                6,
                "Пока условие истинно",
                [
                    ("prediction-while-countdown", "prediction", 25),
                    ("bug-infinite-while", "bug_hunt", 30),
                    ("reorder-while", "reorder", 30),
                    ("prediction-while-zero", "prediction", 25),
                ],
            ),
            (
                "lesson-7",
                7,
                "Остановить или пропустить",
                [
                    ("prediction-break-search", "prediction", 25),
                    ("prediction-continue-empty", "prediction", 25),
                    ("bug-wrong-loop-control", "bug_hunt", 30),
                    ("prediction-continue-flow", "prediction", 30),
                ],
            ),
            (
                "lesson-8",
                8,
                "Автопилот",
                [
                    ("prediction-autopilot", "prediction", 30),
                    ("reorder-autopilot", "reorder", 30),
                    ("prediction-safe-route", "prediction", 30),
                    ("prediction-mixed-route", "prediction", 35),
                ],
            ),
        ],
    },
]


def module_summaries() -> list[ModuleSummary]:
    return [
        ModuleSummary(
            id=module["id"],
            title=module["title"],
            description=module["description"],
            lesson_count=len(module["lessons"]),
        )
        for module in _MODULES
    ]


def module_detail(module_id: str) -> ModuleRead | None:
    module = next((item for item in _MODULES if item["id"] == module_id), None)
    if module is None:
        return None
    lessons = [
        LessonRead(
            id=lesson_id,
            module_id=module_id,
            order_index=order,
            title=title,
            exercises=[
                ExerciseRead(
                    id=exercise_id,
                    lesson_id=lesson_id,
                    type=exercise_type,
                    payload={"source": "mobile/assets/content/module.json"},
                    xp_reward=xp,
                )
                for exercise_id, exercise_type, xp in exercises
            ],
        )
        for lesson_id, order, title, exercises in module["lessons"]
    ]
    return ModuleRead(
        id=module["id"],
        title=module["title"],
        description=module["description"],
        lesson_count=len(lessons),
        lessons=lessons,
    )


def lesson_detail(lesson_id: str) -> LessonRead | None:
    for summary in module_summaries():
        detail = module_detail(summary.id)
        if detail is not None:
            lesson = next((item for item in detail.lessons if item.id == lesson_id), None)
            if lesson is not None:
                return lesson
    return None
