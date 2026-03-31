# Technical Design: meta-harness-restructure

## Approach

This change reorganizes the handoff-harness repo into a self-hosting structure. Today, `install.sh` clones the repo and copies nearly everything at the root into the target project. After this change, the distributable template files live in `src/`, and `install.sh` copies from `src/` instead. The top-level working copy remains fully functional and untouched (except for adding two new command files). Two new slash commands (`/showme` and `/seed`) are added to both `src/.claude/commands/` and the top-level `.claude/commands/`.

The key invariant throughout: the top-level harness pipeline never breaks. Every commit during implementation must leave the repo in a working state.

---

## 1. `src/` directory structure

### Exact file tree

```
src/
  .claude/
    agents/
      build-specialist.md          (copy of top-level)
      engineering-manager.md       (copy of top-level)
      principal-engineer.md        (copy of top-level)
      product-manager.md           (copy of top-level)
      quality-assurance.md         (copy of top-level)
      software-developer.md        (copy of top-level)
    commands/
      commit-and-push.md           (copy of top-level)
      commit-only.md               (copy of top-level)
      kickoff-complex.md           (copy of top-level)
      kickoff.md                   (copy of top-level)
      run-build.md                 (copy of top-level)
      run-pe.md                    (copy of top-level)
      run-pm.md                    (copy of top-level)
      run-qa.md                    (copy of top-level)
      run-sde.md                   (copy of top-level)
      seed.md                      (NEW - identical to top-level)
      showme.md                    (NEW - identical to top-level)
    hooks/
      session-start.sh             (copy of top-level)
    settings.json                  (copy of top-level)
  .state/
    inbox/
      .gitkeep
    plans/
      active/
        .gitkeep
      completed/
        .gitkeep
      legacy/
        .gitkeep
  docs/
    AGENTS.md                      (copy of top-level, placeholders intact)
    ARCHITECTURE.md                (copy of top-level, placeholders intact)
    CONTRIBUTING.md                (copy of top-level, placeholders intact)
    QUALITY_SCORE.md               (copy of top-level, placeholders intact)
    RELIABILITY.md                 (copy of top-level, placeholders intact)
    exec-plans/
      active/
        .gitkeep
      completed/
        .gitkeep
      tech-debt-tracker.md         (copy of top-level)
    references/
      .gitkeep
  hooks/
    pre-commit                     (copy of top-level)
    pre-push                       (copy of top-level)
  scripts/
    run-build-specialist.sh        (copy of top-level)
    run-principal-engineer.sh      (copy of top-level)
    run-product-manager.sh         (copy of top-level)
    run-quality-assurance.sh       (copy of top-level)
    run-software-developer.sh      (copy of top-level)
  CLAUDE.md                        (template version - see below)
  setup.sh                         (copy of top-level)
```

### What stays OUT of `src/`

- `install.sh` -- the installer itself is not distributed into target repos
- `README.md` -- repo-specific documentation
- `LICENSE` -- repo-level license file
- Any live `.state/` data (`.json` files, `.md` inbox files) -- only `.gitkeep` skeletons
- `docs/exec-plans/active/*.md` -- no execution plans; only `.gitkeep`

### `src/CLAUDE.md` content

`src/CLAUDE.md` is identical to the current top-level `CLAUDE.md` with all `{{placeholder}}` tokens preserved. The only addition is a contextual note inserted immediately after the `# CLAUDE.md` heading. The added paragraph reads:

```
This project consists primarily of Markdown files, shell scripts, and
configuration files. There is no compiled application code. The SDLC
pipeline manages documentation, agent definitions, and process automation.
```

The rest of the file is a verbatim copy of the current top-level `CLAUDE.md`, including the commands table (which will include the two new commands -- see below), the agents table, key files table, mobile workflow section, and the project-specific configuration section with `{{LANGUAGE}}`, `{{BUILD_CMD}}`, `{{TEST_CMD}}`, `{{LINT_CMD}}`, `{{FORMAT_CMD}}` placeholders.

### `src/.state/` skeleton

The `.state/` directory under `src/` contains only `.gitkeep` files. No `feature-state.json`, no inbox `.md` files. The directory tree mirrors the top-level `.state/` structure:

