;;;; Private socket listener; Rust remains the durable session authority.
(defmodule cayrn_lfe_listener
  (behaviour gen_server)
  (export (handle_call 3) (handle_cast 2) (handle_info 2)
          (init 1) (start_link 0) (terminate 2)))

(defspec (start_link 0)
  (() (UNION (tuple 'ok (pid)) (tuple 'error (term)))))

(defun start_link ()
  "Start the registered native socket listener."
  (gen_server:start_link (tuple 'local (MODULE)) (MODULE) '() '()))

(defspec (init 1)
  (((nil)) (UNION (tuple 'ok (map)) (tuple 'stop (term)))))

(defun init (_args)
  "Create the native identity guard and private framed Unix listener."
  (ets:new 'cayrn_lfe_contexts
    '(named_table public set #(write_concurrency true)))
  (let (((tuple 'ok path) (application:get_env 'cayrn_lfe 'socket)))
    (case (gen_tcp:listen 0
            (list 'binary '#(active false) '#(packet 4)
                  '#(packet_size 262144) (tuple 'ifaddr (tuple 'local path))
                  '#(backlog 64)))
      ((tuple 'ok socket)
       (let (('ok (file:change_mode path #o600)))
         (! (self) 'accept)
         (tuple 'ok (map 'socket socket 'path path))))
      (error (tuple 'stop error)))))

(defspec (handle_info 2) (((term) (map)) (tuple 'noreply (map))))

(defun handle_info
  "Accept bounded contexts and transfer socket ownership before activation."
  (('accept (= (map 'socket listener) state))
   (case (gen_tcp:accept listener 100)
     ((tuple 'ok socket)
      (let ((counts (supervisor:count_children 'cayrn_lfe_sup)))
        (if (=< (proplists:get_value 'active counts) 64)
          (case (cayrn_lfe_sup:context socket)
            ((tuple 'ok pid)
             (let (('ok (gen_tcp:controlling_process socket pid)))
               (! pid 'activate)))
            (_ (gen_tcp:close socket)))
          (gen_tcp:close socket))))
     ((tuple 'error 'timeout) 'ok)
     ((tuple 'error 'closed) (exit 'listener_closed))
     ((tuple 'error reason) (exit reason)))
   (! (self) 'accept)
   (tuple 'noreply state))
  ((_ state) (tuple 'noreply state)))

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

(defun terminate
  "Release only the listener's owned endpoint."
  ((_reason (map 'socket socket 'path path))
   (gen_tcp:close socket)
   (file:delete path)
   'ok))
