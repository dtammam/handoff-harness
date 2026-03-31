# Requirements: versioning-and-seed-nudge

**Stage:** Discovery — approved requirements
**Date:** 2026-03-31
**Branch:** feat/versioning-and-seed-nudge

---

## Goal

Give users safe, version-aware harness upgrades and clear post-install guidance so they never lose customized files and always know to run `/seed`.

---

## Scope

### In scope

- `src/VERSION` file (semver, initial value `0.1.0`) hydrated into target repos
- `.harness-manifest.json` written by `install.sh` during every hydration (fresh and update)
- `install.sh --update` version comparison and category-based file handling
- Changelog summary printed at the end of every `--update` run
- `setup.sh` (both `src/setup.sh` and top-level `setup.sh`) post-success `/seed` nudge block
- `session-start.sh` (both `src/.claude/hooks/session-start.sh` and top-level `.claude/hooks/session-start.sh`) unfilled-placeholder detection and nudge
- `install.sh` header comment documenting platform support (Mac, Linux, WSL)
- Cross-platform `sha256sum` / `shasum -a 256` compatibility shim used wherever checksums are computed

### Out of scope

- PowerShell or Windows-native installer
- GUI or web-based installer
- Automatic three-way merge of `project-owned` files (merge notice only)
- Changelog generation from git history (version-string summary is sufficient)
- Any changes to agent `.md` files, commands, or docs beyond what is listed above

---

## Requirements

### R1 — VERSION file

**R1.1** A file named `VERSION` shall exist at `src/VERSION` containing exactly the semver string `0.1.0` with no trailing whitespace or extra newlines beyond one terminating newline.

**R1.2** `install.sh` shall copy `src/VERSION` to the target repo root during every hydration (fresh install and `--update`).

**R1.3** The `VERSION` file shall be classified as `harness-owned` in `.harness-manifest.json` (always overwritten on update).

---

### R2 — .harness-manifest.json

**R2.1** After every successful hydration, `install.sh` shall write (or overwrite) `.harness-manifest.json` in the target repo root.

**R2.2** The manifest shall be valid JSON with the following top-level structure:

```json
{
  "harness_version": "<semver from VERSION>",
  "installed_at": "<ISO-8601 timestamp>",
  "files": {
    "<relative-path>": {
      "category": "<harness-owned|project-owned|scaffold>",
      "checksum": "<sha256 hex digest of the file as written>"
    }
  }
}
```

**R2.3** Every file copied from `src/` (including `VERSION`) shall have an entry in the `files` map. No file outside `src/` shall be added to the map.

**R2.4** File category assignments shall be:

| Category | Files |
|---|---|
| `harness-owned` | All files under `scripts/`, `hooks/`, `.claude/agents/`, `.claude/commands/`, `.claude/hooks/`, `.claude/settings.json`, `docs/AGENTS.md`, `VERSION` |
| `project-owned` | `CLAUDE.md`, `docs/CONTRIBUTING.md`, `docs/ARCHITECTURE.md`, `docs/RELIABILITY.md`, `docs/QUALITY_SCORE.md` |
| `scaffold` | `setup.sh`, all `.gitkeep` files under `.state/` and `docs/exec-plans/`, `docs/exec-plans/tech-debt-tracker.md` |

Note: `docs/AGENTS.md` is harness-owned (it is operating instructions for the pipeline agents, not a user-customizable project file).

**R2.5** Checksums shall be computed using `sha256sum` on Linux and `shasum -a 256` on Mac (detected at runtime). The hex digest only (no filename) shall be stored.

**R2.6** `.harness-manifest.json` itself shall NOT be listed as an entry in the `files` map.

---

### R3 — install.sh --update behavior

**R3.1** When `--update` is passed, `install.sh` shall read the local `VERSION` file (if present) and the remote `VERSION` from the cloned temp copy. If both versions are identical, the script shall print "Already at version X.Y.Z — nothing to update." and exit 0 without modifying any files.

**R3.2** For each file in the remote `src/`:

