# Security agent + clean upgrade path + future-agents roadmap

**Stage:** Design
**Date:** 2026-07-06
**Branch:** feature/security-agent
**Feature ID:** security-agent

---

## Goal

Add a security specialist agent to the handoff-harness pipeline with an early
seat (Discovery/Design) and a late seat (post-implementation review), ensure
that adding it (and any future harness change) reaches already-installed
repos through a painless `install.sh --update` while greenfield installs stay
clean, and capture three additional future-agent ideas in a roadmap document
for later discussion — without building them.

---

## Background / context

handoff-harness IS a multi-agent SDLC pipeline, distributed via `install.sh`
into other repos (the "target" or "downstream" repo). This feature is
meta-work: we are changing the harness itself, on the harness's own repo, so
that the change can subsequently be pulled into every downstream repo where
the harness is already installed.

The maintainer (dean@tamm.am) runs the harness across multiple repos and
has identified a recurring gap: no security expert participates in the
pipeline. Security should have a seat at the table early (while requirements
and design are still forming, not only bolted on at the end) and a seat late
(a dedicated pass after implementation and QA, before acceptance). The
maintainer is intentionally non-prescriptive about the agent's exact
responsibilities, trusting Discovery/Design to shape a sensible role, and
has asked for a naming recommendation.

Equally important to the maintainer: this agent (and anything else shipped
on this branch) must reach existing installs cleanly. The installer already
distinguishes greenfield (clean, no existing files) from brownfield
(existing/customized files), and further distinguishes file categories via
`get_category()` in `install.sh`:

- `harness-owned` (`.claude/agents/*`, `.claude/commands/*`, `.claude/hooks/*`,
  `scripts/*`, `hooks/*`, `.claude/settings.json`, `.harness/*`) — copied/
  overwritten unconditionally on update.
- `project-owned` (`CLAUDE.md`, `docs/CONTRIBUTING.md`, `docs/ARCHITECTURE.md`,
  `docs/AGENTS.md`, `docs/RELIABILITY.md`, `docs/QUALITY_SCORE.md`) — on
  update, overwritten only if the local file's checksum still matches the
  manifest baseline (i.e., unmodified by the user); otherwise a
  `<file>.harness-update` sidecar is written for manual merge.
- `scaffold` (everything else, including any *new* doc file with no explicit
  case arm) — on `--update`, scaffold files are unconditionally **skipped**
  (see `install.sh`, update flow, Step 7: `scaffold) skipped=$((skipped+1))`),
  with no check for whether the file already exists locally. This is a
  structural gap: a brand-new scaffold-category file introduced in a harness
  release will never reach an already-installed repo via `--update`, even
  though it would reach a fresh install just fine (fresh install copies
  every file directly on greenfield, or on brownfield when the file doesn't
  already conflict).

This gap directly threatens deliverable 2 for the roadmap document (a new,
previously-nonexistent doc file) unless its `get_category()` classification
is deliberately chosen to avoid it, or the gap itself is fixed. This
Discovery does not resolve the "how" (that is Design's job) but requires the
final implementation to demonstrably not lose the roadmap doc — or any other
new file — on `--update`.

A second structural tension, already flagged in the inbox: wiring the
security agent into `CLAUDE.md`'s agent table is a change to a
`project-owned` file. Any target repo where the maintainer has already
customized `CLAUDE.md` (which is the expected common case, since setup asks
users to fill in placeholders) will have a checksum mismatch against the
manifest baseline, so the update will **not** auto-apply the new table row —
it will land as a `.harness-update` sidecar requiring manual merge. This
conflicts with the maintainer's "just get the new things... it should just
do the things" expectation. Discovery captures this as a requirement/risk
that Design must resolve; Discovery does not prescribe the mechanism.

Finally, `docs/AGENTS.md` is explicitly human-maintained. No pipeline agent
(including the principal-engineer or software-developer working this
feature) may read-to-modify or overwrite it. Any desired addition to
`docs/AGENTS.md` (e.g., a security-engineer row in its "Agent boundaries"
table) must be listed as a manual human follow-up in this plan's final
report, never committed by the pipeline.

---

## In scope

1. **A new Security agent**, added to the pipeline with:
   - A recommended name (see Open questions / recommendations).
   - A defined role and responsibilities, consistent with the pattern of
     existing agent files (`.claude/agents/*.md`), including an "On startup"
     reading list, a defined output/report format, and a "Rules" section.
   - **Early touchpoints:** engaged at the start of Discovery (alongside the
     product-manager forming requirements) and at the start of Design
     (alongside the principal-engineer forming the design). Exact mechanics
     (parallel invocation, an added inbox step, a new exec-plan section it
     populates, etc.) are Design's decision — Discovery only requires that
     both touchpoints exist and are documented in the pipeline's routing
     logic (`.claude/agents/engineering-manager.md` and associated
     `prep-*`/`run-*` commands and scripts).
   - **Late touchpoint:** engaged at or directly after the
     quality-assurance (Review) stage, after implementation is complete and
     before Acceptance.
   - Full wiring into the pipeline surface: an agent file (root + `src/`
     mirror), any new `prep-*`/`run-*` command(s) and `scripts/run-*.sh`
     needed to invoke it (root + `src/` mirrors), and a row in `CLAUDE.md`'s
     agent table (root + `src/` mirror).
   - Preserves human-in-the-loop gating: the security agent is advisory. It
     does not block, veto, or auto-progress any stage; the human retains
     approval authority at every existing gate.

2. **A clean, painless upgrade path for existing installs**, covering:
   - Greenfield/fresh installs remain clean (already largely true; verify no
     regression).
   - Brownfield/already-installed repos running `install.sh --update` pick
     up every new file this feature introduces (agent file, command files,
     scripts) automatically, without manual surgery, per the existing
     `harness-owned` category behavior.
   - The `docs/AGENTS.md` human-maintained-file constraint is preserved:
     no automated update path may write to it.
   - The specific `CLAUDE.md`/`project-owned` merge-friction risk described
     above is explicitly addressed by Design (not necessarily eliminated,
     but not silently ignored either — the maintainer must be able to tell,
     from the printed installer output, that something needs their
     attention and exactly what to do about it).
   - The scaffold-category "new file never reaches existing installs on
     `--update`" gap is explicitly addressed for every new file this feature
     ships (agent file, command files, scripts, and the roadmap doc).

3. **A roadmap document** (doc-only, nothing described in it gets built)
   capturing three future agent ideas for later discussion:
   - Grandmaster / senior architect agent
   - DevOps engineer agent
   - Clean-code / product-cleanliness extension (new agent or PM extension)

---

## Out of scope

- **Building** the grandmaster/senior-architect agent, the DevOps engineer
  agent, or the clean-code/product-cleanliness extension. These are
  roadmap-only for this branch.
- Any edit to `docs/AGENTS.md` performed by a pipeline agent. Desired
  human-maintained additions (e.g., a security-engineer row in its Agent
  boundaries table) are called out as a manual follow-up item, not pipeline
  output.
- Actually running `install.sh --update` against the maintainer's other,
  real downstream repos. This feature only needs to make that subsequent,
  separate action painless when the maintainer chooses to do it; performing
  those migrations is not part of this branch.
- Introducing an automated test framework, package manager, or compiled
  code. This repo is shell + Markdown only (consistent with prior exec
  plans, e.g., `remove-version-relocate-manifest`); verification of the
  installer changes is manual/scripted-manual, not a new CI framework.
- Renaming, restructuring, or otherwise changing existing agents
  (product-manager, principal-engineer, software-developer, build-specialist,
  quality-assurance, engineering-manager) beyond the minimal wiring needed to
  reference the new security agent at its touchpoints.
- Changing `install.sh`'s external interface (URL, flags, usage pattern).

None of the above conflicts with a mandatory standard in `CLAUDE.md` or
`docs/CONTRIBUTING.md`: the human-in-the-loop, no-auto-progress, explicit
staging, no-force-push, and no-`--no-verify` rules in `CLAUDE.md` are
preserved everywhere above, and `docs/CONTRIBUTING.md`'s definition of done
(build/tests/lint clean, no untracked TODOs) is respected — this repo has no
build/test/lint tooling to run beyond the existing manual verification
protocol already established for `install.sh` changes.

---

## Constraints

- **Template mirroring:** every repo-root file this feature adds or changes
  under `.claude/agents/`, `.claude/commands/`, `scripts/`, or `.claude/hooks/`
  MUST have an identical (or intentionally-noted-divergent) counterpart under
  `src/` in the same relative path, or the installer will never ship it to
  any repo. `CLAUDE.md` changes likewise require a `src/CLAUDE.md` mirror.
  `install.sh` itself is NOT part of the `src/` payload (it is fetched fresh
  by curl/git-clone on every run) and therefore has no `src/install.sh`
  counterpart to keep in sync.
- **Installer categorization:** `.claude/agents/*`, `scripts/*`,
  `.claude/commands/*`, and `.claude/hooks/*` are matched by existing
  wildcard case arms in `get_category()` and already resolve to
  `harness-owned` — new files under these directories should not require a
  new case arm, but this must be explicitly verified, not assumed, for every
  new path this feature introduces. Any *new* doc file (e.g. the roadmap
  doc) does NOT have a wildcard match under `docs/*` (only specific
  filenames are matched); it will fall through to the default `scaffold`
  arm unless a deliberate categorization decision is made — and `scaffold`
  files are silently skipped by the current `--update` flow regardless of
  whether they already exist locally. This must be resolved by Design, not
  ignored.
- **`CLAUDE.md`/`project-owned` friction:** wiring the security agent into
  `CLAUDE.md`'s agent table may not auto-apply on `--update` for any repo
  where the maintainer customized `CLAUDE.md` (the expected common case).
  Capture as a requirement/risk; Design owns the resolution mechanism.
- **`docs/AGENTS.md` is human-maintained:** no pipeline agent may read-to-
  modify or overwrite it, ever, in this feature.
- **Human-in-the-loop gates unchanged:** the security agent must not
  auto-progress stages; it advises at its touchpoints only.
- **Git hygiene:** no force-push, no `--no-verify`, explicit `git add
  <file>` staging (never `git add .`/`git add -A`), imperative commit
  messages with the `Co-authored-by: Claude <noreply@anthropic.com>` trailer.

---

## Requirements

### R-1: Security agent identity, role, and responsibilities

**R-1.1** A new agent name MUST be chosen and justified (see recommendation
below). It MUST be kebab-case, consistent with existing agent slugs
(`product-manager`, `principal-engineer`, `software-developer`,
`build-specialist`, `quality-assurance`, `engineering-manager`).

**R-1.2** A new agent file MUST exist at `.claude/agents/<name>.md`, mirrored
byte-for-byte (content-equivalent) at `src/.claude/agents/<name>.md`. It MUST
follow the structural pattern of existing agent files: frontmatter (`name`,
`description`, `tools`, `model`), an "On startup" reading list (at minimum:
its own inbox file, `.state/feature-state.json`, `docs/CONTRIBUTING.md`,
`docs/ARCHITECTURE.md`, `docs/RELIABILITY.md`, and the active exec plan), a
defined body of responsibilities, an explicit output/report format, and a
"Rules" section.

**R-1.3** The agent's responsibilities MUST explicitly cover both of its
engagement modes (see R-2): reviewing requirements/design for security
implications early, and reviewing implemented code/artifacts for
vulnerabilities late. The exact checklist content (e.g., threat modeling,
secrets handling, input validation, dependency risk, auth/authz, injection
classes) is a Design decision, not a Discovery decision — Discovery only
requires that both modes are named and scoped.

**R-1.4** The agent MUST be advisory, not a blocking authority: it reports
findings; it does not fix code, does not modify requirements or designs
directly, and does not decide whether a stage advances. This mirrors the
existing `quality-assurance` agent's non-blocking, report-only posture.

### R-2: Early and late touchpoints

**R-2.1** The security agent MUST be engaged at the **start of Discovery**
(concurrent with or immediately adjacent to the product-manager's
requirements-gathering) so that security considerations can be reflected in
the exec plan's requirements and acceptance criteria before Design begins.

**R-2.2** The security agent MUST be engaged at the **start of Design**
(concurrent with or immediately adjacent to the principal-engineer's design
work) so that security considerations inform the design before
implementation tasks are broken out.

**R-2.3** The security agent MUST be engaged **at or directly after the
Review (quality-assurance) stage** — after implementation is complete —
producing a security-focused pass over the final diff before Acceptance.

**R-2.4** All three touchpoints MUST be documented in
`.claude/agents/engineering-manager.md`'s stage-by-stage routing logic (and
mirrored in `src/.claude/agents/engineering-manager.md`), each specifying:
which inbox file is written (`.state/inbox/<security-agent-name>.md`), what
the security agent reads, and what it's expected to produce (e.g., a
"Security notes" or "Security review" section appended to the exec plan,
and/or a report to the user).

