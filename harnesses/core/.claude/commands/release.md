<!-- harness:region:start id=doc -->
# /release — verify & close (Phase 5)

Verify the work against its anchor and close it out. This is Phase 5 of
`.harness/flow.md`: verify, mark the plan `Shipped` and move it to `completed/`, commit
staged-by-name, and run `check-markers` before any push. It runs only after the
gate is satisfied.

## Input

`$ARGUMENTS` = optional version/tag for the `Shipped <version>` marker.

## Precondition — the gate must be closed

Refuse to proceed unless every required seat (per `.harness/scrutiny.toml`) has an
`APPROVED` verdict in the plan doc, each bound to the CURRENT sha. If the tree
moved after the last approval, those markers are stale — re-run `/gate` first.
**Never self-merge**; a change reaches release only through the gate.

## Procedure

1. **Verify against the anchor** (from the plan's status block):
   - **outcome:** verify the result yourself against the three acceptance
     bullets.
   - **spec / tdd:** verify against the acceptance criteria / the named tests.
   Report any failure VERBATIM, with counts, before any framing. "Verified" is
   not "should work."

2. **Mark the plan Shipped.** Set `status: Shipped <version>` in the status
   block and move the doc from `docs/exec-plans/active/` to
   `docs/exec-plans/completed/`. A terminal status left under `active/` is
   exactly what `check-markers` flags.

3. **Commit the close-out, staged by name.** The work's own files are already
   committed and gated (Phase 3/4). This commit is just the bookkeeping — the
   plan doc moved to `completed/` with its `Shipped` status. Stage it explicitly
   by name (never `git add .` / `git add -A`), commit with an imperative message
   (HEREDOC for multi-line) and the co-author trailer, never `--no-verify`.
   Because it touches only the plan doc, the gated approval stays valid.

4. **Run the marker check before push.** Run `.harness/lib/check-markers.sh` and report
   its output. If it exits non-zero, STOP and fix the flagged markers — a stale
   approval never leaves the machine. Only on a clean result may you push, and
   never force-push.

5. Run any release ceremony the project defines (tag, PR, notes) within the same
   rules.

## Rules

- Never self-merge; the gate is the gate.
- Stage files by name; no `git add .`, no force-push, no `--no-verify`.
- `.harness/lib/check-markers.sh` must pass before push — no exceptions.
- Status is a bound marker in the plan doc, not a prose line or a state file.
<!-- harness:region:end id=doc -->
