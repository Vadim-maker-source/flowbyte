# FLOWBYTE API

Base URL: `http://localhost:2345/api/v1` for the included Docker Compose setup. For a release build, provide the private deployment address through `FLOWBYTE_API_URL`; deployment addresses are not committed.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | service health |
| GET | `/modules` | module summaries |
| GET | `/modules/{id}` | module with lessons |
| GET | `/lessons/{id}` | lesson metadata and three exercise summaries |
| POST | `/attempts` | record one exercise attempt |
| GET | `/progress/{installation_id}` | read remote progress |
| PUT | `/progress/{installation_id}` | idempotently upsert lesson progress |
| POST | `/chat` | optional Byte Assistant |

## Attempts

```json
POST /api/v1/attempts
{
  "installation_id": "c09c6466-3ee0-4a0e-80af-138195942d42",
  "exercise_id": "fix-energy",
  "correct": false,
  "hints_used": 1
}
```

Returns `201`. `hints_used` accepts 0–3; invalid payloads return `422`.

## Progress

```json
PUT /api/v1/progress/{installation_id}
{
  "items": [
    {"lesson_id": "lesson-1", "status": "completed", "score": 100}
  ]
}
```

Statuses: `available`, `active`, `completed`. Local mobile progress remains authoritative for immediate UX; remote sync is opportunistic.

## Assistant

`POST /chat` accepts installation, lesson/exercise context, attempts, hints used, and a message. When no GigaChat Authorization Key is configured the endpoint returns `503`; the mobile client then displays the specified offline message and keeps local lesson hints available. Provider keys never enter Flutter.
