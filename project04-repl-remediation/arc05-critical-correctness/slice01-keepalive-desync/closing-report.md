# Closing Report — Arc 05 Slice 1: L-01 kill the idle-keepalive desync

**Closing SHA:** `c828d11` (iteration 3) — supersedes `2ccceed` (iteration 2)  
**Date:** 2026-06-11  
**Branch:** `arc5/slice1-keepalive-desync` off `release/0.1.x`  
**Rows:** 7 total (F-1…F-5 from iterations 1–2; F-6, F-7 from iteration 3). Done: 7. Deferred: 0. No-op: 0.  
**Iterations used:** 3 (1: test + RED; 2: fix + GREEN, cleanup for eaddrinuse; 3: CDC fixes F-6 + F-7).

---

## F-1: `after 30000` clause removed from `message-loop`

**Status: done.** Commit `2ccceed`.

The `(after 30000 ...)` clause spanning lines 78–82 of the original
`src/xrepl-tcp-handler.lfe` was deleted. After the fix, `message-loop`'s
`receive` block has exactly three clauses: `tcp`, `tcp_closed`, and
`tcp_error`. The loop blocks indefinitely in `receive` — this is the
correct behaviour. TCP/OS dead-peer detection covers liveness; the socket
is re-armed with `{active, once}` before each receive, so a closed peer
still produces a `tcp_closed` message and terminates the handler
gracefully.

Verify: `grep -n "after 30000" src/xrepl-tcp-handler.lfe; echo $?` → exit 1
(no output).

No other idle timer was introduced (`grep -n "after " src/xrepl-tcp-handler.lfe`
shows no `after` clauses at all).

---

## F-2: `send-keepalive` removed

**Status: done.** Commit `2ccceed`.

The `send-keepalive` function (lines 167–171 of the original file) was
deleted entirely. It had one call site (the now-deleted `after` clause) and
no other references. Deletion was preferred over leaving it as dead code.

Verify: `grep -n "send-keepalive" src/xrepl-tcp-handler.lfe; echo $?` → exit 1.
Repo-wide: `grep -rn "send-keepalive" src/ test/` → no output.

---

## F-3: Regression test — red on baseline, green after fix

**Status: done.** Test file: `test/xrepl-keepalive-tests.lfe`.

**Red baseline (pre-fix):**

```
module: xrepl-keepalive-tests
  module 'xrepl-keepalive-tests' .................................. [fail]

      Assertion failure:
      #(assertEqual
               (#(module xrepl-keepalive-tests)
                #(line 44)
                #(expression "(xrepl-client:recv conn 500)")
                #(expected #(error timeout))
                #(value #(ok #M(#"id" #"unknown" #"status" #"ping")))))

  time: 31025ms

summary: Tests: 40  Passed: 39  Skipped: 0  Failed: 1 Erred: 0
```

The `recv` call returned `{ok, #{"id" => "unknown", "status" => "ping"}}` —
the unsolicited keepalive frame the server sent at the 30 s mark. The test
expected `{error, timeout}` (nothing in the buffer). This is exact evidence
of the L-01 desync.

**Green post-fix (commit `2ccceed`):**

```
module: xrepl-keepalive-tests
  module 'xrepl-keepalive-tests' .................................... [ok]
  time: 31530ms

summary: Tests: 40  Passed: 40  Skipped: 0  Failed: 0 Erred: 0
```

The test structure:
- Starts a standalone Ranch UNIX-socket listener (pre-authenticated, no
  token dance needed).
- Connects via `xrepl-client:connect` with `{socket, BinPath}`.
- Sleeps 31 s (one second past the former 30 s keepalive window).
- **Assertion (a):** `recv conn 500` → must return `{error, timeout}` (no
  unsolicited frame was sent).
- **Assertion (b):** `eval conn "(+ 1 2)"` → must return `{ok, _, _}` (the
  stream is still aligned, no desync).
- `try`/`after` guarantees listener cleanup even when assertion (a) throws
  (as it does in the RED run), preventing `eaddrinuse` on subsequent runs.

---

## F-4: `xrepl-client:eval` has no `ping` clause — rationale

**Status: done.** `xrepl-client.lfe` is untouched. Commit `2ccceed`.

Verify: `grep -n '#"ping"' src/xrepl-client.lfe; echo $?` → exit 1.

`xrepl-client:eval` (`:125-140`) matches two `status` values: `#"done"` and
`#"error"`. No `#"ping"` arm exists or is needed — here is why:

Before this fix, the client needed (but lacked) a `ping` arm because the
server could inject an unsolicited ping frame at any moment. The client's
`recv` would read the ping frame before the eval reply, `case_clause` would
crash the process, and the stream was permanently desynchronised. Adding
a `ping` arm would only mask the symptom: the eval reply would then be read
in the *next* recv call, producing the wrong result for the current eval.

After this fix, the server never sends an unsolicited frame. The stream is
strictly request/response: every `send` has exactly one `recv` response.
There is nothing in the buffer between a send and its reply. A `ping` arm
in `eval` would never be reached and would add dead code. The client-side
`xrepl-client:ping/1` function (`:142-152`) is unrelated — it initiates a
client-driven ping op that goes through the normal request/response path.

