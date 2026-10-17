---
project: project08-planning-migration
status: active
depends-on: []
blocks: [canonical-planning-cutover]
related: [project01-repl-foundations, project02-terminal-visualization, project03-emacs-integration, project04-repl-remediation, project05-rust-frontend, project06-pluggable-shells, project07-story-runtime]
---

# Preserve and migrate xrepl planning

Prepared 2026-10-17 under collaboration-framework 2.7.2.

## Outcome and authority

Make xrepl's prompts, designs, audits, implementation notes and historical
acceptance evidence usable from one canonical orphan planning worktree, with
content provenance and original modification times preserved across machines.

The Operator requested this plan, selected `.worktrees/planning`, authorized a
new highest-numbered migration project after mapping all existing material,
and selected One-Contributor. Sofie handles design, implementation and
self-review in one context. No additional contributor contexts or fictional
handoffs are required. This turn prepares the plan and planning substrate;
relocation and source cleanup wait for the Operator's direction to execute it.
The proposed historical names and file mapping remain reviewable choices.

The new ledgers track migration claims. Self-checks are attested; the Operator
owns approval of the plan, source cleanup and final acceptance. Existing
independent-review requirements in old work remain pending where recorded;
this migration neither reopens nor accepts implementation work.

## Baseline and coverage

- Source checkout: `/Users/oubiwann/lab/lfe/xrepl/xrepl`, currently on
  `release/0.1.x` at `18ba5b787d5b77f17050127569e3804585b1f772`.
- Local `main` fast-forwarded from `001caacc14c8e4c8aec30c845713b8f78d6b96ce`
  to that same tip after proving 0 main-only / 34 release-only commits.
  Ref-only update preserved working files and modification times.
- 60 tracked planning files under `docs/design/0.1.0/`, 9 ignored Markdown
  records under `workbench/`, 1 retained public `RUST-CORE-POC.md`, and 2
  excluded `.DS_Store` files: 72 observed files in total, plus 31 directories.
- All local heads and remote tips were compared. Live origin/macpro head
  advertisements were checked; all their tips are contained in local main.
  Arc4's three distinct commits are patch-equivalent to main. Its one older
  tip plan variant will be imported with attribution. No extra project found.
- Mapping: [project-mapping.md](arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/project-mapping.md).
- Raw metadata: [source-inventory.json](arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/source-inventory.json).
- Branch evidence: [branch-inventory.json](arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/branch-inventory.json).

The inventory is an observed baseline, not an execution freeze. Before copying,
compare source HEAD, refs, file hashes, modes, mtimes, directory membership and
new ignored records against it. Explain drift and append a new dated snapshot;
keep this original snapshot. Do not infer absence of ignored work from Git status.

## Proposed historical projects

| ID | Home | Working-tree planning files |
| --- | --- | ---: |
| 01 | `project01-repl-foundations` — architecture and original arcs 1–3 | 9 |
| 02 | `project02-terminal-visualization` — terminal graphics and richer views | 4 |
| 03 | `project03-emacs-integration` — Emacs client design | 1 |
| 04 | `project04-repl-remediation` — BEAM audit, program plan and arcs 4–5 | 19 |
| 05 | `project05-rust-frontend` — Rust architecture and event-core PoC | 5 |
| 06 | `project06-pluggable-shells` — multishell seam and arc 6 | 10 |
| 07 | `project07-story-runtime` — xs engine and xs-shell, arcs 7–8 | 21 |
| 08 | `project08-planning-migration` — this migration | new |

Project04 also receives one branch variant. Project05 relates to the retained
public PoC document. Directory numbers are identifiers, not dependency order.
New metadata records actual relationships: foundations support remediation,
multishell and clients; story integration consumes multishell and terminal
rendering; the remediation program and Rust architecture share lineage.
Do not turn those descriptive relationships into accepted dependency gates
without assessing the bounded result a future implementation actually needs.

The program plan's intended heavy-remediation Arc06 and Rust Arc07 are not the
later multishell Arc6 and xs-engine Arc7. Keep their distinct lineage and all
L-01–L-21 / G-NN / D-NN references. Do not silently drop the old deferred work
or re-label it complete. External protocol/typed/GROUND materials are references,
not newly authorized import scope. Unavailable references stay explicit.

## Preservation and document rules

