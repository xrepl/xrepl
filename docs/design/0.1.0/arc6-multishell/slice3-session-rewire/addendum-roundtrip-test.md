# CC PROMPT — arc6 / slice3 addendum: prove save→close→reopen→restore

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

**Why this exists.** slice3 fixed a *silently broken* persistence bug: the old
`serialize-env` called a non-existent function (`lfe_env:get_vbindings`), a
`try/catch` swallowed it, and an EMPTY snapshot was stored — so reopen restored
nothing. CC's `snapshot/1` now captures bindings correctly. BUT our existing
persistence/recovery tests only assert `(maps:is_key 'env-snapshot …)` — they
passed under BOTH the broken and the fixed code, so the fix is **unproven**.
Arc8's save/resume (story world-state surviving `/quit`→`/game`) stands entirely
on this path. This test is the proof.

## Scope — ONE test, no production changes
Add a single test to `test/xrepl-multi-session-tests.lfe` (alongside the existing
`session-persistence-basic` / `session-recovery`). Touch no `src/`. No git.

## The test — a genuine round-trip
```lfe
(deftest session-restore-roundtrip
  (setup)
  (let ((`#(ok ,id) (xrepl-session-manager:create (map 'name "roundtrip"))))
    (xrepl-session:eval id '(set keep-me 12345))
    (xrepl-session:save-state id)
    (xrepl-session-manager:close id)        ; stops the process, preserves ETS + snapshot
    (xrepl-session-manager:reopen id)       ; restarts; init restores from snapshot
    (case (xrepl-session:eval id 'keep-me)
      (`#(ok ,12345) (is 'true))
      (other (is-equal #(ok 12345) other))))  ; loud failure shows what came back
  (teardown))
```

Notes:
- **Verify the exact session-manager API** before writing: `close/1` and
  `reopen/1` are expected (per the capability audit), but confirm the names/arity
  against `src/xrepl-session-manager.lfe` and adapt if they differ. If reopen
  needs the session to be looked up differently, follow the real API.
- Use a binding value that is plainly serializable (an integer is ideal — the
  snapshot only keeps pure data).
- If `reopen` is asynchronous (process restart), and the eval races the restore,
  add the minimal synchronization the real API offers (a blocking reopen, or a
  short wait on the session being active) — but do NOT loosen the assertion.

## CRITICAL — do not force this green
This test must genuinely pass *because restore works*. **If it fails, STOP and
report** with the actual returned value. A failure means persistence still
doesn't round-trip end-to-end (e.g. the snapshot isn't being read on init, or
`reopen` doesn't rebuild the env) — that is exactly the signal we need before
Arc8, not something to paper over. Do not delete bindings, weaken the assertion,
or mark it pending to get a green.

## Done criteria
- [ ] One new test in `xrepl-multi-session-tests.lfe`; no `src/` changes; no git.
- [ ] Full suite run reported; the new test passes *on its own merits*.
- [ ] If it can't pass, a clear report of what `(xrepl-session:eval id 'keep-me)`
      actually returned and your read of why.

## Hand back
The test, the full-suite run, and a one-line confirmation that a binding set
before `close` is present after `reopen` (or, if not, the failure detail).
