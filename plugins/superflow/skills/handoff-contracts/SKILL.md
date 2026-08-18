---
name: handoff-contracts
description: JSON schemas for persona-to-persona handoffs in the conversational weave — sherlock→codezilla, designer→codezilla, bughunter→lead. Load when running a multi-persona weave so a handoff fails loudly instead of degrading into lossy prose. Workflow scripts get this for free via agent(..., {schema}); this is the same guarantee for the in-chat relay.
---

# Handoff contracts

Prose handoffs between personas are lossy — the caveat in paragraph 4 doesn't survive the relay, and the loss is silent: nothing errors, the next persona simply builds the wrong thing. **Every persona→persona handoff in the weave travels as a fenced JSON block matching one of the schemas below.**

Workflow scripts get this for free via `agent(..., {schema})` — the harness validates and the model retries on mismatch. This skill exists so the *conversational* weave (the routing flow in the `superflow` skill) gets the same guarantee.

## The rule (for the lead running the weave)

1. When spawning a weave persona, the spawn prompt MUST end with:
   > End your report with a single fenced ```json block matching the `<name>` schema in the `superflow:handoff-contracts` skill. Prose before it is welcome; the JSON block is the handoff.
2. Before passing the handoff downstream, validate that the required fields are present and non-empty.
3. Invalid or missing block → re-ask that agent **once** (via SendMessage) to emit the block. Still invalid → **fail loudly to the user** ("sherlock's handoff was malformed — fix before codezilla starts"). Never silently continue on prose.
4. Pass the JSON block **verbatim** into the next persona's prompt — do not paraphrase it.

## Schema: `premap` — sherlock → codezilla (or any implementer)

```json
{
  "task": "one sentence — what is being built/changed",
  "entry_points": ["file:line where the change starts"],
  "key_files": [{ "path": "…", "role": "why this file matters to THIS task" }],
  "data_flow": "how data moves through the touched seam, 2-5 sentences",
  "constraints": ["hard constraints the implementation must respect (invariants, contracts, CODEBASE_RULEBOOK.md rules)"],
  "gotchas": ["surprises that will bite a naive implementation"],
  "out_of_scope": ["things deliberately NOT to touch"],
  "open_questions": ["anything sherlock could not resolve — empty array if none"]
}
```

Required: every field. `open_questions: []` is valid; a missing `constraints` field is not.

## Schema: `design-brief` — designer → codezilla

```json
{
  "screen": "which screen/component this specs",
  "layout": "structure in words — regions, hierarchy, spacing intent",
  "components": [{ "name": "…", "source": "<the repo's design-system package> | new", "notes": "variant/recipe/props intent" }],
  "tokens": ["semantic tokens used, by the names the project actually defines — never raw hex"],
  "states": ["empty / loading / error / hover / focus — what each looks like"],
  "interactions": ["what happens on click/drag/type"],
  "acceptance": ["how codezilla knows the implementation matches the spec"]
}
```

Required: every field. `source` must name an **existing** component from the repo's own design system wherever one fits — `new` requires a note on why no existing primitive works, and lands as a design-system prerequisite, never an inline hack. (When the `design` skill ran the mock loop, the locked mock is the fidelity contract and outranks this brief wherever they differ.)

## Schema: `findings` — bughunter → lead

```json
{
  "findings": [
    {
      "file": "path",
      "line": 0,
      "summary": "one sentence — the defect, not the fix",
      "severity": "high | medium | low",
      "evidence": "the code path / inputs that make this a bug",
      "fix_sketch": "optional"
    }
  ]
}
```

`findings: []` is a valid, good answer. A finding without `evidence` is not a finding.

## What this is NOT

- **Not persona instructions.** The persona files stay untouched — they describe identity and taste, not choreography. Handoff format arrives via the spawn prompt, from the lead.
- **Not a workflow.** The conversational weave stays conversational; only the handoff *format* is contracted. When you want the whole relay made deterministic, that's what `/superflow:review-sweep` and `/superflow:council` are for.
