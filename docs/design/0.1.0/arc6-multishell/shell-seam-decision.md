# Shell seam — design decision (post-audit)

> Workbench, gitignored. Records the architecture decision taken after CC's
> slice1 capability audit (`slice1-capability-audit/REPORT.md`). This is the
> design-of-record for the pluggable-shell seam; it seeds the Arc0 cc-prompts.

## Audit outcome (CC, 2026-06-14)

xrepl **cannot host or switch shells today**. All eval flows through one
hardcoded path: dispatcher → `xrepl-session:eval` → evaluator-loop →
`xrepl-eval:eval-form` → `lfe_eval:expr`. Gaps: (a) register+switch shells
MAJOR, (b) per-session alternate evaluator MAJOR, (c) did-you-mean hook MINOR,
(d) streaming BLOCKER, (e) capability advertisement MAJOR, (f) response
extension field MINOR. Spike tests: `test/xrepl-shell-pluggability-spike-tests.lfe`
(8, all pass).

## Decisions

- **Streaming (d): DEFERRED** (Duncan) — much later. The IF shell is single-turn
  command→response for v1. The behaviour is the growth point; add a streaming
  `eval/3` result variant later without disturbing the seam.
- **Switch granularity: PER-SESSION** (Duncan) — one+one field in `session-state`,
  default shell = `xrepl-shell-lfe`.
- **Shell contract: an `xrepl-shell` BEHAVIOUR** (design lead) — parallel to the
  existing `xrepl-transport` behaviour. Idiomatic, statically checkable,
  house-consistent. (Rejected: callback-record — more dynamic, not checked, no
  precedent.) PENDING Duncan's bless.

## The `xrepl-shell` behaviour

```
callbacks:
  (init Opts)                  -> {ok, ShellState} | {error, R}
  (eval Input ShellState Ctx)  -> {ok, Response, ShellState2}
                                | {switch, TargetMod, InitOpts, Response}
                                | {error, R}
  (describe ShellState)        -> CapabilityMap     ; merged into `describe` op
  (prompt ShellState)          -> binary()          ; OPTIONAL
  (terminate Reason ShellState)-> ok                ; OPTIONAL
```

- `session-state` gains `shell` (module atom, default `'xrepl-shell-lfe`) and
  `shell-state` (opaque term).
- Evaluator-loop delegates to `(call Shell 'eval Input ShellState Ctx)` instead
  of hardwiring `xrepl-eval:eval-form`; threads `ShellState2` back into the
  session.
- **Switching needs NO new dispatcher op.** `eval` returns
  `{switch, Mod, Opts, Response}`; the loop calls `(Mod:init Opts)`, swaps the
  two session fields, and returns `Response` (which announces the now-active
  shell so the client updates its prompt). `(xs:run 'pwd)` in the LFE shell →
  switch to `xs-shell`; story `/quit` → switch back to `xrepl-shell-lfe`.
- **Closes the MAJORs with one seam.** (c) did-you-mean lives in
  `xrepl-shell-lfe:eval/3` (raw `{undef,...}` term is reachable in its catch —
  CC confirmed); (e) `describe` becomes a merge of registered shells'
  `describe/1`; (f) the `image` field is just an extra key a shell adds to its
  response map (encoder not field-locked — CC proved by test).

## LOAD-BEARING GUARDRAIL (into every Arc0 cc-prompt)

`xrepl-shell-lfe` MUST wrap the existing eval path so the default REPL is
behaviorally unchanged and **every current xrepl test stays green**. Arc0 is a
refactor-behind-an-interface, not a behavior change. Day-one observable
difference for a normal LFE user = zero.

## Revised arc plan

- **Arc0 — shell seam (xrepl core; generic, shippable, zero story content):**
  - slice1: capability audit ✅
  - slice2: define `xrepl-shell` behaviour + implement `xrepl-shell-lfe` as NEW
    modules reproducing current parse→eval→thread-env semantics; unit-tested;
    NO live-path changes (existing tests green by construction). cc-prompt ✅
  - slice3: rewire `xrepl-session` to delegate to the active shell
    (`shell`+`shell-state` in `session-state`, default `xrepl-shell-lfe`); the
    risky live-path refactor; all existing session/eval tests stay green.
  - slice4: switching (`#(switch-shell …)` honored in the evaluator-loop) +
    `describe` merges shells' `describe/1`; throwaway echo shell proves
    switch+advertise end-to-end.
  - slice5: did-you-mean / command-not-found hook in `xrepl-shell-lfe` (generic +
    seeded `pwd`/`passwd`/`password` → `(xs:run 'pwd)`).

