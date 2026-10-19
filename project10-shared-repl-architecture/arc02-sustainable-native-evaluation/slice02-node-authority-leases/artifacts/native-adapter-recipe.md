# Native adapter implementation notes — draft,2026-10-18

Author CDC Sofie /root, source7228183. Supporting file/symbol recipe, not a second
wire-policy contract. The canonical native3 authority contract in Cayrn C04 is
binding; actual C04 source/review must be consumed before this native assignment
is issued. No native source implementation has started here.

## Source-grounded changes

- listener:init currently creates cumulative public ETS; remove it. Keep socket
  packet4/frame cap/0600/private endpoint handling. In accept callback, check
  temporary-child admission BEFORE gen_tcp:accept, excluding only permanent
  registry/listener. Full watermark retries without accepting; do not use a timer
  as a lifetime/reclamation proof. Handle per-connection start/ownership failures
  by disposing that socket/child, not crashing the permanent listener and losing
  unrelated leases. Actual listener failure remains one_for_all.
- sup:init adds permanent registry BEFORE listener. Replace context-only dynamic
  start with explicit connection/authority/context temporary child APIs. All
  child specs include modules for test discovery, or tests match actual spec/MFA.
  count_children.active minus two permanent children is a conservative temporary
  process count; all handoff/retiring roles count. No registry -> supervisor sync
  calls: start_child init must remain paused/fast until socket activation.
- connection gen_server init stores owned socket, no environment/registry grant.
  activate arms packet4 active-once with5s timeout. First frame only: decode and
  classify exact native3 role. Start corresponding paused endpoint, transfer
  controlling_process, send activation with first frame, stop router. Keep socket
  ownership sentinel explicit so router terminate never closes transferred port.
  Failed start/transfer stops the acquired endpoint and closes remaining socket.
  A recipient never evaluates/registers until activation; timeout handles router
  death before activation. Unexpected unhandshaken/partial frames fail locally.
- authority gen_server registers through registry on activation, sends its grant,
  then switches packet0/raw active-once. ANY byte (even partial packet4 header),
  EOF or error stops it; monitor retirement is authoritative. No framed post-Ready
  read, heartbeat, reconnect or environment. Temporary child/owned socket only.
- registry gen_server serializes open/admit/monitor updates using private records.
  API wrappers hide calls and parse untrusted wire numbers/IDs in the caller;
  stale/budget/duplicate valid requests return tagged errors preserving required
  high-water mutation. Malformed remote input must not crash the permanent
  registry or lose existing contexts. New admission consumes valid increasing
  ticket before SID/capacity rejection, installs monitor/index before Ready.
  Derive caller PID from From, not a remotely supplied owner field. Keep exact
  PID+ref correlations. Monitor-credit release follows DOWN only. On owner loss
  remove lease first, notify contexts asynchronously, retain context/SID credits
  until their physical DOWN; other leases untouched. Bounded retiring contexts
  may reference an absent lease without creating a retired-lease history map.
- context init currently constructs env before Hello. Change private startup to
  receive socket+decoded Hello while paused, env undefined until registry admit.
  Keep existing identity triple for Dispatch and direct resource callback fixtures;
  store native boot/lease/ticket and registry PID separately. On exact authority
  loss stop normally to run root/collector/trace/socket cleanup, without claiming
  close barrier/Cancelled. Existing native outcome/ACK/retirement logic stays.
- app.src registered list adds registry, dependencies add OTP crypto; existing
  metadata/version/license/startup remain. No legacy services or external deps.
  Declare actual new public callbacks/API specs/docs, alphabetically grouped
  exports, hyphen private helpers; preserve OTP-required underscores.

## LFE/API facts checked by author

