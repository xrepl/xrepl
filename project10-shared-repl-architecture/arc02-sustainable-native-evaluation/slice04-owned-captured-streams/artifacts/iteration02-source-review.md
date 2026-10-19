# Actual early frozen-source review — X04

2026-10-19. Actual reviewer/root/native_design_review, independent of implementer
/root/xrepl_x21. CDC/root independently read all four production drafts and agrees
with the narrow finding. This is NOT final candidate or runtime acceptance.
Full frozen source in inflight-source-review01, manifest SHA256
27b85d098594c30ffc0c2a34fed42be0498f4dbd5d96770997353913b1820d69.
Reviewer read1108 module lines, plus six manifest lines. Contract976ab5ff3301e1448ba4ae21e973c8636fe83960474f422d00bb962eb46adabc,
iteration01 153d34276a9017ecfa4429eec42141fce19fa3eb1224295c40344e1046869bc7.

P3: snapshot context454–460 Close/Cancel starting prevents activation and kills
paused root; root-down352–357 nevertheless emits generic evaluator-terminated
diagnostic, unlike deferred cancellation463–473. Existing contract§4 requires
known source-not-evaluated disposition separately from physical kill. No source
execution leak established. CDC selected retained activation-granted fact and
owned callback/socket stage permutations, physical DOWN still required, in
cc-prompt-iteration02.md. Do not require a queued TCP command to overtake a gated
current callback; root read actual resource fixture335–495 to derive viable test.

No additional source-backed terminal/cleanup defect established in this snapshot:
persistent owner monitor, root+collector DOWN, independent formatter credits,
sent/ACK, seal accounting, deferred publication and terminal writer sent+DOWN
reviewed. Complete runtime/pressure/control gates remain required.

Literal expression-order differences are causally equivalent, not findings:
Output enqueue precedes constructing returned pending state, formatter activation
precedes callback return. Atomic context callback publishes returned state before
handling resulting messages; actual formatter monitor already exists before grant,
and independent surviving-owner cleanup remains. This reconciles wording rather
than silently claiming identical expression order or waiving physical ownership.

Reviewer performed no tests, builds or edits. Snapshot review cannot accept later
changed bytes or replace final root review/reproduction and fresh arc composition.
