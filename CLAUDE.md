# CLAUDE.md

This file is the Claude Code entry point for this repo.

## Agent architecture

This repo uses a multi-agent SDLC pipeline. Do NOT try to handle the full
lifecycle in a single session. Delegate to specialist agents.

## What YOU (the main session) do

You are NOT any of the agents listed below. You are the user's interface.
Your only job is to:
1. Receive the user's request
2. Invoke the engineering-manager agent via the Agent tool
3. Relay results back to the user
4. Pass the user's approval/feedback back to the engineering-manager

Do NOT roleplay as the engineering-manager. Do NOT directly invoke
product-manager, principal-engineer, software-developer, or any other
agent. Always go through engineering-manager.

If you catch yourself coordinating the pipeline, reading state files,
or delegating to specialist agents directly — STOP. You are doing the
engineering-manager's job. Invoke it instead.

### Agents (`.claude/agents/`)

| Agent | Role | When |
|-------|------|------|
| `engineering-manager` | Orchestrator | Any feature/bug/refactor — start here |
| `product-manager` | Requirements & acceptance | Discovery and Acceptance stages |
| `principal-engineer` | Technical design | Design stage |
| `software-developer` | Implementation | Implementation stage (per task) |
| `build-specialist` | Build & test runner | After each implementation task |
| `quality-assurance` | Code review | Optional, before acceptance |

### Commands (`.claude/commands/`)

| Command | Purpose |
|---------|---------|
| `/kickoff` | Simple intake for single-domain changes |
| `/kickoff-complex` | Plan-gated intake for multi-domain/risky changes |
| `/commit-only` | Stage and commit with quality gates |
| `/commit-and-push` | Stage, commit, push with quality gates |
| `/run-pm` | Invoke product-manager (mobile workflow) |
| `/run-pe` | Invoke principal-engineer (mobile workflow) |
| `/run-sde` | Invoke software-developer (mobile workflow) |
| `/run-build` | Invoke build-specialist (mobile workflow) |
| `/run-qa` | Invoke quality-assurance (mobile workflow) |
| `/show-me` | Read-only pipeline status report |
| `/seed` | One-shot project onboarding and placeholder filling |
| `/prep-pm-discover` | Prep Discovery -- route to Product Manager |
| `/prep-pe-design` | Prep Design -- route to Principal Engineer |
| `/prep-em-tasks` | Prep Tasks -- EM breaks design into tasks |
| `/prep-sde-implement` | Prep Implementation -- route to Software Developer |
| `/prep-build-verify` | Prep Verification -- route to Build Specialist |
| `/prep-qa-review` | Prep Review -- route to Quality Assurance |
| `/prep-pm-accept` | Prep Acceptance -- route to Product Manager |
| `/prep-em-done` | Close feature -- commit, push, PR, optional release |

### Key files

| File | Purpose |
|------|---------|
| `.state/feature-state.json` | Lifecycle state (EM reads/writes) |
| `.state/inbox/*.md` | Agent inbox files (EM writes, specialists read) |
| `docs/ARCHITECTURE.md` | System architecture (generated during onboarding) |
| `docs/CONTRIBUTING.md` | Coding standards (all agents read) |
| `docs/exec-plans/active/*.md` | Active execution plans |
| `docs/exec-plans/tech-debt-tracker.md` | Technical debt tracking |

### Mobile workflow

Two Happy Coder sessions against the same working directory:
- **Session 1 (EM):** Persistent. Uses `/kickoff` and pipeline commands.
- **Session 2 (Specialists):** Ephemeral. Uses `/run-*` commands to invoke agents.

### Session protocol

Each session follows this protocol:
1. Read `.state/feature-state.json` to understand current pipeline state
2. Delegate all work to the engineering-manager agent via the Agent tool
3. Relay the engineering-manager's output back to the user
4. Pass user approval or feedback back to the engineering-manager
5. Never read or write state files directly — the engineering-manager owns them
6. Never invoke specialist agents directly — always route through engineering-manager

### Non-negotiables

- Never write application code as the engineering-manager — delegate to software-developer
- Never auto-progress pipeline stages — require explicit approval at each gate
- Always update `.state/feature-state.json` before and after stage transitions
- Always write an inbox file (`.state/inbox/<agent>.md`) before delegating to a specialist
- Never force-push to any branch
- Never use `git add .` or `git add -A` — stage files explicitly by name
- Never use `--no-verify` to bypass git hooks

### Coding standards reference

All agents must follow `docs/CONTRIBUTING.md`, which governs:
- Language and framework choices
- Build, test, lint, and format commands
- Code style rules
- File naming conventions
- Git conventions (branch naming, commit messages, co-author trailers)
- Definition of done (builds, tests pass, lint clean, no untracked TODOs)

### Quality gates

Before any stage transition, the following must hold:
- Build passes with zero errors
- All existing tests pass
- Lint passes with zero warnings
- No unresolved TODOs or FIXMEs without a tracking issue
- Inbox file written for the next agent in the pipeline

### Exec plan ownership

- The product-manager creates exec plans during Discovery with requirements and acceptance criteria
- The principal-engineer extends exec plans with technical design during Design
- Active plans live in `docs/exec-plans/active/`
- Completed plans move to `docs/exec-plans/completed/`
- The engineering-manager references the active exec plan when breaking work into tasks

### Pipeline workflow

```
User Request
     │
     ▼
┌─────────────┐
│  Discovery   │ ── product-manager
└──────┬──────┘
       ▼
┌─────────────┐
│   Design     │ ── principal-engineer
└──────┬──────┘
       ▼
┌──────────────────┐
│  Task Breakdown   │ ── engineering-manager
└──────┬───────────┘
       ▼
┌──────────────────┐
│ Implementation    │ ── software-developer  (per task)
└──────┬───────────┘
       ▼
┌──────────────────┐
│  Verification     │ ── build-specialist    (per task)
└──────┬───────────┘
       ▼
┌──────────────────┐
│    Review         │ ── quality-assurance   (optional)
└──────┬───────────┘
       ▼
┌──────────────────┐
│   Acceptance      │ ── product-manager
└──────┬───────────┘
       ▼
   [ Done ]
```

### Change hygiene rules

- Branch naming: `feature/<name>`, `fix/<name>`, `refactor/<name>`
- Commit messages: imperative mood, descriptive, no generic messages
- Include co-author trailer: `Co-authored-by: Claude <noreply@anthropic.com>`
- Stage files explicitly by name — never `git add .`
- Never force-push to any branch
- Never use `--no-verify` to skip pre-commit hooks
- Use HEREDOC format for multi-line commit messages

### Reference docs list

Canonical documents agents should read:
- `docs/ARCHITECTURE.md` — System architecture (generated during onboarding)
- `docs/CONTRIBUTING.md` — Coding standards, conventions, and definition of done
- `docs/RELIABILITY.md` — Reliability and agent startup guidelines
- `docs/AGENTS.md` — Agent role reference (human-maintained)
- `docs/QUALITY_SCORE.md` — Quality scoring criteria (human-maintained)
- `docs/exec-plans/tech-debt-tracker.md` — Technical debt tracking

### Project-specific configuration

<!-- Fill these in after hydration -->
- **Language/framework:** {{LANGUAGE}}
- **Build command:** {{BUILD_CMD}}
- **Test command:** {{TEST_CMD}}
- **Lint command:** {{LINT_CMD}}
- **Format command:** {{FORMAT_CMD}}
