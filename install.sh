#!/usr/bin/env bash
# handoff-harness installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash -s -- --update
set -euo pipefail

compute_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "ERROR: Neither sha256sum nor shasum found." >&2
    exit 1
  fi
}

get_category() {
  local filepath="$1"
  case "$filepath" in
    VERSION)                              echo "harness-owned" ;;
    scripts/*)                            echo "harness-owned" ;;
    hooks/*)                              echo "harness-owned" ;;
    .claude/agents/*)                     echo "harness-owned" ;;
    .claude/commands/*)                   echo "harness-owned" ;;
    .claude/hooks/*)                      echo "harness-owned" ;;
    .claude/settings.json)                echo "harness-owned" ;;
    docs/AGENTS.md)                       echo "harness-owned" ;;
    CLAUDE.md)                            echo "project-owned" ;;
    docs/CONTRIBUTING.md)                 echo "project-owned" ;;
    docs/ARCHITECTURE.md)                 echo "project-owned" ;;
    docs/RELIABILITY.md)                  echo "project-owned" ;;
    docs/QUALITY_SCORE.md)                echo "project-owned" ;;
    setup.sh)                             echo "scaffold" ;;
    *.gitkeep)                            echo "scaffold" ;;
    docs/exec-plans/tech-debt-tracker.md) echo "scaffold" ;;
    *)                                    echo "scaffold" ;;
  esac
}

get_manifest_checksum() {
  local filepath="$1"
  local manifest="$2"
  grep -A 3 "\"$filepath\"" "$manifest" \
    | grep '"checksum"' \
    | sed 's/.*"checksum"[[:space:]]*:[[:space:]]*"//; s/".*//'
}

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

if $UPDATE; then
  # === UPDATE FLOW ===

  # Step 1: Read remote VERSION
  if [ -f "$TMPDIR/handoff-harness/src/VERSION" ]; then
    REMOTE_VERSION="$(cat "$TMPDIR/handoff-harness/src/VERSION" | tr -d '[:space:]')"
  else
    echo "ERROR: Remote VERSION file not found. The remote repository may be corrupted."
    rm -rf "$TMPDIR"
    exit 1
  fi

  # Step 2: Read local VERSION
  if [ -f "$TARGET/VERSION" ]; then
    LOCAL_VERSION="$(cat "$TARGET/VERSION" | tr -d '[:space:]')"
  else
    LOCAL_VERSION="(unknown)"
  fi

  # Step 3: Version comparison (early exit)
  if [ "$LOCAL_VERSION" != "(unknown)" ] && [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
    echo "Already at version $LOCAL_VERSION -- nothing to update."
    rm -rf "$TMPDIR"
    exit 0
  fi

  # Step 4: Read existing manifest
  MANIFEST="$TARGET/.harness-manifest.json"
  MANIFEST_MISSING=false
  if [ ! -f "$MANIFEST" ]; then
    MANIFEST_MISSING=true
  fi

  # Step 5: Enumerate remote files
  PACK_FILES=$(cd "$TMPDIR/handoff-harness/src" && find . \
    -not -path './.git/*' \
    -not -path './.git' \
    -not -name '.' \
    -type f | sort)

  # Step 6: Initialize counters and merge list
  updated=0
  merged=0
  skipped=0
  merge_list=""

  # Step 7: Per-file processing loop
  for file in $PACK_FILES; do
    clean_path="${file#./}"
    category="$(get_category "$clean_path")"
    src="$TMPDIR/handoff-harness/src/$file"
    dest="$TARGET/$clean_path"

    case "$category" in
      scaffold)
        skipped=$((skipped + 1))
        ;;
      harness-owned)
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        updated=$((updated + 1))
        ;;
      project-owned)
        if [ "$MANIFEST_MISSING" = true ]; then
          # No manifest = pre-manifest installation. Treat ALL project-owned
          # files as customized. Write sidecar for user to review.
          mkdir -p "$(dirname "$dest")"
          cp "$src" "${dest}.harness-update"
          merge_list="$merge_list $clean_path"
          merged=$((merged + 1))
        elif [ ! -f "$dest" ]; then
          # File never existed locally. Copy it in fresh.
          mkdir -p "$(dirname "$dest")"
          cp "$src" "$dest"
          updated=$((updated + 1))
        else
          # File exists locally. Compare current checksum to manifest baseline.
          local_checksum="$(compute_sha256 "$dest")"
          manifest_checksum="$(get_manifest_checksum "$clean_path" "$MANIFEST")"
          if [ "$local_checksum" = "$manifest_checksum" ]; then
            # File unchanged by user -- safe to overwrite.
            cp "$src" "$dest"
            updated=$((updated + 1))
          else
            # File customized by user -- write sidecar instead.
            cp "$src" "${dest}.harness-update"
            merge_list="$merge_list $clean_path"
            merged=$((merged + 1))
          fi
        fi
        ;;
    esac
  done

  # Step 8: Set executable permissions
  chmod +x "$TARGET/scripts/"*.sh 2>/dev/null || true
  chmod +x "$TARGET/hooks/"* 2>/dev/null || true
  chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true
  chmod +x "$TARGET/setup.sh" 2>/dev/null || true

  # Step 9: Generate new .harness-manifest.json
  HARNESS_VERSION="$REMOTE_VERSION"
  INSTALLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  MANIFEST_TMP="$(mktemp)"

  printf '{\n' > "$MANIFEST_TMP"
  printf '  "harness_version": "%s",\n' "$HARNESS_VERSION" >> "$MANIFEST_TMP"
  printf '  "installed_at": "%s",\n' "$INSTALLED_AT" >> "$MANIFEST_TMP"
  printf '  "files": {\n' >> "$MANIFEST_TMP"

  first=true
  for file in $PACK_FILES; do
    clean_path="${file#./}"
    checksum="$(compute_sha256 "$TARGET/$clean_path")"
    category="$(get_category "$clean_path")"
    if [ "$first" = true ]; then
      first=false
    else
      printf ',\n' >> "$MANIFEST_TMP"
    fi
    printf '    "%s": {\n' "$clean_path" >> "$MANIFEST_TMP"
    printf '      "category": "%s",\n' "$category" >> "$MANIFEST_TMP"
    printf '      "checksum": "%s"\n' "$checksum" >> "$MANIFEST_TMP"
    printf '    }' >> "$MANIFEST_TMP"
  done

  printf '\n  }\n' >> "$MANIFEST_TMP"
  printf '}\n' >> "$MANIFEST_TMP"

  mv "$MANIFEST_TMP" "$TARGET/.harness-manifest.json"

  # Step 10: Cleanup
  rm -rf "$TMPDIR"

  # Step 11: Print changelog summary
  echo ""
  echo "Updated handoff-harness: $LOCAL_VERSION -> $REMOTE_VERSION"
  echo "  Files updated:       $updated"
  echo "  Files needing merge: $merged"
  echo "  Files skipped:       $skipped  (scaffold, unchanged)"
  echo ""

  # Step 12: List sidecar files (if any)
  if [ "$merged" -gt 0 ]; then
    echo "The following files have been customized and need manual merge:"
    echo "Review each .harness-update file and apply desired changes:"
    echo ""
    for path in $merge_list; do
      echo "  $path -> ${path}.harness-update"
    done
    echo ""
  fi

