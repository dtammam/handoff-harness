#!/usr/bin/env bash
# handoff-harness v2 installer.
#
#   Fresh:   install.sh --preset=lean|standard [--targets=claude,cursor]
#   Update:  install.sh --update
#   Migrate: install.sh --migrate   (archive a v1 install, then fresh v2)
#
# Presets are config, not file trees: both install core/ and differ only in the
# defaults written to .harness/harness.toml. Updates are region-aware — harness
# regions refresh, your `keep` regions are preserved (see core/lib/regions.md).
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="${SELF_DIR}"                 # dir holding core/ and presets.toml
TARGET="$(pwd)"
MODE="fresh"
PRESET=""
TARGETS="claude"

for arg in "$@"; do
  case "$arg" in
    --update)      MODE="update" ;;
    --migrate)     MODE="migrate" ;;
    --preset=*)    PRESET="${arg#--preset=}" ;;
    --targets=*)   TARGETS="${arg#--targets=}" ;;
    --source=*)    SRC="${arg#--source=}" ;;
    --target=*)    TARGET="${arg#--target=}" ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

CORE="$SRC/core"
PRESETS="$SRC/presets.toml"
[ -d "$CORE" ] || { echo "install: core/ not found under $SRC" >&2; exit 2; }

# --- preset defaults -------------------------------------------------------
preset_val() { # preset_val <preset> <key>
  awk -v p="[$1]" -v k="$2" '
    $0==p {inb=1; next}
    /^\[/ {inb=0}
    inb && $0 ~ ("^[[:space:]]*" k "[[:space:]]*=") {
      sub(/^[^=]*=[[:space:]]*/,""); gsub(/^"|"[[:space:]]*$/,""); print; exit
    }' "$PRESETS"
}

if [ "$MODE" = "fresh" ] || [ "$MODE" = "migrate" ]; then
  if [ -z "$PRESET" ]; then
    echo "Choose a preset:"; echo
    echo "  lean      $(preset_val lean blurb)"; echo
    echo "  standard  $(preset_val standard blurb)"; echo
    printf "preset [lean]: "; read -r PRESET </dev/tty || PRESET="lean"
    PRESET="${PRESET:-lean}"
  fi
fi
if [ "$MODE" = "update" ] && [ -f "$TARGET/.harness/harness.toml" ]; then
  PRESET="$(awk -F'"' '/^flavor/{print $2; exit}' "$TARGET/.harness/harness.toml")"
  t="$(awk -F'[][]' '/^targets/{print $2; exit}' "$TARGET/.harness/harness.toml" | tr -d ' "')"
  [ -n "$t" ] && TARGETS="$t"
fi
case "$PRESET" in lean|standard|"") : ;; *) echo "install: unknown preset '$PRESET'" >&2; exit 2 ;; esac

# --- source → target file map ----------------------------------------------
# Columns: SRC_REL | DEST_REL | CATEGORY | SCOPE
#   CATEGORY: region  (region-aware merge, preserves keep)
#             whole   (harness-owned, overwritten every update)
#             once    (project-owned, placed once, never overwritten)
#             scaffold(empty dir marker)
#   SCOPE:    all | claude   (comma-list; matched against --targets, "all" always)
read -r -d '' MAP <<'EOF'
AGENTS.md|AGENTS.md|region|all
CLAUDE.md|CLAUDE.md|region|claude
flow.md|.harness/flow.md|whole|all
scrutiny.toml|.harness/scrutiny.toml|once|all
docs/CONTRIBUTING.md|docs/CONTRIBUTING.md|once|all
docs/ARCHITECTURE.md|docs/ARCHITECTURE.md|once|all
docs/RELIABILITY.md|docs/RELIABILITY.md|once|all
lib/harness-markers.md|.harness/lib/harness-markers.md|whole|all
lib/gate-protocol.md|.harness/lib/gate-protocol.md|whole|all
lib/regions.md|.harness/lib/regions.md|whole|all
lib/check-markers.sh|.harness/lib/check-markers.sh|whole|all
lib/apply-regions.sh|.harness/lib/apply-regions.sh|whole|all
.claude/agents/adversary.md|.claude/agents/adversary.md|whole|claude
.claude/agents/qa.md|.claude/agents/qa.md|whole|claude
.claude/agents/security-brief.md|.claude/agents/security-brief.md|whole|claude
.claude/commands/start.md|.claude/commands/start.md|whole|claude
.claude/commands/gate.md|.claude/commands/gate.md|whole|claude
.claude/commands/release.md|.claude/commands/release.md|whole|claude
.claude/commands/status.md|.claude/commands/status.md|whole|claude
.claude/commands/seed.md|.claude/commands/seed.md|whole|claude
.claude/hooks/session-start.sh|.claude/hooks/session-start.sh|whole|claude
.claude/settings.json|.claude/settings.json|once|claude
EOF

in_scope() { # in_scope <scope-field>
  [ "$1" = "all" ] && return 0
  case ",$TARGETS," in *",$1,"*) return 0 ;; esac
  return 1
}

