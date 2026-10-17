# Shell seam — design decision (post-audit)

> Design note. Records the architecture decision taken after CC's
> slice1 capability audit (`slice1-capability-audit/REPORT.md`). This is the
> design-of-record for the pluggable-shell seam; it seeds the Arc6 cc-prompts.

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
                                | {switch-shell, TargetMod, InitOpts, Response}
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
  `{switch-shell, Mod, Opts, Response}` (distinct from the dispatcher's existing
  `#(switch …)` *session*-switch); the loop calls `(Mod:init Opts)`, swaps the
  two session fields, and returns `Response` (which announces the now-active
  shell so the client updates its prompt). `(xs:run 'pwd)` in the LFE shell →
  switch to `xs-shell`; story `/quit` → switch back to `xrepl-shell-lfe`.
- **Closes the MAJORs with one seam.** (c) did-you-mean lives in
  `xrepl-shell-lfe:eval/3` (raw `{undef,...}` term is reachable in its catch —
  CC confirmed); (e) `describe` becomes a merge of registered shells'
  `describe/1`; (f) the `image` field is just an extra key a shell adds to its
  response map (encoder not field-locked — CC proved by test).

## LOAD-BEARING GUARDRAIL (into every Arc6 cc-prompt)

`xrepl-shell-lfe` MUST wrap the existing eval path so the default REPL is
behaviorally unchanged and **every current xrepl test stays green**. Arc6 is a
refactor-behind-an-interface, not a behavior change. Day-one observable
difference for a normal LFE user = zero.

## Revised arc plan

