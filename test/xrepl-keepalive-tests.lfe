(defmodule xrepl-keepalive-tests
  "Regression test for L-01: no unsolicited keepalive after idle.

  Uses a standalone Ranch UNIX-socket listener (pre-authenticated, no
  token dance) so the test is self-contained and does not touch the
  default xrepl network supervisor."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

;;; Helpers

(defun listener-ref () 'xrepl-keepalive-test)

(defun tmp-sock-path ()
  "Return a unique /tmp path for the test UNIX socket."
  (++ "/tmp/xrepl-kp-"
      (integer_to_list (erlang:unique_integer (list 'positive)))
      ".sock"))

(defun start-listener (sock-path)
  "Start a standalone Ranch UNIX listener (under ranch_sup, not xrepl-net-sup).
  Stops any leftover listener with the same ref first."
  (catch (ranch:stop_listener (listener-ref)))
  (catch (file:delete sock-path))
  (ranch:start_listener (listener-ref)
                        'ranch_tcp
                        (map 'socket_opts (list (tuple 'ifaddr (tuple 'local sock-path))
                                                (tuple 'port 0))
                             'num_acceptors 1)
                        'xrepl-tcp-handler
                        (map)))

(defun stop-listener (sock-path)
  "Stop the test listener and remove the socket file."
  (catch (ranch:stop_listener (listener-ref)))
  (catch (file:delete sock-path))
  'ok)

;;; Test generator — needs a 60 s eunit timeout (31 s idle + headroom).
;;; deftestgen exports the resulting _test_ function so eunit discovers it.

(deftestgen no-keepalive-after-idle
  (list (tuple 'timeout 60
    (function no-keepalive-after-idle-body 0))))

(defun no-keepalive-after-idle-body ()
  "Assert (a) no unsolicited frame during 31 s idle and
        (b) post-idle eval still returns a correct response.

  On baseline (bug present): server fires after 30000 ms, sending
  #m(status ping) into the socket buffer.  The first recv call below
  then returns {ok, ping-map} instead of {error, timeout} → assertion (a)
  fails → test is RED.

  After fix: nothing is sent during idle; assertion (a) passes; the
  post-idle eval in (b) confirms the stream is still aligned → GREEN."
  (application:ensure_all_started 'xrepl)
  (let ((sock-path (tmp-sock-path)))
    (case (start-listener sock-path)
      (`#(ok ,_)
       (case (xrepl-client:connect (map 'socket (list_to_binary sock-path)))
         (`#(ok ,conn)
          ;; Assertions wrapped in try/after to guarantee cleanup even
          ;; when an assertion throws (as it does in the RED baseline run).
          (try
            (progn
              ;; Idle 31 s — enough for the 30000 ms server timer to fire.
              (timer:sleep 31000)
              ;; (a) Nothing unsolicited should be in the receive buffer.
              (is-equal (tuple 'error 'timeout)
                        (xrepl-client:recv conn 500))
              ;; (b) Post-idle eval still returns a valid response (no desync).
              (case (xrepl-client:eval conn "(+ 1 2)")
                (`#(ok ,_ ,_) (is 'true))
                (`#(error ,reason ,_)
                 (is-equal 'eval-ok (tuple 'error reason)))))
            (after
              (catch (xrepl-client:disconnect conn))
              (stop-listener sock-path))))
         (`#(error ,reason)
          (stop-listener sock-path)
          (is-equal 'connect-ok (tuple 'error reason)))))
      (`#(error ,reason)
       (stop-listener sock-path)
       (is-equal 'listener-ok (tuple 'error reason))))))
