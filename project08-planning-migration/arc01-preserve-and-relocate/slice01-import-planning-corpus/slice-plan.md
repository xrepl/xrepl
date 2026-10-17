# Slice01 — Import the planning corpus

Status: implemented; human Operator acceptance pending.
Parent: [Arc01](../arc-plan.md). Contract: [ledger.md](ledger.md).
Workflow: One-Contributor, selected by the Operator. Sofie plans, implements and
self-checks; no synthetic CC prompt or reviewer-verification file is created.
The Operator's execution direction is the next assignment.

## Usable delivery

A versioned, navigable canonical corpus on orphan `planning`: 69 unchanged local
planning files, one attributed older branch variant, present-day project
navigation, manifests and a safe timestamp-restoration procedure/helper. Source
originals remain available until the next slice's authorized cleanup.

## Baseline and inputs

Read the project and arc plans, then the complete
[project map](artifacts/project-mapping.md),
[source inventory](artifacts/source-inventory.json) and
[branch inventory](artifacts/branch-inventory.json).
Implementation source pin is `18ba5b787d5b77f17050127569e3804585b1f772`.
The old Arc4 plan variant comes from ref `arc4/slice1-stabilize` at
`e16c0aa30ef466457c27766598e5d03c05f3f992`, blob
`157fdad71c4ec0234e5213dd908c26b8b81320c1`.

Before copying, reconcile live refs, content hashes, modes, nanosecond mtimes,
all observed directories and ignored workbench membership. Preserve this
initial inventory; record a dated successor if anything changed. Native
creation-time precision may be added before the copy; current birthtime fields
must not be represented as exact nanoseconds.

## Implementation approach for later execution

1. Confirm the Operator-approved map. Create only the named project homes.
   Reject destination collisions and source membership drift before writes.
2. Copy each of the 69 mapped planning payloads while retaining permissions and
   recorded metadata. Extract the branch variant by pinned blob, with source
   ref/path/commit and commit-derived timestamp provenance clearly labelled.
3. Compare every imported hash and mode before considering source removal.
   Keep basenames, issued prompt bodies, legacy support-file placement and old
   statuses unchanged. Preserve branch names/commits as evidence.
4. Add minimal current project metadata/roadmaps and navigation at needed scales.
   Preserve historical files that already occupy canonical plan/ledger names;
   add `migration-notes.md` beside those. Record legacy naming exceptions,
   reused Arc06/07 meanings, original reference aliases, explicit deferrals and
   pending historical acceptance. Do not automatically execute an old prompt.
5. Deliver `artifacts/restore-timestamps.py` and usage documentation. Default
   to read-only verification; require an explicit apply mode and root/manifest.
   Guard every write with expected type, relative path containment and content
   hash. Do not follow unexpected symlinks or mutate a changed payload. Preserve
   exact mtime_ns where supported; creation-time restoration is capability-
   checked and reported separately. Restore directory timestamps last. Include
   canonical-layout and original-layout recovery; split-parent metadata is not
   assigned arbitrarily to new grouping directories.
6. Commit preserved imports and provenance separately from new wrapper/helper
   changes when practical. Record the exact import pin and file denominator.
   Add only named paths. Do not backdate newly authored migration work.
7. After all writes/checks, restore and compare unchanged file/directory mtimes.
   Report any filesystem rounding or unsupported metadata. Exercise a guarded
   restore from a temporary fresh checkout in this slice; Slice02 repeats the
   complete source/canonical navigation and recovery path at composition scale.
8. Report each slice row, remaining findings and metadata limitations. Bubble
   findings up to the arc/project. All self-check evidence is attested. The next
   slice consumes the exact import commit and receipts, not an assertion that
   copying succeeded.

## Verification and exit criteria

No application behavior is changed; product build/test suites are outside this
slice. Verification is specific to migration: exact file inventory, content and
mode equality, collision/path guards, old-to-new ownership, timestamp equality,
current navigation and clean source diff. Negative cases for the restoration
helper must demonstrate refusal of a changed payload and escaping path before
metadata writes. These checks are planned; none has run in this planning turn.

The slice is ready for cutover only after all acceptance rows have evidence,
file/date denominators reconcile, recoverable import commits exist and findings
are explicitly dispositioned. Existing independent acceptance obligations stay
pending; new self-checks do not overwrite old verification claims.

## Artifact home and assignment record

Durable supporting output: this slice's `artifacts/`, including the initial
inventories/map, later restoration helper, usage, metadata receipts and drift
snapshots. Outputs must serve the import, preservation or cutover decision.

Current assignment: none; Operator requested preparation of this plan.
No `cc-prompt.md`, role handoff packet or close report is pre-created.
The project plan's workflow selection and this direct execution recipe are the
One-Contributor assignment convention; historical CC prompts remain intact.

## Version history

- v1.0 — 2026-10-17: draft import slice and exact proposed mapping; branches
  reviewed before reserving Project08; legacy payloads remain in source.

## Execution record — 2026-10-17

Current assignment: Operator approved all moves and completion of Project08.
Source inspection and lookup assistants are bounded to the approved corpus and
active documentation references. The original preparation-only assignment is
superseded. No CC-role handoff is simulated.

## Implementation status — 2026-10-17

All assigned execution and self-check work is delivered; see closing-report.md.
Earlier preparation/active status is superseded. Ledger evidence is attested;
human acceptance remains explicit and historical gates remain unchanged.
