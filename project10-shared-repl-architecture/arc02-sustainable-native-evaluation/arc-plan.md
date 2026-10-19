# Arc02 — sustainable native evaluation

Version1.1, 2026-10-18. Active under scoped Autonomous Mode. Project10 source release/0.2.x.
Original prepared one-contributor wording is superseded by the activation below.
Sofie CDC independently reviews the assigned CC implementation. Arc01's import and
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
| [Slice01 — fenced capture lifetimes](slice01-fenced-capture-lifetimes/slice-plan.md) | More-than 256 native evaluations; scalar token fence,64 live capture origins, collector retirement with late-output/ACK/close proof | Actual Cayrn C03 native v2 identity/journal return | Active; actual C03 return7b27b0f reconciled before native edits |
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


## Autonomous Mode activation — 2026-10-18

The Operator explicitly selected collaboration-framework **2.8.0 Autonomous
Mode** for the remainder of this arc. This supersedes earlier planning-only,
one-contributor/no-delegation and per-commit approval restrictions for this
authorized scope; it does not rewrite historical prompts or upgrade prior
self-attested evidence. Endpoint: **arc02-sustainable-native-evaluation**, including remaining slices,
iterations, independent review, remediation, local commits, composition checks
and CDC retrospectives. No later arc, project acceptance, push, merge, registry
publication or UX scope is authorized. Existing Project01/Project09 and Operator
gates remain pending unless actually discharged under their own contracts.

Source: `/Users/oubiwann/lab/lfe/xrepl/xrepl` on **release/0.2.x**, intake HEAD `f261152fc150a1addf3286a97b6a1a0324a42869`;
plans remain in `/Users/oubiwann/lab/lfe/xrepl/xrepl/.worktrees/planning` on orphan `planning`.
These existing non-default source branches are reused. Preserve unrelated work,
including xrepl's untracked docs/design. Source/planning commits use separate
explicit allowlists and both required co-author trailers.

CDC: Sofie in the primary /root context, owning design, integration and
retrospectives. Substantive slices use Two-Contributor execution: a fully
briefed CC subagent implements; CDC independently inspects source and reproduces
evidence, recording the actual author/context in `cdc-verification.md`. If CDC
implements a repair, assign a different reviewer before acceptance. Independent
arc composition uses a fresh reviewer context. One-Contributor is reserved for
bounded mechanical tasks with recorded rationale and self-checks. Routine
handoffs use contributor tools with preserved assignments; arrangement changes
retain findings, iteration counts and evidence state. Five-pass limits remain.

Current open work: Cayrn Arc01/Slice03 and xrepl Arc02/Slice01. Every opening row
is still open. Earlier Slice01/02 returns retain their attested/pending status.
Cayrn native2 implementation returns before dependent xrepl source changes;
matching-agent real gates remain held until xrepl returns. No whole-arc dependency
cycle or retroactive conformance claim. Later roadmap slices require complete
engineering-ready open sets before implementation. Material architecture/scope
changes or ambiguities go to the Operator; pause affected work only.

Expedited Mode applies within this endpoint. Close/bubble up only against actual
reviewed evidence, and write `cdc-retrospective.md` at every newly closing scale.
The initial prepared prompt remains preserved; activation and actual CC assignment
are in the slice's `cc-prompt-iteration01.md`. CDC is next-action owner until the
CC acknowledges its exact packet.


## Accepted upstream and active Slice01 — 2026-10-18

Cayrn C03 native2 source7b27b0f4a24d9dd85918fd590760b472a60798a3 is the actual
consumed interface; its bounded Rust acceptance and retrospective are committed
in Cayrn planning cdec989. Native CC /root/xrepl_x21 acknowledged and reconciled
all41 baseline paths and the10 approved upstream deltas before native source
edits. Source remains release/0.2.x overf261152, with docs/design excluded.
The prepared dependency hold above is superseded only by this real handoff.
All12 native +3 consumer runtime gates are now assigned to X01 at matching pins;
no native runtime pass is yet claimed. Node identity and size designs retain
their separate later owners and required decisions.

Version history v1.1: scoped Autonomous Mode2.8.0 and the real C03 handoff change
workflow/status/dependency identity, without changing architecture or acceptance.
