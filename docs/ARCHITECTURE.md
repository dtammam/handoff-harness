<!-- harness:region:start id=doc -->
# Architecture

What this system is and how it's shaped. Referenced from `AGENTS.md`.

## System purpose

handoff-harness is a **modular AI-agent harness** — the scaffolding that governs
how an AI coding agent does work in a repository, plus an installer that drops
that scaffolding into any repo. v2 replaces the old multi-agent persona pipeline
with one Architect (the main session) that builds, and an independent review gate
that refutes before anything ships.

## Shape / topology

A **template tree + a bootstrap installer**, self-hosting:

- `harnesses/core/` — the distributable harness (one source of truth).
- `harnesses/install.sh` — the engine that copies `core/` into a target repo,
  region-aware; `harnesses/presets.toml` — lean/standard defaults.
- `install.sh` (root) — the curl bootstrap: clones the repo, delegates to the engine.
- The repo governs itself with its own dogfood copy of v2 at the root.
- `legacy/v1/` — the retired v1 pipeline, inert, kept for reference and migration.

## Key components

- **AGENTS.md** — canonical index the agent reads first (thin `CLAUDE.md` points to it).
- **flow.md** — the five phases, sized by the anchor dial.
- **The gate** — `lib/gate-protocol.md` + the `adversary` / `qa` / `security-brief`
  seats, sized by `scrutiny.toml`.
- **State-as-document** — `lib/harness-markers.md` (vocabulary) + `check-markers.sh` (enforcer).
- **Region ownership** — `lib/regions.md` + `apply-regions.sh` (updates that preserve edits).

## Data & state

- Work state lives in the plan docs under `docs/exec-plans/` as bound markers —
  there is no state file.
- `.harness/harness.toml` (stamp) + `.harness/manifest.lock` (footprint) are the
  only install metadata. No database, no runtime services.

## External dependencies & boundaries

- Runtime: `bash`, `git`, `awk` (gawk). Install fetches over `git`/HTTPS.
- The harness's responsibility ends at the files it installs into a target repo;
  it never runs the target's build or ships its code.

## Invariants

- **Never self-merge** — the gate always runs; the Adversary is its floor.
- Approval **markers bind to the reviewed sha**; a moved tree voids them.
- Updates **preserve `keep` regions** and refresh only harness regions.
- The gate's seats are set by **scrutiny.toml, not the builder's judgment**.
<!-- harness:region:end id=doc -->

<!-- harness:region:start id=project keep -->
## Architectural decisions

- **2026-09-16 — v1 → v2 cutover.** Collapsed the 7-persona pipeline into one
  Architect + a forked review gate; killed the `.state/` state machine in favor
  of state-as-document; made AGENTS.md canonical so the config is tool-agnostic.
  v1 archived to `legacy/v1/` rather than deleted.
- **Presets are config, not file trees.** lean/standard differ only by the default
  anchor written to `harness.toml`; the agent right-sizes per task at intake.
<!-- harness:region:end id=project -->
