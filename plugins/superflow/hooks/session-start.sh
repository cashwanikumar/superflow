#!/usr/bin/env bash
# superflow — session bootstrap.
# Emits the protocol pointer as a SessionStart JSON payload
# (hookSpecificOutput.additionalContext) so Claude Code injects it into context
# reliably. Falls back to plain stdout (also injected for SessionStart) if jq is absent.
set -euo pipefail

# Full-flow policy. SUPERFLOW_FLOW=auto (default) | always | never.
# The hook cannot detect whether a human is present: the SessionStart payload is
# identical headless and interactive, the hook's stdio is piped either way (the
# payload arrives on stdin), and env vars leak into child sessions. So `auto` hands
# the decision to the agent, which does know; `always`/`never` make it deterministic
# for CI and other unattended runs.
case "${SUPERFLOW_FLOW:-auto}" in
  always)
    POLICY='Full-flow policy: ALWAYS (SUPERFLOW_FLOW=always). Never ask the opt-in — run the weave on every non-trivial turn.'
    ;;
  never)
    POLICY='Full-flow policy: NEVER (SUPERFLOW_FLOW=never). Never ask the opt-in and never spawn the weave — work directly, still rulebook-first.'
    ;;
  *)
    POLICY='Full-flow policy: AUTO (default).
Do not assume a human is present. Treat the session as unattended unless there is positive evidence otherwise this turn — a human-authored message that reads like a reply, an earlier answered question, an interruption. Absence of evidence is unattended, because a question asked into an unattended run stalls it and nothing gets done.
- Human in the loop (positive evidence) → ask once and WAIT:
    "Run the full superflow for this? It would: <one line tailored to THIS task — which personas, in what order>. (yes / no)"
  yes → run the weave. no → answer directly, no sub-agents. Already opted in earlier this session for the same kind of work → skip the question and proceed.
- No human in the loop → do NOT ask; a question nobody can answer only stalls the run. Choose BEFORE you touch anything. The FIRST LINE of your reply must be the choice, verbatim in this format and nothing else on that line: "superflow: weave — <reason>" or "superflow: direct — <reason>". This is the only audit trail an unattended run leaves; do not skip it, and do not bury it mid-reply.
  Default is the weave. Direct is permitted only when ALL THREE hold, judged from the request before you start:
    (a) it asks for ONE capability — an "and" joining two features fails this;
    (b) you can name up front the single file you will edit;
    (c) CODEBASE_RULEBOOK.md already covers that kind of change.
  Unsure on any of them → weave. If you claimed direct and then find yourself editing a second file, say so plainly in your final message rather than restating the original claim.
  Set SUPERFLOW_FLOW=always or SUPERFLOW_FLOW=never to remove the judgement call.'
    ;;
esac

read -r -d '' CONTEXT <<'EOF' || true
[superflow] This repo uses the superflow plugin — process skills + specialist coding personas that conform to this repo's own conventions. Apply this protocol on every turn (full detail: load the `superflow` skill).

This protocol is for the MAIN agent only. A spawned persona/subagent does NOT re-run it — it executes its assigned job directly (still consulting the rulebook before any code change).

Skill-check (always on, before acting on non-trivial work): if a process skill fits, invoke it first — brainstorming (build), systematic-debugging (bug/test failure), receiving-code-review (review feedback). See the `using-superpowers` skill for how skills are discovered.

Routing decision for each user turn:
- Message begins with "/" → it's a slash command; run it and skip the opt-in.
- Trivial (single-line explanation, file read, lookup, "what does X do") → answer directly; no opt-in, no delegation.
- Otherwise (non-trivial, no slash command) → BEFORE doing any work, apply the full-flow policy below.
  The weave: superflow:finder (map) → superflow:pm / superflow:architect (plan) → superflow:designer (UI spec) → superflow:dev (build, TDD) → superflow:fe-unit-tester / superflow:be-unit-tester + superflow:bughunter + superflow:a11y-hunter (verify) → superflow:architect (review). Skip whatever doesn't apply.
  ALWAYS dispatch personas and skills with the superflow: prefix — subagent_type "superflow:dev", never bare "dev". A bare name either fails to resolve or silently hits a same-named agent in the user's own ~/.claude/agents/, which has never seen this protocol.

__POLICY__

Always (every persona, every flow):
- Before any code change, consult CODEBASE_RULEBOOK.md at the repo root and conform. If it's missing, offer to run /superflow:codebase-rulebook first (headless: just run it). If a change would violate it, stop and ask (exception, or update the rulebook?) — headless, note the violation in your final message instead of stalling. Never invent rules that aren't in it.
- Load only the skill the current step touches; spawn only the personas the task needs. Don't blur the context.
- Green tests are necessary, not sufficient: for any user-facing change, verify by exercising the real path in the running app (run it / hit the endpoint / load the page) — not just tests and lint. If the environment blocks that (no deps installed, no network, no permission), say so explicitly rather than implying it was verified.
EOF

CONTEXT="${CONTEXT//__POLICY__/$POLICY}"

if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$CONTEXT" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
else
  printf '%s\n' "$CONTEXT"
fi
