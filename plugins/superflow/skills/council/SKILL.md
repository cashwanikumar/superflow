---
name: council
description: Multi-voice deliberation on a hard, expensive-to-reverse architectural or product decision — each core persona weighs in independently and architect synthesizes. Use when the user runs /superflow:council or explicitly asks for a full council on a decision.
---

# Council

Full multi-voice deliberation on a hard architectural or product decision. Each of the core personas weighs in independently; `architect` synthesizes everything into a single recommendation.

Use this for genuinely hard, expensive-to-reverse calls. For a quick gut-check, just ask `architect` or `bughunter` directly.

---

## How to invoke

```
/superflow:council                                              # ask what the decision is
/superflow:council should we move from REST to GraphQL for the public API
/superflow:council pick a state library for the dashboard
```

If the decision isn't clear, `architect` asks: *"What's the decision you want the council to weigh in on?"*

---

## Lead behavior

`architect` chairs the council. Steps:

1. Restate the decision in one sentence so the user can confirm intent.
2. (Optional) Spawn `finder` to gather relevant code excerpts if the decision is code-tied.
3. Run the voices in parallel, each from its own lens:
   - `architect` — boundaries, failure modes, evolution, build-vs-buy
   - `pm` — user value, scope, what we're *not* doing
   - `dev` — implementation cost, simplicity, what bites later
   - `bughunter` — how it breaks, edge cases, migration risk
   - `finder` — what the current code/usage actually constrains
4. Synthesize all voices **with attribution** — quote who said what, especially on disagreements.
5. End with one clear recommendation.

(Personas are makers/specialists; `designer`, the testers, and `auditor` aren't on the council unless the decision is specifically in their lane.)

---

## Synthesis format

```md
## Council — <decision in one line>

### Voices
- architect: <one-line verdict>
- pm: …
- dev: …
- bughunter: …
- finder: …

### Where they agree
### Where they disagree   ← the interesting part; don't average it away
### Top 3 risks
### Strongest alternative
### Recommendation
- Verdict: proceed / proceed with changes / rethink
- Why:
- If proceeding, change first:
- What would change the verdict:
```

---

## Rules

- Inspect and deliberate only. Never edit files during a council.
- Highlight disagreements — don't smooth them over. A 3-2 split is a finding; say so.
- The final verdict is `architect`'s call, not a vote — explain it if it diverges from the majority.
- If the decision is trivial (formatting, rename, tiny refactor), say so and skip the ceremony.
