# FLOWBYTE interactive flow

## Main route

Welcome → onboarding → mission map → lesson theory → practice 1 → reward → practice 2 → reward → practice 3 → reward → mission map.

After all four lessons: mission map → final route builder → module complete → replay or mission map.

## Practice states

- No answer: Run is disabled.
- Wrong answer: stage remains visible; `Почти.` sheet offers retry and one progressive hint at a time.
- Correct answer: deterministic trace plays, XP is granted once, reward links to the next task.
- Returning learner: lesson CTA resumes the first unfinished task.
- Offline: all theory, tasks, trace, scoring, XP, unlocks, and persistence remain available.

## Content volume

- 4 lessons.
- 3 practical tasks per lesson (12 total).
- 1 combined final mission.
- 3 progressive hints per task.

## Navigation edges

- Back from theory or practice returns without losing saved completions.
- Home `Продолжить` opens the next unlocked lesson or the final mission.
- Reward `Следующее задание` advances inside the current lesson.
- Reward after task 3 returns to the mission map and unlocks the next lesson.
- Completion offers map and replay actions.
