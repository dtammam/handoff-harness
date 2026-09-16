# Product Manager — ACCEPTANCE: validate security-agent against AC-1..AC-14

**Feature:** security-agent — "Security agent + clean upgrade path + future-agents roadmap"
**Branch:** feature/security-agent (nothing pushed; base = `main`)
**Exec plan:** `/home/coder/projects/handoff-harness/docs/exec-plans/active/2026-07-06-security-agent.md`

You are the product-manager doing **Acceptance**. Verify the FINAL implementation
against every acceptance criterion. This is **report-only** — do NOT implement or fix
anything, do NOT modify code, state, or the exec plan. Give an explicit pass/fail per
criterion; "looks good" is not acceptance.

## On startup (read in this order)
1. This inbox.
2. `.state/feature-state.json` — state (stage = acceptance; all 6 tasks done; review
   verdicts recorded).
3. The exec plan above — read the full **Acceptance criteria (AC-1..AC-14)**, the
   `## Design` section, the `## Task breakdown`, and the two recorded review sections
   (`## Security review — Implementation`, `## Quality-assurance review — Implementation`).
4. `git diff main` and the actual files on disk — verify against the real current
   state, not against the plan's prose.

## What to verify — go criterion by criterion (AC-1 through AC-14)
For each AC, state **PASS** or **FAIL** with the concrete evidence (file path, and
line/row where relevant). Key checks:

- **AC-1** — `.claude/agents/security-engineer.md` exists (+ `src/` mirror,
  content-equivalent) with role description, "On startup" list, both early+late
  engagement modes, output/report format, and an advisory Rules section (read-only,
  no code-fix, no stage-advance). NOTE: the Rules section was cleaned up post-review
  (the two malformed bullets removed) — verify it now reads as clean imperative rules.
- **AC-2** — `engineering-manager.md` (+ mirror) documents the three security-engineer
  touchpoints (Discovery start, Design start, at/after Review) each naming the inbox
  written and expected output.
- **AC-3** — `CLAUDE.md` (+ `src/CLAUDE.md`) has the `security-engineer` agent-table
  row and the `/run-security` command-table row. (Root and `src/` CLAUDE.md are
  intentionally divergent files — verify the rows are present in each, not a
  whole-file diff.)
- **AC-4** — `scripts/run-security-engineer.sh` (+ `src/` mirror) follows the
  `run-quality-assurance.sh` pattern (inbox guard, `claude --agent ... < inbox`).
- **AC-5** — a run command under `.claude/commands/` (+ `src/` mirror) invokes the
  security-engineer.
- **AC-6** — `git diff main -- docs/AGENTS.md` is empty (human-maintained file untouched).
- **AC-7..AC-11, AC-14** — the install/update behavior. The **build-specialist already
  verified these 5/5** against the local feature branch (recorded in state history at
  timestamp 00:10 and in the exec plan's recorded results): AC-7 fresh install, AC-8/9
  update auto-copy + roadmap delivery + scaffold preservation, AC-10a/10b CLAUDE.md
  paths, AC-11 get_category trace, AC-14 interface unchanged. You may **reference that
  recorded result** rather than re-running installs — but confirm the result is
  recorded and consistent, and that the source files it depends on (the install.sh
  edits, the new payload files) are present.
- **AC-12** — `docs/ROADMAP.md` (+ mirror) documents all three future agents
  (name candidate, problem, user context, "roadmap only — not approved for build"
  marker) and NO agent/command/script exists for any of the three.
- **AC-13** — `git diff main` under `.claude/agents/` touches ONLY
  `security-engineer.md` and `engineering-manager.md` (verified post-fix; re-confirm).

## Also confirm the risk acceptances
The security-engineer verdict was **PASS WITH CONDITIONS** with two Low findings.
Confirm both are acceptable to CLOSE for this branch:
- **INSTALL-1** (symlink-follow clobber edge case in the scaffold `cp`) — risk-accepted
  as identical to the installer's pre-existing arms and out of the solo-dev
  self-hosted threat model. Agree/disagree?
- **SEC-AGENT-1** (malformed Rules bullets) — fixed on-branch (verify it is actually
  fixed). Confirm closed.

Also note the deferred items are appropriately tracked, not lost: NB-5 (pre-existing
`quality-assurance.md` garble, deferred to preserve AC-13) and NB-6 (optional
install.sh Step 12.1 nesting) are logged in `docs/exec-plans/tech-debt-tracker.md`.

## Output — print an acceptance summary, write nothing
Provide:
1. A per-AC table/list: **AC-1 … AC-14 → PASS/FAIL** with one-line evidence each.
2. Risk-acceptance confirmation for INSTALL-1 and SEC-AGENT-1 (close / do-not-close).
3. An overall verdict: **ACCEPTED** (all AC pass, risk acceptances agreed) or
   **NOT ACCEPTED** (list the failing criteria).

Then stop. The engineering-manager will relay your summary; if ACCEPTED, the feature
closes as a committed, locally-verified branch (no push/PR/release/tag this run).
