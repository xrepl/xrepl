;;;; Supervision for the listener and disposable native contexts.
(defmodule cayrn_lfe_sup
  (behaviour supervisor)
  (export (context 1) (init 1) (start_link 0)))

(defspec (context 1) (((port)) (call 'supervisor 'startchild_ret)))

(defun context (socket)
  "Start a temporary context; a failed environment is never restarted."
  (supervisor:start_child (MODULE)
    (map 'id (make_ref)
         'start (tuple 'cayrn_lfe_context 'start_link (list socket))
         'restart 'temporary 'shutdown 2000)))

(defspec (init 1)
  (((nil)) (tuple 'ok (tuple (call 'supervisor 'sup_flags)
                             (list (call 'supervisor 'child_spec))))))

(defun init (_args)
  "Keep the listener and its contexts in the same failure domain."
  (tuple 'ok
    (tuple (map 'strategy 'one_for_all 'intensity 3 'period 10)
      (list (map 'id 'cayrn_lfe_listener
                 'start (tuple 'cayrn_lfe_listener 'start_link '())
                 'restart 'permanent 'shutdown 2000)))))

(defspec (start_link 0)
  (() (UNION (tuple 'ok (pid)) (tuple 'error (term)))))

(defun start_link ()
  "Start the registered native supervisor."
  (supervisor:start_link (tuple 'local (MODULE)) (MODULE) '()))