```
src/.state/
  inbox/.gitkeep
  plans/active/.gitkeep
  plans/completed/.gitkeep
  plans/legacy/.gitkeep
```

---

## 2. `install.sh` changes

### Current behavior

Lines 37-44 currently discover `PACK_FILES` by running `find` from the cloned repo root, excluding `.git`, `README.md`, `LICENSE`, and `install.sh`. It then copies all discovered files into the target with paths preserved as-is.

### New behavior

The `PACK_FILES` discovery changes to source from the `src/` subdirectory. The `src/` prefix is stripped when computing destination paths.

### Specific code changes

**Change 1: PACK_FILES discovery (lines 37-44)**

Replace:
```bash
PACK_FILES=$(cd "$TMPDIR/handoff-harness" && find . \
  -not -path './.git/*' \
  -not -path './.git' \
  -not -name 'README.md' \
  -not -name 'LICENSE' \
  -not -name 'install.sh' \
  -not -name '.' \
  -type f | sort)
```

With:
```bash
PACK_FILES=$(cd "$TMPDIR/handoff-harness/src" && find . \
  -not -path './.git/*' \
  -not -path './.git' \
  -not -name '.' \
  -type f | sort)
```

The exclusions for `README.md`, `LICENSE`, and `install.sh` are no longer needed because those files do not exist inside `src/`.

**Change 2: Conflict detection loop (lines 48-53)**

No structural change needed. The `$file` variable now holds paths relative to `src/` (e.g., `./.claude/agents/engineering-manager.md`), which is exactly the path we want in the target. The `target_path="$TARGET/$file"` logic works unchanged.

**Change 3: Copy loop source path (lines 73-78)**

Replace:
```bash
  src="$TMPDIR/handoff-harness/$file"
```

With:
```bash
  src="$TMPDIR/handoff-harness/src/$file"
```

The `dest="$TARGET/$file"` line remains unchanged because `$file` is already relative to `src/` (no `src/` prefix in the path).

**Change 4: File count message (line 89)**

No change needed. The `wc -l` count on `$PACK_FILES` will reflect the new file set automatically.

**Change 5: Next steps message (lines 91-98)**

No change needed. The message still references `CLAUDE.md`, `docs/CONTRIBUTING.md`, etc. -- all correct paths in the target.

### Preserved behaviors

- `--update` flag parsing: unchanged (lines 16-20)
- Greenfield/brownfield detection: unchanged logic, just operates on new file set
- Conflict archiving to `.state/plans/legacy/`: unchanged
- Executable permissions (`chmod +x`): unchanged (lines 82-85)
- Temporary directory cleanup: unchanged
- External URL and usage interface: unchanged

---

## 3. `/showme` command

### File path

Identical file at both:
- `.claude/commands/showme.md`
- `src/.claude/commands/showme.md`

### Full command file content

