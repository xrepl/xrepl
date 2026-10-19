# xrepl/Cayrn boundaries and native-agent integration

2026-10-18. The Operator agreed to co-locate the agent in xrepl and convert its
Erlang implementation to LFE while preserving the useful greenfield boundary.
This document specifies the first import and the ownership constraints for later
work. It does not claim the import/translation has run.

## Architecture and authority

| Component | Repository/home | Owns |
| --- | --- | --- |
| Shared Rust protocol/core/host/SDK | Cayrn | Authoritative admission/IDs, session lifecycle, durable journal/replay, generic runtime contract |
| Native cayrn_lfe OTP app | xrepl apps/cayrn_lfe | Opaque LFE environments, parse/eval, native I/O capture and runtime control hooks |
| Rust xrepl terminal/application | xrepl crates/ | Terminal, app features, consuming shared SDK contracts |
| Legacy xrepl OTP/session/transport services | Existing xrepl src/ during migration | Only retained compatibility paths until explicit replacement/retirement is demonstrated |

No second durable session authority is created in the native app. Application
history/snapshots are not silently substituted for Cayrn transcript guarantees.
Story/UI services do not become required native-agent dependencies. The native
app continues to start with kernel, stdlib and lfe only; its app name remains
cayrn_lfe and it is not auto-started just because legacy xrepl starts.

## First slice: import layout and usable entrypoints

Keep legacy root src/ and its application in place. Import the standalone
component under apps/cayrn_lfe with its own src/, test/, bin/, Makefile,
rebar.config/rebar.lock, license and README. Rebar's documented default
project_app_dirs already includes apps/* and .; an explicit equivalent config
may make that boundary visible but must not exclude the existing root app.
See [Rebar3 base configuration](https://rebar3.org/docs/configuration/configuration/)
Directories and application-local configuration sections (checked 2026-10-18).

The component's own Makefile/build remains independently invokable from
apps/cayrn_lfe. Root make build-agent/check-agent delegate there. Root
bin/cayrn-lfe is a tiny exec wrapper for the component's existing launcher. The
launcher uses the component's _build/default/lib/*/ebin and starts only cayrn_lfe;
root build discovery may compile both project apps, but independent agent startup
must not start legacy xrepl, Ranch or its old protocol/term applications.

Existing Cayrn Rust harnesses accept CAYRN_LFE_DIR. Set that variable explicitly
to /Users/oubiwann/lab/lfe/xrepl/xrepl/apps/cayrn_lfe to prove the new component.
The full native/PTY cases must run against that path; passing a suite against
the standalone predecessor is not migrated-agent evidence. Cayrn's later
C-AGENT slice changes common default build/check profile wiring, after both import
and LFE conversion exist. There is no first-slice Cayrn source mutation.

## Provenance and change separation

Source revision: standalone cayrn-lfe 1b04c15ac325731aab68a7491d23e4a9fecaa47a.
Import every tracked file except its AGENTS.md, which is tied to the old project
home. Preserve source/test bytes and executable launcher mode. Native README may
be adapted for new paths; author a component AGENTS.md with current authority.
The baseline JSON lists all source hashes. Return an import map with source/dest
paths, original/result digest and reason for each intentional document/wrapper
change. Keep LICENSE. No nested .git, _build, cache, local state or worktree import.

The predecessor repository stays intact. No deletion/archive or implicit Git
history merge is authorized by the import slice. Source commit+hash provenance
is mandatory; an explicitly approved history import can be a separate change.
The source/test import and the LFE conversion are separate reviewable commits
when commits are requested. Later hardening changes must not be hidden in either.

## Conversion and later hardening

Arc01's second slice converts five Erlang implementation modules and all three native
test modules (including the startup-boundary test added by the import) to idiomatic LFE, preserving the existing LFE evaluator. OTP .app.src
and rebar files remain ordinary Erlang term metadata. Follow the Operator's LFE
style guide and OTP semantics; resolved module-name/callback mappings belong in
that slice's design before assignment. It must preserve evaluator monitoring,
independent command/event paths, capture ACKs, seal order, context isolation,
identity guards and the published capabilities under the same real tests.

The existing 256-operation budget and oversized-value assertion are known
hardening inputs, not desirable long-term behavior. Their intentional fixes live
in Arc02, coordinated with Cayrn's resource contract. Keep those obligations
visible if translation reveals a correctness issue; do not silently redesign
semantics while claiming a behavior-preserving port.


Output hardening must retain the complete supported captured stream as ordered,
bounded chunks. Explicitly bounded/truncated **value previews** do not authorize
silent truncation of output or pruning a live session's transcript. Capture
failure must not be acknowledged as durable output.


## Proposed operation-resource design —2026-10-18

The previous reserved operation-resource decision is now specified for the next
prepared pair in /Users/oubiwann/lab/oxur/cayrn/.worktrees/planning/project02-core-hardening/arc01-native-session-hardening/slice03-journal-backed-native-identities/artifacts/native-resource-contract.md. This is a proposed native2 design for Operator review,
not an implemented result. It uses durable admission tokens/indexed correlation
in Rust and native producer/drain proofs; no durable authority migrates to LFE.
Only that per-operation decision is replaced here. Node context/authority
retirement, size-safe result/output and later input decisions retain their named
owners/gates. See current project resource-planning section for sequence and
compatibility; no original complete-transcript/failure requirement is relaxed.
