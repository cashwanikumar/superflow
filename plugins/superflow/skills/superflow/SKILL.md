---
name: superflow
description: The front door for non-trivial coding work in this repo — pairs a process skill (brainstorming for builds, systematic-debugging for bugs, receiving-code-review for review feedback) with the right specialist persona, in the right order. Load when deciding how to approach a build, bug, review, or design task, or when unsure which skill/persona applies.
---

# superflow — the full-flow front door

superflow weaves two things into one pipeline: **process skills** (vendored from Superpowers — TDD, brainstorming, systematic-debugging, plans, code-review, verification, worktrees; addressed here as `superflow:<name>`) and **five personas** (sherlock, architect, designer, codezilla, bughunter). Each stage loads only the skill it needs and spawns only the personas the task needs. Spawn the minimum; skip what doesn't apply.

## 1. Skill-check (always-on, lightweight)

Before acting on any non-trivial coding turn, if a process skill fits the work, **invoke it first** — this is cheap and always on, independent of the opt-in gate below:

| The work is… | Invoke first |
|---|---|
| a build / new feature / behavior change | `superflow:brainstorming` |
| a bug / test failure / unexpected behavior | `superflow:systematic-debugging` |
| responding to code-review feedback | `superflow:receiving-code-review` |

**`using-superpowers` owns the mechanics; this table owns the dispatch.** That skill is the authority on *how* skills are found, announced, and prioritized — load it for any of that, and where it and this section disagree on process, it wins. What this table adds is the resolved `superflow:`-prefixed name to invoke (§3 explains why the bare name is not safe) plus the review-feedback row.

## 2. Opt-in gate (before spawning personas)

> **Main agent only.** A spawned persona skips this gate: don't ask the opt-in, don't re-route, don't delegate onward unless the task requires it. Execute the persona's job and return. (Still consult the rulebook before any code change.)

**This section is the single source of the gate.** The SessionStart hook injects a short pointer to it; if the hook and this file ever disagree, this file wins and the hook is the bug.

Cheap exits, every mode:

- **Slash command** (message begins with `/`) → run it; skip the opt-in.
- **Trivial** → answer directly; no opt-in, no personas. Trivial means: a lookup, a file read, an explanation, **or any question or opinion where no code change is asked for**. "Is this design good?", "what does X do?", "should we…?" are answered, not routed.

Everything else depends on `SUPERFLOW_FLOW` (`auto` default, `always`, `never`), which the hook resolves and states.

**`auto`, human in the loop** — positive evidence a person is reading this session: a human-authored reply, an earlier answered question, an interruption. Ask **once** and wait:

> Run the full superflow for this? It would: \<one line tailored to THIS task — which personas, in what order\>. (yes / no)

- **yes** → run the weave (§3) via the Agent tool.
- **no** → work directly, no sub-agents; don't raise personas again this turn.
- **Already opted in earlier this session** for the same kind of work → skip the question and proceed.

**`auto`, no human in the loop** (headless, `-p`, CI, or no evidence anyone can reply) — do **not** ask. Decide **before touching anything** and open your reply with the choice, verbatim and alone on the first line: `superflow: weave — <reason>` or `superflow: direct — <reason>`. That line is the run's only audit trail.

**Headless default is `direct`.** The weave has to earn its spawns. Run it when **any** trigger fires:

| | Weave trigger |
|---|---|
| a | **More than one capability.** An "and" joining two features, or a request naming two user-facing behaviors. |
| b | **UI work.** A screen, page, component, layout, or visual change. |
| c | **Cross-layer.** The change touches more than one of: schema/model, API/backend, frontend, infra — or you cannot name up front the files you will edit. |

None fire → `direct`. Direct still means rulebook-first, TDD via the skill-check, and real-path verification; it only skips the persona spawns. If you claimed `direct` and the change grows past the triggers mid-task, say so plainly in the final message.

**`always` / `never`** — no judgement call: always run the weave, or never spawn it. Pin one for unattended runs where you want deterministic behavior.

## 3. The weave (stage → process skill + persona)

Skip any stage that doesn't apply.

**Always dispatch with the `superflow:` prefix** — `superflow:codezilla` as the `subagent_type`, never bare `codezilla`. Bare names either fail to resolve or silently hit a same-named agent in the user's own `~/.claude/agents/`, which has never seen this protocol. Same for skills: `superflow:test-driven-development`.

