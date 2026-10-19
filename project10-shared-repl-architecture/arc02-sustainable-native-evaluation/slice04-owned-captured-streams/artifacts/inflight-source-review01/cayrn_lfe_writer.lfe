;;;; Network-only FIFO worker; its context remains the controlling owner.
(defmodule cayrn_lfe_writer
  (export (enqueue 4) (start 1)))

(defspec (start 1) (((port)) (pid)))
(defun start (socket)
  "Start a linked nontrapping writer owned by the calling context."
  (let ((owner (self)))
    (spawn_link (lambda () (loop owner socket)))))

(defspec (enqueue 4)
  (((pid) (reference) (map) (boolean)) 'ok))
(defun enqueue (writer ref event terminal)
  "Queue one correlated frame; only actual send produces writer_sent."
  (! writer (tuple 'write (self) ref event terminal))
  'ok)

(defun loop (owner socket)
  (receive
    ((tuple 'write sender ref event terminal)
     (when (=:= sender owner) (is_reference ref) (is_map event)
           (is_boolean terminal))
     (let (('ok (gen_tcp:send socket (json:encode event))))
       (! owner (tuple 'writer_sent (self) ref))
       (if terminal 'ok (loop owner socket))))
    (_message (error 'invalid_writer_message))))
