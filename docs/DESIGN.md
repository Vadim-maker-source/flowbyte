# FLOWBYTE design specification

Status: frozen implementation contract. The selected direction is **Mission Control**, approved from the user references `design/reference/mission-control-home.png` and `design/reference/mission-control-flow.png`. Earlier Soft Future boards remain process artifacts only; the user references and this document now win.

## Product personality

Calm, precise, responsive, and encouraging without sounding childish. FLOWBYTE combines messenger-like density, product-tool discipline, an original educational identity, and restrained game feedback. Byte is a guide and a direct visualization of program execution, not decoration.

Audience: teenagers aged 12–17 who are new to programming. Theory stays short, practice starts quickly, and every code concept receives an immediate visible consequence.

## Direction

Mission Control uses a near-black space canvas, compact blue-black panels, electric cyan controls, mint completion states, technical grid/orbit details, clipped corners, and a connected mission rail. The UI should feel like an operational console while remaining readable for first-time learners. Gradients are limited to the main cyan CTA and subtle hero atmosphere; there is no glow-heavy neon, purple, giant pills, card nesting, or ornamental analytics.

## Color tokens

| Token | Hex | Use |
|---|---:|---|
| `background` | `#020B14` | app canvas |
| `surface` | `#071522` | primary solid surface |
| `surfaceElevated` | `#0A1B29` | sheets and raised controls |
| `surfaceInteractive` | `#0C2433` | selected/pressed rows |
| `primary` | `#00D6F2` | CTA, active route, focus |
| `primaryPressed` | `#00AFCB` | pressed CTA |
| `secondaryAccent` | `#2FFFE0` | energy and completion accent |
| `textPrimary` | `#E8F7FF` | primary copy |
| `textSecondary` | `#9FB8C8` | supporting copy |
| `textMuted` | `#5E7A91` | locked and metadata |
| `success` | `#48F2C7` | correct/completed |
| `warning` | `#F2B84B` | guidance |
| `error` | `#FF6474` | incorrect/error |
| `divider` | `#123449` | borders/separators |
| `codeKeyword` | `#F09AC8` | syntax keyword |
| `codeValue` | `#79D7FF` | syntax value |
| `codeFunction` | `#AFC7FF` | syntax function |

Semantic states must include iconography and text. Color is never the only signifier.

## Typography

UI family: Inter when available, otherwise the platform sans. Code: JetBrains Mono when available, otherwise monospace.

| Style | Size / line | Weight |
|---|---|---|
| Display | 26 / 32 | 700 |
| H1 | 22 / 28 | 700 |
| H2 | 19 / 24 | 600 |
| Title | 15 / 20 | 600 |
| Body | 15 / 21 | 400 |
| Body small | 13 / 18 | 400 |
| Label | 12 / 16 | 600 |
| Caption | 11 / 15 | 500 |
| Code | 14 / 21 | 500 |

## Spacing and geometry

- Base grid: 4 px.
- Allowed spacing: 4, 8, 12, 16, 20, 24, 32, 40.
- Default horizontal page padding: 20; dense exercise screens: 16.
- Radius: `xs=2`, `sm=4`, `md=8`, `lg=10`, `xl=12`.
- Primary buttons: 48 height with 10 px clipped top-right/bottom-left corners.
- Lesson tile: 8 radius or clipped active outline, minimum 52 height.
- Answer option: 8 radius, minimum 56 height.
- Code block: 8 radius, 12–16 internal padding.
- Bottom sheet: 12 top radius.
- Icon button: 44 square; default icon 20, small icon 16.
- Borders: 1 px; glass border may use 0.5–1 px.

## Icon system

Font Awesome outline/regular icons through `AppIcons`, `AppIcon`, and `AppIconButton`. No Unicode emoji or direct scattering of icon packages. Educational text may contain code symbols but navigation and actions use the abstraction.

## Byte

Byte is an original polished semi-3D robot: compact white/silver faceted shell, graphite joints, dark visor, cyan eye bars and a short cyan antenna. A single consistent project-owned pose set covers idle, thinking, moving, charging, success, error, explaining, trophy and offline states. Each state uses a distinct silhouette plus a restrained code-native effect; the asset remains semantic-labelled in Flutter. Do not imitate known mascots or mix character models between screens.

## Glass

At least 90% of UI is solid. Glass is allowed only for a floating trace label, contextual overlay, bottom sheet, navigation/floating control, or reward overlay. Blur 12–18, very subtle navy tint, 0.5–1 px border. No glow, rainbow, or gradient border. Never blur scrolling lesson/code/answer items.

## Motion and haptics

`AppMotion`: tap 90 ms, fast 150 ms, state 190 ms, page 240 ms, sheet 270 ms, reward 480 ms. Curves: easeOutCubic, easeOutQuart, fastOutSlowIn.

- Press: scale 1 → 0.975, 90 ms.
- Page: fade + 10 px vertical translate, 240 ms.
- Sheet: translate from bottom + fade, 270 ms.
- Drag: scale 1.03, slight elevation; selection haptic on snap.
- Live Trace: active-line transition 190 ms; condition steps 450–650 ms each; loop movement 360–520 ms each.
- Haptics: light on important primary action, selection on block snap, medium on lesson/final completion. Never on every tap.

