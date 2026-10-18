# Packet validation — 2026-10-18

Author/checker: Sofie, same context that authored this packet. Evidence is
attested. No independent reviewer, implementation or runtime validation.

## Reproduce document checks

From the project root:

```sh
python3 artifacts/check-packet.py
```

The script checks local Markdown targets, whitespace/fences, named requirement/
scenario/oracle presence and the selected source hashes in the baseline. It
checks source bytes, not complete source-reading coverage or runtime behavior.
External URLs were inspected during research; the script does not fetch them.
Named-topic presence is structural, not proof of semantic adequacy.

Installed-packet check passed: 9 Markdown files, 28 local links and 21 selected
source/planning file hashes, plus the Operator LFE reference hash; zero reported
errors. Requirement R01–R08, scenario S01–S09 and oracle T01–T13 presence checks
passed. JSON baseline parsing passed. Git reports only the new Project10 directory
in the planning worktree; implementation main remains at the refreshed audit pin
with only the pre-existing untracked `docs/design/` directory.

The initial extra `git diff --no-index --check /dev/null <file>` wrapper treated
exit 1 as failure. For all 11 new files Git returned 1 with no diagnostic output:
this is the expected no-index difference status, not a whitespace finding. A
corrected interpretation accepts status 0/1 only with empty diagnostic output;
all 11 files pass that check. Plain `git diff --check` also succeeds, but does
not cover untracked files; the packet checker and no-index checks supply that
coverage. This check correction does not waive a whitespace diagnostic.

## Source refresh during the work

Initial local source was `3b5880426494db3b07004dc0cdc762a00de563e2` and the audit
pin object lookup failed. The Operator then pulled main. Rechecks show HEAD
exactly `b865b3137e841269f9218d978817cc243e6b9278`, the Project09 audit baseline;
`git cat-file -t` returns `commit`, and `git diff b865b313... HEAD -- src crates`
is empty. The draft's source manifest records the refreshed baseline and the
earlier failed attempt. No fetch/pull or implementation mutation was performed
by Sofie. Existing untracked source `docs/design/` remains untouched.

## Manual design check

Walked each requirement R01–R08 through the draft, every failure matrix row,
all nine four-runtime scenarios and thirteen proposed conformance oracles.
Kept unknown outcome distinct from failure/cancellation, foreground completion
from output closure, session from runtime/connection, and archive from live
state. Captured proposed secret-input retention exception and remaining decisions.
This is author self-review, not independent validation.

## Explicitly unperformed

No build/test/lint runs on any runtime; no demonstrator implementation; no PTY,
network partition, runtime kill, storage exhaustion, power-loss, checkpoint,
security, performance or physical-deletion experiment. Prior Project09 results
were read as imported evidence and were not rerun or upgraded. No detailed
migration plan, CC handoff, code edit, commit, push or project closure occurred.
