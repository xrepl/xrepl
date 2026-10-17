# Slice02 cutover ledger

Opened2026-10-17. Checks remain attested until the human Operator accepts the result.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C-01 | The 69+1 payload import and ignored-record recovery are durably committed before removal. | Read imported Git blobs and compare every hash/mode with manifests. | serious | approved migration | open | | Execution authorized; acceptance not simulated. |
| C-02 | Only the approved 60 tracked and 9 ignored originals are removed; unrelated source remains. | Compare exact source removal list and diff against manifest/7-path routing allowlist. | serious | approved migration | open | | Execution authorized; acceptance not simulated. |
| C-03 | Source and planning navigation are usable and active stale pointers repaired. | Resolve new links, inspect pointer-only changes and the historical reference inventory. | serious | approved migration | open | | Execution authorized; acceptance not simulated. |
| C-04 | Final source/planning branches work from a fresh clone with exact original metadata restoration. | Run committed helper on fresh planning checkout:69 files/27 directories, no mismatches; recover69/31. | serious | approved migration | open | | Execution authorized; acceptance not simulated. |
| C-05 | Composition and source/planning boundaries preserve every original scope/evidence obligation. | Reconcile payloads, modes, timestamps, source diff, branch provenance and old unresolved findings. | serious | approved migration | open | | Execution authorized; acceptance not simulated. |
| C-06 | Reports, recovery instructions and acceptance attribution are complete. | Per-row closing report and arc/project reports name actual commits/checks and human acceptance pending. | serious | approved migration | open | | Execution authorized; acceptance not simulated. |
