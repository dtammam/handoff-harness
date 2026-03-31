# Technical Design: versioning-and-seed-nudge

**Stage:** Design
**Date:** 2026-03-31
**Author:** Principal Engineer
**Branch:** feat/versioning-and-seed-nudge

---

## 1. Approach

This feature adds three independent capabilities to the handoff-harness installer:

1. **Version tracking and manifest-based updates** -- a `VERSION` file and `.harness-manifest.json` enable `install.sh --update` to selectively update files based on category (harness-owned, project-owned, scaffold) instead of blindly overwriting everything.
2. **Seed nudge in setup.sh** -- a prominent ASCII banner after setup directs users to run `/seed`.
3. **Placeholder detection in session-start.sh** -- a single `grep -q` check for `{{` in CLAUDE.md, with a nudge if found.

All three are independent in data flow. Requirements R1-R3 (version/manifest/update) form a dependency chain. R4, R5, and R6 are standalone.

---

## 2. New Files

| File | Purpose | Category |
|------|---------|----------|
| `src/VERSION` | Semver string `0.1.0` with trailing newline | harness-owned |
| `VERSION` (top-level) | Self-hosting copy, identical to `src/VERSION` | N/A (self-hosting) |

`.harness-manifest.json` is generated at runtime by `install.sh` in the target repo. It is NOT a source file and NOT in `src/`.

---

## 3. Components Affected

| File | Change Type | Summary |
|------|-------------|---------|
| `install.sh` | Major rewrite | Add portable checksum function, manifest generation, category-aware `--update` logic, version comparison, changelog summary, platform docs in header |
| `src/setup.sh` | Append | Add `/seed` nudge banner after final output |
| `setup.sh` (top-level) | Append | Mirror of `src/setup.sh` change |
| `src/.claude/hooks/session-start.sh` | Insert | Add placeholder detection before closing separator |
| `.claude/hooks/session-start.sh` (top-level) | Insert | Mirror of `src/` change |

---

## 4. VERSION File

**Location:** `src/VERSION` (distributed), copied to target repo root as `VERSION`.

**Format:** A single line containing a semver string, terminated by exactly one newline character.

```
0.1.0
```

No leading/trailing whitespace. No `v` prefix. The file is read with:

```
VERSION="$(cat "$FILE" | tr -d '[:space:]')"
```

The `tr -d '[:space:]'` strips any trailing newline or carriage return, making the read robust regardless of line-ending style.

---

## 5. Manifest Schema

**File:** `.harness-manifest.json` in the target repo root.

### 5.1 Schema

```json
{
  "harness_version": "0.1.0",
  "installed_at": "2026-03-31T14:30:00Z",
  "files": {
    "CLAUDE.md": {
      "category": "project-owned",
      "checksum": "a1b2c3d4e5f6..."
    },
    "scripts/run-build-specialist.sh": {
      "category": "harness-owned",
      "checksum": "f6e5d4c3b2a1..."
    },
    "setup.sh": {
      "category": "scaffold",
      "checksum": "1234abcd5678..."
    }
  }
}
```

### 5.2 Field Definitions

- `harness_version`: String. The semver value read from the `VERSION` file at install time.
- `installed_at`: String. ISO-8601 UTC timestamp of when install.sh completed. Generated via `date -u +"%Y-%m-%dT%H:%M:%SZ"`.
- `files`: Object. Keys are relative paths (from repo root, no leading `./`). Values are objects with:
  - `category`: One of `harness-owned`, `project-owned`, `scaffold`.
  - `checksum`: 64-character lowercase hex SHA-256 digest of the file as written to disk.

### 5.3 What Is NOT in the Manifest

- `.harness-manifest.json` itself.
- `VERSION` IS in the manifest (category: `harness-owned`).
- Files not originating from `src/` (e.g., user files, `.git/`).

### 5.4 JSON Generation Strategy

Since this is a shell-only project with no `jq` dependency, the manifest is built by string concatenation. The implementation shall:

1. Open a temp file and write the opening `{` and top-level fields.
2. Loop over all copied files, computing checksums and looking up categories, appending each entry.
3. Handle the trailing-comma problem by writing entries to an array and joining, OR by writing a leading comma on all entries except the first.
4. Close the JSON and move the temp file to `.harness-manifest.json`.

The developer should use `printf` for reliable quoting and avoid `echo` for JSON fragments to prevent shell interpretation issues.

