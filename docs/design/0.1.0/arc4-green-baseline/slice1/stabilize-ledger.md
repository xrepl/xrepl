# Slice 01: Working state + repo hygiene

**Arc:** 04 — Stabilise the branch · **Branch:** `release/0.1.x` (work on a slice
branch off it) · **Origin plan:** `docs/design/0.1.0/2026.06.10-release-0.1.0-plan.md` · **Discipline:**
`LEDGER_DISCIPLINE.md` (CC implements, CDC verifies; every row reaches a final
status with reproducible evidence before the slice advances; five-iteration cap).

**Scope (no behavioural changes):** bring `release/0.1.x` to green and clean the
tree. Triage the crash dump before deleting it. Do **not** fix any audit
behavioural finding here — those are Arc 02.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| F-1 | `rebar3 compile` succeeds on a clean checkout of `release/0.1.x` | `rebar3 compile; echo $?` → `0` | serious | working-state | open | | |
| F-2 | `rebar3 as test lfe ltest` runs and is green | `rebar3 as test lfe ltest` → all suites pass, exit 0 | serious | working-state | open | | If red, fix only build/test breakage, not audit findings |
| F-3 | `erl_crash.dump` triaged then removed | closing report has a 1-paragraph triage note; `ls erl_crash.dump` → "No such file" | correctness | L-21 | open | | Triage = what crashed, does it map to L-01/L-04 |
| F-4 | Root scratch files removed/relocated | `ls test_quit.lfe tmp COMMIT_MSG.txt 2>&1` → all "No such file" | polish | L-21 | open | | |
| F-5 | Untracked design doc resolved | `git status --short docs/design/xrepl-protocol-impl-master-plan.md` → empty (tracked) or file gone | polish | L-21 | open | | Decide: track or remove |
| F-6 | No stray untracked files in tree | `git status --short` → only intended `workbench/` (or clean) | polish | L-21 | open | | `_build/`, `erl_crash.dump` etc. are gitignored |

## What Worked

_(Filled in at slice close.)_

## Closure

_(Filled in at slice close: commit SHA, date, CDC verifier, row tally.)_
Closed at commit `<SHA>` on `<date>`. CDC verification: `<name/session>`.
Total rows: 6. Done: `<n>`. Deferred: `<n>`. No-op: `<n>`.

---

### CC notes

- Read this ledger before writing anything. If a criterion is wrong or
  impossible, raise an amendment — don't silently work around it.
- Fill Evidence at the commit where each row is met; don't leave it all for the
  end. In the closing report, walk the rows one by one — no prose summary, no
  "deviations: none."
- F-2 is the one likely to need iterations: CI has had cover/xref trouble
  historically (commits `eac9d8f`, `f8b6e11`, `99462ea`). Getting `ltest` green is
  in scope; re-enabling xref/dialyzer/coverage gates is **not** (that's Arc 03,
  L-07). If `ltest` won't go green without a behavioural change, stop and flag —
  that's a finding, not a quiet fix.

### CDC notes

- Re-run F-1, F-2, F-4, F-5, F-6 commands yourself; don't trust the evidence
  column. For F-3, confirm the triage paragraph exists _and_ the file is gone.
- Watch for spec-softening on F-2: "tests compile" or "most suites pass" is not
  "green." Exit 0 with all suites passing, or it's not done.
