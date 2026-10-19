# CC correction — xrepl Arc02/Slice02 iteration01

2026-10-19. Predecessor cc-prompt.md preserved. Actual CC /root/xrepl_x21;
independent CDC Sofie /root. Same Operator-approved Autonomous Mode2.8.0/Expedited
Arc02 authority; no push/merge/publish. This is executed correction1/5; first
implementation's development failures/draft passes remain distinct. No change to
original8 acceptance criteria, native3wire/limits, evaluator/collector exclusions
or independent/Operator gates. Actual initial candidate remains uncommitted at
source HEAD7228183 with frozen16-file snapshot, not an accepted implementation.

## Blocking evidence and resolved direction

Trap_exit allows ordinary listener terminate but not kill. Unix pathname remains
after untrappable listener death. First unissued registry-fallback design was
independently rejected LR-01: registrykill can precede pending listener→supervisor
call; supervisor waits listener which waits supervisor, then kills after2000ms,
leaving no cleanup owner. Do not narrow permanent-child failure to an idle or
ordinary gen_serverstop control. Source/API review selects EXISTING application
callback helper as stable listening socket owner outside the one_for_all children.
No new process/third permanent child, no Rust/public/protocol redesign.

## Required manifest and preflight

Load required text completely/recover truncation, reconcile all data and record
source-cited readback before dependent edits in artifacts/execution.md, append-only
execution history. Same installed skills/root authorities as original assignment.

1. Required-full: this prompt, current slice-plan.md/ledger.md, preserved initial
   cc-prompt.md; artifacts/listener-lifetime-contract.md (binding refinementv1.0,
   SHA25611c62368b0ca6ec7f47eadbda169ed023910d77d61e9ab8e632ce262c59471d3), listener-lifetime-design-review.md and both rejected/
   superseded listener-lifetime-refinement[-v2]-draft.md for the causal difference.
   The first draft is NOT implementation authority. Required-full current
   artifacts/cdc-draft-observations.md (all early-oracle corrections retained).
2. Required-data: source-baseline-iteration01.json ALL16 file SHA256/null vs current
   frozen bytes; HEAD/branch/worktrees/status/empty staging and preserved docs/design;
   source-baseline.json original15 hashes remain historical baseline. Reconcile
   Cayrn3bcbbdb unchanged and original canonical native3 contract hash. Retain
   draft log exits/populations/current-byte hashes including stale Rebar attempts.
3. Required-full actual current source cayrn_lfe_app.lfe, sup.lfe, listener.lfe,
   registry.lfe and private include; authority_tests complete current file,
   application_tests complete. Read initial module source/callers across all
   start_link/0,init,listener close/unlink/borrowedPort paths with complete rg query.
   Required-section installed application_master.erl276–307 and373–415;
   gen_tcp.erl nonowneraccept docs around767–770; local_tcp accept156–169;
   prim_inet accept485–521; supervisor count/call829–833 and oneforall shutdown
  1477–1521/1563–1585. Required-section kernel file.hrl file_info definition and
   file read_link_info/mode/identity behavior. No assumed stale source/API.
4. Required-full original source/planning/Project10/native AGENTS; initial LFE
   style guide896lines and erlang entrypoint already fully read receipts may be
   retained if actual text remains in context; otherwise reload actual needed
   full text before code, no summary as replacement. Required-section OTP guide
   PC02/03/07/14,BEH04/05/06/08/10,SUP04/05/09/13 and application/resource ownership
   portions discovered through actual headings. Initial CF2.8.0 Autonomous/ledger/
   iteration/validation rules remain active; reconcile unchanged full-read receipts
   and reload needed sections when context unavailable. No fabricated reading.

Record how apphelper lifetime avoids BOTH childkill directions including blocked
parentcall, why accepted socket ownership still listener, how absolutepath and
inode guard preserve unrelated files, and acquisition/cleanup error boundaries.
Current draft gate hashes do not become final candidate verification.

## Exact implementation

Implement binding listener-lifetime-contract.md completely. App start owns passive
packet4 listenport; capture absolutepath/actualidentity BEFORE chmod and Supstart;
start_link/2 passes borrowedSocket+Path through supervisor childspec to listener.
AppState carries resources explicitly; SAME existing application helper owns port
until stop. Listener init/terminate do not bind/close/unlink borrowed listening
resource. Accepted sockets remain owned by listener then normal router/role
transfer. No production helperprocess/registryfallback state/globalpath rewrite.