## Code reality (verified against source, 2026-06-14)

Read of the live modules refined the plan:
- **The dispatcher already speaks value-tuple conventions.** `xrepl-dispatcher:
  handle-eval` (`xrepl-dispatcher.lfe:95–132`) pattern-matches the eval *value*
  for `#(formatted Text)` and `#(switch …)` / `#(switch-to-other)` before
  formatting. So story text (`#(formatted …)`) and shell-switching ride
  conventions that EXIST today — **no dispatcher/protocol changes needed for v1.**
- **Eval path is OTP-structured:** parse in `xrepl-session:prepare-form`
  (`:262–294`), eval in a *separate spawned evaluator process*
  (`evaluator-loop` `:311–334`, crash-isolated + restarted on `EXIT`), env
  threaded through the loop AND mirrored to `session-state-env` for save/restore
  (`serialize-env`/`restore-env` `:354–444`). The shell refactor must preserve
  this process isolation (shell `eval/3` runs in the evaluator process) and the
  env-snapshot save/restore (slice3 routes serialization through the shell).
- Reuse targets for `xrepl-shell-lfe`: `xrepl-eval:eval-form/2`,
  `xrepl-env:new/3`, `xrepl-env:update-shell-vars/3`, `lfe_io:read_string/1`.
- **Arc1 — `xs` engine (content-agnostic, pure; also the future Lykn browser
  reader's shared core):** `xs-bundle` (load+validate from `.xsf`), `xs-world`,
  `xs-engine` (pure `handle/3`).
- **Arc2 — story shell + wiring:** `xs-shell` (`xrepl-shell` impl) bridging
  `xs-engine` to the protocol; loads `priv/support.xsf`; world-in-metadata
  save/resume; images via `xrepl-term-graphics:render-data/2`.
- **Arc3 — content + polish:** `deep/` + `endings/` content, `egg-in-basket`
  client gating, cross-VM "save game" if wanted (`xrepl-store` export/import).

Naming holds: `xrepl-shell*` / `xs-*` are generic + visible; `support.xsf` +
this workbench are the only story-specific things; "ground" never in tracked
source; committed `xs-*`/`xrepl-shell*` code is content-agnostic.

## slice2 — DONE (accepted 2026-06-14)

CC delivered `src/xrepl-shell.lfe`, `src/xrepl-shell-lfe.lfe`,
`test/xrepl-shell-lfe-tests.lfe`. 58 tests green (49 prior + 9 new); no existing
module modified. **Locked `eval/3` contract (verified by running):**
- `{ok, Value, State2}`
- `{error, {parse, Reason}}`              ; unparseable input
- `{error, {eval, FormattedString}}`      ; runtime error, ALREADY a flat char
  list (`xrepl-eval:eval-form` catches internally) → slice3 passes it straight
  through; no need to re-run the old eval-error/format path for shell errors
- `{error, {exception, Class, Reason, Stack}}`  ; safety net, doesn't fire on
  normal errors

Other locked facts: LFE history var is `*` (star); `describe` returns ATOM keys
(`'name 'kind 'prompt`) with BINARY values (`#"lfe"` …) → slice4 merge uses
`maps:get 'name Desc` (atom key).

**Latent bug found (disposition: slice3 deletes it).**
`xrepl-session:prepare-form` (~L285) matches parse failure as 3-tuple
`#(error ,_ ,_)`, but `lfe_io:read_string/1` returns a 2-tuple `{error, Reason}`
→ unparseable input reaching the server (e.g. `"(("`) matches no clause →
`case_clause` → session gen_server CRASH. Dormant only because clients
pre-assemble forms. Sole caller is `handle_call` (L142). slice3 moves parsing
into the shell (corrected 2-tuple pattern) and DELETES this clause — fold the
fix into the refactor, do not hotfix-then-delete. (Optional standalone 1-line
fix if Duncan wants the running server hardened sooner.)
