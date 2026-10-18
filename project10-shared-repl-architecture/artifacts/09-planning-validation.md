# Planning validation — 2026-10-18

Author: Sofie, current planning context. Evidence strength: attested document,
source-identity and preservation checks; no runtime implementation or independent
acceptance is claimed. Both prompts remain prepared and undispatched.

## Checked population and results

- 21 current Markdown files across both new/refocused project packets, 16 local
  Markdown links, 2 Bash command blocks and 52 ledger rows: zero structural/link,
  shell syntax, duplicate-ID or premature-completion errors. Historical original
  formulation prose is excluded from the current-authority population.
- All 11 original Project10 packet files match the pre-refocus SHA-256 map in
  artifacts/07-refocus-baseline.json at the xrepl project. Original artifact files
  at their old paths remain unchanged; current AGENTS/plan/ledger have snapshot
  counterparts. No hashes were refreshed to make an altered original pass.
- Cayrn Project01's existing check-packet.py --check-origin
  --check-source-baseline: 36 Markdown files, 73 links, 21 pinned source blobs,
  11 origin files; zero errors. It explicitly reports the three refocused source
  paths resolved via their preserved originals. Four live source/planning paths
  differ from their old historical pin; that is reported as drift, not rewritten.
- A temporary isolated copy passed with intact origin snapshots. Corrupting its
  preserved project-plan.md caused exactly one targeted origin-byte error through
  that same checker. Real originals were untouched.
- git diff --check passed in both planning worktrees. Source remains Cayrn main
  04b4913, xrepl release/0.2.x at 571def5 plus the pre-existing authorized 0.2.0
  application-version edit, and native predecessor 1b04c15. Existing xrepl
  docs/design remains untracked and untouched. No runtime/source implementation
  or build/test gate was executed during this planning-only round.

## Reproduction routes and limits

From Cayrn, rerun the existing historical check:

```text
python3 .worktrees/planning/project01-shared-repl-architecture/artifacts/check-packet.py --check-origin --check-source-baseline
```

For snapshot identity, load historical_formulation.files from xrepl's
artifacts/07-refocus-baseline.json and compare each relative file under
artifacts/formulation-v1 using hashlib.sha256. Current open sets are exactly
project-plan.md/design.md/ledger.md, first arc arc-plan.md/ledger.md, and first
slice slice-plan.md/ledger.md/cc-prompt.md in each project. Both project AGENTS
and the two shared planning roots supply scope/navigation. Inspect actual row
semantics, dependency order and reading obligations in addition to structural
checks; file/row counts do not establish good design or runtime acceptance.

The per-slice required-reading manifests, implementations and meaningful test
oracles remain future execution/review obligations. Existing Project01/Project09
review gaps and the original historical checker's old live-source assumptions
remain explicit rather than being silently converted to passed new gates.
