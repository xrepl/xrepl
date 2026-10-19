;;;; Immutable capture origin with producer and durable-write drain proof.
(defmodule cayrn_lfe_io
  (behaviour gen_server)
  (export (committed 3) (finished 2)
          (handle_call 3) (handle_cast 2) (handle_info 2)
          (init 1) (retire 2) (seal 2) (start 3) (terminate 2)))

(defrecord capture
  owner operation root trace
  (producers (map)) (deliveries (map)) (pending (map))
  (sent 0) (observed 0) (finished 'false) (root-accounted 'false)
  (announced 'false) (ready 'false) (sealed 'false))

(defrecord producer (born 'false) (exited 'false) (delivered 'false))

(defspec (start 3)
  (((pid) (binary) (pid)) (tuple 'ok (pid) (term))))

(defun start (owner operation root)
  "Start linked capture and trace a paused root before it can evaluate."
  (let* (((tuple 'ok pid)
          (gen_server:start_link (MODULE) (tuple owner operation root) '()))
         (trace (try (gen_server:call pid 'trace)
                  (catch
                    ((tuple class reason stack)
                     (unlink pid)
                     (exit pid 'kill)
                     (erlang:raise class reason stack))))))
    (tuple 'ok pid trace)))

(defspec (committed 3) (((pid) (pid) (reference)) 'ok))

(defun committed (io from ref)
  "Release one exact pending writer only after durable host commitment."
  (gen_server:cast io (tuple 'committed (self) from ref)))

(defspec (finished 2) (((pid) (pid)) 'ok))

(defun finished (io owner)
  "Record that the owner has received the foreground evaluation result."
  (gen_server:cast io (tuple 'finished owner)))

(defspec (retire 2) (((pid) (pid)) 'ok))

(defun retire (io owner)
  "Grant a previously proven natural retirement after owner unlink."
  (gen_server:cast io (tuple 'retire owner)))

(defspec (seal 2) (((pid) (pid)) 'ok))

(defun seal (io owner)
  "Stop accepting output and acknowledge the owner's forced close barrier."
  (gen_server:cast io (tuple 'seal owner)))

(defspec (init 1) (((tuple)) (tuple 'ok (tuple))))

(defun init
  "Install only this origin's filtered, inherited local process tracing."
  (((tuple owner operation root))
   (let ((trace (trace:session_create 'cayrn_capture (self) '())))
     (try
       (let* ((1 (trace:send trace
                   (list (tuple
                           (list (self) (tuple 'io_request '_ '_ '_))
                           '() '())) '()))
              (1 (trace:process trace root 'true '(procs set_on_spawn send))))
         (tuple 'ok
           (make-capture owner owner operation operation root root trace trace
             producers (map root (make-producer born 'true)))))
       (catch
         ((tuple class reason stack)
          (trace:session_destroy trace)
          (erlang:raise class reason stack)))))))

(defspec (handle_call 3)
  (((term) (call 'gen_server 'from) (tuple))
   (tuple 'reply (term) (tuple))))

(defun handle_call
  "Expose the owned trace handle only to the startup wrapper."
  (('trace _from state) (tuple 'reply (capture-trace state) state))
  ((_request _from state) (tuple 'reply '#(error unsupported) state)))

(defspec (handle_cast 2)
  (((term) (tuple))
   (UNION (tuple 'noreply (tuple)) (tuple 'stop (term) (tuple)))))

(defun handle_cast
  "Process owner notifications without blocking capture or control."
  (((tuple 'finished owner) (= (match-capture owner owner) state))
   (continue (set-capture-finished state 'true)))
  (((tuple 'committed owner from ref)
    (= (match-capture owner owner pending pending) state))
   (let* (((tuple 'true next) (maps:take (tuple from ref) pending)))
     (! from (tuple 'io_reply ref 'ok))
     (continue (set-capture-pending state next))))
  (((tuple 'seal owner) (= (match-capture owner owner) state))
   (! owner (tuple 'sealed (self) (capture-operation state)))
   (tuple 'noreply (set-capture-sealed state 'true)))
  (((tuple 'retire owner)
    (= (match-capture owner owner ready 'true sealed 'false) state))
   (let (('true (drained? state)))
     (tuple 'stop 'normal state)))
  ((_request _state) (error 'invalid_capture_control)))

(defspec (handle_info 2) (((term) (tuple)) (tuple 'noreply (tuple))))

(defun handle_info
  "Account births, exits, trace delivery and actual I/O independently."
  (((tuple 'io_request from ref _)
    (= (match-capture sealed 'true) state))
   (! from (tuple 'io_reply ref '#(error terminated)))
   (tuple 'noreply state))
  (((tuple 'io_request from ref request) state)
   (let* ((key (tuple from ref))
          (pending (capture-pending state))
          ('false (maps:is_key key pending))
          (next (set-capture-observed state (+ 1 (capture-observed state)))))
     (case (output request)
       ((tuple 'ok text) (when (=< (byte_size text) 8192))
        (! (capture-owner state)
           (tuple 'capture (self) from ref (capture-operation state) text))
        (continue (set-capture-pending next (map-set pending key 'true))))
       ((tuple 'ok _)
        (! from (tuple 'io_reply ref '#(error emsgsize)))
        (continue next))
       ((tuple 'error reason)
        (! from (tuple 'io_reply ref (tuple 'error reason)))
        (continue next)))))
  (((tuple 'trace _parent 'spawn child _entry) state)
   (let* ((producers (capture-producers state))
          (p (maps:get child producers (make-producer)))
          ('false (producer-born p)))
     (continue (prune child
                 (set-capture-producers state
                   (map-set producers child (set-producer-born p 'true)))))))
  (((tuple 'trace _pid 'spawned _parent _entry) state)
   (tuple 'noreply state))
  (((tuple 'trace pid 'exit _reason) state)
   (let* ((producers (capture-producers state))
          (p (maps:get pid producers (make-producer)))
          ('false (producer-exited p))
          (ref (trace:delivered (capture-trace state) pid)))
     (continue
       (set-capture-deliveries
         (set-capture-producers state
           (map-set producers pid (set-producer-exited p 'true)))
         (map-set (capture-deliveries state) ref pid)))))
  (((tuple 'trace_delivered pid ref) state)
   (let* (((tuple incoming deliveries)
           (maps:take ref (capture-deliveries state)))
          ('true (=:= incoming pid))
          (producers (capture-producers state))
          (p (map-get producers pid))
          ('true (producer-exited p)))
     (continue
       (prune pid
         (set-capture-producers
           (set-capture-deliveries state deliveries)
           (map-set producers pid (set-producer-delivered p 'true)))))))
  (((tuple 'trace _pid 'send (tuple 'io_request _ _ _) destination) state)
   (when (=:= destination (self)))
   (continue (set-capture-sent state (+ 1 (capture-sent state)))))
  ((_message state) (tuple 'noreply state)))

(defun prune (pid state)
  (let* ((producers (capture-producers state))
         (p (map-get producers pid)))
    (if (andalso (producer-born p) (producer-exited p)
                 (producer-delivered p))
      (set-capture-root-accounted
        (set-capture-producers state (maps:remove pid producers))
        (orelse (capture-root-accounted state)
                (=:= pid (capture-root state))))
      state)))

(defun drained? (state)
  (andalso (capture-finished state) (capture-root-accounted state)
           (=:= 0 (map_size (capture-producers state)))
           (=:= 0 (map_size (capture-deliveries state)))
           (=:= (capture-sent state) (capture-observed state))
           (=:= 0 (map_size (capture-pending state)))))

(defun continue
  (((= (match-capture sealed 'true) state)) (tuple 'noreply state))
  (((= (match-capture ready 'true) state)) (tuple 'noreply state))
  ((state)
   (cond
     ((drained? state)
      (! (capture-owner state)
         (tuple 'retire_ready (self) (capture-operation state)))
      (tuple 'noreply (set-capture-ready state 'true)))
     ((andalso (capture-finished state) (capture-root-accounted state)
               (> (map_size (capture-producers state)) 0)
               (not (capture-announced state)))
      (! (capture-owner state)
         (tuple 'foreground_ready (self) (capture-operation state)))
      (tuple 'noreply (set-capture-announced state 'true)))
     ('true (tuple 'noreply state)))))

(defspec (terminate 2) (((term) (tuple)) 'ok))

(defun terminate (_reason state)
  "Destroy only this origin's trace session on every orderly shutdown."
  (trace:session_destroy (capture-trace state))
  'ok)

(defun output
  (((tuple 'put_chars encoding chars)) (text chars encoding))
  (((tuple 'put_chars chars)) (text chars 'unicode))
  (((tuple 'put_chars encoding module function args))
   (try (text (apply module function args) encoding)
     (catch ((tuple _ _ _) (tuple 'error 'badarg)))))
  (((tuple 'put_chars module function args))
   (output (tuple 'put_chars 'unicode module function args)))
  ((_) (tuple 'error 'enotsup)))

(defun text (chars encoding)
  (try
    (case (unicode:characters_to_binary chars encoding 'utf8)
      (bytes (when (is_binary bytes)) (tuple 'ok bytes))
      (_ (tuple 'error 'badarg)))
    (catch ((tuple _ _ _) (tuple 'error 'badarg)))))