Appstartup guard closes/reaps acquired port and guarded-unlinks only known owned
identity when later acquisition fails; failed bind preserves existingendpoint;
unknown identity never authorizes unlink. Stop after SupDOWN monitors/closes
exact port, awaits exactref/objectDOWN within1000ms then identity/typeguarded
unlink; replacement file/symlink/socket left untouched. Explicitly log cleanup
failures (OTP ignores callback return). Preserve all existing native3 lease/
context/capture/ACK/close/cancel behavior and physical budgets.

Add EVERY binding contract control: real listenerkill/newboot/sameport+samelive
appowner; registrykill; forced positivelypending listener→supervisorcall BEHIND
observed registryEXIT with guaranteed Supresume (may force2000ms childkill, must
stillservefreshscope); relative startupPath then evaluatedcwdchange/restart same
absoluteendpoint; real acceptedPortowner is listener; actualappstop/restart exact
listenportDOWN/pathcleanup; realcallback identityreplacement guards; Supstartfailure
acquisition unwind and failedbind preserves existinghealthyendpoint. Use actual
owned peers/ports/callbacks, no product debug export, no fake inode-only pass.
Test AppState through real start/2 return in test-owned callback process if needed;
keep callback fixture alive to own port and invoke stop in correct owner. Do not
kill/unlink unrelated existing named supervisor in startup-refusal fixture.

Retain all initial tests and strengthened scope/numeric/trace controls. Native
readiness/client attachments remain same; no evaluatedcode replay across freshboot.
NR-02 forced pending-output root teardown is still serious/open X03/C06, not fixed
by listening socket ownership. No wholeVMkill/powerloss/adversarialfilesystem/
automaticApprestart claim. Missing test preconditions are failed/blocked, not skip.

## Exact16-path source allowlist

- apps/cayrn_lfe/src/cayrn_lfe_registry.lfe
- apps/cayrn_lfe/src/cayrn_lfe_connection.lfe
- apps/cayrn_lfe/src/cayrn_lfe_authority.lfe
- apps/cayrn_lfe/src/cayrn_lfe_context.lfe
- apps/cayrn_lfe/src/cayrn_lfe_listener.lfe
- apps/cayrn_lfe/src/cayrn_lfe_sup.lfe
- apps/cayrn_lfe/src/cayrn_lfe.app.src
- apps/cayrn_lfe/include/cayrn_lfe_registry.lfe
- apps/cayrn_lfe/test/cayrn_lfe_authority_tests.lfe
- apps/cayrn_lfe/test/cayrn_lfe_resource_tests.lfe
- apps/cayrn_lfe/test/cayrn_lfe_io_tests.lfe
- apps/cayrn_lfe/test/cayrn_lfe_application_tests.lfe
- apps/cayrn_lfe/README.md
- apps/cayrn_lfe/AGENTS.md
- README.md
- apps/cayrn_lfe/src/cayrn_lfe_app.lfe

The newly added path is ONLY apps/cayrn_lfe/src/cayrn_lfe_app.lfe. No other source
scope expansion. All original manifests/locks/versions/build/launcher/Rust/legacy/
standalone and evaluator/collector implementation exclusions stay. Keep app0.1.0,
xrepl0.2.0 and two permanent roles; no constructor/debug endpoint elsewhere.

## Gates and return

Run native full makecheck on current bytes; retain stale-module diagnosis and
explicit testcompile where needed, then fresh source-only makecheck to prove no
inherited beams. In unchanged matching Cayrn3bcbbdb, overridesunset, full
makecheck lint-integration test-xrepl including ALL14native+3consumer actualcases.
Root test-lfe/build-agent/check-agent/build/lint-rust/test-rust; actual launcher
/private/tmp/spacedsocket exact nativeonly apps crypto/compiler and eval/Close.
Count actual unique/repeats/legacy/native/Rust/doctest/CT0, failure/filter/skip/unrun
population and every exit/rawlog. Source hashes before/after gate must agree.
Changed shell/doclink/scope/diff--check/source-allowlist checks remain. No old draft
pass relabeled final; no source mutation while a gate uses it.

Commit exact reviewed changed subset of16 with both Codex/Billo AI trailers from
initial prompt; no unrelated staging/docs/design, no push. Planning remains
separate; write complete attested8-row return/candidate fullbinarypatch, all16
hashes, inventory/failures/limits/scope diff/bubble-up and explicit NR-02/X03/C06/
C05preview owners. No CDC verdict/parent edits by CC. I independently review and
reproduce final committed bytes then commit planning closure/mandatoryretro.
Acknowledge exact preserved assignment, coherent preflight and proceed.
