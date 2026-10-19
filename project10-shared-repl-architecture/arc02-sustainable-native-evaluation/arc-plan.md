# Arc02 — sustainable native evaluation

Version1.5,2026-10-19. Active under scoped Autonomous Mode. Project10 source release/0.2.x.
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
| [Slice01 — fenced capture lifetimes](slice01-fenced-capture-lifetimes/slice-plan.md) | More-than 256 native evaluations; scalar token fence,64 live capture origins, collector retirement with late-output/ACK/close proof | Actual Cayrn C03 native v2 identity/journal return | Independently accepted7228183/7b27b0f; matching native2 gate passed |
| [Slice02 — node authority leases](slice02-node-authority-leases/slice-plan.md) | Bounded live native lease/context registry; boot/lease/ticket fencing removes4096 cumulative guard | Actual accepted Cayrn C04 native3 handoff; Operator direction approved | Open set draft; upstream implementation-held |
| Slice03 — size-safe previews and captured streams | Bounded explicit value previews and complete bounded-chunk captured output, pressure paths preserving environment/capture ACK correctness | Actual Cayrn C05 structured-preview contract after C04/X02; stable size budgets | Roadmap only; complete source-led pressure/ownership/preview design required |

Directory numbering does not invent a dependency from node identities to size
safety. First-slice operation fencing/collector budgets do not solve node churn,
arbitrary spawned-process resources or output pressure; retain their explicit
owners. Never solve tombstones by deleting stale-context evidence without a new
fence. No prototype/native source edits are authorized by this planning packet.

## Composition ledger and exit

Sibling ledger.md covers first-slice long sessions, complete retained attribution,
node churn beyond 4096, safe result/output handling and actual mixed lifecycle/
pressure behavior on matching source revisions. Cayrn Arc01/Slice06 consumes the
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


## Slice02 design decision — proposed, awaiting Operator discussion

Source inspection after Slice01 confirms that the listener's public ETS table
retains one entry for every Hello session identity and stops normal sequential
admission at4096. Removing entries on close would permit an old Hello/dispatch
stream to create a fresh evaluator under an old identity. Neither TTL eviction
nor silent tombstone deletion satisfies the preserved no-replay/fencing contract.
This choice was already reserved in Slice02's roadmap; no implementation prompt
is issued until it is resolved. Source-space build support remains a separate
packaging follow-up, not a reason to change this protocol decision.

**CDC recommendation:** introduce a connection-owned host-authority lease in the
shared Rust connector, retaining separate per-session runtime sockets. Here
“lease” has no clock or timeout expiry: one live authority connection owns it.
A native boot identity and monotonically issued lease identity prevent a retired
authority handle from becoming current again; native metadata tracks only live
leases. Each lease keeps a scalar context-admission high-water mark and bounded
live contexts, replacing the historical session-ID set. Rust serializes context
creation handshakes per lease and assigns sparse increasing context tickets;
failed attempts consume tickets. Evaluations retain the existing journal-backed
operation token, independent of the context ticket. A lost session socket loses
that context; loss of the host-authority channel retires all contexts belonging
to that host. Other hosts/leases remain independent.

| Owner | State / responsibility |
| --- | --- |
| Shared Rust | Host-authority channel lifecycle, serialized context-ticket allocation, durable public session/generation/operation admission and no native reconnect/replay |
| Thin native agent | Current boot/lease handles, per-live-lease high-water scalar and bounded live-context ownership; reject retired/replayed tickets and enforce native control/capture hooks |
| Journal | Complete historical public identities/transcript; no new native durable authority or transcript replay |

Native handshake changes need a separately versioned paired native protocol
revision; public client RPC need not change for this direction. Support multiple
Rust hosts with a bounded active-lease budget, rather than keeping past host
identities forever. Boot-handle generation, limits, atomic admission/retirement,
connect/disconnect races and exact errors must be specified against source in
the complete open set before implementation. The native permanent guard would
then protect lease/context tickets, while Rust remains responsible for never
allocating a new native context for a closed/lost public session. This boundary
is explicit: a deliberately rewritten Hello with a NEW valid context ticket is
not the same message replay; the native agent is not a second durable public
session registry. Keep bounded duplicate-live-session checks where applicable.

**Tradeoff:** the authority channel introduces another failure path whose loss
ends all of one host's live contexts, even if individual sockets were healthy.
It gives stronger native protection against accidental reissue of an old
context ticket and a clear bounded ownership hierarchy, at the cost of one
additional connection and a native transient lease registry. Thin LFE/Lua/JS
agents would implement only that native registry/hooks; common policy remains
Rust. No heartbeat, distributed leader election or clock-based lease is proposed.

