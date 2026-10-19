;;;; Startup isolation from the legacy parent EUnit node.
(defmodule cayrn_lfe_application_tests
  (export
   (application_stop_reaps_endpoint_test_ 0)
   (await-port-down 1)
   (callback-guard 2)
   (child-failure 1)
   (child_kill_keeps_endpoint_test_ 0)
   (endpoint-info 0)
   (identity_guard_preserves_replacements_test_ 0)
   (independent_application_start_test_ 0)
   (queued-parent-call 0)
   (queued_parent_call_survives_registry_kill_test_ 0)
   (relative_path_survives_evaluated_cwd_test_ 0)
   (startup-refusal 1)
   (startup_refusal_cleans_acquisition_test_ 0)))

(include-lib "eunit/include/eunit.hrl")
(include-lib "kernel/include/file.hrl")

(defspec (independent_application_start_test_ 0) (() (term)))
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
            (assert (lists:member 'crypto running))
            (assert (lists:member 'compiler running))
            (lists:foreach
              (lambda (app) (assertNot (lists:member app running)))
              '(xrepl ranch xrepl_protocol xrepl_term))
            (assertEqual 'other (file_info-type info))
            (assertEqual #o600 (band (file_info-mode info) #o777)))
          (after (peer:stop peer))))
      (after
        (file:delete socket)
        (file:del_dir dir)))))

;;; Stable application ownership across untrappable child failure.

(defspec (child_kill_keeps_endpoint_test_ 0) (() (term)))
(defun child_kill_keeps_endpoint_test_ ()
  "Kill either permanent child; reuse the exact live app-owned endpoint."
  (tuple 'timeout 30
    (lambda ()
      (lists:foreach
        (lambda (role)
          (cayrn_lfe_authority_tests:with-peer
            (lambda (peer path)
              (let* (((tuple owner grant)
                      (cayrn_lfe_authority_tests:authority path #b("a")))
                     ((tuple socket context)
                      (cayrn_lfe_authority_tests:context peer path grant
                        #b("1") #b("old") #b("a"))))
                (try
                  (progn
                    (assertEqual #b("1")
                      (evaluate socket #b("1") #b("(set retained 1)")))
                    (assertEqual 'ok
                      (peer:call peer (MODULE) 'child-failure (list role) 8000))
                    (assertEqual 'ok
                      (peer:call peer 'cayrn_lfe_authority_tests 'await-down
                        (list context)))
                    (assert-fresh peer path grant))
                  (after (gen_tcp:close socket) (gen_tcp:close owner)))))))
        '(cayrn_lfe_registry cayrn_lfe_listener)))))

(defspec (child-failure 1) (((atom)) 'ok))
(defun child-failure (role)
  "Assert actual child kill preserves app owner, port, path and Unix inode."
  (let* ((before (endpoint-info))
         (registry (whereis 'cayrn_lfe_registry))
         (children (temporary-children))
         (target (whereis role))
         (ref (monitor 'process target))
         (port-ref (monitor 'port (map-get before 'socket))))
    (exit target 'kill)
    (receive
      ((tuple 'DOWN incoming 'process pid 'killed)
       (when (=:= incoming ref) (=:= pid target)) 'ok)
      (after 3000 (error 'child_kill_not_observed)))
    (lists:foreach
                  #'cayrn_lfe_authority_tests:await-down/1 children)
    (await-new-registry registry 3000)
    (assertEqual before (endpoint-info))
    (assert-no-port-down port-ref (map-get before 'socket))
    (erlang:demonitor port-ref '(flush))
    'ok))

(defspec (queued_parent_call_survives_registry_kill_test_ 0) (() (term)))
(defun queued_parent_call_survives_registry_kill_test_ ()
  "LR-01 observes an accepted-port start_child behind registry EXIT."
  (tuple 'timeout 30
    (lambda ()
      (cayrn_lfe_authority_tests:with-peer
        (lambda (peer path)
          (let* (((tuple owner grant)
                  (cayrn_lfe_authority_tests:authority path #b("a")))
                 ((tuple socket context)
                  (cayrn_lfe_authority_tests:context peer path grant
                    #b("1") #b("old") #b("a"))))
            (try
              (progn
                (assertEqual 'ok
                  (peer:call peer (MODULE) 'queued-parent-call '() 10000))
                (peer:call peer 'cayrn_lfe_authority_tests 'await-down
                  (list context))
                (assert-fresh peer path grant))
              (after (gen_tcp:close socket) (gen_tcp:close owner)))))))))

(defspec (queued-parent-call 0) (() 'ok))
(defun queued-parent-call ()
  "Force exact queued parent-call ordering with guaranteed owned-peer resume."
  (let* ((sup (whereis 'cayrn_lfe_sup))
         (registry (whereis 'cayrn_lfe_registry))
         (listener (whereis 'cayrn_lfe_listener))
         (before (endpoint-info))
         (listener-ref (monitor 'process listener))
         (registry-ref (monitor 'process registry))
         (port-ref (monitor 'port (map-get before 'socket)))
         (children (temporary-children)))
    (await-accept listener 1000)
    (assert (erlang:suspend_process listener))
    (try
      (let (('true (accepting? listener))
            ('ok (sys:suspend sup)))
        (exit registry 'kill)
        (receive
          ((tuple 'DOWN incoming 'process pid 'killed)
           (when (=:= incoming registry-ref) (=:= pid registry)) 'ok)
          (after 1000 (error 'registry_down_not_observed)))
        (await-registry-exit sup registry 1000)
        (let* (((tuple 'ok raw)
                (gen_tcp:connect (tuple 'local (map-get before 'path)) 0
                  '(binary #(active false) #(packet 4)) 1000)))
          (try
            (progn
              (assert (erlang:resume_process listener))
              (let ((accepted (await-queued-accept sup registry listener 1000)))
                (assertEqual (tuple 'connected listener)
                  (erlang:port_info accepted 'connected))
                (io:format 'user
                  "LR-01 registry EXIT before start_child; accepted owner=~p~n"
                  (list listener))
                (sys:resume sup)
                (receive
                  ((tuple 'DOWN incoming 'process pid reason)
                   (when (=:= incoming listener-ref) (=:= pid listener))
                   (assertEqual 'killed reason))
                  (after 5000 (error 'blocked_listener_not_reaped)))
                (await-port-down accepted)
                (lists:foreach
                  #'cayrn_lfe_authority_tests:await-down/1 children)
                (await-new-registry registry 3000)
                (assertEqual before (endpoint-info))
                (assert-no-port-down port-ref (map-get before 'socket))))
            (after (gen_tcp:close raw)))))
      (after
        (catch (erlang:resume_process listener))
        (catch (sys:resume sup))
        (erlang:demonitor listener-ref '(flush))
        (erlang:demonitor registry-ref '(flush))
        (erlang:demonitor port-ref '(flush)))))
  'ok)

(defun accepting? (listener)
  (case (process_info listener 'current_stacktrace)
    ((tuple 'current_stacktrace stack)
     (lists:any
       (match-lambda
         (((tuple 'prim_inet 'accept0 _ _)) 'true)
         ((_entry) 'false)) stack))
    (_ 'false)))

(defun await-accept
  ((_listener 0) (error 'accept_stack_precondition_missing))
  ((listener attempts)
   (if (accepting? listener) 'ok
     (progn (timer:sleep 1) (await-accept listener (- attempts 1))))))

(defun registry-exit-queued? (sup registry)
  (let (((tuple 'messages messages) (process_info sup 'messages)))
    (lists:any
      (match-lambda
        (((tuple 'EXIT pid 'killed)) (=:= pid registry))
        ((_message) 'false)) messages)))

(defun await-registry-exit
  ((_sup _registry 0) (error 'registry_exit_not_queued))
  ((sup registry attempts)
   (if (registry-exit-queued? sup registry) 'ok
     (progn (timer:sleep 1)
       (await-registry-exit sup registry (- attempts 1))))))

(defun await-queued-accept
  ((_sup _registry _listener 0) (error 'pending_accept_call_not_observed))
  ((sup registry listener attempts)
   (let* (((tuple 'messages messages) (process_info sup 'messages))
          (exit-index (message-index
                        (lambda (message)
                          (=:= message (tuple 'EXIT registry 'killed)))
                        messages))
          (calls (lists:filtermap
                   (match-lambda
                     (((tuple '$gen_call (tuple caller _) (tuple 'start_child
                          (map 'start (tuple 'cayrn_lfe_connection
                                             'start_link (list socket))))))
                      (when (=:= caller listener)) (tuple 'true socket))
                     ((_message) 'false)) messages)))
     (case calls
       ((list socket)
        (let ((call-index (message-index
                            (match-lambda
                              (((tuple '$gen_call (tuple caller _) _))
                               (=:= caller listener))
                              ((_message) 'false)) messages)))
          (assert (> exit-index 0))
          (assert (> call-index exit-index))
          socket))
       (_ (timer:sleep 1)
          (await-queued-accept sup registry listener (- attempts 1)))))))

(defun message-index (predicate messages)
  (message-index predicate messages 1))

(defun message-index
  ((_predicate '() _index) 0)
  ((predicate (cons head tail) index)
   (if (funcall predicate head) index
     (message-index predicate tail (+ index 1)))))

(defspec (relative_path_survives_evaluated_cwd_test_ 0) (() (term)))
(defun relative_path_survives_evaluated_cwd_test_ ()
  "Resolve relative startup once; evaluated cwd cannot relocate restarts."
  (tuple 'timeout 30
    (lambda ()
      (with-owned-peer
        (lambda (peer dir path)
          (let* ((startup (filename:dirname path))
                 (moved (filename:join dir "moved"))
                 ('ok (file:make_dir moved))
                 (name (filename:basename path))
                 ((tuple 'ok old-cwd) (peer:call peer 'file 'get_cwd '())))
            (try
              (progn
                (peer:call peer 'file 'set_cwd (list startup))
                (start-native peer name)
                (let* (((tuple owner grant)
                        (cayrn_lfe_authority_tests:authority path #b("a")))
                       ((tuple socket _)
                        (cayrn_lfe_authority_tests:context peer path grant
                          #b("1") #b("cwd") #b("a")))
                       (source (iolist_to_binary
                                 (io_lib:format "(file:set_cwd ~p)"
                                   (list moved)))))
                  (try
                    (progn
                      (assertEqual #b("ok") (evaluate socket #b("1") source))
                      (peer:call peer (MODULE) 'child-failure
                        '(cayrn_lfe_registry) 8000)
                      (assert-fresh peer path grant)
                      (assertEqual (tuple 'ok name)
                        (peer:call peer 'application 'get_env
                          '(cayrn_lfe socket)))
                      (assertEqual '#(error enoent)
                        (file:read_link_info (filename:join moved name))))
                    (after (gen_tcp:close socket) (gen_tcp:close owner)))))
              (after
                (peer:call peer 'file 'set_cwd (list old-cwd))
                (file:del_dir moved)))))))))

(defspec (application_stop_reaps_endpoint_test_ 0) (() (term)))
(defun application_stop_reaps_endpoint_test_ ()
  "Actual app stop reaps exact listenport/path; restart creates a fresh boot."
  (tuple 'timeout 30
    (lambda ()
      (cayrn_lfe_authority_tests:with-peer
        (lambda (peer path)
          (let* (((tuple owner grant)
                  (cayrn_lfe_authority_tests:authority path #b("a")))
                 ((tuple socket context)
                  (cayrn_lfe_authority_tests:context peer path grant
                    #b("1") #b("old") #b("a")))
                 (before (peer:call peer (MODULE) 'endpoint-info '())))
            (assertEqual 'ok
              (peer:call peer 'application 'stop '(cayrn_lfe)))
            (peer:call peer (MODULE) 'await-port-down
              (list (map-get before 'socket)))
            (peer:call peer 'cayrn_lfe_authority_tests 'await-down
              (list (map-get before 'owner)))
            (peer:call peer 'cayrn_lfe_authority_tests 'await-down
              (list context))
            (assertEqual '#(error enoent) (file:read_link_info path))
            (start-native peer path)
            (assert-fresh peer path grant)
            (gen_tcp:close socket) (gen_tcp:close owner)))))))

(defspec (identity_guard_preserves_replacements_test_ 0) (() (term)))
(defun identity_guard_preserves_replacements_test_ ()
  "Real captured AppState cannot remove replacement file, symlink or socket."
  (tuple 'timeout 30
    (lambda ()
      (lists:foreach
        (lambda (kind)
          (with-owned-peer
            (lambda (peer _dir path)
              (assertEqual 'ok
                (peer:call peer (MODULE) 'callback-guard
                  (list path kind) 8000)))))
        '(regular symlink socket absent)))))

(defspec (callback-guard 2) (((string) (atom)) 'ok))
(defun callback-guard (path kind)
  "Use actual start/2 State and stop/1 on its still-live callback owner."
  (process_flag 'trap_exit 'true)
  (application:set_env 'cayrn_lfe 'socket path)
  (let* (((tuple 'ok sup state) (cayrn_lfe_app:start 'normal '()))
         (endpoint (endpoint-info))
         (port (map-get endpoint 'socket))
         (backup (++ path ".owned-inode"))
         (target (++ path ".target")))
    (assertEqual (self) (map-get endpoint 'owner))
    (try
      (progn
        (gen_server:stop sup 'shutdown 3000)
        (assertEqual (tuple 'connected (self))
          (erlang:port_info port 'connected))
        (let ((ref (monitor 'port port)))
          (gen_tcp:close port)
          (receive
            ((tuple 'DOWN incoming 'port socket _)
             (when (=:= incoming ref) (=:= socket port)) 'ok)
            (after 1000 (error 'callback_owned_port_leaked))))
        ;; Pin captured inode so the different-socket oracle cannot hit ABA.
        (let (('ok (file:make_link path backup))
              ('ok (file:delete path))) 'ok)
        (let ((replacement
                (case kind
                  ('regular (file:write_file path #b("KEEP")) 'undefined)
                  ('symlink (file:write_file target #b("KEEP"))
                            (file:make_symlink target path) 'undefined)
                  ('socket
                   (let (((tuple 'ok socket)
                          (gen_tcp:listen 0
                            (list 'binary '#(active false)
                                  (tuple 'ifaddr (tuple 'local path))))))
                     socket))
                  ('absent 'undefined))))
          (try
            (let ((before (file:read_link_info path)))
              (if (=:= kind 'socket)
                (let (((tuple 'ok old-info) (file:read_link_info backup))
                      ((tuple 'ok new-info) before))
                  (assertNotEqual (file_info-inode old-info)
                                  (file_info-inode new-info)))
                'ok)
              (assertEqual 'ok (cayrn_lfe_app:stop state))
              (assertEqual before (file:read_link_info path))
              (if (=:= kind 'socket)
                (assertEqual '#(error timeout) (gen_tcp:accept replacement 0))
                'ok))
            (after
              (if (is_port replacement) (gen_tcp:close replacement) 'ok)))))
      (after
        (catch (gen_server:stop sup 'shutdown 3000))
        (cayrn_lfe_app:stop state)
        (file:delete path) (file:delete backup) (file:delete target))))
  'ok)

(defspec (startup_refusal_cleans_acquisition_test_ 0) (() (term)))
(defun startup_refusal_cleans_acquisition_test_ ()
  "Supstart refusal reaps new acquisition; failed bind preserves the peer."
  (tuple 'timeout 30
    (lambda ()
      (cayrn_lfe_authority_tests:with-peer
        (lambda (peer path)
          (let* (((tuple owner grant)
                  (cayrn_lfe_authority_tests:authority path #b("a")))
                 ((tuple socket context)
                  (cayrn_lfe_authority_tests:context peer path grant
                    #b("1") #b("live") #b("a"))))
            (try
              (progn
                (assertEqual 'ok
                  (peer:call peer (MODULE) 'startup-refusal (list path) 8000))
                (assertEqual #b("42") (evaluate socket #b("1") #b("42")))
                (send-frame socket (map 'kind 'close))
                (assertEqual #b("closed")
                  (map-get (read-frame socket) #b("kind")))
                (peer:call peer 'cayrn_lfe_authority_tests 'await-down
                  (list context)))
              (after (gen_tcp:close socket) (gen_tcp:close owner)))))))))

(defspec (startup-refusal 1) (((string)) 'ok))
(defun startup-refusal (path)
  "Call real start with existing Sup/live bind; never terminate the old tree."
  (let* ((sup (whereis 'cayrn_lfe_sup))
         (endpoint (endpoint-info))
         (new-path (++ path ".new"))
         (before (lists:sort (erlang:ports))))
    (try
      (progn
        ;; Binding the existing healthy endpoint must fail BEFORE acquisition.
        (assertMatch (tuple 'error _) (cayrn_lfe_app:start 'normal '()))
        (assertEqual endpoint (endpoint-info))
        ;; Binding a new endpoint succeeds, but named Supstart must refuse.
        (application:set_env 'cayrn_lfe 'socket new-path)
        (assertMatch (tuple 'error (tuple 'already_started _))
          (cayrn_lfe_app:start 'normal '()))
        (assertEqual '#(error enoent) (file:read_link_info new-path))
        (assertEqual before (lists:sort (erlang:ports)))
        (assertEqual sup (whereis 'cayrn_lfe_sup))
        (assertEqual endpoint (endpoint-info)))
      (after (application:set_env 'cayrn_lfe 'socket path))))
  'ok)

(defspec (endpoint-info 0) (() (map)))
(defun endpoint-info ()
  "Observe actual borrowed endpoint and connected owner on the test-owned node."
  (let* ((listener (whereis 'cayrn_lfe_listener))
         (registry (whereis 'cayrn_lfe_registry))
         (state (sys:get_state listener))
         (socket (map-get state 'socket)) (path (map-get state 'path))
         ((tuple 'connected owner) (erlang:port_info socket 'connected))
         ((tuple 'ok info) (file:read_link_info path)))
    (assert (is_process_alive owner))
    (assertNotEqual listener owner)
    (assertNotEqual registry owner)
    (assertEqual (filename:absname path) path)
    (map 'socket socket 'owner owner 'path path
         'identity (tuple (file_info-major_device info)
                          (file_info-minor_device info) (file_info-inode info)
                          (band (file_info-mode info) #o170000)))))

(defun temporary-children ()
  (lists:filtermap
    (match-lambda
      (((tuple _ pid _ (list module)))
       (when (=/= module 'cayrn_lfe_listener)
             (=/= module 'cayrn_lfe_registry)) (tuple 'true pid))
      ((_child) 'false))
    (supervisor:which_children 'cayrn_lfe_sup)))

(defspec (await-port-down 1) (((port)) 'ok))
(defun await-port-down (port)
  "Observe physical exact port/ref DOWN, not pathname absence alone."
  (let ((ref (monitor 'port port)))
    (receive
      ((tuple 'DOWN incoming 'port socket _)
       (when (=:= incoming ref) (=:= socket port)) 'ok)
      (after 1000 (erlang:demonitor ref '(flush))
                  (error 'owned_port_not_reaped)))))

(defun assert-no-port-down (ref port)
  (assertNotEqual 'undefined (erlang:port_info port))
  (receive
    ((tuple 'DOWN incoming 'port socket _)
     (when (=:= incoming ref) (=:= socket port))
     (error 'app_owned_listenport_died))
    (after 0 'ok)))

(defun await-new-registry
  ((_old 0) (error 'new_registry_not_ready))
  ((old attempts)
   (let ((registry (whereis 'cayrn_lfe_registry))
         (listener (whereis 'cayrn_lfe_listener)))
     (if (andalso (is_pid registry) (=/= registry old) (is_pid listener))
       'ok
       (progn (timer:sleep 1) (await-new-registry old (- attempts 1)))))))

(defun assert-fresh (peer path old-grant)
  (let* (((tuple owner grant)
          (cayrn_lfe_authority_tests:authority path #b("a")))
         ((tuple socket context)
          (cayrn_lfe_authority_tests:context peer path grant
            #b("1") #b("new") #b("a"))))
    (try
      (progn
        (assertNotEqual (map-get old-grant #b("boot"))
                        (map-get grant #b("boot")))
        (let (((tuple 'ok stale)
               (gen_tcp:connect (tuple 'local path) 0
                 '(binary #(active false) #(packet 4)) 1000)))
          (try
            (progn
              (send-frame stale
                (map 'kind 'hello 'version 4 'session #b("stale")
                     'generation #b("g") 'authority #b("a")
                     'boot (map-get old-grant #b("boot"))
                     'lease (map-get old-grant #b("lease")) 'ticket #b("2")))
              (assertEqual '#(error closed) (gen_tcp:recv stale 0 1000)))
            (after (gen_tcp:close stale))))
        (assertEqual #b("42") (evaluate socket #b("1") #b("42")))
        (send-frame socket (map 'kind 'close))
        (assertEqual #b("closed")
                  (map-get (read-frame socket) #b("kind")))
        (peer:call peer 'cayrn_lfe_authority_tests 'await-down
              (list context)))
      (after (gen_tcp:close socket) (gen_tcp:close owner)))))

(defun evaluate (socket operation source)
  (send-frame socket
    (map 'kind 'dispatch 'operation operation 'source source
         'generation #b("g") 'authority #b("a")))
  (let ((result (read-frame socket)))
    (assertEqual #b("outcome") (map-get result #b("kind")))
    (assertEqual #b("succeeded") (map-get result #b("phase")))
    (map-get result #b("value"))))

(defun send-frame (socket frame)
  (let (('ok (gen_tcp:send socket (json:encode frame)))) 'ok))

(defun read-frame (socket)
  (let (((tuple 'ok bytes) (gen_tcp:recv socket 0 3000))) (json:decode bytes)))

(defun start-native (peer path)
  (peer:call peer 'application 'set_env (list 'cayrn_lfe 'socket path))
  (let (((tuple 'ok _)
         (peer:call peer 'application 'ensure_all_started '(cayrn_lfe)))) 'ok))

(defun with-owned-peer (function)
  (let* ((dir (++ "/private/tmp/cayrn-app-lifetime-" (os:getpid) "-"
                 (integer_to_list
                   (erlang:unique_integer '(positive monotonic)))))
         ('ok (file:make_dir dir)) ('ok (file:change_mode dir #o700))
         (startup (filename:join dir "startup"))
         ('ok (file:make_dir startup))
         (path (filename:join startup "agent socket.sock")))
    (try
      (let (((tuple 'ok peer _)
             (peer:start_link (map 'connection 'standard_io
                                  'args (cons "-pa" (code:get_path))))))
        (try
          (let* (('ok (peer:call peer 'application 'load '(cayrn_lfe)))
                 ((tuple 'ok _) (peer:call peer 'application 'ensure_all_started
                                  '(lfe)))
                 ((tuple 'ok _) (peer:call peer 'application 'ensure_all_started
                                  '(crypto))))
            (funcall function peer dir path))
          (after (peer:stop peer))))
      (after (file:delete path) (file:del_dir startup) (file:del_dir dir)))))
