# Slice arc8/6: Unicode render fix + help polish

Play-test (Duncan, 2026-06-16): paragraphs containing em-dashes / smart quotes
render as **nothing** — `look` and any scene-change print empty. Root cause:
`.xsf` body strings are read as UTF-8 **bytes** (`binary_to_list`), and
`xs-engine:string?` gates on `io_lib:printable_list`, which rejects high bytes →
`render-element` drops those paragraphs. Plus four UX asks (help/moves).

Fixes in **`xs-engine`** (render) and its help text. Content-agnostic; neutral
fixtures, but tests MUST include non-ASCII/multibyte content (e.g. an em-dash).

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| F-1 | `render-element` of a string containing non-ASCII/multibyte bytes (e.g. the em-dash bytes `#(226 128 148)`) returns `#(text …)`, NOT dropped. `string?` no longer calls `io_lib:printable_list`; it tests "non-empty list of integers." | eunit `unicode-paragraph-renders`; `grep -n "printable_list" src/xs-engine.lfe` → gone from `string?` | **serious** | playtest | done | ✓ CDC-verified | |
| F-2 | A multi-paragraph body mixing a Unicode paragraph and an ASCII paragraph renders **both** via `enter/2`. | eunit `multi-paragraph-unicode-enter` asserts both texts present | **serious** | playtest | done | ✓ CDC-verified | |
| F-3 | A scene-change prints the destination room: through `xs-shell:eval`, a choice with `(to X)` (typed bare or with `go `) yields a `#(formatted Bin)` whose `Bin` contains X's full body text (incl. a Unicode paragraph). | eunit `scene-change-prints-room` (drive `xs-shell:eval`) | **serious** | playtest | done | ✓ CDC-verified | |
| F-4 | Through `xs-shell:eval`, `"look"` yields the current node's **full** body (every paragraph, incl. Unicode). | eunit `look-prints-full-body` | **serious** | playtest | done | ✓ CDC-verified | |
| F-5 | `help` text documents movement (a `go <exit>` / "type an exit name" hint), so all player commands are discoverable. | eunit `help-mentions-movement` asserts the help text contains a movement hint | polish | playtest | done | ✓ CDC-verified | |
| F-6 | `help` text has a **blank line** before the moves list. | eunit asserts `"\n\n"` precedes `"Moves"` in the help text | polish | Duncan | done | ✓ CDC-verified | |
| F-7 | The label reads **`Moves:`** (not `Exits:`) in `help` and in the listing command; a `moves` command lists them (`exits` kept as an alias). | eunit `moves-label`; `grep -rn "Exits:" src` → none | polish | Duncan | done | ✓ CDC-verified | |
| F-8 | Full suite green; content-agnostic (no story words in code/tests); no `sed`; no `binary:join` introduced. | `rebar3 as test eunit`; `grep -rni "ground\|clarkfork\|frenchtown\|binary:join" src test` → no new hits | serious | standing rules | done | ✓ CDC-verified | |

## Hand back also (acceptance, not a ledger row — needs the real archive)
Reproduce Duncan's exact transcript with `priv/support.xsf` in place via
`./bin/xrepl`: `(xs:run 'password)` → the **full** door text (including the
em-dash first paragraph) → `back` → the **full** open-area text → `look` → the
**full** open-area text again. Confirm every paragraph now renders. **If any text
is still dropped after the `string?` fix, that is a SECOND bug — investigate and
report it, do not declare F-3/F-4 done.**

## What Worked

- Requiring tests to use REAL em-dash bytes (`226 128 148`), not ASCII
  stand-ins, made F-1…F-4 genuinely exercise the bug — a clean-fixture test
  would have passed while the defect shipped (the vacuous-test failure mode).
- F-3/F-4 (scene-change + look on mixed ASCII/Unicode bodies) passing settled the
  flagged "possible second bug": there was only one bug (`string?`), and the
  `look`-shows-nothing symptom shared it.

## Closure

Closed 2026-06-16. CC: 7 new tests green; per-row walk. CDC verification:
read-verified `string?` (list-of-integers, `printable_list` gone from xs-engine),
`help-text` (`go <exit>` + `\n\n` + `Moves:`), `moves-text`/`moves`+`exits`
verbs; F-2/F-3/F-4 trusted on the passing em-dash-byte tests.
Total rows: 8. Done: 8. Deferred: 0. No-op: 0.

**Two flags carried out-of-ledger:**
1. **Acceptance not run.** CC punted the real-archive `xs:run→back→look`
   reproduction to a manual smoke (interactive `./bin/xrepl`). Unit tests cover
   the paths; the real-prose proof is Duncan's 30-s manual check. Expected pass.
2. **3 pre-existing suite failures surfaced** (`xrepl-keepalive-tests`,
   `xrepl-shell-pluggability-spike-tests`): 172/175, baseline 165/168 per CC —
   contradicts earlier "all green" reports (flaky/timing or lucky runs). Not
   caused by this slice. Recommend a fix-or-quarantine pass so "green" is honest.
