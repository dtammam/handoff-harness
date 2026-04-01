# Exec Plan: readme-improvements

## Goal

Improve the README by moving screenshots from `temp/` to a permanent `docs/assets/` location, embedding them with appropriate captions, and syncing the command table with the full set of commands documented in `CLAUDE.md`.

---

## Scope

**In scope:**
- Move all nine screenshot files from `temp/` to `docs/assets/`
- Embed screenshots in README with descriptive alt text and captions
- Sync the README commands table with the full command list from `CLAUDE.md`
- Update the Mobile Workflow section to reference current command names
- Ensure no path in the final README points to `temp/`

**Out of scope:**
- Changes to `CLAUDE.md` itself
- Changes to any agent or command definition files
- Changes to directory structure outside of `docs/assets/` and the README
- Generating new screenshots or editing existing screenshot content

---

## Requirements

1. A `docs/assets/` directory must exist and contain all nine screenshots currently stored in `temp/`: `discover.png`, `kickoff.png`, `post-run-pm.png`, `prep-pm-discover.png`, `run-pm.png`, `scripts.png`, `seed.png`, `blank.png`, and `one-liner.png`.

2. The `temp/` directory must not be referenced anywhere in `README.md` after the change.

3. Each screenshot embedded in `README.md` must use a relative path under `docs/assets/` and must include descriptive alt text that identifies what the screenshot depicts.

4. The README commands table must contain every command listed in `CLAUDE.md`, including the commands currently missing from the README:
   - `/show-me`
   - `/seed`
   - `/prep-pm-discover`
   - `/prep-pe-design`
   - `/prep-em-tasks`
   - `/prep-sde-implement`
   - `/prep-build-verify`
   - `/prep-qa-review`
   - `/prep-pm-accept`
   - `/prep-em-done`

5. The README commands table must preserve all commands already present in the current README.

6. The Mobile Workflow section must accurately reflect how the two-session workflow operates, using command names that match what is currently in `CLAUDE.md` (e.g., referencing `/prep-*` pipeline commands rather than placeholder names like `/discover` or `/design`).

7. Screenshots must be grouped and placed in a logical section of the README (for example, a "Walkthrough" or "Screenshots" section) so they read as a coherent visual narrative of the workflow, not as isolated images.

8. Each screenshot must have a one-sentence caption (as plain text or an HTML comment, at implementor discretion) describing what is shown.

---

## Acceptance Criteria

AC-1. Running `find docs/assets -name "*.png" | sort` returns all nine expected filenames: `blank.png`, `discover.png`, `kickoff.png`, `one-liner.png`, `post-run-pm.png`, `prep-pm-discover.png`, `run-pm.png`, `scripts.png`, `seed.png`.

AC-2. Running `grep -i "temp/" README.md` returns no matches.

AC-3. Running `grep -c "docs/assets/" README.md` returns a count of at least 9 (one image reference per screenshot).

AC-4. Every command in the `CLAUDE.md` commands table also appears in the `README.md` commands table. Verified by checking each of the 19 command names listed in `CLAUDE.md` against `README.md`.

AC-5. The README commands table retains all commands from the current README (nine commands: `/kickoff`, `/kickoff-complex`, `/commit-only`, `/commit-and-push`, `/run-pm`, `/run-pe`, `/run-sde`, `/run-build`, `/run-qa`).

AC-6. The Mobile Workflow section in `README.md` references `/prep-*` commands (or accurately describes the prep command workflow) and does not reference outdated command names such as `/discover` or `/design` that no longer exist.

AC-7. Each `![...]` image tag in `README.md` has non-empty alt text.

AC-8. The README renders without broken image links when viewed from the repository root (i.e., all image paths resolve correctly relative to `README.md`).

---

## Constraints

