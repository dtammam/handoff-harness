# handoff-harness

A modular AI-agent harness for Claude Code (and any agent that reads `AGENTS.md`).
One session — the **Architect** — designs and builds the work; an independent
**review gate** refutes it before anything ships. State lives in documents, not a
state file, and the whole thing installs into any repo with one command.

> **v2.** The earlier multi-agent persona pipeline (an engineering-manager
> orchestrating PM → engineer → developer → QA hand-offs) is retired to
> `legacy/v1/`. See [Why v2](#why-v2).

## Quick start

```bash
# Install into the current repo (asks lean vs standard)
curl -fsSL https://raw.githubusercontent.com/dtammam/handoff-harness/main/install.sh | bash

# Then, in Claude Code:
/start     # describe a piece of work; the Architect proposes an anchor + acceptance
/gate      # run the independent review gate
/release   # verify against the anchor, mark shipped, commit
/status    # read-only: where does the work stand?
```

Update later with `… | bash -s -- --update`.

## The model

```
You describe work
  → the Architect (main session): blind-spot pass, propose anchor + acceptance,
    then design + build it — no persona hand-offs, context stays in one place
  → the review gate (forked, independent): Adversary always, + QA / Security
    as the change warrants — refute by measurement, verdict bound to the sha
  → fix loop with the same reviewers until every required seat APPROVES
  → verify against the anchor, mark the plan Shipped, commit
```

**Never self-merge.** The Architect writes the code; the gate is the independence.

## The anchor

Every piece of work has an **anchor** — how "correct" is defined — proposed by the
Architect at intake and confirmed by you:

| Anchor | "Correct" is… | Use when |
|--------|----------------|----------|
| `outcome` | you eyeball the result | fast iteration, you're the arbiter |
| `spec` | a written, approved spec | interfaces / data models need deciding first |
| `tdd` | executable tests, written first | each criterion should bind a test |

The Architect states the project **default** next to its **recommendation for this
request**, and argues the difference — the default is a baseline, not a lock.

**Presets** (`lean` / `standard`) just set that default anchor; both install the
identical harness, and the gate always runs.

## The gate

Seats are chosen by `.harness/scrutiny.toml` against the diff — **not** by the
builder's judgment. The Adversary is the floor; QA and a Security pass are added
by the table. Destructive or data-losing changes force the full gate, no
discretion. It's a **protocol** (`.harness/lib/gate-protocol.md`): in Claude Code
the seats are forked subagents; in another tool you run `/gate` in a second
session — either way, a real independent review or none at all.

## State lives in documents

No state file. Each plan under `docs/exec-plans/active/` carries a bound status
block; `.harness/lib/check-markers.sh` flags any marker that's stale (approval
whose `@sha` no longer matches the content) or misfiled. Approved work moves to
`docs/exec-plans/completed/`. Plans keep the same location and `YYYY-MM-DD-<slug>`
naming the old harness used, so a repo's history stays unbroken — with one new
`harness:` header noting which style produced each plan.

## Layout (installed)

```
AGENTS.md              canonical index — the agent reads this first
CLAUDE.md              thin wrapper → AGENTS.md
.claude/
  agents/              adversary · qa · security-brief   (the gate seats)
  commands/            start · gate · release · status
  hooks/ settings.json SessionStart hook (branch, plans, marker health)
.harness/
  harness.toml         install stamp: flavor, version, targets, default anchor
  manifest.lock        what the harness placed, and how it owns each file
  flow.md scrutiny.toml lib/…   the harness's own reference + tools
docs/
  CONTRIBUTING.md ARCHITECTURE.md RELIABILITY.md   (schema'd, project-owned)
  exec-plans/active/ completed/                     (the plans = the state)
```

Updates refresh harness-owned regions and **never touch** your `keep` regions or
project-owned files — region ownership, no checksums, no merge conflicts on the
files you hand-tune (`.harness/lib/regions.md`).

## Works beyond Claude Code

`AGENTS.md` is canonical, so Cursor, Codex, and other agents get the same
operating model and standards. The executable layer (forked seats, slash
commands) is Claude Code-native; elsewhere the gate runs as a second session per
the protocol.

## Why v2

v1 split the *build* across role-agents that handed work down a line, coordinating
through a `.state/feature-state.json` machine. In practice the hand-offs lost
context and the state file went stale. v2 keeps one builder and spends the
independent-agent budget where it catches bugs — an adversarial review gate — and
tracks state in the working documents themselves. v1 remains in `legacy/v1/`,
inert, for reference and migration.

## Requirements

`bash`, `git`, and `gawk`. macOS and Linux; Windows via WSL.

## License

MIT — see [LICENSE](LICENSE).
