# FLOWBYTE architecture

## Mobile

Flutter is feature-oriented and local-first:

```text
UI widgets
  ↓ intent / watched state
Riverpod controllers
  ↓
repositories
  ├─ local module JSON
  ├─ SharedPreferences progress
  └─ optional Dio API
```

- `ContentRepository` parses `assets/content/module.json` into a data-driven route with eight lessons, four exercises per lesson, and deterministic trace models.
- `ExerciseController` owns choice, order, scoring, retry, and hint progression.
- `LiveTraceController` plays safe enumerated steps; it never evaluates arbitrary source code.
- `ProgressController` owns onboarding, XP, levels, attempts, used hints, lesson unlocks, final completion, and local persistence.
- UI updates optimistically before any sync. Backend/AI failure cannot block the educational route.

Routing uses `go_router` with short fade/translate transitions. Design primitives live in `core/theme`; shared code blocks, Byte, buttons, press feedback, and trace stage live in `shared/widgets`.

## Backend

FastAPI separates HTTP routes, Pydantic schemas, services, repositories, and SQLAlchemy models. The application uses an async engine and creates the minimal schema on startup. PostgreSQL is the Compose runtime; SQLite is used only by the isolated backend test suite.

```text
route → schema validation → service/repository → SQLAlchemy async session → PostgreSQL
```

Required tables: `installations`, `modules`, `lessons`, `exercises`, `progress`, and `attempts`.

## Offline and sync

Required content and completion live on the device. The server stores optional sync/analytics records. A failed sync should be retried later and surfaced as “Прогресс сохранён на устройстве,” never as lost work or a blocking loader.

## Security

- Anonymous installation UUID only; no account or personal data.
- No arbitrary code execution.
- No LLM secret in Flutter.
- Local secrets live in ignored `.env` files.
- `.env.example` contains placeholders only.
