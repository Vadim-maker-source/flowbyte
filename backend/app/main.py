from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import attempts, chat, health, lessons, modules, progress
from app.core.config import get_settings
from app.db.models import Base
from app.db.session import engine


@asynccontextmanager
async def lifespan(_: FastAPI):
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    yield


settings = get_settings()
app = FastAPI(title=settings.app_name, version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT"],
    allow_headers=["Content-Type"],
)

prefix = "/api/v1"
app.include_router(health.router, prefix=prefix)
app.include_router(modules.router, prefix=prefix)
app.include_router(lessons.router, prefix=prefix)
app.include_router(attempts.router, prefix=prefix)
app.include_router(progress.router, prefix=prefix)
app.include_router(chat.router, prefix=prefix)