**Alternative:** give every new context connection a fresh native challenge,
remove historical native IDs, and rely entirely on Rust's durable public-session
admission/no-reconnect policy. This keeps per-context failure isolation and a
smaller native adapter; it fences verbatim old handshakes but supplies less
protection against a host incorrectly constructing a fresh connection for an
old public session. Persistent native tombstones are not recommended because
they add a second historical store instead of solving ownership.

Operator decision requested: endorse the host-authority lease direction, prefer
the per-context challenge boundary, or discuss another approach. Existing
Slice01/native2 acceptance work proceeds independently. Slice02 and the dependent
Cayrn Slice04 composition remain held only at this architectural decision; the
separate size/preview design also remains to be made explicit before its prompt.
No implementation or external research is commissioned by this proposal.

## Slice01 accepted — 2026-10-18

Actual source7228183/Cayrn7b27b0f independently accepted by CDC /root,
implementer /root/xrepl_x21. [Verification](slice01-fenced-capture-lifetimes/cdc-verification.md)
and [retrospective](slice01-fenced-capture-lifetimes/cdc-retrospective.md) retain
27 ordinary/12 native/3 client/21 unique native and236 root EUnit executions,
fresh source and root launcher evidence. This discharges the matching-native2
runtime hold; XA02-01/02 are done at their bounded scope, not whole-arc acceptance.
Node4096/size8192/slow-pressure/full composition and historical gates remain.
The proposed Slice02 architecture below remains unapproved pending Operator reply.

## Operator node-authority decision — 2026-10-18

Operator selected **Host authority and context tickets (recommended)** in the
architectural question reply. The earlier awaiting-decision proposal is now
resolved in that direction. Common Rust policy and native transient ownership
are being specified in the canonical native3 contract under Cayrn
Project02/Arc01/Slice04 artifacts/native-authority-contract.md. No clocks, expiry,
heartbeat, replay or native durable registry. Actual dependent implementation
requires complete reviewed open sets, not this status note alone.

## v1.3 — node-authority direction resolved,2026-10-18

Operator approved host authority/context tickets. Prepared Slice02 now consumes
the bounded shared Rust native3 C04 handoff; no native code begins until actual
accepted source exists. Earlier awaiting-decision text is historical. The Rust
connector slice is in Cayrn Arc01 before this native slice; former C04 whole
composition becomes C05 without dropping any obligation. X03 size work and final
composition remain open; approved direction does not imply implementation proof.

## v1.4 — native teardown pressure residual,2026-10-19

X02 preimplementation review NR-02 identified a pre-existing native2 orphan-root
window: a context blocked in send can reach supervisor's kill deadline before
terminate. Native3 adds registry-failure exposure. Preserve this serious open
finding with Slice03's existing output-pressure ownership; XA02-05/06 cannot close
without listener/registry/application teardown under real pending output and
paused-root startup ownership proof. X02 remains the bounded node-authority
increment; authority-only loss still must wake blocked contexts directly and
preserve other leases. No general teardown-under-pressure claim is made at X02.
Cayrn C05 consumes this gate in final composition. The exact X02 source allowlist
is unchanged; no collector workaround is implemented as an unreviewed side task.

## v1.5 — shared preview metadata and composition numbering,2026-10-19

Operator selected **Shared preview metadata (recommended)**. X03 reports
formatter-specific truncation facts through a shared Rust result-preview
contract; clients do not infer them from LFE text. Existing XA02-04 explicit
metadata criterion remains; supported captured output must still be complete.
Cayrn introduces bounded C05 shared preview metadata before X03; former unissued
C05 final composition becomes C06. All earlier C05-composition references are
historical names for the same retained gate, now C06 (including NR-02). Nothing
is silently dropped or accepted. Current order C04→X02→C05→X03→C06.

Exact preview envelope/validation and protocol/archive compatibility require a
reviewed design/open set against actual sources; no native/public version bump
is presumed here. C04's issued native3 contract and current X02 design stay
unchanged. X02 remains held only for actual C04 acceptance, not this later
preview work. Broader migration, UX, publication and Operator gates stay open.

This dated decision/roadmap note is bounded One-Contributor recordkeeping by
CDC: the explicit Operator reply and numbering/dependency update were
self-checked, ledger identities/criteria preserved, no source or acceptance
change claimed. Substantive implementation retains independent review.
