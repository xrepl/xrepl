# X02 CC closing report — native3 authority lifetimes

2026-10-19. Actual CC Sofie `/root/xrepl_x21`. **Proposed done; independent CDC
acceptance is pending.** All eight ledger rows remain open. Operator-authorized
collaboration-framework2.8.0 Autonomous/Expedited Mode; executed correction1/5.
No push, merge or publication. Historical review/Operator gates stay pending.

## Candidate and delivered behavior

Source `/Users/oubiwann/lab/lfe/xrepl/xrepl`, branch `release/0.2.x`:
**38338d6ad38898fd24063b6c89582f0ff486aa30**, base `7228183e2e584e0ab86e03dc6b9454d4b918cc38`.
Unchanged matching Cayrn source `3bcbbdb9ec52667b6c75b7f8a5f2260b93d8be44`, branch
`codex/core-session-lifecycle`. Initial planning activation63f35f3; preserved
iteration01 issue76da3bb and disclosed ledger count reconciliation2b433a9. The
planning return is uncommitted for CDC review and separate planning commit.

Native3 now admits thin LFE contexts through monitored, bounded host-authority
leases and fenced tickets. Live/retiring maps replace cumulative identity history;
physical exact PID/ref DOWN releases credits. Authority EOF or any raw byte retires
only its owned contexts, including a suspended context and a positively observed
blocked send, while another host keeps working. Admission precedes native environment
allocation; exhausted/refused/stale scopes cannot perform the replay-marker effect.
No collector/evaluator implementation changed.

The existing OTP application helper owns the listening port for the application
lifetime. Registry/listener child restart reuses that same live port and absolute
endpoint with a fresh boot; real nonowner accept leaves accepted sockets owned by
the listener until handoff. This covers listenerkill and the observed LR-01 pending
parent-call ordering, including forced2s listenerkill. Startup acquisition and normal
application stop close/reap the owned port and only unlink its captured Unix socket
identity. Replacement regular file, symlink and different socket are preserved.

## Scope and preservation

Initial exact15 paths became16 ONLY through the reviewed, preserved iteration01
addition of cayrn_lfe_app.lfe. No acceptance criterion, wire3 policy, physical limit
or independent/Operator gate was removed. Delivered exactly these16 paths:

- `apps/cayrn_lfe/src/cayrn_lfe_registry.lfe`
- `apps/cayrn_lfe/src/cayrn_lfe_connection.lfe`
- `apps/cayrn_lfe/src/cayrn_lfe_authority.lfe`
- `apps/cayrn_lfe/src/cayrn_lfe_context.lfe`
- `apps/cayrn_lfe/src/cayrn_lfe_listener.lfe`
- `apps/cayrn_lfe/src/cayrn_lfe_sup.lfe`
- `apps/cayrn_lfe/src/cayrn_lfe.app.src`
- `apps/cayrn_lfe/include/cayrn_lfe_registry.lfe`
- `apps/cayrn_lfe/test/cayrn_lfe_authority_tests.lfe`
- `apps/cayrn_lfe/test/cayrn_lfe_resource_tests.lfe`
- `apps/cayrn_lfe/test/cayrn_lfe_io_tests.lfe`
- `apps/cayrn_lfe/test/cayrn_lfe_application_tests.lfe`
- `apps/cayrn_lfe/README.md`
- `apps/cayrn_lfe/AGENTS.md`
- `README.md`
- `apps/cayrn_lfe/src/cayrn_lfe_app.lfe`

Source diff:16 files,1969 insertions,163 deletions. Native app0.1.0/xrepl0.2.0,
two permanent roles, native bounds16 authorities/64 physical contexts and listener
128 accepted sockets/256 temporary roles remain. Rust, legacy modules, build/config/
launcher/locks, external dependencies, evaluator and collector implementations,
standalone predecessor and pre-existing untracked `docs/design/` remain untouched.
Required Codex/Billo AI trailers are present; staging is empty. Generated ignored
test BEAM removal is explicitly recorded below, not a source/build-scope edit.

[Candidate manifest](artifacts/source-candidate.json) holds all16 SHA256s and exact
pins; [binary patch](artifacts/source-candidate.patch) SHA256
`81730df7b3fe390685602912dfdeb982bc270fee81393f8a654a9246a411411e`. All committed blobs equal the frozen pre-gate bytes.
[Commit receipt](artifacts/source-commit.log) records exact commands/trailers/status.
Canonical native3 contract SHA256`ceabf500efd6d1b365c0b61e440247508905d373912e80682c64f0215d7ff8ec`;
listener ownership refinement SHA256`11c62368b0ca6ec7f47eadbda169ed023910d77d61e9ab8e632ce262c59471d3`.

## Eight-row attestation

Every row below is **CC attested proposed done, pending independent CDC**, not
self-acceptance. Concrete behavioral controls are in committed native tests;
full runtime/raw receipts accompany the claims.