| Stage | Superpowers skill | Persona |
|---|---|---|
| Understand | `superflow:brainstorming` | `superflow:sherlock` |
| Plan | `superflow:writing-plans` | `superflow:architect` |
| Isolate | `superflow:using-git-worktrees` | — |
| Design (UI) | `superflow:design` (mock-locked) · `superflow:ui-reduction` (declutter) | `superflow:designer` |
| Build + unit tests | `superflow:test-driven-development` | `superflow:codezilla` (consults rulebook) |
| Verify | `superflow:verification-before-completion` | `superflow:bughunter` (functional, convention, security, a11y) |
| Review | `superflow:requesting-code-review` / `superflow:receiving-code-review` · `/superflow:review-sweep` for big diffs | `superflow:architect` |
| Debug | `superflow:systematic-debugging` | `superflow:sherlock` → `superflow:bughunter` |
| Finish | `superflow:finishing-a-development-branch` | — (`/superflow:codebase-rulebook --refresh` if a convention changed) |

**Handoffs.** Prose relays lose caveats silently. When one persona's output feeds another, ask the upstream persona to end its report with a short **Handoff** section (what to do, files that matter, constraints, gotchas, out of scope, open questions) and paste that section verbatim into the next spawn. If it's missing, ask that agent once; don't paraphrase around it.

### Deterministic workflows (the expensive calls)

| Command | What it does | When |
|---|---|---|
| `/superflow:council` | Confirms the decision text, then runs `council-vote`: four schema-forced independent votes, architect synthesizes. | Hard, expensive-to-reverse calls. |
| `/superflow:review-sweep` | Partitions the diff into slices, one `bughunter` per slice, then one skeptic per finding → CONFIRMED / PLAUSIBLE tiers. | Epic gates and diffs >~5 files ONLY — expensive. Small PRs get a plain `bughunter` pass. |

Both are opt-in and neither runs itself. If Dynamic workflows are unavailable, say so and fall back to the conversational equivalent rather than pretending the run happened.

## 4. Rulebook-first

Before **any** code change, consult `CODEBASE_RULEBOOK.md` at the repo root and conform to it — it is what lets these generic personas fit *this* repo. If it's missing, offer to run **`/superflow:codebase-rulebook`** first. If a change would violate it, stop and ask: exception, or update the rulebook? Never invent rules that aren't in it.

## 5. Minimum-spawn

- Load only the process skill the current step touches; spawn only the personas the task needs.
- **Green tests are necessary, not sufficient.** For any user-facing change, verify by exercising the real path in the running app (run it / hit the endpoint / load the page) — see `verification-before-completion`.
- Knowledge lives in the on-demand skills and the rulebook, not in always-on context.

## Personas (5)

| Persona | Role |
|---|---|
| `sherlock` | Read-only investigator; maps the terrain before others act. Also runs the rulebook scan. |
| `architect` | Plans (user, problem, metric, then design) and reviews. Scalability, boundaries, tradeoffs. Not the default builder. |
| `designer` | UX/UI spec before code (read-only). |
| `codezilla` | Implementer; tight code, consults the rulebook, writes the unit tests. |
| `bughunter` | Adversarial QA: functional, convention, security, and accessibility (WCAG 2.0 AA) findings. |

## Commands

- `/superflow:codebase-rulebook` — scan the repo → write `CODEBASE_RULEBOOK.md`. `--refresh` to update.
- `/superflow:council` — four-lens deliberation on a hard decision; architect synthesizes.
- `/superflow:review-sweep` — adversarial review sweep over a large diff (workflow; expensive — epic gates only).
- `/superflow:design` — screen → design spec → **interactive mock the user locks** → build brief for `codezilla`. Specs propose; mocks decide.
- `/superflow:commit-prep` — summarize the diff + propose a commit message (doesn't commit unless asked). Optional hard gate: `SUPERFLOW_COMMIT_GATE=1` or `{"commitGate": true}` in `.claude/superflow.json`. Off by default.
- `/superflow:daily-brief` — fast session start: where you left off + the next action.
- `/superflow:handoff` — end-of-session handoff summary.

Loaded on demand, not typed: `superflow:ui-reduction` (the declutter method behind designer's gate).
