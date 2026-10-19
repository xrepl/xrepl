# CC assignment — xrepl Project10/Arc02/Slice02

Initial cc-prompt.md,2026-10-19. Actual CC /root/xrepl_x21; independent CDC
Sofie /root. Operator-approved collaboration-framework2.8.0 Autonomous Mode and
Expedited Mode through Arc02. Implement and return proposed done, not acceptance.
Five executed correction passes maximum. No other implementation writer owns
these files. CDC owns design/review, acceptance, parent updates and retrospective.

## Useful result and actual prerequisites

xrepl release/0.2.x at7228183e2e584e0ab86e03dc6b9454d4b918cc38, only pre-existing
untracked docs/design/. Deliver the native3 LFE/OTP half of the approved authority/
context-ticket design, removing cumulative identity exhaustion while retaining
live physical resource budgets and process ownership. Rust owns durable/public
session policy; this app owns transient runtime hooks, not a second journal.

Cayrn's actual source3bcbbdb9ec52667b6c75b7f8a5f2260b93d8be44 on
codex/core-session-lifecycle is independently accepted at bounded C04 scope.
Cayrn planning806a8a35638332f0bb912483f1d45fed3f359a56 preserves its verdict,
failed candidates and correction history. Read the actual source and verdict;
no future hash, previous native2 gate or summary substitutes. Immediately run
its held full real gate against your matching native3 implementation.

Absolute repo roots:
- xrepl: /Users/oubiwann/lab/lfe/xrepl/xrepl
- Cayrn: /Users/oubiwann/lab/oxur/cayrn
- both planning worktrees: corresponding .worktrees/planning
- this project: project10-shared-repl-architecture
- this slice: arc02-sustainable-native-evaluation/slice02-node-authority-leases
- shared C04: Cayrn planning/project02-core-hardening/arc01-native-session-hardening/slice04-host-authority-tickets
- installed skills: /Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills/

## Required-reading manifest and intake

Before dependent edits record actual full text ranges and structured query
coverage, source identity/status, missing/conflicting input disposition, and a
source-cited contract readback in artifacts/execution.md. Recover truncated
output in contiguous chunks. Hashes alone are not reading/comprehension.

1. Required-full: this prompt, slice-plan.md, ledger.md, artifacts/native-adapter-
   recipe.md, artifacts/native-recipe-design-review.md and source-baseline.json.
   Required-full: shared C04 artifacts/native-authority-contract.md v1.3, SHA256
   ceabf500efd6d1b365c0b61e440247508905d373912e80682c64f0215d7ff8ec.
   It is the SINGLE binding wire/ownership contract. Recipe refines private port
   shutdown mechanics, not that contract. NR-01 resolved; NR-02 serious/open X03/C06.
2. Required-full: source AGENTS.md, apps/cayrn_lfe/AGENTS.md, planning AGENTS.md,
   Project10 AGENTS.md. Required-section: project-plan.md Current independently
   accepted resource result, node-authority decision/sequence, preview decision;
   Arc02 arc-plan.md Autonomous Mode activation/current authority and roadmap.
   Earlier one-contributor/hold text is historical under later dated authority.
   Historical/Operator gates retain their meaning.
3. Required-full: collaboration-framework/SKILL.md; its knowledge/project-
   management/guides/README.md, work-verification guides01-ledger-discipline.md
   and05-independent-verification.md, testing03-validation-gates.md.
   Required-section: methodology01-engineering-methodology.md Autonomous Mode;
   PM02 iteration preservation, PM03 issuing/executing iteration. Load actual
   installed2.8.0, not a paraphrase or a stale substitute.
4. Required-full: /Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md
   (896 lines at author review); installed erlang-guidelines/SKILL.md.
   Required-section of its guides: PC-02/03/07/14, BEH-04/05/06/08/10,
   SUP-04/05/09/13. Resolve actual named headings through entrypoint. Apply private
   typed records, fast callbacks/monitor identities, OTP failure domains, and
   explicit LFE equality guards. Nested patterns may shadow rather than compare.
