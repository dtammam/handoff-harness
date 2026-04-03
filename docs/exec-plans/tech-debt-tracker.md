# Tech Debt Tracker

## Active

| # | Description | Severity | Added | Source |
|---|-------------|----------|-------|--------|
| NB-3 | Potential abort on deleted scaffold file: if a scaffold file listed in the manifest is deleted by the user, the update flow may attempt to checksum a missing file. Add a file-existence guard before checksum computation. | Low | 2026-03-31 | QA review of versioning-and-seed-nudge |
| NB-4 | Inbox queuing: each agent has a single inbox file, so prepping the next task overwrites the current one. Support a queue (e.g., per-task inbox files like `software-developer-t2.md`) so multiple tasks can be prepped ahead of time without blocking on the current execution. | Low | 2026-04-01 | User feedback during readme-improvements |

## Closed

| # | Description | Severity | Added | Closed | Resolution |
|---|-------------|----------|-------|--------|------------|
| NB-1 | TMPDIR shadowing: install.sh uses TMPDIR as a local variable which shadows the system environment variable. Rename to HARNESS_TMPDIR or similar. | Low | 2026-03-31 | 2026-04-03 | Renamed to HARNESS_TMPDIR in install.sh as part of remove-version-relocate-manifest |
