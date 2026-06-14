# CC PROMPT — arc0 / slice1: xrepl capability-discovery audit ("shells over the protocol")

**You are** Claude Code (Sonnet 4.6), implementing to a spec written by the
design lead (a sibling CDC / Opus instance) and reviewed by Duncan (project lead
+ QA). This is a **capability-discovery audit (a spike)** — *not* a feature
build.

**Mission (one line):** Determine, with running evidence, whether the current
xrepl app can host **multiple "shells" — alternative implementations of the
xrepl protocol spec — and switch between them within one app**, and identify the
minimal seam we would add if it cannot. Produce a severity-graded,
evidence-backed report.

**Why this matters.** We are building an interactive-fiction (IF) shell that
converts player commands and speaks the **xrepl protocol** — deliberately
dogfooding the protocol instead of writing a bespoke front-end. In our mental
model the IF experience is "just another shell" in an xrepl app: the default LFE
shell reads Lisp; a story shell reads IF commands; both ride the same protocol,
and the app switches between them. Before we design that shell, we must know
what xrepl supports **today**: pluggable/switchable shells, per-session
alternative evaluation, an undefined-function "did you mean" hook, streaming,
and capability advertisement. The design lead has already done a read-only pass
(seeded below); your job is to **confirm it empirically with exploratory tests
and go deeper on the gaps.**

---

## Hard constraints — read before doing anything

- **Do NOT modify any production source** under `src/`. Read + experiment only.
  If verifying a capability would require a production change, do **not** make it
  — record it as "requires implementation to verify" and move on.
- **Do NOT run git and do NOT commit.** Duncan controls git. Leave your work in
  place for his review.
- **Exploratory tests go in a clearly-marked scratch location**, NOT in the real
  suites. Suggested: a `*-spike-tests.lfe` module (or `test/spike/`) with
  "spike" in the name. The report must point to them. These are throwaway probes,
  not coverage.
- **Use a trivial throwaway DSL for any "alternate shell" probe** — e.g. an
  "echo" or "calc" shell (input → trivial transform → response). **No story
  content. Never use the words "ground", "support", or any narrative.** This
  audit is about generic xrepl capability only.
- **Stay in scope.** Answer the questions below. Don't refactor, don't "improve"
  things, don't add features. If something tempts you, note it under the report's
  "Observations" and leave it.

## Evidence & honesty standard — this *is* the deliverable

- Back every claim with EITHER a `file:line` citation OR a test you actually ran
  — and **say which**. "I verified by running X" and "I infer from reading Y" are
  different claims; never blur them.
- If you can't determine something, say so plainly ("could not determine without
  a production change"; "test inconclusive because…"). A disclosed unknown is a
  good result; bluffed certainty is the one failure mode that ruins an audit.
- Classify every capability / gap by severity: **NONE** (already supported — cite
  it), **MINOR** (small/cosmetic to add), **MAJOR** (real work, but a clear path
  exists), **BLOCKER** (cannot ship the shell without building this).
- The seed map below comes from a read-only pass with **approximate** line
  numbers from sub-agents. **Verify it; correct anything wrong** (line numbers
  drift, agents err). A "corrections to the seed map" section is required output.

---

## Seed map — what the design lead already found (verify, don't trust blindly)

Project root: the xrepl repo. Primary app: `xrepl/` (the `xrepl` OTP app, LFE,
rebar3 + rebar3_lfe, LFE 2.2.0). Protocol app: `protocol/` (`xrepl_protocol`).
Terminal lib: `term/` (`xrepl_term`). Protocol spec of record:
`protocol/docs/design/xrepl-unified-spec.md`.

- **Dispatch is a hardcoded `case`** in `xrepl-dispatcher:handle-message/2`
  (`xrepl/src/xrepl-dispatcher.lfe` ~L21–54): ops `eval`, `clone`, `close`,
  `ls_sessions`, `describe`, `ping`, `load_file`, `upload_history` are matched
  literally. `describe`'s advertised op list is also hardcoded (~L169–178). No
  registry / behaviour / callback for ops. The only behaviour seam found is the
  **transport** layer (`xrepl-transport.lfe`), which does not route ops.
- **`eval` path:** dispatcher `handle-eval/2` (~L95–132) → `xrepl-session:eval/2`
  (`xrepl-session.lfe` ~L63) → evaluator gen_server loop (~L311–334) →
  `xrepl-eval:eval-form/2` (`xrepl-eval.lfe` ~L47–89) → `lfe_eval:expr/2`.
- **Sessions:** managed by `xrepl-session-manager` (`create/1`, `close/1`,
  `reopen/1`, `destroy/1`; **no `clone`-as-branch**); state stored in
  `xrepl-store` (ETS, keyed by session-id). Session record `session-state`
  (`xrepl-session.lfe` ~L28–34) holds an LFE `env`, an evaluator PID, etc.
  Arbitrary per-session data lives in a `metadata` map (set via
  `xrepl-store:set-metadata/2` ~L148–157). `close` preserves the ETS entry +
  metadata + a 60s `env-snapshot`; `reopen` restores it. `env-snapshot`
  serializes **pure data only** (`xrepl-session.lfe` ~L354–367).
  `export-session`/`import-session` exist (`xrepl-store.lfe` ~L180–198).
- **A "shell" concept exists client-side:** `xrepl-client-shell.lfe`,
  `xrepl-client-shell-fns.lfe`. Map the full read→eval→print path and how it
  relates to the server session — this is central to Q1.
