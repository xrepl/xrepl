# CC iteration01 — X04 completion/death precision

2026-10-19. Current assignment cc-prompt-iteration01.md, predecessor cc-prompt.md
issued at planninga1054e36729043ae85b788da0c610b2e79e5794f. Actual CC/root/xrepl_x21
identified an ambiguity during implementation before the affected branch was
finished. CDC/root clarifies it here; this is an author-contract precision, not
an independently reproduced product defect. All8 rows remain open, none accepted.
Execute the complete remaining initial assignment with this narrow precedence.

## Binding resolution

Initial contract §6 and §9 loosely bundled two distinct completion/death pairs:

1. **Collector receives formatter stream_done and that worker's monitor DOWN.**
The worker directly sends done to this collector before its normal exit, using
ordinary messages/monitors without priority options. Therefore normal worker
DOWN without a previously recorded exact done is an invariant failure/context
loss. Do NOT keep a normal-dead worker waiting indefinitely for missing done,
invent a grace timer, return success or release credit on DOWN alone. Record done
first, then require exact normal physical DOWN before original io_reply and
collector job_done. Abnormal DOWN is loss immediately. Expected normal linked
EXIT after done is tolerated; EXIT alone is not physical proof.

2. **Context receives collector job_done and its own formatter monitor DOWN.**
These have different senders and either order is legitimate. Keep independent
bits and hold admission credit until BOTH exact witnesses. DOWN first here is
NOT the collector's missing-stream_done fault: collector is independently
responsible for validating the worker's direct done first. Neither context
witness alone returns credit. Collector loss before completion is context loss,
not a missing-done timeout or fabricated ordinary error.

The REQUIRED done/DOWN inversion test in initial §9 means pair2, the context
credit reconciliation. For pair1 test positive done→normal DOWN (still no early
reply/credit) and negative normal DOWN without done. Do not force an artificial
collector-only reversed same-worker history and then require it to succeed.
All other cross-sender inversions (Output ACK/writer_sent, context terminal bits)
and initial criteria remain unchanged. No extra timeout, wire or resource policy.

The authoritative Erlang/OTP28 process reference identifies down as sent by the
terminating monitored process, and preserves signal order from one sender to
one receiver; absent priority reception, mailbox order follows signal order.
These facts support pair1, and do not establish order across pair2 senders.
See [OTP28 process signals](https://www.erlang.org/docs/28/system/ref_man_processes.html),
sections Sending Signals (down), Adding Messages to the Message Queue and Delivery
of Signals; checked2026-10-19, published docs28.5.0.8, local runtime28.5. This is
API verification for authorized implementation, not a new research project.

## Scope, reading and execution

Initial exact12 source paths/eight CC return paths, source7427d1c baseline,
Cayrn34af63e, branches, native4/public1, all budgets/tests/gates and trailers
remain unchanged. Source is an in-flight uncommitted X04 candidate; record its
current12 hashes/absence and Git status, not a new assumed committed baseline.
Do not edit original issued prompt or binding contract. This clarification has
precedence only for the ambiguous collector inversion/missing-done sentences.

Required-full this prompt, current slice-plan.md and ledger.md, original
cc-prompt.md and its complete required-reading manifest/binding contract.
Already actually loaded unchanged material in the same reliable context may
be retained with identity/extent recorded; a summary/receipt is not a substitute
on context recovery. Required-section actual affected collector/context worker
completion, EXIT/DOWN handlers and direct fixtures; inspect full definitions.
Required-data all12 current hashes/status and exact done/job_done/DOWN producers/
consumers; inspect complete query results. The OTP28 sections above are required
bounded API authority, not unrelated history. Record loaded extents, identity,
clarification readback and any truncation recovery in existing execution.md/
intake.log before affected edits. No new intake artifact or routine permission.

Connect XS04-02/03/04/06/07 to exact two-pair implementation and discriminating
tests; all other initial work/gates still required. Keep all56 prior unique cases
meaningful, no silent removal/relabeling. Full component/root/fresh/launcher and
matching14native+3consumer execute at frozen actual pins, no filtering/ignore/
compile-only substitute. Preserve failures and raw command/exits/helper sources.
Source and exact8 return separate reviewed explicit allowlisted commits, both
Codex/Billo AI trailers; no push/merge/publish. All8 statuses open until root
independent reproduction/acceptance/retro. Notify source freeze before shared
build gates. Return identifies this assignment and all8 remaining row dispositions.

Iteration01 is the first refinement after initial implementation began; record
executed1/5 when acknowledged/executed, no reset. Other authorized implementation
may proceed. Challenge a remaining contradiction before inventing new behavior.
No product failure, success or acceptance is asserted by this author correction.
