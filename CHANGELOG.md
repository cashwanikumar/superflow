# Changelog

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
