# superflow

A portable Claude Code plugin that turns non-trivial coding work into one pipeline — brainstorm → plan → build (TDD) → verify → review — run by six specialist personas and disciplined by the process skills of [Superpowers](https://github.com/obra/superpowers). It fits any repo by scanning that repo's own conventions into a `CODEBASE_RULEBOOK.md`.

## Install

```
/plugin marketplace add https://github.com/cashwanikumar/superflow
/plugin install superflow
```

Or from the terminal: `claude plugin marketplace add https://github.com/cashwanikumar/superflow && claude plugin install superflow@superflow` (`--scope user|project|local`). Restart the session so the SessionStart hook fires; `/plugin` should show superflow with 6 personas, 18 skills, 2 workflows, all addressed as `superflow:<name>`.

Then, once per repo:

```
/superflow:codebase-rulebook
```

That writes `CODEBASE_RULEBOOK.md` — the conventions every persona conforms to. Without it the personas are generic; with it they fit your codebase.

Update: `claude plugin marketplace update superflow && claude plugin update superflow@superflow` (restart to apply). Uninstall: `claude plugin uninstall superflow@superflow`. Both need the `@superflow` suffix and the same `--scope` you installed with.

## How it works

Every turn gets a cheap check; the expensive part sits behind one gate.

```mermaid
flowchart LR
    A([Your message]) --> T{trivial?}
    T -->|"question, lookup, opinion"| D([Answer directly])
    T -->|"code change"| G{"Run the full flow?"}
    G -->|no| S["You + the process skills, in-thread"]
    G -->|yes| W["The weave: skill + persona per stage,<br/>only the stages that apply"]
```

**The weave**, in order; each stage is skipped when it doesn't apply:

| Stage | Process skill | Persona |
|---|---|---|
| Understand | brainstorming | `sherlock` (read-only map) |
| Plan | writing-plans | `bossbaby` (what & why) → `architect` (design) |
| Isolate | using-git-worktrees | — |
| Design (UI) | design · ui-reduction | `designer` → mock you click and lock |
| Build + unit tests | test-driven-development | `codezilla` |
| Verify | verification-before-completion | `bughunter` (functional · convention · security · a11y) |
| Review | requesting/receiving-code-review | `architect` |
| Debug | systematic-debugging | `sherlock` → `bughunter` |

A one-line fix runs three stages; a full-stack feature runs all of them. Saying **yes** is the cost control — it's what spawns personas and pulls in worktrees.

Two calls are expensive enough to be scripted rather than left to the model:

- `/superflow:council` — a hard, expensive-to-reverse decision. Independent schema-forced votes from `architect`, `bughunter`, `codezilla`, `bossbaby`; `architect` synthesizes. A dropped or abstaining voice is reported, never silently missing.
- `/superflow:review-sweep` — epic gates and diffs over ~5 files. The diff is partitioned, one `bughunter` per slice, then a dedicated skeptic per finding. Survivors come back **CONFIRMED** (traced end to end) or **PLAUSIBLE** (undecidable from code alone, never dropped for want of a repro). Needs Dynamic workflows enabled (`/config` on Pro).

Other commands: `/superflow:design` (spec → interactive mock → build brief), `/superflow:commit-prep`, `/superflow:daily-brief`, `/superflow:handoff`.

## Unattended runs

`SUPERFLOW_FLOW` controls the gate: `auto` (default — ask when a human is present; headless, run **direct** unless the change spans two capabilities, touches UI, or crosses layers, and state the choice as the first line: `superflow: weave — …` / `superflow: direct — …`), `always` (never ask, always weave), `never` (never spawn personas). Pin `always`/`never` when you want CI behavior deterministic.

## Optional

- **Commit gate** — `SUPERFLOW_COMMIT_GATE=1` (or `{"commitGate": true}` in `.claude/superflow.json`) blocks a bare `git commit` until it goes through `/superflow:commit-prep`. Off by default: a plugin installed at user scope must not silently block commits in every repo you open.
- **graphify** — `pipx install graphifyy && graphify extract . --code-only` gives `sherlock` and `bughunter` a local code graph for "what calls this / what breaks if this changes" in one call. Not bundled; both fall back to grep silently without it.

## Resync the vendored skills

The 10 skills copied from Superpowers (`brainstorming`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`) do not auto-update. Copy the matching directories from the upstream repo, then re-apply two edits: `sed -i 's/superpowers:/superflow:/g'` over the copied files, and point `writing-plans` at `codezilla` instead of the un-vendored `executing-plans` / `subagent-driven-development`.

## Credits

Built on [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent (obra), MIT. superflow adds the personas, the rulebook, the design loop, the two workflows, and the routing. Docs: [Designing a Screen](docs/designing-a-screen.md) · [original design spec](docs/2026-08-14-superflow-design.md). Provenance: [ATTRIBUTION.md](ATTRIBUTION.md).
