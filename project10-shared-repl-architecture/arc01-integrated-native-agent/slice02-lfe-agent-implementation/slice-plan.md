# Slice02 — native agent implementation and tests in LFE

2026-10-18. Prepared open set, not executed. Author/executor/review passes use
one contributor, Sofie, under the Operator's reaffirmed workflow. `cc-prompt.md`
is the retained assignment filename, not a second actor. Source target is xrepl
`release/0.2.x`, now committed at `ea844f5e634dc1ffb2503b7d69c4726164395d82`. Cayrn test input is
`9111136fff4aad0241c7acada4f0b664bb87d2de` on `codex/core-session-lifecycle`. Planning stays here.
The Operator approved committing Slice01 and planning this slice; no claim of
independent reproduction or whole-arc acceptance follows from that approval.

## Useful result and boundaries

Deliver the same reusable native OTP application with its implementation and
native tests written in LFE, built/startable through the existing component/root
entrypoints and passing the real Cayrn host/BEAM/xrepl contract. Preserve clean
application ownership; do not migrate legacy evaluator/session/transport code.
No protocol/version change, new dependency, operation-budget/resource fix,
large-result fix, new input feature or UX change belongs in this port.

## Binding conversion map and unchanged interfaces

All paths below are relative to `apps/cayrn_lfe`. Replace each .erl with .lfe,
retaining the exact module atom and declared API/callback/test name-arities. Metadata (.app.src,
rebar files) remains Erlang terms. Existing `src/cayrn-lfe-eval.lfe`, LICENSE,
launchers and dependency locks remain byte-identical. Root version stays 0.2.0,
native version 0.1.0; kernel/stdlib/lfe remain the only native startup dependencies.

| Before → after | Module / exports to retain | Critical implementation obligation |
| --- | --- | --- |
| src/cayrn_lfe_app.erl → .lfe | cayrn_lfe_app: start/2, stop/1; application | Return supervisor startup tuple; no legacy services |
| src/cayrn_lfe_sup.erl → .lfe | cayrn_lfe_sup: start_link/0, init/1, context/1; supervisor | Same registration, one_for_all intensity 3/10; permanent listener; temporary contexts, shutdown 2000 |
| src/cayrn_lfe_listener.erl → .lfe | cayrn_lfe_listener: start_link/0, init/1, handle_info/2, handle_call/3, handle_cast/2, terminate/2; gen_server | Same private socket, packet 4 / 262144, accept 100ms, controlling_process before activate, ETS identity table and capacity gates |
| src/cayrn_lfe_io.erl → .lfe | cayrn_lfe_io: start/2, loop/2 | Linked tail-recursive loop, immutable operation attribution, no native ACK before Rust, seal ordering and explicit errors |
| src/cayrn_lfe_context.erl → .lfe | cayrn_lfe_context: start_link/1, init/1, handle_info/2, handle_call/3, handle_cast/2, terminate/2; gen_server | Preserve every command/info branch, monitored evaluation and capture/control barriers |
| test/cayrn_lfe_eval_tests.erl → .lfe | cayrn_lfe_eval_tests: four existing *_test/0 functions | Same41→42 bindings, saved environment after errors, function context and ordinary error atom |
| test/cayrn_lfe_io_tests.erl → .lfe | cayrn_lfe_io_tests: two existing *_test/0 functions | Same missing-ACK and seal/late-write negative controls, deadlines and child cleanup |
| test/cayrn_lfe_application_tests.erl → .lfe | cayrn_lfe_application_tests: independent_application_start_test_/0 | Fresh peer over standard_io; native apps present, four legacy apps absent, mode0600 and spaced socket path |

Underscores in these module atoms, callback/API names, test discovery names,
map keys, message tags and foreign record names are deliberate compatibility
exceptions to the style guide's hyphen preference. Filename stem matches module
atom. New private helper/local variable names use hyphens. Preserve map-shaped
state rather than introducing a record migration during translation. Existing
source pin/import map stays historical; record new digests in a conversion map,
not by rewriting Slice01 provenance or the standalone predecessor.

Compiler-generated exports are an explicit exception: LFE 2.2 adds
`__info__/1` and `LFE-EXPAND-EXPORTED-MACRO/3`, observed in the existing LFE
evaluator. Erlang EUnit also generates `test/0`. Do not demand byte-identical
compiled export lists or add spurious spec/API shims for these generated entries.
The conversion map must separately classify them and preserve all declared
runtime/callback entries and seven discoverable test/generator entries above.

