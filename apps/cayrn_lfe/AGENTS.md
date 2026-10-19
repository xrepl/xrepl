# Native Cayrn LFE agent

Sofie (she/her) is the assistant. Current authority is xrepl's orphan planning
worktree, project10-shared-repl-architecture, Arc02. This is a reusable,
independently startable OTP application. Rust Cayrn owns durable session policy;
this component owns live LFE contexts, capture and native control only.

Imported from cayrn-lfe 1b04c15ac325731aab68a7491d23e4a9fecaa47a with its license.
The first slice preserved pinned source/test bytes. Slice02 converts all five
OTP runtime modules and three native test modules to LFE while preserving
semantics and metadata/launcher identities. Arc02 adds native2 token fencing
and producer-aware capture retirement; Arc02/Slice02 adds native3 node authority
leases/context tickets and removes cumulative identity history. Arc02/Slice03
adds native4 bounded result/error previews and explicit shared truncation reports.
Arc02/Slice04 adds complete captured streams and responsive dual ownership.
Native3 registry state uses private typed records,
exact monitor identities and live physical credits. Its authority-loss-only
abortive port disposal must remain distinct from normal Close/drain/ACK.
X04's NR-02 controls require positive send pressure and exact owned deaths for
both owner failures and listener/registry/app teardown. C06 composed sustained
pressure remains a separate gate; do not infer it from focused native controls.
Keep network sends and arbitrary MFA/conversion out of owner callbacks. Preserve
paused register-before-activation, exact physical root/collector/formatter credit,
persistent owner monitors through unlink, independent send/ACK bits and bounded
64job/68frame state. Collector stream_done precedes same-worker normal DOWN;
context collector job_done and its own worker DOWN can arrive in either order.
No success before every chunk's durable ACK, no false Closed before physical drain,
and no second indefinite terminal flush beyond the five-second close timeout.
The existing app callback helper owns the listen port; listener borrows it across
child restarts. Preserve exact port DOWN and inode/type-guarded path disposal,
startup acquisition rollback and stable absolute path despite evaluated cwd.
Never move endpoint cleanup back into a killable listener/registry child.
Do not add legacy xrepl
services to the startup dependency graph. No automatic replay after runtime loss.
Use make build/check here or root make build-agent/check-agent. Keep planning
records in the planning worktree and preserve the standalone predecessor.
Follow root AGENTS.md, OTP guidance and the Operator-selected LFE style guide
when editing language implementation. Self-review is attested, not independent.
Assistant-authored commits require the root planning Codex/Billo AI trailers.

All native evaluator, I/O, application, resource, preview, stream, ownership and authority cases
must run in make check. The I/O companion suite lists all native test modules
explicitly because Rebar's default
EUnit discovery does not enumerate all LFE test source files. Preserve strict
producer birth/exit/delivery, send/request-count and durable ACK drain witnesses;
a root outcome, empty mailbox or timer cannot authorize natural retirement.
Quiet results wait for exact collector DOWN, and all trace sessions have explicit
ownership/teardown. Keep the 64 live-origin budget distinct from lifetime calls.
Preserve declared
callback/test names and classify LFE compiler-generated exports separately.

The pure cayrn-lfe-preview renderer has a fixed8192 UTF-8 byte/depth32 policy.
Keep bounded short probes, lazy structural traversal, preconversion integer
fences and honest omission propagation. Never substitute whole-term prettyprint
or silently clip captured Output under the value policy. Preserve full saved
environments across large results and prior committed environments on errors.
Native4 requires explicit boolean preview metadata on every Outcome; old1/2/3
reject. The shared public RPC remains1, legacy absent/null report UNKNOWN.