Full Operator LFE style guide896 lines loaded. Local OTP28 reports crypto module
crypto-5.8.3; binary:encode_hex(<<0,16,255>>) returns <<"0010FF">>. Native boot uses
strong random bytes as the canonical contract requires, not clock/ref entropy.
Pinned LFE2.2.0 doc/lfe_types.txt lines62–69 supports typed record fields:
`(defrecord rec (field default type))`; a typed field requires an explicit default.
Use valid UNION undefined/default types where appropriate. Existing map-based
context need not undergo a record conversion in this scope.
LFE2.2 source lfe_comp.erl:161–173 adds source Ldir to include path; optional
private include can be `(include-file "../include/cayrn_lfe_registry.lfe")`
from both src/test. lfe_macro_include.erl:80–122 reads through that path. Keep
record macros for access rather than matching their positional tuple manually.
Do not add a product debug function just to inspect state in owned-peer tests.

## Behavioral proof route

Use existing test-owned standard_io peer pattern, not a user/distributed node.
with-peer in resource_tests currently filters out only listener and assumes the
single remaining child is context. Adapt to actual child module/spec after Ready;
retain authority socket for full callback invocation. Existing direct context
fixtures keep their identity triple and tests remain meaningful.

New authority_tests is an explicit companion in io_tests. Observe live state via
sys:get_state on the owned registry/context PIDs, using private shared record
macros if needed. Assert exact original criteria with positive/negative controls:
churn, replay scope, live SID, pressure, exhausted scalar, strict monitor, boot
restart, partial invalid authority bytes, same/different host and teardown. See
canonical contract§6 for numbers/expected results; do not invent new policy here.

4097-context churn: open one authority, create a fresh context/ticket, evaluate
first binding, close and wait exact context DOWN/registry reclamation each cycle;
retain old Hello and retry it at the end (must fail, visible marker absent), then
new ticket still evaluates42. Lease churn uses fresh authority owners and observes
exact owner DOWN; ID counter increases without accumulating old entries. Native
app restart yields different boot and invalidates old handle.

Pressure: while all live contexts held, valid next ticket refused before env/
source; release one exact context DOWN; retry that SAME refused ticket still
rejected, then higher ticket succeeds. Wrong lease/authority/boot does not consume
another live lease's ticket. Unknown/wrong-ref DOWN cannot free its budget. Native
wrapper validation failures remain local, never one_for_all.

Loss: two leases, multiple contexts on first; hold a foreground root/collector,
record owned PIDs and isolated trace. Close authority socket or send ONE raw
unexpected byte; keep context sockets open in the client. Wait EOF and exact
root/collector/context deaths and trace cleanup, then evaluate through other
lease. Context-only close leaves both authority and its sibling context usable.
Background user processes/side effects are not a sandbox/heap-restoration claim.

Ownership failure control can use actual exported handle_info callback with
state obtained from a real owned paused router, invoked on another owned test
process so controlling_process returns not_owner, or a closed owned port. This
must stop acquired endpoint and dispose router/socket, with surviving peer lease
usable. Preserve listener on per-connection failure. Add actual normal handoff/
handshake-timeout coverage; no new product probe/helper export. Record exact
callback setup/result rather than claim a nondeterministic race was forced.

Full actual C04 Make gate includes native4097-public-churn and twoHost process
loss isolation; those compose real installed paths with authority-only raw/
non-language controls at both seams. Preserve all prior21 native cases,1024
sustained and15 real host/PTY cases. Fresh source build and root launcher also
prove new header/modules/crypto are packaged/startable. Root launcher app set now
adds crypto; compiler remains LFE's dependency. No blind old counts/old oracle.

## Native stop must not require context mailbox cooperation

Concrete source liveness concern: context's capture path invokes gen_tcp:send
synchronously. A slow/non-reading client can block it; merely sending an
authority_lost message cannot wake that callback. This is an implementation
mechanic needed for the already-approved lease-loss policy, not a change to
wire semantics or a general output-pressure repair (still X03). Preserve the
issued C04 contract; its abstract registry API is refined privately here.

