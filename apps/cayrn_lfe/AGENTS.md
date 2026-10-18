# Native Cayrn LFE agent

Sofie (she/her) is the assistant. Current authority is xrepl's orphan planning
worktree, project10-shared-repl-architecture, Arc01. This is a reusable,
independently startable OTP application. Rust Cayrn owns durable session policy;
this component owns live LFE contexts, capture and native control only.

Imported from cayrn-lfe 1b04c15ac325731aab68a7491d23e4a9fecaa47a with its license.
The first slice preserves source/test/config/launcher semantics and bytes; the
LFE conversion and resource/size fixes are later work. Do not add legacy xrepl
services to the startup dependency graph. No automatic replay after runtime loss.
Use make build/check here or root make build-agent/check-agent. Keep planning
records in the planning worktree and preserve the standalone predecessor.
Follow root AGENTS.md, OTP guidance and the Operator-selected LFE style guide
when editing language implementation. Self-review is attested, not independent.
Assistant-authored commits require the root planning Codex/Billo AI trailers.
