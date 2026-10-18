# Demonstrator and four-runtime fit plan

Date: 2026-10-18. Status: proposed implementation plan, no code or tests executed.
Consumes [the architecture draft](03-architecture-draft.md). This specifies a
bounded proof of the core contract; detailed Oxur/xrepl migrations and
Lykn/Fennel implementation plans remain later work, as requested.

## 1. Four runtime integration shapes

| Target | Reuse / current seam | Rust responsibility | Thin native responsibility | Key unresolved point |
| --- | --- | --- | --- | --- |
| Oxur | Rust compiler/eval context, Reedline, subprocess executor | Shared host/core/client; compiler-session adapter, worker ownership and capture | No foreign-language layer is inherently needed | Persistent state across interpreted/compiled tiers and truthful cancellation scope |
| LFE/xrepl | Opaque shell state, OTP session/evaluator processes | Journal/admission/replay/client plus native bridge | Preserve LFE compiler/env semantics; process monitoring, I/O server/group leader, native cancellation/term access | Preserve live BEAM integration without duplicating durable policy or killing shared peers |
| Lykn | Active release's Rust compile pipeline emits JS; CLI runs Deno | Persistent compiler context, shared session host and JS runtime adapter | Minimal JS evaluation/I/O/async-context bridge if required | Persistent lexical/module/macros state and JS context; choose supported runtime API |
| Fennel | Fennel compiler and configurable REPL on Lua | Shared host/client, Lua host integration, protocol and capture path | Minimal persistent Fennel REPL bridge and native hooks | Preserve compiler scope/macros/locals; capture stdio beyond value callbacks; native-call interrupt limitations |

Oxur's clone method is not a universal live-state snapshot. xrepl shell snapshots
are not full BEAM checkpoints. Lykn's one-shot compilation pipeline is not yet a
persistent compiler session. Fennel callbacks alone do not capture all evaluated
I/O. Each boundary needs an eventual targeted integration test, not a shared
claim that serializing a map reconstructs a runtime.

## 2. Shared scenarios, checked against all four architectures

These are design walkthroughs, not runtime observations. References to surviving
state always mean the actual session execution context survives.

| ID / scenario | Oxur | LFE / BEAM | Lykn / JS | Fennel / Lua |
| --- | --- | --- | --- | --- |
| S01: terminal defines state, disconnects; editor reads it | Host retains eval/compiler context and worker independently of terminal | Session/evaluator processes remain in OTP app | Rust compiler context AND same JS context remain alive | Same Lua VM plus Fennel REPL compilation context remain alive |
| S02: two clients submit state mutations together | One Rust authority admits in order across all eval tiers | Bridge sends one admitted operation at a time, with caller/operation correlation | One admitted pipeline controls compile and execution; JS background effects remain concurrent | One admitted pipeline controls compile/eval; Lua coroutines/native work obey declared capability |
| S03: reconnect while new output arrives | Journal follow loop covers both old/new events | Native I/O reaches same journal; no BEAM mailbox history mistaken for durable transcript | Timers/promises emit into same captured stream | Lua/host callbacks emit into same captured stream |
| S04: acceptance reply lost; client resends same ID | Request registry returns original operation | Protocol bridge must preserve shared operation identity | JS execution is not repeated by transport retry | Lua execution is not repeated by transport retry |
| S05: user code never yields; cancel arrives | Control path stays responsive; compiled/native work may require owned worker termination | Evaluator-process stop can lose its state; native/NIF blocking and shared resources need separate limits | Busy JS cannot depend on callbacks in the same blocked loop; worker/isolate/process control capability must be proved | Lua hook may interrupt Lua code; blocking C call may require dedicated worker kill |
| S06: Rust authority dies, runtime lives | Only a separate worker can survive that failure domain | Existing BEAM may survive; reconcile execution/capture before re-admission | Separate Deno worker may survive; embedded runtime dies with host | External Lua worker may survive; embedded Lua dies with host |
| S07: runtime dies after external effect before result commit | Active op unknown; compiled cache not live state | Dead evaluator/node state cannot be recovered merely from snapshot/history | Dead JS context is state loss even if emitted code remains on disk | Dead VM is state loss even if source/transcript remains |
| S08: storage full during output, then explicit close | Rust owner pauses admissions/capture and reports close blocked until durability possible | I/O acknowledgements/backpressure must avoid silently dropping native output | Pipe/hook buffering bounded; pause or terminate owned worker under declared policy | Same bounded capture contract; never block shared host indefinitely without visible fault |
| S09: close with background work and another session active | Drain/stop owned workers; do not destroy shared compiler/executor dependencies | Session-owned processes/I/O quiesce; app-global children are outside ownership; no whole-node kill | Managed tasks/context stop; no fake guarantee that timers in unrelated shared context stopped | Managed callbacks/coroutines/VM policy; shared host cannot be killed to close one session |

All four fit the logical protocol. None yet proves the hardest adapter claims:
continuity after an agent link loss, cancellation under blocking/native code,
producer attribution or a reliable close barrier. Capability declarations must
expose differences rather than let a language adapter weaken the core silently.
No general guarantee of independent application-global runtime state is implied.

## 3. First working increment, when authorized

Build the shared core in Rust with an ordinary scripted client and a deterministic
worker fixture. Two independent clients stand in for terminal and editor. A real
Reedline UI is useful after the core semantics work; headless clients make the
failure oracles inspectable. Use a separate child-process fixture as well as an
in-process fixture to expose different failure domains.

