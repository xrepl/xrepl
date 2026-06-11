# Arc 04 — Stabilise the branch

**Release:** 0.1.0 · **Branch:** `release/0.1.x` · **Project plan:**
`../../../../workbench/2026.06.10-remediation-program-plan.md` (§3 arc structure)
· **Framework:** ledger discipline per slice (CC implements / CDC verifies;
grep-verifiable rows; five-iteration cap).

**Arc goal.** `release/0.1.x` is a known-good baseline — compiles, tests green,
tree clean, design docs sorted — *before* any behavioural fix lands. Nothing in
this arc changes runtime behaviour; it is the floor the Arc 05 critical fixes
stand on.

Origin tags (`L-NN`) trace to `2026.06.10-audit-results-lfe.md`.

## Slices

| Slice | Name | Scope | Status |
|-------|------|-------|--------|
| `slice1` | Working state + repo hygiene | green build/tests, crash-dump triage, tree cleanup (L-21) | **closed** — see `slice1/closing-report.md`, CDC in `slice1/cdc-verification.md` |
| `slice2` | Design-doc archaeology | classify the design docs completed-vs-forward, `git mv` completed ones into `docs/design/0.1.0/` | largely done by the release-branch reorg; to be formalised as a tracked slice if any docs remain unsorted |

`slice1` carries the full canonical file set (`slice-doc.md`, `ledger.md`,
`cc-prompt.md`, `closing-report.md`, `cdc-verification.md`). `slice2` has no
directory yet — per ledger discipline, a slice's files are created when the slice
is picked up. Its plan-of-record is the summary below.

### slice2 — Design-doc archaeology → `docs/design/0.1.0/`

**Scope.** Read each design doc in `docs/design/`, classify *completed* (describes
Phase 1/2/3 work that shipped) vs *forward-looking* (vision/spec not yet built),
and `git mv` the completed ones into `docs/design/0.1.0/`. Verify status by
reading each doc **against the code** — do not classify from the filename.

*Completed → `docs/design/0.1.0/`* (proposed; confirm against code): the phase
prompts, `lfe-repl-reusability-analysis-xrepl-design.md`,
`xrepl-protocol-extraction.md` (protocol lib exists),
`terminal-graphics-support.md` + `xrepl-graphics-impl.md` (graphics shipped in
`xrepl-term`), `xrepl-history-with-session.txt`, `xrepl-transport-improvements.txt`
(confirm — may be partial).

*Forward-looking → stay in `docs/design/`* (proposed): `xrepl-graphics-vision.md`
(Vega-Lite, unbuilt), `reveal-like-viz-in-xrepl.md`,
`distributed-repl-architecture-guide.md`, `xrepl-unified-spec.md`,
`xrepl-emacs-guide.md`, `xrepl-protocol-impl-master-plan.md`.

**Ledger-seed (becomes `slice2/ledger.md` when picked up):**

- F-1 `docs/design/0.1.0/` contains every doc classified completed. *(polish; def-of-done #3)*
- F-2 each move is `git mv` (history preserved), verified by `git log --follow`. *(polish)*
- F-3 the closing report lists every design doc with a one-line completed/forward
  disposition **and the evidence** for the call. *(correctness; spec-keeping)*
- F-4 no doc is moved whose feature is unbuilt; spot-check by grepping the code
  for the feature each "completed" doc claims. *(correctness)*

> *Status note (2026.06.10):* much of this is already done — the design docs now
> live under `docs/design/0.1.0/`. What remains for a formal `slice2` is the
> disposition record (F-3): a written, evidence-backed list confirming each move
> was correct and nothing forward-looking was moved by mistake. If that audit
> trail isn't needed, `slice2` can close as a documented no-op.

## Arc checkpoint

Branch green, tree clean, docs sorted with a disposition record. Arc 05 may begin.
