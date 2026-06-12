# CDC Verification — Arc 05 Slice 1: L-01 keepalive desync

**Verified:** 2026-06-11 · **CDC:** Claude (Cowork session; independent of the
CC context that implemented) · **Ledger commits verified against:** fix
`2ccceed`, ledger close `98f986c`, baseline `6609a12` · **Protocol:**
`LEDGER_DISCIPLINE.md` CDC steps 1–8.

**Independence note.** This CDC context drafted the ledger and cc-prompt but
performed none of the implementation; the doer was a separate CC context. The
auditor-≠-doer requirement holds for the implementation under review.

## Row count (CDC step 1)

Opening ledger: 5 rows (F-1…F-5). Closing report: 5 dispositions. **Match — no
silent drops.**

## Per-row verification (CDC step 2)

| Row | CC claim | CDC reproduction | Verdict |
|-----|----------|------------------|---------|
| F-1 | done | `git show 2ccceed:src/xrepl-tcp-handler.lfe \| grep -n "after 30000"` → exit 1. Secondary check `grep -n "after "` → exit 1 (no replacement idle timer introduced). | **done — reproduced** |
| F-2 | done | `git show 2ccceed:src/xrepl-tcp-handler.lfe \| grep -n "send-keepalive"` → exit 1. Partial-adoption sweep (CDC step 7): `grep -rn "send-keepalive" src/ test/` at `98f986c` → exit 1, no stragglers anywhere. | **done — reproduced** |
| F-3 | done | See *F-3 analysis* below. Test source independently audited; red-output forensics pass; diff scope confirmed. Runs **not** re-executed in this environment (no BEAM toolchain in the CDC sandbox; install blocked — no root, distro OTP is 24 vs project's 28, hex builds blocked by network allowlist). | **proposed-done — pending one toolchain re-run** (script below) |
| F-4 | done | `git show 2ccceed:src/xrepl-client.lfe \| grep -n '#"ping"'` → exit 1. `git diff --stat 6609a12 2ccceed -- src/xrepl-client.lfe` → empty (file untouched). Closing-report rationale read: sound, including the correct observation that a client `ping` arm would *mask* the desync (reply read one recv late), not fix it. | **done — reproduced** |
| F-5 | done | `grep -in "doc-truth"` → section at closing-report.md:122. CDC read `README.md:249-305` and the full `bin/xrepl` usage text directly (not via CC's summary): the claim-by-claim verdict table holds; no keepalive language existed to retract. Note: the README:258 "Crash Recovery" verdict concerns a subsystem outside this slice's scope — accepted as unaffected, not as verified. | **done — reproduced** |

## F-3 analysis (the load-bearing row)

What CDC could and could not verify here, precisely:

**Verified — test is not vacuous (discipline failure mode #4).** The test
source at `2ccceed:test/xrepl-keepalive-tests.lfe` asserts (a) `recv` →
`{error, timeout}` after a 31 s idle (the arm that goes red on baseline by
receiving the ping frame) and (b) a post-idle eval returns `#(ok …)` — a
*correct reply*, not merely no-crash. No spec-softening. Cleanup is
`try`/`after`-guarded; the 60 s eunit timeout is handled via `deftestgen`.

**Verified — red output is forensically genuine.** CC's reported red value is
`#(ok #M(#"id" #"unknown" #"status" #"ping"))`. The deleted `send-keepalive`
(baseline `:167-171`) passed `(map 'id (binary "keepalive"))` to
`send-response`, whose lookup is `(maps:get (binary "id") request …)` — an
atom-key/binary-key mismatch, so the wire frame's id was **always**
`#"unknown"`, never `"keepalive"`. The red evidence reproduces this
non-obvious artifact of the deleted code path exactly; fabricated or
hallucinated output would almost certainly have shown `#"keepalive"`.

**Verified — diff scope.** `git diff --numstat 6609a12 2ccceed` → exactly
`src/xrepl-tcp-handler.lfe` (1+/11−, the two deletions) and
`test/xrepl-keepalive-tests.lfe` (86+). Nothing else changed. Green count
(40 tests) is consistent with Arc 04's closed baseline (39) plus this one.

**Not verified — the runs themselves.** The CDC sandbox cannot execute the
BEAM toolchain (documented above), and `2ccceed` contains test+fix together,
so the red state is not a plain checkout. Reproduction script for a
toolchain-bearing machine, from the repo root:

```sh
# --- F-3 red/green reproduction (run from repo root) ---
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

When this script's two EXPECT lines hold, F-3 converts from proposed-done to
done and this report's Outcome line should be updated to 5/5.

## Findings

| ID | Severity | Finding | Recommended disposition |
|----|----------|---------|------------------------|
| CDC-1 | polish | The deletion left orphaned closing parens on their own line (`)))` where the `after` clause was) — violates the LFE style rule "all closing parens on the same line". | Fold onto the preceding line in a follow-up commit on the slice branch before merge; cosmetic, compile-only re-check. |
| CDC-2 | polish | Ledger Closure line cites only `2ccceed`; the ledger itself closed at `98f986c`. | Cite both (fix SHA + ledger SHA) — done in the ledger update accompanying this report. |
| CDC-3 | process | Test and fix landed in a single commit, so red-on-baseline is not reproducible from commit topology alone. | For the remaining Arc 05 slices: commit the red test first (or attach the red run's full output to the closing report). Carried into slice2's cc-prompt. |
| CDC-4 | process | Branch/commit numbering `01.02` (release-sequential) collides with the arc/slice structure and misleads on sight. | Convention changed to `slice/<arc>.<slice>-<slug>` (recorded in `../arc-plan.md`). Rename to `slice/05.01-keepalive` executed by Duncan on his machine — the CDC sandbox cannot mutate `.git` (its rename attempt stranded four lock files, removed by Duncan; see CDC-5). Commit messages left as-is: history is immutable and the ledger's evidence SHAs must stay valid. |
| CDC-5 | process (CDC self-report) | CDC's in-sandbox `git branch -m` half-failed against the mount's no-unlink permission, stranding `HEAD.lock`, `packed-refs.lock`, `index.lock`, and a branch-ref lock in the working repo — a worse state than not attempting it. | Locks removed by Duncan. Standing rule for sandboxed sessions against this repo: **no git write operations from the sandbox** (even `git status` strands `index.lock`); reads via `git log`/`git show`/`git branch --list` only; all mutations happen on the host. |

## Outcome

Rows: 5. Independently reproduced: 4 (F-1, F-2, F-4, F-5). Proposed-done
pending one toolchain re-run: 1 (F-3, with strong static + forensic
corroboration). No silent drops, no spec-softening, no partial adoption
detected. **Recommendation: merge-ready once the F-3 script's two EXPECT
lines are confirmed on a toolchain machine; CDC-1 paren fix folds in before
merge.**
