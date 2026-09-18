#!/usr/bin/env bash
# check-markers.sh — enforce the state-as-document marker contract.
#
# Flags stale or misfiled markers so document-state cannot rot silently.
# See lib/harness-markers.md for the vocabulary this enforces.
#
# Usage:   check-markers.sh [plans_dir]     (default: docs/exec-plans)
# Exit:    0 = clean, 1 = issues found, 2 = usage/setup error.
set -uo pipefail

PLANS_DIR="${1:-docs/exec-plans}"
ISSUES=0

if ! command -v git >/dev/null 2>&1; then
  echo "check-markers: git not found" >&2
  exit 2
fi
if [ ! -d "$PLANS_DIR" ]; then
  echo "check-markers: no such directory: $PLANS_DIR" >&2
  exit 2
fi

flag() {
  # $1 = file, $2 = line-ish, $3 = message
  printf '  ✗ %s: %s\n' "$1" "$3"
  ISSUES=$((ISSUES + 1))
}

# Terminal states that must have moved to completed/.
TERMINAL='^(status:[[:space:]]*)?(Shipped|Abandoned)\b'

while IFS= read -r file; do
  [ -f "$file" ] || continue

  # 1. Terminal status still filed under active/.
  if printf '%s' "$file" | grep -q '/active/'; then
    if grep -Eiq "$TERMINAL" "$file"; then
      flag "$file" "-" "terminal status (Shipped/Abandoned) still under active/ — move to completed/"
    fi
  fi

  # 2 & 3. Approval markers (@<sha>): the sha must exist, and the reviewed CODE
  #        must not have changed since it. The plans dir is EXCLUDED from the
  #        diff, so a plan's own bookkeeping (status update, sibling markers,
  #        moving to completed/) never invalidates a still-valid approval. Only
  #        approval markers are checked — a `Gate: CHANGES` line is history.
  while IFS= read -r line; do
    sha="$(printf '%s' "$line" | grep -oE '@[0-9a-f]{7,40}' | head -n1 | tr -d '@')"
    [ -n "$sha" ] || continue
    if ! git cat-file -e "${sha}^{commit}" 2>/dev/null; then
      flag "$file" "$line" "approval marker references unknown commit @$sha"
      continue
    fi
    if ! git diff --quiet "$sha" -- . ":(exclude)$PLANS_DIR" 2>/dev/null; then
      flag "$file" "$line" "stale approval @$sha — reviewed code changed since; re-gate"
    fi
  done < <(grep -En '(Approved|APPROVED)[^@]*@[0-9a-f]{7,40}' "$file" 2>/dev/null || true)

  # 4. Sha-less approvals: a `status:`/`design: Approved` or `Gate: APPROVED`
  #    with no @<sha> must not pass silently — it asserts approval that binds to
  #    nothing.
  while IFS= read -r line; do
    printf '%s' "$line" | grep -qE '@[0-9a-f]{7,40}' && continue
    flag "$file" "$line" "approval marker has no @<sha> — bind it to the reviewed commit"
  done < <(grep -En '^[[:space:]]*(status|design):[[:space:]]*Approved|Gate:[[:space:]]*APPROVED' "$file" 2>/dev/null || true)

done < <(find "$PLANS_DIR/active" -type f -name '*.md' 2>/dev/null | sort)

if [ "$ISSUES" -eq 0 ]; then
  echo "check-markers: clean ($PLANS_DIR)"
  exit 0
fi
echo "check-markers: $ISSUES issue(s) found" >&2
exit 1