---

## 6. File Category Assignments

Complete mapping of every file in `src/` to its manifest category. This is the single source of truth for the category-lookup function in `install.sh`.

### 6.1 harness-owned (always overwrite on update)

```
.claude/agents/build-specialist.md
.claude/agents/engineering-manager.md
.claude/agents/principal-engineer.md
.claude/agents/product-manager.md
.claude/agents/quality-assurance.md
.claude/agents/software-developer.md
.claude/commands/commit-and-push.md
.claude/commands/commit-only.md
.claude/commands/kickoff-complex.md
.claude/commands/kickoff.md
.claude/commands/run-build.md
.claude/commands/run-pe.md
.claude/commands/run-pm.md
.claude/commands/run-qa.md
.claude/commands/run-sde.md
.claude/commands/seed.md
.claude/commands/showme.md
.claude/hooks/session-start.sh
.claude/settings.json
docs/AGENTS.md
hooks/pre-commit
hooks/pre-push
scripts/run-build-specialist.sh
scripts/run-principal-engineer.sh
scripts/run-product-manager.sh
scripts/run-quality-assurance.sh
scripts/run-software-developer.sh
VERSION
```

### 6.2 project-owned (sidecar on update if customized)

```
CLAUDE.md
docs/ARCHITECTURE.md
docs/CONTRIBUTING.md
docs/QUALITY_SCORE.md
docs/RELIABILITY.md
```

### 6.3 scaffold (never overwrite)

```
setup.sh
.state/inbox/.gitkeep
.state/plans/active/.gitkeep
.state/plans/completed/.gitkeep
.state/plans/legacy/.gitkeep
docs/exec-plans/active/.gitkeep
docs/exec-plans/completed/.gitkeep
docs/exec-plans/tech-debt-tracker.md
docs/references/.gitkeep
```

### 6.4 Category Lookup Logic

The category function uses path-prefix matching, not a hardcoded list per file. This makes it resilient to new files added in future versions.

```
get_category(filepath):
  if filepath == "VERSION"                     -> harness-owned
  if filepath starts with "scripts/"           -> harness-owned
  if filepath starts with "hooks/"             -> harness-owned
  if filepath starts with ".claude/agents/"    -> harness-owned
  if filepath starts with ".claude/commands/"  -> harness-owned
  if filepath starts with ".claude/hooks/"     -> harness-owned
  if filepath == ".claude/settings.json"       -> harness-owned
  if filepath == "docs/AGENTS.md"              -> harness-owned
  if filepath == "CLAUDE.md"                   -> project-owned
  if filepath == "docs/CONTRIBUTING.md"        -> project-owned
  if filepath == "docs/ARCHITECTURE.md"        -> project-owned
  if filepath == "docs/RELIABILITY.md"         -> project-owned
  if filepath == "docs/QUALITY_SCORE.md"       -> project-owned
  if filepath == "setup.sh"                    -> scaffold
  if filepath matches "*.gitkeep"              -> scaffold
  if filepath == "docs/exec-plans/tech-debt-tracker.md" -> scaffold
  # Fallback for any unknown file:
  else                                         -> scaffold
```

The fallback to `scaffold` is the safest default -- unknown files are never overwritten.

---

## 7. install.sh Changes

### 7.1 Header Comment Update (R6)

Replace the existing 2-line usage comment block with:

```
# handoff-harness installer
#
# Platforms:
#   - macOS and Linux are natively supported.
#   - Windows requires WSL; no PowerShell installer is planned.
#   - Runtime dependencies: bash, git, and sha256sum (Linux) or shasum (Mac).
#
# Usage:
#   Fresh install:
#     curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash
#   Update:
#     curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash -s -- --update
```

### 7.2 Portable Checksum Function

Add early in the script, after `set -euo pipefail`:

```
Pseudocode:

  function compute_sha256(filepath):
    if command -v sha256sum exists:
      run: sha256sum "$filepath" | awk '{print $1}'
    elif command -v shasum exists:
      run: shasum -a 256 "$filepath" | awk '{print $1}'
    else:
      print error "Neither sha256sum nor shasum found" to stderr
      exit 1
```

The `command -v` check is POSIX-compliant and works on both platforms. The function outputs only the 64-char hex digest to stdout.

### 7.3 Category Lookup Function

