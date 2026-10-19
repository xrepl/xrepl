# CC iteration02 — exact paused-start cancellation disposition

2026-10-19. Current assignment cc-prompt-iteration02.md; predecessors cc-prompt.md
and cc-prompt-iteration01.md remain preserved. Actual implementer/root/xrepl_x21;
CDC/root owns design/acceptance. Execute all remaining initial scope and iteration01
with this narrow additional correction. Refinement2/5 when acknowledged/executed;
all8 criteria stay open. This is a concrete early-source review finding against
existing §4, not new UX scope or a prior accepted-candidate regression.

## Finding and source-led correction

Read artifacts/iteration02-source-review.md and its complete pinned four-module
snapshot. Independent reviewer/root/native_design_review and CDC/root reproduced
the source reasoning: Dispatch leaves active starting; Close/Cancel handled before
activate_origin prevents activation and kills the paused root; root-down waits
physical DOWN but emits generic evaluator-terminated text. Binding §4 requires
known before-evaluation disposition separately from confirmed root termination.
No source effect/ownership leak was found in this branch; diagnostic facts differ.

Keep an exact per-origin activation-granted boolean, initially false. In the
not-closing activate_origin branch compute retained ownership state with this
fact true before granting collector activation, and return that state with the
existing executing tuple. Closing branch does not grant activation or change
false to true. origin_ready after Close/Cancel still registers then kills the
paused root with kill-requested; both physical root/collector witnesses remain.

When root-down produces the existing Cancelled(false) Outcome after destructive
stop without a recorded result, select the already used deferred diagnostic
`native request cancelled before evaluation; source was not evaluated` only when
that origin never received activation grant. Activated roots retain the existing
`native evaluator terminated; environment discarded` diagnostic. A kill signal
alone is not a physical-down witness and must not publish terminal success or
release credit. Retain result-seen/kill-requested race handling and finishing/
publishing completion-wins behavior unchanged. False activation is a proven
no-source-effect fact; true is permission granted, not proof of source progress.
Equivalent private representation is fine if it retains these exact facts.

Exercise Close and exact Cancel at both boundaries with actual owned callback/
socket resources (the existing closed_socket_retains_acquired_cleanup_state_test
and with-control-state show the acquisition route). Starting from the initialized
context, deliver a valid Dispatch through handle_info; it creates a REAL paused
collector/root and returns starting state. CaseA: deliver the Close/Cancel command
before consuming its actual origin_ready. CaseB: consume real origin_ready through
handle_info to register the actual root, but retain its self-posted activate_origin
in the test mailbox; deliver Close/Cancel before delivering that actual activation
message. Then process actual owner/root/collector/writer messages and monitors,
never fabricate DOWN or let a private boolean alone stand in for observable proof.
This direct owned-callback arrangement controls order without trying to make a
queued TCP Close overtake the currently gated activate_origin callback. Retain
existing real-peer sys:install startup fault specimens separately; do not call
sys:get_state on a gated context or add a product hook.

For all four paused variants, source marker never appears, exact Cancelled text
with preview false is observed after real root DOWN, and final cleanup/Closed or
destructive Lost remains correct. Include activated-root cancellation regression
preserving old diagnostic, plus existing completion-wins race. Integrate into the
planned ownership/resource tests; do not count fixture helpers as methods. The
incorrect current generic diagnostic must fail the pre-activation observation.
No new wire/version/policy/accessor is needed.

## Scope, reading, validation and return

Original exact12 source paths/eight CC return paths unchanged. Expected production
edit is context; ownership/resource fixtures already in scope. No new evaluator,
router/registry/listener/app/build/Rust/dependency/version changes. Source baseline
remains committed7427d1c with in-flight X04 changes, Cayrn34af63e. Snapshot and
iteration02-source-baseline.json describe mutable intake, not a new accepted pin.

Required-full this prompt, current slice-plan/ledger, initial prompt and complete
binding contract, iteration01, iteration02-source-review.md and its full frozen
source snapshot. Retain already loaded unchanged full required inputs only with
actual extents/identity; recover actual text on unreliable context. Required-section
live complete context activation/evaluate/begin-stop/root-down/physical cleanup,
collector activation, and complete affected startup/Cancel/Close test fixtures.
Required-data all12 live hashes/status/staging against iteration02 baseline and
all activation/control producers/callers. Inspect complete results; readback
connects exact no-grant fact, physical DOWN and diagnostics before dependent edits.
All initial LFE/OTP/framework rules/strengths and full required gates still apply.
Coherent intake proceeds under existing authority without routine approval.

Preserve all failed attempts/raw commands/exits/helpers and current-byte/fresh
X-TOOL-01 handling. Full component/root/fresh/root-launcher and matching14native+
3consumer run at final frozen bytes; no filtering/ignore/compile-only substitution.
Notify root source freeze before shared build gates. Exact allowlisted product
and eight-file return commits separately, both Codex/Billo AI trailers. Root
independently reproduces/accepts and writes retrospective; all8 rows remain open
until then. Complete NR02/positive-pressure/physical worker proof remains required.
No acceptance, arc close, push/merge/publish or later-arc authority from this note.

## Author readiness

CDC read complete frozen production snapshot and exact §4, independently agrees
with the narrow finding and supplies concrete retained fact/transition/oracles.
No consequential policy remains for CC to guess. Existing activation-owner ordering
and physical root monitor enable the fix within approved source/test scope.
Two literal recipe expression-order differences in early review are causally
safe under atomic callback state publication and are recorded, not bug findings.
