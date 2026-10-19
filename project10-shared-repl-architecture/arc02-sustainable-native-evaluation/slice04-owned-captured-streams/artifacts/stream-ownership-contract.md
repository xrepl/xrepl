# Owned, complete captured output — binding contract v1.0

CDC Sofie /root, 2026-10-19. This is the source-led engineering contract for
xrepl Project10/Arc02/Slice04, within the Operator-authorized Autonomous Mode
endpoint. Baseline is the accepted X03 candidate identified in the slice plan;
Cayrn is 34af63eb9f07a0e019495378045852ad69d00284. Native4 and public RPC1 remain.
Private helper names are local discretion. The ownership, budgets, ordering,
errors, transitions and proof obligations below are binding. Sketch signatures
are implementation recipes, not claimed compiled code. Preserve the reviewed
unissued draft and its findings as history; this consolidated contract supersedes
its provisional and contradictory passages.

## 1. Usable capability and limits

Supported inherited-group-leader writes may exceed a native frame. Capture the
complete valid text in ordered UTF8 chunks, each at most 8192 bytes. An original
I/O request gets `ok` only after every chunk is durably acknowledged by Rust.
Invalid data and local admission exhaustion produce ordinary I/O errors without
losing an otherwise healthy context. An invalid suffix can leave an already
committed prefix; it never yields whole-request success.

Keep the context and each origin collector responsive while network sending,
user formatting or Unicode traversal blocks. Either surviving owner must stop
the known foreground root and formatter workers after a SINGLE owner fails,
even when user code sets trap_exit true. This resolves serious NR-02, including
collector-only kill while the network writer is positively blocked. Arbitrary
user heap, process fanout and mailbox bounds, tracing tamper, remote/global I/O
and simultaneous destruction of both owners are outside the existing contract.
No promise that arbitrary user descendants are killed on close. Their inherited
dead group leader rejects later I/O; trace origin remains immutable while live.

Preserve native3/X02 authority fencing, exact scope/tickets, 64 live origins,
64 physical contexts, 16 authorities and 128 temporary-role budget. Preserve
native4/X03 previews, metadata and saved environments. Do not change wire,
package versions, registry/listen ownership, public Rust policy or terminal UX.

## 2. Source and callers

At source7427d1c, context `send-event/2` is the only evaluated-context socket
writer. Its nine call sites are capture, killed-root Outcome, close timeout,
Ready, origin-capacity Outcome, pre-dispatch cancel Lost, normal publication,
cancel Lost and Closed. Route ALL through a dedicated writer. Authority
`activate/2` has a separate single bounded AuthorityReady send; it stays unchanged
because it runs no evaluated root or unbounded output stream.

Context `evaluate/3` currently creates a root before starting capture and calls
`cayrn_lfe_io:start/3 -> {ok,Io,Trace}` synchronously. Replace the ownership and
startup flow described below. All production start callers are here; direct
collector tests in io_tests and resource_tests must be adapted. Existing
committed/3 caller is context ACK handling; resource callback tests exercise it.
finished/2 comes from evaluated handling; retire/2 from retire_ready after
unlink; seal/2 from normal-close progress. Replace those exact interfaces and
the associated fixtures together; preserve the stronger observable checks.

Recommended new focused modules: `cayrn-lfe-stream` (pure traversal plus owned
formatter loop) and `cayrn_lfe_writer` (network-only loop). No export_all,
production debug hooks, test-only accessors or budget knobs. Keep existing OTP
supervision/app/listener/registry unchanged; context owns its helper processes.
Extend companion test discovery, rather than relying on accidental test beams.

Recommended concrete private API map (same behavior required for equivalent names):
- io:start/3 above replaces old pid argument/trace return at context evaluate and
  direct io/resource tests. io:activate/3(Io,Owner,OriginRef) handles context's
  registered-origin self-message; Owner must equal self in the API wrapper.
- io:admit/4(Io,Owner,JobRef,Decision), Decision=grant|{error,Reason}, answers exact
  context admission without user payload. io:activate_formatter/4(Io,Owner,Job,Pid)
  releases an exactly registered formatter. Both validate stored Owner in receiver.
- io:committed/4(Io,Job,Worker,Index) replaces committed/3; it embeds caller self
  and validates exact pending chunk. Update context dual confirmation and every
  direct callback fixture together. io:finished/2, retire/2 and seal/2 remain named
  async owner APIs with stronger predicates. New io:stop_sealed/2 is forced-close
  grant after seal confirmation, distinct from natural retire's producers0 proof.
