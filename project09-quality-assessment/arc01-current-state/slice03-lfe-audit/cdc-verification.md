# LFE/OTP coordinator verification — 2026-10-17

Reviewer: Sofie, coordinating context. Actual author: CC plan_sources_c.
Assignment: preserved cc-prompt.md, issued at dbcbc21. Reviewed delivery:
dc56a75c5355c5460d651944e33262e83ca5a519. Source:
b865b3137e841269f9218d978817cc243e6b9278. No source repair was performed by
reviewer or author. This is actual separate-context review of the CC audit,
not a separate CRC identity or acceptance of Sofie's own project synthesis.

**Verdict:** accept the bounded LFE/OTP audit delivery. All 21 findings retained:
12 High,9 Medium,0 Blocker/Low. Findings are diagnoses, not repaired defects.
Source-supported risks remain source-supported; accepting them does not claim
an exploit, network/hardware test or every possible code path was exercised.

## Independent checks and challenges

I read the complete candidate report, evidence/coverage tables and final G2
reconciliation, inspected the five scripts before execution, and checked the
actual source at the reported session/store/history/network/client/reader/
printer/story/render/fork boundaries. I independently replayed all five scripts
against the pinned built code from the source checkout:

- escript artifacts/lfe-probes/public-paths.escript
- escript artifacts/lfe-probes/evaluator-stack.escript
- escript artifacts/lfe-probes/story-contracts.escript
- escript artifacts/lfe-probes/input-boundary.escript
- escript artifacts/lfe-probes/render-boundary.escript

Paths above are relative to this slice; execution used their absolute paths.
All scripts exited0 as observation harnesses; product failures were expected
observations, not passing product assertions. Exact independent outputs are in
[coordinator-review](artifacts/coordinator-review/). No broad EUnit rerun was
needed after unchanged source and existing native receipt.

| Claim group | Independent disposition |
| --- | --- |
| LFE-001/002 | Caller B receives first reply and A times out; sequential3/5 controls survive. Stack grows9→4509 over500 successful calls. Reproduced. |
| LFE-003/004/011/012 | Immediate close loses12345; explicit save restores67890. Expiry removes row but leaves eval11 active. Custom metadata lost; face-name switch fails while actual-ID attach works. Reproduced. |
| LFE-006/007/008/009/013/015/019 | UTF8 doubling/wire lambda length2; incomplete reader crash/raw first-form truncation; parsed story list crash with string/atom controls; actual renderer success tuple rejected; missing binding API/literal module call; scalar dispatcher badmap; malformed condition/codepoint failure and undeclared flag acceptance all reproduced at the documented public boundaries. |
| LFE-005/010/014/016/017/020/021 | Independently inspected cited source and relevant resolved dependency contracts. Accept as bounded source-supported risks/contract defects. No atom exhaustion, oversized frame, real socket/auth, private history, launcher boot or exported script-file exercise claimed. |
| LFE-018 | Inspected actual substitute tests and workflow; current175/175 does not cover the demonstrated boundaries. Existing archive fixture caveat explicitly carried forward. |

Important qualifications checked: packet4 prefix alone is not proof of immediate
4GiB allocation; TCP authentication exists despite unused policy settings;
the whole fork is not dead; real snapshot get_vars and explicit save work;
story completion sets save slot to none correctly; binary:join matches are
comments; local make lint does invoke xref. No global 'no specs anywhere' claim
survives the Erlang fork's specs. Historical L-01–L-21 have current dispositions
without manufacturing historical acceptance.

Guidance: author coverage is full Chineual896 lines plus Erlang entrypoint/all 17
chapters 7220 lines and audit guides, with original G1 gap and G2 recovery retained.
I checked manifests/counts/hashes; these are attributed reading receipts, not a
claim I personally reread every guide. Seven scales are represented by explicit
line/function, module, logical-unit, app, executable entrypoint, whole-codebase
and sibling-workspace boundary findings. Eight concrete clean checks were
reviewed for bounded claims; source search absence is not runtime proof.

## Ledger walk and bubble-up

| Row | Disposition / verification |
| --- | --- |
| S03-01 | done; reproduced coverage/manifests against mapped first-party population; attributed guide receipts reconciled. |
| S03-02 | done; independently checked exact finding source and applicable public probes; risk evidence types retained. |
| S03-03 | done; five isolated public-path script replays and controls, exact logs retained. |
| S03-04 | done; all scales, coherence, severity and eight clean checks inspected. |
| S03-05 | done;21 historical IDs reconciled against current report/map and actual native receipt limits. |
| S03-06 | done; source unchanged, original corpus unchanged, all 21 IDs feed combined index/backlog; no runtime acceptance inferred. |

The slice delivers its assigned language assessment and enables bounded repair
planning. It reveals lifecycle/stack/real-input defects that the existing green
suite misses. Arc plan now records the delivered reports and evidence limits;
no new runtime repair slice or shared architecture is added to Project09.
All mapped code is covered; private/hardware/socket matrices remain explicitly
unrun, not silently removed acceptance criteria. Operator project acceptance
and the coordinator-authored synthesis remain open.
