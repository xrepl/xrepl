# arc6 / slice1: xrepl Shell-Pluggability Capability Audit

**Date:** 2026-06-14  
**Auditor:** Claude Code (Sonnet 4.6), implementing against the spec in `cc-prompt.md`  
**Method:** Read-only source review + in-process spike tests (all 8 pass)  
**Spike tests:** `test/xrepl-shell-pluggability-spike-tests.lfe`  
**How to run:** `rebar3 as test eunit --module xrepl-shell-pluggability-spike-tests`

---

## Summary

**Can xrepl host and switch shells today?  No.**

There is no server-side "shell" concept in xrepl. The dispatcher routes a fixed set of protocol ops via a hardcoded `case` expression; all `eval` traffic flows unconditionally to `lfe_eval:expr`; there is no shell registry, no shell behaviour, and no mechanism to switch the active evaluator per-session.

The only switching-like seam that exists is **session-level**: a session command (`xrepl-commands:new-session`) can return the special value `#(switch NewSessionId)`, which the dispatcher detects and surfaces as `action=switch` in the response. This is session switching, not shell switching.

To host an IF shell (or any alternate evaluator), at minimum three things must be built: a shell registry, a per-session "active evaluator" field, and a `switch_shell` dispatch op. The seams in the current architecture make this a **MAJOR** but tractable addition.

---

## Q1 — Shell architecture & pluggability

### What is a "shell" in xrepl today?

There are two distinct shell concepts, living on opposite sides of the protocol:

**Client-side shell** (`src/xrepl-client-shell.lfe`):  
An interactive gen_server loop that prompts the user, reads a line of input, and sends `{op: eval, code: input}` to the server. It handles a small set of hard-wired client commands (`(quit)`, `(ping)`, `(render-image ...)`) and otherwise ships everything to the server as eval. This is the "user-facing shell" for network connections.  
**Evidence:** `xrepl-client-shell.lfe:77–145` — `handle_cast 'prompt conn` branch.

**Server-side local REPL** (`src/xrepl-transport-stdio.lfe`):  
For stdio transport, `xrepl-transport-stdio:recv/2` reads an LFE expression and wraps it as `{op: eval, code: form}`. The same dispatcher handles it.  
**Evidence:** `xrepl-transport-stdio.lfe:73–95`.

**There is no server-side shell concept.** The server has sessions, not shells. A session holds an LFE `env` and an evaluator process that always calls `lfe_eval:expr`. There is no "shell type" field, no alternate evaluator dispatch.

### Full read → eval → print path (end to end)

```
Client                          Server
──────                          ──────
io:get_line prompt              
  → trimmed input               
    → xrepl-client:eval conn input          (xrepl-client.lfe:125)
      → sends {op:eval, code:<input>}       (msgpack over TCP/unix)
                                → xrepl-tcp-handler:handle-data (tcp-handler.lfe:78)
                                  → xrepl-dispatcher:handle-message/4 (dispatcher.lfe:73)
                                    → handle-eval (dispatcher.lfe:95)
                                      → xrepl-session:eval sid code (session.lfe:63)
                                        → gen_server:call session-proc {eval form}
                                          → prepare-form (session.lfe:262)
                                            → lfe_io:read_string code → LFE form
                                          → ! evaluator-pid {eval form self}
                                          → evaluator-loop recv (session.lfe:311)
                                            → xrepl-eval:eval-form form env (eval.lfe:47)
                                              → lfe_macro:expand_fileforms
                                              → lfe_eval:expr form env
                                            → ! session-proc {eval-result value new-env}
                                          → gen_server:reply caller {ok value}
                                      → format-value value
                                      → {status:done, value:formatted-string}
        ← {status:done, value:...}    
      ← #(ok binary-value new-conn)
    ← print-value binary-value
```

**Evidence:** traced through source; ran test `q2-metadata-ignored-by-eval-path` which confirmed the eval path reaches `lfe_eval:expr` (returns raw integer 42 for `(+ 20 22)`). **[ran-test]**

### Is there any notion of multiple shells, shell behaviour, or shell registry?

**No.** Read-only confirmation:
- No `-behaviour` definition for shells in any source file  
- No shell registry module  
- No map/ETS table of shell implementations  
- `xrepl-transport.lfe:9–33` defines a `transport` behaviour — the ONLY behaviour seam in the system, and it routes messages, not evals  
**Evidence:** read-only pass over all 27 `src/` modules. **[read-only]**

