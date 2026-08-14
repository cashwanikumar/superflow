---
name: superflow
description: The front door for non-trivial coding work in this repo — pairs a process skill (brainstorming for builds, systematic-debugging for bugs, receiving-code-review for review feedback) with the right specialist persona, in the right order. Load when deciding how to approach a build, bug, review, or design task, or when unsure which skill/persona applies.
---

# superflow — the full-flow front door

superflow weaves two things into one pipeline: **process skills** (vendored from Superpowers — TDD, brainstorming, systematic-debugging, plans, code-review, verification, worktrees) and **specialist personas** (finder, pm, designer, dev, testers, bughunter, a11y-hunter, architect, auditor). Each stage loads only the skill it needs and spawns only the personas the task needs. Spawn the minimum; skip what doesn't apply.

## 1. Skill-check (always-on, lightweight)

Before acting on any non-trivial coding turn, if a process skill fits the work, **invoke it first** — this is cheap and always on, independent of the opt-in gate below:

| The work is… | Invoke first |
|---|---|
| a build / new feature / behavior change | `brainstorming` |
| a bug / test failure / unexpected behavior | `systematic-debugging` |
| responding to code-review feedback | `receiving-code-review` |

For how skills are discovered and invoked in general, reference the **`using-superpowers`** skill — superflow is the front door and defers to it rather than duplicating it. Don't restate its mechanics here.

## 2. Opt-in gate (before spawning personas)

> **Main agent only.** If you are a spawned persona/subagent (invoked via the Agent tool), this gate does **not** apply — don't ask the opt-in, don't re-run routing, don't delegate onward unless your task requires it. Execute your persona's work and return it. (You still consult the rulebook before any code change.)

For non-trivial build/review/debug work, ask **once** and wait:

> Run the full superflow for this? It would: \<one line tailored to THIS task — which personas, in what order\>. (yes / no)

- **Slash command** (message begins with `/`) → run it; skip the opt-in.
- **Trivial** (single-line explanation, file read, lookup, "what does X do") → answer directly; no opt-in, no personas.
- **yes** → run the weave below via the Agent tool.
- **no** → answer directly, no sub-agents; don't bring personas up again this turn.
- **Already opted in earlier this session** for the same kind of work → skip the question and proceed.

## 3. The weave (stage → process skill + persona)

Skip any stage that doesn't apply.

| Stage | Superpowers skill | Persona |
|---|---|---|
| Understand | `brainstorming` | `finder` |
| Plan | `writing-plans` | `pm` / `architect` |
| Isolate | `using-git-worktrees` | — |
| Design (UI) | — | `designer` |
| Build | `test-driven-development` | `dev` (consults rulebook) |
| Verify | `verification-before-completion` | `fe-unit-tester` / `be-unit-tester`, `bughunter`, `a11y-hunter` |
| Review | `requesting-code-review` / `receiving-code-review` | `architect` |
| Debug | `systematic-debugging` | `finder` → `bughunter` |
| Finish | `finishing-a-development-branch` | `auditor` (rulebook refresh) |

## 4. Rulebook-first

Before **any** code change, consult `CODEBASE_RULEBOOK.md` at the repo root and conform to it — it is the source of truth for how this codebase does things, and it's what lets these generic personas fit *this* repo. If it's missing, offer to run **`/superflow:codebase-rulebook`** first (auditor scans the repo and writes it). If a change would violate the rulebook, stop and ask: exception, or update the rulebook? Never invent rules that aren't in it.

## 5. Minimum-spawn

- Load only the process skill the current step touches; spawn only the personas the task needs. On-demand is the default — don't blur the context by loading everything.
- **Green tests are necessary, not sufficient.** For any user-facing change, verify by exercising the real path in the running app (run it / hit the endpoint / load the page), not just that tests and lint pass — see `verification-before-completion`.
- Knowledge lives in the on-demand skills and the rulebook, not in always-on context.

## Personas (10)

| Persona | Role |
|---|---|
| `architect` | Scalability, boundaries, tradeoffs. Plans & reviews; not the default builder. |
| `pm` | What to build & why — specs, scope, success metrics. |
| `finder` | Read-only investigator; maps the terrain before others act. |
| `designer` | UX/UI spec before code (read-only). |
| `dev` | Implementer; tight code, consults the rulebook. |
| `fe-unit-tester` | Frontend unit tests, mirroring the repo's setup. |
| `be-unit-tester` | Backend unit tests, mirroring the repo's setup. |
| `bughunter` | Functional QA + convention/security red flags. |
| `a11y-hunter` | Accessibility to WCAG 2.0 AA (frontend). |
| `auditor` | Read-only rule-scanner; writes/refreshes the rulebook. |

## Commands

- `/superflow:codebase-rulebook` — scan the repo → write `CODEBASE_RULEBOOK.md` (the portability keystone). `--refresh` to update.
- `/superflow:council` — multi-voice deliberation (architect, pm, dev, bughunter, finder) on a hard decision; architect synthesizes.
- `/superflow:daily-brief` — fast session start: where you left off + the next action.
- `/superflow:handoff` — end-of-session handoff summary (what changed, state, pending, next steps).
- `/superflow:commit-prep` — summarize the diff + propose a commit message (doesn't commit unless asked).
