# Owned captured stream acceptance ledger

All eight original criteria open; no implementation or acceptance.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| XS04-01 | Complete valid supported I/O is emitted in ordered bounded UTF8 chunks | Large binary/list/mixed encodings, exact concatenation and immutable origin | serious | Arc02 complete output / NR-02 | open | — | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-02 | I/O success requires every durable chunk and physical job disposition | Withheld ACK, send/ACK and done/DOWN inversions, invalid prefix/error/empty writes | serious | Arc02 complete output / NR-02 | open | — | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-03 | Native callbacks remain responsive with bounded admitted jobs and frames | 64jobs/68frames, ordinary overload recovery and nested MFA without deadlock | serious | Arc02 complete output / NR-02 | open | — | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-04 | Foreground and formatter ownership survives single-owner and startup gaps | Paused registration, trap_exit code, context/collector kills and unlink monitor | serious | Arc02 complete output / NR-02 | open | — | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-05 | NR-02 teardown under positive network pressure is resolved | send_pend before listener/registry/app faults, exact owned DOWN/trace, no helping drain | serious | Arc02 complete output / NR-02 | open | — | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-06 | Close/cancel/publication preserve no-false-completion and no-source-effect rules | Deferred token/state permutations, strong seal, physical terminal and honest timeout | serious | Arc02 complete output / NR-02 | open | — | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-07 | Existing behavior and actual Rust/native/terminal integration remain valid | 56retained native methods, full matching17, root/fresh/launcher/exports/current bytes | serious | Arc02 complete output / NR-02 | open | — | Initial cc-prompt.md; accepted X03 source7427d1c |
| XS04-08 | Complete documentation/evidence and composition ownership are retained | Exact12 hashes/patch, all8 return rows/failures/intake, C06 and broader gates explicit | serious | Arc02 complete output / NR-02 | open | — | Initial cc-prompt.md; accepted X03 source7427d1c |

Current preserved assignment cc-prompt-iteration01.md clarifies the two completion/
DOWN pairs; criteria/statuses unchanged, all8open. Author precision, no accepted
implementation or independent product-failure verdict.
