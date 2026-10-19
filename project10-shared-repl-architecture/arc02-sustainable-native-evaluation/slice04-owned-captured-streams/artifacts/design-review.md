# Actual independent source/design review — X04

2026-10-19. CDC/root designed; actual reviewer/root/native_design_review inspected
source and private drafts read-only, no edits/builds/experiments. This is author
readiness evidence, not implementation or runtime acceptance.

Original ownership-only sketch had P2: collector-only kill while context blocks
in gen_tcp:send can strand a trap_exit root. Preserved X03 ownership-review.md
records rejection. CDC combined responsive context writer and collector formatter
work rather than exclude that failure from the promise.

Full streaming draft review found three concrete gaps before issue:
1. Cross-sender TCP/writer completion ordering invalidates an inferred two-Outcome
bound. Resolved explicit publishing plus one deferred validated Dispatch, single
token consumption, no source activation before exact writer_sent; Close/Cancel
cannot later release deferred source. Frame bound now follows explicit state.
2. Unlink before retire grant can leak collector/trace if context dies in gap.
Resolved exact owner monitor retained until physical collector stop, independently
of parent link, plus owned wrapper/externally retained trace negative specimen.
3. Sealed request branch skipped observed while trace counted sent; stronger seal
could then falsely time out on ordinary nested post-seal I/O. Count every request,
reject new admission, wait pre-seal jobs/root-accounted/sent==observed, not arbitrary
descendants. Add inversion/nested error specimens. All original duties retained.

The complete unissued draft SHA c5f8a815a598b80514c007a9487c03f51dafd5cf86aacf4f6f82357b19415e00
is preserved as unissued-stream-draft.md. Consolidation made expected root/
formatter/writer EXIT versus exact DOWN explicit and retained roots beyond result
publication, closing possible state-identity windows.

Reviewer read full initial consolidated contract SHA
3b93f9757a3f4359e08ac1c7fefa63b308904d0cf2a319f17d82ee1b69a83d98.
Literal contradiction: writer cannot be dead before sending Closed. CDC corrected
physical guarantee: root/formatter/collectors dead before Closed, terminal send+
writer DOWN before orderly context stop/physical context credit. Reviewer re-read
corrected sections at0d391ebec584c0bf19e3c8847aaeb7322a5f5bef0a8e177c52b5154aa44a59c2,
then added API map at final976ab5ff3301e1448ba4ae21e973c8636fe83960474f422d00bb962eb46adabc.
No remaining blocking contradiction found within source/design scope.

Actual native7427d1c inspected: context capture61–76,result77–86,unlink91–103,
genericEXIT143–144; IO sealed110–113/trace160–163. Installed OTP28.5 gen_server2393
runs debug {in,Msg} before handle_msg, sys877–890 supplies Name, not state, as Extra.
Startup gate feasible with owned peer controller; never sys:get_state the gated
context. Public policy/version unchanged; no source fix accepted by a design scan.
