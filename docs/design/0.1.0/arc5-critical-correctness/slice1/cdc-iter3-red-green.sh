#!/bin/sh
# CDC iteration-3 red/green reproduction (rows F-6, F-7) — final dynamic
# check for slice arc5/slice1. Uses the guarded-harness pattern proven by
# cdc-f3-red.sh v3.
#
#   RED:   worktree at f1e3555 (decode-error test present, funcall bug
#          present). Expect the decode-error test to FAIL ({error,closed}
#          after the handler's badfun crash); keepalive test passes there.
#   GREEN: suite at your current branch HEAD (5a46cc5 or later). Expect
#          41/41 — this run is also F-7's `rebar3 compile` evidence.
#
# Run time: ~2-3 min total (each suite includes the 31 s keepalive idle).
# The worktree lives in /tmp; your repo's _build is read, never written.

REPO="$(git rev-parse --show-toplevel)" || exit 1
WT=/tmp/cdc-iter3-red
RLOG=/tmp/cdc-iter3-red.log
GLOG=/tmp/cdc-iter3-green.log
BEAM=_build/test/lib/xrepl/ebin/xrepl-tcp-handler.beam

cleanup() {
    cd "$REPO" && git worktree remove --force "$WT" 2>/dev/null
}
trap cleanup EXIT

cd "$REPO" || exit 1
git worktree remove --force "$WT" 2>/dev/null

echo ">>> [RED] creating worktree at f1e3555 (test committed, fix not) ..."
git worktree add "$WT" f1e3555 || exit 1

echo ">>> [RED] guard (a): bug must be present, test must be present ..."
if grep -q "funcall transport" "$WT/src/xrepl-tcp-handler.lfe" \
   && [ -f "$WT/test/xrepl-decode-error-tests.lfe" ]; then
    echo "    ok: funcall present in source; decode-error test present."
else
    echo "    ABORT: f1e3555 worktree isn't the expected red state."
    exit 1
fi

echo ">>> [RED] seeding deps from _build copy, evicting the xrepl app ..."
if [ -d "$REPO/_build" ]; then
    cp -R "$REPO/_build" "$WT/_build" || exit 1
    rm -rf "$WT"/_build/*/lib/xrepl
fi

echo ">>> [RED] running suite at f1e3555 (expect ONE failure, ~90 s) ..."
( cd "$WT" && rebar3 as test lfe ltest ) 2>&1 | tee "$RLOG"

echo ""
echo ">>> [RED] guard (b): worktree handler beam must differ from repo's ..."
RED_CONTAMINATED=no
if [ -f "$WT/$BEAM" ] && [ -f "$REPO/$BEAM" ] \
   && cmp -s "$WT/$BEAM" "$REPO/$BEAM"; then
    RED_CONTAMINATED=yes
    echo "    CONTAMINATED: worktree ran the repo's (post-fix) beam."
else
    echo "    ok: worktree compiled its own (pre-fix) handler beam."
fi

echo ""
echo ">>> [GREEN] running suite at your branch HEAD ($(git rev-parse --short HEAD)) ..."
( cd "$REPO" && rebar3 as test lfe ltest ) 2>&1 | tee "$GLOG"

echo ""
echo "===================== VERDICT ====================="
RED_OK=no
GREEN_OK=no
if [ "$RED_CONTAMINATED" = no ] \
   && grep -q "error closed\|{error,closed}\|#(error closed)" "$RLOG" \
   && ! grep -qE 'Failed: 0([^0-9]|$)' "$RLOG"; then
    RED_OK=yes
fi
if grep -qE 'Passed: 41' "$GLOG" && grep -qE 'Failed: 0([^0-9]|$)' "$GLOG"; then
    GREEN_OK=yes
fi

if [ "$RED_OK" = yes ] && [ "$GREEN_OK" = yes ]; then
    echo "ALL CONFIRMED:"
    echo "  RED:   decode-error test fails at f1e3555 (connection died"
    echo "         after the badfun crash) - F-6 red reproduced."
    echo "  GREEN: 41/41 at branch HEAD - F-6 green + F-7 compile evidence."
    echo "Slice arc5/slice1 is fully CDC-verified: merge-ready."
elif [ "$RED_OK" = no ]; then
    echo "RED NOT CONFIRMED - check $RLOG (contamination guard: $RED_CONTAMINATED)."
    echo "Send Claude the log."
else
    echo "GREEN NOT CONFIRMED - check $GLOG. Send Claude the log."
fi
echo "Logs: $RLOG / $GLOG"
echo "Paste back: this verdict block + the RED run's failing assertion."
echo "===================================================="
