# Project10 — shared REPL architecture

Planning home: orphan branch `planning`, worktree `.worktrees/planning`, under
`project10-shared-repl-architecture/` in xrepl/xrepl. The Operator authorized
Project10 and project-level `artifacts/` on 2026-10-18. This explicitly overrides
the slice-local supporting-artifact default for this formulation/research packet.
Keep future issued prompts beside their slice plans, never in artifacts.

Rust owns the shared REPL infrastructure, client SDK, terminal, session policy,
durable admission/log/replay and runtime coordination. Native runtime agents
are allowed and should remain thin. Evaluated-language independence is the goal;
implementation-language independence is not.

This is CDC/Operator design preparation under the default Two-Contributor
Workflow. Sofie authors the design and attests her own document checks; no CC
implementation assignment or independent verification has occurred. Project09's
agent delegation and Expedited Mode do not automatically apply here. No runtime
changes, historical closures, commits, publication or new repository creation
are authorized by this packet. Detailed migration planning comes later.

Read project-plan.md and ledger.md, then artifacts/README.md. Existing project
and repository instructions continue to apply. Preserve Project09 and all
historical plans; cite their acceptance limits rather than adopting old prompts.
