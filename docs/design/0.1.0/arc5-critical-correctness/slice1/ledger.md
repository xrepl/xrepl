# Slice 1: L-01 — kill the idle-keepalive desync

**Arc:** 05 — 0.1.0 critical correctness (`../arc-plan.md`) · **Branch:**
`arc5/slice1-keepalive-desync` (renamed from `slice/01.02-keepalive` per
CDC-4) off `release/0.1.x` @ `6609a12` · **Origin:**
`workbench/2026.06.10-audit-results-lfe.md` (L-01) · **Discipline:**
`LEDGER_DISCIPLINE.md` (CC implements, CDC verifies; every row reaches a final
status with reproducible evidence before the slice advances; five-iteration cap).

**Scope.** Remove the `(after 30000 …)` keepalive clause that injects an
unsolicited `#m(status ping)` frame into a strictly synchronous request/response
stream (`src/xrepl-tcp-handler.lfe:79-82`; `send-keepalive` at `:167-171`). The
client (`xrepl-client:eval`, `src/xrepl-client.lfe:125-140`) does `send` → `recv`
and matches only `#"done"`/`#"error"`; after 30 s of idle the next eval reads the
ping frame first → `case_clause` → every subsequent reply is off-by-one. A REPL
connection needs no app-level keepalive: TCP/OS dead-peer detection covers
liveness, and the protocol's explicit client-initiated `ping` op
(`xrepl-dispatcher` `handle-ping`) remains untouched. **Also in scope:** the
release def-of-done #5 doc-truth check — README/`bin/xrepl` network-mode claims
must be honest once this lands (program plan §4).

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| F-1 | The `after 30000` clause is gone from `message-loop`; no idle-timeout branch remains in `src/xrepl-tcp-handler.lfe` | `grep -n "after 30000" src/xrepl-tcp-handler.lfe; echo $?` → no match, exit `1` (and `grep -n "after " src/xrepl-tcp-handler.lfe` shows no other idle timer was introduced) | serious | L-01 | done | Commit `2ccceed`. `grep -n "after 30000" src/xrepl-tcp-handler.lfe; echo $?` → exit 1 (no output). | Two deletions: the `(after 30000 ...)` clause (lines 78–82) and the `send-keepalive` function (lines 167–171). |
| F-2 | `send-keepalive` is removed (preferred) or provably unreferenced | `grep -n "send-keepalive" src/xrepl-tcp-handler.lfe; echo $?` → no match, exit `1`; if retained instead, a repo-wide grep shows zero call sites and the Notes column records why deletion was rejected | correctness | L-01 | done | Commit `2ccceed`. `grep -n "send-keepalive" src/xrepl-tcp-handler.lfe; echo $?` → exit 1 (no output). | Deleted entirely (preferred). |
| F-3 | A regression test connects, idles past the former 30 s window, then evals and gets a correct `done` reply — and **fails on pre-fix code** (red-on-baseline evidence required) | `rebar3 as test lfe ltest` → green incl. the new test; Evidence must contain **both** the red baseline output and the green post-fix output, each with its commit SHA | serious | L-01 | done | **RED** (pre-fix, branch before `2ccceed`): `xrepl-keepalive-tests` FAIL — `#(assertEqual ... #(expected #(error timeout)) #(value #(ok #M(#"id" #"unknown" #"status" #"ping"))))` — the ping frame was present. **GREEN** (post-fix, `2ccceed`): `Tests: 40 Passed: 40 Failed: 0`. | Test file: `test/xrepl-keepalive-tests.lfe`. `deftestgen` with 60 s eunit timeout. Two assertions: (a) recv returns `{error,timeout}` after 31 s idle; (b) post-idle eval returns `{ok,...}`. |
| F-4 | `xrepl-client:eval` still has no `ping` clause **and no longer needs one** — the case arms remain exactly `#"done"`/`#"error"`, with the rationale documented in the closing report | `grep -n '#"ping"' src/xrepl-client.lfe; echo $?` → no match, exit `1`; closing report has the "why no ping clause" note | correctness | L-01 | done | Commit `2ccceed`. `grep -n '#"ping"' src/xrepl-client.lfe; echo $?` → exit 1 (no output). `xrepl-client.lfe` untouched. | Rationale in closing report below. |
| F-5 | Doc-truth: README network claims (`README.md:249-305`) and `bin/xrepl` usage text checked against post-fix behaviour; each claim either confirmed accurate or amended | `grep -in "doc-truth" docs/design/0.1.0/arc5-critical-correctness/slice1/closing-report.md` → section present | correctness | program plan §4 #5 | done | Commit `2ccceed`. `grep -in "doc-truth" closing-report.md` → section present (see file). No README or `bin/xrepl` changes needed. | All network claims confirmed accurate. No keepalive language existed to retract. |
| F-6 | The decode-error path re-arms the socket via `(call transport …)`, not `(funcall transport …)`; a regression test sends one malformed frame, receives a decode-error reply, then completes a normal eval **on the same connection** — and fails on pre-fix code (red-on-baseline required) | `grep -n "funcall" src/xrepl-tcp-handler.lfe; echo $?` → no match, exit `1`; `rebar3 as test lfe ltest` green incl. the new test; Evidence carries both the red and green outputs with SHAs | correctness | CDC-7 | done | **RED** (pre-fix, commit `f1e3555`): `xrepl-decode-error-tests` FAIL — `{badfun,ranch_tcp}` crash, `{error,closed}` on eval recv; `#(expected eval-ok) #(value #(error closed))`. **GREEN** (post-fix, `c828d11`): `Tests: 41 Passed: 41 Failed: 0`. `grep -n "funcall" src/xrepl-tcp-handler.lfe; echo $?` → exit 1. | Test file: `test/xrepl-decode-error-tests.lfe`. `deftestgen` with 10 s timeout. Red test committed at `f1e3555` before fix at `c828d11`. |
| F-7 | No orphaned closing parens: every closing paren in `src/xrepl-tcp-handler.lfe` sits on the same line as code, per the LFE style rule | `grep -n "^[[:space:]]*)" src/xrepl-tcp-handler.lfe; echo $?` → no match, exit `1`; `rebar3 compile` clean | polish | CDC-1 | done | Commit `c828d11`. `grep -n "^[[:space:]]*)" src/xrepl-tcp-handler.lfe; echo $?` → exit 1. `rebar3 compile` exits 0. | Folded `))))` onto the `'ok` line of `message-loop`'s `tcp_error` clause. |

