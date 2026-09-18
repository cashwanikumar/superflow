#!/usr/bin/env bash
# Resync the vendored Superpowers skills from an upstream checkout, then re-apply
# superflow's local edits and refuse to finish if anything dangles.
#
#   scripts/resync-superpowers.sh [<path to a superpowers checkout or plugin cache dir>]
#
# Default source: the newest version under ~/.claude/plugins/cache/claude-plugins-official/superpowers/.
# Local edits live in scripts/superpowers-local-edits.patch — regenerate it (see the bottom of this
# file) whenever you deliberately change a vendored file.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$ROOT/plugins/superflow/skills"
PATCH="$ROOT/scripts/superpowers-local-edits.patch"
VENDORED=(brainstorming finishing-a-development-branch receiving-code-review requesting-code-review systematic-debugging test-driven-development using-git-worktrees verification-before-completion writing-plans)

SRC="${1:-}"
if [ -z "$SRC" ]; then
  CACHE="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"
  SRC="$(ls -d "$CACHE"/*/ 2>/dev/null | sort -V | tail -1)"
  [ -n "$SRC" ] || { echo "no upstream found; pass a superpowers checkout path" >&2; exit 1; }
fi
SRC="${SRC%/}"
[ -d "$SRC/skills" ] || { echo "$SRC has no skills/ directory" >&2; exit 1; }

UP_VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$SRC/.claude-plugin/plugin.json" 2>/dev/null | head -1 || true)"
UP_SHA="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo "n/a")"
echo "upstream: $SRC (version ${UP_VERSION:-?}, sha $UP_SHA)"

# 1. Copy the vendored set verbatim.
for s in "${VENDORED[@]}"; do
  [ -d "$SRC/skills/$s" ] || { echo "upstream no longer ships $s — decide manually" >&2; exit 1; }
  rm -rf "$SKILLS_DIR/$s"
  cp -R "$SRC/skills/$s" "$SKILLS_DIR/$s"
done

# 2. Namespace: superpowers:<skill> → superflow:<skill> so references resolve inside this plugin.
find "${VENDORED[@]/#/$SKILLS_DIR/}" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.js' -o -name '*.ts' \) -print0 \
  | xargs -0 perl -pi -e 's/superpowers:/superflow:/g'

# 3. Re-apply superflow's local edits.
if ! (cd "$ROOT" && patch -p1 --forward --fuzz=3 --no-backup-if-mismatch < "$PATCH"); then
  echo "local edits did not apply cleanly — resolve the .rej files, then regenerate the patch" >&2
  exit 1
fi

# 4. Nothing may point at a skill, agent or workflow this plugin does not ship.
dangling=0
while read -r name; do
  if [ ! -d "$SKILLS_DIR/$name" ] && [ ! -f "$ROOT/plugins/superflow/agents/$name.md" ] && [ ! -f "$ROOT/plugins/superflow/workflows/$name.js" ]; then
    echo "DANGLING superflow:$name in: $(grep -rlE "superflow:$name\b" "${VENDORED[@]/#/$SKILLS_DIR/}" | sed "s|$ROOT/||" | tr '\n' ' ')" >&2
    dangling=1
  fi
done < <(grep -rhoE 'superflow:[a-z-]+' "${VENDORED[@]/#/$SKILLS_DIR/}" | sed 's/superflow://' | sort -u)
[ "$dangling" -eq 0 ] || { echo "add the missing skill to VENDORED or extend the patch" >&2; exit 1; }

# 5. Record provenance.
PROVENANCE="Vendored from Superpowers ${UP_VERSION:-?} (sha $UP_SHA) on $(date +%Y-%m-%d)." \
  perl -pi -e 's/^Vendored from Superpowers .*$/$ENV{PROVENANCE}/' "$ROOT/ATTRIBUTION.md"

echo "resynced ${#VENDORED[@]} skills from Superpowers ${UP_VERSION:-?}; review with: git status && git diff --stat"

# To regenerate the patch after a deliberate edit to a vendored file:
#   tmp=$(mktemp -d); cp -R "$SRC/skills/." "$tmp/"; find "$tmp" -type f -name '*.md' | xargs perl -pi -e 's/superpowers:/superflow:/g'
#   for s in "${VENDORED[@]}"; do diff -ru "$tmp/$s" plugins/superflow/skills/$s | sed "s|$tmp/|a/plugins/superflow/skills/|; s|^+++ plugins/|+++ b/plugins/|"; done > scripts/superpowers-local-edits.patch
