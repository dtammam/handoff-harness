#!/usr/bin/env bash
# handoff-harness installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash -s -- --update
set -euo pipefail

REPO="https://github.com/dtammam/handoff-harness.git"
BRANCH="main"
TMPDIR="$(mktemp -d)"
TARGET="$(pwd)"
UPDATE=false
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

echo "handoff-harness installer"
echo "======================"
echo "Target: $TARGET"
echo "Mode: $(if $UPDATE; then echo 'update'; else echo 'install'; fi)"
echo ""

# Clone the repo
echo "Fetching handoff-harness..."
git clone --depth 1 --branch "$BRANCH" "$REPO" "$TMPDIR/handoff-harness" 2>/dev/null
echo "Done."
echo ""

# Files to copy (relative to repo root)
# Excludes: README.md, LICENSE, install.sh itself, .git
PACK_FILES=$(cd "$TMPDIR/handoff-harness" && find . \
  -not -path './.git/*' \
  -not -path './.git' \
  -not -name 'README.md' \
  -not -name 'LICENSE' \
  -not -name 'install.sh' \
  -not -name '.' \
  -type f | sort)

# Detect greenfield vs brownfield
CONFLICTS=""
for file in $PACK_FILES; do
  target_path="$TARGET/$file"
  if [ -f "$target_path" ]; then
    CONFLICTS="$CONFLICTS $file"
  fi
done

if [ -z "$CONFLICTS" ]; then
  echo "Greenfield detected — no conflicting files."
else
  echo "Brownfield detected — found existing files that will be archived:"
  LEGACY_DIR="$TARGET/.state/plans/legacy/$TIMESTAMP"
  mkdir -p "$LEGACY_DIR"
  for file in $CONFLICTS; do
    target_path="$TARGET/$file"
    legacy_path="$LEGACY_DIR/$file"
    mkdir -p "$(dirname "$legacy_path")"
    cp "$target_path" "$legacy_path"
    echo "  Archived: $file → .state/plans/legacy/$TIMESTAMP/$file"
  done
  echo ""
fi

# Copy files
echo "Hydrating handoff-harness into $TARGET..."
for file in $PACK_FILES; do
  src="$TMPDIR/handoff-harness/$file"
  dest="$TARGET/$file"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
done

# Make scripts executable
chmod +x "$TARGET/scripts/"*.sh 2>/dev/null || true
chmod +x "$TARGET/hooks/"* 2>/dev/null || true
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true
chmod +x "$TARGET/setup.sh" 2>/dev/null || true

# Cleanup
rm -rf "$TMPDIR"

echo "Done. $(echo "$PACK_FILES" | wc -l | tr -d ' ') files hydrated."
echo ""
echo "Next steps:"
echo "  1. Run: bash setup.sh"
echo "  2. Fill in {{placeholders}} in CLAUDE.md, docs/CONTRIBUTING.md, etc."
if [ -n "$CONFLICTS" ]; then
  echo "  3. Review archived files in .state/plans/legacy/$TIMESTAMP/"
  echo "  4. Run the onboarding agent to generate ARCHITECTURE.md from your codebase"
fi
echo ""
echo "For brownfield repos, run the onboarding agent after setup to populate"
echo "ARCHITECTURE.md and agent context from your existing codebase."
