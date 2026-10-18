# cayrn-lfe

Imported into xrepl on 2026-10-18 from standalone cayrn-lfe
`1b04c15ac325731aab68a7491d23e4a9fecaa47a` under its included Apache-2.0 license.
This README adapts the component home; implementation/tests remain unchanged.

Reusable thin LFE/OTP runtime agent for Cayrn. The Rust host owns session policy,
durable admission, journals and replay; this application owns native evaluator
contexts and I/O. It depends on LFE, not xrepl. No Rust crate is required here.

Requires OTP 27+ (built-in JSON), rebar3, and LFE 2.2.0 (resolved by rebar3).
Initially exercised on OTP 28. Native LFE semantics are in `cayrn-lfe-eval.lfe`;
small Erlang/OTP modules provide supervision, socket control and native I/O.

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
version 1 independently of public client RPC. Hello carries session, generation
and authority; dispatch carries operation/source and expected generation/authority.
Output has a canonical decimal-string capture position and immutable operation
attribution. Rust must commit output before sending its ACK. Ordinary results
and errors remain separate. Agent IDs are binaries, never dynamically made atoms.

The prototype supports persistent bindings, top-level functions/macros, value
previews, foreground and late output through inherited group leaders, and ordinary
error recovery. Program input returns `enotsup`. Explicit global I/O devices,
including global stderr, are outside the initial capture profile. This evaluates
trusted code in the node; it is not a sandbox or rollback system. Definitions
made earlier in a failed multi-form request are not committed to the saved
environment; external effects and process-dictionary changes are not rolled back.

Limits: 64 live contexts, 256 operations per context, 64 pending I/O writes,
8192-byte source/output/value previews, 256KiB frames, and 4096 context identities
per application lifetime. Operation I/O servers are retained to attribute late
writers, with the context budget bounding them. Identity tombstones and the
volatile duplicate guard are not evicted to make a stale dispatch executable.
Create a fresh session when the operation budget is exhausted. Restarting the
application loses contexts and its volatile identity guard; Rust must report
state loss, never recreate an old environment from transcript history.

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

Close stops the owned foreground evaluator, seals all operation I/O servers,
waits for their seal messages and Rust's outstanding capture ACKs, then emits a
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
It starts `cayrn_lfe` and `lfe`, without starting legacy `xrepl`, Ranch,
`xrepl_protocol` or `xrepl_term`. Root and component Rebar caches are separate.
The component version stays 0.1.0 while the enclosing xrepl release is 0.2.0.

For Cayrn's real native/terminal tests, explicitly set `CAYRN_LFE_DIR` to this
`apps/cayrn_lfe` directory and `XREPL_BIN` to the built xrepl Rust binary.
The independent app startup test complements the six preserved evaluator/I/O
tests; it does not claim that resource limits or oversized previews are fixed.
