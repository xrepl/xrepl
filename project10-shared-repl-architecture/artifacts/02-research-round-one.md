# Research round one — reliability and runtime fit

Date: 2026-10-18. Author: Sofie. Method: focused inspection of primary protocol,
storage, concurrency and runtime documentation, plus selected local seams and
Project09's delivered reports. Findings below separate documented facts from
our architectural inferences. No benchmark or runtime experiment was performed.
This is a bounded first pass, not a claim of comprehensive literature coverage
or a survey of the latest distributed-systems research papers.

## Questions and dispositions

| ID | Starting proposal / question | Evidence | Disposition and design implication |
| --- | --- | --- | --- |
| D01 | One ordered durable session log plus live fanout | Tokio S03; JetStream S04 | Keep. Make the log authoritative and notifications disposable; a slow attachment reads the log rather than blocking other attachments. |
| D02 | Stable request IDs prevent accidental reruns | JetStream S05 and the arbitrary-code failure window | Keep, strengthen. Retain session-scoped dedup records through archive deletion; identical ID with changed payload is a conflict. Messaging dedup cannot transactionally protect arbitrary external effects. |
| D03 | Control remains available during eval | Jupyter S01; Tokio S08 | Keep. Separate scheduling and resource budgets for control; a second socket is optional. A Tokio task abort is not an execution kill. |
| D04 | Completion ends an evaluation | nREPL S02; Jupyter S01 | Clarify. One foreground outcome ends the operation; later attributed output remains legal until a distinct session close barrier. |
| D05 | Complete transcript survives all crashes | SQLite S06/S07 plus producer/log failure analysis | Clarify. Never truncate committed transcript; uncommitted producer output can be lost. Preserve continuity status and never label an uncertain tail complete. |
| D06 | Reconnect should seamlessly catch up | JetStream S04 and session-log design | Keep. Use one read-after cursor path for old and new data, with level-triggered wakeups/rechecks; avoid a replay-to-pubsub handoff race. |
| D07 | Close archives state and records | Local xrepl shell seam; Project09 close/save finding; Rust S09 | Clarify. Archive durable records after owned producer drain; live heap state is released, not implicitly snapshotted. Stopping one shared session must not kill its runtime peers. |
| D08 | Rust core plus thin native agents | Erlang S10/S11; Fennel S12/Lua S13; Lykn/Oxur local source | Keep. Rust owns common policy/storage; native code owns evaluation, runtime context, hooks and native value inspection. Public endpoint placement remains flexible. |
| D09 | Multiple attachments can answer program input | Jupyter S01 identifies a designated input frontend | Add explicit ownership. Prompt IDs plus an exclusive responder assignment and epoch prevent stale/double replies. Secrets are outside the ordinary replay payload. |
| D10 | Pick a broker, codec and database now | Sources constrain semantics but do not select a stack | Defer final selection. Local transactional storage is a plausible first candidate; no external broker is required for the initial topology. |

The additional prompt-ownership detail follows directly from simultaneous clients;
it is a design recommendation, not a newly approved expansion into multi-user
collaboration. The target remains one owner using terminal/editor attachments.

## Primary references and bounded claims

All URLs below were inspected on 2026-10-18. Versioned URLs are pinned where
available; `latest`, `stable` and default-branch URLs are mutable references.
The focused claims are short source summaries, not copied specifications.

