# CC PROMPT — arc6 / slice4: shell switching + echo shell + describe-merge

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

**Mission:** Make the multishell seam real end-to-end — a session can **start in
a chosen shell**, a shell can **switch** the session to another shell mid-stream,
and `describe` **advertises** the active shell. Prove it with a throwaway
`xrepl-shell-echo` and an integration test that switches echo → LFE and confirms
LFE actually evaluates afterwards.

**Read first:** `docs/design/0.1.0/arc6-multishell/shell-seam-decision.md` and
the gotchas in `lfe/lfe/workbench/lfe-proto-skill.md` (esp. `andalso`/`orelse`
short-circuit; verify `lfe_*` API names). slice2/slice3 are landed and green.

## Hard rules
- **The default LFE path must stay byte-for-byte behaviorally identical.** A
  session that never switches behaves exactly as today. All existing tests green.
- Content-agnostic; the echo shell is a generic toy — no story words.
- House LFE style; docstrings on exports. No git/commits. Report full-suite runs.

## The switch contract (standardize on this)
A shell's `eval/3` may return **`#(switch-shell Mod Opts Response)`** (distinct
from the dispatcher's existing `#(switch …)` *session*-switch — do not conflate).
`Mod` = target shell module, `Opts` = its `init/1` map, `Response` = the eval
value to return to the client for this turn (typically `#(formatted Text)`).

## Work in phases

### Phase A — evaluator-loop handles the switch
In `src/xrepl-session.lfe`, the `evaluator-loop` (now carrying
`(SessionId Shell ShellState)`) currently handles `{ok,V,SS2}` and
`{error,EI}` from `shell:eval/3`. Add:
- `#(switch-shell Mod Opts Response)` →
  - `(call Mod 'init Opts)`:
    - `#(ok NewSS)` → send a switch-aware result to the session, e.g.
      `(! reply-to #(eval-result-switch Response Mod NewSS))`, then
      **loop with `(SessionId Mod NewSS)`** (the loop's active shell changes);
    - `#(error R)` → `(! reply-to #(eval-error #(switch-init-failed R)))`, loop
      unchanged.
- New `handle_info` clause `#(eval-result-switch Response Mod NewSS)`: reply
  `#(ok Response)` to the pending `from`; set BOTH `session-state` `shell := Mod`
  and `shell-state := NewSS` (so the record tracks the active shell — keeps
  get-env/save consistent); `maybe-save-state`; `touch-session`.
- `handle_call 'get-env`: guard it — return `env-of` only when the active shell
  is `'xrepl-shell-lfe`; otherwise return `'undefined`. (No external callers; a
  non-LFE shell has no LFE env.)
- **Out of scope for slice4:** a switched shell surviving `close`/`reopen`
  (reopen restarts in the created/default shell). In-VM switching only here.

### Phase B — start a session in a chosen shell
Let `xrepl-session-manager:create` accept an optional `shell` in its opts (it
already stores opts as metadata). In `xrepl-session:init`, read the active shell
as `(maps:get 'shell Metadata 'xrepl-shell-lfe)` and `(Shell:init InitOpts)`
where `InitOpts` carries `session-id`, `remote?`, `snapshot` (each shell takes
what it needs; echo ignores most). Default unchanged → `'xrepl-shell-lfe`.

### Phase C — `src/xrepl-shell-echo.lfe` (throwaway toy shell)
Implement the `xrepl-shell` behaviour (`init/1`, `eval/3`, `describe/1`,
`snapshot/1`; `prompt/1` optional):
- `init/1` → `#(ok #m())` (trivial state).
- `eval/3 (Input State _Ctx)`: render `Input` to text (handle string OR
  already-parsed term). If the text is `"quit"` or `"exit"` →
  `#(switch-shell xrepl-shell-lfe #m() #(formatted #"Leaving echo shell."))`;
  else → `#(ok #(formatted <iolist of "echo: " ++ Input>) State)`.
- `describe/1` → `#m(name #"echo" kind #"toy" prompt #"echo> ")`.
- `snapshot/1` → `#m()` (nothing to persist).

### Phase D — describe advertises the active shell
Add `xrepl-session:describe/1` (API) that returns the active shell's `describe/1`
map (call `(call Shell 'describe ShellState)`). In `xrepl-dispatcher:handle-describe`,
if `context` has a session-id, include that map under a `'shell` key in the
response. No session → omit. Keep the existing `versions`/`ops`/`transports`
fields. (Remember: shell `describe/1` returns ATOM keys + BINARY values —
`maps:get 'name Desc`, not a binary key.)

## Tests
`test/xrepl-shell-echo-tests.lfe` (unit):
- `init` → ok; `eval "hi"` → `#(ok #(formatted …"echo: hi"…) _)`;
  `eval "quit"` → `#(switch-shell xrepl-shell-lfe …)`; `describe` name = `#"echo"`.

Switching integration (in `xrepl-multi-session-tests.lfe` or a new
`xrepl-shell-switching-tests.lfe`):
- create a session with `#m(shell xrepl-shell-echo)`;
- `(xrepl-session:eval id "hi")` → `#(ok #(formatted …"echo: hi"…))`;
- `(xrepl-session:eval id "quit")` → `#(ok #(formatted …"Leaving echo shell."…))`;
- **then** `(xrepl-session:eval id "(+ 1 2)")` → `#(ok 3)` — proves the session is
  genuinely back in the LFE shell after the switch (the load-bearing assertion).
- describe: a default (lfe) session's `describe` response carries `'shell` with
  name `#"lfe"`; after switching to echo (or starting in echo), name `#"echo"`.

## Done criteria
- [ ] `#(switch-shell …)` handled; session record tracks the active shell.
- [ ] `create` honors a `shell` opt; default still `xrepl-shell-lfe`.
- [ ] `xrepl-shell-echo` + unit tests; switching integration test (incl. the
      post-switch `(+ 1 2)` → 3 assertion).
- [ ] `describe` carries the active shell's map.
- [ ] Full suite green (incl. slice3 + the round-trip addendum). Both reported.
- [ ] Default LFE session behavior unchanged; content-agnostic; no git.

## Hand back
Modules touched, the full-suite run, the exact `#(switch-shell …)` threading you
implemented (message names through the session), and anything that differed from
this spec (e.g. how `shell` rides in metadata, any get-env guard surprises).
