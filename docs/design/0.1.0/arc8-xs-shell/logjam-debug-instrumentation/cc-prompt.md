# CC PROMPT — logjam logging setup + image-render debug instrumentation

**You are** Claude Code (Sonnet 4.6), implementing to a spec from the design lead
(sibling CDC/Opus), reviewed by Duncan (lead + QA).

> **EDITING SAFETY (mandatory):** No `sed -i` / in-place stream edits — structured
> editor only. Clean git tree; `git diff --stat` after, report it.

> **LEDGER DISCIPLINE (mandatory):** Ledger at
> `logjam-debug-instrumentation/ledger.md`. Read it first; fill Evidence as you
> go; closing report walks every row L-1…L-6 individually. Five-iteration cap.

**Mission:** (A) set up **logjam** (Duncan's LFE logger formatter, v1.2.4) for
xrepl at **debug** level so logs are readable, then (B) instrument the
image-render path with debug logs to localize a hang: `(render-image "…")` hangs
the REPL on enter with **no output at all** — so it's IN the render path, before
any `put_chars` flush.

**Read first:** the ledger; **`lfe/logjam/README.md`** (config + the `log-debug`
macros); and a proven consumer config: **`lfe/poise/rebar.config`** (uses
`{logjam, "1.2.3"}`) and its `sys.config`. Plus the proto-skill gotchas.

## Part A — set up logjam (L-1, L-2, L-3)
1. **Dep:** add `{logjam, "~> 1.2"}` (1.2.4 is current) to xrepl `rebar.config`
   deps; let `rebar3` update `rebar.lock`; `rebar3 compile` clean.
2. **Config:** create `config/sys.config` per logjam's README — replace the
   kernel default handler's formatter with `{logjam, #{…}}` (use the README's
   options: e.g. `colored => true`, `level_capitalize => true`, `map_depth`,
   `term_depth`). Set the level to **debug** in BOTH places that matter: the
   kernel primary `logger_level` (`{logger_level, debug}`) AND the handler
   `level => debug` — otherwise the primary filter drops debug before the handler
   sees it.
3. **Boot it:** `./bin/xrepl` starts `erl … -eval "application:ensure_all_started(xrepl), xrepl:start(…)"`
   (~line 285) with NO `-config`. Add `-config "<path>/config/sys.config"` (erl
   wants the path WITHOUT the trailing `.config`, i.e. `-config .../config/sys`)
   to that `erl` invocation, resolving the path the same way the script resolves
   `XREPL_EBIN`. Result: startup logs render in logjam's ANSI style (not the
   default `=INFO REPORT=`), and debug lines appear.
   - If wiring `-config` into the script is fiddly, the README's runtime
     alternative is `(logjam:set-config …)` called early in `xrepl:start` — but
     prefer `-config` (configures the formatter at boot, before any log fires).

## Part B — debug-log the render path (L-4, L-5)
Use the logjam macros for module/line context: add
`(include-lib "logjam/include/logjam.hrl")` to each instrumented module and use
`(log-debug "msg ~p" (list X))`. Bracket each step with entry + key values, and
crucially **a log just before AND just after the side-effecting call**, so a
missing "after" pinpoints the hang:

- `src/xrepl.lfe` `execute-graphics-command` — log the form on entry.
- `src/xrepl-client-shell-fns.lfe` `render-image` — log filepath; before/after
  the `xrepl-term-graphics:render-file` call.
- `src/xrepl-term-graphics.lfe` `render-file` — log path; after `file:read_file`
  (size); before/after `render-data`. `render-data` — log the detected protocol.
  `render-iterm2` — log "before iterm2-sequence", "after (seq built, N bytes)",
  **"before put_chars"**, **"after put_chars"** (the prime suspect).
- `src/xs-shell.lfe` `render-images` — log each image id, before/after the
  `xrepl-term-graphics:render-data` call. `src/xs-bundle.lfe` `image-bytes` —
  log the id and the ok/error result.

Keep the log lines terse; don't change any logic — instrumentation only.

## Done criteria
- [ ] Ledger L-1…L-6 each final with evidence; per-row closing walk.
- [ ] logjam dep + `config/sys.config` (debug, logjam formatter) + `./bin/xrepl`
      `-config`; ANSI debug logs at startup.
- [ ] Debug logs bracket the render-image AND story-image paths (before/after the
      side-effecting calls).
- [ ] Suite green; `git diff --stat`; no `sed`; logic unchanged.

## Hand back
Per-row ledger walk; diffs + diffstat; confirm logjam ANSI debug output is live
(paste a couple of startup log lines). The hang itself is then localized by
Duncan running `(render-image …)` and reporting the last debug line before it
hangs — so make the before/after `put_chars` logs unmistakable.
