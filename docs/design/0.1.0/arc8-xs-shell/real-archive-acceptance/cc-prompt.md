# CC PROMPT — acceptance test: the first real `.xsf` (`ground-0.1.1.xsf`)

**You are** Claude Code (Sonnet 4.6), implementing/testing to a spec from the
design lead (sibling CDC/Opus), reviewed by Duncan (lead + QA).

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits — structured
> editor only. Clean git tree; run `git diff --stat` after and report it.

**Mission:** Acceptance-test our engine against the **first real story archive**,
and fix one validation bug found in review. The archive
(`ground-0.1.1.xsf`) is the authored opening chapter: 12 nodes + 5 PNGs;
a play-through runs surface → basement → the `d2-elevator` `suspend` (the
authored frontier) and stops there.

## Important: keep story content OUT of the repo
The archive is real story content. **Do NOT commit it**, and do NOT commit any
test that depends on it. Part 1 (the bug fix) is committed with a NEUTRAL test.
Part 2 is a LOCAL acceptance pass (scratch script + manual run) — report results,
commit nothing story-specific.

---

## Part 1 — FIX: image validation must be stem-aware (committed, neutral test)
In `src/xs-bundle.lfe`, the load-time image-presence check (the
`validate-image-warnings` path) indexes `image-assets` by **full filename**
(`"01-mill-cold.png"`) but nodes reference images by **stem**
(`(image "01-mill-cold")`). So it warns "image not in bundle" for every
stem-referenced painting even though `image-bytes/2` (which IS stem-aware)
resolves them fine. Make the validation use the **same stem-or-exact** match as
`image-bytes` (e.g. compare the node's image id against each asset's basename AND
`filename:rootname` of the basename). Result: a node `(image "door")` with asset
`assets/images/door.png` produces **no** warning.

Add/extend a NEUTRAL `xs-bundle-tests` case: a bundle whose node references an
image by stem and whose zip has `<images-dir>/<stem>.png` → **loads with no image
warning**; a genuinely-missing image → still warns. Full suite stays green.

## Part 2 — LOCAL acceptance pass (not committed)
Place the archive and run it through the real engine.

1. **Install:** copy `ground-0.1.1.xsf`
   (`…/Alternating Current/Backstory/GROUND/dist/ground-0.1.1.xsf`, ask Duncan for
   the path on this machine) to `xrepl/xrepl/priv/support.xsf`. `rebar3 compile`.

2. **Load check** (scratch `.lfe` script or an `erl`/`lfe` shell one-liner; do NOT
   commit): load `priv/support.xsf` via `xs-bundle:load-file` →
   - `#(ok Bundle)`, **no `{error,…}`**, and after Part 1 **no spurious image
     warnings**;
   - `entry-node` = `door`; the node table has 12 nodes; every `(to …)` /
     `(on-success …)` resolves (no dangling — the archive is graph-clean);
   - `xs-bundle:image-bytes Bundle "01-mill-cold"` → `#(ok <bytes>)` (stem
     resolves `assets/images/01-mill-cold.png`); same for `02-warehouse-amber`
     … `05-campsite-dawn`.

3. **Scripted play-through** (read the node forms from the archive to learn the
   path + passwords — the content isn't secret from *you*): drive
   `xs-shell:start` then `xs-shell:eval` in sequence through the opening:
   enter `door` (prompt) → `back` → `open-area` (its `#(image "01-mill-cold")`
   should resolve) → return to `door` (2nd visit ⇒ the rock `reveal` appears) →
   `take rock` (sets `has-rock`, reveals the password) → enter the password →
   `interior` → … → continue to `d2-elevator`, which is a `suspend` ⇒ the turn
   should return a switch-back-to-LFE and write the world to `'xs-save`.
   Assert: rooms render their (multi-paragraph) text; the password gate works;
   the rock item works; reaching `d2-elevator` suspends + saves.

4. **Save/resume:** with the `'xs-save` from the suspend in the session metadata,
   the `xs:run` resume path rebuilds at `d2-elevator` and re-renders that room.
   (Recall `get-current` self-registers in the evaluator now, so resume finds the
   session.)

5. **Manual smoke:** `./bin/xrepl`; type a trigger word (`(open)`) → nudge →
   `(xs:run)` → walk a few steps. On **iTerm2 or Kitty** the `open-area` painting
   should display; on a plain terminal / CI it skips silently (text only) —
   `render-data` emits iTerm2/Kitty only, never sixel.

## Done criteria
- [ ] Part 1 fix committed + neutral test; full suite green; `git diff --stat`
      reported; no `sed`; no story content committed.
- [ ] Part 2 report: load (clean, no spurious warnings), 12 nodes, image-bytes
      resolves all 5 stems, scripted play-through to the `d2-elevator` suspend,
      save/resume, manual smoke (note terminal used + whether the image showed).

## Hand back
The Part-1 diff + test run + diffstat, and a Part-2 acceptance report: what
loaded/played/rendered, the exact path you drove, anything that crashed or
mis-rendered or read wrong against the real content (flag, don't paper over),
and which terminal you smoke-tested in.
