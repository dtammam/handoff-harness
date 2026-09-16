# Quality Assurance — Code Review: security-agent feature

**Feature:** security-agent — "Security agent + clean upgrade path + future-agents roadmap"
**Branch:** feature/security-agent (nothing pushed; base = `main`)
**Exec plan:** `/home/coder/projects/handoff-harness/docs/exec-plans/active/2026-07-06-security-agent.md`

You are the **quality-assurance** agent. Review the implemented change for
correctness, standards compliance, security, and performance. You are read-only —
report findings only, do NOT fix code, do NOT modify state or the exec plan.

## On startup (read in this order)
1. This inbox.
2. `.state/feature-state.json` — current state (stage = review; all 6 tasks done, T1–T6).
3. `docs/CONTRIBUTING.md`, `docs/ARCHITECTURE.md`, `docs/RELIABILITY.md` — standards
   (note: several are template placeholders in this repo).
4. The exec plan above — Requirements (R-1..R-6), Acceptance criteria (AC-1..AC-14),
   the `## Design` section, and the `## Task breakdown` (T1–T6).
5. **`git diff main`** — all changes to review.

## What was built (for orientation)
This is the **handoff-harness** repo itself (a shell + Markdown multi-agent SDLC
pipeline installed into other repos via `install.sh`). This feature adds a new
advisory, read-only `security-engineer` agent and its wiring, plus an installer
upgrade-path fix, plus a roadmap doc. Expected changed files:
- New: `.claude/agents/security-engineer.md` (+ `src/` mirror),
  `scripts/run-security-engineer.sh` (+ `src/` mirror),
  `.claude/commands/run-security.md` (+ `src/` mirror),
  `docs/ROADMAP.md` (+ `src/` mirror).
- Modified: `.claude/agents/engineering-manager.md` (+ mirror), three `prep-*`
  commands (+ mirrors), `CLAUDE.md` (+ `src/CLAUDE.md`), and `install.sh` (no `src/`
  mirror — not in the payload).

## Review focus for this repo
Since there is no compiled code or test framework here, weight your review toward:
- **Correctness of the `install.sh` shell edits** — the `--update` scaffold
  copy-if-missing logic and the Step 12 CLAUDE.md merge note: quoting, edge cases,
  no clobber of preserved files, summary-counter accuracy, no interface change.
- **Consistency of the new agent/script/command with existing siblings** — does
  `run-security-engineer.sh` match the `run-*.sh` pattern? Does the agent file match
  the house structure? Are the `src/` mirrors in sync where they should be (and
  intentionally divergent only for `CLAUDE.md`, which is a template)?
- **Template-mirroring integrity** — every shipped root file that changed has the
  correct `src/` counterpart; `install.sh` correctly has none.
- **Standards / hygiene** — Markdown well-formed; no stray secrets; no `docs/AGENTS.md`
  edit (it is human-maintained and must be untouched); no accidental changes to other
  agents' roles (AC-13).
- **Acceptance-criteria alignment** — spot-check the diff against AC-1..AC-14; note
  any criterion the diff does not appear to satisfy.

## Output — print this report, write nothing
```
Code Review: security-agent

Files reviewed: X   New: Y   Modified: Z

Findings:
CRITICAL (must fix before merge):
- [file:line] ...
WARNING (should fix):
- [file:line] ...
SUGGESTION (consider improving):
- [file:line] ...

Overall: APPROVE | REQUEST CHANGES | NEEDS DISCUSSION
```

Be specific (file:line), prioritize ruthlessly, and if the change is clean say so
briefly and APPROVE. Then stop — the engineering-manager records your verdict. Note:
a separate security-engineer late audit is running in parallel over the same diff;
you do not need to duplicate deep security analysis, but flag anything you see.
