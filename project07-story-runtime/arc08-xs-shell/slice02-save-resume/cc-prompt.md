# CC PROMPT — arc8 / slice2: world save / resume

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits on tracked
> files — structured editor only. Apply on a clean git tree; run `git diff
> --stat` after and report it. An unexpected large rewrite = botched edit; stop
> and recover.

**Mission:** Make a play-through resumable. The player can leave the story
(hit a `suspend` node, or type `quit`) and come back later with `(xs:run)` to
find themselves where they left off — same room, flags, visits, inventory. The
save blob is the **world map** (pure data) stored in **session metadata**, which
already survives `close`/`reopen`.

**Read first:** `arc8-xs-shell/design.md`, `arc7-xs-engine/design.md` (the engine
+ World shape), and the proto-skill gotchas (`andalso`/`orelse`; no inline
lambdas-with-side-effects in `try`; `node` is not a usable var name; quasiquote
patterns need `,` to bind).

## Verified APIs you'll use
- `xrepl-session-manager:get-current/0` -> current session-id (or 'undefined) —
  how a shell-invoked function (`xs:run`) learns its session.
- `xrepl-store:get-metadata/1` / `set-metadata/2` (confirm exact names/arity in
  `src/xrepl-store.lfe`) — read/write the session's arbitrary metadata map. This
  is pure data, persisted in ETS, surviving `close`/`reopen`.
- `xs-shell:eval/3` receives `Ctx` = `#m(session-id SessionId …)` — its session.
- Engine: `xs-engine:enter/2`, `xs-engine:handle/3`; `xs-world` accessors;
  `xs-bundle:load/load-file/node/manifest/entry-node`.

## Scope — edits + tests
EDIT `src/xs-shell.lfe`, `src/xs.lfe`. ADD tests to `test/xs-shell-tests.lfe`.
No git. Content-agnostic; neutral fixtures; the save key is `'xs-save`.

## Phase A — pure save/resume core (build + test first)
- `(save ShellState) -> World` — the world map (same as `snapshot/1`; you may
  define `snapshot` in terms of `save` or vice-versa). Pure.
- `(resume SavedWorld Bundle) -> #(ok ShellState RenderedRoom)` — PURE: rebuild
  an `xs-shell-state` from a saved world + a (freshly loaded) bundle, and render
  the **current** room so the returning player re-orients. "Render current" =
  emit `body` + matching `reveal` + `image` for `(xs-world:current-node
  SavedWorld)` WITHOUT applying `on-enter` or bumping the visit (you are
  resuming, not entering). If the saved current node is missing from the bundle,
  return `#(error stale-save)`.
  (Hint: a "render current room" helper can reuse the same body/reveal/image
  rendering `enter/2` uses — factor it out and call it from both.)
- Tests (neutral bundle): take a played world (current node = `gate`, a flag
  set, `visits` non-zero, an item held), `resume` it against the same bundle →
  the state's world equals the saved world AND `RenderedRoom` contains the
  `gate` body text. A saved world whose node isn't in the bundle → `#(error
  stale-save)`.

## Phase B — save points in `eval/3`
In `xs-shell:eval/3`, using `Ctx`'s session-id (`maps:get 'session-id Ctx
'undefined`):
- **`quit` / `exit`** (intercept BEFORE calling the engine): write the world to
  metadata (`set-metadata` → `maps:put 'xs-save World Meta`), then return
  `#(switch-shell xrepl-shell-lfe #m() #(formatted #"Progress saved. Until next time."))`.
- Engine **`suspend`** output: same — save the world to `'xs-save`, switch back
  to LFE with the suspend room text.
- Engine **`done`** output: the play-through is over — **clear** the save
  (`maps:remove 'xs-save Meta`), switch back to LFE with the ending text.
- If session-id is `'undefined` (no session context), skip the metadata write
  gracefully (still switch back).
- (Per-turn autosave is OUT OF SCOPE — save only at quit / suspend / done.)

## Phase C — resume in `xs:run`
In `src/xs.lfe`, `run/0,1`:
1. `Sid = (xrepl-session-manager:get-current)`.
2. `Saved = ` (if `Sid` valid) read `'xs-save` from that session's metadata, else
   `'none`.
3. Load the bundle (`priv/support.xsf` via `code:priv_dir` — absent for now;
   graceful).
4. Dispatch:
   - `Saved` present AND bundle loads → `xs-shell:resume Saved Bundle`:
     - `#(ok State Room)` → `#(xrepl-switch-shell xs-shell #m(state State) #(formatted Room))`.
     - `#(error stale-save)` → fall through to a fresh start (and clear the bad save).
   - No save AND bundle loads → fresh start (slice1's `xs-shell:start` path).
   - bundle missing → `#(formatted #"There is nothing here yet.")`.

## Tests (`test/xs-shell-tests.lfe`)
- Phase A units as above (pure, neutral bundle).
- Save points: start the app; create a session; drive `xs-shell:eval` with a
  `Ctx` carrying that session-id such that the input hits a `suspend` node (or is
  `quit`) → assert `'xs-save` is now in the session's metadata and equals the
  world; drive a `done` ending → assert `'xs-save` is **removed**.
- Resume round-trip: put a saved world in a session's metadata, `set-current` it,
  and exercise the `xs:run` resume branch against a NEUTRAL bundle (inject the
  bundle however the code structure allows — e.g. a small seam so the test
  doesn't depend on `priv/support.xsf`); assert it rebuilds at the saved node and
  renders that room. If a clean seam isn't available without contorting `xs:run`,
  test `xs-shell:resume/2` directly (Phase A) and the metadata read separately,
  and note the gap.

## Deferred (named)
- Per-turn autosave (crash-resilience) — only quit/suspend/done save here.
- Showing the room automatically on a `close`/`reopen` *session* restart (init
  can't emit output) — resume via `(xs:run)` renders the room; a bare reopen
  shows it on the next `look`.

## Done criteria
- [ ] `resume/2` pure + tested; `save`/`snapshot` return the world.
- [ ] quit/suspend save to `'xs-save`; done clears it.
- [ ] `xs:run` resumes from a saved world (renders the saved room) or starts fresh.
- [ ] Content-agnostic; neutral fixtures; full suite green; both runs + `git diff
      --stat` reported; no `sed`; `grep -r binary:join src test` still empty.

## Hand back
The diffs, both test runs + diffstat, the `'xs-save` metadata shape, the
`resume/2` + `eval/3` save-point behavior, and any session/store API that
differed from this spec (flag, don't paper over).
