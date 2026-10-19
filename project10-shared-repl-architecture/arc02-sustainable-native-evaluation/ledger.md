# Arc02 composition ledger

Slice01 independently accepted at7228183/Cayrn7b27b0f; remaining composition and Operator gates stay open.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| XA02-01 | A live native session exceeds256 evaluations without losing bindings | 512 native +1024 real matching-host cases, immutable retry/late writer | serious | Project10 resource DoD | done | [Slice01 independent verification](slice01-fenced-capture-lifetimes/cdc-verification.md) | Accepted bounded capability at7228183/Cayrn7b27b0f; full mixed composition is XA02-06 |
| XA02-02 | Capture resources retire with strict producer/ACK/barrier proof | Origin budgets, trace cleanup/isolation and close/cancel races | serious | Project10 resource DoD | done | [Slice01 independent verification](slice01-fenced-capture-lifetimes/cdc-verification.md) | Accepted bounded capability at7228183/Cayrn7b27b0f; full mixed composition is XA02-06 |
| XA02-03 | Node churn does not consume a cumulative4096 lifetime budget | More-than 4096 create/close with bounded live registry and stale/replay negatives | serious | Project10 resource DoD | done | [Slice02 independent verification](slice02-node-authority-leases/cdc-verification.md) | Accepted38338d6/Cayrn3bcbbdb;4097 native/public churn, full mixed composition remains XA02-06 |
| XA02-04 | Large value previews preserve environments and mark truncation | Boundary-value/native failures with retained bindings and explicit metadata | serious | Project10 resource DoD | open | — | Operator chose shared machine-readable metadata; C05 Rust contract→X03 native |
| XA02-05 | Supported captured output is complete ordered bounded chunks | Unicode/chunk/pressure/ACK-failure tests and full transcript replay | serious | Project10 resource DoD | open | — | No evidence yet; complete streams and NR-02 now X04-owned, former combined X03 |
| XA02-06 | Slices compose with actual Rust host and terminal | Mixed sustained/churn/size/slow-client/control gate at same source pins | serious | Project10 resource DoD | open | — | Includes NR-02 listener/registry/app shutdown under pending output and paused-root ownership; X03+X04 then C06 |
| XA02-07 | All residual findings, scope and gates are dispositioned | Arc close full row walk, Project09 links, owners and project bubble-up | serious | Project10 resource DoD | open | — | No evidence yet |
