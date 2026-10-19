;;;; Supervision for the listener and disposable native contexts.
(defmodule cayrn_lfe_sup
  (behaviour supervisor)
  (export (authority 1) (connection 1) (context 1) (init 1) (start_link 2)))

(defspec (authority 1) (((port)) (call 'supervisor 'startchild_ret)))
(defun authority (socket)
  "Start a paused disposable authority endpoint."
  (endpoint 'cayrn_lfe_authority socket))

(defspec (connection 1) (((port)) (call 'supervisor 'startchild_ret)))
(defun connection (socket)
  "Start a paused first-frame router."
  (endpoint 'cayrn_lfe_connection socket))

(defspec (context 1) (((port)) (call 'supervisor 'startchild_ret)))
(defun context (socket)
  "Start a paused context, with no evaluator environment yet."
  (endpoint 'cayrn_lfe_context socket))

(defun endpoint (module socket)
  (supervisor:start_child (MODULE)
    (map 'id (make_ref)
         'start (tuple module 'start_link (list socket))
         'restart 'temporary 'shutdown 2000 'modules (list module))))

(defspec (init 1)
  (((tuple (port) (string))) (tuple 'ok (tuple (call 'supervisor 'sup_flags)
                             (list (call 'supervisor 'child_spec))))))

(defun init
  "Keep the listener and its contexts in the same failure domain."
  (((tuple socket path))
    (tuple 'ok
      (tuple (map 'strategy 'one_for_all 'intensity 3 'period 10)
        (list (map 'id 'cayrn_lfe_registry
                   'start (tuple 'cayrn_lfe_registry 'start_link '())
                   'restart 'permanent 'shutdown 2000
                   'modules '(cayrn_lfe_registry))
              (map 'id 'cayrn_lfe_listener
                   'start (tuple 'cayrn_lfe_listener 'start_link
                            (list socket path))
                   'restart 'permanent 'shutdown 2000
                   'modules '(cayrn_lfe_listener)))))))

(defspec (start_link 2)
  (((port) (string)) (UNION (tuple 'ok (pid)) (tuple 'error (term)))))

(defun start_link (socket path)
  "Start the tree with the immutable application-owned listening endpoint."
  (supervisor:start_link (tuple 'local (MODULE)) (MODULE) (tuple socket path)))