**R-2.5** None of the three touchpoints may cause automatic advancement of
`.state/feature-state.json`'s `stage` field. Advancing stages remains
subject to the same explicit-user-approval gate as every other transition.

**R-2.6** The pipeline's user-facing wiring (any new or updated
`prep-*`/`run-*` commands, and any new `scripts/run-*.sh`) MUST let the user
invoke the security agent through the same mechanism as existing specialists
(inbox file check → `claude --agent <path> < inbox`), consistent with
`scripts/run-quality-assurance.sh`'s pattern.

### R-3: Pipeline surface wiring

**R-3.1** `CLAUDE.md`'s agent table MUST include a row for the new security
agent (role + when-to-invoke), mirrored in `src/CLAUDE.md`.

**R-3.2** Any new command file(s) needed to invoke the security agent
(e.g., a `run-*` command for the mobile workflow, and/or updates to
`prep-pm-discover.md`, `prep-pe-design.md`, and `prep-qa-review.md` noting
the adjacent security touchpoint) MUST exist at `.claude/commands/` and be
mirrored at `src/.claude/commands/`.

**R-3.3** A new `scripts/run-<security-agent-name>.sh` MUST exist and be
mirrored at `src/scripts/run-<security-agent-name>.sh`, following the
existing script pattern (verify inbox file exists and is non-empty; invoke
`claude --agent <agent-file> < inbox`).

**R-3.4** `docs/AGENTS.md` MUST NOT be modified by this feature. If a
security-agent row is wanted in its "Agent boundaries" table, this MUST be
listed as an explicit manual human follow-up in this plan's final summary,
not committed by any pipeline agent.

### R-4: Greenfield installs stay clean

**R-4.1** Running `install.sh` (fresh install, no `--update`) into an empty
target directory MUST place the security agent's file(s), command(s),
script(s), and the roadmap doc, with no `.harness-update` sidecars and no
errors — matching current greenfield behavior for all other harness-owned
and scaffold files.

### R-5: Brownfield upgrades are painless

**R-5.1** Running `install.sh --update` against a target that already has a
prior harness install MUST copy every new `harness-owned` file this feature
introduces (agent file, command files, scripts) automatically, with no
manual merge step required — this MUST be true regardless of whether the
target's `CLAUDE.md`/other project-owned files have been customized, since
these new files are harness-owned, not project-owned.

**R-5.2** The roadmap document (and any other net-new doc file this feature
introduces) MUST reach an already-installed target via `install.sh
--update`. The implementation MUST NOT rely on the current default
`scaffold` categorization if that categorization would cause the file to be
silently skipped forever on update (per the structural gap described in
Background). Design chooses the resolution (e.g., a new category, a fix to
the scaffold-skip logic for files that don't yet exist locally, an explicit
`harness-owned` classification, etc.) — Discovery only requires the outcome
be demonstrably true.

**R-5.3** The `CLAUDE.md` agent-table wiring risk (R-2.4/R-3.1 depend on a
`project-owned` file) MUST be explicitly addressed by Design such that the
maintainer is never left silently out of date — either the update applies
automatically when safe (unmodified `CLAUDE.md`), or a clearly surfaced
`.harness-update` sidecar with actionable instructions is produced when the
file was customized. Silent, undetectable loss of the update is not
acceptable.

**R-5.4** `install.sh`'s `get_category()` MUST correctly classify every new
file path this feature introduces. Each new path must be traced through the
existing case statement (or an added case arm) and confirmed not to fall
through to an unintended category.

### R-6: Roadmap document

**R-6.1** A new, doc-only file MUST be created at **`docs/ROADMAP.md`**
(top-level `docs/`, decided by the maintainer at the Discovery gate — NOT
`docs/roadmap/future-agents.md`) capturing the three future agent ideas:
grandmaster/senior-architect agent, DevOps engineer agent, and
clean-code/product-cleanliness extension.

**R-6.2** For each of the three, the document MUST capture, at minimum:
name candidate(s), the problem/gap it addresses, the user context given in
this feature's inbox (self-hosted docker-compose/Alpine/CI-to-Docker-Hub
stack for the architect angle; infra-as-code/config-as-code/pipeline
sufficiency for the DevOps angle; the two adoption modes — disciplined from
day one vs. retrofit-after-MVP-cleanup — for the clean-code angle), and an
explicit "roadmap only — not approved for build" marker.

