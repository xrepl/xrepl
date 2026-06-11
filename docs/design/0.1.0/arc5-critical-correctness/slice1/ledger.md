# Slice 1: L-01 — kill the idle-keepalive desync

**Arc:** 05 — 0.1.0 critical correctness (`../arc-plan.md`) · **Branch:**
`slice/01.02-keepalive` off `release/0.1.x` @ `e16c0aa` · **Origin:**
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
| F-1 | The `after 30000` clause is gone from `message-loop`; no idle-timeout branch remains in `src/xrepl-tcp-handler.lfe` | `grep -n "after 30000" src/xrepl-tcp-handler.lfe; echo $?` → no match, exit `1` (and `grep -n "after " src/xrepl-tcp-handler.lfe` shows no other idle timer was introduced) | serious | L-01 | open | | |
| F-2 | `send-keepalive` is removed (preferred) or provably unreferenced | `grep -n "send-keepalive" src/xrepl-tcp-handler.lfe; echo $?` → no match, exit `1`; if retained instead, a repo-wide grep shows zero call sites and the Notes column records why deletion was rejected | correctness | L-01 | open | | |
| F-3 | A regression test connects, idles past the former 30 s window, then evals and gets a correct `done` reply — and **fails on pre-fix code** (red-on-baseline evidence required: the test run against the parent commit shows the injected `ping` / desync failure) | `rebar3 as test lfe ltest` → green incl. the new test; Evidence must contain **both** the red baseline output and the green post-fix output, each with its commit SHA | serious | L-01 | open | | Test-first: write it, capture red, then fix. See CC notes on the 30 s wall-clock cost and the eunit 5 s default timeout. |
| F-4 | `xrepl-client:eval` still has no `ping` clause **and no longer needs one** — the case arms remain exactly `#"done"`/`#"error"`, with the rationale documented in the closing report | `grep -n '#"ping"' src/xrepl-client.lfe; echo $?` → no match, exit `1`; `grep -n '(defun eval' -A 15 src/xrepl-client.lfe` shows only `#"done"`/`#"error"` arms; closing report has the "why no ping clause" note | correctness | L-01 | open | | Criterion is *absence* — do not add client-side ping handling. |
| F-5 | Doc-truth (def-of-done #5): README network claims (`README.md:249-305`) and `bin/xrepl` usage text checked against post-fix behaviour; each claim either confirmed accurate or amended in a cited commit; disposition recorded in the closing report under a `## Doc-truth` heading | `grep -in "doc-truth" docs/design/0.1.0/arc5-critical-correctness/slice1/closing-report.md` → section present; CDC reads the section against README/`bin/xrepl` at the closing SHA | correctness | program plan §4 #5 | open | | "Network mode works" is now a true claim only if the regression test (F-3) is green; otherwise the docs must say experimental. |

## What Worked

_(Filled in at slice close. Patterns, practices, or decisions that made the
slice close cleanly and should be preserved or generalised.)_

## Closure

Closed at commit `<SHA>` on `<date>`. CDC verification: `cdc-verification.md`.
Total rows: 5. Done: _. Deferred: _. No-op: _.

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
