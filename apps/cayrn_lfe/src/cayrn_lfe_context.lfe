;;;; One live native environment per Rust-owned agent connection.
(defmodule cayrn_lfe_context
  (behaviour gen_server)
  (export (handle_call 3) (handle_cast 2) (handle_info 2)
          (init 1) (start_link 1) (terminate 2)))

(defspec (start_link 1)
  (((port)) (UNION (tuple 'ok (pid)) (tuple 'error (term)))))

(defun start_link (socket)
  "Start a context on its socket; no native reconnection or replay."
  (gen_server:start_link (MODULE) socket '()))

(defspec (init 1) (((port)) (tuple 'ok (map) (timeout))))

(defun init (socket)
  "Pause without an environment until registry admission succeeds."
  (process_flag 'trap_exit 'true)
  (tuple 'ok
    (map 'socket socket 'identity 'undefined 'env 'undefined
         'registry 'undefined 'native-scope 'undefined
         'active 'undefined 'last-token 0 'origins (map) 'pending (map)
         'seq 0 'closing 'undefined)
    5000))

(defspec (handle_info 2)
  (((term) (map))
   (UNION (tuple 'noreply (map)) (tuple 'noreply (map) (timeout))
           (tuple 'stop (term) (map)))))

(defun handle_info
  "Process native control, evaluator, collector and capture events."
  (((tuple 'activate hello) (= (map 'socket socket) state))
   (try
     (let (((tuple 'continue next) (command hello state)))
       (case (inet:setopts socket '(#(active once)))
         ('ok (tuple 'noreply next))
         ((tuple 'error reason) (tuple 'stop reason next))))
     (catch ((tuple _ reason _) (tuple 'stop reason state)))))
  (((tuple 'authority_lost registry lease)
    (= (map 'registry stored-registry
            'native-scope (tuple _ stored-lease _)) state))
   (when (=:= registry stored-registry) (=:= lease stored-lease))
   (tuple 'stop 'normal state))
  (((tuple 'tcp socket bytes) (= (map 'socket socket) state))
   (let ((result
           (try (command (json:decode bytes) state)
             (catch
               ((tuple _ _ _) (tuple 'invalid state))))))
     (case result
       ((tuple 'continue next)
        ;; A successful dispatch has transferred acquired resources to next.
        ;; Rearm failure must terminate that state, never its predecessor.
        (case (inet:setopts socket '(#(active once)))
          ('ok (tuple 'noreply next))
          ((tuple 'error reason) (tuple 'stop reason next))))
       ((tuple 'stop next) (tuple 'stop 'normal next))
       ((tuple 'invalid previous)
        (tuple 'stop 'invalid_agent_command previous)))))

  (((tuple 'capture io from ref operation text) state)
   (let* (((tuple stored-operation _ _ 'live) (origin io state))
          ('true (=:= operation stored-operation))
          (pending (map-get state 'pending)))
     (if (< (map_size pending) 64)
       (let* ((n (+ (map-get state 'seq) 1))
              (position (integer_to_binary n))
              ('ok (send-event state
                     (map 'kind 'output 'operation operation
                          'position position 'text text))))
         (tuple 'noreply
           (map-set state 'seq n
             'pending (map-set pending position (tuple io from ref)))))
       (progn
         (! from (tuple 'io_reply ref '#(error enobufs)))
         (tuple 'stop 'capture_overflow state)))))
  (((tuple 'evaluated pid operation status text env)
    (= (map 'active (tuple pid monitor operation io)) state))
   (erlang:demonitor monitor '(flush))
   (let* (('true (=< (byte_size text) 8192))
          (next (map-set state 'env env
                  'active (tuple 'finishing operation io status text))))
     (cayrn_lfe_io:finished io (self))
     (if (=:= (map-get state 'closing) 'undefined)
       (tuple 'noreply next)
       (transition (progress (publish next))))))
  (((tuple 'foreground_ready io operation) state)
   (let* (((tuple stored-operation _ _ 'live) (origin io state))
          ('true (=:= operation stored-operation)))
     (transition (progress (publish-origin io state)))))
  (((tuple 'retire_ready io operation) state)
   (let* (((tuple stored-operation trace monitor 'live) (origin io state))
          ('true (=:= operation stored-operation)))
     (if (=:= (map-get state 'closing) 'undefined)
       (let* (('false (pending-origin? io state))
              ('true (unlink io))
              (origins (map-get state 'origins))
              (next (map-set state 'origins
                      (map-set origins io
                        (tuple operation trace monitor 'retiring)))))
         (cayrn_lfe_io:retire io (self))
         (tuple 'noreply next))
       (tuple 'noreply state))))
  (((tuple 'DOWN monitor 'process pid _reason)
    (= (map 'active (tuple pid monitor operation _io) 'closing mode) state))
   (when (orelse (=:= mode 'close) (=:= mode 'cancel)))
   (let (('ok (send-event state
                (map 'kind 'outcome 'operation operation 'phase 'cancelled
                     'value #b("native evaluator terminated; "
                               "environment discarded")))))
     (transition (progress (map-set state 'active 'undefined)))))
  (((tuple 'DOWN monitor 'process pid reason)
    (= (map 'active (tuple pid monitor _ _) ) state))
   (tuple 'stop (tuple 'evaluator_lost reason) state))
  (((tuple 'DOWN monitor 'process io reason) state)
   (case (maps:find io (map-get state 'origins))
     ((tuple 'ok (tuple _ trace stored-monitor 'retiring))
      (when (=:= reason 'normal) (=:= monitor stored-monitor))
      (trace:session_destroy trace)
      (let* ((next (map-set state 'origins
                     (maps:remove io (map-get state 'origins))))
             (published (publish-origin io next)))
        (transition (progress published))))
     (_ (tuple 'stop (tuple 'collector_lost reason) state))))
  (((tuple 'sealed io operation) (= (map 'waiting waiting) state))
   (let* (((tuple stored-operation _ _ 'live) (origin io state))
          ('true (=:= operation stored-operation))
          ('true (lists:member io waiting)))
     (transition
       (progress (map-set state 'waiting (lists:delete io waiting))))))
  (('close_timeout (= (map 'closing mode) state))
   (when (=/= mode 'undefined))
   (let (('ok (send-event state
                (map 'kind 'lost
                     'reason #b("native close/interrupt incomplete: producer "
                                "or capture barrier timed out")))))
     (tuple 'stop 'normal state)))
  (((tuple 'tcp_closed _) state) (tuple 'stop 'normal state))
  (((tuple 'tcp_error _ reason) state) (tuple 'stop reason state))
  (('timeout (= (map 'identity 'undefined) state))
   (tuple 'stop 'handshake_timeout state))
  (((tuple 'EXIT _ reason) state)
   (tuple 'stop (tuple 'io_lost reason) state))
  ((_ state) (tuple 'noreply state)))

(defun command
  (((map #b("kind") #b("hello") #b("version") 3
         #b("session") sid #b("generation") generation
         #b("authority") authority #b("boot") boot
         #b("lease") lease #b("ticket") ticket)
    (= (map 'identity 'undefined 'socket socket) state))
   (let* (((tuple 'ok registry)
           (cayrn_lfe_registry:admit boot lease ticket sid generation
                                     authority socket))
          (next (map-set state 'identity (tuple sid generation authority)
                  'registry registry 'native-scope (tuple boot lease ticket)
                  'env (cayrn-lfe-eval:new)))
          ('ok (send-event next
                 (map 'kind 'ready 'version 3 'backend #b("lfe")
                      'interrupt #b("session_destructive")
                      'close_barrier 'true 'boot boot
                      'lease lease 'ticket ticket))))
     (tuple 'continue next)))
  (((map #b("kind") #b("dispatch") #b("operation") operation
         #b("source") source #b("generation") generation
         #b("authority") authority)
    (= (map 'identity (tuple _ generation authority)
            'active 'undefined 'closing 'undefined) state))
   (when (is_binary source) (=< (byte_size source) 8192))
   (let* ((n (token operation))
          ('true (> n (map-get state 'last-token)))
          (next (map-set state 'last-token n)))
     (if (=:= 64 (map_size (map-get state 'origins)))
       (let (('ok (send-event next
                    (map 'kind 'outcome 'operation operation 'phase 'failed
                         'value #b("native resource limit: 64 live capture "
                                   "origins; source not evaluated")))))
         (tuple 'continue next))
       (evaluate operation source next))))
  (((map #b("kind") #b("ack") #b("position") position) state)
   (let* (((tuple (tuple io from ref) pending)
           (maps:take position (map-get state 'pending))))
     (origin io state)
     (cayrn_lfe_io:committed io from ref)
     (progress (map-set state 'pending pending))))
  (((map #b("kind") #b("close"))
    (= (map 'closing 'undefined) state))
   (begin-stop 'close state))
  (((map #b("kind") #b("close")) state) (tuple 'continue state))
  (((map #b("kind") #b("cancel") #b("operation") operation) state)
   (let ((n (token operation)))
     (case (map-get state 'active)
       ((tuple _ _ active-operation _)
        (when (=:= active-operation operation))
        (if (=:= (map-get state 'closing) 'undefined)
          (begin-stop 'cancel state)
          (tuple 'continue state)))
       ('undefined
        (if (andalso (=:= (map-get state 'closing) 'undefined)
                     (> n (map-get state 'last-token)))
          (let (('ok (send-event state
                       (map 'kind 'lost
                            'reason #b("interrupt won before native dispatch; "
                                       "context retired")))))
            (tuple 'stop state))
          (tuple 'continue state)))
       (_ (tuple 'continue state)))))
  (((map #b("kind") #b("stop")) state) (tuple 'stop state))
  ((_ _) (error 'invalid_agent_command)))

(defun evaluate (operation source state)
  (let* ((owner (self))
         (env (map-get state 'env))
         ((tuple pid monitor)
          (spawn_monitor
            (lambda ()
              (receive
                ('evaluate
                 (let* (((tuple status value next)
                         (cayrn-lfe-eval:run source env))
                        (phase (case status
                                 ('ok 'succeeded)
                                 ('error 'failed))))
                   (! owner (tuple 'evaluated (self) operation
                                   phase value next)))))))))
    (try
      (let (((tuple 'ok io trace) (cayrn_lfe_io:start owner operation pid)))
        (try
          (let* ((io-monitor (monitor 'process io))
                 ('true (group_leader io pid)))
            (! pid 'evaluate)
            (tuple 'continue
              (map-set state 'active (tuple pid monitor operation io)
                'origins (map-set (map-get state 'origins) io
                           (tuple operation trace io-monitor 'live)))))
          (catch
            ((tuple class reason stack)
             (trace:session_destroy trace)
             (unlink io)
             (exit io 'kill)
             (erlang:raise class reason stack)))))
      (catch
        ((tuple class reason stack)
         (exit pid 'kill)
         (erlang:demonitor monitor '(flush))
         (erlang:raise class reason stack))))))

(defun token
  ((value) (when (is_binary value) (> (byte_size value) 0)
                 (=< (byte_size value) 19))
   (let* ((n (binary_to_integer value))
          ('true (andalso (> n 0) (=< n 9223372036854775807)
                          (=:= value (integer_to_binary n)))))
     n))
  ((_) (error 'invalid_native_token)))

(defun origin (io state)
  (map-get (map-get state 'origins) io))

(defun pending-origin? (io state)
  (lists:any (match-lambda
               (((tuple incoming _ _)) (=:= incoming io)))
    (maps:values (map-get state 'pending))))

(defun publish-origin
  ((io (= (map 'active (tuple 'finishing _ io _ _)) state))
   (publish state))
  ((_io state) state))

(defun publish
  (((= (map 'active (tuple 'finishing operation _ phase text)) state))
   (let (('ok (send-event state
                (map 'kind 'outcome 'operation operation
                     'phase phase 'value text))))
     (map-set state 'active 'undefined)))
  ((state) state))

(defun begin-stop (mode state)
  (erlang:send_after 5000 (self) 'close_timeout)
  (let ((next (map-set state 'closing mode)))
    (case (map-get next 'active)
      ((tuple 'finishing _ _ _ _) (progress (publish next)))
      ((tuple pid _ _ _) (exit pid 'kill) (progress next))
      ('undefined (progress next)))))

(defun progress
  (((= (map 'closing 'cancel 'active 'undefined) state))
   (let (('ok (send-event state
                (map 'kind 'lost
                     'reason #b("session-destructive interruption ended "
                                "native context; capture tail may be "
                                "uncertain")))))
     (tuple 'stop state)))
  (((= (map 'closing 'close 'active 'undefined) state))
   (case (maps:find 'waiting state)
     ('error
      (let ((live (lists:filtermap
                    (match-lambda
                      (((tuple io (tuple _ _ _ 'live))) (tuple 'true io))
                      ((_entry) 'false))
                    (maps:to_list (map-get state 'origins)))))
        (lists:foreach (lambda (io) (cayrn_lfe_io:seal io (self))) live)
        (progress (map-set state 'waiting live))))
     ((tuple 'ok '())
      (if (andalso (=:= (map_size (map-get state 'pending)) 0)
                   (not (retiring? state)))
        (let (('ok (send-event state (map 'kind 'closed))))
          (tuple 'stop state))
        (tuple 'continue state)))
     (_ (tuple 'continue state))))
  ((state) (tuple 'continue state)))

(defun retiring? (state)
  (lists:any
    (match-lambda
      (((tuple _ _ _ 'retiring)) 'true)
      ((_entry) 'false))
    (maps:values (map-get state 'origins))))

(defun transition
  (((tuple 'continue state)) (tuple 'noreply state))
  (((tuple 'stop state)) (tuple 'stop 'normal state)))

(defun send-event
  (((map 'socket socket) data)
   (gen_tcp:send socket (json:encode data))))

(defspec (handle_call 3)
  (((term) (call 'gen_server 'from) (map))
   (tuple 'reply (term) (map))))

(defun handle_call (_request _from state)
  "Reject unsupported synchronous requests."
  (tuple 'reply '#(error unsupported) state))

(defspec (handle_cast 2) (((term) (map)) (tuple 'noreply (map))))

(defun handle_cast (_request state)
  "Ignore unsupported asynchronous requests."
  (tuple 'noreply state))

(defspec (terminate 2) (((term) (map)) 'ok))

(defun terminate (_reason state)
  "Stop only this context's evaluator, tracing, capture and socket."
  (case (map-get state 'active)
    ((tuple pid _ _ _) (exit pid 'kill))
    (_ 'ok))
  (maps:foreach
    (lambda (io entry)
      (trace:session_destroy (element 2 entry))
      (unlink io)
      (exit io 'kill))
    (map-get state 'origins))
  (gen_tcp:close (map-get state 'socket))
  'ok)
