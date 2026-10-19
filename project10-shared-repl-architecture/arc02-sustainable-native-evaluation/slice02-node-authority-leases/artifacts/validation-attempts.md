# CC validation attempts and populations

All statements are CC attestation. Raw command/output/exit files listed below are
preserved; an old pass never represents later source. Initial implementation
failures precede the first returned candidate. The issued listener correction is
iteration01, executed correction 1/5. No final required gate is held or unrun.

| Attempt / raw artifact | Command / selection | Exit | Actual population / disposition |
| --- | --- | --- | --- |
| compile-01.log | component make build | 0 | Production compile; pinned sticky-module reports retained |
| native-check-01.log | component make check | 2 | Parse error; runtime not reached |
| native-check-02.log | component make check | 2 | 51 executions, 12 failed; duplicate atom/binary fixture keys, wrong trace selector, real listener restart defect |
| native-check-03.log | component make check | 2 | 51 executions, 10 failed; normal listener restart repaired, stale loaded test code still exercised old fixture paths |
| test-precompile-01.log | component rebar3 as test compile | 0 | Separate compile process before runtime |
| native-check-04.log | component make check | 2 | 55 executions, 2 failed; trapped external shutdown was not an actual gen_server stop |
| test-precompile-02.log | component rebar3 as test compile | 1 | New watchdog fixture delimiter; runtime not reached |
| test-precompile-03.log | component rebar3 as test compile | 0 | Syntax corrected |
| native-check-05.log | component make check | 0 | 55/55, 38 unique +17 repeats; draft before listener-kill refinement |
| cayrn-full-draft-01.log | Cayrn make check lint-integration test-xrepl, four overrides unset | 0 | 43 ordinary +14 native +3 consumer/PTY; post native55 and Rust7+1doc; recorded draft hashes only |
| fresh-source-draft-01.log | fresh source-only component make check | 0 | 55/55, no inherited beams/build; draft only |
| root-full-draft-01.log | root make test-lfe build-agent check-agent build lint-rust test-rust | 0 | Root304 =175 legacy +129 native (38 unique +91 repeats); CT0; component55; Rust7+1doc; draft only |
| root-launcher-draft-01.log / process log | actual root bin/cayrn-lfe from /private/tmp, spaced socket | 0 | Native3 hello,42, exact native app set,Closed, process0; draft only |
| test-precompile-04.log | component rebar3 as test compile | 1 | Replay-marker fixture delimiter; runtime not reached |
| test-precompile-05.log | component rebar3 as test compile | 0 | Corrected marker and real paused socket fixtures |
| authority-focused-01.log | rebar3 eunit --module=cayrn_lfe_authority_tests | 0 | 17 selected unique;21 other then-existing unique cases outside focused invocation |
| iteration01-compile-01.log | component make build | 2 | Listener callback tuple-pattern clause syntax; runtime not reached |
| iteration01-compile-02.log | component make build | 0 | Corrected production syntax |
| iteration01-test-compile-01.log | component rebar3 as test compile | 1 | New application fixture delimiters; runtime not reached |
| iteration01-test-compile-02.log | component rebar3 as test compile | 0 | Corrected fixture syntax |
| iteration01-application-01.log | rebar3 eunit --module=cayrn_lfe_application_tests | 0 | 7 selected unique (1 retained +6 new);37 other final unique cases outside focused invocation |
| iteration01-test-compile-03.log | component rebar3 as test compile | 0 | Final frozen source bytes compiled |
| native-final-01.log | component make check | 2 | 61 executions,2 failed; stale parent test beam calls removed await-startup-down while peer loads current module |
| fresh-source-final-01.log | fresh source-only component make check | 0 | Same frozen source61/61 (44 unique +17 repeats); no inherited build/beam |
| generated-beam-shadow-cleanup.log | inventory then remove ONLY ignored native source test/*.beam | 0 | Exact14 generated paths/hashes; no product source changed |
| final-test-precompile-01.log | component rebar3 as test compile | 0 | Separate fresh compile after targeted shadow removal |
| native-final-02.log | component make check | 0 | Final61/61 (44 unique +17 authority repeats); pressure preconditions positively observed |
| runtime-exports.log | isolated erl code:which/module_info exports | 0 | All9 production +5 test modules actually loaded and inspected |
| runtime-export-classification-01.log | classify generated export set | 1 | Classifier omitted compiler-generated __info__/1; actual runtime probe remained0 |
| runtime-export-classification-02.log / JSON | classify source-grounded generated exports | 0 | All14 modules match explicit declarations plus classified generated exports |
| cayrn-full-final-01.log | Cayrn make check lint-integration test-xrepl, four overrides unset | 0 | Final43 ordinary +14 native +3 consumer/PTY,0 failed/ignored/filtered; post native61, Rust7+1doc,Clippy/fmt |
| root-final-test-precompile.log | root rebar3 as test compile | 0 | Refresh root profile before runtime |
| root-full-final-01.log | root make test-lfe build-agent check-agent build lint-rust test-rust | 0 | Final322 =175 legacy +147 native (44 unique +103 repeats); CT0; component61; Rust7+1doc;Clippy/fmt |
| root-launcher-wrapper-final.log / root-launcher.log / process log | actual root wrapper from /private/tmp with spaced socket | 0 | Native3 exact scopes,42, exact native app set,Closed,process0 |
| final-generated-beam-identities-01.log | isolated beam_lib exports/hash inventory | 0 | Current20 generated test beam paths, including symlink aliases; read-only |
| final-generated-beam-identities-02.log | structured beam_lib helper assertions | 0 | All4 current authority beam paths export paused-roles/0 and omit removed await-startup-down/1 |
| source-commit.log | exact16 git add/commit and blob/trailer checks | 0 | Source commit38338d6; all committed hashes equal frozen pre-gate bytes; only unrelated docs/design untracked |

One additional postcommit Python inspection wrapper exited1 because its literal
substring assertion assumed pretty-printed Erlang tuples were on one line. The
underlying Erlang read-only probe exited0; this first wrapper output is retained
in the tool transcript, not fabricated as a raw file. Actual rerun output is
final-generated-beam-identities-01.log; structured Erlang assertions in02 remove
the output-layout assumption and pass. No source edit or runtime gate rerun was
needed. Every build/test raw attempt above is retained. Initial file reads/edits
and some exploratory queries exist only in the tool transcript; execution.md
states that capture boundary explicitly.

Final native component module executions: authority34, application7, resource14,
evaluator4, IO2 =61. Unique population44 =21 retained +17 authority +6 application.
Root native module executions: authority68, application21, resource42, evaluator12,
IO4 =147. Root repeats103 are discovery repetitions, not new cases. CT runs zero.
No skipped/missing-precondition native pass is claimed. Focused exclusions above
are explicit; all final full native and all17 matching host/terminal cases execute.

Target-label reconciliation before CC return: ordinary43 is client2/core1/
host-private15/host-tests-agent12/host-tests-sessions9/protocol4; CLI0/fixture0.
xrepl7 are adventure tests, core ordinary0 and core doctest1 (CLI0/adventuredoc0).
Totals are unchanged. Exact Running targets from cayrn-full-final-01.log ground
these labels; final-runtime-populations.json includes every actual target.
