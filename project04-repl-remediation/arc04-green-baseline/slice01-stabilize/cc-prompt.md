# CC Assignment — Slice 1: Working state + repo hygiene

You are CC (the implementer) for one slice of the xrepl 0.1.0 remediation. Work
the ledger, close every row with reproducible evidence, write a closing report
that walks the ledger row by row. A separate context (CDC) will independently
re-verify your `done` rows afterward.

## Context

- **Repo:** `xrepl` OTP application at `/Users/oubiwann/lab/lfe/xrepl/xrepl`.
- **Branch:** cut a slice branch off `release/0.1.x` (e.g.
  `slice/01.01-stabilize`). Do not commit directly to `release/0.1.x`.
- **Ledger (your spec):** `ledger.md` in this slice directory.
  Read it first. Its six rows F-1…F-6 are the definition of done.
- **Discipline:** load and follow `LEDGER_DISCIPLINE.md` from the
  collaboration-framework skill. Five-iteration cap. Evidence = command output +
  the commit SHA where the row was met.
- **Parent plans (read for context, don't re-derive):** `../arc-plan.md` (the
  Arc 04 plan, with this slice's plan-of-record) and the project plan
  `workbench/2026.06.10-remediation-program-plan.md`.

## What this slice IS

Bring `release/0.1.x` to a known-good baseline: it compiles, tests are green, and
the working tree is clean. Triage the crash dump before deleting it.

## What this slice is NOT — hard constraints

- **No behavioural changes.** Do not fix any audit finding (L-01…L-20). Those are
  later slices (Arc 05 / Arc 06). The *only* code changes permitted here are the
  minimum needed to make `compile` and `ltest` pass — and if a test only goes
  green via a behavioural change, **stop and flag it** (that's a finding, not a
  quiet fix).
- **Do not re-enable xref / dialyzer / coverage gates.** They are commented out
  on purpose right now; turning them back on is Arc 06 (L-07), not this slice.
  Getting `ltest` green is in scope; getting `xref` green is not.
- **Do not touch `src/` behaviour, `docs/design/` contents, or network/session
  logic.** Design-doc sorting is the *next* slice (`slice2`).

## Steps

1. **Branch + baseline.** Cut the slice branch. Run `rebar3 compile` and
   `rebar3 as test lfe ltest`. Capture exact output. (History: cover/xref gave CI
   trouble in commits `eac9d8f`, `f8b6e11`, `99462ea` — expect `ltest` may need a
   couple of iterations.)
2. **Make build + tests green** (F-1, F-2). Fix only build/test breakage. If you
   touch anything that smells behavioural, halt and report.
3. **Triage the crash dump** (F-3). Open `erl_crash.dump`, write a one-paragraph
   triage in the closing report: what crashed, and whether it plausibly maps to
   L-01 (idle keepalive) or L-04 (session cleanup). *Then* delete it.
4. **Close the ledger.** Fill Evidence (command output + commit SHA) on each row
   as you land it — not all at the end.

## Deliverable

Update `ledger.md` in this slice directory in place:

- Every row F-1…F-6 reaches a final status (`done` / `deferred` / `no-op`) with
  evidence. `deferred` needs a reason + re-entry condition; `no-op` needs a
  rationale.
- Fill the **What Worked** section.
- Fill the **Closure** line (commit SHA, date, row tally).
- Write a **closing report** (a new section at the bottom of the ledger, or a
  sibling `closing-report.md`) that walks F-1…F-6 one at a time. No prose summary,
  no "deviations: none" — a disposition per row. Include the crash-dump triage
  paragraph under F-3.

## Stop conditions

- A test only passes via a behavioural change → stop, flag, don't fix here.
- You reach iteration 5 without `ltest` green → stop, report what's blocking
  (likely a real finding or an environment issue), don't grind a sixth pass.
- Anything in the ledger looks wrong or impossible → raise it as an amendment
  request; don't silently work around it.
