# Run the Security Engineer agent.

Invoke the security-engineer agent from the mobile workflow (Session 2).
Use this in Session 2 (specialist workbench) after the EM has routed a security
touchpoint in Session 1 (Discovery, Design, or the late pre-Acceptance audit — the
active touchpoint is determined by whichever inbox the EM wrote).

## Workflow
1. Verify `.state/inbox/security-engineer.md` exists and is non-empty
2. If missing or empty, stop with: "No inbox file found. The EM must write one first."
3. Execute: `bash scripts/run-security-engineer.sh`
