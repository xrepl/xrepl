# CC assignment — xrepl Project10/Arc02/Slice03

2026-10-19, initial issued cc-prompt.md. CDC/root owns engineering/design and
independent acceptance; actual CC/root/xrepl_x21 implements. Autonomous Mode2.8.0
through this Arc02 only, Expedited. Source release/0.2.x at
38338d6ad38898fd24063b6c89582f0ff486aa30, only preexisting??docs/design/. Plans
separate orphan planning. Actual accepted shared Cayrn source
34af63eb9f07a0e019495378045852ad69d00284/planning149ae8c22df5a71997e4674a5efcc160afa64acf.
No guessed future pin or native3 runtime pass relabeled native4.

Useful result: ordinary large LFE values/errors no longer lose a healthy context
while printing; bounded validUTF8/report persist through shared Cayrn, and xrepl
consumer compiles/runs. Native4/publicRPC1. Reusable nativeapp0.1/xrepl0.2 unchanged.
No push/merge/publish, UX/newarc/project/historyacceptance or separate investigation.

## Exact source and return scope

Only these15 source paths (two NEW):
```
apps/cayrn_lfe/src/cayrn_lfe_connection.lfe
apps/cayrn_lfe/src/cayrn_lfe_authority.lfe
apps/cayrn_lfe/src/cayrn_lfe_context.lfe
apps/cayrn_lfe/src/cayrn-lfe-eval.lfe
apps/cayrn_lfe/src/cayrn-lfe-preview.lfe
apps/cayrn_lfe/test/cayrn_lfe_eval_tests.lfe
apps/cayrn_lfe/test/cayrn_lfe_preview_tests.lfe
apps/cayrn_lfe/test/cayrn_lfe_authority_tests.lfe
apps/cayrn_lfe/test/cayrn_lfe_application_tests.lfe
apps/cayrn_lfe/test/cayrn_lfe_resource_tests.lfe
apps/cayrn_lfe/test/cayrn_lfe_io_tests.lfe
crates/xrepl-core/src/cayrn.rs
apps/cayrn_lfe/README.md
apps/cayrn_lfe/AGENTS.md
README.md
```
connection/authority production only handshake positive version3→4, no role/loss
change; applicationtests only positive versionfixture; resource tests only new
finishing tuple metadata fixture and assertions directly affected; preserve all
prior authority/pressure/ACK/root witnesses. IOtest companion adds preview suite.
Consumer source only drain Outcome match tolerance and direct tests if needed,
no presentation redesign. No collector/registry/listener/supervisor/app/build/
launcher/manifest/lock/deps/version changes or standalone predecessor. Essential
missing scope returns to CDC before edits; do not smuggle stream/root fix here.

CC planning exact8 return files relative to this slice: artifacts/execution.md,
artifacts/intake.log,artifacts/validation.log,artifacts/source-candidate.json,
artifacts/source-candidate.patch,artifacts/artifact-inventory.md,closing-report.md,
ledger.md(evidence/notes only, all8statusesopen). No issuedprompt/bindingdesign/
parent/reviewer changes. Raw labelled command/output/exit history append-only;
preserve failures and unrun/filtered/ignored counts. Source and planning separate
explicit reviewed allowlisted commits, never directory-wide staging. Bothtrailers:
Co-authored-by: Codex <noreply@openai.com>
Co-authored-by: Billo AI <ai-engineering@billo.systems>

## Required reading manifest and preflight

Resolve paths:
X=/Users/oubiwann/lab/lfe/xrepl/xrepl
C=/Users/oubiwann/lab/oxur/cayrn
P=X/.worktrees/planning/project10-shared-repl-architecture
A=P/arc02-sustainable-native-evaluation
S=A/slice03-bounded-result-previews
F=/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills/collaboration-framework
K=F/knowledge
E=/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills/erlang-guidelines
R=/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills/rust-guidelines
CP=C/.worktrees/planning/project02-core-hardening

