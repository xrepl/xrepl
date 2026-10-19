;;;; Application-lifetime ownership of the borrowed native listening port.
(defmodule cayrn_lfe_app
  (behaviour application)
  (export (start 2) (stop 1)))

(include-lib "kernel/include/file.hrl")

(defrecord identity
  (major 0 (non_neg_integer))
  (minor 0 (non_neg_integer))
  (inode 0 (non_neg_integer))
  (type #o140000 (non_neg_integer)))

(defrecord endpoint
  (socket 'undefined (UNION 'undefined (port)))
  (path "" (string))
  (identity 'undefined (UNION 'undefined (record identity))))

(defspec (start 2)
  (((call 'application 'start_type) (term))
   (UNION (tuple 'ok (pid) (record endpoint)) (tuple 'error (term)))))
(defun start (_type _args)
  "Own the listen port in the existing app helper across child restarts."
  (let* (((tuple 'ok configured) (application:get_env 'cayrn_lfe 'socket))
         (path (filename:absname configured)))
    (case (gen_tcp:listen 0
            (list 'binary '#(active false) '#(packet 4)
                  '#(packet_size 262144) (tuple 'ifaddr (tuple 'local path))
                  '#(backlog 64)))
      ((tuple 'ok socket) (acquire (make-endpoint socket socket path path)))
      (error error))))

(defun acquire (provisional)
  ;; Capture identity BEFORE chmod; failed capture cannot authorize unlink.
  (case (try (capture-identity (endpoint-path provisional))
          (catch ((tuple class reason _)
                  (tuple 'error (tuple class reason)))))
    ((tuple 'ok identity)
     (let ((state (set-endpoint provisional identity identity)))
       (try
         (let (('ok (file:change_mode (endpoint-path state) #o600)))
           (case (cayrn_lfe_sup:start_link
                   (endpoint-socket state) (endpoint-path state))
             ((tuple 'ok supervisor) (tuple 'ok supervisor state))
             (error (dispose state) error)))
         (catch
           ((tuple class reason _)
            (dispose state)
            (tuple 'error (tuple class reason)))))))
    (error
     (dispose provisional)
     (tuple 'error (tuple 'endpoint_identity error)))))

(defun capture-identity (path)
  (case (file:read_link_info path)
    ((tuple 'ok info)
     (let ((inode (file_info-inode info))
           (major (file_info-major_device info))
           (minor (file_info-minor_device info))
           (type (band (file_info-mode info) #o170000)))
       (if (andalso (=:= (file_info-type info) 'other)
                    (=:= type #o140000) (is_integer inode) (> inode 0)
                    (is_integer major) (>= major 0)
                    (is_integer minor) (>= minor 0))
         (tuple 'ok (make-identity major major minor minor
                                  inode inode type type))
         '#(error unsupported_socket_identity))))
    (error error)))

(defspec (stop 1) (((record endpoint)) 'ok))
(defun stop (state)
  "Reap the exact listen port after Sup death, then guard pathname unlink."
  (dispose state))

(defun dispose (state)
  ;; OTP ignores stop's result: explicit diagnostics survive failed cleanup.
  (let ((result
          (try (close-and-unlink state)
            (catch ((tuple class reason _)
                    (tuple 'error (tuple class reason)))))))
    (case result
      ('ok 'ok)
      (failure
       (logger:error "Native listener cleanup failed for ~p: ~p"
         (list (endpoint-path state) failure)))))
  'ok)

(defun close-and-unlink (state)
  (let* ((socket (endpoint-socket state))
         (ref (monitor 'port socket))
         (closed (try (gen_tcp:close socket)
                   (catch ((tuple class reason _)
                           (tuple 'error (tuple class reason)))))))
    (case closed
      ('ok 'ok)
      (failure (logger:error "Native listening-port close failed: ~p"
                 (list failure))))
    (receive
      ((tuple 'DOWN incoming 'port port _reason)
       (when (=:= incoming ref) (=:= port socket))
       (unlink-owned-path state))
      (after 1000
        (erlang:demonitor ref '(flush))
        (tuple 'error (tuple 'listen_port_down_timeout closed))))))

(defun unlink-owned-path
  (((match-endpoint identity 'undefined))
   '#(error unconfirmed_path_retained))
  ((state)
   (let ((path (endpoint-path state)))
     (case (capture-identity path)
       ((tuple 'ok current)
        (if (=:= current (endpoint-identity state))
          (case (file:delete path)
            ('ok 'ok)
            ('#(error enoent) 'ok)
            (error error))
          'ok))
       ('#(error enoent) 'ok)
       ('#(error unsupported_socket_identity) 'ok)
       (error error)))))