```markdown
# Show Me

Read-only status report for the current SDLC pipeline state.

## Rules

- This command is STRICTLY READ-ONLY.
- Do NOT modify any files, state, or configuration.
- Do NOT invoke any agent (engineering-manager or otherwise).
- Do NOT write to `.state/` or any inbox file.

## Workflow

1. Read `.state/feature-state.json`.
   - If the file does not exist, is empty, contains `{}`, or has no `feature_name` value, report: "No active feature in the pipeline." and STOP.

2. Extract from the state file:
   - `feature_name` -- the active feature
   - `stage` -- the current pipeline stage
   - `exec_plan` -- path to the execution plan
   - `tasks` -- the task list (if present)

3. Determine the responsible agent for the current stage using this mapping:

   | Stage | Responsible Agent |
   |-------|-------------------|
   | `discovery` | Product Manager |
   | `design` | Principal Engineer |
   | `tasks` | Engineering Manager |
   | `implementation` | Software Developer |
   | `verification` | Build Specialist |
   | `review` | Quality Assurance |
   | `acceptance` | Product Manager |

4. Read the inbox file for the responsible agent at `.state/inbox/<agent-name>.md` (using kebab-case: `product-manager.md`, `principal-engineer.md`, `engineering-manager.md`, `software-developer.md`, `build-specialist.md`, `quality-assurance.md`). If the inbox file is missing or empty, note "No inbox content for this agent."

5. Run `git diff --stat` and `git diff --name-only` to capture uncommitted changes. If the working tree is clean, note "Working tree is clean."

6. Read the execution plan file at the path specified in the `exec_plan` field. If the path is missing or the file does not exist, note "No execution plan found."

7. If the `tasks` array is present, summarize task completion status (count completed vs total).

8. Present a formatted summary with these sections:

   ```
   ## Pipeline Status

   **Feature:** <feature_name>
   **Stage:** <stage>
   **Responsible agent:** <agent name from mapping>

   ## Agent Inbox

   <contents of the agent's inbox file, or "No inbox content for this agent.">

   ## Uncommitted Changes

   <output of git diff --stat, or "Working tree is clean.">

   ## Changed Files

   <output of git diff --name-only, or "No changed files.">

   ## Task Progress

   <X of Y tasks completed, or "No tasks defined yet.">

   ## Execution Plan

   <contents of the exec plan file, or "No execution plan found.">

   ## Recommended Next Step

   <Based on the current stage, recommend the appropriate /run-* command or action:
     - discovery: "/run-pm to invoke the Product Manager"
     - design: "/run-pe to invoke the Principal Engineer"
     - tasks: "Waiting for Engineering Manager to break down tasks"
     - implementation: "/run-sde to invoke the Software Developer"
     - verification: "/run-build to invoke the Build Specialist"
     - review: "/run-qa to invoke Quality Assurance"
     - acceptance: "/run-pm to invoke the Product Manager for acceptance">
   ```
```

### Design notes

- The command is a markdown instruction file, not executable code. Claude interprets it.
- It reads state files and runs two git commands but writes nothing.
- The `history` array mentioned in R-13 of the requirements may or may not exist in the state file. The design uses the `stage` field directly to determine the responsible agent, which is equivalent and more reliable (the stage field is always present when a feature is active). If a `history` array is present, the agent may optionally reference it for additional context, but the primary mapping uses `stage`.

---

## 4. `/seed` command

### File path

Identical file at both:
- `.claude/commands/seed.md`
- `src/.claude/commands/seed.md`

### Full command file content

