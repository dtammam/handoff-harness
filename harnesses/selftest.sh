#!/usr/bin/env bash
# selftest.sh — the stub-repo validation loop, self-contained.
# Proves the install/update contract: fresh install lands, a user's `keep`
# region survives an update, a vandalized harness region reverts, markers pass.
#
#   bash harnesses/selftest.sh
set -uo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"
FAILS=0
ok()   { echo "  ✓ $1"; }
bad()  { echo "  ✗ $1"; FAILS=$((FAILS+1)); }
cleanup() { rm -rf "$T"; }
trap cleanup EXIT

( cd "$T" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )

echo "1. fresh install (lean)"
bash "$SRC/install.sh" --preset=lean --targets=claude --source="$SRC" --target="$T" >/dev/null
[ -f "$T/AGENTS.md" ]                    && ok "AGENTS.md placed"        || bad "AGENTS.md missing"
[ -f "$T/.harness/harness.toml" ]        && ok "stamp written"          || bad "stamp missing"
[ -x "$T/.harness/lib/check-markers.sh" ]&& ok "checker executable"     || bad "checker missing"
grep -q 'flavor    = "lean"' "$T/.harness/harness.toml" && ok "flavor recorded" || bad "flavor wrong"

echo "2. user edits keep region + vandalizes a harness region"
perl -0pi -e 's/_\(none recorded yet.*?fill this in\)_/- KEEP-REGION SENTINEL/s' "$T/AGENTS.md"
perl -0pi -e 's/You — the main session — are the \*\*Architect\*\*\./HARNESS SENTINEL (should revert)./s' "$T/AGENTS.md"

echo "3. update"
bash "$SRC/install.sh" --update --source="$SRC" --target="$T" >/dev/null
grep -q 'KEEP-REGION SENTINEL' "$T/AGENTS.md"     && ok "keep region preserved"   || bad "keep region LOST"
! grep -q 'HARNESS SENTINEL' "$T/AGENTS.md"        && ok "harness region reverted" || bad "harness region NOT reverted"
grep -q 'are the \*\*Architect\*\*' "$T/AGENTS.md" && ok "harness content restored" || bad "harness content missing"

echo "4. marker checker on the installed tree"
( cd "$T" && bash .harness/lib/check-markers.sh docs/exec-plans >/dev/null ) && ok "markers clean" || bad "markers failed"

echo
if [ "$FAILS" -eq 0 ]; then echo "SELFTEST PASS"; exit 0; else echo "SELFTEST FAIL ($FAILS)"; exit 1; fi
