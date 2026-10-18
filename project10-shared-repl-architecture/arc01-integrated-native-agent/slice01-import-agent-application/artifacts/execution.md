# First-slice execution — 2026-10-18

Sofie is the sole contributor for design, implementation and a separate self-review pass. Evidence is attested, not independent acceptance. Planning commits precede implementation: Cayrn 53cd1cb, xrepl 023fc5b. No subagents or synthetic verifier files.

## Intake

Loaded current repository/planning/project AGENTS, activated prompt, complete slice plan/8-row ledger, arc plan/ledger, required project-plan/design sections. Loaded testing discipline and ledger discipline guides. Rust entrypoint read in bounded sections (1–611), EH-01/EH-04 definitions and AP-01..10; OTP entrypoint and PS-01/02/07, SUP-11..13 definitions. Relevant source/admission/lifecycle/peer sections were traced; native tracked source/test/config/launcher/license/README and destination Make/rebar/app metadata read. No semantic .lfe changes: conditional full LFE style load not triggered. Broad guides are topic references, not a claim every unrelated pattern was loaded.

Structured baseline query: Python json.load; for every repositories.cayrn.selected_files entry, hashlib.sha256(Path.read_bytes()) compared with recorded digest. Native exact population: git ls-tree -r --name-only <pin>, set equality with native_agent.selected_files, then hashlib.sha256(git show <pin>:<path>) for all 17 entries; dirty_xrepl_input path hash compared separately. Results: Cayrn 31/31 match; native 17/17 match; 0.2.0 seed matches. Current Git status matches baselines: Cayrn clean main04b4913; native clean main1b04c15; xrepl release/0.2.x571def5 with only version seed and untouched untracked docs/design.

## Contract readback

Import all 16 tracked predecessor files except AGENTS from 1b04c15, retaining source/test/config/lock/license bytes and launcher mode; author current instructions. Agent owns native contexts only and keeps kernel/stdlib/lfe startup dependencies, independent of legacy xrepl. Root build/check delegates and cwd-safe exec wrapper target component-local cache. Preserve root app/version, legacy modes and docs/design; prove running-app negative controls and real native/PTY suites against apps/cayrn_lfe. Translation, 256-operation/size hardening and UX are later work. Standalone predecessor remains untouched.

## Implementation and validation

Source base571def5 on release/0.2.x, with the pre-existing authorized 0.2.0 seed.
Exact 24-file candidate is uncommitted, identified in source-candidate.json/.patch.
Import-map.json proves 17 predecessor entries: 1 excluded AGENTS, 16 imports,
15 byte/mode identical and 1 adapted README. New component AGENTS, startup test
and root wrapper account for the other three new files. Native implementation,
two original test modules, build/config/lock and license remain byte-identical.

| Command from xrepl unless noted | Exit | Observation / evidence |
| --- | --- | --- |
| make test-unit-lfe, before import, cold | 2 | LFE dependency cl.lfe error writing file; logs/before-unit-cold.log |
| make test-unit-lfe, before import, retry | 0 | 175 executed, all passed; logs/before-unit.log |
| make test-ct-lfe, before import | 0 | 0 tests discovered; logs/before-ct.log; no CT coverage claim |
| make build-agent check-agent, initial pinned import | 0 | Preserved 6 EUnit tests passed; logs/imported-six.log |
| make check-agent, first startup oracle | 0 | 7 tests, zero failures in component-only node; logs/initial-startup-seven.log |
| make compile-lfe build-rust lint-rust test-rust | 0 | Both root OTP apps compiled; Rust 7 unit + 1 doctest passed; logs/root-rust.log |
| make test-unit-lfe, first post-import run | 2 | 183 passed, 1 new startup test failed, no skips; logs/after-unit-first.log |
| make check-agent, first peer-node revision | 2 | 6 passed, 1 test harness badmatch; logs/startup-peer-first.log |
| make check-agent, corrected peer-node revision | 0 | 7/7 passed; logs/startup-peer-final.log |
| make test-unit-lfe, corrected post-import run | 0 | 184 executed, all passed; logs/after-unit.log |
| make test-ct-lfe, after import | 0 | 0 tests discovered; logs/after-ct.log |
| make build | 0 | Root LFE + component-local agent + Rust built; logs/root-build.log |
| Cayrn make test-xrepl with explicit new component and xrepl paths | 0 | 11 native + 3 actual consumer/PTY, 7 native EUnit, 7 Rust unit + 1 doctest; see paired Cayrn execution/real-integration.log |
| python3 artifacts/wrapper-smoke.py, from this slice | 0 | Root launcher cwd=/private/tmp, spaced socket path, required native apps present, legacy apps absent; logs/wrapper-final.log |
| sh -n bin/cayrn-lfe apps/cayrn_lfe/bin/cayrn-lfe; git diff --check | 0 | Both launchers parse; source diff whitespace clean |

