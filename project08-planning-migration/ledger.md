# Project08 migration ledger

Opened 2026-10-17. All rows remain open for execution. One-Contributor checks
are attested; final Operator acceptance remains explicit. Historical independent
verification requirements are preserved separately, not discharged by migration.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P-01 | Every planning payload has one canonical owner: 69 local files plus 1 attributed older branch variant. | Reconcile source/branch inventories with canonical files and mapping; all hashes match and no unexplained files remain. | serious | Operator scope | open | | Seven historical homes plus Project08. |
| P-02 | Legacy file bytes, modes, prompts, addenda, evidence and old statuses survive without rewritten claims. | Compare imported SHA-256 and modes with pinned manifests; inspect wrappers and old/new diffs. | serious | preservation | open | | Includes ignored workbench records. |
| P-03 | Last-edit mtimes survive for every unchanged imported file and each mapped original directory; split-parent metadata remains retrievable. | Verify nanosecond mtimes after final writes and from a fresh clone after restoration; reconcile all 31 original directory records. | serious | Operator timestamps | open | | Creation/atime precision and immutable ctime disclosed. |
| P-04 | Branch provenance and reused arc numbers remain unambiguous. | Inspect branch inventory, variant import, lineage notes and L/G/D reference ownership. | correctness-grade | branch survey | open | | No replacement of newer main plan or merge of historical feature refs. |
| P-05 | Source/planning cutover is complete and recoverable with intended user docs preserved. | Check source diff against 60-path removal allowlist and approved routing edits; recover the 9 ignored imports from committed planning. | serious | composition | open | | No runtime changes. |
| P-06 | Another machine can fetch both branches, find the canonical documents and restore metadata without private account/toolchain dependencies. | Follow documented fresh-clone/worktree and guarded restoration steps in temporary storage; record exact results. | serious | usability | open | | Push is separately directed. |
| P-07 | Child delivery, composition, limitations and Operator acceptance are recorded honestly. | Walk slice/arc/project ledgers and closure records; self-checks labelled attested, historical gates retained, final acceptance attributed. | serious | framework / workflow | open | | No synthetic verification-role records. |
