(defmodule cayrn-lfe-eval
  "Native parser/macro/evaluator seam; environments remain opaque to Rust."
  (export (new 0) (run 2)))

(defun new () (lfe_env:new))

(defun run (source env)
  (try
    (case (lfe_io:read_string (unicode:characters_to_list source))
      (`#(ok ,forms)
       (let* ((`#(,value ,next-env)
               (lists:foldl
                 (lambda (form acc)
                   (eval-form form (element 2 acc)))
                 (tuple '() env) forms))
              (text (unicode:characters_to_binary (lfe_io:prettyprint1 value))))
         (tuple 'ok text next-env)))
      (`#(error ,reason) (tuple 'error (preview reason) env)))
    (catch
      ((tuple class reason _stack)
       (tuple 'error (preview (tuple class reason)) env)))))

(defun preview (value)
  (unicode:characters_to_binary (lfe_io:prettyprint1 value)))

(defun eval-form (form env)
  (case (lfe_macro:expand_fileforms (list (tuple form 1)) env 'false 'true)
    (`#(ok ,expanded ,macro-env ,_warnings)
     (lists:foldl
       (lambda (item acc) (eval-expanded (element 1 item) (element 2 acc)))
       (tuple '() macro-env) expanded))
    (`#(error ,errors ,_warnings) (error (tuple 'compile errors)))))

(defun eval-expanded
  ((`(progn . ,forms) env)
   (lists:foldl
     (lambda (form acc) (eval-expanded form (element 2 acc)))
     (tuple '() env) forms))
  ((`(set ,pattern ,expr) env)
   (let ((value (lfe_eval:expr expr env)))
     (case (lfe_eval:match pattern value env)
       (`#(yes ,bindings)
        (tuple value
          (lists:foldl
            (lambda (binding acc)
              (lfe_env:add_vbinding (element 1 binding) (element 2 binding) acc))
            env bindings)))
       ('no (error (tuple 'badmatch value))))))
  ((`(define-function ,name ,_metadata ,definition) env)
   (tuple name (lfe_eval:add_dynamic_func name (arity definition) definition env)))
  ((`(define-macro ,name ,_metadata ,definition) env)
   (tuple name (lfe_env:add_mbinding name definition env)))
  ((expr env) (tuple (lfe_eval:expr expr env) env)))

(defun arity
  ((`(lambda ,args . ,_)) (length args))
  ((`(match-lambda (,patterns . ,_) . ,_)) (length patterns)))
