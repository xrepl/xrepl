# Arc8 — `xs-shell` (design + build log)

> The finale: wire the proven `xs` engine (Arc7) to the multishell protocol
> seam (Arc6) so a story is playable in the REPL. `xs-shell`/`xs` are generic +
> visible (content-agnostic, neutral test fixtures); the only story-specific
> artifact is `priv/support.xsf`, packed last. Editing-safety block + LFE gotchas
> (proto-skill) prepended to every Arc8 cc-prompt.

## Slices
- **slice1 — shell core + `xs:run` entry.** `xs-shell` drives `xs-engine`
  `enter`/`handle` over a bundle; `goto`→load+enter next room; `done`/`suspend`→
  switch back to `xrepl-shell-lfe`. `xs:run` calls `xs-shell:start`
  (load + enter entry → state + rendered opening) and returns a generic
  `#(xrepl-switch-shell xs-shell #m(state State) #(formatted Opening))` sentinel;
  `xrepl-shell-lfe:eval/3` recognises that sentinel and switches (the opening room
  reaches the player as the switch Response, no `init` contract change). Graceful
  when `priv/support.xsf` is absent.
- **slice2 — save/resume (WRITTEN).** Save blob = the World map in session
  **metadata** under `'xs-save` (pure data; survives `close`/`reopen` via the
  proven Arc6 persistence path). Save points: `quit`/`exit` (shell-level
  intercept), engine `suspend`; `done` CLEARS the save. `xs:run` reads
  `'xs-save` via `xrepl-session-manager:get-current` + `xrepl-store:get-metadata`
  and either resumes (`xs-shell:resume/2` rebuilds state at the saved node +
  renders that room) or starts fresh. No session-level active-shell-persistence
  needed — metadata carries it. Deferred: per-turn autosave; auto room-render on
  a bare session reopen (resume via `(xs:run)` renders it).
  **DONE (accepted 2026-06-14, 147 green, + 1 addendum):** save via `Ctx`
  session-id works; `resume/2` + save-points (quit/suspend save, done clears)
  correct. GAP CC honestly flagged: `get-current` reads the *calling process's*
  dict; the evaluator process never sets it → `xs:run`'s resume lookup finds
  nothing in real use (tests pass only via explicit `set-current`).
  **addendum-evaluator-current-session.md:** evaluator-loop calls
  `set-current session-id` on start → eval'd code (xs:run + any session-aware
  command) can find its session. Generic infra fix.
- **slice3 — images (WRITTEN, last Arc8 slice).** `xs-bundle` keeps the `.xsf`
  `source` binary + adds `image-bytes/2` (lazy re-open zip, resolve asset id by
  stem-or-exact, `zip_get`). `process-outputs` collects image ids (pure);
  `eval`/`start`/`resume` render each best-effort via
  `xrepl-term-graphics:render-data/2` (raw bytes + `name` opt) — missing image or
  non-graphics terminal → graceful skip, text unaffected. Deferred:
  remote-transport image delivery (in-process render only). OPEN: asset-id ↔
  filename convention (node `(image "X")` = stem or full filename?) — settle when
  paintings are packed; supports both via stem-or-exact match for now.

## slice1 — DONE (accepted 2026-06-14, with one follow-up)

141/141 green; `src/xs-shell.lfe`, `src/xs.lfe` (new), `src/xrepl-shell-lfe.lfe`
(+7: generic sentinel case). Read-verified: comma-bindings complete, goto→enter→
render loop correct, sentinel non-breaking. No `sed` (editing-safety guardrail
held); diffstat reported. `ShellState` = `#m(bundle world)`; `eval/3` →
`#(ok #(formatted Bin) State2)` | `#(switch-shell xrepl-shell-lfe #m()
#(formatted Bin))`.

**FOLLOW-UP (addendum-portable-join.md) — FINAL (CI matrix confirmed):** CI
(`.github/workflows/cicd.yml`) tests **OTP 28/27/26/25**. `binary:join/2` is
OTP-28+ (STDLIB 7.0) → `undefined` on 25/26/27. So `binary:join` DOES break the
supported floor (my original portable-swap flag was right; I wrongly withdrew it
after searching the wrong dir for the CI config and finding none). CC's added
`multi_text_body_joined_by_newline_test` now CALLS `binary:join` → passes locally
(OTP 30) but would go RED on the 25/26/27 CI jobs — the test usefully converted a
latent bug into a visible one. FIX: swap `xs-shell:join-texts` to
`iolist_to_binary(lists:join #"\n" texts)` (portable to OTP 24+); keep the test.
ALSO: `xrepl-history.lfe:121` has the same `binary:join` (same latent OTP-25/26/27
bug, untested path) — fold the identical swap in. Then `grep -r binary:join` →
empty. **RESOLVED (accepted 2026-06-14):** both sites swapped to
`iolist_to_binary(lists:join …)` (verified in source — zero live `binary:join`
calls; only 3 comment/docstring mentions remain); multi-text test kept; 142/142
green. `xrepl-history` pre-existing bug fixed in the same pass. **Arc8 slice1
fully complete.** (Trivial nit: two `xs-shell-tests` docstrings still say
"binary:join" — stale wording, clean up on a future touch.)

**New LFE gotcha (logged to proto-skill):** in LFE quasiquote case patterns a
bare symbol is a LITERAL atom — `` `#(text bin) `` matches `{text, 'bin}`, not a
binding; use `` `#(text ,bin) ``.

## Deferred (named, not built in slice1)
- Images → slice3. Save/resume → slice2. Preserving the player's LFE REPL
  bindings across a story visit (switch-back uses a fresh env) → possible later
  refinement.
