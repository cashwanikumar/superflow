# Changelog

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
