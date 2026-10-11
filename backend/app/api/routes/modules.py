from fastapi import APIRouter, HTTPException

from app.schemas import ModuleRead, ModuleSummary
from app.services.content_service import module_detail, module_summaries

router = APIRouter(prefix="/modules", tags=["modules"])


@router.get("", response_model=list[ModuleSummary])
async def list_modules() -> list[ModuleSummary]:
    return module_summaries()


@router.get("/{module_id}", response_model=ModuleRead)
async def get_module(module_id: str) -> ModuleRead:
    module = module_detail(module_id)
    if module is None:
        raise HTTPException(status_code=404, detail="Module not found")
    return module
