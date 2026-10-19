;;;; Native token fences, physical collector credits and drain-order proofs.
(defmodule cayrn_lfe_resource_tests
  (export (async_descendants_wait_for_commit_test_ 0)
          (closed_socket_retains_acquired_cleanup_state_test 0)
          (quiet_result_waits_for_exact_down_test 0)
          (trace_session_isolation_test 0)
          (retiring_down_and_close_barriers_test 0)
          (callback_order_inversions_test 0)
          (capacity_refusal_and_recovery_test_ 0)
          (collector_failure_is_context_local_test_ 0)
          (full_capacity_close_test_ 0)
          (ownership_and_monitor_mismatches_test 0)
          (quiet_sparse_evaluations_reclaim_origins_test_ 0)
          (retirement_close_orderings_test_ 0)
          (stale_cancel_preserves_active_evaluation_test_ 0)
          (token_replay_and_invalid_tokens_test_ 0)))

(include-lib "eunit/include/eunit.hrl")

(defun quiet_sparse_evaluations_reclaim_origins_test_ ()
  "Exercise 512 sparse admissions with physical reclamation before each result."
  (tuple 'timeout 60 #'quiet-sparse-evaluations/0))

(defun quiet-sparse-evaluations ()
  (with-peer
    (lambda (peer socket context)
      (lists:foreach
        (lambda (i)
          (let* ((token (integer_to_binary (+ 2 (* 3 (- i 1)))))
                 (source (if (=:= i 1) #b("(set counter 1)")
                           #b("(set counter (+ counter 1))")))
                 (result (evaluate socket token source)))
            (assertEqual #b("succeeded") (map-get result #b("phase")))
            (assertEqual (integer_to_binary i) (map-get result #b("value")))
            (assertEqual 0 (map_size (origins peer context)))
            (assertEqual '(#(legacy default))
              (peer:call peer 'trace 'session_info '(all)))))
        (lists:seq 1 512)))))

(defun token_replay_and_invalid_tokens_test_ ()
  "Fence native replay before its visible side effect and reject bad tokens."
  (tuple 'timeout 60 #'token-replay-and-invalid/0))

(defun token-replay-and-invalid ()
  (with-peer
    (lambda (peer socket _context)
      (assertEqual #b("2")
        (map-get (evaluate socket #b("2") #b("2")) #b("value")))
      (assertEqual #b("5")
        (map-get (evaluate socket #b("5") #b("5")) #b("value")))
      (assertEqual #b("9")
        (map-get (evaluate socket #b("9") #b("9")) #b("value")))
      (let ((path (++ "/private/tmp/cayrn-replay-" (os:getpid) "-"
                     (integer_to_list (erlang:unique_integer '(positive))))))
        (try
          (progn
            (dispatch socket #b("5")
              (unicode:characters_to_binary
                (io_lib:format "(file:write_file ~p ~p)" (list path "BAD"))))
            (assertEqual '#(error closed) (gen_tcp:recv socket 0 1000))
            (assertEqual '#(error enoent) (file:read_file path))
            (assert (is_pid (peer:call peer 'erlang 'whereis
                              '(cayrn_lfe_listener)))))
          (after (file:delete path))))))
  (lists:foreach
    (lambda (token)
      (with-peer
        (lambda (_peer socket _context)
          (dispatch socket token #b("42"))
          (assertEqual '#(error closed) (gen_tcp:recv socket 0 1000)))))
    (list #b("0") #b("01") #b("+1") #b("-1") #b("1.0")
          #b("9223372036854775808") 2))
  (with-peer
    (lambda (_peer socket _context)
      (assertEqual #b("42")
        (map-get (evaluate socket #b("9223372036854775807") #b("42"))
          #b("value"))))))

(defun capacity_refusal_and_recovery_test_ ()
  "Refuse operation65 without evaluation, then recover a physical origin."
  (tuple 'timeout 60 #'capacity-refusal-and-recovery/0))

(defun capacity-refusal-and-recovery ()
  (with-peer
    (lambda (peer socket context)
      (let ((children (hold-origins peer socket 64)))
        (assertEqual 64 (map_size (origins peer context)))
        (let ((refused (evaluate socket #b("1000")
                         #b("(set pressure-mutated 1)"))))
          (assertEqual #b("failed") (map-get refused #b("phase")))
          (assertEqual (map #b("truncated") 'false)
            (map-get refused #b("preview")))
          (assertEqual
            #b("native resource limit: 64 live capture origins; "
               "source not evaluated")
            (map-get refused #b("value"))))
        (assertEqual 64 (map_size (origins peer context)))
        ;; The refused token is consumed: idle cancel must see an old token.
        (send-frame socket (map 'kind 'cancel 'operation #b("1000")))
        (peer:call peer 'erlang 'send (list (car children) 'release))
        (await-origins peer context 63)
        (assertEqual #b("failed")
          (map-get (evaluate socket #b("1003") #b("pressure-mutated"))
            #b("phase")))
        (assertEqual #b("42")
          (map-get (evaluate socket #b("1006") #b("(+ 20 22)"))
            #b("value")))
        (lists:foreach
          (lambda (pid) (peer:call peer 'erlang 'send (list pid 'release)))
          (cdr children))
        (await-origins peer context 0)
        (assertEqual '(#(legacy default))
              (peer:call peer 'trace 'session_info '(all)))))))

(defun full_capacity_close_test_ ()
  "Close remains available while all64 origin credits are held."
  (tuple 'timeout 60
    (lambda ()
      (with-peer
        (lambda (_peer socket _context)
          (hold-origins _peer socket 64)
          (send-frame socket (map 'kind 'close))
          (assertEqual #b("closed") (map-get (read-frame socket) #b("kind")))
          (assertEqual '#(error closed) (gen_tcp:recv socket 0 1000)))))))

(defun async_descendants_wait_for_commit_test_ ()
  "Inherited spawn forms keep attribution after sender exit and withheld ACK."
  (tuple 'timeout 60 #'async-descendants/0))

(defun async-descendants ()
  (lists:foreach
    (match-lambda
      (((tuple spawn-form options))
       (with-peer
         (lambda (peer socket context)
           (let ((source
                   (unicode:characters_to_binary
                     (io_lib:format
                       (++ "(progn (~s (lambda () (! (group_leader) "
                           "(tuple 'io_request (self) (make_ref) "
                           "(tuple 'put_chars 'unicode "
                           "(pid_to_list (self))))))~s) 'scheduled)")
                       (list spawn-form options)))))
             ;; First prove natural retirement after a sender exits before ACK.
             (dispatch socket #b("2") source)
             (let* (((tuple output earlier) (until-output socket '()))
                    (sender (peer:call peer 'erlang 'list_to_pid
                              (list (binary_to_list
                                      (map-get output #b("text")))))))
               (await-dead peer sender 500)
               (assertEqual #b("2") (map-get output #b("operation")))
               (assertEqual 1 (map_size (origins peer context)))
               (send-frame socket
                 (map 'kind 'ack 'position (map-get output #b("position"))))
               (if (lists:any
                         (lambda (frame)
                           (=:= #b("outcome") (map-get frame #b("kind"))))
                         earlier)
                 'ok
                 (until-kind socket #b("outcome")))
               (await-origins peer context 0))
             ;; A separate forced-close path must wait for its withheld ACK.
             (dispatch socket #b("5") source)
             (let* (((tuple output _earlier) (until-output socket '()))
                    (sender (peer:call peer 'erlang 'list_to_pid
                              (list (binary_to_list
                                      (map-get output #b("text")))))))
               (await-dead peer sender 500)
               (send-frame socket (map 'kind 'close))
               (assertNot
                 (lists:any #'closed-event?/1 (drain-available socket '())))
               (send-frame socket
                 (map 'kind 'ack 'position (map-get output #b("position"))))
               (assertEqual #b("closed")
                 (map-get (until-kind socket #b("closed")) #b("kind")))))))))
    '(#("spawn" "") #("spawn_link" "") #("spawn_monitor" "")
      #("spawn_opt" " ()"))))

(defun await-dead
  ((_peer _pid 0) (error 'sender_exit_timeout))
  ((peer pid attempts)
   (if (peer:call peer 'erlang 'is_process_alive (list pid))
     (progn (timer:sleep 2) (await-dead peer pid (- attempts 1)))
     'ok)))

(defun collector_failure_is_context_local_test_ ()
  "An unexpected collector death loses its context, never its native peer."
  (tuple 'timeout 30
    (lambda ()
      (with-peer
        (lambda (peer socket context)
          (hold-origins peer socket 1)
          (let ((io (car (maps:keys (origins peer context)))))
            (peer:call peer 'erlang 'exit (list io 'kill))
            (assertEqual '#(error closed) (gen_tcp:recv socket 0 1000))
            (assert (is_pid (peer:call peer 'erlang 'whereis
                              '(cayrn_lfe_listener))))))))))

(defun stale_cancel_preserves_active_evaluation_test_ ()
  "Cancelling an old token cannot interrupt a different active root."
  (tuple 'timeout 30
    (lambda ()
      (with-peer
        (lambda (_peer socket _context)
          (evaluate socket #b("2") #b("1"))
          (dispatch socket #b("5")
            #b("(progn (io:format \"CANCEL-GATE\" ()) 42)"))
          (let ((output (read-frame socket)))
            (assertEqual #b("output") (map-get output #b("kind")))
            (assertEqual #b("CANCEL-GATE") (map-get output #b("text")))
            ;; Both commands precede ACK, while the foreground is blocked.
            (send-frame socket (map 'kind 'cancel 'operation #b("2")))
            (send-frame socket (map 'kind 'cancel 'operation #b("99")))
            (send-frame socket
              (map 'kind 'ack 'position (map-get output #b("position")))))
          (let ((result (until-kind socket #b("outcome"))))
            (assertEqual #b("succeeded") (map-get result #b("phase")))
            (assertEqual #b("42") (map-get result #b("value")))))))))

(defun retirement_close_orderings_test_ ()
  "Close handles both live retire-ready and already-granted retirement."
  (tuple 'timeout 30
    (lambda ()
      (lists:foreach
        (lambda (grant-first)
          (with-peer
            (lambda (peer socket context)
              ;; Hold a descendant so a known collector can be suspended.
              (let* ((children (hold-origins peer socket 1))
                     (io (car (maps:keys (origins peer context)))))
                (peer:call peer 'sys 'suspend (list io))
                (peer:call peer 'erlang 'send (list (car children) 'release))
                (if grant-first
                  (progn
                    (peer:call peer 'sys 'resume (list io))
                    (await-origins peer context 0)
                    (send-frame socket (map 'kind 'close)))
                  (progn
                    (send-frame socket (map 'kind 'close))
                    (peer:call peer 'sys 'resume (list io))))
                (assertEqual #b("closed")
                  (map-get (until-kind socket #b("closed")) #b("kind")))))))
        '(false true)))))

(defun ownership_and_monitor_mismatches_test ()
  "Forged operation/ref/monitor cannot authorize capture or collector credit."
  (with-control-state
    (lambda (_client state io monitor)
      (let ((wrong (make_ref)))
        (assertException 'error _
          (cayrn_lfe_context:handle_info
            (tuple 'capture io wrong #b("5") (make_ref) (self) 1 #b("bad"))
            state))
        (lists:foreach
          (lambda (kind)
            (assertException 'error _
              (cayrn_lfe_context:handle_info (tuple kind io #b("5")) state)))
          '(foreground_ready retire_ready sealed))
        (assertException 'error _
          (cayrn_lfe_context:handle_info
            (tuple 'DOWN wrong 'process io 'normal) state))
        (assertEqual monitor (map-get (map-get (map-get state 'origins) io)
                                     'monitor))))))

(defun callback_order_inversions_test ()
  "Keep birth/exit/delivery and traced-send/request/ACK witnesses independent."
  (with-callback-state
    (lambda (_root state)
      (assertException 'error _
        (cayrn_lfe_io:handle_cast
          (tuple 'committed (self) (make_ref) (self) 1) state))))
  (lists:foreach
    (lambda (finish-first)
      (with-callback-state
        (lambda (root state)
          (let* ((before (if finish-first (finish-state state) state))
                 (accounted (exit-delivered root before))
                 (_complete (if finish-first accounted
                              (finish-state accounted))))
            (assert-ready))))) '(false true))
  (with-callback-state
    (lambda (root state)
      (let* ((child (spawn (lambda () 'ok)))
             (orphan (exit-delivered child state))
             (born (info-state (tuple 'trace root 'spawn child 'entry) orphan)))
        (exit-delivered root (finish-state born)) (assert-ready))))
  (lists:foreach
    (lambda (send-first)
      (with-callback-state
        (lambda (root state)
          (let* ((ref (make_ref))
                 (request (tuple 'io_request (self) ref
                            (tuple 'put_chars 'unicode #b("ordered"))))
                 (witness (tuple 'trace root 'send request (self)))
                 (partial (info-state (if send-first witness request) state))
                 (accounted (exit-delivered root (finish-state partial)))
                 (both (info-state (if send-first request witness) accounted)))
            (assert-no-ready)
            (let* (((tuple captured job worker index text)
                    (callback-capture both)))
              (assertEqual #b("ordered") text)
              (assert-no-ready)
              (let (((tuple 'noreply committed)
                     (cayrn_lfe_io:handle_cast
                       (tuple 'committed (self) job worker index) captured)))
                (callback-reply ref committed)
                (assert-ready))))))) '(false true)))

(defun callback-capture (state)
  (receive
    ((tuple 'admit_io _ _ job)
     (let (((tuple 'noreply next)
            (cayrn_lfe_io:handle_cast (tuple 'admit (self) job 'grant) state)))
       (callback-capture next)))
    ((tuple 'formatter_ready _ _ job worker)
     (let (((tuple 'noreply next)
            (cayrn_lfe_io:handle_cast
              (tuple 'activate_formatter (self) job worker) state)))
       (callback-capture next)))
    ((= (tuple 'stream_chunk _ _ _ _) message)
     (callback-capture (info-state message state)))
    ((tuple 'capture _ _ _ job worker index text)
     (tuple state job worker index text))
    (after 1000 (error 'missing_callback_capture))))

(defun callback-reply (ref state)
  (receive
    ((tuple 'io_reply incoming reply) (when (=:= incoming ref))
     (assertEqual 'ok reply))
    ((tuple 'job_done _ _ _ _) (callback-reply ref state))
    (message
     (callback-reply ref (info-state message state)))
    (after 1000 (error 'missing_callback_reply))))

(defun closed_socket_retains_acquired_cleanup_state_test ()
  "Rearm failure retains provisional collector and its paused owned root."
  (with-control-state
    (lambda (_client state _io _monitor)
      (let* ((socket (map-get state 'socket))
             ('ok (gen_tcp:close socket))
             (before (map-set state 'active 'undefined 'origins (map)
                       'last-token 0 'seq 0 'env (cayrn-lfe-eval:new)
                       'identity (tuple #b("s") #b("g") #b("a"))))
             ((tuple 'stop _reason acquired)
              (cayrn_lfe_context:handle_info
                (tuple 'tcp socket
                  (iolist_to_binary
                    (json:encode
                      (map 'kind 'dispatch 'operation #b("2")
                           'generation #b("g") 'authority #b("a")
                           'source #b("(timer:sleep 10000)"))))) before))
             ((tuple 'starting _ origin ref) (map-get acquired 'active))
             (origin-monitor
               (map-get (map-get (map-get acquired 'origins) origin)
                        'monitor)))
        (receive
          ((= (tuple 'origin_ready io incoming root _trace) ready)
           (when (=:= io origin) (=:= incoming ref))
           (let* (((tuple 'noreply registered)
                   (cayrn_lfe_context:handle_info ready acquired))
                  (monitor
                    (map-get (map-get (map-get registered 'origins) origin)
                             'root-monitor)))
             (assert (is_process_alive root))
             (cayrn_lfe_context:terminate 'normal registered)
             (receive
               ((tuple 'DOWN incoming 'process pid _)
                (when (=:= incoming monitor) (=:= pid root)) 'ok)
               (after 1000 (error 'acquired_root_leaked)))
             (receive
               ((tuple 'DOWN incoming 'process pid _)
                (when (=:= incoming origin-monitor) (=:= pid origin)) 'ok)
               (after 1000 (error 'acquired_collector_leaked)))))
          (after 1000 (error 'missing_provisional_origin)))))))

(defun trace_session_isolation_test ()
  "Destroying capture leaves an independently configured trace unchanged."
  (with-callback-state
    (lambda (root state)
      (let* ((probe (spawn (lambda () (receive ('stop 'ok)))))
             (independent (trace:session_create 'x21_independent (self) '()))
             (1 (trace:process independent root 'true '(procs)))
             (1 (trace:process independent probe 'true '(procs))))
        (try
          (progn
            (cayrn_lfe_io:terminate 'normal state)
            (assertEqual '#(flags (procs))
                         (trace:info independent probe 'flags)))
          (after (trace:session_destroy independent) (exit probe 'kill)))))))

(defun quiet_result_waits_for_exact_down_test ()
  "Retire-ready alone cannot publish or return a physical origin credit."
  (with-control-state
    (lambda (client state io monitor)
      (let (((tuple 'noreply retiring)
             (cayrn_lfe_context:handle_info
               (tuple 'retire_ready io #b("2")) state)))
        (assertEqual 1 (map_size (map-get retiring 'origins)))
        (assertEqual '#(error timeout) (gen_tcp:recv client 0 20))
        (! io 'exit)
        (let ((next (collector-down io monitor retiring)))
          (assertEqual 0 (map_size (map-get next 'origins)))
          (assertEqual #b("42") (map-get (read-frame client) #b("value"))))))))

(defun retiring_down_and_close_barriers_test ()
  "Close waits exact collector death after natural grant or strong seal."
  (lists:foreach
    (lambda (retire-first)
      (with-control-state
        (lambda (client state io monitor)
          (let* ((before
                   (if retire-first
                     (element 2
                       (cayrn_lfe_context:handle_info
                         (tuple 'retire_ready io #b("2")) state)) state))
                 ((tuple 'noreply closing) (close-state before))
                 (retiring
                   (if retire-first closing
                     (element 2
                       (cayrn_lfe_context:handle_info
                         (tuple 'sealed io #b("2")) closing)))))
            (assertEqual '#(error timeout) (gen_tcp:recv client 0 20))
            (! io 'exit)
            (let ((published (collector-down io monitor retiring)))
              (assertEqual #b("outcome")
                           (map-get (read-frame client) #b("kind")))
              (assertMatch (tuple 'stop 'normal _)
                (settle-writer published))
              (assertEqual #b("closed")
                           (map-get (read-frame client) #b("kind"))))))))
    '(false true)))

(defun collector-down (io monitor state)
  (receive
    ((= (tuple 'DOWN incoming 'process pid 'normal) down)
     (when (=:= incoming monitor) (=:= pid io))
     (let (((tuple 'noreply next)
            (cayrn_lfe_context:handle_info down state))) next))
    (after 1000 (error 'missing_exact_collector_down))))

(defun settle-writer (state)
  (receive
    ((= (tuple 'writer_sent _ _) message)
     (case (cayrn_lfe_context:handle_info message state)
       ((tuple 'noreply next) (settle-writer next))
       (stop stop)))
    ((= (tuple 'DOWN monitor 'process writer _) message)
     (when (=:= writer (map-get state 'writer))
           (=:= monitor (map-get state 'writer-monitor)))
     (case (cayrn_lfe_context:handle_info message state)
       ((tuple 'noreply next) (settle-writer next))
       (stop stop)))
    ((tuple 'EXIT _ 'normal) (settle-writer state))
    (after 1000 (error 'missing_terminal_writer_disposition))))

(defun close-state (state)
  (cayrn_lfe_context:handle_info
    (tuple 'tcp (map-get state 'socket)
      (iolist_to_binary (json:encode (map 'kind 'close)))) state))

(defun with-control-state (function)
  (let* (((tuple 'ok listener)
          (gen_tcp:listen 0 '(binary #(active false) #(packet 4)
                             #(ip #(127 0 0 1)))))
         ((tuple 'ok port) (inet:port listener))
         ((tuple 'ok client)
          (gen_tcp:connect '#(127 0 0 1) port
            '(binary #(active false) #(packet 4)) 1000))
         ((tuple 'ok server) (gen_tcp:accept listener))
         ((tuple io monitor)
          (spawn_monitor (lambda () (receive ('exit 'ok)))))
         (trace (trace:session_create 'x21_control (self) '()))
         ((tuple 'ok initial _) (cayrn_lfe_context:init server))
         (state (map-set initial
                  'active (tuple 'finishing #b("2") io
                                 'succeeded #b("42") 'false)
                  'origins
                    (map io (map 'operation #b("2") 'trace trace
                                 'monitor monitor 'phase 'live
                                 'ref (make_ref) 'root 'undefined
                                 'root-monitor 'undefined 'result-seen 'true
                                 'root-down 'true 'collector-down 'false)))))
    (link io)
    (try (funcall function client state io monitor)
      (after
        (unlink io) (exit io 'kill)
        (erlang:demonitor monitor '(flush))
        (trace:session_destroy trace)
        (exit (map-get state 'writer) 'kill)
        (erlang:demonitor (map-get state 'writer-monitor) '(flush))
        (gen_tcp:close server) (gen_tcp:close client)
        (gen_tcp:close listener)))))

(defun with-callback-state (function)
  ;; A collector callback fixture owns its whole mailbox. Repeated umbrella
  ;; discovery must not feed unrelated prior context/writer EXITs into it.
  (let (((tuple pid monitor)
         (spawn_monitor
           (lambda ()
             (process_flag 'trap_exit 'true)
             (callback-fixture function)))))
    (receive
      ((tuple 'DOWN incoming 'process owned reason)
       (when (=:= incoming monitor) (=:= owned pid))
       (assertEqual 'normal reason))
      (after 4000 (exit pid 'kill) (error 'callback_fixture_timeout)))))

(defun callback-fixture (function)
  (let* ((ref (make_ref))
         ((tuple 'ok state)
          (cayrn_lfe_io:init (tuple (self) #b("2") ref (lambda () 'ok)))))
    (receive
      ((tuple 'origin_ready owner incoming root _trace)
       (when (=:= owner (self)) (=:= incoming ref))
       (let ((monitor (monitor 'process root)))
         (try (funcall function root state)
           (after
             (cayrn_lfe_io:terminate 'normal state)
             (receive
               ((tuple 'DOWN incoming 'process pid _)
                (when (=:= incoming monitor) (=:= pid root)) 'ok)
               (after 1000 (error 'callback_root_cleanup_failed)))
             (receive
               ((tuple 'EXIT pid _) (when (=:= pid root)) 'ok)
               (after 0 'ok))))))
      (after 1000 (error 'missing_callback_origin)))))

(defun finish-state (state)
  (let (((tuple 'noreply next)
         (cayrn_lfe_io:handle_cast (tuple 'finished (self)) state))) next))

(defun info-state (message state)
  (let (((tuple 'noreply next) (cayrn_lfe_io:handle_info message state))) next))

(defun exit-delivered (pid state)
  (let ((exited (info-state (tuple 'trace pid 'exit 'normal) state)))
    (receive
      ((= (tuple 'trace_delivered incoming _) marker) (when (=:= incoming pid))
       (info-state marker exited))
      (after 1000 (error 'missing_trace_delivery)))))

(defun assert-ready ()
  (receive ((tuple 'retire_ready _ #b("2")) 'ok)
    (after 1000 (error 'missing_retire_ready))))

(defun assert-no-ready ()
  (receive ((tuple 'retire_ready _ _) (error 'premature_retirement))
    (after 0 'ok)))

(defun with-peer (function)
  (cayrn_lfe_authority_tests:with-peer
    (lambda (peer path)
      (let* (((tuple authority grant)
              (cayrn_lfe_authority_tests:authority path #b("a")))
             ((tuple socket context)
              (cayrn_lfe_authority_tests:context peer path grant #b("1")
                #b("resource-test") #b("a"))))
        (try (funcall function peer socket context)
          (after (gen_tcp:close socket) (gen_tcp:close authority)))))))

(defun origins (peer context)
  (map-get (peer:call peer 'sys 'get_state (list context)) 'origins))

(defun await-origins (peer context count)
  (await-origins peer context count 500))

(defun await-origins
  ((_peer _context _count 0) (error 'origin_reclamation_timeout))
  ((peer context count attempts)
   (if (=:= count (map_size (origins peer context)))
     'ok
     (progn (timer:sleep 2)
       (await-origins peer context count (- attempts 1))))))

(defun hold-origins (peer socket count)
  (lists:map
    (lambda (i)
      (let* ((result (evaluate socket (integer_to_binary (* 3 i))
                      #b("(spawn (lambda () (receive ('release 'ok))))")))
             (pid-text (binary_to_list (map-get result #b("value")))))
        (peer:call peer 'erlang 'list_to_pid
          (list (lists:nthtail 4 pid-text)))))
    (lists:seq 1 count)))

(defun dispatch (socket token source)
  (send-frame socket
    (map 'kind 'dispatch 'operation token 'source source
         'generation #b("g") 'authority #b("a"))))

(defun evaluate (socket token source)
  (dispatch socket token source)
  (until-kind socket #b("outcome")))

(defun send-frame (socket value)
  (let (('ok (gen_tcp:send socket (json:encode value)))) 'ok))

(defun read-frame (socket)
  (let (((tuple 'ok bytes) (gen_tcp:recv socket 0 3000))) (json:decode bytes)))

(defun until-kind (socket kind)
  (let ((frame (read-frame socket)))
    (case (map-get frame #b("kind"))
      (#b("output")
       (send-frame socket (map 'kind 'ack 'position
                            (map-get frame #b("position"))))
       (until-kind socket kind))
      (incoming (when (=:= incoming kind)) frame)
      (_ (until-kind socket kind)))))

(defun until-output (socket earlier)
  (let ((frame (read-frame socket)))
    (if (=:= #b("output") (map-get frame #b("kind")))
      (tuple frame earlier)
      (until-output socket (cons frame earlier)))))

(defun closed-event? (frame)
  (=:= #b("closed") (map-get frame #b("kind"))))

(defun drain-available (socket events)
  (case (gen_tcp:recv socket 0 20)
    ((tuple 'error 'timeout) events)
    ((tuple 'ok bytes)
     (drain-available socket (cons (json:decode bytes) events)))
    (error (error error))))
