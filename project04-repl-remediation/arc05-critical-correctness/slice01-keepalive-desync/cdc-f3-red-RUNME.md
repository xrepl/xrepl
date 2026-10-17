# Run this for me: F-3 red-on-baseline (the last CDC gap)

You already ran the **green** half (`rebar3 as test lfe ltest` on the slice
branch — the 31 s "hang" was the test's intentional idle window; all passed).

The **red** half proves the same test *fails* on the pre-fix code — the
evidence that the test actually detects the bug. CC couldn't leave this in
history because test and fix landed in one commit, so it's reconstructed in a
throwaway worktree under `/tmp`. Your checkout is not touched.

## The one command

From anywhere inside the repo:

```sh
chmod +x docs/design/0.1.0/arc5-critical-correctness/slice1/cdc-f3-red.sh
docs/design/0.1.0/arc5-critical-correctness/slice1/cdc-f3-red.sh
```

Takes ~1–2 min (recompile of the baseline + the test's intentional 31 s
idle).

*(v2: the first version hit a clean-worktree build-ordering wart —
`rebar3_lfe` compiled the LFE test files before the `ltest` dep was built,
so the include failed with `{app_not_found,"ltest"}`. v2 seeds the worktree
with a copy of your `_build`, so deps are prebuilt; your repo's `_build` is
only read, never written.)*

## What you should see

A `VERDICT` block ending in **`RED CONFIRMED`**, and in the test output a
failure like:

```
#(assertEqual ... #(expected #(error timeout))
              #(value #(ok #M(#"id" #"unknown" #"status" #"ping"))))
```

That `status ping` map IS the bug being caught in the act.

## Then

Paste Claude the verdict block plus that failure line (full log is at
`/tmp/cdc-f3-red.log` if anything looks off). F-3 then converts to **done**
and the CDC report's outcome goes to full reproduction. These two files
(`cdc-f3-red.sh`, this RUNME) can be deleted afterwards — or kept as the
slice's reproduction artifact, your call.
