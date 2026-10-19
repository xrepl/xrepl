# CDC X04 technical review — source complete, runtime gate pending

Actual reviewer/root, actual implementer/root/xrepl_x21. No product edits by root.
Initial complete four-module review snapshot manifest27b85d09; all four read fully
by root and separate early reviewer/root/native_design_review. Frozen production
snapshot-to-final diff has only context activation-granted flag/diagnostic plus a
comment; collector, stream and writer hashes unchanged. Final refreeze02 exact12
SHA256c6a706c8cc3334dce384ac193b94957a5e927b5750b5dc90219eed3f8a75c322.
Source commit and independent runtime results HOLD until actual CC return/root runs.

Root source coverage: all4 production modules complete plus complete final delta;
complete IO/resource/stream/ownership tests, authority changed enclosing definitions/
actual helpers, full componentREADME/AGENTS and affected rootREADME section.
Ownership1–EOF read at frozen59668ebe, controller797–845 recovered explicitly.
Resource after refreeze3759eda4 changed only isolated with-callback-state wrapper;
complete inner fixture retained/read. All other11 freeze hashes independently match.
All56 prior behavioral case names retained; companion generator is not a case.
Final76 static definitions =56prior+6stream+14ownership; runtime counts separate.

XS04-01: incremental explicit stack distinguishes root/tail/element, binary tails
and invalid root/improper integer/bit tails;1024 source units per conversion,
copy bounded validUTF8 prefix, carry at most3bytes. Final suite forces actual
UTF8/16/32 prefix boundaries, both endian modes, invalid prefix/EOF carry/encoding,
empty write and user-MFA exception. Output is never result-preview truncation.
XS04-02: one chunk/job; context stores exact pending job/worker/index/position,
writer-ref sent and ACK independent bits; collector continuation only after both.
Original reply waits done then exact normal physical workerDOWN plus trace drain.
Context separately waits cross-sender job_done and ownDOWN before returning credit.
XS04-03: global64 admitted jobs, local64 proposals/origin, writer68frames with
publishing+one deferred Dispatch bound. No arbitrary apply/conversion/socket send
in responsive owner callbacks; nested MFA jobs independent. Conservative temporary
credit retention is permitted, fake logical completion is not physical reclamation.
XS04-04: collector creates linked paused root, retains exact owner monitor through
unlink; context publishes actual root/monitor/trace before activation. Registered
root records survive result and independent root+collectorDOWN; both witnesses
needed. Registered formatter likewise has two owners before apply. Each surviving
owner kills known user workers first; nontrapping paused/unregistered workers are
linked and cannot execute arbitrary code first. Explicit trace destruction retained.
XS04-05: actual positive pending native socket pressure, trapping evaluator+MFA,
exact controller-owned monitors and externally retained trace are the required
oracle for collector/context/listener/registry/application failure. No helping
read or released blocker. CC reports8751 send_pend; NOT root-reproduced yet.
XS04-06: publishing/deferred token consumed once, activation only exact writerSent;
capacity checked then; Close/exact deferredCancel cannot later execute source.
Computed/finishing cancellation completion-wins. Known kill-requested bit permits
recorded root result then expected killedDOWN without spurious loss. New activation-
granted fact distinguishes provably unexecuted starting source only after rootDOWN.
Seal rejects every newly observed IO request while counting actual send witnesses;
recorded sealed proof remains monotonic. Normal Closed follows root/formatter/
collector drain, terminal send+writerDOWN before orderly context/physical credit.
Five-second incomplete barrier has no second indefinite flush; failure may EOF.
XS04-07: all mandatory full component/root/fresh/launcher/matching Rust cases remain
required. Source inventory76 is not execution proof; ignored test BEAM freshness
and real loaded exports/companions need actual gates. OS allocation injection unrun.
XS04-08: docs distinguish previews/complete output, native4/public1, trusted local
capture versus arbitrary user-process growth, focused X04 vs mixed C06, original
historical/package/UX/Operator gates and exact residual owners. No release claim.

Literal recipe order reconciliation: pending record is returned by same atomic
context callback after enqueue; it is published before context handles any response.
Formatter monitor is acquired before activation, callback state publication precedes
context response handling. No remaining correctness finding from those expression
orders; not a claim that expressions match recipe literally. Physical witnesses,
owner cleanup and exact ref validation remain unchanged.

Preserved refinements: iteration01 author clarified collector same-worker signal
order vs context cross-sender inversion (actual OTP28 reference); iteration02 P3
paused-start diagnostic mismatch found by independent early reviewer and confirmed
by CDC.2/5 executed. Root in-flight binary badarg, sealed proof, root+collector
physical bits, predispatch timeout, actual carry and expected-kill observations
were resolved inside the existing implementation contract, not prior accepted
candidate regressions. Full original criteria remain, no scope softened.

Gate attempt limits: version-only make REBAR='rebar3 -v' exit0 executed0tests,
INVALID runtime evidence. First final-root418executions416pass2failure were stale
foreign linked EXITs entering a later direct collector fixture. Refreeze02 isolates
that fixture in an exact monitored owned process and propagates assertion reason;
no arbitrary EXIT filtering or production relaxation. Failed attempt retained;
subsequent gates were UNRUN on that stopped attempt. Corrected full gates/root
independent reproduction still HOLD at this document's creation. No acceptance.
