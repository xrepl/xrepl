# Slice02 execution —2026-10-18

Sofie is the sole contributor; implementation and self-review are functional
passes, not independent actors. Plans committed before code: Cayrn f32126d,
xrepl aaa8140. Active assignment cc-prompt.md plus its recorded activation.

## Intake before dependent edits

Read current prompt/complete slice plan and8-row ledger, source/component/project
AGENTS, arc plan, project ownership/dependency/design sections. Reused unchanged
required source/guide text loaded during authoring in the same conversation:
all5 runtime and3 test modules (reloaded now), evaluator/build/config/launchers,
full896-line style guide (ranges1–300,301–600,601–896), OTP entrypoint and
BEH-01/02, SUP-04/05, AP-02/05/06; LFE2.2 Patterns/Guards/lexical scoping/map
forms/Types Specifications and EUnit bridge. Testing/ledger guides and framework
wayfinder remain in context; no unavailable required input. Earlier truncated
combined guide reads were recovered by bounded subsequent reads.

Required-data query: json.load(source-baseline.json); for each cayrn.files and
xrepl.files entry compare hashlib.sha256(Path.read_bytes()) against its digest;
git rev-parse HEAD against recorded commits, style-guide digest likewise. Results:
10/10 Cayrn and25/25 xrepl match, no drift/exclusions. All8 baseline native export
inventories were checked during authoring against19 declared runtime exports and
7 test/generator entries, with generated module_info/test wrappers separated.

## Contract readback

Replace5 runtime +3 test .erl files with same-stem .lfe; preserve declared module/
callback/test identity and specs, metadata/deps/locks/launcher/evaluator bytes.
LFE-generated __info__/macro exports are distinct from declared interface. Runtime
state stays maps; binary JSON identity stays binary. Inner receive bindings may
shadow outer refs, so pin with explicit equality guards. Maintain monitor/group-
leader-before-evaluate ordering, Rust ACK ownership, immutable output attribution,
DOWN-confirmed cancellation and seal/pending close barrier. Preserve256/8192/etc
limits and existing failure branches; their fixes belong to later slices.
Prove actual LFE beams, seven native cases, real11+3 contracts, isolated startup,
fresh source-only build and legacy modes. Retain failed attempts and no fake
independent acceptance. Return byte-identified validated candidate for Cayrn.

## Implementation and recovered attempts

Translated five runtime modules and three tests, with same module/callback/test
identities. Sequential let* preserves validation and side-effect ordering; explicit
receive guards pin outer references/owner. OTP specs use LFE remote type calls and
unquoted UNION. Runtime maps, binary identity, control frames and thresholds are
unchanged. All 19 exported runtime specs are in compiled abstract_code (the BEAM
attributes chunk does not expose specs). conversion-map.json records all eight
actual .lfe compile sources, old/new bytes, exports and spec counts. Fourteen
protected evaluator/metadata/lock/build/license inputs match baseline hashes.

First build exit2: quoted UNION and two pattern-headed helper/callback definitions
were invalid LFE; corrected syntax. Second build exit0. First native test compile
exit2: LFE try needs one expression; grouped test body in progn with original after
cleanup. Second native test command exit0 but discovered only2/7 cases: not the
seven-case criterion. Added test-only native_agent_companions_test_/0 to the I/O
companion module to include the other two modules, without changing Make/config/
dependencies. Final component make check exit0:7/7. It adds a test discovery export,
classified separately from the preserved7 case entries and compiler-generated APIs.

## Commands and observed populations

All commands ran in xrepl source unless noted. Logs retain full output.

- Component make build/check: initial failures/discovery gap above, then7/7 pass.
- Cayrn make check lint-integration test-xrepl with explicit CAYRN_LFE_DIR pointing
  to integrated component and XREPL_DIR to this source: exit0,20 ordinary tests,
 11 native +3 actual consumer/PTY, Rust7 unit+1 doctest. This run preceded discovery
  fix, so its EUnit2 count is superseded by the separate7-case run. No runtime
  source changed after the real14-case run.
- Root make compile-lfe build lint-rust test-rust test-unit-lfe test-ct-lfe: exit0,
 184 EUnit executions before discovery refinement; Rust7+1; CT0. Final root
  make test-unit-lfe test-ct-lfe: exit0,194 executions =175 legacy +19 native
  executions (7 unique native cases;12 repeats due root companion discovery).
  No test disabled or assertion weakened; CT0 is an existing discovery gap.
- Fresh-copy attempt1 accidentally included generated test/*.beam. Its make check
  exit0 is retained as a recovered setup error, NOT clean-build evidence.
- Corrected clean-copy.json lists only18 source/config/launcher/doc inputs, zero
  beams or build dirs. make check there: exit0,7/7. From Cayrn, explicit clean
  CAYRN_LFE_DIR cargo test -p cayrn-cli --features native-integration --test
  native_agent bindings_shared_clients --locked -- --test-threads=1 --nocapture:
  exit0,1 passed/10 filtered. Uses the new .lfe build, no predecessor beams.
- Prior Slice01 artifacts/wrapper-smoke.py, unchanged, executed from source:
  exit0; child cwd/private/tmp, spaced socket, native apps present, legacy xrepl/
  ranch/protocol/term absent; close barrier succeeds. compiler may load with LFE.

## Separate self-review pass

Reviewed all8 translated modules against pinned Erlang source, map/spec exports,
ordering, identity matching, binary JSON keys, monitor before evaluate, Rust-owned
ACK, immutable late-output operation attribution, DOWN cancellation and complete
pending/seal barrier. Rechecked no recursion body after loop; cleanup after try
and test-ref guard assertions retained. Public callbacks/module/test/message/map
keys keep underscores for compatibility; private helpers use hyphens. Explicit
exports/specs/docstrings retained; <=80 columns checked. No source/evaluator,
resource-limit or oversized-value assertion fix is claimed. Native app0.1.0 and
xrepl0.2.0 seed, dependencies/locks/launchers remain byte-identical.

Scope is exactly19 paths (8 deletions,8 replacements,3 docs); pre-existing
untracked docs/design/ untouched. source-candidate.json and patch identify bytes
for the authorized Cayrn handoff, not a nonexistent conversion commit. All8 rows
are proposed done, author-attested; no independent acceptance or formal arc close.


## Compiled specification equivalence

Beyond spec counts, spec-comparison.json records all five runtime modules'
compiled type signatures equal to the Erlang predecessor after erlang source
annotations are normalized to zero. Before comparison each predecessor .erl file
was checked byte-for-byte against git show ea844f5:apps/cayrn_lfe/src/<module>.erl.
Query per old/new beam: beam_lib:chunks(Path,[abstract_code]); select all
{attribute,_,spec,_} forms from raw_abstract_v1; apply
 erl_parse:map_anno(fun(_)->0 end, Form); lists:sort; compare printed Erlang terms.
All5 equal,19 specs total. verify-conversion.py reproduces current compiled-source,
export/spec-count and14 protected-input checks. Candidate source is unchanged.


## Final record consistency check

Recomputed every source candidate hash/mode and patch digest; all match. Exact
artifact inventory equals closing report;8 unique opening rows all returned.
Both source and planning git diff --check pass. Final four user docs still have
35 Bash/sh blocks passing bash -n and resolving relative file links. Planning
HEADs remain f32126d/aaa8140 with both required trailers. Source HEADs remain
9111136/ea844f5, implementation changes uncommitted as assigned. xrepl's unrelated
docs/design/ remains untracked and untouched. No push/publication or next slice.
