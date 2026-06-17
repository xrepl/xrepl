# Slice arc8/4: navigation UX — forgiving parser + exits-on-help

Two play-test fixes (Duncan, 2026-06-16): a player got trapped at the `door`
prompt because (a) `go back` didn't match the `back` choice and (b) nothing told
him `back` was an exit. Both fixes are in **`xs-engine`** (content-agnostic;
neutral fixtures only).

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| F-1 | A leading movement verb is stripped before choice matching: at a node with a `(cmd "back" …) (to open-area)` choice, `handle` of `"go back"` returns the same `#(goto open-area)` as `"back"`. | eunit `go-prefix-matches-bare-cmd` asserts `#(goto open-area)`; `grep -n "strip-move-prefix\|go \|walk \|move \|head " src/xs-engine.lfe` | correctness | playtest | done | ✓ CDC read-verified | |
| F-2 | The full prefix set works and the bare command still works (no regression): `"walk woods"`, `"move left"`, `"head <syn>"`, and bare `"back"` all match their choice. | eunit assertions for each form | correctness | playtest | done | ✓ CDC read-verified | |
| F-3 | A movement prefix on a non-exit does NOT spuriously match: `"go nowhere"` at a node without a `nowhere` choice falls through (scene → "can't do that"; prompt → password attempt), exactly as the bare word would. | eunit `go-prefix-no-false-match` | correctness | review | done | ✓ CDC read-verified | |
| F-4 | `help` output now includes the current node's exits — the **first** `cmd` synonym of each `(to …)` choice. At `door` → contains `back`; at `open-area` → contains `door`, `woods`, `right`, `left`. | eunit `help-lists-exits` asserts the help text contains `"Exits"` and each expected name | **serious** | playtest (the trap) | done | ✓ CDC read-verified | |
| F-5 | A new `exits` command lists the current node's exits (same source as F-4). `"exits"` is distinct from `"exit"` (the shell quit-word, intercepted upstream) — it reaches the engine. | eunit `exits-command-lists-exits` | correctness | Duncan | done | ✓ CDC read-verified | |
| F-6 | Exits are derived from `(to …)` choices ONLY; `(action …)` choices (e.g. `help`) are NOT listed as exits. `door`'s exit list = `["back"]`, not `["back","help"]`. | eunit asserts `door` exits = `back` only | correctness | review | done | ✓ CDC read-verified | |
| F-7 | A node with no `(to …)` choices reports "no obvious exits" (or equivalent) gracefully — no crash, no empty/garbled output — from both `help` and `exits`. | eunit on an exitless node | polish | review | done | ✓ CDC read-verified | |
| F-8 | Full suite green; content-agnostic (no story words in code or tests); no `sed`; no `binary:join` reintroduced. | `rebar3 as test eunit`; `grep -rni "ground\|clarkfork\|frenchtown\|binary:join" src test` → empty (only the existing 2 binary:join docstring hits permitted) | serious | standing rules | done | ✓ CDC read-verified | |

## What Worked

- Single choke point: routing the go-prefix tolerance through `cmd-matches?`
  (the one function all choice matching flows through) made F-1/F-2 uniform by
  construction — no partial-adoption risk to chase.
- Centralizing the exits line in `exits-text`/`help-text` meant `help` and
  `exits` and the empty case all share one implementation; one fix, three rows.
- CC raised the binary:join miscount as an amendment rather than silently
  matching my (wrong) "2 permitted" — the discipline catching a ledger bug, not
  a code bug.

## Closure

Closed 2026-06-16. CC: 162/162 green, per-row walk with evidence.
CDC verification: read-verified `strip-move-prefix`/`cmd-matches?` (xs-engine.lfe
276–300), `node-exits` (302), `exits-text`/`help-text` (320–335), and the
help/exits wiring; confirmed the OTP-portable `lists:join` idiom; story-word +
binary:join greps clean of new hits.
Total rows: 8. Done: 8. Deferred: 0. No-op: 0.
**Amendment (F-8):** ledger said "2 binary:join docstring hits permitted"; actual
is 3 (all pre-existing docstrings, no live calls, none in changed files). My
count was off by one — accepted, no action.
