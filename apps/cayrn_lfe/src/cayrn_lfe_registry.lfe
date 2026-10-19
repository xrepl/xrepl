;;;; Live node authority leases and physically reclaimed context credits.
(defmodule cayrn_lfe_registry
  (behaviour gen_server)
  (export (admit 7) (handle_call 3) (handle_cast 2) (handle_info 2)
          (init 1) (open 1) (start_link 0) (terminate 2)))

(include-file "../include/cayrn_lfe_registry.lfe")

(defspec (admit 7)
  (((binary) (binary) (binary) (binary) (binary) (binary) (port)) (term)))
(defun admit (boot lease ticket sid generation authority socket)
  "Validate wire domains locally and admit this caller's owned context port."
  (let* (('true (andalso (valid-id? sid) (valid-id? generation)
                         (valid-id? authority)))
         (lease-number (number lease)) (ticket-number (number ticket)))
    (gen_server:call (MODULE)
      (tuple 'admit boot lease-number ticket-number sid generation
             authority socket))))

(defspec (open 1) (((binary)) (term)))
(defun open (authority)
  "Grant this caller a fresh lease, without retaining retired owners."
  (let (('true (valid-id? authority)))
    (gen_server:call (MODULE) (tuple 'open authority))))

(defspec (start_link 0) (() (term)))
(defun start_link ()
  "Start the permanent registry before the listener."
  (gen_server:start_link (tuple 'local (MODULE)) (MODULE) '() '()))

(defspec (init 1) (((nil)) (tuple 'ok (record registry))))
(defun init (_args)
  "Create one cryptographic boot identity and empty live indexes."
  (tuple 'ok (make-registry
               boot (binary:encode_hex (crypto:strong_rand_bytes 16)))))

(defspec (handle_call 3)
  (((term) (call 'gen_server 'from) (record registry)) (term)))
(defun handle_call
  "Serialize grants and consume valid scoped tickets before budget checks."
  (((tuple 'open authority) (tuple owner _) state)
   (let ((leases (registry-leases state)))
     (if (orelse (=:= (map_size leases) 16)
                 (=:= (registry-last-lease state) 9223372036854775807)
                 (lists:any (lambda (lease)
                              (orelse (=:= authority (lease-authority lease))
                                      (=:= owner (lease-owner lease))))
                            (maps:values leases)))
       (tuple 'reply '#(error authority_refused) state)
       (let* ((id (+ (registry-last-lease state) 1))
              (lease (make-lease owner owner monitor (monitor 'process owner)
                                authority authority)))
         (tuple 'reply
           (tuple 'ok (registry-boot state) (integer_to_binary id))
           (set-registry state last-lease id
             leases (map-set leases id lease)))))))
  (((tuple 'admit boot id ticket sid generation authority socket)
    (tuple caller _) state)
   (case (maps:find id (registry-leases state))
     ((tuple 'ok lease)
      (if (andalso (=:= boot (registry-boot state))
                   (=:= authority (lease-authority lease))
                   (> ticket (lease-last-ticket lease))
                   (=:= (erlang:port_info socket 'connected)
                        (tuple 'connected caller)))
        (admit-context id ticket sid generation socket caller lease state)
        (tuple 'reply '#(error invalid_scope) state)))
     (_ (tuple 'reply '#(error invalid_scope) state))))
  ((_request _from state) (tuple 'reply '#(error unsupported) state)))

(defun admit-context (id ticket sid generation socket caller lease state)
  (let* ((consumed (set-registry state leases
                    (map-set (registry-leases state) id
                      (set-lease lease last-ticket ticket))))
         (contexts (registry-contexts state)) (sids (registry-sids state)))
    (if (orelse (=:= (map_size contexts) 64) (maps:is_key sid sids)
                (maps:is_key caller contexts))
      (tuple 'reply '#(error context_refused) consumed)
      (let ((context (make-context pid caller monitor (monitor 'process caller)
                       lease id sid sid generation generation ticket ticket
                       socket socket)))
        (tuple 'reply (tuple 'ok (self))
          (set-registry consumed contexts (map-set contexts caller context)
            sids (map-set sids sid caller)))))))

(defspec (handle_info 2) (((term) (record registry)) (term)))
(defun handle_info
  "Release only exact monitored owners; socket loss is not context reaping."
  (((tuple 'DOWN ref 'process pid _reason) state)
   (case (maps:find pid (registry-contexts state))
     ((tuple 'ok context)
      (if (=:= ref (context-monitor context))
        (tuple 'noreply
          (set-registry state
            contexts (maps:remove pid (registry-contexts state))
            sids (maps:remove (context-sid context) (registry-sids state))))
        (tuple 'noreply state)))
     (_ (tuple 'noreply (retire-owner pid ref state)))))
  ((_message state) (tuple 'noreply state)))

(defun retire-owner (pid ref state)
  (case (lists:filter
          (match-lambda
            (((tuple _ lease))
             (andalso (=:= pid (lease-owner lease))
                      (=:= ref (lease-monitor lease)))))
          (maps:to_list (registry-leases state)))
    ((list (tuple id _lease))
     ;; Revoke before touching ports; credit remains until exact context DOWN.
     (let ((next (set-registry state leases
                   (maps:remove id (registry-leases state)))))
       (lists:foreach
         (lambda (context)
           (if (=:= id (context-lease context))
             (progn
               (abort-port (context-socket context))
               (! (context-pid context)
                  (tuple 'authority_lost (self) (integer_to_binary id))))
             'ok))
         (maps:values (registry-contexts state)))
       next))
    (_ state)))

(defun abort-port (socket)
  ;; OTP prim_inet:close takes direct port_close only with {linger,{true,0}}.
  ;; Never use its default-linger pending-output wait on authority loss.
  (case (inet:setopts socket '(#(linger #(true 0))))
    ('ok (gen_tcp:close socket))
    (_ (catch (erlang:port_close socket))))
  'ok)

(defun number
  ((value) (when (is_binary value) (> (byte_size value) 0)
                 (=< (byte_size value) 19))
   (let* ((n (binary_to_integer value))
          ('true (andalso (> n 0) (=< n 9223372036854775807)
                          (=:= value (integer_to_binary n))))) n))
  ((_) (error 'invalid_native_number)))

(defun valid-id?
  ((id) (when (is_binary id) (> (byte_size id) 0) (=< (byte_size id) 128))
   (=:= (re:run id #b("^[A-Za-z0-9_-]+\\z") '(#(capture none))) 'match))
  ((_) 'false))

(defspec (handle_cast 2) (((term) (record registry)) (term)))
(defun handle_cast (_message state)
  "Ignore unsupported asynchronous requests."
  (tuple 'noreply state))

(defspec (terminate 2) (((term) (record registry)) 'ok))
(defun terminate (_reason _state)
  "The one_for_all supervisor owns native-domain restart."
  'ok)