else
  # === FRESH INSTALL FLOW ===

  # Files to copy (relative to src/)
  PACK_FILES=$(cd "$TMPDIR/handoff-harness/src" && find . \
    -not -path './.git/*' \
    -not -path './.git' \
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
    src="$TMPDIR/handoff-harness/src/$file"
    dest="$TARGET/$file"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  done

  # Make scripts executable
  chmod +x "$TARGET/scripts/"*.sh 2>/dev/null || true
  chmod +x "$TARGET/hooks/"* 2>/dev/null || true
  chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true
  chmod +x "$TARGET/setup.sh" 2>/dev/null || true

  # Generate manifest
  HARNESS_VERSION="$(cat "$TARGET/VERSION" | tr -d '[:space:]')"
  INSTALLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  MANIFEST_TMP="$(mktemp)"

  printf '{\n' > "$MANIFEST_TMP"
  printf '  "harness_version": "%s",\n' "$HARNESS_VERSION" >> "$MANIFEST_TMP"
  printf '  "installed_at": "%s",\n' "$INSTALLED_AT" >> "$MANIFEST_TMP"
  printf '  "files": {\n' >> "$MANIFEST_TMP"

  first=true
  for file in $PACK_FILES; do
    clean_path="${file#./}"
    checksum="$(compute_sha256 "$TARGET/$clean_path")"
    category="$(get_category "$clean_path")"
    if [ "$first" = true ]; then
      first=false
    else
      printf ',\n' >> "$MANIFEST_TMP"
    fi
    printf '    "%s": {\n' "$clean_path" >> "$MANIFEST_TMP"
    printf '      "category": "%s",\n' "$category" >> "$MANIFEST_TMP"
    printf '      "checksum": "%s"\n' "$checksum" >> "$MANIFEST_TMP"
    printf '    }' >> "$MANIFEST_TMP"
  done

  printf '\n  }\n' >> "$MANIFEST_TMP"
  printf '}\n' >> "$MANIFEST_TMP"

  mv "$MANIFEST_TMP" "$TARGET/.harness-manifest.json"

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
fi
