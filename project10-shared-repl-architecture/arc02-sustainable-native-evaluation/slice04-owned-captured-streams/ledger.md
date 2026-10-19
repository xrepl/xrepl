# Owned captured stream acceptance ledger

All eight original criteria open; no implementation or acceptance.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| XS04-01 | Complete valid supported I/O is emitted in ordered bounded UTF8 chunks | Large binary/list/mixed encodings, exact concatenation and immutable origin | serious | Arc02 complete output / NR-02 | open | [CC proposal](closing-report.md) / [raw gates](artifacts/validation.log) | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-02 | I/O success requires every durable chunk and physical job disposition | Withheld ACK, send/ACK and done/DOWN inversions, invalid prefix/error/empty writes | serious | Arc02 complete output / NR-02 | open | [CC proposal](closing-report.md) / [raw gates](artifacts/validation.log) | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-03 | Native callbacks remain responsive with bounded admitted jobs and frames | 64jobs/68frames, ordinary overload recovery and nested MFA without deadlock | serious | Arc02 complete output / NR-02 | open | [CC proposal](closing-report.md) / [raw gates](artifacts/validation.log) | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-04 | Foreground and formatter ownership survives single-owner and startup gaps | Paused registration, trap_exit code, context/collector kills and unlink monitor | serious | Arc02 complete output / NR-02 | open | [CC proposal](closing-report.md) / [raw gates](artifacts/validation.log) | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-05 | NR-02 teardown under positive network pressure is resolved | send_pend before listener/registry/app faults, exact owned DOWN/trace, no helping drain | serious | Arc02 complete output / NR-02 | open | [CC proposal](closing-report.md) / [raw gates](artifacts/validation.log) | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-06 | Close/cancel/publication preserve no-false-completion and no-source-effect rules | Deferred token/state permutations, strong seal, physical terminal and honest timeout | serious | Arc02 complete output / NR-02 | open | [CC proposal](closing-report.md) / [raw gates](artifacts/validation.log) | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-07 | Existing behavior and actual Rust/native/terminal integration remain valid | 56retained native methods, full matching17, root/fresh/launcher/exports/current bytes | serious | Arc02 complete output / NR-02 | open | [CC proposal](closing-report.md) / [raw gates](artifacts/validation.log) | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-08 | Complete documentation/evidence and composition ownership are retained | Exact12 hashes/patch, all8 return rows/failures/intake, C06 and broader gates explicit | serious | Arc02 complete output / NR-02 | open | [CC proposal](closing-report.md) / [raw gates](artifacts/validation.log) | Initial cc-prompt.md; accepted X03 source7427d1c |

Current preserved assignment cc-prompt-iteration01.md clarifies the two completion/
DOWN pairs; criteria/statuses unchanged, all8open. Author precision, no accepted
implementation or independent product-failure verdict.

## Iteration02 issue —2026-10-19

All8 statuses remain open. Actual early reviewer/root/native_design_review found
existing§4 paused-start diagnostic mismatch; CDC independently agrees. Preserved
iteration02 corrects exact no-activation fact after physical root DOWN. No new
criterion, source scope, UX work or acceptance; initial and iteration01 preserved.
Mutable source intake and complete early review snapshot retained in artifacts.

## Actual CC return —2026-10-19

All8 rows proposed done within issued scope at sourcecf1f1a2/Cayrn34af63e;
statuses stay OPEN for independent CDC review/reproduction. Full row walk, exact
source pair/hashes, actual76unique/root243native/175legacy/component93 populations,
54ordinary+14realnative+3consumer/PTY and failed/invalid/unrun dispositions are in
closing-report/artifacts. Initial/iteration01/iteration02 preserved, executed2/5.
C06 mixed composition and historical/tooling/package/UX/Operator holds retained;
no source push, release or whole-arc acceptance.
