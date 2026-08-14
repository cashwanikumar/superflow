---
name: daily-brief
description: Fast session start — where you left off and what to do next, reconstructed from git state and recent work. Use when the user runs /superflow:daily-brief or asks to pick up where they left off.
---

# Daily Brief

Fast session start. No ceremony — just where you left off and what to do next.

Use this at the start of a session when you already know the project and want to pick up quickly.

---

## How to invoke

```
/superflow:daily-brief
```

---

## Behavior

1. Read whichever of these the repo has (skip silently if absent): `SESSION.md`, `NEXT_STEPS.md` / `TODO.md`, `CHANGELOG.md`, and the current `git status` + recent `git log`.
2. Produce a tight brief:
   - **Where you left off** — the last meaningful change / current branch + working-tree state.
   - **What's in flight** — uncommitted work, open PRs, anything half-done.
   - **Suggested next action** — the single most sensible next step, phrased as a concrete task.
3. End by offering to start: *"Say 'go' and I'll pick up the next action."*

If the user says "go" / "yes" / "start", proceed with that next action via the normal superflow routing (load the relevant persona/skill). If they want a different direction, help them re-scope and update `NEXT_STEPS.md` / `SESSION.md`.

Keep it short — a brief, not a report. Don't restate the whole project history.
