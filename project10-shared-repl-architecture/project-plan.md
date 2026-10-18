---
project: project10-shared-repl-architecture
status: refocused-planned-open-set-prepared
depends-on: [cayrn-project02-bounded-contracts]
blocks: [xrepl-0.2.x-core-migration-candidate]
related: [cayrn-project01-shared-repl-architecture, project05-rust-frontend, project06-pluggable-shells, project07-story-runtime, project09-quality-assessment, xrepl_protocol, xrepl_term]
---

# xrepl 0.2.x — migration onto Cayrn

Version 2.0, 2026-10-18. Author: Sofie, current design/planning context. The
Operator explicitly retained this project name and approved the core migration,
agent consolidation and LFE conversion; UX follows in a separate future project.
This turn prepares plans/open sets, not implementation or release acceptance.

## Useful result and boundaries

Make Cayrn the common session/admission/transcript infrastructure for xrepl's
real LFE development experience on release/0.2.x. Bring the purpose-built native
agent into this repository as a small OTP application, convert its Erlang
implementation/tests to LFE, harden it and migrate the existing application
features without inheriting two competing session authorities.

The first usable increment runs the current real agent **from the xrepl source
tree**, independently of starting the legacy xrepl OTP application, and passes
the existing real host/BEAM/terminal tests against that explicit new home.
[Design](design.md) specifies ownership and the first import layout.
[Ledger](ledger.md) carries the current migration DoD. Full formal release waits
for a later UX project, version/package checks and explicit publication authority.

Shared Rust infrastructure remains in Cayrn. LFE behavior belongs here, not in a
new per-language Rust host crate. Preserve the agent's independent application
and supervision boundary even when co-located. No Oxur/Lykn/Fennel implementation
is included. No live heap recovery is inferred from transcript persistence.

## Baseline and provenance

Source checkout /Users/oubiwann/lab/lfe/xrepl/xrepl is on release/0.2.x, based on
571def5. The Operator-authorized src/xrepl.app.src bump to 0.2.0 is uncommitted;
it compiled and generated the right metadata. Cargo package versions remain
0.0.0 until packaging decisions; independent OTP app versions are not assumed to
match the xrepl release. Pre-existing untracked docs/design is out of scope.
Cayrn source is main 04b4913; standalone agent source is 1b04c15.
The [baseline](artifacts/07-refocus-baseline.json) records full hashes/status.

The original Project10 formulation was untracked, so Git history alone could not
preserve it. Before refocus all 11 original files were copied byte-for-byte to
[the original packet](artifacts/formulation-v1/project-plan.md), including its
ledger, AGENTS, artifacts and checker. Old criteria P10-01..09 are preserved there
and continue under Cayrn Project01; they are not retroactively accepted or
reissued as migration work. Current migration rows start at P10-10.
The original artifacts/01..06, README and checker remain byte-identical historical
inputs at their original paths. Their old status text and live-byte checker are
historical, not proof of the new plan. Cayrn's transfer checker resolves this
preserved snapshot when checking original source bytes after refocus.

## Workflow and authority

Default Two-Contributor Workflow; no CRC, delegation or Expedited Mode inferred
from Project09 or prior prototype work. Sofie prepares design/first slices with
the Operator. A future CC implements; a real independent reviewer/Operator gates
acceptance. Same-context self-review is attested. No automatic source or planning
commits/pushes. Prompts are prepared for the next implementation turn, not
executed now. Once issued they are immutable; follow-up prompts are numbered.
Closing/review files are created only after actual work/review.

All xrepl source implementation and integration targets release/0.2.x. Planning
stays in the existing orphan worktree. Native predecessor import must retain
source revision, license, file identities and transformation map; a future
explicitly authorized history/subtree merge may augment that provenance. Do not
silently merge unrelated history or retire the predecessor checkout.

## Definition of done

- A cleanly separated native agent is built/startable/testable in this repository
  and implemented in LFE, with known existing contracts preserved through import
  and conversion and deliberate fixes independently visible.
- Native resource budgets and result/output handling support sustained sessions
  without the 256-operation cliff or a large-result context crash; strict stale-
  identity checks, ACK boundary, late attribution and close barriers remain.
- Real xrepl sessions use Cayrn as authoritative identity/admission/history owner;
  discovery, names, metadata, selection, attach/detach and lifecycle are wired.
- LFE development features have explicit supported equivalents: bindings,
  functions/macros, result/history variables, compile/load helpers, introspection,
  history data/privacy, errors and supported multiline/multiform payloads.
- Program input interoperates with the shared correlated-input contract and its
  multi-client, cancellation/close, EOF and secret-data rules.
- Pluggable shells, switching, story state/save/resume and graphics payloads keep
  a tested path or an explicitly approved compatibility disposition.
- Existing clients/transports and stored sessions have explicit compatibility/
  conversion/retirement decisions; transcript replay never masquerades as heap
  restoration. Old APIs are not removed simply because the prototype bypasses them.
- Startup/ownership/configuration, reproducible installation and package/API
  versions support a real integrated core candidate without sibling path deps.
