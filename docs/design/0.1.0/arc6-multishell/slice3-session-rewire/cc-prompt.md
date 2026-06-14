# CC PROMPT — arc6 / slice3: rewire `xrepl-session` onto the shell

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

**Mission:** Make `xrepl-session` delegate evaluation to a **per-session active
shell** (default `xrepl-shell-lfe`, built in slice2) instead of hardwiring the
LFE eval path. Move the env lifecycle (build/restore/serialize) into the shell.
**Preserve every public contract; keep the entire test suite green.** Delete the
now-dead session code, including a latent parse-error bug (Duncan approved
delete-not-patch).

**Read first:** `docs/design/0.1.0/arc6-multishell/shell-seam-decision.md`
(the locked `eval/3` contract from slice2, and the bug write-up). The slice2
modules `src/xrepl-shell.lfe`, `src/xrepl-shell-lfe.lfe`,
`test/xrepl-shell-lfe-tests.lfe` are in place and green.

---

## NON-NEGOTIABLE: public contracts to preserve (tests enforce these)

1. **`xrepl-session:eval/2` returns `#(ok Value)` | `#(error Msg)`** — unchanged.
   Callers: `xrepl-dispatcher` (L100), spike tests, multi-session tests.
2. **`eval/2` accepts BOTH a string AND an already-parsed form.** The
   multi-session tests call `(xrepl-session:eval id '(set x 42))` (a quoted
   form) and `(... id "(+ 1 2)")` (a string). The shell's `prepare-form`
   already handles both — do not regress this.
3. **Save/restore round-trips, stored under the literal key `'env-snapshot`.**
   `test/xrepl-multi-session-tests.lfe` asserts `(maps:is_key 'env-snapshot
   session-data)` after `save-state`, and tests session isolation + recovery.
   The session's save path MUST keep using key `'env-snapshot`, and the
   shell's snapshot must round-trip bindings so recovery still works.
4. **`get-env/1`** has no external callers but stays functional (its own
   `handle_call 'get-env` clause). Keep it returning the live LFE env (extract
   from the LFE shell-state). Document it as LFE-shell-specific.

If ANY existing test goes red and you can't immediately see why, **STOP and
report** — do not paper over it, loosen an assertion, or `#(ignore)` it.

---

## Hard rules
- Content-agnostic; no story words anywhere. No git/commits.
- House LFE style; docstrings on exports; `defrecord` for state.
- **Run `rebar3 as test eunit` (full suite) after Phase B and again after
  Phase C.** Report both runs. Green is the bar.

---

## Work in three ordered phases

### Phase A — give the LFE shell the full env lifecycle
Edit `src/xrepl-shell.lfe`: add `#(snapshot 1)` to `behaviour_info` callbacks
(required list becomes `init/1`, `eval/3`, `describe/1`, `snapshot/1`).

Edit `src/xrepl-shell-lfe.lfe`:
- **Expand `init/1`.** `Opts` is a map with keys: `remote?` (bool, default
  `'false`), `session-id` (string | `'undefined`), `snapshot` (a stored
  snapshot term | `'undefined`), and optionally `env` (a pre-built env, for
  tests). Behaviour:
  - if `env` present → use it; else build `(xrepl-env:new "" '() Remote?)`.
  - if `snapshot` present and not `'undefined` → restore bindings into the env
    (port `restore-env-from-snapshot/2` from `xrepl-session.lfe` ~L434).
  - inject session id: `(lfe_env:add_vbinding '$session-id SessionId Env)`
    (mirrors `xrepl-session:init` ~L127).
  - return `{ok, (make-lfe-shell-state env FinalEnv session-id SessionId)}`.
- **Add `snapshot/1`** → `(snapshot ShellState) -> map()`. Port
  `serialize-env/1` + `filter-serializable-bindings/1` + `is-serializable?/1`
  from `xrepl-session.lfe` (~L354–396). Operate on the env inside the
  shell-state; return the SAME shape currently stored: `#m(bindings [...])`.
- **Add an env accessor** the session can use for `get-env`, e.g.
  `(env-of ShellState) -> env` (export it).
- Update `test/xrepl-shell-lfe-tests.lfe`: add cases for `init` restoring from a
  snapshot, and `snapshot` returning `#m(bindings …)` that round-trips through
  `init`. Keep all existing slice2 tests passing.

**Run the suite.** Still green (no session change yet).

### Phase B — flip `xrepl-session` to delegate
Edit `src/xrepl-session.lfe`:
- **State record:** replace `env` with `shell` + `shell-state`:
  `(defrecord session-state id shell shell-state evaluator eval-pending
   last-save save-interval)`.
