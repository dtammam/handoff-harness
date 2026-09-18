<!-- harness:region:start id=doc -->
---
plan: research-and-artifact-split
harness: v2 · lean
anchor: spec
status: Building
next: commit + push; open PR (slim gate — adversary only — optional dogfood)
gate: pending
---

# Research phase + per-piece artifact directory

Absorb two things from the PDD-workflow review while keeping v2's back-end
(the gate, sha-binding, scrutiny) exactly as it is: (1) research as a real,
cited, persisted artifact, and (2) split the single God plan doc into a small
per-piece directory so nothing goes stale as a 1,200-line scroll.

Deliberately NOT changing: the default anchor stays `outcome`; the Architect
keeps recommending the anchor per task. This is additive.

## Acceptance

- A piece of work lives in `docs/exec-plans/active/<date>-<slug>/`, not a single
  file. `plan.md` is the spine (bound status block + acceptance + progress +
  `next:`); `research/*.md` and `design.md` are anchor-scaled siblings.
- Research is a phase the Architect runs when the work warrants it, writing cited
  `research/*.md`, and the invalidation rule is stated as a non-negotiable-grade
  rule in the flow.
- `next:` is part of the status block, written by `/start`, reported by `/status`.
- `check-markers.sh` flags an `Approved`/`APPROVED` marker that has no `@sha`.
- `selftest.sh` still passes; the marker checker still ignores the plans dir.

## Decisions

- D1: directory-per-piece, anchor-scaled (outcome = plan.md [+research]; spec/tdd
  add design.md). Keeps lean lean.
- D2: research available at ANY anchor, agent-decided (like the anchor itself).
- D3: `next:` now; `/handoff` deferred to a later rev.

## Progress

- [x] Branch + this plan (dogfoods the new directory layout)
- [x] flow.md: Phase 1.5 Research + directory artifact model + invalidation rule + anti-noise guard
- [x] /start: write the directory + plan.md + next:; propose research when warranted
- [x] /release: move the whole directory to completed/
- [x] harness-markers.md: directory location, next:, research + invalidation conventions
- [x] /status: report next:
- [x] check-markers.sh: flag sha-less approvals; scope marker checks to active/
- [x] Filed the finished v2 build plan to completed/
- [x] sync dogfood + selftest (PASS) + rigged checker test (PASS)

## Backlog (not this rev)

- /handoff command; decouple test-first from the anchor; /seed --refresh; §4
  defects (stale v1 plan under active/, unimplemented `auto`, scrutiny `**/*client*`
  over-trigger, tech-debt NB-4/5, maintainer email in the old active plan).
<!-- harness:region:end id=doc -->
