# xrepl Arc01 composition ledger


All implementation rows are open unless explicitly deferred. No execution or
independent acceptance is claimed by this planning packet.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| XA01-01 | Pinned native import and license are preserved | Slice01 file/mode/digest map and native test run | correctness-grade | design | open | [Slice01 candidate](slice01-import-agent-application/closing-report.md), attested; acceptance pending | No build state or nested Git |
| XA01-02 | Agent starts independently from xrepl tree | Root/component launcher + running application dependency check | serious | separate OTP boundary | open | [Slice01 candidate](slice01-import-agent-application/closing-report.md), attested; acceptance pending | No legacy xrepl services required |
| XA01-03 | Five Erlang implementation modules and tests become LFE | Slice02 translation map, formatter/build and native tests | correctness-grade | Operator | open | — | Existing evaluator remains LFE |
| XA01-04 | Same real contracts survive both import and conversion | 11 native + 3 xrepl tests using explicit apps/cayrn_lfe path | serious | architecture | open | — | No predecessor-path substitution |
| XA01-05 | Legacy build and retained Rust modes remain usable | Before/after build/test comparison and existing IF/terminal gates | serious | preservation | open | [Slice01 candidate](slice01-import-agent-application/closing-report.md), attested; acceptance pending | Record existing legacy gaps |
| XA01-06 | Cayrn next slice receives exact tested native input | Arc handoff path/revision/entrypoints and independent composition gate | correctness-grade | paired roadmap | open | — | Resource/size fixes remain owned |