- **`init/1`:** keep the transport/remote? detection
  (`get-transport-type`, `is-remote-transport?` stay). Read the stored snapshot
  (from `xrepl-store:get-session` → `'env-snapshot`, or `'undefined`). Then:
  ```
  Shell      = 'xrepl-shell-lfe                       ; default shell
  {ok, SS}   = (Shell:init #m(remote? R session-id Id snapshot Snap))
  Evaluator  = (start-evaluator Id Shell SS)
  ```
  Store `shell Shell shell-state SS` in the record.
- **`eval/2`** (public): unchanged signature; still
  `(gen_server:call (process-name Id) (tuple 'eval Input) 5000)`. Update the
  docstring (it's raw input now, not necessarily a parsed form).
- **`handle_call #(eval Input)`:** do NOT parse. Send
  `(! Evaluator (tuple 'eval Input (self)))`, stash `from` in `eval-pending`,
  `noreply`. (Delete the `prepare-form` call and its parse-error reply branch —
  parse errors now return from the shell as `#(eval-error #(parse …))`.)
- **`handle_call 'get-env`:** return `(xrepl-shell-lfe:env-of (session-state-shell-state state))`.
- **`start-evaluator`/`evaluator-loop`:** now carry `(SessionId Shell ShellState)`.
  Loop on `#(eval Input reply-to)`:
  - add history (render `Input` to a string for `xrepl-history:add`; if `Input`
    is a list of char codes use as-is, else `lfe_io:print1`).
  - `(call Shell 'eval Input ShellState Ctx)` (Ctx = `#m(session-id SessionId)`):
    - `{ok, Value, SS2}` → `! reply-to #(eval-result Value SS2)`; loop SS2.
    - `{error, ErrorInfo}` → `! reply-to #(eval-error ErrorInfo)`; loop ShellState.
    - (a `{switch-shell, …}` clause is NOT needed yet — the LFE shell never
      emits it; slice4 adds it. Do not add a switch path now.)
  - keep the surrounding `try`/`catch` as a safety net →
    `#(eval-error #(exception Class Reason Stack))`.
- **`handle_info #(eval-result Value SS2)`:** reply `#(ok Value)`; set
  `shell-state := SS2`; `maybe-save-state`; `xrepl-store:touch-session`.
- **`handle_info #(eval-error ErrorInfo)`:** map to a message and reply
  `#(error Msg)`:
  - `#(eval Str)` → `Msg = Str` (already a flat char list).
  - `#(parse R)` → `Msg` = a readable parse-error string.
  - `#(exception Class Reason Stack)` → `Msg = (xrepl-io:format-error Class
    Reason Stack)` (reuse the existing formatter — preserves current behaviour).
- **`handle_info` evaluator EXIT/restart:** `start-evaluator` with the current
  `Shell` + `ShellState`.
- **`save-state-to-store`:** `(maps:put 'env-snapshot (call Shell 'snapshot
  ShellState) session-data)` — SAME key `'env-snapshot`.

**Run the full suite.** It MUST be green. The high-risk tests are
`xrepl-multi-session-tests.lfe` (isolation + persistence + recovery) and the
spike tests (eval value/error shapes). If red → STOP and report.

### Phase C — delete the dead code
From `src/xrepl-session.lfe`, delete (now owned by the shell):
`prepare-form/1` (this is the **latent-bug** clause — gone, not patched),
`serialize-env/1`, `filter-serializable-bindings/1`, `is-serializable?/1`,
`restore-env/1`, `restore-env-from-snapshot/2`. Keep `get-transport-type`,
`is-remote-transport?`, `maybe-save-state`, `save-state-to-store`, `format-form`.

**Run the full suite again.** Green.

---

## Done criteria
- [ ] `eval/2` contract + both input types + `'env-snapshot` key preserved.
- [ ] Env lifecycle (build/restore/serialize) lives in `xrepl-shell-lfe`.
- [ ] Session delegates to `(session-state-shell …)`; default `xrepl-shell-lfe`.
- [ ] Dead code + the latent parse-bug clause deleted.
- [ ] Full suite green after Phase B AND Phase C; both runs reported.
- [ ] No story words; no git.

## Hand back
The diff summary (modules touched, funcs moved/deleted), both full-suite runs,
confirmation the multi-session persistence/isolation/recovery tests pass, and
anything that didn't match this spec (e.g. an unexpected caller, a tuple shape
that differed) — flag it rather than working around it silently.