Add a shell function implementing the logic from Section 6.4. It takes a single argument (relative filepath without leading `./`) and prints the category string to stdout.

### 7.4 Fresh Install Flow (Modified)

The existing fresh-install flow is modified to add manifest generation at the end:

```
Pseudocode (fresh install):

  1. Clone repo to tmpdir (existing logic, unchanged)
  2. Enumerate files in src/ (existing logic, unchanged)
  3. Strip leading "./" from all paths for clean relative paths
  4. Detect conflicts, archive to legacy dir (existing logic, unchanged)
  5. Copy all files from src/ to target (existing logic, unchanged)
  6. Set executable permissions (existing logic, unchanged)
  7. NEW: Read VERSION from target repo
  8. NEW: Generate .harness-manifest.json:
     a. Set harness_version from VERSION
     b. Set installed_at from current UTC time
     c. For each file copied:
        - Compute sha256 of the file at its target location
        - Look up category
        - Add entry to files map
     d. Write JSON to .harness-manifest.json
  9. Cleanup tmpdir (existing logic, unchanged)
  10. Print next-steps (existing logic, modified to mention /seed)
```

### 7.5 Update Flow (New)

```
Pseudocode (--update):

  1. Clone repo to tmpdir
  2. Read remote VERSION from tmpdir/handoff-harness/src/VERSION
  3. Read local VERSION from TARGET/VERSION (may not exist)
  4. If both versions exist and are identical:
     - Print "Already at version X.Y.Z -- nothing to update."
     - Cleanup tmpdir and exit 0
  5. Read existing .harness-manifest.json if it exists
     - Parse it to extract per-file checksums (using grep/sed, no jq)
     - If manifest missing: set MANIFEST_MISSING=true
  6. Enumerate files in remote src/
  7. Initialize counters: updated=0, merged=0, skipped=0
  8. Initialize merge_list as empty
  9. For each remote file:
     a. Determine category via get_category()
     b. If category == "scaffold":
        - Skip. Increment skipped counter.
     c. If category == "harness-owned":
        - Copy remote file to target, overwriting. Increment updated counter.
     d. If category == "project-owned":
        - If MANIFEST_MISSING is true:
            Treat as customized (go to sidecar path below).
        - Else if local file does not exist:
            Copy remote file to target. Increment updated counter.
        - Else:
            Compute sha256 of current local file.
            Look up original checksum from manifest.
            If checksums match (file unchanged):
              Overwrite with remote version. Increment updated counter.
            Else (file customized):
              Write remote version as <filepath>.harness-update
              Add filepath to merge_list. Increment merged counter.
  10. Set executable permissions (same as fresh install)
  11. Generate new .harness-manifest.json with new checksums
      - For harness-owned and updated project-owned files: checksum of new file
      - For project-owned files with sidecars: checksum of the ORIGINAL file
        (the one the user kept), NOT the sidecar
      - For scaffold files: checksum of existing file on disk (unchanged)
  12. Cleanup tmpdir
  13. Print changelog summary:
      Updated handoff-harness: <old-version> -> <new-version>
        Files updated:        N
        Files needing merge:  M   (see *.harness-update files)
        Files skipped:        K   (scaffold, no changes)
  14. If M > 0, list each .harness-update file path
```

### 7.6 Manifest Parsing Without jq

Since we cannot assume `jq` is installed, the update flow reads the existing manifest using `grep` and `sed`:

```
Pseudocode:

  function get_manifest_checksum(filepath):
    # Extract the checksum for a given filepath from .harness-manifest.json
    # The JSON is machine-generated with predictable formatting, so line-based
    # parsing is safe.
    #
    # Strategy: find the line containing the filepath key, then read the
    # checksum line that follows within the next few lines.

    grep -A 3 "\"$filepath\"" .harness-manifest.json \
      | grep '"checksum"' \
      | sed 's/.*"checksum"[[:space:]]*:[[:space:]]*"//; s/".*//'
```

This works because install.sh controls the JSON format -- it is always written with consistent indentation and field ordering. The parser does not need to handle arbitrary JSON.

### 7.7 Manifest Checksum After Sidecar Update

A critical detail: when a project-owned file is NOT overwritten (sidecar path), the manifest entry for that file must record the checksum of the **existing local file** (the one the user kept). This ensures that on the next `--update`, the comparison baseline is the user's current file, not the sidecar.

The `.harness-update` sidecar files are NOT recorded in the manifest.

