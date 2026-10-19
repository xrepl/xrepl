# CC closing proposal — owned complete captured streams

2026-10-19. Actual CC Sofie `/root/xrepl_x21`; independent CDC `/root`.
**Proposed done within X04; all8 ledger rows remain OPEN pending independent
review/reproduction.** Continued CF2.8.0 Autonomous/Expedited authority is bounded
to Arc02, with no release/whole-arc/publication claim.

Source **`cf1f1a2d94f1e6f4cb6f867ab71c9537348faa31`** on `release/0.2.x`, from7427d1c; matching Cayrn
**`34af63eb9f07a0e019495378045852ad69d00284`**. Current preserved assignment
`cc-prompt-iteration02.md` at planning1ac11a0, initial/iteration01 retained;
executed refinements2/5. Exact12 source paths, four new, and eight CC return paths.
No Rust/protocol version/registry/listener/app/build/dependency changes. Native4/
public1 and package versions stay unchanged. Source committed with both required
trailers; stagingempty and only pre-existing `docs/design/` untracked; no push.

## Result and source-led reasoning

Complete supported chardata streams through copied, acknowledged bounded UTF8
chunks. A paused linked formatter owns conversion/user MFA;
a nontrapping linked writer owns network sends. Context and origin collector
remain responsive independent lifetime owners. Root/formatter registration precedes
activation; exact persistent owner monitors survive the retirement unlink gap.
Known user workers are killed before trace/collector/writer cleanup even when
user code traps exits. Original I/O success requires all durable chunk ACKs and
physical formatter disposition. Invalid suffixes preserve committed prefixes but
return badarg; capacity errors are ordinary/recoverable.

Context retains root and collector physical identities through both DOWNs; root
monitor alone is not trace drain. Independent sent/ACK, context job_done/workerDOWN
and terminal sent/writerDOWN bits validate exact references in either order. The
collector's same-worker done precedes normal DOWN; missing done is invariant loss,
not an invented grace timer. Current-only64jobs/68frames bound admitted helper work.
One deferred validated Dispatch consumes its token once, creates nothing before
Outcome send, and cannot execute after Close/exact Cancel; capacity is rechecked
at activation. Paused roots report proven source-not-evaluated cancellation after
physical root DOWN; activated destructive stop keeps its environment-discarded
diagnostic. Expected kill after recorded result retains completion-wins.

Strong seal counts every request, including unsupported/refused/post-seal ones.
A recorded seal proof permits retirement despite subsequent rejected-request/trace
crossings. Normal Closed waits owned root/formatter/collector deaths; context
physical-credit return additionally waits terminal actual send and writer death.
The five-second incomplete-close bound force-stops honestly Lost/EOF without an
indefinite second flush. Failure abortive disposal remains distinct from completed
normal Close terminal delivery.

## All eight original row dispositions

