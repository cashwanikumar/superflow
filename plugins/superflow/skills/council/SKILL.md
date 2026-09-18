---
name: council
description: Multi-voice deliberation on a hard, expensive-to-reverse architectural or product decision — independent schema-forced votes from four lenses, synthesized by architect. Use when the user runs /superflow:council or explicitly asks for a full council on a decision.
---

# Council

Full multi-voice deliberation on a hard architectural or product decision. Each voice weighs in **independently**, then `architect` synthesizes.

Use this for genuinely hard, expensive-to-reverse calls. For a quick gut-check, just ask `superflow:architect` or `superflow:bughunter` directly — a council run is not cheap.

This skill is the **front door**. The deliberation itself runs as a deterministic workflow, `council-vote`, so no voice can be silently dropped: every vote comes back through a JSON schema, and a voice that dies or abstains is reported rather than quietly missing from the tally. This skill's job is the one thing the script must not decide for you: what the decision actually is.

---

## How to invoke

```
/superflow:council                                              # ask what the decision is
/superflow:council should we move from REST to GraphQL for the public API
/superflow:council pick a state library for the dashboard
```

---

## Lead behavior

### 1. Confirm the decision text

Restate the decision in **one sentence** and get the user to confirm it. This sentence is passed verbatim to every voice — a vague decision produces five vague votes, and you will have paid for all of them.

If the decision isn't clear, ask: *"What's the decision you want the council to weigh in on?"*

### 2. Know the roster

Four lenses, always the same: `architect` (technical), `bughunter` (failure modes), `codezilla` (shippability), and a product voice (user value, scope), plus `sherlock` grounding when the decision is code-tied. Nothing to confirm and nothing billed outside this session.

### 3. Launch the workflow

Once the decision text is confirmed, launch `council-vote` via the **Workflow** tool:

```
Workflow({
  name: "council-vote",
  args: {
    decision:  "<the confirmed one-sentence decision>",
    code_tied: true,                    // false for pure product/process calls — skips sherlock
    hints:     ["path/to/relevant.ts"]  // optional starting points for sherlock
  }
})
```

The workflow returns `{ synthesis, votes }`.

### 4. Report

Render `synthesis` **verbatim** — it is already in the council format, and re-summarizing it is exactly how a disagreement gets averaged away. You may additionally show the `votes` table. If the run reports voices that failed to return, say so plainly.

---

## Rules

- Inspect and deliberate only. Never edit files during a council.
- The decision text is **the human's**, confirmed before launch.
- Highlight disagreements — don't smooth them over. A 3-2 split is a finding; say so.
- Abstains are reported, never counted as votes, and never dropped — an abstain's raw output can still carry signal.
- The final verdict is `architect`'s call, not a vote count — explain it if it diverges from the majority.
- If the decision is trivial (formatting, rename, tiny refactor), say so and skip the ceremony.
- **Headless runs:** take the decision text from the invocation as-is rather than stalling on a confirmation nobody can give, and say so in the final message.