- cayrn-lfe-stream:start/4(Collector,Job,Encoding,Payload) returns a linked paused
  PID. Payload is {chars,Chars}|{mfa,Module,Function,Args}; only after the registered
  activation grant does worker apply/convert. It sends stream_chunk(Worker,Job,
  Index,Text), waits exact stream_continue(Collector,Job,Index), then stream_done
  (Worker,Job,ok|{error,badarg}). Collector monitors/validates all events. No pure
  internal test accessor; exercise through worker/collector or actual native wire.
- writer:start/1 and enqueue/4 are defined below, with exact owner/ref validation.
These are private native interfaces only. Add specs/docs, migrate all rg-discovered
callers and expected-state fixtures; alternative private spelling does not relax
source effect, metadata or lifetime rules. No compatibility promise for direct
internal callbacks, but all prior behavioral negative controls remain meaningful.

## 3. Resource ownership and publication before activation

Two responsive owners remain: context and collector. Add one nontrapping writer
per context and bounded disposable formatters for admitted I/O. Owners perform
NO gen_tcp:send, arbitrary apply, whole-data Unicode conversion or synchronous
call to each other in callbacks. Small bounded metadata/trace operations remain.

Recommended `io:start(Owner,Operation,EvalFun0) -> {ok,Io,OriginRef}` creates a
fresh reference in the wrapper, then passes it to init. No trace getter call.
Collector init first sets trap_exit once and monitors the exact Owner. It creates
a linked paused root itself, creates/configures the trace, seeds root as born,
sets inherited group leader and tracing BEFORE activation. A nested acquisition
guard kills the acquired root and explicitly destroys any acquired trace when
construction fails. No user code before both owners register it.

Init sends `{origin_ready,Io,OriginRef,Root,Trace}` and returns. Context has
already stored provisional `{operation,OriginRef,IoMonitor,phase=starting}` when
it later handles ready. It validates the exact io/ref, stores root PID/monitor,
trace and root-result/down flags in the origin record, and posts self-message
`{activate_origin,Io,OriginRef}`. Only its handler in this published state grants
activation to the collector. Collector checks owner/ref and releases paused root.
No callback can activate source while its returned state still lacks ownership.
Before registration a root is paused, nontrapping and linked to collector; after
activation both owners possess its identity independently.

Context retains each origin's root PID/monitor and result-seen/down disposition
UNTIL exact collector physical DOWN, not just in the current active tuple.
Root evaluation sends its result before it exits. Normal root DOWN after a
recorded result is allowed; unexpected normal/abnormal DOWN without result is
loss unless the current destructive stop expects it. Root monitor is NOT a
trace drain witness. The collector still requires exit plus trace:delivered and
root-accounted. On single collector loss the responsive context kills ALL known
origin roots and registered formatters first, then destroys owned traces and
loses the context. On context loss the responsive collector kills root and all
workers first, then destroys its trace. Use exit(Pid,kill), not a trappable signal.

Collector retains exact owner monitor THROUGH natural/forced unlink and until
its own physical stop. Owner DOWN must clean up even in the unlink-to-retire-grant
gap. Parent link also remains until normal retirement. On normal terminate,
demonitor with flush; no fake DOWN can authorize cleanup or return credit.
Context terminate kills known roots/workers first, then signals responsive
collectors to shut down and destroys known traces as fallback, and kills writer.
Do not brutally kill collectors first and skip their worker cleanup. No shutdown
call cycles or waits inside owner callbacks.

Handle expected linked EXIT and monitored DOWN separately: normal root/formatter
EXIT in collector must not fault before its completion/DOWN state is reconciled;
normal terminal writer EXIT in context must not be treated as generic io_lost.
Validate exact known PID/ref before any credit return. Unexpected writer/root/
formatter/collector failures lose the context; arbitrary unknown DOWN cannot
release a resource. Existing generic EXIT-to-loss is replaced by role-specific
handlers plus an honest unknown-failure path. A link exit is never the physical
monitor or trace-delivery proof.

## 4. Context foreground and publication state

Recommended states are idle, starting(Op,Io,Ref), executing(Op,Io),
finishing(Op,Io,Phase,Text,Preview), publishing(Op,WriterRef); retain separate
origin root records. No unbounded foreground queue. `last-token` advances once
when a validated Dispatch is admitted, including deferred or capacity rejection.