| ID | CC proposal | Concrete evidence/disposition |
| --- | --- | --- |
| XS04-01 | proposed done; OPEN | Stream large_chardata/encoding_carry/native_complete_output plus source explicit1024-unit walker, copied<=4100 UTF8 payloads (wire<=8192). Actual aliases and both UTF16/32 byte orders, mixed list/binary and cross-prefix carry concatenate exactly; immutable origin operation retained. |
| XS04-02 | proposed done; OPEN | Withheld actual native ACK, collector done-before-normal-DOWN negative/positive, context job_done/DOWN both orders, Output sent/ACK both orders, invalid suffix/EOF carry and empty write. Original reply only after every ACK and collector physical/trace disposition; context credit waits both exact witnesses. |
| XS04-03 | proposed done; OPEN | Global64 actual jobs across two origins;65th ordinary enobufs, withheld ACK retains64, exact completion recovers63 and healthy next output. Nested MFA emits INNER/OUTER without deadlock. Owners perform no network send or user conversion/apply. Current-only64job/68frame maps and one pending chunk/job; no lifetime history. |
| XS04-04 | proposed done; OPEN | Real sys pre-handler gates at origin_ready/activate_origin kill either owner with marker absent. Root and MFA trap_exit under collector/context loss, exact watched owned PID/ref deaths, retained external trace handle, actual unlink-without-grant owner kill. Source acquisition rollback reviewed; OS allocation-fault injection explicitly unavailable/unrun. |
| XS04-05 | proposed done; OPEN | Positive send_pend=8751 observed before collector-only/context-only/listener/registry/application failure. Root and active MFA trap_exit=true; all known root/formatters/collector/writer/context watched for exact physical DOWN; known trace present before and absent after. No client drain or user-blocker release to help failure cleanup. C06 broader composition remains separate. |
| XS04-06 | proposed done; OPEN | Deferred Dispatch token consumed once/no actor before Outcome writer_sent; canceled source marker absent; third pipeline invalid;64origins rechecked at deferred activation; computed stale/current/future Cancel no-op. Four real acquired callback/socket preactivation Close/Cancel boundaries yield exact Cancelled(false) only after real root DOWN; activated diagnostic and result/expected-kill completion-wins retained. Strong seal both request/trace orders plus post-proof rejection race; terminal sent/DOWN both orders. Positive-pressure Close delivers504000 admitted bytes then physical Closed; perpetual hold and idle-future Cancel terminate bounded Lost/EOF without false Closed. |
| XS04-07 | proposed done; OPEN | All56 baseline native method identities retained;6stream+14ownership=76unique, actual root243native executions/167repeats plus175legacy=418. Plain component93, fresh93, full root/launcher/current20exports/BEAM identities. Matching Cayrn54ordinary+14realnative+3consumer/PTY; xrepl7adventure+1coredoctest. CT0, helpers excluded, final failed/ignored/filtered0. |
| XS04-08 | proposed done; OPEN | Exact12 before/after hashes, full171000-byte binary-safe patch, source commit, full readback/raw commands/failures and helper sources; all8 rows proposed done but OPEN until CDC independently accepts. Root assessment27finding owners preserved, no claimed quality closure. C06/tooling/package/docs/security/durability/UX/Operator holds explicit; no push. |

No row is deferred/no-op/dropped. The unavailable allocation-injection class is
explicitly unrun under the issued contract; acquisition guards were source-reviewed,
not falsely described as runtime injection.

## Actual final validation

Complete raw commands, outputs/exits, all12 per-run hashes, helpers and exact method
projection are in [validation.log](artifacts/validation.log).

| Final gate | Actual outcome |
| --- | --- |
| Current test precompile + plain component make check | exit0;93 executions/0failures |
| Root test-lfe/build-agent/check-agent/build/lint-rust/test-rust | exit0;418 EUnit=175legacy+243native, CT0, component93, Rust7adventure+1coredoctest |
| Fresh source-only component make check |93/0, manifest excludes all inherited _build/BEAM |
| Root launcher from/private/tmp | spaced socket/native4 scope/42/false/native-only applications/Closed/process exit0 |
| Actual runtime exports/identities |12production+8test, declared APIs match, generated exports classified, all loaded BEAMs hashed |
| Matching Cayrn check/lint-integration/test-xrepl |54ordinary+14realnative+3consumer/PTY; repeated component93 and xreplRust7+1; exit0 |

Native method population is **56retained+6stream+14ownership=76unique**; root
**243native executions=76unique+167repeats**, component93=76+17authority repeats.
Actual verbose identities match all76 source identities, not just a denominator.
Every authority method executes4x, IO methods2x, other native methods3x in root.
Cayrn ordinary54 comprises client3/core3/host-private19/host-agent14/sessions9/
protocol6 (CLI0), distinct from its14real LFE-native cases. xrepl core has0ordinary
tests and1doctest; the7ordinary tests are adventure. Final failed/ignored/filtered0,
required final gates unrun0. CT0 is empty and is not coverage.

