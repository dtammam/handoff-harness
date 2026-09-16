<!-- harness:region:start id=doc -->
# Reliability

How reliability is defined and measured for the harness. Referenced from `AGENTS.md`.

## What "reliable" means here

The harness is reliable when three contracts hold:

1. **Update never eats your edits** — harness regions refresh, `keep` regions and
   project-owned (`once`) files are preserved.
2. **State never silently rots** — a stale or misfiled marker is always flagged.
3. **The gate can't be bypassed** — no change ships self-reviewed; the Adversary
   always runs.

## How it's measured

- `bash harnesses/selftest.sh` — the end-to-end contract: fresh install lands, a
  `keep` edit survives an update, a vandalized harness region reverts, markers pass.
- `bash .harness/lib/check-markers.sh docs/exec-plans` — the marker enforcer;
  exits non-zero on any stale/misfiled marker.
- `bash -n` / `shellcheck` on changed scripts.

## Failure modes & blast radius

- **Bad region-merge** → could clobber a project's `keep` content. Blast radius:
  one file in one repo; caught by `selftest.sh`; recoverable from git.
- **Bad installer** → could write wrong paths into a target repo. Blast radius:
  one repo; brownfield archives originals, so recoverable.
- **Marker parser drift** → the checker could miss a stale marker. Mitigated by
  the rigged/clean self-test cases.

## Startup / smoke checks

- On session start, `.claude/hooks/session-start.sh` reports the branch, active
  plans and their real status, and runs `check-markers` — so a resumed session
  sees true state, not a stale claim.
- After any change: `bash harnesses/selftest.sh`.

## Degradation & recovery

- Updates are additive and region-aware; a failed update leaves the target's
  `keep` content intact.
- A file with no region markers falls back to a `.harness-update` sidecar rather
  than being overwritten — the one degraded path, and it's reported.
- Everything is under git; the v1 cutover is reversible from `legacy/v1/`.
<!-- harness:region:end id=doc -->

<!-- harness:region:start id=project keep -->
## Reliability notes

- If `selftest.sh` breaks on the main line, fix it before any new feature work —
  it is the harness's only end-to-end guarantee.
- The region and marker parsers assume `gawk`; on a non-gawk system verify before
  trusting an update.
<!-- harness:region:end id=project -->
