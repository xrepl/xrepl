# Project10 refocus and preserved formulation

2026-10-18. The Operator retained this project name and changed its active scope
to the xrepl 0.2.x migration onto Cayrn. AGENTS.md, project-plan.md and ledger.md
at project root are the new active records. The original packet was untracked
on planning at aebf3d7, so it was copied before mutation to formulation-v1/.
All 11 file digests are in 07-refocus-baseline.json's historical_formulation map.
That is a byte-preserved snapshot, not reconstructed Git history or acceptance.

Original artifacts/01..06, README.md and check-packet.py remain unchanged. The
historical checker compares old source *working bytes*; current code has changed
since its pin, so it is not the gate for the new migration plan. Current plan
validation checks the new links/rows/contracts, original snapshot hashes and
paired source state separately. Runtime acceptance requires future execution.

Cayrn Project01's unchanged transfer manifest still has the original source
hashes/paths. Its current checker first checks a source path, then, only if those
bytes changed through this refocus, verifies the identical relative path under
artifacts/formulation-v1/. It reports the relocation explicitly. A corrupt or
missing preserved file fails that check; hashes are never refreshed to fit new
content. Other historical transfer/source/research records are not rewritten.

Current architecture authority: project-plan.md and design.md. Old research and
requirements remain accessible; deferred general-runtime work belongs to Cayrn
Project01/future runtime projects. The current paired hardening project is Cayrn
Project02; its independent acceptance gates are not silently satisfied here.