| Ledger row | Delivered evidence / discriminating controls | Disposition |
| --- | --- | --- |
| XS22-01 | scope_and_numeric_fences, context-churn literal old Hello/visible marker absence, authority/context handshakes; wrong boot/lease/authority/version/ticket, noncanonical/overflow numeric and nonbinary/newline IDs; cross-lease negatives preserve each lease high-water; global live SID refusal consumes valid ticket | Proposed done; native-final-02 +fresh61 and matching native14 |
| XS22-02 |4097 exact-DOWN-reclaimed native contexts and33 authority cycles; bounded current maps, literal old first Hello refused, final42; independent public4097 archived-session case actually executes | Proposed done; churn tests +cayrn-full-final-01 |
| XS22-03 | raw EOF/one unexpected byte with context sockets held open; independent lease42; suspended-context EOF before resume while credits held; positive send_pend at decision, no client drain/root release; known roots/collectors/contexts exactDOWN and positively-present weak trace handle absent afterward | Proposed done for authority-loss path; NR-02 broader forced teardown remains serious/open |
| XS22-04 |16/17 authorities,64/65 contexts, valid refused-ticket consumption and recovery, duplicate SID across leases, wrong-ref knownPID and correct-ref unknownPID controls; exact physical release, exhausted counters, already-closed recorded context port | Proposed done; authority/resource full cases |
| XS22-05 | real paused transferred sockets for all3 roles, owner/ref cleanup and clientEOF,5s first-frame/startup deadlines, actual failed controlling-process transfer, preaccept watermark and conservative128socket/256role proof; app-owned listenport tested against listenerkill and LR-01 queued childspec behind observed registryEXIT, acceptedport owner==oldlistener | Proposed done; native/app lifecycle controls; no pending-output forced-Sup readiness claim |
| XS22-06 | All21 original unique native cases retained; registrykill/listenerkill and ordinary stop yield fresh boot, same app-owned listenFD/path/liveowner, old handle refusal/new42; relative startup plus evaluated cwd; app stop/restart exactportDOWN/pathremoval; actual callback replacement and acquisition-failure controls; exact native-only app set | Proposed done;61 final/fresh and actual root wrapper |
| XS22-07 | All full final commands below execute on frozen/committed16 bytes against unchanged accepted Cayrn; no real-case green skip, all14 native +3 consumer/PTY; root legacy/Rust/fresh/launcher checks | Proposed done; final-gate-results.json +runtime populations |
| XS22-08 | Exact16 candidate/patch/hashes, commit receipts, full inventory, all attempt failures/counts, correction/scope history and explicit residual owners | Proposed done by this packet; CDC parent/closure work remains CDC-owned |

## Final runtime gates and exact populations

[Final sequential command receipts](artifacts/final-gate-results.json) and
[population accounting](artifacts/final-runtime-populations.json). Frozen16 SHA256s
checked before and after every sequential full command; no source mutation during
a gate. All final required commands exit0; no final required gate held or unrun.
Four overrides `CAYRN_LFE_DIR XREPL_DIR XREPL_BIN CARGO_TARGET_DIR` unset for matching
host/root runner. Toolchain OTP28/ERTS16.4, Rebar3.27.0, rustc/cargo1.95.0.

| Command / context | Actual final result | Raw evidence |
| --- | --- | --- |
| component rebar3 as test compile, then make check |61/61 executions =44 unique +17 repeated authority cases;21 retained +17 new authority +6 new application unique; no failed case | final-test-precompile-01.log; native-final-02.log |
| Fresh source-only component make check |61/61, same44unique; inherited build/BEAM0; exact manifest and private include copied | fresh-source-final-01.log +manifest.json |
| Matching Cayrn make check lint-integration test-xrepl |43 ordinary +14 real native +3 consumer/PTY,0 failed/ignored/filtered; public4097,1024 sustained and twoHost loss execute; post native61, Rust7+1doctest,Clippy/fmt | cayrn-full-final-01.log |
| Root rebar3 as test compile, then make test-lfe build-agent check-agent build lint-rust test-rust |322 EUnit=175 legacy+147 native;44 unique native+103 discovery repeats; native module authority68/app21/resource42/eval12/IO4; CT0 explicitly; component61; Rust7+1doc;Clippy/fmt | root-final-test-precompile.log; root-full-final-01.log |
| Actual root bin/cayrn-lfe from /private/tmp with spaced socket | AuthorityReady3/Ready3 exact boot/lease/ticket,42, app set(cayrn_lfe compiler crypto kernel lfe stdlib),Closed,process0 | root-launcher-wrapper-final.log; root-launcher.log; root-launcher-process.log |
| Source/docs/runtime export checks | exact16 allowlist/blob hashes, diff--check0,≤80column LFE;0changed shell fences/0new local links; all9production+5test runtime module exports source-classified | final-static-checks.log; runtime-exports.log; runtime-export-classification-02.log/JSON; source-commit.log |