- **Streaming + images:** spec mentions `["streaming"]` … `["done"]` framing and
  an `interrupt`. Terminal rendering is `xrepl-term-graphics:render-data/1,2`
  (`term/src/xrepl-term-graphics.lfe`) — takes raw bytes, supports iTerm2 + Kitty.
- **priv idiom:** `(code:priv_dir 'xrepl)` + `filename:join` (`xrepl.lfe` ~L414).

---

## The questions to answer

### Q1 — Shell architecture & pluggability  (PRIMARY)
- What *is* a "shell" in xrepl today? Map the default LFE shell's full
  read → eval → print path end-to-end, and exactly how the client-side shell
  relates to the server-side session/evaluator over the protocol. Cite modules
  and functions.
- Is there any notion of **multiple shells**, a **shell behaviour/interface**, or
  a **shell registry**? Can one xrepl app define more than one shell
  implementation?
- Is there any mechanism to **switch the active shell** — per session, globally,
  or via an op/command? If yes, cite it and **test it**. If no, say so.
- Where is the **seam** a new shell (a different implementation of the protocol
  spec) would plug into? Is it a behaviour, a callback, config, or would it
  require core edits? Be concrete about the smallest change that would enable
  "register shell + switch shell".
- **Probe:** stand up a trivial throwaway "echo"/"calc" shell concept far enough
  to show whether an alternate shell *can* be hosted/selected without editing
  core dispatch — or to demonstrate exactly what blocks it.

### Q2 — Per-session evaluation routing
- Can a session route input to an **alternate evaluator** (not `lfe_eval`)? Where
  would that branch live (the evaluator loop in `xrepl-session`)? Cite the
  exact function.
- Can session `metadata`/`config` carry a "shell"/"mode" tag, and does anything
  in the eval path read it today? **Test** setting such a tag and observe whether
  the eval path can branch on it (without editing core — if it can't, that's the
  gap to size).

### Q3 — The undefined-function "did you mean" hook
- Locate exactly where an **unbound/undefined function** call is raised and then
  caught/formatted (expected: `lfe_eval:expr/2` raises → caught in
  `xrepl-eval`). Cite file:line.
- **Test:** evaluate a call to a guaranteed-unbound function (e.g. `(zzznope 1)`)
  through the real eval path and **capture the exact error term/response shape**
  (status, fields, the message). Quote it verbatim in the report.
- Assess: can we intercept that path to inspect the unbound symbol's *name* and
  return a custom suggestion (a normal `formatted`/`error` response of our
  choosing)? What is the smallest hook that would let a shell say
  `"Did you mean (xs:run 'pwd)?"` only when the symbol is unbound? Severity-rate
  building it.

### Q4 — Protocol surface we depend on
For each, confirm by **running** against a live in-process session where possible,
and quote the observed shapes:
- **Streaming:** how does a handler emit `["streaming"]` frames then `["done"]`?
  Is there a working `interrupt`/cancel path? Cite + test if feasible.
- **describe / capabilities:** how is the op/capability list produced, and can a
  new capability or shell be **advertised** without editing core? (Tie back to
  the hardcoded list in Q1.)
- **Sessions/metadata:** empirically confirm `create` → `eval` → set/get
  `metadata` → `close` → `reopen` round-trips pure-data state (the seed claims
  this is free; *prove it with a test* and note any caveats).
- **Response extension field:** can an eval/op response carry an **extra field**
  (e.g. `image`) through the encoder to the client without breaking framing?
  Test if feasible; otherwise read the msgpack encoder and reason from it.

### Q5 — Gap analysis & recommendation
- For each capability we need — (a) register + switch shells, (b) per-session
  alternate evaluator, (c) unbound-symbol "did you mean" hook, (d) streaming,
  (e) capability/shell advertisement, (f) response extension field — give a row:
  **capability | NONE/MINOR/MAJOR/BLOCKER | evidence (file:line or test) |
  what's missing | smallest change to close it.**
- Then a short **recommendation**, framed explicitly as *evidence for Duncan +
  the design lead to decide from* — NOT a unilateral design. If the answer is
  "we should add a shell-registry + switch seam," say so and sketch the smallest
  version, but leave the decision to us.

---

## Deliverables

1. **REPORT** at
   `xrepl/workbench/support/arc0-foundation/slice1-capability-audit/REPORT.md`
   with sections: Summary (top-line answer to "can xrepl host & switch shells
   today?") · Q1 · Q2 · Q3 · Q4 · Q5 gap table + recommendation · Corrections to
   the seed map · Observations (out-of-scope things noticed) · What I could NOT
   determine.
2. **Exploratory spike tests** (clearly-named, scratch) with a one-line "how to
   run" in the report. They must actually run; record pass/fail and observed
   output.
3. A note of **anything you had to leave unverified** because it would require a
   production change.

## Done criteria (checklist for yourself before handing back)
- [ ] Every Q answered with evidence, each marked **ran-test** vs **read-only**.
- [ ] Every capability in Q5 severity-classified with a citation.
- [ ] Spike tests actually executed; output captured.
- [ ] No production source modified; nothing committed; no git run.
- [ ] Throwaway DSL only; no "ground"/"support"/story words anywhere.
- [ ] Report explicitly names what you could not determine.
- [ ] Recommendation framed as input for Duncan + CDC, not a final design.

## What to hand back
A short message pointing to the report, stating: the top-line answer to "can
xrepl host and switch shells today?", the severity-graded gap list, and the 2–3
decisions you think Duncan + the design lead now need to make.
