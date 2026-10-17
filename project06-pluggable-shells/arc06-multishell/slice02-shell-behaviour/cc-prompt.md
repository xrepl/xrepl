# CC PROMPT — arc6 / slice2: the `xrepl-shell` behaviour + `xrepl-shell-lfe`

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (a sibling CDC/Opus instance), reviewed by Duncan (lead + QA).

**Mission (one line):** Introduce a pluggable-shell abstraction for xrepl — an
`xrepl-shell` **behaviour** plus a faithful default implementation
`xrepl-shell-lfe` that reproduces the current LFE eval semantics — **as new
modules only**, fully unit-tested, with **zero changes to the live eval path**.

**Decision-of-record:** `docs/design/0.1.0/arc6-multishell/shell-seam-decision.md`
(read it). This slice builds the abstraction; a later slice rewires the session
onto it. Do **not** rewire anything in this slice.

---

## Scope — exactly three new files; nothing else changes

CREATE:
1. `src/xrepl-shell.lfe` — the behaviour (verbatim below).
2. `src/xrepl-shell-lfe.lfe` — the default LFE shell implementing it.
3. `test/xrepl-shell-lfe-tests.lfe` — eunit tests.

DO **NOT** modify any existing module — in particular **not** `xrepl-session.lfe`,
`xrepl-dispatcher.lfe`, `xrepl-eval.lfe`, `xrepl-env.lfe`. You will **call**
`xrepl-eval` and `xrepl-env` (reuse), never edit them. No git. No commits.

## Hard rules
- **Content-agnostic.** This is generic xrepl infrastructure. No story content;
  never the words "ground"/"support"/narrative anywhere.
- **House LFE style** (see `lfe-manual` style guide): 2-space indent, ≤80 cols,
  lowercase-hyphen atoms, `CamelCase`→ no (use hyphen names), docstrings on every
  exported function, `defrecord` for state, behaviour written in the exact shape
  of `src/xrepl-transport.lfe`.
