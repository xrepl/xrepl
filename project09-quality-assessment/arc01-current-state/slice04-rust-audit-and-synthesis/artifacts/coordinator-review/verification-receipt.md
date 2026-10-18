# Coordinator delivery checks — 2026-10-17

Author: Sofie; self-attested composition checks. Actual CC report review is
recorded separately in the two cdc-verification files.

The retained verify-assessment.py checks the original157-file corpus hashes,
87 source hashes/dispositions and clean source/sibling revisions; all 68 original
criteria/IDs/locators and map statuses; guide metadata36 Rust/17 Erlang plus
Chineual/audit references; all 27 findings exactly once in the backlog; JSON,
local Markdown targets and six rows in each of six ledgers; authored-file
whitespace. It does not prove the semantic truth of every plan conclusion,
personal reading transfer, Markdown anchor correctness or Operator acceptance.

Attempt01 exited1: the checker mistakenly required the intentional src/*.lfe
coverage pattern to exist as a literal filename (OBL-L17). This was a checker
false negative, not a source/map failure. The correction verifies each declared
path or glob has at least one actual match, preserving the original map value.
Attempt02 exited0. Attempt03 adds actual installed guidance metadata checks and
also exits0. Exact outputs remain here. Final output after delivery-record link
updates is structural-final.log. The command is:

    python3 verify-assessment.py

Run from this directory or use its absolute path. All raw native failures,
retries and product-probe observations remain elsewhere in their original
artifact homes. The source tree was never repaired to obtain a green audit.
Raw .log/.diff files may contain trailing diff-context whitespace; preserve
exact receipts rather than rewriting them. Authored Markdown/JSON/probe source
is checked separately. Native fmt remains failed, xref remains failed.

Known preserved intake errors: the Rust initial full-guide requirement was not
met until explicitly redistributed/reconciled; LFE G1 was provisional until G2;
the CC's structural-count/sibling-locator false negatives remain in its evidence;
main's native-suite fixture mistake and asset-hash intake are disclosed in the
implementation summary and project delivery. No failed attempt is silently
replaced by its successful retry.
