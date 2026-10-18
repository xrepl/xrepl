# CC implementation assignment — import the native agent into xrepl

## Assignment and authority

Project10 / arc01-integrated-native-agent / slice01-import-agent-application;
initial prepared prompt, no predecessor. Prepared, **not dispatched** in this
planning turn. When the Operator starts this implementation pass, execute the
complete first-slice open set and return a code candidate to the assigned real
reviewer. Do not ask for another routine approval inside that agreed scope.

Source target: /Users/oubiwann/lab/lfe/xrepl/xrepl, release/0.2.x at 571def5 plus
its already authorized uncommitted app version 0.2.0. Preserve docs/design.
Pinned import: /Users/oubiwann/lab/lfe/cayrn-lfe at 1b04c15. Integration tests:
/Users/oubiwann/lab/oxur/cayrn main 04b4913. Recheck exact hashes/dirty state before
copying or executing. No implementation of the later LFE port or hardening.

## Required reading and execution preflight

All project-relative paths below are relative to project10-shared-repl-architecture.
Skill root on this host is
/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills.
Locate equivalent installed skills on another host; don't silently substitute
missing required guidance. Requirements below do not waive repository AGENTS.

| Order | Exact path / source state | Scope | Purpose / before which step |
| --- | --- | --- | --- |
| 1 | Destination root/planning/project AGENTS.md; predecessor AGENTS.md | Required-full current files | Authority, preserved local work and native boundary before edits |
| 2 | This prompt, sibling slice-plan.md, sibling ledger.md | Required-full prepared open set | Every obligation and exact recipe |
| 3 | ../../project-plan.md: Useful result and boundaries; Baseline and provenance; Workflow and authority; Cross-repository dependencies and finding ownership | Required-section | Migration scope and owners |
| 3a | ../arc-plan.md; ../ledger.md | Required-full current arc | Composition/dependencies and no silent scope drops |
| 4 | ../../design.md: Architecture and authority; First slice: import layout and usable entrypoints; Provenance and change separation | Required-section, full tables | Component/source/startup contract |
| 5 | ../../artifacts/07-refocus-baseline.json | Required-data: native repositories.native_agent selected_files complete population; dirty_xrepl_input and branch/head/status; compare exact native git ls-files at pin | Pinned import and authorized version before copying |
| 6 | erlang-guidelines/SKILL.md and guides/12-project-structure.md PS-01, PS-02, PS-07; guides/08-supervision-and-applications.md SUP-11, SUP-12, SUP-13 | Required-full entrypoint; Required-section patterns and definitions | Independent application/dependency/startup boundary |
| 7 | testing/guides/01-testing-discipline.md; work-verification/guides/01-ledger-discipline.md | Required-full | Real seam proof and honest ledger return |
| 8 | Pinned native src/*, test/*, bin/cayrn-lfe, Makefile, rebar.config, rebar.lock, .gitignore, LICENSE, README.md; destination Makefile, mk/lfe.mk, rebar.config, src/xrepl.app.src | Required-full named files, baseline revisions plus declared version seed | Verify imports and actual build/start paths |
| 9 | /Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md | Conditional: required-full if any .lfe code changes beyond byte-identical import are necessary | Repository-selected LFE guidance; no translation is otherwise in scope |

Before dependent edits, recover every truncated required read and record exact
loaded extents/revisions and structured query commands/coverage/results in
artifacts/execution.md. Then write a source-cited contract readback: reusable OTP
app, independent startup, file/mode provenance, unchanged semantics, actual new
agent path in tests, version/legacy preservation and forbidden opportunistic
fixes. Resolve missing/conflicting inputs before affected work; after coherent
preflight continue under this assignment. Reading receipts are not acceptance.

## Implementation spine and binding decisions

Follow the numbered slice-plan recipe. Import tracked files excluding predecessor
AGENTS.md into apps/cayrn_lfe, using git-show bytes or a verified clean source at
the pin. No nested Git/build cache/state. Keep implementation/test bytes and the
executable launcher unchanged. Write a current component AGENTS and adapt README
home/path text with explicit provenance. Keep the standalone checkout intact.

Keep app identity cayrn_lfe, its dependency list kernel/stdlib/lfe, version 0.1.0,
callback/supervision/context semantics and current limits. Preserve root xrepl
0.2.0. Root application startup must not newly require/start cayrn_lfe; independent
agent startup must not start xrepl/Ranch/old protocol/term apps. This is a topology
import, not translation, resource-fix or general legacy repair.

Use component-local rebar/Make build/check as before; add root build-agent and
check-agent delegates and a cwd-independent argv-preserving exec wrapper at
bin/cayrn-lfe. Root build must build a usable agent; root compile must keep the
existing xrepl app. Rebar's default apps/* and . discovery is verified; don't
move root src just to impose a different layout. See design.md's Rebar source.

Apply OTP PS-01/PS-02 SHOULD by retaining the app resource and standard src/test
layout. Apply SUP-11..13 SHOULD by preserving the native app's own supervisor and
dependency-controlled ensure_all_started boot. PS-07 is CONSIDER, not a command
to reorganize all of xrepl. Private Make helper names are local discretion;
component identity, minimal startup and exact provenance are binding.

## Test oracle and integration

From xrepl run make compile-lfe, make build-agent check-agent, make build-rust
lint-rust test-rust, and the existing legacy unit/CT baseline comparison described
in the slice plan. An independently started node must report cayrn_lfe and lfe
running, while xrepl, ranch, xrepl_protocol and xrepl_term are absent. Exercise the
root wrapper from another cwd with a socket path containing spaces. Never use a
live user node or kill by process name.

From Cayrn run make check, make lint-integration, and the existing optional Rust
targets with these exact selected component/consumer paths:

```bash
CAYRN_LFE_DIR=/Users/oubiwann/lab/lfe/xrepl/xrepl/apps/cayrn_lfe \
XREPL_BIN=/Users/oubiwann/lab/lfe/xrepl/xrepl/target/debug/xrepl \
  cargo test -p cayrn-cli --features xrepl-integration \
  --test native_agent --test xrepl --locked -- --test-threads=1
```

Expected baseline population is 6 native EUnit plus 11 real native and 3 real
consumer/PTY tests. Actual counts/results govern. A green run against the old
standalone path does not prove integration. Keep failed attempts, missing inputs,
ignored/filtered/unrun denominators and unresolved legacy findings visible.
No broad gate is waived by this prepared prompt; do not hide existing failures
or enlarge this slice to repair the entire legacy application without discussion.

## Return, scope and stop conditions

Only the slice plan's source allowlist is authorized. No Cayrn source mutations,
term/protocol sibling edits, predecessor deletion, publication, LFE translation or
resource-cap/preview fix. Preserve the version seed and docs/design. Unexpected
root lock changes, incompatible build semantics or startup coupling require
reconciliation before affected acceptance, not an improvised architecture.

Artifacts/execution.md holds intake/readback and command results. Produce
artifacts/import-map.json with original revision, every source/destination path,
digests/modes and reasons for deliberate document/new-wrapper changes. Return
closing-report.md with XS01-01..08 row dispositions, exact source revision/diff,
checks/exits, residual native limits and arc bubble-up. A real independent
reviewer later writes cdc-verification.md; self-checks remain attested. Five
refinement iterations maximum before re-scope. No commits are requested now;
if later authorized use explicit reviewed paths, separate planning/source commits
and both Codex/Billo AI co-author trailers. No push/publication.


## Activation — 2026-10-18

The Operator has now authorized the planning commits and first-slice execution
under the one-collaborator selection recorded in the project plan. Sofie executes
this contract and conducts a separate self-review pass; no separate CC/reviewer
identity is claimed. Earlier prepared/not-dispatched descriptions above are the
preparation history, superseded by this activation. Existing independent gates
remain pending. No source push/publication or later slice is included.
