# CC PROMPT — arc7 / slice2: `xs-world` (state + total condition evaluator)

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design
lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

**Mission:** Implement `xs-world` — the per-play-through world state (flags,
per-node visit counts, inventory) plus a **total** evaluator for the condition
grammar. Pure data, no IO, no xrepl deps. The values are atoms/numbers/maps only
so the whole world serializes for free (Arc8 stores it in session metadata).

**Design-of-record:** `docs/design/0.1.0/arc7-xs-engine/design.md` (Module 2).
`xs-bundle` (slice1) is landed and green; it produces the manifest/flag shapes
this module consumes.

## Scope — two new files
CREATE `src/xs-world.lfe`, `test/xs-world-tests.lfe`. Touch nothing else. No git.
Content-agnostic (neutral fixtures; no story words).

## Shapes (from `xs-bundle`)
`xs-bundle` parses the manifest into a map whose `flags` key is a **list of
flag-definition maps**, each `#m(id <atom> type bool default <bool>)`. (A single
`(flag …)` still yields a one-element list — `xs-bundle:parse-flags` already
normalizes that, so flags are reliably a list. You do NOT need to handle a bare
single flag here.)

## World representation
```
World = #m(node    Id           ; current node id (atom)
           flags   #{f => bool}  ; flag-id -> value
           visits  #{Id => N}    ; per-node visit count
           items   #{id => true});; held item ids
```

## API
```
(new Manifest)            -> World
    ;; seed flags from each flag-def's default; visits/items empty;
    ;; node := (maps:get 'entry Manifest 'undefined)
(current-node World)      -> Id
(set-node World Id)       -> World
(flag World F)            -> bool          ; default 'false if unset
(set-flag World F V)      -> World
(visits World Id)         -> integer       ; 0 if unvisited
(bump-visit World Id)     -> World          ; +1
(has-item World Id)       -> bool
(add-item World Id)       -> World
(eval-cond Cond World)    -> bool
```

## The condition grammar — `eval-cond/2` (MUST be total)
Evaluate a single condition s-expr against `World`:
```
(flag? F)        -> (flag World F) is truthy ('true)
(not C)          -> not (eval-cond C World)
(and C ...)      -> all sub-conds true   (use LFE andalso semantics / lists:all)
(or  C ...)      -> any sub-cond true    (lists:any)
(>= visits N)    -> (visits World (current-node World)) >= N
(=  visits N)    -> (visits World (current-node World)) == N
true             -> true
false            -> false
```
**Totality is the rule:** any unrecognised / malformed form → return `'false`
AND `logger:warning` it (the "undefined smell" — a malformed bundle must never
crash a play-through). Test this explicitly.

Notes:
- `visits` in the grammar means **this (current) node's** visit count — read it
  via `(current-node World)`, per design doc §1.6.
- Implement `and`/`or` so they don't crash on a non-condition arg — evaluate each
  via `eval-cond` (which is itself total), so a bad sub-form degrades to `false`.
  (Recall the LFE gotcha: `(and …)`/`(or …)` are functions; use `andalso`/`orelse`
  or `lists:all`/`lists:any` over the evaluated sub-results.)

## IR-consumption note (applies more to slice3, but be aware)
`xs-bundle`'s `parse-keyword-list` stores a single-element multi-valued field
**bare** and a multi-element one as a **list**. `xs-world` mostly evaluates single
condition forms, so it's largely unaffected — but if you ever iterate a node
sub-form here, normalize with an `as-list` helper (bare non-list → one-element
list). slice3 will lean on this heavily.

## Tests (`test/xs-world-tests.lfe`)
- `new` seeds flag defaults (e.g. a manifest with flags `has-rock=false`,
  `bearing=false` → `(flag World 'has-rock)` = `false`); `node` = the entry.
- `set-flag`/`flag` round-trip; unknown flag reads `false`.
- `visits` 0 before, `bump-visit` → 1, → 2; per-node isolation (bump room-a,
  room-b still 0).
- `add-item`/`has-item`; absent item → `false`.
- `eval-cond` — **one assertion per grammar form**: `(flag? f)` both truthy and
  falsy; `(not …)`; `(and …)` (all-true vs one-false); `(or …)`; `(>= visits N)`
  and `(= visits N)` against a world with a known visit count for the current
  node; literal `true`/`false`.
- **Totality:** `(eval-cond '(bogus-form 1 2) World)` → `false` (and the warning
  path is exercised); a non-list cond like `'whatever` → `false`.

## Done criteria
- [ ] `src/xs-world.lfe` + `test/xs-world-tests.lfe`; nothing else; no git.
- [ ] World is pure data (atoms/numbers/maps only).
- [ ] `eval-cond` covers every grammar form AND is total (unknown → false + warn).
- [ ] New + full suite green; both runs reported.
- [ ] Content-agnostic; neutral fixtures.

## Hand back
The two files, both test runs, the final `World` map shape, and confirmation that
`eval-cond` returns `false` (not a crash) for malformed input. Flag anything in
the manifest/flag shape from `xs-bundle` that differed from this spec.