- **Verify green:** run `rebar3 as test eunit --module xrepl-shell-lfe-tests`
  AND the full suite `rebar3 as test eunit`; report both. Nothing else may break
  (it can't — you changed no existing module — but confirm).

---

## File 1 — `src/xrepl-shell.lfe` (use verbatim)

```lfe
(defmodule xrepl-shell
  "Behaviour for xrepl shells: pluggable read/eval/print front-ends.

  A shell interprets a session's input line and produces a result value plus
  its own next state. The default shell (xrepl-shell-lfe) evaluates LFE; other
  shells may implement entirely different languages or command sets over the
  same xrepl protocol. Shell state is per-session and opaque to the session."
  (export (behaviour_info 1)))

(defun behaviour_info
  "Define the xrepl-shell behaviour callbacks."
  (('callbacks)
   '(;; (init Opts) -> {ok, ShellState} | {error, Reason}
     ;;   Opts is a map. Build the shell's initial per-session state.
     #(init 1)

     ;; (eval Input ShellState Ctx) ->
     ;;     {ok, Value, ShellState2}            ; normal turn
     ;;   | {switch-shell, Mod, Opts, Value}    ; hand off to another shell
     ;;   | {error, ErrorInfo}                  ; diegetic/normal error
     ;;   Input is the raw input (string, or already-parsed term).
     ;;   Ctx is a map (session-id, transport-type, ...).
     ;;   Value flows back as the eval result the dispatcher interprets
     ;;   (a normal term, or #(formatted Text), or a switch tuple).
     #(eval 3)

     ;; (describe ShellState) -> map()
     ;;   Capability map for this shell, merged into the `describe` op.
     #(describe 1)))
  ((_) 'undefined))
```

Note: `prompt/1` and `terminate/2` are OPTIONAL future callbacks — `xrepl-shell-lfe`
MAY implement `prompt/1` (recommended) but do NOT list them in `behaviour_info`
(keeps them optional). Required callbacks are exactly `init/1`, `eval/3`,
`describe/1`.

## File 2 — `src/xrepl-shell-lfe.lfe` (implement to this spec)

State record:
```lfe
(defrecord lfe-shell-state
  env             ;; the LFE environment (lfe_env)
  session-id)     ;; session id string (or 'undefined)
```

### `(init Opts)` -> `{ok, ShellState} | {error, Reason}`
`Opts` is a map. Behaviour:
- If `Opts` has key `env`, use it; else build a fresh base env via
  `(xrepl-env:new "" '() 'false)` (mirror how `xrepl-session:init` builds
  `base-env`; signature is `xrepl-env:new/3` = name, bindings, remote?).
- `session-id` from `Opts` (key `session-id`) or `'undefined`.
- Return `{ok, (make-lfe-shell-state env Env session-id Id)}`.
(Full restore-from-snapshot + `$session-id` injection stays in the *session* and
arrives later via `Opts`; do NOT duplicate that logic here.)

### `(eval Input ShellState Ctx)` -> result
Reproduce the CURRENT semantics, which today are split across
`xrepl-session:prepare-form/1` (parse) + `xrepl-eval:eval-form/2` (eval) +
`xrepl-env:update-shell-vars/3` (history vars). Move the parse into this shell:

1. **Parse.** Port `prepare-form/1` from `xrepl-session.lfe` (lines ~262–294)
   into a private `prepare-form/1` here (string of char codes →
   `lfe_io:read_string/1` → first form; already-parsed list/term → as-is; `'()`
   is valid). On parse failure return `{error, #(parse Reason)}`.
2. **Eval**, wrapped in `try`:
   - `(xrepl-eval:eval-form Form Env)`:
     - `#(ok ,Value ,NewEnv)` →
       `FinalEnv = (xrepl-env:update-shell-vars Form Value NewEnv)`;
       return `{ok, Value, (set-lfe-shell-state-env ShellState FinalEnv)}`.
     - `#(error ,Reason)` → `{error, #(eval Reason)}`.
   - `catch (tuple Class Reason Stack)` →
     `{error, #(exception Class Reason Stack)}`.
   (This mirrors `xrepl-session:evaluator-loop` lines ~315–334 exactly, minus the
   process/messaging — that stays in the session.)

This slice does NOT emit `{switch-shell, ...}` — that arrives in slice5. But
honor the contract shape so slice3/5 don't redefine it.

### `(describe ShellState)` -> map()
Return a capability map for the LFE shell, e.g.
`#m(name #"lfe" kind #"language" prompt #"lfe> ")`. (The `describe`-op merge
happens in slice4; here just return the map.)

### `(prompt ShellState)` -> binary()  (optional, implement it)
Return the prompt binary (e.g. `#"lfe> "`, or pull from config if trivial).

## File 3 — `test/xrepl-shell-lfe-tests.lfe` (eunit)
Cover, with EXACT assertions (no `contains?`-style looseness):
- `init` with `#m()` returns `{ok, State}` whose env is a usable lfe_env.
- `init` with `#m(env E session-id "s1")` wraps the given env + id.
- `eval "(+ 1 2)"` → `{ok, 3, State2}`.
- env threads: `eval "(set x 10)"` then `eval "x"` against the returned state → `10`.
- `update-shell-vars` ran: after an eval, the LFE history var is set (assert by
  evaluating the relevant shell var, per `xrepl-env:update-shell-vars` semantics
  — read that function to find the exact var name; assert the real one).
- parse error: `eval "(("` → `{error, #(parse ...)}`.
- eval error: a clean runtime error (e.g. an unbound function `(zzznope 1)` or a
  bad arithmetic) → `{error, #(eval ...)}` or `{error, #(exception ...)}` —
  assert which one it actually is and lock it.
- `describe` returns a map with `name` = `#"lfe"`.
- `prompt` returns a binary.

Spike-quality is not enough here — these are real, kept tests proving the LFE
shell reproduces current eval semantics. They are the contract slice3 will rely on.

---

## Done criteria (self-check before hand-back)
- [ ] Three files created; **no existing module modified**; no git run.
- [ ] `behaviour_info/1` lists exactly `init/1`, `eval/3`, `describe/1`.
- [ ] `xrepl-shell-lfe` reproduces parse + eval + update-shell-vars faithfully,
      with the `{ok,…}` / `{error,#(parse|eval|exception …)}` contract above.
- [ ] All new tests pass; full suite still green; both runs reported.
- [ ] House style; docstrings on exports; content-agnostic (no story words).

## What to hand back
A short message: the three files, the test run output (new module + full suite),
the exact error-result shapes you locked for parse vs eval vs exception (so the
design lead can confirm slice3 consumes them correctly), and anything in the
current `prepare-form`/`eval-form`/`update-shell-vars` code that surprised you or
that the spec got slightly wrong.