## Component library

- `PrimaryButton`: 48 high, clipped corners, restrained cyan gradient, dark label, leading/trailing icon optional.
- `AppIconButton`: 44 square, radius 4, transparent or surface.
- `ProgressBar`: 6 high, radius 6; track divider, fill primary/success.
- `XPChip`: compact, icon + numeric XP; never a giant pill.
- `LessonTile`: route state, title, duration/type, semantic leading icon, trailing chevron/lock.
- `CodeBlock` / `CodeLine`: line numbers, syntax spans, active line fill, muted inactive lines.
- `DragBlock`: 48 minimum height, 8 radius, solid interactive fill, handle icon, snap feedback.
- `AnswerOption`: radio-like state plus text, neutral/selected/correct/error variants.
- `HintSheet`: progressive index, one short hint, next/retry actions.
- `ResultSheet`: semantic icon, concise title, explanation, XP, one primary next action.
- `ByteAvatar`: state + level; project-owned pose asset, code-native effects, and semantic label.
- `TraceStage`: compact grid/path plus Byte and one trace HUD.
- `BottomNavigation`: 64 high; solid/elevated navy, four compact destinations only where useful.

## Screen specifications

### Splash

Centered mark and FLOWBYTE on background, 600–900 ms maximum. No network loading.

### Welcome

Compact wordmark and skip action; H1 message “Научи Byte принимать решения и повторять действия.”; Byte stage in remaining space; page indicator and 52 px `Начать` CTA near bottom.

### Micro onboarding

Two short pages: visible code consequences; short lessons and offline behavior. Skip always available. No account request.

### Home / Mission Map

Console hero with FLOWBYTE wordmark, settings, technical grid/orbit, Byte, level, XP and energy progress. Below: module name, `n из 4 уроков`, segmented progress, connected vertical route, single clipped-corner `Продолжить` CTA, and four compact nav destinations. States: complete, active, locked. No analytics dashboard.

### Lesson

Top progress, title, one plain-language mental model, a real-life analogy, three explicit execution steps, tiny Byte example, code block, common-mistake callout, and `К практике · 3 задания` CTA. Theory stays scannable and explains the idea without assuming programming vocabulary.

### Condition exercise

Prompt, code block, three answer options, CTA. On Run: condition line activates → HUD `15 > 20 → false` → `else` activates → Byte moves to charging point → feedback sheet.

Every lesson contains three short tasks with visible `Задание n из 3` progress. A lesson unlocks the next one only after all three tasks are solved. The 12 tasks form one station-rescue story across four locations. Exercises alternate prediction, tap-the-bug diagnostics, block ordering and trace observation; every task names the subsystem at risk and the restored result.

### Loop exercise

Prompt, range choice or reordered blocks, code block, trace stage. Run shows the same active line and iteration `1 / 4 … 4 / 4`; Byte advances once per step.

### Fix logic

Almost-correct code with one faulty line. The learner taps the exact line, runs the deterministic diagnostic and receives the concrete replacement in the explanation. Keep editing narrow and explicit; no large code typing.

### Wrong answer + hint

No alert dialog. Keep the stage visible, add `Почти.` and one explanation; actions `Попробовать ещё` and `Подсказка`. Hint sheet reveals one level at a time and never immediately exposes the answer.

### Reward

Byte success/trophy pose, confetti and cyan pulse, animated XP delta, restored-subsystem message, real chain/progress values, preview of the next mission and one primary next action. Reward motion 480 ms and one medium haptic.

### Final challenge

Compact grid with core, obstacle, branch, charging point; block palette and ordered program area; accessible tap-to-add/reorder controls accompany drag. Live Trace stops on the exact error tile and offers replay/hint.

### Module complete

Byte at the energy core, `Модуль завершён`, concise learning summary, lesson checklist, replay action and return to map. No unrelated upsell.

### Byte Assistant

Optional contextual helper. First response guides attention, second explains principle, explicit request explains briefly. When unavailable: “Помощник сейчас недоступен. Подсказки урока продолжают работать.” Core hint action remains available.

### Hidden demo panel

Reachable only by repeated long press on version/build label. Reset progress, unlock lesson, set XP, simulate backend offline. Never present in normal navigation.

## Accessibility

Interactive targets are at least 44 × 44. Support text scaling without clipping through flexible layouts and scrolling. Add semantic labels to icons, Byte state, trace progress, correctness, and locked lessons. Keep primary text contrast at WCAG AA or better. Motion respects reduced-motion settings by shortening or skipping travel while preserving state changes.

## Anti-patterns

No purple startup palette; rainbow gradients; gradient borders; neon glow; pervasive glass; 20–40 px radii; random blobs; giant pills; emoji as icons; giant functional headings; nested cards; excessive shadows; fake charts; meaningless badges; raw exceptions; full-screen network spinners; standard correctness alert dialogs.
