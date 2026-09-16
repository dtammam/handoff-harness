# Software Developer — FIX-1: clean up two malformed Rules bullets in security-engineer.md (+ src mirror)

**Feature:** security-agent
**Branch:** feature/security-agent (already checked out)
**Task:** Post-review remediation (SEC-AGENT-1 / QA WARNING) — MINIMAL, surgical
**Exec plan:** `/home/coder/projects/handoff-harness/docs/exec-plans/active/2026-07-06-security-agent.md`

Both reviews cleared the gate (security-engineer: PASS WITH CONDITIONS; QA: APPROVE).
The only on-branch fix requested is this one tiny cleanup. Do EXACTLY this and
nothing more.

## The problem
`.claude/agents/security-engineer.md` has two malformed `## Rules` bullets (lines
159–160) that read as leaked meta-commentary rather than clean rules:

```
- "ALWAYS verify artifacts exist at their state-recorded paths before proceeding" (was implied in the core principle but not enforced as a rule)
- "Run ONE stage per invocation, then stop" (was described in the core principle but not listed as an explicit rule)
```

## The exact fix (apply to BOTH files)
Files (the ONLY two files you may touch):
- `/home/coder/projects/handoff-harness/.claude/agents/security-engineer.md`
- `/home/coder/projects/handoff-harness/src/.claude/agents/security-engineer.md`

1. **Replace line 159** (the first malformed bullet) with this clean imperative rule:
   ```
   - Verify artifacts exist at their state-recorded paths before proceeding
   ```
2. **Delete line 160** entirely (the second malformed bullet). It is redundant with
   the existing rule further down the list: `- Run exactly ONE touchpoint per
   invocation, then stop`.

After the edit, the `## Rules` list should begin:
```
## Rules

- Verify artifacts exist at their state-recorded paths before proceeding
- Report findings and a single top-line verdict — never fix code
- Read-only, always: write to no file, ever. No `Edit`/`Write` tool. Never
  modify source, config, requirements, design, the exec plan, or
  `.state/feature-state.json`
- Never advance stages — your verdict is advice to the human gate, not an
  automatic transition
- Apply the stated gate threshold consistently (CRITICAL/HIGH block;
  MEDIUM/LOW accept-with-rationale; INFO advisory)
- Run exactly ONE touchpoint per invocation, then stop
```

Make the identical change in the `src/` mirror so the two files stay **byte-identical**.

## CRITICAL CONSTRAINTS (do not violate — protects AC-13)
- Do **NOT** touch `.claude/agents/quality-assurance.md` or its `src/` mirror. Its
  identical pre-existing garble is intentionally left alone and is logged separately
  as tech debt (NB-5). Fixing it here would break **AC-13** (which limits
  `.claude/agents/` changes to `security-engineer.md` + `engineering-manager.md`).
- Do **NOT** touch any other agent file, command, script, `install.sh`, `CLAUDE.md`,
  `docs/`, `docs/AGENTS.md`, or `.state/feature-state.json`.
- Change ONLY the two Rules bullets described above — no other edits to
  security-engineer.md (no rewording elsewhere, no reflowing).

## Done when
- Line 159 is the clean imperative rule; the old line 160 is gone; both root and
  `src/` files updated and byte-identical; no other file changed. `git diff` shows
  changes to exactly those two files, in the Rules section only.

## Report back
Show the before/after of the Rules section (root file), confirm the `src/` mirror is
byte-identical, and confirm `git diff --name-only` lists ONLY
`.claude/agents/security-engineer.md` and `src/.claude/agents/security-engineer.md`
for this fix. Do NOT commit or push. Then stop.
