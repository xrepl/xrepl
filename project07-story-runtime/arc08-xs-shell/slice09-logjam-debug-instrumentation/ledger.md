# Slice: logjam logging setup + image-render debug instrumentation

Yak-shave + diagnostic (Duncan, 2026-06-16). xrepl uses the default OTP `logger`
formatter (ugly). Set up **logjam** (Duncan's LFE logger formatter + macros,
v1.2.4) at **debug** level, then instrument the image-render path with debug logs
so we can localize the `(render-image …)` hang (it hangs on enter, no output —
so it's IN the render path, before any `put_chars` flush).

logjam lives at `lfe/logjam` (README has the config); proven consumer config:
`lfe/poise/rebar.config` + its sys.config use `{logjam, "1.2.3"}`.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| L-1 | `logjam` (~1.2) is a dep in xrepl `rebar.config`; `rebar.lock` updated; compiles. | `grep -n logjam rebar.config rebar.lock`; `rebar3 compile` clean | serious | Duncan | open | | |
| L-2 | `config/sys.config` sets the kernel default logger handler's `formatter => {logjam, …}` and BOTH the primary `logger_level` and the handler `level` to `debug`. | `grep -nE "logjam|logger_level|level => debug|level, debug" config/sys.config` | serious | Duncan | open | | |
| L-3 | `./bin/xrepl` boots with that config (`-config …/sys.config` added to the `erl` invocation, ~line 285) so logjam formatting + debug level are active at startup. | `grep -n "config" bin/xrepl`; manual: startup log lines are ANSI logjam-formatted (not the default `=INFO REPORT=` style), and debug-level lines appear | serious | Duncan | open | | |
| L-4 | Debug logs (logjam `log-debug` macro — include `logjam/include/logjam.hrl`) bracket each step of the **render-image** path: `xrepl:execute-graphics-command`, `xrepl-client-shell-fns:render-image`, `xrepl-term-graphics:render-file`, `render-data`, `render-iterm2` — each logging entry + key values + (for the last safe point) just-before/just-after `put_chars`. | `grep -rn "log-debug" src` shows logs in each named fn | serious | Duncan | open | | |
| L-5 | Debug logs also bracket the **story image** path: `xs-shell:render-images` (per id), `xs-bundle:image-bytes` (id + ok/error). | `grep -n "log-debug" src/xs-shell.lfe src/xs-bundle.lfe` | correctness | review | open | | |
| L-6 | Existing behaviour unchanged; full suite green (note pre-existing flaky failures); no `sed`; logging added, nothing else altered. | `rebar3 as test eunit`; `git diff --stat` | serious | standing rules | open | | |

## Hand back (the diagnostic payoff)
After this lands, Duncan runs `./bin/xrepl` → `(render-image "priv/images/logo-v1-x250.png")`.
The **last debug line printed before the hang** localizes it (e.g. "render-iterm2:
before put_chars" with no "after" ⇒ the hang is the write). Report that line — it
tells us exactly where to fix.

## What Worked

_(Filled at close.)_

## Closure

_(Closed at <SHA> on <date>. CDC: <session>. Rows: 6. Done/Deferred/No-op: _.)_
