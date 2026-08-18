# A Feature, Woven

*A session diary.* One developer, one Saturday, one feature our invoicing app has needed for a year — recurring invoices — built through the full superflow, with the specbook keeping the receipts.

`repo: tally — a small Express + React invoicing app · plugin: superflow 0.4.0`

> A fictional but faithful walkthrough, written against superflow 0.4: personas, gate wording, file layouts and rules as shipped at the time. Nothing in this story changes in 0.5 — see the [README](../README.md) for what 0.5 added. Companion page: [The Weave & the Specbook](the-weave-and-the-specbook.md).

---

## Scene I — Setup, once · 09:02

Two commands to install, one to teach it my repo, one to opt into the spec layer. That's the whole ceremony, and only the first two are ever repeated in other repos.

```
❯ /plugin marketplace add https://github.com/cashwanikumar/superflow
❯ /plugin install superflow
  Installed superflow 0.4.0 — 10 personas, 21 skills, 1 hook.

❯ /superflow:codebase-rulebook
  architect frames the run, delegates the scan to auditor…
  12 sections written, 3 open questions → CODEBASE_RULEBOOK.md
  Future code changes will consult it.

❯ /superflow:specbook
  bossbaby leads. sherlock is mapping capabilities…
  sherlock: 7 candidates — invoices, clients, payments, reminders,
          auth, exports, webhooks (each with file:line evidence)
  bossbaby: writing baseline specs. Unverified behavior goes under
      Open questions, marked "Baseline — derived from code, verify".
  7 capability specs written, 4 open questions → specbook/
```

```
❯ tree specbook -L 2
specbook/
├── README.md
├── specs/
│   ├── auth.md          ├── invoices.md      ├── clients.md
│   ├── payments.md      ├── reminders.md     ├── exports.md
│   └── webhooks.md
├── changes/             ← empty. nothing in flight
└── archive/             ← empty. nothing shipped yet
```

> **Why bother?** Until today, what tally *must do* lived in my head and in old chat scrollback. Now it's seven Markdown files with numbered requirements and Given/When/Then scenarios — the rulebook says *how* we build, the specbook says *what* it does.

---

## Scene II — A trivial ask spawns nothing · 09:40

The always-on tier is cheap. Questions stay questions.

```
❯ where do we compute invoice totals?
  src/services/invoice-totals.ts:31 — line items reduce into
  subtotal, then tax via applyTaxProfile(). Rounding is
  banker's, per specbook/specs/invoices.md R3.
```

No gate, no personas, four seconds. But notice it cited R3 — the hook told this session a specbook exists, so even a lookup answers from the spec, not from vibes.

---

## Scene III — The feature, and the gate · 10:05

The real ask. This is where superflow asks its one question.

```
❯ add recurring invoices — monthly and quarterly
  Run the full superflow for this? It would: sherlock maps invoicing +
  jobs, bossbaby/architect write the change folder, codezilla builds test-first in
  a worktree, QA verifies against the spec deltas, architect reviews,
  bossbaby folds the spec back at finish. (yes / no)
❯ yes
```

**Understand.** sherlock reads the terrain — including the spec layer — before anyone plans anything.

```
  sherlock: specbook/specs/invoices.md has 5 requirements; R3 (rounding)
  and R5 (numbering is gapless) constrain generation. exports.md
  declares "Depends on: invoices" — CSV export will see new rows.
  specbook/changes/ is empty: no overlapping work in flight.
  Jobs run through src/jobs/scheduler.ts (node-cron, daily 06:00).
```

**Plan.** The lead opens `specbook/changes/2026-08-16-recurring-invoices/`. bossbaby writes the proposal; architect settles the design; the task list lands as checkboxes. Three files exist before a single line of code does.

**`specbook/changes/2026-08-16-recurring-invoices/proposal.md`**