- **Arc6 — shell seam (xrepl core; generic, shippable, zero story content):**
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
- **Arc7 — `xs` engine (content-agnostic, pure; also the future Lykn browser
  reader's shared core):** `xs-bundle` (load+validate from `.xsf`), `xs-world`,
  `xs-engine` (pure `handle/3`).
- **Arc8 — story shell + wiring:** `xs-shell` (`xrepl-shell` impl) bridging
  `xs-engine` to the protocol; loads `priv/support.xsf`; world-in-metadata
  save/resume; images via `xrepl-term-graphics:render-data/2`.
- **Arc9 — content + polish:** `deep/` + `endings/` content, `egg-in-basket`
  client gating, cross-VM "save game" if wanted (`xrepl-store` export/import).

Naming holds: `xrepl-shell*` / `xs-*` are generic + visible; `support.xsf` is
the only story-specific artifact — the narrative lives only inside it (opaque).
These docs are public (deep-divers earn the reward); committed `xs-*`/`xrepl-shell*` code is content-agnostic.

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

## slice3 — DONE (accepted 2026-06-14)

Session rewired onto the active shell. 63/63 green after Phase B and Phase C;
multi-session isolation/persistence tests pass (they enforce `eval/2` contract +
env-threading + both input types). Phase A expanded `xrepl-shell-lfe`
(`init/1` now handles remote?/snapshot/session-id; added `snapshot/1`,
`env-of/1`). Phase B: `session-state` `env` → `shell`+`shell-state`; loop calls
`shell:eval/3`; error routed via `eval-error-to-msg`; save uses `shell:snapshot`
under the same `'env-snapshot` key. Phase C: deleted `prepare-form` (+ the latent
parse-bug clause), `serialize-env`, `filter-serializable-bindings`,
`is-serializable?`, `restore-env`, `restore-env-from-snapshot`.

**MAJOR finding — persistence was silently broken in shipping xrepl.** Old
`serialize-env` called `lfe_env:get_vbindings` (does not exist in LFE 2.2); a
`try/catch` swallowed it and stored an EMPTY snapshot → reopen restored nothing.
CC's `snapshot/1` uses the real `lfe_env:get_vars/1` and now captures bindings
correctly. So slice3 silently FIXED a latent bug (good, but not behavior-neutral
as billed).

**TEST GAP (action).** `session-persistence-basic` / `session-recovery` only
assert `(maps:is_key 'env-snapshot …)` — they passed with BOTH the broken empty
snapshot and the real one. No test closes→reopens→asserts a restored value, so
working save/restore is UNPROVEN. Arc8 save/resume depends on this path → add a
`session-restore-roundtrip` test (set → save → close → reopen → assert value)
before building on it. **RESOLVED 2026-06-14:** `session-restore-roundtrip`
added (strict `#(ok 12345)` assertion + loud-failure branch); 64/64 green; the
fix is PROVEN — in-VM binding save/resume round-trips end-to-end. Arc8 save/resume
foundation is solid.

**LFE gotcha (for future cc-prompts):** `(and …)`/`(or …)` are functions
(evaluate all args); `(andalso …)`/`(orelse …)` short-circuit. CC's
`(and (is_list x) (is_integer (car x)))` crashed on atom input until switched to
`andalso`.

## slice4 — DONE (accepted 2026-06-14)

Switching + echo shell + describe-merge. 75/75 green (+11 new). The seam is
proven end-to-end: `xrepl-shell-switching-tests.lfe` starts a session in
`xrepl-shell-echo`, echoes, switches on `"quit"`, and asserts the session then
evaluates `(+ 1 2)` → `#(ok 3)` (genuinely back in LFE), and `describe`'s
advertised shell flips `#"echo"`→`#"lfe"` across the switch. Switch threading:
shell `eval/3` → `#(switch-shell Mod Opts Response)` → evaluator-loop inits Mod →
`#(eval-result-switch Response Mod NewSS)` → session sets `shell`+`shell-state`.
`shell` opt on `create` selects the starting shell (default `xrepl-shell-lfe`);
`get-env` guarded to the LFE shell; `describe` omits `'shell` cleanly when no
session.

**Incidental fix:** `xrepl-session-manager:create` set metadata AFTER
`start-session`, so `init` couldn't read it; fixed by pre-building metadata
(incl. `shell`) before the spawn. Also makes transport-type correct at init.
(Second incidental correctness fix this arc, after the persistence one.)

## slice5 — WRITTEN (the did-you-mean breadcrumb)

Hook in `xrepl-shell-lfe:eval/3`: an UNBOUND call to a seeded trigger
(`pwd`/`passwd`/`password`) returns `#(formatted "Did you mean (xs:run '<name>)?")`
instead of a raw error; never hijacks a bound function; non-trigger unbound calls
and normal eval untouched. `xs:run` is a FORWARD REFERENCE — wired in Arc8; slice5
only emits the suggestion text (don't seed/stub `xs:run`).

## Arc6 status
slices 1–4 DONE; slice5 written/queued. After slice5 lands, the multishell seam
is complete: pluggable + per-session-switchable + advertised shells, with proven
save/resume. Forward: Arc7 (`xs` engine — slice1 `xs-bundle` cc-prompt already
written, fully parallel) and Arc8 (`xs-shell`, which makes `xs:run` real and
completes the breadcrumb).

## slice5 — DONE (accepted 2026-06-14) — Arc6 COMPLETE

did-you-mean hook landed in `xrepl-shell-lfe`. 81/81 green. Uses
`lfe_env:is_fbound/3` (verified) to fire only on UNBOUND trigger symbols;
no-hijack proven; returns `#(ok #(formatted "Did you mean (xs:run '<name>)?") …)`.

**Bait-word finding (open design tweak — Duncan's call).** `pwd` is a real
xrepl built-in (`xrepl-env` binds `pwd/0` → `lfe_xrepl:pwd`), so the hint never
fires for `(pwd)` in the live shell — the favored "shell reflex" bait is taken.
Collision is ONLY `pwd`. Taken built-ins: `cd clear ep epp exit flush h help hist
i memory p pid pp pwd q quit regs sesh-* uptime`. FREE thematic words (all fire):
`passwd password login unlock secret key knock sesame open door enter auth
authenticate`. Recommendation: drop `pwd`, seed door-themed free words
(`password passwd unlock open knock sesame secret login`) — a one-line seed-list
edit. **DECIDED (Duncan 2026-06-14):** that exact 8-word set; tweak cc-prompt
written (`slice5-did-you-mean/bait-words-tweak.md`). **LANDED + verified in
source:** seed = the 8 words, `pwd` removed; guard uses `andalso` + `is_fbound`;
all 8 confirmed `is_fbound=false` at runtime (default env); tests assert hints in
the default shell env. (CC's pasted report was truncated — full-suite `N/N green`
line not visible; Duncan to confirm the run.) Nit: module docstring still lists
`pwd` as an example — clean up on the next touch (Arc8). **Arc6 COMPLETE.**

Arc6 multishell seam is otherwise COMPLETE: pluggable + per-session-switchable +
advertised shells, proven save/resume, discovery hook. Two latent xrepl bugs
fixed en route (broken persistence; metadata-timing). Forward: Arc7 (`xs` engine)
+ Arc8 (`xs-shell`, completes the breadcrumb).
