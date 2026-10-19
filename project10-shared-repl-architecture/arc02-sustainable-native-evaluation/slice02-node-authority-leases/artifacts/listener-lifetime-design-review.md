# Independent listener lifetime design review —2026-10-19

Reviewer /root/native_design_review, design author CDC /root. Read-only source/
API review, no builds/experiments/implementation verdict. Initial refinement draft
SHA2566f4de9c211e264c06e19a75a4a5397fc1674b0fa4308009e3d22c7b532b16d03.

LR-01,P2 blocking: registrykill may precede a pending listener→supervisor
count_children/start_child call. Installed supervisor.erl829–833 uses call infinity.
Supervisor one_for_all waits for listener shutdown, listener waits on supervisor;
after2000ms supervisor kills listener, skipping primary unlink. Registry is dead,
so initial fallback descriptor cannot help. This is an ordinary single registry
fault after startup, independent of NR-02 output pressure. Initial draft rejected;
no code was implemented from it and it must not be called sufficient.

Reviewer requires positively pending child→supervisor request behind registry
EXIT, guaranteed supervisor resume/owned-peer teardown, then usable restart.
Absolute configuration must remain startup-resolved THROUGH child restart;
recomputing relative config after evaluated file:set_cwd can silently rebind a
new directory. Port monitor exactref/object and read_link_info dev/inode/type
checks are otherwise supported; compare type bits, not chmod-sensitive permissions.

CDC subsequent source reading: application_master.erl276–278 traps exits;
297–307 calls Mod:start then continues SAME process in loop_it with AppState;
373–396 invokes Mod:stop after top supervision PID exits. Existing application
start callback therefore offers a stable existing resource owner outside the
one_for_all children, without adding a role/process. prim_inet accept0/async_accept
485–521 has no controlling-owner restriction and sends accept request from calling
acceptor, a standard borrowed listen-port pattern. New mechanism is separately
specified in listener-lifetime-refinement-v2-draft.md and requires fresh review.
This is source-grounded implementation design, not an approved comparative inquiry.

## v2 independent review —2026-10-19

Actual same independent reviewer /root/native_design_review read v2 draft
SHA25667785cdb14e50b5a086379d786a994cb272b4dd80b5b050b0211912718fa63cc and
review history02125f044a0981c0d2c2243e1e9b36d6635e5be9e67ae22b375401f767a6930f.
**v2 resolves LR-01 at design level; no further blocking design gap identified.**
Official installed gen_tcp.erl767–770 explicitly supports nonowner accept/multiple
acceptors; local_tcp156–169 delegates to prim_inet485–521. application_master
297–307/373–396 preserves same apphelper/AppState untilstop after Supdeath.

Before issue incorporate reviewed precision: capture identity BEFORE chmod; if
identity cannot be captured, close/reap without unconfirmed unlink; cleanup errors
need explicit logging because application_master catches/ignores stop outcome.
Force positively queued listener→supervisor race and retained absolute path/cwd
controls; assert actual listen AND accepted socket connected owners. Final binding
listener-lifetime-contract.md includes these. No code/build/experiment/runtime
acceptance from this review. Root owns final design/implementation acceptance.

## Early iteration01 production snapshot review —2026-10-19

The same independent reviewer read the actual three production modules and
binding contract after implementation: no blocking production gap found. Identity
capture precedes chmod; ordinary startup failures unwind; disposal monitors the
exact port before close and requires matching DOWN before identity-guarded unlink.
Listener borrows the port; supervisor restarts retain its original socket/path.

Reviewed SHA256s:
- App8999a457817de1bfd81726bf874accdb49bb81a8ab1c11bd1f065b2139de6833
- Listener5f7201969d9d7fe7d4537948669b9e08b2751628f4ff77e6c395bfc12863cc4d
- Supervisordb1fb6c3f4bfb14e05c209a337abee40f3f6b9478c9ef185e08e973be0581316
- Contract11c62368b0ca6ec7f47eadbda169ed023910d77d61e9ab8e632ce262c59471d3

No edits or builds by that reviewer. This is an early source snapshot, not final
committed-source acceptance or reproduced runtime evidence. CDC separately read
the current production and full555-line application test module; final candidate
reconciliation and independent runtime controls remain required.
