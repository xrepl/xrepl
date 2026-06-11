# CDC Verification — Slice 1 (arc4-green-baseline)

**Verifier:** independent context (separate from the CC that closed the slice).
**Date:** 2026.06.10 · **Branch verified:** `slice/01.01-stabilize` @ `f8afef7`
(baseline `d1f29f4`). **Ledger:** `ledger.md` (6 rows).

## Method

Re-ran each row's Verify command against the actual repo state rather than
trusting the Evidence column, per LEDGER_DISCIPLINE.md CDC protocol. **Constraint
disclosed up front:** the verification environment has **no BEAM toolchain**
(`rebar3`, `erl`, `erlc` all absent), so the two build/test rows (F-1, F-2) could
not be reproduced — they were checked for internal consistency only. The four
filesystem/git rows were fully reproduced.

## Row-by-row

| Row | Sig | CDC disposition | How |
|-----|-----|-----------------|-----|
| F-1 `rebar3 compile` → 0 | serious | **consistent, NOT reproduced** | no toolchain; evidence internally credible (app/dep list + known `cl.lfe` car/cdr warnings) but not re-run |
| F-2 `ltest` 39/39 green | serious | **consistent, NOT reproduced** | no toolchain; 4 suite names match the 4 test files in `test/`, counts sum to 39, evidence is genuine green (exit 0, 0 failed/erred) — but not re-run |
| F-3 dump triaged + gone | correctness | **CONFIRMED** | `ls erl_crash.dump` → "No such file"; triage paragraph present and substantive (clean OTP-28 shutdown, no L-01/L-04 map) |
| F-4 scratch files gone | polish | **CONFIRMED** | `ls test_quit.lfe tmp COMMIT_MSG.txt` → all absent |
| F-5 master-plan doc resolved | polish | **CONFIRMED** | gone from `docs/design/` and `docs/design/0.1.0/`; removed in `ca5fa66` |
| F-6 tree clean | polish | **CONFIRMED** | `git status --short` → empty |

Row count: opening 6, closing 6 — no silent drops. No spec-softening detected
(F-2 evidence is genuine green, not "compiles"/"most pass").

## Outstanding before merge

1. **Reproduce F-1 and F-2 on a machine with the toolchain.** These are the two
   serious-significance rows and the only ones CDC could not independently run.
   Expected to pass (evidence is consistent), but the methodology's evidence-
   access property is not satisfied until the commands are re-run. Owner: Duncan
   (has the BEAM toolchain). ~6s of test time.

## Bookkeeping (non-blocking)

- **Closure SHA.** The Closure line cites `d1f29f4` (the baseline CC verified
  against); the actual close commit is `f8afef7`. Should reference the close
  commit. One-line fix.
- **Provenance of F-4/F-5/F-6.** Satisfied by pre-slice cleanup commits
  (`ca5fa66`–`d1f29f4`), not by CC action. CC disclosed this honestly; criteria
  are end-state, so `done` is fair (could equally be `no-op`). Noted, not a defect.

## Verdict

**4 of 6 rows independently confirmed; 2 (build/test) consistent but unreproduced
in this environment.** Recommend merge to `release/0.1.x` **conditional on** Duncan
re-running `rebar3 compile` and `rebar3 as test lfe ltest` green on the slice
branch. With that, the slice closes fully.
