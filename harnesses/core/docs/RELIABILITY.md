<!-- harness:region:start id=doc -->
# Reliability

*Schema template. `/seed` fills the `{{PLACEHOLDER}}` tokens from the detected
project; every `## ` heading is fixed — a section may read "N/A — none" but is
never renamed or reordered. The `keep` region at the bottom is yours and
survives every harness update.*

How reliability is defined and measured here — so a change can be judged against
it, not against a vibe. Referenced from `AGENTS.md` for "how reliability is
defined and measured here."

## What "reliable" means here

*The concrete definition for this system: the behavior it must uphold, and the
bar it is held to. Not a platitude — something a change can be checked against.*

{{RELIABILITY_DEFINITION}}

## How it's measured

*The signals and thresholds that say whether the bar is being met — tests,
metrics, SLOs, error budgets, or the manual checks that stand in for them.*

{{RELIABILITY_MEASURES}}

## Failure modes & blast radius

*The ways this system fails, and how far each failure spreads — what breaks,
who's affected, and what stays contained.*

{{FAILURE_MODES}}

## Startup / smoke checks

*The fast checks that confirm the system is up and sane after a start or deploy —
what to run, and what a healthy result looks like.*

{{SMOKE_CHECKS}}

## Degradation & recovery

*How the system degrades under stress rather than falling over, and the steps to
bring it back — retries, fallbacks, rollback, and the recovery runbook pointer.*

{{DEGRADATION_AND_RECOVERY}}
<!-- harness:region:end id=doc -->

<!-- harness:region:start id=project keep -->
## Reliability notes

*This region is yours. The harness never regenerates it on update. Record here
the hard-won operational lessons: incidents and their rulings, known-fragile
areas, environment quirks, and the checks that exist because something once
broke.*

- If a build breaks on the main line, fix it before any new feature work.
- _(incidents and dated rulings accrete here — the seed step and your own edits
  fill this in)_
<!-- harness:region:end id=project -->
