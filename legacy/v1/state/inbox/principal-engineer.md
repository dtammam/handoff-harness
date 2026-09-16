# Principal Engineer — Design: Security agent + clean upgrade path + roadmap

**Feature:** security-agent
**Stage:** Design
**Date:** 2026-07-06
**Branch:** feature/security-agent
**From:** Engineering Manager

You are the principal-engineer for the **handoff-harness** repo. This is
meta-work: handoff-harness IS a multi-agent SDLC pipeline distributed into
other repos via `install.sh`. We are changing the harness itself so the change
can later be pulled into every already-installed downstream repo.

Your job in this stage is **Design only**: produce a concrete `## Design`
section in the exec plan that a software-developer can implement without
ambiguity. Do NOT write application code, agent files, scripts, or commands.
Do NOT modify the Requirements, Acceptance criteria, Constraints, or Out-of-scope
sections of the exec plan.

## Required reading (in order)
1. **Exec plan (approved requirements + AC):**
   `docs/exec-plans/active/2026-07-06-security-agent.md` — read it fully. R-1
   through R-6 and AC-1 through AC-14 are approved and locked. Your design must
   satisfy every one.
2. `docs/ARCHITECTURE.md`, `docs/CONTRIBUTING.md`, `docs/RELIABILITY.md`
   (note: CONTRIBUTING/RELIABILITY are largely template placeholders in this repo).
3. `install.sh` — read end to end. Study `get_category()` (~line 29), the
   FRESH INSTALL flow, and especially the UPDATE flow's Step 7 per-file loop
   (~line 161) where `scaffold` files are unconditionally skipped.
4. The existing agent files under `.claude/agents/` (especially
   `quality-assurance.md` and `engineering-manager.md`) and their
   `src/.claude/agents/` mirrors, plus `scripts/run-quality-assurance.sh`,
   `.claude/commands/run-qa.md`, `.claude/commands/prep-qa-review.md`,
   `.claude/commands/prep-pm-discover.md`, and `.claude/commands/prep-pe-design.md`,
   to match the established pattern exactly.

## Locked decisions (from the Discovery gate — do NOT relitigate)
- **Agent name:** `security-engineer` (accepted; use this exact kebab-case slug
  everywhere — agent file, script, commands, CLAUDE.md table row, inbox filename
  `.state/inbox/security-engineer.md`).
- **Roadmap doc location:** `docs/ROADMAP.md` (top-level `docs/`, NOT
  `docs/roadmap/future-agents.md`).

## The two structural upgrade risks you MUST solve mechanically

These are the crux of the Design. The maintainer's bar is "on `--update`, an
existing install just gets the new things — it just works." Your design must
specify a concrete, painless mechanism for both:

### Risk A — scaffold files are silently skipped forever on `--update`
In `install.sh`'s UPDATE flow, the per-file loop classifies each remote `src/`
file via `get_category()` and, for `scaffold`, does
`skipped=$((skipped + 1))` with **no check for whether the file already exists
locally**. Consequence: any brand-new file that resolves to `scaffold` (which is
the default fallthrough) never reaches an already-installed repo on `--update` —
it only lands on a fresh install. `docs/ROADMAP.md` has no explicit
`get_category()` case arm, so today it falls through to `scaffold` and would be
lost on every upgrade.

Design a concrete fix. Consider (and pick, with rationale) options such as:
- Adding a case arm classifying `docs/ROADMAP.md` (and/or a `docs/*` policy) into
  a category that copies on update; and/or
- Changing the `scaffold` update behavior to "copy if the file does not yet exist
  locally, otherwise preserve/skip" (a copy-if-missing rule), which fixes the gap
  generally for all future net-new scaffold files without clobbering user edits.

Your design MUST explicitly reason about the risk of any change to `scaffold`
behavior clobbering user-owned scaffold files that legitimately should be
preserved on update (e.g., `.gitkeep`, `tech-debt-tracker.md`, exec plans). State
the before/after behavior precisely and confirm no regression for existing
scaffold files. Note: `install.sh` is fetched fresh by curl/clone and is NOT part
of the `src/` payload, so it has no `src/install.sh` mirror to maintain — but any
`get_category()` change must be reflected in the manifest categories it emits.