Required-full means actual complete body/tables/code/appendices, recover truncated
output; data query coverage is distinct from prose received into context. Read
before dependent implementation in this order:
1.Required-full S/cc-prompt.md,slice-plan.md,ledger.md,artifacts/preview-contract.md,
artifacts/preview-design-review.md,artifacts/ownership-review.md; X/AGENTS.md,
X/apps/cayrn_lfe/AGENTS.md,X/.worktrees/planning/AGENTS.md,P/AGENTS.md,
P/project-plan.md,P/design.md,P/ledger.md (parent AGENTS requires full reading).
Required-section A/arc-plan.md: Capability and boundaries, Inputs and sequence,
Composition ledger and exit, Autonomous Mode activation, v1.5 shared preview,
v1.6 accepted native3 and v1.7 native decomposition complete sections; A/ledger.md
full. Draft algorithm is reference-only superseded history; contract binds.
2.Required-full actual C05 cdc-verification.md at CP/arc01-native-session-hardening/
slice05-structured-result-previews and C/docs/result-previews.md; required-section
C/crates/protocol/src/lib.rs PreviewMetadata/RenderedPreview/Operation/EventKind/
agentEvent and both VERSION declarations complete definitions. Actual source34af63e.
Required-section A/slice02-node-authority-leases/cdc-verification.md Current verdict,
Final bubble-up and scope disposition; current X-TOOL-01 in P/project-plan.md. This
bounds actual prior evidence/holds/tool freshness; does not waive new gates.
3.Required-full F/SKILL.md2.8.0,K/project-management/guides/README.md,
K/work-verification/guides/01-ledger-discipline.md,
K/work-verification/guides/05-independent-verification.md,
K/testing/guides/03-validation-gates.md. Required-section
K/engineering-methods/guides/07-implementation-prompt-authoring.md Required reading
and CC intake; methodology01 Roles/shared invariants, Two-Contributor, Autonomous
Mode; PM02 Slice iteration filenames/preservation, PM03 Issuing/executing iteration.
4.Required-full /Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md,
E/SKILL.md,E/guides/11-anti-patterns.md; required complete headed clauses E/guides/
04-data-and-types.md DT01/10/11/12/16;05-functions-and-pattern-matching.md
FP01/08/09/11/12;10-performance.md PF07/08/09. Relevant clauses actually applied
in bindingcontract Guideline application, do not substitute Erlang syntax for LFE.
Required-full R/SKILL.md; required-section R/guides/11-anti-patterns.md all70heading
scan plus AP09/25 complete; retained source Rust style/concurrency stays unchanged.
5.Required-full actual38338d6 X/apps/cayrn_lfe/src/cayrn-lfe-eval.lfe,
cayrn_lfe_context.lfe,cayrn_lfe_connection.lfe,cayrn_lfe_authority.lfe;
X/apps/cayrn_lfe/test/cayrn_lfe_eval_tests.lfe,cayrn_lfe_io_tests.lfe;
X/crates/xrepl-core/src/cayrn.rs; X/apps/cayrn_lfe/README.md,X/README.md.
Required-section resource tests all evaluated/finishing direct fixtures+full
related tests/helpers; authority/app tests all version references and full
related tests/helpers, preserving raw invalidfield/EOF/pendingoutput witnesses.
New renderer/tests absent baseline. Read X/apps/cayrn_lfe/Makefile, root Makefile
native/Rust quality targets, component/root rebar configs for actual testroute.
6.Required-section pinned X/_build/default/lib/lfe/src/lfe_io_write.erl term/symbol/
bitstring/bytes/function/string full definitions and helper escaping dependencies;
lfe_io_pretty.erl print/term collection branches(default depth/string/map/binary
full materialization explains rejection). Installed maps.erl iterator/next full
branches; installed io_lib_format.erl fwrite_g/1,io_lib.erl PID/port/ref scalar
branches. Locate installedstdlib path via current OTP; source API, not memory.
7.Required-data artifacts/source-baseline.json ALL15hashes/absence/actualupstream
pins; compute hashes, HEAD/branch/worktrees/staging/status bothrepos, preserve
preexistingdocs/design. Query every cayrn-lfe-eval:run caller, evaluated/finishing
message producer/pattern, nativeversion reference and native Outcome writer in
apps/cayrn_lfe; query all xRust Outcome patterns+JSONpaths; inspect complete result
population and enclosing definitions. No missing producer/caller silently ignored.

