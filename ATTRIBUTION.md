# Attribution

**superflow** is a portable Claude Code plugin that combines coding personas with
process-discipline skills. See [`docs/2026-08-14-superflow-design.md`](docs/2026-08-14-superflow-design.md).

## Vendored: Superpowers skills (`plugins/superflow/skills/`)

13 of the 23 skills under `plugins/superflow/skills/` are copies of skills from
the **Superpowers** plugin: `brainstorming`, `dispatching-parallel-agents`,
`finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`,
`subagent-driven-development`, `systematic-debugging`, `test-driven-development`,
`using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`,
and `writing-skills`. Most are verbatim; `writing-plans` and `subagent-driven-development`
have had their references to Superpowers' `executing-plans` skill removed, since superflow
does not vendor it (subagents are always available in Claude Code, and `executing-plans`
defers to `subagent-driven-development` whenever they are).

The remaining 10 are ours and are **not** Superpowers work: `superflow/`, `codebase-rulebook/`,
`specbook/`, `commit-prep/`, `council/`, `daily-brief/`, `handoff/`, `design/`, `ui-reduction/`,
and `handoff-contracts/`.

- Project: **Superpowers** — https://github.com/obra/superpowers
- Author: **Jesse Vincent** (obra)
- License: **MIT**

These files are redistributed under their original MIT license. All credit for the
Superpowers skills belongs to their author. This project claims no ownership over them.
They are vendored (not auto-updated) — see the README's "Resync Superpowers skills from
upstream" note.

## Personas (`plugins/superflow/agents/`)

The coding personas and the `codebase-rulebook` mechanism are a **generalized fork** of an
internal **agent-circus** plugin, stripped of all stack-specific skills so they work in any
repository. Credited here for provenance.

## Adapted: UI reduction method (`plugins/superflow/skills/ui-reduction/`)

The Step 0 quick-diagnostic and the Step 6 severity-rating patterns are adapted from the
MIT-licensed **wondelai/skills** `ux-heuristics` skill. The rest of the method is original.

## Original work (`plugins/superflow/skills/`, `plugins/superflow/workflows/`)

The `superflow` front-door skill, the rulebook and specbook layers, the `design` /
`ui-reduction` / `handoff-contracts` skills, the `council-vote` and `review-sweep` workflows,
the hooks, and this plugin's packaging are original work by **Ashwani Kumar**, MIT-licensed
(see [`LICENSE`](LICENSE)).
