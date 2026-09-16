# Quality Assurance Review Report

**Feature:** `remove-version-relocate-manifest`
**Branch:** `feature/remove-version-relocate-manifest`
**Reviewer:** quality-assurance agent
**Date:** 2026-04-03
**Verdict:** APPROVE WITH NOTES

---

## Files Reviewed

1. `install.sh` (primary artifact -- all 4 tasks converge here)
2. `docs/exec-plans/tech-debt-tracker.md` (T4 artifact)
3. `.claude/commands/seed.md` (live seed.md -- parity check)
4. `src/.claude/commands/seed.md` (template seed.md -- parity check)
5. `docs/exec-plans/active/remove-version-relocate-manifest.md` (exec plan)
6. Confirmed absent: `VERSION`, `src/VERSION`, `docs/exec-plans/active/readme-improvements.md`

---

## Acceptance Criteria Check Results

| AC | Description | Result | Notes |
|----|-------------|--------|-------|
| AC-1.1 | `VERSION` absent from repo root | PASS | File does not exist |
| AC-1.2 | `src/VERSION` absent | PASS | File does not exist |
| AC-1.3 | `grep -n "VERSION)" install.sh` returns zero matches | PASS | Zero matches confirmed |
| AC-1.4 | No file-path references to `VERSION` in `install.sh` | PASS | All remaining references are variable names (`REMOTE_VERSION`, `LOCAL_VERSION`, `HARNESS_VERSION`) |
| AC-2.3 | `grep "harness-manifest" install.sh` returns zero matches | QUALIFIED FAIL | Lines 115 and 119 reference `.harness-manifest.json` in the migration block (required by R-2.6). Implementation is correct; AC text is inconsistent with design. See NB-QA-1. |
| AC-2.4 | `.harness/manifest` referenced at all read/write sites | PASS | Lines 127, 244 (update flow), 371 (fresh install flow) |
| AC-2.5 | `.harness/*` case arm exists in `get_category()` | PASS | Line 32 |
| AC-3.2 | No `.harness-manifest.json` outside completed/ | PASS | Only present in exec plan spec and completed docs (both exempt) |
| AC-3.3 | Live `seed.md` uses `.harness/manifest.json` | PASS | Lines 193 and 205 |
| AC-3.4 | `src/seed.md` does not contain `.harness-manifest.json` | PASS | Zero matches |
| AC-4.1 | `grep -n "TMPDIR" install.sh` returns zero matches | PASS | Only `HARNESS_TMPDIR` matches |
| AC-4.2 | `HARNESS_TMPDIR` appears at all expected sites | PASS | 11 occurrences |
| AC-4.4 | NB-1 in Closed table of tech-debt-tracker.md | PASS | Present with correct resolution |
| AC-5.1 | `grep "harness-manifest" src/seed.md` returns zero | PASS | Zero matches |
| AC-5.2 | `src/seed.md` contains `.harness/manifest` | N/A | Design section explicitly declares no change needed (pre-existing divergence, out of scope). See NB-QA-2. |
| AC-6.1 | `docs/exec-plans/active/readme-improvements.md` absent | PASS | Confirmed |
| AC-6.2 | `docs/exec-plans/completed/readme-improvements.md` present | PASS | Confirmed |
| AC-8 | `cleanup_stale_sidecars()` exists with correct logic | PASS | Lines 66-78 |

---

## Issues

### NON-BLOCKING Issues

**NB-QA-1: AC-2.3 inconsistent with design -- exec plan should be corrected before close**

AC-2.3 states `grep "harness-manifest" install.sh` returns zero matches. However, the migration block (Step 1.5, required by R-2.6) necessarily references `.harness-manifest.json` at lines 115 and 119. The implementation is correct. The AC should be amended to note the migration block exception before archiving.

**NB-QA-2: AC-5.2 contradicts the exec plan's own design decision**

AC-5.2 says `src/seed.md` should contain `.harness/manifest`. The design section (lines 493-497) explicitly declares no change is needed because the divergence is pre-existing and out of scope. Implementation followed the design section correctly. The AC should be noted before archiving.

**NB-QA-3: `dev == dev` version comparison could cause spurious early-exit on untagged branches**

File: `install.sh`, line 135. When both sides resolve to `"dev"` (untagged branches), the script prints "Already at version dev" and exits without applying updates. Fix: add `[ "$REMOTE_VERSION" != "dev" ]` to the guard. Low risk for production (tagged releases), affects developer testing only.

**NB-QA-4: Migration flow does not preserve `LOCAL_VERSION` from the old manifest**

After archiving the old manifest (mv), `LOCAL_VERSION` reads from the new path and gets `"(unknown)"` instead of the prior version. Outcome is safe (`"(unknown)"` skips early-exit, runs full update). Only cosmetic impact on the update summary line.

**NB-QA-5: `get_manifest_version()` with malformed manifest could abort under `set -eo pipefail`**

If the manifest exists but lacks `harness_version`, `grep` exits 1 and `set -e` aborts. Low risk (manifest is always installer-generated). Adding `|| true` to the grep pipeline would make it defensive.

---

## Suggestions (Optional)

**S-1:** Consider tracking NB-QA-3 (`dev == dev` issue) as a new tech debt entry.

**S-2:** The `mkdir -p "$TARGET/.harness"` in the migration block (line 120) is redundant with Step 9 (line 243). Harmless but unnecessary.

---

## Verdict: APPROVE WITH NOTES

The implementation is correct and complete. All four tasks (T1-T4) are implemented as specified. All requirements (R-1 through R-7) are satisfied. The two apparent AC failures (AC-2.3 and AC-5.2) are caused by inconsistencies in the exec plan text, not by bugs -- the design sections explicitly justify both deviations.

The non-blocking issues are cosmetic, low-probability edge cases, or documentation artifacts. None block merge.

Code is clean, consistent with existing style, follows conventions for variable naming and quoting, introduces no TODO/FIXME without tracking, and has no new security vulnerabilities. The migration path (R-2.6) is non-destructive as required.

**Recommended follow-up before archiving:** Update AC-2.3 and AC-5.2 in the exec plan to reflect the design decisions documented elsewhere in the same plan.