- Every Project09 finding is mapped to repaired, replaced-and-proven, retained
  with a fix owner, or explicitly deferred with a gate/re-entry condition. Do not
  repair obsolete code only to discard it or assume replacement fixes a finding.
- Arc/project composition, evidence limits and independent/Operator gates are
  explicit; later UX and public publication remain separate.

## Arc roadmap

Only Arc01 and its first slice are deep-planned now. Each later arc lands a
usable vertical capability with tests/docs; detailed designs/prompts follow
actual upstream results. A held contract is resolved before dependent work.

| Arc | Useful outcome and delivery home | Actual prerequisites | State |
| --- | --- | --- | --- |
| [Arc01 — integrated native agent](arc01-integrated-native-agent/arc-plan.md) | Existing agent runs from apps/cayrn_lfe, independently startable; then an LFE implementation preserves behavior | Pinned standalone source and current xrepl/Cayrn interfaces; no whole Cayrn hardening prerequisite | First import slice prepared |
| Arc02 — sustainable native evaluation | Native resource retirement/fencing and safe size-limited previews/output support long sessions | Arc01; Cayrn C-RESOURCE for native resource contract; existing bounded wire for size-safe native fixes | Roadmap only |
| Arc03 — Cayrn-backed session and LFE services | Cayrn authority for catalog/names/metadata/lifecycle plus supported LFE developer helpers and history semantics | Bounded Cayrn administration APIs and Arc02 runtime; Project09/source contracts | Roadmap only |
| Arc04 — input and shell services | Correlated program input, multiline/multiform payloads and shell switching preserve session identity/state ownership | Shared input contract; Arc03 semantic services; native hooks | Roadmap only |
| Arc05 — application and legacy compatibility | Story/save/resume/graphics path plus explicit old transport/client and snapshot compatibility, with obsolete infrastructure retired after proof | Earlier core paths and supported-feature map; bounded compatibility/security decisions | Roadmap only |
| Arc06 — operable core candidate | Owned startup/readiness/config, install/package compatibility and clean-environment system acceptance | Cayrn operational/package contracts and earlier xrepl composition | Roadmap only; UX/release gate separate |

Session names/data, input, error classifications and output correctness are core
work. Prompt colors, friendly displays and editor interaction polish are not
prerequisites for those core changes. Existing editing behavior is preserved as
a regression control while new UX is deferred.

## Cross-repository dependencies and finding ownership

The canonical paired order is in Cayrn Project02's Cross-repository dependency
order section. C-ERR and X-IMPORT can begin independently. X-IMPORT → X-LFE →
C-AGENT → C-RESOURCE → X-RESOURCE; X-LFE → X-SIZE independently. C-COMPOSE consumes
both native results. Only bounded accepted APIs block their actual consumers;
neither entire project waits for the other's formal project close.

Cayrn owns protocol/journal/common SDK changes. Project10 owns native semantics,
agent configuration, application feature preservation and retirement of legacy
xrepl session/transport infrastructure. Import/conversion do not fix Project09
by declaration. Use its existing implementation map and synthesis; attach each
of its 27 finding IDs to the slice that changes or retires the affected path,
including equivalent regression checks. Mapping is part of affected delivery,
not an excuse for a new audit-only phase. No assessment acceptance is fabricated.

## Deferred backlog

| ID | Item | Owner | Re-entry / gate |
| --- | --- | --- | --- |
| X-UX-01 | Separate usability/UX project: prompt/name/colors, readable client/operation/cursor labels, copyable resume commands, startup flows, output formatting/redraw while editing, persistent terminal resume conveniences, completion/highlighting and editing/history ergonomics | Operator with Sofie preparing the later project | Deferred by explicit Operator direction. Re-enter after core feature/contracts and system composition are accepted and the Operator opens the UX project. Agree its actual scope before planning arcs. No new project number is reserved now. |

History data/privacy, program input and valid multiline payloads stay in this
project's core scope; their presentation/editing ergonomics are the future UX
project. Formal release remains gated on that later UX outcome or an explicit
Operator re-scope, plus package validation and publication approval.

## Version history

- v1.0 — 2026-10-18: original shared four-runtime formulation; preserved unchanged
  in artifacts/formulation-v1. Shared working architecture later moved to Cayrn.
- v2.0 — 2026-10-18: Operator retains Project10's name and sharpens it to the
  xrepl 0.2.x migration, approves in-repo agent/LFE direction, core-first roadmap
  and deferred UX. Prepare Arc01 and first import slice; preserve old gates.

[Planning validation](artifacts/09-planning-validation.md) records source/row/link checks and their limits.

## Operator workflow selection — 2026-10-18

The Operator explicitly selected one collaborator (Sofie) to execute both first
slices, using separate design, implementation and review passes as useful.
These are functional passes by one contributor, not simulated independent
contributors. No subagents/other chats are commissioned. Self-check evidence is
attested. Existing independent/Operator acceptance gates, including historical
Project01/Project09 gates, are preserved; no role-specific verification verdict
will be manufactured. The Operator authorized planning commits and starting the
first slices. Push/publication and later-slice execution are not authorized here.
Prepared cc-prompt.md files remain the canonical implementation contracts under
the existing ledger convention; their names do not imply a separate CC actor.
