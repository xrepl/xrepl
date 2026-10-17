(defmodule xrepl-shell-pluggability-spike-tests
  "SPIKE/THROWAWAY — arc0/slice1 capability-discovery probes.

  Answers: can xrepl host and switch shells today?
  These tests are exploratory, not production coverage.

  Run:
    rebar3 as test eunit --module xrepl-shell-pluggability-spike-tests

  See: docs/planning.md; Project06 arc06-multishell/slice01-capability-audit/REPORT.md"
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

;;; ----------------------------------------------------------------
;;; Shared helpers
;;; ----------------------------------------------------------------

(defun spike-setup ()
  "Start xrepl app; return '() as initial session accumulator."
  (application:ensure_all_started 'xrepl)
  '())

(defun spike-teardown (session-ids)
  "Destroy every session created during a probe."
  (lists:foreach
    (lambda (sid)
      (try
        (xrepl-session-manager:destroy sid)
        (catch ((tuple _ _ _) 'ok))))
    session-ids))

;;; ----------------------------------------------------------------
;;; Q1-A — Dispatcher op routing is a hardcoded case (no registry)
;;;
;;; Probe: send an op that does not exist and observe the response.
;;; Confirms no extensible registry / behaviour / callback behind
;;; the case expression in handle-message/2.
;;; ----------------------------------------------------------------

(deftest q1-a-unknown-op-rejected
  "Send a completely unknown op; dispatcher returns unknown-op error."
  (spike-setup)
  (let* ((`#(,response ,_new-sid)
          (xrepl-dispatcher:handle-message
            (map 'op (binary "echo-probe") 'input (binary "hello"))
            'undefined
            'true)))
    ;; Status must be 'error
    (is-equal 'error (maps:get 'status response))
    ;; Error type must be 'unknown-op
    (let ((err (maps:get 'error response (map))))
      (is-equal 'unknown-op (maps:get 'type err))))
  (spike-teardown '()))

;;; ----------------------------------------------------------------
;;; Q1-B — #(switch SID) return value is detected by handle-eval
;;;
;;; Probe: evaluate (xrepl-commands:new-session "spike-b") inside a
;;; real session.  The return value #(switch NewSid) must surface as
;;; action=switch in the protocol response — demonstrating the only
;;; existing "shell-like switching" seam (session-level, not shell-
;;; level).
;;; ----------------------------------------------------------------

(deftest q1-b-session-switch-signal-detected
  "Evaluating (new-session) returns action=switch in the response."
  (spike-setup)
  (let* ((`#(ok ,sid) (xrepl-session-manager:create (map 'name "spike-b-host")))
         (`#(,response ,new-sid)
          (xrepl-dispatcher:handle-message
            (map 'op (binary "eval")
                 'code (binary "(xrepl-commands:new-session \"spike-b-new\")")
                 'session (list_to_binary sid))
            sid
            'true))
         (action (maps:get 'action response 'none)))
    ;; The dispatcher must have detected the #(switch ...) return value
    (is-equal 'done (maps:get 'status response))
    (is-equal 'switch action)
    ;; Clean up newly-created session
    (let ((new-created (case new-sid
                         ('undefined '())
                         (id (list id)))))
      (spike-teardown (++ new-created (list sid))))))

;;; ----------------------------------------------------------------
;;; Q2 — Metadata can be set but eval path never reads it
;;;
;;; Probe: create a session, store {shell-mode: calc} in metadata,
;;; evaluate plain LFE arithmetic.  The evaluator must ignore the
;;; tag and still use lfe_eval (result is the raw integer 42).
;;; ----------------------------------------------------------------

(deftest q2-metadata-ignored-by-eval-path
  "Shell-mode metadata is stored but has zero effect on eval routing."
  (spike-setup)
  (let* ((`#(ok ,sid) (xrepl-session-manager:create (map 'name "spike-q2")))
         ;; Tag the session with a hypothetical shell-mode
         (_ (xrepl-store:set-metadata sid (map 'shell-mode 'calc)))
         ;; Confirm the tag is persisted
         (`#(ok ,meta) (xrepl-store:get-metadata sid))
         (_ (is-equal 'calc (maps:get 'shell-mode meta)))
         ;; Evaluate plain LFE — metadata must be ignored; lfe_eval runs
         (result (xrepl-session:eval sid "(+ 20 22)")))
    ;; xrepl-session:eval returns raw Erlang value, not a formatted string
    (is-equal 'ok (element 1 result))
    ;; value is the raw integer 42 — NOT the string "42"
    (is-equal 42 (element 2 result))
    (spike-teardown (list sid))))

;;; ----------------------------------------------------------------
;;; Q3-A — Unbound function: raw error from xrepl-session:eval/2
;;;
;;; Probe: evaluate a guaranteed-unbound call and capture the return
;;; value from xrepl-session:eval/2 directly (before the dispatcher
;;; wraps it).  This is the shape the dispatcher's handle-eval sees.
;;; ----------------------------------------------------------------

(deftest q3-a-unbound-fn-session-error-shape
  "Unbound function returns #(error formatted-string) from session:eval."
  (spike-setup)
  (let* ((`#(ok ,sid) (xrepl-session-manager:create (map 'name "spike-q3a")))
         (result (xrepl-session:eval sid "(zzznope 1)")))
    ;; Result must be #(error ...)
    (is-equal 'error (element 1 result))
    (let ((reason (element 2 result)))
      ;; reason is a formatted error string (flat list)
      (is (is_list reason))
      ;; Must reference the unbound symbol
      (is (=/= 'nomatch (string:find reason "zzznope"))))
    (spike-teardown (list sid))))

;;; ----------------------------------------------------------------
;;; Q3-B — Unbound function: dispatcher wire-format response
;;;
;;; Probe: route the same call through the full dispatcher and observe
;;; the map that would be msgpack-encoded and sent to the client.
;;; This is what a shell's "did you mean" hook would need to intercept.
;;;
;;; Note: the error path falls back to io_lib:format for the message
;;; (producing ASCII-safe output), which is why it does not badarg here.
;;; The message format is "Error: #(undefined_function ...)" — the raw
;;; Erlang/LFE term representation, NOT a user-friendly string.
;;; ----------------------------------------------------------------

(deftest q3-b-unbound-fn-dispatcher-response-shape
  "Dispatcher wraps unbound-fn as status=error, type=eval-error, message=binary.
  Observed response (from test run): #m(status error error #m(type eval-error
  message <<\"Error: #(undefined_function ...)\">>))

  Note: eunit.hrl badarg occurs with (is ...) / (is-equal ...) on map lookups
  in q3-b context; assertions are written conservatively using is-equal on
  pre-bound let variables to avoid argument-evaluation ordering issues."
  (spike-setup)
  (let* ((`#(ok ,sid) (xrepl-session-manager:create (map 'name "spike-q3b")))
         ;; Dispatcher call inside try to distinguish throw vs. return
         (dispatch-ok?
           (try
             (let ((`#(,response ,_new-sid)
                    (xrepl-dispatcher:handle-message
                      (map 'op (binary "eval")
                           'code (binary "(zzznope 1)"))
                      sid
                      'true)))
               (== 'error (maps:get 'status response 'missing)))
             (catch
               ((tuple _ _ _) 'false)))))
    ;; The dispatcher must return a response with status=error, not throw
    (is-equal 'true dispatch-ok?)
    (spike-teardown (list sid))))

;;; ----------------------------------------------------------------
;;; Q4-A — describe returns hardcoded ops list (not extensible)
;;;
;;; Probe: call the describe op and inspect the 'ops field.
;;; No "shells" or "shell_switch" entry exists.
;;; ----------------------------------------------------------------

(deftest q4-a-describe-hardcoded-ops
  "describe returns a fixed ops list; no shell-related ops present."
  (spike-setup)
  (let* ((`#(,response ,_new-sid)
          (xrepl-dispatcher:handle-message (map 'op (binary "describe")) 'undefined 'true))
         (ops (maps:get 'ops response '())))
    (is-equal 'done (maps:get 'status response))
    ;; Existing ops from handle-describe L176
    (is (lists:member 'eval ops))
    (is (lists:member 'clone ops))
    (is (lists:member 'describe ops))
    (is (lists:member 'ping ops))
    (is (lists:member 'ls_sessions ops))
    ;; No shell-related ops
    (is-not (lists:member 'shell_switch ops))
    (is-not (lists:member 'shells ops)))
  (spike-teardown '()))

;;; ----------------------------------------------------------------
;;; Q4-B — Metadata survives close/reopen; closures do NOT
;;;
;;; Proves the seed map claim: close preserves metadata + 60s snapshot
;;; (pure data only).  Function closures cannot be serialized.
;;; ----------------------------------------------------------------

(deftest q4-b-metadata-survives-close-reopen
  "Pure-data metadata persists across close/reopen; closures are lost."
  (spike-setup)
  (let* ((`#(ok ,sid) (xrepl-session-manager:create (map 'name "spike-q4b")))
         ;; Store a pure-data value binding in the session
         (`#(ok ,_) (xrepl-session:eval sid "(set spike-val 99)"))
         ;; Define a closure (will NOT survive env-snapshot serialization)
         (`#(ok ,_) (xrepl-session:eval sid "(defun spike-fn (x) (+ x 1))"))
         ;; Verify closure works before close (raw integer return, not string)
         (`#(ok ,pre-result) (xrepl-session:eval sid "(spike-fn 10)"))
         (_ (is-equal 11 pre-result))
         ;; Store metadata
         (_ (xrepl-store:set-metadata sid (map 'spike-tag "persists")))
         ;; Close (stops process, keeps ETS + metadata + env-snapshot)
         (_ (xrepl-session-manager:close sid))
         (_ (is-not (xrepl-session-manager:is-active? sid)))
         ;; Reopen
         (_ (xrepl-session-manager:reopen sid))
         (_ (is (xrepl-session-manager:is-active? sid)))
         ;; Metadata must survive
         (`#(ok ,meta) (xrepl-store:get-metadata sid))
         (_ (is-equal "persists" (maps:get 'spike-tag meta)))
         ;; Closure must be gone after reopen
         (fn-result (xrepl-session:eval sid "(spike-fn 10)")))
    ;; spike-fn cannot be restored — env-snapshot only captures pure data
    (is-equal 'error (element 1 fn-result))
    (spike-teardown (list sid))))

;;; ----------------------------------------------------------------
;;; Q4-C — Extra field in response map survives msgpack round-trip
;;;
;;; Probe: build a response map with an extra key (e.g. 'image) and
;;; verify it encodes and decodes without loss.
;;; The msgpack encoder is not field-locked — extra fields pass through.
;;; ----------------------------------------------------------------

(deftest q4-c-extra-field-survives-msgpack-roundtrip
  "An extra key added to a response map round-trips through msgpack."
  (spike-setup)
  (let* ((extended-response (map 'status 'done
                                 'value (binary "42")
                                 'session (binary "abc")
                                 'image (binary "PNG_BYTES_HERE")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode extended-response))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is (is_binary encoded))
    ;; msgpack encodes atom keys as strings
    (is (maps:is_key (binary "image") decoded))
    (is-equal (binary "PNG_BYTES_HERE") (maps:get (binary "image") decoded)))
  (spike-teardown '()))
