# Requirements: meta-harness-restructure

## Goal

Restructure the handoff-harness repo to be self-hosting — separating clean distributable source files into `src/` while keeping the top-level working copy intact, and adding two new commands (`/showme` and `/seed`) to both locations.

---

## Scope

### In scope

- Create a `src/` directory that mirrors the directory layout a target repo receives after `install.sh` runs
- Populate `src/` with all distributable harness files (agents, commands, hooks, docs templates, scripts, state skeleton, CLAUDE.md template, setup.sh)
- Include the two new commands (`showme.md`, `seed.md`) in both `src/.claude/commands/` and the top-level `.claude/commands/`
- Update `install.sh` to copy from `src/` rather than the repo root
- Leave all top-level harness files (`.claude/`, `CLAUDE.md`, `docs/`, `hooks/`, `scripts/`, `.state/`, `setup.sh`) exactly in place and fully functional

### Explicitly out of scope

- Changing any agent logic beyond what is needed for the two new commands
- Symlinking between `src/` and top-level (files are duplicated; top-level can diverge as a customized working copy)
- Adding automated tests or a test framework
- Changing the external interface of `install.sh` (same flags, same usage pattern)
- Modifying `README.md`, `LICENSE`, or any documentation unrelated to this change
- Any compiled language, package manager, or build tooling introduction

---

## Requirements

### R-1: `src/` directory structure

1. A `src/` directory MUST exist at the repo root after this change.
2. `src/` MUST contain the following subtrees, each populated with the current distributable content:
   - `src/.claude/agents/` — all 6 agent definition files
   - `src/.claude/commands/` — all 9 existing command files plus the 2 new commands (`showme.md`, `seed.md`)
   - `src/.claude/hooks/` — session hook scripts
   - `src/.claude/settings.json`
   - `src/CLAUDE.md` — the template CLAUDE.md with `{{placeholders}}`
   - `src/docs/` — all template doc files (CONTRIBUTING.md, ARCHITECTURE.md, RELIABILITY.md, QUALITY_SCORE.md, AGENTS.md, exec-plans/ skeleton, references/)
   - `src/hooks/` — git hooks (pre-commit, pre-push)
   - `src/scripts/` — all runner scripts
   - `src/.state/` — skeleton directory structure with `.gitkeep` files only (no live state)
   - `src/setup.sh`
3. `src/` MUST NOT contain `install.sh`, `README.md`, `LICENSE`, or any live `.state/` data.

### R-2: `install.sh` updated to copy from `src/`

4. `install.sh` MUST source files from `src/` inside the cloned repo, not from the repo root.
5. `install.sh` MUST continue to support both greenfield and brownfield (conflict-archive) modes.
6. `install.sh` MUST continue to accept the `--update` flag with unchanged behavior.
7. Files installed into a target repo MUST NOT include the `src/` prefix in their destination paths (i.e., `src/.claude/agents/foo.md` installs as `.claude/agents/foo.md` in the target).

### R-3: Top-level self-hosting copy remains intact

8. All top-level harness files (`.claude/`, `CLAUDE.md`, `docs/`, `hooks/`, `scripts/`, `.state/`, `setup.sh`) MUST remain present and unmodified except to add the two new commands.
9. The top-level harness MUST remain fully functional as a working SDLC pipeline throughout and after the restructure (no broken agent references, no broken command paths).
10. The top-level `.claude/commands/` MUST include `showme.md` and `seed.md` after this change.

### R-4: `/showme` read-only status command

11. A command file `showme.md` MUST exist at both `.claude/commands/showme.md` and `src/.claude/commands/showme.md`.
12. When invoked, `/showme` MUST read `.state/feature-state.json` and report the current pipeline stage and active feature name.
13. `/showme` MUST read the `history` array in the state file and map the most recent stage transition to the agent responsible for it, using the following mapping:
    - `discovery` → Product Manager
    - `design` → Principal Engineer
    - `tasks` → Engineering Manager
    - `implementation` → Software Developer
    - `verification` → Build Specialist
    - `review` → Quality Assurance
    - `acceptance` → Product Manager
14. `/showme` MUST read the last active agent's inbox file from `.state/inbox/`.
15. `/showme` MUST run `git diff --stat` and `git diff --name-only` to surface recently changed files.
16. `/showme` MUST read the exec plan path recorded in `feature-state.json` and display its contents.
17. `/showme` MUST present a formatted summary containing: Stage, Last agent, What changed, Where we are in the pipeline, and the recommended next step.
18. `/showme` MUST be strictly read-only — it MUST NOT modify any state files and MUST NOT invoke any other agent.
19. If no active feature is present (state file absent or feature name empty), `/showme` MUST report that no active feature exists and stop without error.

### R-5: `/seed` interactive onboarding command