```markdown
# Seed

One-shot onboarding command that auto-detects project configuration and fills in template placeholders.

## Rules

- This command does NOT start a feature lifecycle.
- This command does NOT interact with `.state/feature-state.json`.
- This command does NOT create execution plans or tasks.
- This is a ONE-SHOT operation. It runs, produces a report, and finishes.
- NEVER silently overwrite existing non-placeholder content.

## Workflow

1. Invoke the engineering-manager agent with the following SEED instruction (use the Agent tool with the `engineering-manager` agent):

   ```
   SEED INSTRUCTION -- NOT A FEATURE KICKOFF

   This is a one-shot onboarding operation. Do NOT create a feature lifecycle
   entry. Do NOT write to .state/feature-state.json. Do NOT create an
   execution plan.

   Your job:

   A. SCAN the codebase to auto-detect:
      - Primary language(s) and framework(s)
      - Build command (e.g., `cargo build`, `npm run build`, `go build ./...`)
      - Test command (e.g., `cargo test`, `npm test`, `pytest`)
      - Lint command (e.g., `cargo clippy`, `npx eslint .`, `ruff check .`)
      - Format command (e.g., `cargo fmt`, `npx prettier --write .`, `black .`)
      - Package manager (e.g., cargo, npm, pip, go modules)
      - High-level architecture patterns (monolith, microservices, monorepo, etc.)
      - Existing coding conventions (naming style, module organization, error handling patterns)

      Detection sources: look for Cargo.toml, package.json, go.mod, pyproject.toml,
      Makefile, Dockerfile, CI config files (.github/workflows/, .gitlab-ci.yml),
      existing source files, and any existing documentation.

   B. CHECK for remaining placeholders in these target files:
      - CLAUDE.md
      - docs/CONTRIBUTING.md
      - docs/ARCHITECTURE.md
      - docs/RELIABILITY.md
      - hooks/pre-commit
      - hooks/pre-push

      Placeholders are tokens matching the pattern: {{PLACEHOLDER_NAME}} or {{TODO}}.

      If NO placeholders remain in ANY target file, produce a NO-OP REPORT:
        - State that all placeholders are already filled.
        - Summarize the current detected values for each field.
        - Offer to re-scan if the user wants to update values.
        - Do NOT modify any files.
        - STOP here.

   C. FILL IN detected values by replacing placeholder tokens in each target file:
      - {{LANGUAGE}} -> detected primary language
      - {{FRAMEWORK}} -> detected framework (or "None" if not applicable)
      - {{PACKAGE_MANAGER}} -> detected package manager
      - {{BUILD_CMD}} -> detected build command
      - {{TEST_CMD}} -> detected test command
      - {{LINT_CMD}} -> detected lint command
      - {{FORMAT_CMD}} -> detected format command
      - {{STYLE_RULES}} -> observed coding style conventions
      - {{NAMING_CONVENTIONS}} -> observed file/variable naming patterns
      - {{SYSTEM_OVERVIEW}} -> high-level architecture description
      - {{COMPONENT_LIST}} -> detected major components/modules
      - {{DATA_FLOW_DESCRIPTION}} -> how data moves through the system
      - {{CONSTRAINTS}} -> detected technical constraints
      - {{ERROR_HANDLING_PATTERNS}} -> observed error handling approach
      - {{LOGGING_CONVENTIONS}} -> observed logging patterns
      - {{UNIT_TEST_APPROACH}} -> detected unit test setup
      - {{INTEGRATION_TEST_APPROACH}} -> detected integration test setup
      - {{E2E_TEST_APPROACH}} -> detected E2E test setup
      - {{MONITORING_APPROACH}} -> detected monitoring setup
      - {{TEST_CMD_FAST}} -> fast test subset command
      - {{DOMAIN_1}} -> primary domain name

      For hooks/pre-commit and hooks/pre-push:
      - Uncomment the appropriate tech-stack section based on detected language
      - Fill in any placeholder commands
      - Leave other commented sections as-is

      PRESERVATION RULES:
      - Only replace the placeholder token itself. Do not alter surrounding text.
      - If a file contains both placeholder tokens and user-written content,
        preserve all user-written content exactly as-is.
      - If a placeholder cannot be auto-detected, leave the placeholder in place
        and flag it in the report.

   D. PRODUCE a structured seed report with these sections:

      ## Seed Report

      ### Detected Configuration
      | Field | Value | Confidence | Source |
      |-------|-------|------------|--------|
      (one row per detected value, with the file/signal that informed the detection)

      ### Files Modified
      - List each file that was modified and what placeholders were filled

      ### Unresolved Placeholders
      - List any placeholders that could NOT be auto-detected
      - For each, explain why and suggest how the user can fill it manually

      ### Recommendations
      - Any additional setup steps the user should take

   E. STOP. Do not proceed to any pipeline stage.
   ```

2. Present the seed report to the user.
3. If the engineering-manager reports a no-op (all placeholders filled), relay that to the user and offer to re-run with `--force` semantics (re-scan and update).
```

### Design notes

- The `/seed` command file itself is a markdown instruction that tells the main Claude session to invoke the engineering-manager with a special non-lifecycle instruction.
- The engineering-manager must be able to handle SEED instructions distinctly from normal kickoff flows. This requires no code change to the EM agent file -- the instruction is self-contained in the prompt passed via the Agent tool.
- The placeholder detection pattern is simple string matching for `{{...}}` tokens.
- The command operates on the target repo's top-level files (not `src/` files). After install, those files are what the user has.

---

## 5. Top-level CLAUDE.md update

After the two new commands are added, the Commands table in both the top-level `CLAUDE.md` and `src/CLAUDE.md` must include two new rows:

```
| `/showme` | Read-only pipeline status report |
| `/seed` | One-shot project onboarding and placeholder filling |
```

These rows are inserted into the existing Commands table. No other changes to the top-level `CLAUDE.md`.

---

## 6. Components affected

| File | Change | Reason |
|------|--------|--------|
| `install.sh` | Modify PACK_FILES discovery and copy source path | Source from `src/` instead of repo root |
| `.claude/commands/showme.md` | New file | New `/showme` command |
| `.claude/commands/seed.md` | New file | New `/seed` command |
| `CLAUDE.md` | Add 2 rows to commands table | Document new commands |

---

## 7. New components

