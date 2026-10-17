# CC PROMPT — arc8 / slice1: `xs-shell` core + `xs:run` entry

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

> **EDITING SAFETY (mandatory):** Never use `sed -i` / in-place stream edits on a
> tracked file — use the structured editor. If a bulk transform is genuinely
> needed, run it to stdout first (no `-i`), inspect the diff, and apply only on a
> **clean git tree** so `git checkout -- <file>` recovers. After editing, run
> `git diff --stat` and **report it** — an unexpectedly large rewrite is the
> signature of a botched substitution; stop and recover, don't hand back a
> corrupted file.

**Mission:** Make a story *playable in the REPL*. `xs-shell` is an `xrepl-shell`
behaviour impl that drives the (already built, proven) `xs-engine` over a bundle:
enter a node → show the room → take a command → move rooms → reach an ending →
return to the LFE shell. Plus `xs:run`, the entry that switches the session into
the story shell (completing the breadcrumb from Arc6 slice5).

**Read first:** `docs/design/0.1.0/arc7-xs-engine/design.md` (the engine + its
Output contract), `docs/design/0.1.0/arc6-multishell/shell-seam-decision.md` (the
`xrepl-shell` behaviour + the `#(switch-shell …)` mechanism), and the gotchas in
`lfe/lfe/workbench/lfe-proto-skill.md` (esp. `(and/or)` vs `andalso/orelse`; no
inline lambdas-with-side-effects in `try`; `node` is not a usable var name).

## Scope — new + one edit
CREATE `src/xs-shell.lfe`, `src/xs.lfe`, `test/xs-shell-tests.lfe`.
EDIT `src/xrepl-shell-lfe.lfe` (one small, generic addition — see §4).
No git/commits. **Content-agnostic** — `xs-shell`/`xs` contain ZERO story text;
tests use a NEUTRAL in-test bundle (`start`/`gate`/`vault`, no story words). The
only story-specific artifact is `priv/support.xsf`, which does NOT exist yet — so
`xs:run` must degrade gracefully when it's absent.

## Recap: the engine Output contract (from Arc7)
`xs-engine:enter(Nd, World) -> #(World2 Outputs)` and
`xs-engine:handle(Nd, Input, World) -> #(World2 Outputs)`, where each Output ∈
`#(text Bin) | #(stream Bin) | #(image AssetId) | #(goto NodeId) | done | suspend`.
`xs-bundle:node(Bundle, Id) -> #(ok NodeMap) | error`;
`xs-bundle:entry-node(Bundle) -> Id`; `xs-world:new(Manifest) -> World`;
`xs-world:current-node` / `set-node`.

## 1. `xs-shell:start/1` (load + open a story) — a plain helper, not a callback
```
(start BundleBinaryOrPath) -> #(ok ShellState RenderedOpening) | #(error Reason)
```
- Load the bundle (`xs-bundle:load` for a binary, `load-file` for a path).
- `World0 = (xs-world:new (xs-bundle:manifest Bundle))`, current node = entry.
- ENTER the entry node: `#(W1 Outs) = (xs-engine:enter EntryNd World0)`.
- `ShellState` = a record/map holding `bundle` + `world` (W1, with current node).
- `RenderedOpening` = `(render-outputs Outs)` (a binary — see §3 render rules).
  (If the entry node is itself an ending/suspend, that's fine — the opening just
  also carries the terminal signal; for v1 assume the entry is a scene/prompt.)

## 2. `xs-shell` behaviour callbacks
- `(init Opts)` -> `#(ok ShellState)`. `Opts` carries a pre-built state:
  `#m(state ShellState)` → adopt it. (The bundle is loaded by `start/1` in `xs:run`,
  so `init` just adopts — this is how the opening room reaches the player via the
  switch Response without changing the shipped `init→{ok,State}` contract.)
- `(eval Input ShellState Ctx)` -> the turn (see §3).
- `(describe ShellState)` -> `#m(name #"xs" kind #"story" prompt #"> ")`.
- `(snapshot ShellState)` -> the **world** map only (pure data; the bundle is
  reloadable). Full save/resume wiring is slice2 — here just return the world.
- `(prompt ShellState)` -> `#"> "`.

## 3. `xs-shell:eval/3` — one player turn (the core loop)
```
(eval Input ShellState Ctx) ->
    #(ok #(formatted Bin) ShellState2)              ; normal turn
  | #(switch-shell xrepl-shell-lfe #m() #(formatted Bin))  ; story ended/suspended
```
Steps:
1. `Nd = current node map` (`xs-bundle:node Bundle (xs-world:current-node World)`).
2. `#(W1 Outs) = (xs-engine:handle Nd Input World)`.
3. **Process the Output list** into `{World2, AccText, Terminal}`:
   - `#(text B)` / `#(stream B)` → append `B` to the accumulated text.
   - `#(image Id)` → **slice1: skip** (a later slice renders it; optionally append
     a tiny `"[image]"` placeholder, your call — but do NOT load bytes here).
   - `#(goto Id)` → set current node to `Id` in the world, then `xs-engine:enter`
     that node; **fold its Outputs into the same processing** (so moving to a room
     shows that room). A `goto` target that is an `ending`/`suspend` will surface
     `done`/`suspend` here.
   - `done` / `suspend` → mark Terminal.
