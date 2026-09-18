#!/usr/bin/env bash
# superflow — session bootstrap. Emits a pointer, not the policy: the gate, the weave
# and the rulebook rules live in the `superflow` skill only.
set -euo pipefail

version=$( { sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "${CLAUDE_PLUGIN_ROOT:-.}/.claude-plugin/plugin.json" 2>/dev/null || true; } | head -1)
mode="${SUPERFLOW_FLOW:-auto}"

CONTEXT="[superflow ${version:-?}] SUPERFLOW_FLOW=${mode}. Main agent only; a spawned persona never re-runs this. Per turn: a message starting with \"/\" → run that slash command. Trivial (a lookup, a read, an explanation, or any question or opinion with no code change asked for) → answer directly. Any code change → load the \`superflow\` skill and follow it before touching code."

if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$CONTEXT" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
else
  printf '%s\n' "$CONTEXT"
fi