Normal evaluated result updates the committed environment, marks root result-seen,
and tells collector finished. Quiet origins wait their exact normal physical
collector DOWN before publication; live background producers allow foreground_ready
publication while keeping the origin. Preserve existing trace-based decisions.
Outcome enqueue enters publishing and does NOT immediately become idle.

While publishing accept ONE correctly scoped/token-valid Dispatch in a bounded
`deferred={operation,source}` slot. Consume its token once, but create/evaluate
nothing yet. Keep TCP active-once rearmed so ACK/Close/Cancel remain responsive.
A second deferred Dispatch is invalid pipeline and loses that invalid context.
The actual Rust serial host cannot require two because it waits each Outcome.
On exact writer_sent for the publishing Outcome, clear publishing, and if not
closing activate the prepared deferred operation WITHOUT token revalidation
against its already advanced high-water. Check origin64 capacity at activation;
if full return ordinary Failed with explicit false preview and no source effect.
That Outcome also enters publishing. Never allocate a root on a rejected request.

Close removes an exact deferred request, emits Cancelled(false) explaining source
was not evaluated, and cannot later activate it. Exact Cancel of deferred does
the same then uses existing destructive context retirement. Cancel of the
already computed/publishing operation is completion-wins/no-op. While starting
or executing, exact active Cancel kills its root; future other cancel is no-op
as existing behavior. While finishing/publishing WITHOUT deferred, matching,
stale or future-other cancel remains no-op. While truly idle and not closing,
future cancel retains existing pre-dispatch Lost retirement. No stronger queued-
cancel promise is invented. Close during starting cancels activation and kills
the paused root; a later ready/self-activation cannot run it. Record the exact
cancel-before-evaluation diagnostic separately from a confirmed root kill.

## 5. Dedicated writer and durable chunk acknowledgements

Recommended `writer:start(Socket) -> Pid` spawns linked network-only worker;
it captures owner PID, never traps exits and never runs user code. Context
monitors it, retains socket controlling_process and registry port ownership.
`enqueue(Writer,Ref,Event,TerminalBool)` sends exact owner/ref job; writer validates
owner and executes FIFO json encode + gen_tcp:send. Successful actual send emits
`{writer_sent,Writer,Ref}`; failure exits without success. Terminal job sends its
completion then exits normal. Context death/terminate stops this nontrapping
worker even if gen_tcp:send is blocked.

Context bounds outstanding frames to Output64 + Outcome2 + Ready1 + terminal1
=68. Track only current exact writer refs, no operation/frame history. Output
has at most one chunk per admitted formatting job. Outcome2 is justified by
publishing plus the single canceled deferred request, NOT by cross-sender
scheduling assumptions. Invalid excess pipeline is loss, never silent shedding.

Before enqueueing Output allocate the next global canonical string position
and store pending `{io,job,worker,chunk,writerRef,sent=false,acked=false}`.
ACK and writer_sent come from different senders and can arrive in either order.
Mark independent bits; ONLY both exact confirmations remove pending and notify
collector. Unknown/duplicate/mismatched ACK or completion faults; no forged
credit. Writer_sent alone is not durable, ACK alone does not invent send proof.
Only after that dual confirmation may collector let the worker advance.
Operation token is the immutable origin, never the current foreground operation.

Normal terminal completion requires BOTH exact writer_sent and normal monitor
DOWN, either order, before context stops and registry can return physical credit.
Handle normal linked EXIT while waiting. Context failure may abort immediately;
normal Closed must not be enqueued then killed before it was sent.

## 6. Job admission, formatter registration and physical credits

Increment collector observed for EVERY io_request, INCLUDING unsupported,
over-capacity and post-seal rejections; otherwise traced sent and observed can
never reconcile. Validate supported put_chars constructor without applying it.
Unsupported requests get enotsup, sealed requests get terminated, no worker.
Unsealed local proposals keyed `(From,ReplyRef)` cap at64 per collector; excess
returns ordinary enobufs. Retain opaque payload only locally, send context only
`{admit_io,Io,OriginRef,JobRef}`. Duplicate pending keys are invariant faults.

