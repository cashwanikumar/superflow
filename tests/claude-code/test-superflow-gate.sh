#!/usr/bin/env bash
# The front door: trivial turns are answered directly; a code change consults the rulebook and a process skill.
set -uo pipefail
source "$(dirname "$0")/test-helpers.sh"
fails=0
proj="$(make_project)"; cd "$proj"

echo "-- trivial question: answered, no skill ceremony, no persona"
out="$(SUPERFLOW_FLOW=auto run_claude 'What does the function in src/math.js return? One sentence.' 90 --allowed-tools 'Read,Glob,Grep')"
assert_contains "$out" 'sum\|adds\|a + b\|addition' 'answers the question' || fails=$((fails+1))
assert_not_contains "$out" 'Run the full superflow' 'does not ask the opt-in for a question' || fails=$((fails+1))
assert_not_contains "$out" 'Using `superflow:brainstorming`\|Using superflow:brainstorming' 'does not load brainstorming for a lookup' || fails=$((fails+1))

echo "-- code change, SUPERFLOW_FLOW=never: direct, rulebook-first, no personas"
out="$(SUPERFLOW_FLOW=never run_claude 'Add a subtract(a, b) function to src/math.js with a test. Then say which files you read before editing.' 180 --allowed-tools 'Read,Glob,Grep,Edit,Write,Bash(node*),Bash(ls*),Bash(cat*),Skill')"
assert_contains "$out" 'CODEBASE_RULEBOOK' 'names the rulebook among files read' || fails=$((fails+1))
[ -f "$proj/src/math.test.js" ] && echo "  [PASS] test file placed per rulebook (src/math.test.js)" || { echo "  [FAIL] no src/math.test.js"; fails=$((fails+1)); }
assert_not_contains "$out" 'Run the full superflow' 'never mode does not ask the opt-in' || fails=$((fails+1))

rm -rf "$proj"
echo; [ "$fails" -eq 0 ] && exit 0 || exit 1