- **`harness-owned`:** overwrite unconditionally.
- **`project-owned`:** compute the sha256 checksum of the current local file and compare it to the `checksum` stored in the existing `.harness-manifest.json`.
  - If the checksums match (file is unchanged since install): overwrite silently.
  - If the checksums differ (file has been customized): write the incoming file as `<original-filename>.harness-update` in the same directory; do NOT overwrite the original; add the path to a merge-notice list.
- **`scaffold`:** skip entirely; do not overwrite.

**R3.3** If no `.harness-manifest.json` exists locally when `--update` is run (e.g., first update after this feature ships), `install.sh` shall treat all `project-owned` files as customized (safe default: write `.harness-update` sidecars, never overwrite).

**R3.4** After update, `install.sh` shall rewrite `.harness-manifest.json` with updated checksums and the new `harness_version`.

**R3.5** `install.sh` shall print a changelog summary at the end of every `--update` run in the format:

```
Updated handoff-harness: <old-version> → <new-version>
  Files updated:        N
  Files needing merge:  M   (see *.harness-update files)
  Files skipped:        K   (scaffold, no changes)
```

If `M > 0`, a follow-up line shall list each `.harness-update` file path.

**R3.6** The `--update` path shall not alter files in `.state/` beyond rewriting `.harness-manifest.json` at the repo root.

---

### R4 — setup.sh seed nudge

**R4.1** After the existing success or warning message, `setup.sh` shall print the following block verbatim (using ASCII box characters so it renders correctly in all terminals):

```
===============================================
NEXT: Start a Claude Code session and run /seed
This will auto-detect your project and fill in
all {{placeholder}} values in your config files.
===============================================
```

**R4.2** The nudge block shall appear whether setup completed cleanly or with missing-directory warnings; it shall always be the last output printed.

**R4.3** The change shall be applied identically to both `src/setup.sh` and the top-level `setup.sh`.

---

### R5 — session-start hook placeholder nudge

**R5.1** After the existing `=== Session Context ===` output block, the session-start hook shall scan `$ROOT/CLAUDE.md` for the pattern `{{` using `grep -q`.

**R5.2** If unfilled placeholders are detected, the hook shall append the following lines to its output, before the closing `======================` separator:

```
Unfilled placeholders detected in CLAUDE.md.
Run /seed to auto-configure your project.
```

**R5.3** If `CLAUDE.md` does not exist, the check shall be silently skipped (no error).

**R5.4** The check shall complete within the existing <500 ms performance budget; it is a single `grep -q` pass and shall not trigger any file writes or network calls.

**R5.5** The change shall be applied identically to both `src/.claude/hooks/session-start.sh` and the top-level `.claude/hooks/session-start.sh`.

---

### R6 — Cross-platform documentation in install.sh

**R6.1** The header comment block of `install.sh` (lines beginning with `#`) shall be updated to include a `Platforms:` section stating:

- Mac (macOS) and Linux are natively supported.
- Windows requires WSL; no PowerShell installer is planned.
- Runtime dependencies are: `bash`, `git`, and either `sha256sum` (Linux) or `shasum` (Mac).

**R6.2** No other documentation file (README, separate doc) is required by this feature; the header comment is sufficient.

---

## Acceptance Criteria