### Is there any mechanism to switch the active shell?

**No.** The closest thing is the `#(switch SessionId)` and `#(switch-to-other)` special return values that `handle-eval` detects and surfaces as `action=switch` / `action=switch-to-other` in the response (`dispatcher.lfe:105–112`). This switches the **session**, not the evaluator.

`xrepl-session-manager:switch/1` exists (`session-manager.lfe:285–300`) and changes the "current session" in the process dictionary via `erlang:put`. This is purely process-local and is not a protocol-level shell switch.

**Evidence:** `q1-b-session-switch-signal-detected` ran, confirmed `action=switch` in response when `(xrepl-commands:new-session ...)` is evaluated. **[ran-test]**

### Where is the seam for a new shell?

There is **no seam today**. The smallest change that would enable "register shell + switch shell":

1. **Add a `shell` field to the session record** (`xrepl-session.lfe` `session-state`, ~L28–34).  
2. **In `evaluator-loop`** (`session.lfe:311`), instead of always calling `xrepl-eval:eval-form`, look up the session's shell module and call `ShellMod:eval-form form env`.  
3. **Add a `switch_shell` op** to the dispatcher's `case` at `dispatcher.lfe:33–54` (or add a registry and a `register_shell` op).  
4. **Advertise** the shells via a registry read in `handle-describe`.

That is: one new record field, one branch in the evaluator loop, two new dispatcher ops, and a registry. No behaviour definition is strictly required (a module-name convention + `apply/3` would suffice for phase 1).

### Echo-shell probe

I implemented the probe as test `q1-a-unknown-op-rejected`: sent `{op: "echo-probe"}` to the dispatcher. The response was `{status: error, error: {type: unknown-op, message: "Unknown operation: echo-probe"}}`. There is no way to register "echo-probe" as a real op without editing `dispatcher.lfe:33–54` — confirming the lack of a registry. **[ran-test]**

---

## Q2 — Per-session evaluation routing

### Can a session route to an alternate evaluator?

**Not today.** The `evaluator-loop` in `xrepl-session.lfe:311–334` always calls `xrepl-eval:eval-form/2`, which always calls `lfe_eval:expr/2`. There is no branching on session metadata or any other tag.

The exact function to modify is `evaluator-loop/2` at `xrepl-session.lfe:311`. Specifically the line:

```lfe
(xrepl-eval:eval-form form env)   ;; session.lfe ~L322
```

An alternate evaluator would replace this call with `(apply EvalMod 'eval-form (list form env))` where `EvalMod` is read from session state.

**Evidence:** read-only, confirmed by source. **[read-only]**

### Can session metadata carry a shell/mode tag? Does anything read it?

**Metadata CAN carry arbitrary tags; nothing in the eval path reads them.**

Test `q2-metadata-ignored-by-eval-path` set `{shell-mode: calc}` on a session, confirmed the tag was stored via `xrepl-store:get-metadata`, then evaluated `(+ 20 22)`. Result was the raw integer `42` — confirming `lfe_eval:expr` ran, not any alternate evaluator. The `session-state` record has no `shell-mode` field and the evaluator-loop reads no metadata from the store. **[ran-test]**

---

## Q3 — The undefined-function "did you mean" hook

### Where is the undefined-function error raised and caught?

1. **Raised:** inside `lfe_eval:expr/2` (LFE library, not xrepl source) when a function call resolves to an unbound name. Erlang raises `error:{undef, [{FuncName, Arity, Args, []}]}` or LFE raises a similar structure.

2. **Caught:** inside `xrepl-eval:eval-form/2` at `eval.lfe:87–89`:
   ```lfe
   (catch
     ((tuple class reason stack)
      (tuple 'error (format-error class reason stack))))
   ```
   `format-error` (`eval.lfe:23–41`) calls `lfe_lib:format_exception` with a stack-filter that hides `lfe_eval` and `xrepl-eval` frames, and pretty-prints the reason. If formatting itself throws, it falls back to `io_lib:format "~p" [reason]`.

3. **Forwarded:** the formatted string travels as `reason` through `evaluator-loop` → `xrepl-session:handle_info eval-error` → `xrepl-io:format-error` → back to the dispatcher as `#(error formatted-string)` → `make-error-response`.

