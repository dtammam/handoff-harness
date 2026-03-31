# Execution Plan: prep-commands

## Status: Done

## Summary

Added 8 new EM-session prep commands to the harness and merged improvements from
temp/ versions of existing commands. Renamed showme.md to show-me.md for naming
convention consistency.

---

## Completion

Feature completed 2026-03-31. QA approved with non-blocking issues NB-1 and NB-3 tracked in tech-debt-tracker.md.

### Tasks Completed

- T1: Added 8 new prep commands (16 files, 8 pairs in .claude/commands/ and src/.claude/commands/)
- T2: Merged temp improvements into existing commands, renamed showme to show-me, added descriptive first lines
- T3: Updated CLAUDE.md command tables in both root and src/
- T4: Final verification -- all 19 commands confirmed, byte-identical invariant, no stale references
