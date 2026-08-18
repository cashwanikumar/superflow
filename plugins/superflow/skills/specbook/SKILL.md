---
name: specbook
description: Bootstrap and maintain specbook/ — this repo's persistent spec layer (living per-capability specs with scenario acceptance criteria, plus one folder per change holding proposal/design/tasks, archived and folded back on finish). Use ONLY when the user runs /superflow:specbook or explicitly asks to create, refresh, open, or archive specs. Never activate just because specbook/ is missing — the layer is opt-in per repo.
---

# Specbook

Durable requirements that outlive the conversation. `CODEBASE_RULEBOOK.md` records *how* this repo builds; `specbook/` records *what* it must do. Living per-capability specs carry scenario-checkable requirements; each non-trivial change gets its own folder (proposal / design / tasks); finished changes are archived and their spec deltas folded back into the living specs.

**Opt-in per repo.** The layer exists only in repos where this command was run once. Never bootstrap it because the directory is missing — that decision belongs to the user, and headless runs never create or mention it.

This command is inspect-only except for writing inside `specbook/`.

---

## How to invoke

```
/superflow:specbook                        # bootstrap — create specbook/, derive baseline capability specs from the codebase
/superflow:specbook --refresh [capability] # re-derive living specs vs current code (all, or one); preserve human edits
/superflow:specbook --change <slug>        # open specbook/changes/YYYY-MM-DD-<slug>/ with proposal/design/tasks stubs
/superflow:specbook --archive <slug>       # fold the proposal's Spec deltas into specs/, move the folder to archive/
/superflow:specbook --dry-run              # combinable with any form: show what would be written without writing
```

---

## Lead behavior

`bossbaby` frames the run and owns every write — bossbaby's description says it owns specs, and this is where that ownership lives. Three modes:

**Bootstrap / `--refresh`:**

1. Confirm the repo root (quick `git status` + file tree).
2. If `specbook/` already exists and `--refresh` was not passed, ask:
   > A specbook already exists. Refresh it? (yes / no / dry-run)
3. Delegate the terrain map to `sherlock` with the brief below.
4. From sherlock's capability list, derive **5–12 capability specs** — one per *user-meaningful capability* (auth, billing, search…), never one per file or module.
5. Write `specbook/README.md`, `specbook/specs/<capability>.md` for each, and create empty `changes/` and `archive/` directories.
6. Summarize: `<N> capability specs written, <M> open questions`.
7. Tell the user the specbook is now in effect — the weave will read and write it from here on.

**`--change <slug>`:** create `specbook/changes/YYYY-MM-DD-<slug>/` with the three stubs from the templates below. Nothing else.

**`--archive <slug>`:** read the change's `proposal.md` Spec deltas; apply each ADDS / CHANGES / REMOVES to `specs/<capability>.md` verbatim (create the file from the capability template for NEW SPEC); update each touched spec's "Last updated" line; move the whole folder to `archive/`; confirm what changed in one paragraph. Fold-back always happens before the move — an archived change whose deltas never landed is a silent spec lie.

---

## sherlock assignment (bootstrap/refresh only)

```text
Owner: `sherlock`
Objective: Map this repo's user-facing capabilities so bossbaby can write baseline specs.
Scope:
  - Entry points: routes, CLI commands, screens/pages, public APIs, jobs/schedulers
  - Tests as behavior evidence: what the suite asserts the system does
  - Repo docs: README, docs/, CODEBASE_RULEBOOK.md, CHANGELOG
Constraints:
  - Read-only. No installs, builds, or mutating commands.
  - Report capabilities with file:line evidence; flag guesses as guesses.
Expected output:
  - Candidate capability list, each with a 1-line purpose + evidence paths.
Validation: Read-only commands only (Glob, Grep, Read).
```

---

## bossbaby assignment (bootstrap/refresh)

```text
Owner: `bossbaby`
Objective: Write specbook/specs/<capability>.md for each confirmed capability.
Constraints:
  - Behavior only, never implementation. A spec that names a framework is broken.
  - Every requirement must be scenario-checkable (a tester could pass/fail it).
  - Anything derived from code but unverified goes under Open questions,
    marked "Baseline — derived from code, verify". Code can encode bugs;
    baseline specs must stay falsifiable, not authoritative.
  - On --refresh, preserve any sections marked <!-- human-edited -->.
  - Write only inside specbook/.
```

