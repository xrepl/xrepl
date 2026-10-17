# CC PROMPT — arc6 / slice5: the did-you-mean / command-not-found hook

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

**Mission:** Add a small, generic "did-you-mean" nudge to the LFE shell: when the
user calls an **unbound** function whose name is in a configured suggestion
table, return a friendly hint instead of a raw error. Seed it so that
`(pwd)` / `(passwd)` / `(password …)` suggest `(xs:run '<name>)`.

**Read first:** the gotchas in `lfe/lfe/workbench/lfe-proto-skill.md` (verify
`lfe_env` API names against source!) and
`docs/design/0.1.0/arc6-multishell/shell-seam-decision.md`. slices 2–4 are
landed and green (75/75).

## Scope
EDIT `src/xrepl-shell-lfe.lfe`; ADD tests to `test/xrepl-shell-lfe-tests.lfe`
(or a new `test/xrepl-shell-lfe-suggest-tests.lfe`). Touch nothing else. No git.

## Hard rules
- **Only fire for UNBOUND symbols in the suggestion table.** Never hijack a
  symbol the user has actually bound as a function — if they `(defun pwd …)`,
  `(pwd)` must call their function normally.
- Normal eval is untouched: `(+ 1 2)` → `3`; an unbound symbol NOT in the table
  (e.g. `(zzznope 1)`) → the **same** error as today (no suggestion).
- Content-agnostic mechanism; the seed list is the only story-flavoured part and
  it's fine in tracked code (Duncan's call). House style; docstrings. No git.

## Where it goes
Inside `xrepl-shell-lfe:eval/3`, **after** `prepare-form` parses the input into a
`Form` and **before** calling `xrepl-eval:eval-form`:

1. If `Form` is a function call `(Sym . Args)` where `Sym` is an atom (skip
   atoms, numbers, non-call forms — they go straight to normal eval); AND
2. `Sym` is in the suggestion table; AND
3. `Sym` is **not** a bound function in the env at the called arity — check with
   the real `lfe_env` API (find it in `lfe/src/lfe_env.erl`; do NOT guess the
   name — per the proto-skill gotcha, plausible names like `*_fbound` may or may
   not exist; verify);

then short-circuit: return a suggestion response **without evaluating** and
**without changing the shell state** (env unchanged). Otherwise fall through to
the normal `eval-form` path unchanged.

## The suggestion
- Table: the trigger set `#(pwd passwd password)` (a small list/set in the
  module; keep it trivial to extend).
- The hint **substitutes the typed name**: `(pwd)` → suggest `(xs:run 'pwd)`;
  `(password …)` → suggest `(xs:run 'password)`. Build the string from `Sym`.
- Return shape: `#(ok #(formatted Text) ShellState)` where `Text` is e.g.
  `"Did you mean (xs:run 'pwd)?"`. (A normal `#(formatted …)` hint reads as a
  helpful nudge; the dispatcher already renders it. If you find an `#(error …)`
  shape reads better as "command not found," note it — but default to the
  formatted hint.)

## Forward reference (do NOT implement here)
`xs:run` does **not exist yet** — it's wired in Arc8 (the story shell). slice5
only *emits the suggestion text*; typing `(xs:run 'pwd)` will still error until
Arc8. That's expected. **Do not** add `xs:run` to the suggestion table (it must
never suggest itself), and do not stub `xs:run`.

## Tests
- `(pwd)` (unbound) → `#(ok #(formatted T) _)` where `T` contains `(xs:run 'pwd)`;
  env/state unchanged.
- `(passwd)` → contains `(xs:run 'passwd)`; `(password 1 2)` → contains
  `(xs:run 'password)` (name substituted, args ignored).
- `(zzznope 1)` (unbound, NOT a trigger) → the normal error path (assert it is
  NOT a suggestion — i.e. still an `#(error …)` / `{error, …}` as before).
- **No-hijack:** `(set-then-call)` — bind `pwd` as a function first
  (`(defun pwd () 'real)` via eval), then `(pwd)` → returns `'real`, NOT a
  suggestion. (This proves the unbound guard.)
- `(+ 1 2)` → `3` (normal eval unaffected).

## Done criteria
- [ ] Hook fires only for unbound table symbols; never hijacks bound functions.
- [ ] Suggestion substitutes the typed name; `xs:run` NOT in the table.
- [ ] Non-trigger unbound calls and normal eval behave exactly as before.
- [ ] New tests + full suite green; both reported.
- [ ] `lfe_env` function-binding check uses a verified real API (name confirmed
      against source, per the gotcha).

## Hand back
The change, the full-suite run, the exact `lfe_env` function you used for the
unbound check (and how you confirmed it exists), and the response shape you chose
(formatted hint vs error). Flag anything that differed from this spec.
