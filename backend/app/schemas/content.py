from typing import Any

from pydantic import BaseModel


class ExerciseRead(BaseModel):
    id: str
    lesson_id: str
    type: str
    payload: dict[str, Any]
    xp_reward: int


class LessonRead(BaseModel):
    id: str
    module_id: str
    order_index: int
    title: str
    exercises: list[ExerciseRead]


class ModuleSummary(BaseModel):
    id: str
    title: str
    description: str
    lesson_count: int


class ModuleRead(ModuleSummary):
    lessons: list[LessonRead]
