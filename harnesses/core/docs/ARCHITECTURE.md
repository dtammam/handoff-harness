<!-- harness:region:start id=doc -->
# Architecture

*Schema template. `/seed` fills the `{{PLACEHOLDER}}` tokens by scanning the
codebase; every `## ` heading is fixed — a section may read "N/A — none" but is
never renamed or reordered. The `keep` region at the bottom is yours and
survives every harness update.*

What kind of system this is and how it's shaped. Referenced from `AGENTS.md` for
"what kind of system this is and how it's shaped." Read it before touching a part
you don't own end-to-end.

## System purpose

*What this system is for, in one or two sentences — the problem it exists to
solve, not how.*

{{SYSTEM_PURPOSE}}

## Shape / topology

*The overall form: monolith, service set, CLI, library, batch job — and how the
pieces are deployed and talk to each other.*

{{SYSTEM_TOPOLOGY}}

## Key components

*The parts that carry real responsibility, each with a one-line charter.*

{{KEY_COMPONENTS}}

## Data & state

*What data the system owns, where state lives, and what is authoritative vs.
derived.*

{{DATA_AND_STATE}}

## External dependencies & boundaries

*Systems, services, and APIs this depends on, and the line where this system's
responsibility ends and theirs begins.*

{{EXTERNAL_DEPENDENCIES}}

## Invariants

*Things that must always hold — the properties a change is never allowed to
break. Violating one is a correctness bug, not a preference.*

- {{INVARIANTS}}
<!-- harness:region:end id=doc -->

<!-- harness:region:start id=project keep -->
## Architectural decisions

*This region is yours. The harness never regenerates it on update. Record here
the significant, dated design decisions and the trade-offs behind them — the
context a fresh session needs to avoid re-litigating settled choices or breaking
one by accident.*

- _(none recorded yet — the seed step and your own edits fill this in)_
<!-- harness:region:end id=project -->
