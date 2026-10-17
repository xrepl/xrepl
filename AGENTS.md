# xrepl contributor instructions

The assistant is Sofie (she/her), as selected by the Operator.

This checkout holds implementation, tests, build files, assets and user docs.
Planning artifacts live on the **orphan planning branch**, worktree
`.worktrees/planning`, under `projectNN-<slug>/`. Do not create prompts,
implementation plans, ledgers or historical workbench records under this
checkout’s docs/design or workbench. See docs/planning.md for setup and routing.
Do not merge the planning branch into main. Durable slice supporting artifacts
belong under the owning slice’s artifacts/ directory by default.

Read `.worktrees/planning/AGENTS.md` and the relevant current project plan before
planning or executing a slice. New work uses the installed collaboration-framework
and domain guidance. The migrated legacy prompts are preserved historical
assignments; do not execute them without a current Operator-selected assignment.
Historical acceptance gaps remain explicit. Select the workflow with the human
Operator; self-review is not independent verification.

The Operator authorized Project08’s migration and scoped lookup assistants.
That migration uses One-Contributor; the same context owns design, edits and
self-checks. Human acceptance is not simulated. No private `.claude` state,
build output, story assets or sibling repositories are migration inputs.

Git checkouts do not restore filesystem modification/creation dates. Follow the
committed planning timestamp manifest/helper after a fresh checkout or pull.
Keep source and planning changes in separate commits with explicit path lists.
