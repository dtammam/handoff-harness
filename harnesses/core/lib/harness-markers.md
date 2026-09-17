<!-- harness:region:start id=doc -->
# Harness markers — the state-as-document spine

State lives in the working documents under `docs/exec-plans/`, never in an
external state file. For that to be trustworthy — and not rot the way a stale
`feature-state.json` or an unmoved "SHIPPED" plan does — every marker obeys a
**closed vocabulary** and **binds to the git ref it describes**. A checker
(`.harness/lib/check-markers.sh`) mechanically flags any marker that no longer matches.

## The status block (machine-readable spine)

Every working doc opens with YAML frontmatter:

```yaml
---
plan: <kebab-name>          # stable id; matches the branch name
harness: v2 · <flavor>      # which harness style produced this plan (from .harness/harness.toml)
anchor: outcome|spec|tdd    # the acceptance dial for this work
status: <lifecycle-state>   # from the closed set below
design: Approved <date> @<sha>     # present once design is approved (spec/tdd)
gate: <verdict>                    # see gate line below; "pending" until gated
---
```

## Location & naming (continuity with v1)

Plans live where they always have — this is deliberate, so a repo that used the
old harness keeps one unbroken history:

- `docs/exec-plans/active/YYYY-MM-DD-<slug>.md` while in flight (`<slug>` matches
  the branch name), moving to `docs/exec-plans/completed/` when `Shipped`.
- `docs/exec-plans/tech-debt-tracker.md` is unchanged.

The `harness:` header is the one addition: it tells a mixed repo which style
produced each plan. v1 plans simply have no `harness:` line; v2 plans carry it.

## Closed lifecycle vocabulary

A `status:` is exactly one of:

| State | Meaning | Lives in |
|-------|---------|----------|
| `Draft` | intake underway; nothing approved | `active/` |
| `Approved @<sha>` | plan/design approved at `<sha>` | `active/` |
| `Building` | implementation in progress | `active/` |
| `Gate:<verdict> r<n> @<sha>` | under or through review | `active/` |
| `Shipped <version>` | merged/released | **`completed/`** |
| `Parked(revisit: <why>)` | paused deliberately | `active/` (allowed) |
| `Abandoned(<why>)` | will not ship | **`completed/`** |

Prose status lines (`Status: ACTIVE. "pivot to sync."`) are forbidden — they are
exactly what rotted in the reference repos. If a state isn't in the table, it
doesn't exist; add to the table, don't freehand.

## The gate line

The gate writes its verdict INTO the plan, bound to the reviewed sha:

```
Gate: APPROVED r2 @7f3a2c1 — adversary, qa, security-brief
Gate: CHANGES r1 @a19c4d0 — adversary (see findings below)
```

- `r<n>` is the review round (the fix loop increments it).
- `@<sha>` is the commit reviewed. **Approval binds to that sha.** If the tree
  changes after it, the approval is stale until re-confirmed at the new sha.
- Close requires every *required* seat (per `.harness/scrutiny.toml`) APPROVED at the
  current sha. Never self-merge.

## What the checker enforces

`.harness/lib/check-markers.sh` flags, and exits non-zero on:

1. A terminal `status:` (`Shipped`, `Abandoned`) on a doc still under `active/`.
2. An approval marker (`@<sha>`) whose `<sha>` is not in history.
3. An `Approved` / `Gate: APPROVED @<sha>` where the reviewed CODE has changed
   since `<sha>`. The plans dir is EXCLUDED from this diff, so a plan's own
   bookkeeping (status update, sibling markers, moving to `completed/`) never
   invalidates a still-valid approval. `Gate: CHANGES` lines are history and are
   not checked.

Run it from the SessionStart hook (so a resumed session sees the true state) and
from `pre-push` (so stale approvals never leave the machine).

## Conventions that keep this honest

- **Commit before gating.** A bound verdict needs a real commit sha, so gate the
  committed work (a WIP commit is fine); the fix loop adds new commits rather
  than rewriting the approved one.
- **One piece, one plan doc.** A piece of work carries its bound markers in its
  own plan doc. An umbrella / roadmap doc holds status *pointers* — prose and
  links to the per-piece plans — never its own bound `Gate:` / `Approved`
  markers, so one piece's edits never touch another's approval.
<!-- harness:region:end id=doc -->
