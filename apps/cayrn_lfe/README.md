# cayrn-lfe

Imported into xrepl on 2026-10-18 from standalone cayrn-lfe
`1b04c15ac325731aab68a7491d23e4a9fecaa47a` under its included Apache-2.0 license.
The import preserved the prototype. Its five OTP runtime modules and three native
test modules are now written in LFE, preserving the native contract.

Reusable thin LFE/OTP runtime agent for Cayrn. The Rust host owns session policy,
durable admission, journals and replay; this application owns native evaluator
contexts and I/O. It depends on LFE, not xrepl. No Rust crate is required here.

Requires OTP 27+ (built-in JSON), rebar3, and LFE 2.2.0 (resolved by rebar3).
Initially exercised on OTP 28. The existing `cayrn-lfe-eval.lfe` supplies evaluator
semantics; the LFE OTP modules provide supervision, socket control and native I/O.

```sh
cd apps/cayrn_lfe # from the xrepl checkout
make check
mkdir -m 700 /tmp/cayrn-agent-demo
./bin/cayrn-lfe /tmp/cayrn-agent-demo/agent.sock
```

In another terminal, from the Cayrn Rust checkout:

```sh
make build
./bin/cayrn serve-agent --state-dir /tmp/cayrn-agent-demo/host \
  --agent-socket /tmp/cayrn-agent-demo/agent.sock
./bin/cayrn request --state-dir /tmp/cayrn-agent-demo/host '{"op":"create"}'
```

Use the returned session and generation with Cayrn's submit/inspect/read requests.
For example, submit `(set x 41)` followed by `(+ x 1)`. All client attachments
may disconnect; the host's separate agent connection keeps the environment alive.
The launcher runs a dedicated node; the OTP application can also be started in an
existing node by setting its `socket` application environment before startup.
It refuses an existing socket path; choose a fresh private directory after an
unclean node exit, rather than deleting an endpoint another process may own.

The internal agent wire is bounded, four-byte big-endian length-prefixed JSON,
version 3 independently of public client RPC version 1. Each Rust host first
opens one persistent AuthorityHello channel and receives a cryptographic node
boot and monotonic lease. Context Hello carries session, generation, authority,
boot, lease and an increasing canonical decimal ticket. Ready echoes that scope.
The host completes this handshake during bind; unavailable/mismatched agents fail
startup. Authority channels switch to raw framing after Ready: any byte/EOF/error
retires that lease and all its contexts, even if their clients remain connected.
A context socket loss alone preserves its sibling contexts. There is no native
reconnection, lease expiry or code replay. Dispatch/cancel/output/outcome use canonical positive
decimal admission tokens (1..i64::MAX); tokens may be sparse. Rust maps them to
public operation IDs using its durable journal. A scalar high-water fence rejects
stale/replayed native dispatches without retaining all past operation identities.
Output has an independent canonical decimal-string capture position and immutable
origin attribution. Rust must commit output before sending its ACK. Ordinary
results and errors remain separate. Agent IDs are binaries, never dynamically made atoms.

The prototype supports persistent bindings, top-level functions/macros, value
previews, foreground and late output through inherited group leaders, and ordinary
error recovery. Program input returns `enotsup`. Explicit global I/O devices,
including global stderr, are outside the initial capture profile. This evaluates
trusted code in the node; it is not a sandbox or rollback system. Definitions
made earlier in a failed multi-form request are not committed to the saved
environment; external effects and process-dictionary changes are not rolled back.

Limits: 16 live authority owners, 64 globally live/retiring contexts, 64 live
capture origins per context, 64 pending I/O writes, 8192-byte source/output/value
previews and 256KiB frames. Listener admission checks temporary children before
accepting at a watermark of128, with conservative hard bounds of128 accepted
sockets and256 temporary processes during router handoff. There is no cumulative
context-identity or operation-count limit. Registry maps retain only live state;
lease/ticket scalar exhaustion refuses new grants without wrapping. A valid new
context ticket is consumed before duplicate-SID/capacity refusal; retry needs a
higher ticket. Physical context credits return only after exact monitor DOWN.
A quiet evaluation returns its origin credit only after the collector has
physically stopped. Late descendants retain their original collector/token.
At 64 live origins a new valid token receives the ordinary Failed preview
`native resource limit: 64 live capture origins; source not evaluated`.
Its source does not run or change the saved environment, and its token remains
consumed. Capacity recovers when producers finish; retry requires a new public
operation ID. If every producer needs another evaluation to release it, external
runtime work or close is needed. Control remains available at full capacity.

Each origin owns an isolated OTP trace session on its paused evaluator and local
spawn descendants. Producer birth/exit/delivery witnesses, traced I/O sends,
actual I/O requests and durable-write ACKs jointly establish quiescence. Quiet
foreground results wait for collector DOWN; results with live background
producers can publish while retaining that origin. Capture tracing is destroyed
explicitly without changing independently configured trace sessions.
This covers inherited-group-leader local `spawn`, `spawn_link`, `spawn_monitor`
and `spawn_opt`, including asynchronous I/O senders that exit before an ACK.
Assigning an old group leader to unrelated existing processes, remote processes,
explicit devices and user tampering with tracing are outside this trusted
profile. User process/heap/message fanout is not sandboxed by origin credits.

