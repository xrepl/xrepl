# CC PROMPT — arc6 / slice5 tweak: finalize the did-you-mean bait words

**You are** Claude Code (Sonnet 4.6), implementing a small spec change from the
design lead (sibling CDC/Opus), approved by Duncan.

**Why:** slice5 landed the did-you-mean hook correctly, but the seed list
included `pwd` — which is a real xrepl built-in (`xrepl-env` binds `pwd/0` →
`lfe_xrepl:pwd`), so the hint never fires for it (the no-hijack guard is working
as designed). Swap the seed list to door-themed words that are all genuinely
**unbound** in the default LFE shell, so the breadcrumb actually fires.

## The change
In `src/xrepl-shell-lfe.lfe`, replace the suggestion seed list with exactly:

```
password  passwd  unlock  open  knock  sesame  secret  login
```

**Drop `pwd` entirely** (it's taken; leaving it is a dead entry).

## Verify (don't assume)
For EACH new word, confirm `(lfe_env:is_fbound 'WORD 0 Env)` is **false** in the
**default LFE shell env** (the one `xrepl-env:new` builds with shell functions
added) — not just a bare env. All eight were checked free against
`xrepl-env.lfe`'s binding table, but confirm at runtime so we know the hint
genuinely fires for a real user. If any word turns out bound, report it and drop
it rather than shipping a dead trigger.

## Tests (`test/xrepl-shell-lfe-tests.lfe` / wherever the slice5 suggest tests live)
- Replace the old `pwd`-via-bare-env test (obsolete) with default-env tests for
  representatives of the new set: e.g. `(open)` → `#(ok #(formatted T) _)` where
  `T` contains `(xs:run 'open)`; `(sesame)` → contains `(xs:run 'sesame)`;
  `(unlock 1)` → contains `(xs:run 'unlock)` (name substituted, args ignored).
- Keep the **no-hijack** test — use `passwd` (in the set, starts unbound): bind
  `passwd` as a function, then `(passwd)` returns the real value, NOT a hint.
- Keep the non-trigger test: `(zzznope 1)` → normal error, no hint.
- Keep `(+ 1 2)` → `3`.

## Done criteria
- [ ] Seed list = the 8 words above; `pwd` removed.
- [ ] Each seed word verified unbound in the default shell env (report the check).
- [ ] Tests updated for the new words; no-hijack + non-trigger + normal-eval kept.
- [ ] Full suite green; reported. No git.

## Hand back
The seed change, the per-word `is_fbound` confirmation in the default env, the
test run, and any word you had to drop because it was unexpectedly bound.
