# superflow — handoff / context primer

> Open a new Claude Code session **in this folder** and paste the "Kickoff prompt"
> at the bottom, or just say "read HANDOFF.md and tell me the next step."

## What this is
**superflow** is a portable Claude Code **plugin** that combines two things into one
"full-flow" dev toolkit that works in **any** repo:
- **Specialist coding personas** (finder, pm, designer, dev, fe/be-unit-tester,
  bughunter, a11y-hunter, architect, auditor) — a *generalized fork* of an internal
  `agent-circus` plugin, with all stack-specific (Marvin) skills removed.
- **Process-discipline skills** — 14 skills vendored verbatim from **Superpowers**
  (obra, MIT): TDD, brainstorming, systematic-debugging, writing/executing-plans,
  requesting/receiving-code-review, verification, worktrees, etc.
- A **self-scanning codebase rulebook** (`/codebase-rulebook`) so the generic
  personas conform to *this* repo's conventions instead of hardcoded ones.

Design spec: [`docs/2026-08-14-superflow-design.md`](docs/2026-08-14-superflow-design.md).
Provenance/credits: [`ATTRIBUTION.md`](ATTRIBUTION.md).

## Where we are (status: BUILT, PUSHED, not yet live-installed)
- Repo: **https://github.com/cashwanikumar/superflow** — branch `main`.
- Commits: `Initial: design spec + vendored skills` → `Scaffold installable superflow plugin` → `Add HANDOFF.md` → `Add How-it-works flowcharts + explainer link to README`.
- Structure (matches the spec): **10 agents · 5 commands · 15 skills (14 Superpowers + new `superflow`) · SessionStart hook · manifests · MIT LICENSE + ATTRIBUTION**.
- **Visual explainer** (interactive, private): https://claude.ai/code/artifact/037be08d-120b-4026-aee4-513a8de6c773 — the two-tier engagement model + two worked-example flowcharts (rate-limit = 4/9 stages; OAuth = 8/9). The same flowcharts are now embedded in `README.md` as GitHub-native Mermaid under "How it works" (source of truth for the visuals; the artifact is a richer hand-drawn SVG version).
- Layout:
  ```
  .claude-plugin/marketplace.json        # registers the plugin
  plugins/superflow/
    .claude-plugin/plugin.json
    agents/      (10 generalized personas)
    commands/    (codebase-rulebook, commit-prep, council, daily-brief, handoff)
    hooks/       (hooks.json + session-start.sh)
    skills/      (superflow/ + 14 vendored Superpowers skills)
  docs/, LICENSE, README.md, ATTRIBUTION.md
  ```

## Locked design decisions
1. **Truly generic** — no Marvin skills; each repo generates its own `CODEBASE_RULEBOOK.md`.
2. **Distribution:** private git **marketplace** (this repo).
3. **Engagement:** *opt-in per task* — always-on lightweight skill-check, but ask once
   ("run the full flow? yes/no") before spawning the multi-persona pipeline.
4. Superpowers skills **vendored verbatim** (MIT, attribution kept) — they will NOT
   auto-update; resync manually from upstream (see README).

## Verified (executed locally)
- All 3 JSON manifests parse; `marketplace.json` matches the schema of working installed marketplaces.
- `agents/` + `commands/` are **grep-clean** of `marvin|@marvin|chakra|redux|DRF|ui-kit|celery|heymarvin|agent-circus`.
- Every persona + skill has valid `name`/`description` frontmatter; `a11y-hunter` keeps WCAG 2.0 AA; `session-start.sh` is executable and **runs (exit 0)** emitting the generic protocol.
- **Portability proven:** ran the `codebase-rulebook` flow against a throwaway non-Marvin repo (Express + Zod + Vitest) → produced an accurate, stack-specific rulebook (Zod-validation pattern, router-per-resource, `eqeqeq`, etc.).

## NOT yet tested (the one remaining leg) → **do this next**
A true **interactive install + slash-command run in a live session** couldn't be done from the build session. To confirm end-to-end, in a **fresh terminal session**:
```
/plugin marketplace add https://github.com/cashwanikumar/superflow
/plugin install superflow
```
Then, in any repo:
1. Confirm the plugin loaded: `/plugin` (see it enabled) and check the `superflow` skill + the 10 agents + 5 commands appear.
2. Run `/codebase-rulebook` → verify it writes a sensible `CODEBASE_RULEBOOK.md`.
3. Ask for a small, non-trivial change → confirm it offers the **opt-in gate**, and that a persona (e.g. `dev`) consults the rulebook before editing.
4. Try one more command (`/commit-prep`, `/handoff`) to confirm they resolve.
5. Optional: `claude plugin details superflow` and `claude plugin eval superflow` once installed.

## Known follow-ups / open questions
- **Name** — `superflow` is a working title; rename the plugin + `name` fields if you want.
- **Hook aggressiveness** — SessionStart injects the protocol every session; consider making it opt-in if it's noisy.
- **Skill resync** — document/automate pulling upstream Superpowers updates.
- **README install URL** uses `github.com/cashwanikumar/superflow` — correct as of now.
- (Unrelated to this repo: 4 old *Marvin* intercept design docs were lost during cleanup in the other repo — git was unaffected; noted only so it isn't a surprise.)

## Key facts for a fresh agent
- This folder is its own git repo with remote `origin = https://github.com/cashwanikumar/superflow.git`.
- Commit identity used: `Ashwani <ashwani@heymarvin.com>`; commits keep a `Co-Authored-By: Claude` trailer.
- Source of the personas (to re-diff/generalize further): the internal `agent-circus` plugin at
  `~/.claude/plugins/cache/marvin-internal/agent-circus/0.1.0/`.
- Upstream Superpowers (for resync): `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.2.0/` or https://github.com/obra/superpowers.

---

## Kickoff prompt (paste into a new session opened in this folder)

> You're working in the `superflow` repo — a portable Claude Code plugin (personas +
> vendored Superpowers process skills + a self-scanning codebase rulebook). Read
> `HANDOFF.md` and `docs/2026-08-14-superflow-design.md` for full context. The plugin
> is built and pushed to `github.com/cashwanikumar/superflow`; what's left is a live
> install smoke-test (see "NOT yet tested" in HANDOFF.md) and the open follow-ups
> (name, hook aggressiveness, skill resync). Tell me the current state in 3 bullets,
> then ask me which of the follow-ups to tackle first. Don't change files until I pick.
