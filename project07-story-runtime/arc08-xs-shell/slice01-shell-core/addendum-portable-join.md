# CC PROMPT — arc8 / slice1 addendum: make `join-texts` portable to OTP 25

**You are** Claude Code (Sonnet 4.6), implementing a fix from the design lead
(sibling CDC/Opus), approved by Duncan.

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits on tracked
> files — structured editor only. Apply on a clean git tree; run `git diff
> --stat` after and report it.

## Context (DEFINITIVE — supersedes earlier drafts of this file)
The project's CI (`.github/workflows/cicd.yml`) tests **OTP 28, 27, 26, 25**.
`binary:join/2` was added in **OTP 28** (STDLIB 7.0), so it is `undefined` on
OTP 25/26/27. The new `multi_text_body_joined_by_newline_test` now *calls*
`binary:join`, so it passes locally (OTP 30) but **will fail the 25/26/27 CI
jobs**. Fix: use the OTP-portable idiom (`lists:join` is OTP-19+, `iolist_to_binary`
is ancient). Keep the new test — it then passes on all four OTPs.

## Change 1 — `src/xs-shell.lfe` `join-texts/1`
Replace the `binary:join` implementation with:
```lfe
(defun join-texts (texts)
  "Join text binaries with newlines into one binary (portable to OTP 25)."
  (iolist_to_binary (lists:join #"\n" texts)))
```
`lists:join` handles empty/single/multi; `iolist_to_binary` flattens. Remove the
old `'()` / `(list single)` / `binary:join` clauses. Keep
`multi_text_body_joined_by_newline_test` (it now validates this across OTPs).

## Change 2 — `src/xrepl-history.lfe:~121` (same latent bug)
That module also calls `binary:join lines #"\n"` — same OTP-28+ break on the
supported floor (latent only because no CI test exercises the multi-line history
write path). Apply the same swap:
```lfe
;; was: (binary:join lines #"\n")
(iolist_to_binary (lists:join #"\n" lines))
```
If you'd rather keep this slice tight, do Change 1 only and leave a one-line note
in the hand-back that `xrepl-history.lfe:121` still needs the same fix — but it's
the identical edit and it's genuinely broken on OTP 25/26/27, so folding it in is
preferred.

## Verify
After the swaps, grep the whole `src/`+`test/` tree for `binary:join` and confirm
**zero** remaining occurrences.

## Done criteria
- [ ] `xs-shell:join-texts` uses `iolist_to_binary(lists:join …)`; multi-text test kept.
- [ ] `xrepl-history.lfe` swapped too (or explicitly flagged in hand-back).
- [ ] `grep -r binary:join src test` → nothing.
- [ ] Full suite green; both runs + `git diff --stat` reported; no `sed`.

## Hand back
The diffs, the test run + diffstat, and the `binary:join` grep result (should be
empty). Note whether `xrepl-history` was included.