On successful native registry admission also retain the context port as a live
shutdown handle, supplied by context after controlling-process transfer. Extend
private admit's arguments with that port (no wire/Rust API change). Validate
port_info(Socket,connected) matches the caller PID before admission. Registry
authority-DOWN first retires the lease, then closes its recorded context sockets
with the abortive authority-loss procedure below and sends authority_lost asynchronously.
Do not wait on gen_server:stop or kill context (which would leak unlinked root).
Physical context/SID credit still waits exact DOWN; socket closure alone is not
reaping proof. The context remains the cleanup owner of root/collectors/traces.

Local OTP28/kernel10.6.3 and erts16.4 source verifies gen_tcp:close delegates
through inet:tcp_close to prim_inet:close without a controlling-owner check. The
false/default linger path can wait on pending output for up to180000ms and must
NOT be used by this registry callback. Select an abortive close on AUTHORITY LOSS
ONLY: first inet:setopts(Socket,[{linger,{true,0}}]), then gen_tcp:close(Socket).
prim_inet:close173–178 takes its direct close_port branch for {true,0}; close_port
268–273 invokes erlang:port_close with no queue-drain loop. The setopts control
path1023–1033/2962–2977 uses port_control rather than a mailbox receive. If setopts
fails because the recorded port is already closed, use caught erlang:port_close
as the bounded idempotent disposal fallback, never default-linger gen_tcp:close.
Handle closed/invalid ports locally; do not crash the permanent registry.
prim_inet:send576–629 monitors the port and returns {error,closed} on port DOWN,
waking the blocked sender so normal context termination can clean owned resources.

This path deliberately abandons native buffered bytes at a lost authority. Only
the already committed Rust transcript prefix is promised; loss has uncertain
capture tail and no false Close barrier/outcome. Do NOT change socket linger for
normal operation or explicit Close; its drain/ACK semantics remain. A retained
port is a transient control handle, not native durable history. This selects one
mechanism for the supported port-based Unix socket profile; runtime tests must
confirm the actual pressure behavior rather than infer it from option docs.

Discriminating owned-peer control: establish a context with known active root/IO,
drain/ACK its START output, then sys:suspend the context. Retire only its authority
while keeping context client socket open. EOF must arrive BEFORE context resumes;
registry lease gone but context/SID credit retained while PID still alive. Other
lease evaluates while first context is suspended. Resume in guaranteed cleanup;
then wait exact root/collector/context DOWN and trace cleanup/credit release.
A notify-only implementation fails this control; a premature-credit release
also fails. This proves the authority shutdown path does not wait for a normal
context mailbox turn; it does not claim to benchmark or exhaust all TCP queues.

Additional pending-output control (distinct from suspended-context control): use
an owned real context and non-reading raw client, configure small send/receive
buffers and record their returned values. Dispatch a bounded source that posts
at most32 asynchronous group-leader io_request messages, each8000 characters,
then waits for a release message. The source stays below8192 bytes; individual
chunks stay below the current8192 capture bound and pending requests below64.
Poll actual inet:getstat(ContextPort,[send_pend]) until >0 before retiring the
authority. A sleep is not proof that a send queue is pending. Retire only that
authority, without draining client output or releasing the root, and require
registry responsiveness/other-lease evaluation plus exact context/root/collector
DOWN and eventual credit reclamation. Use a bounded external fixture watchdog
and guaranteed owned-peer teardown so an incorrect close cannot strand the test.
Record inability to establish the positive pressure precondition as a failed or
blocked attempt, not a passing negative control. This specifically rejects the
false/default-linger waiting branch and notify-only shutdown; it does not certify
general ordinary-operation output pressure, which remains X03.

Revision2026-10-19: independent review NR-01 rejected the earlier false-linger
recipe after inspecting prim_inet. That draft was never issued to CC and no native
code was implemented from it. The source counterexample and review are preserved
in native-recipe-design-review.md; this corrected recipe requires fresh review.