---

## F-5: Doc-truth

**Status: done.** No README or `bin/xrepl` changes needed. Commit `2ccceed`.

I reviewed `README.md:249-305` (Phase 3 / Server Modes section) and the full
`bin/xrepl` script against post-fix behaviour. Disposition of each network
claim:

| Claim | Location | Verdict |
|-------|----------|---------|
| "Network REPL support with TCP and UNIX domain sockets is now available" | README:249 | **Accurate.** Post-fix, connections are stable across idle periods. The regression test (F-3) proves it. |
| "Multiple clients can connect to the same server simultaneously" | README:254 | **Accurate.** Ranch handles concurrent connections; the fix doesn't affect concurrency. |
| "Both TCP and UNIX domain sockets" | README:255 | **Accurate.** Both transports use the same `message-loop`; both benefit from the fix. |
| "Token authentication for TCP; file-permission auth for UNIX" | README:256-257 | **Accurate.** Unchanged. |
| "Crash Recovery: Client supervision tree provides automatic crash recovery" | README:258 | **Accurate.** Refers to client-side supervisor, not the keepalive. |
| "Special `(ping)`, `(q)`, and `(quit)` commands for remote clients" | README:260 | **Accurate.** `ping` is a client-initiated op through the dispatcher (`handle-ping`); unrelated to the deleted server-side keepalive. |
| `--server`, `--connect`, `--hybrid` mode descriptions | bin/xrepl | **Accurate.** The `--server` mode no longer injects unsolicited keepalive frames; behaviour matches documentation. |

No keepalive language existed anywhere in the docs to retract. No amendments
were needed.

The regression test (F-3) is the proof that "Network REPL works" is now an
honest sentence: it connects, idles past the former desync window, and
confirms a correct reply arrives.

---

## Iteration 3 Addendum — CDC findings F-6 and F-7

### F-6: decode-error path re-arms socket via `call`, not `funcall`

**Status: done.** RED commit `f1e3555` (test only). Fix commit `c828d11`.

**The bug.** `handle-data`'s `` `#(error ,reason) `` clause (former line 111)
called `(funcall transport 'setopts socket ...)`. `transport` is the module
atom `ranch_tcp`, not a lambda or fun — `funcall` compiles to `Transport(…)`,
calling an atom as a fun → `{badfun, ranch_tcp}`. Every other `setopts` call
site in the file correctly used `(call transport …)`. The practical effect:
after a malformed frame, the decode-error reply was sent, then the handler
crashed; the connection dropped and `(message-loop state)` on the next line
was unreachable. Every malformed client frame killed the connection.

**Red baseline output (commit `f1e3555`, pre-fix):**

```
module: xrepl-decode-error-tests
  module 'xrepl-decode-error-tests' ...... [fail]

      Assertion failure:
      #(assertEqual
               (#(module xrepl-decode-error-tests)
                #(line 43)
                #(expression "(tuple (quote error) reason)")
                #(expected eval-ok)
                #(value #(error closed))))

      time: 19ms

[ERROR REPORT] Error in process with exit value:
{{badfun,ranch_tcp}, [{'xrepl-tcp-handler','handle-data',2,...}]}
```

The handler crashed (`{badfun, ranch_tcp}`), connection closed, `gen_tcp:recv`
for the post-error eval returned `{error, closed}`.

**Fix.** One token: `funcall` → `call` at the decode-error path. Test first
(commit `f1e3555`), fix after (commit `c828d11`).

**Green post-fix (commit `c828d11`):**

```
module: xrepl-decode-error-tests
  module 'xrepl-decode-error-tests' ... [ok]   time: 17ms

summary: Tests: 41  Passed: 41  Skipped: 0  Failed: 0 Erred: 0
```

Verify: `grep -n "funcall" src/xrepl-tcp-handler.lfe; echo $?` → exit 1 (no
output).

**Note on related-but-deferred issue.** CDC-7 also flagged `#m(id (binary
"unknown"))` on the same path: the atom key `id` is never found by
`send-response`'s binary-key lookup `(maps:get (binary "id") request (binary
"unknown"))`, so the response id is always `#"unknown"`. This is the same
defect family as the keepalive id (map atom/binary key mismatch). It is
disclosed-deferred to Arc 06 (protocol/boundary cleanup) and is NOT fixed
here.

---

### F-7: orphaned closing parens folded

**Status: done.** Commit `c828d11`.

The keepalive deletion (commit `2ccceed`) left `)))` alone on its own line
after the `tcp_error` clause of `message-loop`. Folded onto the preceding
line: `'ok))))`, per the LFE style rule "all closing parens on the same line."

The fold required careful paren counting: the previous standalone `)))` plus
the `'ok)` on the line above totalled 4 closing parens (close tcp_error clause
+ close receive + close let + close defun). The initial fold attempt used 3
parens (`'ok)))`), which dropped the defun's closing paren and caused a
`{60, lfe_parse, missing_token}` compile error. The correct form `'ok))))` was
verified by successful compilation.

Verify: `grep -n "^[[:space:]]*)" src/xrepl-tcp-handler.lfe; echo $?` → exit 1.
`rebar3 compile` → exit 0.