## What Worked

- **Test-first discipline caught the real failure mode.** Writing the test against
  unfixed code and watching it fail with the exact ping frame (`#M(#"id" #"unknown"
  #"status" #"ping")`) confirmed both the bug and the test's non-vacuousness in one
  step. The failure message is self-documenting evidence.
- **`deftestgen` + `try`/`after` was the right combination.** `deftestgen` provides
  the eunit `_test_()` convention and explicit export; `try`/`after` ensures the
  Ranch listener is cleaned up even when an assertion throws during the RED run —
  otherwise the second run fails with `eaddrinuse` on the same listener ref.
- **Standalone `ranch:start_listener` avoids supervisor conflicts.** Bypassing
  `xrepl-net-sup:start-unix-listener` (which hardcodes `ref = 'xrepl_unix'`) let
  the test use a private ref and not interfere with any production listener.
- **The fix was exactly two deletions.** No other code changed, confirming the
  scope was correctly bounded by the ledger constraint.
- *(CDC)* **Forensic cross-checking of reported evidence works.** The red run's
  failure value carried `#"id" #"unknown"` — an artifact of the deleted code's
  atom-vs-binary key mismatch that fabricated output would not contain. Checking
  reported evidence against non-obvious properties of the deleted code path is a
  cheap, reusable verification move when CDC can't re-execute the run itself.
- **Committing the RED test before the fix (CDC-3 discipline)** created a clean
  SHA boundary (`f1e3555` = red test, `c828d11` = fixes) that CDC can verify
  without worktree gymnastics: `git checkout f1e3555 && rebar3 as test lfe ltest`
  produces the red run directly.

## Closure

Closed at fix commit `c828d11` (ledger commit `5a46cc5`), on 2026-06-11.
CDC verification: `cdc-verification.md` — **fully verified, 7/7**: all five
original rows reproduced (F-3 via guarded host harness); F-6 red/green and
F-7 compile reproduced via operator-executed `cdc-iter3-red-green.sh`
(red: `{badfun,ranch_tcp}` crash + `#(error closed)`, 40/41 at `f1e3555`;
green: 41/41 at `5a46cc5`). Merge-ready to `release/0.1.x`.
Total rows: 7. Done: 7. Deferred: 0. No-op: 0. Iterations: 3 of 5.

---

### CC notes

- Read this ledger before writing anything. If a criterion is wrong or
  impossible, raise an amendment — don't silently work around it.
- **Work test-first.** F-3's red-on-baseline evidence is the proof the test
  isn't vacuous (failure mode #4 in the discipline). Write the test, run it
  against unfixed code, capture the failure, *then* delete the keepalive.
- **The idle wait is real time.** Post-fix there is no timer to shorten, so the
  honest test idles >30 s (one test, ~31 s wall clock). eunit's default per-test
  timeout is 5 s — wrap the test in a timeout fixture/generator (`{timeout, 60,
  …}` shape). Two assertions in one idle window keep it to a single wait:
  (a) nothing unsolicited arrives during idle (`recv` → `{error, timeout}`),
  (b) a post-idle eval returns `#(ok …)`.
- **Transport choice:** a UNIX-socket connection is pre-authenticated
  (`xrepl-tcp-handler.lfe:51`), skipping the token dance; the keepalive bug is
  transport-independent (same `message-loop`). TCP + token is equally valid if
  UNIX local sockets are awkward in CI. Listener entry points:
  `xrepl-net-sup:start-tcp-listener/1`, `start-unix-listener/1`; app-env path in
  `xrepl-app.lfe:34-75`.
- **Deleting the `after` clause makes `message-loop` block indefinitely — that
  is intended.** `tcp_closed`/`tcp_error` remain the exit paths, and the socket
  is re-armed `{active, once}` before each receive, so dead peers still
  terminate the handler. Do **not** add a replacement idle-disconnect feature.
- Fill Evidence (command output + commit SHA) per row as you land it, not all at
  the end. Closing report walks F-1…F-5 one at a time — no prose summary, no
  "deviations: none."

### CDC notes

- Re-run every Verify command yourself at the closing SHA; treat CC's `done` as
  proposed-done.
- **F-3 is the row to lean on.** Reproduce the red-on-baseline run (check out
  the parent SHA, run the test) — a green-only evidence trail is exactly the
  vacuous-test failure mode. Confirm the test asserts a *correct reply*, not
  merely "no crash" (spec-softening watch).
- **F-2 partial-adoption watch:** if `send-keepalive` was kept, grep the whole
  repo (`grep -rn "send-keepalive" src/ test/`) for stragglers.
- **F-5:** read the README server-mode section and `bin/xrepl` usage text
  yourself against the closing-SHA behaviour; the closing-report paragraph alone
  is a claim, not evidence.
