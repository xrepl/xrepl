(defmodule cayrn-lfe-eval
  "Native parser/macro/evaluator seam; environments remain opaque to Rust."
  (export (new 0) (run 2)))

(defspec (new 0) (() (term)))
(defun new ()
  "Create an opaque native environment."
  (lfe_env:new))

(defspec (run 2)
  (((binary) (term)) (tuple (UNION 'ok 'error) (binary) (boolean) (term))))
(defun run (source env)
  "Evaluate forms and return status, bounded text, omission and saved env."
  (try
    (case (lfe_io:read_string (unicode:characters_to_list source))
      (`#(ok ,forms)
       (let* ((`#(,value ,next-env)
               (lists:foldl
                 (lambda (form acc)
                   (eval-form form (element 2 acc)))
                 (tuple '() env) forms))
              ((tuple text omitted) (cayrn-lfe-preview:render value)))
         (tuple 'ok text omitted next-env)))
      (`#(error ,reason) (result 'error reason env)))
    (catch
      ((tuple class reason _stack)
       (result 'error (tuple class reason) env)))))

(defun result (status value env)
  (let (((tuple text omitted) (cayrn-lfe-preview:render value)))
    (tuple status text omitted env)))

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
              (lfe_env:add_vbinding (element 1 binding)
                                   (element 2 binding) acc))
            env bindings)))
       ('no (error (tuple 'badmatch value))))))
  ((`(define-function ,name ,_metadata ,definition) env)
   (tuple name
     (lfe_eval:add_dynamic_func name (arity definition) definition env)))
  ((`(define-macro ,name ,_metadata ,definition) env)
   (tuple name (lfe_env:add_mbinding name definition env)))
  ((expr env) (tuple (lfe_eval:expr expr env) env)))

(defun arity
  ((`(lambda ,args . ,_)) (length args))
  ((`(match-lambda (,patterns . ,_) . ,_)) (length patterns)))
