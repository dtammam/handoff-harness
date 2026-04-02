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
