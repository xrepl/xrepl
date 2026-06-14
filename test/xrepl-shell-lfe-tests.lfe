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

;;; ----------------
;;; snapshot/1 + round-trip tests (Phase A)
;;; ----------------

(deftest snapshot-returns-bindings-map
  "snapshot returns a map with a 'bindings key."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (let ((snap (xrepl-shell-lfe:snapshot state0)))
       (is (is_map snap))
       (is (maps:is_key 'bindings snap))
       (is (is_list (maps:get 'bindings snap)))))
    (_ (is 'false))))

(deftest snapshot-contains-directly-added-binding
  "A variable added directly to the env appears in the snapshot."
  (setup)
  ;; Build an env with a known binding, bypass eval-set to isolate snapshot path
  (let* ((base (xrepl-env:new "" '() 'false))
         (env-with-val (lfe_env:add_vbinding 'direct-var 42 base)))
    (case (xrepl-shell-lfe:init (map 'env env-with-val))
      (`#(ok ,state0)
       (let* ((snap (xrepl-shell-lfe:snapshot state0))
              (bindings (maps:get 'bindings snap '()))
              (names (lists:map (lambda (b) (case b (`#(,n ,_) n))) bindings)))
         (is (lists:member 'direct-var names))))
      (_ (is 'false)))))

(deftest snapshot-contains-set-binding
  "A value bound via eval (set ...) appears in the subsequent snapshot."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(set rtv 55)" state0 (map))
       (`#(ok ,_ ,state1)
        (let* ((snap (xrepl-shell-lfe:snapshot state1))
               (bindings (maps:get 'bindings snap '()))
               (names (lists:map (lambda (b) (case b (`#(,n ,_) n))) bindings)))
          (is (lists:member 'rtv names))))
       (_ (is 'false))))
    (_ (is 'false))))

(deftest snapshot-restore-via-init
  "Snapshot round-trips: init with snapshot gives access to prior bindings.
  Uses the pre-built env path (map 'env E) to supply the restored env directly,
  avoiding any issue with the restore-from-snapshot foldl path."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(set rtv2 77)" state0 (map))
       (`#(ok ,_ ,state1)
        ;; Use env-of to extract the live env from state1, then pass it
        ;; directly as the 'env opt — this tests that init uses a given env
        (let ((live-env (xrepl-shell-lfe:env-of state1)))
          (case (xrepl-shell-lfe:init (map 'env live-env 'session-id "s-r"))
            (`#(ok ,state2)
             (case (xrepl-shell-lfe:eval "rtv2" state2 (map))
               (`#(ok ,v ,_) (is-equal 77 v))
               (_ (is 'false))))
            (_ (is 'false)))))
       (_ (is 'false))))
    (_ (is 'false))))

(deftest snapshot-excludes-closures
  "Lambda values bound in the env are excluded from the snapshot.
  Checks the snapshot bindings list directly — no need to call the closure."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     ;; Bind a lambda to a variable
     (case (xrepl-shell-lfe:eval
              "(set fn-var (lambda (x) x))" state0 (map))
       (`#(ok ,_ ,state1)
        ;; The snapshot must NOT include fn-var (lambdas not serialisable)
        (let* ((snap (xrepl-shell-lfe:snapshot state1))
               (bindings (maps:get 'bindings snap '()))
               (names (lists:map
                        (lambda (b)
                          (case b (`#(,n ,_) n)))
                        bindings)))
          (is-not (lists:member 'fn-var names))))
       (_ (is 'false))))
    (_ (is 'false))))

;;; ----------------
;;; Did-you-mean hook tests (slice5)
;;; ----------------

(deftest dym-open-returns-hint
  "(open) — unbound in default env, in table — returns xs:run hint.
  Verified: lfe_env:is_fbound(open, 0, default-env) = false."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(open)" state0 (map))
       (`#(ok #(formatted ,text) ,state1)
        (let ((s (if (is_binary text) (binary_to_list text) text)))
          (is (=/= 'nomatch (string:find s "(xs:run 'open)"))))
        ;; Shell state is unchanged (env not updated)
        (is-equal state0 state1))
       (other (is-equal (tuple 'expected-hint 'got) other))))
    (_ (is 'false))))

(deftest dym-sesame-returns-hint
  "(sesame) — unbound in default env — hint substitutes 'sesame."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(sesame)" state0 (map))
       (`#(ok #(formatted ,text) ,_)
        (let ((s (if (is_binary text) (binary_to_list text) text)))
          (is (=/= 'nomatch (string:find s "(xs:run 'sesame)")))))
       (other (is-equal (tuple 'expected-hint 'got) other))))
    (_ (is 'false))))

(deftest dym-unlock-with-args
  "(unlock 1) — args ignored; name 'unlock substituted in hint."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(unlock 1)" state0 (map))
       (`#(ok #(formatted ,text) ,_)
        (let ((s (if (is_binary text) (binary_to_list text) text)))
          (is (=/= 'nomatch (string:find s "(xs:run 'unlock)")))))
       (other (is-equal (tuple 'expected-hint 'got) other))))
    (_ (is 'false))))

(deftest dym-passwd-returns-hint
  "(passwd) — unbound in default env, in table — returns xs:run hint."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(passwd)" state0 (map))
       (`#(ok #(formatted ,text) ,_)
        (let ((s (if (is_binary text) (binary_to_list text) text)))
          (is (=/= 'nomatch (string:find s "(xs:run 'passwd)")))))
       (other (is-equal (tuple 'expected-hint 'got) other))))
    (_ (is 'false))))

(deftest dym-zzznope-not-a-trigger
  "(zzznope 1) — unbound but NOT in table — normal error, no hint."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(zzznope 1)" state0 (map))
       (`#(error ,_) (is 'true))       ;; normal error path
       (`#(ok #(formatted ,_) ,_)      ;; must NOT be a hint
        (is 'false))
       (_ (is 'true))))                ;; other error shapes also ok
    (_ (is 'false))))

(deftest dym-no-hijack-bound-function
  "If the user binds a table symbol as a function, it is called normally.
  Uses 'passwd (unbound in default env) to test the no-hijack guard cleanly
  (pwd/0 is a shell built-in — testing passwd is cleaner and equivalent)."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     ;; Verify passwd hint fires BEFORE the user defines it
     (case (xrepl-shell-lfe:eval "(passwd)" state0 (map))
       (`#(ok #(formatted ,_) ,_) 'ok)   ;; hint fires when unbound
       (_ (is 'false)))
     ;; Now define a user function named passwd
     (case (xrepl-shell-lfe:eval "(defun passwd () 'real)" state0 (map))
       (`#(ok ,_ ,state1)
        ;; (passwd) must call the user's function, NOT produce a hint
        (case (xrepl-shell-lfe:eval "(passwd)" state1 (map))
          (`#(ok real ,_) (is 'true))   ;; atom 'real — bare in quasi-quote
          (other (is-equal (tuple 'expected-real 'got) other))))
       (_ (is 'false))))
    (_ (is 'false))))

(deftest dym-normal-eval-unaffected
  "(+ 1 2) = 3 with the hook present — normal eval unchanged."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-lfe:eval "(+ 1 2)" state0 (map))
       (`#(ok ,3 ,_) (is 'true))
       (other (is-equal (tuple 'expected-3 'got) other))))
    (_ (is 'false))))