| File | Purpose |
|------|---------|
| `src/` (entire tree) | Distributable template files for install.sh |
| `src/CLAUDE.md` | Template CLAUDE.md with project context note |
| `src/.claude/agents/*.md` (6 files) | Copies of agent definitions |
| `src/.claude/commands/*.md` (11 files) | Copies of all commands including new ones |
| `src/.claude/hooks/session-start.sh` | Copy of session hook |
| `src/.claude/settings.json` | Copy of settings |
| `src/.state/` (4 `.gitkeep` files) | State directory skeleton |
| `src/docs/` (5 doc files + skeleton dirs) | Template documentation |
| `src/hooks/pre-commit`, `src/hooks/pre-push` | Copy of git hooks |
| `src/scripts/*.sh` (5 files) | Copy of runner scripts |
| `src/setup.sh` | Copy of setup script |
| `.claude/commands/showme.md` | New command (top-level) |
| `.claude/commands/seed.md` | New command (top-level) |

---

## 8. Data flow

### `/showme` data flow

```
User invokes /showme
  -> Claude reads showme.md command definition
  -> Claude reads .state/feature-state.json
  -> Claude maps stage to responsible agent
  -> Claude reads .state/inbox/<agent>.md
  -> Claude runs git diff --stat and git diff --name-only
  -> Claude reads exec plan file
  -> Claude presents formatted summary to user
```

No data is written. All flows are read-only.

### `/seed` data flow

```
User invokes /seed
  -> Claude reads seed.md command definition
  -> Claude invokes engineering-manager agent with SEED instruction
  -> EM scans codebase (package manifests, CI config, source files)
  -> EM reads target files for {{placeholder}} tokens
  -> If no placeholders remain: EM produces no-op report, stops
  -> If placeholders found: EM replaces tokens with detected values
  -> EM produces structured seed report
  -> Report relayed to user
```

No interaction with `.state/feature-state.json`. No pipeline lifecycle entry.

### `install.sh` data flow

```
User runs install.sh (curl pipe or local)
  -> Clones repo to temp dir
  -> find runs inside $TMPDIR/handoff-harness/src/ (changed from repo root)
  -> Conflict detection against $TARGET using src-relative paths
  -> Copies from $TMPDIR/handoff-harness/src/$file to $TARGET/$file
  -> src/ prefix is never in destination path (find runs inside src/)
  -> Cleanup temp dir
```

---

## 9. Interface contracts

### `/showme` command

- **Input:** None (reads state files directly)
- **Output:** Formatted markdown summary to the conversation
- **Side effects:** None (two read-only git commands)
- **Error states:** Missing/empty state file produces graceful "no active feature" message

### `/seed` command

- **Input:** None (scans codebase automatically)
- **Output:** Structured seed report to the conversation
- **Side effects:** Modifies up to 6 files to fill placeholders (CLAUDE.md, docs/CONTRIBUTING.md, docs/ARCHITECTURE.md, docs/RELIABILITY.md, hooks/pre-commit, hooks/pre-push)
- **Error states:** Fully hydrated repo produces no-op report; undetectable values flagged in report

### `install.sh`

- **External interface:** Unchanged. Same URL, same flags (`--update`), same usage pattern.
- **Internal change:** File discovery path changes from repo root to `src/` subdirectory.

---

## 10. Edge cases

| Edge case | Handling |
|-----------|----------|
| `install.sh` run on a repo that already has harness files | Brownfield detection still works -- paths from `src/` are the same as paths in target |
| `/showme` when `.state/feature-state.json` does not exist | Report "No active feature" and stop |
| `/showme` when `.state/feature-state.json` is `{}` | Report "No active feature" and stop |
| `/showme` when inbox file for current agent is missing | Note "No inbox content for this agent" |
| `/seed` on fully hydrated repo (no placeholders) | Produce no-op report, do not modify files |
| `/seed` on partially hydrated repo | Fill remaining placeholders, preserve filled ones |
| `/seed` cannot detect a value | Leave placeholder in place, flag in report |
| `src/` files diverge from top-level over time | By design -- `src/` is the clean distributable, top-level is the working copy |
| `install.sh` clones repo that doesn't have `src/` yet (old version) | Not a concern -- install.sh and src/ ship in the same commit |

---

## 11. Testing strategy