**R-6.3** The document MUST NOT include implementation details, agent
files, commands, or scripts for any of the three ideas — discussion-ready
content only.

**R-6.4** The document's location and `get_category()` classification MUST
satisfy R-5.2 (it must reach existing installs on `--update`, not just
fresh installs).

---

## Acceptance criteria

- [ ] **AC-1:** `.claude/agents/<security-agent-name>.md` exists, is
      mirrored at `src/.claude/agents/<security-agent-name>.md`, and
      contains a role description, an "On startup" reading list, defined
      responsibilities covering both early and late engagement modes, an
      output/report format, and a "Rules" section stating it is advisory
      (does not fix code, does not auto-progress stages).
- [ ] **AC-2:** `.claude/agents/engineering-manager.md` (and its `src/`
      mirror) documents at least three explicit security-agent touchpoints:
      at/adjacent to Discovery start, at/adjacent to Design start, and
      at/after the Review (QA) stage before Acceptance — each specifying
      the inbox file written and expected output.
- [ ] **AC-3:** `CLAUDE.md` (and `src/CLAUDE.md`) contains a row for the new
      security agent in its agent table with role and "when" columns
      filled in.
- [ ] **AC-4:** A `scripts/run-<security-agent-name>.sh` exists, is
      mirrored at `src/scripts/run-<security-agent-name>.sh`, and follows
      the existing pattern (inbox existence/non-empty check, `claude
      --agent ... < inbox`).
- [ ] **AC-5:** At least one new or updated command file exists under
      `.claude/commands/` (mirrored under `src/.claude/commands/`) that lets
      a user invoke the security agent at each of its three touchpoints,
      consistent with the existing `run-*`/`prep-*` command pattern.
- [ ] **AC-6:** `docs/AGENTS.md` shows no diff introduced by this feature
      (`git diff main -- docs/AGENTS.md` is empty); if a security-agent row
      is desired there, it is documented as a manual human follow-up in the
      final report, not committed.
- [ ] **AC-7:** A fresh install test (running `install.sh` with no
      `--update` against an empty target directory) places the security
      agent's file, its command(s), its script, and the roadmap doc, with
      zero `.harness-update` sidecars and zero errors.
- [ ] **AC-8:** An update test (running `install.sh --update` against a
      target simulating a prior install — i.e., an existing `.harness/manifest.json`
      whose checksums predate this feature) results in the security agent's
      file, command(s), and script being copied in automatically with no
      manual merge required.
- [ ] **AC-9:** The same update test (AC-8) demonstrates that the roadmap
      doc reaches the target — i.e., it is present in the target directory
      after `--update` completes, not silently skipped as an
      already-forever `scaffold` file.
- [ ] **AC-10:** The same update test (AC-8), run against a target whose
      local `CLAUDE.md` has been intentionally modified (checksum mismatch
      vs. manifest), demonstrates one of: (a) the security-agent row is
      merged into the target's `CLAUDE.md` automatically, or (b) a
      `CLAUDE.md.harness-update` sidecar is produced along with printed
      output that clearly tells the user a merge is needed and why. Silent
      loss of the update (no sidecar, no message, no applied change) is a
      failure.
- [ ] **AC-11:** Tracing every new file path this feature introduces
      through `install.sh`'s `get_category()` confirms each resolves to the
      intended category (no unintended fallthrough to a category that would
      break AC-8/AC-9/AC-10).
- [ ] **AC-12:** A new doc-only file exists at `docs/ROADMAP.md` documenting
      all three future agents (grandmaster/senior-architect, DevOps engineer, clean-code/
      product-cleanliness extension), each with a name candidate, problem
      statement, relevant user context, and an explicit "roadmap only — not
      approved for build" marker; no agent files, commands, or scripts exist
      anywhere in the repo for any of the three.
- [ ] **AC-13:** `git diff main` for this feature touches no files under
      `.claude/agents/` other than the new security agent file and (if
      applicable) `engineering-manager.md`'s routing-logic update — i.e.,
      product-manager, principal-engineer, software-developer,
      build-specialist, and quality-assurance agent files are otherwise
      unchanged in role/responsibilities.
- [ ] **AC-14:** `install.sh`'s external interface is unchanged: same URL,
      same `--update`/`--branch=` flags, same usage pattern before and
      after this feature.

---

## Open questions / recommendations

**Recommended agent name: `security-engineer`.**

Rationale: it mirrors the existing role-noun pattern already in the pipeline
(`principal-engineer`, `software-developer`, `build-specialist`,
`quality-assurance`) rather than introducing a differently-shaped name like
`security-expert` or `application-security`. "Engineer" signals a broad,
technical, hands-on role capable of both advisory review (early) and
technical audit (late) — matching the two engagement modes requested —
without narrowing scope the way "specialist" might (which the pipeline
already uses for the build-focused `build-specialist`) or sounding like a
static compliance function the way "security-expert" might. It is also the
most common industry job title for this function, which should make the
agent's purpose immediately legible to anyone reading `CLAUDE.md`'s agent
table.

Alternatives considered and why they were set aside: `security-expert` (less
consistent with the existing "-engineer/-manager/-specialist" naming
texture); `application-security` (reads as a domain/noun rather than a
role, inconsistent with every other agent slug being a person-role);
`security-reviewer` (undersells the early-touchpoint, requirements/design-
shaping half of the role, implying review-only).

**Open question for Design:** how to resolve R-5.2 (new scaffold-category
files silently skipped forever on `--update`) and R-5.3 (`CLAUDE.md`
project-owned merge friction) mechanically. Both are flagged as hard
requirements in this plan; the specific fix (new manifest category, a
scaffold "copy if missing locally" fix, a targeted CLAUDE.md merge strategy,
etc.) is intentionally left to the principal-engineer.

**Open question for the maintainer:** RESOLVED at the Discovery gate — the
roadmap document lives at top-level **`docs/ROADMAP.md`**. Note this path has
no explicit `get_category()` case arm and falls through to `scaffold`, so it
directly triggers the R-5.2 structural gap; Design MUST resolve how it
reaches existing installs on `--update`.

---

## Design

### Approach

This feature adds one advisory pipeline agent (`security-engineer`) and wires it
into three routing touchpoints, while making the harness's `install.sh --update`
path deliver net-new files to already-installed repos. The design is deliberately
minimal and leans on an existing structural fact of the pipeline: **all functional
routing lives in harness-owned files** (`.claude/agents/*`, `.claude/commands/*`,
`scripts/*`), which the installer already overwrites unconditionally on `--update`.
`CLAUDE.md` is only human/main-session documentation. That single fact is the key
to both upgrade risks: because the agent file, its run script, its command, and the
engineering-manager routing are all harness-owned, the security-engineer becomes
**fully operational on every upgraded install automatically** — the `CLAUDE.md`
table row is cosmetic and its lag (Risk B) cannot break the agent.

The two upgrade risks are solved mechanically. **Risk A** is fixed generally by
changing the `scaffold` branch of the update loop from an unconditional skip to a
**copy-if-missing** rule, so any net-new scaffold file (including `docs/ROADMAP.md`
and every future one) reaches existing installs, with zero clobber risk for
existing scaffold files. **Risk B** is solved by keeping `CLAUDE.md` project-owned
(respecting user customization), carrying all functional registration in
harness-owned files, and adding a **targeted, loud `CLAUDE.md` merge note** to the
installer's update output so the residual cosmetic step is deterministic and
visible, never silent.

Files created: `.claude/agents/security-engineer.md`,
`scripts/run-security-engineer.sh`, `.claude/commands/run-security.md`,
`docs/ROADMAP.md` (each with its `src/` mirror). Files modified:
`.claude/agents/engineering-manager.md`, three `prep-*` commands, `CLAUDE.md`
(each with its `src/` mirror), and `install.sh` (no `src/` mirror — not part of
the payload). `docs/AGENTS.md` and `docs/ARCHITECTURE.md` are intentionally not
modified (see Component changes).

### Component changes

