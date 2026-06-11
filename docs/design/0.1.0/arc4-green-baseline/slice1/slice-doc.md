# Slice 1 — Working state + repo hygiene

**Arc:** 04 — Stabilise the branch (`../arc-plan.md`) · **Branch (used):**
`slice/01.01-stabilize` off `release/0.1.x` @ `d1f29f4` · **Status:** **closed**
(see `closing-report.md`; CDC in `cdc-verification.md`).

Plan-of-record for the slice. Acceptance criteria live in `ledger.md` (with
evidence); the per-row walk is in `closing-report.md`; the CC assignment is in
`cc-prompt.md`.

## Scope (no behavioural changes)

Bring `release/0.1.x` to a known-good baseline: it compiles, tests are green, and
the working tree is clean. Triage the crash dump *before* deleting it (it may
reproduce L-01 or L-04 — free evidence). Confirm the build and test commands pass
on a clean checkout; fix only what blocks build/test — **no audit behavioural
fixes** (those are Arc 05). Decide the fate of the untracked
`xrepl-protocol-impl-master-plan.md`.

## Out of scope (hard constraints)

- No audit behavioural fixes (L-01…L-20) — Arc 05 / Arc 06.
- Do **not** re-enable xref / dialyzer / coverage gates — that's Arc 06 (L-07).
- No `src/` behaviour changes, no `docs/design/` content changes (doc-sorting is
  Arc 04 `slice2`).

## Ledger-seed (→ `ledger.md` rows)

- F-1 `rebar3 compile` exits 0 on a clean checkout. *(serious; working-state)*
- F-2 `rebar3 as test lfe ltest` runs and is green. *(serious; working-state)*
- F-3 `erl_crash.dump` triaged (1-paragraph note) **then** removed. *(correctness; L-21)*
- F-4 `test_quit.lfe`, `tmp/`, `COMMIT_MSG.txt` removed/relocated. *(polish; L-21)*
- F-5 `xrepl-protocol-impl-master-plan.md` tracked or removed. *(polish; L-21)*
- F-6 `git status --short` shows no stray untracked files. *(polish; L-21)*

## Files

Repo root, `_build/` (ignored), `docs/design/`. No `src/` behaviour changes.

## Outcome

Closed in one iteration, no `src/` changes. F-1/F-2 green on baseline `d1f29f4`
(39/39 tests); crash dump was a clean OTP-28 shutdown (no L-01/L-04 map);
hygiene rows satisfied by pre-slice cleanup. CDC reproduced the four tree-state
rows; the two build/test rows are pending a toolchain re-run (no BEAM toolchain in
the CDC sandbox). See `cdc-verification.md`.
