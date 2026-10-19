# Native Cayrn LFE agent

Sofie (she/her) is the assistant. Current authority is xrepl's orphan planning
worktree, project10-shared-repl-architecture, Arc02. This is a reusable,
independently startable OTP application. Rust Cayrn owns durable session policy;
this component owns live LFE contexts, capture and native control only.

Imported from cayrn-lfe 1b04c15ac325731aab68a7491d23e4a9fecaa47a with its license.
The first slice preserved pinned source/test bytes. Slice02 converts all five
OTP runtime modules and three native test modules to LFE while preserving
semantics and metadata/launcher identities. Arc02 adds native2 token fencing
and producer-aware capture retirement; node identity and size hardening remain
later slices. Do not add legacy xrepl
services to the startup dependency graph. No automatic replay after runtime loss.
Use make build/check here or root make build-agent/check-agent. Keep planning
records in the planning worktree and preserve the standalone predecessor.
Follow root AGENTS.md, OTP guidance and the Operator-selected LFE style guide
when editing language implementation. Self-review is attested, not independent.
Assistant-authored commits require the root planning Codex/Billo AI trailers.

All native evaluator, I/O, application and resource cases must be discovered by
make check. The I/O companion suite includes evaluator/application/resource
tests explicitly because Rebar's default
EUnit discovery does not enumerate all LFE test source files. Preserve strict
producer birth/exit/delivery, send/request-count and durable ACK drain witnesses;
a root outcome, empty mailbox or timer cannot authorize natural retirement.
Quiet results wait for exact collector DOWN, and all trace sessions have explicit
ownership/teardown. Keep the 64 live-origin budget distinct from lifetime calls.
Preserve declared
callback/test names and classify LFE compiler-generated exports separately.
