# X04 CDC notes — in-flight, not acceptance

Actual reviewer /root, implementer /root/xrepl_x21. Source remains mutable;
this record does not replace final complete-byte review/reproduction.

Root read all four production drafts completely, and the six-test stream suite.
Frozen read-only independent review snapshot at /private/tmp/x04-inflight-review-01
records exact four hashes; reviewer /root/native_design_review assigned. No shared
builds run by root while CC owns mutable native tree/builds.

In-flight source findings against existing binding criteria, acknowledged by CC:
- Convert error tuple atom badarg must not enter binary Good-prefix branch.
- Recorded monotonic sealed proof must survive later rejected requests whose
  direct and trace messages temporarily mismatch observed/sent.
- Root and collector DOWN have different senders; retain both physical witnesses.
- Idle predispatch cancellation also needs the existing bounded stop deadline.
- Carry tests must split across our1024-source-unit prefixes, including both
  UTF16/32 byte orders; short split fragments exercise only OTP conversion.
- Record exact per-origin kill request before destructive stop. A result already
  recorded followed by expected killed root must not become spurious StateLost;
  unrelated abnormal death remains loss, finishing/publishing Cancel remains no-op.

Author-contract precision: iteration01 preserves initial prompt, differentiating
collector same-worker stream_done before DOWN from context cross-sender job_done/
DOWN inversion. Actual OTP28 signal reference supports this. Count1/5 executed;
not a prior accepted candidate defect or a reset.

Evidence population correction retained: stream suite six methods plus one
exported MFA fixture, not seven methods. First focused six pass; first combined
resource/stream20 run had two direct-fixture failures from stale owned EXIT/DOWN.
Final cleanup correction and full gates still pending. No false unique count,
old gate, cache freshness or root-pressure acceptance claimed.

Retrospective material, pending actual close: explicit event-order and dual-owner
source design caught errors before the full build gate. Responsive context and
collector must ship together for NR02; preview-only acceptance cannot carry that
claim. Keep full source/physical teardown and positive pressure as acceptance,
not narrative or helper message-only proof.
