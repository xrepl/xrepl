(defmodule xrepl-shell-lfe-tests
  "Unit tests for xrepl-shell-lfe — the default LFE shell.

  These are real kept tests that lock the parse->eval->thread-env contract
  that slice3 relies on when rewiring xrepl-session onto the shell behaviour."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

;;; ----------------
;;; Setup
;;; ----------------

(defun setup ()
  "Start the xrepl application so xrepl-env and xrepl-eval are available."
  (application:ensure_all_started 'xrepl)
  'ok)

;;; ----------------
;;; init/1 tests
;;; ----------------

(deftest init-empty-opts
  "init with #m() returns {ok, State} with a usable LFE environment."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state)
     ;; The state is valid: we can eval a simple expression against it
     (case (xrepl-shell-lfe:eval "(+ 1 1)" state (map))
       (`#(ok ,v ,_state2) (is-equal 2 v))
       (_ (is 'false))))
    (_ (is 'false))))

(deftest init-with-env-and-session-id
  "init with #m(env E session-id S) uses the given env and stores the id."
  (setup)
  ;; Build a custom env with a unique binding
  (let* ((base-env (xrepl-env:new "" '() 'false))
         (custom-env (lfe_env:add_vbinding 'my-test-var 99 base-env)))
    (case (xrepl-shell-lfe:init (map 'env custom-env 'session-id "s1"))
      (`#(ok ,state)
       ;; Verify the custom env binding is accessible via eval
       (case (xrepl-shell-lfe:eval "my-test-var" state (map))
         (`#(ok ,v ,_state2) (is-equal 99 v))
         (_ (is 'false))))
      (_ (is 'false)))))

;;; ----------------
;;; eval/3 tests
;;; ----------------

(deftest eval-simple-arithmetic
  "eval \"(+ 1 2)\" returns {ok, 3, State2}."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(+ 1 2)" state0 (map))
       (`#(ok ,v ,_state2) (is-equal 3 v))
       (other (is-equal (tuple 'expected-ok 3) other))))
    (_ (is 'false))))

(deftest eval-threads-env
  "Environment threads across calls: (set x 10) then x returns 10."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     ;; First eval binds x = 10
     (case (xrepl-shell-lfe:eval "(set x 10)" state0 (map))
       (`#(ok ,v1 ,state1)
        (is-equal 10 v1)
        ;; Second eval reads x from the threaded env
        (case (xrepl-shell-lfe:eval "x" state1 (map))
          (`#(ok ,v2 ,_state2) (is-equal 10 v2))
          (other (is-equal (tuple 'expected-x 10) other))))
       (other (is-equal (tuple 'expected-set 10) other))))
    (_ (is 'false))))

(deftest eval-update-shell-vars
  "update-shell-vars runs: after eval, the * variable holds the last result."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     ;; Eval (+ 1 2) = 3; * should be set to 3 in the returned state
     (case (xrepl-shell-lfe:eval "(+ 1 2)" state0 (map))
       (`#(ok ,v1 ,state1)
        (is-equal 3 v1)
        ;; Evaluate the shell history variable * in the new state
        (case (xrepl-shell-lfe:eval "*" state1 (map))
          (`#(ok ,star ,_state2) (is-equal 3 star))
          (other (is-equal (tuple 'expected-star 3) other))))
       (other (is-equal (tuple 'expected-ok 3) other))))
    (_ (is 'false))))

(deftest eval-parse-error
  "eval of an incomplete expression returns {error, #(parse Reason)}."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     ;; \"((\" is incomplete; lfe_io:read_string returns eof -> {error,{parse,_}}
     (case (xrepl-shell-lfe:eval "((" state0 (map))
       (`#(error #(parse ,_reason))
        ;; Error tag is 'parse — locked
        (is 'true))
       (other
        (is-equal (tuple 'expected-parse-error 'got) other))))
    (_ (is 'false))))

(deftest eval-unbound-function-error
  "eval of an unbound function returns {error, #(eval Reason)}.

  xrepl-eval:eval-form/2 catches the exception internally and returns
  {error, FormattedString}, so xrepl-shell-lfe wraps it as {eval, Reason}.
  NOT an {exception, ...} — xrepl-eval never re-throws."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(zzznope 1)" state0 (map))
       ;; xrepl-eval catches the exception and returns {error, string}
       ;; xrepl-shell-lfe wraps as {error, {eval, string}}
       (`#(error #(eval ,reason))
        ;; The reason is the formatted error string (flat char list or binary)
        (is (orelse (is_list reason) (is_binary reason))))
       ;; If somehow exception escapes, accept {exception,...} too and report it
       (`#(error #(exception ,class ,_rsn ,_stk))
        ;; Lock which branch we actually get — currently expect {eval,_}
        (is-equal 'eval-not-exception class))
       (other
        (is-equal (tuple 'expected-eval-error 'got) other))))
    (_ (is 'false))))

;;; ----------------
;;; describe/1 test
;;; ----------------

(deftest describe-returns-name-lfe
  "describe returns a map with name = #\"lfe\"."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (let ((desc (xrepl-shell-lfe:describe state0)))
       (is (is_map desc))
       (is-equal #"lfe" (maps:get 'name desc))))
    (_ (is 'false))))

;;; ----------------
;;; prompt/1 test
;;; ----------------

(deftest prompt-returns-binary
  "prompt returns a binary string."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (let ((p (xrepl-shell-lfe:prompt state0)))
       (is (is_binary p))
       (is (> (byte_size p) 0))))
    (_ (is 'false))))
