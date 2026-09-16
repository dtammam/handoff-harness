# Security Engineer — LATE DIFF AUDIT (touchpoint 3)

**Phase:** Implementation
**Mode:** late code/diff audit (post-QA, pre-Acceptance)
**Feature:** security-agent — "Security agent + clean upgrade path + future-agents roadmap"
**Branch:** feature/security-agent (nothing pushed; base = `main`)
**Exec plan:** `/home/coder/projects/handoff-harness/docs/exec-plans/active/2026-07-06-security-agent.md`

You are the **security-engineer** agent running your own touchpoint-3 late audit —
fittingly, this is the feature that *adds* you auditing its own diff. You are
**strictly read-only** (tools: Read, Glob, Grep). Do NOT modify any file, do NOT edit
the exec plan or state, and do NOT advance any stage. You **print** your report; the
engineering-manager records your verdict into the exec plan.

## On startup (read in this order)
1. This inbox.
2. `.state/feature-state.json` — current state (stage = review; all 6 tasks done).
3. `docs/CONTRIBUTING.md`, `docs/ARCHITECTURE.md`, `docs/RELIABILITY.md` — standards
   (note: several are template placeholders in this repo).
4. The exec plan above — Requirements (R-1..R-6), Acceptance criteria (AC-1..AC-14),
   and the full `## Design` section for intended behavior.
5. **`git diff main`** — the complete implemented change. This is your primary audit
   surface.

## Context that governs your risk ratings
This is the **handoff-harness** repo: a multi-agent SDLC pipeline made of **shell +
Markdown**, distributed into other repos via `install.sh`. Deployment context is
**solo-dev, self-hosted applications**. Rate impact×likelihood contextually (OWASP
Risk Rating style), not generic worst-case CVSS. The diff is mostly harness
meta-files (agent/command/doc Markdown) plus one shell file (`install.sh`).

## Where to focus this audit
1. **`install.sh` shell edits (highest priority).** Two changes: the `--update`
   scaffold **copy-if-missing** logic, and the **CLAUDE.md merge note** in Step 12.
   Scrutinize for:
   - Path / quoting safety: unquoted expansions, word-splitting, globbing on
     `$src`/`$dest`/`$file`, `mkdir -p "$(dirname "$dest")"` correctness.
   - Clobber/overwrite risk: does copy-if-missing ever overwrite an existing local
     file it shouldn't? Does it respect the preserve semantics for existing scaffold
     files? Any TOCTOU between the `[ ! -f "$dest" ]` test and the `cp`?
   - Injection: any place where a repo-controlled path/filename could inject into a
     command, `eval`, or the `case " $merge_list " in ...` match. Consider filenames
     with spaces/globs in `merge_list`.
   - Manifest/version handling side effects from the change; any new early-return or
     state that could skip security-relevant steps.
   - The broader `curl | bash` trust model of the installer (note if relevant; it
     predates this feature).
2. **The security-engineer agent's own instructions** (`.claude/agents/security-engineer.md`):
   are they sound and safe? Read-only posture actually enforced (tools list, Rules)?
   Verdict/threshold model coherent? Any instruction that could cause it to leak
   sensitive data or take an unsafe action?
3. **The routing / docs changes** (engineering-manager.md, prep commands, CLAUDE.md
   rows, ROADMAP.md): lightweight — flag only real security-relevant issues (e.g.,
   instructions that would weaken a gate or mislead on security posture).

## Output — print this report, write nothing
Use your standard format, **top-line verdict first**:

```
SECURITY VERDICT: <PASS | PASS WITH CONDITIONS | FAIL — BLOCKED>

Security Review — Implementation: Security agent + clean upgrade path + roadmap
Date: 2026-07-06
Mode: late code/diff audit
Scope: git diff main (harness meta-files + install.sh)
Gate threshold: CRITICAL/HIGH block; MEDIUM/LOW accept-with-rationale

Threat surface: <1–2 sentences>

Findings (grouped by severity):
CRITICAL: ...
HIGH: ...
MEDIUM: ...
LOW: ...
INFO: ...

Verdict rationale: <ties the top-line verdict to the findings + gate threshold>
```

Apply the gate threshold: CRITICAL/HIGH block (→ FAIL — BLOCKED); only MEDIUM/LOW
remaining → PASS WITH CONDITIONS (each fixed or risk-accepted with rationale); clean →
PASS. If clean, say so briefly and emit `SECURITY VERDICT: PASS`.

Then stop. The engineering-manager will record your verdict + findings into the exec
plan as `## Security review — Implementation`. Your verdict is advice to the human
gate; a `FAIL — BLOCKED` is a human-enforced hard gate before Acceptance — you do not
auto-advance or auto-block anything.
