---
name: superflow
description: The front door for non-trivial coding work in this repo — pairs a process skill (brainstorming for builds, systematic-debugging for bugs, receiving-code-review for review feedback) with the right specialist persona, in the right order. Load when deciding how to approach a build, bug, review, or design task, or when unsure which skill/persona applies.
---

# superflow — the full-flow front door

superflow weaves two things into one pipeline: **process skills** (vendored from Superpowers — TDD, brainstorming, systematic-debugging, plans, subagent-driven development, code-review, verification, worktrees; addressed here as `superflow:<name>`) and **five personas** (sherlock, architect, designer, codezilla, bughunter). Each stage loads only the skill it needs and spawns only the personas the task needs. Spawn the minimum; skip what doesn't apply.

**This file is the single source of the protocol.** The SessionStart hook emits only a pointer to it; nothing else restates the gate, the weave, or the rulebook rule.

## 1. Skill-check (always-on, lightweight)

Before acting on any non-trivial coding turn — including before clarifying questions or exploring the codebase — if a process skill fits the work, **invoke it first**, announce "Using `<skill>` to `<purpose>`", and follow it. If it turns out not to fit, drop it. This is cheap and always on, independent of the opt-in gate below. User instructions (CLAUDE.md, direct requests) take precedence over any skill.

| The work is… | Invoke first |
|---|---|
| a build / new feature / behavior change | `superflow:brainstorming` |
| a bug / test failure / unexpected behavior | `superflow:systematic-debugging` |
| responding to code-review feedback | `superflow:receiving-code-review` |

Always use the resolved `superflow:`-prefixed name (§3 explains why the bare name is not safe).

## 2. Opt-in gate (before spawning personas)

> **Main agent only.** A spawned persona skips this gate: don't ask the opt-in, don't re-route, don't delegate onward unless the task requires it. Execute the persona's job and return. (Still consult the rulebook before any code change.)

Cheap exits, every mode:

- **Slash command** (message begins with `/`) → run it; skip the opt-in.
- **Trivial** → answer directly; no opt-in, no personas. Trivial means: a lookup, a file read, an explanation, **or any question or opinion where no code change is asked for**. "Is this design good?", "what does X do?", "should we…?" are answered, not routed.

Everything else depends on `SUPERFLOW_FLOW` (`auto` default, `always`, `never`), which the hook states:

- **`auto`** — before the first persona spawn of the session, ask **once** and wait:

  > Run the full superflow for this? It would: \<one line tailored to THIS task — which personas, in what order\>. (yes / no)

  **yes** → run the weave (§3) via the Agent tool. **no** → work directly, no sub-agents. Remember the answer for the rest of the session; don't ask again. If the session cannot return a reply (`-p`, CI, a run with nobody reading), a question only stalls it — work **direct** and say so in one line of the final message.
- **`always`** — never ask; run the weave on every non-trivial turn.
- **`never`** — never ask, never spawn personas; work directly.

Direct still means rulebook-first, the skill-check in §1, and real-path verification; it only skips the persona spawns. `brainstorming` classifies the work (spike / bounded / architectural) and ends every path with your human partner's approval; when no reply is possible, state the classification and the design in the final message, proceed, and say plainly that the approval gate could not be satisfied. Pin `always` or `never` for unattended runs where you want deterministic behavior.

## 3. The weave (stage → process skill + persona)

Skip any stage that doesn't apply.

**Always dispatch with the `superflow:` prefix** — `superflow:codezilla` as the `subagent_type`, never bare `codezilla`. Bare names either fail to resolve or silently hit a same-named agent in the user's own `~/.claude/agents/`, which has never seen this protocol. Same for skills: `superflow:test-driven-development`.

