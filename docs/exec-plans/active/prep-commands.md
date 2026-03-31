# Execution Plan: prep-commands

## Status: Design

## Summary

Add 8 new EM-session prep commands to the harness and merge improvements from
temp/ versions of existing commands.

---

## Design

### 1. New Command Summaries

The 8 new prep commands form a sequential EM-session workflow that routes work to specialist agents. Each command covers one SDLC stage. They are copied from `temp/` with renamed filenames and updated internal cross-references.

#### prep-pm-discover.md (from temp/discover.md)

**Purpose:** Routes to the Product Manager for requirements gathering (Discovery stage).

**What it does:**
1. Invokes the engineering-manager agent to run the Discovery stage only
2. EM writes the PM inbox file; user is told to run the PM via VS Code task
3. Points to the next step in the workflow chain

**Rename references needed:**
- `Run **'/design'**` must become `Run **'/prep-pe-design'**`
- `before '/design'` must become `before '/prep-pe-design'`

#### prep-pe-design.md (from temp/design.md)

**Purpose:** Routes to the Principal Engineer for technical design (Design stage).

**What it does:**
1. Invokes the engineering-manager agent to run the Design stage only
2. EM writes the PE inbox file; user is told to run the PE via VS Code task
3. Points to the task-breakdown step

**Rename references needed:**
- `Run **'/tasks'**` must become `Run **'/prep-em-tasks'**`
- `before '/tasks'` must become `before '/prep-em-tasks'`

#### prep-em-tasks.md (from temp/tasks.md)

**Purpose:** EM breaks the approved design into discrete, implementable tasks.

**What it does:**
1. Invokes the engineering-manager agent to split the design into tasks
2. EM writes tasks to the state file and exec plan
3. Points to the implementation step

**Rename references needed:**
- `Run **'/implement'**` must become `Run **'/prep-sde-implement'**`

#### prep-sde-implement.md (from temp/implement.md)

**Purpose:** Routes to the Software Developer for one task (Implementation stage).

**What it does:**
1. Invokes the engineering-manager agent to identify the next incomplete task
2. EM writes the SDE inbox file; user is told to run the SDE via VS Code task
3. Chains to next implement, verify, or review depending on task status

**Rename references needed:**
- `run **'/implement'**` must become `run **'/prep-sde-implement'**`
- `run **'/verify'**` must become `run **'/prep-build-verify'**`
- `run **'/review'**` must become `run **'/prep-qa-review'**`
- `the EM should tell the user to run '/verify'` must become `'/prep-build-verify'`

#### prep-build-verify.md (from temp/verify.md)

**Purpose:** Routes to the Build Specialist for build and test verification.

**What it does:**
1. Invokes the engineering-manager agent to run the Verification stage
2. EM writes the build-specialist inbox file; user is told to run via VS Code task
3. Chains to implement, accept, or review depending on results

**Rename references needed:**
- `run **'/implement'**` (two occurrences) must become `run **'/prep-sde-implement'**`
- `run **'/accept'**` must become `run **'/prep-pm-accept'**`
- `run **'/review'**` must become `run **'/prep-qa-review'**`

#### prep-qa-review.md (from temp/review.md)

**Purpose:** Routes to Quality Assurance for code review.

**What it does:**
1. Invokes the engineering-manager agent to run the Review stage
2. EM writes the QA inbox file; user is told to run via VS Code task
3. Chains to done, implement, or discussion depending on verdict

**Rename references needed:**
- `run '/done'` must become `run '/prep-em-done'`
- `run '/implement'` must become `run '/prep-sde-implement'`
- `after '/verify'` must become `after '/prep-build-verify'`
- `before '/done'` must become `before '/prep-em-done'`

#### prep-pm-accept.md (from temp/accept.md)

**Purpose:** Routes to the Product Manager for acceptance testing against criteria.

**What it does:**
1. Invokes the engineering-manager agent to run the Acceptance stage
2. EM confirms all tasks are complete, writes the PM inbox file
3. Chains to done or implement depending on results

**Rename references needed:**
- `run **'/done'**` must become `run **'/prep-em-done'**`
- `run **'/implement'**` must become `run **'/prep-sde-implement'**`

#### prep-em-done.md (from temp/done.md)

**Purpose:** Closes out the feature -- commit, push, create PR, optional release tag.

**What it does:**
1. Invokes the engineering-manager to mark feature complete, archive exec plan, reset state
2. Automatically runs commit + push + PR creation flow
3. Offers optional release tagging
4. Points to `/kickoff` to start the next feature

**Rename references needed:**
- `after '/accept'` must become `after '/prep-pm-accept'`
- The `/kickoff` reference on the "when done" line is correct as-is (kickoff retains its name)

---

### 2. Existing Command Diff Analysis

#### kickoff.md

