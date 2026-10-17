# Remediation lineage and unresolved work

Retrospective index, 2026-10-17. No new implementation acceptance.

- Original [program plan](2026.06.10-remediation-program-plan.md), lines64–93,
  maps every L-01–L-21/G/D item. Its structural Arc06 and Rust Arc07 were
  intentions; they are not project06's multishell Arc06 or project07's xs Arc07.
- Arc04 [verification](arc04-green-baseline/slice01-stabilize/cdc-verification.md),
  lines20–21, 32–36, 49–52, leaves F-1/F-2 reproduction with the Operator.
- Arc05 [plan](arc05-critical-correctness/arc-plan.md), lines31–35, is older than
  its slice1 [verification](arc05-critical-correctness/slice01-keepalive-desync/cdc-verification.md),
  lines281–303 (7/7 at 5a46cc5). The mismatch is retained, not silently rewritten.
- Original Arc05 slices2–5 (L-04/L-05/L-09 and L-02 swing) need an explicit
  resumption/disposition; no accepted records for them were imported.
- Structural L-03/L-06/L-07/L-08/L-10/L-12/L-13/L-14/L-15/L-16/L-17/L-18/L-19/L-20
  remain owned by the original program backlog, not silently dropped.
  L-11 depends on the Rust inversion decision, owned with Project05 lineage.
- Decode-error request-id/map-key family is explicitly deferred in the Arc05
  verification lines252–255 and closing-report lines202–208.
- Rust G-01 streaming/G-02 interrupt/G-03 shutdown and open D-02 live in
  Project05's original architecture addendum and bootstrap. Their external
  protocol/TypeScript/typed dependencies are references, not imported scope.

These are evidence pointers for selecting future bounded work, not an audit of
whether later source commits might have addressed any of these items.