### Risk B — CLAUDE.md is project-owned, so the agent-table row won't auto-apply
Wiring `security-engineer` into `CLAUDE.md`'s agent/command tables (R-3.1) edits a
`project-owned` file. On `--update`, project-owned files only auto-overwrite when
the local checksum still matches the manifest baseline; if the user customized
`CLAUDE.md` (the expected common case, since setup fills placeholders), the change
lands as a `CLAUDE.md.harness-update` sidecar instead of applying. Silent,
undetectable loss of the update is unacceptable (AC-10).

Design a concrete mechanism. Options to weigh (pick, with rationale):
- Accept the sidecar path but guarantee the installer's printed output clearly
  tells the user a `CLAUDE.md` merge is needed and exactly what to do (satisfying
  AC-10 option (b)); and/or
- Reduce reliance on `CLAUDE.md` edits by carrying the routing/registration of the
  security-engineer in harness-owned files (agent files, commands, scripts,
  engineering-manager routing) so the agent is fully functional on upgrade even if
  the `CLAUDE.md` cosmetic table row lags behind in a sidecar; and/or
- Any other approach that makes the outcome deterministic and visible.

Whichever you choose, the agent must be **operational** on an upgraded install
without manual surgery, and any residual manual step (like merging a CLAUDE.md
table row) must be loudly surfaced, not silent.

## The rest of the design must also cover
- **Security-engineer agent file** (`.claude/agents/security-engineer.md` +
  `src/` mirror): frontmatter, "On startup" reading list, responsibilities for
  BOTH engagement modes (early requirements/design review; late code/diff audit),
  a defined report format, and a "Rules" section establishing it is advisory
  (does not fix code, does not auto-progress stages). Specify the concrete
  security review content (threat modeling, secrets, input validation, authz,
  injection classes, dependency risk, etc.) — Discovery left this to you.
- **Three touchpoints** (R-2, AC-2): specify exactly how
  `engineering-manager.md` (+ `src/` mirror) routes to security-engineer at
  (1) Discovery start, (2) Design start, (3) at/after QA before Acceptance —
  including which inbox is written, what it reads, what artifact/section it
  produces (e.g., a "Security review" section appended to the exec plan), and
  confirm none of them auto-advance `stage`.
- **Command + script wiring** (R-2.6, R-3.2, R-3.3): specify the new
  `scripts/run-security-engineer.sh` (+ `src/` mirror) following
  `run-quality-assurance.sh`; and the new/updated `.claude/commands/` files
  (a `run-*` command, plus how `prep-pm-discover`, `prep-pe-design`,
  `prep-qa-review` reference the adjacent security touchpoint) with `src/` mirrors.
- **Template mirroring map** (Constraints): produce an explicit table of every
  file added/changed and its required `src/` counterpart, so the implementer has
  a checklist and nothing drifts.
- **get_category() trace** (R-5.4, AC-11): trace every new file path through the
  case statement and state the resulting category, confirming no unintended
  fallthrough.
- **AGENTS.md** (R-3.4, AC-6): confirm your design writes NOTHING to
  `docs/AGENTS.md`. Record the desired security-engineer row there as an explicit
  manual human follow-up in the design, not as pipeline work.
- **Roadmap doc** (R-6): specify the `docs/ROADMAP.md` structure (three future
  agents, each with name candidate, problem, user context, "roadmap only — not
  approved for build" marker) and how it is verified to reach existing installs
  on `--update` per Risk A.
- **Verification approach**: this repo is shell + Markdown with no build/test/lint
  tooling. Specify how the installer changes will be verified manually/scripted
  (e.g., a temp-dir fresh-install run and a temp-dir `--update` run simulating a
  prior manifest, including the customized-`CLAUDE.md` case) to prove AC-7 through
  AC-11.
- **Architecture doc**: the security-engineer is a new pipeline component. Update
  `docs/ARCHITECTURE.md` (and its `src/` mirror) to reflect the new agent and its
  touchpoints if appropriate.
- **Risks & alternatives considered**: for both Risk A and Risk B, document the
  options you weighed and why you chose your approach.

## Output
Write a `## Design` section into
`docs/exec-plans/active/2026-07-06-security-agent.md` (the placeholder `## Design`
section near the end is where it goes). Do not touch the Requirements/AC sections.

When done, report a concise summary: your chosen mechanism for Risk A and Risk B,
the full list of files to be created/changed (with `src/` mirrors), and any
residual manual human follow-ups. Then stop. The maintainer reviews the design at
this gate before we proceed to Task breakdown.
