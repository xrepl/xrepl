# XS22 acceptance ledger

All rows open; no implementation acceptance.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| XS22-01 | Native3 handshakes enforce boot/lease/ticket domain and live owner scope | Malformed/cross-lease/stale/duplicate live SID/echo and side-effect negatives | serious | Approved host-authority direction/native3 contract | open | — | No execution yet |
| XS22-02 | Context/authority history does not consume cumulative lifetime budget | 4097 context close cycles,33 authority cycles, exact-DOWN bounded maps and final evaluation | serious | Approved host-authority direction/native3 contract | open | — | No execution yet |
| XS22-03 | Authority loss retires all its contexts and no peer lease | Raw sockets held open; roots/collectors/traces reaped; other lease still evaluates; partial-byte negative | serious | Approved host-authority direction/native3 contract | open | — | No execution yet |
| XS22-04 | Pressure and monitor correlation are explicit and recoverable | 16/17 authorities,64/65 contexts, forged DOWN/physical release recovery and exhausted counters | serious | Approved host-authority direction/native3 contract | open | — | No execution yet |
| XS22-05 | Socket handoff and teardown preserve bounded ownership | Paused recipient, timeout/closed socket failure, raw authority reads;128 sockets/256 process proof | serious | Approved host-authority direction/native3 contract | open | — | No execution yet |
| XS22-06 | OTP/native startup and existing capture contract remain sound | All existing21 cases; registry supervision restart/fresh boot, crypto dep, no legacy startup | serious | Approved host-authority direction/native3 contract | open | — | No execution yet |
| XS22-07 | Actual matching host/terminal and fresh/legacy checks pass | Full Cayrn check lint-integration test-xrepl incl4097 public churn +twoHosts; native fresh/root tests | serious | Approved host-authority direction/native3 contract | open | — | No execution yet |
| XS22-08 | Return and residual size/composition owners are complete | Exact16-path candidate (iteration01 app-owner addition), all rows, failure/count inventory, re-entry owners and parent update | serious | Approved host-authority direction/native3 contract | open | — | No execution yet |

## Scope-count reconciliation —2026-10-19

Iteration01 explicitly adds apps/cayrn_lfe/src/cayrn_lfe_app.lfe to the original
15-path allowlist (current16). XS22-08 source-count text is updated15→16 to match
that issued, reviewed scope; its complete-return/ownership requirement and all
other seven criteria are preserved. This is a disclosed source-scope expansion,
not a silent unchanged-count claim or weakened acceptance. Original ledger text
remains in Git history; issued prompt files are unchanged. All rows remain open.