| ID | Criterion | Verifiable by |
|----|-----------|---------------|
| AC1 | `src/VERSION` exists and contains only `0.1.0\n` | `cat src/VERSION` |
| AC2 | After a fresh `install.sh` run, `.harness-manifest.json` exists in the target root with valid JSON matching the R2.2 schema | Manual inspection / `jq .` |
| AC3 | Every file copied from `src/` has an entry in the manifest `files` map | `jq '.files | keys | length'` vs file count |
| AC4 | Manifest checksums match the actual files on disk | Shell checksum verification loop |
| AC5 | `--update` with matching versions prints "Already at version" and exits without modifying files | Manual test |
| AC6 | `--update` on a `harness-owned` file always overwrites it | Manual test: modify a harness-owned file, run `--update`, confirm it is reset |
| AC7 | `--update` on an unmodified `project-owned` file overwrites it silently | Manual test: run `--update` with pristine CLAUDE.md, confirm overwrite and no sidecar |
| AC8 | `--update` on a modified `project-owned` file produces a `.harness-update` sidecar and prints a merge notice, without altering the original | Manual test: modify CLAUDE.md, run `--update`, confirm sidecar present and original intact |
| AC9 | `--update` on a `scaffold` file skips it entirely | Manual test: modify setup.sh, run `--update`, confirm original unchanged and no sidecar |
| AC10 | Changelog summary is printed after every `--update` run with correct counts | Manual test |
| AC11 | `setup.sh` outputs the `/seed` nudge block as the last item, both on success and warning paths | Run `bash setup.sh` in a fresh environment; confirm block appears last |
| AC12 | `session-start.sh` outputs the placeholder nudge when CLAUDE.md contains `{{` | Run the hook with a CLAUDE.md containing `{{`; confirm nudge appears |
| AC13 | `session-start.sh` outputs no placeholder nudge when CLAUDE.md contains no `{{` | Run the hook with a fully-filled CLAUDE.md; confirm no nudge |
| AC14 | `session-start.sh` does not error when CLAUDE.md is absent | Remove CLAUDE.md, run hook, confirm clean exit |
| AC15 | install.sh header comment documents Mac/Linux/WSL platform support and runtime dependencies | Read install.sh header |
| AC16 | Checksum logic works on both Mac (`shasum -a 256`) and Linux (`sha256sum`) | Verified by code inspection of the platform-detection shim |
| AC17 | `src/` and top-level copies of `setup.sh` and `session-start.sh` are identical after changes | `diff src/setup.sh setup.sh` and `diff src/.claude/hooks/session-start.sh .claude/hooks/session-start.sh` return no output |

---

## Constraints

- Shell and Markdown only — no package manager, no compiled code, no external binaries beyond `bash`, `git`, `sha256sum`/`shasum`.
- `install.sh` must remain curl-pipeable: `curl -fsSL <url> | bash` and `curl -fsSL <url> | bash -s -- --update` must both work without local file system pre-conditions.
- Mac uses `shasum -a 256`; Linux uses `sha256sum`. The platform detection must be runtime, not build-time.
- The self-hosting copy of the harness (top-level files in this repo) must remain functional after these changes are applied.
- Every change to a distributable file in `src/` must be mirrored to the corresponding top-level file.
- `install.sh` itself is NOT distributed via `src/`; it lives only at the repo root and is fetched directly by the curl pipeline.

---

## Dependencies Between Requirements

```
R1 (VERSION file)
  └─► R2 (manifest — reads VERSION for harness_version field)
        └─► R3 (--update — reads and rewrites manifest)

R4 (setup.sh nudge) — independent
R5 (session-start nudge) — independent
R6 (install.sh docs) — independent, touches same file as R2/R3
```

Implementation order recommendation: R1 → R2 → R3 → R4 → R5 → R6.

---

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| `shasum` not available on some Linux distros | Low | Detection shim falls back gracefully; `sha256sum` is standard on all major Linux distros |
| Manifest missing on first `--update` after feature ships | Certain (first run) | R3.3 defines the safe default: treat all `project-owned` files as customized |
| Category mis-assignment causes scaffold file overwrite | Medium | Explicit category table in R2.4 is the single source of truth; reviewed during acceptance |
| `session-start.sh` performance regression | Low | Single `grep -q` is sub-millisecond |
| Top-level and `src/` copies drift | Medium | AC17 diff check enforces parity |

---

## Open Questions

None. All ambiguities from the inbox were resolved in the requirements above. The following were explicitly decided:

- Initial VERSION is `0.1.0`.
- No PowerShell installer is planned (documented, not deferred).
- Nudge text uses ASCII `=` box characters (not Unicode box-drawing) for maximum terminal compatibility.
- Manifest does not list `.harness-manifest.json` itself (R2.6).
- No `docs/exec-plans/active/.gitkeep` or similar scaffold files are listed under `project-owned`.