Record text extents/truncation recovery separately from complete data-query
coverage in artifacts/execution.md, raw receipts intake.log. Source-cited readback
must connect XS03rows to byte/depth/omission, savedenv/error, allOutcomeversions,
exact scope, actual17gate and X04/NR02/C06 holds before source mutation. Resolve
contradictions/unavailable required inputs with CDC, otherwise coherent preflight
permits execution under authority, no routine approval pause. Revalidate on resume;
hashes/anothercontextsummary never count as this context's actual text reading.

## Implementation spine

Binding algorithm artifacts/preview-contract.md is current; prior draft is
preserved only for review history. Exact8192UTF8, depth32; explicit fit/no_fit,
marker/closer/separator reservations and omission propagation. New pure module
render1 returns #(binary bool), spec/doc, private helpers. No test-only budget API.
Use lazy listcons/tupleelement/defaultmapiterator/byte+bit cursor, bounded256short
string/binary probes, scalar APIs verified above. NEVER fullcollection prettyprint,
maps:to_list/tuple_to_list/listlength scans/fullbinary Unicode conversion or full
bigint decimal conversion before bounded threshold comparison. Integer threshold
1bsl(4*remaining) before decimal conversion/no hugeabs; exact resultingbytecheck.
Emptylistbeforestring; guard insufficient reservation before subtraction; all
fragments UTF8binary/ASCII, single bounded final assembly. Structural syntax and
conservative early omission explicit; no fullpretty/codec/maximalutilization claim.

Preserve actual fullvalue/savedenv; rendering large value becomes preview true,
not an assertion/context loss. Evaluator run2 returns4tuple status/text/report/env
for success, parsefailure, ordinaryevalfailure; previous committedenv onerror.
Context updates EVERY evaluated/finishing construction/match, forwarding flag to
nativeOutcome. Keep reader/capture/foreground-ready/physicalDOWN/close/ACK order.
Fixed resource failure and cancellation messages reportfalse. Nativepositive
Hello/Ready4, reject1/2/3; nofallback. All nativeOutcome paths requiremetadata.
Update direct resourcefixture and fourevaltests for reportfalse plus new preview
suite, explicitly listed in native_agent_companions_test_. Nativewire largecases
use actual socket helper conventions, not artificial contextcallback-only proof.

In actual xrepl-core cayrn.rs fn drain exhaustive Outcome adds '..' (or explicit
unused preview); JSONmode already serializes wholeEvent and must retainmetadata.
No humantext change. Rebuild consumer and execute existing actualheadless+PTY
cases at matching Cayrn4 immediately. Docs explain shortstrings/structuralfallback,
byte/depthflag/UNKNOWNdistinction and native4compat, no general bound on userheap.
X04 complete supportedstreams+ownedresponsiveteardown, C06 crossrepo composition
remain blocking; no nativeIO/workerownership implementation in this slice.

## Discriminating tests and actual gates

All8rows map to tests/source assertions, not counts alone. Test smallscalar/type
representations, escapingUnicode/invalidbinary/improperlist/bittail/funPIDportref,
emptyvalues, literalellipsis false. Wide100k list/map/tuple/binary; nesting32/33;
million-bit positive/negativeinteger; exact8192-digit rootintegerfalse/8193true.
Conservative listoracle4094one-digititems8189bytesfalse;4095mayearlytruncate true
though exact8191textwouldfit;4096overbudgettrue. Check byte_size<=8192 and validUTF8
for generated cases. Source review must check every branch's boundedoperations,
not claim performance proof from specimens or elapsedtimeout. Testdelimiter/
bit/maptail/minimalremaining paths via actualfixedbudget render1, no publicknob.

