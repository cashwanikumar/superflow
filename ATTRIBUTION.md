# Attribution

**superflow** is a portable Claude Code plugin that combines coding personas with
process-discipline skills. See the README for how it works.

## Vendored: Superpowers skills (`plugins/superflow/skills/`)

9 of the 15 skills under `plugins/superflow/skills/` are copies of skills from
the **Superpowers** plugin: `brainstorming`, `finishing-a-development-branch`,
`receiving-code-review`, `requesting-code-review`, `systematic-debugging`,
`test-driven-development`, `using-git-worktrees`,
`verification-before-completion`, and `writing-plans`. Two edits are applied on
top: `superpowers:<skill>` references are rewritten to `superflow:<skill>` so they
resolve inside this plugin, and `writing-plans` no longer points at Superpowers'
`executing-plans` / `subagent-driven-development` skills, which superflow does not
vendor (the weave's `codezilla` stage works the plan instead). Upstream's
`writing-skills`, `subagent-driven-development` and `dispatching-parallel-agents`
were dropped in 0.7.0; `using-superpowers` in 0.10.0 (three sentences of it now live in
the `superflow` skill §1, credited here).

The remaining 6 are ours and are **not** Superpowers work: `superflow/`, `codebase-rulebook/`,
`council/`, `handoff/`, `design/`, and `ui-reduction/`.

- Project: **Superpowers** — https://github.com/obra/superpowers
- Author: **Jesse Vincent** (obra)
- License: **MIT**

These files are redistributed under their original MIT license. All credit for the
Superpowers skills belongs to their author. This project claims no ownership over them.
They are vendored (not auto-updated); `scripts/resync-superpowers.sh` refreshes them and
re-applies the edits above.
Vendored from Superpowers 6.3.0 (sha n/a) on 2026-09-18.

## Personas (`plugins/superflow/agents/`)

The coding personas and the `codebase-rulebook` mechanism are a **generalized fork** of an
internal **agent-circus** plugin, stripped of all stack-specific skills so they work in any
repository. Credited here for provenance.

## Adapted: UI reduction method (`plugins/superflow/skills/ui-reduction/`)

The Step 0 quick-diagnostic and the Step 6 severity-rating patterns are adapted from the
MIT-licensed **wondelai/skills** `ux-heuristics` skill. The rest of the method is original.

## Original work (`plugins/superflow/skills/`, `plugins/superflow/workflows/`)

The `superflow` front-door skill, the rulebook layer, the `design` / `ui-reduction` skills,
the `council-vote` and `review-sweep` workflows,
the hook, and this plugin's packaging are original work by **Ashwani Kumar**, MIT-licensed
(see [`LICENSE`](LICENSE)).
