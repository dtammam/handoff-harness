# Tech Debt Tracker

## Active

| # | Description | Severity | Added | Source |
|---|-------------|----------|-------|--------|
| NB-1 | TMPDIR shadowing: install.sh uses TMPDIR as a local variable which shadows the system environment variable. Rename to HARNESS_TMPDIR or similar. | Low | 2026-03-31 | QA review of versioning-and-seed-nudge |
| NB-3 | Potential abort on deleted scaffold file: if a scaffold file listed in the manifest is deleted by the user, the update flow may attempt to checksum a missing file. Add a file-existence guard before checksum computation. | Low | 2026-03-31 | QA review of versioning-and-seed-nudge |

## Closed

| # | Description | Severity | Added | Closed | Resolution |
|---|-------------|----------|-------|--------|------------|
