# Arc01 — integrated, independently startable native LFE agent

Version 1.1, 2026-10-18. In progress; first-slice candidate returned, acceptance pending. Deliver the native agent
from xrepl's release/0.2.x source tree while preserving its greenfield boundary,
then convert its implementation/tests to LFE with the real runtime contract intact.

## Inputs and boundaries

Standalone native revision 1b04c15 is the import source, Cayrn 04b4913 provides
existing real test targets, xrepl 571def5 plus its authorized uncommitted 0.2.0
version is the source base. The first slice does not depend on Cayrn hardening
or a complete old-system audit repair. Existing native semantics are a bounded
prototype input, not independently accepted whole-system correctness.
Delivery is apps/cayrn_lfe plus root build/launch/docs integration. Keep legacy
xrepl src/, Rust IF behavior and the current Cayrn mode operational. Preserve all
untracked docs/design content. No changes to sibling term/protocol repositories.

## Slice breakdown

| Slice | Useful delivered result | Dependencies | State |
| --- | --- | --- | --- |
| [Slice01 — import agent application](slice01-import-agent-application/slice-plan.md) | Existing Erlang/LFE agent runs from apps/cayrn_lfe through xrepl entrypoints and passes real host/terminal tests | Pinned native source; current public/agent interfaces | Candidate returned; attested, acceptance pending |
| Slice02 — LFE implementation | Five Erlang modules and native tests (including the new startup boundary test) become LFE; independent application, capture/control, identity and isolation contracts still hold | Slice01 accepted import; fully resolved translation/callback map and style guidance | Scope only; next prompt after import evidence |

No standalone investigation arc, untranslated halfway runtime or source-only port
counts as the completed arc. Build, startup and real tests accompany each slice.
The second slice should remain one coherent context; split if actual translation
complexity requires it without dropping any module/test obligation.

## Composition and handoff

Reproduce native tests and Cayrn's 11+3 integration tests against the explicit
in-repo app path. Start the agent alone and inspect running OTP apps: legacy
xrepl/Ranch/protocol/term applications must not be needed. Prove the root legacy
application still builds and retained Rust modes work. Known legacy baseline
failures remain explicit; new regressions block the affected slice.

On arc acceptance hand the exact native app path/build/check entrypoints and
source revision to Cayrn C-AGENT. Leave resource/size defects to Arc02 with owner
and source evidence, not lost in the port. The standalone repository remains
available until later explicitly agreed retirement.

## Version history

- v1.0 — 2026-10-18: preserve/import first, then translate, with real composition
  and separate application ownership at both steps.

- v1.1 —2026-10-18: Slice01 added a startup-boundary regression test. Include it
  in Slice02’s native-test conversion inventory so the import’s proof is retained;
  no change to runtime scope or acceptance gates.

## Slice01 bubble-up — 2026-10-18

[Implementation return](slice01-import-agent-application/closing-report.md): usable candidate implemented
and self-checked; acceptance remains pending. No sequencing/architecture change.