**Evidence:** read-only source trace + tests below. **[read-only]**

### Observed error shape (verbatim)

Test `q3-a-unbound-fn-session-error-shape` evaluated `(zzznope 1)` via `xrepl-session:eval/2`:

```
xrepl-session:eval/2 return:
  #(error "exception error: #(undefined_function #(zzznope 1 ()))")
   ^class  ^reason — flat char list (formatted error string)
```

The reason is a flat char list (tested with `(is_list reason)` = true). **[ran-test]**

Test `q3-b-unbound-fn-dispatcher-response-shape` confirmed the same call through the dispatcher returns a proper response with `status=error`: **[ran-test]**

```
Response map (atom keys, before msgpack encoding):
  #{status   => error,
    error    => #{type    => eval-error,
                  message => <<"Error: #(undefined_function #(zzznope 1 ...))">>}}
```

### Can we intercept the path for "did you mean"?

Yes, with a small hook. The intercept point is in `xrepl-eval:eval-form/2`'s catch clause (`eval.lfe:87–89`):

```lfe
(catch
  ((tuple class reason stack)
   ;; Hook: inspect reason to see if it is an unbound-function error.
   ;; If so, a shell module could return a custom {formatted, "Did you mean...?"}
   ;; instead of a generic formatted string.
   (tuple 'error (format-error class reason stack))))
```

The `reason` at this point is the raw Erlang exception reason (e.g., `{undef, [{zzznope, 1, [1], []}]}`). A hook could pattern-match on `{undef, [{FuncName, Arity, _, _}|_]}` and return a custom response. Without this hook, the formatter obscures the structured `{undef, ...}` term.

**Severity of building this hook: MINOR.** One `case` expression added to `eval-form`'s catch, delegating to a shell module if set on the session. No protocol change required. Requires the "active shell module" field from Q2's gap to be in place first.

---

## Q4 — Protocol surface

### Streaming

**Not implemented.** The dispatcher has no streaming-emit function, no `streaming` status frames are produced, and no `interrupt` op exists. The spec (`xrepl-unified-spec.md`) mentions `"streaming"` and `"done"` framing and an `interrupt` operation, but these are absent from the current dispatcher (`dispatcher.lfe:33–54` lists ops; no streaming op appears).

**Evidence:** read-only. No streaming-related function was found in any `src/` module. **[read-only]**  
**Could not verify with a test** — would require production change.

### describe / capabilities

`handle-describe` (`dispatcher.lfe:169–178`) returns a hardcoded map:

```lfe
(map 'status 'done
     'versions (map 'xrepl ... 'lfe ... 'erlang ...)
     'ops (list 'eval 'clone 'close 'ls_sessions 'describe 'ping 'load_file 'upload_history)
     'transports (list 'tcp 'unix 'stdio))
```

There is **no mechanism to extend this list** without editing the function. No capability registry, no plugin hook, no `extend-capabilities` API.

Test `q4-a-describe-hardcoded-ops` confirmed: `'shell_switch` and `'shells` are absent from the returned list. **[ran-test]**

### Sessions / metadata round-trip

Test `q4-b-metadata-survives-close-reopen` confirmed:

- `close` stops the session gen_server but preserves the ETS entry (metadata + env-snapshot).
- `reopen` restarts the session process and restores pure-data env bindings.
- **Pure-data metadata** (`{spike-tag: "persists"}`) survived close/reopen. **[ran-test]**
- **Function closures do NOT survive.** `(defun spike-fn (x) (+ x 1))` was callable before close (returned integer `11` for `(spike-fn 10)`); after reopen, evaluating `(spike-fn 10)` returned `#(error "...")`. **[ran-test]**

Caveat: `env-snapshot` serializes only terms where `is-serializable?` returns true (atoms, numbers, binaries, lists, tuples, maps — NOT funs, PIDs, refs, ports). This is documented in `session.lfe:380–396`.

### Response extension field

Test `q4-c-extra-field-survives-msgpack-roundtrip` confirmed: a response map with an extra `'image` key encodes and decodes through msgpack without loss:

```
Input:  #{status => done, value => <<"42">>, session => <<"abc">>, image => <<"PNG_BYTES_HERE">>}
Encoded: binary (msgpack)
Decoded: #{<<"status">> => <<"done">>, <<"image">> => <<"PNG_BYTES_HERE">>, ...}
```

