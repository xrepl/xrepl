#!/bin/sh
# CDC F-3 red-on-baseline reproduction (Arc 05 slice 1, L-01) — v3.
#
# History of this script's own fix loop (iteration 3 of its budget):
#   v1: clean worktree → rebar3_lfe compiled LFE tests before the ltest dep
#       existed → include failure {app_not_found,"ltest"}.
#   v2: seeded the worktree with a copy of the repo's _build → CONTAMINATION:
#       the copy carries the POST-FIX xrepl beams (and rebar3's lib/xrepl can
#       contain symlinks back to the live source tree), so the suite ran the
#       FIX and passed. Green-on-baseline was my harness bug, not a vacuous
#       test.
#   v3: copy _build for the prebuilt deps, then EVICT the xrepl app from the
#       copy so it must rebuild from the baseline checkout. Add two guards:
#       (a) pre-check the worktree source really contains the bug;
#       (b) post-check the handler beam actually differs from the repo's.
#
# Run time: ~1-2 min. Your repo and _build are read, never written.

REPO="$(git rev-parse --show-toplevel)" || exit 1
WT=/tmp/cdc-f3-red
LOG=/tmp/cdc-f3-red.log
BEAM=_build/test/lib/xrepl/ebin/xrepl-tcp-handler.beam

cleanup() {
    cd "$REPO" && git worktree remove --force "$WT" 2>/dev/null
}
trap cleanup EXIT

cd "$REPO" || exit 1
git worktree remove --force "$WT" 2>/dev/null

echo ">>> creating baseline worktree at 6609a12 ..."
git worktree add "$WT" 6609a12 || exit 1

echo ">>> guard (a): baseline source must contain the bug ..."
if grep -q "after 30000" "$WT/src/xrepl-tcp-handler.lfe"; then
    echo "    ok: 'after 30000' present in worktree source (pre-fix code)."
else
    echo "    ABORT: worktree source has no 'after 30000' - not the baseline?"
    exit 1
fi

echo ">>> seeding deps from _build copy, then evicting the xrepl app ..."
if [ -d "$REPO/_build" ]; then
    cp -R "$REPO/_build" "$WT/_build" || exit 1
    rm -rf "$WT"/_build/*/lib/xrepl
else
    echo "    (no _build found - deps will be fetched; v1 ordering bug may recur)"
fi

echo ">>> injecting regression test from 2ccceed ..."
git show 2ccceed:test/xrepl-keepalive-tests.lfe \
    > "$WT/test/xrepl-keepalive-tests.lfe" || exit 1

echo ">>> running suite against pre-fix code (expect ONE failure, ~90 s) ..."
( cd "$WT" && rebar3 as test lfe ltest ) 2>&1 | tee "$LOG"

echo ""
echo ">>> guard (b): worktree handler beam must differ from the repo's ..."
CONTAMINATED=no
if [ -f "$WT/$BEAM" ] && [ -f "$REPO/$BEAM" ]; then
    if cmp -s "$WT/$BEAM" "$REPO/$BEAM"; then
        CONTAMINATED=yes
        echo "    CONTAMINATED: worktree ran the repo's (post-fix) beam."
    else
        echo "    ok: worktree compiled its own (pre-fix) handler beam."
    fi
else
    echo "    note: beam comparison skipped (missing file)."
fi

echo ""
echo "===================== VERDICT ====================="
if [ "$CONTAMINATED" = yes ]; then
    echo "INVALID RUN: post-fix beam contamination - harness bug, not a"
    echo "test verdict. Send Claude the log."
elif grep -qF '#"ping"' "$LOG"; then
    echo "RED CONFIRMED: the keepalive test fails on baseline by receiving"
    echo "the injected ping frame. F-3 red half: reproduced."
elif grep -qE 'Failed: 0([^0-9]|$)' "$LOG"; then
    echo "PROBLEM: suite genuinely passed on pre-fix code (guards say the"
    echo "right beam ran). The test may really be vacuous - this would be a"
    echo "ledger finding. Send Claude the log."
elif grep -q 'lfe_macro_include\|app_not_found' "$LOG"; then
    echo "BUILD PROBLEM: ltest include ordering bug recurred. Send the log."
else
    echo "UNCLEAR: no ping-frame failure and no clean pass detected."
    echo "Send Claude the log."
fi
echo "Full log saved to: $LOG"
echo "Paste back: this verdict block + the assertEqual failure line"
echo "(the one containing: #\"status\" #\"ping\")."
echo "===================================================="
