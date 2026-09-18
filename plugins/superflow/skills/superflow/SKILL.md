---
name: superflow
description: The front door for non-trivial coding work in this repo — pairs a process skill (brainstorming for builds, systematic-debugging for bugs, receiving-code-review for review feedback) with the right specialist persona, in the right order. Load when deciding how to approach a build, bug, review, or design task, or when unsure which skill/persona applies.
---

# superflow — the full-flow front door

superflow weaves two things into one pipeline: **process skills** (vendored from Superpowers — TDD, brainstorming, systematic-debugging, plans, code-review, verification, worktrees; addressed here as `superflow:<name>`) and **specialist personas** (sherlock, bossbaby, designer, codezilla, unit-tester, bughunter, a11y-hunter, architect, auditor). Each stage loads only the skill it needs and spawns only the personas the task needs. Spawn the minimum; skip what doesn't apply.

## 1. Skill-check (always-on, lightweight)

Before acting on any non-trivial coding turn, if a process skill fits the work, **invoke it first** — this is cheap and always on, independent of the opt-in gate below:

| The work is… | Invoke first |
|---|---|
| a build / new feature / behavior change | `superflow:brainstorming` |
| a bug / test failure / unexpected behavior | `superflow:systematic-debugging` |
| responding to code-review feedback | `superflow:receiving-code-review` |

**`using-superpowers` owns the mechanics; this table owns the dispatch.** That skill is the authority on *how* skills are found, announced, and prioritized, and on the rationalizations that talk you out of one — load it for any of that, and where it and this section disagree on process, it wins. What this table adds is the resolved `superflow:`-prefixed name to actually invoke (§3 explains why the bare name is not safe to dispatch) plus the review-feedback row, which has no equivalent there. Nothing else about skill invocation belongs in this file.

## 2. Opt-in gate (before spawning personas)

> **Main agent only.** A spawned persona/subagent (invoked via the Agent tool) skips this gate: don't ask the opt-in, don't re-route, don't delegate onward unless the task requires it. Execute the persona's job and return. (Still consult the rulebook before any code change.)

**This section is the single source of the gate.** The SessionStart hook injects a two-line pointer to it and nothing more; if the hook and this file ever disagree, this file wins and the hook is the bug.

Cheap exits, every mode:

- **Slash command** (message begins with `/`) → run it; skip the opt-in.
- **Trivial** (single-line explanation, file read, lookup, "what does X do") → answer directly; no opt-in, no personas.

Everything else depends on `SUPERFLOW_FLOW` (`auto` default, `always`, `never`), which the hook resolves and states.

**`auto`, human in the loop** — positive evidence a person is reading this session: a human-authored reply, an earlier answered question, an interruption. Ask **once** and wait:

> Run the full superflow for this? It would: \<one line tailored to THIS task — which personas, in what order\>. (yes / no)

- **yes** → run the weave (§3) via the Agent tool.
- **no** → work directly, no sub-agents; don't raise personas again this turn.
- **Already opted in earlier this session** for the same kind of work → skip the question and proceed.

**`auto`, no human in the loop** (headless, `-p`, CI, or no evidence anyone can reply) — do **not** ask; a question nobody can answer stalls the run. Decide **before touching anything** and open your reply with the choice, verbatim and alone on the first line: `superflow: weave — <reason>` or `superflow: direct — <reason>`. That line is the run's only audit trail.

**Headless default is `direct`.** Nobody is watching a headless run, so the cheap path is the safe default and the weave has to earn its spawns. Run the weave when **any** trigger fires:

| | Weave trigger |
|---|---|
| a | **More than one capability.** An "and" joining two features, or a request that names two user-facing behaviors. |
| b | **UI work.** A screen, page, component, layout, or visual change — the designer stage exists for a reason. |
| c | **Cross-layer.** The change touches more than one of: schema/model, API/backend, frontend, infra — or you cannot name up front the files you will edit. |

None fire → `direct`. Direct still means rulebook-first, TDD via the skill-check, and real-path verification; it only skips the persona spawns. If you claimed `direct` and the change grows past the triggers mid-task, say so plainly in the final message rather than restating the claim.