- Do not delete the `temp/` directory itself -- only its contents are being relocated. (The `temp/` directory may be gitignored or used for other ephemeral purposes; that is outside this feature's scope.)
- Screenshot files must be copied or moved, not re-created or modified.
- No changes to any file outside `README.md` and `docs/assets/` (plus the file moves from `temp/`).
- The README must remain valid Markdown throughout.

---

## Open Questions

None. Requirements are sufficiently clear to proceed to design.

---

## Screenshot Inventory and Proposed Captions

Based on visual review of each file:

| File | Depicts | Proposed caption |
|------|---------|-----------------|
| `blank.png` | A fresh Claude Code workspace with only a `README.md` in the file tree and an open bash terminal -- the starting state before installation | "A blank project workspace before handoff-harness is installed." |
| `one-liner.png` | Terminal output of the `curl ... install.sh \| bash` one-liner running successfully, showing 58 files hydrated and next-step instructions | "Running the one-liner installer to hydrate a greenfield repo." |
| `scripts.png` | Terminal output of `setup.sh` verifying directory structure and marking hooks/scripts executable, ending with a prompt to run `/seed` | "Running `setup.sh` to wire git hooks and verify directory structure." |
| `seed.png` | A Claude Code session running `/seed`, showing the engineering-manager scanning the codebase and filling in placeholder values across config files | "Running `/seed` to auto-detect the tech stack and fill configuration placeholders." |
| `kickoff.png` | A Claude Code session running `/kickoff` with the engineering-manager bootstrapping a new feature (feature-state.json created, stage set to discovery) | "Using `/kickoff` to start a new feature -- the EM creates the feature state and routes to discovery." |
| `discover.png` | The same session after `/kickoff` completes, showing the EM's summary and a `/prep-pm-discover` command being typed in the input box | "After kickoff, the EM summarizes next steps and prompts the user to run `/prep-pm-discover`." |
| `prep-pm-discover.png` | A Claude Code session executing `/prep-pm-discover`, showing the engineering-manager writing the PM's inbox file and updating feature state | "Running `/prep-pm-discover` to prepare the product-manager inbox for the Discovery stage." |
| `run-pm.png` | A second Claude Code session (the specialist workbench) showing `/run-pm` in the command palette alongside `/run-pe` | "In the specialist session, `/run-pm` invokes the product-manager agent to run Discovery." |
| `post-run-pm.png` | The result after the product-manager agent has completed Discovery -- requirements document produced, acceptance criteria written, open questions listed, next-step guidance shown | "The product-manager agent completes Discovery and presents requirements and acceptance criteria for user approval." |

---

## Stage

- **Requested:** 2026-04-01
- **Discovery complete:** 2026-04-01
- **Design complete:** 2026-04-01
- **Done:** 2026-04-01

---

## Technical Design

### 1. Approach

This is a documentation-only change. No application code, agent definitions, or command files are modified. The work has three parts:

1. **File relocation:** Create `docs/assets/` and move nine PNG files from `temp/` into it.
2. **README restructuring:** Add a "Walkthrough" section with screenshots embedded as a narrative, expand the commands table from 9 to 19 rows, and fix the Mobile Workflow section.
3. **Verification:** Confirm all acceptance criteria pass (path correctness, image rendering, command completeness).

### 2. Directory Changes

#### Create directory

```
docs/assets/
```

This directory does not currently exist. The developer must create it before moving files.

#### Move files (not copy)

Move each of the following from `temp/` to `docs/assets/`:

| Source | Destination |
|--------|-------------|
| `temp/blank.png` | `docs/assets/blank.png` |
| `temp/one-liner.png` | `docs/assets/one-liner.png` |
| `temp/scripts.png` | `docs/assets/scripts.png` |
| `temp/seed.png` | `docs/assets/seed.png` |
| `temp/kickoff.png` | `docs/assets/kickoff.png` |
| `temp/discover.png` | `docs/assets/discover.png` |
| `temp/prep-pm-discover.png` | `docs/assets/prep-pm-discover.png` |
| `temp/run-pm.png` | `docs/assets/run-pm.png` |
| `temp/post-run-pm.png` | `docs/assets/post-run-pm.png` |

**Do NOT delete the `temp/` directory itself.** It is gitignored and may serve other purposes.

### 3. README Structure (Proposed Section Order)

The updated `README.md` must have the following top-level sections in this order. Sections marked with "(unchanged)" retain their current content. Sections marked with "(modified)" or "(new)" are described in detail below.

```
# handoff-harness
(intro paragraph -- unchanged)

## Architecture
(unchanged)

## Agents
(unchanged)

## Coordination
(unchanged)

## Commands
(modified -- expanded from 9 to 19 rows, grouped logically)

## Walkthrough
(new -- screenshots woven into narrative steps)

## Installation
(unchanged)

## Directory Structure
(unchanged)

## Mobile Workflow (Happy Coder)
(modified -- corrected command references)

## License
(unchanged)
```

**Rationale for Walkthrough placement:** It sits after Commands (so the reader knows what commands exist) and before Installation (so the reader sees the workflow before diving into setup details). This puts the visual narrative in a prominent position without displacing reference material.

### 4. Walkthrough Section Design

The Walkthrough section tells the story of going from a blank project to completing the first pipeline stage. It uses nine steps, each with:

- A `###` subheading naming the step
- One to two sentences of narrative context
- A Markdown image tag with descriptive alt text
- A caption in italics on the line below the image

**Image path format:** All image references must use paths relative to the repository root, since `README.md` lives at the root. The format is:

```markdown
![Alt text describing the screenshot](docs/assets/filename.png)
```

**Step-by-step design:**

#### Step 1: Starting Point
- **Heading:** `### 1. A blank workspace`
- **Narrative:** "Start with a fresh project directory. All you need is a repo with a README."
- **Image:** `![A fresh Claude Code workspace with an empty file tree and terminal](docs/assets/blank.png)`
- **Caption:** *A blank project workspace before handoff-harness is installed.*

#### Step 2: Run the Installer
- **Heading:** `### 2. Run the one-liner installer`
- **Narrative:** "Run the curl installer to hydrate the repo with agents, commands, hooks, and state files."
- **Image:** `![Terminal output showing the curl installer hydrating 58 files into the project](docs/assets/one-liner.png)`
- **Caption:** *Running the one-liner installer to hydrate a greenfield repo.*

#### Step 3: Run Setup
- **Heading:** `### 3. Run setup`
- **Narrative:** "Execute `setup.sh` to verify the directory structure and wire git hooks."
- **Image:** `![Terminal output of setup.sh verifying directories and setting permissions](docs/assets/scripts.png)`
- **Caption:** *Running `setup.sh` to wire git hooks and verify directory structure.*

#### Step 4: Seed the Project
- **Heading:** `### 4. Seed the project`
- **Narrative:** "Use the `/seed` command to auto-detect your tech stack and fill in configuration placeholders across all config files."
- **Image:** `![Claude Code session running /seed, showing the engineering-manager scanning and filling placeholders](docs/assets/seed.png)`
- **Caption:** *Running `/seed` to auto-detect the tech stack and fill configuration placeholders.*

#### Step 5: Kick Off a Feature
- **Heading:** `### 5. Kick off a feature`
- **Narrative:** "Use `/kickoff` to start a new feature. The engineering-manager creates the feature state and routes to the discovery stage."
- **Image:** `![Claude Code session running /kickoff to bootstrap a new feature](docs/assets/kickoff.png)`
- **Caption:** *Using `/kickoff` to start a new feature -- the EM creates the feature state and routes to discovery.*

#### Step 6: Prepare for Discovery
- **Heading:** `### 6. Prepare for discovery`
- **Narrative:** "After kickoff, the EM summarizes what happens next. Run `/prep-pm-discover` to prepare the product-manager's inbox for the Discovery stage."
- **Image:** `![The EM's post-kickoff summary with /prep-pm-discover being typed](docs/assets/discover.png)`
- **Caption:** *After kickoff, the EM summarizes next steps and prompts the user to run `/prep-pm-discover`.*

#### Step 7: Run the Prep Command
- **Heading:** `### 7. Run the prep command`
- **Narrative:** "Running `/prep-pm-discover` writes the product-manager's inbox file and advances the pipeline state."
- **Image:** `![Claude Code session executing /prep-pm-discover, writing the PM inbox file](docs/assets/prep-pm-discover.png)`
- **Caption:** *Running `/prep-pm-discover` to prepare the product-manager inbox for the Discovery stage.*

#### Step 8: Invoke the Specialist
- **Heading:** `### 8. Invoke the specialist`
- **Narrative:** "Switch to the specialist session and run `/run-pm` to invoke the product-manager agent."
- **Image:** `![The specialist session showing /run-pm in the command palette](docs/assets/run-pm.png)`
- **Caption:** *In the specialist session, `/run-pm` invokes the product-manager agent to run Discovery.*

#### Step 9: Discovery Complete
- **Heading:** `### 9. Discovery complete`
- **Narrative:** "The product-manager agent reads its inbox, runs Discovery, and presents requirements and acceptance criteria for user approval."
- **Image:** `![Product-manager agent output showing completed requirements and acceptance criteria](docs/assets/post-run-pm.png)`
- **Caption:** *The product-manager agent completes Discovery and presents requirements and acceptance criteria for user approval.*

### 5. Commands Table Design

The updated commands table must contain all 19 commands from `CLAUDE.md`, organized into logical groups using row separators (blank table rows are not valid Markdown, so grouping is achieved by ordering alone, with a comment or note above the table explaining the groups). The table keeps the three-column format from the current README (`Command | File | Purpose`) since the file paths are useful reference.

**Complete table contents (19 rows):**

```markdown
## Commands

Commands are organized into four groups: intake, commit, specialist invocation, and pipeline prep/utility.

| Command | File | Purpose |
|---------|------|---------|
| `/kickoff` | `.claude/commands/kickoff.md` | Simple intake for single-domain changes |
| `/kickoff-complex` | `.claude/commands/kickoff-complex.md` | Plan-gated intake for multi-domain/risky changes |
| `/commit-only` | `.claude/commands/commit-only.md` | Stage and commit with quality gates |
| `/commit-and-push` | `.claude/commands/commit-and-push.md` | Stage, commit, push with quality gates |
| `/run-pm` | `.claude/commands/run-pm.md` | Invoke product-manager (mobile workflow) |
| `/run-pe` | `.claude/commands/run-pe.md` | Invoke principal-engineer (mobile workflow) |
| `/run-sde` | `.claude/commands/run-sde.md` | Invoke software-developer (mobile workflow) |
| `/run-build` | `.claude/commands/run-build.md` | Invoke build-specialist (mobile workflow) |
| `/run-qa` | `.claude/commands/run-qa.md` | Invoke quality-assurance (mobile workflow) |
| `/show-me` | `.claude/commands/show-me.md` | Read-only pipeline status report |
| `/seed` | `.claude/commands/seed.md` | One-shot project onboarding and placeholder filling |
| `/prep-pm-discover` | `.claude/commands/prep-pm-discover.md` | Prep Discovery -- route to Product Manager |
| `/prep-pe-design` | `.claude/commands/prep-pe-design.md` | Prep Design -- route to Principal Engineer |
| `/prep-em-tasks` | `.claude/commands/prep-em-tasks.md` | Prep Tasks -- EM breaks design into tasks |
| `/prep-sde-implement` | `.claude/commands/prep-sde-implement.md` | Prep Implementation -- route to Software Developer |
| `/prep-build-verify` | `.claude/commands/prep-build-verify.md` | Prep Verification -- route to Build Specialist |
| `/prep-qa-review` | `.claude/commands/prep-qa-review.md` | Prep Review -- route to Quality Assurance |
| `/prep-pm-accept` | `.claude/commands/prep-pm-accept.md` | Prep Acceptance -- route to Product Manager |
| `/prep-em-done` | `.claude/commands/prep-em-done.md` | Close feature -- commit, push, PR, optional release |
```

**Ordering rationale:**
- **Intake** (`/kickoff`, `/kickoff-complex`): How you start work.
- **Commit** (`/commit-only`, `/commit-and-push`): How you save work.
- **Specialist invocation** (`/run-pm` through `/run-qa`): How you invoke agents in the specialist session.
- **Utility** (`/show-me`, `/seed`): Standalone tools.
- **Pipeline prep** (`/prep-pm-discover` through `/prep-em-done`): Stage transition commands, listed in pipeline order.

### 6. Mobile Workflow Section (Corrected Text)

The current text references outdated command names (`/discover`, `/design`). Replace the entire Mobile Workflow section body with:

```markdown
## Mobile Workflow (Happy Coder)

Two sessions running simultaneously against the same working directory:

- **Session 1 (EM):** Persistent, long-running. Uses `/kickoff` to start features, then `/prep-*` commands (e.g., `/prep-pm-discover`, `/prep-pe-design`, `/prep-sde-implement`) to advance through pipeline stages.
- **Session 2 (Specialist workbench):** Ephemeral, one agent at a time. Uses `/run-pm`, `/run-pe`, `/run-sde`, `/run-build`, or `/run-qa` to invoke the agent whose inbox was prepared by Session 1.

The EM writes `.state/inbox/<agent-name>.md`. Session 2 consumes those inbox files via the `/run-*` commands.
```

**Changes from current text:**
- Session 1 description: replaced `/discover`, `/design`, etc. with `/prep-*` commands and gave concrete examples.
- Session 2 description: listed all five `/run-*` commands explicitly.
- Third paragraph: unchanged (it is already accurate).

### 7. Components Affected

| File/Path | Change Type | What Changes |
|-----------|-------------|--------------|
| `docs/assets/` | New directory | Created to hold screenshots |
| `docs/assets/*.png` (9 files) | New files (moved) | Moved from `temp/` |
| `README.md` | Modified | Commands table expanded, Walkthrough section added, Mobile Workflow corrected |
| `temp/*.png` (9 files) | Deleted (moved) | Files relocated to `docs/assets/` |

**Not changed:** `CLAUDE.md`, any agent files, any command files, `docs/CONTRIBUTING.md`, `docs/ARCHITECTURE.md`, any code files.

### 8. Data Flow

This is a documentation change. There is no runtime data flow. The relevant "flow" is:

1. Developer creates `docs/assets/` directory.
2. Developer moves nine PNG files from `temp/` to `docs/assets/`.
3. Developer edits `README.md` to add the Walkthrough section, expand the Commands table, and fix the Mobile Workflow section.
4. Git stages the moved files (git will detect them as renames if content is identical) and the modified `README.md`.

### 9. Interface Contracts

Not applicable -- no APIs, function signatures, or type definitions are involved. The "interface" is the Markdown structure of `README.md`, which is fully specified in sections 3-6 above.

### 10. Edge Cases and Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| **Relative path breakage:** `README.md` is at the repo root, images are at `docs/assets/`. The path `docs/assets/foo.png` is correct from root. If someone views the README from a subdirectory or a rendered context that changes the base path, images may break. | Low | GitHub, GitLab, and most Markdown renderers resolve image paths relative to the file's location. Since `README.md` is at root, `docs/assets/` is correct. |
| **Large file sizes inflating repo:** PNG screenshots may be large. | Low | Screenshots already exist in `temp/` (which was committed or is about to be). Moving them to `docs/assets/` does not increase repo size -- git detects the rename. |
| **`temp/` directory accidentally deleted:** The constraint says do not delete `temp/`. | Low | Developer instructions explicitly state: move files, do not delete the directory. |
| **Missing file in move:** If one of the nine files is accidentally skipped, an image tag will produce a broken link. | Low | AC-1 verifies all nine files exist in `docs/assets/`. AC-8 verifies no broken image links. |
| **Commands table drift:** If commands are added to `CLAUDE.md` after this feature ships, the README table will be stale again. | Medium | Out of scope for this feature. Could be addressed with a future lint check or CI validation. Noted in tech debt tracker if desired. |
| **Markdown rendering differences:** Italic captions, image sizing, or alt text may render differently across GitHub, VS Code preview, and other viewers. | Low | Use only standard Markdown syntax (no HTML). Captions as italic text on a separate line are universally supported. |

### 11. Testing Strategy

This is a documentation-only change. There are no unit tests or integration tests to write. Verification is done through the acceptance criteria checks:

1. **AC-1:** `find docs/assets -name "*.png" | sort` returns all nine filenames.
2. **AC-2:** `grep -i "temp/" README.md` returns no matches.
3. **AC-3:** `grep -c "docs/assets/" README.md` returns at least 9.
4. **AC-4:** Each of the 19 command names from `CLAUDE.md` appears in `README.md`.
5. **AC-5:** All 9 original commands still present.
6. **AC-6:** `grep -E "/discover|/design" README.md` in the Mobile Workflow section returns no matches (outdated names removed).
7. **AC-7:** Every `![` tag has non-empty alt text (no `![]` with empty brackets).
8. **AC-8:** All image paths resolve correctly from repo root.

The build specialist can run these as shell commands during verification.

### 12. Scope Boundaries (What We Are NOT Building)

- NOT creating new screenshots or editing existing screenshot images.
- NOT changing `CLAUDE.md` or any agent/command definition files.
- NOT adding CI checks for README-to-CLAUDE.md command sync.
- NOT restructuring any section of the README beyond Commands, Walkthrough (new), and Mobile Workflow.
- NOT deleting the `temp/` directory.
- NOT adding HTML to the README (pure Markdown only).

---

## Task Breakdown

- **Task breakdown complete:** 2026-04-01

### T1: Move screenshots to docs/assets/

Create the `docs/assets/` directory and move all nine PNG files from `temp/` into it. Verify all nine files exist at the destination. Do NOT delete the `temp/` directory itself.

**Files involved:** `temp/*.png` (9 files) -> `docs/assets/*.png` (9 files)

### T2: Expand the README Commands table

Expand the Commands table in `README.md` from 9 rows to 19 rows. Add the 10 missing commands: `/show-me`, `/seed`, `/prep-pm-discover`, `/prep-pe-design`, `/prep-em-tasks`, `/prep-sde-implement`, `/prep-build-verify`, `/prep-qa-review`, `/prep-pm-accept`, `/prep-em-done`. Add a one-line intro sentence describing the command grouping. Preserve all 9 existing commands. Follow section 5 of the design.

**Files involved:** `README.md`

### T3: Add Walkthrough section with screenshots

Add a new "Walkthrough" section to `README.md`, placed between Commands and Installation. Nine steps, each with a `###` subheading, 1-2 sentences of narrative, a Markdown image tag with descriptive alt text pointing to `docs/assets/`, and an italic caption. Follow the exact step-by-step design in section 4.

**Files involved:** `README.md`

### T4: Fix Mobile Workflow section

Replace the Mobile Workflow section body with corrected text. Remove references to `/discover` and `/design`. Session 1 should reference `/kickoff` and `/prep-*` commands with concrete examples. Session 2 should list all five `/run-*` commands. Follow the exact replacement text in section 6 of the design.

**Files involved:** `README.md`

### T5: Verification (build-specialist)

Run all 8 acceptance criteria checks as shell commands:
- AC-1: `find docs/assets -name "*.png" | sort` returns all 9 filenames
- AC-2: `grep -i "temp/" README.md` returns no matches
- AC-3: `grep -c "docs/assets/" README.md` returns >= 9
- AC-4: All 19 commands from `CLAUDE.md` appear in `README.md`
- AC-5: All 9 original commands still present in `README.md`
- AC-6: No `/discover` or `/design` in Mobile Workflow section
- AC-7: No empty alt text in image tags (no `![]`)
- AC-8: All image paths resolve from repo root