**Existing version:** 17 lines. Describes a 5-step workflow: check overlapping plans, check tech debt, collect structured input from user, normalize into Execution Brief, invoke the EM.

**Temp version:** 30 lines. Completely different structure. Rewritten as an EM-session routing command that bootstraps a new feature, initializes state, and points to `/discover` as the next step. Includes `$ARGUMENTS` handling and explicit rules about not chaining stages.

**Analysis:** The temp version is a full rewrite. It transforms kickoff from a procedural checklist into a routing command consistent with the new prep-command workflow. The existing version's value (checking for overlapping plans, tech debt, structured intake) is useful but could be handled by the EM agent internally.

**Recommendation:** MERGE -- adopt the temp version's structure. Preserve the existing version's checklist items (check overlapping plans, check tech debt tracker) by incorporating them into the EM instruction block. The temp version's reference to `/discover` must become `/prep-pm-discover`.

#### commit-only.md

**Existing version:** 17 lines. Title "Commit Only". Uses heading format.

**Temp version:** 20 lines. Title line reads "Safely stage and commit without pushing. All quality gates enforced." Content is functionally identical.

**Recommendation:** MERGE -- adopt the temp version. The more descriptive title line is an improvement. Body content is the same.

#### commit-and-push.md

**Existing version:** 18 lines. Title "Commit And Push". Uses heading format.

**Temp version:** 21 lines. Title line reads "Safely commit and push to origin with all quality gates enforced." Content is functionally identical.

**Recommendation:** MERGE -- adopt the temp version. Same rationale as commit-only.

#### seed.md

**Existing version:** 116 lines. Comprehensive onboarding command with detailed EM instruction block covering scan, check, fill-in, and report steps. Includes extensive placeholder token list and preservation rules.

**Temp version:** 138 lines. Same overall structure, reorganized with lettered steps (A-E) instead of numbered steps. Adds more detection source examples and a structured report format with confidence/source table.

**Analysis:** The two versions are functionally equivalent. The existing version already contains all substantive features (no-op detection, placeholder list, preservation rules, structured report). Differences are cosmetic/organizational.

**Recommendation:** KEEP EXISTING -- no changes needed. The existing version is already comprehensive and its numbered-step structure inside the EM instruction is slightly clearer.

#### run-build.md

**Existing version:** 7 lines. Title "Run Build Specialist". Checks inbox, runs script.

**Temp version:** 7 lines. Adds context line: "Use this in Session 2 (specialist workbench) after the EM has routed work via `/verify` in Session 1."

**Recommendation:** MERGE -- adopt temp version. The added context about which Session 1 command prepares the inbox is helpful. The `/verify` reference must become `/prep-build-verify`.

#### run-pe.md

**Existing version:** 7 lines. Title "Run Principal Engineer". Checks inbox, runs script.

**Temp version:** 7 lines. Adds context: "after the EM has routed work via `/design` in Session 1."

**Recommendation:** MERGE -- adopt temp version. The `/design` reference must become `/prep-pe-design`.

#### run-pm.md

**Existing version:** 7 lines. Title "Run Product Manager". Checks inbox, runs script.

**Temp version:** 7 lines. Adds context: "after the EM has routed work via `/discover` or `/accept` in Session 1."

**Recommendation:** MERGE -- adopt temp version. References must become `/prep-pm-discover` and `/prep-pm-accept`.

#### run-qa.md

**Existing version:** 7 lines. Title "Run Quality Assurance". Checks inbox, runs script.

**Temp version:** 7 lines. Adds context: "after the EM has routed work via `/review` in Session 1."

**Recommendation:** MERGE -- adopt temp version. The `/review` reference must become `/prep-qa-review`.

#### run-sde.md

**Existing version:** 7 lines. Title "Run Software Developer". Checks inbox, runs script.

**Temp version:** 7 lines. Adds context: "after the EM has routed work via `/implement` in Session 1."

**Recommendation:** MERGE -- adopt temp version. The `/implement` reference must become `/prep-sde-implement`.

#### showme.md (naming convention fix)

**Issue:** All other commands use hyphens in multi-word names (e.g., `commit-and-push`, `run-build`, `kickoff-complex`). `showme.md` breaks this convention.

**Recommendation:** RENAME to `show-me.md` in both `.claude/commands/` and `src/.claude/commands/`. Update all references in CLAUDE.md command tables and any other files that mention `/showme`. No content changes needed -- only the filename and references change.

---

### 3. CLAUDE.md Table Updates

Both `/home/coder/projects/handoff-harness/CLAUDE.md` and `/home/coder/projects/handoff-harness/src/CLAUDE.md` contain a Commands table under `### Commands`. The following 8 rows must be added after the existing `/seed` row:

