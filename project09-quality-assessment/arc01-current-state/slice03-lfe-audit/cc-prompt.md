# CC assignment — Project09 / Arc01 / Slice03 — LFE/OTP audit

Initial assignment issued 2026-10-17; no predecessor. Reviewer: Sofie in the
coordinating context. Evidence/report work under Operator-authorized CC agents
and Expedited Mode. Source root `/Users/oubiwann/lab/lfe/xrepl/xrepl`, pin
`b865b3137e841269f9218d978817cc243e6b9278`. Planning root is its `.worktrees/planning`.

## Required reading and intake

Required-full: source/parent/Project09 `AGENTS.md`; Project09 plan, Arc01 plan;
this slice's plan, ledger and prompt; installed code-auditing skill/five guides;
`/Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md` (896
lines); installed erlang-guidelines entrypoint and guides, beginning with
`11-anti-patterns.md`. Skills root is
`/Users/oubiwann/Library/Application Support/ChatGPT-Profiles/personal/codex-home/skills`.
Record exact files/extents/hashes, recover truncated output, and preserve any
unread guidance as outstanding scope. Do not equate enumeration with reading.

Required-data: `git ls-files src test bin rebar.config rebar.lock Makefile mk
.github` gives the finite source population; inspect every LFE/test/Erlang
source and support boundary. Read resolved dependency APIs only when needed
to interpret xrepl calls. `_checkouts` uses local protocol/term siblings; record
their exact pins and applicable differences from lockfile package versions.
No full sibling audits. Read historical L-01–L-21 finding bodies under
Project04 `arc01-beam-audit/slice01-audit/artifacts/2026.06.10-audit-results-lfe.md`
as original claims to recheck, not current truth. Other historical prompts are
reference-only and never fresh execution authority.

Write a concise coverage/intake and source-cited contract readback in the
allowed evidence file before dependent work; missing/conflicting inputs block
only affected claims. Full source/guidance coverage remains explicit across
named passes if the packet is too large. No pretend full audit acceptance.

## Author-grounded inspection method and proof

The Operator approved assessing existing xrepl, with a finite repository/corpus
scope and reports as deliverables. Stop when every source surface has a
disposition and reviewable findings/evidence are returned. No separate benchmark,
architecture investigation or hardening/repair work is authorized. Main context
owns scope, design, final judgments and acceptance coordination.

Sofie has read the live lifecycle/transport/storage/story paths and run native
checks. EUnit passes175/175; xref exits1 with undefined/dead calls. Inspect these
candidate paths without prescribing a result:
- `xrepl-session:handle_call/3` stores one `eval-pending`; inspect simultaneous
  callers and result attribution. A neutral slow first eval/fast second eval
  should let each caller get its own value or explicit busy response.
- `xrepl-store:do-cleanup-expired-sessions` deletes metadata while merely
  logging a live process. Check lifecycle ownership and downstream history.
- `xrepl-session:process-name`, history table names and input-derived atoms.
- Network packet settings/validation/authentication, request-response IDs,
  malformed MessagePack shapes, advertised operations and output routing.
- `binary_to_list/list_to_binary` versus Unicode conversion in the dispatcher,
  xs-shell and parser. Distinguish synthetic string tests from parsed LFE forms.
- Copied Erlang shell and live environment/error formatting API calls: identify
  real callers rather than assuming all xref warnings are equivalent defects.

Recommended sequence: complete intake; construct full module/test/call-boundary
map; walk all source with domain/audit hunt lists; compare each historical
L-ID with current source; create isolated neutral repros for significant
candidates; write one LFE/OTP report with a tagged Erlang-fork subsection.
Use stable `LFE-NNN` IDs, severity/scale, file:line, failure mode, fix direction
and actual evidence. Include five concrete clean checks and all applicable
scales. Source-supported risks and observations are distinguishable from
demonstrated runtime failures. Style preferences are not correctness defects.

Use real public functions where integration is promised. Synthetic fixtures
only. For Erlang VM probes, load existing built modules, application-load xrepl,
set `history_enabled=false` and `network_enabled=false`/`tcp_enabled=false`
before application start; set any history path to a private `/private/tmp`
path. Never repurpose HOME/CODEX_HOME, start real auth/file-backed listeners,
read personal history, load `priv/support.xsf`, or alter the real archive.
No production source/test/lock/format changes. Cap probe waits and remove only
your child processes. Preserve native prior logs under
`/private/tmp/xrepl-p09-20261017/`; do not rerun broad suites without new reason.
Native rebar commands can rewrite checkout entries in rebar.lock: record the
exact generated diff, coordinate restoration with Sofie and never commit it.

## Outputs, commits and return

Allowed writes/commits, relative to this slice:
- `artifacts/2026.10.17-audit-results-lfe.md`
- `artifacts/2026.10.17-lfe-evidence.md`
- Neutral probe code/logs under `artifacts/lfe-probes/`.

Temporary probe/build files under `/private/tmp` are allowed. No other source,
plans, ledgers, prompts or close records may be changed. Do not inspect `.claude`.
Commit only named allowed files on planning with explicit lists and
`git commit --only`; shared checkout may contain other agents' work. Return
commit/paths, source/guidance coverage, commands/results, proposed findings,
unknowns and historical dispositions. Sofie reviews/independently checks actual
CC work; no self-acceptance or retroactive historical closure.
