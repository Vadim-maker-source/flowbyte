import json
import time
import uuid
from urllib.parse import parse_qs

import httpx
import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings, get_settings
from app.main import app
from app.schemas.chat import ChatRequest
from app.services import chat_service


def test_health(client: TestClient) -> None:
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_module_and_lesson(client: TestClient) -> None:
    modules = client.get("/api/v1/modules")
    assert modules.status_code == 200
    assert len(modules.json()) == 2
    assert modules.json()[0]["lesson_count"] == 4

    loops = client.get("/api/v1/modules/loops")
    assert loops.status_code == 200
    assert loops.json()["lessons"][-1]["id"] == "lesson-8"

    lesson = client.get("/api/v1/lessons/lesson-2")
    assert lesson.status_code == 200
    assert len(lesson.json()["exercises"]) == 4
    assert lesson.json()["exercises"][0]["type"] == "fix_logic"


def test_attempt_and_validation(client: TestClient) -> None:
    installation_id = str(uuid.uuid4())
    response = client.post(
        "/api/v1/attempts",
        json={
            "installation_id": installation_id,
            "exercise_id": "prediction-door",
            "correct": True,
            "hints_used": 1,
        },
    )
    assert response.status_code == 201
    assert response.json()["correct"] is True

    invalid = client.post(
        "/api/v1/attempts",
        json={
            "installation_id": installation_id,
            "exercise_id": "prediction-door",
            "correct": False,
            "hints_used": 9,
        },
    )
    assert invalid.status_code == 422


def test_progress_round_trip(client: TestClient) -> None:
    installation_id = str(uuid.uuid4())
    update = client.put(
        f"/api/v1/progress/{installation_id}",
        json={"items": [{"lesson_id": "lesson-1", "status": "completed", "score": 100}]},
    )
    assert update.status_code == 200
    assert update.json()["items"][0]["status"] == "completed"

    read = client.get(f"/api/v1/progress/{installation_id}")
    assert read.status_code == 200
    assert read.json()["items"][0]["score"] == 100


@pytest.fixture(autouse=True)
def reset_gigachat_token_cache() -> None:
    chat_service._cached_token = None
    chat_service._cached_key_hash = None
    chat_service._token_valid_until = 0.0


def _chat_payload(message: str = "Почему else?") -> dict:
    return {
        "installation_id": str(uuid.uuid4()),
        "lesson_id": "lesson-2",
        "exercise_id": "fix-energy",
        "attempts": 1,
        "hints_used": 0,
        "message": message,
    }


def test_chat_is_optional_without_gigachat_key(client: TestClient) -> None:
    app.dependency_overrides[get_settings] = lambda: Settings(
        gigachat_auth_key=None,
        _env_file=None,
    )
    try:
        response = client.post("/api/v1/chat", json=_chat_payload())
    finally:
        app.dependency_overrides.pop(get_settings, None)
    assert response.status_code == 503
    assert "Local lesson hints" in response.json()["detail"]


