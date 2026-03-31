# handoff-harness

A multi-agent SDLC pipeline for Claude Code. Instead of one monolith session handling everything, specialist agents handle each phase of the development lifecycle in their own context window.

## Architecture

```
User describes work
  → engineering-manager (orchestrator — never codes)
    → product-manager (Discovery: requirements & acceptance criteria)
    → principal-engineer (Design: technical approach)
    → engineering-manager (Task breakdown)
    → software-developer (Implementation: code & tests, per task)
    → build-specialist (Verify: build & test, per task)
    → product-manager (Acceptance: validate criteria)
  → Done
```

Every stage transition requires explicit user approval. No auto-progression.

## Agents

| Agent | File | Role | Model |
|-------|------|------|-------|
| engineering-manager | `.claude/agents/engineering-manager.md` | Orchestrator | opus |
| product-manager | `.claude/agents/product-manager.md` | Requirements & acceptance | sonnet |
| principal-engineer | `.claude/agents/principal-engineer.md` | Technical design | opus |
| software-developer | `.claude/agents/software-developer.md` | Implementation | sonnet |
| build-specialist | `.claude/agents/build-specialist.md` | Build & test runner | haiku |
| quality-assurance | `.claude/agents/quality-assurance.md` | Code review (optional) | sonnet |

## Coordination

Agents don't share a context window. They coordinate through:

1. **`.state/feature-state.json`** — lifecycle state, current stage, task list, artifact paths
2. **`docs/exec-plans/active/*.md`** — requirements, design, progress log
3. **`docs/CONTRIBUTING.md`** — shared coding standards all agents read

The engineering-manager reads and writes the state file. Other agents read it for context and write to exec plan files.

## Commands

| Command | File | Purpose |
|---------|------|---------|
| `/kickoff` | `.claude/commands/kickoff.md` | Simple intake for single-domain changes |
| `/kickoff-complex` | `.claude/commands/kickoff-complex.md` | Plan-gated intake for multi-domain changes |
| `/commit-only` | `.claude/commands/commit-only.md` | Stage and commit |
| `/commit-and-push` | `.claude/commands/commit-and-push.md` | Stage, commit, push |
| `/run-pm` | `.claude/commands/run-pm.md` | Invoke product-manager agent |
| `/run-pe` | `.claude/commands/run-pe.md` | Invoke principal-engineer agent |
| `/run-sde` | `.claude/commands/run-sde.md` | Invoke software-developer agent |
| `/run-build` | `.claude/commands/run-build.md` | Invoke build-specialist agent |
| `/run-qa` | `.claude/commands/run-qa.md` | Invoke quality-assurance agent |

## Installation

### New repo (greenfield)

```bash
curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash
```

### Existing repo (brownfield)

Same command — the installer detects existing files, archives them to `.state/plans/legacy/`, then hydrates. After hydration, run the onboarding agent to generate ARCHITECTURE.md from your existing codebase.

### Updating

```bash
curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash -s -- --update
```

## Directory Structure

```
.claude/
  agents/              # Agent definitions (one .md per agent)
  commands/            # Slash commands for Claude Code
  hooks/               # Claude Code hooks (e.g., SessionStart)
  settings.json        # Claude Code settings (hooks registration)
.state/
  feature-state.json   # Current feature lifecycle state
  inbox/               # EM writes here, specialists read from here
  plans/
    active/            # In-flight execution plans
    completed/         # Finished plans
    legacy/            # Pre-hydration artifacts archived here
docs/
  ARCHITECTURE.md      # Generated during onboarding from codebase scan
  CONTRIBUTING.md      # Coding standards all agents read
  AGENTS.md            # Agent operating instructions
  RELIABILITY.md       # Reliability and quality standards
  QUALITY_SCORE.md     # Quality grading by domain
  exec-plans/
    active/            # Active execution plan files
    completed/         # Completed execution plan files
    tech-debt-tracker.md
  references/          # Reference docs for agents
hooks/
  pre-commit           # Git pre-commit hook
  pre-push             # Git pre-push hook
scripts/
  run-product-manager.sh
  run-principal-engineer.sh
  run-software-developer.sh
  run-build-specialist.sh
  run-quality-assurance.sh
CLAUDE.md              # Claude Code entry point
install.sh             # Hydration script
setup.sh               # Post-hydration setup (git hooks, permissions)
```

## Mobile Workflow (Happy Coder)

Two sessions running simultaneously against the same working directory:

- **Session 1 (EM):** Uses `/kickoff`, `/discover`, `/design`, etc. — persistent, long-running
- **Session 2 (Specialist workbench):** Uses `/run-pm`, `/run-sde`, etc. — ephemeral, one agent at a time

The EM writes `.state/inbox/<agent-name>.md`. Session 2 consumes those inbox files via the `/run-*` commands.

## License

MIT
