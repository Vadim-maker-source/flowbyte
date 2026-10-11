import asyncio
import hashlib
import logging
import time
import uuid

import httpx

from app.core.config import Settings
from app.schemas.chat import ChatRequest


class AssistantUnavailableError(RuntimeError):
    pass


logger = logging.getLogger(__name__)

_SYSTEM_PROMPT = """Ты Byte — встроенный ИИ-наставник приложения FLOWBYTE для
подростков 12–17 лет. FLOWBYTE — локальный Android-курс в стиле космического центра
управления: ученик помогает роботу Byte восстановить станцию Helios, изучает Python,
решает миссии, видит пошаговую Live Trace, получает XP и сертификаты модулей.

Курс состоит из двух модулей и восьми уроков:
1 — основы if; 2 — if/else; 3 — сравнения >, <, ==, !=; 4 — elif, and, or, not;
5 — for и range; 6 — while; 7 — break и continue; 8 — условия внутри циклов.

Отвечай по-русски, дружелюбно, конкретно и простыми словами. Сначала дай прямой
ответ на вопрос, затем объясни причину и при необходимости покажи короткий пример.
Учитывай весь диалог, точное название урока, теорию, код и формулировку упражнения,
которые передал клиент. Не меняй тему и не спрашивай то, что уже есть в контексте.
Если ученик прямо просит написать, исправить или показать код — сразу дай минимальный
рабочий код; не уклоняйся и не заменяй ответ наводящим вопросом. Наводящий вопрос
уместен только если ученик сам просит подсказку без готового ответа.

Для сравнения двух введённых чисел обязательно учитывай три случая: первое больше,
второе больше, числа равны. Если в вопросе сказано «считать», «ввести» или
«с клавиатуры», используй input(). Для целых чисел начинай буквально так:
`a = int(input("Первое число: "))` и `b = int(input("Второе число: "))`,
затем используй if/elif/else.

Не выдумывай функции FLOWBYTE там, где нужен обычный Python. Не проси персональные
данные и не утверждай, что запускал код. Любой код помещай только в блок
```python ... ```. После кода объясни ключевые строки. Ответ обычно до 120 слов,
без markdown-таблиц."""

_LESSON_CONTEXT = {
    "lesson-1": "Основы if: логическое условие, двоеточие и блок кода с отступом.",
    "lesson-2": "Два пути: if/else, граничные значения и выбор ровно одной ветки.",
    "lesson-3": "Сравнения: >, <, >=, <=, == и !=; отличие сравнения от присваивания.",
    "lesson-4": "Несколько условий: elif, and, or и not; первая истинная ветка.",
    "lesson-5": "Цикл for и range(start, stop) для известного числа повторов.",
    "lesson-6": "Цикл while, изменение состояния и защита от бесконечного цикла.",
    "lesson-7": "break останавливает цикл, continue пропускает одну итерацию.",
    "lesson-8": "Условия внутри циклов и пошаговая трассировка автопилота Byte.",
}

_TWO_NUMBER_COMPARISON = """Вот минимальный рабочий вариант:

```python
first = int(input("Первое число: "))
second = int(input("Второе число: "))

if first > second:
    print("Первое число больше")
elif first < second:
    print("Второе число больше")
else:
    print("Числа равны")
```

`input()` считывает текст с клавиатуры, а `int()` превращает его в целое число.
`if` проверяет первый вариант, `elif` — второй, `else` обрабатывает равенство."""

def _is_two_number_input_comparison(message: str) -> bool:
    text = message.casefold()
    asks_for_two_values = any(
        form in text for form in ("два", "две", "двух", "двум")
    ) and any(word in text for word in ("числ", "перемен", "значен"))
    asks_for_comparison = any(word in text for word in ("сравн", "больш", "меньш"))
    asks_for_input = any(word in text for word in ("счит", "ввод", "клавиатур", "input"))
    return asks_for_two_values and asks_for_comparison and asks_for_input


def _course_context(request: ChatRequest) -> str:
    fallback = _LESSON_CONTEXT.get(
        request.lesson_id,
        "Общий маршрут курса Python: условия и циклы.",
    )
    lines = [
        "Контекст текущего экрана FLOWBYTE:",
        f"Урок: {request.lesson_id} — {request.lesson_title or fallback}",
        f"Модуль: {request.module_title or 'курс Python'}",
        f"Раздел/задание: {request.exercise_id}",
        f"Попыток ученика: {request.attempts}; подсказок: {request.hints_used}",
    ]
    if request.lesson_summary:
        lines.append(f"Теория урока: {request.lesson_summary}")
    if request.exercise_prompt:
        lines.append(f"Формулировка упражнения: {request.exercise_prompt}")
    if request.current_code:
        lines.append("Код на экране:\n```python\n" + "\n".join(request.current_code) + "\n```")
    return "\n".join(lines)


