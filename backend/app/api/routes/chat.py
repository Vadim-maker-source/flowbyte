from fastapi import APIRouter, Depends, HTTPException, status

from app.core.config import Settings, get_settings
from app.schemas import ChatRequest, ChatResponse
from app.services.chat_service import AssistantUnavailableError, explain

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("", response_model=ChatResponse)
async def chat(payload: ChatRequest, settings: Settings = Depends(get_settings)) -> ChatResponse:
    try:
        return ChatResponse(reply=await explain(payload, settings))
    except AssistantUnavailableError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Byte Assistant is currently unavailable. Local lesson hints still work.",
        ) from error
