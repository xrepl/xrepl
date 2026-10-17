# Arc01 — Preserve and relocate planning

Status: implemented; human Operator acceptance pending. Prepared 2026-10-17. Parent: [Project08](../project-plan.md).
Workflow: Operator-selected One-Contributor. Acceptance: [ledger.md](ledger.md).

## Capability

Turn the existing planning corpus into a versioned canonical planning workspace
that can replace source-branch planning without losing content, provenance or
last-edit timestamps. The useful first delivery is a navigable imported corpus;
source cleanup follows only after its content and recovery path are established.

## Slices

| Slice | Delivery | Depends on |
| --- | --- | --- |
| [slice01-import-planning-corpus](slice01-import-planning-corpus/slice-plan.md) | Import 69 local planning files and 1 branch variant; add current navigation, retain historical claims, deliver timestamp restoration and preservation receipts. | Operator accepts the proposed file mapping; source/ref drift check. |
| `slice02-cut-over-source-navigation` | Remove only verified source copies, establish tracked source guidance and `.worktrees` ignore, repair active pointers, and demonstrate fresh-clone recovery and end-to-end composition. | Recorded Slice01 import commit and passed preservation checks; Operator directs execution/cleanup. |

## Boundaries and integration

Deliveries integrate on orphan `planning`; source removals/routing integrate on
`main` (currently equal to release/0.1.x). Source code, tests, build logic,
private account state, story content and sibling repositories are outside this
migration's edit scope. Historical support scripts are preserved, not executed
as proof that old implementations pass today. No source/planning branch merge.

New wrappers explain source state and missing records without fabricating past
acceptance. Historical plans occupying canonical filenames stay intact, with
new migration notes beside them. Exact directory and filename treatment is in
the project plan and proposed file map.

## Verification and composition

Slice01 verifies bytes/modes/metadata against the inventory, restores mtime and
records a guarded restoration procedure. Slice02 verifies the removal allowlist,
active navigation and portability from a temporary fresh clone. At arc close,
reconcile all 69+1 payloads and all original directory records, check the source
cutover against the planning import, and demonstrate that the documented next-
machine steps reach the same preserved corpus. Old green suites or child
reports alone do not establish this composition result.

## Current status

Both slices are implemented; see their per-row reports and the arc's
[composition report](closing-report.md). All checks are attested. Human
Operator acceptance remains pending; previous planned-only status is historical.

## Version history

- v1.0 — 2026-10-17: one delivery arc, two usable increments, with branch
  coverage and timestamp restoration included in the import/cutover obligations.

## Execution update v1.1 — 2026-10-17

Slice01’s exact import 094e72b and restoration/recovery checks are delivered
(attested). Slice02 is now [planned in detail](slice02-cut-over-source-navigation/slice-plan.md)
and authorized for source cutover. Pointer-only Cargo/test comments surfaced
by Slice01 are explicitly included; no behavior changes. Earlier planned-only
status is superseded. Final acceptance remains with the human Operator.

## Version update v1.2 — 2026-10-17

Slice02 delivered source 9d7956b and full source+planning recovery. The arc
composition is implemented with attested evidence; no additional slice needed.
