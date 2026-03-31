# Run Build Specialist

Invoke the build-specialist agent from the mobile workflow (Session 2).

## Workflow
1. Verify `.state/inbox/build-specialist.md` exists and is non-empty
2. If missing or empty, stop with: "No inbox file found. The EM must write one first."
3. Execute: `bash scripts/run-build-specialist.sh`
