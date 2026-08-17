# Attribution

**superflow** is a portable Claude Code plugin that combines coding personas with
process-discipline skills. See [`docs/2026-08-14-superflow-design.md`](docs/2026-08-14-superflow-design.md).

## Vendored: Superpowers skills (`plugins/superflow/skills/`)

14 of the 21 skills under `plugins/superflow/skills/` are **verbatim copies** of skills from
the **Superpowers** plugin: `brainstorming`, `dispatching-parallel-agents`, `executing-plans`,
`finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`,
`subagent-driven-development`, `systematic-debugging`, `test-driven-development`,
`using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`,
and `writing-skills`.

The remaining 7 are ours and are **not** Superpowers work: `superflow/`, `codebase-rulebook/`,
`specbook/`, `commit-prep/`, `council/`, `daily-brief/`, and `handoff/`.

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

## Original work (`plugins/superflow/skills/{superflow,codebase-rulebook,specbook,commit-prep,council,daily-brief,handoff}/`)

The `superflow` front-door skill, the rulebook and specbook layers, the four workflow skills,
and this plugin's packaging are original work by **Ashwani Kumar**, MIT-licensed
(see [`LICENSE`](LICENSE)).
