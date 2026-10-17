# Timestamp restoration and recovery

The manifests preserve exact mtime_ns, modes, hashes, original paths and
Darwin-native birthtime_ns. `restore-timestamps.py` uses only Python's standard
library. Default operation verifies without explicit metadata writes; reading
files may update atime. --apply restores snapshot atime/mtime and modes.
--creation adds native creation-time restoration/verification on Darwin; other
platforms explicitly report unsupported creation times. ctime cannot be restored.
The historical branch variant has no original filesystem dates and is excluded
from the old-date restoration set; its provenance is in branch-inventory.json.

From the implementation repository root after creating the planning worktree:

```sh
python3 .worktrees/planning/project08-planning-migration/arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/restore-timestamps.py --root .worktrees/planning --apply --creation
python3 .worktrees/planning/project08-planning-migration/arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/restore-timestamps.py --root .worktrees/planning --creation
```

Expected: 69 files, 27 directories, mismatches=[]; on macOS creation_unsupported=[].
Do this after pulling or adding files: directory edits can change old directory
mtime. New navigation documents retain their real new dates. Four split original
parents have no single canonical destination; their records remain in the manifest.

To recover all 69 files with their original paths into a new empty directory:

```sh
python3 .worktrees/planning/project08-planning-migration/arc01-preserve-and-relocate/slice01-import-planning-corpus/artifacts/restore-timestamps.py --root /private/tmp/xrepl-legacy-recovery --layout original --recover-from .worktrees/planning --apply --creation
```

Expected: 69 files, 31 directories, mismatches=[]. An existing nonempty recovery
root is refused. No source originals, source code or private account state are
modified. Hash/type/path/symlink checks complete before writes. A modified legacy
payload is refused; reconcile intentional edits rather than changing the manifest
just to make a check pass. Original public RUST-CORE-POC.md is retained in source
history; the two excluded DS_Store files are not recovered.

Evidence: import-validation.json records a real fresh-checkout mismatch before
apply, successful restore/verify and original-layout recovery, plus refusal of
changed payload, escaping-path and symlink cases. These are self-checks (attested).
