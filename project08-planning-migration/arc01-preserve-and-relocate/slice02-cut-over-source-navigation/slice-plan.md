# Slice02 — Cut over source navigation

Status: implemented; follow-up cleanup authorized 2026-10-17.
Workflow: One-Contributor with read-only lookup assistance.
Parent: [Arc01](../arc-plan.md). Contract: [ledger](ledger.md).

## Delivery and inputs

Make the imported planning branch the single canonical planning home while
keeping user documentation/source on main. Slice01 imported 69 planning files
and one older branch variant at planning commit 094e72b. Its metadata/helper
checks are in ../slice01-import-planning-corpus/artifacts/import-validation.json.
No independent implementation acceptance is claimed; whole-migration execution
was authorized by the Operator and the self-checks permit this bounded cutover.

## Explicit source edit allowance

Remove exactly the 60 tracked source paths whose disposition is migrate in
source-inventory.json, after rechecking their hash/mode and committed import.
Remove exactly its 9 formerly ignored workbench source files after proving their
imported bytes can be read from committed Git objects. Preserve unrelated local
files and the two DS_Store files. Keep source history and old feature refs.

Routing edits/additions only: .gitignore, AGENTS.md, README.md, docs/planning.md,
RUST-CORE-POC.md, plus pointer-only comments in Cargo.toml and
test/xrepl-shell-pluggability-spike-tests.lfe. No runtime logic, assertions,
dependencies, build behavior, assets or sibling repositories change.
Switch to main only while it equals release/0.1.x, preserving unchanged file
mtimes. Commit source removals/routing separately from planning updates. Do not
merge the orphan planning branch into main.

## Verification and recovery

Before source removal, verify all 69 imported file hashes against manifests,
the 60 tracked Git blobs, and the one attributed branch-variant blob; inspect
the exact 70-path import commit. Verify the 9 ignored imports via git show.
After cutover, compare the exact source diff against its allowlist, follow all
new navigation links, and ensure no active obsolete path references remain
except explicitly labelled historical mentions. The one original relative
Markdown link remains valid because both audit files moved together.

Use a temporary fresh clone of final local main and add its planning worktree.
Follow docs/planning.md and the committed restore helper; assert 69 canonical
payloads/27 directories and exact native creation/mtime equality on this host.
Recover 69 payloads/31 directories into an empty original-layout root and compare
hashes. Reconcile source removal against canonical destinations and all ledgers.
Guarded negative cases from Slice01 remain applicable to the unchanged helper.
This slice’s new evidence is artifacts/cutover-validation.json and reference
inventory, then its per-row closing report and arc/project composition records.

Recovery after cleanup uses import commit 094e72b plus manifests; source commit
18ba5b7 recovers the 60 tracked originals. Source Git cannot recover the 9 ignored
workbench files, so their versioned planning import is the recovery authority.
Publication/push remains a separately directed action. Self-checks are attested;
final human Operator acceptance is not simulated.

## Version history

- v1.0 — 2026-10-17: opened after exact import and successful restoration,
  recovery and negative checks; scoped pointer-only source comments explicitly.

## Implementation status — 2026-10-17

All assigned execution and self-check work is delivered; see closing-report.md.
Earlier preparation/active status is superseded. Ledger evidence is attested;
human acceptance remains explicit and historical gates remain unchanged.

## Follow-up allowance v1.1 — 2026-10-17

Operator-authorized cleanup supersedes the original preservation of the two
DS_Store files and retention of RUST-CORE-POC.md in source. Remove the recorded
empty docs/design and workbench containers using guarded unlink/rmdir, keeping
their captured metadata in artifacts/legacy-container-cleanup.json. The PoC
overview becomes a timestamp-preserved Project05 artifact; commit the copy and
its supplemental manifest before deleting the tracked source-root file. Add its
route and supplemental restoration command to docs/planning.md. Commit and push
main and planning after all work, as expressly requested.
