# Fenced capture lifetime acceptance ledger

Prepared, not executed. All 8 rows open. Planning/source inspection is attested;
no runtime pass or independent acceptance implied.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| XS21-01 | Native2 canonical tokens fence stale/replayed dispatch with bounded metadata | Sparse/replayed/invalid tokens and visible non-execution; no seen-ID history | serious | Resource design | open | — | Not implemented |
| XS21-02 | Quiet sessions pass512 native and 1024 integrated evaluations without state loss | Bindings, retry/dedup and complete replay at exact matching source pins | serious | Resource design | open | — | Not implemented |
| XS21-03 | Producer-aware collectors retire only after complete drain proof | Spawn/exit/order inversions, send witnesses, ACK withheld and sys/trace checks | serious | Resource design | open | — | Not implemented |
| XS21-04 | At most64 origins produce explicit recoverable pressure, not environment loss | 64 held/65th refusal, no source side effect; controlled release and new token | serious | Resource design | open | — | Not implemented |
| XS21-05 | ACK, late attribution, close and failure semantics remain intact | Old writer release, no false ACK, close/retire races, collector crash/peer tests | serious | Resource design | open | — | Not implemented |
| XS21-06 | Ownership/tracing cleanup follows OTP and LFE conventions | Scoped trace isolation, gen_server specs/exports; no node-global flags/PID tombstones | serious | Resource design | open | — | Not implemented |
| XS21-07 | Native/client/legacy gates run against actual matching inputs | Fresh component, native discovery, full real14+new, Rust/legacy/CT populations | serious | Resource design | open | — | Not implemented |
| XS21-08 | Return preserves boundaries/residual owners and all rows | Exact source candidate, all 8 rows/logs/artifact inventory; tombstone/size owners | serious | Resource design | open | — | Not implemented |