You know which mode you're in; the hook does not. The SessionStart payload is byte-identical headless and interactive, the hook's stdio is piped either way, and env vars are inherited by child sessions — so this decision lives here, not in the shell script.

**`always` / `never`** — no judgement call: always run the weave, or never spawn it (direct, rulebook-first). Pin one of these for unattended runs where you want the behavior deterministic rather than inferred.

## 3. The weave (stage → process skill + persona)

Skip any stage that doesn't apply.

**Always dispatch with the `superflow:` prefix** — pass `superflow:codezilla` as the `subagent_type`, never bare `codezilla`. Bare names are not superflow's: they either fail to resolve, or silently hit a same-named agent in the user's own `~/.claude/agents/`, which is a different persona that has never seen this protocol. (Observed in testing: a weave that named personas bare ran four of the user's agents and only one of superflow's.) The same applies to skills — `superflow:test-driven-development`, not `test-driven-development`.

| Stage | Superpowers skill | Persona |
|---|---|---|
| Understand | `superflow:brainstorming` | `superflow:sherlock` |
| Plan | `superflow:writing-plans` | `superflow:bossbaby` / `superflow:architect` |
| Isolate | `superflow:using-git-worktrees` | — |
| Design (UI) | `superflow:design` (mock-locked) · `superflow:ui-reduction` (declutter) | `superflow:designer` |
| Build | `superflow:test-driven-development` | `superflow:codezilla` (consults rulebook) |
| Verify | `superflow:verification-before-completion` | `superflow:unit-tester`, `superflow:bughunter`, `superflow:a11y-hunter` |
| Review | `superflow:requesting-code-review` / `superflow:receiving-code-review` · `/superflow:review-sweep` for big diffs | `superflow:architect` |
| Debug | `superflow:systematic-debugging` | `superflow:sherlock` → `superflow:bughunter` |
| Finish | `superflow:finishing-a-development-branch` | `superflow:auditor` (rulebook refresh) · `superflow:bossbaby` (specbook fold-back, if a change folder is open) |

With `specbook/` present (§5), Understand reads it, Plan writes the change folder, and Finish folds it back.

### Handoffs between stages

The weave relays through prose by default, and prose handoffs are lossy in a way nothing errors on — the caveat in paragraph 4 doesn't survive, and the next persona builds the wrong thing. For any weave with two or more handoffs, load **`superflow:handoff-contracts`** and require the fenced JSON block on each spawn. A malformed handoff then fails loudly instead of degrading silently.

### Deterministic workflows (the expensive calls)

Two decisions are costly enough to be worth taking out of the model's hands and into a script, where a dropped voice or a skipped slice is impossible rather than unlikely:

| Command | What it does | When |
|---|---|---|
| `/superflow:council` | Confirms the decision + roster + external spend, then runs the `council-vote` workflow: schema-forced independent votes, architect synthesizes. | Hard, expensive-to-reverse calls. |
| `/superflow:review-sweep` | Partitions the diff into coherent slices, one `bughunter` per slice, then one skeptic per finding → CONFIRMED / PLAUSIBLE tiers. | Epic gates and diffs >~5 files ONLY — a run is expensive. Small PRs get a plain `bughunter` pass. |

Both are opt-in and neither runs itself. If Dynamic workflows are unavailable in the user's session, say so and fall back to the conversational equivalent (the `council` skill's roster run by hand; a plain `bughunter` review) rather than pretending the run happened.

## 4. Rulebook-first

Before **any** code change, consult `CODEBASE_RULEBOOK.md` at the repo root and conform to it — it is the source of truth for how this codebase does things, and it's what lets these generic personas fit *this* repo. If it's missing, offer to run **`/superflow:codebase-rulebook`** first (auditor scans the repo and writes it). If a change would violate the rulebook, stop and ask: exception, or update the rulebook? Never invent rules that aren't in it.

## 5. Specbook (opt-in spec layer)

