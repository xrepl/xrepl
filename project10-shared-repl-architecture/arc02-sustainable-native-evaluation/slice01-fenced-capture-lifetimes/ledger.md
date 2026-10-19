# Fenced capture lifetime acceptance ledger

All8 rows independently accepted by Sofie /root at7228183/Cayrn7b27b0f.
Actual implementer /root/xrepl_x21. See [CDC verification](cdc-verification.md)
and [CDC retrospective](cdc-retrospective.md); original CC attestations remain below.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| XS21-01 | Native2 canonical tokens fence stale/replayed dispatch with bounded metadata | Sparse/replayed/invalid tokens and visible non-execution; no seen-ID history | serious | Resource design | done | attested: artifacts/native-tests.log; token-replay-and-invalid / capacity refusal | Accepted: scalar sparse/canonical fence; visible replay non-execution |
| XS21-02 | Quiet sessions pass512 native and 1024 integrated evaluations without state loss | Bindings, retry/dedup and complete replay at exact matching source pins | serious | Resource design | done | attested: artifacts/native-tests.log; matching-cayrn-gates.log | Accepted:512 native and1024 integrated binding/late-origin/replay checks |
| XS21-03 | Producer-aware collectors retire only after complete drain proof | Spawn/exit/order inversions, send witnesses, ACK withheld and sys/trace checks | serious | Resource design | done | attested: artifacts/native-tests.log; callback order / async descendants / exact DOWN tests | Accepted: birth/exit/delivery, send/request and ACK witnesses; physical credits |
| XS21-04 | At most64 origins produce explicit recoverable pressure, not environment loss | 64 held/65th refusal, no source side effect; controlled release and new token | serious | Resource design | done | attested: artifacts/native-tests.log; capacity-refusal-and-recovery / full-capacity-close | Accepted:64/65 non-evaluation, consumed refusal token, controlled recovery |
| XS21-05 | ACK, late attribution, close and failure semantics remain intact | Old writer release, no false ACK, close/retire races, collector crash/peer tests | serious | Resource design | done | attested: artifacts/native-tests.log; matching-cayrn-gates.log | Accepted: exact ACK/ownership, held-output cancel, close/retire, collector/peer failure |
| XS21-06 | Ownership/tracing cleanup follows OTP and LFE conventions | Scoped trace isolation, gen_server specs/exports; no node-global flags/PID tombstones | serious | Resource design | done | attested: artifacts/native-tests.log; fresh-native.log; source-candidate.patch | Accepted: isolated tracing/cleanup, OTP record server, no historical PID/operation sets |
| XS21-07 | Native/client/legacy gates run against actual matching inputs | Fresh component, native discovery, full real14+new, Rust/legacy/CT populations | serious | Resource design | done | attested: artifacts/matching-cayrn-gates.log; xrepl-gates.log; xrepl-final-lfe.log; fresh-native.log; root-launcher.log | Accepted:27 ordinary,15 real,21 unique native,236 root executions, Rust7+1, CT0 disclosed |
| XS21-08 | Return preserves boundaries/residual owners and all rows | Exact source candidate, all 8 rows/logs/artifact inventory; tombstone/size owners | serious | Resource design | done | attested: closing-report.md; artifacts/execution.md; artifacts/source-candidate.json; artifacts/development-checks.log | Accepted: exact7-path commit,8-row return, residual4096/8192 owners and pending review |

Independent evidence for each row: cdc-verification.md row walk and artifacts/cdc-* logs. No arc/project/Operator acceptance inferred.
