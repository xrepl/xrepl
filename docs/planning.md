# Planning workspace

Designs, prompts, ledgers, audits and implementation notes now live on the
separate orphan `planning` branch, checked out at `.worktrees/planning`.
Source, tests, build files, assets and user documentation stay on `main`.
Do not merge these two branches.

## Project index

| Project | Planning directory |
| --- | --- |
| REPL foundations | project01-repl-foundations |
| Terminal visualization | project02-terminal-visualization |
| Emacs integration | project03-emacs-integration |
| REPL remediation | project04-repl-remediation |
| Rust frontend | project05-rust-frontend |
| Pluggable shells | project06-pluggable-shells |
| Story runtime | project07-story-runtime |
| Planning migration | project08-planning-migration |

Start with README.md and the owning project-plan.md in the planning checkout.
Original payloads are preserved at planning import commit094e72b. New
retrospective plans describe imported records and acceptance gaps; they do not
assert that historical work is independently accepted today.

## Set up another checkout

Both local branches are committed. After main and planning are pushed to the
remote, fetch them on the other machine:

```sh
git fetch origin
```

If no local planning branch exists:

```sh
git worktree add -b planning .worktrees/planning origin/planning
```

If the local planning branch already exists and is not checked out elsewhere:

```sh
git worktree add .worktrees/planning planning
git -C .worktrees/planning pull --ff-only origin planning
```

The worktree has its own planning-specific AGENTS.md. Existing local planning
changes need normal reconciliation; never reset them to force setup.

## Restore original edit dates

Git stores content and commit dates, not file/directory filesystem dates. After
creating/updating the planning checkout, run from this implementation repo root:

```sh
python3 .worktrees/planning/project08-planning-migration/arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/restore-timestamps.py --root .worktrees/planning --apply --creation
```

Expected on macOS:69 files,27 directories,mismatches=[],creation_unsupported=[].
The helper guards every payload by hash and restores exact observed edit dates;
native creation times are also restored on Darwin. Other systems explicitly
report unsupported creation fields. ctime remains OS-maintained. New plans have
their new edit dates. The older branch variant has source provenance but no
recoverable original filesystem timestamp.

## Find old paths and recover originals

The complete file map, manifests and restoration guide are in:

```text
.worktrees/planning/project08-planning-migration/arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/
```

Search project-mapping.md for a former docs/design or workbench path.
The helper’s --layout original --recover-from option can reconstruct all69
planning files and31 original directories in a new empty recovery root; see
timestamp-restoration.md. Source commit18ba5b7 also preserves the60 previously
tracked originals. The9 formerly ignored workbench files are recoverable from
their committed planning import, not from old source history.

Historical support scripts must run from the implementation checkout because
they derive its Git root and need its source/build context. Read their historical
contracts first; relocation does not authorize rerunning them or prove runtime
acceptance. Existing inline historical references remain unchanged and map back
to their pinned original context.
