;;;; Capture ACK and sealing negative controls.
(defmodule cayrn_lfe_io_tests
  (export (capture_requires_owner_ack_test 0)
          (native_agent_companions_test_ 0)
          (seal_orders_prior_capture_and_rejects_late_writes_test 0)))

(include-lib "eunit/include/eunit.hrl")

;; Rebar discovers Erlang test files, while LFE companion discovery starts here.
;; Include the evaluator and isolated-startup modules explicitly in the suite.
(defun native_agent_companions_test_ ()
  "Discover all native cases without depending on Erlang source files."
  (list '#(module cayrn_lfe_eval_tests)
        '#(module cayrn_lfe_application_tests)
        '#(module cayrn_lfe_resource_tests)
        '#(module cayrn_lfe_authority_tests)))

(defun capture_requires_owner_ack_test ()
  "Never acknowledge a native write before its owner commits capture."
  (let* ((root (spawn (lambda () (receive ('stop 'ok)))))
         ((tuple 'ok io _trace)
          (cayrn_lfe_io:start (self) #b("2") root))
        (ref (make_ref)))
    (try
      (progn
        (! io (tuple 'io_request (self) ref
                     (tuple 'put_chars 'unicode #b("hello"))))
        (receive
          ((tuple 'capture incoming-io from incoming-ref #b("2") #b("hello"))
           (when (=:= incoming-ref ref) (=:= incoming-io io))
           (assertEqual (self) from))
          (after 1000 (error 'missing_capture)))
        (receive
          ((tuple 'io_reply incoming-ref _)
           (when (=:= incoming-ref ref))
           (error 'false_native_ack))
          (after 20 'ok)))
      (after
        (unlink io)
        (exit io 'kill)
        (exit root 'kill)))))

(defun seal_orders_prior_capture_and_rejects_late_writes_test ()
  "Seal after earlier capture and reject subsequent writes explicitly."
  (let* ((root (spawn (lambda () (receive ('stop 'ok)))))
         ((tuple 'ok io _trace)
          (cayrn_lfe_io:start (self) #b("5") root))
        (ref (make_ref)))
    (try
      (progn
        (! io (tuple 'io_request (self) ref
                     (tuple 'put_chars 'unicode #b("before"))))
        (cayrn_lfe_io:seal io (self))
        (receive
          ((= (tuple 'capture incoming-io _ _ _ _) first)
           (when (=:= incoming-io io))
           (assertEqual (tuple 'capture io (self) ref #b("5") #b("before"))
             first))
          ((tuple 'sealed incoming-io _) (when (=:= incoming-io io))
           (error 'seal_preceded_capture))
          (after 1000 (error 'missing_capture)))
        (receive
          ((= (tuple 'sealed incoming-io _) second)
           (when (=:= incoming-io io))
           (assertEqual (tuple 'sealed io #b("5")) second))
          (after 1000 (error 'missing_seal)))
        (let ((later (make_ref)))
          (! io (tuple 'io_request (self) later
                       (tuple 'put_chars 'unicode #b("after"))))
          (receive
            ((tuple 'io_reply incoming-ref reply)
             (when (=:= incoming-ref later))
             (assertEqual '#(error terminated) reply))
            (after 1000 (error 'missing_late_rejection)))))
      (after
        (unlink io)
        (exit io 'kill)
        (exit root 'kill)))))
