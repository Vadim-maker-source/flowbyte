# FLOWBYTE design QA

prototype: Flutter Web release build at `http://127.0.0.1:18080`  
viewport: 393 × 852  
source: `design/reference/mission-control-home.png`, `design/reference/mission-control-flow.png`, `design/context.md`, and the user's physical-device reward screenshot

## Visual

- PASS — the running app now uses one consistent polished Byte character in nine genuinely different poses: idle, thinking, moving, charging, success, error, explaining, trophy and offline.
- PASS — welcome, lesson briefing, exercise briefing and reward were screenshot-checked at 393 × 852. Mascot silhouettes, transparent edges, scaling and cyan rim light remain consistent.
- PASS — the reward now stages success with a jumping pose, confetti, pulse ring, animated XP, restored-system panel, real progress cards and next-mission preview. The former half-screen empty void is removed.
- PASS — near-black canvas, cyan clipped CTA, blue-black panels, technical grid, compact radii and mint completion states still match the Mission Control references.
- PASS — generated raster art is limited to the character; layout, particles, glows, interaction states and trace visuals remain deterministic Flutter code.

## Behavior

- PASS — 12 exercises and the final mission remain data-driven, local-first and deterministic.
- PASS — `bugHunt` adds a distinct interaction: tap an exact faulty code line, then run the diagnostic. Prediction and reorder interactions remain available.
- PASS — the reward advances to the next exercise inside a lesson and returns to the map after task 3.
- PASS — wrong-answer feedback now shows Byte's error pose while progressive hints remain available.

## Learning content

- PASS — four lessons are now four connected station locations: emergency airlock, life support, cargo sector and debris-field autopilot.
- PASS — every exercise contains a mission brief, subsystem label, visible consequence, three progressive hints and a cause/effect explanation.
- PASS — lesson theory retains a plain-language concept, analogy, three execution steps, code example and common-mistake callout.

## Accessibility sanity

- PASS — Byte retains one stable semantic label even though the visual asset changes; decorative particles are excluded from semantics.
- PASS — interactive targets remain at least 44 px; bug-hunt code rows are 44 px minimum and reorder tasks retain up/down controls.
- PASS — locked, selected, correct and error states use text/icons in addition to colour.
- MANUAL — TalkBack reading order, maximum Android text scale and haptic feel still require a physical-device pass.

## Verification

- `flutter analyze`: clean.
- `flutter test`: 11/11 passed.
- Flutter Web release build: passed.
- Browser visual checks saved in `docs/screenshots/`.

## Verdict

READY for physical-device review. The three HIGH findings in `design/audit.md` — flat repeated mascot, empty reward and repetitive course loop — are addressed in the implementation.

## Follow-up QA — context memory and trace fidelity

date: 2026-10-03  
builds: Flutter Web release and Android release APK

### AI assistant

- PASS — the first request includes FLOWBYTE product context, the active lesson and exercise.
- PASS — a second request includes the preceding user and assistant messages; a widget test verifies the exact transmitted history.
- PASS — the live Groq endpoint returned fenced Python for reading and comparing two integers, including the equal case.
- PASS — direct code requests are answered directly; the former first-attempt rule that forced an evasive question has been removed.
- PASS — the opening copy now promises the actual behavior: lesson awareness, conversation memory and code on request.

### Live Trace

- PASS — browser comparison confirms a system-only energy task shows the “Аварийный док” effect panel and no route destination.
- PASS — a real `move()` task shows the route line and destination.
- PASS — all 24 lesson exercises plus the final mission pass a content invariant: only `move` may change position, and exactly one cell per call.
- PASS — bug-hunt success switches the visible panel to `resolvedCode` before playback.
- PASS — final mission now includes the previously missing `else:` block; `turn()` preserves Byte's position.

### Verification

- `flutter analyze`: clean.
- `flutter test`: 18/18 passed.
- backend `pytest`: 7/7 passed.
- Web release: built and browser-inspected.
- Android release APK: built against `http://192.168.1.222:18001/api/v1`.

follow-up verdict: READY. Remaining MANUAL checks are installation on the target phone, LAN reachability/firewall and TalkBack at maximum text scale.