Context admits at most64 formatting jobs across all64 origins. A credit spans
admission, paused registration, formatting, pending chunk, completion and exact
physical worker DOWN. Grant only an exact live origin/job reference; exhausted
capacity returns ordinary enobufs without losing context or creating a worker.
No worker before grant, no early credit on logical completion or collector seal.

On grant collector creates linked paused worker, stores its PID/monitor, manually
seeds born and enables inherited procs/send/set_on_spawn tracing because collector
itself is not traced. Set worker group leader to collector. Send exact
`formatter_ready(Io,Job,Worker)` to context; context stores/monitors Worker, then
activates it through collector. Before that grant it cannot run MFA or conversion.
After activation both owners know its PID and can kill it despite trap_exit.
Drop collector's opaque payload after the worker owns it. Worker request source
and user children remain traced under this immutable origin.

Use concurrent formatters up to global64, NOT one serial formatter per origin:
a formatter MFA may perform nested supported I/O and wait on the same collector.
Nested work must have an independent admission slot; at saturation return
ordinary enobufs, not deadlock. No per-request atomicity between different writers;
per-job chunks are ordered and host journal gives the overall event order.

Worker emits one copied bounded chunk then waits its exact commit grant before
next chunk. Collector validates job/PID/chunk index, forwards capture metadata to
context. Context positions/enqueues, reconciles dual send+ACK, collector validates
and releases worker. On completion worker sends `{done,Job,Status}` then exits.
Collector waits BOTH done and exact normal worker DOWN before replying to original
request and notifying context job_done. Context waits BOTH collector job_done and
its own exact worker DOWN before returning credit; handle either sender order.
Unexpected death or normal DOWN without done is loss, never fake ordinary success.
Only a fully committed request gets ok. Error after prefix gets badarg with that
prefix retained. Empty valid write emits one empty Output and awaits ACK; invalid
data before any valid bytes emits no fake empty success event.

Catch arbitrary MFA exceptions ONLY around apply (old ordinary badarg boundary).
Catch Unicode converter's expected badarg only. Do not translate internal owner/
state machine bugs or unrelated failures into ordinary successful/benign results.
No new input, request-batch or getopts surface; preserve supported constructors.

## 7. Complete incremental conversion

Support actual unicode:encoding(): latin1, unicode/utf8, utf16 and {utf16,big|little},
utf32 and {utf32,big|little}; invalid encoding is badarg. Integers are codepoints
for every encoding, with latin1 at most255. Preserve binary fragments as binaries,
never convert byte slices to byte integers (that changes mixed encoding semantics).

Recommended explicit-stack walker distinguishes root, list-tail and element.
Root/tail permit nil, cons and binary only; integer is allowed ONLY as an element.
Thus root integer and improper integer tail are badarg, binary tail is valid,
non-byte bitstring invalid. Push cons head as element and tail as list-tail.
Gather at most1024 source units per prefix (binary byte counts1, integer codepoint
counts1), without full input scan/flatten/length. Deep empty lists can take work
inside worker; no absolute heap/depth guarantee for arbitrary user chardata.

Convert `[Carry,Prefix]` with unicode:characters_to_binary(...,Encoding,utf8).
Carry is an incomplete fragment of one encoded character, at most3 bytes for
these encodings, carried across consecutive binaries/nested lists. Integers after
an incomplete binary follow actual OTP validation, not guessed concatenation.
For complete binary Good or {incomplete,Good,Rest}, UTF8 Good is bounded by
4*1024+4=4100 bytes; copy it into owned bounded chunk, await ACK, then traverse
next prefix. Never split a UTF8 codepoint. Empty prefixes with carry continue
without fake empty event. At EOF with carry report badarg.

For {error,Good,Rest}, emit any valid nonempty Good prefix through durable ACK,
THEN return badarg. The same applies to a later invalid structural tail after
prior valid chunks: preserve committed prefix, no whole-write ok. No normalization,
preview truncation/metadata, original-size estimate or fullbinary conversion.
Bounded chunk copies prevent context/collector pending state retaining a huge
parent binary. Worker may retain its remaining original input until traversal.

## 8. Drain, seal, cancellation and shutdown

Natural drain retains original finished + root-accounted + producers0 +
deliveries0 + sent==observed + jobs0/pending0 proof. Foreground_ready retains
root exit/delivered and background-producer distinction. No mailbox-empty/timer
substitute. Collector retirement is two phase: ready proof, context unlink/grant,
normal collector DOWN; owner monitor covers that unlink gap.