20. A command file `seed.md` MUST exist at both `.claude/commands/seed.md` and `src/.claude/commands/seed.md`.
21. When invoked, `/seed` MUST trigger the engineering-manager with a special SEED instruction that does NOT start a normal feature lifecycle.
22. The seed operation MUST discover the following from the target project's existing codebase: primary language and framework, build/test/lint/format commands, package manager, high-level architecture patterns, and existing coding conventions.
23. The seed operation MUST fill in `{{TODO}}` and `{{placeholder}}` tokens in: `CLAUDE.md`, `docs/CONTRIBUTING.md`, `docs/ARCHITECTURE.md`, `docs/RELIABILITY.md`, `hooks/pre-commit`, and `hooks/pre-push`.
24. The seed operation MUST present a structured seed report summarizing what was auto-detected and what was filled in.
25. The seed operation MUST be one-shot — it MUST NOT place a feature into the SDLC lifecycle state machine.
26. The seed operation MUST preserve existing user-written content when filling placeholders (merge/append approach, not wholesale replacement of non-placeholder text).
27. Any value that cannot be auto-detected MUST be flagged explicitly in the seed report as requiring manual attention, rather than left as a placeholder silently.

---

## Acceptance criteria

### AC-1: `src/` structure

- AC-1.1: `ls src/` returns directories `.claude/`, `docs/`, `hooks/`, `scripts/`, `.state/` and files `CLAUDE.md`, `setup.sh`.
- AC-1.2: `src/.claude/commands/` contains exactly 11 files: the 9 existing commands plus `showme.md` and `seed.md`.
- AC-1.3: `src/.state/` contains only `.gitkeep` files — no `.json`, `.md`, or other live data files.
- AC-1.4: `install.sh`, `README.md`, and `LICENSE` are NOT present inside `src/`.

### AC-2: `install.sh` behavior

- AC-2.1: The `PACK_FILES` discovery in `install.sh` references the `src/` subdirectory of the cloned repo, not the repo root.
- AC-2.2: A dry-run inspection of what `install.sh` would copy shows paths stripped of the `src/` prefix (e.g., `.claude/agents/engineering-manager.md`, not `src/.claude/agents/engineering-manager.md`).
- AC-2.3: `install.sh --update` flag is still accepted and handled.

### AC-3: Top-level functional integrity

- AC-3.1: `.claude/commands/` at the top level contains `showme.md` and `seed.md` in addition to the existing 9 commands.
- AC-3.2: `.claude/agents/`, all 6 agent files, and all existing command files remain present and unmodified (excluding additions).
- AC-3.3: `.state/feature-state.json` and `.state/inbox/` remain intact and unmodified.

### AC-4: `/showme` command

- AC-4.1: `showme.md` is present at both `.claude/commands/showme.md` and `src/.claude/commands/showme.md`.
- AC-4.2: The command definition instructs the agent to read `.state/feature-state.json` before doing anything else.
- AC-4.3: The command definition includes the stage-to-agent mapping table covering all 7 stages.
- AC-4.4: The command definition explicitly prohibits state writes and agent invocations.
- AC-4.5: The command definition includes a no-active-feature guard condition.

### AC-5: `/seed` command

- AC-5.1: `seed.md` is present at both `.claude/commands/seed.md` and `src/.claude/commands/seed.md`.
- AC-5.2: The command definition instructs invocation of `engineering-manager` with a SEED instruction, not a standard feature kickoff.
- AC-5.3: The command definition lists all 6 target files for placeholder replacement.
- AC-5.4: The command definition specifies that existing non-placeholder content must be preserved.
- AC-5.5: The command definition specifies that undetectable values must be flagged in the seed report rather than left as placeholders.
- AC-5.6: The command definition explicitly states this does NOT create a feature lifecycle entry.

---

## Constraints

- Shell and Markdown only — no compiled code, no package manager, no test framework may be introduced.
- The top-level harness pipeline MUST remain operational at all times during implementation; the restructure MUST be staged so it never leaves the repo in a broken state.
- `src/` files are copies, not symlinks. The top-level working copy is allowed to diverge from `src/` over time as project-specific customization occurs.
- `install.sh` external interface (URL, flags, usage) MUST NOT change; only its internal file-sourcing path changes.
- No force-push. No `--no-verify`. Commits must be staged explicitly per CONTRIBUTING.md git conventions.

---

## Resolved questions

1. **`src/CLAUDE.md` content:** Identical to top-level `CLAUDE.md` (with `{{placeholders}}` intact), but with added context that the repo houses a project consisting mostly of markdown and config files.

2. **`src/docs/` scope:** RELIABILITY.md, QUALITY_SCORE.md, and AGENTS.md all exist at the top level already. They should be copied into `src/docs/` as templates (preserving their `{{placeholder}}` tokens).

3. **Top-level `showme.md` and `seed.md` vs `src/` copies:** Identical. The top-level copies start as exact duplicates of the `src/` counterparts.

4. **`/seed` engineering-manager integration:** Seed operates entirely outside the state machine. There is no `seeding` stage. `/seed` is a one-shot onboarding operation that does not interact with `feature-state.json`.

5. **Conflict behavior for `/seed`:** If run on a fully hydrated repo (no `{{placeholder}}` tokens remaining), `/seed` should produce a no-op report summarizing what it found, or offer to re-scan and update values. It must not silently overwrite existing content.
