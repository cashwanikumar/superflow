# superflow

A portable Claude Code plugin that turns non-trivial coding work into one pipeline — brainstorm → plan → build (TDD) → verify → review — run by six specialist personas and disciplined by the process skills of [Superpowers](https://github.com/obra/superpowers). It fits any repo by scanning that repo's own conventions into a `CODEBASE_RULEBOOK.md`.

## Install

```
/plugin marketplace add https://github.com/cashwanikumar/superflow
/plugin install superflow
```

Or from the terminal:

```bash
claude plugin marketplace add https://github.com/cashwanikumar/superflow
claude plugin install superflow@superflow      # add --scope to control reach
```

| `--scope` | Where it applies |
|---|---|
| `user` (default) | every repo you open |
| `project` | this repo, shared with your team via committed settings |
| `local` | this repo, your machine only (gitignored `.claude/settings.local.json`) |

Restart the session so the SessionStart hook fires; `/plugin` should show superflow with 6 personas, 18 skills, 2 workflows, all addressed as `superflow:<name>`.

Then, once per repo:

```
/superflow:codebase-rulebook
```

That writes `CODEBASE_RULEBOOK.md` — the conventions every persona conforms to. Without it the personas are generic; with it they fit your codebase.

```bash
claude plugin marketplace update superflow           # pull the latest marketplace metadata
claude plugin update superflow@superflow             # restart required to apply
claude plugin uninstall superflow@superflow          # add the same --scope you installed with
```

`update` and `uninstall` need the **`@superflow` marketplace suffix** — the bare name resolves for `install` and `details` but not for these. Both default to `--scope user`: if you installed at `project` or `local` scope, pass the same `--scope` again, or that copy stays on the old version — and local/project take precedence over user, so a stale one wins silently.

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

`SUPERFLOW_FLOW` controls the opt-in gate:

| Value | Behavior |
|---|---|
| `auto` (default) | Ask and wait when a human is present. Headless: don't ask — run **direct** unless a weave trigger fires (more than one capability, UI work, or a cross-layer change), and state the choice in one line. |
| `always` | Never ask; run the full weave on every non-trivial turn. |
| `never` | Never ask, never spawn personas; work directly (still rulebook-first). |

```
SUPERFLOW_FLOW=always claude -p "add the delete endpoint"
```

On `auto` with nobody to ask, the agent opens its reply with the choice, verbatim: `superflow: weave — <reason>` or `superflow: direct — <reason>`. That line is the only audit trail an unattended run leaves, so grep CI logs for it. The hook deliberately does not try to sniff whether a human is present — the SessionStart payload is identical either way and env vars leak into child sessions — so the decision is left to the agent, which actually knows.

## Optional setup

Everything below is off unless you turn it on.

### The commit gate

Off by default. Turn it on per repo and a bare `git commit` is blocked until it goes through `/superflow:commit-prep`:

```bash
export SUPERFLOW_COMMIT_GATE=1              # or: {"commitGate": true} in .claude/superflow.json
```

A prepared commit opts through by including the token `COMMIT_PREP_OK` anywhere in the command (e.g. a trailing `# COMMIT_PREP_OK` comment). It stays off by default because superflow installs at user scope, and a plugin that silently blocks commits in every repo you open is a hostile default.

### graphify (code graph)

`sherlock` and `bughunter` can use a local tree-sitter code graph to answer structure questions in one call instead of ten file reads — "what does this symbol touch" and the reverse nobody checks by hand, "what breaks if this changes". Not bundled (native grammars can't ride along in a markdown plugin):

```bash
pipx install graphifyy
graphify extract . --code-only     # once per repo — builds graphify-out/
graphify update .                  # incremental refresh, seconds, no LLM
echo "graphify-out/" >> .gitignore
```

Without it, both personas fall back to grep silently and never ask you to install anything mid-task. The graph gives you *structure*, never semantics — anything load-bearing still gets read from the source.

## Resync the vendored skills

The 10 skills copied from Superpowers (`brainstorming`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`) do not auto-update. Copy the matching directories from the upstream repo, then re-apply two edits: `sed -i 's/superpowers:/superflow:/g'` over the copied files, and point `writing-plans` at `codezilla` instead of the un-vendored `executing-plans` / `subagent-driven-development`.

Three upstream skills are intentionally **not** vendored: `writing-skills` (a meta-skill for authoring skills), `subagent-driven-development` and `dispatching-parallel-agents` (the weave already owns the dispatch). Install Superpowers itself if you want them.

## Credits

Built on [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent (obra), MIT. superflow adds the personas, the rulebook, the design loop, the two workflows, and the routing. The personas and the rulebook mechanism are a generalized fork of an internal agent-circus plugin; the `ui-reduction` skill's quick-diagnostic and severity patterns are adapted from the MIT-licensed wondelai/skills `ux-heuristics` skill. Docs: [Designing a Screen](docs/designing-a-screen.md) · [original design spec](docs/2026-08-14-superflow-design.md). Provenance: [ATTRIBUTION.md](ATTRIBUTION.md).
