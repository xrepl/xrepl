;;;; Native evaluator persistence and error semantics.
(defmodule cayrn_lfe_eval_tests
  (export (errors_preserve_committed_environment_test 0)
          (functions_and_macro_context_test 0)
          (ordinary_error_atom_is_a_value_test 0)
          (persistent_bindings_test 0)))

(include-lib "eunit/include/eunit.hrl")

(defun persistent_bindings_test ()
  "Keep bindings across separate evaluations."
  (let* ((env (cayrn-lfe-eval:new))
         ((tuple 'ok #b("41") next)
          (cayrn-lfe-eval:run #b("(set x 41)") env)))
    (assertMatch (tuple 'ok #b("42") _)
      (cayrn-lfe-eval:run #b("(+ x 1)") next))))

(defun errors_preserve_committed_environment_test ()
  "Preserve the committed environment across parse and evaluation errors."
  (let* (((tuple 'ok _ env)
          (cayrn-lfe-eval:run #b("(set x 41)") (cayrn-lfe-eval:new)))
         ((tuple 'error _ after-eval)
          (cayrn-lfe-eval:run #b("(/ 1 0)") env))
         ((tuple 'error _ after-parse) (cayrn-lfe-eval:run #b("(") env)))
    (assertEqual env after-eval)
    (assertEqual env after-parse)
    (assertMatch (tuple 'ok #b("41") _) (cayrn-lfe-eval:run #b("x") env))))

(defun functions_and_macro_context_test ()
  "Retain a top-level function in the native environment."
  (let (((tuple 'ok _ env)
         (cayrn-lfe-eval:run #b("(defun inc (x) (+ x 1))")
           (cayrn-lfe-eval:new))))
    (assertMatch (tuple 'ok #b("42") _)
      (cayrn-lfe-eval:run #b("(inc 41)") env))))

(defun ordinary_error_atom_is_a_value_test ()
  "Return the ordinary error atom as a value, not an evaluation failure."
  (assertMatch (tuple 'ok #b("error") _)
    (cayrn-lfe-eval:run #b("'error") (cayrn-lfe-eval:new))))
