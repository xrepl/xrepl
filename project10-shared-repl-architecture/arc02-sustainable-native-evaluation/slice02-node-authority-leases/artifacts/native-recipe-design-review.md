# Independent native adapter recipe review

2026-10-18. Reviewer `/root/native_design_review`; recipe/design author CDC
Sofie `/root`. Bounded read-only recipe/source review under existing Autonomous
Mode authority. No source implementation, experiments or C04 implementation
verdict. The reviewer read the complete adapter recipe, Slice02 plan and approved
canonical native3 contractv1.3. The common contract was not edited.

Input identities:
- Native recipe SHA256:
  `ee91ebfbdff3a3245e6847ab751d0f182d901c7bb320e84a02f713cc9707cfa5`.
- Slice plan SHA256:
  `8626f40a14ce694b49e111cff322ec9f8280439e5a3a83e43c2dd9cfa3cee254`.
- Canonical immutable C04 contractv1.3 SHA256:
  `ceabf500efd6d1b365c0b61e440247508905d373912e80682c64f0215d7ff8ec`.
- Native source `7228183e2e584e0ab86e03dc6b9454d4b918cc38`.
- Installed OTP28 kernel10.6.3 / erts16.4 source paths inspected below.

## NR-01 — P2, blocking: false linger close can block the registry

Recipe lines135–144 prescribe registry-side gen_tcp:close with false linger as
a nonblocking way to wake a context whose send callback is blocked by a slow or
nonreading peer. The cited inet option documentation says false linger returns
immediately, but the installed backend implementation does not guarantee that.

Actual call path: kernel gen_tcp.erl:867–870 delegates a port socket to
inet:tcp_close; inet.erl:4579–4582 calls prim_inet:close. In
erts-16.4/src/prim_inet.erl:173–213, the false/default linger branch calls
subscribe(S,[subs_empty_out_q]). When pending output N>0, it creates a180000ms
timer and calls close_pend_loop. That loop (215–254) waits for the queue to empty,
the timer, or periodic pending-output checks; kernel inet_int.hrl:282 defines
INET_CLOSE_TIMEOUT as5000ms. It may continue waiting while output progresses.

Concrete counterexample: one recorded context has pending driver output. Its
authority dies; registry handles owner DOWN, removes the lease and synchronously
closes that context port as prescribed. The false-linger close enters the
pending-output wait. Registry is then unable to process other owner/context
DOWNs or new open/admit calls during that wait. This defeats the intended fast
registry callback and other-lease admission/control isolation on the very path
that motivated retaining a shutdown handle.

The installed option docs and implementation disagree here. Reviewing only the
inet wrapper/docs is insufficient to establish the selected mechanism. This is
a static source counterexample, not a measured claim about a particular socket
queue or OS behavior. CDC must select/specify a truly immediate shutdown path
appropriate to this authority-loss boundary and reconcile its observable error /
EOF behavior. No alternative architecture is selected by this reviewer.

## Test discrimination

The proposed suspended-context test remains useful for mailbox independence and
monitor-held credits: suspend after a known START output/ACK, retire authority,
require transport loss before resume, retain physical credit until exact DOWN,
and keep another lease usable. Guaranteed resume/peer teardown on failure is
necessary so the negative control cannot strand its own fixture.

However, draining/ACKing START likely leaves an empty output queue; false-linger
close can pass that test via its empty-queue branch. That test alone does not
exercise NR-01. Preserve it, and add a source-grounded oracle or selected-close
API proof that distinguishes the potentially waiting branch. Do not relabel the
empty-queue suspension case as proof under all socket output pressure. General
output-pressure work may remain X03; the authority-loss path itself still needs
the nonblocking property required here.

## Other inspected portions

The private native refinement is otherwise coherent with C04v1.3: storing only
an admitted live port is transient control state, not a native durable journal or
wire/Rust API extension. Validate actual controlling PID against gen_server From
before admission, after router transfer; retain exact PID+monitor+SID correlations
and release credit only on physical context DOWN, never on port closure. An
already-closed port must be handled idempotently without crashing the permanent
registry or granting someone else's credit.

Current native context source7228183 performs synchronous output send at
context.lfe:51–63; tcp_closed handling is128, and terminate cleanup is338–350.
Thus merely posting authority_lost can indeed wait behind a blocked callback;
external port interruption is relevant. Context must still return through its
normal/error termination cleanup rather than an untrappable process kill,
because root/collector/trace ownership remains with that context. A suspended
context can retain those resources until resumed, and the recipe correctly
keeps its credits while alive.

