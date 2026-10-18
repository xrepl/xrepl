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

## Language guidance

This is an LFE/OTP and Rust project. Read both references when work crosses
that boundary:

- **LFE:** `~/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md`, the
  LFE Chineual's consolidated AI style guide, is the Operator-selected interim
  reference while the dedicated LFE guidelines skill is unfinished. Expand
  `~` on the execution host and read the actual file.
- **Rust:** load the installed `rust-guidelines/SKILL.md`, starting with
  `guides/11-anti-patterns.md` and following its topic-specific loading rules.

Match established project conventions when the LFE guide permits judgment.
Distinguish style preferences from correctness and runtime reliability defects.
If a reference is unavailable, report the missing path; do not silently invent
a substitute. Project09 records the reference revisions used for assessment.

## Quality assessment

The Operator approved `project09-quality-assessment` on 2026-10-17. Its
Operator-defined One-Contributor coordination keeps CDC/CRC responsibilities
with Sofie and permits well-prompted CC agents at her discretion. This extends
the framework's strict single-context definition; record actual authors and
reviewers rather than simulating independence. The Operator owns final acceptance.
Expedited Mode is enabled: commit reviewable changes with explicit path lists,
keep source/planning commits separate, and advance within scope when required
review and acceptance gates permit. Mode changes do not weaken validation.
Read its planning `AGENTS.md` and `project-plan.md` before assessment work.
The assessment covers LFE and Rust, preserves historical records and leaves
the separate distributed, language-agnostic REPL architecture work untouched.
Assessment findings do not authorize runtime fixes or historical acceptance.

## Migration provenance

The Operator authorized Project08’s migration and scoped lookup assistants.
That migration uses One-Contributor; the same context owns design, edits and
self-checks. Human acceptance is not simulated. No private `.claude` state,
build output, story assets or sibling repositories are migration inputs.

Git checkouts do not restore filesystem modification/creation dates. Follow the
committed planning timestamp manifest/helper after a fresh checkout or pull.
Keep source and planning changes in separate commits with explicit path lists.

## Cayrn first-consumer prototype

The Operator authorized all three Cayrn native-agent/LFE integration increments
on 2026-10-18, including this Rust terminal consumer. The cross-repository source
of truth is /Users/oubiwann/lab/oxur/cayrn/.worktrees/planning/
project01-shared-repl-architecture/arc02-native-agent-integration/.
Use that current plan and slice returns; independent acceptance remains pending.
This is separate from Project09 assessment authority. Preserve existing native
LFE shells and the IF mock mode, and leave pre-existing docs/design untouched.
The reusable agent lives in /Users/oubiwann/lab/lfe/cayrn-lfe and does not depend
on xrepl. Rust SDK dependencies currently use the sibling Cayrn checkout.
