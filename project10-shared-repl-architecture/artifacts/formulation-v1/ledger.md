# Project10 formulation ledger

All rows remain open for review. Evidence below is an authored candidate or an
attested document check, not independent acceptance or runtime proof.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P10-01 | Confirmed requirements remain distinguishable from proposals | Compare initial/revised contracts with conversation | serious | Operator | open | artifacts/01-initial-contract.md; artifacts/03-architecture-draft.md — attested | No implied codec/topology approval |
| P10-02 | Failures, uncertainty, output loss and durability boundaries are explicit | Walk matrix and recovery algorithm | serious | failure discussion | open | artifacts/03-architecture-draft.md — authored proposal | Runtime/host power loss not tested |
| P10-03 | Two submitting clients receive an ordered replayable session view without rerunning code | Walk scenarios S01–S04 and tests T01–T04 | serious | Operator | open | artifacts/04-demonstrator-plan.md — specified | No implementation exists |
| P10-04 | Close/archive/delete, busy close and late output have coherent ownership | Walk lifecycle, S08–S09 and T09–T10 | serious | Operator | open | artifacts/03-architecture-draft.md; artifacts/04-demonstrator-plan.md — specified | Product defaults proposed |
| P10-05 | Rust owns common infrastructure; four adapters expose only runtime-specific behavior | Compare ownership table and runtime fits | correctness-grade | Operator | open | artifacts/03-architecture-draft.md — attested source-informed design | Native endpoints still allowed |
| P10-06 | Research answers the finite question set with primary sources and decision dispositions | Follow research decision/source tables | correctness-grade | agreed next chunk | open | artifacts/02-research-round-one.md — inspected references plus synthesis | Not an exhaustive survey |
| P10-07 | All four runtimes have explicit scenario dispositions and proof gaps | Walk S01–S09 and adapter caveats | serious | Operator | open | artifacts/04-demonstrator-plan.md — source-informed analysis | No migration or runtime acceptance claim |
| P10-08 | Demonstrator exposes failures rather than tests that merely mirror design | Inspect T01–T13 and negative controls | serious | agreed next chunk | open | artifacts/04-demonstrator-plan.md — proposed test oracles | Implementation assignment deferred |
| P10-09 | Files/links/source baselines are reviewable and unrelated work preserved | Reproduce baseline hashes/link/whitespace checks | correctness-grade | repository rules | open | artifacts/05-baseline.json; artifacts/06-validation.md — attested | Human/independent review pending |
