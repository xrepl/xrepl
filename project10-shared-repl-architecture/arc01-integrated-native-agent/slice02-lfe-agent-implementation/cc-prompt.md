# Slice02 assignment — convert the native OTP agent to LFE

Project10 / arc01-integrated-native-agent / slice02-lfe-agent-implementation.
Initial prepared assignment, predecessor none. Not started. Implement the whole
XS02-01..08 ledger after activation; current source is xrepl release/0.2.x
`ea844f5e634dc1ffb2503b7d69c4726164395d82`, Cayrn integration input is
`9111136fff4aad0241c7acada4f0b664bb87d2de` on codex/core-session-lifecycle.
Recheck status/worktrees and preserve pre-existing untracked docs/design.
Source checkout `/Users/oubiwann/lab/lfe/xrepl/xrepl`. Target remains release/0.2.x.
Useful outcome: same reusable independently startable OTP agent, all five runtime
modules and three native test modules in LFE, real native/terminal contract intact.

## Required reading — before dependent edits

Relative manifest paths resolve from this slice directory (../../ is the
project root). Source paths resolve from the checkout above; skills from the
root below.

| Order | Exact input | Scope / state | Why |
| --- | --- | --- | --- |
| 1 | Source/planning/project AGENTS.md; apps/cayrn_lfe/AGENTS.md | Required-full current | Authority and thin native boundary |
| 2 | This prompt, sibling slice-plan.md and ledger.md | Required-full prepared open set | Binding map, recipe, every 8 rows and tests |
| 3 | ../arc-plan.md and ../ledger.md | Required-full | Conversion inventory including startup test and dependencies |
| 4 | ../../project-plan.md: Useful result and boundaries; Workflow and authority; Cross-repository dependencies and finding ownership; ../../design.md: Architecture and authority, Conversion and later hardening | Required-section complete | Shared Rust versus native ownership, known later fixes |
| 5 | artifacts/source-baseline.json | Required-data all xrepl.files, cayrn.files, style_guide and native_export_inventory entries | Compare every listed file SHA256/branch/HEAD/status and all 8 native export inventories; classify generated entries as designed. Report full discrepancies, no sampling |
| 6 | All five apps/cayrn_lfe/src/*.erl and three test/*.erl; src/cayrn-lfe-eval.lfe; component Makefile, rebar.config/lock, src/cayrn_lfe.app.src, bin/cayrn-lfe; root bin/cayrn-lfe, mk/lfe.mk, rebar.config, src/xrepl.app.src | Required-full named committed source at ea844f5 | Preserve all branches, exports, identity/limits and build boundary |
| 7 | /Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md | Required-full 896-line current guide, digest in baseline | LFE translation conventions and scoped compatibility exceptions |
| 8 | Installed erlang-guidelines/SKILL.md; guides/07-otp-behaviours.md BEH-01/02; guides/08-supervision-and-applications.md SUP-04/05; guides/11-anti-patterns.md AP-02/05/06 | Required-full entrypoint, required-section patterns incl rationale/definitions | Preserve behaviours, supervision, binary IDs, off-thread eval and exception ownership |
| 9 | Pinned LFE 2.2.0 doc/src/lfe_guide.7.md: Patterns, Guards, Variable Binding and Scoping, map access forms; doc/src/lfe_types.7.md Specifications; test/ltest-macros.lfe EUnit include/deftest/assertion sections | Required-section, in apps/cayrn_lfe/_build/default/lib/lfe or verified exact dependency source | Resolve rebinding, map insertion, native specs and EUnit discovery without new dependency |
| 10 | testing/guides/01-testing-discipline.md; work-verification/guides/01-ledger-discipline.md | Required-full | Real contract checks and truthful evidence |
| 11 | Cayrn crates/cli/tests/native_agent.rs, xrepl.rs and support/mod.rs: Harness::new/process ownership and scenario names used by the plan | Required-section current9111136; no edits | Actual runtime path and test oracles, source pin on return |

If the pinned dependency source is absent, building the unchanged component may
materialize it; missing required guidance must be resolved before translation.
This does not authorize dependency upgrades or another research project.

## Implementation spine and consequential choices

Follow slice-plan.md's Binding conversion map, Translation recipe and semantic
traps, and Test oracles sections in full. Remove/replace exactly the five runtime
.erl and three test .erl files with same-stem .lfe. Keep all module atoms and
declared public/callback/test name-arities exactly. Compiler-generated LFE
__info__/macro exports and EUnit test/0 are classified separately, as specified
in the slice plan; compiled export lists need not be byte-identical. Use `(MODULE)` for the preserved atom,
explicit exports/behaviours/docs/specs, hyphenated private helpers and unchanged
map/wire/message keys. No export-all or ltest dependency. Existing evaluator,
launchers, metadata, versions, config/locks and license remain identical.

Port app/supervisor/I/O first, then listener/context/tests. Retain one_for_all,
temporary contexts, linked immutable-operation I/O, owner/control separation and
capture ACK/barrier ordering. Pattern repeats compare within a pattern; inner
bindings shadow outer values. Use distinct incoming variables plus equality
guards where the Erlang code pins an outer ref/socket/PID/identity; carry that
through the negative tests. Add waiting with map-set, not existing-key-only
map-update. Dispatch must group_leader before evaluate; DOWN must confirm cancel
before lost; close waits for seals and empty pending ACKs before closed.

Apply OTP BEH-01/02 SHOULD by preserving callback contracts, SUP-04/05 SHOULD by
retaining temporary contexts and one_for_all shared fate, AP-02/05 AVOID by binary
IDs/off-callback evaluation. AP-06 AVOID does not authorize changing the pinned
command/I/O exception boundaries during a behavior-preserving port; retain their
current stop/error results and keep later hardening separate. Style-guide record
and naming preferences yield to preserved state/map/foreign OTP identities here,
as justified in the slice plan. This is idiomatic LFE within a fixed contract.

Allowlist: apps/cayrn_lfe/src/cayrn_lfe_{app,sup,listener,io,context}.{erl,lfe};
apps/cayrn_lfe/test/cayrn_lfe_{eval,io,application}_tests.{erl,lfe}; component
README.md/AGENTS.md; root README.md. These brace patterns enumerate the 8 known
pairs, not permission for arbitrary new files. No evaluator or old legacy source,
Cargo/Rebar dependency change, Rust policy edit, 256-limit fix, large-value fix,
new input or UX. Private factoring may differ while every observed behavior holds.

## Validation spine and return input to Cayrn

Use the exact commands/oracles in the slice plan. Native suite must execute all
7 named cases; inspect actual LFE beam source paths for all 8 replacements and
perform the fresh source-only component build/check plus filtered real native
case. Cached Erlang beams or an undiscovered empty suite cannot prove the port.
Keep the same EUnit ref/owner/late-write assertions; no weaker fallbacks.

Run root LFE/build/Rust checks and legacy EUnit/CT comparison. Cayrn make check,
lint-integration and explicit-new-agent make test-xrepl supply20 fast plus11+3
real scenarios and native/Rust gates at the inspected baseline. Derive actual
counts, identify the 2 duplicate root I/O executions and CT0 gap; no coverage claim
from empty discovery. Root startup test uses a fresh peer, never its already-
populated legacy parent. Test only owned temporary nodes and reap them in after.

artifacts/conversion-map.json records the baseline and every replaced file,
new digests/modes, export/spec preservation and seven case identities. The return
must give Cayrn C-AGENT the exact source commit or clearly uncommitted candidate,
built component home and full gate results; do not invent the next source pin.

## Workflow, intake and return rules

Prepared for the Operator-selected one-collaborator workflow. Sofie performs
design, implementation and a separate self-review pass; `cc-prompt.md` is the
canonical ledgered assignment name, not a commissioned second actor. This turn
plans only. Start implementation only on Operator activation and satisfied
prerequisites; do not confuse preparation/commit approval with independent
runtime reproduction. Preserve existing independent/Operator gates and historical
Project01/Project09 evidence. No delegation, push, publication or later slice.

Skill root on this host:
`/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills`.
On another host locate equivalent installed guidance rather than guessing APIs.
Read the manifest completely to its stated boundaries, including tables/code;
recover truncated output. Run required-data queries and retain exact commands,
exits, full population/denominators/exclusions. Before dependent edits record
loaded extents/revisions and source-cited contract readback in
`artifacts/execution.md`. Cover scope, semantic traps, identity/lifecycle and
expected tests. Resolve a missing/conflicting input before affected edits;
a coherent intake permits work under the activation without repeated approval.
No arbitrary recall quiz or hashes-as-comprehension claim.

Use only the source allowlist below. Preserve every issued prompt; a later
refinement gets cc-prompt-iterationNN.md beside this file, with assignment history
updated. No more than five refinement iterations before surfacing re-scope.
Keep failed attempts, filtered/ignored/unrun cases and prerequisite failures
visible. Missing external runtimes do not become a green skip. Source commits
only when separately requested, with the exact reviewed path list; planning and
source commits remain separate. Both trailers are mandatory if authorized:

```text
Co-authored-by: Codex <noreply@openai.com>
Co-authored-by: Billo AI <ai-engineering@billo.systems>
```

Return closing-report.md with each ledger row, exact source candidate/commit,
intake/evidence references, complete source allowlist, artifact inventory and
scope-as-specified/delivered bubble-up to the arc. Artifacts default to this
slice's artifacts/. Author self-checks are attested; do not generate a fictional
cdc-verification.md/crc-verification.md. Do not create a close record before work.

## Execution activation —2026-10-18

The Operator now authorizes committing these plans, then implementing xrepl's
LFE conversion followed by Cayrn's integrated-agent profile with one collaborator.
Earlier prepared/planning-only wording is historical, superseded here. Sofie
executes and separately self-reviews; all evidence stays author-attested. The
validated, byte-identified converted-agent candidate/return is the bounded input
for Cayrn, even if its implementation commit has not yet been requested. No
independent acceptance, whole-arc close, push/publication or later slice is implied.
The staged sequence is authorized without intermediate routine approval.
