# CC PROMPT — arc7 / slice1: `xs-bundle` (load + validate)

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

**Mission:** Implement `xs-bundle` — load and validate an interactive-fiction
**bundle** from a `.xsf` (a zip archive) into an in-memory representation, with
loud validation. Pure-ish (zip + read at the edges, no game logic), fully
unit-tested, with **no dependency** on the session/shell/terminal layers.

**Design-of-record:** `docs/design/0.1.0/arc7-xs-engine/design.md` (read it).
This is the first of three Arc7 modules (`xs-bundle`, `xs-world`, `xs-engine`).

---

## Scope — two new files
CREATE: `src/xs-bundle.lfe`, `test/xs-bundle-tests.lfe`. Touch nothing else.
No git/commits.

## Hard rules
- **Content-agnostic.** `xs-bundle` loads ANY bundle and contains zero story
  content. **Test fixtures must use neutral, invented nodes** (e.g. `room-a`,
  `room-b`) — no real narrative, and do not use the words "ground" or any story
  text anywhere.
- House LFE style (≤80 cols, 2-space indent, lowercase-hyphen atoms, docstrings
  on exports, `defrecord`/maps for data).
- All new tests green; run `rebar3 as test eunit --module xs-bundle-tests` and
  the full suite; report both.

---

## The bundle format (what you parse)

A `.xsf` is a zip containing:
- `manifest.lfe` — exactly one `(story …)` s-expr form.
- `nodes/**/*.lfe` — one `(node …)` form per file (subdir layout is cosmetic).
- `assets/images/**` — binary image files (NOT parsed here; bytes fetched later
  by a different module).

**Node ids are atoms; asset ids are strings.** Forms (per the design doc):

```lisp
(story (schema "…") (title "…") (version "…") (entry <atom>) (protocol "…")
       (flags (flag (id <atom>) (type bool) (default <bool>)) …)
       (assets (images-dir "…")))

(node (id <atom>) (type scene|prompt|ending|suspend) (title "…")
      (image "<asset-id>")                    ; optional
      (body <element> …)
      (choices (choice (cmd "…" …) (to <atom>) (set <flag> <val>) (if <cond>)) …)
      (on-enter (set <flag> <val>) …)         ; optional
      (on-success <atom>) (password "…") (prompt "…") (fail-text "…")  ; prompt nodes
      (items (item (id <atom>) (takeable <cond>) (on-take <element> … (set <flag> <val>))) …)
      (stub true))                            ; optional
```

## Load path
```
(load Binary)      -> {ok, Bundle} | {error, Reason}   ; Binary = the .xsf bytes
(load-file Path)   -> {ok, Bundle} | {error, Reason}   ; file:read_file then load/1
(node Bundle Id)   -> {ok, Node} | error
(entry-node Bundle)-> Id
(manifest Bundle)  -> Manifest
```

1. `(zip:zip_open Binary '(memory))` → handle; `(zip:zip_list_dir Handle)` to
   enumerate entries; `(zip:zip_get Name Handle)` → `{ok, {Name, Bin}}` per entry;
   `(zip:zip_close Handle)` when done.
2. Parse `manifest.lfe` and each `nodes/**.lfe` entry with
   `(lfe_io:read_string (binary_to_list Bin))` → `{ok, [Form]}`; take the single
   form. (Confirmed: `read_string/1` returns `{ok, [Form,…]} | {error, Reason}`
   — a **2-tuple** error.)
3. Parse each `(story …)`/`(node …)` keyword-list s-expr into an internal map
   (a small recursive reader over the `(key . values)` pairs). Keep sub-forms
   (`body`, `choices`, `items`, `reveal`, conditions) as raw s-exprs — later
   modules interpret them; `xs-bundle` only needs structure for indexing +
   validation.
4. `Bundle` = `#m(manifest M nodes #{Id => NodeMap} flags FlagSchema
   images-dir Dir image-assets #{AssetId => true})`. Index nodes by `id`.

## Validation (fail loud at load)
Return `{error, Reason}` (don't crash) on:
- a `(to <id>)` (inside any choice), `(on-success <id>)`, or the manifest
  `entry` that names a **missing node** → `{error, {dangling, Where, Id}}`;
- a **duplicate node id** → `{error, {dup-node, Id}}`;
- `entry` missing entirely → `{error, {no-entry, …}}`.
Warn (via `logger:warning`) but still load on:
- a node `(image "<id>")` with no matching `assets/images/**` entry.

**Deferred (disclosed):** validating that flags referenced in `(set f …)` /
`(flag? f)` are declared in the manifest requires walking the condition/`set`
grammar, which the `xs-world` slice owns — defer flag-reference validation to
that slice. Note this in your hand-back; do not half-implement it here.

## Tests (`test/xs-bundle-tests.lfe`)
Build tiny **neutral** bundles in-test with `(zip:create Name Entries '(memory))`
(entries = `{Name, Bin}` of `manifest.lfe` + a couple of `node` files), then:
- a good 2-node bundle loads → `{ok, Bundle}`; `entry-node`, `node/2`,
  `manifest/1` return the expected pieces;
- a `(to missing-node)` → `{error, {dangling, …}}`;
- a duplicate node id → `{error, {dup-node, …}}`;
- a node with `(image "nope")` and no such asset → loads, and (if practical)
  assert the warning path is exercised;
- entry pointing at a missing node → `{error, {dangling|no-entry, …}}`.

## Done criteria
- [ ] `src/xs-bundle.lfe` + `test/xs-bundle-tests.lfe`; nothing else touched.
- [ ] Loads from a `.xsf` binary via `zip` + `lfe_io:read_string/1`.
- [ ] Validation: dangling refs, dup ids, missing entry → `{error,…}`;
      missing image → warn + load.
- [ ] Flag-reference validation explicitly DEFERRED (noted), not half-done.
- [ ] New + full suite green; both runs reported.
- [ ] Content-agnostic; neutral fixtures; no story words; no git.

## Hand back
The two files, both test runs, the exact `{error, …}` shapes you settled for each
validation failure (the `xs-world`/`xs-engine` slices and the design lead will
build on them), and anything in the bundle-form shape that the design doc got
slightly wrong.