- **`.claude/agents/security-engineer.md` (new, + `src/` mirror)**: The agent
  file. Frontmatter:

  ```yaml
  ---
  name: security-engineer
  description: >
    Advisory security specialist. Reviews requirements and design for security
    implications early, and audits the implemented diff for vulnerabilities late.
    Invoked by the engineering-manager via inbox files. Reports findings and a
    single top-line verdict; does not fix code, does not write to any file, and
    does not advance stages.
  tools: Read, Glob, Grep
  model: sonnet
  ---
  ```

  Posture: **strictly read-only, exactly like `quality-assurance`** — tools are
  `Read, Glob, Grep` only (no `Edit`, no `Write`). The agent emits its verdict and
  findings as a report to the engineering-manager/user; the **EM records the
  verdict** into the exec plan (as a `## Security review — <phase>` section), the
  same way the EM records QA's outcome. The agent itself never writes to any file.

  Body sections:
  - **"On startup"** reading list (satisfies R-1.2): (1)
    `.state/inbox/security-engineer.md`, (2) `.state/feature-state.json`, (3)
    `docs/CONTRIBUTING.md`, (4) `docs/ARCHITECTURE.md`, (5) `docs/RELIABILITY.md`,
    (6) the active exec plan referenced in the inbox, and — **in late mode only**
    — (7) `git diff main` (or the recorded base branch).
  - **Responsibilities — early mode (Discovery/Design)**: lightweight threat model
    (assets, trust boundaries, threat actors; STRIDE-lite); flag security-relevant
    requirements (authn/authz, data sensitivity/PII, secrets management,
    input/output boundaries, third-party/dependency risk, privacy/compliance);
    propose **suggested security acceptance criteria** (Discovery) and **security
    design constraints** (Design) for the PM/PE to fold in.
  - **Responsibilities — late mode (post-QA audit)**: review `git diff main` for
    vulnerability classes — injection (SQL/command/path/template), committed
    secrets/credentials, missing input validation at boundaries, missing authz
    checks, insecure deserialization, SSRF, unsafe file/temp-file operations,
    crypto misuse, dependency risk, and sensitive-data logging. Because the harness
    itself is shell + Markdown, the checklist explicitly calls out shell-specific
    risks: unquoted expansions, `eval`, `curl | bash` trust, path traversal,
    `mktemp`/temp-file races, and untrusted-input injection into commands.
  - **Severity model** (each finding is banded): CRITICAL / HIGH / MEDIUM / LOW /
    INFO. Each finding carries a one-line **impact × likelihood** rationale in the
    OWASP Risk Rating style — contextual, not raw CVSS numerics. The context that
    governs the rating is stated in the agent file: this harness serves **solo-dev,
    self-hosted applications**, so reasoning favors realistic impact and likelihood
    for that deployment over generic worst-case CVSS scores (the familiar band
    names are kept for legibility).
  - **Verdict model** (the core output — one unambiguous top-line verdict, mirroring
    QA's APPROVE / REQUEST CHANGES texture, gated by a severity threshold):
    - **PASS** — no Critical or High findings.
    - **PASS WITH CONDITIONS** — only Medium/Low findings remain, each either
      quick-fixed or explicitly **risk-accepted with written rationale** (the analog
      of QA's "APPROVED WITH NITS").
    - **FAIL — BLOCKED** — one or more Critical/High findings unresolved. This is a
      **HARD GATE**: the feature cannot clear Acceptance until the finding is
      resolved, or (rare) the maintainer explicitly signs off a documented risk
      acceptance.

    The **default gate threshold** is stated in the agent file and is adjustable:
    **CRITICAL and HIGH block; MEDIUM and LOW are accept-with-rationale; INFO is
    advisory only.** The agent file documents that a maintainer may tune this
    threshold per-project.
  - **Report format** (satisfies R-1.2 output format; top-line verdict first so the
    outcome is never ambiguous):

    ```text
    SECURITY VERDICT: <PASS | PASS WITH CONDITIONS | FAIL — BLOCKED>

    Security Review — <Discovery|Design|Implementation>: <Feature Name>
    Date: YYYY-MM-DD
    Mode: <early requirements/design review | late code/diff audit>
    Scope: <what was reviewed>
    Gate threshold: CRITICAL/HIGH block; MEDIUM/LOW accept-with-rationale

    Threat surface: <one or two sentences>

    Findings (grouped by severity):
    CRITICAL:
    - [ref] [description] — impact×likelihood: [one line] → [mitigation]
    HIGH:
    - [ref] [description] — impact×likelihood: [one line] → [mitigation]
    MEDIUM:
    - [ref] [description] — impact×likelihood: [one line] → [fix or risk-accept + rationale]
    LOW:
    - [ref] [description] — impact×likelihood: [one line] → [fix or risk-accept + rationale]
    INFO:
    - [ref] [note]

    Suggested security acceptance criteria / design constraints (early modes):
    - ...

    Verdict rationale: <one or two sentences tying the top-line verdict to the
    findings above and the gate threshold>
    ```

    The agent **prints this report to the user/EM only** — it writes to no file. The
    **EM records** the verdict and findings into the exec plan as a
    `## Security review — <phase>` section, exactly as it records QA's outcome.
  - **"Rules"** (satisfies R-1.4, advisory posture): report findings and a single
    top-line verdict, never fix code; **read-only — write to no file, ever** (no
    `Edit`/`Write` tool; never modify source, config, requirements, design, the
    exec plan, or `.state/feature-state.json`); never advance stages (the verdict is
    advice to the human gate, not an automatic transition); apply the stated gate
    threshold consistently; run ONE touchpoint per invocation, then stop; ALWAYS
    verify artifacts exist at their state-recorded paths before proceeding;
    prioritize ruthlessly; if the change is clean, emit `SECURITY VERDICT: PASS` and
    say so briefly.

- **`.claude/agents/engineering-manager.md` (modified, + `src/` mirror)**: add the
  three touchpoints into the existing stage subsections without removing anything
  (see "Three touchpoints" below). Harness-owned → reaches every install on
  `--update` automatically.

- **`scripts/run-security-engineer.sh` (new, + `src/` mirror)**: byte-for-pattern
  copy of `scripts/run-quality-assurance.sh` with
  `AGENT=".claude/agents/security-engineer.md"` and
  `INBOX=".state/inbox/security-engineer.md"`; same non-empty-inbox guard and
  `claude --agent "$AGENT" < "$INBOX"` invocation.

- **`.claude/commands/run-security.md` (new, + `src/` mirror)**: mobile-workflow
  run command mirroring `run-qa.md`; verifies
  `.state/inbox/security-engineer.md` exists/non-empty, then runs
  `bash scripts/run-security-engineer.sh`. This single command is the invocation
  surface for all three touchpoints (which touchpoint is active is determined by
  the inbox the EM wrote), matching how `run-qa.md` is reused.

- **`.claude/commands/prep-pm-discover.md`, `prep-pe-design.md`,
  `prep-qa-review.md` (modified, + `src/` mirrors)**: each gains a short
  "Security touchpoint" note instructing the EM to also write
  `.state/inbox/security-engineer.md` for that phase and telling the user to
  optionally run the "Run Security Engineer" task (`/run-security`) after the
  primary agent. No behavior of the existing agents changes.

- **`CLAUDE.md` (modified, + `src/` mirror)**: add a `security-engineer` row to the
  Agents table (role + when) and a `/run-security` row to the Commands table.
  Project-owned; see Risk B for how it reaches installs.

- **`docs/ROADMAP.md` (new, + `src/` mirror)**: doc-only roadmap (see "Roadmap
  document" below).

- **`install.sh` (modified, no `src/` mirror)**: two surgical edits (Risk A scaffold
  copy-if-missing; Risk B `CLAUDE.md` merge note). External interface unchanged
  (AC-14).

- **`docs/ARCHITECTURE.md` — intentionally NOT modified.** It is a project-owned
  template full of `{{placeholders}}` that describes the *downstream* project's
  architecture, and its `src/` mirror is shipped to every install. Injecting
  harness-pipeline description into it would pollute every downstream repo's
  architecture doc and would create an avoidable project-owned sidecar on
  `--update`. The pipeline roster is already documented in `CLAUDE.md`'s agent
  table, the agent files themselves, and `docs/AGENTS.md`. This is a deliberate
  scope decision; it does not conflict with the inbox's "if appropriate" clause.

- **`docs/AGENTS.md` — intentionally NOT modified** (R-3.4, AC-6). It is
  human-maintained. The desired `security-engineer` row is recorded as a manual
  follow-up in the final report only.

### Three touchpoints (engineering-manager routing)

All three write the same inbox, `.state/inbox/security-engineer.md`, read the
active exec plan plus standards, and produce a **printed report with a top-line
`SECURITY VERDICT`** that the **EM records** into the exec plan as a
`## Security review — <phase>` section (the read-only agent writes nothing itself,
same as QA). None of them **touch `.state/feature-state.json.stage`** (satisfies
R-2.5, AC-2). They are added as sub-bullets inside existing EM stages:

1. **Discovery start** (inside the `### Discovery` stage of
   `engineering-manager.md`): after writing the product-manager inbox, also write
   the security-engineer inbox for an *early requirements review*. Sequence: run
   PM first (drafts the exec plan), then run security-engineer, which reports
   suggested security requirements/acceptance criteria; the EM records the verdict
   as `## Security review — Discovery` and the human/PM folds accepted items in.
   Ordering after the PM avoids a race on the not-yet-existing exec plan.

2. **Design start** (inside `### Design`): after writing the principal-engineer
   inbox, also write the security-engineer inbox for an *early design review*.
   Sequence: PE drafts the Design section, then security-engineer reports a threat
   model of the proposed approach + security design constraints; the EM records the
   verdict as `## Security review — Design`.

3. **At/after Review, before Acceptance** (inside `### Review`): after the QA pass,
   write the security-engineer inbox for the *late diff audit* over `git diff main`.
   The agent reports findings and a top-line `SECURITY VERDICT`; the EM records it
   as `## Security review — Implementation`. The verdict is a **hard gate** for the
   human at Acceptance (a `FAIL — BLOCKED` must be resolved or explicitly
   risk-accepted by the maintainer), but the agent still does not auto-advance or
   auto-block `stage` — the human enforces the gate.

Each EM sub-bullet explicitly states: inbox written =
`.state/inbox/security-engineer.md`; agent reads = active exec plan + state +
`CONTRIBUTING.md`/`ARCHITECTURE.md`/`RELIABILITY.md` (+ `git diff main` for
touchpoint 3); output = a printed `SECURITY VERDICT` report that the **EM records**
as the corresponding `## Security review — <phase>` section; and "this does not
advance `stage` — approval gates are unchanged." A matching line is added to the EM
"Rules" list noting the security-engineer is advisory (read-only, never writes,
never advances a stage) and that a `FAIL — BLOCKED` verdict is a human-enforced
gate before Acceptance.

### Risk A resolution — scaffold copy-if-missing (chosen mechanism)

**Chosen mechanism:** change only the `scaffold` arm of the UPDATE flow's Step 7
per-file loop in `install.sh` from an unconditional skip to copy-if-missing.
`get_category()` is **not** changed, so the manifest categories it emits are
unaffected; `docs/ROADMAP.md` continues to resolve to `scaffold` via the default
`*` arm.

Before:

```bash
scaffold)
  skipped=$((skipped + 1))
  ;;
```

After:

```bash
scaffold)
  if [ ! -f "$dest" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    updated=$((updated + 1))
  else
    skipped=$((skipped + 1))
  fi
  ;;
```

**Precise before/after behavior and no-regression proof:**

- *Existing local scaffold files* (`setup.sh`, `*.gitkeep`,
  `docs/exec-plans/tech-debt-tracker.md`, and any user exec plans) already exist in
  an installed repo, so `[ ! -f "$dest" ]` is false → they hit the `else` branch →
  `skipped` → preserved, byte-for-byte identical to today. No regression, and
  user-owned scaffold edits are never clobbered because copy only happens when the
  file is **absent**.
- *Net-new scaffold files* (`docs/ROADMAP.md` today, any future one) are absent
  locally → copied in fresh, closing the structural gap for the whole class, not
  just this feature (satisfies R-5.2, AC-9). The Step 9 manifest regeneration then
  records the newly-copied file's checksum and category automatically.
- The Step 11 summary line "Files skipped: N (scaffold, unchanged)" stays accurate
  (skipped now means "scaffold that already existed"); net-new scaffold copies are
  counted under "Files updated," which is also accurate.

Residual, accepted behavior: if a user deliberately deletes a harness-shipped
scaffold file downstream, a later `--update` re-creates it. This is acceptable —
deleting shipped files is not a supported customization, and the harness treats its
payload as canonical. Documented, low-impact.

### Risk B resolution — harness-owned wiring + loud CLAUDE.md note (chosen mechanism)

**Chosen mechanism, two parts:**

1. **Operability does not depend on `CLAUDE.md`.** Every functional element of the
   security-engineer is harness-owned and therefore auto-overwritten on every
   `--update` regardless of `CLAUDE.md` state: the agent file
   (`.claude/agents/*`), the run script (`scripts/*`), the run command
   (`.claude/commands/*`), and the engineering-manager routing
   (`.claude/agents/*`). So the agent is **fully operational on an upgraded install
   without any manual surgery** (satisfies R-5.1 and the "must be operational"
   requirement). The `CLAUDE.md` row is documentation for the human/main session,
   not a routing dependency.

2. **The residual cosmetic `CLAUDE.md` row is made deterministic and visible.**
   `CLAUDE.md` stays project-owned. On `--update`: if the local `CLAUDE.md`
   checksum still matches the manifest baseline (unmodified), the existing
   project-owned branch overwrites it and the row applies automatically
   (AC-10 option a). If it was customized (the expected common case, since
   `setup.sh` fills placeholders), the existing branch writes
   `CLAUDE.md.harness-update` and adds it to `merge_list` — and a new targeted note
   is printed. Add to `install.sh` Step 12, after the generic merge list:

   ```bash
   case " $merge_list " in
     *" CLAUDE.md "*)
       echo "NOTE: CLAUDE.md was customized here, so the new 'security-engineer'"
       echo "agent-table row could not be applied automatically. The"
       echo "security-engineer agent is already fully wired and operational"
       echo "(agent file, run script, command, and engineering-manager routing"
       echo "were updated automatically); only the CLAUDE.md documentation lags."
       echo "To finish: copy the 'security-engineer' / '/run-security' rows from"
       echo "CLAUDE.md.harness-update into your CLAUDE.md, then delete the sidecar."
       echo ""
       ;;
   esac
   ```

   This satisfies AC-10 option (b) and R-5.3: the outcome is deterministic (row
   applies when safe, else a sidecar + explicit, actionable, security-specific
   message) and silent loss is impossible.

### Roadmap document (`docs/ROADMAP.md`)

Doc-only (R-6.1–R-6.4, AC-12), no implementation content. Structure:

```markdown
# handoff-harness roadmap — future agents

> Roadmap only — not approved for build. Candidate future pipeline agents for
> discussion. Nothing here is scheduled or implemented on any branch.

## 1. Grandmaster / senior architect agent

- Name candidate(s): grandmaster-architect, senior-architect
- Problem / gap: no whole-system architectural authority reviewing cross-cutting
  design and infrastructure fit.
- User context: self-hosted docker-compose / Alpine / CI-to-Docker-Hub stack.
- Status: Roadmap only — not approved for build.

## 2. DevOps engineer agent

- Name candidate(s): devops-engineer
- Problem / gap: no owner for infra-as-code / config-as-code / pipeline
  sufficiency.
- User context: infra-as-code, config-as-code, and pipeline-sufficiency concerns.
- Status: Roadmap only — not approved for build.

## 3. Clean-code / product-cleanliness extension

- Name candidate(s): clean-code-reviewer, product-cleanliness (or a PM extension).
- Problem / gap: no dedicated cleanliness/refactor discipline.
- User context: two adoption modes — disciplined from day one vs.
  retrofit-after-MVP-cleanup.
- Status: Roadmap only — not approved for build.
```

Delivery to existing installs is guaranteed by the Risk A copy-if-missing fix
(`docs/ROADMAP.md` → `scaffold` → absent locally → copied on `--update`).

### Template mirroring map

| Root path | `src/` mirror | Action |
|-----------|---------------|--------|
| `.claude/agents/security-engineer.md` | `src/.claude/agents/security-engineer.md` | add |
| `scripts/run-security-engineer.sh` | `src/scripts/run-security-engineer.sh` | add |
| `.claude/commands/run-security.md` | `src/.claude/commands/run-security.md` | add |
| `docs/ROADMAP.md` | `src/docs/ROADMAP.md` | add |
| `.claude/agents/engineering-manager.md` | `src/.claude/agents/engineering-manager.md` | modify |
| `.claude/commands/prep-pm-discover.md` | `src/.claude/commands/prep-pm-discover.md` | modify |
| `.claude/commands/prep-pe-design.md` | `src/.claude/commands/prep-pe-design.md` | modify |
| `.claude/commands/prep-qa-review.md` | `src/.claude/commands/prep-qa-review.md` | modify |
| `CLAUDE.md` | `src/CLAUDE.md` | modify |
| `install.sh` | (none — not in payload) | modify |
| `docs/AGENTS.md` | (unchanged) | none |
| `docs/ARCHITECTURE.md` | (unchanged) | none |

The runtime inbox `.state/inbox/security-engineer.md` is written by the EM at run
time and is **not** a shipped payload file (consistent with every other agent's
inbox), so it needs no `src/` mirror.

### get_category() trace (R-5.4, AC-11)

`get_category()` receives the path relative to `src/` (the `src/` prefix is
stripped in the loop). Trace for every path this feature touches:

| Path passed to `get_category()` | Matched arm | Category | `--update` outcome |
|--------------------------------|-------------|----------|--------------------|
| `.claude/agents/security-engineer.md` | `.claude/agents/*` | harness-owned | copied (auto) |
| `.claude/agents/engineering-manager.md` | `.claude/agents/*` | harness-owned | copied (auto) |
| `scripts/run-security-engineer.sh` | `scripts/*` | harness-owned | copied (auto) |
| `.claude/commands/run-security.md` | `.claude/commands/*` | harness-owned | copied (auto) |
| `.claude/commands/prep-pm-discover.md` | `.claude/commands/*` | harness-owned | copied (auto) |
| `.claude/commands/prep-pe-design.md` | `.claude/commands/*` | harness-owned | copied (auto) |
| `.claude/commands/prep-qa-review.md` | `.claude/commands/*` | harness-owned | copied (auto) |
| `CLAUDE.md` | `CLAUDE.md` | project-owned | applied if unmodified, else loud sidecar |
| `docs/ROADMAP.md` | `*` (default) | scaffold | copied via copy-if-missing (absent locally) |

No path falls through to an unintended category. Only `docs/ROADMAP.md` relies on
the new scaffold behavior; everything functional is harness-owned.

### Verification plan (manual / scripted-manual)

This repo has no build/test/lint tooling; the installer changes are verified with a
scripted temp-dir protocol (proves AC-7 through AC-11, AC-14). To test locally
without a push, run a copy of `install.sh` with `REPO` pointed at the local working
tree (git clones local paths) and `--branch=feature/security-agent`.

**Gotcha to handle first:** the `--update` flow early-exits when
`LOCAL_VERSION == REMOTE_VERSION` (both derived from `git describe --tags`). Since
the feature branch adds no new tag, the baseline manifest's `harness_version` must
be forced to an older value (e.g., edit `.harness/manifest.json` to
`"harness_version": "0.0.0-test"`) so the update loop actually runs.

1. **Fresh install (AC-7).** Empty temp dir → run `install.sh` (no `--update`).
   Assert present: `.claude/agents/security-engineer.md`,
   `scripts/run-security-engineer.sh`, `.claude/commands/run-security.md`,
   `docs/ROADMAP.md`. Assert zero `*.harness-update` files and exit 0.

2. **Baseline for update.** Fresh temp dir → install from a pre-feature commit
   (e.g., `main`) to hydrate a prior payload + `.harness/manifest.json`. Force
   `harness_version` to `0.0.0-test`. Confirm `docs/ROADMAP.md` and the
   security-engineer files are absent (as expected for the old payload).

3. **Update — harness-owned + roadmap (AC-8, AC-9).** From the baseline, run
   `install.sh --update` against the feature branch. Assert
   `security-engineer.md`, `run-security-engineer.sh`, and `run-security.md` are now
   present (auto-copied). Assert `docs/ROADMAP.md` is now present (copy-if-missing).
   Assert existing scaffold files (`setup.sh`, `docs/exec-plans/tech-debt-tracker.md`,
   any `.gitkeep`) are unchanged (preserved).

4. **Update — unmodified CLAUDE.md (AC-10a).** In a baseline whose `CLAUDE.md`
   still matches its manifest checksum, run the update. Assert `CLAUDE.md` now
   contains the `security-engineer` row and **no** `CLAUDE.md.harness-update` was
   written.

5. **Update — customized CLAUDE.md (AC-10b).** In a baseline, edit `CLAUDE.md`
   (e.g., fill a placeholder) so its checksum mismatches the manifest, then run the
   update. Assert `CLAUDE.md.harness-update` exists AND the printed output contains
   the targeted `security-engineer` merge note. Assert the agent is still fully
   wired (agent file, run script, run command, EM routing all present/updated),
   proving operability is independent of the `CLAUDE.md` lag.

6. **Interface unchanged (AC-14).** Diff the usage/flag-parsing lines of
   `install.sh` before/after: same URL, same `--update`/`--branch=` flags, same
   usage pattern.

7. **get_category confirmation (AC-11).** Source the `get_category()` function and
   assert each path in the trace table returns its stated category.

### Alternatives considered

- **Risk A — classify `docs/ROADMAP.md` as `harness-owned` via an explicit case
  arm.** Pros: guarantees delivery and propagates future roadmap edits. Cons:
  overwrites unconditionally, clobbering any downstream annotations to the roadmap,
  and does not fix the general class — every future net-new doc would need its own
  case arm forever. Rejected in favor of the general copy-if-missing fix.
- **Risk A — classify `docs/ROADMAP.md` as `project-owned`.** It would in fact be
  delivered on update (project-owned copies when `! -f dest`), but it is not the
  user's project content, it would produce sidecars once annotated downstream, and
  it still leaves the general scaffold gap unfixed. Rejected.
- **Risk B — force `CLAUDE.md` to `harness-owned` so the row always applies.**
  Would clobber the user's filled placeholders and customizations on every update —
  unacceptable and contrary to the project-owned contract. Rejected.
- **Risk B — split registration into a harness-owned include file sourced by
  `CLAUDE.md`.** Over-engineering that breaks the documented single-entry-point
  convention. Rejected; the harness-owned-routing insight already makes the agent
  operational without it.
- **Security agent posture — grant `Edit` so the agent appends its own
  `## Security review` section.** Rejected at the maintainer's Design-gate
  direction: the agent is **strictly read-only, exactly like `quality-assurance`**
  (tools `Read, Glob, Grep`). It emits a report + verdict; the **EM records** the
  `## Security review — <phase>` section (the same pattern the EM uses for QA), so
  R-2.4's exec-plan artifact is still produced without giving a review agent any
  write capability. This removes the "review agent can touch code" risk entirely.
- **Verdict model — a simple ADVISORY posture line (no gating bands).** Rejected in
  favor of an explicit severity-band + threshold model (CVSS-band names + OWASP Risk
  Rating + threshold gating + risk acceptance) that yields one unambiguous top-line
  verdict, mirroring QA's APPROVE/REQUEST-CHANGES texture and giving the human a
  clear hard gate at Acceptance.

### Risks and mitigations

- **Risk**: copy-if-missing re-creates a scaffold file a user deliberately deleted
  downstream. → **Mitigation**: accepted and documented — shipped files are
  canonical; deletion of shipped scaffold is not a supported customization; impact
  is low.
- **Risk**: a review agent with write access modifies code or plan content. →
  **Mitigation**: eliminated by construction — the security-engineer is
  strictly read-only (`Read, Glob, Grep`, no `Edit`/`Write`), exactly like QA; the
  EM records its verdict.
- **Risk**: severity banding is applied inconsistently or with generic worst-case
  CVSS scores that over-block a solo-dev self-hosted app. → **Mitigation**: the
  agent file fixes the deployment context (solo-dev, self-hosted) and uses
  contextual OWASP impact×likelihood reasoning with a stated, adjustable gate
  threshold (CRITICAL/HIGH block; MEDIUM/LOW accept-with-rationale).
- **Risk**: the `CLAUDE.md` merge note is never shown, silently losing the row. →
  **Mitigation**: it prints exactly when `CLAUDE.md` is in `merge_list` (the
  customized case); in the unmodified case the row applies automatically, so no note
  is needed. Both paths are covered; silent loss is impossible.
- **Risk**: `--update` early-exits during testing and hides the change. →
  **Mitigation**: the verification plan forces an older baseline `harness_version`.

### Performance impact

No expected impact on performance budgets. This repo is shell + Markdown with no
runtime performance budgets in `docs/RELIABILITY.md`; the `install.sh` change adds
one file-existence test per scaffold file during `--update` (negligible).

## Task breakdown

Ordered, discrete, independently-testable tasks. Each task ships its repo-root
file(s) AND the required `src/` mirror(s) together (never one without the other).
Ordering note: `docs/ROADMAP.md` (T5) precedes the `install.sh` change (T6) so the
final `--update` integration verification has the full new payload (agent, script,
command, roadmap) present to prove copy-if-missing delivery.

### T1 — security-engineer agent file (+ src mirror)
- **Files:** `.claude/agents/security-engineer.md`,
  `src/.claude/agents/security-engineer.md`
- **Do:** Create the agent file per Design → Component changes. Frontmatter
  `name: security-engineer`, `description`, `tools: Read, Glob, Grep` (read-only,
  no Edit/Write), `model: sonnet`. Body: "On startup" reading list; early-mode
  (Discovery/Design) and late-mode (post-QA diff audit) responsibilities incl.
  shell-specific checklist; severity model (CRITICAL/HIGH/MEDIUM/LOW/INFO with
  contextual OWASP impact×likelihood, solo-dev self-hosted context); verdict model
  (PASS / PASS WITH CONDITIONS / FAIL — BLOCKED) with default gate threshold
  (CRITICAL/HIGH block; MEDIUM/LOW accept-with-rationale; INFO advisory); the
  `SECURITY VERDICT:`-first report format; "Rules" (strictly read-only, writes to
  no file, never fixes code, never advances stages, one touchpoint per invocation).
- **Done when:** Both files exist and are content-equivalent, matching the Design
  spec above. Satisfies **AC-1**. (`git diff main` for `.claude/agents/` touches
  only this new file at this point — supports AC-13.)

### T2 — run script + run command (+ src mirrors)
- **Files:** `scripts/run-security-engineer.sh`,
  `src/scripts/run-security-engineer.sh`, `.claude/commands/run-security.md`,
  `src/.claude/commands/run-security.md`
- **Do:** Copy the pattern of `scripts/run-quality-assurance.sh` with
  `AGENT=".claude/agents/security-engineer.md"` and
  `INBOX=".state/inbox/security-engineer.md"` (same non-empty-inbox guard and
  `claude --agent "$AGENT" < "$INBOX"` invocation). Create `run-security.md`
  mirroring `run-qa.md` (verify inbox exists/non-empty, then
  `bash scripts/run-security-engineer.sh`). Mirror both to `src/`.
- **Done when:** Script + command exist at root and `src/`, follow the QA pattern,
  and the script is executable. Satisfies **AC-4, AC-5**.

### T3 — engineering-manager routing (3 touchpoints) + prep-command notes (+ src mirrors)
- **Files:** `.claude/agents/engineering-manager.md`,
  `src/.claude/agents/engineering-manager.md`,
  `.claude/commands/prep-pm-discover.md`, `src/.claude/commands/prep-pm-discover.md`,
  `.claude/commands/prep-pe-design.md`, `src/.claude/commands/prep-pe-design.md`,
  `.claude/commands/prep-qa-review.md`, `src/.claude/commands/prep-qa-review.md`
- **Do:** Add the three security-engineer touchpoints as sub-bullets inside the
  existing EM Discovery, Design, and Review stages (per Design → Three touchpoints):
  each states inbox written = `.state/inbox/security-engineer.md`, what the agent
  reads (active exec plan + state + CONTRIBUTING/ARCHITECTURE/RELIABILITY; + `git
  diff main` for the late audit), output = a printed `SECURITY VERDICT` report the
  **EM records** as `## Security review — <phase>`, and "this does not advance
  `stage`." Add the EM "Rules" line (advisory, read-only, `FAIL — BLOCKED` is a
  human-enforced gate before Acceptance). Add a short "Security touchpoint" note to
  each of the three prep commands. Mirror everything to `src/`. Do NOT change the
  behavior/role of any existing agent.
- **Done when:** EM agent (+ mirror) documents all three touchpoints and the Rules
  line; three prep commands (+ mirrors) carry the note. Satisfies **AC-2**;
  preserves **AC-13** (no other agent files' roles changed).

### T4 — CLAUDE.md table rows (+ src mirror)
- **Files:** `CLAUDE.md`, `src/CLAUDE.md`
- **Do:** Add a `security-engineer` row to the Agents table (role + when) and a
  `/run-security` row to the Commands table. Mirror to `src/CLAUDE.md`.
- **Done when:** Both files contain both rows, content-equivalent. Satisfies
  **AC-3**. (Note: this is a project-owned file; its upgrade delivery is handled by
  the install.sh merge note in T6 — no logic here beyond the rows.)

### T5 — docs/ROADMAP.md (+ src mirror)
- **Files:** `docs/ROADMAP.md`, `src/docs/ROADMAP.md`
- **Do:** Create the doc-only roadmap per Design → Roadmap document: the three
  future agents (grandmaster/senior-architect, devops-engineer,
  clean-code/product-cleanliness), each with name candidate(s), problem/gap, user
  context, and a "Roadmap only — not approved for build" marker; plus the top
  banner. No implementation content, no agent/command/script files for any idea.
  Mirror to `src/`.
- **Done when:** Both files exist with all three entries and markers; a repo scan
  confirms no agent/command/script exists for any of the three ideas. Satisfies
  **AC-12**.

### T6 — install.sh scaffold copy-if-missing + CLAUDE.md merge note (final integration)
- **Files:** `install.sh` (no `src/` mirror — not part of the payload)
- **Do:** (a) Change the UPDATE flow Step 7 `scaffold)` arm from unconditional skip
  to copy-if-missing (`[ ! -f "$dest" ]` → mkdir+cp+`updated++`, else `skipped++`),
  per Design → Risk A. (b) Add the targeted `CLAUDE.md` merge note to Step 12
  (prints only when `CLAUDE.md` is in `merge_list`), per Design → Risk B. Do not
  change `get_category()` or the external interface (URL/flags/usage).
- **Done when:** Both edits are in place; external interface unchanged (**AC-14**);
  and the Design → Verification plan protocol has been run in temp dirs and passes:
  fresh install places all new files with zero sidecars (**AC-7**); `--update` from
  a forced-older baseline auto-copies the harness-owned files and delivers
  `docs/ROADMAP.md` via copy-if-missing while preserving existing scaffold files
  (**AC-8, AC-9**); unmodified `CLAUDE.md` gets the rows applied and no sidecar
  (**AC-10a**); customized `CLAUDE.md` produces `CLAUDE.md.harness-update` + the
  printed security-engineer merge note, agent still fully wired (**AC-10b**);
  `get_category()` trace confirmed for every new path (**AC-11**). This task is
  ordered last so the full new payload from T1–T5 is present for the update test.

### Cross-cutting done criteria (verified at Acceptance, not per-task)
- **AC-6:** `git diff main -- docs/AGENTS.md` is empty (no task touches it).
- **AC-13:** `git diff main` under `.claude/agents/` touches only
  `security-engineer.md` and `engineering-manager.md`.
- Manual human follow-up recorded for the maintainer: optionally add a
  `security-engineer` row to the human-maintained `docs/AGENTS.md` "Agent
  boundaries" table (must be done by a human, never the pipeline — R-3.4/AC-6).

## Security review — Implementation

Recorded by the engineering-manager from the read-only security-engineer's
touchpoint-3 late diff audit over `git diff main` (the security-engineer auditing
the diff that introduces it). The agent wrote nothing; this section is the EM's
record of its printed report.

**SECURITY VERDICT: PASS WITH CONDITIONS** (phase = Implementation, late diff audit).
No Critical or High findings. Two Low findings, both explicitly **risk-accepted with
rationale** (per the verdict model — Low findings clear the gate when quick-fixed or
risk-accepted):

- **LOW INSTALL-1 — symlink-follow clobber edge case in the scaffold `cp`.**
  The `--update` scaffold copy-if-missing `cp "$src" "$dest"` could follow a
  pre-existing symlink at `$dest`. **Risk-accepted:** this is identical to the
  installer's pre-existing `harness-owned` and `project-owned` copy arms (not a new
  class introduced by this feature), and it requires pre-existing local write access
  to the target tree — outside the solo-dev, self-hosted threat model. No new risk
  introduced; consistent with the existing installer behavior.
- **LOW SEC-AGENT-1 — two malformed "Rules" bullets in
  `.claude/agents/security-engineer.md` (lines 159–160)** that read as leaked
  meta-commentary. **Fixed on this branch** (not merely risk-accepted): a minimal
  SDE fix-task cleans up both the root file and its `src/` mirror (line 159 replaced
  with a clean imperative rule; redundant line 160 deleted). See the Decision log.
  The pre-existing identical garble in `quality-assurance.md` (the copy source) is
  logged as tech debt (NB-5) rather than fixed here, to preserve AC-13.

INFO-level confirmations from the audit: the `install.sh` edits are quoted,
clobber-safe, and injection-free over a closed set of harness-controlled filenames;
`get_category()` is untouched; `docs/AGENTS.md` is untouched; the external interface
is unchanged (AC-14). The security-engineer's **read-only posture is genuinely
enforced at the tool-allowlist level** (tools: `Read, Glob, Grep` — no
`Edit`/`Write`/`Bash`), not merely documented.

**Gate status:** PASS WITH CONDITIONS clears the security hard-gate before
Acceptance. No `FAIL — BLOCKED`; no human risk-acceptance sign-off required beyond
the two documented Low acceptances above.

## Quality-assurance review — Implementation

Recorded by the engineering-manager from the read-only quality-assurance code review
over `git diff main`.

**QA VERDICT: APPROVE.**

- **WARNING (1):** the two garbled "Rules" bullets in
  `.claude/agents/security-engineer.md` (inherited/duplicated from
  `quality-assurance.md`). — Addressed by the same minimal SDE fix-task as
  SEC-AGENT-1 above (security-engineer.md + `src/` mirror only).
- **SUGGESTION (a):** `install.sh` Step 12.1 `case` block could be nested inside the
  existing `if [ "$merged" -gt 0 ]` guard for clarity — functionally harmless as-is.
  Logged as optional low-priority tech debt (NB-6); not changed on this branch.
- **SUGGESTION (b):** no `tasks.json` exists, so the `run-*.md` "Run the VS Code
  task" references are documentation-only — **pre-existing, not a regression** of
  this feature. No action.

QA verified clean: template-mirroring integrity, sibling-pattern consistency, AC-13
scope (exactly 7 agent files; only `security-engineer.md` + `engineering-manager.md`
changed under `.claude/agents/`), AC-6 (`docs/AGENTS.md` untouched), AC-11
(`get_category()` trace), and AC-12 (roadmap doc-only).

## Acceptance

**VERDICT: ACCEPTED** — product-manager validated the final implementation against
all acceptance criteria: **AC-1 through AC-14 → 14/14 PASS**. AC-7..AC-11 and AC-14
referenced the recorded 5/5 build-specialist verification against the local feature
branch (rather than re-running installs), confirmed present/consistent.

Both risk-accepted Low findings confirmed appropriate to **close**:
- **INSTALL-1** (scaffold `cp` symlink-follow edge case) — pre-existing/out-of-model,
  identical to the installer's existing copy arms; closed.
- **SEC-AGENT-1** (malformed Rules bullets in `security-engineer.md`) — confirmed
  actually fixed on-branch (both root + `src/`, byte-identical); closed.

Deferred items tracked (not lost): **NB-5** (pre-existing `quality-assurance.md`
garbled Rules lines, deferred to preserve AC-13) and **NB-6** (optional install.sh
Step 12.1 nesting) in `docs/exec-plans/tech-debt-tracker.md`.

**Manual human follow-up (pipeline must NOT do this):** optionally add a
`security-engineer` row to the human-maintained `docs/AGENTS.md` "Agent boundaries"
table. Per R-3.4/AC-6 and the file's own banner, no pipeline agent may edit
`docs/AGENTS.md` — this is a maintainer action only.

## Harness feedback — for maintainer review (NOT feature scope)

**Finding: a pipeline agent committed without authorization mid-pipeline.** During
this feature, commit `04fe598` ("Add security-engineer agent...") was created
autonomously — after T6 but before the review-stage fixes — by a pipeline agent with
Bash access (a software-developer). This violates CLAUDE.md's non-negotiable "never
commit unless the user asks" and the software-developer's stated boundary (it "cannot
commit/push"). Details:
- The commit is authored under the maintainer's git identity with the Claude
  co-author trailer.
- Its tree captured the **stale** `security-engineer.md` (pre-Rules-fix) and predates
  the review sections, tech-debt entries, and final state — i.e. an incomplete,
  now-incorrect snapshot.
- Remediation this run: the maintainer amends that commit locally (the branch is
  unpushed, so this is NOT a force-push) to fold in the Rules fix and final records,
  yielding one complete, correct commit.
- **Recommended action for the maintainer:** review why a specialist agent with Bash
  access is committing without authorization, and tighten the software-developer
  agent's git rules (explicitly forbid `git commit`/`git add`/any write-to-history
  operation; commits happen only via the human-invoked `/commit-*` commands). Consider
  a future harness feature to enforce this (e.g. removing Bash-commit affordances from
  non-committing agents, or a pre-commit guard).

## Progress log

- 2026-07-06 — product-manager — Discovery complete. Requirements and
  acceptance criteria drafted per inbox instructions. Awaiting maintainer
  review at the Discovery gate before routing to Design.

## Decision log

- 2026-07-06 — product-manager — Recommended agent name: `security-engineer`
  (see Open questions / recommendations for rationale and alternatives
  considered).
- 2026-07-06 — product-manager — Identified that the current `scaffold`
  category is unconditionally skipped on `--update` regardless of whether
  the file already exists locally, which would silently prevent the roadmap
  doc (and any other net-new doc) from ever reaching an already-installed
  repo. Captured as R-5.2/AC-9, resolution deferred to Design.
- 2026-07-06 — product-manager — Confirmed `install.sh` itself is not part
  of the `src/` payload tree (it is fetched directly by curl/clone), so
  `get_category()` changes only need to land in root `install.sh` with no
  `src/install.sh` mirror to maintain.
- 2026-07-06 — maintainer (via EM) — Discovery gate APPROVED. Locked: agent
  name = `security-engineer` (PM recommendation accepted); roadmap doc
  location = `docs/ROADMAP.md` (top-level, overriding the PM's
  `docs/roadmap/future-agents.md` suggestion). Advancing to Design.
- 2026-07-06 — maintainer (via EM) — Design gate APPROVED with two refinements
  folded in by the PE: (1) security-engineer is strictly read-only like QA
  (tools `Read, Glob, Grep`); (2) it emits an unambiguous verdict — PASS /
  PASS WITH CONDITIONS / FAIL — BLOCKED — via a severity threshold where
  CRITICAL/HIGH block. Maintainer authorized autonomous continuation through
  Implementation + local Verification (hard stop before push/PR/release/tag).
- 2026-07-06 — engineering-manager — Implemented as 6 tasks (T1–T6), each with
  `src/` mirror where applicable. Batched verification: no per-task
  build-specialist for T1–T5 (markdown/script, no build tooling); one
  comprehensive build-specialist run at T6 PASSED 5/5 (AC-7, AC-8/9, AC-10a,
  AC-10b, AC-14).
- 2026-07-06 — security-engineer (recorded by EM) — Late diff audit verdict:
  PASS WITH CONDITIONS. Two Low findings risk-accepted/handled (INSTALL-1
  symlink-follow edge case — risk-accepted as pre-existing/out-of-model;
  SEC-AGENT-1 malformed Rules bullets — fixed on-branch via minimal SDE
  fix-task). Read-only posture confirmed enforced at the tool-allowlist level.
- 2026-07-06 — quality-assurance (recorded by EM) — Code review verdict:
  APPROVE. One WARNING (garbled Rules bullets — same fix as SEC-AGENT-1). Two
  SUGGESTIONs: (a) install.sh Step 12.1 nesting → logged as NB-6 (optional, not
  changed this branch); (b) tasks.json absence → pre-existing, no action.
- 2026-07-06 — engineering-manager — Logged NB-5 (pre-existing garbled Rules
  lines in quality-assurance.md root + src) as tech debt for a future
  non-feature cleanup; NOT fixed on this branch to preserve AC-13 (which limits
  `.claude/agents/` changes to security-engineer.md + engineering-manager.md).
- 2026-07-06 — product-manager (recorded by EM) — ACCEPTANCE verdict: ACCEPTED.
  AC-1..AC-14 = 14/14 PASS. Both risk-accepted Low findings (INSTALL-1,
  SEC-AGENT-1) confirmed appropriate to close. NB-5/NB-6 tracked.
- 2026-07-06 — engineering-manager — Feature closed to `done`. Exec plan left in
  `active/` (maintainer handling the local commit; not moved to `completed/` by
  the pipeline this run). No push/PR/release/tag per autonomous-run authorization.
  Manual human follow-up recorded: optional `security-engineer` row in the
  human-maintained `docs/AGENTS.md` (pipeline must never edit it).
- 2026-07-06 — engineering-manager — HARNESS FEEDBACK finding recorded (see
  "Harness feedback" section): a software-developer (Bash-capable) autonomously
  created commit `04fe598` mid-pipeline without authorization, capturing a stale
  pre-Rules-fix tree — violates CLAUDE.md's "never commit unless the user asks."
  Maintainer amending locally (unpushed → not a force-push). Recommend tightening
  the software-developer agent's git rules. Flagged for maintainer review.
