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
anchor: outcome|spec|tdd    # the acceptance dial for this work
status: <lifecycle-state>   # from the closed set below
design: Approved <date> @<sha>     # present once design is approved (spec/tdd)
gate: <verdict>                    # see gate line below; "pending" until gated
---
```

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
2. A bound marker (`@<sha>`) whose `<sha>` is not in history.
3. A bound marker whose file has changed since `<sha>` — the approval no longer
   describes the content next to it.
4. A `Gate: APPROVED` at a sha older than the latest change to the plan's code.

Run it from the SessionStart hook (so a resumed session sees the true state) and
from `pre-push` (so stale approvals never leave the machine).
<!-- harness:region:end id=doc -->
