# Slice01 CC implementation return — iteration01

**Proposed done; independent CDC acceptance pending.** Actual CC implementer:
`/root/xrepl_x21`; independent reviewer/CDC: Sofie `/root`. Assignment
`cc-prompt-iteration01.md`; initial prompt preserved. This is the first executed
implementation attempt, with no returned corrective iteration; refinement budget
remains zero of five pending review.

Source **7228183e2e584e0ab86e03dc6b9454d4b918cc38** on `release/0.2.x`, baseline
`f261152fc150a1addf3286a97b6a1a0324a42869`. Actual upstream Cayrn
**7b27b0f4a24d9dd85918fd590760b472a60798a3**, `codex/core-session-lifecycle`.
All seven committed paths match [candidate hashes](artifacts/source-candidate.json).
Source status after commit: only pre-existing untracked `docs/design/`; no other
source changes. Both required co-author trailers are present. No push. Planning
return commit remains CDC-owned, pending reconciliation/commit on orphan planning.

## Delivered behavior

Native2 accepts canonical positive sparse admission tokens and rejects old/native
replays before evaluation. A scalar fence replaces the historical seen map and
256-operation cliff. Valid attempts consume their token even when all64 live
origin credits are held: the exact ordinary Failed preview states that source was
not evaluated, with no collector/evaluator or environment mutation. External
producer release restores capacity for a new token; full-capacity close works.

Every collector is an OTP gen_server with its own isolated trace session. Paused
roots are traced before evaluation; local descendants inherit only this origin's
flags. Temporary producer birth/exit/delivery records, separate traced-send and
actual-request counts, and pending (From,Ref) durable ACKs prove drain. Root-accounted
and finished are separate constant witnesses, so notification ordering is safe.
Quiet results publish only after exact normal collector DOWN; live descendants
allow an earlier foreground result while preserving their immutable origin.
Retirement unlink/grant retains credit through DOWN. Forced close seals Live
origins, waits already Retiring DOWNs and pending ACKs, and handles finishing
without deadlocking on a natural grant that closing disabled. Unexpected collector
or root death still loses only its context. Acquisition failures and socket-rearm
failures retain explicit root/collector/trace cleanup ownership.

Rust remains the durable session/admission/operation/transcript authority. Public
client RPC stays1; native2 requires a matching host, with no native1 fallback.
The 4096 cumulative context-identity guard,8192 result/output constraints and
ordinary capture-pressure hardening remain the later Arc02 Slice02/03 owners.
No evaluator semantics, metadata/dependencies/launchers, legacy application,
Rust terminal, Cayrn source, standalone predecessor or UX change was made.

## Validation at the actual matching inputs

| Command / check | Exit and population | Evidence |
| --- | --- | --- |
| xrepl `make check-agent` |0;21 unique native cases,0 failed (7 preserved+14 resource) | native-tests.log |
| Cayrn `make check lint-integration test-xrepl`, no overrides |0;27 ordinary,12 real native+3 real consumer/PTY; component21; consumer Rust7+1 doctest; all passed | matching-cayrn-gates.log |
| xrepl `make compile-lfe build lint-rust test-rust test-unit-lfe test-ct-lfe` |0; build and Rust lint/tests pass;236 root EUnit executions, CT0 | xrepl-gates.log |
| xrepl final `make test-unit-lfe test-ct-lfe` after test refinements |0;236 EUnit executions,0 failed; CT0 | xrepl-final-lfe.log |
| Fresh19-file source-only native component `make check` |0;21 native cases; no inherited BEAM/_build | fresh-native.log |
| Root wrapper from/private/tmp, socket path with spaces |native2 Ready/evaluation/close pass; only native app/LFE dependencies started | root-launcher.log |
| Bounded documentation/format/scope checks |0;7 paths,4 LFE files<=80 columns,1 relative link,3 changed-scope shell blocks; clean diff | static-checks.txt |

Root denominator236 =175 retained legacy executions +61 native executions.
Native discovery is21 unique cases, with40 repeated executions in root Rebar
module/app composition; repetitions are not extra coverage. Consumer Rust is7
unit tests+1 doctest; other workspace targets discover0. CT0 remains the known
discovery gap and is not substantive Common Test coverage. Ordinary27 remain
OTP-free. No test is ignored or weakened to obtain the final pass.

