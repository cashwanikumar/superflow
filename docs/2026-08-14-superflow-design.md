# superflow — design spec

_Date: 2026-08-14 · Status: approved (design), pending implementation plan_

## 1. Overview

`superflow` is a **new, self-contained Claude Code plugin** that combines two existing plugins into one portable "full-flow" development toolkit:

- **agent-circus** (Marvin-internal): routed coding **personas** (finder, designer, dev, testers, bughunter, a11y-hunter, architect, auditor, pm) + a per-repo **rulebook** mechanism.
- **Superpowers** (obra, MIT): 14 harness-agnostic **process skills** (brainstorming, TDD, systematic-debugging, plans, code-review, verification, worktrees, etc.).

The result is one plugin that can be dropped into **any** repository and provides a coherent pipeline: brainstorm → plan → build (TDD) → verify → review → finish, driven by specialist personas, with each project's conventions captured in its own generated rulebook.

## 2. Goals / Non-goals

**Goals**
- Truly generic — works in any repo, any stack (not Marvin-specific).
- Self-contained — one install, no dependency on agent-circus or Superpowers being present.
- Portable distribution — a private git **marketplace** repo.
- Opt-in cost control — heavy multi-persona pipeline runs only when the user says so.

**Non-goals**
- Not shipping Marvin-specific skills (ui-kit, Redux data-fetching, DRF, icons, pubsub, event-tracking, in-app-interviewer, the Marvin test stacks). Those are replaced by each repo's generated `CODEBASE_RULEBOOK.md`.
- Not auto-updating the vendored Superpowers skills (accepted cost of self-containment).
- Not re-authoring the Superpowers skills — they are vendored verbatim under MIT with attribution.

## 3. Key decisions (locked)

| Decision | Choice | Why |
|---|---|---|
| Portability | **Truly generic** (any repo) | Drop the 8 Marvin skills; rely on the self-scanning `codebase-rulebook`. |
| Distribution | **Private git marketplace** | `/plugin marketplace add <repo>` → central updates, shareable. |
| Engagement | **Opt-in per task** | Always-on lightweight skill-check; ask once before spawning the persona pipeline. |
| Structure | **One unified plugin** | Matches "self-contained, drop into multiple projects". |

## 4. Architecture / repository layout

```
superflow/                                      # git repo (= private marketplace)
├── .claude-plugin/marketplace.json             # registers the plugin
├── README.md                                   # what it is, install steps
├── LICENSE                                      # MIT
├── ATTRIBUTION.md                              # credits obra/superpowers (MIT) + Marvin agent-circus
└── plugins/superflow/
    ├── .claude-plugin/plugin.json              # name, version, author, keywords
    ├── agents/                                 # 10 generalized personas (forked from agent-circus)
    │   ├── finder.md  pm.md  designer.md  dev.md
    │   ├── fe-unit-tester.md  be-unit-tester.md
    │   ├── bughunter.md  a11y-hunter.md  architect.md  auditor.md
    ├── commands/                               # 5 generalized (package-skills dropped)
    │   ├── codebase-rulebook.md  commit-prep.md  council.md
    │   ├── daily-brief.md  handoff.md
    ├── hooks/
    │   ├── hooks.json
    │   └── session-start.sh                    # injects opt-in flow protocol + skill-check
    └── skills/
        ├── superflow/SKILL.md                  # NEW: merged routing / full-flow map (front door)
        ├── using-superpowers/                  # vendored (SKILL.md + references/{codex,gemini,pi,antigravity}-tools.md)
        ├── brainstorming/                      # vendored (SKILL.md + visual-companion.md + scripts/ + reviewer prompt)
        ├── writing-plans/                      # vendored (SKILL.md + plan-document-reviewer-prompt.md)
        ├── writing-skills/                     # vendored (SKILL.md + best-practices, persuasion, examples/, graphviz)
        ├── test-driven-development/            # vendored (SKILL.md + writing-good-tests.md)
        ├── systematic-debugging/               # vendored (SKILL.md + 10 helper files)
        ├── verification-before-completion/     # vendored (SKILL.md)
        ├── requesting-code-review/             # vendored (SKILL.md + code-reviewer.md)
        ├── receiving-code-review/              # vendored (SKILL.md)
        ├── subagent-driven-development/        # vendored (SKILL.md + prompts + scripts/)
        ├── dispatching-parallel-agents/        # vendored (SKILL.md)
        ├── executing-plans/                    # vendored (SKILL.md)
        ├── using-git-worktrees/                # vendored (SKILL.md)
        └── finishing-a-development-branch/     # vendored (SKILL.md)
```

