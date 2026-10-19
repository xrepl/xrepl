# Slice01 — fenced capture lifetimes

Version1.0, 2026-10-18. Prepared, dependency-held, not executed. xrepl Project10 /
Arc02 sustainable native evaluation. Sourcef261152fc150a1addf3286a97b6a1a0324a42869
on release/0.2.x. Cayrn 722d086 is the current baseline, **not** a native v2 result.
Cayrn Arc01/Slice03 must return its actual tested native v2 implementation before
this consumer starts. No assumed future hash; revalidate the entire changed input.

## Useful result and source of truth

A real LFE session performs more than 256 evaluations while keeping a long-lived
writer's origin intact and reclaiming quiescent collectors. Native duplicate
protection becomes a scalar token high-water mark, with 64 live capture origins
and recoverable non-evaluation failures under pressure. Full native/client checks
then prove the immediately preceding Rust contract against the thin BEAM agent.
Rust remains the durable admission/journal authority. Native lifecycle bookkeeping
is runtime-specific; it is not a new LFE session host or durable operation registry.

The single paired design is at /Users/oubiwann/lab/oxur/cayrn/.worktrees/planning/project02-core-hardening/arc01-native-session-hardening/slice03-journal-backed-native-identities/artifacts/native-resource-contract.md. Read it fully, especially§§5–9.
This is a worked proposed design awaiting activation, not proof the algorithm has
run. Its wire/ordering/capacity/capture boundary is a design decision, not a menu
for the implementation pass. If evidence contradicts it, stop affected work and
return to design; no timeout or heuristic retirement fallback.

## Required upstream handoff

Read actual Cayrn Slice03 closing report and candidate/commit, protocol agent
OperationToken/VERSION/commands, private journal lookup/output and active-slot
implementation, and actual non-language1024/error/rollback results. Check all
baseline Cayrn file drift against that return's reviewed allowlist/candidate.
Its real native gate is deliberately held for this slice, not claimed already
passed. This bounded input is enough; whole Cayrn project/arc closure is not a
prerequisite. Record actual pins and any adaptation before native source edits.

## Implementation recipe

1. context.lfe handshake: require native v2, keep exact generation/authority checks.
   Replace seen map/256 guard with last-token integer. Validate canonical binary
   token1..i64::MAX and accept strictly greater sparse tokens. Advance it even on
   origin-capacity refusal, before any source could run. Invalid/replayed frames
   close only that context. Raw public operation IDs are not native identities.
2. Replace ios lifetime list with owned origin map (collector PID/token/trace
   handle). Limit it to64. Full capacity returns the specified Failed preview
   with unchanged env and no evaluator/collector; not runtime loss. Source is
   not executed, and duplicate dispatch is still fenced. No automatic retries.
3. Spawn a monitored paused evaluator before collector setup. Convert io.lfe to
   gen_server and start(Owner,Token,RootPid)->{ok,Pid,TraceHandle}; setup isolated
   tracing before setting group leader and sending evaluate. Seed root producer,
   use procs/set_on_spawn plus filtered I/O-request sends, per-process delivery
   confirmations and orphan exit-before-birth records as contract§6. Use a static
   session-name atom, explicit specs/docs/exports; no dynamic atoms/process dict.
   New IO state uses a record; context keeps its established maps. Internal OTP/
   wire/record names retain required spelling; private helpers use hyphens.
4. Track actual I/O request count, traced request count, pending(From,Ref) and
   root outcome. ACK routing includes collector identity and returns the caller's
   io_reply only after context receives durable Rust ACK. A send witness may be
   delayed relative to the message; retirement needs both counts equal after
   all producer delivery barriers, not an empty mailbox or root death alone.
5. Natural retire-ready/grant: validate ownership and empty pending at context,
   unlink then mark Retiring/grant, retain credit until the exact normal monitor
   DOWN confirms physical cleanup. Quiet foreground results wait for that credit;
   roots with descendants publish after root accounting, without awaiting their
   background work. Keep all context handling asynchronous. Cancel on a computed
   finishing result is completion-wins; close publishes it before forced seal,
   then waits retiring DOWNs and live seal/capture confirmations. Preserve
   unexpected EXIT/DOWN quarantine; teardown destroys owned trace handles. No
   permanent retired-PID set or per-operation tombstone collection.
6. Adapt two original I/O tests to the new start/3/private API and add resource
   tests in cayrn_lfe_resource_tests.lfe, included explicitly in the existing
   native_agent_companions_test_ generator. Keep evaluator/startup tests intact;
   root EUnit duplicate executions are not new unique coverage. Use fresh owned
   OTP peers, known ContextPid sys:get_state and trace:session_info for assertions,
   not new product debug endpoints or inspection of user nodes.
7. Run all matching Cayrn native/consumer scenarios, including its new sustained
   case. Native app/startup/metadata/deps/launchers and public terminal behavior
   remain unchanged; document native v2 and old-pair compatibility. Update native
   README/AGENTS and root README for new live-origin budget, supported local
   descendant capture and residual node/size limits. UX remains separate.

## Verification and oracles

Native unit/API fixtures:512 quiet dispatches with sparse tokens, env preserved,
collectors and trace sessions reclaimed; old frame replay cannot perform a side
effect;0/noncanonical/overflow/stale tokens rejected. Hold64 producer origins,
65th attempted source must not set a binding or create a collector; environment
stays live, out-of-band test-owned release restores capacity, and a new ID/token
can evaluate. Full-capacity close still works. Busy peer remains responsive.