Role separation, admission-before-env, registry-before-listener supervision,
router ownership sentinel, local failure handling and updated child-discovery
helpers remain within the approved native scope. The private API/record change
must be reflected in specs/callers/shared test record macros. No change to the
immutable common wire contract or C04 implementation verdict is implied.

Verdict for the reviewed recipe bytes: pending NR-01. No further blocking gap
identified in this bounded review. Future real paired/native tests and independent
implementation acceptance remain required; no runtime behavior was certified.

## Corrected recipe re-review — 2026-10-19

Actual independent follow-up by `/root/native_design_review`. Read the complete
corrected recipe/current slice plan and relevant installed prim_inet implementation.
No source implementation, experiments or C04 implementation review occurred.
The initial NR-01 finding and reviewed false-linger draft above remain history.

Exact inputs:
- Corrected native-adapter-recipe.md SHA256:
  `91d91ebe4412da5bb3a258b8180ce1ff247dc08f1e55eae4954fd5d5d35fc78a`.
- Updated slice-plan.md SHA256:
  `249fdefa63501f7a975aeae1ae8a54fff9e7efc8c8740f02f40b13cf072e42a5`.
- C04v1.3 common contract remains unchanged at
  `ceabf500efd6d1b365c0b61e440247508905d373912e80682c64f0215d7ff8ec`.

**NR-01 resolved in the corrected design. No further blocking recipe gap
identified in this bounded review.** CDC selected the revised mechanism; this
reviewer did not select an alternative architecture.

The authority-loss-only path first sets linger to {true,0}, then calls close.
Installed erts16.4 prim_inet.erl:175–177 routes that option to close_port directly,
bypassing its subscribe/close_pend_loop branches. close_port invokes caught
port_close (268–273); the prescribed setopts-error/already-closed fallback also
uses caught port_close, never default-linger gen_tcp:close. setopts1023–1031 and
ctl_cmd2962–2973 use port_control with encoded fixed options, without an Erlang
mailbox receive loop. send585–626 includes port-monitor DOWN/error returns,
providing the source-grounded interruption path for a blocked sender. Runtime
verification on the selected port-based Unix-socket backend remains mandatory.

The recipe now explicitly permits abandoning buffered native bytes ONLY after
authority loss, while promising only the committed Rust transcript prefix and
uncertain capture tail. It preserves ordinary/explicit Close drain/ACK semantics,
normal/error context termination cleanup, exact-DOWN credit and other-lease
isolation. This is consistent with the immutable C04 loss policy and does not
claim general X03 pressure completion or add a wire/common API.

The new bounded pressure control improves the oracle materially: a real context,
nonreading owned client, recorded actual buffer settings and positive observed
send_pend precede authority retirement; source/chunk/pending populations remain
within current limits. Failure to establish that positive precondition cannot
be a pass. At implementation review, ensure pressure is present through the
retirement decision rather than relying on one early transient pending sample;
use existing private state/fixture synchronization and report actual observations.
Do not drain client output or release evaluated source to make cleanup succeed.
The independent suspended-context test remains necessary for mailbox independence
and retained physical credits. Keep an external bounded watchdog/guaranteed peer
teardown so a deliberately wrong close path cannot hang its own test.

Abortive transport failure may surface as closed/EOF or a reset according to the
supported API/backend; assertions must recognize actual transport LOSS without
calling it a successful Close barrier, complete transcript tail or ordinary
outcome. No buffer-pressure timing or runtime result is asserted by this review.

The corrected unissued recipe is ready for the already-defined prerequisite and
implementation handoff. Exact actual C04 candidate/review consumption, independent
native implementation review, full paired runtime gates and existing acceptance
boundaries remain required. This disposition is design readiness only.

## Separate supervisor-teardown ownership finding — 2026-10-19

Actual independent source-only follow-up by `/root/native_design_review`, at CDC's
request. No experiments, runtime reproduction, source edits or implementation
acceptance. The corrected recipe/plan remain the exact SHA256 inputs recorded
above (`91d91ebe...fc78a` / `249fdefa...e42a5`); common C04v1.3 is unchanged.
The previous NR-01 resolution and its bounded authority-loss design verdict are
preserved. This finding concerns a different shutdown entry point.