Counts: **10 agents · 5 commands · 2 hook files · 15 skills** (14 vendored Superpowers + 1 new `superflow`) · 4 top-level files.

Install anywhere: `/plugin marketplace add <git-url>` → `/plugin install superflow`.

_Note (2026-08): the `commands/` directory shown above has since merged into `skills/` — the 5 commands ship as namespaced invocable skills (`skills/<name>/SKILL.md`). The filesystem is the source of truth._

## 5. Component: generalized personas

Each persona keeps its **identity + workflow**. Substantive edits only where Marvin specifics leak:

- **dev.md** — remove the "Load the matching skill" Marvin table (`marvin-ui-kit`, `@marvin/*`, DRF/celery). Replace with: "Before building, consult this repo's `CODEBASE_RULEBOOK.md` and conform; load `test-driven-development` for method and `systematic-debugging` for bugs. If a convention isn't in the rulebook, follow the surrounding code."
- **fe-unit-tester.md / be-unit-tester.md** — drop Marvin's exact stack (Vitest+RTL MockProvider / pytest fixtures). Replace with: "read the repo's existing test config + a sibling test, mirror it; load `test-driven-development` for method."
- **finder / designer / bughunter / a11y-hunter / architect / pm** — strip incidental Marvin examples → generic phrasing or "per the rulebook." `a11y-hunter` keeps WCAG 2.0 AA.
- **auditor** — unchanged in spirit; it **owns** generating `CODEBASE_RULEBOOK.md`, which is what makes the plugin portable.

Interface for each persona: **input** = a scoped task prompt; **output** = its work product (map / spec / diff / findings / verdict); **depends on** = the repo's rulebook + the process skill it's told to load. Personas do not depend on each other's internals.

## 6. Component: the `superflow` skill (front door)

`skills/superflow/SKILL.md` is the entry point and does five things:

1. **Skill-check (always-on, lightweight):** before acting, if a process skill fits — `brainstorming` (build), `systematic-debugging` (bug), `receiving-code-review` (review feedback) — invoke it first. References `using-superpowers`; does not duplicate it.
2. **Opt-in gate:** for non-trivial build/review/debug, ask once *"Run the full flow? (yes/no)"* with a one-line tailored plan (which personas, in what order). `no` → answer directly, no personas.
3. **The weave** (stage → method skill + persona):

   | Stage | Superpowers skill | Persona |
   |---|---|---|
   | Understand | brainstorming | finder |
   | Plan | writing-plans | pm / architect |
   | Isolate | using-git-worktrees | — |
   | Design (UI) | — | designer |
   | Build | test-driven-development | dev (consults rulebook) |
   | Verify | verification-before-completion | fe/be-unit-tester, bughunter, a11y-hunter |
   | Review | requesting- / receiving-code-review | architect |
   | Debug | systematic-debugging | finder → bughunter |
   | Finish | finishing-a-development-branch | auditor (rulebook refresh) · pm (specbook fold-back, if a change folder is open) |

4. **Rulebook-first:** before any code change, consult `CODEBASE_RULEBOOK.md`; if missing, offer to run `/codebase-rulebook` first.
5. **Minimum-spawn:** load only the skill the step touches; spawn only the personas the task needs. Skip stages that don't apply.

## 7. Commands (kept, generalized)

