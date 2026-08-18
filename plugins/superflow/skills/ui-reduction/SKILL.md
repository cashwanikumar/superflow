---
name: ui-reduction
description: A step-by-step method for turning a complex, cluttered screen into a simpler one — structure before styling. Load before the taste pass whenever a screen is multi-section, does more than one job, or the user says "simplify", "declutter", "clean up", "messy", "cluttered", or "busy". Used by the designer persona's reduction gate.
---

# UI Reduction Method

A procedure for turning a complex, cluttered screen into a simpler one. This is a **method you walk, in order** — not values you carry. Do not skip steps and do not reorder them: the most common failure is jumping to rearranging (step 5) before cutting (step 3), which produces a tidier version of the same clutter.

Run this BEFORE any visual/taste pass. The output of this method is structure, not styling.

---

## Step 0 — Quick diagnostic

Five pass/fail questions, answered honestly against the current screen:

1. Is there exactly one obvious primary action?
2. Is the screen's purpose clear within ~5 seconds?
3. Is every visible control needed on most visits?
4. Is nesting at most 2 containers deep?
5. Are related controls grouped and labeled?

**All five pass** → skip Steps 1–6, record "reduction not needed (passed quick diagnostic)", and go straight to the taste pass. **Any fail** → run the full method, carrying the failed questions into Step 2 as your first diagnosis leads.

---

## Step 1 — Inventory

List **every element** on the current screen: every button, field, toggle, label, badge, panel, tab, link, icon, stat. Read the actual component code — do not inventory from memory or screenshots alone.

For each element, record two things:

| Element | Task it serves | How often users need it |
| ------- | -------------- | ------------------------ |
| ...     | one task, named | every visit / sometimes / rarely / never |

Rules:
- One task per element. If you can't name the task, that's a finding — mark it `task: unknown`.
- If two elements serve the same task, note the duplication explicitly.
- Frequency is your honest estimate from the code, the docs, and the user's description — say when you're guessing.
- For a NEW screen with no code yet, inventory from the requirements/task list instead — every task the screen must serve becomes a row.

This table is the contract for step 6: nothing on it may vanish without a decision.

---

## Step 2 — Diagnose the source of complexity

Name which of these the screen suffers from (often more than one, but rank them). The fix differs per source, so a wrong diagnosis produces the wrong redesign:

1. **Too many co-equal tasks on one screen.** Nothing is primary; five jobs compete for attention. → Fix in step 5 is *splitting* (flow, master-detail, or tabs-by-task).
2. **A flat ungrouped pile of controls.** Twenty settings/buttons at the same level with no structure. → Fix is *chunking* into named groups + smart defaults.
3. **Deep nesting.** Panels inside cards inside tabs inside accordions; users lose where they are. → Fix is *flattening* — whitespace and headings instead of boxes-in-boxes.
4. **Redundant paths to the same outcome.** Two buttons, a menu item, and a shortcut all do the one thing. → Fix is *cutting* down to one obvious path.

Write the diagnosis down in one or two sentences before proceeding. Every structural move in step 5 must trace back to it.

---

## Step 3 — Reduce before rearrange

Work in this strict order. **Deleting beats tidying** — a moved element still costs attention; a cut one costs nothing.

1. **CUT** — remove elements that are unused, duplicate (from the step-1 table), or purely decorative. Also cut any decision the product can make itself (see smart defaults, step 5).
2. **DEFER** — for elements needed *rarely*, move them behind progressive disclosure: an "Advanced" section, a details-on-demand expansion, an overflow menu, a settings modal. They still exist; they just don't cost attention on every visit.
3. Only after cutting and deferring: **group and arrange what's left** (step 5).

If you find yourself designing a layout for an element you haven't justified keeping, go back to 1.

---

## Step 4 — Rank tasks and layer the screen

Rank the surviving tasks by **frequency × importance**.

Frequency maps to fate mechanically: **never → CUT** (step 3) · **rarely → DEFER, Layer 3** · **sometimes → Layer 2** · **every visit → primary / Layer 1**. High importance may bump an element UP one layer (rare-but-critical can sit in Layer 2); importance never bumps anything down.

- The **top task** becomes primary and immediate: visible without scrolling, one obvious action, no mode switch to reach it.
- The **long tail** is layered, one click deeper per layer:
  - Layer 1 — summary (always visible, glanceable)
  - Layer 2 — details on demand (expand, drill in, hover/selection detail)
  - Layer 3 — advanced/rare (one click deeper again: modal, sub-page, "Advanced" disclosure)

A screen with two "primary" tasks failed step 2 — go back and split it.

---

## Step 5 — Structural moves, by leverage

Apply the move(s) your step-2 diagnosis calls for, in descending order of leverage:

1. **Split the screen** if it does more than one job. Pick the shape by relationship: a *flow* (steps in sequence), *master-detail* (list → selected item), or *tabs-by-task* (peer jobs, one at a time). Splitting is the highest-leverage move and the most under-used.
2. **Flatten nesting.** Replace boxes-in-boxes with whitespace + headings. A heading and a 24px gap group as well as a bordered card, at zero chrome cost. Reserve actual containers for the one or two groupings that must read as bounded.
3. **Chunk loose controls** into named groups drawn from the user's real task boundaries ("Delivery", "Access", "Notifications") — never by implementation ("Misc", "Other settings"). The task boundaries decide the count: don't pad a 3-group screen to five, and more than ~7 groups means the screen does too many jobs — go back to Step 2 and split.
4. **Give smart defaults.** Every setting with one obviously-right value gets that value and moves behind disclosure. A decision the user doesn't make is the cheapest simplification there is.
5. **Leave exactly one primary action** on the screen. Everything else demotes to a quiet secondary style or into menus.

---

## Step 6 — Account for everything

Reconcile against the step-1 inventory. Every element must be in exactly one bucket:

- **KEPT** — survives, with its place in the new structure named.
- **MOVED** — deferred/relocated, with the named destination ("→ Advanced disclosure", "→ row overflow menu").
- **CUT** — deliberately removed, with the one-line reason.

Every **MOVED** and **CUT** row — and any **KEPT** row that is itself a problem — also carries a **severity** for the issue it addresses, scored as frequency × impact on the primary task:

`0` cosmetic · `1` minor · `2` moderate · `3` serious · `4` blocks the primary task

An unaddressed severity-4 is a failed reduction; a table of only 0–1s means the screen needed polish, not reduction.

Nothing vanishes silently. If an element has no bucket, you haven't finished. Present this reconciliation table in the output — it is what lets a reviewer trust the reduction.

---

## Step 7 — Output of this pass

Produce, **before any visual styling**:

1. The quick-diagnostic result (step 0 — which questions failed).
2. The diagnosis (step 2, one or two sentences).
3. The simplified structure: the screen's job(s), the primary task, the layers.
4. An **ASCII wireframe** of the new structure — regions, groups, and the one primary action marked. No colors, no type scale, no tokens yet.
5. The reconciliation table (step 6, with severities).

Only then proceed to the taste/visual pass (the designer persona's normal spec).

<!-- The Step 0 quick-diagnostic and Step 6 severity-rating patterns are adapted from the MIT-licensed wondelai/skills ux-heuristics skill. -->
