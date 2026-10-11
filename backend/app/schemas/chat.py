import uuid
from typing import Literal

from pydantic import BaseModel, Field


class ChatHistoryMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=1200)


class ChatRequest(BaseModel):
    installation_id: uuid.UUID
    lesson_id: str = Field(max_length=64)
    exercise_id: str = Field(max_length=64)
    attempts: int = Field(default=0, ge=0, le=100)
    hints_used: int = Field(default=0, ge=0, le=3)
    message: str = Field(min_length=1, max_length=500)
    history: list[ChatHistoryMessage] = Field(default_factory=list, max_length=12)
    module_title: str | None = Field(default=None, max_length=160)
    lesson_title: str | None = Field(default=None, max_length=160)
    lesson_summary: str | None = Field(default=None, max_length=1200)
    exercise_prompt: str | None = Field(default=None, max_length=600)
    current_code: list[str] = Field(default_factory=list, max_length=20)


class ChatResponse(BaseModel):
    reply: str