5. Required-full source: apps/cayrn_lfe/src/{cayrn_lfe_context,cayrn_lfe_listener,
   cayrn_lfe_sup,cayrn_lfe_io}.lfe and cayrn_lfe.app.src; test/{cayrn_lfe_resource_tests,
   cayrn_lfe_io_tests,cayrn_lfe_application_tests}.lfe; src/cayrn-lfe-eval.lfe;
   apps/cayrn_lfe/{README.md,Makefile,rebar.config}, root bin/cayrn-lfe,
   mk/lfe.mk and mk/rust.mk. Existing evaluator/collector logic read-only here.
   Required-section rootREADME native agent/startup and Cayrn consumer instructions.
6. Required-full shared source: Cayrn crates/host/src/authority.rs;
   protocol/src/lib.rs complete agent module and lease/ticket codecs;
   cli/tests/support/mod.rs +native_agent.rs. Required-section host/src/agent.rs
   prepare/Ready validation, output/outcome/loss/control lifecycle; C04
   cdc-verification.md Current accepted verdict through final limits. C04 earlier
   failures reference-only unless needed to interpret current observer logic.
7. Required-data: reconcile ALL15 baseline files SHA256/null, actual HEAD/branch/
   worktrees/status/diff, preserve docs/design/. Reconcile accepted Cayrn HEAD
   and immutable contract hash. Query all supervisor child APIs/callers and
   handshake/test helper references before changing them. Query/discover actual
   tests rather than copying expected counts as results.
8. Rust-only if editing Rust (not authorized now): load rust-guidelines first.
   No Rust implementation changes are in this scope. Existing Rust integration
   commands are execution/verification, not permission for source changes.

## Implementation route — resolved design

Follow full shared contract§§1–4/6 and native-adapter-recipe.md. Private helper
names/record layout may be chosen within these fixed behavior/ownership bounds.
Do not redesign protocol, leasing, limits, loss semantics or widen source scope.

- Add registered registry gen_server before listener, fresh cryptographic boot,
  last-lease scalar, max16 live authorities and64 globally live/retiring contexts,
  live SID index and exact PID/ref monitors. No cumulative ETS/tombstone/history.
  Canonical positive decimal1..i64MAX,128-byte ID grammar, exact scope/domain
  checks. Consume increasing valid ticket before SID/capacity refusal; bad scope
  cannot consume somebody else's ticket. Exhaustion never wraps.
- Router owns initial packet4 socket and5s deadline; paused endpoint role starts
  fast, socket transfer precedes activation. Ownership sentinel distinguishes
  transferred socket from router-owned socket on EVERY failure. Authority raw
  packet0/active-once after Ready; ANY byte/EOF/error loses that authority.
  Context admits before env allocation/Ready, retains separate native scope.
- Native registry admit also takes live context port and validates its actual
  controlling PID==gen_server From caller. Retire lease FIRST on exact owner DOWN;
  abortive authority-loss-only linger{true,0} then close each recorded context port,
  caught port_close fallback on setopts failure/already closed. NO false/default-
  linger close on this path (can wait180s); no synchronous context stop/kill.
  Send exact registry-owned loss notice asynchronously; physical credits remain
  until context DOWN. Closed/reset/EOF is LOSS/uncertain tail, never Close barrier.
  Ordinary Close/drain/ACK is unchanged; no globally abortive socket option.
- Listener before-accept temporary-child count excludes two permanent roles,
  admission watermark128; at capacity bounded retry WITHOUT accepting. Router
  creates≤1 endpoint for SAME socket, yielding hard128accepted-socket/256temporary-
  process bounds. Retiring roles count. Perconnection failure stays local;
  permanent failure remains one_for_all/freshboot. No registry→supervisor sync
  cycle. Addcryptoapp, preserve native0.1.0/xrepl0.2.0/legacy startup separation.
- Update existing peer helpers to retain authority and discover actual context
  child by module/spec, not allchildren-minus-listener. Preserve all21 existing
  native/resource cases and real1024 sustained behavior. New authority_tests must
  be an explicitly discovered io_tests companion. No product debug endpoint.

## Discriminating tests and limits

Implement all canonical§6 native tests, not a sampled subset:4097context cycles
(exact physical reclamation each),33authority cycles; final usable evaluation;
old tickets/leases/boots, duplicate live SID and crossscope/no source sideeffect;
16/17authorities,64/65contexts/refusedticketconsumed/recovery; unknown/wrongref
DOWN; counter exhaustion; firstframe/local failures/timeouts/ownership-transfer
failure with otherlease usable. Assert bounded LIVE state and increasing scalars,
not merely that creation returned. Native wrapper validation errors stay local.

