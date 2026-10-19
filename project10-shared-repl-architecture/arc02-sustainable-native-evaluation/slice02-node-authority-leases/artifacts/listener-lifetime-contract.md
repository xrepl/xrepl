# Stable application-owned listener — binding refinementv1.0,2026-10-19

CDC /root. Supersedes unissued initial registry-fallback draft rejected by LR-01.
No wire3/boot/lease/ticket/session/loss policy or2permanent-role/128socket/256role
limit changes. No new process, framework or third permanent child. Add ONE source
path to X02 exact allowlist: apps/cayrn_lfe/src/cayrn_lfe_app.lfe (16total). This
already-existing application boundary, not a new architecture component, owns
its listening resource across child restarts. Native captures/evaluator unchanged.
Actual independent source/API design review resolved LR-01; facts and exact
draft hashes are in listener-lifetime-design-review.md. This final contract adds
reviewed acquisition-order/diagnostic precision before issue. Canonical native3
wire/resource contract remains unchanged; this supersedes only its private
listening-port owner recipe and initial prompt's15-path allowlist with16paths.

## Concrete ownership and startup

Existing application callback start/2 executes in OTP application_master's
start_it helper and that SAME process persists in loop_it until application stop.
Source installed kernel10.6.3 application_master276–307/373–396 confirms this.
Keep the listening port owned by that existing application helper throughout the
application lifetime; do NOT transfer it to listener or supervisor. No new owner
process/registry descriptor/extra port monitor in registry is needed.

App start reads configured socket path and resolves absolute path ONCE before
resource acquisition. Bind packet4/binary/passive/maxframe/backlog listen port. IMMEDIATELY capture
and validate read_link_info file identity BEFORE chmod (major/minor device,inode,
Unix socket file-type bits; no mutable permission equality), then chmod0600. Store socket/path/identity
as explicit application State passed to stop/1. No process dictionary/persistent
term/global path rewrite. start/2 returns {ok,SupPid,State}. Local private typed
record may live in app module; reuse existing private include if justified.

Pass borrowed listen Socket plus absolute Path as supervisor:start_link/2 args.
Supervisor init/1 carries these immutable arguments into permanent listener's
start_link/2 childspec. One_for_all restarts reuse SAME live listening port/path;
registry still gets fresh cryptographic boot. Context/authority sockets remain
owned by their existing roles. Listener accept calls on borrowed port are allowed
by selected port-based Unix backend; accepted socket is owned by calling listener
and its router/role handoff remains unchanged. Required actual tests verify
ownership and nonowner acceptance, not a claim inferred only from source.

Listener init no longer binds/chmods/unlinks listening endpoint; it validates
borrowed port live and owner is not self, stores absolute path/socket, starts
bounded accept loop. Listener terminate NEVER closes/unlinks borrowed listen port
or pathname. It may trap parent exits for ordinary callbacks, but socket lifetime
must not depend on listener terminate, which untrappable kill skips. Registry is
unchanged by this endpoint-ownership mechanism. Existing count_children/start_child
calls may still be killed by parent after2000ms in LR-01 race; accepted sockets
owned by dead listener close, borrowed listen port/application owner survive and
new listener can accept. No helper spawned/detached to mask supervisor-call cycle.
No stale accepted port/session is revived across registry boot restart.

App startup acquisition guard handles ordinary bind/chmod/identity/Supstart
failure after acquiring port: close/reap acquired port then identity-guarded
unlink where identity was captured. If identity capture itself fails, close/reap
owned port, report startup failure and leave unconfirmed pathname; NEVER delete
without captured identity. Bind failure before port acquisition leaves existing
endpoint untouched. No false Ready or unowned supervisor. If supervisor was acquired and
subsequent work can fail, explicitly terminate/reap it before releasing resource;
prefer no fallible work after successful Supstart except returning complete State.
No source acquisition silently relies on terminate after failed init.

## Normal/failed application teardown and path guard

Application stop/1 runs after root supervisor death (installed loop_it source).
The existing application helper still owns listen port. Monitor exact port BEFORE
close, close listener port (has no evaluation/output queue), require exact ref/
port DOWN with fixed≤1000ms deadline, then read_link_info absolute path and unlink
only if dev/inode/filetype match captured owned Unix socket. Already absent is
idempotent. Replacement regularfile/symlink/different socket inode left untouched.
Explicit close/error handling; cleanup failure must be logged explicitly because
application_master catches stop/1 failures/ignores its result. Do not rely on a
returned error/raised exception alone as diagnostic or claim invented success. No generic unlink-existing-path in startup and no connecting to a foreign
service as a pathname probe. Trusted private directory profile, no adversarial
atomic-stat/unlink or arbitrary global-node sideeffect guarantee.

Whole application/helper/VM untrappable death can still leave a stale pathname;
no agent can execute finalization after wholeVMdeath. No automatic BEAMrelaunch/
filesystem transaction/powerloss claim. This increment guarantees registry or
listener child failure after successful native startup, including untrappable
kill, does not destroy/rebind the app-owned listening resource. Supervisor death
invokes existing app stop path and cleanup; no automatic application restart claim.

## Required discriminating controls

- Record listener port's real connected owner PID, prove≠listener/registry and live;
  real authority/context creation demonstrates nonowner accept. Kill listener:
  old endpointroles/context DOWN, fresh registryboot/newlistener, SAME listenPort/
  owner/absolutePath, oldboot invalid, new context eval/Close. Keep registrykill
  and ordinary child-stop controls; no narrowing from kill to gen_serverstop.
- LR-01: owned peer suspends supervisor, kills registry, positively observes old
  registryDOWN/queuedEXIT and a listener's actual count_children/start_child call
  pending BEHIND that EXIT. Resume guaranteed finally. Listener may hit real2000ms
  parent shutdown kill, but application-owned socket/owner MUST stay alive and new
  node state serves valid new context. Do not require normal listenerterminate
  as the cleanup proof; that was the rejected initial design.
- Start with relative configured path from private startupdir, evaluate/change
  nodecwd, fail registry/listener, prove SAME original absolute endpoint survives
  and replacementcwd has no unintended socket. Restorecwd/peerfinallyowned.
- Stop/start native application on same owned node/path: exactportDOWN before
  pathremoval, no root/child role loss hidden; supported nonblocked controls only.
  NR-02 blocked-output forced-context teardown remains X03/C06 serious/open.
- Identity guard actualcallback control: captured real port/state, independently
  replace owned stale path with regularfile/symlink/different owned socket, run
  actual app stop callback on owner test fixture, require replacementuntouched.
  Native test modules may use a real owned callback fixture/process, no product
  debugexport. Source/test method must not accidentally test only fake inode.
- Startup failure real owned bind/Supstart fault proves acquired port/path cleanup,
  no accepted protocol Ready and no leftover owned supervisor. Exactnew native
  population/discovery; fresh source and rootlauncher required. Full Cayrn43
  ordinary+17real, rootlegacy/Rust gates rerun on final bytes, no olddraft pass
  relabeled final. Preserve Rebar stale-module/explicit testcompile observations.

This binding refinement is issued through cc-prompt-iteration01.md after
independent v2 design review and CDC precision/readback. Exactly16 source paths
are listed there; all8 original criteria survive. This is executed correction1/5.
Earlier draft gates are retained as draft evidence, never relabeled final.
Native4/preview and NR-02 X03/C06 remain separate owners.