## Translation recipe and semantic traps

1. Start with app/supervisor/I/O, then listener, context and tests, compiling the
   component during the port. Keep each .erl removal paired with its replacement;
   no shipped runtime depends on both implementations or on old cached beams.
2. Use `(defmodule ... (behaviour ...))`, explicit exports, public docstrings,
   2-space formatting, <=80 columns, pattern-matched function clauses and the
   documented `(defspec (name arity) (arg-types return-type))` form to retain
   exported contract/spec intent. No export-all, ltest addition or dynamic atoms.
3. Keep exact JSON key binaries and atom values. LFE maps use quoted atom keys
   for construction/access; binary JSON keys remain binaries. Erlang `=>`
   insertion/update maps to `map-set`; use `map-update` only for pre-existing
   keys. In particular `waiting` is added during close, not present in init.
4. Repeated variables within one pattern do compare, but an inner let/case/
   receive binding shadows an outer variable. Where Erlang pins an outer socket,
   ref, pid, monitor, operation, generation or authority, bind a distinct incoming
   variable and compare with explicit =:= guard. Do not let translated negative
   tests accept another reference/owner. Repeated equality inside a single
   function-head argument pattern may be retained as documented by LFE 2.2.
5. For context dispatch retain ordering: capture owner/env, start immutable-op
   I/O server, spawn_monitor evaluator waiting for evaluate, set group_leader,
   then send evaluate and record active/seen/ios. Evaluation must stay out of
   gen_server callbacks. Scope try/catch exactly as predecessor: bad commands
   stop invalid_agent_command; I/O conversion failures return badarg/enotsup;
   unexpected evaluator DOWN loses only its context. Do not widen a catch into
   a successful default or silently narrow existing failure classification.
6. Trace context branches: activate; tcp/hello/dispatch/ack/close/cancel/stop;
   capture; evaluated; DOWN for close/cancel versus unexpected; sealed;
   close_timeout; tcp_closed/error; handshake timeout; linked I/O EXIT; catch-all.
   Preserve matching identity guards and unknown-message behavior. Keep cancel
   and close distinct: cancel reports Cancelled after DOWN then lost; close
   waits until no evaluator, all I/O sealed and pending ACK map empty before
   emitting closed. EOF never substitutes for that barrier. Timers remain 5000 ms.
7. Keep current limits and failures: seen<256, pending<64, source/value8192,
   identity tombstones 4096 and listener gate 64. Preserve the oversized-value
   assertion and strict invalid-command exit as known later hardening inputs.
   No resource retirement or clamping/truncation in this port.
8. Convert all three tests using OTP EUnit header macros directly, verified in
   LFE 2.2's own test/ltest-macros.lfe. Explicitly export all six original test
   functions and the startup generator; keep _test/_test_ names. No ltest runtime
   dependency. Import kernel file.hrl and use file_info record macros for type/
   mode checks. Preserve peer result {ok,Pid,Node} and stop in after; do not
   inspect the root EUnit node, which legacy tests may already have populated.
9. Update component README/AGENTS and root README narrowly for completed port
   and residual limits. Native identity/config and root legacy startup remain.

Representative API sketch (not compiled here):

```lisp
(defmodule cayrn_lfe_app
  (behaviour application)
  (export (start 2) (stop 1)))

(defun start (_type _args)
  "Start the native agent supervision tree."
  (cayrn_lfe_sup:start_link))
```

All five runtime modules and three tests are one coherent ~350-line predecessor
population plus LFE expansion, within one implementation context with review/fix
headroom. If a missing compiler facility or semantic ambiguity demands a new
architecture/dependency, hold that affected work and discuss; do not silently
split/drop modules or start an investigation. Five refinement iterations max.

## Test oracles, stale-code control and commands

| Claim | Real check / rejected implementation |
| --- | --- |
| Implementation is actually LFE | Exactly8 .erl removed,8 .lfe replacements; inspect compile_info source ending.lfe for five runtime and three test modules in the built profile. A stale Erlang beam cannot satisfy this. Existing evaluator remains unchanged. |
| Native semantics preserved | Explicit 7-case component EUnit inventory and exact assertion outcomes; empty/undiscovered suite is failure, not success. |
| Capture/control and fencing preserved | Existing 11 real native tests at explicit new agent dir; false ACK, stale authority/gen, malformed frames, cancellation death, close immutability and loss cases remain. |
| Terminal integration retained | Existing 3 actual xrepl/PTY tests, same source client; no fake consumer. |
| Independent app remains reusable | Converted startup test creates a fresh peer, excludes xrepl/ranch/xrepl_protocol/xrepl_term and checks mode0600/socket-with-space. |
| No cache-assisted port | In addition to current builds, copy only source/config/lock/Make/launcher/license into a test-owned fresh component directory (no _build, ebin or .git), make build/check there; use that directory in a filtered real native binding/reconnect test. No user state/cache deletion. |
| Existing application preserved | Root compile/build, Rust lint/tests and legacy EUnit before/after; prior 184 executions include2 duplicate I/O cases, legacy 175 are separately retained. CT0 discovery is a known gap, never acceptance. |

