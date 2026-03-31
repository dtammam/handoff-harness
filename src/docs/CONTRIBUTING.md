# Contributing

Coding standards and conventions for this project. All agents read this file.

## Language & framework

- **Language:** {{LANGUAGE}}
- **Framework:** {{FRAMEWORK}}
- **Package manager:** {{PACKAGE_MANAGER}}

## Commands

| Action | Command |
|--------|---------|
| Build | `{{BUILD_CMD}}` |
| Test | `{{TEST_CMD}}` |
| Lint | `{{LINT_CMD}}` |
| Format | `{{FORMAT_CMD}}` |

## Code style

- {{STYLE_RULES}}

## File naming

- {{NAMING_CONVENTIONS}}

## Git conventions

- Branch naming: `feature/<name>`, `fix/<name>`, `refactor/<name>`
- Commit messages: imperative mood, descriptive, no generic messages
- Use HEREDOC format for multi-line commit messages
- Co-author trailer: `Co-authored-by: Claude <noreply@anthropic.com>`
- Never force-push. Never use `--no-verify`.
- Stage files explicitly — never `git add .`

## Definition of done

- [ ] Code compiles/builds without errors
- [ ] All existing tests pass
- [ ] New tests cover the change
- [ ] Lint passes with zero warnings
- [ ] No TODO/FIXME introduced without a tracking issue
