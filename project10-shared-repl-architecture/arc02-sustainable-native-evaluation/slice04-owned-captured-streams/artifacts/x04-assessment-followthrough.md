# Project09 findings retained through native hardening

CDC/root, 2026-10-19. This is Project10/Arc02's explicit residual-owner map for
all27 assessment IDs, not a new assessment, a repair claim or a later-arc open set.
The original assessment at sourceb865b31 remains attested with its own acceptance
gates. Source of record is Project09/Arc01/Slice04's2026.10.17-audit-modernization-
synthesis.md (all27 recommended/unimplemented) and its linked reports. Read-only
lookup/root/native_design_review enumerated all IDs,41 assessed file paths and exact
committed Arc02 overlap; CDC read the complete synthesis and retains its required
regression/compatibility/re-entry instructions. The68-row implementation map is
47 product families+21 historical remediation obligations, NOT these27 findings.

At committed Arc02 f261152→7427d1c,22 changed paths have zero intersection with
those41 assessed file locations. Changes are the separately integrated native app,
its tests/docs, README and the new cayrn.rs Rust consumer. Native equivalent
behavior does not retire a still-supported legacy API. X04's exact12-path scope
also excludes every assessed location; verify the final committed delta before
arc acceptance rather than infer its bytes from this planned scope.

Earlier commits are qualified: a041799 changed assessed Rust repl/event/adventure
formatting, error adds Cayrn fault conversion, lib exports separate consumer,
main selects mode; legacy input remains. No RUST-001/002 repair proof follows.
RUST-004 may have formatting mitigation, but no per-ID repair acceptance exists.
ea844f5's app version seed does not change LFE-010 declared limits. Do not label
all assessed files untouched since audit, or accept anything from absence of
current Arc02 overlap alone.

Owner roles are Project10 roadmap delivery owners under CDC coordination, with
Operator decisions still binding. 'Retained' below means not repaired/retired by
Arc02; future owning delivery must demonstrate repair, supported replacement or
explicit compatibility disposition using the original synthesis proof, before
P10-18 can close. No later arc is opened here.

