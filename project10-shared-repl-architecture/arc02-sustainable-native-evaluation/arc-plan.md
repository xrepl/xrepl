# Arc02 — sustainable native evaluation

Version1.0, 2026-10-18. Prepared, not executed. Project10 source release/0.2.x.
Sofie remains the sole contributor; self-review is attested. Arc01's import and
LFE conversion are committed at ea844f5/f261152 with pending independent gates.
Those bounded working interfaces and the Operator's next-planning request suffice
to prepare this arc; no formal Arc01 close or independent acceptance is invented.

## Capability and boundaries

Keep real LFE environments usable across long sessions: native dispatch replay
is fenced without a lifetime ID set, capture resources follow live producer
lifetimes, legitimate pressure preserves committed state, and result/output size
handling cannot turn ordinary large values into context loss. Rust owns durable
policy and protocol; this thin OTP app owns runtime-specific process/I/O hooks.
Complete supported output remains ordered/durable; bounded value previews may be
explicitly truncated. No user-code memory sandbox, heap restoration or UX project.

## Inputs and sequence

Current xrepl source f261152; Cayrn 722d086 is still native v1. First slice consumes
Cayrn Project02/Arc01/Slice03's actual native v2 return when available, not an assumed
future commit. The two projects use one canonical proposed resource design at
/Users/oubiwann/lab/oxur/cayrn/.worktrees/planning/project02-core-hardening/arc01-native-session-hardening/slice03-journal-backed-native-identities/artifacts/native-resource-contract.md. No duplicated policy copy.
C03→X01 is a bounded interface dependency, not a circular whole-project gate.
The first native landing must run actual host/terminal integration immediately;
final system size/churn checks are additional composition, not deferred-only QA.

| Slice | Usable result / delivery | Actual dependency | State |
| --- | --- | --- | --- |
| [Slice01 — fenced capture lifetimes](slice01-fenced-capture-lifetimes/slice-plan.md) | More-than 256 native evaluations; scalar token fence,64 live capture origins, collector retirement with late-output/ACK/close proof | Actual Cayrn C03 native v2 identity/journal return | Fully prepared; dependency-held and not activated |
| Slice02 — bounded node identity lifecycle | Remove4096 cumulative context-tombstone lifetime guard while retaining stale generation/authority and concurrent-context protection | X01 actual ownership/retirement behavior; resolved authority/tombstone design | Roadmap only; do not issue implementation until design/Operator decision |
| Slice03 — size-safe previews and captured streams | Bounded explicit value previews and complete bounded-chunk captured output, pressure paths preserving environment/capture ACK correctness | LFE conversion; stable wire budgets; align with current native v2 if after X01 | Roadmap only; may proceed independently of node churn after design |

Directory numbering does not invent a dependency from node identities to size
safety. First-slice operation fencing/collector budgets do not solve node churn,
arbitrary spawned-process resources or output pressure; retain their explicit
owners. Never solve tombstones by deleting stale-context evidence without a new
fence. No prototype/native source edits are authorized by this planning packet.

## Composition ledger and exit

Sibling ledger.md covers first-slice long sessions, complete retained attribution,
node churn beyond 4096, safe result/output handling and actual mixed lifecycle/
pressure behavior on matching source revisions. Cayrn Arc01/Slice04 consumes the
native results and tests the full cross-repository system; both owner reports
remain attributable. Children passing alone do not close this arc. Preserve
original failure/physical durability gaps and Project09's27 finding dispositions;
new native work does not accept or retire unrelated legacy behavior.

## Deferred and retained owners

- Node 4096 guard: Slice02, design held. No declaration of bounded whole-node life
  from first-slice origin reclamation.
- Oversized result assertion and output chunking/pending pressure: Slice03.
- Public session catalog/input/LFE services and legacy migration: later project
  arcs, not bundled into native resource work.
- X-UX-01 remains the Operator-owned future UX project after core composition.
- Standalone agent remains untouched provenance; native v1 is paired with its old
  host. Native2 has no automatic fallback or package publication authorization.

## Workflow and version history

The next-planning authorization keeps one collaborator, Sofie, with distinct
implementation/self-review passes after activation; no agents or independent-role
files. Implementation/source/new-plan commits, pushes and publication are separate
requests. Ledger row closure follows the existing preserved acceptance contract.
The first slice's artifacts/ is its evidence home. Later open sets follow actual
results, not speculative future pins.

- v1.0 —2026-10-18: Arc01/Slice02 conversion/profile returns identify concrete
  resource holders. Prepare native capture/fencing slice paired with Rust C03,
  split remaining node identity and size obligations into explicit later owners.
