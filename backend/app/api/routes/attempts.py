from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Attempt
from app.db.session import get_session
from app.repositories import ensure_installation
from app.schemas import AttemptCreate, AttemptRead

router = APIRouter(prefix="/attempts", tags=["attempts"])


@router.post("", response_model=AttemptRead, status_code=status.HTTP_201_CREATED)
async def create_attempt(payload: AttemptCreate, session: AsyncSession = Depends(get_session)) -> Attempt:
    await ensure_installation(session, payload.installation_id)
    attempt = Attempt(**payload.model_dump())
    session.add(attempt)
    await session.commit()
    await session.refresh(attempt)
    return attempt
