---
name: handoff
description: Session handoff in both directions — at the end, write what changed, current state, verified vs not, pending work, next steps and watch-outs; at the start, read the last handoff plus git state and name the next action. Use when the user runs /superflow:handoff, asks for a handoff or wrap-up, or asks to pick up where they left off.
---

# Handoff

One skill, two directions: **write** a handoff when a session ends, **read** one when a session starts.

---

## How to invoke

```
/superflow:handoff            # end of session: write the handoff
/superflow:handoff resume     # start of session: read the last one and name the next action
```

With no argument, infer the direction: substantive work this session → write; a fresh session with no work yet → resume.

---

## Write (end of session)

Review what happened this session (the conversation + `git status` + `git log` of new commits) and produce a handoff with these sections:

- **What changed** — the substantive changes made this session (files/areas, not a diff dump).
- **Current state** — branch, what's committed vs uncommitted, what's pushed, any open PR.
- **Verified vs not** — what was actually exercised/tested vs assumed. Be honest about gaps.
- **Pending / blocked** — what's unfinished, and what's blocking it.
- **Next steps** — the ordered next actions, specific enough to act on cold.
- **Watch out for** — landmines, half-migrations, pending schema/migration steps, decisions made that could be revisited.

Then offer to write it to `SESSION.md` (and update `NEXT_STEPS.md`) — don't write the files unless the user says so.

Be accurate over flattering: if something failed or was skipped, say so plainly.

## Resume (start of session)

1. Read whichever of these the repo has (skip silently if absent): `SESSION.md`, `NEXT_STEPS.md` / `TODO.md`, `CHANGELOG.md`, plus the current `git status` and recent `git log`.
2. Produce a tight brief: **where you left off** (last meaningful change, branch, working-tree state), **what's in flight** (uncommitted work, open PRs, anything half-done), and the **single most sensible next action**, phrased as a concrete task.
3. End with: *"Say 'go' and I'll pick up the next action."* On "go", proceed via the normal superflow routing.

Keep it short — a brief, not a report. Don't restate the whole project history.
