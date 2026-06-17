# CC PROMPT — arc8 / slice7: Unicode output + multi-word input

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design lead
(sibling CDC/Opus), reviewed by Duncan (lead + QA).

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits — structured
> editor only. Clean git tree; `git diff --stat` after, report it.

> **LEDGER DISCIPLINE (mandatory):** Ledger at `slice7-unicode-multiword/ledger.md`.
> Read it first; fill Evidence as you go; in the closing report **walk every row
> F-1…F-6 individually** (status + evidence), no prose summary. Amendments, not
> silent workarounds. Five-iteration cap.

**Mission:** Two confirmed live-play bugs (the story is unreadable and half the
commands don't work) plus a `dirs` alias.

**Read first:** the ledger; the proto-skill gotchas.

## Fix 1 — Unicode output (F-1), in `src/xrepl.lfe`
The value printer double-encodes: it does `binary_to_list` on a UTF-8 binary,
then `io:put_chars`, which re-encodes the bytes as codepoints (`—` → `Ã¢ÂÂ`).
Find the value-printing branch (≈ lines 251–257, where it currently does
`(if (is_binary value-bin) (binary_to_list value-bin) value-bin)` then
`io:put_chars`). **Write the binary directly** — `(io:put_chars value-bin)`
(io:put_chars accepts a binary or a char list; a UTF-8 binary on the unicode
device renders correctly). Drop the `binary_to_list` step for the binary case.
This is a generic xrepl fix — verify plain ASCII output is unchanged (existing
tests), and (manual) that an em-dash now renders as `—`.

## Fix 2 — multi-word input (F-2, F-3, F-4), in `src/xs-shell.lfe`
**Root cause:** the player types at an LFE REPL, so the line is parsed to an LFE
**form** before `xs-shell:eval` sees it: `back` → atom `back`; `go back` → the
list `(go back)`; `take rock` → `(take rock)`. `normalize-input/1` only handles
binaries, strings, and (via `~p`) single atoms — it mangles list forms, so every
multi-word command fails. (This is exactly why slice4's go-prefix and `take
<item>` passed string-based tests but fail live.)

Rewrite `normalize-input/1` to render ANY of these to a canonical command binary:
- binary → its string;
- a **string** (a list whose elements are all integers) → use as-is;
- a **list form** (e.g. `(go back)`, `(take rock)` — elements are atoms/terms) →
  render each element to its text (`atom_to_list` for an atom; a char-list as-is;
  numbers via `~w`) and **join with single spaces**;
- an atom → `atom_to_list`;
- anything else → `~w`/`~p` fallback.
Then lowercase + trim → binary. So `(go back)` → `#"go back"`, `(take rock)` →
`#"take rock"`, `back` → `#"back"`, `"look"` → `#"look"`.

**Tests MUST feed FORMS, not strings** (or they'll pass while the bug ships):
`normalize-input` unit cases for each shape; and `xs-shell:eval` driven with the
forms `(go back)` (→ moves via the `back` choice) and `(take rock)` (→ item
taken). Use a neutral bundle/fixtures.

## Fix 3 — `dirs` alias (F-5), in `src/xs-engine.lfe`
Add a `dirs` meta-verb alongside `moves`/`exits` — all three list the moves
(`Moves:` line). One more `((== s "dirs") …)` clause routing to the same
`moves-text`.

## Done criteria
- [ ] Ledger F-1…F-6 each final with evidence; per-row closing walk.
- [ ] Unicode binary written directly (no re-encode); `normalize-input` handles
      forms; `go back`/`take rock` work when driven as FORMS; `dirs` lists moves.
- [ ] Full suite green (note pre-existing flaky failures separately if present);
      both runs + `git diff --stat`; no `sed`; no `binary:join`.

## Hand back
Per-row ledger walk, diffs, both test runs + diffstat, and the real-archive
acceptance transcript (em-dash renders as `—`; `go back` AND `back` both move;
`take rock` works). Amend, don't paper over.
