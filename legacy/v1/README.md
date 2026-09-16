# Legacy — handoff-harness v1

**Historical reference only. Nothing here is wired to anything.**

This is the original multi-agent SDLC pipeline: an `engineering-manager`
orchestrating hand-offs between `product-manager` → `principal-engineer` →
`software-developer` → `build-specialist` → `quality-assurance` →
`security-engineer`, coordinating through `state/feature-state.json` and inbox
files. It was superseded by v2 on 2026-09-16.

## Why it's inert

Everything that would otherwise auto-load has been moved out of its magic
location so a launching agent never picks it up:

- agent definitions are under `agents/` (not `.claude/agents/`)
- commands under `commands/` (not `.claude/commands/`)
- `CLAUDE.md` is here, not at the repo root
- the v1 `state/`, `src/` template tree, `scripts/`, `githooks/`, and installer
  all live under this folder

The repo is now governed by v2 — see the root `AGENTS.md`.

## What it's kept for

- Reference: the full v1 design, in case a decision needs its context.
- Migration: the v1→v2 migrator reads a v1 install's `.harness/manifest.json`
  to know which files it owned; `harness/` here is the shape it expects.

The current, maintained harness lives in `../../harnesses/`.
