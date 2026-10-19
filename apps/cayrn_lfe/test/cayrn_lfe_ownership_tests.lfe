;;;; Physical ownership, cross-sender credit and positively blocked teardown.
(defmodule cayrn_lfe_ownership_tests
  (export (collector_completion_and_postseal_test 0)
          (context_cross_sender_bits_test 0)
          (controller-call 2) (held-mfa 1) (install-gate 3)
          (deferred_capacity_and_computed_cancel_test 0)
          (idle_future_cancel_pressure_test_ 0)
          (global_job_capacity_recovery_test_ 0)
          (new-controller 0) (owned_pressure_failures_test_ 0)
          (paused_start_controls_test 0)
          (activated_cancel_preserves_diagnostic_test_ 0)
          (pressure-snapshot 1) (pressure_close_drains_test_ 0)
          (pressure_close_timeout_test_ 0) (start-unlink-wrapper 1)
          (publishing_deferred_controls_test 0)
          (root_completion_wins_expected_kill_test 0)
          (startup_single_owner_gaps_test_ 0)
          (unlink_owner_monitor_gap_test_ 0)))

(include-lib "eunit/include/eunit.hrl")

;; Private callback fixture mirrors the collector's named record. It exposes no
;; No production accessor; separate real socket tests witness physical PIDs.
(defrecord capture
  owner owner-monitor operation origin root trace
  (producers (map)) (deliveries (map)) (jobs (map)) (keys (map))
  (sent 0) (observed 0) (finished 'false) (root-accounted 'false)
  (announced 'false) (ready 'false) (sealed 'false)
  (seal-ready 'false) (activated 'false))

(defun context_cross_sender_bits_test ()
  "ACK/sent, context job_done/DOWN and terminal sent/DOWN need both exact bits."
  (lists:foreach
    (lambda (first-bit)
      (with-handler-state
        (lambda (state)
          (let* ((io (stub (self))) (worker (stub (self)))
                 (job (make_ref)) (origin (make_ref))
                 (worker-monitor (make_ref)) (writer-ref (make_ref))
                 (entry (map 'io io 'worker worker 'monitor worker-monitor
                             'done 'false 'down 'false))
                 (pending (map 'io io 'job job 'worker worker 'index 1
                               'writer-ref writer-ref
                               'sent 'false 'acked 'false))
                 (prepared
                   (map-set state 'jobs (map job entry)
                     'origins (map io (origin-entry origin))
                     'frames (map writer-ref (tuple 'output #b("1")))
                     'pending (map #b("1") pending)))
                 (ack (tuple 'tcp (map-get state 'socket)
                        (iolist_to_binary
                          (json:encode (map 'kind 'ack 'position #b("1"))))))
                 (sent (tuple 'writer_sent (self) writer-ref)))
            (try
              (let* ((first (if first-bit ack sent))
                     (second (if first-bit sent ack))
                     ((tuple 'noreply partial)
                      (cayrn_lfe_context:handle_info first prepared)))
                (assertEqual 1 (map_size (map-get partial 'pending)))
                (assert-no-stub)
                (let (((tuple 'noreply complete)
                       (cayrn_lfe_context:handle_info second partial)))
                  (assertEqual 0 (map_size (map-get complete 'pending)))
                  (receive
                    ((tuple 'stub incoming
                      (tuple '$gen_cast (tuple 'committed owner ref pid 1)))
                     (when (=:= incoming io))
                     (assertEqual (self) owner) (assertEqual job ref)
                     (assertEqual worker pid))
                    (after 1000 (error 'missing_dual_commit)))
                  (assertMatch (tuple 'stop 'invalid_agent_command _)
                    (cayrn_lfe_context:handle_info ack complete))
                  (assertException 'error _
                    (cayrn_lfe_context:handle_info sent complete))))
              (after (exit io 'kill) (exit worker 'kill))))))) '(false true))
  (lists:foreach
    (lambda (down-first)
      (with-handler-state
        (lambda (state)
          (let* ((io (stub (self))) (worker (stub (self)))
                 (job (make_ref)) (origin (make_ref)) (monitor (make_ref))
                 (entry (map 'io io 'worker worker 'monitor monitor
                             'done 'false 'down 'false))
                 (prepared (map-set state 'jobs (map job entry)
                             'origins (map io (origin-entry origin))))
                 (done (tuple 'job_done io origin job worker))
                 (down (tuple 'DOWN monitor 'process worker 'normal)))
            (try
              (let* (((tuple 'noreply partial)
                      (cayrn_lfe_context:handle_info
                        (if down-first down done) prepared))
                     (_ (assertEqual 1 (map_size (map-get partial 'jobs))))
                     ((tuple 'noreply complete)
                      (cayrn_lfe_context:handle_info
                        (if down-first done down) partial)))
                (assertEqual 0 (map_size (map-get complete 'jobs)))
                (assertException 'error _
                  (cayrn_lfe_context:handle_info
                    (tuple 'DOWN (make_ref) 'process worker 'normal)
                    prepared)))
              (after (exit io 'kill) (exit worker 'kill))))))) '(false true))
  (lists:foreach
    (lambda (down-first)
      (with-handler-state
        (lambda (state)
          (let* ((ref (make_ref))
                 (monitor (map-get state 'writer-monitor))
                 (prepared (map-set state 'closing 'close
                             'frames (map ref 'terminal)
                             'terminal (map 'ref ref 'sent 'false
                                            'down 'false)))
                 (sent (tuple 'writer_sent (self) ref))
                 (down (tuple 'DOWN monitor 'process (self) 'normal))
                 ((tuple 'noreply partial)
                  (cayrn_lfe_context:handle_info
                    (if down-first down sent) prepared)))
            (assertMatch (tuple 'stop 'normal _)
              (cayrn_lfe_context:handle_info
                (if down-first sent down) partial)))))) '(false true)))

(defun collector_completion_and_postseal_test ()
  "Collector requires done before exact normal DOWN; seal proof stays stable."
  (with-collector-state
    (lambda (state)
      (let* ((worker (stub (self))) (monitor (make_ref))
             (job (make_ref)) (reply (make_ref))
             (entry (map 'worker worker 'monitor monitor 'from (self)
                         'reply reply 'down 'false 'done 'undefined
                         'pending 'undefined 'phase 'active))
             (prepared (set-capture state jobs (map job entry)
                         keys (map (tuple (self) reply) job)
                         producers (map) deliveries (map)
                         finished 'true root-accounted 'true)))
        (try
          (progn
            (assertException 'error _
              (cayrn_lfe_io:handle_info
                (tuple 'DOWN monitor 'process worker 'normal) prepared))
            (let (((tuple 'noreply done)
                   (cayrn_lfe_io:handle_info
                     (tuple 'stream_done worker job 'ok) prepared)))
              (receive ((tuple 'io_reply incoming _) (when (=:= incoming reply))
                         (error 'logical_done_returned_credit))
                (after 0 'ok))
              (assertException 'error _
                (cayrn_lfe_io:handle_info
                  (tuple 'DOWN (make_ref) 'process worker 'normal) done))
              (assertMatch (tuple 'noreply _)
                (cayrn_lfe_io:handle_info
                  (tuple 'DOWN monitor 'process worker 'normal) done))
              (receive ((tuple 'io_reply incoming 'ok)
                        (when (=:= incoming reply)) 'ok)
                (after 1000 (error 'missing_physical_reply)))))
          (after (exit worker 'kill))))))
  (lists:foreach
    (lambda (send-first)
      (with-collector-state
        (lambda (state)
          (let* ((ref (make_ref))
                 (request (tuple 'io_request (self) ref
                            (tuple 'put_chars #b("LATE"))))
                 (sent (tuple 'trace (capture-root state) 'send request
                              (self)))
                 (prepared (set-capture state sealed 'true
                             root-accounted 'true producers (map)))
                 ((tuple 'noreply partial)
                  (cayrn_lfe_io:handle_info
                    (if send-first sent request) prepared)))
            (receive ((tuple 'sealed _ _) (error 'early_seal_count))
              (after 0 'ok))
            (let (((tuple 'noreply sealed)
                   (cayrn_lfe_io:handle_info
                     (if send-first request sent) partial)))
              (receive ((tuple 'io_reply incoming reply)
                        (when (=:= incoming ref))
                        (assertEqual '#(error terminated) reply))
                (after 1000 (error 'missing_sealed_rejection)))
              (receive ((tuple 'sealed _ _) 'ok)
                (after 1000 (error 'missing_balanced_seal)))
              ;; A NEW rejected request/send may transiently unbalance counts
              ;; after the recorded proof, while stop grant crosses senders.
              (let (((tuple 'noreply raced)
                     (cayrn_lfe_io:handle_info
                       (if send-first request sent) sealed)))
                (assertMatch (tuple 'stop 'normal _)
                  (cayrn_lfe_io:handle_cast
                    (tuple 'stop_sealed (self)) raced)))))))) '(false true)))

(defun root_completion_wins_expected_kill_test ()
  "Root/collector deaths commute; requested kill after result keeps completion."
  (lists:foreach
    (lambda (collector-first)
      (with-handler-state
        (lambda (state)
          (let* ((io (stub (self))) (root (stub (self)))
                 (root-monitor (make_ref)) (io-monitor (make_ref))
                 (trace (trace:session_create 'x04_root_order (self) '()))
                 (entry (map-set (origin-entry (make_ref)) 'trace trace
                          'monitor io-monitor 'root root
                          'root-monitor root-monitor 'root-down 'false
                          'phase 'retiring))
                 (prepared (map-set state 'origins (map io entry)
                             'active (tuple 'finishing #b("2") io
                                            'succeeded #b("42") 'false)))
                 (root-down (tuple 'DOWN root-monitor 'process root 'normal))
                 (io-down (tuple 'DOWN io-monitor 'process io 'normal)))
            (try
              (let* (((tuple 'noreply partial)
                      (cayrn_lfe_context:handle_info
                        (if collector-first io-down root-down) prepared)))
                (assertEqual 1 (map_size (map-get partial 'origins)))
                (assert-no-write)
                (let (((tuple 'noreply complete)
                       (cayrn_lfe_context:handle_info
                         (if collector-first root-down io-down) partial)))
                  (assertEqual 0 (map_size (map-get complete 'origins)))
                  (receive
                    ((tuple 'write _ _ (map 'kind 'outcome 'value #b("42")) _)
                     'ok)
                    (after 1000 (error 'missing_after_both_outcome)))))
              (after (trace:session_destroy trace)
                     (exit io 'kill) (exit root 'kill))))))) '(false true))
  (with-handler-state
    (lambda (state)
      (let* ((io (stub (self))) (root (stub (self))) (monitor (make_ref))
             (entry (map-set (origin-entry (make_ref)) 'root root
                      'root-monitor monitor 'root-down 'false
                      'kill-requested 'true 'result-seen 'false))
             (prepared (map-set state 'closing 'close
                         'origins (map io entry)
                         'active (tuple root monitor #b("2") io))))
        (try
          (let* (((tuple 'noreply evaluated)
                  (cayrn_lfe_context:handle_info
                    (tuple 'evaluated root #b("2") 'succeeded #b("42")
                           'false (map)) prepared)))
            (assertMatch (tuple 'noreply _)
              (cayrn_lfe_context:handle_info
                (tuple 'DOWN monitor 'process root 'killed) evaluated))
            (assertException 'error _
              (cayrn_lfe_context:handle_info
                (tuple 'DOWN monitor 'process root 'killed)
                (map-set evaluated 'origins
                  (map io (map-set (map-get (map-get evaluated 'origins) io)
                            'kill-requested 'false
                            'activation-granted 'false))))))
          (after (exit io 'kill) (exit root 'kill)))))))

(defun publishing_deferred_controls_test ()
  "One consumed deferred token cannot run before sent or after Close/Cancel."
  (lists:foreach
    (lambda (control)
      (with-handler-state
        (lambda (state)
          (let* ((ref (make_ref)) (marker (marker-path))
                 (source (iolist_to_binary
                           (io_lib:format "(file:write_file ~p #b(1))"
                             (list marker))))
                 (prepared (map-set state 'identity
                             (tuple #b("s") #b("g") #b("a"))
                             'last-token 2
                             'active (tuple 'publishing #b("2") ref)
                             'frames (map ref (tuple 'outcome #b("2")))))
                 ((tuple 'noreply deferred)
                  (command (map 'kind 'dispatch 'operation #b("5")
                                'source source 'generation #b("g")
                                'authority #b("a")) prepared)))
            (try
              (progn
                (assertEqual 5 (map-get deferred 'last-token))
                (assertEqual 0 (map_size (map-get deferred 'origins)))
                (assertNot (filelib:is_file marker))
                (case control
                  ('pipeline
                   (assertMatch (tuple 'stop 'invalid_agent_command _)
                     (command (map 'kind 'dispatch 'operation #b("9")
                                   'source source 'generation #b("g")
                                   'authority #b("a")) deferred)))
                  ('activate
                   (let* (((tuple 'noreply next)
                           (cayrn_lfe_context:handle_info
                             (tuple 'writer_sent (self) ref) deferred)))
                     (assertEqual 1 (map_size (map-get next 'origins)))
                     (assertEqual 'undefined (map-get next 'deferred))
                     (assertNot (filelib:is_file marker))
                     (cleanup-context next)))
                  (_
                   (let* ((frame (if (=:= control 'close)
                                  (map 'kind 'close)
                                  (map 'kind 'cancel 'operation #b("5"))))
                          ((tuple 'noreply canceled) (command frame deferred))
                          ('undefined (map-get canceled 'deferred))
                          ((tuple 'noreply after-sent)
                           (cayrn_lfe_context:handle_info
                             (tuple 'writer_sent (self) ref) canceled)))
                     (assertEqual 0 (map_size (map-get after-sent 'origins)))
                     (assertNot (filelib:is_file marker))
                     (receive
                       ((tuple 'write _ _
                          (map 'kind 'outcome 'operation #b("5")
                               'phase 'cancelled 'preview
                               (map 'truncated 'false)) 'false) 'ok)
                       (after 1000 (error 'missing_deferred_cancellation)))))))
              (after (file:delete marker)))))))
    '(close cancel pipeline activate)))

;;; Owned-peer startup and unlink windows: no product probe or gated get_state.
(defun startup_single_owner_gaps_test_ ()
  "Both startup publication stages retain a paused root on either owner loss."
  (tuple 'timeout 60
    (lambda ()
      (lists:foreach
        (lambda (stage)
          (lists:foreach (lambda (target) (startup-gap stage target))
                         '(context collector)))
        '(origin_ready activate_origin)))))

(defun startup-gap (stage target)
  (cayrn_lfe_authority_tests:with-peer
    (lambda (peer path)
      (let* (((tuple owner grant)
              (cayrn_lfe_authority_tests:authority path #b("a")))
             ((tuple socket context)
              (cayrn_lfe_authority_tests:context peer path grant #b("1")
                #b("startup") #b("a")))
             (controller (peer:call peer (MODULE) 'install-gate
                           (list context stage (make_ref))))
             (marker (++ path ".not-evaluated")))
        (try
          (progn
            (dispatch socket #b("1")
              (iolist_to_binary (io_lib:format "(file:write_file ~p #b(1))"
                                 (list marker))))
            (let* ((event (await-record peer controller 'gate 1000))
                   ((tuple 'gate blocked io root trace ref) event))
              (assertEqual context blocked)
              (assertEqual '#(trap_exit false)
                (peer:call peer 'erlang 'process_info (list root 'trap_exit)))
              (assertNot (filelib:is_file marker))
              (watch peer controller (list context io root))
              (peer:call peer 'erlang 'exit
                (list (if (=:= target 'context) context io) 'kill))
              (if (=:= target 'collector)
                (progn
                  (await-watched peer controller (list io root) 1000)
                  (assertNot (filelib:is_file marker))
                  (peer:call peer 'erlang 'send
                    (list context (tuple 'release ref))))
                'ok)
              (await-watched peer controller (list context io root) 1000)
              (assert-no-trace peer trace)
              (assertNot (filelib:is_file marker))))
          (after (file:delete marker) (gen_tcp:close socket)
                 (gen_tcp:close owner)))))))

(defspec (install-gate 3) (((pid) (atom) (reference)) (pid)))
(defun install-gate (context stage ref)
  "Install an actual pre-handler sys gate; FuncState stores prior payload."
  (let ((controller (new-controller)))
    (sys:install context
      (tuple
        (lambda (state event _server-name)
          (case event
            ((tuple 'in (tuple 'origin_ready io origin root trace))
             (let ((details (map 'io io 'origin origin
                                 'root root 'trace trace)))
               (if (=:= stage 'origin_ready)
                 (block-stage controller io root trace ref)
                 details)))
            ((tuple 'in (tuple 'activate_origin io origin))
             (when (=:= stage 'activate_origin))
             (let (('true (=:= io (map-get state 'io)))
                   ('true (=:= origin (map-get state 'origin))))
               (block-stage controller io (map-get state 'root)
                            (map-get state 'trace) ref)))
            (_ state))) 'armed))
    controller))

(defun block-stage (controller io root trace ref)
  (! controller (tuple 'record (tuple 'gate (self) io root trace ref)))
  (receive ((tuple 'release incoming) (when (=:= incoming ref)) 'done)))

(defun unlink_owner_monitor_gap_test_ ()
  "An unlinked collector retains its exact owner monitor and external trace."
  (tuple 'timeout 30
    (lambda ()
      (cayrn_lfe_authority_tests:with-peer
        (lambda (peer _path)
          (let* ((controller (peer:call peer (MODULE) 'new-controller '()))
                 (owner (peer:call peer (MODULE) 'start-unlink-wrapper
                          (list controller)))
                 ((tuple 'gap_ready incoming io root trace)
                  (await-record peer controller 'gap_ready 1000)))
            (assertEqual owner incoming)
            (await-record peer controller 'root_started 1000)
            (assertEqual '#(trap_exit true)
              (peer:call peer 'erlang 'process_info (list root 'trap_exit)))
            (watch peer controller (list owner io root))
            (peer:call peer 'erlang 'send (list owner 'unlink))
            (await-record peer controller 'gap_unlinked 1000)
            (assert (lists:member (element 2 trace)
                      (peer:call peer 'trace 'session_info '(all))))
            (peer:call peer 'erlang 'exit (list owner 'kill))
            (await-watched peer controller (list owner io root) 1000)
            (assert-no-trace peer trace)))))))

(defspec (start-unlink-wrapper 1) (((pid)) (pid)))
(defun start-unlink-wrapper (controller)
  "Own a real active collector, then expose the unlink-without-grant gap."
  (spawn
    (lambda ()
      (let* ((evaluate
               (lambda ()
                 (process_flag 'trap_exit 'true)
                 (! controller (tuple 'record (tuple 'root_started (self))))
                 (receive ('never 'ok))))
             ((tuple 'ok io ref)
              (cayrn_lfe_io:start (self) #b("1") evaluate)))
        (receive
          ((tuple 'origin_ready incoming origin root trace)
           (when (=:= incoming io) (=:= origin ref))
           (! controller
              (tuple 'record (tuple 'gap_ready (self) io root trace))))
          (after 1000 (error 'missing_unlink_root)))
        (cayrn_lfe_io:activate io (self) ref)
        (receive
          ('unlink
           (unlink io)
           (! controller (tuple 'record (tuple 'gap_unlinked (self))))
           (receive ('never 'ok))))))))

(defun owned_pressure_failures_test_ ()
  "Positive send_pend precedes each single-owner/native-domain failure."
  (tuple 'timeout 120
    (lambda ()
      (lists:foreach
        (lambda (mode)
          (with-pressure 'true
            (lambda (peer _socket context controller snapshot)
              (let* ((io (map-get snapshot 'io))
                     (root (map-get snapshot 'root))
                     (held (map-get snapshot 'held))
                     (pids (map-get snapshot 'owned))
                     (port (map-get snapshot 'port)))
                (assertEqual '#(trap_exit true)
                  (peer:call peer 'erlang 'process_info (list root 'trap_exit)))
                (assertEqual '#(trap_exit true)
                  (peer:call peer 'erlang 'process_info (list held 'trap_exit)))
                (assert (> (send-pending peer port) 0))
                (io:format 'user "NR-02 fault=~p positive send_pend=~p~n"
                  (list mode (send-pending peer port)))
                (case mode
                  ('collector (peer:call peer 'erlang 'exit (list io 'kill)))
                  ('context
                   (peer:call peer 'erlang 'exit (list context 'kill)))
                  ('application
                   (assertEqual 'ok
                     (peer:call peer 'application 'stop '(cayrn_lfe) 10000)))
                  (role
                   (peer:call peer 'erlang 'exit
                     (list (peer:call peer 'erlang 'whereis (list role))
                           'kill))))
                ;; Never read the client or release user blockers to help stop.
                (await-watched peer controller pids 3000)
                (assert-no-trace peer (map-get snapshot 'trace))))))
        '(collector context cayrn_lfe_listener
          cayrn_lfe_registry application)))))

(defun pressure_close_drains_test_ ()
  "Normal Close ACKs all pre-seal large jobs before physical Closed."
  (tuple 'timeout 30
    (lambda ()
      (with-pressure 'false
        (lambda (peer socket _context controller snapshot)
          (assert (> (send-pending peer (map-get snapshot 'port)) 0))
          (send-frame socket (map 'kind 'close))
          (let (((tuple bytes cancelled) (drain-close socket 1 0 'false)))
            (assertEqual (* 63 8000) bytes)
            (assert cancelled)
            (await-watched peer controller (map-get snapshot 'owned) 3000)
            (assert-no-trace peer (map-get snapshot 'trace))))))))

(defun pressure_close_timeout_test_ ()
  "Perpetual pending output forces bounded Lost/EOF, never false Closed."
  (tuple 'timeout 30
    (lambda ()
      (with-pressure 'false
        (lambda (peer socket _context controller snapshot)
          (assert (> (send-pending peer (map-get snapshot 'port)) 0))
          (send-frame socket (map 'kind 'close))
          ;; Observe death BEFORE any client drain, not a helping read.
          (await-watched peer controller (map-get snapshot 'owned) 4000)
          (assert-no-trace peer (map-get snapshot 'trace))
          (assert-no-closed socket 128))))))

(defun global_job_capacity_recovery_test_ ()
  "64 physical jobs across two origins reject65 ordinarily and recover."
  (tuple 'timeout 30
    (lambda ()
      (cayrn_lfe_authority_tests:with-peer
        (lambda (peer path)
          (let* (((tuple owner grant)
                  (cayrn_lfe_authority_tests:authority path #b("a")))
                 ((tuple socket context)
                  (cayrn_lfe_authority_tests:context peer path grant #b("1")
                    #b("job-capacity") #b("a"))))
            (try
              (progn
                (lists:foreach
                  (lambda (token)
                    (dispatch socket token
                      #b("(let ((root (self))) "
                         "(lists:foreach (lambda (_) (spawn (lambda () "
                         "(io:request (group_leader) (tuple 'put_chars "
                         "'unicode 'cayrn_lfe_ownership_tests 'held-mfa "
                         "(list root)))))) (lists:seq 1 32)) 'scheduled)"))
                    (assertEqual #b("succeeded")
                      (map-get (read-frame socket) #b("phase"))))
                  (list #b("1") #b("2")))
                (let* ((full (await-jobs peer context 64 1000))
                       (workers (lists:map
                                  (lambda (entry) (map-get entry 'worker))
                                  (maps:values (map-get full 'jobs)))))
                  (assertEqual 2 (map_size (map-get full 'origins)))
                  (dispatch socket #b("3")
                    #b("(io:request (group_leader) "
                       "(tuple 'put_chars 'unicode #b(\"REFUSED\")))"))
                  (let ((refused (read-frame socket)))
                    (assertEqual #b("succeeded") (map-get refused #b("phase")))
                    (assertEqual #b("#(error enobufs)")
                                 (map-get refused #b("value"))))
                  (peer:call peer 'erlang 'send (list (car workers) 'release))
                  (let ((output (read-frame socket)))
                    (assertEqual #b("HELD") (map-get output #b("text")))
                    (assertEqual 64
                      (map_size (map-get
                                  (peer:call peer 'sys 'get_state
                                    (list context)) 'jobs)))
                    (ack socket output))
                  (await-jobs peer context 63 1000)
                  (dispatch socket #b("4")
                    #b("(io:put_chars #b(\"RECOVERED\"))"))
                  (let ((output (read-frame socket)))
                    (assertEqual #b("RECOVERED") (map-get output #b("text")))
                    (ack socket output))
                  (assertEqual #b("ok")
                    (map-get (read-frame socket) #b("value")))
                  (await-jobs peer context 63 1000)))
              (after (gen_tcp:close socket) (gen_tcp:close owner)))))))))

(defun await-jobs
  ((_peer _context _count 0) (error 'physical_job_count_timeout))
  ((peer context count attempts)
   (let* ((state (peer:call peer 'sys 'get_state (list context)))
          (jobs (map-get state 'jobs)))
     (if (andalso (=:= count (map_size jobs))
                  (lists:all
                    (lambda (entry) (is_pid (map-get entry 'worker)))
                    (maps:values jobs)))
       state
       (progn (timer:sleep 2)
         (await-jobs peer context count (- attempts 1)))))))

(defun with-pressure (held function)
  (cayrn_lfe_authority_tests:with-peer
    (lambda (peer path)
      (let* (((tuple owner grant)
              (cayrn_lfe_authority_tests:authority path #b("a")))
             ((tuple socket context)
              (cayrn_lfe_authority_tests:context peer path grant #b("1")
                #b("positive-pressure") #b("a")))
             (controller (peer:call peer (MODULE) 'new-controller '()))
             (state (peer:call peer 'sys 'get_state (list context)))
             (port (map-get state 'socket)))
        (try
          (progn
            (inet:setopts socket '(#(recbuf 1024)))
            (peer:call peer 'inet 'setopts (list port '(#(sndbuf 1024))))
            (dispatch socket #b("1") (pressure-source held))
            (let ((start (read-frame socket)))
              (assertEqual #b("START") (map-get start #b("text")))
              (ack socket start))
            (let* ((snapshot (await-pressure peer context held 2000))
                   (owned (map-get snapshot 'owned)))
              ;; Retain actual strong trace outside both native owners.
              (peer:call peer 'erlang 'send
                (list controller (tuple 'record
                                   (tuple 'pressure_trace
                                          (map-get snapshot 'trace)))))
              (assert (lists:member (element 2 (map-get snapshot 'trace))
                        (peer:call peer 'trace 'session_info '(all))))
              (watch peer controller owned)
              (await-pending peer port 2000)
              (funcall function peer socket context controller snapshot)))
          (after (gen_tcp:close socket) (gen_tcp:close owner)))))))

(defun pressure-source (held)
  (iolist_to_binary
    (list
      "(progn (process_flag 'trap_exit 'true) "
      (if held
        (++ "(let ((root (self))) (spawn (lambda () "
            "(io:request (group_leader) (tuple 'put_chars 'unicode "
            "'cayrn_lfe_ownership_tests 'held-mfa (list root)))))) "
            "(receive ((tuple 'mfa_ready _) 'ok)) ") "")
      "(io:format \"START\" ()) "
      "(lists:foreach (lambda (_) (spawn (lambda () "
      "(io:put_chars (binary:copy #b(\"x\") 8000))))) "
      "(lists:seq 1 63)) (receive ('release 'never)))")))

(defspec (pressure-snapshot 1) (((pid)) (map)))
(defun pressure-snapshot (context)
  "Inspect the responsive owners on the test-owned node, never a gated server."
  (let* ((state (sys:get_state context))
         ((tuple root io)
          (case (map-get state 'active)
            ((tuple active-root _ _ active-io) (tuple active-root active-io))
            ('undefined
             (let* (((list (tuple origin entry))
                     (maps:to_list (map-get state 'origins))))
               (tuple (map-get entry 'root) origin)))))
         (capture (sys:get_state io))
         (jobs (map-get state 'jobs))
         (workers (lists:filtermap
                    (lambda (entry)
                      (let ((worker (map-get entry 'worker)))
                        (if (is_pid worker) (tuple 'true worker) 'false)))
                    (maps:values jobs)))
         (trapping (lists:filter
                     (lambda (pid)
                       (=:= '#(trap_exit true) (process_info pid 'trap_exit)))
                     workers)))
    (map 'root root 'io io 'trace (capture-trace capture)
         'held (case trapping ((cons pid _) pid) ('() 'undefined))
         'producers (maps:keys (capture-producers capture))
         'observed (capture-observed capture)
         'collector-jobs (map_size (capture-jobs capture))
         'jobs (map_size jobs) 'workers (length workers)
         'pending (map_size (map-get state 'pending))
         'port (map-get state 'socket)
         'owned (lists:usort (list* context root io
                                   (map-get state 'writer) workers)))))

(defun await-pressure
  ((_peer _context _held 0) (error 'registered_pressure_jobs_not_ready))
  ((peer context held attempts)
   (let* ((snapshot (peer:call peer (MODULE) 'pressure-snapshot
                     (list context)))
          (jobs (map-get snapshot 'jobs))
          (expected (if held 65 64)))
     (if (andalso (=:= expected (map-get snapshot 'observed))
                  (=:= jobs (map-get snapshot 'collector-jobs))
                  (=:= jobs (map-get snapshot 'workers))
                  (>= jobs (if held 62 63))
                  (=:= (- jobs (if held 1 0)) (map-get snapshot 'pending))
                  (orelse (not held) (is_pid (map-get snapshot 'held))))
       snapshot
       (progn (timer:sleep 2)
         (await-pressure peer context held (- attempts 1)))))))

(defun send-pending (peer port)
  (let (((tuple 'ok stats)
         (peer:call peer 'inet 'getstat (list port '(send_pend)))))
    (proplists:get_value 'send_pend stats)))

(defun await-pending
  ((_peer _port 0) (error 'positive_send_pressure_missing))
  ((peer port attempts)
   (if (> (send-pending peer port) 0) 'ok
     (progn (timer:sleep 2) (await-pending peer port (- attempts 1))))))

(defun drain-close (socket position bytes cancelled)
  (let ((frame (read-frame socket)))
    (case (map-get frame #b("kind"))
      (#b("output")
       (let ((text (map-get frame #b("text"))))
         (assertEqual (integer_to_binary (+ position 1))
                      (map-get frame #b("position")))
         (assert (=< (byte_size text) 8192))
         (assert (is_list (unicode:characters_to_list text)))
         (ack socket frame)
         (drain-close socket (+ position 1) (+ bytes (byte_size text))
                      cancelled)))
      (#b("outcome")
       (assertEqual #b("cancelled") (map-get frame #b("phase")))
       (drain-close socket position bytes 'true))
      (#b("closed") (tuple bytes cancelled))
      (other (error (tuple 'unexpected_close_event other))))))

(defun assert-no-closed
  ((_socket 0) (error 'timeout_transport_did_not_end))
  ((socket remaining)
   (case (gen_tcp:recv socket 0 1000)
     ((tuple 'ok bytes)
      (assertNotEqual #b("closed") (map-get (json:decode bytes) #b("kind")))
      (assert-no-closed socket (- remaining 1)))
     ('#(error closed) 'ok)
     ('#(error econnreset) 'ok)
     (other (error (tuple 'timeout_transport_did_not_end other))))))

(defun send-frame (socket frame)
  (let (('ok (gen_tcp:send socket (json:encode frame)))) 'ok))

(defun ack (socket frame)
  (send-frame socket (map 'kind 'ack 'position (map-get frame #b("position")))))

(defun read-frame (socket)
  (let (((tuple 'ok bytes) (gen_tcp:recv socket 0 7000))) (json:decode bytes)))

;;; Direct handler fixture supplements real physical socket/owner tests.
(defun with-handler-state (function)
  (let* (((tuple 'ok listener)
          (gen_tcp:listen 0 '(binary #(active false) #(packet 4))))
         ((tuple 'ok port) (inet:port listener))
         ((tuple 'ok client)
          (gen_tcp:connect "localhost" port
            '(binary #(active false) #(packet 4)) 1000))
         ((tuple 'ok server) (gen_tcp:accept listener))
         (state (map 'socket server 'identity 'undefined 'env (map)
                     'active 'undefined 'deferred 'undefined 'last-token 0
                     'origins (map) 'jobs (map) 'pending (map) 'seq 0
                     'writer (self) 'writer-monitor (make_ref)
                     'frames (map) 'terminal 'undefined 'closing 'undefined)))
    (try (funcall function state)
      (after (gen_tcp:close server) (gen_tcp:close client)
             (gen_tcp:close listener) (flush-writes)))))

(defun cleanup-context (state)
  ;; The direct-fixture writer is self, never pass it to production terminate.
  (let ((dummy (stub (self))))
    (cayrn_lfe_context:terminate 'normal (map-set state 'writer dummy))))

(defun origin-entry (ref)
  (map 'operation #b("2") 'ref ref 'monitor (make_ref) 'phase 'live
       'root 'undefined 'root-monitor 'undefined 'trace 'undefined
       'result-seen 'true 'root-down 'true 'collector-down 'false
       'kill-requested 'false 'activation-granted 'false))

(defun command (frame state)
  (cayrn_lfe_context:handle_info
    (tuple 'tcp (map-get state 'socket)
           (iolist_to_binary (json:encode frame))) state))

(defun with-collector-state (function)
  (let* ((ref (make_ref))
         ((tuple 'ok state)
          (cayrn_lfe_io:init (tuple (self) #b("2") ref (lambda () 'ok)))))
    (receive
      ((tuple 'origin_ready io origin root _trace)
       (when (=:= io (self)) (=:= origin ref))
       (let ((monitor (monitor 'process root)))
         (try (funcall function state)
           (after
             (cayrn_lfe_io:terminate 'normal state)
             (receive ((tuple 'DOWN incoming 'process pid _)
                       (when (=:= incoming monitor) (=:= pid root)) 'ok)
               (after 1000 (error 'fixture_root_leaked)))
             (receive ((tuple 'EXIT pid _) (when (=:= pid root)) 'ok)
               (after 0 'ok))
             (flush-owned-proof)))))
      (after 1000 (error 'missing_fixture_origin)))))

(defun flush-owned-proof ()
  (receive ((tuple 'retire_ready _ _) (flush-owned-proof))
           ((tuple 'sealed _ _) (flush-owned-proof))
           ((tuple 'job_done _ _ _ _) (flush-owned-proof))
    (after 0 'ok)))

(defun stub (owner)
  (spawn (lambda () (stub-loop owner))))

(defun stub-loop (owner)
  (receive (message (! owner (tuple 'stub (self) message)) (stub-loop owner))))

(defun assert-no-stub ()
  (receive ((tuple 'stub _ _) (error 'premature_commit)) (after 0 'ok)))

(defun assert-no-write ()
  (receive ((tuple 'write _ _ _ _) (error 'premature_frame)) (after 0 'ok)))

(defun flush-writes ()
  (receive ((tuple 'write _ _ _ _) (flush-writes))
           ((tuple 'stub _ _) (flush-writes))
    (after 0 'ok)))

(defun marker-path ()
  (++ "/private/tmp/cayrn-x04-marker-" (os:getpid) "-"
      (integer_to_list (erlang:unique_integer '(positive monotonic)))))

(defun new-controller ()
  (spawn (lambda () (controller-loop (map 'records '() 'watches (map)
                                        'downs (map))))))

(defspec (controller-call 2) (((pid) (term)) (term)))
(defun controller-call (controller request)
  "Query the test-owned controller; never query a deliberately gated context."
  (let ((ref (make_ref)))
    (! controller (tuple 'call (self) ref request))
    (receive ((tuple 'reply incoming result) (when (=:= incoming ref)) result)
      (after 2000 (error 'controller_unresponsive)))))

(defun controller-loop (state)
  (receive
    ((tuple 'record entry)
     (controller-loop
       (map-set state 'records (cons entry (map-get state 'records)))))
    ((tuple 'call from ref 'read)
     (! from (tuple 'reply ref state)) (controller-loop state))
    ((tuple 'call from ref (tuple 'watch pids))
     (let ((watches
             (lists:foldl (lambda (pid acc)
                            (map-set acc pid (monitor 'process pid)))
               (map-get state 'watches) (lists:usort pids))))
       (! from (tuple 'reply ref watches))
       (controller-loop (map-set state 'watches watches))))
    ((tuple 'DOWN ref 'process pid reason)
     (let (('true (=:= ref (map-get (map-get state 'watches) pid))))
       (controller-loop
         (map-set state 'downs
           (map-set (map-get state 'downs) pid (tuple ref reason))))))
    (_message (error 'invalid_controller_message))))

(defun await-record
  ((_peer _controller _kind 0) (error 'missing_owned_stage))
  ((peer controller kind attempts)
   (let* ((state (peer:call peer (MODULE) 'controller-call
                  (list controller 'read)))
          (matches (lists:filter (lambda (entry) (=:= kind (element 1 entry)))
                                 (map-get state 'records))))
     (case matches
       ((cons entry _) entry)
       ('() (timer:sleep 2)
            (await-record peer controller kind (- attempts 1)))))))

(defun watch (peer controller pids)
  (peer:call peer (MODULE) 'controller-call
    (list controller (tuple 'watch pids))))

(defun await-watched
  ((_peer _controller _pids 0) (error 'owned_processes_leaked))
  ((peer controller pids attempts)
   (let* ((state (peer:call peer (MODULE) 'controller-call
                  (list controller 'read)))
          (downs (map-get state 'downs)))
     (if (lists:all (lambda (pid) (maps:is_key pid downs)) pids)
       'ok
       (progn (timer:sleep 2)
         (await-watched peer controller pids (- attempts 1)))))))

(defun assert-no-trace (peer trace)
  (assertNot (lists:member (element 2 trace)
               (peer:call peer 'trace 'session_info '(all)))))

(defun dispatch (socket operation source)
  (let (('ok (gen_tcp:send socket
               (json:encode
                 (map 'kind 'dispatch 'operation operation 'source source
                      'generation #b("g") 'authority #b("a")))))) 'ok))

(defspec (held-mfa 1) (((pid)) (binary)))
(defun held-mfa (root)
  "A deliberately trapping user formatter, released only in nonfailure tests."
  (process_flag 'trap_exit 'true)
  (! root (tuple 'mfa_ready (self)))
  (receive ('release #b("HELD"))))


(defun paused_start_controls_test ()
  "Actual acquired roots stay unevaluated at both Close/Cancel startup stages."
  (lists:foreach
    (lambda (stage)
      (lists:foreach
        (lambda (control)
          ;; Each owned callback server has its own mailbox and lifetime.
          (let (((tuple pid monitor)
                 (spawn_monitor
                   (lambda ()
                     (process_flag 'trap_exit 'true)
                     (paused-control stage control)))))
            (receive
              ((tuple 'DOWN incoming 'process owned reason)
               (when (=:= incoming monitor) (=:= owned pid))
               (assertEqual 'normal reason))
              (after 10000 (exit pid 'kill)
                (error 'owned_callback_case_timeout)))))
        '(close cancel))) '(before_ready before_activation)))

(defun paused-control (stage control)
  (let* (((tuple 'ok listener)
          (gen_tcp:listen 0 '(binary #(active false) #(packet 4))))
         ((tuple 'ok port) (inet:port listener))
         ((tuple 'ok client)
          (gen_tcp:connect "localhost" port
            '(binary #(active false) #(packet 4)) 1000))
         ((tuple 'ok server) (gen_tcp:accept listener))
         ((tuple 'ok initial _) (cayrn_lfe_context:init server))
         (marker (marker-path))
         (source (iolist_to_binary
                   (io_lib:format "(file:write_file ~p #b(1))" (list marker))))
         ((tuple 'noreply acquired)
          (command (map 'kind 'dispatch 'operation #b("2") 'source source
                        'generation #b("g") 'authority #b("a"))
            (map-set initial 'identity (tuple #b("s") #b("g") #b("a"))
              'env (cayrn-lfe-eval:new))))
         ((tuple 'starting _ io ref) (map-get acquired 'active)))
    (try
      (receive
        ((= (tuple 'origin_ready incoming origin root trace) ready)
         (when (=:= incoming io) (=:= origin ref))
         (let* ((control-frame
                  (if (=:= control 'close) (map 'kind 'close)
                    (map 'kind 'cancel 'operation #b("2"))))
                (before
                  (if (=:= stage 'before_ready)
                    (let* (((tuple 'noreply closing)
                            (command control-frame acquired))
                           ((tuple 'noreply registered)
                            (cayrn_lfe_context:handle_info ready closing)))
                      registered)
                    (let* (((tuple 'noreply registered)
                            (cayrn_lfe_context:handle_info ready acquired))
                           ((tuple 'noreply closing)
                            (command control-frame registered))) closing))))
           (try
             (let ((stopped (pump-paused before root 'false)))
               (cayrn_lfe_context:terminate 'normal stopped)
               (let ((result (read-frame client))
                     (terminal (read-frame client)))
                 (assertEqual #b("cancelled") (map-get result #b("phase")))
                 (assertEqual #b("native request cancelled before evaluation; "
                                "source was not evaluated")
                              (map-get result #b("value")))
                 (assertEqual #m(#b("truncated") false)
                              (map-get result #b("preview")))
                 (assertEqual (if (=:= control 'close) #b("closed") #b("lost"))
                              (map-get terminal #b("kind"))))
               (assertNot (filelib:is_file marker)))
             (after (exit root 'kill) (exit io 'shutdown)
                    (trace:session_destroy trace)))))
        (after 1000 (error 'missing_owned_paused_origin)))
      (after
        (exit (map-get initial 'writer) 'kill)
        (gen_tcp:close server) (gen_tcp:close client)
        (gen_tcp:close listener) (file:delete marker)
        (flush-owned-proof)))))

(defun pump-paused (state root root-down)
  (receive
    (message
     (let* ((seen (case message
                    ((tuple 'DOWN _ 'process pid _) (when (=:= pid root)) 'true)
                    (_ root-down)))
            (result (cayrn_lfe_context:handle_info message state)))
       ;; The only Outcome creation path in this specimen follows actual DOWN.
       (if (> (map_size (map-get (element (tuple_size result) result)
                                'frames)) 0)
         (assert seen) 'ok)
       (case result
         ((tuple 'noreply next) (pump-paused next root seen))
         ((tuple 'stop 'normal stopped) (assert seen) stopped))))
    (after 7000 (error 'paused_control_did_not_finish))))

(defun activated_cancel_preserves_diagnostic_test_ ()
  "Granted active source retains the destructive evaluator diagnostic."
  (tuple 'timeout 20
    (lambda ()
      (cayrn_lfe_authority_tests:with-peer
        (lambda (peer path)
          (let* (((tuple owner grant)
                  (cayrn_lfe_authority_tests:authority path #b("a")))
                 ((tuple socket _context)
                  (cayrn_lfe_authority_tests:context peer path grant #b("1")
                    #b("active-cancel") #b("a"))))
            (try
              (progn
                (dispatch socket #b("1")
                  #b("(progn (io:put_chars \"START\") (receive ('never 42)))"))
                (let ((start (read-frame socket)))
                  (assertEqual #b("START") (map-get start #b("text")))
                  ;; Cancel while real source is blocked awaiting durable ACK.
                  (send-frame socket (map 'kind 'cancel 'operation #b("1")))
                  (ack socket start))
                (let ((outcome (read-frame socket)))
                  (assertEqual #b("cancelled") (map-get outcome #b("phase")))
                  (assertEqual #b("native evaluator terminated; "
                                 "environment discarded")
                               (map-get outcome #b("value"))))
                (assertEqual #b("lost")
                  (map-get (read-frame socket) #b("kind"))))
              (after (gen_tcp:close socket) (gen_tcp:close owner)))))))))


(defun deferred_capacity_and_computed_cancel_test ()
  "Capacity is checked at deferred activation; computed Cancel stays no-op."
  (with-handler-state
    (lambda (state)
      (let* ((ref (make_ref))
             (prepared (map-set state 'identity
                         (tuple #b("s") #b("g") #b("a")) 'last-token 2
                         'active (tuple 'publishing #b("2") ref)
                         'frames (map ref (tuple 'outcome #b("2"))))))
        (lists:foreach
          (lambda (token)
            (assertEqual (tuple 'noreply prepared)
              (command (map 'kind 'cancel 'operation token) prepared)))
          (list #b("1") #b("2") #b("99")))
        (let* (((tuple 'noreply deferred)
                (command (map 'kind 'dispatch 'operation #b("5")
                              'source #b("(error 'must-not-run)")
                              'generation #b("g") 'authority #b("a"))
                         prepared))
               (origins (maps:from_list
                          (lists:map
                            (lambda (n) (tuple n 'retained))
                            (lists:seq 1 64))))
               ((tuple 'noreply refused)
                (cayrn_lfe_context:handle_info
                  (tuple 'writer_sent (self) ref)
                  (map-set deferred 'origins origins))))
          (assertEqual 5 (map-get refused 'last-token))
          (assertEqual origins (map-get refused 'origins))
          (assertEqual 'undefined (map-get refused 'deferred))
          (assertMatch (tuple 'publishing #b("5") _) (map-get refused 'active))
          (receive
            ((tuple 'write _ _
               (map 'kind 'outcome 'operation #b("5") 'phase 'failed
                    'preview (map 'truncated 'false) 'value value) 'false)
             (assertEqual #b("native resource limit: 64 live capture origins; "
                            "source not evaluated") value))
            (after 1000 (error 'missing_activation_capacity_refusal))))))))

(defun idle_future_cancel_pressure_test_ ()
  "Idle future Cancel cannot wait forever behind background network pressure."
  (tuple 'timeout 30
    (lambda ()
      (cayrn_lfe_authority_tests:with-peer
        (lambda (peer path)
          (let* (((tuple owner grant)
                  (cayrn_lfe_authority_tests:authority path #b("a")))
                 ((tuple socket context)
                  (cayrn_lfe_authority_tests:context peer path grant #b("1")
                    #b("idle-pressure") #b("a")))
                 (controller (peer:call peer (MODULE) 'new-controller '())))
            (try
              (progn
                (dispatch socket #b("1")
                  #b("(progn (lists:foreach (lambda (_) (spawn (lambda () "
                     "(receive ('go (io:put_chars "
                     "(binary:copy #b(\"x\") 8000))))))) "
                     "(lists:seq 1 63)) 'scheduled)"))
                (assertEqual #b("scheduled")
                             (map-get (read-frame socket) #b("value")))
                (let* ((quiet (peer:call peer (MODULE) 'pressure-snapshot
                                (list context)))
                       (port (map-get quiet 'port)))
                  (assertEqual 63 (length (map-get quiet 'producers)))
                  (inet:setopts socket '(#(recbuf 1024)))
                  (peer:call peer 'inet 'setopts
                    (list port '(#(sndbuf 1024))))
                  (lists:foreach
                    (lambda (pid) (peer:call peer 'erlang 'send (list pid 'go)))
                    (map-get quiet 'producers))
                  (let* ((snapshot (await-idle-pressure peer context 2000))
                         (pids (map-get snapshot 'owned)))
                    (peer:call peer 'erlang 'send
                      (list controller (tuple 'record
                                         (tuple 'pressure_trace
                                           (map-get snapshot 'trace)))))
                    (watch peer controller pids)
                    (await-pending peer port 2000)
                    (send-frame socket (map 'kind 'cancel 'operation #b("99")))
                    ;; No drain/release: only the existing5s bound can end this.
                    (await-watched peer controller pids 4000)
                    (assert-no-trace peer (map-get snapshot 'trace))
                    (assert-no-closed socket 128))))
              (after (gen_tcp:close socket) (gen_tcp:close owner)))))))))

(defun await-idle-pressure
  ((_peer _context 0) (error 'idle_pressure_not_ready))
  ((peer context attempts)
   (let* ((snapshot (peer:call peer (MODULE) 'pressure-snapshot (list context)))
          (state (peer:call peer 'sys 'get_state (list context))))
     (if (andalso (=:= 'undefined (map-get state 'active))
                  (=:= 63 (map-get snapshot 'observed))
                  (=:= 63 (map-get snapshot 'workers))
                  (=:= 63 (map-get snapshot 'pending)))
       snapshot
       (progn (timer:sleep 2)
         (await-idle-pressure peer context (- attempts 1)))))))
