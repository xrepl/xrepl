# CC PROMPT — arc8 / slice6: Unicode render fix + help/moves polish

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design lead
(sibling CDC/Opus), reviewed by Duncan (lead + QA).

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits on tracked
> files — structured editor only. Clean git tree; run `git diff --stat` after and
> report it.

> **LEDGER DISCIPLINE (mandatory):** Ledger at `slice6-render-unicode/ledger.md`.
> Read it before coding; fill Evidence as you go; in the closing report **walk
> every row F-1…F-8 individually** (status + evidence), no prose summary. Raise
> amendments rather than working around. Five-iteration cap.

**Mission:** Fix a critical render bug — prose paragraphs containing non-ASCII
characters (em-dashes, smart quotes) render as **nothing** — plus four help/moves
UX asks from play-testing.

**Read first:** the ledger; `arc7-xs-engine/design.md`; the proto-skill gotchas.

## The root cause (read before fixing)
`.xsf` body strings are read from the zip as UTF-8 **bytes** (`binary_to_list`),
so an em-dash becomes the byte sequence `226 128 148`. `xs-engine:string?/1`
gates on `io_lib:printable_list`, which rejects bytes > 127, so `render-element`
falls through to its default `'()` and **drops the whole paragraph**. The door
opening showed only its ASCII paragraphs for exactly this reason.

## Scope
EDIT `src/xs-engine.lfe` (render + help text). ADD tests to
`test/xs-engine-tests.lfe`. Touch nothing else. No git. Content-agnostic — but
test fixtures MUST include non-ASCII/multibyte content (an em-dash).

## Fix A — `string?` recognises any char/byte list (F-1, F-2, F-3, F-4)
Change `string?/1` from "printable list" to **"non-empty list of integers"**:
```lfe
(defun string? (v)
  "True when V is a non-empty list of integers (a char/byte list). Unicode
  codepoints and raw UTF-8 bytes (as read from the .xsf) all count as text;
  printability is NOT required."
  (andalso (is_list v)
           (=/= v '())
           (lists:all #'erlang:is_integer/1 v)))   ; not a lambda-in-try; fine
```
This still cleanly separates strings from tagged forms (`(stream …)`/`(if …)`/
`(choice …)`/`(set …)` have **atom** heads → not all-integers) and from
lists-of-elements (head is a list → not all-integers). `render-element` then
emits `#(text (to-bin elem))`; the UTF-8 bytes pass through `list_to_binary` to
the terminal, which renders them correctly. Do NOT otherwise change
`render-element`, `as-list`, or the reader — bytes-through-to-terminal is the
intended path here.

**Tests:** `render-element` of a string containing `226 128 148` → `#(text …)`
(not `'()`). A 2-paragraph body (one with an em-dash, one ASCII) via `enter/2`
→ both paragraphs in the output. Drive `xs-shell:eval` (you may need a tiny
neutral bundle + start) for F-3 (a `(to X)` choice prints X's full body) and F-4
(`look` prints the full current body) — both with a Unicode paragraph present.

## Fix B — help / moves polish (F-5, F-6, F-7)
In `help-text/1` and the listing command (currently `exits-text` + the `exits`
meta-verb):
- **Rename the label `Exits:` → `Moves:`** everywhere (help line + the listing
  command). Empty case → `"Moves: none obvious."`.
- **Document movement in `help`** — add a hint that the player moves by typing an
  exit name (optionally prefixed `go `), e.g. extend the commands line to
  `"Commands: look, help, inventory (i), take <item>, go <exit>."`.
- **Blank line before the moves list** in `help`: the help text should be
  `…<commands line>\n\nMoves: …` (two newlines, a blank line between).
- **Add a `moves` meta-verb** that lists the moves (keep `exits` as an alias →
  both produce the `Moves:` line). Build the joined string with
  `iolist_to_binary(lists:join …)` — NOT `binary:join` (OTP-28+; CI floor is 25).

## Acceptance hand-back (real archive, not committed)
With `priv/support.xsf` present, via `./bin/xrepl`: `(xs:run 'password)` →
`back` → `look`, confirming the **full** room text renders at each step (the
em-dash first paragraph included). If text is still dropped after Fix A, that is
a SECOND bug — investigate and report, don't close F-3/F-4.

## Done criteria
- [ ] Ledger F-1…F-8 each final with evidence; per-row closing walk.
- [ ] `string?` = list-of-integers; `grep printable_list src/xs-engine.lfe` gone
      from `string?`; Unicode paragraphs render via enter/look/scene-change.
- [ ] `Moves:` label; movement in help; blank line; `moves` command (+ `exits`).
- [ ] Full suite green; both runs + `git diff --stat`; no `sed`; no `binary:join`.

## Hand back
Per-row ledger walk (F-1…F-8), the diffs, both test runs + diffstat, the real-
archive reproduction result, and anything that differed (amend, don't paper over).