- **codebase-rulebook** — scans the current repo → writes `CODEBASE_RULEBOOK.md` (the portability keystone). `--refresh` to update.
- **specbook** _(added 2026-08, see §12)_ — bootstraps `specbook/`, the opt-in persistent spec layer. `--refresh` / `--change <slug>` / `--archive <slug>` / `--dry-run`.
- **commit-prep** — summarize the diff + propose a commit message (doesn't commit unless asked).
- **council** — multi-voice deliberation (architect, pm, dev, bughunter, finder) on a hard decision.
- **daily-brief** — session start: where you left off + next action.
- **handoff** — end-of-session handoff summary.
- **Dropped:** `package-skills` (regenerated Marvin in-house package skills — not applicable generically).

## 8. Hooks

- **session-start.sh** — injects a short pointer to the `superflow` protocol each session (so the skill-check + opt-in gate are live), mirroring agent-circus's SessionStart injection but generalized (no Marvin references, points at `superflow`/rulebook). The heavy pipeline stays opt-in.
- **hooks.json** — registers the SessionStart hook.

## 9. Licensing / attribution

- Superpowers is **MIT** (obra / Jesse Vincent) — vendoring verbatim is permitted; `LICENSE` (MIT) + `ATTRIBUTION.md` retained and credited.
- agent-circus is Marvin-internal — this is a fork of Marvin's own personas/commands, generalized; credited in `ATTRIBUTION.md`.

## 10. Risks / tradeoffs

- **Vendored drift:** the 14 Superpowers skills won't auto-update. Mitigation: a documented "resync from upstream" step in the plugin README (copy from the installed Superpowers cache / the obra repo).
- **`using-superpowers` vs `superflow` overlap:** resolved by making `superflow` the front door and having it *reference* `using-superpowers` rather than both competing as entry points.
- **Persona generalization completeness:** all 10 persona files mention Marvin somewhere; the edit must catch incidental references, not just the dev skill-table. A grep gate (`marvin|@marvin|chakra|redux|drf|ui-kit`) over `agents/` should return clean before release.
- **Genericness vs power:** without the Marvin skills, first-run value in a Marvin repo is lower until `/codebase-rulebook` has run. Mitigation: the flow prompts to generate the rulebook first.

## 11. Open questions (for implementation plan)

- Final plugin **name** (`superflow` is a working title).
- Which **git host** for the marketplace repo (GitHub org? personal?).
- Whether the SessionStart hook should be **opt-in to install** (some users may not want per-session injection).

## 12. Addendum (2026-08): specbook — persistent spec layer

OpenSpec-inspired ([Fission-AI/openspec](https://github.com/Fission-AI/openspec)) but superflow-native: a durable, committed spec layer in target repos, so requirements outlive the conversation. The rulebook records *how* the repo builds; the specbook records *what* it must do.

Target-repo layout (created by `/superflow:specbook`):

```
specbook/
  README.md                      # orientation stub; declares the path preferences
  specs/<capability>.md          # living per-capability requirements (R1, R2… with Given/When/Then scenarios)
  changes/YYYY-MM-DD-<slug>/     # one folder per in-flight change
    proposal.md                  # pm: what & why + Spec deltas (fold-back-ready)
    design.md                    # technical design (brainstorming's output lands here)
    tasks.md                     # implementation plan (writing-plans' output lands here)
  archive/YYYY-MM-DD-<slug>/     # completed changes, moved after fold-back
```

Locked rules:

- **Opt-in per repo** — spec awareness activates only when `specbook/` exists; superflow never creates it unprompted, and headless runs never mention it when absent.
- **Vendored skills untouched** — the layer rides the "user preferences override spec/plan location" escape hatch in `brainstorming`/`writing-plans`, declared by the hook, the front-door skill, and the generated `specbook/README.md`.
- **Ownership split** — `pm` owns every write inside `specbook/` (proposal at Plan, fold-back + archive at Finish); `auditor` still writes only `CODEBASE_RULEBOOK.md`.
- **Minimum-spawn preserved** — a change folder opens only when the Plan stage runs (or `--change`); pm joins Finish only when a change folder is open.