| Stage | Superpowers skill | Persona |
|---|---|---|
| Understand | `superflow:brainstorming` | `superflow:sherlock` |
| Plan | `superflow:writing-plans` | `superflow:architect` (design; what & why come from brainstorming with the human — cite the ticket/spec, don't restate it) |
| Isolate | `superflow:using-git-worktrees` | — |
| Design (UI) | `superflow:design` (mock-locked) · `superflow:ui-reduction` (declutter) | `superflow:designer` |
| Build + unit tests | `superflow:subagent-driven-development` (fresh implementer per task, spec + quality review per task, rulings ledger) · `superflow:test-driven-development` inside each task | `superflow:codezilla` as the implementer `subagent_type`; SDD's reviewer prompts as written |
| Verify | `superflow:verification-before-completion` | `superflow:bughunter` (functional, convention, security, a11y) |
| Review | `superflow:requesting-code-review` / `superflow:receiving-code-review` · `/superflow:review-sweep` for big diffs | `superflow:architect` |
| Debug | `superflow:systematic-debugging` | `superflow:sherlock` → `superflow:bughunter` |
| Finish | `superflow:finishing-a-development-branch` | — (`/superflow:codebase-rulebook --refresh` if a convention changed) |

**Build stage.** The plan is worked by `superflow:subagent-driven-development`, not by one long-lived agent: dispatch each implementer with `subagent_type: superflow:codezilla` and SDD's implementer prompt (brief file, report file, self-review), keep SDD's task reviewer and re-review prompts as written, and record rulings in its ledger. Tightly coupled tasks, or direct mode with no personas, run `superflow:executing-plans` inline instead. Independent non-plan work fans out via `superflow:dispatching-parallel-agents`.

**Handoffs.** Prose relays lose caveats silently. When one persona's output feeds another, ask the upstream persona to end its report with a short **Handoff** section (what to do, files that matter, constraints, gotchas, out of scope, open questions) and paste that section verbatim into the next spawn. If it's missing, ask that agent once; don't paraphrase around it.

### Deterministic workflows (the expensive calls)

| Command | What it does | When |
|---|---|---|
| `/superflow:council` | Confirms the decision text, then runs `council-vote`: four schema-forced independent votes (architect, bughunter, codezilla, product-owner lens), sherlock grounds, architect synthesizes. | Hard, expensive-to-reverse calls. |
| `/superflow:review-sweep` | Partitions the diff into slices, one `bughunter` per slice, then one skeptic per finding → CONFIRMED / PLAUSIBLE tiers. | Epic gates and diffs >~5 files ONLY — expensive. Small PRs get a plain `bughunter` pass. |

Both are opt-in and neither runs itself. If Dynamic workflows are unavailable, say so and fall back to the conversational equivalent rather than pretending the run happened.

## 4. Rulebook-first

Before **any** code change, consult the relevant section(s) of `CODEBASE_RULEBOOK.md` at the repo root and conform — it is what lets these generic personas fit *this* repo. If it's missing, offer to run **`/superflow:codebase-rulebook`** first; when nobody can answer, run it and say in the final message that the rulebook was written. If a change would violate the rulebook, stop and ask: exception, or update the rulebook? When nobody can answer, note the violation in the final message instead of stalling. Never invent rules that aren't in it.

## 5. Minimum-spawn

- Load only the process skill the current step touches; spawn only the personas the task needs.
- **Green tests are necessary, not sufficient.** For any user-facing change, verify by exercising the real path in the running app (run it / hit the endpoint / load the page) — see `verification-before-completion`. If the environment blocks that, say so plainly rather than implying it was verified.
- Knowledge lives in the on-demand skills and the rulebook, not in always-on context.

## Personas

| Persona | Role |
|---|---|
| `sherlock` | Read-only investigator; maps the terrain before others act. Also runs the rulebook scan. |
| `architect` | Technical design and review. Scalability, boundaries, tradeoffs. Not the default builder. |
| `designer` | UX/UI spec before code (read-only). |
| `codezilla` | Implementer; tight code, consults the rulebook, writes the unit tests. Runs as SDD's implementer in the Build stage. |
| `bughunter` | Adversarial QA: functional, convention, security, and accessibility (WCAG 2.0 AA) findings. |

## Commands

- `/superflow:codebase-rulebook` — scan the repo → write `CODEBASE_RULEBOOK.md`. `--refresh` to update.
- `/superflow:council` — four-voice deliberation (architect, bughunter, codezilla, product-owner lens; sherlock grounds) on a hard decision; architect synthesizes.
- `/superflow:review-sweep` — adversarial review sweep over a large diff (workflow; expensive — epic gates only).
- `/superflow:design` — screen → design spec → **interactive mock the user locks** → build brief for `codezilla`. Specs propose; mocks decide.

Loaded on demand, not typed: `superflow:ui-reduction` (the declutter method behind designer's gate).