Normal Close starts existing5second timeout, stops foreground activation and
kills an executing/paused root as before. Completion-wins finishing/publishing
Outcome still publishes. Seal forbids ALL newly received I/O, including nested
requests from pre-seal MFA; each gets terminated and observed++. Already admitted
pre-seal jobs may finish/error and emit remaining chunks. A callback may propagate
nested failure or deliberately ignore it and return its own valid text; request
success claims only its own returned text. A blocked/infinite callback may time
out Lost, never falsely Closed.

Seal confirmation waits root exit plus delivered/accounted, jobs/formatters0,
pending chunks0 and sent==observed. It does NOT require arbitrary user descendants
dead. Keep honest accounting of requests racing trace sends; no premature success
based on one queue observation. After confirmation context unlinks/grants forced
collector stop (distinct from natural drain), retains entry until exact normal
physical DOWN. Collector explicitly destroys trace before stop. Context final
close predicate includes origins0, jobs0, pending0 and foreground disposition,
then sends terminal Closed and waits writer_sent+normal writer DOWN. Closed is sent only after owned roots, formatters and collectors have died;
orderly context stop and physical context-credit return additionally await
terminal send plus writer DOWN. The terminal writer necessarily sends Closed
while itself still alive, then exits; no contrary remote-observation claim.

Destructive Cancel kills exact active root, waits confirmed DOWN for Cancelled
when healthy, then Lost. Under broken/backpressured wire that Outcome may be
undelivered; Rust Unknown/StateLost is honest. Request receipt is not completion.
No ordinary I/O success for aborted work. Existing5second timeout FORCE-STOPS:
best-effort Lost enqueue, but no second indefinite terminal flush; context kills
writer and resources. EOF is honest StateLost if Lost cannot be written.
Administrative listener/registry/app/authority failure retains current scope;
responsive context or collector must prevent root/formatter leaks even when
supervisor escalation bypasses terminate. No false Closed on any such path.

## 9. Discriminating tests and retained behavior

Preserve all56 unique native X03 methods and their meaningful ACK/authority/
retirement/EOF predicates, explicitly adapting changed private interfaces and
stronger seal ordering. Do not relabel historical native3 proof as native4.
Add focused stream and ownership suites wired through io_tests companion list.

- Large Unicode binary/list/mixed chardata and latin1, UTF16/32 split sequences:
  concatenate emitted text exactly, chunk<=8192 validUTF8, every ACK held until
  inspected; original io_reply absent until final ACK. Invalid root/tail/bitstring,
  invalid encoding, invalid suffix and EOF carry: correct badarg, committed prefix
  retained, no false ok. Empty write one acknowledged empty frame. MFA exception,
  nested MFA I/O and ordinary capacity refusal recover on the same context.
- Global64 admitted jobs across origins; 65th ordinary enobufs, credit returns
  only exact worker DOWN+job_done, then recovery. Real wire plus actual handler
  inversion tests cover sent/ACK, done/DOWN and terminal sent/DOWN. Unknown/forged
  completion cannot release credit. One outstanding chunk/job and bounded frames.
- Publishing/deferred Dispatch/Close/Cancel permutations, exact single token
  consumption, capacity at activation, no canceled deferred source file effect,
  no third pipeline acceptance. Actual handler permutations supplement wire tests
  where cross-sender arrival cannot be forced by a wire peer alone.
- Startup gates use test-owned peer sys:install arity3 callback on `{in,Msg}`
  origin_ready before registration and activate_origin after registration before
  grant. Extra argument is SERVER NAME, not state. Stage messages go to an owned
  PEER test controller; inspect via peer:call. Hold paused root, marker absent,
  kill context/collector, assert exact DOWN and no marker. No product hook.
- Owned-wrapper unlink-gap test unlinks collector then kills owner WITHOUT stop
  grant. Retain external trace handle; assert collector/root DOWN and explicit
  trace destruction. A link-only implementation must fail this specimen.
- Root and an active MFA formatter set trap_exit true. Keep a trapped formatter
  in one slot; concurrent writers in other63 fill network. Set small native
  sndbuf/peer recbuf, REQUIRE positive inet:getstat(Socket,[send_pend]) before
  faults. Collector-only kill must end both registered root+formatter even while
  writer remains blocked. Context-only kill must invoke collector's independent
  ownership cleanup. Listener kill, registry kill and app stop under the same
  positive pressure require exact context/root/collector/formatter/writer DOWN,
  explicit trace disposition and no false Closed. Do not read/drain client or
  release user blockers to make cleanup pass. Peer isolation respects existing
  native fault domain. One held4KB job may fit OS buffers: use concurrent jobs
  and positive pressure, never a sleep or presumed socket capacity.
