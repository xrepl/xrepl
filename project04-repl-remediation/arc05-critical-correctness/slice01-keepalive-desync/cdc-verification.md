# CDC Verification — Arc 05 Slice 1: L-01 keepalive desync

**Date:** 2026.06.11 · **Verifier:** CDC (independent context; did not implement
this slice) · **Ledger commit verified:** `98f986c` (committed close) **and**
the working-tree revision of `ledger.md` — the five F-rows are byte-identical
between the two (`git diff HEAD -- …ledger.md | grep '^[+-]| F-'` → empty);
only the header, a CDC What-Worked bullet, and the Closure line differ.
**Fix commit:** `2ccceed` · **Baseline:** `6609a12` · **HEAD at verification:**
`98f986c` on branch `arc5/slice1-keepalive-desync`.

**Supersession note.** A prior CDC pass had written a `cdc-verification.md`
(staged, uncommitted) reaching the same 4/5 outcome with F-3 proposed-done.
This report replaces it after a full independent re-run. The prior pass's
findings (CDC-1…CDC-5) are carried forward below because other documents
reference them (CDC-4 in `../arc-plan.md`, `cc-prompt.md`, `ledger.md`).

---

## F-1 — `after 30000` clause removed: **confirmed**

Verify command, re-run exactly (sandbox, working tree at `98f986c`):

```
$ grep -n "after 30000" src/xrepl-tcp-handler.lfe; echo $?
exit=1            (no output)
$ grep -n "after " src/xrepl-tcp-handler.lfe; echo $?
exit=1            (no output — no replacement idle timer)
```

Independently cross-checked at the fix commit: `git show 2ccceed --
src/xrepl-tcp-handler.lfe` shows the `(after 30000 …)` clause (old lines
78–82) deleted; the current `message-loop` `receive` has exactly three
clauses — `tcp`, `tcp_closed`, `tcp_error` — and blocks indefinitely, as the
ledger intends. Matches the evidence column.

Residual cosmetic defect: the deletion left `)))` orphaned on its own line
(current `src/xrepl-tcp-handler.lfe:79`) — prior finding CDC-1, still
unfixed at `98f986c`.

## F-2 — `send-keepalive` removed: **confirmed**

```
$ grep -n "send-keepalive" src/xrepl-tcp-handler.lfe; echo $?
exit=1            (no output)
$ grep -rn "send-keepalive" src/ test/; echo $?
exit=1            (repo-wide, no stragglers — partial-adoption sweep clean)
```

The only remaining `send-keepalive` occurrences in the repo are historical
design documents (`docs/design/0.1.0/arc3-networked-repl/plan.md`,
`cc-prompt.md` there) — records of the old design, not code and not
user-facing claims. Deletion (the preferred resolution) was taken; the diff
confirms one call site existed (the deleted `after` clause).

## F-3 — regression test, red-on-baseline + green post-fix: **confirmed (operator-executed host reproduction, 2026-06-11)**

The Verify command is `rebar3 as test lfe ltest`. **I could not execute it:**
the sandbox has no BEAM toolchain (`erl: command not found`), no root for
`apt` (dpkg lock: permission denied; `sudo` blocked by no-new-privileges),
distro candidate is OTP 24 (jammy) vs the project's newer beams, and
`binaries2.erlang.org` is blocked by the network allowlist
(`X-Proxy-Error: blocked-by-allowlist`). A `done` whose Verify command CDC
cannot reproduce is proposed-done; this row requires a host run.

What I **did** independently verify, statically:

