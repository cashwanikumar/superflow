#!/usr/bin/env bash
# superflow — session bootstrap.
# Emits the protocol pointer as a SessionStart JSON payload
# (hookSpecificOutput.additionalContext) so Claude Code injects it into context
# reliably. Falls back to plain stdout (also injected for SessionStart) if jq is absent.
set -euo pipefail

read -r -d '' CONTEXT <<'EOF' || true
[superflow] This repo uses the superflow plugin — process skills + specialist coding personas that conform to this repo's own conventions. Apply this protocol on every turn (full detail: load the `superflow` skill).

This protocol is for the MAIN agent only. A spawned persona/subagent does NOT re-run it — it executes its assigned job directly (still consulting the rulebook before any code change).

Skill-check (always on, before acting on non-trivial work): if a process skill fits, invoke it first — brainstorming (build), systematic-debugging (bug/test failure), receiving-code-review (review feedback). See the `using-superpowers` skill for how skills are discovered.

Routing decision for each user turn:
- Message begins with "/" → it's a slash command; run it and skip the opt-in.
- Trivial (single-line explanation, file read, lookup, "what does X do") → answer directly; no opt-in, no delegation.
- Otherwise (non-trivial, no slash command) → BEFORE doing any work, ask once and wait:
    "Run the full superflow for this? It would: <one line tailored to THIS task — which personas, in what order>. (yes / no)"
  yes → run the weave: finder (map) → pm/architect (plan) → designer (UI spec) → dev (build, TDD) → fe/be-unit-tester + bughunter + a11y-hunter (verify) → architect (review). Skip whatever doesn't apply.
  no → answer directly, no sub-agents.
  If the user already opted in earlier this session for the same kind of work, skip the question and proceed.

Always (every persona, every flow):
- Before any code change, consult CODEBASE_RULEBOOK.md at the repo root and conform. If it's missing, offer to run /superflow:codebase-rulebook first. If a change would violate it, stop and ask (exception, or update the rulebook?). Never invent rules that aren't in it.
- Load only the skill the current step touches; spawn only the personas the task needs. Don't blur the context.
- Green tests are necessary, not sufficient: for any user-facing change, verify by exercising the real path in the running app (run it / hit the endpoint / load the page) — not just tests and lint.
EOF

if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$CONTEXT" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
else
  printf '%s\n' "$CONTEXT"
fi