4. If Terminal → return
   `#(switch-shell xrepl-shell-lfe #m() #(formatted AccText))` (leave the story,
   back to the LFE shell). Else →
   `#(ok #(formatted AccText) ShellState2)` (await the next line).
Join accumulated text with newlines into one binary. Keep `eval` PURE except for
the engine calls (no IO, no zip — image bytes are a later slice).

## 4. `xrepl-shell-lfe` — recognise a switch sentinel (generic, small)
So an ordinary LFE call like `(xs:run)` can switch shells, add to
`xrepl-shell-lfe:eval/3`: after `xrepl-eval:eval-form` yields a `Value`, if
`Value` is `#(xrepl-switch-shell Mod Opts Response)` → return
`#(switch-shell Mod Opts Response)` instead of `#(ok Value State)`. This is a
generic mechanism (any function may return the sentinel to request a switch); it
does not mention `xs` at all.

## 5. `src/xs.lfe` — the entry
```
(run)      -> (run 'support)        ; xs:run/0
(run _trigger) ->                    ; xs:run/1 (the breadcrumb passes the typed word; ignore it)
   case (load priv/support.xsf via code:priv_dir + xs-shell:start) of
     #(ok State Opening) -> #(xrepl-switch-shell xs-shell #m(state State) #(formatted Opening))
     #(error _)          -> #(formatted #"There is nothing here yet.")  ; graceful: support.xsf absent
```
`xs:run` returns the sentinel (so the LFE shell switches via §4) when the bundle
loads, else a plain formatted message. (`priv/support.xsf` won't exist until the
content is packed in a later arc — the graceful path is exercised now.)

## Deferred (name them, don't build them)
- Images (`#(image Id)` → real bytes via `xrepl-term-graphics:render-data/2`) — a
  later slice. slice1 skips image outputs.
- World save/resume into session metadata (`/quit`→`/game`) — slice2. slice1's
  `snapshot/1` just returns the world.
- Preserving the player's LFE REPL bindings across a story visit — switching back
  uses a fresh LFE env (`#m()`); stash/restore is a possible later refinement.
  Note this as a known v1 simplification.

## Tests (`test/xs-shell-tests.lfe`) — NEUTRAL bundle
Build a small in-test `.xsf` (reuse the `xs-bundle` test helper: `zip:create …
[memory]`) with `start` (scene, a `north`→`gate` choice), `gate` (prompt,
password `"xyzzy"`, on-success `vault`, a `back`→`start` choice), `vault`
(ending). Then:
- `xs-shell:start` → `#(ok State Opening)`; `Opening` is a binary containing the
  `start` room's body text.
- `eval "north"` → `#(ok #(formatted T) State2)` where `T` contains the `gate`
  room's text (proves goto→enter→render).
- `eval "wrong"` at `gate` → `#(ok #(formatted T) _)` with the fail-text; world
  current node still `gate`.
- `eval "xyzzy"` at `gate` → moves to `vault` (ending) → returns
  `#(switch-shell xrepl-shell-lfe #m() #(formatted T))` with the `vault` text
  (proves done → leave-story).
- `describe`/`prompt`/`snapshot` shapes.
- **Sentinel recognition:** a function returning `#(xrepl-switch-shell M O R)`,
  evaluated through `xrepl-shell-lfe:eval`, yields `#(switch-shell M O R)`.
- `xs:run` with no `priv/support.xsf` present → the graceful `#(formatted …)`.

## Done criteria
- [ ] A neutral story is playable end-to-end through `xs-shell` (enter → command →
      goto → ending → switch back to lfe), proven by tests.
- [ ] `xs:run` returns the switch sentinel on load, graceful message when absent.
- [ ] `xrepl-shell-lfe` recognises the generic switch sentinel.
- [ ] Images / save-resume / env-preservation explicitly DEFERRED (named).
- [ ] Content-agnostic; neutral fixtures; full suite green; both runs + `git diff
      --stat` reported.

## Hand back
The files, both test runs, `git diff --stat`, the final `ShellState` shape and
`eval/3` return shapes, and any engine/shell contract mismatch you hit (flag,
don't paper over). If `sed` or any bulk edit touched a file, say so and show the
diffstat.