From xrepl: `make build-agent check-agent`, `make compile-lfe build`,
`make lint-rust test-rust`, `make test-unit-lfe`, `make test-ct-lfe`.
Run baseline unit/CT before port if drift affects earlier 184/CT0 evidence; preserve
any failure and compare the actual named legacy cases. No ignored/weakened tests.
From Cayrn: `make check`, `make lint-integration`, then

```bash
make test-xrepl \
  CAYRN_LFE_DIR=/Users/oubiwann/lab/lfe/xrepl/xrepl/apps/cayrn_lfe \
  XREPL_DIR=/Users/oubiwann/lab/lfe/xrepl/xrepl
```

This uses the converted app explicitly; Cayrn's default still points to the
predecessor until C-AGENT. Inspect actual executed counts. A clean-copy native
case can use `cargo test -p cayrn-cli --features native-integration --test
native_agent bindings_shared_clients --locked -- --test-threads=1` with
CAYRN_LFE_DIR set to that already-built fresh copy. Record the exact copy file
population and test-owned process cleanup. No new reusable validator is needed.

## Allowed source and return

Allowlist: the 8 .erl removals and corresponding8 .lfe additions above;
apps/cayrn_lfe/README.md, apps/cayrn_lfe/AGENTS.md, README.md. Existing evaluator,
metadata, versions, dependencies/locks, launchers, Make targets and all legacy
source stay unchanged. Build/cache paths are test artifacts only, never commits.
No Cayrn source edit. Preserve untracked docs/design and sibling/predecessor repos.
Source commits only when requested with exact reviewed files and Codex/Billo AI
trailers; no push/publication or automatic later-slice execution.

Artifacts: artifacts/execution.md for required-text ranges, data query, source-
cited readback, commands/failed attempts and self-review; conversion-map.json for
old/new paths, commit, digests, modes, export/spec/test-case inventory; supporting
logs as needed. Return closing-report.md with every XS02 row, exact candidate/
commit, source allowlist, inventory and arc bubble-up. Keep independent gates
pending until performed; no synthetic verification file.

## Author readiness and assignment history

Inspected pinned 5 runtime modules, 3 native test modules, existing LFE evaluator,
component build/metadata, root hooks and Rust harness. Loaded full 896-line style
guide, LFE 2.2 guide Patterns/Variable Binding and Scoping/Map forms and Types
Specifications, own EUnit macro bridge, OTP BEH-01/02, SUP-04/05 and AP-02/05/06.
Existing evaluator compile_info and representative module export tables were
queried: source records actual .lfe path; LFE compiler/EUnit generated exports
are explicitly distinguished from the preserved declared interface,
so that oracle is available without a new framework. LFE/OTP choices are resolved
above; examples are author sketches, not a tested translation. No inquiry-only
work is commissioned. Existing real tests supply contract proof; this packet
supplies the missing translation/identity/cache/discovery checks.

| Assignment | Date | Predecessor | Disposition |
| --- | --- | --- | --- |
| cc-prompt.md | 2026-10-18 | none | Prepared for Operator activation; not executed |

Current assignment: prepared cc-prompt.md. Next action owner: Operator to select
execution; Sofie then performs the implementation and separate self-review pass.

[Planning checks and readiness limits](artifacts/planning-validation.md) record
the current source/row/link checks and distinguish them from future execution.

## Execution activation —2026-10-18

The Operator now authorizes committing these plans, then implementing xrepl's
LFE conversion followed by Cayrn's integrated-agent profile with one collaborator.
Earlier prepared/planning-only wording is historical, superseded here. Sofie
executes and separately self-reviews; all evidence stays author-attested. The
validated, byte-identified converted-agent candidate/return is the bounded input
for Cayrn, even if its implementation commit has not yet been requested. No
independent acceptance, whole-arc close, push/publication or later slice is implied.
The staged sequence is authorized without intermediate routine approval.
