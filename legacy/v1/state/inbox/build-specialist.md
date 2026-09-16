# Build Specialist Inbox: remove-version-relocate-manifest (FINAL Verification Pass)

## Feature

remove-version-relocate-manifest

## Stage

Verification -- FINAL comprehensive pass (all tasks T1-T4 complete)

## Context

All four implementation tasks have been built by the software developer:

- **T1** (TMPDIR rename): verified in earlier pass
- **T2** (VERSION removal + version derivation): verified in earlier pass
- **T3** (manifest relocation, migration, sidecar cleanup): verified in earlier pass
- **T4** (reference sweep + tech debt cleanup): just completed by SDE, not yet verified

This is the FINAL comprehensive verification covering the entire feature before acceptance. Run every acceptance criterion from the exec plan (AC-1 through AC-8). If everything passes, the feature moves to acceptance with the product-manager.

The project's build, test, lint, and format commands in `docs/CONTRIBUTING.md` are currently unhydrated placeholders, so standard build/lint/test tool invocation is not applicable. Your verification must be structural, grep-based, and code-reading-based.

All paths are absolute from the repository root: `/home/coder/projects/handoff-harness`

---

## Primary artifacts

- `/home/coder/projects/handoff-harness/install.sh` -- the main installer script (all four changes land here)
- `/home/coder/projects/handoff-harness/docs/exec-plans/tech-debt-tracker.md` -- NB-1 closure
- `/home/coder/projects/handoff-harness/.claude/commands/seed.md` -- live seed command
- `/home/coder/projects/handoff-harness/src/.claude/commands/seed.md` -- template seed command

## Exec plan

- `/home/coder/projects/handoff-harness/docs/exec-plans/active/remove-version-relocate-manifest.md`

---

## Full Acceptance Criteria Checklist

Run EVERY check below. Report PASS or FAIL for each item with evidence (command output or code reference). Do NOT skip any check.

---

### AC-1: VERSION file removal

**AC-1.1:** `ls /home/coder/projects/handoff-harness/VERSION` must return "No such file or directory."

**AC-1.2:** `ls /home/coder/projects/handoff-harness/src/VERSION` must return "No such file or directory."

**AC-1.3:** `grep -n "VERSION)" /home/coder/projects/handoff-harness/install.sh` must return zero matches (the case arm is gone from `get_category()`).

**AC-1.4:** `grep -n "VERSION" /home/coder/projects/handoff-harness/install.sh` -- inspect all matches. Only variable names like `HARNESS_VERSION`, `REMOTE_VERSION`, `LOCAL_VERSION` used in the new manifest-based version derivation are acceptable. Any match referencing `VERSION` as a file path (e.g., `cat VERSION`, `$TARGET/VERSION`, `src/VERSION`) is a FAIL.

**AC-1.5:** Read the install.sh fresh-install flow code that constructs the manifest JSON. Confirm `harness_version` is set to a derived value from `get_manifest_version()` or `git describe --tags --abbrev=0` -- not an empty string or placeholder.

---

### AC-2: Manifest relocated to `.harness/manifest.json`

**AC-2.1:** Read install.sh to verify the fresh-install flow writes the manifest to `$TARGET/.harness/manifest.json` (not `$TARGET/.harness-manifest.json`).

**AC-2.2:** Read install.sh to verify the update flow reads the existing manifest from `$TARGET/.harness/manifest.json`.

**AC-2.3:** `grep "harness-manifest" /home/coder/projects/handoff-harness/install.sh` -- inspect all matches. Matches are ACCEPTABLE only inside the migration block (Step 1.5) where the old path is referenced by design for detecting and archiving. Matches anywhere else are FAILURES.

**AC-2.4:** `grep -n '\.harness/manifest' /home/coder/projects/handoff-harness/install.sh` must return matches at all locations where the manifest is written or read (fresh install write, update read, update write).

**AC-2.5:** Verify `get_category()` in install.sh contains a case arm matching `.harness/*` that returns `harness-owned`.

**AC-2.6:** Verify the migration block exists: if `$TARGET/.harness-manifest.json` exists during an update, the installer archives it as a `.bak` file with a date stamp before proceeding. Check for the `mv` command and the printed migration message.

---

### AC-3: Exhaustive reference sweep

**AC-3.1:** Run from repo root:
```bash
grep -rn "\bVERSION\b" --include="*.sh" --include="*.md" \
  --exclude-dir=".git" \
  --exclude-dir="docs/exec-plans/completed" \
  /home/coder/projects/handoff-harness/
```
Inspect EVERY match. Matches in `docs/exec-plans/active/remove-version-relocate-manifest.md` are acceptable (that is the exec plan documenting this feature). Matches that are prose uses of the word "version" are acceptable. Any match referencing `VERSION` as a file path outside the exec plan is a FAIL. Report each match with your assessment.

**AC-3.2:** Run from repo root:
```bash
grep -rn "\.harness-manifest\.json" \
  --exclude-dir=".git" \
  --exclude-dir="docs/exec-plans/completed" \
  /home/coder/projects/handoff-harness/
```
Matches inside `install.sh` migration block and inside the active exec plan are acceptable. Matches anywhere else are FAILURES.

**AC-3.3:** Verify `.claude/commands/seed.md` contains `.harness/manifest.json` and does NOT contain `.harness-manifest.json`:
```bash
grep "harness-manifest" /home/coder/projects/handoff-harness/.claude/commands/seed.md
grep "\.harness/manifest" /home/coder/projects/handoff-harness/.claude/commands/seed.md
```