Use the real lifecycle handlers for deterministic child-exit-before-parent-spawn
and I/O-send-trace-before/after-receive inversions; pair those focused private
state tests with real spawn descendants. Withheld capture ACK prevents retire
and close completion. Inject collector death and retire-ready/close orderings;
no broad ignore of EXIT. Independent trace session remains configured after
agent cleanup; no user node tracing. Test local spawn/link/monitor/opt forms and
an asynchronous io_request sender that exits before its commit reply.
If trace APIs/order tests cannot support the prescribed proof, keep open; resolve
with Operator before redesign or a separately budgeted tracing investigation.

From xrepl: make build-agent check-agent; make compile-lfe build lint-rust
 test-rust test-unit-lfe test-ct-lfe. From Cayrn matching C03 source:
make check lint-integration test-xrepl (no native/checkout overrides), then native
sustained filter with --nocapture if needed for failure diagnosis. Every existing
14 real case and new cases must run against integrated native v2, not predecessor.
Record exact actual populations, repeats/filtered/unrun. Baseline unique native7,
Rust 7+1, legacy175 and CT0 remain context, not fixed expected new counts.
Fresh source-only component copy must build/test (no inherited .beam/_build),
and root wrapper must start only native apps from /private/tmp with spaced socket.

## Scope and later owners

- `apps/cayrn_lfe/src/cayrn_lfe_context.lfe`
- `apps/cayrn_lfe/src/cayrn_lfe_io.lfe`
- `apps/cayrn_lfe/test/cayrn_lfe_io_tests.lfe`
- `apps/cayrn_lfe/test/cayrn_lfe_resource_tests.lfe`
- `apps/cayrn_lfe/README.md`
- `apps/cayrn_lfe/AGENTS.md`
- `README.md`

Only these seven native/docs paths may change. No evaluator/legacy source,
manifest/lock/license/app version/build/launcher/Rust terminal/Cayrn source edits.
Cayrn already ships the shared connector and new real fixture; if its contract
needs a correction, return there with a new assignment rather than silently
changing it from xrepl. No new dependency or global tracing facility.

4096 node-lifetime context tombstones remain explicit for Arc02/Slice02; they
must not be dropped/evicted to fabricate sustainable churn. Large preview
assertion/chunked output/ordinary capture-pressure handling remain Arc02/Slice03.
Later Cayrn composition consumes all three. Current slice removes the **per-
session operation** cliff, not all node lifetime/resource limits or user-code
resource exhaustion. No old heap restoration or full Project09 acceptance claim.

## Readiness and assignment history

Reviewed current context/IO/listener/supervisor/evaluator/native tests and the
paired Rust seam. API names and filtered-send match shape checked against local
kernel10.6.3 trace.erl and official documentation. No trace prototype/experiment
or throughput comparison was run. The birth/exit/send/delivery state machine is
specified and falsifiable; implementation must prove it, not assume the docs
provide a ready-made REPL lifecycle. This is one bounded native context: two
production modules and scoped test/docs changes; one collector role per module,
no extra runtime transport/service. Keep test/review/iteration headroom; if source
reveals a larger change, discuss splitting rather than weakening the drain proof.

| Assignment | Date | Predecessor | State |
| --- | --- | --- | --- |
| cc-prompt.md | 2026-10-18 | none | Prepared; held for actual Cayrn C03 return and activation |

Current assignment is prepared cc-prompt.md. No guessed C03 source pin and no
claim Arc01's pending independent acceptance was closed by commit approval.

## Workflow and execution boundary

Prepared for the Operator-selected **one collaborator, Sofie**. Design,
implementation and a separate self-review are functional passes by that one
contributor. This is the canonical cc-prompt.md assignment name under the existing
ledger convention, not another agent. The current request commits Slice02 and
plans these next slices; it does **not** execute them. New plan commits require
separate approval; no automatic source commit/push/publication. Historical and
parent independent/Operator gates remain pending until actually performed.
No synthetic CDC/CRC verification file or formal parent close.

When activated, keep the exact reviewed source allowlist. If separately authorized
to commit, source/planning are separate explicit path lists; both footers required:
Co-authored-by: Codex <noreply@openai.com>
Co-authored-by: Billo AI <ai-engineering@billo.systems>
Preserve issued prompt bytes/path; refinements use cc-prompt-iterationNN.md beside
it, update assignment history, five-pass cap before discussing re-scope.

## Artifacts and return

Use this slice's artifacts/ for intake, command logs, exact source candidate/
patch and supporting checks. Before dependent edits record actual source/plan
state, required text extents/revisions, required-data commands/results and a
source-cited contract readback in artifacts/execution.md. Hashes do not substitute
for reading. Recover truncated reads; missing/conflicting inputs block affected
work, not unrelated supported progress. Do not create closing/review records
before work. Return closing-report.md with every opening row's disposition,
commands/exits/counts (including filtered, failed, blocked, unrun), candidate identity,
complete artifact inventory, scope-as-specified/delivered and bubble-up to the arc.
Self-check evidence is attested. Never turn a missing native prerequisite into a
green skip or claim physical durability from injected transaction aborts.


## Assignment transition — Autonomous Mode

2026-10-18: initial `cc-prompt.md` preserved, superseded only in execution/
contributor authority by `cc-prompt-iteration01.md` (current, issued to a separate
CC context). Technical contract/rows/allowlists unchanged. No implementation pass
previously executed; correction budget zero of five. CDC /root independently
reviews CC work and owns planning commits/retrospective. Actual CC acknowledgment
and source intake go in artifacts/execution.md.