1. **Test is not vacuous (discipline failure mode #4).** Read
   `test/xrepl-keepalive-tests.lfe` in full: assertion (a) `is-equal
   #(error timeout) (xrepl-client:recv conn 500)` after a real 31 s idle —
   the arm that goes red on baseline by receiving the ping frame; assertion
   (b) requires the post-idle eval to match `` `#(ok ,_ ,_) `` — a *correct
   reply*, not merely no-crash. No spec-softening. `deftestgen` +
   `{timeout, 60, …}` handles the eunit 5 s default; `try`/`after` guards
   cleanup; standalone Ranch listener with a private ref.
2. **Red output is forensically genuine — re-derived, not just accepted.**
   At baseline `6609a12`, `send-keepalive` passed `(map 'id (binary
   "keepalive"))` while `send-response` (baseline `:142-152`) looks up
   `(maps:get (binary "id") request (binary "unknown"))` — atom key written,
   binary key read — so the wire frame's id was unconditionally `#"unknown"`.
   CC's reported red value `#(ok #M(#"id" #"unknown" #"status" #"ping"))`
   reproduces this non-obvious artifact exactly; fabricated output would
   almost certainly have said `#"keepalive"`.
3. **Diff scope is exactly as claimed.** `git diff --numstat 6609a12 2ccceed`
   → `src/xrepl-tcp-handler.lfe 1+/11−`, `test/xrepl-keepalive-tests.lfe
   86+`, nothing else. Green count 40 = Arc 04's closed 39 + this test.
4. **Build artifacts corroborate a host run.**
   `_build/test/lib/xrepl/ebin/xrepl-tcp-handler.beam` (mtime Jun 11 23:54)
   contains no `keepalive` string — compiled post-fix — and
   `_build/test/lib/xrepl/test/xrepl-keepalive-tests.lfe` was staged at
   23:55, consistent with the reported green run. Corroboration, not
   reproduction.

**Host reproduction record (closes this row).** Operator-executed on
2026-06-11 via `cdc-f3-red.sh` v3 (worktree at `6609a12`, deps seeded from a
`_build` copy with the xrepl app evicted, test injected from `2ccceed`):

