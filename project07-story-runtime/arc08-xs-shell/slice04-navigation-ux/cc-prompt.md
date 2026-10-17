# CC PROMPT — arc8 / slice4: navigation UX (forgiving parser + exits-on-help)

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design lead
(sibling CDC/Opus), reviewed by Duncan (lead + QA).

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits on tracked
> files — structured editor only. Clean git tree; run `git diff --stat` after and
> report it. A surprise large rewrite = botched edit; stop and recover.

> **LEDGER DISCIPLINE (mandatory):** This slice has a ledger at
> `slice4-navigation-ux/ledger.md`. **Read it before writing code** — it is the
> definition of "done." Work against it, fill the Evidence column as you go, and
> in your closing report **walk every row F-1…F-8 individually** with its final
> status (`done`/`deferred`/`no-op`) and evidence (the test name + result, or the
> grep output). Do NOT write a prose summary or "deviations: none" — per-row only.
> If a criterion is wrong or impossible, raise it as an amendment, don't silently
> work around it. Five-iteration cap.

**Mission:** Two play-test fixes, both in **`src/xs-engine.lfe`** — a player got
trapped at a `prompt` node because `go back` didn't match the `back` choice and
nothing told him `back` was a way out.

**Read first:** the ledger; `arc7-xs-engine/design.md`; the proto-skill gotchas
(`andalso`/`orelse`; no inline lambdas-with-side-effects in `try`; `node` is not a
usable var name; quasiquote `,` to bind).

## Scope
EDIT `src/xs-engine.lfe`. ADD tests to `test/xs-engine-tests.lfe`. Touch nothing
else. No git. **Content-agnostic** — neutral fixtures only (`start`/`gate`/etc.);
no story words anywhere.

## Fix 1 — forgiving movement-verb parser (F-1, F-2, F-3)
In the **choice-matching** path only (not password, not other meta-verbs), let a
leading movement verb be stripped before comparing to choice `cmd` synonyms.
- Add a helper, e.g. `(strip-move-prefix Input) -> Input'`: if the input (work on
  its string/binary form) begins with one of `"go "`, `"walk "`, `"move "`,
  `"head "`, `"run "`, return the remainder (trimmed); else return it unchanged.
- In `cmd-matches?` (or wherever a choice's `cmd` list is compared to the input),
  a choice matches if **either** the raw input **or** `strip-move-prefix(input)`
  equals one of the synonyms. Keep it scoped to choice matching so passwords and
  `take <id>` are unaffected.
- Result: `go back` ⇒ `back` ⇒ the choice's `(to …)`; bare `back` still works;
  `go nowhere` (no such choice) still falls through normally.

## Fix 2 — `help` and a new `exits` command list the room's exits (F-4…F-7)
- Add a helper `(node-exits Nd) -> [Binary]`: for each choice in
  `(as-list (maps:get 'choices Nd '()))` that has a `(to …)`, take its **first**
  `cmd` synonym (as a binary). `(action …)`-only choices are NOT exits. Returns a
  list (possibly empty).
- **`help`** (both the `(action help)` choice path AND the `"help"` meta-verb):
  append the exits to the existing help line, e.g.
  `"Commands: look, help, inventory (i), take <item>.\nExits: back."` — join the
  exit names with `", "`. If `node-exits` is empty → `"Exits: none obvious."`
  (Build the joined binary with `iolist_to_binary(lists:join …)` — NOT
  `binary:join` (OTP-28+; this project's CI floor is OTP 25).)
- **`exits`** — add a new meta-verb in the input dispatch: input `"exits"` →
  `#(text "Exits: …")` (same source as help; "none obvious" when empty). Note
  `"exits"` ≠ `"exit"` (the latter is the shell's quit-word, intercepted in
  `xs-shell` before the engine — don't touch it here).

## Tests (`test/xs-engine-tests.lfe`) — map to the ledger rows
Use a neutral node with a `(cmd "back" "down" "away") (to open-area)` choice plus
a `(cmd "go-room" …) (to <x>)` style choice and an `(action help)` choice; and an
exitless node (e.g. a `suspend` or a node with only an `(action help)`):
- F-1/F-2: `"go back"`, `"walk back"`, `"move back"`, `"head back"`, and bare
  `"back"` → `#(goto open-area)`.
- F-3: `"go nowhere"` → NOT a goto (scene → can't-do-that; or prompt → password
  path).
- F-4: `handle` of `"help"` → text contains `"Exits"` and each `(to …)` choice's
  first synonym.
- F-5: `"exits"` → text listing the exits.
- F-6: a node whose choices are one `(to …)` + one `(action help)` → exits list
  has only the `(to …)` synonym, not `help`.
- F-7: an exitless node → `help`/`exits` say "none obvious" (no crash).

## Done criteria
- [ ] Ledger F-1…F-8 each reaches a final status with evidence; closing report
      walks them per-row.
- [ ] Fixes in `xs-engine` only; neutral fixtures; full suite green; both runs +
      `git diff --stat` reported; no `sed`; no `binary:join` added.

## Hand back
The per-row ledger walk (F-1…F-8: status + evidence), the diffs, both test runs +
diffstat, and the `node-exits` / `strip-move-prefix` shapes. Flag anything that
differed; raise amendments rather than working around the ledger.