If `specbook/` exists at the repo root, this repo keeps a persistent spec layer and the weave reads and writes it. If it does not exist: say at most one line, once per session — "No `specbook/` here; `/superflow:specbook` bootstraps a persistent spec layer if you want one." — then drop the subject. **Never create it unprompted, and never mention it in a headless run.**

When present:

- `specbook/specs/<capability>.md` are the living requirements. Read the affected ones at Understand; verify against their Scenarios at Verify; pass the change folder as the requirements input at Review.
- Every change that runs the Plan stage gets `specbook/changes/YYYY-MM-DD-<slug>/`, opened by the lead. `bossbaby` writes `proposal.md`; the technical design goes in `design.md` — **this is the repo's preferred spec location, which the `brainstorming` skill defers to** — and the plan goes in `tasks.md` — **the preferred plan location, which `writing-plans` defers to**. Include the change-folder path in every persona brief; a spawned subagent has not seen this section.
- Work that skips Plan opens no folder. If direct work alters behavior a living spec covers, update that spec in the same change — headless, state the drift in your final message instead of stalling.
- At Finish, `bossbaby` folds the proposal's Spec deltas into `specs/` and moves the folder to `archive/` (`/superflow:specbook --archive`). auditor writes only `CODEBASE_RULEBOOK.md`; bossbaby writes only inside `specbook/`.
- The rulebook says **how** this codebase does things; the specbook says **what** it must do.

## 6. Minimum-spawn

- Load only the process skill the current step touches; spawn only the personas the task needs. On-demand is the default — don't blur the context by loading everything.
- **Green tests are necessary, not sufficient.** For any user-facing change, verify by exercising the real path in the running app (run it / hit the endpoint / load the page), not just that tests and lint pass — see `verification-before-completion`.
- Knowledge lives in the on-demand skills and the rulebook, not in always-on context.

## Personas (9)

| Persona | Role |
|---|---|
| `architect` | Scalability, boundaries, tradeoffs. Plans & reviews; not the default builder. |
| `bossbaby` | What to build & why — specs, scope, success metrics. |
| `sherlock` | Read-only investigator; maps the terrain before others act. |
| `designer` | UX/UI spec before code (read-only). |
| `codezilla` | Implementer; tight code, consults the rulebook. |
| `unit-tester` | Unit tests, frontend or backend, mirroring the repo's setup. |
| `bughunter` | Functional QA + convention/security red flags. |
| `a11y-hunter` | Accessibility to WCAG 2.0 AA (frontend). |
| `auditor` | Read-only rule-scanner; writes/refreshes the rulebook. |

## Commands

- `/superflow:codebase-rulebook` — scan the repo → write `CODEBASE_RULEBOOK.md` (the portability keystone). `--refresh` to update.
- `/superflow:specbook` — bootstrap `specbook/` (living capability specs + per-change proposal/design/tasks). Opt-in per repo. `--refresh` / `--change <slug>` / `--archive <slug>` / `--dry-run`.
- `/superflow:council` — multi-voice deliberation (architect, bossbaby, codezilla, bughunter, sherlock) on a hard decision; architect synthesizes.
- `/superflow:daily-brief` — fast session start: where you left off + the next action.
- `/superflow:handoff` — end-of-session handoff summary (what changed, state, pending, next steps).
- `/superflow:commit-prep` — summarize the diff + propose a commit message (doesn't commit unless asked). Optionally hard-gated: set `SUPERFLOW_COMMIT_GATE=1` (or `{"commitGate": true}` in `.claude/superflow.json`) and a bare `git commit` is blocked until it goes through this skill. Off by default.
- `/superflow:design` — screen → design spec → **interactive mock the user locks** → build brief for `codezilla`. Specs propose; mocks decide.
- `/superflow:review-sweep` — adversarial review sweep over a large diff (workflow; expensive — epic gates only).

Loaded on demand, not addressed as commands: `superflow:ui-reduction` (the declutter method, fired by designer's gate) and `superflow:handoff-contracts` (JSON handoff schemas for the weave).
