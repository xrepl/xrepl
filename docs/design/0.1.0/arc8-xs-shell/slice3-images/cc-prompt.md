# CC PROMPT — arc8 / slice3: render images from the .xsf

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design lead
(sibling CDC/Opus), reviewed by Duncan (lead + QA). **This is the last slice of
Arc8 — after it, the engine is complete.**

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits — structured
> editor only. Clean git tree; run `git diff --stat` after and report it.

**Mission:** When the engine emits `#(image AssetId)`, fetch the image bytes from
the bundle's `.xsf` and render them to the terminal via
`xrepl-term-graphics:render-data/2`. Best-effort: a missing image or a
non-graphics terminal must never break the turn (text always renders).

**Read first:** `arc8-xs-shell/design.md`, and the proto-skill gotchas.

## Verified facts
- `xrepl-term-graphics:render-data/1,2` (in `term/src`) takes **raw image bytes**
  (a binary) and base64-encodes internally for iTerm2 + Kitty. Pass an `opts` map
  with a `name` (from the asset id) — `render-file` sets it; do the same here.
- Image bytes live in the `.xsf` zip under `<images-dir>/<asset-file>`
  (images-dir from the manifest, default `"assets/images"`). `xs-bundle:load`
  parses nodes/manifest but does NOT keep image bytes or the zip handle.
- `render-data` writes terminal escape sequences (a side effect) to the shared
  tty — works for the **in-process/local** client. Remote-transport image
  delivery (carrying bytes over the protocol to a networked client) is DEFERRED.

## Scope — edits + tests
EDIT `src/xs-bundle.lfe`, `src/xs-shell.lfe`. ADD tests. No git. Content-agnostic;
neutral fixtures (a fake image entry with arbitrary bytes — NOT a real painting).

## Phase A — `xs-bundle` image access (pure, testable)
- At load, keep the source so images can be re-fetched lazily: store
  `source => Binary` in the Bundle map (`load-file` already has the bytes after
  `file:read_file`; thread them through `load`). Do NOT eagerly read image bytes
  at load (keep load light).
- Add `(image-bytes Bundle AssetId) -> #(ok Binary) | error`:
  - re-open the source zip in memory (`zip:zip_open Source '(memory)`),
  - resolve the entry: match an entry under `<images-dir>/` whose basename equals
    `AssetId` **or** whose basename without extension equals `AssetId` (so a node
    `(image "01-foo")` resolves `assets/images/01-foo.png`). `zip:zip_get` it,
    `zip:zip_close`.
  - `#(ok Bin)` on success, `error` if no matching entry.
  - **FLAG in hand-back:** the asset-id ↔ filename convention (does a node's
    `(image "X")` name the stem or the full filename?) — settle it when the real
    paintings are packed; for now support both via the stem-or-exact match.
- Tests: build a neutral bundle whose zip has `assets/images/pic-a.png` =
  `#"PNGBYTES"`; `image-bytes Bundle "pic-a"` → `#(ok #"PNGBYTES")` (stem match)
  AND `image-bytes Bundle "pic-a.png"` → `#(ok …)` (exact); `image-bytes Bundle
  "nope"` → `error`.

## Phase B — `xs-shell` renders images (isolate the side effect)
- Make `process-outputs` ALSO collect image ids: return
  `#(World2 Texts ImageIds Terminal)` (accumulate each `#(image Id)`'s id instead
  of dropping it). This stays pure and testable.
- In `eval/3`, AFTER `process-outputs`, render each collected image id as a
  best-effort side effect, then return the (unchanged) text response:
  ```
  for each Id in ImageIds:
    case (xs-bundle:image-bytes Bundle Id):
      #(ok Bin) -> (try (xrepl-term-graphics:render-data Bin (map 'name (to-bin Id)))
                        (catch ((tuple _ _ _) 'ok)))   ; graphics-less terminal: skip
      error     -> 'ok                                  ; missing image: skip (warn ok)
  ```
  The text `#(formatted …)` response is returned exactly as before — images are an
  additive side channel, never blocking text. Apply the same in the `start/1`
  opening render and `resume/2` (so the opening/resumed room shows its image).
- Tests: `process-outputs` over a list containing `#(image "pic-a")` →
  `ImageIds` contains `"pic-a"` (pure, asserted); a room whose body + image
  render → text still correct AND (with a fake image present) `image-bytes`
  resolves; a node referencing a MISSING image → turn still returns its text
  (graceful). The actual escape-writing of `render-data` is a side effect on a
  graphics terminal — do not try to assert its bytes; cover the decision/fetch
  path and the graceful skips.

## Deferred (named)
- Remote-transport image delivery (carry bytes/refs over the protocol so a
  networked ratatui client renders them) — in-process render only here.
- Streaming (`#(stream …)`) pacing — still rendered as text; real slow-reveal is
  a later concern.

## Done criteria
- [ ] `xs-bundle:image-bytes` resolves stem-or-exact + tested; `source` stored.
- [ ] `process-outputs` collects image ids (pure, tested); `eval`/`start`/`resume`
      render them best-effort; missing image / non-graphics terminal → graceful,
      text unaffected.
- [ ] Content-agnostic; neutral fixtures; full suite green; both runs + `git diff
      --stat` reported; no `sed`; `grep -r binary:join src test` still empty.

## Hand back
The diffs, both test runs + diffstat, the `image-bytes` resolution behavior, and
your recommendation on the asset-id ↔ filename convention (stem vs full) for when
the paintings are packed. Flag anything that differed from this spec.