### NR-02 — P2: forced supervisor teardown can orphan the foreground root

Concrete pre-existing source gap at xrepl
`7228183e2e584e0ab86e03dc6b9454d4b918cc38`: context traps exits
(context.lfe:18), invokes synchronous gen_tcp:send in its capture callback
(51–63,318–320), and starts its foreground evaluator with spawn_monitor rather
than a link (199–223). Its terminate callback is the ordinary owner which kills
that active root (338–342). A root may send bounded asynchronous io_request
messages and then wait indefinitely for an explicit release; that root does not
need to be blocked on a synchronous I/O reply to expose the ownership gap.

Installed OTP stdlib7.3 supervisor.erl restart(one_for_all),1477–1484, calls
terminate_children sequentially (1510–1521); normal supervisor terminate also
uses that function (1247–1250). do_save_child prepends new dynamic child IDs
(1758–1760), and children_map traverses them in that order (1887–1899).
Consequently a context created after its authority is stopped before that older
authority and the permanent registry/listener. shutdown1563–1585 sends shutdown,
waits the child's timeout, then sends untrappable kill. Current context child
shutdown is2000 (sup.lfe:8–13).

A pending-send context cannot dispatch the parent EXIT to gen_server terminate:
installed erts16.4 prim_inet.erl:590–625 waits on port replies/DOWN and does not
consume that parent EXIT; stdlib7.3 gen_server.erl:2373–2380 handles parent EXIT
only from its normal decode loop. After two seconds the supervisor kills it,
skipping context terminate. Its unlinked foreground root survives. Later registry
authority-DOWN handling and external port closure cannot repair a context which
already died without releasing that root. If the registry itself crashed, its
callback is unavailable from the outset. This applies to listener-triggered
one_for_all restart and application/supervisor shutdown while the node remains
running, not to OS/node death where the VM necessarily destroys its processes.

Do not overstate the leak population: the live collector is linked through
io.lfe:19–29 and does not currently trap exits, so context death normally kills
that collector through its link. This review does not establish that every
collector or trace session persists. The unlinked foreground-root counterexample
is sufficient. Root survival and exact cleanup must be observed in any runtime
control; socket EOF or fresh registry boot alone is not that proof.

### Scope and recommendation for CDC decision

The defect already exists in native2's listener failure/application-stop path;
native3 adds a registry-failure trigger, not the original ownership bug. Common
C04v1.3:97–99 retains registry/listener one_for_all as the shared native failure
domain. Its ownership recipe115–116 says not to skip terminate and leave an
unlinked evaluator alive, although that sentence appears within the authority-
loss paragraph and its test list does not explicitly enumerate every pending-
output supervisor-teardown combination. Therefore this finding does not undo
the reviewed authority-DOWN abortive-close mechanism or certify a new wire policy.
It does limit a general claim of teardown readiness. CDC must explicitly place
this ownership repair or retain the known limitation/dependency before claiming
that broader lifecycle guarantee; general ordinary output pressure can stay X03.

A narrow repair needs cleanup ownership independent of the context's blocked
mailbox/terminate and of registry survival, established before root execution.
CDC suggested assessing the existing collector as that owner. Source feasibility:
it already knows Owner and paused Root (io.lfe:57–69), is context-linked, and can
trap its parent exit so gen_server invokes terminate; that callback would also
need to kill the exact root. Normal context termination already explicitly kills
root/destroys trace before unlinking/killing collectors. A paused-root owner
monitor must bridge spawn through collector readiness and the evaluate handoff:
collector-only cleanup cannot cover context death before collector startup.
Natural collector retirement must preserve its current drained/root-dead proof.
This is a feasible direction to be chosen/refined by CDC, not reviewer-selected
architecture; collector edits require expansion of X02's present explicit
no-collector-change allowlist or a separately recorded later-slice dependency.

A discriminating owned-peer control should hold a known foreground root and
context, trigger real registry/listener failure or application shutdown, and
require exact context/root death without releasing the root or draining peer
output to enable cleanup. A suspended-context control can deterministically
expose the terminate-skipping path; a separately positively observed pending-send
control connects it to the actual socket case. Record the supervisor's timeout
and cleanup observations, guarantee owned-peer teardown, and distinguish loss
from a successful Close barrier. No such test was run during this review.
