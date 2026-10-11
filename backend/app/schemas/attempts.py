import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class AttemptCreate(BaseModel):
    installation_id: uuid.UUID
    exercise_id: str = Field(min_length=1, max_length=64)
    correct: bool
    hints_used: int = Field(default=0, ge=0, le=3)


class AttemptRead(AttemptCreate):
    id: int
    created_at: datetime
