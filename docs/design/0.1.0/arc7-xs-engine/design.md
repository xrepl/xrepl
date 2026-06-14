# Arc7 — the `xs` engine (design)

> Design-of-record for the content-agnostic interactive-
> fiction engine. Three modules — `xs-bundle`, `xs-world`, `xs-engine` — that
> load a story bundle and run it. **Pure and portable:** no socket, no terminal,
> no zip in the core transition logic; the same `.xsf` IR and the same
> `xs-engine:handle/3` are what a future Lykn→JS browser reader re-ports. The
> protocol/terminal wiring is Arc8 (`xs-shell`), kept strictly out of here.
>
> Source of truth for schema + semantics: GROUND doc 12 (`12-LFE-ENGINE-HOWTO.md`).
> Verified runtime APIs: `zip:zip_open/2 [memory]` + `zip:zip_get/2`,
> `lfe_io:read_string/1` (LFE 2.2.0), `code:priv_dir/1`.

## The bundle (IR) — recap

A bundle is `manifest.lfe` (one `(story …)` form) + `nodes/**/*.lfe` (one
`(node …)` form per file) + `assets/images/**`. **Node ids are atoms**; the
subdir layout is for humans. **Asset ids are strings** (may start with a digit).
At runtime the bundle is one zip renamed `priv/support.xsf`; entries are read as
binaries and parsed with `lfe_io:read_string/1`.

Node keys (per doc 12 §1.3): `(id <atom>)`, `(type scene|prompt|ending|suspend)`,
`(title "…")`, `(image "<asset-id>")`, `(body <element> …)`,
`(choices (choice …) …)`, `(on-enter (set <flag> <val>) …)`,
`(reveal (when <cond>) <element> …)`, `(stub true)`. Prompt-only: `(prompt "…")`,
`(password "…")`, `(on-success <id>)`, `(fail-text "…")`, `(items (item …) …)`.
Body elements: `"string"` (paragraph), `(stream "…")` (slow reveal — DEFERRED,
Arc9+), `(if <cond> <then> [<else>])`. Choice:
`(choice (cmd "go" "down" …) (to <id>) (set <flag> <val>) (if <cond>))` or
`(choice (cmd …) (action help|look|inventory))`. Condition grammar (§1.6):
`(flag? f) | (not c) | (and c …) | (or c …) | (>= visits N) | (= visits N) |
true | false`.

## Module 1 — `xs-bundle` (load + validate)

Pure-ish (does zip+read at the edge; no game logic). Unit-testable from a bundle
binary built in-test.

```
(load Binary)            -> {ok, Bundle} | {error, Reason}   ; Binary = the .xsf bytes
(load-file Path)         -> {ok, Bundle} | {error, Reason}   ; reads then load/1
(node Bundle Id)         -> {ok, Node} | error
(entry-node Bundle)      -> Id
(manifest Bundle)        -> Manifest
```

`Bundle` = a map `#m(manifest M nodes #{Id => Node} flags FlagSchema images-dir
Dir)`. Load path:
1. `zip:zip_open(Binary, '(memory))` → handle; `zip:zip_list_dir/1` to enumerate.
2. For each `nodes/**.lfe` entry: `zip:zip_get(Name, H)` → `{ok, {_, Bin}}` →
   `lfe_io:read_string(binary_to_list(Bin))` → `{ok, [Form]}` → take the one
   `(node …)` form. Same for `manifest.lfe` → the one `(story …)` form.
3. `zip:zip_close/1`. Image entries (`assets/images/**`) are **not** parsed
   here — their bytes are fetched lazily by Arc8 when a node is shown.
4. Parse each `(node …)`/`(story …)` s-expr into an internal map (a small
   recursive reader over the keyword-list form). Build `#{Id => Node}` + manifest.

**Validate at load (fail loud — cheap insurance, doc 12 §1.8):**
- every `(to <id>)`, `(on-success <id>)`, and `entry` names an existing node →
  else `{error, {dangling, …}}`;
- every `(if (flag? f) …)` / `(set f …)` names a flag declared in the manifest →
  else `{error, {undeclared-flag, f}}`;
- duplicate node id → `{error, {dup-node, id}}`;
- `(image "<id>")` with no matching asset entry → **warn, don't fail** (text
  still renders).

