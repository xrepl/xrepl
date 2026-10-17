# Approved legacy project mapping

Prepared 2026-10-17 from the checked-out corpus and all local branches, with live origin/macpro branch-tip checks. Project numbers identify records; they do not express dependencies. All eight project homes now exist. The seven historical names were reserved during planning and populated in the approved migration.

| Project | Files to relocate | Scope |
| --- | ---: | --- |
| `project01-repl-foundations` | 9 | Local, multi-session and network REPL foundations; original arcs 1–3 and architecture notes. |
| `project02-terminal-visualization` | 4 | Terminal graphics and rich visualization designs; no delivery inferred from the designs. |
| `project03-emacs-integration` | 1 | Emacs client design; proposed integration, not a verified implementation. |
| `project04-repl-remediation` | 19 | BEAM audit, remediation program, arcs 4–5, continuation context and older branch variant. |
| `project05-rust-frontend` | 5 | Rust frontend architecture, capability review, bootstrap and infrastructure PoC notes. |
| `project06-pluggable-shells` | 10 | Pluggable shell seam and existing arc 6 implementation records. |
| `project07-story-runtime` | 21 | Pure xs engine and xs-shell integration, including acceptance and diagnostic assignments. |
| `project08-planning-migration` | new | Preserve and relocate this corpus, then switch source navigation. |

Initial import: 69 planning files + 1 historical branch variant. Follow-up: the Operator moved `RUST-CORE-POC.md` into Project05’s infrastructure PoC artifacts, adding one preserved planning record. The two leftover `.DS_Store` files are disposable cleanup, not project records.

## Evidence and classification limits

- Source pin: `18ba5b787d5b77f17050127569e3804585b1f772`; main and release/0.1.x now agree.
- The old remediation program reserves Arc06 for structural hardening and Arc07 for inversion. Those are distinct from the later actual `arc6-multishell` and `arc7-xs-engine` directories. Their unrealized scope remains explicitly in Project04/Project05 lineage notes; it is not erased or treated as delivered.
- Original arc numbers survive (zero-padded in destination directory names); no claim that any project or arc is closed is introduced.
- Project07’s two unnumbered assignments receive proposed directory IDs slice08 (real archive acceptance) and slice09 (logjam diagnostics). IDs distinguish records; they do not reconstruct execution order or current assignments.
- `verification-findings.md` remains with its existing multishell owner. Project07 links it as engine input; the payload is not duplicated.
- Existing `slice-doc.md`, `cc-prompt-2.md`, addenda, scripts and verification filenames stay unchanged. New companion plans explain the legacy naming and unresolved evidence.
- Current status wrappers are authored today and labelled retrospective/imported-unreconciled. No fake historical plans, missing ledgers, independent reviews or close reports are backfilled.
- Graphics and Emacs source documents were classified by their opening scope, headings and code/design roles; their technical recommendations were not revalidated in this planning pass.

## Branch reconciliation

- `main` was behind release by 34 commits with zero unique commits; fast-forwarded from `001caac` to `18ba5b7` by an ancestry-guarded compare-and-swap ref update. No checkout or timestamp reset.
- `arc5/slice1-keepalive-desync` is 34 commits behind main and has zero unique commits.
- `arc4/slice1-stabilize` has 3 distinct commit IDs; all are patch-equivalent to main (`git cherry` reports `-` for all three). Main has 44 other commits. Do not merge or reset the feature branch to collect documents.
- The one differing tip document is an older Arc05 plan, missing the later branch-naming paragraph. Preserve it as an attributed branch variant, without replacing the newer plan.
- All documentation blobs in off-main reachable commits are already reachable in main history. There is no additional project to name.
- Live origin exposes main=`001caac` and release=`5d4e334`; live macpro exposes main=`001caac`. These are all ancestors of local main. The stale macpro tracking ref was refreshed. No remote was pushed.
- Git has no original filesystem mtime for a branch-only blob. The variant records its original ref, path, commit, blob and last path-changing commit time; any timestamp derived from that commit must be explicitly labelled synthetic.

## Complete working-tree file map

Destinations are relative to the planning worktree except retained public documentation. The approved imports are committed at 094e72b; source cutover is9d7956b. The initial inventory retains its original proposal label as historical snapshot metadata. Exact file metadata, hashes, original directory metadata and dispositions are in `source-inventory.json`.

