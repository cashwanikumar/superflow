# Attribution

**superflow** is a portable Claude Code plugin that combines coding personas with
process-discipline skills. See the README for how it works.

## Vendored: Superpowers skills (`plugins/superflow/skills/`)

12 of the 17 skills under `plugins/superflow/skills/` are copies of skills from
the **Superpowers** plugin: `brainstorming`, `dispatching-parallel-agents`,
`executing-plans`, `finishing-a-development-branch`, `receiving-code-review`,
`requesting-code-review`, `subagent-driven-development`, `systematic-debugging`,
`test-driven-development`, `using-git-worktrees`, `verification-before-completion`,
and `writing-plans`. Two edits are applied on top: `superpowers:<skill>` references
are rewritten to `superflow:<skill>` so they resolve inside this plugin, and one
reference to the un-vendored `writing-skills` is dropped. Upstream's `writing-skills`
is not vendored; `using-superpowers` was dropped in 0.10.0 (three sentences of it now
live in the `superflow` skill §1, credited here).

The remaining 5 are ours and are **not** Superpowers work: `superflow/`, `codebase-rulebook/`,
`council/`, `design/`, and `ui-reduction/`.

- Project: **Superpowers** — https://github.com/obra/superpowers
- Author: **Jesse Vincent** (obra)
- License: **MIT**

These files are redistributed under their original MIT license. All credit for the
Superpowers skills belongs to their author. This project claims no ownership over them.
They are vendored (not auto-updated); `scripts/resync-superpowers.sh` refreshes them and
re-applies the edits above.
Vendored from Superpowers 6.3.0 (sha b36e082) on 2026-09-19.

## Personas (`plugins/superflow/agents/`)

The coding personas and the `codebase-rulebook` mechanism are a **generalized fork** of an
internal **agent-circus** plugin, stripped of all stack-specific skills so they work in any
repository. Credited here for provenance.

## Adapted: usability method (`ui-reduction/`, `agents/designer.md`, `agents/bughunter.md`)

Three pieces are adapted from the MIT-licensed **wondelai/skills** `ux-heuristics` skill
(https://github.com/wondelai/skills): the Step 0 quick-diagnostic and the Step 6
severity-rating patterns in `ui-reduction`, the usability questions in `designer`'s critique
pass, and the Quick Diagnostic plus severity scale in `bughunter`'s Usability lens. The
heuristics themselves are Nielsen's ten (Nielsen Norman Group) and Krug's laws, restated.
The rest of each file is original.

## Original work (`plugins/superflow/skills/`, `plugins/superflow/workflows/`)

The `superflow` front-door skill, the rulebook layer, the `design` / `ui-reduction` skills,
the `council-vote` and `review-sweep` workflows,
the hook, and this plugin's packaging are original work by **Ashwani Kumar**, MIT-licensed
(see [`LICENSE`](LICENSE)).
