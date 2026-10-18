# Rust audit iteration01 — attributed guidance reconciliation

Issued 2026-10-17. Predecessor: `cc-prompt.md`; CC source-pass commit `553a6b6`.
Source remains `b865b31`. Reviewer: Sofie. This is one bounded refinement pass,
not a source repair. All original no-source-edit, isolated-probe, explicit-commit
and proposed-done return rules still apply.

## Why this refinement

The original source pass fully read four Rust guides but could not complete
the entire 36-file packet in its context. Preserve that intake gap; do not
claim that another reader's work was your own. Sofie allocated the remaining
32 files to a bounded lookup context under the Operator's explicit discretion
to use agents. All32 files/27,676 lines were actually read in two full passes;
the complete existing36-file/32,559-line population now has attributed reading.
This adjusts the execution allocation of guidance, not source/audit scope,
evidence strength, child acceptance or the requirement that every existing
guide receive a full read before final review. Original incomplete intake is
retained as historical evidence. No missing installation file is invented.

## Required reading

Required-full: this prompt, current slice-plan/ledger, your two authored reports,
`artifacts/2026.10.17-rust-team-guide-coverage.json`. The original prompt remains
binding except that full language-guidance reading is now explicitly distributed
across named contexts; only your actual reads may be claimed as yours.

Required-section in installed Rust guides (load full named sections):
- `03-error-handling.md`: EH-01, EH-04, EH-07, EH-14, EH-26.
- `12-project-structure.md`: PS-02, PS-03, PS-11, PS-21, PS-25, PS-29.
- `13-documentation.md`: DC-11.
- `15-cargo/06-cargo-advanced.md`: CG-A-08 and CG-A-09.

These sections cover library/application errors, deliberate invariants,
real integration tests, doctest limits and native CI/MSRV conclusions. Other
full-guide reads remain attributed to the lookup context; they are not a
substitute for these applicable source-judgment sections in your own context.
Record precise extent/intake/readback in an appended evidence section.

## Changes and checks

1. Reconcile RUST-001–004 with these actual sections and the previously fully
   loaded anti-pattern/concurrency/CLI error/lint chapters. No new finding is
   required; correct unsupported claims if found. Preserve all original failures,
   guide table and source/probe receipts. Do not rewrite the old personal-read
   table to say all36 were read by you.
2. Update current-status text in the report/evidence to point to team coverage
   and this explicit allocation change. Record the missing referenced CLI09
   chapter and observed guide inconsistencies without treating them as xrepl
   bugs. Judge actual code/contracts and avoid mechanically applying erroneous
   examples (e.g. edition2024 paired with1.75 in old structure examples).
3. Main coordinator has independently replayed real-core normal/EOF/panic/
   no-TTY cases, confirming both runtime findings. That is reviewer evidence,
   not your own replay. No broad native rerun is needed for prose-only changes.
4. Modify/commit only your two authored Rust report/evidence files, with
   explicit path list. No prompt/ledger edits or source changes. Whitespace/link
   checks apply to authored prose; raw logs remain unchanged.

Return commit, exact sections actually read, claim corrections and remaining
limits. Final acceptance belongs to Sofie/Operator at their actual scopes.
