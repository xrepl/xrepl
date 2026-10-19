;;;; Responsive immutable origin owner with physically credited I/O jobs.
(defmodule cayrn_lfe_io
  (behaviour gen_server)
  (export (activate 3) (activate_formatter 4) (admit 4) (committed 4)
          (finished 2) (handle_call 3) (handle_cast 2) (handle_info 2)
          (init 1) (retire 2) (seal 2) (start 3) (stop_sealed 2)
          (terminate 2)))

(defrecord capture
  owner owner-monitor operation origin root trace
  (producers (map)) (deliveries (map)) (jobs (map)) (keys (map))
  (sent 0) (observed 0) (finished 'false) (root-accounted 'false)
  (announced 'false) (ready 'false) (sealed 'false)
  (seal-ready 'false) (activated 'false))

(defrecord producer (born 'false) (exited 'false) (delivered 'false))

(defspec (start 3)
  (((pid) (binary) (function)) (tuple 'ok (pid) (reference))))
(defun start (owner operation evaluate)
  "Create a collector-owned paused root; publish identity before activation."
  (let* ((ref (make_ref))
         ((tuple 'ok io)
          (gen_server:start_link (MODULE)
            (tuple owner operation ref evaluate) '())))
    (tuple 'ok io ref)))

(defspec (activate 3) (((pid) (pid) (reference)) 'ok))
(defun activate (io owner ref)
  "Grant source execution only from the registered lifetime owner."
  (let (('true (=:= owner (self))))
    (gen_server:cast io (tuple 'activate owner ref))))

(defspec (admit 4) (((pid) (pid) (reference) (term)) 'ok))
(defun admit (io owner job decision)
  "Answer an exact bounded admission proposal without moving its payload."
  (let (('true (=:= owner (self))))
    (gen_server:cast io (tuple 'admit owner job decision))))

(defspec (activate_formatter 4)
  (((pid) (pid) (reference) (pid)) 'ok))
(defun activate_formatter (io owner job worker)
  "Release only a formatter already registered by both owners."
  (let (('true (=:= owner (self))))
    (gen_server:cast io (tuple 'activate_formatter owner job worker))))

(defspec (committed 4)
  (((pid) (reference) (pid) (pos_integer)) 'ok))
(defun committed (io job worker index)
  "Release one exact chunk after actual send AND durable Rust ACK."
  (gen_server:cast io (tuple 'committed (self) job worker index)))

(defspec (finished 2) (((pid) (pid)) 'ok))
(defun finished (io owner)
  "Record receipt of the root result without inferring trace drain."
  (gen_server:cast io (tuple 'finished owner)))

(defspec (retire 2) (((pid) (pid)) 'ok))
(defun retire (io owner)
  "Grant proven natural retirement; owner monitor survives the unlink gap."
  (gen_server:cast io (tuple 'retire owner)))

(defspec (seal 2) (((pid) (pid)) 'ok))
(defun seal (io owner)
  "Reject new admission while draining previously admitted physical jobs."
  (gen_server:cast io (tuple 'seal owner)))

(defspec (stop_sealed 2) (((pid) (pid)) 'ok))
(defun stop_sealed (io owner)
  "Grant forced retirement only after the stronger seal confirmation."
  (gen_server:cast io (tuple 'stop_sealed owner)))

(defspec (init 1) (((tuple)) (tuple 'ok (record capture))))
(defun init
  "Acquire linked paused root and trace with explicit rollback at each stage."
  (((tuple owner operation ref evaluate))
   (process_flag 'trap_exit 'true)
   (let* ((owner-monitor (monitor 'process owner))
          (root (spawn_link
                  (lambda ()
                    (receive
                      ((tuple 'evaluate incoming)
                       (when (=:= incoming ref)) (funcall evaluate)))))))
     (try
       (let ((trace (trace:session_create 'cayrn_capture (self) '())))
         (try
           (let* ((1 (trace:send trace
                       (list (tuple
                               (list (self) (tuple 'io_request '_ '_ '_))
                               '() '())) '()))
                  ('true (group_leader (self) root))
                  (1 (trace:process trace root 'true
                       '(procs set_on_spawn send))))
             (! owner (tuple 'origin_ready (self) ref root trace))
             (tuple 'ok
               (make-capture owner owner owner-monitor owner-monitor
                 operation operation origin ref root root trace trace
                 producers (map root (make-producer born 'true)))))
           (catch
             ((tuple class reason stack)
              (trace:session_destroy trace)
              (erlang:raise class reason stack)))))
       (catch
         ((tuple class reason stack)
          (exit root 'kill)
          (erlang:demonitor owner-monitor '(flush))
          (erlang:raise class reason stack)))))))

(defspec (handle_call 3)
  (((term) (call 'gen_server 'from) (record capture)) (term)))
(defun handle_call (_request _from state)
  "Reject calls; owner control never synchronously calls back into a peer."
  (tuple 'reply '#(error unsupported) state))

(defspec (handle_cast 2) (((term) (record capture)) (term)))
(defun handle_cast
  "Validate exact owner grants, physical credits and retirement predicates."
  (((tuple 'activate owner ref)
    (= (match-capture owner owner origin ref activated 'false
                      sealed 'false) state))
   (! (capture-root state) (tuple 'evaluate ref))
   (continue (set-capture-activated state 'true)))
  (((tuple 'admit owner job decision)
    (= (match-capture owner owner) state))
   (let* ((entry (map-get (capture-jobs state) job))
          ('proposed (map-get entry 'phase)))
     (case decision
       ('grant (start-formatter job entry state))
       ((tuple 'error reason)
        (reply entry (tuple 'error reason))
        (continue (remove-job job entry state))))))
  (((tuple 'activate_formatter owner job worker)
    (= (match-capture owner owner) state))
   (let* ((entry (map-get (capture-jobs state) job))
          ('paused (map-get entry 'phase))
          ('true (=:= worker (map-get entry 'worker))))
     (! worker (tuple 'stream_activate (self) job))
     (continue (put-job job (map-set entry 'phase 'active) state))))
  (((tuple 'committed owner job worker index)
    (= (match-capture owner owner) state))
   (let* ((entry (map-get (capture-jobs state) job))
          ('true (=:= worker (map-get entry 'worker)))
          ('true (=:= index (map-get entry 'pending))))
     (! worker (tuple 'stream_continue (self) job index))
     (continue (put-job job
                 (map-set entry 'pending 'undefined 'index (+ index 1))
                 state))))
  (((tuple 'finished owner) (= (match-capture owner owner) state))
   (continue (set-capture-finished state 'true)))
  (((tuple 'seal owner) (= (match-capture owner owner) state))
   (continue (set-capture-sealed state 'true)))
  (((tuple 'retire owner)
    (= (match-capture owner owner ready 'true sealed 'false) state))
   (let (('true (drained? state))) (tuple 'stop 'normal state)))
  (((tuple 'stop_sealed owner)
    (= (match-capture owner owner sealed 'true seal-ready 'true) state))
   ;; The recorded seal proof is stable: later requests only get rejected.
   (let (('true (capture-root-accounted state))
         (0 (map_size (capture-jobs state))))
     (tuple 'stop 'normal state)))
  ((_request _state) (error 'invalid_capture_control)))

(defspec (handle_info 2) (((term) (record capture)) (term)))
(defun handle_info
  "Account EVERY request, trace witness and exact owned-worker disposition."
  (((tuple 'io_request from ref request) state)
   (let ((next (set-capture-observed state (+ 1 (capture-observed state)))))
     (cond
       ((capture-sealed next)
        (! from (tuple 'io_reply ref '#(error terminated))) (continue next))
       ((maps:is_key (tuple from ref) (capture-keys next))
        (error 'duplicate_io_request))
       ((=:= 64 (map_size (capture-jobs next)))
        (! from (tuple 'io_reply ref '#(error enobufs))) (continue next))
       ('true
        (case (output request)
          ((tuple 'ok encoding payload)
           (let* ((job (make_ref))
                  (entry (map 'from from 'reply ref 'encoding encoding
                              'payload payload 'phase 'proposed)))
             (! (capture-owner next)
                (tuple 'admit_io (self) (capture-origin next) job))
             (continue
               (set-capture-keys (put-job job entry next)
                 (map-set (capture-keys next) (tuple from ref) job)))))
          ((tuple 'error reason)
           (! from (tuple 'io_reply ref (tuple 'error reason)))
           (continue next)))))))
  (((tuple 'stream_chunk worker job index text) state)
   (let* ((entry (map-get (capture-jobs state) job))
          ('true (=:= worker (map-get entry 'worker)))
          ('active (map-get entry 'phase))
          ('undefined (map-get entry 'pending))
          ('true (=:= index (map-get entry 'index)))
          ('true (andalso (is_binary text) (=< (byte_size text) 8192))))
     (! (capture-owner state)
        (tuple 'capture (self) (capture-origin state)
               (capture-operation state) job worker index text))
     (continue (put-job job (map-set entry 'pending index) state))))
  (((tuple 'stream_done worker job status) state)
   (let* ((entry (map-get (capture-jobs state) job))
          ('true (=:= worker (map-get entry 'worker)))
          ('undefined (map-get entry 'pending))
          ('undefined (map-get entry 'done))
          ('true (orelse (=:= status 'ok) (=:= status '#(error badarg)))))
     (continue (put-job job (map-set entry 'done status) state))))
  (((tuple 'DOWN ref 'process owner reason)
    (= (match-capture owner owner owner-monitor ref) state))
   (tuple 'stop (tuple 'owner_lost reason) state))
  (((tuple 'DOWN ref 'process worker reason) state)
   (let* ((matches (lists:filter
                    (match-lambda
                      (((tuple _ entry))
                       (andalso (=:= worker (maps:get 'worker entry 'none))
                                (=:= ref (maps:get 'monitor entry 'none)))))
                    (maps:to_list (capture-jobs state))))
          ((list (tuple job entry)) matches)
          ('true (=:= reason 'normal))
          ('true (=/= (map-get entry 'done) 'undefined))
          ('false (map-get entry 'down)))
     (continue (put-job job (map-set entry 'down 'true) state))))
  (((tuple 'EXIT owner reason) (= (match-capture owner owner) state))
   (tuple 'stop (tuple 'owner_lost reason) state))
  (((tuple 'EXIT root _reason) (= (match-capture root root) state))
   ;; Context's exact root monitor decides expected destructive interruption.
   (continue state))
  (((tuple 'EXIT _worker 'normal) state)
   ;; Link exit never returns credit; exact worker DOWN and done do that.
   (continue state))
  (((tuple 'EXIT worker reason) state)
   (tuple 'stop (tuple 'formatter_lost worker reason) state))
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

(defun start-formatter (job entry state)
  (let ((worker (cayrn-lfe-stream:start (self) job
                  (map-get entry 'encoding) (map-get entry 'payload))))
    (try
      (let* (('true (group_leader (self) worker))
             (1 (trace:process (capture-trace state) worker 'true
                  '(procs set_on_spawn send)))
             (monitor (monitor 'process worker))
             (registered (map-set (maps:remove 'payload entry)
                           'worker worker 'monitor monitor 'phase 'paused
                           'index 1 'pending 'undefined
                           'done 'undefined 'down 'false))
             (next (set-capture-producers
                     (put-job job registered state)
                     (map-set (capture-producers state) worker
                       (make-producer born 'true)))))
        (! (capture-owner state)
           (tuple 'formatter_ready (self) (capture-origin state) job worker))
        (continue next))
      (catch
        ((tuple class reason stack)
         (exit worker 'kill)
         (erlang:raise class reason stack))))))

(defun put-job (job entry state)
  (set-capture-jobs state (map-set (capture-jobs state) job entry)))

(defun remove-job (job entry state)
  (set-capture state jobs (maps:remove job (capture-jobs state))
    keys (maps:remove (tuple (map-get entry 'from) (map-get entry 'reply))
                      (capture-keys state))))

(defun reply (entry status)
  (! (map-get entry 'from) (tuple 'io_reply (map-get entry 'reply) status)))

(defun complete-jobs (state)
  (lists:foldl
    (match-lambda
      (((tuple job entry) current)
       (if (andalso (=:= (maps:get 'down entry 'false) 'true)
                    (=/= (maps:get 'done entry 'undefined) 'undefined)
                    (not (maps:is_key (map-get entry 'worker)
                                     (capture-producers current))))
         (progn
           (reply entry (map-get entry 'done))
           (! (capture-owner current)
              (tuple 'job_done (self) (capture-origin current) job
                     (map-get entry 'worker)))
           (remove-job job entry current))
         current))) state (maps:to_list (capture-jobs state))))

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
           (=:= 0 (map_size (capture-jobs state)))))

(defun sealed-drained? (state)
  (andalso (capture-root-accounted state)
           (=:= 0 (map_size (capture-jobs state)))
           (=:= (capture-sent state) (capture-observed state))))

(defun continue (incoming)
  (let ((state (complete-jobs incoming)))
    (cond
      ((capture-sealed state)
       (if (andalso (sealed-drained? state) (not (capture-seal-ready state)))
         (progn
           (! (capture-owner state)
              (tuple 'sealed (self) (capture-operation state)))
           (tuple 'noreply (set-capture-seal-ready state 'true)))
         (tuple 'noreply state)))
      ((capture-ready state) (tuple 'noreply state))
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

(defspec (terminate 2) (((term) (record capture)) 'ok))
(defun terminate (_reason state)
  "Kill known user workers first, then destroy tracing and owner monitor."
  (exit (capture-root state) 'kill)
  (maps:foreach
    (lambda (_job entry)
      (case (maps:find 'worker entry)
        ((tuple 'ok worker) (exit worker 'kill))
        (_ 'ok))) (capture-jobs state))
  (trace:session_destroy (capture-trace state))
  (erlang:demonitor (capture-owner-monitor state) '(flush))
  'ok)

(defun output
  (((tuple 'put_chars encoding chars))
   (tuple 'ok encoding (tuple 'chars chars)))
  (((tuple 'put_chars chars))
   (tuple 'ok 'unicode (tuple 'chars chars)))
  (((tuple 'put_chars encoding module function args))
   (tuple 'ok encoding (tuple 'mfa module function args)))
  (((tuple 'put_chars module function args))
   (tuple 'ok 'unicode (tuple 'mfa module function args)))
  ((_) '#(error enotsup)))
