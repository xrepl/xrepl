# Arc 05 — 0.1.0 critical correctness (the limited cut)

**Release:** 0.1.0 · **Branch:** `release/0.1.x` · **Project plan:**
`../../../../workbench/2026.06.10-remediation-program-plan.md` · **Framework:**
ledger discipline per slice (CC implements / CDC verifies; grep-verifiable rows;
five-iteration cap). Origin tags (`L-NN`) trace to
`2026.06.10-audit-results-lfe.md`.

**Arc goal.** The deliberately small set of fixes that make 0.1.0 *useful and
correct* in normal use. Each slice is one finding, one mergeable diff, one ledger
— small enough to ship or revert independently. After the last slice closes,
Duncan re-tags 0.1.0.

> **Why these four (+1 swing) and not more.** The default 0.1.0 experience is the
> local stdio REPL (`network_enabled=false`). L-04 and L-05 corrupt/leak state in
> *local* multi-session use; L-09 is a *local* foot-gun; L-01 breaks the network
> mode the README/launcher advertise. Those four make the shipped thing wrong.
> Everything else is structural (needs the Arc 06 refactors) or doesn't affect
> normal use — disclosed-deferred per the program plan §7. L-02 is the swing
> (program plan §5).

## Slices

Each slice gets its own `sliceN/` directory with the canonical file set
(`slice-doc.md`, `ledger.md`, `cc-prompt.md`, `closing-report.md`,
`cdc-verification.md`) **when it is picked up**, not before. The plans-of-record
are below; they become each slice's `slice-doc.md` and seed its `ledger.md`.

| Slice | Finding | One-line | Status |
|-------|---------|----------|--------|
| `slice1` | L-01 | kill the idle-keepalive desync | not started |
| `slice2` | L-04 | route session expiry through the lifecycle | not started |
| `slice3` | L-05 | per-session history + `terminate/2` save | not started |
| `slice4` | L-09 | identify ids by shape, not hex-parseability | not started |
| `slice5` | L-02 | bound intake (swing — see program plan §5) | not started; include pending Duncan's call |

### slice1 — L-01: kill the idle-keepalive desync

**Scope.** Remove the `(after 30000 …)` keepalive that injects an unsolicited
`#m(status ping)` frame into a synchronous request/response stream
(`xrepl-tcp-handler.lfe:79-82`, `send-keepalive` at `:167-171`). A REPL connection
doesn't need app-level keepalives. **Also** the doc-truth check (def-of-done #5):
confirm README/`bin/xrepl` network claims are honest once this lands. Add a
regression test: connect, idle past the old 30s window, eval, assert a correct
reply (not a `ping`/`case_clause`).

**Ledger-seed:**

- F-1 the `after 30000` clause is gone from `message-loop`; `grep -n "after 30000"
  src/xrepl-tcp-handler.lfe` returns nothing. *(serious; L-01)*
- F-2 `send-keepalive` is removed or unreferenced. *(correctness; L-01)*
- F-3 a test connects, waits past the former keepalive interval (or simulates an
  idle tick), evals, and asserts a `done`/`error` reply — **fails** if a `ping`
  frame is injected. *(serious; L-01)*
- F-4 `xrepl-client:eval` still has no `ping` clause **and no longer needs one** —
  documented in the closing report. *(correctness; L-01)*

**Files.** `src/xrepl-tcp-handler.lfe`; a new test under `test/`; possibly
`README.md`/`bin/xrepl` wording.

### slice2 — L-04: route session expiry through the lifecycle

