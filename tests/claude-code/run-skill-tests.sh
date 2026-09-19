#!/usr/bin/env bash
# Behavioral tests: drive `claude -p --plugin-dir plugins/superflow` against throwaway repos.
# Slow (minutes) and spends tokens. Run one with: tests/claude-code/run-skill-tests.sh -t gate
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
command -v claude >/dev/null || { echo "claude CLI not found"; exit 1; }
only=""; [ "${1:-}" = "-t" ] && only="$2"
fails=0
for t in "$DIR"/test-*.sh; do
  [ -n "$only" ] && [[ "$(basename "$t")" != *"$only"* ]] && continue
  echo "== $(basename "$t")"
  bash "$t" || fails=$((fails+1))
done
echo; [ "$fails" -eq 0 ] && echo "all behavioral tests passed" || { echo "$fails behavioral test file(s) failed"; exit 1; }
