# Changelog

## 0.12.1

**Usability lens.** Nothing in the pipeline reviewed a UI change for usability: `designer` designed, `bughunter` checked accessibility, nobody asked whether the error message says what to do or whether there is an undo.

- `designer`: the critique pass now walks seven usability questions (one obvious primary action, orientation without body copy, labels in the user's words, feedback and error text, undo without confirmation dialogs, nothing hover- or icon-only, nothing that makes you stop and think) and fixes a "no" in the spec before handoff.
- `bughunter`: a **Usability** lens next to Accessibility — Nielsen's ten heuristics, one line each, rated on the same 0–4 severity scale, reported with file:line like every other finding. It runs on every frontend change, including the ones that never went through `/superflow:design`.
- Adapted from the MIT-licensed wondelai/skills `ux-heuristics` skill; credited in ATTRIBUTION alongside the pieces `ui-reduction` already borrowed.

## 0.12.0

**Vendor the Build loop. Add tests.**

- **Build stage is now `subagent-driven-development`.** 0.7.0 dropped SDD on the theory that "the weave owns the dispatch", and the Build row became one `codezilla` spawn working the plan top to bottom — no per-task review, no fix-round cap, no rulings ledger. That was the one place superflow was weaker than the upstream it forked. SDD, `executing-plans` and `dispatching-parallel-agents` are vendored again (12 of 17 skills); the weave dispatches SDD's implementer with `subagent_type: superflow:codezilla` and keeps SDD's reviewer prompts as written. Tightly coupled tasks and direct mode run `executing-plans` inline.
- **`writing-plans` is upstream-clean again.** The local patch that rewrote its execution handoff to `codezilla` is gone; the patch is down to one hunk (a dropped reference to the un-vendored `writing-skills`). `requesting-code-review`'s "after each task in subagent-driven development" line is back as upstream wrote it.
- **Dropped `handoff`.** `SESSION.md` / `NEXT_STEPS.md` was a convention only this skill read; SDD's ledger carries in-session state, and the harness's own session resume covers the rest.
- **`tests/`.** `tests/run-tests.sh` runs static checks (frontmatter names, dangling `superflow:` refs, leftover `superpowers:` prefixes, version in three places, README/ATTRIBUTION counts vs the tree, patch touches only vendored files, workflows parse, weave names shipped skills, hook stays under 120 words) and the SessionStart hook contract. `--claude` adds behavioral tests that drive `claude -p --plugin-dir` (trivial gate, code-change routing, ui-reduction trigger). Every static check corresponds to a drift a past release shipped.
- Counts: 5 personas, 17 skills (12 vendored), 2 workflows, 1 hook.

## 0.11.0

**Resync the vendored Superpowers skills to 6.3.0, and make resync a command.**

- The nine vendored skills were copied from Superpowers 6.2.0 on 2026-08-14, two days after 6.3.0 shipped, and never refreshed. They now match 6.3.0. What that brings: `brainstorming` classifies work as spike / bounded / architectural — a bounded change gets a short in-chat design and no spec or plan document, which is what the weave's "spawn the minimum" always meant; `finishing-a-development-branch` gains the "never `--force` a refused worktree removal" guard; `requesting-code-review`'s reviewer no longer spawns sub-reviewers.
- `scripts/resync-superpowers.sh` does the refresh: copy, namespace rewrite, re-apply the local edits from `scripts/superpowers-local-edits.patch` (three files: the writing-plans handoff to `codezilla`, two dropped references to un-vendored skills), fail on any dangling `superflow:` reference, stamp the upstream version into `ATTRIBUTION.md`. The README recipe it replaces missed two of the three edits.
- `superflow` §2: when no reply is possible, brainstorming's approval gate is reported as unsatisfied rather than silently skipped.

## 0.10.0

**Cut the shell, keep the core.** Same five personas, same rulebook, same two workflows; the routing and gating machinery around them is gone.

- **Gate simplified to what a model can actually decide.** `auto` now means: ask once per session before the first persona spawn, remember the answer; a run that cannot return a reply works direct and says so. Dropped the human-presence heuristic (undecidable on turn 1 of every interactive session), the `superflow: weave — <reason>` first-line stamp (nothing read it), and the a/b/c weave-trigger table. `always` / `never` unchanged.
- **Hook is a pointer again, for real.** `session-start.sh` emits ~60 words: the running version, the `SUPERFLOW_FLOW` value, and "trivial → answer; code change → load the `superflow` skill". 0.7.0 claimed this and then restated the whole `auto` policy in the same file; the copies had already drifted. SessionStart now matches `startup|clear|compact` so a resume does not re-inject it.
- **Dropped the commit gate** (`require-commit-prep.sh`, the PreToolUse hook, `commit-prep`). It ran on every Bash call for an off-by-default feature, its deny message printed the bypass token, and `commit-prep` restated the harness's default commit flow.
- **Dropped `using-superpowers`.** Its precedence clause let "questions are tasks" override the 0.8.0 trivial gate. The three operative sentences now live in `superflow` §1.
- **Folded `daily-brief` into `handoff`** (`/superflow:handoff resume`). One skill, two directions; the only reader/writer pair was `SESSION.md`.
- **Rulebook template carries `[ENFORCED]` / `[OBSERVED]` labels.** Real rulebooks were already using them and consumers depend on them; a `--refresh` under the old template would have dropped them.
- **Enforced read-only** on `sherlock` and `designer` via `disallowedTools` instead of prose.
- **Headless `design` no longer commits the mock** into the user's repo.
- **`review-sweep`**: default diff base is the remote's default branch (was hardcoded `main`); a string `args` is normalized like `council-vote` does; dead sweep slices and lost verifiers are logged and returned (`dead_slices`, `unverified`, `left_out`) instead of silently dropped.
- `marketplace.json` no longer carries a version or persona count — `plugin.json` is the one source.
- Retired `docs/2026-08-14-superflow-design.md` (described 10 personas + the specbook) to git history.
- Counts: 5 personas, 15 skills (9 vendored), 2 workflows, 1 hook.

## 0.9.0

**Fold `bossbaby`.** Personas 6 → 5.

- **Dropped the PM persona from the build pipeline.** In the weave it ran right after `brainstorming`, which already settles what/why *with the human* — the actual product owner. Sequentially re-deriving that alone, it restated the ticket and invented the parts it could not know (user counts, success metrics, rollout plans), and nothing downstream read the spec it wrote. Plan stage is now `architect` alone, citing the ticket/spec rather than restating it.
- **Kept the product viewpoint where it earns its seat: `/superflow:council`.** Four voices still vote blind in parallel; the fourth is a product-owner lens carried inline in `council-vote.js`, told explicitly not to invent data it cannot see. Three engineers agreeing is not a council.
- Counts: 5 personas, 18 skills, 2 workflows.

## 0.8.0

**Cut the overbuilt edges.** Same pipeline; fewer moving parts, less markdown.

- **Personas 9 → 6:** `sherlock`, `bossbaby`, `architect`, `designer`, `codezilla`, `bughunter`. `unit-tester` folded into `codezilla` (TDD skill already owned the method); `a11y-hunter` is now an accessibility section of `bughunter` (WCAG 2.0 AA, same bar); `auditor` folded into the `codebase-rulebook` skill (sherlock scans, the lead writes). `bossbaby` stays: product framing independent of the design is the one pushback folding would lose.
- **Dropped the specbook.** Three files per change plus a fold-back ceremony was OpenSpec-in-a-plugin; the rulebook carries its weight for the repos this targets. If you used it, the last version with it is 0.7.0.
- **Dropped external vendor CLIs from `/superflow:council`.** The secret-sanitization and sandboxing were prompt text, not code, and the README read like enforcement. Council is the four in-session persona voices now.
- **Dropped `handoff-contracts`.** The workflows already enforce schemas in code; the chat weave now asks for a plain Handoff section instead of a JSON contract.
- **Trivial gate widened.** Any question or opinion with no code change asked for is answered directly, no opt-in.
- README trimmed to ~75 lines; two specbook-centric docs removed.
- Counts: 6 personas, 18 skills, 2 workflows.

## 0.7.0

**Trim + single-source protocol.** Same pipeline, ~25% less markdown, one place the gate is defined.

- **Hook shrunk ~950 → ~220 words.** `session-start.sh` now injects a pointer, not the policy. The `superflow` skill §2 is the single source of the gate; the two can no longer drift.
- **Headless default flipped to `direct`.** Under `SUPERFLOW_FLOW=auto` with no human present, the weave now has to earn its spawns: it runs only when a trigger fires (more than one capability, UI work, cross-layer change). Previously weave was the default and direct needed three conditions.
- **Dropped three vendored meta-skills:** `writing-skills` (~2k lines), `subagent-driven-development`, `dispatching-parallel-agents`. The weave owns dispatch; skill authoring belongs in Superpowers itself. Also dropped `using-superpowers/references/` (Codex/Gemini/Pi/Antigravity adapters — this is a Claude Code plugin).
- **Fixed dangling `superpowers:` prefixes** in the vendored skills (`systematic-debugging`, `using-superpowers`, `writing-plans`, `test-driven-development`). They did not resolve inside this plugin.
- `writing-plans` and the specbook `tasks.md` template now hand off to `codezilla` instead of the removed skill.
- Counts: 9 personas, 20 skills, 2 workflows.

## 0.6.1

- README install docs; stale vendoring claims.

## 0.6.0

- Remove duplicate agents and skills.
