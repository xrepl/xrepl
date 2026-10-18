# Native import first-slice acceptance ledger

All implementation rows are open. Prepared plans and source hashes do not
establish execution, independent acceptance or a release.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| XS01-01 | All intended native files have pinned provenance and license | git import population, per-file digest/mode map | correctness-grade | Operator import decision | open | [return](closing-report.md), [execution](artifacts/execution.md); attested | Implementation proposed done; acceptance remains pending |
| XS01-02 | Agent is an independently startable OTP application in xrepl | Component build/check and actual running-app negative controls | serious | clean boundary | open | [return](closing-report.md), [execution](artifacts/execution.md); attested | Implementation proposed done; acceptance remains pending |
| XS01-03 | Root/component entrypoints are usable and cwd/argv safe | Root build-agent, wrapper from another cwd and spaced socket path | correctness-grade | usable increment | open | [return](closing-report.md), [execution](artifacts/execution.md); attested | Implementation proposed done; acceptance remains pending |
| XS01-04 | Native contract survives the import at the real new path | 6 native EUnit plus both Rust real test targets with explicit new CAYRN_LFE_DIR | serious | prototype preservation | open | [return](closing-report.md), [execution](artifacts/execution.md); attested | Implementation proposed done; acceptance remains pending |
| XS01-05 | Legacy source/build and Rust modes are preserved | Compile, IF tests and native legacy before/after comparison | serious | migration scope | open | [return](closing-report.md), [execution](artifacts/execution.md); attested | Implementation proposed done; acceptance remains pending |
| XS01-06 | Version seed and branch are retained without unrelated upgrades | release/0.2.x and generated root application version 0.2.0 | correctness-grade | Operator | open | [return](closing-report.md), [execution](artifacts/execution.md); attested | Implementation proposed done; acceptance remains pending |
| XS01-07 | Docs/instructions communicate current scope and real limits | Read runnable examples and capability/limit claims against code | correctness-grade | usable delivery | open | [return](closing-report.md), [execution](artifacts/execution.md); attested | Implementation proposed done; acceptance remains pending |
| XS01-08 | Return scope/evidence/gates are explicit | Closing row walk and reviewed import/source file allowlist | correctness-grade | framework | open | [return](closing-report.md), [execution](artifacts/execution.md); attested | Implementation proposed done; acceptance remains pending |

2026-10-18: all 8 rows returned as proposed done after implementation/self-review.
Rows intentionally remain open for the preserved acceptance gate.
