#!/usr/bin/env bash
# superflow — optional commit gate (PreToolUse:Bash).
#
# Routes commits through the `superflow:commit-prep` skill instead of letting a
# bare `git commit` slip through unreviewed. /commit-prep (or a deliberate,
# prepared commit) opts through by including the token COMMIT_PREP_OK anywhere in
# the command — e.g. a trailing `# COMMIT_PREP_OK` comment.
#
# OFF BY DEFAULT. superflow installs at user scope by default, and a plugin that
# silently blocks `git commit` in every repo you open is a hostile default. Turn
# it on per repo (or globally, if you want it) with:
#
#   SUPERFLOW_COMMIT_GATE=1
#
# or by setting {"commitGate": true} in .claude/superflow.json at the repo root.
#
# Fail-open: any parsing problem exits 0 without blocking.
set -uo pipefail

input=$(cat)

# --- gate enabled? ---------------------------------------------------------
enabled=0
case "${SUPERFLOW_COMMIT_GATE:-}" in
  1|true|yes|on) enabled=1 ;;
esac

if [ "$enabled" -eq 0 ] && command -v jq >/dev/null 2>&1; then
  cfg="${CLAUDE_PROJECT_DIR:-.}/.claude/superflow.json"
  if [ -f "$cfg" ] && [ "$(jq -r '.commitGate // false' "$cfg" 2>/dev/null)" = "true" ]; then
    enabled=1
  fi
fi

[ "$enabled" -eq 1 ] || exit 0

command -v jq >/dev/null 2>&1 || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

# Match `git commit` in command position — at the start or after a separator (; & && | || (),
# with optional VAR=val prefixes) — so `cd x && git commit` and `git -C dir commit` are caught
# but `echo "git commit"` is not.
if printf '%s' "$cmd" | grep -Eq '(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)'; then
  if printf '%s' "$cmd" | grep -q 'COMMIT_PREP_OK'; then
    exit 0
  fi
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Direct `git commit` is gated in this repo — commits go through the superflow:commit-prep skill (it reviews the diff, stages, writes the message, and commits). Invoke /superflow:commit-prep now instead of committing directly. If you ARE finalizing a commit through commit-prep, include the token COMMIT_PREP_OK in the commit command (e.g. a trailing `# COMMIT_PREP_OK` comment) to pass this gate."
  }
}
JSON
  exit 0
fi
exit 0
