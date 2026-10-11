from fastapi import APIRouter, HTTPException

from app.schemas import LessonRead
from app.services.content_service import lesson_detail

router = APIRouter(prefix="/lessons", tags=["lessons"])


@router.get("/{lesson_id}", response_model=LessonRead)
async def get_lesson(lesson_id: str) -> LessonRead:
    lesson = lesson_detail(lesson_id)
    if lesson is None:
        raise HTTPException(status_code=404, detail="Lesson not found")
    return lesson