---

## 8. setup.sh Changes (R4)

### 8.1 Exact Additions

Append the following block after the existing final `echo` statements (after the "Remaining setup:" block). This replaces the existing final three `echo` lines with an updated version plus the nudge:

Current ending (lines 59-65 of setup.sh):

```
echo ""
echo "Remaining setup:"
echo "  1. Fill in {{placeholders}} in CLAUDE.md, docs/CONTRIBUTING.md,"
echo "     docs/ARCHITECTURE.md, docs/RELIABILITY.md, and hooks/*"
echo "  2. Adapt hooks/pre-commit and hooks/pre-push to your tech stack"
echo "  3. For brownfield repos: run the onboarding agent to generate"
echo "     ARCHITECTURE.md from your existing codebase"
```

New ending:

```
echo ""
echo "Remaining setup:"
echo "  1. Adapt hooks/pre-commit and hooks/pre-push to your tech stack"
echo "  2. For brownfield repos: run the onboarding agent to generate"
echo "     ARCHITECTURE.md from your existing codebase"
echo ""
echo "==============================================="
echo "NEXT: Start a Claude Code session and run /seed"
echo "This will auto-detect your project and fill in"
echo "all {{placeholder}} values in your config files."
echo "==============================================="
```

The old step 1 about filling placeholders manually is removed because the nudge replaces it with the `/seed` command. Steps are renumbered.

### 8.2 Scope

Apply identically to both `src/setup.sh` and `setup.sh` (top-level). The two files must remain byte-identical after the change.

---

## 9. session-start.sh Changes (R5)

### 9.1 Insertion Point

The placeholder detection must be inserted BEFORE the closing `echo "======================"` line (currently line 59), and AFTER the existing inbox output block.

### 9.2 Exact Logic

```
# Unfilled placeholder detection
CLAUDE_MD="$ROOT/CLAUDE.md"
if [ -f "$CLAUDE_MD" ] && grep -q '{{' "$CLAUDE_MD" 2>/dev/null; then
  echo "Unfilled placeholders detected in CLAUDE.md."
  echo "Run /seed to auto-configure your project."
fi
```

### 9.3 Placement Within Output

The output order becomes:

```
=== Session Context ===
Branch: ...
Active plans: ...
Tech debt items: ...
Active feature: ... (if any)
Pending inbox: ... (if any)
Unfilled placeholders detected in CLAUDE.md.   <-- NEW (conditional)
Run /seed to auto-configure your project.       <-- NEW (conditional)
======================
```

### 9.4 Performance

`grep -q '{{' CLAUDE.md` exits on first match. CLAUDE.md is a small file (typically <100 lines). This adds sub-millisecond overhead.

### 9.5 Scope

Apply identically to both `src/.claude/hooks/session-start.sh` and `.claude/hooks/session-start.sh` (top-level). The two files must remain byte-identical after the change.

---

## 10. Data Flow

### 10.1 Fresh Install

```
Remote repo (GitHub)
  |
  v
install.sh clones to tmpdir
  |
  v
Enumerate src/ files
  |
  v
Copy all files to target --> Compute sha256 per file
  |                              |
  v                              v
Set permissions            Build .harness-manifest.json
  |                              |
  v                              v
Print next steps           Write manifest to target root
```

### 10.2 Update

```
Remote repo (GitHub)
  |
  v
install.sh clones to tmpdir
  |
  v
Compare VERSION (local vs remote)
  |
  +--> Same version --> exit early
  |
  +--> Different version:
       |
       v
  Read existing .harness-manifest.json (if present)
       |
       v
  For each remote src/ file:
       |
       +-- harness-owned --> overwrite
       +-- scaffold --> skip
       +-- project-owned:
            |
            +-- no manifest --> write .harness-update sidecar
            +-- manifest exists:
                 |
                 +-- checksum matches --> overwrite
                 +-- checksum differs --> write .harness-update sidecar
       |
       v
  Rebuild .harness-manifest.json with new state
       |
       v
  Print changelog summary
```

---

## 11. Cross-Platform Considerations

### 11.1 sha256sum vs shasum

- **Linux:** `sha256sum` is part of GNU coreutils (present on all major distros).
- **macOS:** `shasum` ships with Perl (present on all macOS versions). `sha256sum` is NOT available by default.
- **Detection:** `command -v sha256sum` is tried first. If not found, fall back to `command -v shasum`. If neither found, exit with error.
- **Output format:** Both produce `<hash>  <filename>`. The function uses `awk '{print $1}'` to extract just the hash.