Native3 requires a matching rebuilt Cayrn host, with no native1/2 fallback.
Restarting the application creates a fresh cryptographic boot and loses live
contexts; Rust reports state loss and never recreates an environment from history.
Authority-loss shutdown closes recorded context ports abortively to wake blocked
native senders, then requests normal owner cleanup. It abandons uncertain native
buffered bytes, never reports a Close barrier or success, and retains credits until
exact context DOWN. Ordinary explicit Close still drains/ACKs; it does not use
abortive linger. Root/collector/trace cleanup remains context-owned.

The existing OTP application helper owns the listening port for the whole
application lifetime. Registry or listener child failure, including kill while a
listener call waits on its supervisor, restarts native state with a fresh boot
while retaining the same live listening port and startup-resolved absolute path.
Accepted sockets belong to the listener until role handoff. Normal app stop reaps
the exact listen port before removing only its recorded socket inode; replacement
files/symlinks/socket inodes are preserved. Bind/Supstart failures unwind newly
acquired resources. Whole application/helper/VM kill can still leave a stale path;
there is no automatic BEAM relaunch or adversarial filesystem guarantee.

Large-value assertions/output chunking and ordinary capture-pressure hardening
remain later work. A serious known limit (NR-02, X03/C06) is forced supervisor
teardown during a blocked context send: it can orphan an unlinked evaluator root.
The native3 authority-loss path has separate suspended/positively pending-send
controls; they do not establish broad forced-teardown readiness. The standalone
native1 predecessor remains pinned separately.

Host-agent link loss terminates that context and marks its state uncertain/lost;
it never kills the shared BEAM or peer contexts. Host restart retains the Rust
journal but does not restore native environments or rerun evaluations. Agent
control/recovery capabilities remain experimental; use the documented Cayrn
profile, not arbitrary retries of native dispatch messages.

`make check` runs native evaluator tests. Cayrn's `make test-agent` runs the
real host/BEAM socket path, including reconnect, deduplication and failure cases.
Nothing has been published to Hex or crates.io.

## Native control capabilities

The handshake advertises `interrupt: session_destructive` and `close_barrier: true`.
An interrupt receipt is not success: the agent monitors evaluator death before
reporting Cancelled, then retires the context and exposes possible capture-tail
uncertainty. Peers in the node remain alive. A completed evaluation can win a
cancel race. Cooperative interruption is a separate capability supported by the
shared Rust contract, not currently by this LFE implementation.

Close stops a running foreground evaluator or publishes an already computed
result, seals Live capture origins and waits for their seal messages, all
Retiring collector DOWNs and Rust's outstanding capture ACKs before emitting a
close barrier. Sealed I/O cannot append later output. Unmanaged external processes
are not rolled back or silently claimed stopped. A five-second barrier timeout
reports incomplete close; socket EOF is never a close acknowledgement. Rust
alone seals the archive and rejects later mutation. Native supervision or context
replacement never restores a heap or automatically retries an uncertain operation.

The test suite includes I/O false-ACK and seal-order negative controls; the real
Cayrn/xrepl gate additionally exercises context/agent/host failure, SQLite aborts,
shared-node peer preservation and actual keyboard Ctrl-C in a PTY. Physical disk/
fsync/power-loss durability and production security remain unverified.

## xrepl repository entrypoints

From the repository root, `make build-agent check-agent` builds/tests this
component independently. `make build` includes the agent, legacy LFE app and
Rust client. `./bin/cayrn-lfe /private/path/agent.sock` delegates to this
component's launcher; it uses this component's `_build/default/lib/*/ebin`.
It starts `cayrn_lfe`, `lfe`, `crypto` and LFE's `compiler` dependency,
without starting legacy `xrepl`, Ranch,
`xrepl_protocol` or `xrepl_term`. Root and component Rebar caches are separate.
The component version stays 0.1.0 while the enclosing xrepl release is 0.2.0.

Cayrn's native/terminal targets default to this integrated component and the
sibling xrepl Rust binary; explicit `CAYRN_LFE_DIR` and `XREPL_BIN` overrides are
available. Component-only `make check` explicitly discovers evaluator, application
resource and authority tests through the I/O companion generator. Resource cases cover
512 quiet sparse dispatches, 64/65 origin pressure, replay non-execution, producer
and request/trace order inversions, ACK/close races, physical retirement and
independent tracing. The matching Cayrn integration fixture performs 1024 further
evaluations while retaining an early late writer's attribution. Callback/module
names retain underscores for OTP/wire compatibility; private helpers use LFE
conventions. Authority cases exercise4097 reclaimed contexts,33 lease cycles,
16/17 authority and64/65 context pressure, strict scope/replay/counter/monitor
controls, router/handshake failures, fresh boot and authority-only loss with raw
client sockets retained, including suspended and positively pending native sends.
Size and ordinary-pressure limits are recorded above.
