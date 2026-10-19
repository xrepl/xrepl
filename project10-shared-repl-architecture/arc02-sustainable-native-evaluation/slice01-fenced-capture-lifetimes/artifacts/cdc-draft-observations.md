# CDC observations during the first native implementation attempt

2026-10-18, CDC Sofie /root. These are review inputs to the ongoing first CC
attempt, not acceptance of a draft or a returned correction iteration. Final
verdict must inspect the returned candidate and its discriminating tests.

1. Startup acquisition: a paused evaluator is created before collector startup.
   If collector init/start or group-leader setup fails before state installation,
   terminate(previous-state) alone cannot own/kill that root. CC acknowledged
   explicit acquisition cleanup for paused root and collector/trace setup.
2. Root trace exit/delivery may precede evaluation_finished. CC acknowledged
   separate constant root-accounted and finished witnesses. Quiet publication
   must wait exact collector DOWN; background publication is separate.
3. Draft lexical shadowing: in command Cancel, nested case `(tuple _ _ operation _)`
   introduces a new binding over incoming operation. It must use distinct stored
   token and explicit equality so old/nonmatching cancel cannot kill a peer.
   The same scrutiny applies to nested let/case pattern operation and monitor
   names in capture/foreground_ready/retire_ready/sealed and collector DOWN.
   Same-clause function-argument repeats are not equivalent to nested lexical
   bindings. Requested actual LFE-semantic confirmation and targeted negative
   cases for old-token cancel with another operation active, token ownership and
   exact monitor-reference handling.

All points enforce the existing contract, with no architecture/scope/acceptance
change. First implementation has not returned; refinement budget is unchanged.

## Further draft review inputs, resolved before first return

- On successful command followed by socket-rearm failure, teardown must use the
  new resource-owning state, not the old state.
- Stale/future Cancel negative control must withhold foreground output ACK; a
 100ms sleep is not proof that cancellation preceded completion.
- Acquisition cleanup must observe exact DOWN for both root and collector; test
  spawn_opt on the real async request path and natural reclamation after ACK.

All addressed in7228183; see actual independent cdc-verification.md. These are
inputs during one CC attempt, not separately executed correction passes.
