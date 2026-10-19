# CC implementation — xrepl Project10/Arc02/Slice04

2026-10-19, initial cc-prompt.md. CDC/root owns design and independent acceptance;
actual CC/root/xrepl_x21 implements under CF2.8.0 Autonomous/Expedited authority
through this Arc02 only. Source release/0.2.x is accepted7427d1c8e43183b25012e6870937347c39425606,
X03 planning acceptance a683721 (full identity in source-baseline.json). Matching
Cayrn34af63eb9f07a0e019495378045852ad69d00284, clean source. Preserve xrepl's only
pre-existing untracked docs/design. No push, merge, publish, later arc, UX or new
inquiry. This is implementation, not a return-only readiness task.

Useful result: complete supported output in bounded UTF8 chunks; responsive
native owners and exact durable ACKs prevent ordinary large writes or a failed
owner from stranding the root/formatter. Serious NR-02 is in scope, not waived.
Binding details are artifacts/stream-ownership-contract.md, required in full.
No native4/public1/version/dependency or common Rust policy change.

## Exact source and return scope

Only these12 source paths, including four NEW:
```
apps/cayrn_lfe/src/cayrn_lfe_context.lfe
apps/cayrn_lfe/src/cayrn_lfe_io.lfe
apps/cayrn_lfe/src/cayrn-lfe-stream.lfe
apps/cayrn_lfe/src/cayrn_lfe_writer.lfe
apps/cayrn_lfe/test/cayrn_lfe_io_tests.lfe
apps/cayrn_lfe/test/cayrn_lfe_resource_tests.lfe
apps/cayrn_lfe/test/cayrn_lfe_authority_tests.lfe
apps/cayrn_lfe/test/cayrn_lfe_stream_tests.lfe
apps/cayrn_lfe/test/cayrn_lfe_ownership_tests.lfe
apps/cayrn_lfe/README.md
apps/cayrn_lfe/AGENTS.md
README.md
```
Existing resource/authority tests may migrate private state/API fixtures and
strengthen pressure witnesses, preserving their original observable criteria.
New stream/ownership suites must be discovered through actual companion route.
No registry/listener/supervisor/app/router/evaluator/preview/Rust/build/manifest/
lock/launcher or standalone changes. Essential missing scope/contradiction goes
to CDC before affected edits; no opportunistic fixes or silently weaker proof.

Planning CC exact8 return files relative to this slice: artifacts/execution.md,
artifacts/intake.log, artifacts/validation.log, artifacts/source-candidate.json,
artifacts/source-candidate.patch, artifacts/artifact-inventory.md,
closing-report.md, ledger.md (evidence/notes only, all8 statuses open). No parent,
issued prompt, binding design or reviewer edits. Preserve raw failed attempts,
commands/exits and helper sources. Source and planning separate reviewed exact
allowlisted commits, both trailers:
Co-authored-by: Codex <noreply@openai.com>
Co-authored-by: Billo AI <ai-engineering@billo.systems>

## Required-reading manifest and intake

Resolve X=/Users/oubiwann/lab/lfe/xrepl/xrepl,
C=/Users/oubiwann/lab/oxur/cayrn,
P=X/.worktrees/planning/project10-shared-repl-architecture,
A=P/arc02-sustainable-native-evaluation,
S=A/slice04-owned-captured-streams,
F=/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills/collaboration-framework,
K=F/knowledge,
E=/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills/erlang-guidelines.
Required-full means complete actual text, tables/code/appendices, with contiguous
truncation recovery. Data-query coverage is not full prose reading. Order:

1. Required-full S/cc-prompt.md, slice-plan.md, ledger.md,
artifacts/stream-ownership-contract.md and design-review.md; X/AGENTS.md,
X/apps/cayrn_lfe/AGENTS.md, X/.worktrees/planning/AGENTS.md, P/AGENTS.md,
P/project-plan.md, P/design.md, P/ledger.md, A/ledger.md. Required-section
A/arc-plan.md Capability/boundaries, Inputs/sequence, Composition/exit, Autonomous
activation, v1.4 NR-02, v1.7 decomposition and v1.8/X03 acceptance complete.
Superseded unissued draft is reference-only history; consolidated contract binds.

2. Required-full X03/cdc-verification.md and cdc-retrospective.md under A;
X02/cdc-verification.md Current verdict, NR-02, final bubble-up complete sections
and X03/artifacts/ownership-review.md. Existing evidence is pinned, not a new X04
runtime pass. C/docs/native-agent.md required sections protocol, capture ACK,
close and interrupt; C/docs/result-previews.md full preserves native4 metadata.

