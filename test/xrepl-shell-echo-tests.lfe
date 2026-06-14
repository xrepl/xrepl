(defmodule xrepl-shell-echo-tests
  "Unit tests for xrepl-shell-echo — the toy echo shell."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

(defun setup ()
  (application:ensure_all_started 'xrepl)
  'ok)

;;; ----------------
;;; init/1
;;; ----------------

(deftest init-returns-ok
  "init with any opts returns {ok, State}."
  (setup)
  (case (xrepl-shell-echo:init (map))
    (`#(ok ,_state) (is 'true))
    (_ (is 'false))))

;;; ----------------
;;; eval/3
;;; ----------------

(deftest eval-echoes-string
  "eval \"hi\" returns {ok, {formatted \"echo: hi\"}, State}."
  (setup)
  (case (xrepl-shell-echo:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-echo:eval "hi" state0 (map))
       (`#(ok #(formatted ,text) ,_state1)
        ;; text may be a char list or binary — check content
        (let ((as-list (if (is_binary text) (binary_to_list text) text)))
          (is-equal "echo: hi" as-list)))
       (other (is-equal (tuple 'expected-formatted-ok 'got) other))))
    (_ (is 'false))))

(deftest eval-quit-triggers-switch
  "eval \"quit\" returns {switch-shell, xrepl-shell-lfe, #m(), Response}."
  (setup)
  (case (xrepl-shell-echo:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-echo:eval "quit" state0 (map))
       (`#(switch-shell xrepl-shell-lfe ,_opts #(formatted ,_text))
        (is 'true))
       (other (is-equal (tuple 'expected-switch-shell 'got) other))))
    (_ (is 'false))))

(deftest eval-exit-triggers-switch
  "eval \"exit\" also returns {switch-shell, ...}."
  (setup)
  (case (xrepl-shell-echo:init (map))
    (`#(ok ,state0)
     (case (xrepl-shell-echo:eval "exit" state0 (map))
       (`#(switch-shell xrepl-shell-lfe ,_ ,_) (is 'true))
       (_ (is 'false))))
    (_ (is 'false))))

;;; ----------------
;;; describe/1
;;; ----------------

(deftest describe-has-name-echo
  "describe returns a map with name = #\"echo\"."
  (setup)
  (case (xrepl-shell-echo:init (map))
    (`#(ok ,state0)
     (let ((desc (xrepl-shell-echo:describe state0)))
       (is (is_map desc))
       (is-equal #"echo" (maps:get 'name desc))))
    (_ (is 'false))))

;;; ----------------
;;; snapshot/1
;;; ----------------

(deftest snapshot-returns-map
  "snapshot returns a map (echo has nothing to persist)."
  (setup)
  (case (xrepl-shell-echo:init (map))
    (`#(ok ,state0)
     (is (is_map (xrepl-shell-echo:snapshot state0))))
    (_ (is 'false))))
