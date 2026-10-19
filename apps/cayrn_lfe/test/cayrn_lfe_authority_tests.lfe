;;;; Native3 lease ownership, bounded live state and abortive-loss controls.
(defmodule cayrn_lfe_authority_tests
  (export
   (authority 2)
   (authority_capacity_test_ 0)
   (authority_churn_test_ 0)
   (authority_eof_test_ 0)
   (authority_partial_byte_test_ 0)
   (await-down 1)
   (context 6)
   (context_capacity_test_ 0)
   (context_churn_test_ 0)
   (context_only_loss_test_ 0)
   (first_frame_timeout_test_ 0)
   (listener_restart_test_ 0)
   (monitor_and_exhaustion_test_ 0)
   (paused-roles 0)
   (paused_endpoint_timeout_test_ 0)
   (pending_output_loss_test_ 0)
   (preaccept_watermark_test_ 0)
   (registry_restart_test_ 0)
   (router-failure 0)
   (router_transfer_failure_test_ 0)
   (scope_and_numeric_fences_test_ 0)
   (set-limit 1)
   (suspended_context_loss_test_ 0)
   (with-peer 1)))

(include-lib "eunit/include/eunit.hrl")
(include-file "../include/cayrn_lfe_registry.lfe")

(defspec (context_churn_test_ 0) (() (term)))
(defun context_churn_test_ ()
  "4097 contexts physically reclaim under one lease; replay cannot run source."
  (tuple 'timeout 240 #'context-churn/0))