Positive send_pend8751 precedes each collector/context/listener/registry/app fault
with trapping root+MFA. Exact known PID/ref DOWN and retained external trace
presence/absence prove disposal without client drain or user-blocker release.
Normal pressured Close drains504000bytes of admitted jobs then Closed; perpetual
hold and idle-future Cancel hit bounded loss without false Closed.

## Failed, invalid and held evidence

Preserved five compile failures (testcompile01/02/06/07/10) are fixture syntax/
form attempts with0runtime cases. Resource-focused01 ran20/2failed due stale owned
EXIT/monitor fixture selection; retry20/0. Ownership-focused01 ran12/1failed due
foreign fixture EXIT; isolated callback/socket cases then12/0. Ownership-focused03
ran14/1failed because evaluated fixture source had an extra delimiter, then corrected.
First final-root ran418:416passed/2failed, both repeated callback_order_inversions
consuming prior context/writer EXIT through a test catch-all. Only its allowed
resource fixture changed: monitored fresh mailbox per callback fixture, preserving
all inner actual root/formatter/trace/ACK assertions and abnormal assertion reason.
Production and the other11hashes stayed identical. Full refreeze02 gates then passed;
stopped downstream checks were unrun at first freeze and fully rerun at refreeze02.

`final-component-verbose` printed Rebar version only: exit0, **zero tests, INVALID
runtime evidence**, not counted passed/failed EUnit. The final2-component-verbose
label executes plain make check and actually runs93/0. Raw first invocation remains.
Planning staged whitespace check exits2 only on byte-exact unified-patch context
markers and two raw Make command trailing spaces. Source diff and six nonraw
return files pass whitespace checks; evidence bytes are preserved, no config change.
Sticky-dir json/gen_tcp/sys ERROR REPORTs remain disclosed pinned Rebar macro-probe
behavior; successful real gates are not described as warning-free.

X-TOOL-01 current test precompile, exact ignored source-test BEAM inventory/removal
and current20module identities plus fresh-source gate address current-byte proof;
permanent cache tooling remains Arc06. Checkout-with-spaces X-PKG-01 is separate
from passed spaced-socket launcher. X-DOC-01 historical shell placeholder remains
tracked, no new shell fences/examples/local links introduced. All source/tooling
limitations and real helper text are retained, not hidden in a success denominator.

## Scope, silent-drop diff and next owner

Exact12 source paths/hashes and full171000-byte binary patch are in
[source-candidate.json](artifacts/source-candidate.json) and
[source-candidate.patch](artifacts/source-candidate.patch), patch SHA256
`3c1969f14907187be17daf855f02dba19e1e809a9cf53bc89ab8f6cd8b5966ce`.
[Execution/readback](artifacts/execution.md), [intake](artifacts/intake.log) and
[support inventory](artifacts/artifact-inventory.md) account for exact8 returns and
all supporting inputs. Root-owned early snapshot/review and Project09 follow-through
are retained, untouched. They do not claim27assessment findings repaired. Concurrent
reviewer-owned CDC logs/returns are excluded from CC hashing and separately inventoried
by CDC; CC self-review is attestation, not independent acceptance.

**Silent-drop diff:**8/8 original row proposals,0new deferrals/no-ops/dropped rows.
Focused NR-02 single-owner/pressure and complete streams are delivered together;
no ownership-only acceptance substitutes for output. **Cayrn C06** still owns
sustained mixed/churn/large-value/two-observer/spool/storage composition before
whole-arc readiness. Arbitrary user-process heap/fanout, simultaneous owner destruction,
tracing tamper/remote/global I/O, unavailable OS allocation injection, production
security and physical durability remain outside this bounded proof. No arbitrary
descendant kill promise was added. Historical Project01/09/import/conversion gates,
packaging, later UX and Operator publication/acceptance gates stay pending.
Root independently reviews/reproduces/accepts and writes the mandatory retrospective.
