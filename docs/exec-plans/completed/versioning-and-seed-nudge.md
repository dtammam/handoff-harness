# Requirements: versioning-and-seed-nudge

**Stage:** Done
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

## Completion

Feature completed 2026-03-31. QA approved with non-blocking issues NB-1 and NB-3 tracked in tech-debt-tracker.md.