(This is the same discipline as the Rust LFE static-analyzer's "undefined
function" check — reused, per doc 12.)

## Module 2 — `xs-world` (state + conditions)

The per-play-through world. Pure data so it serializes for free (Arc8 stores it
in session metadata; the values are atoms/numbers/maps only).

```
World = #m(node Id flags #{f => bool} visits #{Id => N} items #{id => true})

(new Manifest)               -> World          ; seed flags from manifest defaults, visits empty
(flag World f)               -> bool
(set-flag World f v)         -> World
(visits World Id)            -> integer
(bump-visit World Id)        -> World
(has-item World id)          -> bool
(add-item World id)          -> World
(eval-cond Cond World)       -> bool           ; the §1.6 grammar
```

`eval-cond` is **total**: any unrecognised form → `false` (and log via
`logger:warning` — the "undefined smell"). This keeps a malformed bundle from
crashing a play-through.

## Module 3 — `xs-engine` (the pure transition core)

The heart, and the part the Lykn browser reader re-ports. **No IO, no zip, no
protocol** — just data in, data out.

```
(handle Node Input World) -> {World2, [Output]}
  Output = #(text Binary)      ; a paragraph
         | #(stream Binary)    ; slow-reveal (Arc9+ in xs-shell; engine just tags it)
         | #(image AssetId)    ; render hint; bytes fetched by xs-shell
         | #(goto NodeId)      ; transition; caller loads + re-enters
         | suspend             ; soft-exit, resumable
         | done                ; play-through complete
```

`Input` is the player's raw line (a binary), already lowercased/trimmed by the
caller. Behaviour by node `type` (doc 12 §2):
- **scene:** apply `on-enter` sets, bump this node's visit, emit `body`
  (+ matching `reveal`/`if`), then match `Input` against `choices` cmd-synonyms
  and meta verbs (`look`, `take <id>`, `inventory`/`i`, `help`); a matched
  choice with `(to Id)` → also apply its `(set …)`, emit `#(goto Id)`. No match
  → a generic "You can't do that." (or a per-node override).
- **prompt:** like scene, but free text matching nothing else is a **password
  attempt**. Precedence: (1) a choice cmd synonym; (2) a meta verb; (3) compare
  to `password` → match emits the transition to `on-success`; no match → emit
  `fail-text` as a NORMAL output (diegetic "Nothing happens.", never an error).
- **ending:** emit `body` (+ image), then `done`.
- **suspend:** emit `body`, then `suspend` (caller saves + returns to the REPL).

Items: `take <id>`/`get <id>` picks it up if its `(takeable <cond>)` holds,
applies `on-take` sets, emits the `on-take` text; `inventory`/`i` lists held
items.

The caller (xs-shell) owns the **enter→await→handle** loop: on `#(goto Id)` it
loads the node, runs its entry (on-enter/body/reveal), and awaits the next line.
`handle/3` itself stays a single pure step so it's table-testable and portable.

## Arc8 seam (not built here — just the contract `xs-shell` will honour)

`xs-shell` is an `xrepl-shell` behaviour impl whose `eval/3` feeds the player's
line to `xs-engine:handle/3`, threads `World` inside its shell-state (mirrored to
session `metadata` for free in-VM save/resume), and renders `[Output]`:
`#(text B)` / `fail-text` → `#(formatted B)` (the dispatcher already groks that);
`#(image Id)` → `zip:zip_get` the bytes from `support.xsf` and
`xrepl-term-graphics:render-data/2`; `#(goto Id)` → load + re-enter;
`suspend`/`done` → switch back to `xrepl-shell-lfe`. Entry (`xs:run`) returns
`{switch-shell, 'xs-shell, Opts, Greeting}` from the LFE shell.

## Test strategy (mirrors doc 12 §6)

- **xs-bundle:** a good in-test bundle loads; a deliberately dangling `(to …)`
  → `{error, {dangling,…}}`; a missing image warns but loads; dup id fails;
  undeclared flag fails.
- **xs-world:** each op; every condition-grammar form; unknown form → `false`.
- **xs-engine (table-driven `handle/3`):** wrong password → `fail-text`, world
  unchanged; `back` → `#(goto open-area)`; 1st vs 2nd visit to `door` (visit
  counter) → rock hint appears on the 2nd; `take rock` → sets `has-rock`, emits
  the password; correct password → `#(goto interior)`.

Test fixtures use a tiny **neutral** in-test bundle (a couple of nodes), NOT the
real story — `xs-*` is content-agnostic and its tests must stay story-free.

## Slice order (Arc7)
- slice1: `xs-bundle` (load + validate from a bundle binary).
- slice2: `xs-world` (state + total condition evaluator).
- slice3: `xs-engine` (`handle/3`, all four node kinds + items + meta verbs).

Each is pure and unit-testable with no xrepl/session/terminal dependency — they
can be built and reviewed independently of, and in parallel with, Arc6.

## slice1 `xs-bundle` — DONE (accepted 2026-06-14)

`src/xs-bundle.lfe` + tests; 89/89 green; content-agnostic (neutral `room-a`/
`room-b` fixtures). Load path = `zip:zip_open [memory]` → `zip_get` →
`lfe_io:read_string/1` per entry. **Locked `{error,…}` shapes:**
`{dangling, NodeId|entry, TargetId}` (covers `to`, `on-success`, and manifest
`entry`), `{dup-node, Id}`, `no-entry`, `no-manifest`; missing image →
`logger:warning` + `{ok, Bundle}`. Flag-reference validation DEFERRED to
`xs-world` (owns the condition/set grammar). `Bundle` =
`#m(manifest M nodes #{Id=>NodeMap} flags FlagList images-dir Dir
image-assets #{AssetId=>true})`.

## slice2 `xs-world` — DONE (accepted 2026-06-14)

`src/xs-world.lfe` + tests; 111/111 green; content-agnostic. World =
`#m(node Id flags #{f=>bool} visits #{Id=>N} items #{id=>true})` (pure data).
`eval-cond/2` covers every grammar form and is **total** (catch-all →
`logger:warning` + `false`, proven by tests). `and`/`or` use named helper
foldls (the `lfe_codelift` workaround — see proto-skill gotcha #4). Flag shape
from `xs-bundle` consumed directly (always a list).

### IR-consumption note (LOAD-BEARING for slice2/slice3 + the Lykn reader)
`parse-keyword-list` stores a multi-valued node field **bare when single, as a
list when many** — e.g. `(body "one")` → `body => "one"`; `(body "a" "b")` →
`body => ("a" "b")`. Same for `choices`, `items`, `on-enter`, `reveal`.
`xs-bundle` handled this for `choices` (`collect-to-targets` checks the
`(cons 'choice …)` bare case). **Every consumer must normalize** with an
`as-list` helper (bare non-list → one-element list) at each multi-valued field
access, or it will mishandle single-element nodes. (`flags` is exempt —
`parse-flags` already returns a list.) Bake `as-list` into `xs-engine`.
