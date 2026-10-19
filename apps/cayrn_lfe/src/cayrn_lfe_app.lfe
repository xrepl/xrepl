;;;; Native Cayrn application boundary.
(defmodule cayrn_lfe_app
  (behaviour application)
  (export (start 2) (stop 1)))

(defspec (start 2)
  (((call 'application 'start_type) (term))
   (UNION (tuple 'ok (pid)) (tuple 'error (term)))))

(defun start (_type _args)
  "Start the native supervision tree without legacy xrepl services."
  (cayrn_lfe_sup:start_link))

(defspec (stop 1) (((term)) 'ok))

(defun stop (_state)
  "Finish application shutdown after the supervision tree stops."
  'ok)