- Normal Close after positive pressure may resume ACKs and must deliver all
  admitted pre-seal chunks or explicit ordinary errors, then physical cleanup
  and Closed. Withhold forever: bounded Lost/EOF, never Closed. Post-seal nested
  rejection must reconcile traced sent/observed in both arrival orders, no false
  loss from the old sealed branch's missing observed increment.

Use existing actual peer/socket/authority helpers, owned private directories,
bounded observations and cleanup. Complete source review covers acquisition
failure guards; inaccessible OS allocation fault injection is explicitly unrun,
not pretend-tested. No helper export solely for tests. No benchmark/inquiry.

Full gates: component make check, root make test-lfe build-agent check-agent build
lint-rust test-rust, fresh source-only component make check, root launcher from
/private/tmp with spaced socket/native4 scope echo/42/false preview/native-only
applications/Closed/owned process0. Matching Cayrn make check lint-integration
 test-xrepl with overrides unset must actually execute all14 native+3 consumer
cases. Preserve raw commands, failures, ignored/filtered/unrun counts, test method
population versus repeats and CT0. X-TOOL-01 requires exact ignored shadow inventory
and current test precompile before root, plus independent fresh-source gate;
permanent tooling fix stays Arc06. X-PKG-01 spaced checkout is different from
required spaced socket; no build configuration expansion here.

C06 still owns sustained mixed/churn/size/two-observer/spool/storage composition.
X04 acceptance does not close either arc, full migration, package, UX, historical
Project01/09 independent/Operator gates or authorize publication.

## 10. Applied language and OTP guidance

Interim LFE guide sections4–6: focused hyphenated pure stream module, underscored
OTP modules matching current tree; explicit exported API/spec/doc, small pattern
heads, no export_all/debug API. Existing context map may remain to limit change;
collector/job records or consistent maps are local representation discretion,
not a reason to leak private state through production API.

Erlang PC-02/03 SHOULD one role and one process module: separate network writer
and formatter from the two lifetime owners, keep each message loop together.
PC-07 SHOULD linked/monitored spawn and PC-10 SHOULD unique correlation refs:
paused linked workers, independent owner monitors and exact physical credits.
PC-14 CONSIDER cross-sender ordering and PC-15 CONSIDER copy cost: independent
sent/ACK and done/DOWN bits; opaque input stays local, bounded chunk handoffs.
BEH-03 SHOULD encapsulated APIs, BEH-05 MUST fast callbacks and BEH-06 CONSIDER
call cycles: use focused named async APIs with explicit response/credit state,
not mutual blocking calls. BEH-04 SHOULD call for backpressure is contextual:
the owners cannot block on each other; this explicit bounded asynchronous job/ACK
protocol supplies backpressure while disposable workers wait. BEH-08 SHOULD
named state: collector/job records or consistent existing context maps have
explicit fields, replacing fragile positional foreground state as appropriate.
BEH-09 SHOULD light init and BEH-10 SHOULD best-effort terminate: establish only
bounded construction guarantees before return and retain surviving-owner cleanup
when terminate is skipped. SUP-04/05/06/07 SHOULD match restart/failure/shutdown
policy; SUP-09 MUST linked supervised startup: preserve app tree and temporary
contexts, do not restart user evaluation, exercise escalation beyond shutdown.
SUP-11/12/13/14 SHOULD app boundary/dependencies/configuration stay intact; no
new dependency or test-only config budget. AP-05 AVOID blocking callbacks is
central; AP-06 AVOID broad exception swallowing preserves invariant failures.
DT-10/11 SHOULD binary/iodata, DT-12/FP-11 SHOULD bounded binary traversal,
PF-07 SHOULD copied small chunks, PF-08 CONSIDER tail recursion, PF-09 SHOULD
avoid length scans: explicit incremental stack, no whole flatten/convert, UTF8
bound before handoff. These are contextual applications, not promotion of every
recommendation to MUST. Native Rust ownership/durability remains unchanged;
actual integration is the proof at that boundary.
