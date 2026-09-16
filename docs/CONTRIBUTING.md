<!-- harness:region:start id=doc -->
# Contributing

How code is written in this repo — the harness's own project doc. Referenced from
`AGENTS.md` for "code style, build/test/lint commands, git conventions."

## Language & frameworks

- **Language:** Bash (POSIX-ish, `bash` features allowed) and Markdown.
- **Primary framework:** none — the harness is shell scripts + Markdown instruction files.
- **Other frameworks / runtimes:** `awk` (gawk) for the region/marker parsers; `git`.
- **Package manager:** none.

## Build / test / lint / format commands

| Action | Command |
|--------|---------|
| Build  | N/A — nothing to compile |
| Test   | `bash harnesses/selftest.sh` (install → edit → update → verify), plus `bash .harness/lib/check-markers.sh docs/exec-plans` |
| Lint   | `bash -n <script>` for syntax; `shellcheck harnesses/**/*.sh` if available |
| Format | N/A — keep shell tidy by hand; 2-space indent |

## Code style

- Shell: `set -uo pipefail` at the top of every script (add `-e` only where a
  failure should abort); quote expansions; prefer explicit checks over cleverness.
- Keep scripts small and single-purpose; a script that needs a paragraph of
  explanation wants splitting.
- Markdown instruction files (agents, commands, flow): imperative, dense, no
  filler. Wrap harness-owned content in region markers (see `.harness/lib/regions.md`).

## File & naming conventions

- kebab-case filenames; executable scripts end in `.sh` and are `chmod +x`.
- Agent files: `.claude/agents/<seat>.md`; commands: `.claude/commands/<name>.md`.
- Harness source lives under `harnesses/core/`; the installed copy mirrors it.

## Git conventions

- Branch naming: `feature/<name>`, `fix/<name>`, `refactor/<name>`.
- Commit messages: imperative mood, describe the decision; HEREDOC for multi-line.
- Co-author trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Stage files by name.** Never `git add .` / `git add -A`.
- **Never force-push. Never `--no-verify`.**

## Testing methodology

- Tests are self-contained bash scripts that assert and exit non-zero on failure
  (`harnesses/selftest.sh`, the rigged/clean cases for `check-markers.sh`).
- Prove a mechanism by running it, not by describing it — the same discipline the
  Adversary seat enforces.
- **Anchor tie-in:** under `tdd`, write the failing check first; under `spec`,
  the check follows the approved design in the same change; under `outcome`,
  cover the observable behavior. The active anchor governs — see `.harness/flow.md`.

## Definition of done

- [ ] `bash harnesses/selftest.sh` passes.
- [ ] `bash .harness/lib/check-markers.sh docs/exec-plans` is clean.
- [ ] Changed scripts pass `bash -n` (and `shellcheck` where available).
- [ ] Any change to a `harnesses/core/` file is reflected in the installed root copy if it governs this repo.
- [ ] Failures reported verbatim, with counts — "verified," not "should work."
<!-- harness:region:end id=doc -->

<!-- harness:region:start id=project keep -->
## Project conventions

- `harnesses/core/` is the single source of truth; the repo's own root install is
  a dogfood copy. When you change a core file that also governs this repo,
  re-run the dogfood install or the two drift.
- Every harness-owned Markdown file carries region markers; the one project-owned
  region per file is marked `keep` and is never regenerated.
<!-- harness:region:end id=project -->
