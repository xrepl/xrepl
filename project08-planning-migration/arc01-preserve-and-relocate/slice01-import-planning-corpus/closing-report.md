# Slice01 implementation report

2026-10-17. Implementation delivered; evidence strength **attested**. This is
Sofie’s self-check report under the Operator-selected One-Contributor workflow,
not independent acceptance. Human Operator acceptance remains pending. The full
migration was authorized; this permits the verified import to feed Slice02
without inventing a separate contributor handoff.

Source baseline18ba5b7. Preserved-payload planning commit 094e72b contains exactly
69 mapped local files plus one older attributed Arc4 plan variant. Newly authored
navigation/helper metadata is separate; this report’s commit is its plan state.
Source originals remained intact throughout this slice.

| Row | Disposition and attested evidence |
| --- | --- |
| S-01 | Implemented: all 72 original hashes/modes/mtimes and31 directory records matched; ignored membership and source refs had no drift. Initial snapshot retained; native creation precision added separately. |
| S-02 | Implemented: all 69 local hashes/modes and1 pinned variant match the exact70-path import commit. |
| S-03 | Implemented: unchanged historical bytes preserve all prompts/addenda/failure evidence/statuses. Current notes expose unreproduced Arc04 gates, the Arc05 chronology mismatch, Rust PoC unverified-build note, and later story open rows. |
| S-04 | Implemented: seven project plans plus dated retrospective navigation; existing canonical plan/ledger payloads stay unchanged. Next work remains unassigned until selected. |
| S-05 | Implemented: helper validates the full set before writes; changed content, escaping path and symlink negative cases all refused (import-validation.json). |
| S-06 | Implemented: fresh clone initially fails mtime comparison, then restore/verify returns 69 files/27 directories with zero edit/creation-time mismatches. Original-layout recovery returns 69/31 with all hashes equal. |
| S-07 | Implemented: import commit 094e72b is recoverable, including9 ignored workbench records; source unchanged in this slice. |
| S-08 | Implemented: this report, preserved manifests, restoration usage and receipts provide the exact inputs to Slice02. Self-checks remain attested. |

Ledger rows remain open with evidence until actual Operator acceptance; this
report does not manufacture reproduced status. No historical gate is waived.

## Artifacts and validation

artifacts/ contains the complete project map, source and branch inventories,
native-creation-times.json, restore-timestamps.py, timestamp-restoration.md,
navigation-created-paths.json and import-validation.json. The original three
planning records are retained. No legacy scripts or product tests were run.
Eight expected success/failure helper cases passed in temporary storage.

## Bubble-up to the arc

Delivered the arc’s first useful increment: a usable, committed planning corpus
with old-to-new ownership and working timestamp recovery. Source removal is
Slice02’s responsibility. Native Darwin APIs enabled exact creation-time
preservation too; ctime remains observational and atime is snapshot-only.
The source reference lookup surfaced two pointer-only comments in Cargo.toml
and the spike-test module; their explicit routing allowance is recorded in the
project amendment and Slice02 plan. No additional project or payload appeared.
Silent-drop comparison: 69 local records+1 variant, all expected metadata and
historical limits included; source/publication are left to their named stages.
