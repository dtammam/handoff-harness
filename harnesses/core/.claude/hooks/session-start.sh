#!/usr/bin/env bash
# SessionStart hook — inject only git-derived and marker-derived facts, never
# stored state. Anything that can silently rot does not belong here.
set -uo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

branch="$(git branch --show-current 2>/dev/null || true)"
echo "Branch: ${branch:-(detached)}"

# Active plan(s) and their real status, read from the doc markers themselves.
shopt -s nullglob 2>/dev/null || true
plans=(docs/exec-plans/active/*.md)
if [ "${#plans[@]}" -gt 0 ]; then
  echo "Active plans (${#plans[@]}):"
  for p in "${plans[@]}"; do
    status="$(grep -m1 '^status:' "$p" 2>/dev/null | sed 's/^status:[[:space:]]*//')"
    echo "  - $(basename "$p"): ${status:-no status marker}"
  done
fi

# Marker health — report, never block. Stale markers surface here first.
if [ -x .harness/lib/check-markers.sh ]; then
  .harness/lib/check-markers.sh docs/exec-plans 2>&1 | sed 's/^/  /' || true
fi
