# The Weave & the Specbook

superflow turns non-trivial coding work into a staged pipeline of process skills and specialist personas. It can also keep a **specbook** — a durable spec layer in your repo, so requirements outlive the conversation. Here is how the pieces move, with worked examples.

> Written against superflow 0.4. The weave and the specbook are unchanged in 0.5 — see the [README](../README.md) for what 0.5 added (deterministic workflows, the mock-locked design loop, handoff contracts).

---

## 1. Two tiers, one gate

A cheap check runs on every message and never spawns agents. The expensive half — full process skills plus the persona team — sits behind a single opt-in.

```mermaid
flowchart LR
    M([your message]) --> SC{{"skill-check<br/>always-on · no agents"}}
    SC -->|trivial| ANS([answered directly<br/>nothing spawned])
    SC -->|non-trivial| GATE{"opt-in gate<br/>“run the full flow?”"}
    GATE -->|no| SOLO([solo<br/>you + superflow, in-thread])
    GATE -->|yes| WEAVE([the weave<br/>skill + persona per stage])
```

**Saying yes runs the whole machine.** Each stage has a fixed skill-plus-persona binding, and the task decides how many of the nine stages show up. If `specbook/` exists in the repo, the session-start hook has already said so — both the solo path and the weave read it. Headless runs never see the question: the policy (`SUPERFLOW_FLOW`) decides, and the transcript opens with the choice.

---

## 2. The specbook — requirements that outlive the chat

Opt-in, once per repo. Everything superflow used to know only in the conversation now has a place on disk.

| | |
|---|---|
| **`CODEBASE_RULEBOOK.md`** | Conventions. *How* this repo builds things — stack, layout, test setup, lint rules. Written by `auditor`. |
| **`specbook/`** | Requirements. *What* the system must do — living per-capability specs with Given/When/Then scenarios. Written by `pm`. |

```
specbook/
├── README.md                        # orientation + path preferences
├── specs/                           # living requirements, one file per capability
│   ├── auth.md                      #   R1, R2… each with Given/When/Then scenarios
│   └── invoices.md
├── changes/                         # one folder per in-flight change
│   └── 2026-08-16-google-oauth/
│       ├── proposal.md              #   pm — what & why + Spec deltas
│       ├── design.md                #   technical design (brainstorming lands here)
│       └── tasks.md                 #   checkbox plan (writing-plans lands here)
└── archive/                         # finished changes, moved after fold-back
```

```mermaid
flowchart LR
    CMD(["/superflow:specbook<br/>run once · pm leads, finder maps"]) -->|bootstrap| SPECS["specs/<br/>auth.md · invoices.md · …<br/>living requirements"]
    PLAN["Plan stage<br/>(or --change slug)"] -->|opens| CH["changes/date-slug/<br/>proposal.md · design.md · tasks.md"]
    CH -->|"fold Spec deltas — Finish · pm"| SPECS
    CH -->|move| ARC["archive/<br/>done changes"]
    SPECS -.->|"read at Understand · checked at Verify"| USE([the weave])
```

**The fold-back is the whole point.** A proposal writes its requirements as *Spec deltas* — the future spec text, in full. At Finish, `pm` applies those deltas to `specs/` verbatim and archives the folder, so the living specs always describe the shipped system. `auditor` still writes only the rulebook; the two never touch each other's files.

Activation is a single directory check: no `specbook/`, no spec behavior. superflow will mention the option at most once per interactive session and never creates the directory on its own — a repo that hasn't opted in pays zero overhead.

---

## 3. Three runs, same machine

### Example 1 — a small change, no specbook

"Add a rate limit to `/login`" in a repo that never opted in. Four of nine stages; nothing else changes.

```mermaid
flowchart LR
    Q(["“rate-limit /login”<br/>gate → yes"]) --> U["Understand<br/>finder"]
    U --> B["Build<br/>dev · TDD"]
    B --> V["Verify<br/>bughunter"]
    V --> R["Review<br/>architect → ship"]
```

**4 of 9 stages.** Plan is skipped for a single-capability change — and since a change folder is opened only by the Plan stage, a run this small would create no folder *even in a repo with a specbook*. Minimum-spawn survives the new layer.

### Example 2 — a full feature, specbook present

"Add sign-in with Google (OAuth)" in a repo that opted in. Eight stages run — and now each one reads or writes something durable.

```mermaid
flowchart TD
    U["Understand · finder"] --> P["Plan · pm + architect"]
    P --> I["Isolate · git worktree"]
    I --> D["Design · designer"]
    D --> B["Build · dev · TDD"]
    B --> V["Verify · QA + a11y"]
    V --> R["Review · architect"]
    R --> F["Finish · auditor + pm"]

    SPEC["specs/auth.md<br/>the affected living spec"]
    CH["changes/2026-08-16-google-oauth/<br/>proposal.md · design.md · tasks.md"]
    ARC["archive/"]

    U -.->|reads| SPEC
    P -->|opens the folder · writes all three files| CH
    B -.->|works tasks.md, top to bottom| CH
    V -.->|tests the deltas’ Scenarios| CH
    R -.->|requirements input| CH
    F -->|closes it out| ARC
    CH -->|fold Spec deltas| SPEC
    CH -->|move| ARC
```

**8 of 9 stages** (only Debug sits out — nothing is broken yet). The top chain is the weave; the bottom band is what the specbook adds. Plan leaves three files a human can read and edit *before any code exists*; Verify gets scenarios instead of guesses; and Finish leaves `specs/auth.md` updated to describe the system that actually shipped. Solid arrows write, dashed arrows read.

### Example 3 — direct work under a specbook

Not every change earns the weave. The drift rule keeps small changes honest without spawning anyone.

```mermaid
flowchart LR
    A([a small ask]) --> B([direct<br/>no change folder opened])
    B --> C{"alters spec-covered<br/>behavior?"}
    C -->|yes| D["update the touched spec<br/>in the same change"]
    C -->|no| E([ship<br/>specs untouched])
```

**Specs stay true even off the weave.** Headless variant: instead of stalling to ask, the run states the drift in its final message — same honesty posture as the rulebook-violation rule.

---

## 4. Unattended runs

`SUPERFLOW_FLOW` still controls the gate. The specbook adds one axis: whether the directory exists.

| Mode | `specbook/` present | `specbook/` absent |
|---|---|---|
| `auto` (default) | Weave writes change folders; direct work reads specs and notes drift in the final message instead of stalling. | Interactive: one line, once — "`/superflow:specbook` bootstraps a spec layer if you want one." Headless: silence — never mentioned, never created. |
| `always` | Every non-trivial turn runs the weave, spec-aware. | Silence, never created. |
| `never` | No personas — but direct work still consults affected specs and notes drift. | Silence, never created. |

---

## 5. The specbook command surface

| Command | What it does |
|---|---|
| `/superflow:specbook` | bootstrap — pm + finder derive baseline capability specs from the codebase |
| `/superflow:specbook --refresh [capability]` | re-derive vs current code; `<!-- human-edited -->` sections survive |
| `/superflow:specbook --change <slug>` | open a change folder by hand (the Plan stage normally does this) |
| `/superflow:specbook --archive <slug>` | fold Spec deltas into `specs/`, move the folder to `archive/` |
| `/superflow:specbook --dry-run` | combinable with any form — show, don't write |

---

*The specbook is OpenSpec-inspired, superflow-native. Rulebook = how, specbook = what.*
