;;;; Responsive context policy and independent root/formatter lifetime owner.
(defmodule cayrn_lfe_context
  (behaviour gen_server)
  (export (handle_call 3) (handle_cast 2) (handle_info 2)
          (init 1) (start_link 1) (terminate 2)))

(defspec (start_link 1) (((port)) (term)))
(defun start_link (socket)
  "Start a paused disposable environment on its transferred native socket."
  (gen_server:start_link (MODULE) socket '()))

(defspec (init 1) (((port)) (term)))
(defun init (socket)
  "Own the nontrapping network worker before any environment can execute."
  (process_flag 'trap_exit 'true)
  (let ((writer (cayrn_lfe_writer:start socket)))
    (tuple 'ok
      (map 'socket socket 'identity 'undefined 'env 'undefined
           'registry 'undefined 'native-scope 'undefined
           'active 'undefined 'deferred 'undefined 'last-token 0
           'origins (map) 'jobs (map) 'pending (map) 'seq 0
           'writer writer 'writer-monitor (monitor 'process writer)
           'frames (map) 'terminal 'undefined 'closing 'undefined)
      5000)))

(defspec (handle_info 2) (((term) (map)) (term)))
(defun handle_info
  "Reconcile controls and exact ownership witnesses without blocking I/O."
  (((tuple 'activate hello) state) (receive-command hello state))
  (((tuple 'tcp socket bytes) (= (map 'socket socket) state))
   (let ((result
           (try (command (json:decode bytes) state)
             (catch ((tuple _ _ _) (tuple 'invalid state))))))
     (rearm result state)))
  (((tuple 'authority_lost registry lease)
    (= (map 'registry stored-registry
            'native-scope (tuple _ stored-lease _)) state))
   (when (=:= registry stored-registry) (=:= lease stored-lease))
   (tuple 'stop 'normal state))
  (((tuple 'origin_ready io ref root trace) state)
   (let* ((entry (origin io state))
          ('true (=:= ref (map-get entry 'ref)))
          ('undefined (map-get entry 'root))
          (monitor (monitor 'process root))
          (next (put-origin io
                  (map-set entry 'root root 'root-monitor monitor
                                 'trace trace) state)))
     ;; Publication is returned before our later activation handler can run.
     (! (self) (tuple 'activate_origin io ref))
     (if (=:= (map-get next 'closing) 'undefined)
       (tuple 'noreply next)
       (progn
         (exit root 'kill)
         (tuple 'noreply
           (put-origin io (map-set (origin io next) 'kill-requested 'true)
                       next))))))
  (((tuple 'activate_origin io _ref)
    (= (map 'closing mode 'origins origins) state))
   (when (=/= mode 'undefined) (not (is_map_key io origins)))
   (tuple 'noreply state))
  (((tuple 'activate_origin io ref) state)
   (let* ((entry (origin io state))
          ('true (=:= ref (map-get entry 'ref)))
          (root (map-get entry 'root))
          (operation (map-get entry 'operation)))
     (if (=:= (map-get state 'closing) 'undefined)
       (progn
         (cayrn_lfe_io:activate io (self) ref)
         (tuple 'noreply
           (map-set state 'active
             (tuple root (map-get entry 'root-monitor) operation io))))
       (progn (exit root 'kill) (tuple 'noreply state)))))
  (((tuple 'admit_io io ref job) state)
   (let* ((entry (origin io state))
          ('true (=:= ref (map-get entry 'ref)))
          (jobs (map-get state 'jobs))
          ('false (maps:is_key job jobs)))
     (if (< (map_size jobs) 64)
       (progn
         (cayrn_lfe_io:admit io (self) job 'grant)
         (tuple 'noreply
           (map-set state 'jobs
             (map-set jobs job
               (map 'io io 'worker 'undefined 'monitor 'undefined
                    'done 'false 'down 'false)))))
       (progn
         (cayrn_lfe_io:admit io (self) job '#(error enobufs))
         (tuple 'noreply state)))))
  (((tuple 'formatter_ready io ref job worker) state)
   (let* ((entry (origin io state))
          ('true (=:= ref (map-get entry 'ref)))
          (job-state (map-get (map-get state 'jobs) job))
          ('true (=:= io (map-get job-state 'io)))
          ('undefined (map-get job-state 'worker))
          (next (put-job job
                  (map-set job-state 'worker worker
                    'monitor (monitor 'process worker)) state)))
     (cayrn_lfe_io:activate_formatter io (self) job worker)
     (tuple 'noreply next)))
  (((tuple 'capture io ref operation job worker index text) state)
   (let* ((entry (origin io state))
          ('true (=:= ref (map-get entry 'ref)))
          ('true (=:= operation (map-get entry 'operation)))
          (job-state (map-get (map-get state 'jobs) job))
          ('true (andalso (=:= io (map-get job-state 'io))
                          (=:= worker (map-get job-state 'worker))))
          ('false (pending-job? job state))
          ('true (andalso (is_binary text) (=< (byte_size text) 8192)))
          (n (+ (map-get state 'seq) 1))
          (position (integer_to_binary n))
          ((tuple queued writer-ref)
           (enqueue state
             (map 'kind 'output 'operation operation
                  'position position 'text text)
             (tuple 'output position) 'false))
          (pending (map 'io io 'job job 'worker worker 'index index
                        'writer-ref writer-ref 'sent 'false 'acked 'false)))
     (tuple 'noreply
       (map-set queued 'seq n
         'pending (map-set (map-get queued 'pending) position pending)))))
  (((tuple 'job_done io ref job worker) state)
   (let* ((entry (origin io state))
          ('true (=:= ref (map-get entry 'ref)))
          (job-state (map-get (map-get state 'jobs) job))
          ('true (andalso (=:= io (map-get job-state 'io))
                          (=:= worker (map-get job-state 'worker))))
          ('false (map-get job-state 'done))
          ('false (pending-job? job state)))
     (transition (progress (finish-job job
                             (map-set job-state 'done 'true) state)))))
  (((tuple 'evaluated pid operation status text omitted env)
    (= (map 'active (tuple pid _monitor operation io)) state))
   (let* ((entry (origin io state))
          ('false (map-get entry 'result-seen))
          ('true (=< (byte_size text) 8192))
          (next (put-origin io (map-set entry 'result-seen 'true)
                  (map-set state 'env env 'active
                    (tuple 'finishing operation io status text omitted)))))
     (cayrn_lfe_io:finished io (self))
     (tuple 'noreply next)))
  (((tuple 'foreground_ready io operation) state)
   (check-operation io operation state)
   (transition (progress (publish-origin io state))))
  (((tuple 'retire_ready io operation) state)
   (check-operation io operation state)
   (if (=:= (map-get state 'closing) 'undefined)
     (let* ((entry (origin io state))
            ('live (map-get entry 'phase))
            ('false (pending-origin? io state)))
       (unlink io)
       (cayrn_lfe_io:retire io (self))
       (tuple 'noreply (put-origin io (map-set entry 'phase 'retiring) state)))
     (tuple 'noreply state)))
  (((tuple 'sealed io operation) state)
   (check-operation io operation state)
   (let* ((entry (origin io state))
          ('sealing (map-get entry 'phase))
          ('false (pending-origin? io state)))
     (unlink io)
     (cayrn_lfe_io:stop_sealed io (self))
     (tuple 'noreply (put-origin io (map-set entry 'phase 'retiring) state))))
  (((tuple 'writer_sent writer ref) (= (map 'writer writer) state))
   (let* (((tuple kind frames) (maps:take ref (map-get state 'frames)))
          (next (writer-sent kind ref (map-set state 'frames frames))))
     (transition (progress next))))
  (((tuple 'DOWN ref 'process writer reason)
    (= (map 'writer writer 'writer-monitor ref) state))
   (let* ((terminal (map-get state 'terminal))
          ('true (andalso (=/= terminal 'undefined) (=:= reason 'normal)))
          ('false (map-get terminal 'down)))
     (transition (progress
                   (map-set state 'terminal (map-set terminal 'down 'true))))))
  (((tuple 'DOWN ref 'process pid reason) state)
   (physical-down pid ref reason state))
  (((tuple 'EXIT writer reason) (= (map 'writer writer) state))
   (if (andalso (=:= reason 'normal)
                (=/= (map-get state 'terminal) 'undefined))
     (tuple 'noreply state)
     (tuple 'stop (tuple 'writer_lost reason) state)))
  (((tuple 'EXIT io 'normal) state)
   (if (maps:is_key io (map-get state 'origins))
     (tuple 'noreply state)
     (tuple 'stop 'unknown_link_exit state)))
  (((tuple 'EXIT _ reason) state)
   (tuple 'stop (tuple 'io_lost reason) state))
  (('close_timeout (= (map 'closing mode) state))
   (when (=/= mode 'undefined))
   ;; Best effort only; no second flush can extend the five-second barrier.
   (if (< (map_size (map-get state 'frames)) 68)
     (enqueue state
       (map 'kind 'lost 'reason
            #b("native close/interrupt incomplete: producer "
               "or capture barrier timed out")) 'diagnostic 'false)
     'ok)
   (tuple 'stop 'normal state))
  (((tuple 'tcp_closed _) state) (tuple 'stop 'normal state))
  (((tuple 'tcp_error _ reason) state) (tuple 'stop reason state))
  (('timeout (= (map 'identity 'undefined) state))
   (tuple 'stop 'handshake_timeout state))
  ((_message state) (tuple 'noreply state)))

(defun receive-command (message state)
  (rearm
    (try (command message state)
      (catch ((tuple _ _ _) (tuple 'invalid state)))) state))

(defun rearm
  (((tuple 'continue next) _previous)
   ;; Acquired resources belong to next even when peer rearming fails.
   (case (inet:setopts (map-get next 'socket) '(#(active once)))
     ('ok (tuple 'noreply next))
     ((tuple 'error reason) (tuple 'stop reason next))))
  (((tuple 'stop next) _previous) (tuple 'stop 'normal next))
  (((tuple 'invalid previous) _state)
   (tuple 'stop 'invalid_agent_command previous)))

(defun command
  (((map #b("kind") #b("hello") #b("version") 4
         #b("session") sid #b("generation") generation
         #b("authority") authority #b("boot") boot
         #b("lease") lease #b("ticket") ticket)
    (= (map 'identity 'undefined 'socket socket) state))
   (let* (((tuple 'ok registry)
           (cayrn_lfe_registry:admit boot lease ticket sid generation
                                     authority socket))
          ((tuple next _ref)
           (enqueue
             (map-set state 'identity (tuple sid generation authority)
               'registry registry 'native-scope (tuple boot lease ticket)
               'env (cayrn-lfe-eval:new))
             (map 'kind 'ready 'version 4 'backend #b("lfe")
                  'interrupt #b("session_destructive") 'close_barrier 'true
                  'boot boot 'lease lease 'ticket ticket) 'ready 'false)))
     (tuple 'continue next)))
  (((map #b("kind") #b("dispatch") #b("operation") operation
         #b("source") source #b("generation") generation
         #b("authority") authority)
    (= (map 'identity (tuple _ generation authority)
            'closing 'undefined) state))
   (when (is_binary source) (=< (byte_size source) 8192))
   (let* ((n (token operation))
          ('true (> n (map-get state 'last-token)))
          (consumed (map-set state 'last-token n)))
     (case (map-get consumed 'active)
       ('undefined (tuple 'continue (evaluate operation source consumed)))
       ((tuple 'publishing _ _)
        (let (('undefined (map-get consumed 'deferred)))
          (tuple 'continue
            (map-set consumed 'deferred (tuple operation source)))))
       (_ (error 'invalid_dispatch_pipeline)))))
  (((map #b("kind") #b("ack") #b("position") position) state)
   (let* ((entry (map-get (map-get state 'pending) position))
          ('false (map-get entry 'acked)))
     (progress (confirm-output position (map-set entry 'acked 'true) state))))
  (((map #b("kind") #b("close"))
    (= (map 'closing 'undefined) state))
   (progress (begin-stop 'close state)))
  (((map #b("kind") #b("close")) state) (tuple 'continue state))
  (((map #b("kind") #b("cancel") #b("operation") operation) state)
   (let ((n (token operation)))
     (case (map-get state 'deferred)
       ((tuple deferred-operation _)
        (when (=:= deferred-operation operation))
        (progress (begin-stop 'cancel state)))
       (_ (cancel-active operation n state)))))
  (((map #b("kind") #b("stop")) state) (tuple 'stop state))
  ((_ _) (error 'invalid_agent_command)))

(defun cancel-active (operation n state)
  (case (map-get state 'active)
    ((tuple 'starting active-operation _ _)
     (when (=:= active-operation operation))
     (progress (begin-stop-once 'cancel state)))
    ((tuple pid _ active-operation _)
     (when (is_pid pid) (=:= active-operation operation))
     (progress (begin-stop-once 'cancel state)))
    ('undefined
     (if (andalso (=:= (map-get state 'closing) 'undefined)
                  (> n (map-get state 'last-token)))
       (let (((tuple next _)
              (enqueue (begin-stop 'cancel state)
                (map 'kind 'lost 'reason
                     #b("interrupt won before native dispatch; "
                        "context retired")) 'terminal 'true)))
         (tuple 'continue next))
       (tuple 'continue state)))
    (_ (tuple 'continue state))))

(defun evaluate (operation source state)
  (if (=:= 64 (map_size (map-get state 'origins)))
    (outcome operation 'failed
      #b("native resource limit: 64 live capture origins; "
         "source not evaluated") 'false state)
    (let* ((owner (self)) (env (map-get state 'env))
           (evaluate
             (lambda ()
               (let* (((tuple status text omitted next)
                       (cayrn-lfe-eval:run source env))
                      (phase (case status
                               ('ok 'succeeded) ('error 'failed))))
                 (! owner (tuple 'evaluated (self) operation
                                 phase text omitted next)))))
           ((tuple 'ok io ref) (cayrn_lfe_io:start owner operation evaluate)))
      (try
        (let* ((entry
                 (map 'operation operation 'ref ref
                      'monitor (monitor 'process io) 'phase 'live
                      'root 'undefined 'root-monitor 'undefined
                      'trace 'undefined 'result-seen 'false 'root-down 'false
                      'collector-down 'false 'kill-requested 'false)))
          (put-origin io entry
            (map-set state 'active (tuple 'starting operation io ref))))
        (catch
          ((tuple class reason stack)
           ;; Collector owns its paused root even before origin_ready arrives.
           (exit io 'shutdown)
           (erlang:raise class reason stack)))))))

(defun physical-down (pid ref reason state)
  (let ((origins (map-get state 'origins)))
    (case (maps:find pid origins)
      ((tuple 'ok entry)
       (let* (('true (=:= ref (map-get entry 'monitor)))
              ('retiring (map-get entry 'phase))
              ('true (=:= reason 'normal))
              ('false (pending-origin? pid state)))
         ;; Collector and root DOWN have different senders. Keep both identities.
         (transition
           (progress (finish-origin pid
                       (map-set entry 'collector-down 'true) state)))))
      (_
       (let ((root (lists:filter
                     (match-lambda
                       (((tuple _ entry))
                        (andalso (=:= pid (map-get entry 'root))
                                 (=:= ref (map-get entry 'root-monitor)))))
                     (maps:to_list origins))))
         (case root
           ((list (tuple io entry)) (root-down io entry reason state))
           ('() (formatter-down pid ref reason state))))))))

(defun root-down (io entry reason state)
  (let* (('false (map-get entry 'root-down))
         (next (put-origin io (map-set entry 'root-down 'true) state)))
    (cond
      ((map-get entry 'result-seen)
       (let (('true (orelse (=:= reason 'normal)
                            (andalso (=:= reason 'killed)
                                     (map-get entry 'kill-requested)))))
         (transition (progress (finish-origin io
                                 (origin io next) next)))))
      ((=/= (map-get state 'closing) 'undefined)
       (transition
         (progress
           (outcome (map-get entry 'operation) 'cancelled
             #b("native evaluator terminated; environment discarded")
             'false (finish-origin io (origin io next) next)))))
      ('true (tuple 'stop (tuple 'evaluator_lost reason) next)))))

(defun finish-origin (io entry state)
  (if (andalso (map-get entry 'collector-down) (map-get entry 'root-down))
    (progn
      (trace:session_destroy (map-get entry 'trace))
      (publish-origin io
        (map-set state 'origins (maps:remove io (map-get state 'origins)))))
    (put-origin io entry state)))

(defun formatter-down (pid ref reason state)
  (let* (((list (tuple job entry))
          (lists:filter
            (match-lambda
              (((tuple _ entry))
               (andalso (=:= pid (map-get entry 'worker))
                        (=:= ref (map-get entry 'monitor)))))
            (maps:to_list (map-get state 'jobs))))
         ('true (=:= reason 'normal))
         ('false (map-get entry 'down)))
    (transition (progress (finish-job job (map-set entry 'down 'true) state)))))

(defun finish-job (job entry state)
  (map-set state 'jobs
    (if (andalso (map-get entry 'done) (map-get entry 'down))
      (maps:remove job (map-get state 'jobs))
      (map-set (map-get state 'jobs) job entry))))

(defun writer-sent
  (((tuple 'output position) ref state)
   (let* ((entry (map-get (map-get state 'pending) position))
          ('true (=:= ref (map-get entry 'writer-ref)))
          ('false (map-get entry 'sent)))
     (confirm-output position (map-set entry 'sent 'true) state)))
  (((tuple 'outcome operation) ref
    (= (map 'active (tuple 'publishing operation ref)) state))
   (let ((next (map-set state 'active 'undefined)))
     (case (map-get next 'deferred)
       ((tuple deferred-operation source)
        (when (=:= (map-get next 'closing) 'undefined))
        (evaluate deferred-operation source
          (map-set next 'deferred 'undefined)))
       (_ next))))
  (('terminal ref state)
   (let* ((entry (map-get state 'terminal))
          ('true (=:= ref (map-get entry 'ref)))
          ('false (map-get entry 'sent)))
     (map-set state 'terminal (map-set entry 'sent 'true))))
  (('ready _ref state) state)
  (('secondary_outcome _ref state) state)
  (('diagnostic _ref state) state))

(defun confirm-output (position entry state)
  (if (andalso (map-get entry 'sent) (map-get entry 'acked))
    (progn
      (cayrn_lfe_io:committed (map-get entry 'io) (map-get entry 'job)
                             (map-get entry 'worker) (map-get entry 'index))
      (map-set state 'pending (maps:remove position (map-get state 'pending))))
    (map-set state 'pending
      (map-set (map-get state 'pending) position entry))))

(defun publish-origin
  ((io (= (map 'active (tuple 'finishing operation io phase text omitted))
           state))
   (outcome operation phase text omitted state))
  ((_io state) state))

(defun outcome (operation phase text omitted state)
  (let (((tuple next ref)
         (enqueue state
           (map 'kind 'outcome 'operation operation 'phase phase 'value text
                'preview (map 'truncated omitted))
           (tuple 'outcome operation) 'false)))
    (map-set next 'active (tuple 'publishing operation ref))))

(defun begin-stop-once (mode state)
  (if (=:= (map-get state 'closing) 'undefined)
    (begin-stop mode state) state))

(defun begin-stop (mode state)
  (erlang:send_after 5000 (self) 'close_timeout)
  (let* ((next (cancel-deferred (map-set state 'closing mode)))
         (sealed
           (maps:fold
             (lambda (io entry current)
               (if (=:= (map-get entry 'phase) 'live)
                 (progn
                   (cayrn_lfe_io:seal io (self))
                   (put-origin io (map-set entry 'phase 'sealing) current))
                 current)) next (map-get next 'origins))))
    (case (map-get sealed 'active)
      ((tuple pid _ _ io) (when (is_pid pid))
       (let ((owned (put-origin io
                      (map-set (origin io sealed) 'kill-requested 'true)
                      sealed)))
         (exit pid 'kill) owned))
      ((tuple 'starting _ io _)
       (let* ((entry (origin io sealed))
              (owned (put-origin io (map-set entry 'kill-requested 'true)
                                 sealed)))
         (case (map-get entry 'root)
           ('undefined 'ok) (root (exit root 'kill)))
         owned))
      (_ sealed))))

(defun cancel-deferred (state)
  (case (map-get state 'deferred)
    ((tuple operation _source)
     (let (((tuple next _ref)
            (enqueue state
              (map 'kind 'outcome 'operation operation 'phase 'cancelled
                   'value #b("native request cancelled before evaluation; "
                             "source was not evaluated")
                   'preview (map 'truncated 'false))
              'secondary_outcome 'false)))
       (map-set next 'deferred 'undefined)))
    (_ state)))

(defun progress (state)
  (case (map-get state 'terminal)
    (terminal (when (is_map terminal))
     (if (andalso (map-get terminal 'sent) (map-get terminal 'down))
       (tuple 'stop state) (tuple 'continue state)))
    (_ (close-progress state))))

(defun close-progress
  (((= (map 'closing 'cancel 'active 'undefined) state))
   (let (((tuple next _ref)
          (enqueue state
            (map 'kind 'lost 'reason
                 #b("session-destructive interruption ended native context; "
                    "capture tail may be uncertain")) 'terminal 'true)))
     (tuple 'continue next)))
  (((= (map 'closing 'close 'active 'undefined) state))
   (if (andalso (=:= (map_size (map-get state 'origins)) 0)
                (=:= (map_size (map-get state 'jobs)) 0)
                (=:= (map_size (map-get state 'pending)) 0))
     (let (((tuple next _ref)
            (enqueue state (map 'kind 'closed) 'terminal 'true)))
       (tuple 'continue next))
     (tuple 'continue state)))
  ((state) (tuple 'continue state)))

(defun enqueue (state event kind terminal)
  (let* ((frames (map-get state 'frames))
         ('true (< (map_size frames) 68))
         (ref (make_ref))
         (next (map-set state 'frames (map-set frames ref kind)))
         (owned (if terminal
                  (map-set next 'terminal
                    (map 'ref ref 'sent 'false 'down 'false)) next)))
    (cayrn_lfe_writer:enqueue (map-get state 'writer) ref event terminal)
    (tuple owned ref)))

(defun origin (io state) (map-get (map-get state 'origins) io))

(defun check-operation (io operation state)
  (let (('true (=:= operation (map-get (origin io state) 'operation)))) 'ok))

(defun put-origin (io entry state)
  (map-set state 'origins (map-set (map-get state 'origins) io entry)))

(defun put-job (job entry state)
  (map-set state 'jobs (map-set (map-get state 'jobs) job entry)))

(defun pending-job? (job state)
  (lists:any (lambda (entry) (=:= job (map-get entry 'job)))
    (maps:values (map-get state 'pending))))

(defun pending-origin? (io state)
  (lists:any (lambda (entry) (=:= io (map-get entry 'io)))
    (maps:values (map-get state 'pending))))

(defun token
  ((value) (when (is_binary value) (> (byte_size value) 0)
                 (=< (byte_size value) 19))
   (let* ((n (binary_to_integer value))
          ('true (andalso (> n 0) (=< n 9223372036854775807)
                          (=:= value (integer_to_binary n))))) n))
  ((_) (error 'invalid_native_token)))

(defun transition
  (((tuple 'continue state)) (tuple 'noreply state))
  (((tuple 'stop state)) (tuple 'stop 'normal state)))

(defspec (handle_call 3) (((term) (term) (map)) (term)))
(defun handle_call (_request _from state)
  "Reject synchronous requests; lifetime peers use bounded async protocols."
  (tuple 'reply '#(error unsupported) state))

(defspec (handle_cast 2) (((term) (map)) (term)))
(defun handle_cast (_request state)
  "Ignore unsupported casts."
  (tuple 'noreply state))

(defspec (terminate 2) (((term) (map)) 'ok))
(defun terminate (_reason state)
  "Stop all known user workers before responsive collectors and writer."
  (maps:foreach
    (lambda (_io entry)
      (case (map-get entry 'root)
        ('undefined 'ok) (root (exit root 'kill))))
    (map-get state 'origins))
  (maps:foreach
    (lambda (_job entry)
      (case (map-get entry 'worker)
        ('undefined 'ok) (worker (exit worker 'kill))))
    (map-get state 'jobs))
  (maps:foreach
    (lambda (io entry)
      (exit io 'shutdown)
      (case (map-get entry 'trace)
        ('undefined 'ok) (trace (trace:session_destroy trace))))
    (map-get state 'origins))
  (exit (map-get state 'writer) 'kill)
  (let ((socket (map-get state 'socket))
        (terminal (map-get state 'terminal)))
    (if (andalso (=:= (map-get state 'closing) 'close)
                 (is_map terminal) (map-get terminal 'sent)
                 (map-get terminal 'down))
      (gen_tcp:close socket)
      ;; Failure never waits for unconsumed buffered bytes to drain.
      (case (inet:setopts socket '(#(linger #(true 0))))
        ('ok (gen_tcp:close socket))
        (_ (catch (erlang:port_close socket))))))
  'ok)