The matching production integration gate ran after the final context/IO runtime
edits, including rearm cleanup. Subsequent changes were test-oracle strengthening
and documentation wrapping only. Context/IO bytes remained unchanged; final
component, fresh component and root LFE gates reran final test bytes. Earlier
ordinary/Rust evidence remains applicable because those sources did not change.

Runtime oracles include512 quiet sparse dispatches checking bindings, zero origin
credits after every outcome and no retained capture trace sessions;1024 real host
evaluations preserving a first-operation Unicode writer, dedup/retry and complete
paged transcript; raw replay visible-file non-execution, invalid/bound tokens;
64 held origins/65th non-evaluation and controlled release; all four spawn forms
with an asynchronous sender confirmed dead before ACK, natural reclamation after
ACK, and separate forced-close ACK blocking. Deterministic actual-handler tests
reverse finishing/trace-delivery and request/send-witness order, retain orphan
exit-before-birth, reject unknown commit/forged tokens/wrong monitors, and withhold
quiet publication until exact DOWN. Stale/future cancel is ordered before ACK of
`CANCEL-GATE`, with foreground completion then Succeeded42; it has no timing oracle.
Independent trace settings remain configured after capture teardown.

## Failures and retained limits

Development failures are recorded in [development-checks.log](artifacts/development-checks.log)
and [execution.md](artifacts/execution.md): initial LFE parenthesis errors and an
unsupported unless macro;17-case pass with5 fixture failures (PID prettyprint,
legacy trace entry, foreach arity);20-case pass with1 iolist-vs-binary fixture
failure;21-case pass with1 leftover test-owned monitor. All were corrected and
final gates passed. A source-cleanup compile failure and initial focused real
1-pass/11-filtered run exist in tool history; raw output was not separately
retained as a durable log and is not called independently reproduced.

One intermediate successful native run logged a sticky gen_tcp compiler/tooling
load diagnostic; it does not recur in final component/fresh runs. Fresh LFE2.2
build logs retain upstream cl.lfe car/cdr redefinition warnings; root legacy
warning reports remain visible. No new product compile warning was hidden.
The first source-only copy used a directory with a space; pinned Rebar/LFE hooks
split that source path and failed. The ordinary-path fresh copy succeeds; spaced
socket/root launcher behavior passes. This slice does not repair build tooling.
A broader README Bash syntax check initially failed on a pre-existing historical
`--token <TOKEN>` placeholder; final checks explicitly cover the changed intro
and full component docs. Historical examples were neither silently edited nor
reported runnable. Source-space support and historical placeholder examples are
not new native protocol guarantees.

Physical fsync/disk-full/power-loss durability, remote CI, registry publishing,
heap restoration, arbitrary user process/heap fanout bounds and live user-node
tracing were not run or claimed. The predecessor and prior independent/Operator
gates retain their existing meaning. Test-owned polling waits observe explicit
state/death properties with bounded failure time; no timer authorizes retirement.

## Opening-row walk

| ID | CC disposition | Attested evidence / constraint |
| --- | --- | --- |
| XS21-01 | Proposed done | Native2/canonical/sparse/replay/bounds and consumed refusal token tests pass; actual context has last-token scalar and no seen history. |
| XS21-02 | Proposed done | Native512 + matching integrated1024 pass; persisted binding/dedup/replay and early-origin writer remain correct at exact pins. |
| XS21-03 | Proposed done | Producer/delivery/request/ACK state machine passes both-order, orphan and sender-exit tests; quiet publication and credit require exact collector DOWN. |
| XS21-04 | Proposed done |64 held/65th exact Failed preview, no pressure-mutated binding, consumed token, release/recovery and full close all pass. |
| XS21-05 | Proposed done | Actual late output/ACK/close/cancel and node/host/context failures pass; forged token/monitor/unknown commit controls fail without false ACK or peer interruption. |
| XS21-06 | Proposed done | Scoped trace isolation and teardown pass; gen_server record/spec/docs/API conventions inspected; no global tracer, history map or retired-PID set. |
| XS21-07 | Proposed done | All required matching native/client, native/fresh/root and legacy/Rust gates pass with disclosed21/236/27/15/7+1/CT0 populations. |
| XS21-08 | Proposed done | Exact7-path source commit/candidate/patch, complete8-row attested return, failure logs/inventory and residual owners retained. |

