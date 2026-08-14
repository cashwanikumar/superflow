---
name: commit-prep
description: Summarize the current diff and propose a commit message, without committing unless explicitly asked. Use when the user runs /superflow:commit-prep or asks what changed / for a commit message before committing.
---

# Commit Prep

Prepare a concise commit summary and message for the current changes.

**This command must not commit unless the user explicitly asks** — it stages-and-describes, you decide.

---

## How to invoke

```
/superflow:commit-prep
```

---

## Behavior

1. Look at what's changed: `git status` + `git diff` (staged and unstaged).
2. Summarize the change in a sentence or two — *what* changed and *why*, not a file-by-file dump.
3. If the diff spans **multiple unrelated concerns**, say so and propose splitting it into separate logical commits (one message each) rather than one mixed commit.
4. Propose a commit message that matches the repo's existing style (check recent `git log` for the convention — e.g. `type(scope): summary`). Subject in the imperative, ≤ ~72 chars; body only if the *why* isn't obvious.
5. Flag anything that shouldn't be committed — secrets, debug logging, stray files, unrelated formatting churn.

Then stop. Only run `git commit` if the user explicitly says to. Match the repo's trailer/attribution conventions (don't add attribution the repo doesn't use).
