(defmodule xrepl-shell-switching-tests
  "Integration tests for shell switching end-to-end.

  Creates sessions in a non-default shell, drives switching via eval,
  and asserts the session genuinely executes in the new shell after."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

(defun setup ()
  (application:ensure_all_started 'xrepl)
  'ok)

(defun teardown ()
  (lists:foreach
    (lambda (sid)
      (try (xrepl-session-manager:destroy sid)
           (catch ((tuple _ _ _) 'ok))))
    (xrepl-session-manager:list))
  (xrepl-session-manager:clear-current)
  'ok)

;;; ----------------------------------------------------------------
;;; Create session in echo shell
;;; ----------------------------------------------------------------

(deftest create-session-in-echo-shell
  "A session created with shell=xrepl-shell-echo starts in echo mode."
  (setup)
  (case (xrepl-session-manager:create (map 'name "echo-start"
                                           'shell 'xrepl-shell-echo))
    (`#(ok ,id)
     ;; eval "hi" must echo, not evaluate LFE
     (case (xrepl-session:eval id "hi")
       (`#(ok #(formatted ,text))
        (let ((s (if (is_binary text) (binary_to_list text) text)))
          (is-equal "echo: hi" s)))
       (other (is-equal (tuple 'expected-echo-ok 'got) other))))
    (_ (is 'false)))
  (teardown))

;;; ----------------------------------------------------------------
;;; Switch from echo to LFE, then verify LFE is active
;;; ----------------------------------------------------------------

(deftest switch-echo-to-lfe-and-eval
  "After 'quit' in echo shell, the session runs in LFE and (+ 1 2) = 3.
  This is the load-bearing assertion proving the switch actually happened."
  (setup)
  (case (xrepl-session-manager:create (map 'name "switch-test"
                                           'shell 'xrepl-shell-echo))
    (`#(ok ,id)
     ;; Step 1: echo shell is active
     (case (xrepl-session:eval id "hi")
       (`#(ok #(formatted ,t1))
        (let ((s1 (if (is_binary t1) (binary_to_list t1) t1)))
          (is-equal "echo: hi" s1)))
       (other1 (is-equal (tuple 'step1-expected-echo 'got) other1)))
     ;; Step 2: quit triggers switch to xrepl-shell-lfe
     (case (xrepl-session:eval id "quit")
       (`#(ok #(formatted ,t2))
        ;; Any non-error formatted response means switch succeeded
        (is (orelse (is_list t2) (is_binary t2))))
       (other2 (is-equal (tuple 'step2-expected-switch 'got) other2)))
     ;; Step 3 (load-bearing): LFE shell must evaluate (+ 1 2) = 3
     (case (xrepl-session:eval id "(+ 1 2)")
       (`#(ok ,3) (is 'true))
       (other3 (is-equal #(ok 3) other3))))
    (_ (is 'false)))
  (teardown))

;;; ----------------------------------------------------------------
;;; describe advertises the active shell
;;; ----------------------------------------------------------------

(deftest describe-reports-lfe-for-default-session
  "A default session's describe response includes shell name #\"lfe\"."
  (setup)
  (case (xrepl-session-manager:create (map 'name "desc-lfe"))
    (`#(ok ,id)
     (let ((desc (xrepl-session:describe id)))
       (is (is_map desc))
       (is-equal #"lfe" (maps:get 'name desc))))
    (_ (is 'false)))
  (teardown))

(deftest describe-reports-echo-for-echo-session
  "A session started in echo shell reports name #\"echo\"."
  (setup)
  (case (xrepl-session-manager:create (map 'name "desc-echo"
                                           'shell 'xrepl-shell-echo))
    (`#(ok ,id)
     (let ((desc (xrepl-session:describe id)))
       (is (is_map desc))
       (is-equal #"echo" (maps:get 'name desc))))
    (_ (is 'false)))
  (teardown))

(deftest describe-updates-after-switch
  "After switching from echo to LFE, describe reports name #\"lfe\"."
  (setup)
  (case (xrepl-session-manager:create (map 'name "desc-switch"
                                           'shell 'xrepl-shell-echo))
    (`#(ok ,id)
     ;; Before switch: echo
     (is-equal #"echo" (maps:get 'name (xrepl-session:describe id)))
     ;; Switch to LFE
     (xrepl-session:eval id "quit")
     ;; After switch: lfe
     (is-equal #"lfe" (maps:get 'name (xrepl-session:describe id))))
    (_ (is 'false)))
  (teardown))
