---
project: project10-shared-repl-architecture
status: active-design-preparation
depends-on: []
blocks: []
related: [project05-rust-frontend, project06-pluggable-shells, project09-quality-assessment, oxur, lykn, fennel, xrepl_protocol, xrepl_term]
---

# Shared Rust REPL architecture

Created 2026-10-18. Author: Sofie, current coordinating/design context.
Status: first research-informed design packet delivered for Operator review;
implementation and independent acceptance remain unperformed.

## Purpose and useful result

Define one Rust-centric REPL infrastructure and protocol usable by Oxur/Rust,
LFE/BEAM, Lykn/JavaScript and Fennel/Lua without imposing one runtime's state,
concurrency, compiler or value model on the others. The first usable result is
a reviewable behavioral contract and a demonstrator specification that can
falsify its guarantees before integrations are committed to it.

The Operator approved the preceding four-step proposal: consolidate the draft;
research reliability; examine all four runtime fits; revise the architecture
and define a small demonstrator. The Operator also reiterated that almost all
infrastructure is Rust and the runtime-language layer is the thinnest layer.
This authorization does not select a codec, storage engine, public project name,
new repository or implementation assignment.

## Home and authority

The Operator selected Project10 after xrepl's Project09 and suggested the
project artifacts directory. Adopt `project10-shared-repl-architecture/` with
`artifacts/` for this shared design/research packet. This records the supporting
artifact-home override. Canonical plan and ledger stay at project root.
No arc/slice execution directories or prompts are opened during this design
preparation. They will be detailed when an implementation assignment is agreed.

Default Two-Contributor Workflow: this Sofie context carries CDC design/planning;
the human Operator owns requirements and scope decisions. No CC is assigned.
Self-checks are attested, not independent acceptance. Project09's special
One-Contributor coordination/delegation and Expedited Mode are separate grants.
The project remains active pending review; no closure or review-role file is
manufactured for this packet.

## Definition of done for the formulation

- Preserve confirmed requirements separately from recommended mechanisms.
- Specify command/event/session identity, durability boundaries, failure behavior,
  close/archive/delete semantics and simultaneous client behavior.
- Establish Rust ownership and a minimal native-agent responsibility boundary.
- Record bounded primary-source research with keep/change/defer decisions.
- Check shared scenarios against all four runtime/compiler architectures,
  including uncertainty and capabilities that require actual experiments.
- Define a small demonstrator with discriminating failure/recovery oracles.
- Record remaining product decisions and deferred migration/implementation work.

The [ledger](ledger.md) holds the review criteria. A design document does not
prove a working distributed system or satisfy future conformance gates.

## Bounded inquiry and stopping rule

Usefulness: detect contradictions in session/replay/durability promises before
choosing implementation dependencies. Consumer: Operator and subsequent Rust/core
and adapter planners. Applicability: the conversational requirements are now
coherent enough to compare with established protocols and runtime boundaries.

The approved effort boundary is the previously proposed chunk: one reliability
research pass and one four-runtime fit pass, ending in this decision packet and
demonstrator definition. The finite question set is admission/deduplication,
ordered replay/fanout, cancellation/control, output completion, close lifecycle,
storage failure, recovery uncertainty and Rust/native ownership. No numerical
time/token/source budget was agreed; do not label an invented number approved.
Stop when each question has a recommendation or explicit unresolved decision and
each runtime has a scenario disposition. Do not extend into benchmarks, a broker
comparison campaign, full sibling audits or an implementation spike. A further
research round requires its own agreed question and boundary.

## Roadmap

| Stage | Useful outcome and destination | Actual prerequisites | State |
| --- | --- | --- | --- |
| Design preparation | Contract, bounded research, runtime-fit checks and demonstrator plan in project artifacts | Conversation requirements and local source/reference inspection | Candidate delivered; Operator review pending |
| Arc01, to be detailed | A working Rust demonstrator proves admission, replay, concurrency and lifecycle behavior | Reviewed contract; chosen repository home and minimal codec/storage decisions | Proposed, no assignment or directory created |
| Subsequent work, to be planned later | Oxur/xrepl migrations and Lykn/Fennel implementations | Demonstrator evidence and runtime-specific integration decisions | Deferred as requested; no detailed migration plan yet |

The eventual shared repository is undecided. This xrepl planning directory is the
current design home, not a decision to make xrepl own the future shared crates.
Project09 is useful input, not a dependency requiring its formal closure before
this architecture discussion can proceed; its findings are not repaired here.

## Current delivery and limits

Start with [the packet index](artifacts/README.md). The initial contract is a
reconstruction from this conversation, not a verbatim saved prior message.
The revised contract is a proposal following the authorized research pass.
Source pins/hashes are in the baseline manifest; reference URLs have retrieval
dates and focused claim descriptions. No builds, runtime experiments, failover,
performance, power-loss tests or independent document review were performed.

## Version history

- v1.0 — 2026-10-18: establish Operator-authorized Project10 and artifact home;
  consolidate requirements, research the reliability model, check four runtimes
  and deliver the proposed contract and demonstrator specification.
