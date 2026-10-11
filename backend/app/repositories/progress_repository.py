import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Installation, Progress
from app.schemas.progress import ProgressItem


async def ensure_installation(session: AsyncSession, installation_id: uuid.UUID) -> None:
    if await session.get(Installation, installation_id) is None:
        session.add(Installation(id=installation_id))
        await session.flush()


async def get_progress(session: AsyncSession, installation_id: uuid.UUID) -> list[Progress]:
    result = await session.scalars(
        select(Progress).where(Progress.installation_id == installation_id).order_by(Progress.lesson_id)
    )
    return list(result)


async def upsert_progress(
    session: AsyncSession, installation_id: uuid.UUID, items: list[ProgressItem]
) -> list[Progress]:
    await ensure_installation(session, installation_id)
    existing = {
        item.lesson_id: item for item in await get_progress(session, installation_id)
    }
    for payload in items:
        record = existing.get(payload.lesson_id)
        if record is None:
            session.add(
                Progress(
                    installation_id=installation_id,
                    lesson_id=payload.lesson_id,
                    status=payload.status,
                    score=payload.score,
                )
            )
        else:
            record.status = payload.status
            record.score = payload.score
    await session.commit()
    return await get_progress(session, installation_id)