**AC-3.4:** Verify `src/.claude/commands/seed.md` contains `.harness/manifest.json` and does NOT contain `.harness-manifest.json`:
```bash
grep "harness-manifest" /home/coder/projects/handoff-harness/src/.claude/commands/seed.md
grep "\.harness/manifest" /home/coder/projects/handoff-harness/src/.claude/commands/seed.md
```

---

### AC-4: NB-1 TMPDIR fix

**AC-4.1:** `grep -n "TMPDIR" /home/coder/projects/handoff-harness/install.sh | grep -v "HARNESS_TMPDIR"` must return zero matches.

**AC-4.2:** `grep -n "HARNESS_TMPDIR" /home/coder/projects/handoff-harness/install.sh` must return matches for all occurrences (assignment via mktemp, git clone, find, rm -rf, and all path constructions).

**AC-4.3:** Read through the HARNESS_TMPDIR usage in install.sh to confirm it is a purely mechanical rename -- same logic, same paths, just the variable name changed from TMPDIR to HARNESS_TMPDIR.

**AC-4.4:** Verify NB-1 row is present in the Closed table in `/home/coder/projects/handoff-harness/docs/exec-plans/tech-debt-tracker.md` with resolution text mentioning "Renamed to HARNESS_TMPDIR."

---

### AC-5: src/ template parity

**AC-5.1:** `grep "harness-manifest" /home/coder/projects/handoff-harness/src/.claude/commands/seed.md` must return zero matches.

**AC-5.2:** `grep "\.harness/manifest" /home/coder/projects/handoff-harness/src/.claude/commands/seed.md` must return at least one match.

**AC-5.3:** For every file changed under `src/` as part of this feature, verify the corresponding top-level file received the same change (and vice versa). Key pair to check: `.claude/commands/seed.md` vs `src/.claude/commands/seed.md`. Diff or compare the manifest-related lines in both files.

---

### AC-6: Housekeeping

**AC-6.1:** `ls /home/coder/projects/handoff-harness/docs/exec-plans/active/readme-improvements.md` must return "No such file or directory."

**AC-6.2:** `ls /home/coder/projects/handoff-harness/docs/exec-plans/completed/readme-improvements.md` must confirm the file exists.

---

### AC-7: No regressions in installer behavior

**AC-7.1:** Read through install.sh to verify the greenfield fresh-install flow is intact: clones repo to HARNESS_TMPDIR, copies files, writes `.harness/manifest.json`, sets permissions.

**AC-7.2:** Read through install.sh to verify the brownfield fresh-install flow handles existing files (archives conflicts) and writes `.harness/manifest.json`.

**AC-7.3:** Read through install.sh to verify the update flow reads `.harness/manifest.json`, processes files per get_category(), and writes the updated manifest without corruption.

**AC-7.4:** `grep -n 'chmod' /home/coder/projects/handoff-harness/install.sh` -- verify chmod calls are present for `scripts/`, `hooks/`, `.claude/hooks/`, and/or `setup.sh`.

---

### AC-8: Stale `.harness-update` cleanup

**AC-8.1:** Verify `cleanup_stale_sidecars()` function exists in install.sh and removes files matching `*.harness-update` under `$TARGET` using `find`.

**AC-8.2:** Verify the function is silent when no stale files exist (conditional output: only prints when count > 0).

**AC-8.3:** Verify the function is called in BOTH the update flow AND the fresh brownfield install flow, BEFORE the per-file processing loop in each.

**AC-8.4:** Verify the find pattern targets ONLY `*.harness-update` (e.g., `-name "*.harness-update"`) and would NOT match files like `something.harness-update.bak`.

**AC-8.5:** Verify a human-readable message is printed with the count when stale files are found (e.g., "Cleaned up N stale .harness-update file(s) from previous run.").

---

### Syntax validation (bonus, always run)

```bash
bash -n /home/coder/projects/handoff-harness/install.sh
```

PASS if exit code is 0. FAIL if bash reports any parse errors.

---

## Output format

For each AC item, report:
```
AC-X.Y: PASS | FAIL
  Evidence: <command output or code line reference>
  (If FAIL: exact error or unexpected output)
```

At the end, provide a SUMMARY:
- Total passed / total checks
- Whether the feature is ready for acceptance

## State file update

If ALL checks pass, update `/home/coder/projects/handoff-harness/.state/feature-state.json`:
- Set T4 status to `"verified"`
- Update `updated_at` to the current ISO 8601 timestamp

If any check fails, do NOT update task status. Report failures clearly so the EM can route back to the software-developer.

---

## Reference files

- **State file:** `/home/coder/projects/handoff-harness/.state/feature-state.json`
- **Exec plan:** `/home/coder/projects/handoff-harness/docs/exec-plans/active/remove-version-relocate-manifest.md`
- **Primary artifact:** `/home/coder/projects/handoff-harness/install.sh`
- **Tech debt tracker:** `/home/coder/projects/handoff-harness/docs/exec-plans/tech-debt-tracker.md`
- **Live seed command:** `/home/coder/projects/handoff-harness/.claude/commands/seed.md`
- **Template seed command:** `/home/coder/projects/handoff-harness/src/.claude/commands/seed.md`
- **Contributing guide:** `/home/coder/projects/handoff-harness/docs/CONTRIBUTING.md`
