import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_session
from app.repositories import get_progress, upsert_progress
from app.schemas import ProgressEnvelope, ProgressRead, ProgressUpdate

router = APIRouter(prefix="/progress", tags=["progress"])


def _envelope(installation_id: uuid.UUID, records: list) -> ProgressEnvelope:
    return ProgressEnvelope(
        installation_id=installation_id,
        items=[
            ProgressRead(
                lesson_id=record.lesson_id,
                status=record.status,
                score=record.score,
                updated_at=record.updated_at,
            )
            for record in records
        ],
    )


@router.get("/{installation_id}", response_model=ProgressEnvelope)
async def read_progress(
    installation_id: uuid.UUID, session: AsyncSession = Depends(get_session)
) -> ProgressEnvelope:
    return _envelope(installation_id, await get_progress(session, installation_id))


@router.put("/{installation_id}", response_model=ProgressEnvelope)
async def update_progress(
    installation_id: uuid.UUID,
    payload: ProgressUpdate,
    session: AsyncSession = Depends(get_session),
) -> ProgressEnvelope:
    records = await upsert_progress(session, installation_id, payload.items)
    return _envelope(installation_id, records)