### 11.2 date Command

- `date -u +"%Y-%m-%dT%H:%M:%SZ"` works identically on Linux and macOS for generating the ISO-8601 timestamp.

### 11.3 find Command

- The existing `find` usage in install.sh is POSIX-compliant and works on both platforms.

### 11.4 mktemp

- `mktemp -d` works on both Linux and macOS. No changes needed.

### 11.5 No Other Platform Differences

The rest of the script uses only POSIX shell builtins (`grep`, `sed`, `awk`, `cat`, `cp`, `mkdir`, `chmod`) which are identical across platforms.

---

## 12. Edge Cases

### 12.1 First Install (No Manifest)

Normal path. The manifest is generated fresh. No comparison logic runs. All files are copied unconditionally.

### 12.2 First Update After Feature Ships (No Manifest, Pre-Manifest Installation)

Handled by R3.3. When `--update` runs and no `.harness-manifest.json` exists:

- `harness-owned` files: overwritten (safe -- these are framework files).
- `project-owned` files: ALL treated as customized. Sidecars are written for every project-owned file. The user merges manually. This is the safest default.
- `scaffold` files: skipped as always.
- A new manifest is generated covering all files.

### 12.3 Corrupted Manifest

If `.harness-manifest.json` exists but is not valid JSON (or is empty, or a specific file entry is missing):

- The `get_manifest_checksum` function returns an empty string when it cannot find a match.
- An empty string will never match an actual sha256 digest.
- Therefore, corrupted or incomplete manifest entries cause the same behavior as "no manifest" for that file: project-owned files get the sidecar treatment.
- This is fail-safe by design.

### 12.4 Missing VERSION Locally

When running `--update` and no local `VERSION` file exists (pre-manifest installation):

- The local version variable is set to empty string or a sentinel like `"unknown"`.
- Since empty/unknown will never equal the remote version, the update proceeds.
- The changelog summary shows `Updated handoff-harness: (unknown) -> 0.1.0` or similar.

### 12.5 Missing VERSION Remotely

This should never happen (it would mean the remote repo is broken). If it does:

- The remote version variable is set to empty string.
- The script should print an error and exit: "ERROR: Remote VERSION file not found. The remote repository may be corrupted."

### 12.6 Target File Deleted by User

If a file listed in the manifest no longer exists on disk:

- `harness-owned`: the file is re-created (copied from remote). This is correct -- harness-owned files should exist.
- `project-owned`: the local checksum computation fails (file missing). Treat as "customized" (the user intentionally deleted it). Write the `.harness-update` sidecar so the user can decide whether to restore it.
- `scaffold`: skipped regardless.

### 12.7 Concurrent Updates

Not a concern. `install.sh` is a single-user CLI tool. No locking needed.

### 12.8 CLAUDE.md Missing During Session Start

R5.3 covers this. The `[ -f "$CLAUDE_MD" ]` check means the grep is never executed if the file is absent. No error, no output.

---

## 13. Migration Path

### 13.1 Existing Installations (Pre-Manifest)

Users who installed handoff-harness before this feature have:
- All `src/` files hydrated into their repo.
- No `VERSION` file.
- No `.harness-manifest.json`.

**Migration sequence:**

1. User runs `curl -fsSL <url> | bash -s -- --update`.
2. install.sh clones the new version (which includes `src/VERSION`).
3. No local `VERSION` found -- version treated as unknown, update proceeds.
4. No local `.harness-manifest.json` found -- `MANIFEST_MISSING=true`.
5. All `harness-owned` files are overwritten (framework files get latest version).
6. All `project-owned` files get `.harness-update` sidecars (safe default).
7. All `scaffold` files are skipped.
8. New `.harness-manifest.json` is written with current checksums.
9. `VERSION` file is written (via the harness-owned copy).
10. Changelog summary is printed, showing sidecar files to review.

After this, the installation is fully migrated to the manifest system. Subsequent updates use the normal comparison flow.

### 13.2 Self-Hosting Copy

The handoff-harness repo itself uses the top-level files as a self-hosting copy. During implementation:

- `VERSION` is created at repo root (in addition to `src/VERSION`).
- `setup.sh` and `session-start.sh` changes are applied to both `src/` and top-level copies.
- No `.harness-manifest.json` is committed to the repo (it is a runtime artifact).

