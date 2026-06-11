# Closing Report — Slice 1 (Working state + repo hygiene)

Per-row walk written at slice close. Ledger: `ledger.md`. Independent
verification: `cdc-verification.md`. Closed at commit `f8afef7` (ledger) on
baseline `d1f29f4`; one iteration, no `src/` changes.

### F-1: `rebar3 compile` succeeds

**Status: done.**

`rebar3 compile` exits 0 on the baseline checkout at `d1f29f4`. The build
compiles all three apps (xrepl_term, xrepl_protocol, xrepl) plus dependencies
(lfe, ranch, bbmustache, msgpack) without errors. Two benign LFE warnings
from the `lfe` dependency itself (`cl.lfe:472,479: redefining core function
car/1, cdr/1`) — these are upstream in LFE's cl module, not in xrepl code.
No code changes were needed.

### F-2: `rebar3 as test lfe ltest` is green

**Status: done.**

All 39 tests pass, exit 0, on the baseline at `d1f29f4`. Four test modules ran:

- `xrepl-config-tests`: 11 passed (54ms)
- `xrepl-multi-session-tests`: 7 passed (30ms)
- `xrepl-session-manager-tests`: 12 passed (37ms)
- `xrepl-store-phase2-tests`: 9 passed (3031ms)

Summary: 39 passed, 0 skipped, 0 failed, 0 erred. Total time: 6303ms.

No code changes were needed. The historical cover/xref trouble (commits
`eac9d8f`, `f8b6e11`, `99462ea`) did not manifest — those gates are still
commented out and `min_coverage=0`, which is correct for this slice (re-enabling
them is Arc 06 / L-07, not this slice).

### F-3: Crash dump triaged then removed

**Status: done.**

**Triage:** The crash dump (`erl_crash.dump`, 1.5 MB, dated Sat Oct 18 00:08:49
2025) recorded a clean application shutdown on Erlang/OTP 28 [erts-16.0]. The
slogan was `Kernel pid terminated (application_controller)
("{application_terminated,kernel,shutdown}")` — the application_controller shut
down the kernel application normally. Only 11 processes were alive at dump time,
all system-level (init, erts_code_purger, socket_registry, erl_prim_loader,
logger). No xrepl session processes, keepalive timers, or evaluator processes
were running. The `xrepl-app` and `xrepl-sup` modules were loaded but no xrepl
processes were active. **This does not map to L-01 (keepalive desync) or L-04
(session cleanup/ETS leak)** — there were no active sessions at the time of the
dump. The crash dump was most likely produced by a normal `erl` termination
(Ctrl-C or `q()`) where OTP 28 wrote a dump on the clean shutdown path.

The file was gitignored and has been deleted. `ls erl_crash.dump` → "No such
file or directory."

### F-4: Root scratch files removed/relocated

**Status: done.**

`test_quit.lfe`, `tmp/`, and `COMMIT_MSG.txt` are all absent from the tree at
`d1f29f4`. These files were untracked (never committed) and were removed by
Duncan before this slice was picked up. They do not appear in any commit between
`dfab3a0` (the HEAD when the remediation program plan was written) and `d1f29f4`
(current HEAD), confirming they were local working-tree artifacts that have been
cleaned up.

### F-5: Untracked design doc resolved

**Status: done.**

`docs/design/xrepl-protocol-impl-master-plan.md` no longer exists in the tree.
`git status --short` for that path returns empty output. The file was removed in
commit `ca5fa66` ("Started moving docs around") as part of Duncan's doc
reorganization, alongside the deletion of `xrepl-protocol-extraction.md` (979
lines) and moves of several other design docs into `docs/design/0.1.0/`.

### F-6: No stray untracked files in tree

**Status: done.**

`git status --short` returns empty output — the working tree is fully clean.
The `workbench/` directory mentioned in the criterion is tracked (committed).
The doc reorganization commits (`ca5fa66`–`d1f29f4`) resolved all previously
untracked design docs. `erl_crash.dump` was gitignored and has been deleted
(F-3). `_build/` is gitignored.
