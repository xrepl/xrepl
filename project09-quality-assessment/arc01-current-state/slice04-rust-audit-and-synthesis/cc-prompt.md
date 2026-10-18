# CC assignment — Project09 / Arc01 / Slice04 — Rust audit

Issued 2026-10-17. Initial assignment; no predecessor. Reviewer: Sofie in the
coordinating chat. This is a real evidence/report execution assignment under
the Operator-authorized optional-CC workflow and Expedited Mode.

## Required reading and intake

Required-full, in order:
1. Source `/Users/oubiwann/lab/lfe/xrepl/xrepl/AGENTS.md`.
2. Planning root `AGENTS.md`, Project09 `AGENTS.md`, `project-plan.md`, Arc01
   `arc-plan.md`, this slice's `slice-plan.md`, `ledger.md`, and this prompt.
3. Installed `code-auditing/SKILL.md` and its five `guides/*.md`.
4. Installed `rust-guidelines/SKILL.md` and **every file under its `guides/`**,
   beginning with `11-anti-patterns.md`. Read in bounded contiguous chunks;
   recover omitted output. Record actual guide paths, hashes and extents.
5. Project05's `arc02-event-core/slice01-infrastructure-poc/artifacts/`
   `2026.06.13-rust-core-poc-notes.md` and `RUST-CORE-POC.md`.

Skills resolve under `/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills/`.
Planning root is `/Users/oubiwann/lab/lfe/xrepl/xrepl/.worktrees/planning`.
Reference-only: Project05's architecture alternatives; these do not authorize
implementing the shared architecture or treating all milestones as PoC scope.

Required-data: enumerate `git ls-files crates Cargo.toml Cargo.lock Makefile mk
.github` at source pin `b865b3137e841269f9218d978817cc243e6b9278`, inspect all
Rust source/tests/manifests and support boundaries. Record complete population,
exclusions, source state and commands. Data enumeration is not semantic reading.
Write intake coverage and a concise source-cited contract readback in the allowed
evidence file before dependent work. Resolve conflicting/missing inputs first.

## Intent, decisions and inspection recipe

The Operator wants a quality assessment of existing xrepl, not repairs or a new
architecture. This finite assignment covers the three current Rust crates,
their native validation and synthetic fault/exit checks; stop when every source
surface has a disposition and the report is reviewable. Sofie consumes the
evidence for independent review and combined synthesis. No separate benchmark,
architecture experiment or broader repository study is authorized.

Binding: diagnosis only; no source/lock/dependency/format edits. The PoC selects
event channel, reedline thread, backend task/trait and renderer; BEAM integration,
streaming and interrupt are explicitly deferred. Read actual code before judging.
The author already inspected all Rust code and found public failure/lifecycle
claims deserve checking, while existing tests exercise only the adventure.
Do not prescribe that a bug must exist. For each candidate trace ownership,
channel closure, prompt pulses and task/thread completion through real `run`.

Recommended sequence:
1. Complete intake/full guidance; build map by crate, public API and logical unit.
2. Walk every Rust source and test using the loaded anti-pattern/topic guides.
   Check ownership and failure paths, output errors, current synchronous backend
   contract, task joining, channel capacity, docs and native CI/Make alignment.
3. Reuse exact native receipts under `/private/tmp/xrepl-p09-20261017/` as
   prior evidence, then independently run `cargo test --offline --locked
   --workspace --all-features`, Clippy with `--all-targets -- -D warnings`, and
   `cargo fmt --all -- --check`. Preserve failures; do not repair source.
4. If needed, make a neutral temporary harness depending on the real local
   `xrepl-core` API. Exercise a normal input/quit control and a backend panic,
   EOF or error boundary. Use a PTY only if necessary for reedline; cap waits
   and clean up only your child processes. Never manipulate personal history or
   environment HOME/CODEX_HOME. Keep probe code/logs in allowed artifacts or
   `/private/tmp`. No external system, credentials or story assets are needed.
5. Write findings only when evidence supports them; otherwise label uncertainty.
   Include stable `RUST-NNN` IDs, severity, file:line, scale, failure mode,
   concrete fix direction and actual evidence. Separate explicit deferral from
   bugs. Include five concrete clean checks and full scale coverage.

Guidance application: code-auditing's scope map governs completeness and its
finding shape governs evidence; Rust anti-pattern/async ownership guidance
governs error/lifecycle review. Probes must discriminate normal completion from
a stalled/failed peer rather than merely restating implementation. Existing
zero-core-test result is a coverage observation, not proof of a bug.

## Allowed writes, validation and return

Only these planning files may be created/committed:
- This slice `artifacts/2026.10.17-audit-results-rust.md`.
- This slice `artifacts/2026.10.17-rust-evidence.md`.
- Neutral probe source/log files beneath this slice `artifacts/rust-probes/`.

No plan/ledger/prompt/closing or other source edits. Main context writes those
after review. Before commit, inspect diff and run whitespace/local-link checks;
verify the source checkout and historical records are untouched. Use explicit
file lists with `git commit --only` on `planning`; do not stage unrelated files.
Other agents may be reading/writing elsewhere. Never use broad add/reset/clean.
Return exact paths, commit, population/read coverage, checks/results, proposed
findings, uncertainty and untouched boundaries. Your work remains proposed-done
until Sofie's review; do not claim project or historical acceptance.
