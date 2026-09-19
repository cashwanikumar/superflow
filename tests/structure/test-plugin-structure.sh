#!/usr/bin/env bash
# Static checks over the plugin tree. No Claude, no network — runs in a second.
# Every check here caught a real drift at some point (see CHANGELOG 0.7.0, 0.10.0, 0.11.0).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
P="$ROOT/plugins/superflow"
fails=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; fails=$((fails + 1)); }

# 1. Every skill dir has a SKILL.md whose frontmatter name matches the directory.
for d in "$P"/skills/*/; do
  s="$(basename "$d")"
  if [ ! -f "$d/SKILL.md" ]; then fail "skills/$s has no SKILL.md"; continue; fi
  fm_name="$(sed -n '2,6p' "$d/SKILL.md" | sed -n 's/^name: *//p' | head -1)"
  [ "$fm_name" = "$s" ] && pass "skills/$s frontmatter name matches" || fail "skills/$s frontmatter name is '$fm_name'"
  grep -q '^description: .' "$d/SKILL.md" && pass "skills/$s has a description" || fail "skills/$s has no description"
done

# 2. Every agent file's frontmatter name matches its filename.
for f in "$P"/agents/*.md; do
  a="$(basename "$f" .md)"
  fm_name="$(sed -n '2,6p' "$f" | sed -n 's/^name: *//p' | head -1)"
  [ "$fm_name" = "$a" ] && pass "agents/$a frontmatter name matches" || fail "agents/$a frontmatter name is '$fm_name'"
done

# 3. Read-only personas are enforced by metadata, not prose (0.10.0).
for a in sherlock designer; do
  grep -q '^disallowedTools:.*Edit.*Write' "$P/agents/$a.md" && pass "agents/$a is read-only via disallowedTools" || fail "agents/$a lacks disallowedTools Edit/Write"
done

# 4. No `superflow:<name>` reference anywhere in the plugin points at something it does not ship.
dangling=0
while read -r name; do
  if [ ! -d "$P/skills/$name" ] && [ ! -f "$P/agents/$name.md" ] && [ ! -f "$P/workflows/$name.js" ]; then
    fail "dangling superflow:$name in $(grep -rlE "superflow:$name\b" "$P" | sed "s|$ROOT/||" | tr '\n' ' ')"
    dangling=1
  fi
done < <(grep -rhoE 'superflow:[a-z-]+' "$P" | sed 's/superflow://' | sort -u)
[ "$dangling" -eq 0 ] && pass "no dangling superflow: references"

# 5. No leftover upstream namespace inside the plugin (the resync rewrite must be complete).
if grep -rqE 'superpowers:[a-z-]+' "$P"; then
  fail "upstream 'superpowers:' prefix survives in: $(grep -rlE 'superpowers:[a-z-]+' "$P" | sed "s|$ROOT/||" | tr '\n' ' ')"
else
  pass "no 'superpowers:' prefix inside the plugin"
fi

# 6. One version, three places.
v_plugin="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$P/.claude-plugin/plugin.json" | head -1)"
v_changelog="$(grep -m1 '^## ' "$ROOT/CHANGELOG.md" | sed 's/^## *//')"
v_readme="$(grep -oE '\[superflow [0-9]+\.[0-9]+\.[0-9]+\]' "$ROOT/README.md" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
[ "$v_plugin" = "$v_changelog" ] && pass "plugin.json version $v_plugin == CHANGELOG top entry" || fail "plugin.json $v_plugin != CHANGELOG $v_changelog"
[ "$v_plugin" = "$v_readme" ] && pass "plugin.json version == README hook example" || fail "plugin.json $v_plugin != README $v_readme"
grep -q '"version"' "$ROOT/.claude-plugin/marketplace.json" && fail "marketplace.json carries a version (plugin.json is the one source)" || pass "marketplace.json carries no version"

# 7. README counts match the tree.
n_agents="$(ls "$P"/agents/*.md | wc -l | tr -d ' ')"
n_skills="$(ls -d "$P"/skills/*/ | wc -l | tr -d ' ')"
n_workflows="$(ls "$P"/workflows/*.js | wc -l | tr -d ' ')"
grep -q "$n_agents personas, $n_skills skills, $n_workflows workflows" "$ROOT/README.md" && pass "README counts: $n_agents personas, $n_skills skills, $n_workflows workflows" || fail "README counts do not match tree ($n_agents/$n_skills/$n_workflows)"

# 8. Vendored set: resync VENDORED == what ATTRIBUTION claims == what README lists.
vendored=($(sed -n 's/^VENDORED=(\(.*\))$/\1/p' "$ROOT/scripts/resync-superpowers.sh"))
n_vendored="${#vendored[@]}"
grep -q "^$n_vendored of the $n_skills skills" "$ROOT/ATTRIBUTION.md" && pass "ATTRIBUTION says $n_vendored of $n_skills" || fail "ATTRIBUTION count != $n_vendored of $n_skills"
grep -q "The $n_vendored skills copied from Superpowers" "$ROOT/README.md" && pass "README says $n_vendored vendored" || fail "README vendored count != $n_vendored"
for s in "${vendored[@]}"; do
  [ -d "$P/skills/$s" ] || fail "VENDORED lists $s but skills/$s is missing"
  grep -q "\`$s\`" "$ROOT/ATTRIBUTION.md" || fail "ATTRIBUTION does not list vendored skill $s"
done
# The local-edits patch may only touch vendored files.
while read -r f; do
  top="$(echo "$f" | sed -n 's|^plugins/superflow/skills/\([^/]*\)/.*|\1|p')"
  printf '%s\n' "${vendored[@]}" | grep -qx "$top" && pass "patch touches vendored $top" || fail "patch touches non-vendored file $f"
done < <(sed -n 's|^+++ b/||p' "$ROOT/scripts/superpowers-local-edits.patch" | cut -f1)

# 9. Workflows parse.
for w in "$P"/workflows/*.js; do
  node --check "$w" 2>/dev/null && pass "$(basename "$w") parses" || fail "$(basename "$w") does not parse"
  grep -q "^export const meta = {" "$w" && pass "$(basename "$w") has meta" || fail "$(basename "$w") lacks 'export const meta'"
done

# 10. The weave table in the front-door skill only names shipped skills/personas (subset of check 4, but per-row).
weave="$P/skills/superflow/SKILL.md"
for stage in brainstorming writing-plans using-git-worktrees design ui-reduction subagent-driven-development test-driven-development verification-before-completion requesting-code-review receiving-code-review systematic-debugging finishing-a-development-branch; do
  grep -q "superflow:$stage" "$weave" && pass "weave names $stage" || fail "weave does not name $stage"
done

# 11. Hook is a pointer, not the policy (0.10.0).
ctx_words="$(CLAUDE_PLUGIN_ROOT="$P" SUPERFLOW_FLOW=auto bash "$P/hooks/session-start.sh" | { command -v jq >/dev/null && jq -r .hookSpecificOutput.additionalContext || cat; } | wc -w | tr -d " ")"
[ "$ctx_words" -lt 120 ] && pass "hook context is $ctx_words words (< 120)" || fail "hook context is $ctx_words words — the policy is leaking back into the hook"

echo
[ "$fails" -eq 0 ] && exit 0 || { echo "$fails structural check(s) failed"; exit 1; }