Through actualnative4socket evaluate large set/list/map/binary, succeededtrue then
small query onbinding provesenvironmentretained. Hugeuserexceptionfailedtrue
preservescommittedenv, parsefailurebounded, ordinarysmall/resource/cancelfalse.
All old44unique native cases remain unchanged semantically with version/tuple
fixtures only; stale/scope/credit/authorityloss/control/ACK negatives staymeaningful.
No output truncation under valuepolicy. No bigger threshold standing in forfix.

Run actualcomponent makecheck; root make test-lfe build-agent check-agent build
lint-rust test-rust; matchingCayrn make check lint-integration test-xrepl with
CAYRN_LFE_DIR/XREPL_BIN overridesunset. Shipped14native+3consumer all execute,
including4097publiccontexts/1024evals/twoHostownership. No compile/list-only green,
no filtering/ignored/fallback. Fresh source-only component makecheck +rootlauncher
from/private/tmp spacedsocket: actualauthority4/ready4scopeecho,42,Closed, native
only apps(cayrn_lfe compiler crypto kernel lfe stdlib), ownedprocess0. Preserve raw
commands/exits and actualunique/repeated/rootlegacy/native/Rust/CT populations.

X-TOOL-01 known ignored testbeam loader freshness: identify generatedshadowfiles
and compile current componenttests BEFORE rootgate to avoid loading oldmacros;
remove only exactownedgeneratedshadows after verifying identity if needed. Retain
anyfailedattempt and source/freshcheck. Do not changebuild/config inthisscope.
Existing CT0 and X-PKG-01 rootspacedsourcehook limitations explicitly recorded;
spacedsocket is stillrequired and different. No unapprovedbenchmark/inquiry.

## Return and stop

Complete exact15before/aftercandidate hashes, fullbinarysafepatch, actualupstream
pins, all8proposedrows+testmapping, sourceintake, rawresults/errors and complete
supportinventory. Commit sourcefirst, exact8returnsecond with bothtrailers. Source
clean exceptpreexistingdocs/design. All8ledgerstatusesopen untilactualCDCacceptance;
CC selfchecks attested, no manufacturedreview. Correctionbudget max5 executed
iterations, issuedpromptsneveroverwritten. CDCissuesnewnumberedpromptifneeded.
Stop affectedwork for source drift/missingessentialscope/policycontradiction or
requiredgatefailure needing designchange; no specweakening or greenfallback.
Other authorized work canproceed. Rootindependentreview/retro/parentupdatesbefore
nextslice. Sourcecommentary should state usablebehavior/uncertainty, not receipts.

## Author readiness

Rootinspected actual38338d6 evaluator/context/router/authority, directtuplefixture,
consumerdrain and allchangedversion/callerpaths; matchingaccepted34af63e common
contract explains exactprivate4/public1 transition. Applied completeLFE guide and
namedBEAM clauses, verifiedpinnedscalar/map/prettyAPIs. Indepread-onlyreview found
oneconcrete reservation/testcontradiction and nonexistentalternativefloatAPI;
resolved explicitly inbindingcontract beforeissue, no newoperatorpolicy. X04
ownershipreview P2 prevents prematureownershipacceptance. Exactscope includes
companiondiscovery/consumerpointofuse. Completeintake/recipe/tests fit pureprinter
increment with recoveryheadroom; no consequential choice delegated as missingpolicy.
Local helpernames/moduleorganization insidecontractdiscretionary. No claimed
compiled pseudocode, arbitrarytermformalcomplexity, release or generalteardown.
