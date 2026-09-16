# handoff-harness roadmap — future agents

> Roadmap only — not approved for build. Candidate future pipeline agents for
> discussion. Nothing here is scheduled or implemented on any branch.

This document captures ideas for possible future specialist agents in the
handoff-harness pipeline. Each entry is a discussion starting point, not a
design or a commitment. None of the agents described below exist as agent
files, commands, scripts, or pipeline routing anywhere in this repo.

## 1. Grandmaster / senior architect agent

- **Name candidate(s):** `grandmaster-architect`, `senior-architect`
- **Purpose / gap it addresses:** No whole-system architectural authority
  challenges *why* an approach is chosen and whether it is the right pattern
  versus a comfortable default. The pipeline currently has no role dedicated
  to big-picture architectural scrutiny across the whole system.
- **When it would engage:** Likely at/around the Design stage, and possibly
  as a periodic cross-cutting review touchpoint independent of any single
  feature's design.
- **Example prompts it would ask:**
  - "Have you really thought about *why* you're doing this this way?"
  - "Is this a comfortable default you're reaching for, or the right pattern
    for this problem?"
  - "What's the bigger-picture / current-best-practice approach here?"
- **User context:** The maintainer builds self-hosted apps on a comfortable
  stack — docker-compose YAMLs, `.env` files, Alpine-based web apps, CI
  publishing to Docker Hub, beta/stable tags across 3-4 apps.
- **Open questions:**
  - Should this be a standalone agent or a mode of the principal-engineer?
  - How does it avoid becoming a rubber-stamp or, conversely, a blocking
    gate that stalls every design?
  - What triggers it versus routine Design-stage review?
- **Status:** Roadmap only — not approved for build.

## 2. DevOps engineer agent

- **Name candidate(s):** `devops-engineer`
- **Purpose / gap it addresses:** No owner ensuring infra-as-code,
  config-as-code, and pipelines are up to snuff — that a pipeline exists
  where appropriate and infra is done right.
- **When it would engage:** Likely at/around the Design stage for
  infra-touching features, and at/around Review for changes that affect
  CI/CD, container builds, or deployment configuration.
- **Example prompts it would ask:**
  - "Does this change need a pipeline, and if so, does one exist?"
  - "Is this infra/config expressed as code, or is it a manual step someone
    has to remember?"
  - "Are the image tags, publish targets, and promotion path (beta to
    stable) consistent with the rest of the stack?"
- **User context:** The maintainer's self-hosted stack (docker-compose, CI
  publishing to Docker Hub, beta/stable tags) has real infra/config/pipeline
  surface that currently no agent scrutinizes.
- **Open questions:**
  - What is in scope versus out of scope (e.g., does it review
    docker-compose files, CI workflow files, both)?
  - How does it interact with the existing build-specialist role?
  - Does it need write access to propose fixes, or stay advisory like QA
    and the security agent?
- **Status:** Roadmap only — not approved for build.

## 3. Clean-code / product-cleanliness extension

- **Name candidate(s):** `clean-code-reviewer`, `product-cleanliness` (or an
  extension of the existing product-manager role)
- **Purpose / gap it addresses:** Nothing nudges toward doing things
  "mostly cleanly without being too aggressive," especially during
  retrofit/cleanup work.
- **When it would engage:** Possibly at Acceptance (as a lightweight
  cleanliness pass) or as an optional standalone touchpoint invoked when a
  project is being brought under harness discipline after the fact.
- **Example prompts it would ask:**
  - "Is this mostly clean, or does it need another pass before we call it
    done?"
  - "Are we introducing new mess while cleaning up old mess?"
  - "What's the smallest set of changes that establishes a clean baseline
    here?"
- **User context:** The maintainer works in two modes — (a) disciplined with
  the harness from day one, or (b) a rough MVP with plain Claude Code / no
  agents, then adopting the harness afterward to establish a baseline and
  clean up. This idea specifically helps the mode-(b) cleanup path.
- **Open questions:**
  - Standalone agent, or a mode/extension of the existing product-manager
    role?
  - How does it avoid pushing for aggressive rewrites when the goal is a
    pragmatic baseline?
  - Does it apply per-feature, or as a one-time onboarding pass for
    retrofit adopters?
- **Status:** Roadmap only — not approved for build.