---

## 14. Testing Strategy

### 14.1 Manual Integration Tests

Since this is a shell-only project with no test framework, verification is manual. Each acceptance criterion (AC1-AC17) maps to a specific manual test.

**Test environment setup:**
- Create a temp directory, `git init` inside it.
- Run install.sh against it for fresh install tests.
- Modify files, then run `--update` for update tests.
- Repeat on both a Linux machine and macOS (or Docker containers).

**Key test scenarios:**

| Scenario | Steps | Expected |
|----------|-------|----------|
| Fresh install generates manifest | Run install.sh, inspect `.harness-manifest.json` | Valid JSON, all files listed, checksums match |
| Version match skips update | Install, then immediately `--update` | "Already at version" message, no files changed |
| Harness-owned overwrite | Modify a script, run `--update` with new version | Script reverted to upstream |
| Project-owned unchanged overwrite | Run `--update` without touching CLAUDE.md | CLAUDE.md updated, no sidecar |
| Project-owned customized sidecar | Edit CLAUDE.md, run `--update` | CLAUDE.md untouched, CLAUDE.md.harness-update created |
| Scaffold skip | Modify setup.sh, run `--update` | setup.sh untouched |
| No manifest migration | Delete .harness-manifest.json, run `--update` | All project-owned get sidecars |
| setup.sh nudge | Run `bash setup.sh` | `/seed` banner is last output |
| session-start placeholder detect | Create CLAUDE.md with `{{FOO}}`, run hook | Nudge printed |
| session-start no placeholders | Create CLAUDE.md without `{{`, run hook | No nudge |
| session-start no CLAUDE.md | Delete CLAUDE.md, run hook | Clean exit, no error |
| Cross-platform checksum | Run on Linux and macOS | Both produce identical checksums |

### 14.2 Diff Parity Check

After implementation, verify:

```
diff src/setup.sh setup.sh
diff src/.claude/hooks/session-start.sh .claude/hooks/session-start.sh
```

Both must return no output (AC17).

---

## 15. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| JSON generation bugs (unescaped chars in filenames) | Low | Medium | All filenames are controlled by us (no user input). Use `printf` with explicit quoting. |
| Manifest grep-parsing breaks on format change | Medium | Medium | Document that install.sh is the only writer/reader. Use consistent indentation. Add a comment warning not to hand-edit. |
| sha256sum missing on minimal Linux (Alpine, BusyBox) | Low | Low | BusyBox includes `sha256sum`. Alpine includes it in coreutils. Detection shim handles fallback. |
| Large file count slows manifest generation | Very Low | Low | Current file count is 41. Even 200 files with sha256 would complete in <2 seconds. |
| Top-level and src/ copies drift after implementation | Medium | Medium | AC17 enforces diff check. Could be automated as a pre-commit hook in future. |

---

## 16. Scope Boundaries (What We Are NOT Building)

- No automatic three-way merge of project-owned files. Users merge sidecars manually.
- No `jq` dependency. JSON is built and parsed with shell string operations.
- No PowerShell or Windows-native installer.
- No changelog generation from git history. Only version-string comparison.
- No new agent definitions, command definitions, or documentation files beyond what is listed.
- No `.harness-manifest.json` committed to the source repo.
- No changes to any agent `.md` files or command `.md` files (their content is unchanged; they are just categorized in the manifest).
- No interactive prompts during install or update (remains fully non-interactive for curl-pipe usage).

---

## 17. Implementation Task Breakdown

Recommended implementation order (matching requirement dependencies):

| Task | Files | Description |
|------|-------|-------------|
| T1 | `src/VERSION`, `VERSION` | Create VERSION file with `0.1.0` |
| T2 | `install.sh` | Add portable checksum function, category lookup function, manifest generation on fresh install |
| T3 | `install.sh` | Add version-aware `--update` flow with category-based handling and changelog summary |
| T4 | `install.sh` | Update header comment with platform documentation |
| T5 | `src/setup.sh`, `setup.sh` | Add `/seed` nudge banner |
| T6 | `src/.claude/hooks/session-start.sh`, `.claude/hooks/session-start.sh` | Add placeholder detection and nudge |

T1 must precede T2. T2 must precede T3. T4, T5, and T6 are independent of each other and of T1-T3.
