# FLOWBYTE engineering contract

## Product scope

Build and maintain the registration-free Android learning route defined in `design/context.md` and `docs/DESIGN.md`: onboarding, four lessons, data-driven exercises, deterministic Live Trace, XP/Byte levels, final mission, completion, replay, persistence, and an optional helper.

Non-goals are authentication, admin, social/multiplayer, leaderboards, purchases, subscriptions, and arbitrary code execution.

## Source of truth

1. Hackathon/master brief.
2. `design/final/flowbyte-screen-board.png` for visual intent.
3. `docs/DESIGN.md` for exact implementation decisions.
4. Theme/design tokens.
5. UX and content models.

Do not improvise colors, radii, spacing, hierarchy, component dimensions, or motion inside feature widgets. Change the specification and token first when an intentional design change is approved.

## Architecture boundaries

- `mobile/lib/core`: theme, icons, storage, networking, general utilities only.
- `mobile/lib/shared`: reusable presentation primitives and animations only.
- `mobile/lib/features`: feature controllers, domain state, and screens.
- `mobile/lib/data`: models, local/remote sources, repository implementations.
- Widgets render state and emit intent; answer checking, XP, unlocking, hints, persistence, and trace construction live outside widgets.
- Riverpod is the state-management boundary; repositories are injected.
- `assets/content/module.json` is the required educational content source.

## Local-first rule

Home, lessons, all required exercises, final mission, progress display, and completion must work without network. Persist progress locally first and sync opportunistically. Network failure must not roll back local success or block navigation.

## Live Trace safety

Never execute arbitrary user code. Convert the limited exercise model to deterministic steps (`checkCondition`, `move`, `turn`, `charge`, `loopStart`, `loopIteration`, `loopEnd`) or load a predeclared trace. UI plays those steps; it does not evaluate general Python/Dart.

## API-key rule

The mobile application never contains or calls an LLM provider key. Flutter calls `POST /api/v1/chat`; FastAPI owns provider integration through environment variables. Do not commit `.env` or secrets. The assistant is optional and must fail gracefully.

## Testing requirements

- Unit: scoring, lesson unlock, XP/level, progress, hint progression, trace sequence.
- Widget: Welcome, Home, Lesson, Exercise, success/error feedback.
- Integration: Welcome → lessons 1–4 → final → completion.
- Backend: health, content, progress, attempts, validation.
- Run static analysis and tests before handoff.
- Screenshot key screens at 393 × 852 and compare hierarchy, type, spacing, radius, color, icons, and control heights to the locked design.

## Code style

- Prefer `const` widgets and small rebuild scopes.
- Use `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppMotion`, and icon abstractions; do not hardcode visual values in feature widgets.
- No emoji for UI icons.
- User-visible errors are short Russian copy, never raw exceptions.
- Keep motion purposeful and under the defined timings.
- Core route contains no TODO, placeholder, or dead action.

## Repository shape

```text
mobile/       Flutter application
backend/      FastAPI application and tests
assets/       local module content and project-owned visuals
design/       context, exploration, and frozen boards
docs/         product/design/API/architecture/AI contracts
docker-compose.yml
README.md
```