All8 opening rows are accounted for; no deferred/no-op row or silent scope
reduction. Ledger remains open pending actual independent CDC review. No formal
arc/project/historical acceptance is asserted by this CC return.

## Source and planning paths

Exact source commit paths (seven): README.md; apps/cayrn_lfe/AGENTS.md;
apps/cayrn_lfe/README.md; apps/cayrn_lfe/src/cayrn_lfe_context.lfe;
apps/cayrn_lfe/src/cayrn_lfe_io.lfe; apps/cayrn_lfe/test/cayrn_lfe_io_tests.lfe;
apps/cayrn_lfe/test/cayrn_lfe_resource_tests.lfe. Candidate hashes and full patch
are retained. No manifest/lock/evaluator/build/launcher/Rust/legacy changes.

CC planning changes: this closing-report.md, ledger.md, and the artifacts below.
CDC owns planning commits, parent updates, reviewer record and retrospective.
Issued prompts, slice/arc/project plans and existing baseline inputs are intact.

## Artifact inventory

CC-produced under artifacts/:
- execution.md — acknowledgment/intake, full-population reconciliation, contract
  readback, source/evidence identity and failure/validation/self-review notes.
- source-candidate.json, source-candidate.patch — exact7 paths/commit/hashes and diff.
- native-tests.log — final21-case component execution.
- matching-cayrn-gates.log — full ordinary/lint/15 real/consumer/native gate.
- xrepl-gates.log — full source build/Rust/legacy gates.
- xrepl-final-lfe.log — final test-byte EUnit/CT reproduction.
- fresh-native.log — source-only ordinary-path fresh build/tests, upstream warnings.
- root-launcher.log — actual native-only application list, spaced socket and close.
- static-checks.txt — scoped shell/link/style/allowlist checks and exclusions.
- development-checks.log — consolidated intermediate failed/successful attempts,
  fresh source-space failure and disclosed non-durable/raw-output limitations.

Pre-existing source-baseline.json and planning-validation.md are preserved.
CDC-owned cdc-draft-observations.md is a concurrent supporting artifact; CC read
it but did not author/edit or count it as independent acceptance. First-class
prompts/plan/ledger/closing report remain outside artifacts/ by convention.

## Bubble-up to the arc

1. Arc02 Slice01 delivers its assigned piece at the source commit above: native2
   fencing, producer-aware collector retirement, explicit recoverable64-origin
   pressure and complete matching actual host/terminal integration. This removes
   the per-session operation cliff and discharges C03's held native runtime gate
   after CDC reproduction; it does not establish whole-node sustainability.
2. No architecture or scope change was required. CDC draft observations improved
   ownership/lexical guards and discriminating tests within the existing contract.
   Existing source-space Rebar hook limitation and historical README placeholder
   syntax are disclosed tooling/documentation observations, outside this slice.
   Arc02 Slice02 must resolve node authority/tombstone retirement; Slice03 owns
   safe previews/output chunking/pending pressure; Cayrn Arc01 Slice04 composes
   all three. CDC decides any roadmap update before subsequent planning.
3. Scope-as-delivered matches all seven paths/eight rows. No automatic retry,
   native1 fallback, tombstone eviction, user-code sandbox or UX change is hidden
   in the delivery. All applicable required runtime gates ran; remaining physical
   durability, Project09 and Operator gates retain their prior owners.

Independent cdc-verification.md and mandatory Autonomous Mode
cdc-retrospective.md are CDC-owned pending actual review. This is an author
attestation, not an independent verdict.

## Subsequent actual CDC disposition — 2026-10-18

The original CC proposal above is preserved. Sofie /root independently reviewed
and reproduced the candidate, accepting all8 rows; see [CDC verification](cdc-verification.md)
and the separately required [closing retrospective](cdc-retrospective.md).
Matching native2 gates now discharge the runtime hold in Cayrn C03. Parent
node/size/composition and Operator gates remain open.