---

## Templates

### specbook/README.md (generated at bootstrap)

```md
# Specbook

This repo keeps a persistent spec layer, maintained by superflow (`/superflow:specbook`).

- `specs/` — living per-capability requirements. The source of truth for *what* this
  system must do (the `CODEBASE_RULEBOOK.md` covers *how* it's built).
- `changes/YYYY-MM-DD-<slug>/` — one folder per in-flight change: `proposal.md`
  (what & why + spec deltas), `design.md` (technical design), `tasks.md` (implementation plan).
- `archive/` — completed changes, moved here after their deltas are folded into `specs/`.

Preferred locations for this repo (skills that default elsewhere defer to these):
design docs → `changes/<change>/design.md`; implementation plans → `changes/<change>/tasks.md`.
The change folder's name already carries the date and topic.
```

### Living capability spec — `specs/<capability>.md`

```md
# <Capability>

_Part of this repo's specbook. Last updated: YYYY-MM-DD (change: <slug> | baseline)._

## Purpose
One paragraph: what this capability does, for whom.

## Requirements

### R1. <One testable sentence>
- Scenario: <name>
  - Given <starting state>
  - When <action>
  - Then <observable outcome>

### R2. ...

## Boundaries
- Out of scope: ...
- Depends on: <other capability specs, if any>

## Open questions
- ...
```

### proposal.md — bossbaby's spec, fold-back-ready

```md
# Proposal: <change title>

_Change: <slug> · Opened: YYYY-MM-DD · Status: active_

## Context & motivation
## Goals & non-goals
## User stories
## Spec deltas
For each affected spec: the operation, then the added/changed requirements written
IN FULL (heading + scenarios), exactly as they should read in specs/<capability>.md
after this ships.
- `specs/<capability>.md` — ADDS R4 / CHANGES R2 / REMOVES R3 / NEW SPEC
## Out of scope
## Success metrics
## Open questions
## Rollout
```

### design.md (stub)

```md
# Design: <change title>

Written by the brainstorming skill / architect. Technical decisions, not
requirements — requirements live in proposal.md.
```

### tasks.md (stub)

```md
# Tasks: <change title>

Written by the writing-plans skill. Keep tasks as `- [ ]` checkbox items so
executing-plans / subagent-driven-development can consume this file unchanged.
```

---

## How the specbook is used afterward

Once `specbook/` exists, the weave reads and writes it (the session-start hook injects the reminder; the `superflow` skill carries the detail):

- **Understand** — sherlock reads the affected `specs/*.md` and scans `changes/` for overlapping in-flight work.
- **Plan** — the lead opens the change folder; bossbaby writes `proposal.md`; the technical design goes in `design.md`; the plan goes in `tasks.md`.
- **Build** — codezilla reads `proposal.md` (the what) and works `tasks.md`; the rulebook stays the how.
- **Verify** — bughunter tests against the affected specs' Scenarios plus the proposal.
- **Review** — the change folder path fills the code-review request's requirements slot.
- **Finish** — bossbaby folds the proposal's Spec deltas into `specs/` and moves the folder to `archive/` (the `--archive` behavior above).

The path-preference seam, stated once and verbatim: **once `specbook/` exists, the repo's preferred spec location is `specbook/changes/<change>/design.md` and its preferred plan location is `specbook/changes/<change>/tasks.md` — skills that default to `docs/superpowers/{specs,plans}` defer to these.**

---

## Rules

- Opt-in only: never run because the directory is missing; headless runs never create it.
- bossbaby is read-only outside `specbook/`. auditor never writes inside it.
- Specs record behavior (*what*), never implementation (*how*).
- `--archive` is the only way a change folder leaves `changes/`; fold-back before move, always.
- `--refresh` preserves `<!-- human-edited -->` sections.
- `--dry-run` prints what would be written without modifying anything.
- A change folder is opened only by the Plan stage of the weave or by `--change`.