# --- migrate: archive a v1 install first -----------------------------------
if [ "$MODE" = "migrate" ]; then
  V1="$TARGET/.harness/manifest.json"
  STAMP="$(date +%Y%m%d-%H%M%S)"
  ARCH="$TARGET/.state/plans/legacy/$STAMP"
  echo "Migrating v1 → v2 (archiving to .state/plans/legacy/$STAMP)"
  mkdir -p "$ARCH"
  if [ -f "$V1" ]; then
    # v1 manifest tells us which files it owns; archive them, then let the
    # fresh v2 install below overwrite. Project-owned files are left in place.
    grep -oE '"[^"]+"[[:space:]]*:[[:space:]]*\{' "$V1" 2>/dev/null \
      | sed 's/[[:space:]]*:.*//; s/^"//; s/"$//' \
      | while IFS= read -r f; do
          [ -f "$TARGET/$f" ] || continue
          mkdir -p "$ARCH/$(dirname "$f")"; cp "$TARGET/$f" "$ARCH/$f"
        done
    cp "$V1" "$ARCH/manifest.json"
    echo "  archived v1 files per manifest.json"
  else
    echo "  no v1 manifest.json found — archiving nothing, installing v2 fresh"
  fi
  MODE="fresh"
fi

# --- place files ------------------------------------------------------------
placed=""   # dest|category lines for manifest.lock
n_new=0; n_upd=0; n_kept=0
while IFS='|' read -r s d cat scope; do
  [ -n "$s" ] || continue
  in_scope "$scope" || continue
  src="$CORE/$s"; dest="$TARGET/$d"
  [ -f "$src" ] || { echo "  ! missing source: $s (skipped)"; continue; }
  mkdir -p "$(dirname "$dest")"
  case "$cat" in
    region)
      if [ -f "$dest" ] && [ "$MODE" = "update" ]; then
        merged="$(bash "$CORE/lib/apply-regions.sh" "$src" "$dest")"
        printf '%s\n' "$merged" > "$dest"; n_upd=$((n_upd+1))
      else
        bash "$CORE/lib/apply-regions.sh" "$src" > "$dest"; n_new=$((n_new+1))
      fi ;;
    whole)
      cp "$src" "$dest"; n_upd=$((n_upd+1)) ;;
    once)
      if [ -f "$dest" ]; then n_kept=$((n_kept+1)); else cp "$src" "$dest"; n_new=$((n_new+1)); fi ;;
  esac
  placed="${placed}${d}|${cat}
"
done <<< "$MAP"

# scaffold dirs
for dir in docs/exec-plans/active docs/exec-plans/completed; do
  mkdir -p "$TARGET/$dir"
  [ -f "$TARGET/$dir/.gitkeep" ] || : > "$TARGET/$dir/.gitkeep"
done
chmod +x "$TARGET/.harness/lib/"*.sh "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true

# --- stamp + lockfile -------------------------------------------------------
VERSION="$(cd "$SRC/.." 2>/dev/null && git describe --tags --abbrev=0 2>/dev/null || echo dev)"
COMMIT="$(cd "$SRC/.." 2>/dev/null && git rev-parse --short HEAD 2>/dev/null || echo unknown)"
INSTALLED="$(date -u +%Y-%m-%d)"
ANCHOR="$(preset_val "$PRESET" anchor)"; ANCHOR="${ANCHOR:-outcome}"
INVOLVE="$(preset_val "$PRESET" involvement)"; INVOLVE="${INVOLVE:-interactive}"
TARGETS_TOML="$(printf '%s' "$TARGETS" | sed 's/,/", "/g; s/^/"/; s/$/"/')"

mkdir -p "$TARGET/.harness"
if [ ! -f "$TARGET/.harness/harness.toml" ] || [ "$MODE" != "update" ]; then
  sed -e "s/{{FLAVOR}}/$PRESET/" -e "s/{{VERSION}}/$VERSION/" -e "s/{{COMMIT}}/$COMMIT/" \
      -e "s/{{INSTALLED}}/$INSTALLED/" -e "s/{{TARGETS}}/$TARGETS_TOML/" \
      -e "s/{{ANCHOR}}/$ANCHOR/" -e "s/{{INVOLVEMENT}}/$INVOLVE/" \
      "$CORE/lib/harness.toml.tmpl" > "$TARGET/.harness/harness.toml"
else
  # update: bump only version/commit, preserve chosen flavor/targets/defaults
  sed -i.bak -e "s/^version .*/version   = \"$VERSION\"/" -e "s/^commit .*/commit    = \"$COMMIT\"/" \
      "$TARGET/.harness/harness.toml" 2>/dev/null && rm -f "$TARGET/.harness/harness.toml.bak"
fi

{ echo "# generated by the installer — do not edit"; printf '%s' "$placed" | sort; } \
  > "$TARGET/.harness/manifest.lock"

# --- report -----------------------------------------------------------------
echo
echo "handoff-harness v2 — $MODE ($PRESET, targets: $TARGETS)"
echo "  new: $n_new   refreshed: $n_upd   preserved: $n_kept"
echo "  version $VERSION @ $COMMIT"
case "$TARGETS" in *cursor*|*codex*)
  echo "  note: AGENTS.md + docs are portable; the executable seats/commands are"
  echo "        Claude Code-native. In Cursor/Codex, run the gate as a second"
  echo "        session per .harness/lib/gate-protocol.md." ;;
esac
if [ "$MODE" = "fresh" ]; then
  echo
  echo "Next: run /seed to fill the {{placeholders}} in AGENTS.md and docs/,"
  echo "then /start to begin your first piece of work."
fi
