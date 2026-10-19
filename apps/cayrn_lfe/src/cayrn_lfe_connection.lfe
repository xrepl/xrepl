;;;; First-frame routing with an explicit socket-ownership handoff.
(defmodule cayrn_lfe_connection
  (behaviour gen_server)
  (export (handle_call 3) (handle_cast 2) (handle_info 2)
          (init 1) (start_link 1) (terminate 2)))

(defrecord connection (socket 'undefined (UNION 'undefined (port))))

(defspec (start_link 1) (((port)) (term)))
(defun start_link (socket)
  "Start paused; the listener transfers ownership before activation."
  (gen_server:start_link (MODULE) socket '()))

(defspec (init 1) (((port)) (term)))
(defun init (socket)
  "Keep only a provisional port and a five-second handshake deadline."
  (tuple 'ok (make-connection socket socket) 5000))

(defspec (handle_info 2) (((term) (record connection)) (term)))
(defun handle_info
  "Read exactly one framed Hello and transfer to one paused endpoint."
  (('activate state)
   (case (inet:setopts (connection-socket state) '(#(active once)))
     ('ok (tuple 'noreply state 5000))
     ((tuple 'error reason) (tuple 'stop reason state))))
  (((tuple 'tcp socket bytes) state)
   (when (=:= socket (connection-socket state)))
   (try
     (route (json:decode bytes) socket state)
     (catch ((tuple _ reason _) (tuple 'stop reason state)))))
  (('timeout state) (tuple 'stop 'handshake_timeout state))
  (((tuple 'tcp_closed _) state) (tuple 'stop 'normal state))
  (((tuple 'tcp_error _ reason) state) (tuple 'stop reason state))
  ((_message state) (tuple 'noreply state 5000)))

(defun route (hello socket state)
  (let* ((role (case hello
                ((map #b("kind") #b("authority_hello") #b("version") 4)
                 'authority)
                ((map #b("kind") #b("hello") #b("version") 4) 'context)))
         ((tuple 'ok child) (call 'cayrn_lfe_sup role socket)))
    (case (gen_tcp:controlling_process socket child)
      ('ok
       ;; Sending to a vanished child is harmless: owner death closes the port.
       (! child (tuple 'activate hello))
       (tuple 'stop 'normal (set-connection state socket 'undefined)))
      ((tuple 'error reason)
       (exit child 'shutdown)
       (tuple 'stop reason state)))))

(defspec (handle_call 3)
  (((term) (call 'gen_server 'from) (record connection)) (term)))
(defun handle_call (_request _from state)
  "Reject unsupported calls."
  (tuple 'reply '#(error unsupported) state))

(defspec (handle_cast 2) (((term) (record connection)) (term)))
(defun handle_cast (_request state)
  "Ignore unsupported casts without extending the handshake lifetime."
  (tuple 'noreply state 5000))

(defspec (terminate 2) (((term) (record connection)) 'ok))
(defun terminate (_reason state)
  "Close the socket only while it still belongs to this router."
  (case (connection-socket state)
    ('undefined 'ok)
    (socket (gen_tcp:close socket)))
  'ok)
