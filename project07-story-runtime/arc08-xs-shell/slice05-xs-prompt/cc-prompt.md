# CC PROMPT — arc8 / slice5: `xs> ` prompt while in the story shell

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design lead
(sibling CDC/Opus), reviewed by Duncan (lead + QA).

**Run AFTER `slice4-navigation-ux`.** Tiny cosmetic change, no ledger.

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits on tracked
> files — structured editor only. Clean git tree; run `git diff --stat` after and
> report it.

**Mission:** While a story is loaded and the session's active shell is `xs-shell`,
the REPL prompt should read **`xs> `** instead of **`xrepl> `**. Everything else
about the prompt (colours, the multi-session `name:` form) stays exactly as is.

## The change — `src/xrepl.lfe`, `prompt/2` (≈ line 372)
Today `prompt/2` hardcodes the label `"xrepl"` in three spots (single-session;
multi-session `undefined`; multi-session named uses `"xrepl:"`). Compute the
label from the session's active shell instead:

- Add a small helper, e.g.
  `(shell-label SessionId) -> "xs" | "xrepl"`: the active shell advertises a name
  via `xrepl-session:describe/1` — `(maps:get 'name (xrepl-session:describe
  SessionId))` returns `#"xs"` for `xs-shell` and `#"lfe"` for the default shell.
  Return `"xs"` when that name is `#"xs"`, otherwise `"xrepl"`. Wrap the
  `describe` call defensively (`try`/`catch` → default `"xrepl"`) so the prompt
  never crashes on a transient/odd session state.
- In `prompt/2`, replace the literal `"xrepl"` with `(shell-label session-id)`
  and `"xrepl:"` with `(++ (shell-label session-id) ":")`. **Keep the colour
  calls and structure identical** — only the label text changes.

Net effect: default/LFE sessions still show `xrepl> ` (and `xrepl:name>` with
multiple sessions); a session that has switched into `xs-shell` shows `xs> `
(and `xs:name>`). When the player leaves the story (the shell switches back to
`xrepl-shell-lfe`), it returns to `xrepl> ` on its own.

## Scope
EDIT `src/xrepl.lfe` only. ADD a focused test (below). No git. Content-agnostic
(`"xs"` is the generic shell name, not story content).

## Test
Extract `shell-label/1` so it's unit-testable without rendering. In
`test/` (an existing xrepl/session test module, or a small new one): start the
app, create a session (default) → `shell-label` = `"xrepl"`; create a session
with `#m(shell xs-shell)` (the `shell` create-opt from arc6/slice4) →
`shell-label` = `"xs"`. (Don't try to assert the colourised prompt string.)

## Done criteria
- [ ] `shell-label/1` returns `"xs"` for an `xs-shell` session, `"xrepl"`
      otherwise (incl. on a `describe` failure); test proves both.
- [ ] `prompt/2` uses the label; colours/structure unchanged; default prompt
      still `xrepl> `.
- [ ] Full suite green; both runs + `git diff --stat` reported; no `sed`.

## Hand back
The diff, the test run + diffstat, and a one-line confirmation that a default
session prompts `xrepl> ` while an `xs-shell` session prompts `xs> `. If you can,
manual smoke: `./bin/xrepl` → `(xs:run)` → prompt becomes `xs> ` → leave the story
→ back to `xrepl> `.
