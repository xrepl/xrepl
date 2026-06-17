# Slice arc8/7: Unicode output + multi-word input (playability bugs)

Two confirmed bugs from live play (Duncan, 2026-06-16):

1. **Unicode mojibake.** We emit a correct UTF-8 binary, but `xrepl.lfe`'s value
   printer does `binary_to_list` then `io:put_chars`, which treats the UTF-8
   bytes as codepoints and **re-encodes** (`—` → `Ã¢ÂÂ`). Fix: write the binary
   directly. (`src/xrepl.lfe`.)
2. **Multi-word commands fail.** The player types at an LFE REPL, so `go back` /
   `take rock` arrive as **LFE forms** `(go back)` / `(take rock)`, not strings.
   `xs-shell:normalize-input` only handles single atoms + strings, so multi-word
   input is mangled. (`src/xs-shell.lfe`.) THIS is why slice4's go-prefix and the
   `take <item>` verb "passed tests" (string inputs) but fail live (form inputs).

Plus a trivial `dirs` alias.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| F-1 | The value printer writes a formatted binary **directly** (no `binary_to_list` re-encode), so a UTF-8 multibyte char survives to the terminal. | `grep -nA3 "is_binary value-bin" src/xrepl.lfe` shows the binary passed straight to the output (no `binary_to_list` before `put_chars`) + manual: the em-dash renders as `—`, not `Ã¢ÂÂ` | **serious** | playtest | open | | |
| F-2 | `xs-shell:normalize-input` converts an LFE **form** to its command string: `(go back)` → `#"go back"`, `(take rock)` → `#"take rock"`, atom `back` → `#"back"`, string `"look"` → `#"look"`; lowercased + trimmed. | eunit `normalize-input-forms` asserts each | **serious** | playtest | open | | |
| F-3 | Driving `xs-shell:eval` with the **form** `(go back)` at a node whose `back` choice goes to X yields the move to X (go-prefix now reaches the matcher live). | eunit `eval-go-back-form-moves` (input is the FORM, not the string) | **serious** | playtest | open | | |
| F-4 | Driving `xs-shell:eval` with the **form** `(take rock)` at a node with a takeable `rock` item picks it up. | eunit `eval-take-rock-form` (FORM input) | **serious** | playtest | open | | |
| F-5 | A `dirs` command lists the moves (alias of `moves`/`exits`). | eunit `dirs-lists-moves` → text contains `Moves:` | polish | Duncan | open | | |
| F-6 | ASCII output unaffected; full suite green; content-agnostic; no `sed`; no `binary:join` introduced. | `rebar3 as test eunit` (note any pre-existing flaky); `grep -rni "ground\|clarkfork\|frenchtown\|binary:join" src test` → no new | serious | standing rules | open | | |

## Hand back also (acceptance, real archive)
Via `./bin/xrepl` with `priv/support.xsf`: `(xs:run 'password)` → confirm the
em-dash paragraph renders as readable text (not `Ã¢ÂÂ`); `go back` AND `back`
both move to open-area; at the door 2nd visit, `take rock` works. Report the
transcript.

## What Worked

_(Filled at close.)_

## Closure

_(Closed at <SHA> on <date>. CDC: <session>. Rows: 6. Done/Deferred/No-op: _.)_
