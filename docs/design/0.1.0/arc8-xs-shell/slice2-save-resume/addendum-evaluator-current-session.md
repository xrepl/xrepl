# CC PROMPT — arc8 / slice2 addendum: let eval'd code find its session

**You are** Claude Code (Sonnet 4.6), implementing a small fix from the design
lead (sibling CDC/Opus), approved by Duncan.

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits — structured
> editor only. Clean git tree; run `git diff --stat` after and report it.

## Why
`xrepl-session-manager:get-current/0` reads the **calling process's** dictionary.
`xs:run` is evaluated inside the per-session **evaluator-loop process**, which
never sets `xrepl-current-session` — so `get-current` returns no-session there,
and slice2's resume lookup fails in real use (it passes in tests only because
the test process calls `set-current` explicitly). The save side is unaffected
(it uses `eval/3`'s `Ctx` session-id); this fixes resume.

## The fix — `src/xrepl-session.lfe`
When the evaluator process starts, register its own session as current, so any
eval'd code (`xs:run`, and any future session-aware shell command) can call
`get-current` and get the right id. Set it **inside the spawned evaluator
process** (per-process dict), at the top of `evaluator-loop` before the receive
loop (or in the spawn lambda in `start-evaluator`):

```lfe
;; evaluator process binds itself to its session for eval'd code:
(xrepl-session-manager:set-current session-id)
```

This is isolated (process dictionary, per-process) — it does NOT affect the
client/dispatcher process's own current-session tracking. Reuse the existing
public `set-current/1`; do not invent a new mechanism.

## Tests
- **Eval'd code finds its session:** start the app, create a session, and
  `xrepl-session:eval` an expression that calls
  `(xrepl-session-manager:get-current)` → it returns THAT session's id (not
  no-session), with NO manual `set-current` by the test. This proves the
  evaluator process self-registers.
- If feasible, tighten one slice2 resume test to rely on this (drop the test's
  manual `set-current`, confirm resume still finds the save). If a test must keep
  an explicit `set-current` for unrelated setup reasons, note why.

## Done criteria
- [ ] Evaluator process calls `set-current session-id` on start.
- [ ] A test proves eval'd code gets its session via `get-current` with no manual
      `set-current`.
- [ ] Full suite green (esp. the multi-session tests — confirm no regression in
      current-session behavior); both runs + `git diff --stat` reported; no `sed`.

## Hand back
The diff, both test runs + diffstat, and confirmation that `get-current` now
returns the session from inside an `eval`. Flag any multi-session-test
interaction with the new `set-current` call.