(defun context-churn ()
  (with-peer
    (lambda (peer path)
      (let* (((tuple owner grant) (authority path #b("a")))
             (first (hello grant #b("1") #b("1") #b("a")))
             (marker (++ path ".replay"))
             (source (iolist_to_binary
                       (io_lib:format "(file:write_file ~p #b(\"BAD\"))"
                         (list marker)))))
        (lists:foreach
          (lambda (i)
            (let* ((ticket (integer_to_binary i))
                   ((tuple socket pid)
                    (context peer path grant ticket ticket #b("a"))))
              (if (=:= i 1)
                (assertEqual #b("1")
                  (value socket #b("1") #b("(set initial-binding 1)") #b("a")))
                'ok)
              (close-context peer socket pid)
              (assertEqual 0 (map_size (registry-contexts (state peer))))
              (assertEqual 0 (map_size (registry-sids (state peer))))))
          (lists:seq 1 4097))
        (refused-source path first source)
        (assertNot (filelib:is_file marker))
        (let (((tuple socket pid)
               (context peer path grant #b("5000") #b("final") #b("a"))))
          (assertEqual #b("42") (value socket #b("1") #b("42") #b("a")))
          (close-context peer socket pid))
        (assertEqual 1 (map_size (registry-leases (state peer))))
        (gen_tcp:close owner)))))

(defspec (authority_churn_test_ 0) (() (term)))
(defun authority_churn_test_ ()
  "33 exact owner retirements increase a scalar without historical maps."
  (tuple 'timeout 60
    (lambda ()
      (with-peer
        (lambda (peer path)
          (lists:foreach
            (lambda (i)
              (let* (((tuple owner grant) (authority path #b("a")))
                     (before (state peer))
                     (lease (map-get (registry-leases before) i)))
                (assertEqual (integer_to_binary i) (map-get grant #b("lease")))
                (gen_tcp:close owner)
                (down peer (lease-owner lease))
                (await-counts peer 0 0)
                (assertEqual i (registry-last-lease (state peer)))
                (refused path (hello grant #b("1") #b("old") #b("a")))))
            (lists:seq 1 33))
          (let* (((tuple owner grant) (authority path #b("a")))
                 ((tuple socket pid)
                  (context peer path grant #b("1") #b("final") #b("a"))))
            (assertEqual #b("42") (value socket #b("1") #b("42") #b("a")))
            (close-context peer socket pid)
            (gen_tcp:close owner)))))))

(defspec (scope_and_numeric_fences_test_ 0) (() (term)))
(defun scope_and_numeric_fences_test_ ()
  "Bad scopes, decimal domains and IDs are local; no visible source effect."
  (tuple 'timeout 60
    (lambda ()
      (with-peer
        (lambda (peer path)
          (let* (((tuple owner grant) (authority path #b("a")))
                 ((tuple other other-grant) (authority path #b("b")))
                 ((tuple socket pid)
                  (context peer path grant #b("1") #b("live") #b("a")))
                 (base (hello grant #b("2") #b("new") #b("a")))
                 (marker (++ path ".forbidden"))
                 (source (iolist_to_binary
                           (io_lib:format "(file:write_file ~p #b(\"BAD\"))"
                             (list marker)))))
            (lists:foreach
              (lambda (key)
                (lists:foreach
                  (lambda (bad) (refused-source path (map-set base key bad)
                                               source))
                  (list #b() 1 #b("0") #b("01") #b("+1") #b("-1")
                        #b(" 1") #b("1\n") #b("9223372036854775808"))))
              '(lease ticket))
            (lists:foreach
              (lambda (key)
                (lists:foreach
                  (lambda (bad) (refused-source path (map-set base key bad)
                                               source))
                  (list #b() 1 #b("a\n") #b("bad.dot")
                        (binary:copy #b("a") 129))))
              '(session generation authority))
            (refused-source path (map-set base 'boot #b("WRONG")) source)
            (refused-source path (map-set base 'authority #b("b")) source)
            (refused-source path
              (map-set base 'lease (map-get other-grant #b("lease")))
              source)
            ;; No invalid scope consumed either lease's next valid ticket.
            (let (((tuple fresh fresh-pid)
                   (context peer path grant #b("2") #b("new") #b("a"))))
              (assertEqual #b("42") (value fresh #b("1") #b("42") #b("a")))
              (close-context peer fresh fresh-pid))
            (let (((tuple live-b pid-b)
                   (context peer path other-grant #b("1")
                            #b("b-live") #b("b"))))
              (assertEqual #b("42") (value live-b #b("1") #b("42") #b("b")))
              (refused-source path
                (hello other-grant #b("2") #b("live") #b("b")) source)
              (refused path
                (hello other-grant #b("2") #b("b-retry") #b("b")))
              (let (((tuple next-b next-pid)
                     (context peer path other-grant #b("3")
                              #b("b-retry") #b("b"))))
                (assertEqual #b("42")
                  (value next-b #b("1") #b("42") #b("b")))
                (close-context peer next-b next-pid))
              (close-context peer live-b pid-b))
            ;; Duplicate SID consumes ticket3; its source cannot run.
            (refused-source path (hello grant #b("3") #b("live") #b("a"))
                            source)
            (refused path (hello grant #b("3") #b("unused") #b("a")))
            (assertNot (filelib:is_file marker))
            (assertEqual #b("42") (value socket #b("1") #b("42") #b("a")))
            (close-context peer socket pid)
            (gen_tcp:close owner) (gen_tcp:close other)))))))

(defspec (authority_capacity_test_ 0) (() (term)))
(defun authority_capacity_test_ ()
  "16 live owners reject the17th and duplicate; exact DOWN restores credit."
  (tuple 'timeout 60
    (lambda ()
      (with-peer
        (lambda (peer path)
          (let ((owners
                  (lists:map
                    (lambda (i) (authority path (integer_to_binary i)))
                    (lists:seq 1 16))))
            (refused path (map 'kind 'authority_hello 'version 3
                               'authority #b("overflow")))
            (refused path (map 'kind 'authority_hello 'version 3
                               'authority #b("1")))
            (assertEqual 16 (registry-last-lease (state peer)))
            (let* ((lease (map-get (registry-leases (state peer)) 1))
                   ((tuple socket _) (car owners)))
              (gen_tcp:close socket) (down peer (lease-owner lease)))
            (await-counts peer 15 0)
            (let (((tuple fresh grant) (authority path #b("fresh"))))
              (assertEqual #b("17") (map-get grant #b("lease")))
              (gen_tcp:close fresh))
            (lists:foreach (lambda (entry) (gen_tcp:close (element 1 entry)))
                           owners)))))))

(defspec (context_capacity_test_ 0) (() (term)))
(defun context_capacity_test_ ()
  "64 physical contexts reject65; a refused ticket remains consumed."
  (tuple 'timeout 60
    (lambda ()
      (with-peer
        (lambda (peer path)
          (let* (((tuple owner grant) (authority path #b("a")))
                 (contexts
                   (lists:map
                     (lambda (i)
                       (let ((id (integer_to_binary i)))
                         (context peer path grant id id #b("a"))))
                     (lists:seq 1 64))))
            (refused path (hello grant #b("65") #b("overflow") #b("a")))
            (assertEqual 64 (map_size (registry-contexts (state peer))))
            (close-context peer (element 1 (car contexts))
                               (element 2 (car contexts)))
            (await-counts peer 1 63)
            (refused path (hello grant #b("65") #b("retry") #b("a")))
            (let (((tuple socket pid)
                   (context peer path grant #b("66") #b("retry") #b("a"))))
              (assertEqual #b("42") (value socket #b("1") #b("42") #b("a")))
              (close-context peer socket pid))
            (lists:foreach
              (match-lambda (((tuple socket pid))
                              (close-context peer socket pid)))
              (cdr contexts))
            (await-counts peer 1 0)
            (gen_tcp:close owner)))))))

(defspec (monitor_and_exhaustion_test_ 0) (() (term)))
(defun monitor_and_exhaustion_test_ ()
  "Forged DOWNs cannot free credits; exhausted counters never wrap."
  (tuple 'timeout 30
    (lambda ()
      (with-peer
        (lambda (peer path)
          (let* (((tuple owner grant) (authority path #b("a")))
                 ((tuple socket pid)
                  (context peer path grant #b("1") #b("live") #b("a")))
                 (before (state peer))
                 (registry (peer:call peer 'erlang 'whereis
                             '(cayrn_lfe_registry))))
            (lists:foreach
              (lambda (target)
                (peer:call peer 'erlang 'send
                  (list registry (tuple 'DOWN (make_ref) 'process
                                        target 'normal))))
              (list pid (lease-owner (map-get (registry-leases before) 1))))
            (let ((record (map-get (registry-contexts before) pid)))
              (peer:call peer 'erlang 'send
                (list registry (tuple 'DOWN (context-monitor record)
                                      'process (self) 'normal))))
            (assertEqual before (state peer))
            (peer:call peer (MODULE) 'set-limit '(ticket))
            (refused path (hello grant #b("9223372036854775807")
                                #b("max") #b("a")))
            (peer:call peer (MODULE) 'set-limit '(lease))
            (refused path (map 'kind 'authority_hello 'version 3
                               'authority #b("b")))
            (assertEqual 9223372036854775807
              (registry-last-lease (state peer)))
            (assertEqual #b("42") (value socket #b("1") #b("42") #b("a")))
            ;; Retain a physically live record while its port is already closed.
            (peer:call peer 'sys 'suspend (list pid))
            (try
              (progn
                (peer:call peer 'erlang 'port_close
                  (list (context-socket
                          (map-get (registry-contexts (state peer)) pid))))
                (gen_tcp:close owner)
                (await-counts peer 0 1)
                (assert (peer:call peer 'erlang 'is_process_alive (list pid))))
              (after (peer:call peer 'sys 'resume (list pid))))
            (down peer pid) (await-counts peer 0 0)
            (gen_tcp:close socket)))))))

(defspec (set-limit 1) (((atom)) (term)))
(defun set-limit (which)
  "Owned-peer test-only state mutation; no production debug endpoint."
  (sys:replace_state 'cayrn_lfe_registry
    (lambda (state)
      (case which
        ('lease (set-registry state last-lease 9223372036854775807))
        ('ticket
         (let* ((leases (registry-leases state)) (lease (map-get leases 1)))
           (set-registry state leases
             (map-set leases 1
               (set-lease lease last-ticket 9223372036854775807)))))))))

(defspec (router_transfer_failure_test_ 0) (() (term)))
(defun router_transfer_failure_test_ ()
  "Actual not-owner transfer failure cleans provisional roles locally."
  (tuple 'timeout 30
    (lambda ()
      (with-peer
        (lambda (peer path)
          (let (((tuple owner grant) (authority path #b("a"))))
            (assertEqual 'ok (peer:call peer (MODULE) 'router-failure '()))
            (let (((tuple socket pid)
                   (context peer path grant #b("1") #b("live") #b("a"))))
              (assertEqual #b("42") (value socket #b("1") #b("42") #b("a")))
              (close-context peer socket pid))
            (gen_tcp:close owner)))))))

(defspec (router-failure 0) (() (term)))
(defun router-failure ()
  "Invoke the real callback outside its actual router's controlling PID."
  (let* (((tuple 'ok listener)
          (gen_tcp:listen 0 '(binary #(active false) #(packet 4)) ))
         ((tuple 'ok port) (inet:port listener))
         ((tuple 'ok client)
          (gen_tcp:connect "localhost" port '(binary #(active false)) 1000))
         ((tuple 'ok server) (gen_tcp:accept listener))
         ((tuple 'ok router) (cayrn_lfe_sup:connection server))
         ('ok (gen_tcp:controlling_process server router))
         (before (sys:get_state router)))
    (try
      (let* (((tuple 'stop reason next)
              (cayrn_lfe_connection:handle_info
                (tuple 'tcp server
                  (iolist_to_binary
                    (json:encode (map 'kind 'authority_hello 'version 3
                                      'authority #b("provisional"))))) before)))
        (assertEqual 'not_owner reason)
        (cayrn_lfe_connection:terminate reason next)
        (gen_server:stop router)
        (assertEqual '#(error closed) (gen_tcp:recv client 0 1000))
        'ok)
      (after
        (gen_tcp:close server) (gen_tcp:close client)
        (gen_tcp:close listener)))))

(defspec (first_frame_timeout_test_ 0) (() (term)))
(defun first_frame_timeout_test_ ()
  "Partial, malformed and old first frames fail without losing a peer lease."
  (tuple 'timeout 30
    (lambda ()
      (with-peer
        (lambda (peer path)
          (let* (((tuple owner grant) (authority path #b("a")))
                 (unhandshaken (connect path)))
            (assertEqual '#(error closed) (gen_tcp:recv unhandshaken 0 6500))
            (gen_tcp:close unhandshaken)
            (let ((partial (connect path)))
              (inet:setopts partial '(#(packet 0)))
              (gen_tcp:send partial #b(0))
              (assertEqual '#(error closed) (gen_tcp:recv partial 0 6500))
              (gen_tcp:close partial))
            (refused path (map 'kind 'hello 'version 2))
            (let ((bad (connect path)))
              (gen_tcp:send bad #b("not-json")) (lost bad)
              (gen_tcp:close bad))
            (let (((tuple socket pid)
                   (context peer path grant #b("1") #b("live") #b("a"))))
              (assertEqual #b("42") (value socket #b("1") #b("42") #b("a")))
              (close-context peer socket pid))
            (gen_tcp:close owner)))))))

(defspec (preaccept_watermark_test_ 0) (() (term)))
(defun preaccept_watermark_test_ ()
  "128 paused roles prevent accepting another descriptor until physical exit."
  (tuple 'timeout 30
    (lambda ()
      (with-peer
        (lambda (peer path)
          (let* (((tuple owner grant) (authority path #b("a")))
                 (listener (peer:call peer 'erlang 'whereis
                             '(cayrn_lfe_listener)))
                 ('ok (peer:call peer 'sys 'suspend (list listener)))
                 (dummy (lists:map
                          (lambda (_)
                            (element 2
                              (peer:call peer 'cayrn_lfe_sup 'connection
                                         '(undefined))))
                          (lists:seq 1 127)))
                 (waiting (connect path)))
            (try
              (progn
                (peer:call peer 'sys 'resume (list listener))
                (send-frame waiting (hello grant #b("1") #b("waiting") #b("a")))
                (assertEqual '#(error timeout) (gen_tcp:recv waiting 0 50))
                (assertEqual 128 (temporary-count peer))
                (peer:call peer 'erlang 'exit (list (car dummy) 'shutdown))
                (down peer (car dummy))
                (assertEqual #b("ready")
                  (map-get (read-frame waiting) #b("kind"))))
              (after
                (catch (peer:call peer 'sys 'resume (list listener)))
                (lists:foreach
                  (lambda (pid) (peer:call peer 'erlang 'exit
                                  (list pid 'shutdown))) dummy)
                (gen_tcp:close waiting) (gen_tcp:close owner)))))))))

(defspec (authority_eof_test_ 0) (() (term)))
(defun authority_eof_test_ ()
  "Only authority EOF destroys its active contexts; another lease stays usable."
  (tuple 'timeout 30 (lambda () (authority-loss 'eof 'false))))

(defspec (authority_partial_byte_test_ 0) (() (term)))
(defun authority_partial_byte_test_ ()
  "One raw unexpected byte retires an authority without a complete frame."
  (tuple 'timeout 30 (lambda () (authority-loss 'byte 'false))))

(defspec (suspended_context_loss_test_ 0) (() (term)))
(defun suspended_context_loss_test_ ()
  "Port loss precedes suspended callback cooperation, credits wait exact DOWN."
  (tuple 'timeout 30 (lambda () (authority-loss 'eof 'true))))

(defun authority-loss (mode suspended)
  (with-peer
    (lambda (peer path)
      (let* (((tuple owner grant) (authority path #b("a")))
             ((tuple other other-grant) (authority path #b("b")))
             ((tuple socket context)
              (context peer path grant #b("1") #b("held") #b("a")))
             ((tuple sibling sibling-pid)
              (context peer path grant #b("2") #b("sibling") #b("a")))
             ((tuple survivor survivor-pid)
              (context peer path other-grant #b("1") #b("survivor") #b("b")))
             ((tuple root io trace) (start-held peer socket context)))
        (try
          (progn
            (if suspended (peer:call peer 'sys 'suspend (list context)) 'ok)
            (retire owner mode)
            (lost socket)
            (lost sibling)
            (if suspended
              (progn
                (assert (peer:call peer 'erlang 'is_process_alive
                          (list context)))
                (await-counts peer 1 2)
                (assert (maps:is_key #b("held") (registry-sids (state peer)))))
              'ok)
            (assertEqual #b("42")
              (value survivor #b("1") #b("42") #b("b")))
            (if suspended (peer:call peer 'sys 'resume (list context)) 'ok)
            (lists:foreach (lambda (pid) (down peer pid))
                           (list context sibling-pid root io))
            (assert-no-trace peer trace)
            (await-counts peer 1 1)
            (close-context peer survivor survivor-pid))
          (after
            (catch (peer:call peer 'sys 'resume (list context)))
            (gen_tcp:close socket) (gen_tcp:close sibling)
            (gen_tcp:close survivor) (gen_tcp:close owner)
            (gen_tcp:close other)))))))

(defspec (pending_output_loss_test_ 0) (() (term)))
(defun pending_output_loss_test_ ()
  "Actual send_pend>0 remains positive through authority-only retirement."
  (tuple 'timeout 30 #'pending-output-loss/0))

(defun pending-output-loss ()
  (with-peer
    (lambda (peer path)
      (let* (((tuple owner grant) (authority path #b("a")))
             ((tuple other other-grant) (authority path #b("b")))
             ((tuple socket context)
              (context peer path grant #b("1") #b("pending") #b("a")))
             ((tuple survivor survivor-pid)
              (context peer path other-grant #b("1") #b("survivor") #b("b")))
             (port (map-get (peer:call peer 'sys 'get_state (list context))
                            'socket))
             ((tuple watchdog watchdog-ref)
              (spawn_monitor
                (lambda ()
                  (receive
                    ('done 'ok)
                    (after 15000
                      (catch (peer:stop peer))
                      (error 'pressure_fixture_watchdog_fired)))))))
        (try
          (progn
            (inet:setopts socket '(#(recbuf 1024)))
            (peer:call peer 'inet 'setopts (list port '(#(sndbuf 1024))))
            (io:format 'user "pressure buffers client=~p native=~p~n"
              (list (inet:getopts socket '(recbuf))
                    (peer:call peer 'inet 'getopts (list port '(sndbuf)))))
            (dispatch socket #b("1")
              #b("(progn (io:format \"START\" ()) "
                 "(lists:foreach (lambda (i) "
                 "(! (group_leader) (tuple 'io_request (self) (make_ref) "
                 "(tuple 'put_chars 'unicode (lists:duplicate 8000 120))))) "
                 "(lists:seq 1 32)) (receive ('release 42)))") #b("a"))
            (let* ((start (read-frame socket))
                   ('true (=:= #b("START") (map-get start #b("text"))))
                   (active (await-active peer context 500))
                   ((tuple root _ _ io) (map-get active 'active))
                   ((tuple _ trace _ _) (map-get (map-get active 'origins) io)))
              (assert-trace peer trace)
              (send-frame socket
                (map 'kind 'ack 'position (map-get start #b("position"))))
              (await-pending peer port 1000)
              ;; Do not read client bytes or release evaluated code to help.
              (let ((pending (send-pending peer port)))
                (assert (> pending 0))
                (io:format 'user "retirement decision send_pend=~p~n"
                  (list pending)))
              (gen_tcp:close owner)
              (lists:foreach (lambda (pid) (down peer pid))
                             (list context root io))
              (await-counts peer 1 1)
              (assert-no-trace peer trace)
              (assertEqual #b("42")
                (value survivor #b("1") #b("42") #b("b")))
              (close-context peer survivor survivor-pid)))
          (after
            (gen_tcp:close socket) (gen_tcp:close survivor)
            (gen_tcp:close owner) (gen_tcp:close other)
            (! watchdog 'done)
            (receive
              ((tuple 'DOWN ref 'process pid reason)
               (when (=:= ref watchdog-ref) (=:= pid watchdog))
               (assertEqual 'normal reason))
              (after 1000 (error 'watchdog_cleanup_failed)))))))))

(defspec (context_only_loss_test_ 0) (() (term)))
(defun context_only_loss_test_ ()
  "Context-only loss preserves its sibling and both authority owners."
  (tuple 'timeout 30
    (lambda ()
      (with-peer
        (lambda (peer path)
          (let* (((tuple owner grant) (authority path #b("a")))
                 ((tuple first first-pid)
                  (context peer path grant #b("1") #b("first") #b("a")))
                 ((tuple second second-pid)
                  (context peer path grant #b("2") #b("second") #b("a"))))
            (gen_tcp:close first) (down peer first-pid)
            (await-counts peer 1 1)
            (assertEqual #b("42") (value second #b("1") #b("42") #b("a")))
            (close-context peer second second-pid)
            (gen_tcp:close owner)))))))

(defspec (registry_restart_test_ 0) (() (term)))
(defun registry_restart_test_ ()
  "Nonblocked registry restart creates a fresh boot and rejects old scope."
  (tuple 'timeout 30 (lambda () (restart-role 'cayrn_lfe_registry))))

(defspec (listener_restart_test_ 0) (() (term)))
(defun listener_restart_test_ ()
  "Listener failure restarts the domain, fresh boot and old-scope rejection."
  (tuple 'timeout 30 (lambda () (restart-role 'cayrn_lfe_listener))))

(defun restart-role (role)
  (with-peer
        (lambda (peer path)
          (let* (((tuple owner grant) (authority path #b("a")))
                 ((tuple socket pid)
                  (context peer path grant #b("1") #b("old") #b("a")))
                 (registry (peer:call peer 'erlang 'whereis
                             '(cayrn_lfe_registry))))
            (if (=:= role 'cayrn_lfe_listener)
              (peer:call peer 'gen_server 'stop
                (list (peer:call peer 'erlang 'whereis (list role))
                      'shutdown 1000))
              (peer:call peer 'erlang 'exit (list registry 'kill)))
            (down peer registry) (down peer pid)
            (await-new peer registry 500)
            (let* (((tuple fresh new-grant) (authority path #b("a")))
                   ((tuple live live-pid)
                    (context peer path new-grant #b("1") #b("new") #b("a"))))
              (assertNotEqual (map-get grant #b("boot"))
                              (map-get new-grant #b("boot")))
              (refused path (hello grant #b("2") #b("stale") #b("a")))
              (assertEqual #b("42") (value live #b("1") #b("42") #b("a")))
              (close-context peer live live-pid)
              (gen_tcp:close fresh))
            (gen_tcp:close socket) (gen_tcp:close owner)))))

(defspec (paused_endpoint_timeout_test_ 0) (() (term)))
(defun paused_endpoint_timeout_test_ ()
  "Paused roles own actual ports, time out and allocate no environment."
  (tuple 'timeout 15
    (lambda ()
      (with-peer
        (lambda (peer _path)
          (assertEqual 'ok (peer:call peer (MODULE) 'paused-roles '() 8000))
          (await-counts peer 0 0))))))

(defspec (paused-roles 0) (() 'ok))
(defun paused-roles ()
  "Exercise all paused startup roles concurrently on actual transferred ports."
  (let ((workers
          (lists:map
            (lambda (role)
              (spawn_monitor (lambda () (paused-role role))))
            '(connection authority context))))
    (try
      (lists:foreach
        (match-lambda
          (((tuple pid ref))
           (receive
             ((tuple 'DOWN incoming 'process target reason)
              (when (=:= incoming ref) (=:= target pid))
              (assertEqual 'normal reason))
             (after 7500 (error 'paused_role_socket_leaked))))) workers)
      (after
        (lists:foreach
          (match-lambda (((tuple pid ref))
                          (exit pid 'kill)
                          (erlang:demonitor ref '(flush)))) workers))))
  'ok)

(defun paused-role (role)
  (let* (((tuple 'ok listener)
          (gen_tcp:listen 0 '(binary #(active false) #(packet 4))))
         ((tuple 'ok port) (inet:port listener))
         ((tuple 'ok client)
          (gen_tcp:connect "localhost" port
            '(binary #(active false) #(packet 4)) 1000))
         ((tuple 'ok server) (gen_tcp:accept listener))
         ((tuple 'ok child) (call 'cayrn_lfe_sup role server))
         (ref (monitor 'process child)))
    (try
      (let (('ok (gen_tcp:controlling_process server child)))
        (if (=:= role 'context)
          (assertEqual 'undefined (map-get (sys:get_state child) 'env))
          'ok)
        ;; No activation: the real provisional owner must time out itself.
        (assertEqual '#(error closed) (gen_tcp:recv client 0 6500))
        (receive
          ((tuple 'DOWN incoming 'process pid _)
           (when (=:= incoming ref) (=:= pid child)) 'ok)
          (after 500 (error 'paused_owner_not_reaped))))
      (after
        (catch (gen_server:stop child 'normal 1000))
        (erlang:demonitor ref '(flush))
        (gen_tcp:close server) (gen_tcp:close client)
        (gen_tcp:close listener)))))

;;; Owned fixture helpers; no running user node or product instrumentation.

(defspec (with-peer 1) (((function)) (term)))
(defun with-peer (function)
  "Run on a fresh standard-I/O peer and always dispose the whole owned node."
  (let* ((dir (++ "/private/tmp/cayrn-authority-" (os:getpid) "-"
                 (integer_to_list
                   (erlang:unique_integer '(positive monotonic)))))
         ('ok (file:make_dir dir)) ('ok (file:change_mode dir #o700))
         (path (filename:join dir "agent socket.sock")))
    (try
      (let (((tuple 'ok peer _)
             (peer:start_link (map 'connection 'standard_io
                                  'args (cons "-pa" (code:get_path))))))
        (try
          (let* (('ok (peer:call peer 'application 'load '(cayrn_lfe)))
                 ('ok (peer:call peer 'application 'set_env
                        (list 'cayrn_lfe 'socket path)))
                 ((tuple 'ok _) (peer:call peer 'application 'ensure_all_started
                                  '(cayrn_lfe))))
            (funcall function peer path))
          (after (peer:stop peer))))
      (after (file:delete path) (file:del_dir dir)))))

(defspec (authority 2) (((string) (binary)) (term)))
(defun authority (path id)
  "Open native3 authority and retain its socket through context lifetime."
  (let ((socket (connect path)))
    (send-frame socket (map 'kind 'authority_hello 'version 3 'authority id))
    (let ((grant (read-frame socket)))
      (assertEqual #b("authority_ready") (map-get grant #b("kind")))
      (tuple socket grant))))

(defspec (context 6) (((pid) (string) (map) (binary) (binary) (binary)) (term)))
(defun context (peer path grant ticket sid authority)
  "Admit a real context and discover its exact registry/module identity."
  (let ((socket (connect path)))
    (send-frame socket (hello grant ticket sid authority))
    (let* ((ready (read-frame socket))
           ('true (=:= #b("ready") (map-get ready #b("kind"))))
           (pid (map-get (registry-sids (state peer)) sid))
           (children (peer:call peer 'supervisor 'which_children
                       '(cayrn_lfe_sup))))
      (assertEqual (map-get grant #b("boot")) (map-get ready #b("boot")))
      (assertEqual (map-get grant #b("lease")) (map-get ready #b("lease")))
      (assertEqual ticket (map-get ready #b("ticket")))
      (assert (lists:any
                (match-lambda
                  (((tuple _ child _ (list 'cayrn_lfe_context)))
                   (=:= child pid))
                  ((_entry) 'false)) children))
      (tuple socket pid))))

(defun hello (grant ticket sid authority)
  (map 'kind 'hello 'version 3 'session sid 'generation #b("g")
       'authority authority 'boot (map-get grant #b("boot"))
       'lease (map-get grant #b("lease")) 'ticket ticket))

(defun connect (path)
  (let (((tuple 'ok socket)
         (gen_tcp:connect (tuple 'local path) 0
           '(binary #(active false) #(packet 4)) 1000))) socket))

(defun refused (path hello)
  (refused-source path hello #b("(error 'FORBIDDEN)")))

(defun refused-source (path hello source)
  (let ((socket (connect path)))
    (try
      (progn
        (send-frame socket hello)
        ;; The invalid first frame and evaluation are on the same TCP stream.
        (gen_tcp:send socket
          (json:encode (map 'kind 'dispatch 'operation #b("1")
                            'source source 'generation #b("g")
                            'authority #b("a"))))
        (lost socket))
      (after (gen_tcp:close socket)))))

(defun close-context (peer socket pid)
  (send-frame socket (map 'kind 'close))
  (assertEqual #b("closed") (map-get (read-frame socket) #b("kind")))
  (down peer pid)
  (gen_tcp:close socket)
  (await-absent peer pid 500))

(defun state (peer)
  (peer:call peer 'sys 'get_state '(cayrn_lfe_registry) 2000))

(defun temporary-count (peer)
  (- (proplists:get_value 'active
       (peer:call peer 'supervisor 'count_children '(cayrn_lfe_sup))) 2))

(defun down (peer pid)
  (assertEqual 'ok (peer:call peer (MODULE) 'await-down (list pid) 3000)))

(defspec (await-down 1) (((pid)) (term)))
(defun await-down (pid)
  "Wait exact known PID/ref DOWN, including already physically dead peers."
  (let ((ref (monitor 'process pid)))
    (receive
      ((tuple 'DOWN incoming 'process target _)
       (when (=:= incoming ref) (=:= target pid)) 'ok)
      (after 2500 (erlang:demonitor ref '(flush))
                  (error 'owned_process_leaked)))))

(defun await-counts (peer leases contexts)
  (await-counts peer leases contexts 500))

(defun await-counts
  ((_peer _leases _contexts 0) (error 'registry_reclamation_timeout))
  ((peer leases contexts attempts)
   (let ((s (state peer)))
     (if (andalso (=:= leases (map_size (registry-leases s)))
                  (=:= contexts (map_size (registry-contexts s))))
       'ok
       (progn (timer:sleep 2)
         (await-counts peer leases contexts (- attempts 1)))))))

(defun await-absent
  ((_peer _pid 0) (error 'context_credit_not_reaped))
  ((peer pid attempts)
   (if (maps:is_key pid (registry-contexts (state peer)))
     (progn (timer:sleep 2) (await-absent peer pid (- attempts 1)))
     'ok)))

(defun await-new
  ((_peer _previous 0) (error 'registry_restart_timeout))
  ((peer previous attempts)
   (let ((pid (peer:call peer 'erlang 'whereis '(cayrn_lfe_registry))))
     (if (andalso (is_pid pid) (=/= previous pid)
                  (is_pid (peer:call peer 'erlang 'whereis
                            '(cayrn_lfe_listener))))
       'ok
       (progn (timer:sleep 2) (await-new peer previous (- attempts 1)))))))

(defun start-held (peer socket context)
  (dispatch socket #b("1")
    #b("(progn (io:format \"START\" ()) (receive ('release 42)))") #b("a"))
  (let* ((output (read-frame socket))
         ('true (=:= #b("START") (map-get output #b("text"))))
         (state (await-active peer context 500))
         ((tuple root _ _ io) (map-get state 'active))
         ((tuple _ trace _ _) (map-get (map-get state 'origins) io)))
    (assert-trace peer trace)
    (send-frame socket
      (map 'kind 'ack 'position (map-get output #b("position"))))
    (tuple root io trace)))

(defun assert-trace (peer trace)
  (assert (lists:member (element 2 trace)
            (peer:call peer 'trace 'session_info '(all)))))

(defun assert-no-trace (peer trace)
  (assertNot (lists:member (element 2 trace)
               (peer:call peer 'trace 'session_info '(all)))))

(defun await-active
  ((_peer _context 0) (error 'no_active_evaluator))
  ((peer context attempts)
   (let ((state (peer:call peer 'sys 'get_state (list context))))
     (if (=:= 'undefined (map-get state 'active))
       (progn (timer:sleep 2) (await-active peer context (- attempts 1)))
       state))))

(defun send-pending (peer port)
  (let (((tuple 'ok stats)
         (peer:call peer 'inet 'getstat (list port '(send_pend)) 2000)))
    (proplists:get_value 'send_pend stats)))

(defun await-pending
  ((_peer _port 0) (error 'positive_send_pressure_not_established))
  ((peer port attempts)
   (let ((pending (send-pending peer port)))
     (if (> pending 0)
       (io:format 'user "positive native send_pend=~p~n" (list pending))
       (progn (timer:sleep 2) (await-pending peer port (- attempts 1)))))))

(defun retire (socket mode)
  (case mode
    ('eof (gen_tcp:close socket))
    ('byte (inet:setopts socket '(#(packet 0)))
           (gen_tcp:send socket #b(0)))))

(defun lost (socket)
  (case (gen_tcp:recv socket 0 2000)
    ((tuple 'error 'closed) 'ok)
    ((tuple 'error 'econnreset) 'ok)
    (other (error (tuple 'expected_transport_loss other)))))

(defun dispatch (socket token source authority)
  (send-frame socket
    (map 'kind 'dispatch 'operation token 'source source
         'generation #b("g") 'authority authority)))

(defun value (socket token source authority)
  (dispatch socket token source authority)
  (let ((result (until-outcome socket)))
    (assertEqual #b("succeeded") (map-get result #b("phase")))
    (map-get result #b("value"))))

(defun until-outcome (socket)
  (let ((frame (read-frame socket)))
    (case (map-get frame #b("kind"))
      (#b("outcome") frame)
      (#b("output")
       (send-frame socket (map 'kind 'ack 'position
                              (map-get frame #b("position"))))
       (until-outcome socket)))))

(defun send-frame (socket value)
  (let (('ok (gen_tcp:send socket (json:encode value)))) 'ok))

(defun read-frame (socket)
  (let (((tuple 'ok bytes) (gen_tcp:recv socket 0 3000))) (json:decode bytes)))
