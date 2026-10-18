# xrepl planning

Canonical planning lives on the orphan `planning` branch in `.worktrees/planning`.
Implementation and user documentation remain on `main`. These branches must not
be merged into one another.

| Project | Scope | Status |
| --- | --- | --- |
| [project01-repl-foundations](project01-repl-foundations/project-plan.md) | repl foundations | imported-unreconciled |
| [project02-terminal-visualization](project02-terminal-visualization/project-plan.md) | terminal visualization | imported-unreconciled |
| [project03-emacs-integration](project03-emacs-integration/project-plan.md) | emacs integration | imported-unreconciled |
| [project04-repl-remediation](project04-repl-remediation/project-plan.md) | repl remediation | imported-unreconciled |
| [project05-rust-frontend](project05-rust-frontend/project-plan.md) | rust frontend | imported-unreconciled |
| [project06-pluggable-shells](project06-pluggable-shells/project-plan.md) | pluggable shells | imported-unreconciled |
| [project07-story-runtime](project07-story-runtime/project-plan.md) | story runtime | imported-unreconciled |
| [project08-planning-migration](project08-planning-migration/project-plan.md) | Preserve and relocate the planning corpus | implemented; human acceptance pending |
| [project09-quality-assessment](project09-quality-assessment/project-plan.md) | Assess plans, implementation and LFE/Rust code quality | active; setup complete, assessment pending |

Project01–07 plans are new retrospective navigation, not new implementation
acceptance. Original prompts, ledgers, addenda, failed attempts and verification
records remain byte-preserved. Follow their current navigation notes and explicit
missing evidence; do not execute an old prompt automatically.

See the [complete original-to-canonical map](project08-planning-migration/arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/project-mapping.md)
and [timestamp restoration/recovery](project08-planning-migration/arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/timestamp-restoration.md).
The exact preserved payload import is commit `094e72b`; source provenance is
`18ba5b7`. Project08 uses One-Contributor with scoped read-only lookup assistants;
all implementation checks are attested, not independently accepted.

Initial source cutover: `9d7956b`; follow-up cleanup/PoC relocation: `02fc239`. [Migration implementation report](project08-planning-migration/closing-report.md) records all checks and remaining acceptance/publication state.

The [Rust PoC overview](project05-rust-frontend/arc02-event-core/slice01-infrastructure-poc/artifacts/RUST-CORE-POC.md) now lives with its Project05 implementation notes. Its dates are covered by the supplemental relocation manifest; source legacy containers are removed.
