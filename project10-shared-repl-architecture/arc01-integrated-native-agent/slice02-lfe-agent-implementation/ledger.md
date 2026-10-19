# LFE native-agent conversion acceptance ledger

Prepared, not executed. All8 rows are open; planning checks are not runtime
acceptance. One-contributor self-checks are attested; preserved gates remain.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| XS02-01 | Five runtime modules and three native tests are replaced by LFE | Complete old/new map, exact 8+8 paths, compile_info .lfe and clean-copy check | correctness-grade | Slice02 design | open | — | Not implemented |
| XS02-02 | Native OTP application identity and topology remain compatible | Export/spec inventory, metadata equality, fresh-node startup exclusions | serious | Slice02 design | open | — | Not implemented |
| XS02-03 | Evaluation/control/identity semantics survive translation | Existing 11 native and3 actual consumer/PTY cases at explicit converted path | serious | Slice02 design | open | — | Not implemented |
| XS02-04 | All seven native tests retain their discriminating assertions | Explicit EUnit case inventory, ref/owner comparisons and no false ACK/seal checks | serious | Slice02 design | open | — | Not implemented |
| XS02-05 | Translated source follows scoped LFE conventions with justified exceptions | Style review, explicit exports/specs/docs, compatibility naming map | correctness-grade | Slice02 design | open | — | Not implemented |
| XS02-06 | Clean and incremental builds exercise new code while legacy modes survive | Fresh component build/native case, root build/Rust and legacy test comparison | serious | Slice02 design | open | — | Not implemented |
| XS02-07 | Known limits/dependencies and import provenance remain honest | Diff excludes resource/size fixes, evaluator/metadata/locks unchanged, docs/map | serious | Slice02 design | open | — | Not implemented |
| XS02-08 | Return supplies reproducible candidate and Cayrn handoff | Eight-row closing walk, source pin/map/checks/inventory and arc bubble-up | correctness-grade | Slice02 design | open | — | Not implemented |
