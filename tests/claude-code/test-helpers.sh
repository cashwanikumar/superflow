#!/usr/bin/env bash
# Helpers for behavioral tests. Adapted from Superpowers' tests/claude-code/test-helpers.sh (MIT, Jesse Vincent).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLUGIN_DIR="$ROOT/plugins/superflow"

# with_timeout SECONDS cmd... — GNU timeout, gtimeout (brew coreutils), or a perl alarm fallback (macOS ships none).
with_timeout() {
  local s="$1"; shift
  if command -v timeout >/dev/null; then timeout "$s" "$@"
  elif command -v gtimeout >/dev/null; then gtimeout "$s" "$@"
  else perl -e 'alarm shift; exec @ARGV' "$s" "$@"
  fi
}

# run_claude "prompt" [timeout_s] [extra claude args...]
# Runs headless with this checkout's plugin loaded, in the current directory.
run_claude() {
  local prompt="$1"; local timeout_s="${2:-120}"; shift 2 || shift $#
  local out; out="$(mktemp)"
  if with_timeout "$timeout_s" claude -p "$prompt" --plugin-dir "$PLUGIN_DIR" --output-format text "$@" > "$out" 2>&1; then
    cat "$out"; rm -f "$out"; return 0
  else
    local rc=$?; cat "$out" >&2; rm -f "$out"; return $rc
  fi
}

assert_contains() {   # output pattern name — case-insensitive
  if echo "$1" | grep -qi -- "$2"; then echo "  [PASS] $3"; return 0
  else echo "  [FAIL] $3"; echo "    expected: $2"; echo "$1" | sed 's/^/    | /' | head -40; return 1; fi
}
assert_not_contains() {
  if echo "$1" | grep -qi -- "$2"; then echo "  [FAIL] $3"; echo "    did not expect: $2"; echo "$1" | sed 's/^/    | /' | head -40; return 1
  else echo "  [PASS] $3"; return 0; fi
}
assert_any() {        # output name pattern... — passes if any pattern matches
  local out="$1" name="$2"; shift 2
  for p in "$@"; do echo "$out" | grep -qi -- "$p" && { echo "  [PASS] $name (matched: $p)"; return 0; }; done
  echo "  [FAIL] $name"; echo "    expected one of: $*"; echo "$out" | sed 's/^/    | /' | head -40; return 1
}

# make_project → path of a fresh git repo with a tiny app and a minimal rulebook
make_project() {
  local d; d="$(mktemp -d)"
  ( cd "$d" && git init -q && \
    mkdir -p src && printf 'export function add(a, b) {\n  return a + b\n}\n' > src/math.js && \
    printf '# CODEBASE RULEBOOK\n\n_How to read this file: `[ENFORCED]` rules fail CI or a hook — non-negotiable. `[OBSERVED]` rules are the house style._\n\n## Tests\n- [OBSERVED] Test files live next to the source as `*.test.js`.\n' > CODEBASE_RULEBOOK.md && \
    git add -A && git commit -qm init )
  echo "$d"
}
export -f with_timeout run_claude assert_contains assert_not_contains assert_any make_project
