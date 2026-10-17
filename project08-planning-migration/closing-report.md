# Project08 implementation report

2026-10-17. All authorized migration implementation is delivered and self-checked.
Status: **implemented; human Operator acceptance pending**. Sofie combines
planning, implementation and self-review, aided by two read-only lookup workers.
No worker supplied design, edits or an independent acceptance verdict. No human
approval is simulated. Evidence strength is attested throughout this migration.

## Delivered states and commits

- Planning0d4e9d2: approved plan and original inventory.
- Planning094e72b: exactly 69 byte-preserved local records+1 older branch variant.
- Planning46fcca1: modern retrospective navigation, safe timestamp helper,
  native creation metadata and initial checks; original payload bytes unchanged.
- Source9d7956b: canonical source cutover, exact60 removals+7 routing paths.
- This report’s planning commit records final receipts and current status; no
  checked payload/helper content changes are included in the reporting layer.

## Project row walk

| Row | Disposition and evidence |
| --- | --- |
| P-01 | Implemented: all 69 local planning files have one mapped canonical owner;1 attributed Arc4 variant is preserved separately. Seven historical projects+Project08 exist. |
| P-02 | Implemented: all original hashes/modes/prompts/addenda and caveats preserved. Newly authored wrappers are dated retrospective records, not rewritten history. |
| P-03 | Implemented: exact native mtime/creation restored for69 files/27 mapped directories. All31 original directory records recovered in original-layout exercise. Split-parent, atime and ctime limits disclosed. |
| P-04 | Implemented: ref/path/blob/source provenance retained; original Arc06/07 backlog distinguished from later multishell/xs scopes. Feature refs are not merged/reset; older variant does not replace newer plan. |
| P-05 | Implemented: main cutover is exact60 removals+7 bounded routing edits;9 ignored originals recover from planning Git. Runtime/build/assertion content remains unchanged outside pointer-only comments. |
| P-06 | Implemented: real temporary fresh main clone+planning worktree followed committed setup;69/27 timestamp restoration and69/31 original recovery succeeded with matching hashes. Actual remote publication is not claimed. |
| P-07 | Execution/reporting implemented: slice8+6 rows, arc4 rows and project7 rows all accounted for, with evidence and honest limits. Human Operator acceptance remains pending, so ledger rows remain open rather than claiming independent done. |

## Verification, artifact inventory and practical limits

Import receipts record8 success/failure cases, including initial fresh-checkout
mtime mismatch, successful exact restore and refusals for changed payloads,
escaping paths and symlinks. Composition receipts independently reconcile69+1
hashes, modes and committed blobs, 185 planning links, exact source diff and
fresh source+planning recovery. Product suites were not run for this migration;
no runtime behavior or test assertions changed. See Slice02 artifacts for the
exact original removal list, routing references and fresh-clone results.
All new supporting evidence is in the owning slice artifacts/ directories;
first-class plans/ledgers/implementation reports remain beside their plans.
Historical support-file layout exceptions remain explicit.

Creation-time restoration was exercised on macOS; other platforms report
unsupported creation fields rather than claiming preservation. Git itself does
not store filesystem dates, so run the committed helper after checkout/update.
Ctime is OS-maintained; atime reflects the observation/reads. The older variant
has no original filesystem timestamp; its provenance is commit-derived only.

Old Arc04 verification gaps, Arc05 stale plan chronology, Rust PoC unrun build
note, story acceptance gaps/failures and open slice07/logjam rows are visible in
current navigation. They are not work claimed accepted by this migration.

## Composition and version-history reconciliation

One arc delivered both planned increments: recoverable canonical import followed
by source cutover. Scope-as-specified versus scope-as-delivered: 69+1 payloads,
all date/provenance records and recovery instructions present; no silent drops.
Slice01’s pointer-comment allowance was explicitly recorded before source edits.
No extra project or arc was needed. All authorized execution is complete.

The next action is the human Operator’s review/acceptance. Publishing source and
planning is separately directed; no remote was pushed. Main is canonical source;
release/0.1.x and old feature refs retain their historical state.

Final metadata check: Slice02 artifacts/final-navigation-check.json records
188 current planning links with zero missing targets and matching row walks
(P7/A4/S8/C6). All70 legacy payloads and the restoration helper remain unchanged
from the checked import/composition candidates; source worktree is clean.

## Follow-up cleanup and PoC relocation — 2026-10-17

Operator-authorized follow-up supersedes retention of the source-root PoC
overview and two Finder metadata files. Planning commit `d71913e` preserves
the unchanged overview under Project05’s infrastructure PoC slice with an exact
mtime/creation-time supplemental manifest. Source commit `02fc239` removes its
root copy and updates only docs/planning.md. Local docs/design and workbench
containers are now absent: 11 empty directories and two DS_Store files removed,
with their observed dates recorded in Slice02’s legacy-container-cleanup.json.
The initial file-derived inventory did not include six empty subdirectories;
their timestamps are now captured in that supplement before deletion. Initial
69+1 payloads/manifests remain unchanged; this follow-up adds one preserved
overview (70 planning files plus one historical branch variant).

Both restoration manifests report zero modification/creation-time mismatches:
original69 files/27 directories plus supplementary1 file/0 directories. The
original-layout helper remains scoped to its initial31 directory records; the
six additional empty-container records are retained separately, without
creating new active slice scopes. Ctime remains OS-maintained. Current planning
filesystem links all resolve, including the PoC overview’s source-context
forwarder. Product tests were not run; no code, assertions or build data changed.

Evidence: Slice02 artifacts/legacy-container-cleanup.json and Slice01
artifacts/rust-poc-relocation.json. Checks are attested; historical independent
acceptance requirements are unchanged. The Operator explicitly requested commit
and push of main and planning after this work. Prior publication holds are
superseded for these two branches; no release-branch change is included.