```
| `/prep-pm-discover` | Prep Discovery -- route to Product Manager |
| `/prep-pe-design` | Prep Design -- route to Principal Engineer |
| `/prep-em-tasks` | Prep Tasks -- EM breaks design into tasks |
| `/prep-sde-implement` | Prep Implementation -- route to Software Developer |
| `/prep-build-verify` | Prep Verification -- route to Build Specialist |
| `/prep-qa-review` | Prep Review -- route to Quality Assurance |
| `/prep-pm-accept` | Prep Acceptance -- route to Product Manager |
| `/prep-em-done` | Close feature -- commit, push, PR, optional release |
```

One existing row needs modification: `/showme` must be renamed to `/show-me` to match the hyphenated naming convention used by all other commands.

Both CLAUDE.md files must remain consistent (they currently have identical command tables). The root CLAUDE.md has a comment `<!-- Fill these in after hydration -->` in the project-specific section that `src/CLAUDE.md` does not; this pre-existing difference is unrelated to this feature and should be left as-is.

---

### 4. install.sh Verification

The `get_category()` function in `install.sh` (lines 27-48) contains:

```
.claude/commands/*)    echo "harness-owned" ;;
```

This glob matches all files under `.claude/commands/` regardless of filename prefix. The new `prep-*.md` files will match this pattern and be categorized as `harness-owned`, meaning they are overwritten from source on update with no merge/sidecar logic.

**Verdict:** No changes needed to `install.sh`. The existing glob covers the new files correctly.

---

### 5. Ordered Task Breakdown

Each task is scoped for a single SDE agent session.

#### Task 1: Add the 8 new prep commands

**Files created (16 total -- 8 pairs):**
- `.claude/commands/prep-pm-discover.md` + `src/.claude/commands/prep-pm-discover.md`
- `.claude/commands/prep-pe-design.md` + `src/.claude/commands/prep-pe-design.md`
- `.claude/commands/prep-em-tasks.md` + `src/.claude/commands/prep-em-tasks.md`
- `.claude/commands/prep-sde-implement.md` + `src/.claude/commands/prep-sde-implement.md`
- `.claude/commands/prep-build-verify.md` + `src/.claude/commands/prep-build-verify.md`
- `.claude/commands/prep-qa-review.md` + `src/.claude/commands/prep-qa-review.md`
- `.claude/commands/prep-pm-accept.md` + `src/.claude/commands/prep-pm-accept.md`
- `.claude/commands/prep-em-done.md` + `src/.claude/commands/prep-em-done.md`

**Work:**
- For each of the 8 temp files, copy content to the target filename
- Update all internal cross-references from short names to prep-prefixed names (see Section 1 for the complete reference map)
- Write identical content to both `.claude/commands/` and `src/.claude/commands/`
- Verify byte-identical copies between the two directories

**Definition of done:** All 8 files exist in both directories with correct names, all internal references use the new `prep-*` names, files are byte-identical across directories.

#### Task 2: Merge temp improvements into existing commands

**Files modified (16 total -- 8 pairs, seed.md excluded):**
- `.claude/commands/kickoff.md` + `src/.claude/commands/kickoff.md`
- `.claude/commands/commit-only.md` + `src/.claude/commands/commit-only.md`
- `.claude/commands/commit-and-push.md` + `src/.claude/commands/commit-and-push.md`
- `.claude/commands/run-build.md` + `src/.claude/commands/run-build.md`
- `.claude/commands/run-pe.md` + `src/.claude/commands/run-pe.md`
- `.claude/commands/run-pm.md` + `src/.claude/commands/run-pm.md`
- `.claude/commands/run-qa.md` + `src/.claude/commands/run-qa.md`
- `.claude/commands/run-sde.md` + `src/.claude/commands/run-sde.md`

**Work:**
- kickoff.md: Adopt temp version structure, incorporate existing checklist items (overlapping plan check, tech debt check) into the EM instruction, update `/discover` to `/prep-pm-discover`
- commit-only.md: Replace with temp version (descriptive title)
- commit-and-push.md: Replace with temp version (descriptive title)
- seed.md: No changes (keep existing)
- run-build.md: Replace with temp version, update `/verify` to `/prep-build-verify`
- run-pe.md: Replace with temp version, update `/design` to `/prep-pe-design`
- run-pm.md: Replace with temp version, update `/discover` to `/prep-pm-discover`, `/accept` to `/prep-pm-accept`
- run-qa.md: Replace with temp version, update `/review` to `/prep-qa-review`
- run-sde.md: Replace with temp version, update `/implement` to `/prep-sde-implement`
- Write identical content to both directories
- Verify byte-identical copies

Additionally, rename `showme.md` to `show-me.md`:
- Rename `.claude/commands/showme.md` to `.claude/commands/show-me.md`
- Rename `src/.claude/commands/showme.md` to `src/.claude/commands/show-me.md`
- Content is unchanged; only the filename changes

