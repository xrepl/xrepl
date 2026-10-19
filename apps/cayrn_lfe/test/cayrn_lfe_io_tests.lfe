;;;; Capture ACK and stronger sealing negative controls.
(defmodule cayrn_lfe_io_tests
  (export (capture_requires_owner_ack_test 0)
          (native_agent_companions_test_ 0)
          (seal_orders_prior_capture_and_rejects_late_writes_test 0)))

(include-lib "eunit/include/eunit.hrl")

(defun native_agent_companions_test_ ()
  "Discover all native methods explicitly, including stream/ownership suites."
  (list '#(module cayrn_lfe_eval_tests)
        '#(module cayrn_lfe_preview_tests)
        '#(module cayrn_lfe_application_tests)
        '#(module cayrn_lfe_resource_tests)
        '#(module cayrn_lfe_authority_tests)
        '#(module cayrn_lfe_stream_tests)
        '#(module cayrn_lfe_ownership_tests)))

(defun capture_requires_owner_ack_test ()
  "Never acknowledge a native write before its owner commits the exact chunk."
  (with-origin
    (lambda (io)
      (let ((ref (make_ref)))
        (! io (tuple 'io_request (self) ref
                     (tuple 'put_chars 'unicode #b("hello"))))
        (let (((tuple job worker index text) (await-capture io)))
          (assertEqual #b("hello") text)
          (assert-no-reply ref)
          (cayrn_lfe_io:committed io job worker index)
          (await-reply ref 'ok))))))

(defun seal_orders_prior_capture_and_rejects_late_writes_test ()
  "Seal waits prior durable capture/worker death and rejects late requests."
  (with-origin
    (lambda (io)
      (let ((ref (make_ref)))
        (! io (tuple 'io_request (self) ref
                     (tuple 'put_chars 'unicode #b("before"))))
        (let (((tuple job worker index text) (await-capture io)))
          (assertEqual #b("before") text)
          (cayrn_lfe_io:seal io (self))
          (let ((later (make_ref)))
            (! io (tuple 'io_request (self) later
                         (tuple 'put_chars 'unicode #b("after"))))
            (await-reply later '#(error terminated)))
          (receive ((tuple 'sealed incoming _) (when (=:= incoming io))
                     (error 'seal_preceded_capture_commit))
            (after 20 'ok))
          (assert-no-reply ref)
          (cayrn_lfe_io:committed io job worker index)
          (await-reply ref 'ok)
          (receive
            ((tuple 'sealed incoming #b("5")) (when (=:= incoming io)) 'ok)
            (after 1000 (error 'missing_strong_seal))))))))

(defun with-origin (function)
  (let* (((tuple 'ok io ref)
          (cayrn_lfe_io:start (self) #b("5") (lambda () 'ok)))
         (monitor (monitor 'process io)))
    (try
      (progn
        (receive
          ((tuple 'origin_ready incoming origin _root trace)
           (when (=:= incoming io) (=:= origin ref))
           (let ((1 (trace:process trace (self) 'true '(send))))
             (cayrn_lfe_io:activate io (self) ref)))
          (after 1000 (error 'missing_origin_publication)))
        (funcall function io))
      (after
        (unlink io)
        (gen_server:stop io 'normal 1000)
        (erlang:demonitor monitor '(flush))))))

(defun await-capture (io)
  (receive
    ((tuple 'admit_io incoming _ref job) (when (=:= incoming io))
     (cayrn_lfe_io:admit io (self) job 'grant)
     (await-capture io))
    ((tuple 'formatter_ready incoming _ref job worker)
     (when (=:= incoming io))
     (cayrn_lfe_io:activate_formatter io (self) job worker)
     (await-capture io))
    ((tuple 'capture incoming _ref #b("5") job worker index text)
     (when (=:= incoming io)) (tuple job worker index text))
    (after 1000 (error 'missing_capture))))

(defun assert-no-reply (ref)
  (receive
    ((tuple 'io_reply incoming _) (when (=:= incoming ref))
     (error 'false_native_ack))
    (after 20 'ok)))

(defun await-reply (ref expected)
  (receive
    ((tuple 'io_reply incoming reply) (when (=:= incoming ref))
     (assertEqual expected reply))
    (after 1000 (error 'missing_io_reply))))
