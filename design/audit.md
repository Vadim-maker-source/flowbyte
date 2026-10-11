# FLOWBYTE UI audit — 2026-10-03

target: Android build on a physical 393 × 852-class device  
goal: make the learning route feel like the approved Mission Control game concept, with a recognisable companion and missions worth completing

| # | area | confirmed issue | sev | concrete fix | eff |
|---|---|---|---|---|---|
| 1 | character | `ByteAvatar` draws nearly the same flat silhouette for every mood; success changes one arm angle and error only changes eye colour. The promised mascot performance is absent. | HIGH | Replace the painter with a consistent rendered pose set: idle, thinking, running, charging, success, error, explaining, trophy and offline. Give each state its own entrance/effect animation. | M |
| 2 | reward | The result screen spends almost half of the viewport on empty black space. It communicates points, but not a completed event or changed game state. | HIGH | Turn it into a mission debrief: full-width effect layer, expressive success pose, animated XP, system-restored result, streak/energy cards and a compact bottom CTA without a spacer-created void. | M |
| 3 | learning loop | Most activities repeat the same “read code → choose an option” pattern. Values change, but the player's role and consequence do not. | HIGH | Connect all 12 tasks into one station-rescue story and mix prediction, bug hunting, command ordering and trace observation. State the system at risk and the visible outcome in every task. | L |
| 4 | hierarchy | The visual emphasis in the shipped reward screen is on the static mascot and XP number; the useful explanation reads as low-contrast metadata. | MED | Promote a short mission result card, keep the explanation to one concrete cause/effect sentence, and use the accent only for the earned value and restored system. | S |
| 5 | progression | “Practice credited” is generic and does not explain what changed in the mission. Energy is a decorative counter with no narrative meaning. | MED | Show the restored subsystem and the current chain of solved tasks. Rename the counters to mission-specific outcomes and derive them from actual progress. | S |
| 6 | consistency | The approved reference uses a polished semi-3D mascot, particles and spatial depth, while the app uses a code-drawn icon on a mostly flat page. | MED | Keep the existing dark Mission Control tokens, add project-owned raster mascot assets and restrained particles/glows behind them; do not add unrelated colours or illustration styles. | M |
| 7 | accessibility | Tap targets and primary-button contrast are adequate in the inspected screen, but the generated mascot needs a stable semantic label and decorative particles must be excluded from semantics. A full TalkBack pass is not yet verified. | MED | Preserve the current `Semantics` label on Byte, mark effects decorative, and run a manual TalkBack pass before release. | S |

verdict: the three HIGH items explain the user's reaction. The next build must change character performance, reward staging and course structure together; polishing spacing alone will not solve it.

## Follow-up audit — execution fidelity and AI context

| # | area | confirmed issue | sev | implemented fix |
|---|---|---|---|---|
| 8 | Live Trace | A generic destination was rendered for every task, and several non-movement actions changed `position`. That visually claimed Byte moved even when no `move()` ran. | HIGH | Destination is now shown only when the plan contains `move`; system-only missions use an action/status panel. Position is ignored for non-movement plans, and all 25 simulations are validated so only `move` can change a cell. |
| 9 | bug hunt | After finding a faulty line, the success trace ran beside the original broken code. The highlighted trace and displayed code therefore contradicted one another. | HIGH | Every bug-hunt has explicit `resolvedCode`; the code panel switches to the corrected version before the success trace starts. |
| 10 | assistant | Each request contained only the newest message, while the prompt forced a guiding question on early attempts. Byte forgot the conversation, lacked product context and evaded direct code requests. | HIGH | The client retains lesson-scoped chat, sends the previous 12 messages, and clears only when the lesson changes. The server prompt now includes FLOWBYTE, its eight lessons, current lesson/exercise and a direct-answer policy. |
| 11 | action semantics | `turn`, `continue`, `charge`, alarm and subsystem commands reused the same movement vocabulary and target affordance. | MED | Actions now have distinct trace types, icons, colors and labels; `turn`/`continue` preserve position and branch transitions use `checkCondition`. |

follow-up verdict: the interaction model now has one source of truth: corrected code → semantic trace action → visible consequence. Automated tests protect this mapping from content regressions.