The runner's ordinary43 is2client+1core+15host-private+12host/tests/agent+
9host/tests/sessions+4protocol; CLI and fixture ordinary targets run0. xrepl's
Rust7 are adventure tests; core ordinary0 and core doctest1. Matching native14
and consumer3 are separately executed explicit targets;
zero-test binary/doc targets are not counted as substantive coverage. CT0 is not
coverage. EUnit discovery repeats are never added to unique counts.

## Failures and validation limits retained

[All attempt commands/exits/populations](artifacts/validation-attempts.md) and
[execution record](artifacts/execution.md) retain parse failures, failed control
oracles, initial listener lifecycle defect, every draft pass and current-byte
re-entry. Original native51/12,51/10,55/2; final native61/2 are not relabeled passes.
Focused17authority and7application attempts explicitly exclude the other cases;
final full native61 executes every unique case. No precondition failure becomes skip.

Pinned LFE macro exp_call_macro (lfe_macro.erl1082–1112, code:load_file at1101) can
load ignored source test/*.beam generated by the root profile before recompilation.
Final native attempt01 ran old parent helper await-startup-down while the peer
loaded current code,61 executions/2failures. Fresh source-only SAME frozen bytes
passed61/61. Exact old authority source-shadow SHA256
`eb1f291425c73e728e73a8baabb3ec3f4ea7bbd028ab60ca3e800614010ed91c` and targeted
14 generated-only removals are preserved in generated-beam-shadow-cleanup.log.
Separate component compile then native-final-02 passes61/61; separate root compile
then final root gate passes322. No blanket clean or build-config expansion.
Final generated-beam-identities-01/02 logs record current realpaths/hashes/exports:
all4 current authority beam paths contain paused-roles/0 and omit removed helper.
This is a disclosed validation/tooling limitation with CDC follow-through, not a
claim that stale-cache handling is permanently fixed. Pinned dependency car/cdr
warnings and sticky-dir json/gen_tcp/sys/trace probe reports remain, not warning-free.
One export classifier missed generated __info__/1 and was corrected against pinned
compiler source; a read-only postcommit inspection wrapper assumed one-line pretty
printing and was replaced by structured assertions. Both failures are disclosed.

All build/test raw logs exist; some initial reads/edits/exploratory source queries
are only in the tool transcript, not separately saved. No retrospective raw logs
were invented. X-PKG-01 pinned checkout-path-spaces hook and X-DOC-01 historical
shell-placeholder exclusions remain explicit. Source-only build proves no inherited
artifacts, not those excluded packaging claims.

## Residual owners, bubble-up and re-entry

- **NR-02 serious/open —xrepl X03, Cayrn C06 composition.** Forced supervisor teardown
  while context send is blocked can kill context before cleanup and orphan its
  unlinked root. Native3 abortive authority retirement is proven separately; app
  listening-port ownership does not fix ordinary-output/root ownership. Require
  positively pending listener/registry/app teardown, exact root/context/collector
  deaths/trace disposition/no falsebarrier and paused-root startup ownership there.
- **Cayrn C05 shared previews/native4; xrepl X03 pairing.** No preview implementation
  or public Outcome/consumer-Rust compatibility change in X02. Integrate only actual
  accepted paired contract later; composition stays C06.
- **CDC tooling follow-through:** source-generated test BEAM shadows and macro-loader
  cache can invalidate ordinary developer gates after prior root/test builds. Preserve
  this concrete causal case and plan a scoped repeatable freshness repair separately;
  no build tooling is smuggled into this source allowlist.
- **CDC parent/review/retro ownership:** independently reproduce committed pin, resolve
  rows, update arc/project ledgers and create mandatory closing retrospective in a
  separate planning commit. This CC does not edit parent or reviewer records.
- Whole helper/VM kill stale pathname, automatic app/BEAM restart, adversarial stat/
  unlink, generic runtime sandbox/heap recovery and fsync/powerloss are not promised.
  UX remains the previously tracked later project, outside this core hardening slice.

[Artifact inventory](artifacts/artifact-inventory.md) covers this CC return and
immutable supplied supporting inputs. Concurrent cdc-* verification logs are
reviewer-owned and will be inventoried separately at acceptance; this CC neither
hashes their active contents nor treats them as its own evidence. Source frozen
and committed; independent CDC review pending. No Operator gate bypassed.

## Subsequent CDC disposition —2026-10-19

CDC /root independently accepted all8 rows at38338d6/3bcbbdb after full current
source review, matching/root/fresh/launcher reproduction and71-entry inventory
reconciliation. The original CC pending wording records its return-time status.
See [verification](cdc-verification.md) and mandatory [retrospective](cdc-retrospective.md).
This accepts the bounded slice, retaining NR-02/size/output/composition/Operator gates.
