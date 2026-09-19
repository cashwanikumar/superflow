#!/usr/bin/env bash
# superflow test runner.
#
#   tests/run-tests.sh            # static + hook tests (seconds, no Claude needed)
#   tests/run-tests.sh --claude   # also run the behavioral tests under tests/claude-code (minutes, spends tokens)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUN_CLAUDE=false
[ "${1:-}" = "--claude" ] && RUN_CLAUDE=true

failed=0
run() {
  echo "── $1"
  if bash "$1"; then echo "   ok"; else echo "   FAILED"; failed=$((failed + 1)); fi
}

run "$ROOT/tests/structure/test-plugin-structure.sh"
run "$ROOT/tests/hooks/test-session-start.sh"
if $RUN_CLAUDE; then
  run "$ROOT/tests/claude-code/run-skill-tests.sh"
fi

echo
[ "$failed" -eq 0 ] && { echo "all test files passed"; exit 0; } || { echo "$failed test file(s) failed"; exit 1; }