Authority-loss tests retain raw context client sockets, active root/collector and
trace identities while closing/sendingonebyte only authority; all its exact owned
resources terminate and peerlease evaluates. Context-only loss remains local.
Two complementary port-disposal tests are REQUIRED:
1. Known START output/ACK, suspend context, lose authority, observe transport loss
   BEFORE resume; leasegone/contextPIDalive/SIDcreditheld, otherlease usable.
   Guaranteed finallyresume then exactcontext/root/collectorDOWN/tracecleanup.
2. Real nonreading client/smallactualbuffers; bounded source≤32asyncio_requests
   of8000chars thenwaitrelease; source<8192,pending<64. Observe actualsend_pend>0
   through retirement decision; no sleepaspressureproof. Retire onlyauthority,
   no clientdrain or sourcerelease to help; require registryresponsive, otherlease
   evaluation and exact owned cleanup/credit. External bounded watchdog and
   guaranteed ownedpeerfailurecleanup. Failure to establish positive pressure is
   failed/blocked, NEVERpass. Preserve source-reasoned no-waitbranch review too.
These tests distinguish notify-only, premature-credit and waiting-close defects.

NR-02: pre-existing forced supervisor teardown under blocked socket send can
orphan unlinked root. Serious/open, X03 ordinarypressure/rootowner +C06composition
blocking owner. DO NOT claim broad teardown readiness or smuggle collector/
evaluator repair into X02. Still prove this slice's normal authority-loss cleanup,
registry restart/freshboot in supported nonblocked controls and exact listed rows.
No usernode/sandbox/background-sideeffect/heaprestore/physicaldurability claim.

## Exact15-path source allowlist

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

Private include is optional; all other scope as listed. No evaluator/collector
implementation, legacy,Rust,build,launcher,version,lock,dependency/standalone edits.
No edits to Cayrn source or its plans. If an actual upstream defect blocks gates,
report exact evidence to CDC instead of fixing it in this assignment.

## Gates, commit and complete return

Run make help. Native component make check; root make test-lfe build-agent
check-agent build lint-rust test-rust. In matching Cayrn UNSET CAYRN_LFE_DIR,
XREPL_DIR,XREPL_BIN,CARGO_TARGET_DIR and run make check lint-integration test-xrepl.
All17real optional cases must ACTUALLYrun:14native(including4097publiccontexts,
twoHostlossisolation and1024sustained) +3consumer/PTY. Missing prerequisites are
failures/blocks, not greenskips. Actual terminal build path must be rootrelease
checkout; no stalebinary/standalone fallback. Distinguish ordinary/native/consumer/
uniqueEUnit/repeated/rootlegacy/Rust/doctest/CT populations, failures and filters.

Fresh source-only native component, tracked source/new files copied with no
_build/.beam, make check. Root launcher from/private/tmp with spaced socket;
actualnative3authority/context/eval/Close, exactnativeonlystartedapps includes
crypto ANDcompiler (LFEdependency), nolegacy/Ranch. Record source hashes/oracle.
Existing X-PKG-01 checkoutpathspaces and X-DOC-01 historicalplaceholder limitations
stay disclosed; no scope expansion. Changed Bash fences0..3indent bash-n, local
links, diff--check, exactallowlist, bothcommittrailers and candidate hashes.

Keep every command rawlog/exit including development failures, filters, unrun
checks and incomplete capture; no fabricate recovered logs. No loopuntilgreen
without diagnosis; consequential changes/new scope go to CDC. Source commit with
explicit reviewed changed-file subset of above15; preserve existing staging and
docs/design/. Both trailers required:
Co-authored-by: Codex <noreply@openai.com>
Co-authored-by: Billo AI <ai-engineering@billo.systems>
No push/merge/publish. Source and planning separate. CC may write only this slice's
artifacts/execution.md, raw logs, source-candidate.json/fullbinarypatch, complete
artifact inventory, closing-report.md and proposed ledger evidence. Never alter
issued prompt/contract/plan or manufacture CDC verdict. CDC commits planning.
Return all8 original rows with exact scope-as-specified/delivered and bubble-up,
actual source pin/SHA256s, paths, commands/exits/populations, failed attempts,
limits and explicit NR-02/X03/C06/preview owners. Initial return is attested
proposed done; root independently reviews/reproduces before acceptance.
Acknowledge assignment/intake and proceed under existing authority.