**Scope.** `do-cleanup-expired-sessions` (`xrepl-store.lfe:443-472`) deletes the
ETS row of an expired session whose process is still alive *without stopping the
process* — orphaning the session gen_server, its evaluator, and its history ETS
table, and leaving the store/registry inconsistent. Fix: expiry must stop the
process through the lifecycle owner (`xrepl-session-manager:destroy/1`) rather
than reaching into ETS + the registry directly. (Does *not* require the L-20
dedup — that's Arc 06; this slice fixes the leak against the current code.)

**Ledger-seed:**

- F-1 after an expiry sweep, a session that was alive has **no** registered
  process: `whereis(process-name)` → `undefined`. *(serious; L-04)*
- F-2 its history ETS table is gone: `ets:info(table-name)` → `undefined`. *(serious; L-04)*
- F-3 store and registry agree post-sweep — no id for which `is-active?` is true
  but `get-session` is `not-found`. *(serious; L-04)*
- F-4 a test creates a session, forces expiry, and asserts F-1–F-3. *(serious; L-04)*
- F-5 cleanup no longer calls `ets:delete` directly on a live session's row; it
  goes through `xrepl-session-manager:destroy` (or equivalent). *(correctness; L-04)*

**Files.** `src/xrepl-store.lfe` (and/or move expiry into
`xrepl-session-manager.lfe`); a test.

### slice3 — L-05: per-session history + `terminate/2` save

**Scope.** Every session's `setup-save-on-exit` spawns an unsupervised process
that monitors the global `user` and saves *its* history to the **shared**
`~/.lfe-xrepl-history`, so concurrent sessions clobber each other (data loss) and,
in `--server` mode (no `user`), the spawned process leaks forever. Fix: (a)
persist per-session to a per-session path; (b) tie the save to the session
gen_server's `terminate/2` (it already traps exits) and delete the
`setup-save-on-exit` spawn entirely.

**Ledger-seed:**

- F-1 `setup-save-on-exit` and its `spawn` are gone. *(serious; L-05)*
- F-2 save happens in `xrepl-session:terminate/2`. *(correctness; L-05)*
- F-3 two concurrent sessions with distinct histories both persist without
  clobber — a test asserts each file has its own commands. *(serious; L-05)*
- F-4 no per-session saver process survives a `--server`-style start with no
  `user`. *(correctness; L-05)*
- F-5 history file path is per-session for writes. *(correctness; L-05)*

**Files.** `src/xrepl-history.lfe`, `src/xrepl-session.lfe`; a test.

*Note:* this changes the on-disk history layout. If 0.1.0 must read the old
single-file history, add a one-time import; otherwise document the break in the
closing report. **Flag for Duncan if back-compat matters.**

### slice4 — L-09: identify ids by shape, not hex-parseability

**Scope.** `is-session-id?` (`xrepl-session-manager.lfe:357-370`) and
`resolve-session-id` (`xrepl-commands.lfe:239-255`) decide "is this an id?" by
`list_to_integer(Str, 16)`, so any hex-ish *name* (`"face"`, `"42"`, `"cafe"`) is
misclassified as an id. Fix: an id is exactly 32 hex chars; anything else is a
name (or carry an explicit `{id,_}`/`{name,_}` tag).

**Ledger-seed:**

- F-1 a session named `"face"` resolves by name (test). *(serious; L-09)*
- F-2 a 32-hex-char string still resolves as an id. *(correctness; L-09)*
- F-3 the discriminator is shape-based, not `list_to_integer/2`. *(correctness; L-09)*
- F-4 both call sites use the same rule — no partial adoption. *(correctness; L-09)*

**Files.** `src/xrepl-session-manager.lfe`, `src/xrepl-commands.lfe`; a test.

### slice5 — L-02: bound intake (swing — see program plan §5)

**Scope.** Add `{packet_size, N}` to the socket opts in
`xrepl-tcp-handler.lfe:36-38` so a hostile 4-byte length can't make the driver
buffer gigabytes pre-auth, and pass `max_connections` into the Ranch
`transport_opts` in `xrepl-net-sup.lfe:47`. **Include only if Duncan greenlights
for 0.1.0** (default: include); otherwise this slice moves to Arc 06.

**Ledger-seed:**

- F-1 `grep -n "packet_size" src/xrepl-tcp-handler.lfe` shows a finite cap
  alongside `{packet, 4}`. *(serious; L-02)*
- F-2 an oversized length-prefixed frame is rejected without unbounded buffering
  (test). *(serious; L-02)*
- F-3 `max_connections` from app env reaches the Ranch `transport_opts`. *(correctness; L-02)*

**Files.** `src/xrepl-tcp-handler.lfe`, `src/xrepl-net-sup.lfe`; a test.

## Arc checkpoint → TAG 0.1.0

All slices closed with CDC-verified ledgers; def-of-done (program plan §4) met.
Duncan re-tags `0.1.0`. Then rebase `main` off `release/0.1.x` and cut
`release/0.2.x` from the updated `main`.

## Notes for the executor (CC) and reviewer (CDC)

- **One slice = one branch off `release/0.1.x` = one ledger.** Don't bundle.
- **Tests are the Verify column where behaviour changes.** A grep proves code
  *shape*; a test proves *behaviour*. L-01/L-04/L-05/L-09/L-02 each need a test
  that would fail if the bug were still present.
- **CDC re-runs every `done` row's Verify command.** A `done` without reproduced
  evidence is `proposed-done`.
- **The four core slices are independent** (no inter-dependencies), so they can be
  parallelised across branches — but each rebases onto a green `release/0.1.x` and
  closes its own ledger.
- **Back-compat:** `slice3` (L-05) changes the history on-disk layout — surface to
  Duncan before closing if old-history import matters.