The msgpack encoder is not field-locked. **Extra fields pass through.** However, the **dispatcher never produces them** — `handle-eval` builds a fixed map (`status`, `value`, `session`). Adding an `image` key to eval responses requires editing `handle-eval`. **[ran-test]**

---

## Q5 — Gap analysis & recommendation

| Capability | Severity | Evidence | What's missing | Smallest change to close |
|---|---|---|---|---|
| (a) Register + switch shells | **MAJOR** | Q1 read-only; spike q1-a | No shell concept, registry, or switch op anywhere in server | Add `shell` field to `session-state`; add `apply/3` dispatch in `evaluator-loop`; add `switch_shell` op to dispatcher `case`; add shell registry (map or ETS) |
| (b) Per-session alternate evaluator | **MAJOR** | Q2 ran-test (q2) | `evaluator-loop` hardwires `xrepl-eval:eval-form`; session metadata is inert | One `case` in `evaluator-loop` dispatching to `(apply EvalMod 'eval-form [form env])` if session has a `shell` field |
| (c) Unbound-symbol "did you mean" hook | **MINOR** | Q3 ran-test (q3-a, q3-b) | `format-error` in `eval-form` catch discards the structured `{undef, ...}` before a shell can inspect it | Inspect `reason` in `eval-form`'s catch before formatting; if `{undef, [{Name, Arity, _, _}|_]}`, call `ShellMod:unbound-hook Name Arity Env` instead of `format-error` |
| (d) Streaming (`streaming`/`done` frames) | **BLOCKER** | Q4 read-only | Entirely absent: no streaming emit, no interrupt op, no incremental response protocol | New streaming protocol layer required: `handle-stream-eval`, a streaming-capable `eval-form`, and `interrupt` op; significant work |
| (e) Capability/shell advertisement | **MAJOR** | Q4 ran-test (q4-a) | `handle-describe` returns hardcoded list; no registry to extend | Add a capability registry (ETS or config); `handle-describe` reads from it; `register_shell` op adds entries |
| (f) Response extension field (`image`, etc.) | **MINOR** | Q4 ran-test (q4-c) | `handle-eval` builds a fixed-key map; extra fields never produced | `handle-eval` passes an optional `extra-fields` map from the eval result; `make-response` merges it; needs a convention for shells to return extra fields |

### Recommendation (for Duncan + the design lead to decide from)

This audit finds **xrepl has the right skeleton but lacks the shell-pluggability layer**. The core eval path is clean and well-seamed — the `evaluator-loop`'s single `eval-form` call is the natural hook point. The evidence suggests the following smallest viable addition:

1. **Shell registry + session field (MAJOR):** A shell is a module implementing a small interface (`eval-form/2`, optionally `unbound-hook/3`). Add a `shell` field to `session-state`, default to `xrepl-eval`. The dispatcher gets a `switch_shell` op that sets this field. The `describe` op reads the registry. This is foundational — (b), (c), and (e) all follow from it.

