# CC PROMPT — arc7 / slice3: `xs-engine` (the pure transition core)

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

**Mission:** Implement `xs-engine` — the **pure** interactive-fiction step
functions. No IO, no zip, no protocol, no xrepl deps. Data in, data out. This is
the heart, and the piece a future Lykn→JS browser reader re-ports, so keep it
ruthlessly pure and total.

**Design-of-record:** `docs/design/0.1.0/arc7-xs-engine/design.md` (Module 3 +
the **IR-consumption note** — read it). `xs-bundle` (slice1) and `xs-world`
(slice2) are landed and green; you consume their shapes.

## Scope — two new files
CREATE `src/xs-engine.lfe`, `test/xs-engine-tests.lfe`. Touch nothing else.
No git. **Content-agnostic** — neutral invented fixtures only (e.g. `start`,
`gate`, `vault`); NO story words.

## Read these gotchas first
`lfe/lfe/workbench/lfe-proto-skill.md` — especially: `(and/or …)` evaluate all
args (use `andalso`/`orelse` or named helpers + `foldl`); and the `lfe_codelift`
trap (no inline lambdas with side-effects inside `try` — use named helpers).

---

## Phase A — `as-list/1` (the normalizer — build + test this FIRST)

`xs-bundle`'s `parse-keyword-list` stores a multi-valued node field **bare when
it has one element, as a list when many**. You MUST normalize every multi-valued
access (`body`, `choices`, `items`, `on-enter`, the elements of `reveal`).

Element shapes: a body element is a **string** (`"…"` — a list of ints), or a
**tagged form** `(stream "…")` / `(if c a b)`; a choice is `(choice …)`; an item
is `(item …)`; an on-enter entry is `(set f v)`. So:

```
(as-list V) ->
  '()                                  when V == '()
  (list V)                             when V is a string (printable int list)
  V                                    when (is_list V) and the HEAD of V is
                                       itself a list or a string  ; already a
                                       list of elements
  (list V)                             when (is_list V)           ; single tagged
                                       form whose head is an ATOM (stream/if/
                                       choice/item/set …)
  (list V)                             otherwise
```

Provide a `string?/1` helper (printable list / all-integers; `io_lib:printable_list`
is fine). **Test `as-list` directly** against every case:
`"x"` → `("x")`; `("a" "b")` → `("a" "b")`; `(stream "x")` → `((stream "x"))`;
`(choice (cmd "go") (to a))` → `((choice …))`; `((choice …) (choice …))` →
unchanged; `'()` → `'()`. Get this right — every other function depends on it.

## Output type
`handle/3` and `enter/2` return `#(World2 Outputs)` where each Output is:
```
#(text Binary)   | #(stream Binary)   | #(image AssetIdString)
#(goto NodeId)   | done               | suspend
```
Render a body **string** → `#(text Bin)`; `(stream "…")` → `#(stream Bin)`;
`(if Cond Then [Else])` → eval `Cond` via `xs-world:eval-cond` and render the
chosen branch element. (`->binary`: `list_to_binary` / `unicode:characters_to_binary`.)

## Phase B — `enter/2`
`(enter NodeMap World) -> #(World2 Outputs)` — the player arrives at a node.
**Order matters:**
1. Apply `on-enter`: for each `(set F V)` in `(as-list (maps:get 'on-enter NodeMap '()))`,
   `xs-world:set-flag`.
2. **Bump this node's visit** (`xs-world:bump-visit` on the node's `id`) — BEFORE
   evaluating any visit-gated conditions, so a `(>= visits 2)` reveal appears on
   the 2nd entry.
3. Emit body: for each element of `(as-list (maps:get 'body NodeMap '()))`, render
   per the Output rules above (strings, `(stream …)`, `(if …)`).
4. Emit `reveal` if present: `reveal` value is `((when Cond) Elem …)`. Extract
   `Cond` from the `(when Cond)` head; if `(xs-world:eval-cond Cond World2)`,
   render `(as-list (rest))`. (Assume at most one `reveal` per node — the bundle
   map can only hold one `'reveal` key; flag if you find multi-reveal nodes.)
