# Onboard the agent framework into this repository.

One-shot onboarding command that auto-detects project configuration and fills in template placeholders.

## Rules

- **EDIT-ONLY RULE: The agent MUST use the Edit tool (not the Write tool) for every placeholder replacement in any file that already contains non-placeholder content. Using the Write tool on such a file is explicitly prohibited. The Edit tool replaces only the matched token and preserves all surrounding content exactly. This rule applies to every file touched during Phase 4.**
- NO-TOUCH LIST -- these files must NEVER be modified by the seed command, even if they contain `{{` placeholder tokens:
  - `docs/exec-plans/tech-debt-tracker.md`
  - `QUALITY_SCORE.md` (matches `docs/QUALITY_SCORE.md` and `src/docs/QUALITY_SCORE.md`)
  - `AGENTS.md` (matches `docs/AGENTS.md` and `src/docs/AGENTS.md`)

  The matching rule is suffix-based: if the target file path ends with any entry in the no-touch list, skip it. Files skipped due to the no-touch list do NOT count toward the "all placeholders filled" no-op determination.
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

   Phases are executed in numerical order: 0, 1, 2, 3, 4, 5, 6, 7.

   --- SCAN ---

   Before the phases begin, scan the codebase to auto-detect:
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

   --- PHASE 0: DRY-RUN GATE ---

   If the user's invocation includes `--dry-run`, the agent enters dry-run mode.
   In dry-run mode:
      - Run the SCAN and Phase 1 (pre-flight) normally to identify target files
        and placeholders.
      - Run Phase 2 (file classification) normally.
      - Then show each planned replacement (file, token, proposed value) WITHOUT
        writing anything.
      - Identify all files that would be skipped (no-touch list, no placeholders found).
      - Produce a **Dry-Run Summary** report (see dry-run report format below) and STOP.
        No files are created, modified, or backed up.
   If `--dry-run` is NOT present, proceed to Phase 1 normally.

   --- PHASE 1: PRE-FLIGHT SCAN ---

   For each target file in this list:
      - CLAUDE.md
      - docs/CONTRIBUTING.md
      - docs/ARCHITECTURE.md
      - docs/RELIABILITY.md
      - hooks/pre-commit
      - hooks/pre-push

   Apply the following checks in order:

   1a. NO-TOUCH CHECK: Check if the file path ends with any entry in the no-touch list
       (docs/exec-plans/tech-debt-tracker.md, QUALITY_SCORE.md, AGENTS.md).
       If it matches, skip the file. Record the file and reason ("on no-touch list")
       for the "Skipped (no-touch list)" section of the report. Do NOT process further.

   1b. PLACEHOLDER CHECK: Grep the file for `{{` tokens.
       If NO `{{` tokens are found, skip the file. Record the file and reason
       ("no {{ tokens found") for the "Skipped (no placeholders)" section of the report.
       Do NOT process further.

   1c. Build the list of files that will be processed (passed both checks).

   IMPORTANT: CLAUDE.md almost always contains placeholder tokens in its
   "Project-specific configuration" section (e.g., {{LANGUAGE}}, {{BUILD_CMD}},
   {{TEST_CMD}}, {{LINT_CMD}}, {{FORMAT_CMD}}). If your grep reports zero
   matches for CLAUDE.md, re-read the file and search again — a false negative
   here means the entire file will be silently skipped.

   NO-OP DETERMINATION: If ALL non-no-touch-list target files have no `{{` tokens
   (i.e., the list from step 1c is empty), produce a NO-OP REPORT:
      - State that all placeholders are already filled.
      - Summarize the current detected values for each field.
      - Offer to re-scan if the user wants to update values.
      - Do NOT modify any files.
      - STOP here.

   --- PHASE 2: FILE CLASSIFICATION ---

   For each target file that passed Phase 1 checks, classify it as:
      - **Greenfield:** File contains only placeholder tokens and structural skeleton
        text (headings, empty tables). No substantive authored content.
      - **Brownfield:** File contains authored content beyond placeholders.

   Classification criteria: if ANY content beyond Markdown headings, empty table
   skeletons, HTML comments, and placeholder tokens exists, classify as brownfield.
   Default to brownfield when uncertain.

   For brownfield files, the agent must operate in **additive-only mode** during
   Phase 4: replace placeholder tokens but must NOT alter, reorder, or remove any
   surrounding authored content.

   For greenfield files, proceed normally during Phase 4.

   Record the classification for each file. This feeds into the **File Classifications**
   report section.

   --- PHASE 3: BACKUP BEFORE WRITE ---

   Before any file is modified during a live (non-dry-run) seed operation, copy the
   original file to `<original-filename>.pre-seed.bak` in the same directory.
   Example: before modifying `docs/CONTRIBUTING.md`, copy it to
   `docs/CONTRIBUTING.md.pre-seed.bak`.

   If a `.pre-seed.bak` file already exists for that file, do NOT overwrite it.
   The oldest backup is preserved.

   Record all backup files created. This feeds into the **Backups Created** report section.

   --- PHASE 4: REPLACEMENT ---

   REMINDER: The EDIT-ONLY RULE applies here. For every placeholder replacement,
   use the Edit tool. Do NOT use the Write tool on any file that already contains
   non-placeholder content. Violating this rule risks destroying user-written content.

   For each file that passed Phase 1 checks, replace placeholder tokens with detected
   values using the Edit tool:
      - {{PROJECT_DESCRIPTION}} -> 1-3 sentence description of the project's tech stack and purpose, derived from detected language/framework and repo structure
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

   --- PHASE 5: PER-REPLACEMENT VERIFICATION LOGGING ---

   After each individual replacement made during Phase 4, record a confirmation entry
   containing:
      - The file path
      - The placeholder token that was replaced
      - The new value that was substituted
      - An explicit statement that no surrounding content was modified

   These records feed into the "Replacements Made" table in the seed report.

   --- PHASE 6: HARNESS MANIFEST ---

   Read `.harness/version`. If it does not exist, create it with content `1.0.0`.

   Create (or update if it exists) `.harness/manifest.json` with these required fields:

   | Field | Type | Description |
   |-------|------|-------------|
   | `harness_version` | string | Value read from `.harness/version` |
   | `seeded_at` | ISO 8601 datetime | Timestamp of the current seed run |
   | `seed_history` | array of objects | Log of past seed runs; each entry has `timestamp` (ISO 8601) and `files_modified` (array of file paths) |
   | `installed_agents` | array of strings | Stem names (no `.md`) of agent files in `.claude/agents/` |
   | `installed_commands` | array of strings | Stem names (no `.md`) of command files in `.claude/commands/` |

   Arrays sorted alphabetically.

   If `.harness/manifest.json` already exists, read it first, preserve existing
   `seed_history` entries, and append a new entry for the current run. Update
   `seeded_at` to current timestamp.

   If it does not exist, create it fresh with a single entry in `seed_history`.

   --- PHASE 7: POST-SEED VALIDATION ---

   After all replacements and manifest creation, run a validation pass over all
   files that were modified during this seed run.

   Validation checks:
      1. No `{{` tokens remain in any modified file (no orphaned placeholders).
      2. For `.md` files: check for unclosed code fences and malformed table rows.
      3. For shell files (e.g., hooks/pre-commit, hooks/pre-push): check that the
         file is non-empty and contains no `{{` tokens.

   Record a pass/fail result per file. This feeds into the **Validation Results**
   report section.

   Any file containing a remaining `{{` token MUST be flagged as a failure.

   --- REPORT ---

   After all phases complete, produce a structured seed report with these sections
   in this order:

      ## Seed Report

      ### Detected Configuration
      | Field | Value | Confidence | Source |
      |-------|-------|------------|--------|
      (one row per detected value, with the file/signal that informed the detection)

      ### Skipped (no-touch list)
      - `<file path>` -- on no-touch list
      (one entry per file skipped due to the no-touch list; omit section if none)

      ### Skipped (no placeholders)
      - `<file path>` -- no {{ tokens found
      (one entry per file skipped because no {{ tokens were found; omit section if none)

      ### File Classifications
      | File | Classification | Mode |
      |------|---------------|------|
      | docs/CONTRIBUTING.md | brownfield | additive-only |
      | docs/ARCHITECTURE.md | greenfield | normal |
      (one row per file that passed Phase 1 checks)

      ### Backups Created
      - `docs/CONTRIBUTING.md.pre-seed.bak`
      - `docs/ARCHITECTURE.md.pre-seed.bak`
      (list of backup file paths created during Phase 3; or "No backups needed." if none)

      ### Replacements Made
      | File | Token | New Value | Content Integrity |
      |------|-------|-----------|-------------------|
      | docs/CONTRIBUTING.md | {{LANGUAGE}} | Markdown/Shell | No surrounding content was modified |
      (one row per individual replacement made during Phase 4)

      ### Unresolved Placeholders
      - List any placeholders that could NOT be auto-detected
      - For each, explain why and suggest how the user can fill it manually

      ### Validation Results
      | File | Status | Details |
      |------|--------|---------|
      | docs/CONTRIBUTING.md | PASS | No orphaned placeholders, valid Markdown |
      | hooks/pre-commit | PASS | Non-empty, no {{ tokens |
      (one row per modified file; FAIL rows include what check failed)

      ### Recommendations
      - Any additional setup steps the user should take

   --- DRY-RUN REPORT FORMAT ---

   When running in dry-run mode (Phase 0), produce this report instead of the
   live report above:

      ## Seed Report (DRY RUN -- no files modified)

      ### Detected Configuration
      (same as live run)

      ### Skipped (no-touch list)
      (same as live run)

      ### Skipped (no placeholders)
      (same as live run)

      ### File Classifications
      (same as live run)

      ### Planned Replacements
      | File | Token | Proposed Value |
      |------|-------|---------------|
      (one row per replacement that WOULD be made)

      ### Unresolved Placeholders
      (same as live run)

   No "Backups Created", "Replacements Made", or "Validation Results" sections
   in dry-run mode.

   STOP. Do not proceed to any pipeline stage.
   ```

2. Present the seed report to the user.
3. If the engineering-manager reports a no-op (all placeholders filled), relay that to the user and offer to re-run with `--force` semantics (re-scan and update).
