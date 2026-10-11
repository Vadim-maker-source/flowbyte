import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class ProgressItem(BaseModel):
    lesson_id: str = Field(min_length=1, max_length=64)
    status: str = Field(pattern="^(available|active|completed)$")
    score: int = Field(ge=0, le=100)


class ProgressUpdate(BaseModel):
    items: list[ProgressItem] = Field(max_length=20)


class ProgressRead(ProgressItem):
    updated_at: datetime


class ProgressEnvelope(BaseModel):
    installation_id: uuid.UUID
    items: list[ProgressRead]
