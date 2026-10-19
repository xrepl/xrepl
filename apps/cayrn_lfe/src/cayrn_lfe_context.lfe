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
  "Create an opaque evaluator environment and bounded capture/control state."
  (process_flag 'trap_exit 'true)
  (tuple 'ok
    (map 'socket socket 'identity 'undefined 'env (cayrn-lfe-eval:new)
         'active 'undefined 'seen (map) 'ios '() 'pending (map)
         'seq 0 'closing 'undefined)
    5000))

(defspec (handle_info 2)
  (((term) (map))
   (UNION (tuple 'noreply (map)) (tuple 'noreply (map) (timeout))
           (tuple 'stop (term) (map)))))

(defun handle_info
  "Process native control, evaluator and capture events in mailbox order."
  (('activate (= (map 'socket socket) state))
   (let (('ok (inet:setopts socket '(#(active once)))))
     (tuple 'noreply state 5000)))
  (((tuple 'tcp socket bytes) (= (map 'socket socket) state))
   (try
     (case (command (json:decode bytes) state)
       ((tuple 'continue next)
        (let (('ok (inet:setopts socket '(#(active once)))))
          (tuple 'noreply next)))
       ((tuple 'stop next) (tuple 'stop 'normal next)))
     (catch ((tuple _ _ _) (tuple 'stop 'invalid_agent_command state)))))
  (((tuple 'capture from ref operation text) state)
   (let ((pending (map-get state 'pending)))
     (if (< (map_size pending) 64)
       (let* ((n (+ (map-get state 'seq) 1))
              (position (integer_to_binary n)))
         (let (('ok (send-event state
                      (map 'kind 'output 'operation operation
                           'position position 'text text))))
           (tuple 'noreply
             (map-set state 'seq n
               'pending (map-set pending position (tuple from ref))))))
       (progn
         (! from (tuple 'io_reply ref '#(error enobufs)))
         (tuple 'stop 'capture_overflow state)))))
  (((tuple 'evaluated pid operation status text env)
    (= (map 'active (tuple pid monitor operation)) state))
   (erlang:demonitor monitor '(flush))
   (let* (('true (=< (byte_size text) 8192))
         ('ok (send-event state
                (map 'kind 'outcome 'operation operation
                     'phase status 'value text))))
     (transition
       (progress (map-set state 'active 'undefined 'env env)))))
  (((tuple 'DOWN monitor 'process pid _reason)
    (= (map 'active (tuple pid monitor operation) 'closing mode) state))
   (when (orelse (=:= mode 'close) (=:= mode 'cancel)))
   (let (('ok (send-event state
                (map 'kind 'outcome 'operation operation 'phase 'cancelled
                     'value #b("native evaluator terminated; "
                               "environment discarded")))))
     (transition (progress (map-set state 'active 'undefined)))))
  (((tuple 'DOWN monitor 'process pid reason)
    (= (map 'active (tuple pid monitor _)) state))
   (tuple 'stop (tuple 'evaluator_lost reason) state))
  (((tuple 'sealed io) (= (map 'waiting waiting) state))
   (transition
     (progress (map-set state 'waiting (lists:delete io waiting)))))
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
  (((map #b("kind") #b("hello") #b("version") 1
         #b("session") sid #b("generation") generation
         #b("authority") authority)
    (= (map 'identity 'undefined) state))
   (let* (('true (andalso (valid-id? sid) (valid-id? generation)
                         (valid-id? authority)))
         ('true (< (ets:info 'cayrn_lfe_contexts 'size) 4096))
         ('true (ets:insert_new 'cayrn_lfe_contexts
                  (tuple sid generation authority)))
         ('ok (send-event state
                (map 'kind 'ready 'version 1 'backend #b("lfe")
                     'interrupt #b("session_destructive")
                     'close_barrier 'true))))
     (tuple 'continue
       (map-set state 'identity (tuple sid generation authority)))))
  (((map #b("kind") #b("dispatch") #b("operation") operation
         #b("source") source #b("generation") generation
         #b("authority") authority)
    (= (map 'identity (tuple _ generation authority)
            'active 'undefined 'seen seen 'closing 'undefined) state))
   (when (is_binary source) (=< (byte_size source) 8192)
         (< (map_size seen) 256))
   (let* (('true (valid-id? operation))
         ('false (maps:is_key operation seen)))
     (let* ((owner (self))
            (io (cayrn_lfe_io:start owner operation))
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
       (let* (('true (group_leader io pid)))
         (! pid 'evaluate)
         (tuple 'continue
           (map-set state 'active (tuple pid monitor operation)
                    'seen (map-set seen operation 'true)
                    'ios (cons io (map-get state 'ios))))))))
  (((map #b("kind") #b("ack") #b("position") position) state)
   (let* (((tuple (tuple from ref) pending)
           (maps:take position (map-get state 'pending))))
     (! from (tuple 'io_reply ref 'ok))
     (progress (map-set state 'pending pending))))
  (((map #b("kind") #b("close"))
    (= (map 'closing 'undefined) state))
   (begin-stop 'close state))
  (((map #b("kind") #b("close")) state) (tuple 'continue state))
  (((map #b("kind") #b("cancel") #b("operation") operation)
    (= (map 'active (tuple _ _ operation) 'closing 'undefined) state))
   (begin-stop 'cancel state))
  (((map #b("kind") #b("cancel") #b("operation") operation)
    (= (map 'active 'undefined 'seen seen 'closing 'undefined) state))
   (if (maps:is_key operation seen)
     (tuple 'continue state)
     (let (('ok (send-event state
                  (map 'kind 'lost
                       'reason #b("interrupt won before native dispatch; "
                                  "context retired")))))
       (tuple 'stop state))))
  (((map #b("kind") #b("cancel")) state) (tuple 'continue state))
  (((map #b("kind") #b("stop")) state) (tuple 'stop state))
  ((_ _) (error 'invalid_agent_command)))

(defun begin-stop (mode state)
  (erlang:send_after 5000 (self) 'close_timeout)
  (case (map-get state 'active)
    ((tuple pid _ _) (exit pid 'kill))
    ('undefined 'ok))
  (progress (map-set state 'closing mode)))

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
      (let ((ios (map-get state 'ios)))
        (lists:foreach (lambda (pid) (! pid (tuple 'seal (self)))) ios)
        (progress (map-set state 'waiting ios))))
     ((tuple 'ok '())
      (if (=:= (map_size (map-get state 'pending)) 0)
        (let (('ok (send-event state (map 'kind 'closed))))
          (tuple 'stop state))
        (tuple 'continue state)))
     (_ (tuple 'continue state))))
  ((state) (tuple 'continue state)))

(defun transition
  (((tuple 'continue state)) (tuple 'noreply state))
  (((tuple 'stop state)) (tuple 'stop 'normal state)))

(defun valid-id?
  ((id) (when (is_binary id) (> (byte_size id) 0)
              (=< (byte_size id) 128))
   (=:= (re:run id #b("^[A-Za-z0-9_-]+$") '(#(capture none))) 'match))
  ((_) 'false))

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
  "Stop only this context's evaluator, capture servers and socket."
  (case (map-get state 'active)
    ((tuple pid _ _) (exit pid 'kill))
    ('undefined 'ok))
  (lists:foreach (lambda (pid) (exit pid 'kill)) (map-get state 'ios))
  (gen_tcp:close (map-get state 'socket))
  'ok)