| ID | Primary source and locator | What it supports / limit |
| --- | --- | --- |
| S01 | [Jupyter messaging](https://jupyter-client.readthedocs.io/en/stable/messaging.html), Introduction, Kernel status, stdin | Multiple frontends, broadcast output, independent control, input routing and output after idle. Its documented background-output ambiguity motivates an explicit rule here. We do not adopt its transport or claim its IOPub provides durable replay. |
| S02 | [nREPL draft specification](https://spec.nrepl.org/), Protocol Description, eval, stdin, optional operations | Asynchronous multi-response requests, capability discovery, output that can outlive a request. Borrow useful patterns while defining our own durability/session semantics. |
| S03 | [Tokio broadcast](https://docs.rs/tokio/latest/tokio/sync/broadcast/), Lagging and subscribe | Bounded retention can overwrite old messages; new subscribers see future messages. Useful as a wakeup/fanout aid, insufficient as transcript storage. |
| S04 | [JetStream concepts](https://docs.nats.io/concepts/jetstream), Streams and Consumers | Stored streams and independently tracked consumers support replay and redelivery. Useful reference model, not a selected deployment dependency. |
| S05 | [NATS maintainers' deep-dive source](https://github.com/nats-io/nats.docs/blob/master/using-nats/jetstream/model_deep_dive.md), Message Deduplication and Exactly Once Semantics | Deduplication has a configured window; publication/consumption guarantees concern messaging. Our session-lifetime key retention and arbitrary-code effect limits are our design inference. |
| S06 | [SQLite synchronous](https://www.sqlite.org/pragma.html#pragma_synchronous), FULL/NORMAL; [atomic commit](https://www.sqlite.org/atomiccommit.html), flush and hardware assumptions | WAL/NORMAL can lose committed transactions after power loss; WAL/FULL has a stronger durability contract subject to VFS/storage assumptions. A commit policy must be explicit. |
| S07 | [SQLite WAL](https://www.sqlite.org/wal.html), Overview and Disadvantages | WAL uses host-local shared memory; long readers/checkpointing need care. A possible local journal, not shared network-filesystem coordination. |
| S08 | [Tokio spawn_blocking](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html), cancellation caveat | Already-running blocking work cannot be stopped with task abort. Put evaluator cancellation and hard-stop semantics at the actual runtime/process boundary. |
| S09 | [Tokio process Command](https://docs.rs/tokio/latest/tokio/process/struct.Command.html#method.kill_on_drop), kill_on_drop | Child cleanup depends on explicit ownership/policy. A terminal's task tree must not own a durable session's runtime lifetime. |
| S10 | [Erlang I/O protocol](https://www.erlang.org/doc/apps/stdlib/io_protocol.html), Protocol Basics | Native I/O uses correlated request/reply messages. An adapter can acknowledge captured output through a Rust-owned durable path. Exact behavior requires implementation tests. |
| S11 | [Erlang group_leader](https://www.erlang.org/docs/27/apps/erts/erlang.html#group_leader/0), group_leader/0 and /2 | Child processes inherit group leaders; normal group I/O goes there. This does not capture every possible native/file/network write or identify the originating eval automatically. |
| S12 | [Fennel 1.6.1 API](https://github.com/bakpakin/Fennel/blob/1.6.1/api.md), configurable repl | REPL callbacks expose reading, values and errors; ordinary evaluated print/io calls need separate capture. Do not replace persistent REPL compilation context with unrelated one-shot eval calls. |
| S13 | [Lua 5.5 manual](https://www.lua.org/manual/5.5/manual.html#lua_sethook), lua_sethook | Count/line hooks run while executing Lua functions. This is not proof of timely interruption while blocked in native C work. |
| S14 | [Deno REPL](https://docs.deno.com/runtime/reference/cli/repl/), special variables and eval flags | Deno has a persistent interactive environment. The CLI documentation alone does not define a supported programmatic Lykn incremental evaluator API; integration remains an explicit decision. |

## Local evidence and interpretation

The [baseline manifest](05-baseline.json) records current local revisions and
selected-file hashes. Selected source reads support architectural seams, not
whole-repository audits or fresh acceptance of historical claims.

- Oxur uses direct Postcard serialization and a Reedline terminal. Its evaluation
  context includes both interpreter and compiled/subprocess routes. Keep the
  evaluator/compiler adapter separate from the shared session protocol. Existing
  enum fields/modes and clone behavior are not automatically portable contracts.
- xrepl has an opaque per-shell state behavior, a useful native boundary. The
  Rust PoC's synchronous `handle -> Vec<OutputFrame>` cannot deliver independent
  late events/control; it is an input to a future migration, not our target API.
- Lykn's active release source emits JavaScript through Rust codegen and invokes
  Deno. A persistent REPL must preserve both compiler-side and JavaScript-side
  state; launching `deno run` afresh per form would violate R04.
- The protocol sibling supplies MessagePack framing and an operation catalogue;
  builders for operations do not prove those operations are implemented by a
  server. The terminal sibling is an LFE terminal library, not the Rust REPL.

[Project09's assessment index](../../project09-quality-assessment/arc01-current-state/slice04-rust-audit-and-synthesis/artifacts/2026.10.17-audit-index.md)
and [synthesis](../../project09-quality-assessment/arc01-current-state/slice04-rust-audit-and-synthesis/artifacts/2026.10.17-audit-modernization-synthesis.md)
provide reported failure cases worth preserving as future conformance tests:
same-session result misattribution, close/save races, expiry/lifecycle ownership,
Rust peer failure, response correlation, text conversion and ineffective limits.
At initial inspection the audit source pin `b865b313...` was unavailable locally
(`git cat-file -t` failed) and main was `3b588042...`. After the Operator pulled
main during this work, a fresh check resolved HEAD to exactly
`b865b3137e841269f9218d978817cc243e6b9278`; the object lookup succeeds and
`git diff b865b313... HEAD -- src crates` is empty. The source baseline now
matches Project09. This refresh does not reproduce its runtime tests. Project09's test results and
review statements remain imported evidence with their recorded limitations.
No runtime repair or Project09 gate is closed here.

### Selected source locators

These links resolve to the local files hashed in the baseline manifest. They
identify the inspected seams, not a claim of complete repository review.

| Seam | Source |
| --- | --- |
| Oxur wire serialization | [Cargo dependency](/Users/oubiwann/lab/oxur/oxur/crates/oxur-repl/Cargo.toml), [codec](/Users/oubiwann/lab/oxur/oxur/crates/oxur-repl/src/protocol/codec.rs) |
| Oxur state and worker ownership | [evaluation context](/Users/oubiwann/lab/oxur/oxur/crates/oxur-repl/src/eval/context.rs), [subprocess](/Users/oubiwann/lab/oxur/oxur/crates/oxur-repl/src/executor/subprocess.rs) |
| xrepl synchronous Rust boundary | [backend](/Users/oubiwann/lab/lfe/xrepl/xrepl/crates/xrepl-core/src/backend.rs), [runner](/Users/oubiwann/lab/lfe/xrepl/xrepl/crates/xrepl-core/src/repl.rs) |
| xrepl native shell state | [shell behavior](/Users/oubiwann/lab/lfe/xrepl/xrepl/src/xrepl-shell.lfe) |
| Lykn active compile/runtime route | [Rust compiler](/Users/oubiwann/lab/lykn/lang/.worktrees/0.6.x/crates/lykn-cli/src/compile.rs), [CLI](/Users/oubiwann/lab/lykn/lang/.worktrees/0.6.x/crates/lykn-cli/src/main.rs) |
| Protocol and terminal siblings | [MessagePack](/Users/oubiwann/lab/lfe/xrepl/protocol/src/xrepl-ptcl-msgpack.lfe), [terminal library](/Users/oubiwann/lab/lfe/xrepl/term/src/xrepl-term.lfe) |

## Lookup failures and limits

- The short Erlang `/doc/system/io_protocol.html` route failed; the official
  stdlib route S10 succeeded.
- Old NATS concepts/consumer and deep-dive URLs redirected to reorganized docs.
  S04 uses the resulting concepts page; S05 uses the maintainers' source for the
  specific deduplication discussion. No broker release behavior was tested.
- SQLite page searches initially missed the relevant heading; the focused
  synchronous section was then inspected directly. This is a document lookup,
  not an fsync/power-loss validation.
- Deno CLI evidence does not settle the embedding/agent API. Lua hooks do not
  settle cancellation of native calls. Both remain bounded open decisions.

## Result and stopping condition

The finite reliability questions have keep/change/defer dispositions and all
four runtimes have explicit fit scenarios in the demonstrator plan. Stop this
research round here. The current evidence is enough to propose an implementable
contract; it does not justify automatic failover, transparent runtime recovery,
a dependency performance claim or production durability acceptance.

A subsequent research round should target a named remaining decision, such as
Lykn's persistent execution API or native endpoint/Rust-core packaging, with an
agreed scope and stopping condition. Do not silently renew this survey.