```md
# Proposal: Recurring invoices
_Change: recurring-invoices · Opened: 2026-08-16 · Status: active_

## Context & motivation
Agencies re-issue the same invoice monthly by duplicating last
month's by hand. Three support tickets this quarter; two churned
accounts named it in exit notes.

## Goals & non-goals
- Monthly and quarterly schedules on any invoice.
- Non-goal: proration mid-cycle.

## Spec deltas
- specs/invoices.md  — ADDS R6, R7
- specs/reminders.md — CHANGES R2 (reminders attach to generated
  invoices, not only hand-created ones)

### R6. An invoice can carry a recurring schedule
- Scenario: month-end clamping
  - Given an invoice with schedule=monthly anchored on Jan 31
  - When the generation job runs in February
  - Then a new draft is created dated Feb 28/29 (clamped to month end)

### R7. Generation is idempotent per period
- Scenario: job retry
  - Given the job already generated the March draft
  - When the job re-runs for March
  - Then no second draft exists
```

> **The human beat.** I opened `proposal.md` in my editor, deleted "weekly" from the goals, and added an open question about pausing a schedule. **The plan is a file I can edit, not a chat scroll I can only argue with.** Nothing gets built until this says what I actually want.

**`…/recurring-invoices/tasks.md`**

```md
# Tasks: Recurring invoices
Written by the writing-plans skill. Checkbox items — executing-plans
consumes this file unchanged.

### Task 1: schedule column + model
- [ ] Step 1: failing test — schedule accepts monthly|quarterly|null
- [ ] Step 2: migration + model change
### Task 3: generation job
- [ ] Step 1: failing test — Jan 31 anchor → Feb 28 draft (R6)
- [ ] Step 2: failing test — re-run creates no duplicate (R7)
```

**Isolate → Build.** A worktree at `.worktrees/recurring-invoices`, then codezilla works `tasks.md` top to bottom, test-first — the rulebook supplies the *how* (Vitest, migration naming, service-layer rule), the proposal supplies the *what*.

**Verify** · 11:20 — bughunter doesn't guess what to test. The scenarios are sitting in the deltas.

```
  bughunter — findings, ranked:
  1. HIGH — R7 violation. Killed the job between insert and
     checkpoint, re-ran → two March drafts. Expected (R7 / job
     retry): no second draft. Actual: duplicate.
  2. LOW — generated drafts skip the default reminder, against the
     proposed CHANGES to reminders.md R2. Flagged against the delta.
  codezilla: fixed #1 with an idempotency key on (invoice_id, period);
  fixed #2; both regression tests added. Suite green.
```

**Review → Finish** · 12:02 — architect reviews with the change folder as the requirements input, then the finish menu, then the part that makes the whole layer worth it: the fold-back.

```
  Tests green. Merge to main locally / push + PR / keep as-is?
❯ merge locally
  Merged. Worktree removed.
  bossbaby: folding Spec deltas → specs/invoices.md, specs/reminders.md
      moving change folder → specbook/archive/
  auditor: rulebook refresh — added "background jobs carry
      idempotency keys" to Custom conventions.
```

```diff
--- specbook/specs/invoices.md
- _Last updated: 2026-08-02 (baseline)._
+ _Last updated: 2026-08-16 (change: recurring-invoices)._
  ### R5. Invoice numbering is gapless per client
  …
+ ### R6. An invoice can carry a recurring schedule
+ - Scenario: month-end clamping …
+ ### R7. Generation is idempotent per period
+ - Scenario: job retry …
```

The living spec now describes the system that actually shipped — including the two requirements that didn't exist this morning. `changes/` is empty again; the folder sits in `archive/2026-08-16-recurring-invoices/` with the proposal, the design, and every checked-off task, if anyone ever asks how this happened.

---

## Scene IV — Three weeks later, a fresh session · Sep 4

New conversation. Zero memory of August. A client is confused about their billing date.

```
❯ client says their Jan-31-anchored invoice arrived on Feb 28 — bug?
  Working as specified. specbook/specs/invoices.md R6, scenario
  "month-end clamping": an anchor past the month's last day clamps
  to month end. Shipped in change recurring-invoices (2026-08-16 —
  full context in specbook/archive/ if you want the why).
```

Seconds, not archaeology. The requirement outlived the conversation that created it — which is the entire bet.

And the CI lane never stalls on a question nobody's there to answer. Headless runs decide by rule and stamp the transcript:

```
❯ claude -p "fix the typo in the overdue email subject"
  superflow: direct — one file (src/emails/overdue.ts), covered by
  the rulebook; no spec-covered behavior touched.
```