5. Emit `#(image Id)` if the node has `(image Id)`.
6. Node-kind tail: `ending` → append `done`; `suspend` → append `suspend`;
   `scene`/`prompt` → no tail (await input).

Return the updated World (with sets + visit) and the Output list.

## Phase C — `handle/3`
`(handle NodeMap Input World) -> #(World2 Outputs)` — process the player's line.
`Input` is a binary, already lowercased + trimmed by the caller. Match like so:

**Choice match** (both node kinds): for each `(choice …)` in
`(as-list (maps:get 'choices NodeMap '()))`, the choice's `cmd` is one or more
strings; if `Input` equals one (case-insensitive) AND the choice's optional
`(if Cond)` holds (default true), take it: apply the choice's `(set …)` writes,
then emit `#(goto Target)` for `(to Target)`, or run `(action help|look|inventory)`.

**Meta verbs** (if no choice matched): parse `Input`'s first word —
- `look` → re-emit the node's body + reveal + image (no on-enter, no visit bump).
- `take <id>` / `get <id>` → see Items below.
- `inventory` / `i` → `#(text "You are carrying: …")` (or "nothing").
- `help` → a short generic help `#(text …)`.

**Prompt-node password** (prompt nodes only, after choice + meta verbs miss):
compare `Input` to `(maps:get 'password NodeMap)`. Match → `#(goto OnSuccess)`
(from `(on-success …)`); no match → emit `(fail-text)` as `#(text Bin)` — a
NORMAL response, never an error, world unchanged.

**Unmatched** (scene, nothing matched): `#(text "You can't do that.")` (a
per-node override is optional; not required).

### Items (`take`/`get <id>`)
For `(item …)` in `(as-list (maps:get 'items NodeMap '()))` whose `(id X)`
matches: eval its `(takeable Cond)` via `xs-world:eval-cond`; if true → render
the `on-take` elements, apply the `on-take` `(set …)` writes, and
`xs-world:add-item` the id. If not takeable / no such item → `#(text "You can't
take that.")`.

## Neutral test fixtures + table-driven tests
Build a small invented graph in-test (NodeMaps shaped exactly as `xs-bundle`
produces — i.e. with the bare-vs-list ambiguity present, so `as-list` is
exercised). Suggested: `start` (scene, on-enter set, a `(>= visits 2)` reveal, an
item gated on `(>= visits 2)`), `gate` (prompt, password `"xyzzy"`,
on-success `vault`, fail-text, a `back`→`start` choice), `vault` (ending).

Cover (mirrors design §"Test strategy" / doc 12 §6, neutral):
- `enter start` (1st) → body text + image emitted; world has the on-enter flag;
  `visits[start]=1`; reveal NOT shown.
- `enter start` (2nd) → `visits[start]=2`; reveal text shown.
- `handle start "north"` (a choice) → `#(goto gate)` (+ any choice set applied).
- `enter gate` → the prompt/body text.
- `handle gate "wrong"` → `#(text fail-text)`, **world unchanged**, no goto.
- `handle gate "xyzzy"` → `#(goto vault)`.
- `handle gate "back"` → `#(goto start)`.
- 2nd-visit `handle start "take key"` → world flag set + item held + on-take text;
  1st-visit `take key` (not takeable) → "can't take".
- `enter vault` → body text then `done`.
- `handle start "inventory"` and `"help"` → text; `handle start "zzz"` → "can't do that".

## Done criteria
- [ ] `as-list/1` built first, tested against all shapes.
- [ ] `enter/2` order: on-enter → bump-visit → body → reveal → image → kind-tail.
- [ ] `handle/3`: choice → meta verbs → (prompt) password; items; unmatched.
- [ ] PURE (no IO/zip/protocol); totality (a malformed sub-form degrades, never
      crashes — lean on `xs-world:eval-cond`'s totality and defensive `case`s).
- [ ] New + full suite green; both reported. Content-agnostic; neutral fixtures.

## Hand back
The two files, both test runs, the final `enter/2` + `handle/3` signatures and
Output shapes, the `as-list` heuristic as implemented, and ANY node-schema shape
from `xs-bundle` that surprised you (the bare-vs-list corners especially). Flag,
don't paper over.
