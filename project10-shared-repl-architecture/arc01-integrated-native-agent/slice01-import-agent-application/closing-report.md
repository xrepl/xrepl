# Slice01 implementation return — proposed done

2026-10-18. Sole contributor: Sofie. The activated cc-prompt.md assignment is
implemented and self-checked. Every row below is proposed done with **attested**
evidence; ledger statuses remain open pending the preserved acceptance gate.
This is not a formal slice close, independent verification or permission to
advance into Slice02. No synthetic CDC/CRC identity or verification file.

Planning assignment commit: `023fc5b`. Source base `571def5`, branch
`release/0.2.x`, **uncommitted candidate**. Only planning commits were requested.
Exact source bytes/modes and patch digest: [candidate](artifacts/source-candidate.json),
[patch](artifacts/source-candidate.patch). No source push/publication. Return-record
planning commit: pending until this packet is committed (identify via Git log).

## Ledger walk — 8 opening rows / 8 returned rows

| ID | Proposed disposition | Attested evidence |
| --- | --- | --- |
| XS01-01 | proposed done; acceptance pending | artifacts/import-map.json, 15 identical +1 adapted imports, pinned license |
| XS01-02 | proposed done; acceptance pending | Fresh peer actual running-app negative controls, logs/startup-peer-final.log |
| XS01-03 | proposed done; acceptance pending | Root build, cwd/spaced-argv smoke and component build/check, logs/root-build.log and wrapper-final.log |
| XS01-04 | proposed done; acceptance pending | 6 preserved native cases +1 startup, 11 real native +3 consumer/PTY at explicit imported path |
| XS01-05 | proposed done; acceptance pending | Legacy175 before, full184 after including native/duplicate cases; Rust7+1; root builds; CT0 disclosed |
| XS01-06 | proposed done; acceptance pending | release/0.2.x, preserved0.2.0 seed and generated metadata; component0.1.0 |
| XS01-07 | proposed done; acceptance pending | Root/component README and AGENTS current home/boundary/known limits; no behavior fix claimed |
| XS01-08 | proposed done; acceptance pending | Exact24-file candidate, map, execution and row walk; independent acceptance pending |

Commands, counts, failed attempts, negative controls and self-review conclusions:
[execution record](artifacts/execution.md). No required check remains unrun; CT
discovery of zero cases is a coverage gap, not a behavioral proof.

## Reviewed source allowlist

- `AGENTS.md`
- `Makefile`
- `README.md`
- `mk/lfe.mk`
- `src/xrepl.app.src`
- `apps/cayrn_lfe/.gitignore`
- `apps/cayrn_lfe/AGENTS.md`
- `apps/cayrn_lfe/LICENSE`
- `apps/cayrn_lfe/Makefile`
- `apps/cayrn_lfe/README.md`
- `apps/cayrn_lfe/bin/cayrn-lfe`
- `apps/cayrn_lfe/rebar.config`
- `apps/cayrn_lfe/rebar.lock`
- `apps/cayrn_lfe/src/cayrn-lfe-eval.lfe`
- `apps/cayrn_lfe/src/cayrn_lfe.app.src`
- `apps/cayrn_lfe/src/cayrn_lfe_app.erl`
- `apps/cayrn_lfe/src/cayrn_lfe_context.erl`
- `apps/cayrn_lfe/src/cayrn_lfe_io.erl`
- `apps/cayrn_lfe/src/cayrn_lfe_listener.erl`
- `apps/cayrn_lfe/src/cayrn_lfe_sup.erl`
- `apps/cayrn_lfe/test/cayrn_lfe_application_tests.erl`
- `apps/cayrn_lfe/test/cayrn_lfe_eval_tests.erl`
- `apps/cayrn_lfe/test/cayrn_lfe_io_tests.erl`
- `bin/cayrn-lfe`

## Artifact inventory

- `artifacts/.gitattributes` (literal log/patch whitespace preservation)
- `artifacts/execution.md`
- `artifacts/import-map.json`
- `artifacts/logs/after-ct.log`
- `artifacts/logs/after-unit-first.log`
- `artifacts/logs/after-unit.log`
- `artifacts/logs/before-ct.log`
- `artifacts/logs/before-unit-cold.log`
- `artifacts/logs/before-unit.log`
- `artifacts/logs/imported-six.log`
- `artifacts/logs/initial-startup-seven.log`
- `artifacts/logs/root-build.log`
- `artifacts/logs/root-rust.log`
- `artifacts/logs/startup-peer-final.log`
- `artifacts/logs/startup-peer-first.log`
- `artifacts/logs/wrapper-final.log`
- `artifacts/logs/wrapper-first.log`
- `artifacts/source-candidate.json`
- `artifacts/source-candidate.patch`
- `artifacts/wrapper-smoke.py`

## Bubble-up to the arc

The first slice delivers a usable in-repository native OTP application with
root/component build/check/launch entrypoints and real host/terminal proof.
The exact pinned import/README adaptation/new-boundary-test map is preserved;
legacy source, app startup, Rust modes and0.2.0 seed remain intact. No predecessor
retirement is implied. Scope-as-specified versus delivered: all8 implementation
rows have evidence; independent acceptance remains pending. No translation or
hardening was bundled into the topology import.

The test-isolation refinements reveal no architecture or slice-breakdown change.
Arc01 Slice02 remains the five-module/two-original-test LFE conversion; include
its new startup boundary test in the conversion inventory too (it is Erlang and
new to this slice). This small inventory addition is recorded in arc-plan.md;
it does not expand the agreed native implementation/test conversion scope.
Arc02 owns the256-operation limit, retained I/O/tombstone resources and oversized
value assertion; preserve these visible limits until deliberately fixed. Later
Cayrn C-AGENT owns common profile/default path wiring after conversion. Root CT
zero-discovery remains an explicit legacy coverage gap for affected later work.
Project09's findings are not closed by175 passing legacy cases or this import.
Operator owns acceptance/next assignment; no second slice was executed.

What worked: byte/mode pinning kept behavior changes out of the import, and the
real gate's explicit new CAYRN_LFE_DIR prevented accidental predecessor testing.
The fresh-peer oracle proves the application boundary even when the parent
legacy test node already runs xrepl services.

## Planning return commit allowlist

- `project10-shared-repl-architecture/project-plan.md`
- `project10-shared-repl-architecture/ledger.md`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/arc-plan.md`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/ledger.md`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/slice-plan.md`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/ledger.md`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/closing-report.md`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/execution.md`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/import-map.json`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/after-ct.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/after-unit-first.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/after-unit.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/before-ct.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/before-unit-cold.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/before-unit.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/imported-six.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/initial-startup-seven.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/root-build.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/root-rust.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/startup-peer-final.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/startup-peer-first.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/wrapper-final.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/logs/wrapper-first.log`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/source-candidate.json`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/source-candidate.patch`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/wrapper-smoke.py`
- `project10-shared-repl-architecture/arc01-integrated-native-agent/slice01-import-agent-application/artifacts/.gitattributes`