- Guard (a): `after 30000` present in worktree source — true baseline.
- Guard (b): worktree compiled its own handler beam (differs from the
  repo's post-fix beam) — no contamination.
- **RED:** `xrepl-keepalive-tests` failed at line 47 in 31,019 ms with
  `#(expected #(error timeout))
   #(value #(ok #M(#"id" #"unknown" #"status" #"ping")))` —
  the exact forensic artifact re-derived in item 2 above. Suite:
  `Tests: 40 Passed: 39 Failed: 1`.
- **GREEN:** operator ran `rebar3 as test lfe ltest` on the slice branch
  (pre-iteration-3 state): completed successfully, with the expected ~31 s
  idle pause observed.

Harness note for the record: reproducing red took the script three
iterations of its own (v1 dep-ordering failure, v2 `_build`-copy
contamination that produced a false "vacuous test" alarm, v3 guarded) —
failures logged in the script header. The guards in v3 are what make this
verdict trustworthy.

**Topology caveat (prior CDC-3, resolved for later work):** test and fix
landed in the single commit `2ccceed`, so the red state is not a plain
checkout.
Host reproduction script (run from the repo root, on the host — **not** the
sandbox; `git worktree add` writes to `.git`):

```sh
git worktree add /tmp/cdc-f3-red 6609a12
git show 2ccceed:test/xrepl-keepalive-tests.lfe \
  > /tmp/cdc-f3-red/test/xrepl-keepalive-tests.lfe
( cd /tmp/cdc-f3-red && rebar3 as test lfe ltest )
# EXPECT: xrepl-keepalive-tests FAILS with
#   #(value #(ok #M(#"id" #"unknown" #"status" #"ping")))

git worktree add /tmp/cdc-f3-green 2ccceed
( cd /tmp/cdc-f3-green && rebar3 as test lfe ltest )
# EXPECT: 40 tests, 40 passed (≈31.5 s — the idle window is real time)

git worktree remove --force /tmp/cdc-f3-red
git worktree remove --force /tmp/cdc-f3-green
```

*(Satisfied 2026-06-11 — see the host reproduction record above. The
original five rows are now fully reproduced: 5/5.)*

## F-4 — client has no `ping` clause and needs none: **confirmed**

```
$ grep -n '#"ping"' src/xrepl-client.lfe; echo $?
exit=1            (no output)
```

`git diff --numstat 6609a12 2ccceed` shows `src/xrepl-client.lfe` untouched.
Read `eval` directly (`src/xrepl-client.lfe:125-140`): the case arms are
exactly `#"done"` / `#"error"`. The closing-report rationale is present and
sound — in particular the correct observation that a client `ping` arm would
*mask* the desync (the eval reply would be read one `recv` late), not fix
it; `xrepl-client:ping/1` is a normal request/response op, unrelated.

## F-5 — doc-truth: **confirmed**

```
$ grep -in "doc-truth" docs/design/0.1.0/arc5-critical-correctness/slice1/closing-report.md
122:## F-5: Doc-truth          exit=0
```

I read `README.md:240-314` (Phase 3 / Server Modes / Network Features) and
the full `bin/xrepl` usage text directly, not via CC's summary. The
claim-by-claim table in the closing report holds: no keepalive language
exists in README or `bin/xrepl` to retract; the network-mode claims
(transports, multi-client, token/file-permission auth, client `(ping)`
command, `--server`/`--connect`/`--hybrid` descriptions) are consistent with
post-fix behaviour. The README:258 "Crash Recovery" verdict concerns a
subsystem outside this slice — accepted as *unaffected*, not as verified.

---

## Cross-check: arc-plan ledger-seed F-1…F-4 vs the closed ledger

From `../arc-plan.md` §slice1 ledger-seed:

| Seed | Ledger row | Disposition |
|------|-----------|-------------|
| F-1 `after 30000` gone (grep) | F-1 | present; **strengthened** (adds the no-other-`after`-timer check) |
| F-2 `send-keepalive` removed or unreferenced | F-2 | present; **strengthened** (repo-wide grep on retention path) |
| F-3 idle-then-eval test that fails if ping injected | F-3 | present; **strengthened** (explicit red-on-baseline evidence requirement) |
| F-4 client still has no `ping` clause, documented | F-4 | present; same + closing-report rationale requirement |

**No silent drops.** The ledger added F-5 (doc-truth) beyond the seed, with
declared origin (program plan §4 #5) — an addition, not a drop, and within
the slice scope statement.

## Iteration-3 verification (F-6, F-7) — added 2026-06-11

CC closed iteration 3 at ledger commit `5a46cc5` (test `f1e3555` → fix
`c828d11`), adding rows F-6 (CDC-7 funcall bug) and F-7 (CDC-1 parens) as
disclosed scope additions. CDC checks at those SHAs:

- **Row count:** 7 opening (5 + 2 disclosed additions), 7 dispositions. No
  silent drops.
- **F-6 static: confirmed.** `git show c828d11:src/xrepl-tcp-handler.lfe |
  grep -n "funcall"` → exit 1; the converted site brings `call transport`
  occurrences to 6. Diff scope at `c828d11` is the one-token fix plus the
  paren fold; the test landed separately at `f1e3555`
  (`test/xrepl-decode-error-tests.lfe`, 106 lines).
- **F-6 test quality: confirmed not vacuous.** Read in full at `c828d11`:
  asserts the decode-error reply (`#"error"` status) AND a same-connection
  `#"done"` eval reply afterward — exactly the criterion; raw `gen_tcp` +
  `xrepl-protocol-msgpack` (correctly bypassing `xrepl-client`'s
  always-valid encoding); 10 s timeout; `try`/`after` cleanup; same harness
  pattern as the keepalive test.
- **CDC-3 honored: red is now a plain checkout.** The test commit
  (`f1e3555`) precedes the fix (`c828d11`) — red-on-baseline for F-6 is
  reproducible from topology alone, unlike F-3's. CC's red evidence
  (`{badfun,ranch_tcp}`, `{error,closed}` on the eval recv) matches the
  statically predicted failure mode exactly.
- **F-7 static: confirmed.** `grep -n "^[[:space:]]*)"` at `c828d11` → exit
  1. CC's closing note honestly records a first paren-fold attempt that
  failed compile (3 parens, missing the `defun` close) and was corrected —
  the crash-report culture working as intended.
- **Dynamic reproduction: confirmed (operator-executed, 2026-06-11,
  `cdc-iter3-red-green.sh`).**
  - **RED** at the `f1e3555` worktree (guards clean): decode-error test
    failed in 18 ms with `#(expected eval-ok) #(value #(error closed))`,
    and the log carries the predicted crash itself —
    `{{badfun,ranch_tcp}, [{'xrepl-tcp-handler','handle-data',2,…{line,80}}]}`
    plus the Ranch listener exit report. The statically derived failure
    mode, observed verbatim. Suite: 40/41 (keepalive test passes there, as
    expected — L-01's fix predates `f1e3555`).
  - **GREEN** at branch HEAD `5a46cc5`: 41/41, decode-error test `[ok]`
    (28 ms), keepalive `[ok]` (31,515 ms). This run is also F-7's compile
    evidence.
  - *Harness erratum:* the script printed "GREEN NOT CONFIRMED" — a verdict
    -logic bug (ltest's ANSI-colored summary defeats a plain
    `grep 'Passed: 41'`), the fourth harness defect of this slice's
    verification tooling. CDC closes on direct inspection of the captured
    logs, not the script's verdict; the script is retired at its own
    iteration cap rather than fixed. The `not_purged` load reports in the
    red run are benign (stale seeded beams reloaded over a running app).

## Findings

Carried forward from the prior CDC pass (status re-checked at `98f986c`;
updated again after iteration 3 at `5a46cc5`):

| ID | Severity | Finding | Status at this verification |
|----|----------|---------|------|
| CDC-1 | polish | Orphaned `)))` on its own line where the `after` clause was (`src/xrepl-tcp-handler.lfe:79`) — violates the LFE closing-paren style rule. | **Resolved** at `c828d11` (iteration 3, ledger row F-7). |
| CDC-2 | polish | Closure line should cite both fix SHA and ledger SHA. | **Resolved** in the working-tree ledger (cites `2ccceed` + `98f986c`). |
| CDC-3 | process | Test + fix in one commit → red not reproducible from topology alone. | Standing rule for future slices; compensated for F-3 by the operator-run harness (red reproduced 2026-06-11). **Honored in iteration 3** (`f1e3555` test precedes `c828d11` fix). Carry into slice2's cc-prompt. |
| CDC-4 | process | Release-sequential branch numbering retired in favour of arc-relative numbering. | Rename executed — **but see CDC-6**: the executed name differs from the documented convention. |
| CDC-5 | process | No git write operations from the sandbox (stranded lock files). | Standing rule; observed in this pass (all git usage read-only). |

New this pass:

| ID | Severity | Finding | Recommended disposition |
|----|----------|---------|------------------------|
| CDC-7 | correctness | *(added in follow-up review, same day)* `src/xrepl-tcp-handler.lfe:111` (decode-error path in `handle-data`) uses `(funcall transport 'setopts …)` where every sibling site uses `(call transport …)`. `transport` is a module atom, so `funcall` compiles to `Transport(…)` → `badfun` crash after the decode-error reply is sent; the `(message-loop state)` that follows is unreachable. Every malformed frame kills the connection the code intends to keep. | **Fixed** at `c828d11` (iteration 3, ledger row F-6, red-first test at `f1e3555`) — see the iteration-3 section. Related-but-deferred: the same path's `#m(id (binary "unknown"))` literal makes the request id the *list* `(binary "unknown")`, moot only because `send-response`'s atom/binary key mismatch defaults to `#"unknown"` anyway — same defect family as the keepalive id; disclosed-deferred to Arc 06 (protocol/boundary work). |
| CDC-6 | process / doc-truth | The actual branch is **`arc5/slice1-keepalive-desync`** (sibling: `arc4/slice1-stabilize`), but the working-tree `ledger.md` header, `cc-prompt.md`, and `../arc-plan.md` all record the rename target as **`slice/05.01-keepalive`** under a `slice/<arc>.<slice>-<slug>` convention. The convention documented in the uncommitted docs and the convention actually executed (`arc<N>/slice<M>-<slug>`) disagree. Doc-truth defect in the very documents being committed. | **Resolved 2026-06-11 (option 1):** `ledger.md` header, `cc-prompt.md`, and `../arc-plan.md` now record `arc<N>/slice<M>-<slug>` as the convention and `arc5/slice1-keepalive-desync` as this slice's branch; the dotted `slice/05.01` interim style is documented as retired alongside the release-sequential style. Rationale recorded in the arc-plan: each scale self-labeled and grouped, no two scales in one dotted token; mirrors the docs layout `arc<N>-<arc-slug>/slice<M>/`. |

## Caveats

- **Toolchain absence is load-bearing for F-3 only.** All grep-based rows
  were reproduced both in the working tree and (spot-checked via `git show`)
  at the closing SHAs. Sandbox limits verified, not assumed: no `erl`, no
  root, OTP-24-only distro candidate, `binaries2.erlang.org`
  allowlist-blocked (github.com reachable, but no usable prebuilt OTP for
  this platform within the session's constraints).
- **Which ledger was verified:** both. The committed ledger at `98f986c` and
  the working-tree ledger differ only in header (branch rename note), one
  CDC-attributed What-Worked bullet, and the Closure line; the five rows —
  criteria, Verify commands, evidence — are byte-identical between the two.
- **Uncommitted repo state at verification:** modified `arc-plan.md`,
  `slice1/cc-prompt.md`, `slice1/ledger.md`; staged-new
  `slice1/cdc-verification.md` (the prior report this one replaces). The
  working-tree ledger's Closure line cites this file's 4/5 outcome; that
  citation remains accurate after this re-verification.
- **Self-reference:** the ledger's Closure line was written citing the prior
  CDC report's outcome before this re-run. Since this pass reaches the same
  outcome (4 confirmed, F-3 proposed-done), no ledger amendment is required;
  had the outcomes differed, the Closure line would have been a finding.
- All git usage in this pass was read-only (`log`, `show`, `diff`, `branch
  --list`, `status`), per the sandbox git-write hazard (CDC-5).

## Overall disposition

**Original five rows (L-01): fully verified, 5/5.** F-1, F-2, F-4, F-5
confirmed by exact re-run of the Verify commands plus direct
source/document reads; F-3 confirmed by operator-executed host
reproduction (guarded harness, red and green both observed — see the F-3
host reproduction record).

**Iteration-3 rows (F-6, F-7): fully verified.** Red-first topology
honored; test quality read and confirmed non-vacuous; all greps reproduce;
dynamic red/green reproduced by operator on 2026-06-11 (red: the predicted
`{badfun,ranch_tcp}` observed verbatim with `#(error closed)`; green:
41/41 at `5a46cc5`, doubling as F-7's compile evidence).

**Findings register:** CDC-1 resolved (F-7). CDC-2 resolved. CDC-3 honored
in iteration 3; standing rule for slices 2-5. CDC-4 resolved (convention
`arc<N>/slice<M>-<slug>` everywhere). CDC-5 standing (no sandbox git
writes). CDC-6 resolved (docs reconciled). CDC-7 fixed (F-6).

**Merge recommendation:** `arc5/slice1-keepalive-desync` is **merge-ready
to `release/0.1.x`** — all 7 rows independently verified, no open gates.
Iteration count: 3 of 5 used. The `cdc-f3-red.sh` /
`cdc-iter3-red-green.sh` harness scripts and their RUNME are reproduction
artifacts; keep or delete at the operator's discretion (this report stands
without them).