1. Import all 69 planning payloads byte-for-byte; preserve their basenames,
   executable modes, addenda, failed/retried evidence, historical wording and
   unresolved flags. Import Arc4's older plan as an attributed variant, never
   as a replacement for the newer main plan. Keep original refs and commits.
2. Source history is retained. The new orphan branch cannot preserve source
   commit ancestry through a normal move: manifests record original path,
   blob hash, source commit and, for branch variants, ref and provenance.
   The 9 ignored workbench files gain version control during import.
3. Zero-pad mapped arc/slice directory IDs; retain original numeric identity.
   Special acceptance/diagnostic directories receive mapped IDs, not invented
   historical execution status. Record this one-time relocation explicitly.
4. Preserve `cc-prompt-2.md`, `slice-doc.md` and historical verification names.
   Legacy arc-root prompts and support scripts retain their relative placement
   as documented import exceptions. A new companion plan records anomalies and
   directs future work to the next unused canonical prompt name when applicable.
5. Add present-day project/arc/slice navigation and ledgers only where needed
   for current planning. Label retrospective wrappers `imported-unreconciled`,
   cite the originals and state missing evidence. Existing `arc-plan.md` and
   `ledger.md` payloads are not overwritten to make them conform. Where a
   historical plan already owns the canonical filename, a companion
   `migration-notes.md` records current navigation and known gaps.
6. Historical inline paths remain unchanged. Resolve them through the complete
   map and pinned source history. New/current instructions use canonical links.
   Inventory link and command-path issues; distinguish moved targets, already
   missing targets, source paths, external repositories and historical examples.
7. `RUST-CORE-POC.md`, README, runtime code, tests, archive/assets and build
   files remain deliverables in the implementation checkout. At cutover, update
   user-facing references to moved notes where needed; changed user docs get
   honest new edit dates, with their old versions retained in Git.

## Timestamp contract

Capture and retain original paths, type, content hash, mode, size and nanosecond
mtime before mutations. Keep observed atime, birth/creation time and ctime too,
with their provenance and precision. The existing snapshot has exact Python
`st_mtime_ns`; its birthtime is an observed floating-point seconds value, not a
claim of nanosecond precision. A native metadata read should augment creation
precision before the actual import if available.

For unchanged legacy payloads, restore exact recorded mtime after copy, review
and all reads/checks that may affect metadata. Restore one-to-one arc/slice
directory mtimes deepest-first after adding wrappers and all other child writes.
Keep directory mode and creation metadata when the host supports it. New
project/grouping directories and new plans have new dates.

Four old grouping directories (`docs/`, `docs/design/`, `docs/design/0.1.0/`,
`workbench/`) split across projects and have no single canonical destination.
Preserve their metadata in the manifest and support original-layout recovery;
do not assign one historical parent's date arbitrarily to several new projects.

mtime preservation is the acceptance requirement for last edits. Attempt
creation-time restoration with the platform API and report exact precision or
unsupported fields. ctime is OS-maintained and cannot be restored as an old
edit time; retain it as provenance only. atime is the observed snapshot value
and may already reflect this inspection. Do not describe these fields as
universally preserved if the host cannot restore them.

Git stores neither file nor directory filesystem timestamps. Commit the
manifest and a bounded restoration helper, with documented canonical and
original-layout modes, hash-before-write guards, explicit root selection and
read-only verification. It must refuse modified payloads, avoid source/private
state, restore directory times last, and report filesystem precision limits.
A clean clone/worktree exercise in temporary storage proves portability for
mtime; ordinary Git checkout alone does not. The helper is part of Slice01's
delivery under its `artifacts/`, not implemented during this planning turn.

A branch-only document has no recoverable original filesystem mtime in Git.
For the Arc4 variant retain the last path-changing commit time as labelled
commit-derived metadata; never call it the original last-edit timestamp.
New migration commits and documents use today's dates. Existing commit dates
and source history are not rewritten.

## Roadmap

One arc: [arc01-preserve-and-relocate](arc01-preserve-and-relocate/arc-plan.md).

| Slice | Usable delivery | Preconditions and next consumer |
| --- | --- | --- |
| 01 — Import planning corpus | Versioned, byte-preserved canonical corpus with project navigation, metadata, branch variant and timestamp restoration procedure/helper | Operator accepts mapping; refresh baseline. Source originals stay available. Slice02 consumes the recorded import commit and successful preservation receipts. |
| 02 — Cut over source navigation | Main points at canonical planning; migrated originals are removed only after durable import checks; another machine can fetch and restore planning | Slice01 deliverable passes its rows; Operator directs cleanup. Source removal commit names exact paths and the import commit. Final source/planning composition is checked and reported. |