The root EUnit population executes two original I/O cases twice through its
multi-app discovery: 175 original executions + 7 native/startup cases + 2 duplicate
I/O executions =184; do not describe this as184 distinct tests. Legacy175 all pass.
Common Test discovers no cases both before/after; that is a visible coverage gap.

## Failure triage and refinement history

1. Cold legacy dependency compilation failed before import. Retry succeeded175/175;
   the initial failure is retained, not attributed to the import.
2. Initial startup test inspected its parent EUnit node. Component7/7 passed, but
   root legacy tests had already started legacy services; the new assertion failed.
   The oracle needed an isolated node, not weaker forbidden-app checks.
3. Switched the new startup test to OTP peer over standard_io, preserving all
   forbidden-app checks and socket mode/path assertions. First attempt expected a
   two-element start result; actual/documented OTP28 result was {ok,Pid,Node}.
   Corrected to the documented three-element pattern; component7/7 and root184/184
   now pass. peer:stop in after owns/reaps only this test node. Consulted local
   OTP28.5 stdlib7.3 src/peer.erl start_link specification/control lifecycle.
4. Temporary wrapper smoke initially assumed exact running set without OTP compiler.
   LFE evaluation legitimately started compiler. Retained failure log; changed only
   this temporary harness to require native apps and exclude the four legacy apps.
   Actual set: cayrn_lfe, compiler, kernel, lfe, stdlib. Original outer shell ended0
   after sh -n despite the prior Python assertion failure; no smoke success is
   inferred from that outer status. Corrected smoke passed0 and is saved here.

## Separate self-review pass

Checked complete root diff plus every new file against pin/map. No source/test/
config/launcher adaptation was hidden in the import. Both source and generated
root app versions are0.2.0; component source/generated version stays0.1.0.
Root rebar.config, rebar.lock and Cargo.lock unchanged. Component startup depends
only on kernel/stdlib/lfe; root app dependencies unchanged. Actual fresh peer and
root-wrapper node both exclude xrepl/Ranch/protocol/term; root compile still builds
legacy xrepl. Standalone predecessor remains clean; docs/design untouched.
No later translation, resource retirement, size assertion fix, UX, old transport
removal or sibling source edits. All observations are author-attested self-checks.

## Return-packet checks

Python verification compared every candidate file digest and patch SHA256, ran
`git apply --reverse --check artifacts/source-candidate.patch` from the source
checkout (read-only), counted8 open rows and all8 closing-report IDs, resolved
all new Markdown links, and ran source/planning `git diff --check`: passed.
Root manifest/lock byte checks against HEAD passed; predecessor Git status clean.
Source changes remain uncommitted and are not part of the planning return commit.

The first staged return-packet whitespace check flagged literal Make output
trailing spaces, blank log endings and unified-diff context lines. Raw evidence
bytes are preserved. artifacts/.gitattributes disables whitespace diagnostics
only for logs/*.log and source-candidate.patch; source/docs/metadata remain
checked. The failed staged check caused no commit. Scoped attributes are part
of the return inventory and the retried check must pass before commit.
