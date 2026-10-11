# FLOWBYTE AI Tutor — GigaChat

The Flutter UI calls the existing `POST /api/v1/chat` endpoint. No secrets are
stored in Flutter, the APK, or the HTTP request sent by the device. The FastAPI
server calls **GigaChat API** and returns `{ "reply": "..." }` to Flutter.

## Setup (Docker Compose)

1. Copy `.env.example` to the root `.env` file.
2. Add your **private** `GIGACHAT_AUTH_KEY` (the Base64-encoded Client ID and
   Client Secret from GigaChat Studio). Do not add the `Basic ` prefix to this
   variable. Set a real `POSTGRES_PASSWORD`.
3. Run `docker compose up -d --build`, then check
   `http://localhost:2345/api/v1/health`.

The root `.env` is ignored by Git. **Never place credentials in a Dart file**, a
public repository, a screenshot or a release APK. Treat ZIPs containing `.env`
as sensitive too. If you shared the key publicly, regenerate it in Studio.

For local Python development without Docker, copy `backend/.env.example` to
`backend/.env` and add `GIGACHAT_AUTH_KEY` there, then start Uvicorn from
`backend/`.

## Backend configuration

| Variable | Default | Description |
|---|---|---|
| `GIGACHAT_AUTH_KEY` | empty | Secret Base64 Authorization Key (required) |
| `GIGACHAT_SCOPE` | `GIGACHAT_API_PERS` | Personal account scope |
| `GIGACHAT_MODEL` | `GigaChat-2-Pro` | Main model for Python explanations and code |
| `GIGACHAT_BASE_URL` | `https://api.giga.chat/v1` | Current API endpoint |
| `GIGACHAT_OAUTH_URL` | `https://ngw.devices.sberbank.ru:9443/api/v2/oauth` | OAuth endpoint |
| `GIGACHAT_CA_BUNDLE` | empty | Optional CA bundle path on the backend host or inside the container |
| `ASSISTANT_TIMEOUT_SECONDS` | `45` | Network timeout |

GigaChat API uses a two-step authorization flow:

1. `POST /api/v2/oauth` with `Authorization: Basic <Authorization Key>`, a new
   `RqUID` UUID4, and form data `scope=GIGACHAT_API_PERS`.
2. `POST /v1/chat/completions` with `Authorization: Bearer <access_token>` and
   the current conversation, system prompt and lesson context.

The server reuses the access token until shortly before it expires (~30 minutes),
refreshes it automatically and retries once with a new token on a `401` from
the chat endpoint. TLS certificate validation is **on**. If your system does
not trust the certificate authority GigaChat uses, install the official trusted
root certificates (including those of the Russian Ministry of Digital
Development), or provide a trusted PEM certificate bundle using
`GIGACHAT_CA_BUNDLE`. For Docker, mount that file into the API container and
set `GIGACHAT_CA_BUNDLE` to its path inside the container. Do not disable TLS
certificate validation in production.

## Error handling and prompt

The assistant includes the last 12 messages, lesson and module titles, exercise
prompt, code, attempts and hint counts. The server keeps the FLOWBYTE Byte
persona, explanations and short Python examples. It does not send the
installation UUID to GigaChat (only the educational context and message).

Missing or invalid credentials, unavailable quotas/models, network timeouts,
malformed responses and SSL issues cause `/chat` to return HTTP `503` without
exposing secrets or upstream responses. The Flutter assistant shows its existing
retry/offline state; local lessons and hints are unaffected. The deterministic
two-number comparison answer still works without external AI.

Official API reference:
- https://developers.sber.ru/docs/ru/gigachat/api/reference/rest/gigachat-api
- https://developers.sber.ru/docs/ru/gigachat/api/reference/rest/post-chat
