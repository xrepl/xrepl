;;;; One persistent raw control channel per Rust host authority.
(defmodule cayrn_lfe_authority
  (behaviour gen_server)
  (export (handle_call 3) (handle_cast 2) (handle_info 2)
          (init 1) (start_link 1) (terminate 2)))

(defrecord authority
  (socket 'undefined (UNION 'undefined (port)))
  (active 'false (boolean)))

(defspec (start_link 1) (((port)) (term)))
(defun start_link (socket)
  "Start paused until the router has transferred the socket."
  (gen_server:start_link (MODULE) socket '()))

(defspec (init 1) (((port)) (term)))
(defun init (socket)
  "Do not grant a lease before socket ownership is transferred."
  (tuple 'ok (make-authority socket socket) 5000))

(defspec (handle_info 2) (((term) (record authority)) (term)))
(defun handle_info
  "Grant once; thereafter any byte, EOF or error retires this owner."
  (((tuple 'activate
      (map #b("kind") #b("authority_hello") #b("version") 4
           #b("authority") authority)) state)
   (when (=:= (authority-active state) 'false))
   (try
     (let* ((socket (authority-socket state))
            ((tuple 'connected owner) (erlang:port_info socket 'connected))
            ('true (=:= owner (self)))
            ((tuple 'ok boot lease) (cayrn_lfe_registry:open authority))
            ('ok (gen_tcp:send socket
                   (json:encode
                     (map 'kind 'authority_ready 'version 4
                          'boot boot 'lease lease))))
            ('ok (inet:setopts socket '(#(packet 0) #(active once)))))
       (tuple 'noreply (set-authority state active 'true)))
     (catch ((tuple _ reason _) (tuple 'stop reason state)))))
  (('timeout state) (tuple 'stop 'handshake_timeout state))
  (((tuple 'tcp _ _) state) (tuple 'stop 'unexpected_authority_data state))
  (((tuple 'tcp_closed _) state) (tuple 'stop 'normal state))
  (((tuple 'tcp_error _ reason) state) (tuple 'stop reason state))
  ((_message state) (tuple 'stop 'invalid_authority_activation state)))

(defspec (handle_call 3)
  (((term) (call 'gen_server 'from) (record authority)) (term)))
(defun handle_call (_request _from state)
  "Reject unsupported calls."
  (tuple 'reply '#(error unsupported) state))

(defspec (handle_cast 2) (((term) (record authority)) (term)))
(defun handle_cast (_request state)
  "Do not accept an authority command protocol after Ready."
  (tuple 'stop 'unexpected_authority_cast state))

(defspec (terminate 2) (((term) (record authority)) 'ok))
(defun terminate (_reason state)
  "Close this owner's socket; the registry observes its exact DOWN."
  (gen_tcp:close (authority-socket state))
  'ok)
