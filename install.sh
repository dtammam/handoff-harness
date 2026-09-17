#!/usr/bin/env bash
# handoff-harness — installer (bootstrap).
#
# One entry point: clones the harness and delegates to harnesses/install.sh.
# The preset prompt (lean / standard) is the only choice; both install the same
# core and differ only in the default anchor.
#
#   Fresh:   curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash
#   Preset:  ... | bash -s -- --preset=lean
#   Update:  ... | bash -s -- --update
#   Branch:  HH_BRANCH=feature/harness-v2 ... (for testing an unmerged branch)
set -euo pipefail

REPO="https://github.com/dtammam/handoff-harness.git"
BRANCH="${HH_BRANCH:-main}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "handoff-harness: fetching ($BRANCH)…"
git clone --depth 1 --branch "$BRANCH" "$REPO" "$TMP/hh" >/dev/null 2>&1

exec bash "$TMP/hh/harnesses/install.sh" \
  --source="$TMP/hh/harnesses" \
  --target="$(pwd)" \
  "$@"