**Definition of done:** All 8 commands are updated, seed.md is confirmed unchanged, all cross-references use prep-prefixed names, byte-identical copies maintained. `showme.md` has been renamed to `show-me.md` in both directories. `kickoff-complex.md` is untouched.

#### Task 3: Update CLAUDE.md command tables

**Files modified (2):**
- `CLAUDE.md`
- `src/CLAUDE.md`

**Work:**
- Add the 8 new prep command rows to the Commands table in both files (see Section 3 for exact rows)
- Rename the existing `/showme` row to `/show-me` in both files
- Verify table formatting is consistent with existing rows

**Definition of done:** Both CLAUDE.md files contain all 8 new rows, the `/showme` row has been renamed to `/show-me`, tables render correctly in markdown.

#### Task 4: Delete temp/ folder and final verification

**Work:**
- Delete the entire `temp/` directory
- Verify all 19 command files (11 existing + 8 new) exist in `.claude/commands/`
- Verify all 19 command files exist in `src/.claude/commands/`
- Verify byte-identical invariant holds for every file
- Grep for stale short-name command references (backtick-quoted `/discover`, `/design`, `/tasks`, `/implement`, `/verify`, `/review`, `/accept`, `/done`, `/showme`) across both command directories and CLAUDE.md files -- confirm none remain as command invocation references
- Confirm `show-me.md` exists and `showme.md` does not exist in either directory
- Confirm `kickoff-complex.md` is unmodified

**Definition of done:** `temp/` directory deleted, all commands present in both directories, byte-identical invariant holds, no stale command references, `show-me.md` present (old `showme.md` removed), `kickoff-complex.md` confirmed unmodified.

---

### 6. Risks and Edge Cases

#### Cross-reference consistency

The new prep commands form a workflow chain where each command's "Next step" section points to the next command. If any reference is missed during renaming, the user will be told to run a command that does not exist (e.g., `/design` instead of `/prep-pe-design`).

**Mitigation:** After Tasks 1 and 2, grep both `.claude/commands/` and `src/.claude/commands/` for bare short names in command-reference context (backtick-quoted like `` `/design` ``) to confirm none remain. Be careful not to false-positive on descriptive text like "Run the Discovery stage" -- only flag patterns that look like command invocations.

#### Byte-identical invariant

Every file in `.claude/commands/` must have a byte-identical copy in `src/.claude/commands/`. If any task updates one directory but not the other, the invariant is broken.

**Mitigation:** Each task's definition of done includes the byte-identical check. The SDE should write content to one directory then copy to the other, rather than editing each independently.

#### kickoff.md merge complexity

The temp version of kickoff.md is a complete rewrite, not an incremental diff. The existing version's checklist items (check overlapping plans, check tech debt) must be preserved in the new structure.

**Mitigation:** The SDE should incorporate the existing checklist as a sub-list inside the EM instruction block of the temp version's structure. These are important safeguards.

#### Stale references in other project files

Files outside `.claude/commands/` might reference the short command names. For example, this exec plan, agent definitions, or other documentation.

**Mitigation:** The prep commands are NEW commands that did not previously exist, so no external files reference them yet. The existing commands keep their existing names. This risk is minimal.

#### showme.md rename to show-me.md

The filename `showme.md` breaks the hyphenated naming convention used by all other multi-word commands. It must be renamed to `show-me.md` in both directories, and all references in CLAUDE.md tables updated from `/showme` to `/show-me`.

**Mitigation:** Task 2 handles the file rename. Task 3 handles the CLAUDE.md table update. Task 4 verifies that `showme.md` no longer exists and `show-me.md` is present in both directories. Grep for stale `/showme` references in Task 4.

#### kickoff-complex.md must not be touched

This existing command has no temp counterpart and must remain unmodified.

**Mitigation:** Explicitly excluded from all tasks. Task 4 includes a verification step to confirm it is unmodified.

#### seed.md must not be overwritten

The design recommends keeping the existing seed.md. The SDE must not accidentally replace it with the temp version.

**Mitigation:** Task 2 explicitly lists seed.md as "no changes needed" and excludes it from the modified files list.

---

## Scope Boundaries -- What We Are NOT Building

- No new agent definitions (`.claude/agents/` is unchanged)
- No changes to `install.sh`
- `showme.md` is renamed to `show-me.md` (filename only, content unchanged); `kickoff-complex.md` is unchanged
- No changes to shell scripts in `scripts/`
- No changes to `.state/` files beyond normal pipeline operation
- No changes to `docs/ARCHITECTURE.md`, `docs/CONTRIBUTING.md`, or `docs/RELIABILITY.md`
- No new VS Code task definitions
- No changes to hooks
