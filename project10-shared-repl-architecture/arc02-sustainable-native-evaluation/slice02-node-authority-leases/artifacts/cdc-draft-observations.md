# CDC draft source/test observations —2026-10-19

CDC Sofie /root read uncommitted first production draft and initial authority
fixture while actual CC /root/xrepl_x21 implemented X02. These are development
review inputs within the initial attempt, not executed correction passes or an
implementation verdict. Changing source is not called a stable candidate; final
committed bytes require full re-read/reproduction. Tool history preserves actual
snapshots; no unavailable hashes/line receipts are fabricated.

Production inspected: registry152+private header28; router68; authority61;
listener77; supervisor49; context activation/new native3 admission/cleanup plus
unchanged existing execution paths. Initial authority tests1–665 complete.

- Regex$ can accept a final newline; require exact ASCII whole-ID grammar,
  bytewise or absolute-end, with newline/nonbinary negatives/peer preservation.
- Initial caution about abort-port closed-port exceptions was source-checked:
  installed inet1570–1580→prim_inet1023–1031→ctl_cmd2962–2976 catches port_control
  errors into error/einval; closed recorded port remains is_port. close_port268
  catches port_close. No unsupported exception-wrapper defect was asserted.
  Keep actual closed-recorded-port retirement control with retained credit.
- Private open originally could register multiple different authorities from one
  caller PID while retire-owner handled a single match. Real authority role calls
  once; CC should keep that invariant explicit/robust. No new remote wire policy
  or hostile-local-code sandbox promise introduced by the observation.
- compile-01 exit0 has sticky-dir json/gen_tcp ERROR REPORTs; classify/preserve,
  do not claim warning-free compilation.
- First native-check-02 had failed new controls; CC diagnosed atom/binary override
  fixture and trace absence oracle, plus actual listener restart path cleanup.
  CDC agrees listener trap_exit lets gen_server terminate dispose owned endpoint;
  real registry/listener restart freshboot/oldhandle controls required. Positive
  send_pend observed before failed trace check is partial, not passing gate.
- Pending-output test initially ACKed START before sys:get_state active snapshot,
  racing context's later blocked send. Capture root/collector/trace BEFORE ACK;
  after ACK only external port stats/registry controls until authority retirement.
  CC independently identified the same observation race and is correcting it.
- Scope test must positively verify other lease's ticket1 after invalid scope,
  global duplicate SID across leases consumes valid ticket2, same refused ticket
  cannot retry under new SID, ticket3 recovers. Wrong-ref existing PID DOWN alone
  misses wrong-PID/real-ref case; add that no-credit negative. These distinguish
  plausible incorrect registry implementations under existing criteria.

NR-02 remains serious/open X03/C06. No source edits by CDC, no acceptance, no
Cayrn source mutation. Full real gates, fresh source and exact candidate review
remain required after actual return. No earlier failed observation is made green.

## Trace oracle clarification during initial attempt

The post-failure replacement used lists:member(strongTraceHandle,
trace:session_info(all)). Installed OTP trace.erl153–166 defines strong handle
as{Ref,Weak}, weak as{atom,integer};1460–1477 documents all returns WEAK handles.
Direct strong-in-weak comparison is alwaysfalse and would pass vacuously. CDC
requested normalization to exact weak handle plus SAME predicate positive presence
BEFORE loss and absence AFTER exact root/collector/context deaths, in all affected
ordinary/suspended/pending controls. session_info(strongHandle) is invalid because
its argument domain is process/port/MFA/event/all, not a sessionhandle. Preserve
failed old calls and this caught-vacuous candidate; final passing normalized test
requires fresh execution. No earlier failed trace oracle is relabeled passing.
