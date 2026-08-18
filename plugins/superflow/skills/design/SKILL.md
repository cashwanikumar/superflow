---
name: design
description: Turn a screen (existing or new) into an implementable design spec — reduction first on complex screens, then taste — locked by an interactive mock and handed to codezilla as a build brief. Use when the user runs /superflow:design, or for any UI work: a new screen, a redesign, or a "simplify / declutter this messy page" request.
---

# Design

Turn a screen (existing or new) into an implementable design spec — reduction first on complex screens, then taste — with an explicit handoff brief for `codezilla`.

Use this for any UI work: a new screen, a redesign, or a "simplify / declutter this messy page" request.

This skill is **inspect-and-spec only**. It does not modify application code. Implementation happens only via the `codezilla` handoff at the end, and only if the user approves it.

---

## How to invoke

State the screen and the goal. Examples:

```
/superflow:design                                     # ask what screen to design
/superflow:design the Settings page — it's cluttered, simplify it
/superflow:design a new run-history dashboard
/superflow:design the projects empty state
```

If the target isn't clear, ask:

> Which screen (or new screen) is this, and what should be different when we're done?

---

## Lead behavior

The lead frames the screen, delegates the design to `superflow:designer`, then produces the `codezilla` handoff.

1. Restate the screen and goal in one sentence so the user can confirm intent.
2. Frame the problem: locate the screen's code (component files, routes), name its job(s), and note any constraints from `CODEBASE_RULEBOOK.md` (design-system import rules, lint bans, component patterns). If a `specbook/` exists, read the affected capability spec too.
3. Delegate to `superflow:designer` with the framing below. Designer decides whether the reduction gate fires; do not pre-empt that decision.
4. Receive the spec. Check it is **grounded**: real components, variants, and tokens from the project's design system — no invented tokens, nothing the project's lint rules ban.
5. **Build an interactive mock from the spec** — a self-contained clickable HTML page using the project's real design tokens (both color modes), with the key interactions wired. If the spec changes *navigation structure*, mock the leading candidate but expect to pivot: layout **feel** is decided by clicking, never by prose — this is where the real design decisions happen.
6. **Iterate the mock with the user until they lock it.** Each round: they react, you update the mock in place. Where the evolving mock and the original spec disagree, **the mock wins**.
7. On lock: commit the mock into the repo (`docs/mocks/<slug>.html`, or the repo's own convention) as the **fidelity contract**, then produce the **handoff brief** for `codezilla` (format below) — derived from the LOCKED MOCK, not the original spec.
8. Stop. Implementation starts only when the user approves, and then only via `superflow:codezilla`.

**Headless runs** (no human to iterate with): skip steps 5–7's iteration loop. Build the mock, commit it, and say plainly in the final message that the mock was **not** human-locked — a mock nobody clicked is a proposal, not a contract.

The lead must not write the spec itself and must not implement anything during this skill.

---

## Delegation to designer

```text
Owner: `superflow:designer`
Objective: Produce a design spec for <screen>, per the stated goal.
Scope: <the screen's component files>, plus the project's design-system source
  (token/theme files, variant/recipe definitions, the component library).
Constraints: Read-only — no code. If the screen is non-trivial (multi-section,
  cluttered, or the goal says simplify/declutter), FIRST load the
  `superflow:ui-reduction` skill and walk its method to a simplified structure
  (diagnosis, ASCII wireframe, kept/moved/cut reconciliation), THEN run the taste
  pass on that structure. Express everything in the project's real components,
  variants, and tokens (discover them; see CODEBASE_RULEBOOK.md).
  New primitives/variants/tokens may be PROPOSED as handoff items only — never
  spec'd as inline hacks.
Expected output: The full design spec per designer's output format, including the
  Reduction summary section when the gate fired and the Design-system handoffs
  section when anything new is proposed.
```

---

## Handoff brief to codezilla

Written ONLY after the user locks the mock — a brief derived from an unlocked spec is premature and will be thrown away when the mock evolves. It must be concrete enough that `codezilla` can build without guessing: name files, components, variants, and tokens explicitly, and reference the committed mock as the fidelity contract.

```md
## Implementation brief — <screen>

### Files to change
- <exact paths of the components to edit or create>

### Fidelity contract
- <path to the locked mock>

### Design-system prerequisites (do these in the design-system package FIRST)
- <each new primitive/variant/token designer proposed, with its spec — or "none">

### Structure
- <the final layout from the mock — regions, groups, layers; include designer's ASCII wireframe verbatim if reduction ran>

### Element disposition (only if reduction ran)
- <the kept/moved/cut table verbatim — codezilla must not re-add cut elements or drop moved ones>

### Component + token mapping
- <per region: which component from the project's library, which variant/size, which tokens — e.g. "header: layout container, surface-background token, bottom border token; primary action: primary button variant, size md">

### States
- <empty / loading / error / disabled behavior from the spec>

### Rules
- Conform to CODEBASE_RULEBOOK.md: the project's design-system import rules and
  lint bans apply to every line; new shared components go in the design-system
  package, not app code.
- Run the project's check commands (lint/typecheck/tests) before reporting done.
- Green tests are not enough — load the real screen in the running app, in both
  color modes, and compare it against the locked mock.

### Acceptance
- <3–6 checkable statements: "exactly one solid Button on the screen", "advanced
  options are behind a disclosure and hidden by default", "renders correctly in
  both color modes", ...>
```

---

## Rules

- Inspect and spec only. Never edit application code during this skill (the mock and its commit are the only writes).
- Reduction (when it fires) always precedes taste — structure before styling.
- The spec must be expressed in the project's real design-system names; a spec the project's lint bans can't build is a failed spec.
- Anything new the design system needs is a prerequisite in the handoff, implemented by `codezilla` in the design-system package — never inline in app code.
- Every element of the original screen must be accounted for (kept / moved / cut) when reduction runs — silent disappearance is a defect.
- **The mock loop is not optional for structural changes: specs propose, mocks decide.** The locked mock supersedes the spec wherever they differ, and implementation is verified against the mock.
- If the screen is trivial (one control, copy tweak, spacing nudge), say so and hand `codezilla` a one-paragraph brief instead of running the full process — no mock needed.
- Do not start implementation without user approval of the locked mock.