There is no test framework (per constraints). Verification is manual:

1. **`src/` structure verification:** `find src/ -type f | sort` matches the expected file tree. `diff` between `src/` copies and top-level originals confirms they match (except `src/CLAUDE.md` which has the added context note).
2. **`install.sh` verification:** Clone to temp dir, run `install.sh` in a fresh directory, verify all files appear without `src/` prefix. Run with `--update` to verify flag still works. Test brownfield by running twice.
3. **`/showme` verification:** Invoke with active feature state, verify output. Invoke with empty/missing state file, verify graceful handling.
4. **`/seed` verification:** Invoke on the handoff-harness repo itself (which has placeholders), verify detection and replacement. Invoke on a hydrated repo, verify no-op report.
5. **Top-level integrity:** After all changes, verify the existing pipeline still works by running `/kickoff` or checking that all agent/command/script paths resolve.

---

## 12. Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Forgetting a file in `src/` | Installed repos missing files | Implementation task includes a verification step that diffs `src/` against the expected manifest |
| `install.sh` breaks during transition | Users can't install | The `src/` directory and `install.sh` change ship in the same commit; `install.sh` is updated only after `src/` is fully populated |
| `/seed` overwrites user content | Data loss | Seed instruction explicitly requires placeholder-only replacement with preservation rules |
| EM agent doesn't handle SEED instruction | Seed fails or starts lifecycle | SEED instruction is self-contained in the prompt; no EM agent file changes needed. The instruction explicitly says "do NOT create a feature lifecycle entry" |
| `src/CLAUDE.md` template drifts from top-level | Installed copies missing features | Accepted by design -- documented in requirements as intentional. `src/` is the distributable template; top-level is the working copy |

---

## 13. Implementation ordering

The implementation must be sequenced so the top-level harness pipeline remains fully functional after every commit.

### Task 1: Create `src/` directory with all distributable files

- Create the entire `src/` tree as specified in Section 1
- Copy all files from their top-level locations
- Create `src/CLAUDE.md` with the added context note
- Create `.gitkeep` files in `src/.state/` skeleton
- Create `src/docs/exec-plans/` skeleton with `.gitkeep` files

**Safety:** This is purely additive. Nothing existing is modified. The top-level harness continues to work exactly as before.

**Commit message:** `Add src/ directory with distributable template files`

### Task 2: Add `/showme` and `/seed` command files

- Create `.claude/commands/showme.md` (top-level)
- Create `.claude/commands/seed.md` (top-level)
- Create `src/.claude/commands/showme.md` (identical copy)
- Create `src/.claude/commands/seed.md` (identical copy)
- Update top-level `CLAUDE.md` commands table to include the two new commands
- Update `src/CLAUDE.md` commands table to include the two new commands

**Safety:** Additive only. New command files do not affect existing commands. The CLAUDE.md table update adds rows but does not change existing content.

**Commit message:** `Add /showme and /seed commands`

### Task 3: Update `install.sh` to source from `src/`

- Modify `PACK_FILES` discovery to run `find` inside `src/`
- Modify copy loop source path to prepend `src/`
- Remove now-unnecessary exclusions (README.md, LICENSE, install.sh)

**Safety:** This is the only potentially breaking change, and it depends on Task 1 being complete. Since `src/` was populated in Task 1, the new paths resolve correctly. The old behavior (copying from root) is replaced atomically in a single commit.

**Commit message:** `Update install.sh to source distributable files from src/`

### Why this order is safe

- Task 1 is purely additive (new directory, no changes to existing files)
- Task 2 is purely additive (new files, minor table update)
- Task 3 depends on Task 1 but only modifies `install.sh` internals
- At no point is an existing file deleted or moved
- Each task can be committed independently and the repo works after each commit

---

## 14. What we are NOT building

- No symlinks between `src/` and top-level
- No automated sync mechanism between `src/` and top-level
- No test framework or automated test suite
- No changes to agent definition files
- No changes to existing command files (other than adding two new ones)
- No changes to `README.md` or `LICENSE`
- No new pipeline stages (no "seeding" stage)
- No changes to `setup.sh` at the top level
- No changes to `.claude/settings.json`
- No changes to git hooks at the top level
- No changes to runner scripts at the top level