| Original path | Disposition / destination |
| --- | --- |
| `RUST-CORE-POC.md` | `project05-rust-frontend/arc02-event-core/slice01-infrastructure-poc/artifacts/RUST-CORE-POC.md` |
| `docs/design/0.1.0/arc1-standalone-repl/cc-prompt.md` | `project01-repl-foundations/arc01-standalone-repl/cc-prompt.md` |
| `docs/design/0.1.0/arc1-standalone-repl/cli-addendum.md` | `project01-repl-foundations/arc01-standalone-repl/cli-addendum.md` |
| `docs/design/0.1.0/arc2-multi-session/cc-prompt.md` | `project01-repl-foundations/arc02-multi-session/cc-prompt.md` |
| `docs/design/0.1.0/arc3-networked-repl/cc-prompt.md` | `project01-repl-foundations/arc03-networked-repl/cc-prompt.md` |
| `docs/design/0.1.0/arc3-networked-repl/plan.md` | `project01-repl-foundations/arc03-networked-repl/plan.md` |
| `docs/design/0.1.0/arc4-green-baseline/arc-plan.md` | `project04-repl-remediation/arc04-green-baseline/arc-plan.md` |
| `docs/design/0.1.0/arc4-green-baseline/slice1/cc-prompt.md` | `project04-repl-remediation/arc04-green-baseline/slice01-stabilize/cc-prompt.md` |
| `docs/design/0.1.0/arc4-green-baseline/slice1/cdc-verification.md` | `project04-repl-remediation/arc04-green-baseline/slice01-stabilize/cdc-verification.md` |
| `docs/design/0.1.0/arc4-green-baseline/slice1/closing-report.md` | `project04-repl-remediation/arc04-green-baseline/slice01-stabilize/closing-report.md` |
| `docs/design/0.1.0/arc4-green-baseline/slice1/ledger.md` | `project04-repl-remediation/arc04-green-baseline/slice01-stabilize/ledger.md` |
| `docs/design/0.1.0/arc4-green-baseline/slice1/slice-doc.md` | `project04-repl-remediation/arc04-green-baseline/slice01-stabilize/slice-doc.md` |
| `docs/design/0.1.0/arc5-critical-correctness/.DS_Store` | `exclude-local-metadata` |
| `docs/design/0.1.0/arc5-critical-correctness/arc-plan.md` | `project04-repl-remediation/arc05-critical-correctness/arc-plan.md` |
| `docs/design/0.1.0/arc5-critical-correctness/slice1/cc-prompt-2.md` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/cc-prompt-2.md` |
| `docs/design/0.1.0/arc5-critical-correctness/slice1/cc-prompt.md` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/cc-prompt.md` |
| `docs/design/0.1.0/arc5-critical-correctness/slice1/cdc-f3-red-RUNME.md` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/cdc-f3-red-RUNME.md` |
| `docs/design/0.1.0/arc5-critical-correctness/slice1/cdc-f3-red.sh` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/cdc-f3-red.sh` |
| `docs/design/0.1.0/arc5-critical-correctness/slice1/cdc-iter3-red-green.sh` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/cdc-iter3-red-green.sh` |
| `docs/design/0.1.0/arc5-critical-correctness/slice1/cdc-verification.md` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/cdc-verification.md` |
| `docs/design/0.1.0/arc5-critical-correctness/slice1/closing-report.md` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/closing-report.md` |
| `docs/design/0.1.0/arc5-critical-correctness/slice1/ledger.md` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/ledger.md` |
| `docs/design/0.1.0/arc6-multishell/shell-seam-decision.md` | `project06-pluggable-shells/arc06-multishell/shell-seam-decision.md` |
| `docs/design/0.1.0/arc6-multishell/slice1-capability-audit/REPORT.md` | `project06-pluggable-shells/arc06-multishell/slice01-capability-audit/REPORT.md` |
| `docs/design/0.1.0/arc6-multishell/slice1-capability-audit/cc-prompt.md` | `project06-pluggable-shells/arc06-multishell/slice01-capability-audit/cc-prompt.md` |
| `docs/design/0.1.0/arc6-multishell/slice2-shell-behaviour/cc-prompt.md` | `project06-pluggable-shells/arc06-multishell/slice02-shell-behaviour/cc-prompt.md` |
| `docs/design/0.1.0/arc6-multishell/slice3-session-rewire/addendum-roundtrip-test.md` | `project06-pluggable-shells/arc06-multishell/slice03-session-rewire/addendum-roundtrip-test.md` |
| `docs/design/0.1.0/arc6-multishell/slice3-session-rewire/cc-prompt.md` | `project06-pluggable-shells/arc06-multishell/slice03-session-rewire/cc-prompt.md` |
| `docs/design/0.1.0/arc6-multishell/slice4-switching-echo/cc-prompt.md` | `project06-pluggable-shells/arc06-multishell/slice04-switching-echo/cc-prompt.md` |
| `docs/design/0.1.0/arc6-multishell/slice5-did-you-mean/bait-words-tweak.md` | `project06-pluggable-shells/arc06-multishell/slice05-did-you-mean/bait-words-tweak.md` |
| `docs/design/0.1.0/arc6-multishell/slice5-did-you-mean/cc-prompt.md` | `project06-pluggable-shells/arc06-multishell/slice05-did-you-mean/cc-prompt.md` |
| `docs/design/0.1.0/arc6-multishell/verification-findings.md` | `project06-pluggable-shells/arc06-multishell/verification-findings.md` |
| `docs/design/0.1.0/arc7-xs-engine/design.md` | `project07-story-runtime/arc07-xs-engine/design.md` |
| `docs/design/0.1.0/arc7-xs-engine/slice1-bundle-loader/cc-prompt.md` | `project07-story-runtime/arc07-xs-engine/slice01-bundle-loader/cc-prompt.md` |
| `docs/design/0.1.0/arc7-xs-engine/slice2-xs-world/cc-prompt.md` | `project07-story-runtime/arc07-xs-engine/slice02-xs-world/cc-prompt.md` |
| `docs/design/0.1.0/arc7-xs-engine/slice3-xs-engine/cc-prompt.md` | `project07-story-runtime/arc07-xs-engine/slice03-xs-engine/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/.DS_Store` | `exclude-local-metadata` |
| `docs/design/0.1.0/arc8-xs-shell/acceptance-testing.md` | `project07-story-runtime/arc08-xs-shell/acceptance-testing.md` |
| `docs/design/0.1.0/arc8-xs-shell/design.md` | `project07-story-runtime/arc08-xs-shell/design.md` |
| `docs/design/0.1.0/arc8-xs-shell/logjam-debug-instrumentation/cc-prompt.md` | `project07-story-runtime/arc08-xs-shell/slice09-logjam-debug-instrumentation/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/logjam-debug-instrumentation/ledger.md` | `project07-story-runtime/arc08-xs-shell/slice09-logjam-debug-instrumentation/ledger.md` |
| `docs/design/0.1.0/arc8-xs-shell/real-archive-acceptance/cc-prompt.md` | `project07-story-runtime/arc08-xs-shell/slice08-real-archive-acceptance/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice1-shell-core/addendum-portable-join.md` | `project07-story-runtime/arc08-xs-shell/slice01-shell-core/addendum-portable-join.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice1-shell-core/cc-prompt.md` | `project07-story-runtime/arc08-xs-shell/slice01-shell-core/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice2-save-resume/addendum-evaluator-current-session.md` | `project07-story-runtime/arc08-xs-shell/slice02-save-resume/addendum-evaluator-current-session.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice2-save-resume/cc-prompt.md` | `project07-story-runtime/arc08-xs-shell/slice02-save-resume/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice3-images/cc-prompt.md` | `project07-story-runtime/arc08-xs-shell/slice03-images/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice4-navigation-ux/cc-prompt.md` | `project07-story-runtime/arc08-xs-shell/slice04-navigation-ux/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice4-navigation-ux/ledger.md` | `project07-story-runtime/arc08-xs-shell/slice04-navigation-ux/ledger.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice5-xs-prompt/cc-prompt.md` | `project07-story-runtime/arc08-xs-shell/slice05-xs-prompt/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice6-render-unicode/cc-prompt.md` | `project07-story-runtime/arc08-xs-shell/slice06-render-unicode/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice6-render-unicode/ledger.md` | `project07-story-runtime/arc08-xs-shell/slice06-render-unicode/ledger.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice7-unicode-multiword/cc-prompt.md` | `project07-story-runtime/arc08-xs-shell/slice07-unicode-multiword/cc-prompt.md` |
| `docs/design/0.1.0/arc8-xs-shell/slice7-unicode-multiword/ledger.md` | `project07-story-runtime/arc08-xs-shell/slice07-unicode-multiword/ledger.md` |
| `docs/design/0.1.0/distributed-repl-architecture-guide.md` | `project01-repl-foundations/distributed-repl-architecture-guide.md` |
| `docs/design/0.1.0/lfe-repl-reusability-analysis-xrepl-design.md` | `project01-repl-foundations/lfe-repl-reusability-analysis-xrepl-design.md` |
| `docs/design/0.1.0/reveal-like-viz-in-xrepl.md` | `project02-terminal-visualization/arc02-rich-visualization/slice01-design/artifacts/reveal-like-viz-in-xrepl.md` |
| `docs/design/0.1.0/terminal-graphics-support.md` | `project02-terminal-visualization/arc01-terminal-graphics/slice01-design/artifacts/terminal-graphics-support.md` |
| `docs/design/0.1.0/xrepl-emacs-guide.md` | `project03-emacs-integration/slice01-client-design/artifacts/xrepl-emacs-guide.md` |
| `docs/design/0.1.0/xrepl-graphics-impl.md` | `project02-terminal-visualization/arc01-terminal-graphics/slice01-design/artifacts/xrepl-graphics-impl.md` |
| `docs/design/0.1.0/xrepl-graphics-vision.md` | `project02-terminal-visualization/arc02-rich-visualization/slice01-design/artifacts/xrepl-graphics-vision.md` |
| `docs/design/0.1.0/xrepl-history-with-session.txt` | `project01-repl-foundations/arc02-multi-session/xrepl-history-with-session.txt` |
| `docs/design/0.1.0/xrepl-transport-improvements.txt` | `project01-repl-foundations/arc03-networked-repl/xrepl-transport-improvements.txt` |
| `workbench/2026.06.10-audit-index.md` | `project04-repl-remediation/arc01-beam-audit/slice01-audit/artifacts/2026.06.10-audit-index.md` |
| `workbench/2026.06.10-audit-results-lfe.md` | `project04-repl-remediation/arc01-beam-audit/slice01-audit/artifacts/2026.06.10-audit-results-lfe.md` |
| `workbench/2026.06.10-reedline-ratatui-capability-map.md` | `project05-rust-frontend/arc01-architecture/slice01-architecture-review/artifacts/2026.06.10-reedline-ratatui-capability-map.md` |
| `workbench/2026.06.10-remediation-program-plan.md` | `project04-repl-remediation/2026.06.10-remediation-program-plan.md` |
| `workbench/2026.06.10-rust-core-architecture-review.md` | `project05-rust-frontend/arc01-architecture/slice01-architecture-review/artifacts/2026.06.10-rust-core-architecture-review.md` |
| `workbench/2026.06.11-arc5-continuation-bootstrap.md` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/artifacts/2026.06.11-arc5-continuation-bootstrap.md` |
| `workbench/2026.06.11-arch-part3-bootstrap.md` | `project05-rust-frontend/arc01-architecture/slice01-architecture-review/artifacts/2026.06.11-arch-part3-bootstrap.md` |
| `workbench/2026.06.11-rust-core-architecture-review-addendum.md` | `project05-rust-frontend/arc01-architecture/slice01-architecture-review/artifacts/2026.06.11-rust-core-architecture-review-addendum.md` |
| `workbench/2026.06.13-rust-core-poc-notes.md` | `project05-rust-frontend/arc02-event-core/slice01-infrastructure-poc/artifacts/2026.06.13-rust-core-poc-notes.md` |

## Historical branch variant

| Ref / original path | Destination |
| --- | --- |
| `refs/heads/arc4/slice1-stabilize:docs/design/0.1.0/arc5-critical-correctness/arc-plan.md` | `project04-repl-remediation/arc05-critical-correctness/slice01-keepalive-desync/artifacts/branch-variants/e16c0aa/arc-plan.md` |

All old→new path mappings are provenance. Historical inline references remain byte-preserved and resolve through this map and pinned Git source history. New plans and current instructions must link to the canonical locations.

Execution update2026-10-17: all 69 mapped planning payloads and1 older attributed branch variant are imported unchanged. See the Project08 implementation report for self-check receipts and pending human acceptance.

Follow-up 2026-10-17: the PoC relocation supersedes its initial retained-public disposition. Exact current source bytes/dates are in `rust-poc-relocation.json`; initial migration snapshots remain unchanged.