The first useful increment is a usable planning corpus while source still has
recovery copies. It is a controlled import stage, not permission for two
competing long-term authorities. Source cutover completes the migration.
Each slice includes its own checks. There is no separate generic validation arc.
Detailed Slice02 planning is written when the import is ready.

## Commit, recovery and publication sequence

1. Commit this new plan on orphan `planning` at the actual current date.
2. During Slice01, copy and verify originals before source removals. Commit
   payload import, mapping and metadata on `planning`, with source pins in the
   message. Prefer an exact import commit separate from new wrapper/tooling
   changes so the preserved bytes are easy to review.
3. After final writes, restore/verify legacy mtimes using the committed manifest.
   Record content, mode, timestamp and reference receipts in the slice artifacts.
4. Slice02 records the canonical planning import commit. With the Operator's
   execution direction, remove only the 60 mapped tracked source files using
   explicit paths; remove the 9 ignored originals only after hash equality and
   durable versioned recovery are established. Leave unrelated local artifacts.
   Update `.gitignore` with `/.worktrees/`, source planning guidance and user-doc
   pointers. Keep source and planning commits separate; do not merge the orphan
   planning branch into main or merge old feature branches just to collect docs.
5. Publication is a later explicit operation: push source and `planning` when
   directed. Existing remotes/feature refs remain intact. On another machine,
   fetch `planning`, create its worktree and run the recorded restoration helper.
   Prove this procedure locally with a temporary fresh clone before hand-back.
6. Recovery before source cleanup: discard/rebuild only the explicit imports;
   originals remain. Recovery after cleanup: use the recorded planning import
   commit/manifest for all 69 payloads; source commit `18ba5b7` recovers the 60
   tracked originals. Ignored workbench originals require the planning import.

## Definition of done

The sibling [ledger](ledger.md) is the acceptance contract. At project scale,
demonstrate complete 69+1 payload coverage, no source-scope changes beyond the
approved routing/removal, exact mtime restoration for unchanged payloads and
mapped directories, honest timestamp limitations, retrievable branch/source
provenance, usable current navigation and a fresh-machine recovery procedure.
Preserve historical statuses and outstanding review requirements. The Operator
accepts the completed migration after the self-check report.

## Current status and next action

Planning substrate and proposed map prepared. No legacy file has moved or been
edited. No migration helper has been written or run; no import, source cleanup,
product tests or push has occurred. Local main fast-forward is complete.
Next action: Operator reviews the mapping and directs the migration when ready.

## Version history

- v1.0 — 2026-10-17: initial plan and reserved seven-project map. Expanded the
  inventory during planning to cover feature branches and live remote tips at
  the Operator's request; seven historical homes still suffice. Recorded the
  authorized main fast-forward, filesystem preservation limits, and the
  One-Contributor workflow. This is a new plan, not a historical acceptance.

## Execution authorization — v1.1 (2026-10-17)

The Operator approved the complete plan and all moves, permitted well-scoped
subagents and optionally additional contributor workflows. Retain the existing
One-Contributor workflow with read-only lookup assistants; the Operator remains
the acceptance authority. Sofie owns implementation and self-review. Lookup
returns are evidence inputs, not independent acceptance. No role substitution
or simulated human approval is claimed. All migration/cleanup steps are now
authorized; the earlier preparation-only hold is superseded. Publishing remains
a separately directed operation.

Before mutation, all 72 original file hashes, file modes and mtimes, all 31
directory modes and mtimes, and ignored-file membership matched the initial
manifest. Main and release still agree at 18ba5b7. Creation metadata will be
augmented through Darwin's native timestamp API before copying.

Reference lookup identified routing-only comments in Cargo.toml and
test/xrepl-shell-pluggability-spike-tests.lfe. Include those two explicit files
in source cutover solely to repair moved/pre-existing stale documentation
pointers; no code, test assertion, dependency or build behavior changes.

v1.1 records the Operator's execution/delegation permission, the unchanged
baseline, and the bounded routing-comment allowance surfaced by Slice01.