3. Required-full F/SKILL.md2.8.0, K/project-management/guides/README.md,
K/work-verification/guides/01-ledger-discipline.md and05-independent-verification.md,
K/testing/guides/03-validation-gates.md. Required-section methodology01 Roles/shared,
Two-Contributor and Autonomous; prompt-authoring07 Required reading/intake; PM02
iteration preservation and PM03 issuing/executing iteration. No simulated review.

4. Required-full actual /Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md,
E/SKILL.md, E/guides/11-anti-patterns.md. Required complete headed clauses:
06-processes-and-concurrency PC02/03/07/10/14/15;
07-otp-behaviours BEH03/04/05/06/08/09/10;
08-supervision-and-applications SUP04/05/06/07/09/11/12/13/14;
04-data-and-types DT10/11/12;05-functions-and-pattern-matching FP11;
10-performance PF07/08/09. Contract §10 applies actual strength/context, including
fast callbacks MUST and asynchronous bounded credit instead of blocking call cycle.
Rust not edited; existing real Rust/native gates still required.

5. Required-full current X/apps/cayrn_lfe/src/cayrn_lfe_context.lfe,
cayrn_lfe_io.lfe, cayrn_lfe_authority.lfe, cayrn_lfe_registry.lfe,
cayrn_lfe_listener.lfe, cayrn_lfe_sup.lfe, cayrn_lfe_app.lfe;
all current6 native test modules (eval, preview, application, authority, resource,
io); X/apps/cayrn_lfe/README.md. Required-section root README native integration
and Makefile native/Rust check targets plus component Makefile/rebar configs.
No parent source expansion implied by required read-only inspection.

6. Required-section installed OTP stdlib unicode.erl exported encoding/chardata
specs, characters_to_binary error/incomplete branches and mixed-list/binary
carry logic (verify actual stdlib path; author used7.3, lines78–110,153–255,
301–344,851–903,1216–1217). sys.erl install docs and debug callback invocation
(lines691–724,877–890); gen_server.erl actual {in,Msg} debug-before-handler
2392–2394. kernel trace.erl session_create/destroy docs1403–1457. Read actual
symbols/dependencies if installed line offsets differ. APInames verified locally,
no invented sys callback state access; Extra is Name, not state.

7. Required-data artifacts/source-baseline.json ALL12 before hashes/absence,
both source pins/branches/worktrees/staging/status, planning identity. Query every
production gen_tcp:send, capture/committed/finished/retire/seal/start caller,
root/evaluated/foreground/retirement state producer/pattern, direct context/IO
callback fixture and test discovery reference across native tree; inspect complete
population and enclosing definitions. Capture runtime export/module population
before/after; generated exports classified, no test-only API. Existing56 unique
native methods must retain behavioral disposition, repeats separately counted.

Record complete text extents/recovery and separate data-query results in
artifacts/execution.md/intake.log. Source-cited readback must explain startup
publication, owner-monitor unlink gap, retained root identities, blocked-writer
single-owner kill, cross-sender sent/ACK/job credit/terminal bits, deferred-source
cancellation, post-seal rejection accounting and all actual gates before source
mutation. Resolve material gaps with CDC; coherent preflight proceeds without
routine approval. Revalidate source/assignment and reload unreliable contracts on
resume; receipts/hashes/another context summary never prove actual text reading.

## Implementation spine

Follow binding contract §§2–8, one coherent ownership/stream increment:

1. New network writer module owns only bounded FIFO sends, nontrapping linked
worker. Context owns/monitors it, retains socket controlling process. Replace all
nine context direct send paths; authority's single activation send stays intact.
Track exact current refs and68 frame bound; terminal sent+normal DOWN before
context credit. No network send in context/collector callbacks.
2. Collector creates linked paused root under guarded acquisition, stores exact
owner monitor through retirement unlink. Async origin_ready/ref→published context
root/trace identities→activate self-message→collector grant. Retain every root
identity until collector physical DOWN. Both responsive owners kill known roots/
formatters first; expected role EXIT/DOWN handlers preserve real completion.
3. Explicit foreground states and one deferred validated Dispatch while publishing;
consume token once, create nothing before writer_sent. Close/exact deferred Cancel
cannot later activate source. Capacity checked at activation; no unbounded queue.
4. Collector validates supported request shape/counts EVERY request, holds opaque
payload locally and proposes bounded metadata. Context64 admitted jobs include
startup through physical DOWN. Linked paused formatter registration before any
user MFA/conversion. Concurrent workers permit nested supported I/O; ordinary
capacity errors, not one-worker deadlock. Trace manual worker births/descendants.
5. Stream worker explicit root/tail/element stack gathers<=1024 source units,
converts actual encodings with bounded carry, copied validUTF8 chunks<=8192,
one chunk/job until dual sent+durableACK. Invalid suffix emits valid prefix then
badarg, no whole-write ok. Empty valid write one empty ACKed frame. MFA exception
catch only around apply, conversion expected badarg only, invariant bugs visible.
6. Done+collector workerDOWN before io_reply/job_done; context job_done+its worker
DOWN before credit. Strong seal waits pre-seal admitted jobs/chunks/root-accounted
and traced sent==observed; new/nested post-seal requests terminated+observed.
Natural and forced retirement retain separate proofs and exact physical DOWN.
Normal Closed after root/formatter/collector cleanup, then writer flush/death;
5second timeout FORCE-STOPS honestly with Lost/EOF, no indefinite second flush.
7. Adapt existing fixtures deliberately, add focused real wire and owner-failure
specimens, update component/root docs with complete output/errors/budgets and
single-owner limits. No result/output confusion, UX or legacy removal.

## Tests, gates and return

Contract §9 specifies exact falsifiable setups. Large mixed Unicode/binary/list,
all encodings/split carry/invalid tail/empty/MFA/nesting, no false original reply
before final ACK, capacity recovery, handler-order inversions and deferred-source
marker are required. Startup sys debug gates are pre-handler and use owned PEER
controller; never call sys:get_state on deliberately gated context. Unlink-gap
fixture retains external trace handle so GC cannot fake explicit cleanup.

Serious NR-02 requires positive native send_pend before collector-only/context-
only/listener/registry/application failure, with trap_exit root and formatter.
Use concurrent jobs to fill actual network, exact PID/ref DOWN and trace cleanup;
do not drain peer or release user blockers to make stop pass. Normal Close may
resume ACK after pressure and must fully resolve pre-seal jobs; perpetual hold
ends Lost/EOF, never false Closed. Inaccessible OS allocation injection explicitly
unrun; source review of construction guards is not pretend runtime coverage.

Run component make check; current-test precompile then root make test-lfe
build-agent check-agent build lint-rust test-rust; fresh source-only component
make check; root launcher from/private/tmp spaced socket native4 exactscope/42/
false preview/native-only apps/Closed/process0. Matching Cayrn make check
lint-integration test-xrepl executes ALL14 native+3 consumer/PTY with overrides
unset. No filtered/ignored/compile-only substitute. Derive actual unique/repeated/
root legacy/native/Rust/CT populations. Preserve warnings and every failed attempt.
X-TOOL-01 exact ignored shadow inventory/current precompile/fresh gate remains;
no permanent build-tool repair in this slice. X-PKG-01/X-DOC-01 distinct holds.

Freeze exact12 bytes and notify root BEFORE shared build gates. Capture all12
before/after hashes, full binary-safe patch, actual exports/BEAM identities,
complete intake/readback, all8 proposed row walk, failed/unrun/ignored counts and
support inventory. Commit exact source list then exact8 planning return, both
trailers, no push. All8 ledger statuses remain open until root independently
reviews/reproduces/accepts. Max5 executed corrective iterations; issued prompts
immutable. C06 composition remains required; no standalone owner workaround or
silent drop of original output/NR-02 duties. Challenge a mistaken recipe before
changing binding policy or claiming green.

## Author readiness

Root read actual context/io and caller/test scope, full project contract and
current X03 acceptance, applied actual LFE/BEAM guidance and installed Unicode,
sys/debug and trace APIs. Independent source/design review found and resolved
cross-sender publication, unlink owner-monitor, post-seal count and Closed/writer
wording contradictions before issue. Full source-led private API/state recipe
and discriminating tests are consolidated in the binding contract. This combined
slice fits the coupled responsiveness proof that the earlier ownership-only
sketch failed; all12 paths/8 criteria, actual gates and C06 hold remain. Private
helper names/consistent state representation discretionary; no unresolved public
behavior, budgets, failure policy or proof method delegated to CC. No sketch is
claimed compiled, no investigation or general sandbox proof commissioned.