The worker is not a fifth language integration. It is a controlled test endpoint
that can retain a counter, emit attributed output before/after an outcome, wait
for input, block, acknowledge cancellation, die at named barriers and report an
external-effect marker independently of the core's operation journal.

Proposed increments, each integrating behavior and its checks:

1. **Two-client durable session:** create/attach, submit serialized mutations,
   journal admission/results, observe from both clients, detach/reconnect and
   query an operation. Persist request registry and transcript atomically.
2. **Interrupted observation and recovery:** page/follow from independent cursors;
   restart clients/host; test duplicate delivery/submission and uncertain dispatch.
   Enforce exclusive owner before recovery can send execution commands.
3. **Busy lifecycle and resource pressure:** late output, program input ownership,
   cancellation, storage fault handling, close barriers, archive reads/deletion.
4. **Adapter conformance probes, later:** select one real runtime only after the
   core proof. Eventually run common oracles on all four; choose the first runtime
   based on the uncertainty we most need to reduce, not assumed convenience.

Before coding, settle repo home, minimum transport/codec, journal candidate and
resource defaults. Do not implement optional debug/refactor/checkpoint families
or an external broker in order to demonstrate the mandatory behavior.

## 4. Discriminating conformance oracles

Tests are proposed. None has passed or failed in this project yet. Each test must
observe real public command/event and process/storage boundaries, with bounded
waits and neutral fixtures. Sleeps alone do not establish ordering; use explicit
barriers/hooks to place each failure.

| ID | Setup / trigger | Required observable outcome | Wrong implementation rejected |
| --- | --- | --- | --- |
| T01 | Two clients submit many distinct state mutations through one session | Unique admitted order and matching ordered foreground outcomes; independent session can progress | A per-connection queue that races the shared environment |
| T02 | Mutate state, detach last client, reconnect new client and read state | Same generation/live value; complete event replay; worker start count unchanged | Runtime tied to last socket/terminal task |
| T03 | Lose acceptance reply; resend exact ID; then reuse ID with changed source | One admission/execution, original operation returned; changed payload conflicts | Timeout retry performs mutation twice |
| T04 | Append between every history/read/wait boundary; drop/coalesce wakeups | Every committed sequence eventually arrives in order, duplicates deduped | Replay-then-subscribe gap and missed final wakeup |
| T05 | Stop one client; exceed notification and memory thresholds with output | Other client progresses; stopped client recovers full committed stream from disk; memory bounded | Broadcast ring used as transcript or slowest-client global blocking |
| T06 | Crash at pre-admission, post-commit/pre-ack, dispatch-intent/pre-send and post-effect/pre-outcome barriers | No false accepted work before commit; durable accepted work discoverable; uncertain dispatch/effect never auto-runs again | Treating every unfinished record as safe-to-retry code |
| T07 | Restart authority with separate live worker; also try a second authority | No concurrent dispatch; reconcile existing op/generation/capture before resume; uncertain old owner blocks takeover | Lock-free replacement authority executes alongside old one |
| T08 | Kill runtime with buffered output and pending old-generation work | Explicit state loss/uncertain capture boundary; old pending work does not run on fresh state | New generation silently presented as resumed runtime |
| T09 | Foreground outcome then delayed attributed output; close races another submit | Late output retained before barrier; submit either admitted with outcome or rejected; sealed archive has no later session events | Assuming done means all output ended; append after close |
| T10 | Close cooperative worker, then uncooperative dedicated worker, then shared runtime with peer | Graceful drain closes; bounded wait reports incomplete; force policy explicit; peer remains alive | Successful close reported while code still runs, or shared runtime killed |
| T11 | Inject journal write/fsync failure while stdout arrives and while close commits | No false durable ack; halt admission, surface non-durable fault; restore storage and record continuity uncertainty before work | Ignored I/O error or gap event claimed committed on full disk |
| T12 | Prompt to client A; A disconnects; assign B with new epoch; submit old/duplicate replies | Exactly one authorized prompt response; stale replies rejected; secrets absent from replay; no implicit EOF | Both clients feed stdin or password appears in transcript |
| T13 | Close/archive; replay from both clients; delete; resend stale operation/attach IDs | Archive replay only until explicit deletion; old IDs cannot resurrect session; live handles invalidated | Automatic archive eviction, implicit recreate or stale handle reuse |

Negative controls: normal success/error/EOF and a healthy peer session accompany
fault probes. Check source exceptions versus infrastructure errors, Unicode,
multi-value nil/false results, oversized/malformed frames and cursor precision at
binding boundaries. These can be parameterized into the tests above rather than
counted as unrelated test-count targets.

Process-crash injection tests establish process-recovery behavior only. They do
not prove host power-loss durability, physical erasure, remote partition safety
or arbitrary runtime cancellation. Those claims need separate scoped validation.

## 5. Decisions ready now and work held for later

Ready to review: one ordered durable Rust-owned session core; independent event
observation; ID-based operation recovery; explicit uncertainty/generation state;
close barrier and archive separation; thin native evaluation agents.

Next design choices: accept/refine the transcript crash boundary and secret-input
exception; select shared repo/public name and Rust/core packaging; then choose
only the minimum dependencies needed for the demonstrator. A named follow-up
inquiry may be needed for Lykn's persistent JS/compiler API or BEAM bridge shape.

Later migration/implementation plans must map existing commands, sessions,
wire/storage compatibility, public APIs, prompt/history UX and capabilities to
the shared contract, preserve useful source seams and resolve Project09 findings
with real boundary tests. This packet does not allocate those repairs or imply
that changing the protocol automatically fixes them.
