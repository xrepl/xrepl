# Planning checks —2026-10-18

Sofie authored and self-reviewed this packet. These are planning/source identity
checks, not execution of Slice02 or independent acceptance.

## Committed inputs

- Cayrn `9111136fff4aad0241c7acada4f0b664bb87d2de`, codex/core-session-lifecycle.
- xrepl `ea844f5e634dc1ffb2503b7d69c4726164395d82`, release/0.2.x.
- Before commit, every saved candidate file SHA256 matched current bytes (10
  Cayrn, 24 xrepl). Explicit reviewed file lists were committed with both required
  trailers; there were no new implementation edits or new test runs this turn.
- Cayrn source clean; xrepl tracked source clean with pre-existing untracked
  docs/design untouched. No source merge, push or publication.

## Actual checks

Python loaded source-baseline.json and compared every selected file using
hashlib.sha256(Path.read_bytes()), with exact Git HEAD/branch comparison:
10/10 Cayrn and 25/25 xrepl hashes matched (35 selected inputs, no sampling).
Both 8-row ledgers have consecutive unique IDs and remain open. All new relative
Markdown links resolved; original first-slice issued prompt bytes still match
planning HEAD. No new closing/verification records exist for Slice02. Source
`git diff --quiet` and planning `git diff --check` passed. Future execution must
recheck drift and the actual upstream result; hashes identify bytes, not reading.

Framework load: collaboration-framework/project-management wayfinder; scales,
canonical layout, top-down planning and implementation-prompt authoring; selected
one-contributor responsibilities; testing discipline/proportionate proof and
ledger discipline. Source/skill loading used bounded reads; initially truncated
combined guide output was recovered in later ranges rather than treated as full.
The unchanged first-slice tests remain attested prior evidence; committing their
exact bytes does not create a new independent verification or remote CI result.

## Draft review corrections

Before handoff, corrected relative manifest bases so ../ and ../../ resolve from
the slice, preserving source/skill roots explicitly. No issued prompt was edited.
Separated compiler-generated exports from declared API preservation. Kept actual
runtime proof and failed-prerequisite oracles distinct from structural checks.
No new general-purpose validator or investigation was commissioned.

Artifacts: this note and source-baseline.json. Required future execution evidence
is named in the slice plan/prompt; it is not pre-created. Planning changes are
ready for review and remain separate from the approved source commits.

## Conversion-specific author checks and readiness

Read all five native runtime modules, three native test modules and evaluator,
component build/config/metadata and actual root integration hooks at the pin.
Loaded the full 896-line Operator-selected LFE style guide in ranges 1–300,
301–600 and 601–896. Consulted pinned LFE 2.2.0 guide Patterns/Guards, Variable
Binding and Scoping, Map access forms, Types Specifications and own EUnit macro
bridge; OTP BEH-01/02, SUP-04/05 and AP-02/05/06 support the chosen preservation.

Read-only OTP 28.5 module_info queries against built pinned modules established:
8/8 baseline module export inventories agree with 19 declared runtime exports and
7 native test/generator entries; generated module_info/test wrappers are separate.
The existing LFE evaluator additionally exports __info__/1 and
LFE-EXPAND-EXPORTED-MACRO/3 and compile_info records its actual .lfe source path.
Consequently exact raw export-list equality would be an incorrect port oracle;
new generated entries are classified while declared contracts stay fixed.

The conversion map covers exactly 5 runtime plus 3 native test modules (8 .erl
removals + 8 .lfe additions). Source-mode/test discovery, lexical rebinding of
outer receive values, same callback/wire identities, immutable writer attribution,
DOWN/ACK/seal order and current budget/assertion limits have concrete instructions
and discriminating checks. Existing evaluator/metadata/locks/launchers stay fixed.
Fresh source-only build plus compile_info rejects stale Erlang beams; seven
named cases prevent an empty-suite false success. No translation was compiled or
run in this planning turn; the illustrative LFE app snippet is an author sketch.

Prepared for Operator activation after review/acceptance decisions. Same-context
self-review is attested, not a manufactured independent contributor or verdict.
The actual conversion return supplies Cayrn's missing input; it is not invented
in advance. No dependency/architecture change or new inquiry is required by the
inspected source. Real implementation/validation and up to five fix iterations
remain the execution work, with known resource/size defects owned by Arc02.
