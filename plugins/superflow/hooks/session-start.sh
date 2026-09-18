#!/usr/bin/env bash
# superflow — session bootstrap.
# Emits a SHORT protocol pointer as a SessionStart payload. The full policy (gate
# tests, weave table, rulebook rules) lives in ONE place — the
# `superflow` skill — so this file never restates it and the two cannot drift.
set -euo pipefail

# SUPERFLOW_FLOW=auto (default) | always | never. The hook cannot tell whether a
# human is present (payload and stdio are identical either way), so `auto` hands
# that call to the agent; `always`/`never` pin it for CI.
case "${SUPERFLOW_FLOW:-auto}" in
  always) POLICY='Flow policy: ALWAYS — never ask; run the weave on every non-trivial turn.' ;;
  never)  POLICY='Flow policy: NEVER — never ask, never spawn personas; work directly, rulebook-first.' ;;
  *)      POLICY='Flow policy: AUTO — human present (a reply, an answered question, an interruption this session): ask once "Run the full superflow for this? It would: <personas, in order>. (yes / no)" and wait; a yes earlier this session for the same kind of work carries over. No human: do not ask — decide, and make the FIRST LINE of your reply exactly "superflow: weave — <reason>" or "superflow: direct — <reason>". Headless default is DIRECT; weave only when the superflow skill'"'"'s weave triggers fire (more than one capability, UI work, or cross-layer change).' ;;
esac

read -r -d '' CONTEXT <<'EOF2' || true
[superflow] This repo uses the superflow plugin. MAIN agent only — a spawned persona executes its job and never re-runs this.

Per turn: "/" → run the slash command. Trivial (lookup, explain, read, or any question or opinion with no code change asked for) → answer directly. Anything else → load the `superflow` skill and follow its gate before touching code.
__POLICY__
Always:
- Before any code change, conform to CODEBASE_RULEBOOK.md at the repo root (missing → offer /superflow:codebase-rulebook; headless → run it). A change that must violate it → stop and ask; headless → note it in the final message.
- Dispatch with the superflow: prefix (subagent_type "superflow:codezilla", never bare). Spawn only the personas the task needs.
- Green tests are necessary, not sufficient: exercise the real path in the running app, or say plainly that you could not.
EOF2

CONTEXT="${CONTEXT/__POLICY__/$POLICY}"

if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$CONTEXT" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
else
  printf '%s\n' "$CONTEXT"
fi