def _messages(request: ChatRequest) -> list[dict[str, str]]:
    history = [
        {"role": item.role, "content": item.content}
        for item in request.history[-12:]
    ]
    return [
        # GigaChat accepts a single system message, so the stable tutor rules
        # and the current lesson context must be combined into that message.
        {
            "role": "system",
            "content": f"{_SYSTEM_PROMPT}\n\n{_course_context(request)}",
        },
        *history,
        {"role": "user", "content": request.message},
    ]


# Share the OAuth token between requests, refreshing it before expiration.
# This cache is per API worker, and never exposed to Flutter.
_token_lock = asyncio.Lock()
_cached_token: str | None = None
_cached_key_hash: str | None = None
_token_valid_until = 0.0


async def _access_token(client: httpx.AsyncClient, settings: Settings) -> str:
    global _cached_token, _cached_key_hash, _token_valid_until

    auth_key = (settings.gigachat_auth_key or "").strip()
    if not auth_key:
        raise AssistantUnavailableError("GigaChat authorization key is not configured")
    if auth_key.lower().startswith("basic "):
        auth_key = auth_key[6:].strip()

    key_hash = hashlib.sha256((auth_key + ":" + settings.gigachat_scope).encode()).hexdigest()
    async with _token_lock:
        if (
            _cached_token is not None
            and _cached_key_hash == key_hash
            and time.monotonic() < _token_valid_until
        ):
            return _cached_token

        response = await client.post(
            settings.gigachat_oauth_url,
            headers={
                "Authorization": f"Basic {auth_key}",
                "RqUID": str(uuid.uuid4()),
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
            },
            data={"scope": settings.gigachat_scope},
        )
        response.raise_for_status()
        result = response.json()
        token = result["access_token"]
        if not isinstance(token, str) or not token.strip():
            raise ValueError("GigaChat OAuth returned an invalid access token")

        # GigaChat tokens are valid for 30 minutes. Support either seconds or
        # milliseconds for expires_at, and refresh one minute early.
        ttl = 29 * 60.0
        expiry = result.get("expires_at")
        if isinstance(expiry, (int, float)) and not isinstance(expiry, bool):
            expiry_seconds = expiry / 1000 if expiry > 1e11 else expiry
            ttl = max(0.0, min(ttl, expiry_seconds - time.time() - 60))

        _cached_token = token
        _cached_key_hash = key_hash
        _token_valid_until = time.monotonic() + ttl
        return token


async def _gigachat_reply(request: ChatRequest, settings: Settings) -> str:
    if not settings.gigachat_auth_key or not settings.gigachat_auth_key.strip():
        raise AssistantUnavailableError("GigaChat authorization key is not configured")

    payload = {
        "model": settings.gigachat_model,
        "messages": _messages(request),
        "temperature": 0.15,
        "max_tokens": 520,
        "stream": False,
    }
    url = f"{settings.gigachat_base_url.rstrip('/')}/chat/completions"
    async with httpx.AsyncClient(
        timeout=settings.assistant_timeout_seconds,
        verify=settings.gigachat_ca_bundle or True,
    ) as client:
        token = await _access_token(client, settings)
        response = await client.post(
            url,
            headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
            json=payload,
        )
        if response.status_code == 401:
            # Revoke only the token we actually used, in case another request
            # refreshed the shared token while this one was in flight.
            global _cached_token, _token_valid_until
            async with _token_lock:
                if _cached_token == token:
                    _cached_token = None
                    _token_valid_until = 0.0
            token = await _access_token(client, settings)
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
                json=payload,
            )
        response.raise_for_status()
        answer = response.json()["choices"][0]["message"]["content"]
        if not isinstance(answer, str) or not answer.strip():
            raise ValueError("GigaChat returned an empty reply")
        return answer.strip()


async def explain(request: ChatRequest, settings: Settings) -> str:
    if _is_two_number_input_comparison(request.message):
        return _TWO_NUMBER_COMPARISON

    try:
        return await _gigachat_reply(request, settings)
    except AssistantUnavailableError:
        raise
    except (httpx.HTTPError, KeyError, IndexError, TypeError, ValueError) as error:
        # Do not leak provider errors, authorization data or raw responses to users.
        logger.warning("GigaChat request failed: %s", type(error).__name__)
        raise AssistantUnavailableError("GigaChat is currently unavailable") from error
