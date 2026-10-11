# FLOWBYTE — Product context

goal: Ship a polished Android learning prototype that helps a first-time programmer understand that programs make decisions (`if / else`) and repeat actions (loops) by immediately showing how code changes Byte's behavior.

user: Teenagers aged 12–17 with little or no programming experience. They are comfortable with modern mobile products, impatient with long theory, and sensitive to slow or dated interfaces.

JTBD: In one short, registration-free session, teach Byte to choose paths and repeat actions, complete four 3–5 minute lessons, and combine both concepts in a final mission.

constraints:
- Platform: Android, Flutter stable.
- Reference viewport: 393 × 852 logical pixels.
- Local-first core route; no server or AI dependency for required learning.
- Riverpod, go_router, shared_preferences, Font Awesome abstraction.
- Backend: FastAPI + PostgreSQL under `/api/v1`.
- One restrained XP/Byte-level progression system.
- Performance-first motion; target 60 fps and responsive high-refresh behavior.
- No registration before the educational route.
- Russian product copy.

success:
- A user can complete Welcome → onboarding → four lessons → final mission → completion without an account or network.
- Three exercise formats, retry, progressive hints, deterministic Live Trace, XP, Byte levels, replay, and restart-safe progress all work.
- The same code line and its visible consequence can be understood during execution, especially condition branching and loop iteration.
- Core Flutter and backend tests pass; the app launches; required screens visually conform at 393 × 852.

scope v1:
- Welcome and two-step micro-onboarding.
- Compact mission map with four lessons and final mission.
- Prediction, reorder/drag, fix-logic, and final-mission exercises.
- Deterministic Live Trace engine.
- XP, four Byte levels, rewards, local persistence, replay.
- Hidden demo controls.
- FastAPI sync/content/attempt endpoints, PostgreSQL models, Docker.
- Optional Byte Assistant with safe backend-only provider boundary and graceful offline fallback.

non-goals:
- Authentication, profiles, admin panel, multiplayer, social, leaderboard, purchases, subscriptions, or enterprise LMS behavior.
- Arbitrary code execution.
- Required dependence on remote content or AI.

assumptions:
- The supplied master brief is the hackathon case and primary source of truth.
- No prior visual reference exists in the empty repository, so the visual exploration in `design/ideate/` becomes the approved reference.
- Direction B, Soft Future, may be selected autonomously if it scores best against clarity, teen appropriateness, educational focus, speed, and originality.
- The optional AI experience is implemented as an architectural boundary and graceful UI state; a real provider is enabled only through backend environment configuration.

risks:
- A single greenfield pass can drift visually unless all values are tokenized and screenshot-checked.
- Drag interactions need a non-drag accessible alternative.
- Image-generated boards can contain inaccurate text; implementation and `docs/DESIGN.md`, not generated text, remain the semantic source of truth.
