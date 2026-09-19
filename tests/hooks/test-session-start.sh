#!/usr/bin/env bash
# The SessionStart hook must emit valid JSON with the running version and the flow mode.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
P="$ROOT/plugins/superflow"
HOOK="$P/hooks/session-start.sh"
fails=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; fails=$((fails + 1)); }

command -v jq >/dev/null || { echo "  [SKIP] jq not installed"; exit 0; }
version="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$P/.claude-plugin/plugin.json" | head -1)"

out="$(CLAUDE_PLUGIN_ROOT="$P" bash "$HOOK")"
echo "$out" | jq -e . >/dev/null 2>&1 && pass "output is JSON" || fail "output is not JSON: $out"
ctx="$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext')"
[ "$(echo "$out" | jq -r '.hookSpecificOutput.hookEventName')" = "SessionStart" ] && pass "hookEventName is SessionStart" || fail "hookEventName wrong"
[[ "$ctx" == "[superflow $version]"* ]] && pass "context starts with [superflow $version]" || fail "context does not start with the version: ${ctx:0:40}"
[[ "$ctx" == *"SUPERFLOW_FLOW=auto"* ]] && pass "default mode is auto" || fail "default mode not stated as auto"
[[ "$ctx" == *'`superflow` skill'* ]] && pass "points at the superflow skill" || fail "does not point at the superflow skill"

out2="$(SUPERFLOW_FLOW=never CLAUDE_PLUGIN_ROOT="$P" bash "$HOOK")"
[[ "$(echo "$out2" | jq -r '.hookSpecificOutput.additionalContext')" == *"SUPERFLOW_FLOW=never"* ]] && pass "SUPERFLOW_FLOW env is echoed" || fail "SUPERFLOW_FLOW=never not echoed"

matcher="$(jq -r '.hooks.SessionStart[0].matcher' "$P/hooks/hooks.json")"
[ "$matcher" = "startup|clear|compact" ] && pass "matcher excludes resume" || fail "matcher is '$matcher'"

echo
[ "$fails" -eq 0 ] && exit 0 || exit 1
