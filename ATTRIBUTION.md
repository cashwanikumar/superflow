# Attribution

**superflow** is a portable Claude Code plugin that combines coding personas with
process-discipline skills. See [`docs/2026-08-14-superflow-design.md`](docs/2026-08-14-superflow-design.md).

## Vendored: Superpowers skills (`plugins/superflow/skills/`)

Every skill under `plugins/superflow/skills/` **except `superflow/`** is a **verbatim copy**
of a skill from the **Superpowers** plugin.

- Project: **Superpowers** — https://github.com/obra/superpowers
- Author: **Jesse Vincent** (obra)
- License: **MIT**

These files are redistributed under their original MIT license. All credit for the
Superpowers skills belongs to their author. This project claims no ownership over them.
They are vendored (not auto-updated) — see the README's "Resync Superpowers skills from
upstream" note.

## Personas & commands (`plugins/superflow/agents/`, `plugins/superflow/commands/`)

The coding personas and the `codebase-rulebook` mechanism are a **generalized fork** of an
internal **agent-circus** plugin (personas + the codebase-rulebook mechanism), stripped of
all stack-specific skills so they work in any repository. Credited here for provenance.

## superflow skill (`plugins/superflow/skills/superflow/`)

The `superflow` front-door skill and this plugin's packaging are original work by
**Ashwani Kumar**, MIT-licensed (see [`LICENSE`](LICENSE)).
