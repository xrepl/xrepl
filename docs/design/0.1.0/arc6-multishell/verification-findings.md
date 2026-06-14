# support (GROUND IF) — doc-12 §7 verification findings

> Workbench note, gitignored. Resolves the `[verify]` items in
> `12-LFE-ENGINE-HOWTO.md §7` against the actual xrepl/LFE/OTP source, and
> records three corrections to docs 11/12 where the code diverges from the spec.
> Naming: generic engine = `xs-*` (visible); story-specific = `support`
> (`priv/support.xsf`, this workbench). "ground"/"GROUND" never appears in
> tracked xrepl source.

Date: 2026-06-14. LFE dep pinned at **2.2.0** (`xrepl/xrepl/rebar.lock`).

## Resolved §7 items

**§7.1 — LFE reader (read one form from a zip-entry binary).**
Each node entry is exactly one `(node ...)` form; the manifest is one
`(story ...)` form. Use `lfe_io:read_string/1` on the entry bytes:

```lfe
;; EntryBin :: binary() from zip:zip_get/2
(case (lfe_io:read_string (binary_to_list EntryBin))
  (`#(ok (,form)) form)            ; exactly one form expected
  (`#(error ,reason) ...))         ; fail loudly at load (validation)
```

`lfe_io:read_string/1` (`lfe/src/lfe_io.erl:221`) parses ALL forms →
`{ok,[Sexpr,...]} | {error,Error}`. NOT `lfe_io:read_file` (no file — we have a
binary), NOT `file:consult` (that's Erlang terms). `lfe_io:scan_sexpr/3` is the
lower-level re-entrant scanner if we ever need partial/streaming reads; not
needed for one-form-per-entry.

**§7.3 — priv resolution.** xrepl already uses the standard idiom
(`xrepl/xrepl/src/xrepl.lfe:414`, banner loading):

```lfe
(let* ((path (filename:join (list (code:priv_dir 'xrepl) "support.xsf")))
       (`#(ok ,bin) (file:read_file path))
       (`#(ok ,zip) (zip:zip_open bin '(memory))))
  ...)                              ; then zip:zip_get/2 per entry, zip:zip_close/1
```

**Workbench is already gitignored** — `xrepl/xrepl/.gitignore:35` → `/workbench`.
So `workbench/support/**` (this whole planning tree) is untracked automatically.
No git action required.

## Corrections to docs 11/12 (code diverges from spec)

**C1 — There is NO op-dispatch plugin seam.** Dispatch is a hardcoded `case` in
`xrepl-dispatcher:handle-message/2` (`xrepl/xrepl/src/xrepl-dispatcher.lfe:21-54`):
ops are pattern-matched literally (`eval`, `clone`, `close`, `ls_sessions`,
`describe`, `ping`, `load_file`, `upload_history`). No registry, no behaviour,
no callback. `describe`'s advertised op list is also hardcoded
(`xrepl-dispatcher.lfe:169-178`). The only behaviour seam in the system is the
*transport* layer (`xrepl-transport`), which does not route ops. Adding a story
capability therefore means a (small) edit to core dispatch — there is no
seam-free path.

**C1b — The evaluator speaks LFE, not raw IF input.** `eval` flows
dispatcher → `xrepl-session:eval/2` (`xrepl-session.lfe:63`) → evaluator
gen_server → `xrepl-eval:eval-form/2` (`xrepl-eval.lfe:47-89`) → `lfe_eval:expr/2`.
So a player's raw line ("take rock", a bare password) cannot be the eval `code`
— the LFE evaluator would choke. Docs 11/12's "reuse `eval`, don't add an op"
was written assuming eval-reuse was free AND that raw input could ride `eval`;
neither holds. **Decision required — see below.**

**C2 — No `clone`-as-branch.** `xrepl-session-manager` exports `create/1`,
`close/1`, `reopen/1`, `destroy/1` — but **no `clone`** that branches an existing
session's state. (Note: the *dispatcher* has a `handle-clone` clause; its exact
semantics weren't pinned — likely create-flavored, not state-branch. PIN LATER.)
Consequence: a play-through STARTS via `create/1`. Doc 12's "clone to create the
story session" and "clone to branch / checkpoint (CYOA for free)" do not hold —
CYOA branching is not free. Fine for v1 (linear play-through + save/resume).

**C3 — State has a free home, but not where the doc put it.** `close/1`
(`xrepl-session-manager.lfe:79-98`) stops the process but PRESERVES the ETS entry,
its `metadata` map, and a `env-snapshot` saved every 60s; `reopen/1` (`:100-125`)
restarts the gen_server and restores bindings (`xrepl-session.lfe:423-444`).
`env-snapshot` only serializes **pure data** (atoms/numbers/strings/lists/
tuples/maps — functions/PIDs/refs excluded; `xrepl-session.lfe:354-367`).
So **in-VM** save/resume of pure data is free. World-state (flags / visits /
inventory) is all pure data → it should live in the **session `metadata` map**
(arbitrary, settable via `xrepl-store:set-metadata/2` `xrepl-store.lfe:148-157`,
auto-persisted in ETS, restored on reopen) — NOT in env bindings and NOT in a
process. Cross-VM-restart "save game" is NOT free (ETS is in-memory only); if we
want it later, `xrepl-store:export-session/import-session` (`xrepl-store.lfe:180-198`)
is the hook for a disk blob keyed by session id.

## The one decision (C1/C1b)

Because dispatch has no seam and the evaluator speaks LFE, I recommend adding
**one small, generic `xs` op** to the dispatcher: a `handle-xs/2` handler, one
`case` clause, and one entry in `describe`'s op list. It routes a story session's
raw input line to `xs-session`/`xs-engine`, keeping raw IF input out of the LFE
evaluator, giving world-state a clean home (session metadata), and still
dogfooding the full session/transport/streaming machinery (the co-author's
actual goal). `xs` is the visible/generic name → leaks nothing.

Rejected alternative: pure eval-reuse forces the client to wrap every turn as
`(xs:turn #"take rock")` and complicates world-state threading through the
evaluator env, for no real gain.

## UPDATE (2026-06-14) — superseded by Duncan's reframe

The single-`xs`-op recommendation above is **withdrawn** in favor of a better
shape: a **per-session pluggable evaluator ("kernel")**. Default kernel = LFE
(`lfe_eval`); entering the story (`xs:run`) swaps in an `xs` kernel that takes
the raw input line and routes it to `xs-engine`, so IF input never touches the
Lisp evaluator. This is xrepl's original DSL-hosting purpose and routes at the
session/eval layer, sidestepping the hardcoded dispatcher (C1) entirely rather
than editing it.

Discovery breadcrumb: a generic **did-you-mean / command-not-found** hook in the
`xrepl-eval` undefined-function path (eval → `lfe_eval:expr/2` raises → caught
and formatted in `xrepl-eval`). When an unbound symbol like `(pwd)` / `(passwd)`
/ `(password ...)` is typed at the LFE REPL, return `#(error "Did you mean
(xs:run 'pwd)?")` (substituting the typed name). Fires only when the symbol is
unbound in `$ENV`. Framed as a real, shippable REPL feature whose easter-egg
payload is a seeded special-case → maximal cover. `(pwd)` is shell-reflex bait.

OPEN: does xrepl support a per-session kernel today, or must we build it? →
**CC capability-discovery audit** (read + exploratory eunit, zero production
changes), seeded with this note, producing a severity-graded report here in
`workbench/support/`. Then Duncan + CDC decide the kernel-seam shape (likely:
add kernel/plugin support). The pure spine (`xs-bundle`/`xs-world`/`xs-engine`)
is unaffected and design-able now.

## Module design implied by the above

- `xs-bundle` — `zip:zip_open(Bin,[memory])`; `read_string/1` per entry; build
  `#{Id => Node}` + manifest; validate graph (dangling `to`/`on-success`/`entry`,
  undeclared flags, missing images=warn, dup ids). Pure-ish, unit-testable.
- `xs-world` — world-state ops over a pure data map (flags/visits/inventory) +
  the condition evaluator (total: unknown form → false + log).
- `xs-engine` — pure transition core `handle(Node, Input, World) ->
  {World2, [Output]}`; `Output` = `{text,B}|{stream,B}|{image,Id}|{goto,Id}|
  suspend|done`. No socket, no terminal.
- `xs-session` — bridges session id ↔ world (held in session metadata), drives
  `xs-engine`, renders `[Output]` → protocol responses (text→`formatted`,
  stream→`["streaming"]`, image→read bytes from the `.xsf` and call
  `xrepl-term-graphics:render-data/2`).
- `xs-kernel` — the dispatcher hook (the `xs` op + describe entry).

Committed code rule (every cc-prompt): `xs-*` is content-agnostic — loads ANY
bundle, contains zero story text and never the word "ground". The only
story-specific tracked artifact is `priv/support.xsf` (opaque).