@pytest.mark.asyncio
async def test_gigachat_tutor_uses_oauth_and_server_side_course_context(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    requests: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        if request.url.path.endswith("/oauth"):
            return httpx.Response(
                200,
                json={"access_token": "test-access-token", "expires_at": int(time.time() + 1800)},
            )
        return httpx.Response(
            200,
            json={"choices": [{"message": {"content": "Сначала проверь условие."}}]},
        )

    real_async_client = httpx.AsyncClient
    monkeypatch.setattr(
        chat_service.httpx,
        "AsyncClient",
        lambda **kwargs: real_async_client(transport=httpx.MockTransport(handler), **kwargs),
    )
    reply = await chat_service.explain(
        ChatRequest(
            installation_id=uuid.uuid4(),
            lesson_id="lesson-6",
            exercise_id="bug-infinite-while",
            attempts=2,
            hints_used=1,
            message="Почему цикл не заканчивается?",
            history=[
                {"role": "user", "content": "Что делает while?"},
                {"role": "assistant", "content": "while повторяет блок, пока условие истинно."},
            ],
        ),
        Settings(gigachat_auth_key="test-base64-key", _env_file=None),
    )

    assert reply == "Сначала проверь условие."
    assert len(requests) == 2
    oauth, completion = requests
    assert str(oauth.url) == "https://ngw.devices.sberbank.ru:9443/api/v2/oauth"
    assert oauth.headers["Authorization"] == "Basic test-base64-key"
    assert uuid.UUID(oauth.headers["RqUID"]).version == 4
    assert parse_qs(oauth.content.decode()) == {"scope": ["GIGACHAT_API_PERS"]}
    assert str(completion.url) == "https://api.giga.chat/v1/chat/completions"
    assert completion.headers["Authorization"] == "Bearer test-access-token"
    data = json.loads(completion.content)
    assert data["model"] == "GigaChat-2-Pro"
    assert "lesson-6" in data["messages"][0]["content"]
    assert data["messages"][1] == {"role": "user", "content": "Что делает while?"}
    assert data["messages"][-1]["content"] == "Почему цикл не заканчивается?"
    assert "не уклоняйся" in data["messages"][0]["content"]
    assert 'a = int(input("Первое число: "))' in data["messages"][0]["content"]
    assert "test-base64-key" not in completion.content.decode()


@pytest.mark.asyncio
async def test_gigachat_reuses_token_between_messages(monkeypatch: pytest.MonkeyPatch) -> None:
    oauth_calls = 0
    completion_calls = 0

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal oauth_calls, completion_calls
        if request.url.path.endswith("/oauth"):
            oauth_calls += 1
            return httpx.Response(200, json={"access_token": "shared-token"})
        completion_calls += 1
        assert request.headers["Authorization"] == "Bearer shared-token"
        return httpx.Response(200, json={"choices": [{"message": {"content": "OK"}}]})

    real_async_client = httpx.AsyncClient
    monkeypatch.setattr(chat_service.httpx, "AsyncClient", lambda **kwargs: real_async_client(
        transport=httpx.MockTransport(handler), **kwargs
    ))
    settings = Settings(gigachat_auth_key="key", _env_file=None)
    request = ChatRequest(**_chat_payload())
    assert await chat_service.explain(request, settings) == "OK"
    assert await chat_service.explain(request, settings) == "OK"
    assert oauth_calls == 1
    assert completion_calls == 2


@pytest.mark.asyncio
async def test_gigachat_refreshes_token_after_chat_401(monkeypatch: pytest.MonkeyPatch) -> None:
    oauth_calls = 0
    completion_auth: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal oauth_calls
        if request.url.path.endswith("/oauth"):
            oauth_calls += 1
            return httpx.Response(200, json={"access_token": f"token-{oauth_calls}"})
        completion_auth.append(request.headers["Authorization"])
        if completion_auth[-1] == "Bearer token-1":
            return httpx.Response(401, json={"message": "Token expired"})
        return httpx.Response(200, json={"choices": [{"message": {"content": "Обновлено"}}]})

    real_async_client = httpx.AsyncClient
    monkeypatch.setattr(chat_service.httpx, "AsyncClient", lambda **kwargs: real_async_client(
        transport=httpx.MockTransport(handler), **kwargs
    ))
    reply = await chat_service.explain(
        ChatRequest(**_chat_payload()), Settings(gigachat_auth_key="key", _env_file=None)
    )
    assert reply == "Обновлено"
    assert oauth_calls == 2
    assert completion_auth == ["Bearer token-1", "Bearer token-2"]


@pytest.mark.asyncio
async def test_gigachat_auth_failure_is_assistant_unavailable(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/oauth")
        return httpx.Response(401, json={"error": "invalid credentials"})

    real_async_client = httpx.AsyncClient
    monkeypatch.setattr(chat_service.httpx, "AsyncClient", lambda **kwargs: real_async_client(
        transport=httpx.MockTransport(handler), **kwargs
    ))
    with pytest.raises(chat_service.AssistantUnavailableError):
        await chat_service.explain(
            ChatRequest(**_chat_payload()), Settings(gigachat_auth_key="invalid", _env_file=None)
        )


@pytest.mark.asyncio
async def test_comparison_fallback_remains_offline() -> None:
    reply = await chat_service.explain(
        ChatRequest(
            installation_id=uuid.uuid4(),
            lesson_id="lesson-3",
            exercise_id="theory-conditions",
            message="Считай два целых числа с клавиатуры и сравни, какое больше",
        ),
        Settings(gigachat_auth_key=None, _env_file=None),
    )
    for token in ("```python", "input(", "int(", "if ", "elif ", "else:"):
        assert token in reply


def test_chat_endpoint_returns_gigachat_reply_to_flutter(
    monkeypatch: pytest.MonkeyPatch, client: TestClient,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path.endswith("/oauth"):
            return httpx.Response(200, json={"access_token": "a-token"})
        assert request.url.path.endswith("/chat/completions")
        return httpx.Response(200, json={
            "choices": [{"message": {"content": "Это ветка else."}}]
        })

    real_async_client = httpx.AsyncClient
    monkeypatch.setattr(chat_service.httpx, "AsyncClient", lambda **kwargs: real_async_client(
        transport=httpx.MockTransport(handler), **kwargs
    ))
    app.dependency_overrides[get_settings] = lambda: Settings(
        gigachat_auth_key="test-server-only-secret", _env_file=None
    )
    try:
        response = client.post("/api/v1/chat", json=_chat_payload())
    finally:
        app.dependency_overrides.pop(get_settings, None)
    assert response.status_code == 200
    assert response.json() == {"reply": "Это ветка else."}
