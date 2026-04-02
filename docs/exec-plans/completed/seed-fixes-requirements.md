# Requirements: Seed Command Fixes & Pipeline Wiring

**Feature:** seed-command-fixes-pipeline-wiring
**Stage:** Done
**Date:** 2026-04-02
**Author:** Product Manager
**Completed:** 2026-04-02

---

This exec plan has been moved to completed. For the full requirements, technical design, and task breakdown, refer to the git history or the content below.

---

## Summary

Hardened the `/seed` command against data-loss bugs, closed agent pipeline wiring gaps, and added operational safeguards (dry-run mode, backup-before-write, brownfield/greenfield detection, harness manifest, post-seed validation) that make seeding safe to run in both greenfield and brownfield repositories. Restored missing sections to CLAUDE.md and added an inline pipeline workflow diagram.

## Tasks Completed

- T1: Agent pipeline wiring -- added RELIABILITY.md to SDE and QA startup sequences, added human-maintained headers to QUALITY_SCORE.md and AGENTS.md
- T2: CLAUDE.md restoration -- verified command table, added 7 missing sections, added ASCII workflow diagram
- T3: Seed command rewrite (safety) -- Edit-only rule, no-touch list, pre-flight scan, per-replacement verification
- T4: Seed command rewrite (operational) -- dry-run mode, backup-before-write, brownfield detection, manifest creation, post-seed validation

## Live Verification Testing

After T1-T4 were implemented, a live end-to-end test was run against the tasksync repo (SvelteKit + Rust monorepo) by installing from the feature branch and running `/seed`. This uncovered 5 bugs, all fixed before merge:

| Bug | Issue | Root Cause | Fix |
|-----|-------|-----------|-----|
| B1 | Seed reported "no placeholders found" for CLAUDE.md despite `{{LANGUAGE}}` etc. being present | Agent's grep produced a false negative; no guardrail to catch it | Added explicit re-read instruction in Phase 1 when CLAUDE.md reports zero matches |
| B2 | CLAUDE.md kept harness boilerplate ("Markdown files, shell scripts...") in brownfield installs | Description was hardcoded text, not a placeholder token | Replaced with `{{PROJECT_DESCRIPTION}}` placeholder in src/CLAUDE.md |
| B3 | SDE and QA agents in installed projects missing RELIABILITY.md startup step | T1 edited repo agents but not `src/` templates used by installer | Synced RELIABILITY.md step to src/.claude/agents/ templates |
| B4 | install.sh hardcodes BRANCH="main", can't test from feature branches | No branch override flag | Added `--branch=<name>` flag |
| B5 | Installer overwrites QUALITY_SCORE.md, AGENTS.md, tech-debt-tracker.md with templates in brownfield installs | Fresh install copied all files regardless of category | Made brownfield install category-aware: project-owned/scaffold files preserved, templates written as .harness-update sidecars |

### Verification Results (final run)

All checks passed on second test run:
- Phased execution order confirmed
- CLAUDE.md: all 6 placeholders found and replaced
- No-touch files preserved with .harness-update sidecars
- Backups created for all modified files
- Zero orphaned `{{` tokens
- Manifest and version file created correctly
- Both agents include RELIABILITY.md at step 5
