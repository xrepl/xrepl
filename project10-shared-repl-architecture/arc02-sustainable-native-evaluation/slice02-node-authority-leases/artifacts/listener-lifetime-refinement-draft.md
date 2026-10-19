# Listener endpoint lifetime refinement — draft,2026-10-19

CDC Sofie /root. X02 development exposed that trap_exit handles ordinary
supervisor shutdown but not untrappable listener kill: its port closes yet Unix
pathname remains, blocking one_for_all restart. Native3 contract's permanent
registry/listener failure domain must not be narrowed away. This is a private
resource-owner refinement within existing15 source paths, no wire/Rust/limits/
permanent-role-count change. Initial prompt/common contract remain preserved.
Independent source/design review precedes a new preserved corrective prompt.

## Resolved candidate mechanism

Listener remains primary owner of listen port/path and its ordinary cleanup.
Registry additionally retains ONE bounded endpoint descriptor after listener bind:
listenerPID,port,path,file identity and exact port-monitor ref, plus gone boolean.
This is transient resource ownership, not context/history/tombstone state.
Record includes kernel file_info major_device/minor_device/inode plus Unix socket
mode/type; read_link_info avoids following replacement symlinks. Use private typed
record/shared include and kernel file.hrl include in allowed registry/listener.

Add private registry register_listener(Socket,Path) wrapper. Callback derives
caller from From, verifies current live port connected==caller, Path equals the
configured native application socket, actual file is Unix socket (mode&type),
and no previous endpoint registered. Record exact inode/device identity and
monitor(port,Socket) BEFORE replying. No supervisor call from registry. Listener
cannot complete init/start accepting or native Ready before this registration.
No remotely supplied path/port or new protocol/debug endpoint.

Listener post-listen init uses acquisition guard: if mode/registration or any
later init step fails before returning state, close the newly acquired port and
remove ONLY the exact owned socket identity if still present. init failure does
not invoke terminate, so explicit unwind is required. Ordinary terminate closes
port then uses SAME identity-aware unlink; no unconditional deletion of another
inode/file/symlink. Path directory is Operator-private/trusted local profile;
this is not a new adversarial filesystem authentication guarantee.

Registry normal callback on exact port DOWN marks gone=true and tries idempotent
identity-aware unlink. Wrong port/ref cannot unlink or clear descriptor. Retain
bounded descriptor if cleanup fails for later termination attempt; log failures,
never manufacture native readiness. Already-absent path is success. A different
inode/type is left untouched; no pathname probe that connects to an unrelated
service and no broad rm/retry-unlink in listener init.

Registry must trap supervisor exits so terminate callback runs. On termination:
- if endpoint already has exact DOWN proof, perform idempotent guarded cleanup;
- if listenerPID is still alive and no portDOWN proof, do NOT close/remove its
  live endpoint or wait for it (registry's own stop causes supervisor to stop
  listener afterwards; listener primary cleanup owns that route);
- if listenerPID is physically dead but its portDOWN is not yet consumed, wait
  ONLY for exact owned port/ref DOWN with a fixed≤1000ms deadline, then guarded
  cleanup. If deadline/errors, leave path and report failure, never delete a
  potentially live endpoint. This wait is termination-only within2000ms child
  shutdown, not normal registry control callback or lease expiry. Monitor proof
  precedes pathname disposal; no physical context credit freed by port closure.
The descriptor has no resource acquisition that outlives this native app.

Single permanent-child failure AFTER successful native startup is covered in
both directions: registrykill→supervisor normally stops listener (primary path);
listenerkill→supervisor normally stops registry (fallback already owns descriptor).
Both yield fresh registry boot/no old handles and a usable newly bound endpoint.
Simultaneous repeated destructive faults/restart-intensity exhaustion and kill
before successful endpoint registration are NOT arbitrary crash-proof filesystem
transactions. No powerloss/automatic BEAMrelaunch/pathauthentication claim. Initial
startup failure must still be surfaced, never a false Ready. Existing source had
no such crash guarantee; don't infer one from this bounded poststartup mechanism.

## Required behavioral/source controls

1. Real listener kill (not only external shutdown signal/gen_server stop) after
   authority/context Ready: exact old resources/roles DOWN, new registry+listener,
   new boot, old handles rejected, new context evaluates/Closes. Registrykill
   counterpart and supported ordinary application stop/restart remain. NR-02
   blocked-output forced teardown stays serious/open X03/C06, not hidden here.
2. Exact live port/identity present before fault; same cleanup predicate requires
   physical port DOWN. Wrong-ref/wrong-port monitor notice cannot remove active
   endpoint or disturb a live lease. Registry normal shutdown while listener
   alive cannot eagerly unlink live port (owned direct callback/source control
   without new product accessor, if needed).
3. Idempotent absent path. Owned peer deliberately replaces stale socket path
   with regular file or different owned socket inode before fallback helper;
   guard MUST leave replacement untouched. Derive fixture from real captured
   descriptor and exported actual callback/terminate, no product debug export.
   No arbitrary user filesystem modification; only private test directories.
4. Post-listen init registration failure uses explicit acquisition unwind: actual
   owned socket closed/path removed, no new registeredendpoint/lease leak. Error
   remains local startup failure, not fake ready. Use owned peer/private state
   controlled failure, not nondeterministic race or sleeps as proof.
5. Rerun all old/new native cases and full paired17real gate, fresh source/root
   launcher, root legacy/Rust gates. Preserve initial attempts/current-byte versus
   stale Rebar module observation; no earlier draft gate becomes final proof.

Exact scope remains initial15; new private registry API/record fields are allowed
there. Source changes not authorized from this draft; root issues preserved
iteration after independent review. No third permanent process, new fileoutside
scope, supervisor-call cycle, collector/evaluator repair or native4 preview work.