2. **"Did you mean" hook (MINOR, blocked on #1):** Once the session carries a shell module, one `case` in `eval-form`'s catch checks if the raw exception is `{undef, ...}` and asks the shell module before falling back to the default formatter.

3. **Streaming (BLOCKER, can defer):** Nothing in the current wire protocol or server supports streaming. This is real work and probably should not block a first IF shell if that shell's responses are short (command → one response).

4. **Response extension fields (MINOR, blocked on #1):** Once shells can return custom values, add a convention (`#(extra-fields Map)` wrapped in the result) that `handle-eval` merges into the response map.

**Decisions needed:**

1. **Shell interface contract:** Should a "shell" be a module with known exported functions (`eval-form/2`, optionally `unbound-hook/3`)? Or a callback struct? The answer shapes the registry and the switch op.
2. **When to add streaming:** Is the IF shell's first milestone constrained to single-turn interactions (no streaming needed)? Or does the story-engine output stream chunks? If the latter, streaming is a BLOCKER and must be scoped now.
3. **Scope of `switch_shell` op:** Should shell-switching be per-connection, per-session, or global? The simplest implementation is per-session (one field in `session-state`). Global would require an app-level registry and is probably wrong for a multi-user server.

---

## Corrections to the seed map

| Seed claim | Correct? | Correction |
|---|---|---|
| "Dispatch is a hardcoded `case` in `handle-message/2` ~L21–54" | ✓ Confirmed | Lines are accurate: L33–54 for the `case`, handle-message/2 at L21. |
| "`describe`'s advertised op list is also hardcoded (~L169–178)" | ✓ Confirmed | L169–178 accurate. |
| "eval path: `handle-eval/2` (~L95–132) → `xrepl-session:eval/2` (~L63)" | ✓ Confirmed | Line numbers accurate. |
| "`evaluator gen_server loop (~L311–334) → xrepl-eval:eval-form/2 (~L47–89)`" | ✓ Confirmed | Both ranges accurate. |
| "`session-state` record (~L28–34) holds LFE `env`, evaluator PID, etc." | ✓ Confirmed | Fields: id, env, evaluator, eval-pending, last-save, save-interval. |
| "Arbitrary per-session data lives in a `metadata` map (set via `xrepl-store:set-metadata/2` ~L148–157)" | ✓ Confirmed | `set-metadata/2` at L157; the actual gen_server call at L148. |
| "`env-snapshot` serializes **pure data only** (`xrepl-session.lfe` ~L354–367)" | ✓ Confirmed | `serialize-env/1` at L354, `filter-serializable-bindings` at L369, `is-serializable?/1` at L380. |
| "`export-session`/`import-session` exist (`xrepl-store.lfe` ~L180–198)" | ✓ Confirmed | `export-session/1` at L180, `import-session/1` at L190 (store API). |
| "A 'shell' concept exists client-side: `xrepl-client-shell.lfe`, `xrepl-client-shell-fns.lfe`" | ✓ Confirmed | These exist. But the framing "shell concept" should be clarified: this is the CLIENT-SIDE interactive loop, not a server-side evaluator shell. The server has no shell concept. |
| "`priv` idiom: `(code:priv_dir 'xrepl)` + `filename:join`" | ✓ Confirmed | Used in `xrepl-client-shell.lfe:304` (banner loading). |
| "No registry / behaviour / callback for ops" | ✓ Confirmed | `xrepl-transport` behaviour exists but routes messages, not ops. |
| "no `clone`-as-branch" for sessions | ✓ Confirmed | `clone` creates a fresh session, not a branch of an existing one. |

---

## Observations (out-of-scope; noted for Duncan + design lead)

1. **`make-error-response` uses `list_to_binary` on error strings** (`dispatcher.lfe:318–323`). If LFE's exception formatter ever returns an iolist with chars > 255 (Unicode), this raises badarg. The safe alternative is `iolist_to_binary`. Currently masked by the `format-error` fallback path in `xrepl-eval:format-error` which uses `io_lib:format "~p"` (ASCII output) when `lfe_lib:format_exception` throws.

2. **`xrepl-tcp-handler:handle-data` has no surrounding try-catch** (`tcp-handler.lfe:78–110`). An exception inside `handle-message` (e.g., from the `make-error-response` issue above) would crash the connection process.

3. **`xrepl-commands.lfe` uses process-dictionary** for `switch-session` via `session-manager:set-current` which calls `erlang:put` (`session-manager.lfe:230–241`). This is process-local and not visible across connections. The current-session concept is suitable only for the local REPL context, not multi-client server use.

4. **`load_file` op is a stub** returning `not-implemented` (`dispatcher.lfe:188–190`).

---

## What I could NOT determine

1. **Streaming interrupt path** — not testable without building streaming support. Whether the protocol framing (4-byte length prefix + msgpack) can carry `streaming` frames in sequence to the same client socket requires a production change to verify.

2. **Whether `lfe_lib:format_exception` can produce chars > 255** for common errors — this depends on internal LFE library behavior I didn't trace into. The fallback prevents visible failures today but the latent risk in `make-error-response` is real.

3. **Whether the `clone` op is intended to eventually support branching** (the spec's terminology suggests it might). The current implementation (`dispatcher.lfe:134–147`) just creates a fresh session with no connection to a parent.

4. **`switch-to-other` semantics** — `xrepl-commands.lfe` returns `#(switch-to-other)` in `switch-session/1` for the case where a session is found but something else applies (`dispatcher.lfe:113`). The exact client behavior triggered by `action=switch-to-other` was not traced client-side; it is surfaced in the response map but how the client interprets it was not determined.
