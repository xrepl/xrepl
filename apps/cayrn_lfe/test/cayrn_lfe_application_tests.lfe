;;;; Startup isolation from the legacy parent EUnit node.
(defmodule cayrn_lfe_application_tests
  (export (independent_application_start_test_ 0)))

(include-lib "eunit/include/eunit.hrl")
(include-lib "kernel/include/file.hrl")

(defun independent_application_start_test_ ()
  "Check native startup in a fresh, test-owned OTP node."
  (tuple 'timeout 30 #'independent-application-start/0))

(defun independent-application-start ()
  (let* ((dir (filename:join "/private/tmp"
                (++ "cayrn-app-" (os:getpid) "-"
                    (integer_to_list
                      (erlang:unique_integer '(positive monotonic))))))
         ('ok (file:make_dir dir))
         ('ok (file:change_mode dir #o700))
         (socket (filename:join dir "agent socket.sock")))
    (try
      ;; Standard I/O control requires no distributed or live user node.
      (let (((tuple 'ok peer _node)
             (peer:start_link
               (map 'connection 'standard_io
                    'args (cons "-pa" (code:get_path))))))
        (try
          (let* (('ok (peer:call peer 'application 'load '(cayrn_lfe)))
                 ('ok (peer:call peer 'application 'set_env
                        (list 'cayrn_lfe 'socket socket)))
                 ((tuple 'ok _)
                  (peer:call peer 'application 'ensure_all_started
                    '(cayrn_lfe)))
                 (running (lists:map (lambda (app) (element 1 app))
                            (peer:call peer 'application
                              'which_applications '())))
                 ((tuple 'ok info) (file:read_file_info socket)))
            (assert (lists:member 'cayrn_lfe running))
            (assert (lists:member 'lfe running))
            (lists:foreach
              (lambda (app) (assertNot (lists:member app running)))
              '(xrepl ranch xrepl_protocol xrepl_term))
            (assertEqual 'other (file_info-type info))
            (assertEqual #o600 (band (file_info-mode info) #o777)))
          (after (peer:stop peer))))
      (after
        (file:delete socket)
        (file:del_dir dir)))))
