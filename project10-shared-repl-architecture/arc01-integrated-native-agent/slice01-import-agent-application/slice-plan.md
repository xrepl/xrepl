# Slice01 — import the native agent as an xrepl OTP application

2026-10-18. Implementation-ready plan; **not started**. The useful result is the
same real native agent running from the xrepl repository, independently of the
legacy app, with existing Cayrn/xrepl contract tests proving that exact new path.

## Baselines and integration home

Destination /Users/oubiwann/lab/lfe/xrepl/xrepl, release/0.2.x at 571def5 plus the
Operator-authorized uncommitted src/xrepl.app.src version 0.2.0. Preserve that
change and pre-existing docs/design. Source predecessor is
/Users/oubiwann/lab/lfe/cayrn-lfe at 1b04c15ac325731aab68a7491d23e4a9fecaa47a.
Cayrn tests are at /Users/oubiwann/lab/oxur/cayrn main 04b4913.
[Baseline](../../artifacts/07-refocus-baseline.json) identifies all tracked native
files/digests and the actual dirty destination input.

## Source-grounded design and recipe

1. Derive the import population from git ls-files at the pinned native revision.
   Copy every tracked file except AGENTS.md into apps/cayrn_lfe. Do not copy .git,
   _build, caches, private histories or untracked files. Native source/test files,
   .app.src, lock/config, LICENSE and launcher bytes are preserved; retain the
   launcher's executable bit. README and local instructions may deliberately
   adapt paths/home, with the map recording each change. The existing .gitignore
   protects component-local build output.
2. Keep app name cayrn_lfe, version 0.1.0, existing underscore OTP registration
   names and its kernel/stdlib/lfe dependency list. This component's version is
   independent of xrepl's 0.2.0. Keep the root xrepl src/ app and 0.2.0 seed intact.
   Do not add cayrn_lfe to root xrepl.app.src startup dependencies: no socket is
   configured by legacy startup, and independent agent boot must not start xrepl.
3. Retain the native app's own rebar.config/lock and Makefile for independent
   make -C apps/cayrn_lfe build/check. Root Rebar discovery supports both . and
   apps/* by default. If explicit project_app_dirs is added, keep both entries.
   Root make compile-lfe must still compile the old app. Avoid moving legacy
   src/ into an umbrella as collateral work. No root dependency upgrade is needed.
4. In mk/lfe.mk/root Make help add build-agent and check-agent delegating into
   apps/cayrn_lfe. Add root bin/cayrn-lfe as an exec-only wrapper resolving its
   own root and forwarding the sole socket argument to the component launcher.
   The component launcher retains its own root/_build/default/lib/*/ebin lookup.
   It starts only cayrn_lfe via application:ensure_all_started. Root make build
   should include build-agent so a built root launcher is usable. Nested and
   root Rebar build caches are distinct during this first import; no path trick
   may accidentally launch the predecessor checkout.
5. Add apps/cayrn_lfe/AGENTS.md pointing to current Project10 authority and keep
   reusable agent instructions separate from app services. Adapt component/root
   README startup/build examples for the new path and explicit independent boot.
   Preserve the prototype's real limits/capabilities (including 256/8KiB), no
   sandbox/heap restore/input claims and no publication claim. Record source
   commit, license and full source/destination digest/mode map in
   artifacts/import-map.json as execution evidence. Historical commit import or
   predecessor retirement is outside this slice.
6. Run native tests from the component home and the actual Cayrn Rust integration
   tests with CAYRN_LFE_DIR explicitly set to the new component. XREPL_BIN points
   to this checkout's built target/debug/xrepl. A green predecessor run does not
   count. Inspect application:which_applications in a dedicated agent-only test
   node: cayrn_lfe and lfe are started; xrepl, ranch, xrepl_protocol and xrepl_term
   are not. Use the existing native tests or a small component-local startup
   regression test; no new generic verification program is needed.
7. Re-run retained Rust modes and root native compile. Record baseline legacy
   test/xref failures before attributing changes. No new regression can be
   excused as old without evidence. Import does not repair known Project09
   findings, the operation cap or large-result assertion; list their next owner.

## Required checks and exact observations

