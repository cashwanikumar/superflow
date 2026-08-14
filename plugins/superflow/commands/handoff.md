# Handoff Summary

Create a full session handoff so the next session (you or someone else) can resume cleanly.

Use this at the end of a work session or before switching context.

---

## How to invoke

```
/handoff
```

---

## Behavior

Review what happened this session (the conversation + `git status` + `git log` of new commits) and produce a handoff with these sections:

- **What changed** — the substantive changes made this session (files/areas, not a diff dump).
- **Current state** — branch, what's committed vs uncommitted, what's pushed, any open PR.
- **Verified vs not** — what was actually exercised/tested vs assumed. Be honest about gaps.
- **Pending / blocked** — what's unfinished, and what's blocking it.
- **Next steps** — the ordered next actions, specific enough to act on cold.
- **Watch out for** — landmines, half-migrations, pending schema/migration steps, decisions made that could be revisited.

Then offer to write it to `SESSION.md` (and update `NEXT_STEPS.md`) — don't write the files unless the user says so.

Be accurate over flattering: if something failed or was skipped, say so plainly.
