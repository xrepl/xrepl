# Initial contract reconstructed from the conversation

Recorded 2026-10-18. This is a reconstruction of the pre-research discussion,
not a verbatim transcript or a claim that this file existed before browsing.
Preserve this starting point; revisions belong in the architecture draft.

## Explicit requirements

R01. Rust implements the shared core, clients and REPL infrastructure. The
language running inside a REPL is the agnostic dimension.

R02. Native runtime agents are allowed. Their language-specific responsibility
should be thin. A mandatory extra public Rust proxy in front of every native
endpoint has not been selected.

R03. Support Oxur/Rust, LFE/BEAM, Lykn/JavaScript and Fennel/Lua. Compiler and
runtime integration may differ substantially.

R04. Sessions survive ordinary terminal/editor disconnects and client crashes
while their live runtime state survives. Reconnect uses stable session identity.

R05. Simultaneous terminal/editor attachments can both submit evaluations and
observe submissions, results and output in the same session.

R06. Retain the complete transcript for the session lifetime, spooling to disk
as needed. Reconnecting clients catch up without executing code again.

R07. Develop migration plans for Oxur/xrepl and implementation plans for
Lykn/Fennel later, after substantial general formulation and research.

R08. Perform bounded research after a coherent first pass. The Operator has now
authorized the consolidation/research/runtime-fit/demonstrator-definition chunk.

## First-pass recommendations accepted as a draft basis

The Operator called the principles and supported operations a good basis for a
first-draft plan. This is not approval of every implementation detail below.

- One authority and ordered admission queue per session; serialize normal evals.
- Independent connection, session and runtime lifecycles.
- Ordered session event log, stable request IDs, independent client cursors.
- Durable admission before acceptance; durable results before publication.
- Replay records, never automatically re-execute uncertain arbitrary code.
- Distinguish client/network failure from execution-state loss and storage loss.
- On runtime loss, retain records and identify state loss; explicit new generation.
- Control operations remain responsive while evaluation runs.
- Cancellation requests do not themselves prove code stopped or effects rolled back.
- Close rejects new work, cancels queued work, resolves active work, releases
  owned resources and archives a sealed transcript. Delete is separate.
- A shared-runtime force kill cannot silently destroy other sessions.
- Checkpoint restoration is an optional capability; replay is observation.
- No automatic multi-host authority failover in the first guarantee set.

## Open before research

What does complete transcript mean at the producer-to-journal crash boundary?
How do catch-up and live observation avoid a gap? How long must deduplication
records remain? What ends output from background work? Who answers stdin with
two attachments? Where does the common Rust owner live when a native runtime
serves the public protocol? What happens when graceful close cannot quiesce the
owned runtime resources? These motivate the next record.
