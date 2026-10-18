# Arc01 — xrepl current-state assessment

Status: active; first slice prepared, execution pending. Created 2026-10-17.
Parent: [Project09](../project-plan.md).

## Capability and slice roadmap

Deliver one coherent assessment of plan quality, implementation extent and
LFE/Rust code quality on a recorded baseline. Each slice yields a usable report
or map, preserving original evidence and unresolved gaps for later consumers.

| Slice | Useful outcome | Required inputs | State |
| --- | --- | --- | --- |
| [slice01-plan-assessment](slice01-plan-assessment/slice-plan.md) | Cited plan-quality report, source/corpus inventory and obligation IDs | Project01–07 originals/navigation, Project08 provenance, source structure | Prepared |
| slice02-implementation-map | Capability status map and native build/test receipts | Slice01 obligations/baseline plus code/test inspection | Planned; detail after Slice01 |
| slice03-lfe-audit | LFE/OTP audit report with severity, evidence and coverage | Existing inventory/map, Chineual guide and applicable OTP/Erlang guidance | Planned; detail after Slice02 |
| slice04-rust-audit-and-synthesis | Rust audit, index, cross-language analysis and prioritized combined backlog | Existing map/evidence, LFE findings and full Rust audit guidance | Planned; detail after Slice03 |

Later slices remain roadmap entries, not empty directories or issued prompts.
No artificial implementation work is needed to make assessment useful.

## Method and composition

Review plans for purpose/scope, architecture assumptions, dependencies,
acceptance, traceability, status consistency and safe resumption. Judge older
plans in historical context; absence of today's folder conventions is not
itself a defect. Distinguish Project08 wrappers from original intent. Preserve
child acceptance criteria and distinguish repeated promises from new scope.

The implementation map distinguishes demonstrated behavior, partial delivery,
source present but unverified, absent implementation, explicit deferral and
ambiguous obligations. Keep an interpretable denominator. Native test/build
results support judgments but do not prove the plan complete.

Map every first-party module/crate/target and support surface before audit
findings. Follow code-auditing's severity, negative-check and scale-coverage
contracts and Project09's language guidance. A targeted read is not full audit
coverage. Recheck historical findings and label unchanged, changed or unknown.
Record host/tool/dependency state, exact failures and isolated probes. No source
corrections or historical contract changes are part of the arc.

## Artifacts and acceptance

Each slice owns its supporting `artifacts/`, with dated report filenames.
The final slice owns the index and modernization synthesis and links earlier
reports. Keep source instruction/routing edits separate from planning changes.
The [ledger](ledger.md) checks child delivery and composition.

Use the Operator-defined coordination/optional-CC workflow and Expedited Mode
in the project instructions. Sofie's own work remains attested; actual CC
deliveries get real coordinator review and applicable independent checks before
acceptance. Lookup summaries do not establish independent verification. Final
human acceptance is explicit. Write close reports only after delivery, with
scope comparison and bubble-up. Update plans openly as findings affect the
roadmap; scope changes go to the Operator. Commit and advance as gates permit.

## Version history

- v1.0 — 2026-10-17: define four-slice roadmap and prepare Slice01; defer later
  detail until its evidence inputs exist.
- v1.1 — 2026-10-17: carry the Operator's optional-CC coordination and
  Expedited Mode selection into arc execution; deliverable scope is unchanged.
