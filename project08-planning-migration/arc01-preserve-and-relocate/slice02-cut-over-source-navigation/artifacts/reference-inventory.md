# Reference reconciliation

2026-10-17. Lookup workers supplied file:line evidence; Sofie inspected original
pointer text and the imported status evidence before editing. Evidence is
attested; neither lookup worker accepted the migration.

Active path search covered README.md, RUST-CORE-POC.md, Cargo.toml, Makefile,
mk/, bin/, .github/, src/ and test/. Excluded dependency/build/private state.
Only four active obsolete filesystem-reference lines needed routing changes:
Cargo.toml: 6, RUST-CORE-POC.md: 39, 67 and the spike-test module: 10. The latter
already pointed at a nonexistent workbench/support path. They now route through
docs/planning.md and their owning project. Historical arc0/slice1 text at test
line2 remains a historical label, not a filesystem path or acceptance claim.

The source README and source AGENTS now explain the canonical planning checkout.
No source behavior, test assertions or parsed Cargo data changed. The exact
source allowlist was checked against the source-removal receipt.

Legacy Markdown has one relative filesystem link (audit index to its report),
seven same-document fragment links (Emacs contents) and17 external HTTPS links.
The audit pair moved together and its link resolves. Source code paths, external
repository references and old inline backticked paths in historical payloads
remain unchanged; the complete old-to-new map and pinned source history resolve
their provenance. They are not automatically current assignments.

Composition receipt checks185 current planning filesystem links with zero
missing targets, including links to unchanged original records. Historical
status caveats surfaced in project plans include Arc04’s unreproduced F-1/F-2,
Arc05’s stale arc table versus later7/7 close, Rust PoC’s unrun build, and later
story acceptance/test failures/open rows. None was silently promoted to current
independent acceptance.
