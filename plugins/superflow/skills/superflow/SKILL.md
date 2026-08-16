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

First, the cheap exits — these apply in every mode:

- **Slash command** (message begins with `/`) → run it; skip the opt-in.
- **Trivial** (single-line explanation, file read, lookup, "what does X do") → answer directly; no opt-in, no personas.

For everything else, the gate depends on whether anyone can answer it. The SessionStart hook resolves `SUPERFLOW_FLOW` (`auto` default, or `always` / `never`) and states the policy in its protocol line — follow that policy over anything here if they disagree.

**`auto`, human in the loop** — ask **once** and wait:

> Run the full superflow for this? It would: \<one line tailored to THIS task — which personas, in what order\>. (yes / no)

- **yes** → run the weave below via the Agent tool.
- **no** → answer directly, no sub-agents; don't bring personas up again this turn.
- **Already opted in earlier this session** for the same kind of work → skip the question and proceed.

**`auto`, no human in the loop** (headless, `-p`, CI, or any session that cannot receive a reply) — do **not** ask. A question nobody can answer is not a safe default; it just stalls the run and the work happens anyway, ungoverned. Decide **before touching anything**, and open your reply with the choice — `superflow: weave — <reason>` or `superflow: direct — <reason>` — so the transcript shows which path was taken.

**The weave is the default.** Going direct requires all three, judged from the request before you start:

| | Test |
|---|---|
| a | The request is **one** capability. An "and" joining two features fails this. |
| b | You can name the single file you will edit, up front. |
| c | `CODEBASE_RULEBOOK.md` already covers that kind of change. |

Unsure on any → weave. If you claimed `direct` and then find yourself editing a second file, say so plainly in the final message instead of restating the original claim. This asymmetry is deliberate: an unattended run has nobody to catch an under-governed change, and the failure mode observed in testing was a multi-feature request being waved through as "single file, fully covered by the rulebook."

You know which mode you're in; the hook does not. It cannot: the SessionStart payload is byte-identical in both, the hook's stdio is piped either way, and env vars are inherited by child sessions. That's why this branch lives here and not in the shell script.

**`always` / `never`** — no judgement call: always run the weave, or never spawn it (work directly, still rulebook-first). Set these for unattended runs where you want the behavior pinned rather than inferred.

## 3. The weave (stage → process skill + persona)

Skip any stage that doesn't apply.

**Always dispatch with the `superflow:` prefix** — pass `superflow:dev` as the `subagent_type`, never bare `dev`. Bare names are not superflow's: they either fail to resolve, or silently hit a same-named agent in the user's own `~/.claude/agents/`, which is a different persona that has never seen this protocol. (Observed in testing: a weave that named personas bare ran four of the user's agents and only one of superflow's.) The same applies to skills — `superflow:test-driven-development`, not `test-driven-development`.

| Stage | Superpowers skill | Persona |
|---|---|---|
| Understand | `superflow:brainstorming` | `superflow:finder` |
| Plan | `superflow:writing-plans` | `superflow:pm` / `superflow:architect` |
| Isolate | `superflow:using-git-worktrees` | — |
| Design (UI) | — | `superflow:designer` |
| Build | `superflow:test-driven-development` | `superflow:dev` (consults rulebook) |
| Verify | `superflow:verification-before-completion` | `superflow:fe-unit-tester` / `superflow:be-unit-tester`, `superflow:bughunter`, `superflow:a11y-hunter` |
| Review | `superflow:requesting-code-review` / `superflow:receiving-code-review` | `superflow:architect` |
| Debug | `superflow:systematic-debugging` | `superflow:finder` → `superflow:bughunter` |
| Finish | `superflow:finishing-a-development-branch` | `superflow:auditor` (rulebook refresh) · `superflow:pm` (specbook fold-back, if a change folder is open) |

With `specbook/` present (§5), Understand reads it, Plan writes the change folder, and Finish folds it back.

## 4. Rulebook-first

Before **any** code change, consult `CODEBASE_RULEBOOK.md` at the repo root and conform to it — it is the source of truth for how this codebase does things, and it's what lets these generic personas fit *this* repo. If it's missing, offer to run **`/superflow:codebase-rulebook`** first (auditor scans the repo and writes it). If a change would violate the rulebook, stop and ask: exception, or update the rulebook? Never invent rules that aren't in it.

## 5. Specbook (opt-in spec layer)

If `specbook/` exists at the repo root, this repo keeps a persistent spec layer and the weave reads and writes it. If it does not exist: say at most one line, once per session — "No `specbook/` here; `/superflow:specbook` bootstraps a persistent spec layer if you want one." — then drop the subject. **Never create it unprompted, and never mention it in a headless run.**

When present:

- `specbook/specs/<capability>.md` are the living requirements. Read the affected ones at Understand; verify against their Scenarios at Verify; pass the change folder as the requirements input at Review.
- Every change that runs the Plan stage gets `specbook/changes/YYYY-MM-DD-<slug>/`, opened by the lead. `pm` writes `proposal.md`; the technical design goes in `design.md` — **this is the repo's preferred spec location, which the `brainstorming` skill defers to** — and the plan goes in `tasks.md` — **the preferred plan location, which `writing-plans` defers to**. Include the change-folder path in every persona brief; a spawned subagent has not seen this section.
- Work that skips Plan opens no folder. If direct work alters behavior a living spec covers, update that spec in the same change — headless, state the drift in your final message instead of stalling.
- At Finish, `pm` folds the proposal's Spec deltas into `specs/` and moves the folder to `archive/` (`/superflow:specbook --archive`). auditor writes only `CODEBASE_RULEBOOK.md`; pm writes only inside `specbook/`.
- The rulebook says **how** this codebase does things; the specbook says **what** it must do.

## 6. Minimum-spawn

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
- `/superflow:specbook` — bootstrap `specbook/` (living capability specs + per-change proposal/design/tasks). Opt-in per repo. `--refresh` / `--change <slug>` / `--archive <slug>` / `--dry-run`.
- `/superflow:council` — multi-voice deliberation (architect, pm, dev, bughunter, finder) on a hard decision; architect synthesizes.
- `/superflow:daily-brief` — fast session start: where you left off + the next action.
- `/superflow:handoff` — end-of-session handoff summary (what changed, state, pending, next steps).
- `/superflow:commit-prep` — summarize the diff + propose a commit message (doesn't commit unless asked).
