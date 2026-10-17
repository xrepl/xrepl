# CC Assignment — Arc 05 Slice 1, iteration 3: CDC fixes (parens + funcall)

You are CC for the fix-iteration on slice arc5/slice1 (L-01 keepalive desync).
The slice's first two iterations landed the fix and closed the original five
ledger rows; CDC verification then surfaced two findings that must fold in
before merge. **This is iteration 3 of the slice's 5-iteration budget.**

## Context

- **Repo:** `xrepl` OTP application at `/Users/oubiwann/lab/lfe/xrepl/xrepl`.
- **Branch:** the existing `arc5/slice1-keepalive-desync` — work directly on
  it; this is the same slice, not a new one. Do not rebase or amend existing
  commits (their SHAs are ledger evidence).
- **Ledger:** `ledger.md` in this slice directory. **Amend it** by adding the
  two rows below (F-6, F-7) — a disclosed scope addition from CDC findings
  CDC-7 and CDC-1 (`cdc-verification.md`), not a silent change.
- **Discipline:** `LEDGER_DISCIPLINE.md` from the collaboration-framework
  skill. Evidence = command output + commit SHA, per row.
- **Knowledge:** Erlang guidelines skill (anti-patterns first) + the LFE style
  guide; match the existing `test/xrepl-*-tests.lfe` conventions.

## New ledger rows (add to `ledger.md` exactly)

| ID | Criterion | Verify | Significance | Origin | Status |
|----|-----------|--------|--------------|--------|--------|
| F-6 | The decode-error path re-arms the socket via `(call transport …)`, not `(funcall transport …)`; a regression test sends one malformed frame, receives a decode-error reply, then completes a normal eval **on the same connection** — and fails on pre-fix code (red-on-baseline required) | `grep -n "funcall" src/xrepl-tcp-handler.lfe; echo $?` → no match, exit `1`; `rebar3 as test lfe ltest` green incl. the new test; Evidence carries both the red and green outputs with SHAs | correctness | CDC-7 | open |
| F-7 | No orphaned closing parens: every closing paren in `src/xrepl-tcp-handler.lfe` sits on the same line as code, per the LFE style rule | `grep -n "^[[:space:]]*)" src/xrepl-tcp-handler.lfe; echo $?` → no match, exit `1`; `rebar3 compile` clean | polish | CDC-1 | open |

## Fix 1 — F-6: `funcall` → `call` on the decode-error path (the real bug)

`src/xrepl-tcp-handler.lfe:111`, in `handle-data`'s `` `#(error ,reason) ``
clause:

```lisp
(funcall transport 'setopts socket (list (tuple 'active 'once)))
```

`transport` is a module atom (`ranch_tcp`). `funcall` compiles to
`Transport(…)` — calling an atom as a fun → `badfun` crash. So after a
malformed frame: the decode-error reply IS sent, then the handler crashes and
the connection drops; the `(message-loop state)` on the next line is
unreachable. Every sibling call site (`:36`, `:41`, `:95`, `:105`, `:146`)
correctly uses `(call transport …)`. The fix is that one token.

**Test (red FIRST — commit the test before the fix, per CDC-3):**
`test/xrepl-decode-error-tests.lfe` (or fold into a sensibly named module).
The existing `xrepl-keepalive-tests.lfe` helpers are the harness pattern to
copy (standalone Ranch UNIX listener, private ref, `try`/`after` cleanup).
Note: `xrepl-client` can't send malformed bytes (it always encodes), and its
connection record isn't importable — use raw `gen_tcp` with
`(list 'binary (tuple 'packet 4) (tuple 'active 'false))` against the test
listener, plus `xrepl-protocol-msgpack` directly:

1. connect; send garbage bytes (e.g. `#"not msgpack"`) as one frame;
2. recv + decode → assert a `status` = `error` / decode-error reply arrives;
3. send a *valid* encoded eval frame on the same socket; recv → assert a
   `#"done"` reply.

On pre-fix code, step 3 fails (`{error, closed}` — the handler died). That is
your red. No idle wait involved; this test is fast.

## Fix 2 — F-7: fold the orphaned parens

`src/xrepl-tcp-handler.lfe:78` — the keepalive deletion left `)))` alone on a
line after the `tcp_error` clause. Fold onto the preceding line
(`'ok))))` shape), per the style rule "all closing parens on the same line".
Compile is the check; no behaviour change.

## What this iteration is NOT

- **No test rename.** The keepalive test's 31 s pause alarmed nobody yet;
  the operator has explicitly deferred renaming until someone complains.
- **No fix for the decode-error request-id literal** (`#m(id (binary
  "unknown"))` produces a list, moot via `send-response`'s key-mismatch
  default). Same defect family as the keepalive id; disclosed-deferred to
  Arc 06 — noted in CDC-7's disposition. Leave it.
- **No other findings** (L-02 packet cap is slice5; L-04/L-05/L-09 are
  slices 2-4; dispatcher/boundary work is Arc 06).
- **No rebase/amend** of existing commits.

## Deliverable

- Two commits minimum: the red test, then the fixes (one commit for both
  fixes is fine — F-7 is compile-checked, not behaviour).
- `ledger.md`: rows F-6/F-7 added and closed with evidence; Closure tally
  updated to 7 rows; one What-Worked line if something generalises.
- `closing-report.md`: an iteration-3 addendum walking F-6 and F-7 — per-row
  dispositions, including the red output for F-6.

## Stop conditions

- F-6's test won't go red on pre-fix code → your understanding of the path is
  wrong; stop and report, don't proceed.
- The one-token fix changes any *other* test's outcome → stop, flag.
- Anything beyond the two fixes seems needed → amendment request, not scope
  creep. Two iterations remain in the budget after this one.
