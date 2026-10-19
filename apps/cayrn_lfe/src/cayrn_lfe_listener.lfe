;;;; Private socket listener; Rust remains the durable session authority.
(defmodule cayrn_lfe_listener
  (behaviour gen_server)
  (export (handle_call 3) (handle_cast 2) (handle_info 2)
          (init 1) (start_link 2) (terminate 2)))

(defspec (start_link 2)
  (((port) (string)) (UNION (tuple 'ok (pid)) (tuple 'error (term)))))

(defun start_link (socket path)
  "Accept on the application helper's borrowed listening socket."
  (gen_server:start_link (tuple 'local (MODULE)) (MODULE)
    (tuple socket path) '()))

(defspec (init 1)
  (((tuple (port) (string))) (tuple 'ok (map))))

(defun init
  "Validate a live borrowed endpoint without rebinding or changing ownership."
  (((tuple socket path))
    (process_flag 'trap_exit 'true)
    (let* (((tuple 'connected owner) (erlang:port_info socket 'connected))
           ('true (andalso (is_pid owner) (=/= owner (self))
                          (=:= path (filename:absname path)))))
      (! (self) 'accept)
      (tuple 'ok (map 'socket socket 'path path)))))

(defspec (handle_info 2) (((term) (map)) (tuple 'noreply (map))))

(defun handle_info
  "Accept bounded contexts and transfer socket ownership before activation."
  (('accept (= (map 'socket listener) state))
   (let* ((counts (supervisor:count_children 'cayrn_lfe_sup))
          (temporary (- (proplists:get_value 'active counts) 2)))
     (if (< temporary 128)
       (progn
         (case (gen_tcp:accept listener 100)
           ((tuple 'ok socket) (start-router socket))
           ((tuple 'error 'timeout) 'ok)
           ((tuple 'error reason) (exit reason)))
         (! (self) 'accept))
       (erlang:send_after 10 (self) 'accept)))
   (tuple 'noreply state))
  ((_ state) (tuple 'noreply state)))

(defun start-router (socket)
  (case (cayrn_lfe_sup:connection socket)
    ((tuple 'ok pid)
     (case (gen_tcp:controlling_process socket pid)
       ('ok (! pid 'activate))
       (_ (exit pid 'shutdown) (gen_tcp:close socket))))
    (_ (gen_tcp:close socket))))

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

(defun terminate (_reason _state)
  "Leave the borrowed listen port/path to its application-lifetime owner."
  'ok)