| Finding | Recorded concern / assessed home | Primary delivery owner / re-entry |
| --- | --- | --- |
| LFE-001 | Same-session caller/evaluator result misattribution, xrepl-session | Arc03 session/lifecycle owner; overlapping calls and exact result/error correlation before legacy evaluation retirement. |
| LFE-002 | Protected recursive evaluator receive grows stack, xrepl-session | Arc03 evaluation service owner; repeated success/error/switch stack and state proof in supported path. |
| LFE-003 | Graceful close loses newer-than-snapshot changes, session-manager/session | Arc05 snapshot/compatibility owner with Arc03 lifecycle; explicit process-state persistence promise, immediate bind-close/reopen and save-error controls. Transcript alone is not heap restoration. |
| LFE-004 | Expiry removes bookkeeping but leaves evaluator live, xrepl-store | Arc03 lifecycle/catalog owner; expiration inactive/absent/physical stop and peer/no-call-cycle proof. |
| LFE-005 | Session/history/story strings mint permanent atoms | Arc03 naming/history owner, Arc05 story owner; bounded atom growth, public lookup compatibility and known-item validation before replacement. |
| LFE-006 | UTF8 bytes reinterpreted as codepoints, dispatcher/local printer | Arc04 shell/payload owner with Arc05 legacy transport; actual lambda/emdash through supported entry/response seams. New native capture is not old dispatcher repair. |
| LFE-007 | Incomplete reader error tuple crashes continuation, xrepl-io/local loop | Arc04 input/multiline owner; public reader incomplete→complete/error/EOF controls. |
| LFE-008 | Raw story commands truncated/parsed forms crash normalization | Arc04 shell input owner with Arc05 story; neutral raw/parsed story and ordinary LFE controls at real seam. |
| LFE-009 | Successful graphics tuple crashes client wrapper | Arc05 graphics compatibility owner consulting term maintainer; synthetic renderer success/error tuple proof, hardware separately gated. |
| LFE-010 | Network frame/connection/rate declarations unenforced | Arc05 legacy transport policy owner, Arc06 configuration; Operator resolves auth/UNIX policy, actual predecode boundary/limit controls. No new listener/exposure here. |
| LFE-011 | Caller metadata discarded during creation | Arc03 session metadata owner; preserve caller metadata and authoritative reserved-key precedence at create/store/start. |
| LFE-012 | Hex-looking names confused with IDs | Arc03 session selection owner; face/fullID/missing controls in supported manager/client equivalent. |
| LFE-013 | Missing LFE APIs and literal dynamic-module calls | Arc03 LFE developer-services owner; resolved API/caller map, bindings/info/error and actual xref/runtime proof. |
| LFE-014 | Done replies lack assumed value/correlation protection | Arc05 client/transport compatibility owner; actual reply variants and stale/unrelated response isolation before retirement. |
| LFE-015 | Decoded shapes/types bypass request validation | Arc05 transport boundary owner; actual bounded structured errors for scalar/array/wrong fields, distinct malformed-byte/unknown-op controls. |
| LFE-016 | History owner/path/disable/upload privacy disagree | Arc03 history data/privacy owner with Arc04 input; isolated opt-out/custom path/concurrent save proof, no personal history fixtures. Core policy, not deferred UX. |
| LFE-017 | Configuration stored but execution sites ignore it | Arc06 configuration owner with Arc03/04 services; supported option policy/validation and actual behavior, not store/get-only checks. Presentation remains later UX unless explicitly retained. |
| LFE-018 | Substitute seams/ambient archives/missing static gates | Arc06 validation owner, affected Arc03–05 delivery owners supply regressions; neutral real boundaries, truly absent archive, individual xref triage and supported matrix. Green native counts do not repair legacy tests. |
| LFE-019 | Story condition/text/flag grammar violates totality | Arc05 story runtime owner; malformed/improper/Unicode8212 and agreed grammar plus valid transition/save controls. |
| LFE-020 | Banner/hybrid UNIX/auth option plumbing disagrees | Arc06 startup/config owner with Arc05 transport compatibility; isolated banner/hybrid/TCP matrix and policy; sh syntax alone insufficient. |
| LFE-021 | Competing output engines/exported fork obscure API ownership | Arc05 public API/legacy compatibility owner; supported callers/exports, output/file ownership and helpers protected before deletion/deprecation. |
| RUST-001 | Backend panic leaves REPL waiting | Arc04 Rust shell lifecycle owner; actual normal/quit/EOF/panic/input-parking proof and blocking read state. New Cayrn mode does not remove old run path. |
| RUST-002 | Terminal input failure becomes successful completion | Arc04 Rust input lifecycle owner; Err/nonzero/stderr and normal quit/EOF controls. Core error semantics, not deferred UX polish. |
| RUST-003 | Missing locked Rust CI/meaningful lifecycle/MSRV gates | Arc06 validation/CI owner; actual CI/test/fmt/all-target/features/declared MSRV execution. Current local native tests not remote CI proof. |
| RUST-004 | Formatting fails advertised gate | Arc06 tooling owner; inspect earlier mechanical mitigation, required current fmt/tests/Clippy plus actual per-ID disposition before acceptance. |
| TOOLS-001 | Push-loop failures print success/return zero | Arc06 build-tooling owner; neutral git stub failure42/success/multi-remote policy, no real push needed or authorized. |
| TOOLS-002 | cargo-outdated failure becomes up-to-date success | Arc06 build-tooling owner; neutral empty-stdout failure/no-updates/updates controls, no network/installer inquiry. |

All27 retained,0 claimed fixed/retired/no-op; earlier formatting mitigation remains
unaccepted pending owning proof. Existing Project09 compatibility classes and
explicit behavior/product decisions bind their future changes. The historical
OBL/PLAN families, assessment host/MSRV/OTP/OS/private story/terminal/auth/package
and missing original acceptance receipts remain separately recorded in the
synthesis; this27 map neither erases nor claims to cover them.

Native Arc02-specific residuals remain explicit too: X-PKG-01 spaced checkout
hook and X-TOOL-01 stale ignored LFE test-beam macro loading are Arc06 owners;
X-DOC-01 historical shell placeholder is later client/docs owner; X-UX-01 is the
Operator's later project. Serious NR-02 belongs X04 proof+C06 composition and
cannot be deferred by this map. P10-18/project/full migration stays open until
actual future disposition/compatibility/regression proof. Current accepted
native increments are useful infrastructure, not complete xrepl0.2 refactoring.

## Lookup correction retained

The initial read-only lookup reported42 distinct location tokens. Reproducing
its extraction caught one false positive: an inline git-push shell snippet next
to TOOLS-001's Location paragraph was counted as a file. Correct population is
41 actual paths, including the sibling term graphics file. Zero Arc02 overlap
remains. This is a corrected lookup denominator, not an executed push, source
change or new assessment finding. The corrected source-location-qualified
method/list accompanies the eventual closing evidence; no42-path claim accepted.
