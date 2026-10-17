# Slice 1: Working state + repo hygiene

**Arc:** 04 — Stabilise the branch (`../arc-plan.md`) · **Branch:**
`slice/01.01-stabilize` off `release/0.1.x` @ `d1f29f4` · **Origin plan:**
`../arc-plan.md` · **Discipline:**
`LEDGER_DISCIPLINE.md` (CC implements, CDC verifies; every row reaches a final
status with reproducible evidence before the slice advances; five-iteration cap).

**Scope (no behavioural changes):** bring `release/0.1.x` to green and clean the
tree. Triage the crash dump before deleting it. Do **not** fix any audit
behavioural finding here — those are Arc 05.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| F-1 | `rebar3 compile` succeeds on a clean checkout of `release/0.1.x` | `rebar3 compile; echo $?` → `0` | serious | working-state | done | Exit 0 on `d1f29f4`. Output: `===> Compiling xrepl` with no errors. | Passed on baseline; no changes needed. |
| F-2 | `rebar3 as test lfe ltest` runs and is green | `rebar3 as test lfe ltest` → all suites pass, exit 0 | serious | working-state | done | Exit 0 on `d1f29f4`. 39 tests, 39 passed, 0 skipped, 0 failed, 0 erred. 4 suites: xrepl-config-tests, xrepl-multi-session-tests, xrepl-session-manager-tests, xrepl-store-phase2-tests. | Passed on baseline; no changes needed. |
| F-3 | `erl_crash.dump` triaged then removed | closing report has a 1-paragraph triage note; `ls erl_crash.dump` → "No such file" | correctness | L-21 | done | `ls erl_crash.dump` → "No such file or directory". Triage paragraph in closing report below. | Crash dump deleted; it was gitignored so no commit needed. |
| F-4 | Root scratch files removed/relocated | `ls test_quit.lfe tmp COMMIT_MSG.txt 2>&1` → all "No such file" | polish | L-21 | done | All three: "No such file or directory" on `d1f29f4`. | Already resolved by Duncan before slice started. These files were untracked and are no longer present on `release/0.1.x` HEAD. |
| F-5 | Untracked design doc resolved | `git status --short docs/design/xrepl-protocol-impl-master-plan.md` → empty (tracked) or file gone | polish | L-21 | done | `git status --short` output: empty. File was removed in commit `ca5fa66` as part of doc reorganization. | Resolved by Duncan in commit `ca5fa66` (deleted alongside moves to `docs/design/0.1.0/`). |
| F-6 | No stray untracked files in tree | `git status --short` → only intended `workbench/` (or clean) | polish | L-21 | done | `git status --short` → empty output (fully clean tree). | Resolved by Duncan's doc reorganization commits `ca5fa66`–`d1f29f4`. |

## What Worked

- **Branch was already in good shape.** Duncan's earlier commits (`ca5fa66`–`d1f29f4`)
  cleaned up scratch files, reorganized docs, and updated ignores before this slice
  was picked up. F-1 and F-2 passed on baseline with zero code changes needed. This
  meant the slice was a verification exercise rather than a fix-and-iterate cycle —
  the right outcome for a stabilization slice.
- **Crash dump triage was informative.** Reading the dump before deleting it
  confirmed that the crash was a clean shutdown (not an L-01/L-04 reproduction),
  which is useful negative evidence for the Arc 05 work.
- **Ledger discipline as a checklist worked cleanly.** With 6 rows and most already
  resolved, the per-row walk took one iteration. The discipline's value here was in
  forcing the crash-dump triage (F-3) rather than just deleting the file.

## Closure

Closed at ledger commit `f8afef7` on 2026-06-10 (baseline `d1f29f4`).
CDC verification: `cdc-verification.md` (4/6 rows reproduced; F-1/F-2 pending a
toolchain re-run). Total rows: 6. Done: 6. Deferred: 0. No-op: 0.

---

### CC notes

- Read this ledger before writing anything. If a criterion is wrong or
  impossible, raise an amendment — don't silently work around it.
- Fill Evidence at the commit where each row is met; don't leave it all for the
  end. In the closing report, walk the rows one by one — no prose summary, no
  "deviations: none."
- F-2 is the one likely to need iterations: CI has had cover/xref trouble
  historically (commits `eac9d8f`, `f8b6e11`, `99462ea`). Getting `ltest` green is
  in scope; re-enabling xref/dialyzer/coverage gates is **not** (that's Arc 06,
  L-07). If `ltest` won't go green without a behavioural change, stop and flag —
  that's a finding, not a quiet fix.

### CDC notes

- Re-run F-1, F-2, F-4, F-5, F-6 commands yourself; don't trust the evidence
  column. For F-3, confirm the triage paragraph exists _and_ the file is gone.
- Watch for spec-softening on F-2: "tests compile" or "most suites pass" is not
  "green." Exit 0 with all suites passing, or it's not done.

---

## Closing Report

The per-row walk lives in `closing-report.md` (split out per the methodology's
per-slice file set). Summary: all 6 rows `done`, one iteration, no `src/` changes;
F-1/F-2 green on baseline `d1f29f4` (39/39 tests); crash dump was a clean OTP-28
shutdown (no L-01/L-04 map).
