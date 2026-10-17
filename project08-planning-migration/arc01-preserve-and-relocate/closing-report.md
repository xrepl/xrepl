# Arc01 implementation and composition report

2026-10-17. Capability delivered; evidence **attested**, human acceptance pending.
Source9d7956b; exact import 094e72b; checked planning candidate 46fcca1. Subsequent
planning commits record these reports without changing the checked helper or
legacy bytes. Both planned implementation slices were delivered.

| Row | Disposition and evidence |
| --- | --- |
| A-01 | Implemented: Slice01 imported69 unchanged records+1 attributed branch variant; navigation and timestamp restoration are usable. See its per-row report and import-validation.json. |
| A-02 | Implemented: Slice02 source commit 9d7956b removes exactly 60 tracked copies and updates7 routing paths, after all 9 ignored imports were versioned and compared. |
| A-03 | Implemented: cutover-validation.json demonstrates final main+planning setup from a fresh clone, 69/27 exact edit/creation-time restore and69/31 original-layout recovery, plus 185 resolving links and unchanged unrelated source blobs/modes. |
| A-04 | Implemented: this report and project report carry every discovered caveat, old scope lineage and pending human gate upward. No fabricated independent review. |

## Slice walk and composition

Slice01: delivered import/recovery and complete mapping. Slice02: delivered
source cutover, active navigation and fresh-machine composition. Both have
attested per-row reports; neither claims independently reproduced acceptance.
The integration demonstration was performed against actual source+planning
commits, rather than inferred from child status. All69 local records+1 variant
and31 original directory metadata records reconcile; no assigned scope missing.

## Change log and bubble-up to the project

Slice01 surfaced four active path references, including Cargo/test comments;
the source routing allowance was made explicit before source edits. Native
Darwin metadata supports exact creation-time restoration as well as mtime.
Ctime is not restorable, atime reflects reads, and the four split parent dates
remain metadata until original-layout recovery. These limits were anticipated
by the project plan. No new arc/project or implementation scope is needed.
Final human acceptance is pending; no additional independent gate is invented
for the selected workflow, and no old independent gate is waived.

The arc’s capability as specified (versioned canonical records plus recoverable
source cutover) is implemented. Silent-drop diff: none. Publication remains a
separately directed operation. This is an implementation report, not human
Operator acceptance or independent CRC/CDC verification.

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
