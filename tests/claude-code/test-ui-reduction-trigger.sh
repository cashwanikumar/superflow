#!/usr/bin/env bash
# "Simplify this cluttered screen" must walk ui-reduction: inventory → diagnosis → KEPT/MOVED/CUT — before any styling.
set -uo pipefail
source "$(dirname "$0")/test-helpers.sh"
fails=0
proj="$(make_project)"; cd "$proj"
mkdir -p src/pages
cat > src/pages/Settings.jsx <<'JSX'
export function Settings() {
  return (
    <div className="card"><div className="card"><div className="card">
      <h1>Settings</h1>
      <button>Save</button><button>Save changes</button><button>Export CSV</button><button>Import CSV</button>
      <button>Delete account</button><button>Reset password</button><button>Invite user</button>
      <input placeholder="Display name" /><input placeholder="Email" /><input placeholder="Timezone" />
      <input placeholder="Webhook URL" /><input placeholder="API key" /><input placeholder="Retry count" />
      <label><input type="checkbox" /> Beta features</label><label><input type="checkbox" /> Dark mode</label>
      <label><input type="checkbox" /> Email digest</label><label><input type="checkbox" /> Slack alerts</label>
      <table><tr><td>Plan</td><td>Pro</td></tr><tr><td>Seats</td><td>12</td></tr></table>
      <a href="/help">Help</a><a href="/billing">Billing</a><a href="/logout">Log out</a>
    </div></div></div>
  )
}
JSX
git add -A && git commit -qm settings

echo "-- declutter request loads ui-reduction and produces the reconciliation table (spec only, no edits)"
out="$(SUPERFLOW_FLOW=never run_claude 'The Settings page in src/pages/Settings.jsx is a cluttered mess — simplify it. Produce the design output only; do not edit any file.' 240 --allowed-tools 'Read,Glob,Grep,Skill')"
assert_any "$out" 'walks the reduction method' 'ui-reduction' 'quick diagnostic' 'inventory' || fails=$((fails+1))
assert_any "$out" 'names the source of complexity' 'co-equal\|flat.*pile\|deep nesting\|redundant path\|diagnos' || fails=$((fails+1))
assert_contains "$out" 'CUT' 'reconciliation has CUT rows' || fails=$((fails+1))
assert_any "$out" 'reconciliation has KEPT/MOVED rows' 'KEPT' 'MOVED' || fails=$((fails+1))
assert_contains "$out" 'Save' 'accounts for the duplicate Save button' || fails=$((fails+1))
git -C "$proj" diff --quiet && echo "  [PASS] no files edited" || { echo "  [FAIL] files were edited during a spec-only run"; fails=$((fails+1)); }

rm -rf "$proj"
echo; [ "$fails" -eq 0 ] && exit 0 || exit 1
