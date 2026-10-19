# Independent CDC verification — 2026-10-18

Verdict: **accept all eight Slice01 rows** at xrepl
`7228183e2e584e0ab86e03dc6b9454d4b918cc38`, paired with Cayrn core
`7b27b0f4a24d9dd85918fd590760b472a60798a3`. Actual implementer:
`/root/xrepl_x21`; actual independent source reviewer and reproducing verifier:
Sofie `/root`. This is the first executed CC attempt; zero returned correction
passes of five. Review inputs during that attempt are not extra executed passes.
No Operator, arc, project or historical acceptance is inferred.

## Source and evidence identity

Read the actual two production modules, resource/I/O tests, seven-path diff,
CC intake/execution and full return. Independently checked all seven SHA256s in
[the candidate](artifacts/source-candidate.json) against committed/current source;
exact changed-path allowlist holds. Only pre-existing docs/design/ is untracked.
No evaluator, manifest, lock, build, launcher, Rust terminal or legacy edits.
The issued technical contract and both prompt versions remain unchanged.

## Reproduced checks

All final commands below exited 0, at the source pins above. Logs are independent
CDC executions, not copies of the CC's logs.

- Cayrn, with CAYRN_LFE_DIR/XREPL_DIR/XREPL_BIN/CARGO_TARGET_DIR unset:
  `make check lint-integration test-xrepl` — [full log](artifacts/cdc-full-gate.log).
  27 ordinary tests;12 real native host/BEAM cases;3 actual consumer/PTY cases;
  21 unique native EUnit;7 consumer Rust tests and1 doctest. Formatting, Clippy,
  rustdoc and actual native/client discovery passed. No fallback or green skip.
- xrepl `make test-lfe` — [root log](artifacts/cdc-root-lfe.log):236 EUnit
  executions =175 legacy +61 native; native population21 unique +40 repeats.
  CT discovers0 tests; this is explicitly not CT coverage.
- Fresh `git archive` of the19 tracked native component files, no inherited
  _build/.beam, `make check` — [log](artifacts/cdc-fresh-native.log),21 native
  cases; [archive/file hashes](artifacts/cdc-fresh-native.json), unchanged by run.
- Root launcher from /private/tmp, spaced socket path, native2 Hello/Ready,
  evaluation of started applications, Close/Closed — [log](artifacts/cdc-root-launcher.log),
  [reproduction script](artifacts/cdc-launcher-check.py). Exact native-only app
  population `(cayrn_lfe compiler kernel lfe stdlib)`; no legacy/Ranch startup.

## Row walk and source reasoning

| Row | Verdict | Independent basis |
| --- | --- | --- |
| XS21-01 | done | Scalar positive canonical sparse token fence; replay/invalid/overflow non-execution and consumed capacity-refusal token pass. No seen-ID history. |
| XS21-02 | done |512 native quiet evaluations with collector/trace reclamation after each outcome;1024 real-host evaluations retain state, early-writer origin, retry/dedup and contiguous paged replay. |
| XS21-03 | done | Actual local spawn/link/monitor/opt descendants; exit-before-birth and send/receive inversion controls; traced-send/request counts and delivery witnesses; withheld ACK blocks reclaim; exact DOWN returns physical credit. |
| XS21-04 | done |64 live origins;65th exact ordinary failure cannot mutate binding or acquire evaluator/collector; token consumed; controlled producer release and new-token recovery; full-capacity close passes. |
| XS21-05 | done | Real late attribution/ACK/close/cancel and context/host failure scenarios; unknown commit receives no false ACK. Finishing completion wins, forced sealing and Retiring DOWNs drain. Stale/future cancel tested before foreground output ACK, not with a timing-only oracle. |
| XS21-06 | done | OTP gen_server/record/spec/docs and private helper conventions inspected. Per-origin isolated trace session cleanup preserves independent tracing. No retired-PID tombstone collection. Acquisition failure reaps both paused root and collector; rearm failure tears down the resource-owning next state. Explicit equality guards avoid nested LFE pattern shadowing. |
| XS21-07 | done | All populations above independently reproduced, including fresh native source and root launcher. CT0, repeats, failures and limits disclosed. |
| XS21-08 | done | Exact7-path candidate/commit and complete8-row CC return, evidence inventory, residual4096/8192 owners and parent disposition retained. |

No blocking implementation finding remains. The trace accounting proof uses
separate root-accounted/finished witnesses, per-producer delivery completion,
traced-send/request equality and durable pending replies. Quiet foreground
publication waits for exact normal collector DOWN; background producers retain
immutable origin. Monitor/token checks compare stored identities explicitly.
Collector startup precedes root activation and teardown owns every acquired
resource. These are source and behavioral checks, not claims of arbitrary-code
sandboxing or node-wide tracing guarantees.

## Failed attempts and boundaries

CC [development log](artifacts/development-checks.log) and return retain initial
LFE parse/unsupported-macro repairs,17-case fixture failures,20-case iolist mismatch,
and21-case test-owned-monitor cleanup failure. One intermediate compile failure
and a focused1-pass/11-filtered run survive only in tool history; no durable raw
log is fabricated. Final/fresh suites reproduce the delivered bytes.
Fresh source whose checkout path contains spaces fails the pinned Rebar/LFE build
hook; ordinary fresh checkout passes. This is X-PKG-01, a packaging re-entry gate,
not evidence of arbitrary checkout-path support. Spaced socket paths pass.
Broad historical README syntax validation encounters its pre-existing `<TOKEN>`
placeholder; scoped changed docs validate. X-DOC-01 owns later documentation repair.
Pinned dependency warnings remain disclosed; no new product compile warning is
hidden by the final runs.

CDC's first launcher probe used an incorrect expected app list omitting compiler;
[it failed](artifacts/cdc-root-launcher-initial-failure.log). Actual lfe.app lists
compiler as a dependency. Corrected only that oracle, then reran startup,
evaluation and Close successfully; no product change. This is a reviewer repair,
not evidence that the initial probe passed.

4096 cumulative node context identities remain Slice02;8192-size/preview/output
pressure remain Slice03. Cayrn C04 composes all native results. No physical-disk
power-loss, remote CI, publishing, heap restoration, user-node tracing, full
Project09 acceptance or release claim. The next architectural proposal is
unapproved; this acceptance does not authorize changing its boundary.

CDC additions are this record, cdc-retrospective.md and artifacts/cdc-* (draft
observations; full/root/fresh/launcher logs; fresh manifest; launcher script;
retained failed oracle log). CC inventory is in closing-report.md. Artifacts
support first-class records rather than replace them.