From xrepl: make compile-lfe; make build-agent check-agent; make build-rust
lint-rust test-rust. Run make test-unit-lfe and make test-ct-lfe before/after to
identify legacy behavior changes; capture real failures/missing fixtures rather
than making the new slice own every historical fix. Existing failures remain
owned by the Project10 migration map/Project09, not silently marked accepted.

From Cayrn: make check; make lint-integration, then run the existing optional
Rust targets against the component (build the source projects first):

```bash
CAYRN_LFE_DIR=/Users/oubiwann/lab/lfe/xrepl/xrepl/apps/cayrn_lfe \
XREPL_BIN=/Users/oubiwann/lab/lfe/xrepl/xrepl/target/debug/xrepl \
  cargo test -p cayrn-cli --features xrepl-integration \
  --test native_agent --test xrepl --locked -- --test-threads=1
```

At the inspected baseline this is 6 native EUnit checks plus 11 real native and
3 actual consumer/PTY tests. Derive actual counts from execution. Preserve all
failure and ignored/unrun denominators; no weakened or ignored tests. Existing
local gate counts are prior attestation, not this slice's future result.

The native-only app-start check must prove the boundary, not just read .app.src.
Root launcher must work from a different working directory and preserve a socket
path containing spaces; give argv as an argument, never shell interpolation.
Do not use the user's manual REPL or kill unrelated BEAM processes.

## Scope, allowlist and artifacts

Allowed source destinations: apps/cayrn_lfe/** from the pinned import plus local
AGENTS/README and any focused boundary test; bin/cayrn-lfe; mk/lfe.mk; Makefile;
README.md; AGENTS.md; rebar.config only for explicit equivalent app discovery;
src/xrepl.app.src only to preserve/include the already authorized version seed.
Do not edit legacy evaluator/session/transport code or Rust evaluation behavior.
Root rebar.lock/Cargo.lock changes are not expected; disclose and reconcile any
unavoidable resolution change before accepting it. No term/protocol sibling or
standalone predecessor source writes. No Cayrn source mutations in this slice.

Execution evidence belongs in this slice's artifacts/: execution.md for intake,
contract readback, commands/exits and baseline comparisons; import-map.json for
provenance; supporting logs as needed. Return closing-report.md with all XS01
rows, source/plan revisions, file allowlist and residual ownership. No close or
verification file is pre-created. Up to five refinement iterations, then re-scope.
No automatic commit/push/publication. When commits are later requested, include
the explicit reviewed source allowlist (including the authorized version seed if
still pending), separate source/planning commits and both co-author trailers.

## Author readiness and assignment history

The native source, its five Erlang modules/one LFE evaluator, two test modules,
launcher, app resource, build/config/dependencies and xrepl discovery/build paths
were inspected. Relevant Rebar config semantics were checked against official
documentation. Design resolves component home, independent startup, old-app
preservation, exact import population and real test path. OTP PS-01/PS-02 and
SUP-11..13 justify retaining application/dependency/startup boundaries; PS-07 is
CONSIDER, used only for adding one app without relocating the root app.

The old code can pass only if genuinely imported and launched from the new path;
a wrapper still calling the predecessor fails provenance/path/startup checks.
Accidentally starting legacy xrepl fails the running-app negative controls.
Wrong launcher cwd/quoting fails the path-with-spaces case. The read packet and
code size leave implementation/review headroom; no translation is bundled here.
This is source-grounded author readiness, not a compiled integration claim.

| Assignment | Date | Predecessor | Disposition |
| --- | --- | --- | --- |
| cc-prompt.md | 2026-10-18 | none | Prepared; not dispatched/executed in this turn |

Current assignment: prepared cc-prompt.md for the next explicitly started CC
implementation pass. No CC/delegation or independent review is inferred.


## Activation and workflow transition — 2026-10-18

The Operator selected one collaborator, authorized planning commits, then
execution of this first slice. Current assignment: cc-prompt.md activated for
Sofie; its design/implementation/review are separate functional passes by the same
contributor. Earlier prepared/not-started entries remain historical. No other
reviewer or CC is dispatched. Self-checks remain attested and existing independent
acceptance gates remain pending. Source pins/open rows are unchanged; next action
owner is Sofie after the planning commit. Scope is this first slice only.
