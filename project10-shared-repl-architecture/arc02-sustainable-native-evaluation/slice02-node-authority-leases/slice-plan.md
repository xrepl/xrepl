# Slice02 — bounded native authority leases

Version1.0 draft,2026-10-18. xrepl Project10/Arc02, release/0.2.x source7228183;
only pre-existing docs/design/ untracked. Operator selected host authority and
context tickets. Useful result: native LFE agent can create/close more than4096
contexts with bounded LIVE identity metadata; shared host ownership failure is
explicit, peers isolated, full real Rust/terminal integration runs on landing.

## Actual prerequisite and canonical design

Cayrn C04 must first return its exact independently accepted native3 candidate.
Record actual source pin/allowlist/readback before implementation. Do not guess
a future hash or execute against native2. Canonical contract at
/Users/oubiwann/lab/oxur/cayrn/.worktrees/planning/project02-core-hardening/arc01-native-session-hardening/slice04-host-authority-tickets/artifacts/native-authority-contract.md,
required-full §§1–7. Root owns design; CC implements resolved behavior, not a new
protocol/lease policy. Read actual C04 return/review and changed source before
activation. All old21 native/resource cases remain positive regression controls.

## Implementation route

Add registry, initial socket router and authority role, each a focused gen_server;
use private record state and monitors. Update supervisor temporary-role APIs and
listener ownership/counting. Context admission precedes environment/Ready; no
historical ETS. Native boot uses declared crypto application. Maintain exact
physical monitor credit, role ownership, trace/producer/ACK/cancel/close behavior.
Adapt resource helper's child discovery by module; new authority tests are
explicit companions. Optional private include/cayrn_lfe_registry.lfe may share
registry record definitions with owned-peer tests; no public debug endpoints.

## Exact source scope

- apps/cayrn_lfe/src/cayrn_lfe_registry.lfe
- apps/cayrn_lfe/src/cayrn_lfe_connection.lfe
- apps/cayrn_lfe/src/cayrn_lfe_authority.lfe
- apps/cayrn_lfe/src/cayrn_lfe_context.lfe
- apps/cayrn_lfe/src/cayrn_lfe_listener.lfe
- apps/cayrn_lfe/src/cayrn_lfe_sup.lfe
- apps/cayrn_lfe/src/cayrn_lfe.app.src
- apps/cayrn_lfe/include/cayrn_lfe_registry.lfe
- apps/cayrn_lfe/test/cayrn_lfe_authority_tests.lfe
- apps/cayrn_lfe/test/cayrn_lfe_resource_tests.lfe
- apps/cayrn_lfe/test/cayrn_lfe_io_tests.lfe
- apps/cayrn_lfe/test/cayrn_lfe_application_tests.lfe
- apps/cayrn_lfe/README.md
- apps/cayrn_lfe/AGENTS.md
- README.md

No evaluator/collector/legacy/Rust/build/launcher/version/lock changes. app.src
registered list and crypto dependency may change; keep native app0.1.0/xrepl0.2.0.
No external dependency or standalone predecessor edits.

## Checks and point of use

Native make check and root make test-lfe/build-agent/check-agent/build/lint-rust/
test-rust; matching Cayrn make check lint-integration test-xrepl with overrides
unset. All old15 real cases plus new4097-public-session churn and twoHost isolation
run against this new native3. Fresh source-only component make check; root wrapper
from /private/tmp with spaced socket, native-only started apps now including
crypto/compiler. Count actual unique native/repeated/legacy/Rust/CT populations.
Existing CT0/path-space pinned hook limitations disclosed, not silently skipped.
Test raw authority-only loss with held context sockets and independent lease;
one unexpected raw byte (even partial frame) must retire authority.4097 native
contexts and33 authority cycles must reclaim exact DOWN state and still evaluate.

## Workflow, evidence and preservation

Scoped collaboration-framework2.8.0 Autonomous Mode, Expedited, dedicated source
branch; actual CC implements and CDC /root independently reviews. Independent
review required for substantive changes; five executed correction passes max.
CDC owns parent updates and closing retrospective. Preserve issued prompts; new
assignments use cc-prompt-iterationNN.md, never overwrite. No synthetic role or
self-acceptance. Native architectural direction is Operator-approved; material
new design/scope ambiguity pauses affected work, not unrelated authorized work.
No push/merge/publish, UX or later arc. Source and planning commits separate exact
allowlists; both Codex and Billo AI co-author trailers required. Do not touch
xrepl docs/design/ or standalone cayrn-lfe. Artifacts under this slice artifacts/;
first-class closing/review/retrospective records stay beside this plan.

Before dependent edits load manifest completely, recover truncated output, run
required-data queries and record actual read ranges/source state plus concise
contract readback in artifacts/execution.md. Missing/conflicting required inputs
block affected work. Hashes alone are not reading or comprehension. Return all8
row dispositions, exact source candidate/hashes/patch, commands/exits/populations
including failed/filtered/unrun, full artifact inventory, scope diff and bubble-up.
No closing/review records until actual work/review exists.

## Readiness and assignment history

Source-grounded role/startup/test helper inventory and full shared contract are
prepared. Native2 hold resolves only with actual C04 accepted handoff; author
readiness is rechecked then. Current assignment: none; no cc-prompt.md issued.
No guessed upstream candidate pin. Size-safe previews/output stay Slice03; Cayrn
full composition is renumbered Slice05, preserving former roadmap obligations.

## Native implementation mechanics — draft refinement

artifacts/native-adapter-recipe.md adds file/symbol/test guidance and source API
checks. It preserves the issued common contract; the private native registry
admit call additionally receives a live context port so authority retirement
can wake a blocked context send without waiting for its mailbox. Required
suspended-context/EOF/held-credit test distinguishes that shutdown behavior;
general ordinary output pressure remains Slice03. Actual C04 candidate is still
required before issuing the native CC assignment.

2026-10-19 native recipe correction before issue: NR-01 found that OTP's
false-linger backend can synchronously wait on pending output. Authority-loss
retirement selects abortive linger {true,0} then close, with caught port_close for
already-closed/error fallback; normal Close keeps its barrier/drain semantics.
Add a positively observed pending-output queue control alongside mailbox-suspend
proof. Shared C04 wire/loss policy remains immutable; this is a native shutdown
mechanic, not general X03 output-pressure completion. Fresh independent recipe
review required before X02 issuance.

## NR-02 placement —2026-10-19

Independent recipe review found a serious pre-existing native2 teardown gap:
while context is blocked in socket send, supervisor shutdown may kill it before
terminate and strand its unlinked foreground root. Native3 registry failure adds
a trigger, not a different underlying ownership defect. X02's abortive authority-
loss path remains required and independently tested; this finding does not waive
that path. CDC retains NR-02 under X03 ordinary-output-pressure/root-teardown work,
with XA02-05/06 and Cayrn C05 as blocking composition owners. X02 is not broad
teardown readiness under blocked sends; no collector/evaluator fix is smuggled
into its exact15-path scope. NR-02 remains serious/open, not done or no-op.

Rationale: X03 already owns the blocking pressure path. A temporary collector
cleanup workaround would also need to account for supported MFA formatting that
can block that collector; a complete ownership/flow design belongs with that
slice. Before composition acceptance, require listener failure, registry failure
and application stop under positively observed pending output, exact owned root/
context/collector termination, trace disposition and no false barrier; include
paused-root startup handoff ownership. Source/OTP evidence and a feasible narrow
alternative are preserved in artifacts/native-recipe-design-review.md NR-02.
No Operator gate, arc scope or acceptance criterion is weakened by this placement.
