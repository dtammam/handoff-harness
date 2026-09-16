# Tech Debt Tracker

## Active

| # | Description | Severity | Added | Source |
|---|-------------|----------|-------|--------|
| NB-3 | Potential abort on deleted scaffold file: if a scaffold file listed in the manifest is deleted by the user, the update flow may attempt to checksum a missing file. Add a file-existence guard before checksum computation. | Low | 2026-03-31 | QA review of versioning-and-seed-nudge |
| NB-4 | Inbox queuing: each agent has a single inbox file, so prepping the next task overwrites the current one. Support a queue (e.g., per-task inbox files like `software-developer-t2.md`) so multiple tasks can be prepped ahead of time without blocking on the current execution. | Low | 2026-04-01 | User feedback during readme-improvements |
| NB-5 | Garbled `## Rules` bullets in `.claude/agents/quality-assurance.md` (and its `src/` mirror): the first two Rules read as leaked meta-commentary (e.g. `"...(was implied in the core principle but not enforced as a rule)"`) instead of clean imperative rules. These are the pre-existing source that the security-engineer.md garble was copied from (SEC-AGENT-1, fixed on the security-agent branch). Clean both up in a future non-feature branch — deferred out of the security-agent branch to preserve AC-13 (which limits `.claude/agents/` changes to security-engineer.md + engineering-manager.md). | Low | 2026-07-06 | Security-engineer + QA reviews of security-agent |
| NB-6 | `install.sh` Step 12.1 CLAUDE.md merge-note `case` block could be nested inside the existing `if [ "$merged" -gt 0 ]` guard for clarity. Functionally harmless as-is (the case only matches when `CLAUDE.md` is in `merge_list`, which implies `merged > 0`). Optional readability cleanup. | Low | 2026-07-06 | QA SUGGESTION (a) during security-agent review |

## Closed

| # | Description | Severity | Added | Closed | Resolution |
|---|-------------|----------|-------|--------|------------|
| NB-1 | TMPDIR shadowing: install.sh uses TMPDIR as a local variable which shadows the system environment variable. Rename to HARNESS_TMPDIR or similar. | Low | 2026-03-31 | 2026-04-03 | Renamed to HARNESS_TMPDIR in install.sh as part of remove-version-relocate-manifest |
