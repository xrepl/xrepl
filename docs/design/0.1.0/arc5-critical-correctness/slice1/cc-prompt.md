# CC Assignment — Arc 05 Slice 1: L-01, kill the idle-keepalive desync

You are CC (the implementer) for one slice of the xrepl 0.1.0 remediation. Work
the ledger, close every row with reproducible evidence, write a closing report
that walks the ledger row by row. A separate context (CDC) will independently
re-verify your `done` rows afterward.

## Context

- **Repo:** `xrepl` OTP application at `/Users/oubiwann/lab/lfe/xrepl/xrepl`.
- **Branch:** cut `arc5/slice1-keepalive-desync` off `release/0.1.x`. Do not
  commit directly to `release/0.1.x`. *(Historical note: executed as
  `slice/01.02-keepalive` under the retired release-sequential convention;
  renamed per CDC-4. Naming is `arc<N>/slice<M>-<slug>` — see
  `../arc-plan.md`.)*
- **Ledger (your spec):** `ledger.md` in this slice directory. Read it first.
  Its five rows F-1…F-5 are the definition of done.
- **Discipline:** load and follow `LEDGER_DISCIPLINE.md` from the
  collaboration-framework skill. Five-iteration cap. Evidence = command output +
  the commit SHA where the row was met.
- **Knowledge:** load the Erlang guidelines skill (anti-patterns chapter first)
  and the LFE style guide (`lfe-manual` part7 ai-resources). The diff here is
  small; the test is where style applies — ltest-unit behaviour, existing
  `test/xrepl-*-tests.lfe` files are the convention to match.
- **Parent plans (read for context, don't re-derive):** `../arc-plan.md` (Arc 05
  plan-of-record for this slice) and
  `workbench/2026.06.10-remediation-program-plan.md`. The audit finding itself:
  `workbench/2026.06.10-audit-results-lfe.md` §L-01.

## The bug, precisely

`message-loop` (`src/xrepl-tcp-handler.lfe:60-82`) has an `(after 30000 …)`
clause that calls `send-keepalive` (`:167-171`), writing an unsolicited
`#m(status ping)` frame to the socket after 30 s idle. The client speaks strict
synchronous `send` → `recv` (`xrepl-client.lfe`), so after any 30 s of
think-time the next eval reads the ping frame instead of its reply;
`xrepl-client:eval` matches only `#"done"`/`#"error"` (`:131-136`) →
`case_clause` → crash, and the stream is off-by-one from then on. Guaranteed
failure for an interactive REPL — idling at a prompt is the normal case.

## The fix

Delete the `(after 30000 …)` clause and `send-keepalive`. Nothing replaces
them: TCP/OS dead-peer detection covers liveness; the protocol stays strictly
request/response; the client-initiated `ping` *op* (`xrepl-dispatcher`
`handle-ping`) is unrelated and stays. After deletion `message-loop` blocks
indefinitely in `receive` — intended; `tcp_closed`/`tcp_error` are the exit
paths and the socket is re-armed `{active, once}` before each receive.

## Order of work — test first

1. **Branch + baseline.** Cut the slice branch; confirm `rebar3 compile` and
   `rebar3 as test lfe ltest` are green before touching anything (Arc 04 closed
   green at 39/39).
2. **Write the regression test (F-3) and capture it RED on unfixed code.**
   Connect, idle past 30 s, eval, assert a correct `done` reply. Red-on-baseline
   output is required ledger evidence — it proves the test isn't vacuous.
   Practical notes:
   - The idle is real wall-clock (~31 s); eunit's default 5 s per-test timeout
     must be lifted with a timeout fixture/generator (`{timeout, 60, …}` shape).
   - One idle window can carry both assertions: during idle, `recv` returns
     `{error, timeout}` (nothing unsolicited — this is the arm that goes red on
     baseline, receiving the ping frame); after idle, eval returns `#(ok …)`.
   - A UNIX-socket connection is pre-authenticated
     (`xrepl-tcp-handler.lfe:51`) and skips the token dance; the bug is
     transport-independent. TCP + token works too. Listener entry points:
     `xrepl-net-sup:start-tcp-listener/1` / `start-unix-listener/1`; app-env
     path in `xrepl-app.lfe:34-75`. Use an ephemeral port / tmp socket path;
     clean up the listener in teardown.
3. **Apply the fix** (F-1, F-2). Two deletions in `src/xrepl-tcp-handler.lfe`.
   Re-run the suite; capture the test green.
4. **Client check (F-4).** Confirm `xrepl-client:eval` is untouched and still
   has no `ping` clause — the criterion is *absence*. Write the "why no ping
   clause is needed" rationale into the closing report.
5. **Doc-truth (F-5).** Read `README.md:249-305` (Phase 3 / server modes) and
   the `bin/xrepl` usage text against post-fix behaviour. Each network claim is
   either confirmed accurate or amended in a cited commit. Record the
   disposition under a `## Doc-truth` heading in the closing report. The test
   you wrote in step 2 is the evidence that "network REPL works" is now an
   honest sentence.
6. **Close the ledger.** Evidence per row as you land it (output + SHA), What
   Worked, Closure line, and `closing-report.md` walking F-1…F-5 one at a time.

## What this slice is NOT — hard constraints

- **No other audit findings.** L-02 (`packet_size`) is slice5 pending Duncan's
  call; L-04/L-05/L-09 are slices 2-4. If you see them while in the file, leave
  them.
- **No replacement idle-disconnect / timeout feature.** Deleting the keepalive
  is the whole behavioural change. An idle-session reaper is L-04's territory
  and Arc 06 structure — not here.
- **No client-side ping handling.** F-4 forbids it; the protocol is
  request/response only.
- **No refactor of `message-loop` / `handle-data`** beyond the deletions, even
  where the code invites it (that's Arc 06).
- **No re-enabling xref/dialyzer/coverage gates** (Arc 06, L-07).

## Stop conditions

- The regression test will not go red on baseline → the test is vacuous or the
  bug is misunderstood; stop and rework the test, don't proceed to the fix.
- The test exposes a *different* desync (off-by-one from another source, auth
  interleaving, etc.) → that's a new finding; flag it, don't fix it here.
- Suite goes green only with changes beyond the two deletions + test → stop and
  flag; that's a finding.
- Iteration 5 without convergence → stop, report what's blocking.
- Anything in the ledger looks wrong or impossible → amendment request, not a
  silent workaround.
