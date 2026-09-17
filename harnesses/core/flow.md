<!-- harness:region:start id=doc -->
# The flow — five phases, sized by the anchor

One flow, not two. "Lean" and "Standard" are the same five phases at different
depths; the **anchor** decides the depth and the **auto** flag decides how often
you stop to ask. Build, Gate, and Close always run. Nobody hand-authors a
per-flavor flow — the depth is derived from the anchor.

The anchor is one of `outcome | spec | tdd` and is recorded in the plan's status
block and in `.harness/harness.toml [defaults]`. `auto` is a flag whose halts
are *derived from the anchor*: a `spec` or `tdd` anchor still forces the
design/plan approval halt even under `auto`, because an anchor no human approved
is fiction.

## Phase 1 — Intake & anchor  *(always)*

Read the request; do a blind-spot pass over the repo (the unknowns the user
hasn't thought to raise, while they're cheap). Then form an opinion: state the
project **default anchor** (`.harness/harness.toml`) next to the anchor you
**recommend for this request**, and when they differ, flag it and argue the
change with reasons — the default is only a baseline; your read of the work wins,
the user decides. Propose the acceptance for this work, and confirm once.

- **outcome:** three-bullet inferred acceptance, written to a plan doc under
  `docs/exec-plans/active/`. Confirm, then step back.
- **spec / tdd:** a decision register — IDs, recommendation, rationale, ordered
  by blast radius (data models & interfaces first). Approve the batch or override
  individual IDs.

Either way a plan doc now exists with a bound status block. There is always a
written acceptance the gate can measure against; a bullet the Adversary cannot
measure is itself a finding — send it back here.

## Phase 2 — Design & plan  *(depth = anchor)*

- **outcome:** a short approach note, or nothing. No formal gate.
- **spec:** a self-contained design → record `design: Approved <date> @<sha>`,
  then a plan of `Step N:` items → `status: Approved @<sha>`.
- **tdd:** as spec, and each acceptance criterion names the test that will bind
  it before any code exists.

## Phase 3 — Build  *(always)*

You implement it. `tdd` writes the failing test first. Record progress in the
plan; log deviations under a `Deviations` heading. **A deviation that changes a
public interface, a data model, an acceptance criterion, or user-visible
behavior halts and returns to the user, whatever the involvement setting** — the
approval covered the design as written.

**Commit the work before gating** (staged by name; a WIP/checkpoint commit is
fine). The gate binds its verdict to a commit sha, and the reviewers mutate
against a committed tree — so a real commit must exist before Phase 4. This
commit is what ships; do not rewrite it after approval (that would void the
bound verdict). A fix in the gate's fix loop is a *new* commit, re-gated.

## Phase 4 — Gate  *(always)*

Run the gate protocol (`.harness/lib/gate-protocol.md`) against the committed
work — `<sha>` is `HEAD`. Seats are set by `.harness/scrutiny.toml` against the
diff — never by your judgment; you may only escalate. Each seat writes
`Gate: <verdict> r<n> @<sha> — <seat>`.

**The fix loop:** on `CHANGES`, fix, then re-engage the **same seat instances**
for a delta re-review; they re-verify their findings (and their own
prescriptions) against the new sha and re-verdict at `r<n+1>`. Repeat until every
required seat is `APPROVED` at the same final sha. Never self-merge.

## Phase 5 — Verify & close  *(always)*

- **outcome:** you verify the result yourself.
- **spec / tdd:** verify against the acceptance criteria / the tests.

The work is already committed and gated (Phase 3/4). Now close it out: set the
plan's status to `Shipped <version>`, move the doc to `completed/`, and commit
that **as its own bookkeeping commit** — it touches only the plan doc, so it
does not change the reviewed code and the approval stays valid. Then run any
release ceremony and push. Run `.harness/lib/check-markers.sh` before push — a
stale approval never leaves the machine.

## The shape, at a glance

```
1 Intake&anchor ─▶ 2 Design&plan ─▶ 3 Build ─▶ 4 Gate ─▶ 5 Verify&close
                     (anchor)                    │  ▲
                                                 └──┘  fix loop: same seats
```
<!-- harness:region:end id=doc -->
