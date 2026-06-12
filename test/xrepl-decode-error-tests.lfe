(defmodule xrepl-decode-error-tests
  "Regression test for CDC-7 / F-6: decode-error path re-arms the socket.

  Sends one malformed (non-msgpack) frame, asserts a decode-error reply
  arrives, then sends a valid eval on the SAME connection and asserts a
  done reply.  Fails on pre-fix code because (funcall transport ...) causes
  a badfun crash after the error reply is sent, closing the connection."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

;;; Helpers — same harness pattern as xrepl-keepalive-tests.lfe

(defun listener-ref () 'xrepl-decode-error-test)

(defun tmp-sock-path ()
  (++ "/tmp/xrepl-de-"
      (integer_to_list (erlang:unique_integer (list 'positive)))
      ".sock"))

(defun start-listener (sock-path)
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
  (catch (ranch:stop_listener (listener-ref)))
  (catch (file:delete sock-path))
  'ok)

;;; Test generator — no idle wait, 10 s timeout is ample.

(deftestgen decode-error-keeps-connection
  (list (tuple 'timeout 10
    (function decode-error-keeps-connection-body 0))))

(defun decode-error-keeps-connection-body ()
  "Send one malformed frame, assert decode-error reply, then eval on the
  same connection and assert a done reply.

  On pre-fix code (funcall bug): after the decode-error reply the handler
  crashes (badfun), the socket closes, and the second recv returns
  {error, closed} → assertion fails → RED.

  After fix (call): handler survives, loops back, processes the eval →
  done reply → GREEN."
  (application:ensure_all_started 'xrepl)
  (let* ((sock-path (tmp-sock-path))
         ;; UNIX socket options — same as xrepl-client:connect-unix
         (sock-opts (cons 'local (list 'binary
                                       (tuple 'packet 4)
                                       (tuple 'active 'false)))))
    (case (start-listener sock-path)
      (`#(ok ,_)
       (case (gen_tcp:connect (tuple 'local sock-path) 0 sock-opts)
         (`#(ok ,sock)
          (try
            (progn
              ;; Step 1: Send garbage bytes — not valid msgpack.
              (gen_tcp:send sock #"GARBAGE")
              ;; Step 2: Recv decode-error reply (server sends it before
              ;;         attempting to re-arm the socket).
              (case (gen_tcp:recv sock 0 5000)
                (`#(ok ,data)
                 (case (xrepl-protocol-msgpack:decode data)
                   (`#(ok ,response)
                    (is-equal #"error" (maps:get #"status" response)))
                   (`#(error ,_)
                    (is-equal 'decodeable-response 'not-msgpack))))
                (`#(error ,reason)
                 (is-equal 'error-reply-received (tuple 'error reason))))
              ;; Step 3: Send valid eval on the SAME connection.
              ;; Pre-fix: handler crashed; gen_tcp:recv returns {error, closed}.
              ;; Post-fix: handler looped back; eval is processed normally.
              (case (xrepl-protocol-msgpack:encode
                      (map 'op 'eval 'code #"(+ 1 2)" 'id #"de-test-1"))
                (`#(ok ,encoded)
                 (gen_tcp:send sock encoded)
                 (case (gen_tcp:recv sock 0 5000)
                   (`#(ok ,eval-data)
                    (case (xrepl-protocol-msgpack:decode eval-data)
                      (`#(ok ,eval-response)
                       ;; Assert done reply — connection survived the decode error
                       (is-equal #"done" (maps:get #"status" eval-response)))
                      (`#(error ,_)
                        (is-equal 'decodeable-eval-response 'not-msgpack))))
                   (`#(error ,reason)
                    ;; RED on baseline: {error, closed}
                    (is-equal 'eval-ok (tuple 'error reason)))))
                (`#(error ,reason)
                 (is-equal 'encode-ok (tuple 'error reason)))))
            (after
              (catch (gen_tcp:close sock))
              (stop-listener sock-path))))
         (`#(error ,reason)
          (stop-listener sock-path)
          (is-equal 'connect-ok (tuple 'error reason)))))
      (`#(error ,reason)
       (stop-listener sock-path)
       (is-equal 'listener-ok (tuple 'error reason))))))
