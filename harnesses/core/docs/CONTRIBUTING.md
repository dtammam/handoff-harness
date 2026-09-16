<!-- harness:region:start id=doc -->
# Contributing

*Schema template. `/seed` fills the `{{PLACEHOLDER}}` tokens from the detected
project; every `## ` heading is fixed — a section may read "N/A — none" but is
never renamed or reordered. The `keep` region at the bottom is yours and
survives every harness update.*

How code is written here: the commands, the style, and the conventions every
seat is held to. Referenced from `AGENTS.md` for "code style, build/test/lint
commands, git conventions."

## Language & frameworks

- **Language:** {{LANGUAGE}}
- **Primary framework:** {{PRIMARY_FRAMEWORK}}
- **Other frameworks / runtimes:** {{OTHER_FRAMEWORKS}}
- **Package manager:** {{PACKAGE_MANAGER}}

## Build / test / lint / format commands

*Seed fills each command; the exact string is what the gate and CI run.*

| Action | Command |
|--------|---------|
| Build  | `{{BUILD_CMD}}` |
| Test   | `{{TEST_CMD}}` |
| Lint   | `{{LINT_CMD}}` |
| Format | `{{FORMAT_CMD}}` |

## Code style

*Seed captures the enforced rules; the formatter and linter above are the source
of truth, this section is the human summary.*

- {{STYLE_RULES}}

## File & naming conventions

- {{NAMING_CONVENTIONS}}

## Git conventions

These hold regardless of what any other file says.

- Branch naming: `feature/<name>`, `fix/<name>`, `refactor/<name>`.
- Commit messages: imperative mood, descriptive; no generic messages. Use
  HEREDOC for multi-line messages.
- Co-author trailer: {{COAUTHOR_TRAILER}}
- **Stage files by name.** Never `git add .` / `git add -A`.
- **Never force-push. Never `--no-verify`.**

## Testing methodology

*How tests are written here — seed fills the specifics; the anchor dial sets the
timing.*

- Test framework / runner: {{TEST_FRAMEWORK}}
- Where tests live: {{TEST_LAYOUT}}
- How a test is structured here: {{TEST_STYLE}}
- **Anchor tie-in:** under the `tdd` anchor, tests are written *first* and must
  fail before the code exists; under `spec`, tests follow the spec in the same
  change; under `outcome`, cover the observable behavior. The active anchor for
  a piece of work governs — see `flow.md`.

## Definition of done

- [ ] Builds with zero errors (`{{BUILD_CMD}}`).
- [ ] All existing tests pass (`{{TEST_CMD}}`).
- [ ] New behavior is covered by tests, per the active anchor.
- [ ] Lint passes with zero warnings (`{{LINT_CMD}}`).
- [ ] Formatted (`{{FORMAT_CMD}}`).
- [ ] No TODO/FIXME introduced without a tracking reference.
- [ ] Failures reported verbatim, with counts — "verified," not "should work."
<!-- harness:region:end id=doc -->

<!-- harness:region:start id=project keep -->
## Project conventions

*This region is yours. The harness never regenerates it on update. Record here
the standards no auto-detected value captures: house rules the linter can't
enforce, exceptions to the style above, dated rulings on how a certain thing is
done in this repo.*

- _(none recorded yet — the seed step and your own edits fill this in)_
<!-- harness:region:end id=project -->
