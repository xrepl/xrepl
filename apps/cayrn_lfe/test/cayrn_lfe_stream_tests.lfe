;;;; Complete incremental encoding, prefix errors and native stream behavior.
(defmodule cayrn_lfe_stream_tests
  (export (encoding_carry_test 0)
          (invalid_data_preserves_prefix_test 0)
          (large_chardata_test 0)
          (native_complete_output_test_ 0)
          (native_nested_mfa_and_recovery_test_ 0)
          (nested-mfa 0)
          (paused_and_empty_stream_test 0)))

(include-lib "eunit/include/eunit.hrl")

(defun large_chardata_test ()
  "Large binary/list/mixed data emits complete copied bounded UTF8 chunks."
  (let* ((chars (lists:flatten (lists:duplicate 10000 '(65 19990 128512))))
         (expected (unicode:characters_to_binary chars)))
    (lists:foreach
      (lambda (data)
        (let (((tuple result chunks) (collect 'unicode (tuple 'chars data))))
          (assertEqual 'ok result)
          (assert (> (length chunks) 1))
          (assertEqual expected (iolist_to_binary chunks))))
      (list chars expected
        (list '(65) (unicode:characters_to_binary '(19990 128512))
              (cdr (cdr (cdr chars))))))))

(defun encoding_carry_test ()
  "Actual encodings carry split binary fragments across nested lists."
  (lists:foreach
    (lambda (encoding)
      (let* ((chars (if (=:= encoding 'latin1)
                      '(65 233 255) '(65 19990 128512)))
             (expected (unicode:characters_to_binary chars))
             (bytes (unicode:characters_to_binary chars 'unicode encoding))
             (fragments (lists:map (lambda (byte) (binary byte))
                                   (binary_to_list bytes))))
        (assertEqual (tuple 'ok (list expected))
          (collect encoding (tuple 'chars (list fragments))))))
    '(latin1 unicode utf8 utf16 #(utf16 big) #(utf16 little)
      utf32 #(utf32 big) #(utf32 little)))
  ;; These force carry BETWEEN our1024-unit prefixes, not just inside OTP.
  (lists:foreach
    (lambda (encoding)
      (let* ((chars
               (case encoding
                 ('utf8 (++ (lists:duplicate 1023 65) '(128512)))
                 ((tuple 'utf16 _) (++ (lists:duplicate 511 65) '(128512)))
                 ((tuple 'utf32 _) (++ (lists:duplicate 255 65) '(19990)))))
             (bytes (unicode:characters_to_binary chars 'unicode encoding))
             (data (case encoding
                     ((tuple 'utf32 _) (list 65 bytes))
                     (_ bytes)))
             (expected (unicode:characters_to_binary
                         (case encoding
                           ((tuple 'utf32 _) (cons 65 chars))
                           (_ chars))))
             ((tuple status chunks) (collect encoding (tuple 'chars data))))
        (assertEqual 'ok status)
        (assert (> (length chunks) 1))
        (assertEqual expected (iolist_to_binary chunks))))
    '(utf8 #(utf16 big) #(utf16 little) #(utf32 big) #(utf32 little)))
  ;; Incomplete binary followed by integer is an actual OTP error.
  (assertEqual (tuple '#(error badarg) '())
    (collect 'utf8 (tuple 'chars (list #b(226) 65)))))

(defun invalid_data_preserves_prefix_test ()
  "Invalid roots/tails/encoding/carry never turn a committed prefix into ok."
  (lists:foreach
    (lambda (data)
      (assertEqual (tuple '#(error badarg) '())
        (collect 'unicode (tuple 'chars data))))
    (list 65 'bad (binary (1 (size 1)))))
  (assertEqual (tuple '#(error badarg) '())
    (collect 'unknown_encoding (tuple 'chars '())))
  (lists:foreach
    (lambda (data)
      (let (((tuple status chunks) (collect 'unicode (tuple 'chars data))))
        (assertEqual '#(error badarg) status)
        (assertEqual #b("GOOD") (iolist_to_binary chunks))))
    (list (cons #b("GOOD") 1) (list #b("GOOD") #b(255))
          (list #b("GOOD") #b(226))
          (list #b("GOOD") (binary (1 (size 1))))))
  (assertEqual (tuple '#(error badarg) '())
    (collect 'unicode (tuple 'mfa 'erlang 'error '(user_exception)))))

(defun paused_and_empty_stream_test ()
  "No user apply before grant; empty valid write still waits its one ACK."
  (let* ((job (make_ref))
         (worker (cayrn-lfe-stream:start (self) job 'unicode
                   (tuple 'mfa 'erlang 'send (list (self) 'MFA_RAN))))
         (monitor (monitor 'process worker)))
    (try
      (progn
      (receive ('MFA_RAN (error 'formatter_ran_before_registration))
        (after 20 'ok))
      (! worker (tuple 'stream_activate (self) job))
      (receive ('MFA_RAN 'ok) (after 1000 (error 'missing_mfa_activation)))
      ;; send/2 returns an atom, invalid root chardata => ordinary badarg.
      (receive
        ((tuple 'stream_done incoming ref status)
         (when (=:= incoming worker) (=:= ref job))
         (assertEqual '#(error badarg) status))
        (after 1000 (error 'missing_mfa_badarg)))
      (receive
        ((tuple 'DOWN ref 'process pid reason)
         (when (=:= ref monitor) (=:= pid worker))
         (assertEqual 'normal reason))
        (after 1000 (error 'missing_formatter_down))))
      (after (unlink worker) (exit worker 'kill)
             (erlang:demonitor monitor '(flush)))))
  (assertEqual (tuple 'ok (list #b()))
    (collect 'unicode (tuple 'chars '()))))

(defun collect (encoding payload)
  (let* ((job (make_ref))
         (worker (cayrn-lfe-stream:start (self) job encoding payload))
         (monitor (monitor 'process worker)))
    (try
      (progn
        (! worker (tuple 'stream_activate (self) job))
        (collect worker monitor job 1 '()))
      (after (unlink worker) (exit worker 'kill)
             (erlang:demonitor monitor '(flush))))))

(defun collect (worker monitor job index chunks)
  (receive
    ((tuple 'stream_chunk incoming ref chunk text)
     (when (=:= incoming worker) (=:= ref job))
     (assertEqual index chunk)
     (assert (=< (byte_size text) 8192))
     (assert (is_list (unicode:characters_to_list text)))
     (assertEqual (byte_size text) (binary:referenced_byte_size text))
     (receive
       ((tuple 'stream_done same _ _) (when (=:= same worker))
        (error 'done_before_chunk_commit))
       (after 0 'ok))
     (! worker (tuple 'stream_continue (self) job index))
     (collect worker monitor job (+ index 1) (cons text chunks)))
    ((tuple 'stream_done incoming ref status)
     (when (=:= incoming worker) (=:= ref job))
     (receive
       ((tuple 'DOWN incoming-ref 'process pid reason)
        (when (=:= incoming-ref monitor) (=:= pid worker))
        (assertEqual 'normal reason))
       (after 1000 (error 'missing_stream_physical_down)))
     (tuple status (lists:reverse chunks)))
    (after 3000 (error 'missing_stream_progress))))

(defun native_complete_output_test_ ()
  "Actual wire emits every Unicode byte; its original reply waits final ACK."
  (tuple 'timeout 30
    (lambda ()
      (with-context
        (lambda (_peer socket _context)
          (dispatch socket #b("1")
            #b("(io:put_chars (lists:duplicate 10000 19990))"))
          (let* ((expected
                   (unicode:characters_to_binary (lists:duplicate 10000 19990)))
                 ((tuple frames outcome) (drain socket '())))
            (assertEqual expected
              (iolist_to_binary (lists:map
                                  (lambda (f) (map-get f #b("text"))) frames)))
            (assert (> (length frames) 1))
            (assertEqual #b("ok") (map-get outcome #b("value")))
            (assertEqual #b("succeeded") (map-get outcome #b("phase")))))))))

(defun native_nested_mfa_and_recovery_test_ ()
  "Nested MFA writes have independent jobs; ordinary MFA/data errors recover."
  (tuple 'timeout 30
    (lambda ()
      (with-context
        (lambda (_peer socket _context)
          (dispatch socket #b("1")
            #b("(io:request (group_leader) (tuple 'put_chars 'unicode "
               "'cayrn_lfe_stream_tests 'nested-mfa ()))"))
          (let (((tuple frames result) (drain socket '())))
            (assertEqual #b("INNEROUTER")
              (iolist_to_binary
                (lists:map (lambda (f) (map-get f #b("text"))) frames)))
            (assertEqual #b("ok") (map-get result #b("value"))))
          (dispatch socket #b("2")
            #b("(io:request (group_leader) (tuple 'put_chars 'unicode "
               "'erlang 'error (list 'boom)))"))
          (let (((tuple '() error-result) (drain socket '())))
            (assertEqual #b("#(error badarg)")
                         (map-get error-result #b("value"))))
          (dispatch socket #b("3") #b("42"))
          (let (((tuple '() result) (drain socket '())))
            (assertEqual #b("42") (map-get result #b("value")))))))))

(defspec (nested-mfa 0) (() (binary)))
(defun nested-mfa ()
  "User callback fixture deliberately waits on supported nested inherited I/O."
  (let (('ok (io:put_chars #b("INNER")))) #b("OUTER")))

(defun with-context (function)
  (cayrn_lfe_authority_tests:with-peer
    (lambda (peer path)
      (let* (((tuple owner grant)
              (cayrn_lfe_authority_tests:authority path #b("a")))
             ((tuple socket context)
              (cayrn_lfe_authority_tests:context peer path grant #b("1")
                #b("stream") #b("a"))))
        (try (funcall function peer socket context)
          (after (gen_tcp:close socket) (gen_tcp:close owner)))))))

(defun dispatch (socket operation source)
  (gen_tcp:send socket
    (json:encode (map 'kind 'dispatch 'operation operation 'source source
                     'generation #b("g") 'authority #b("a")))))

(defun drain (socket frames)
  (let* (((tuple 'ok bytes) (gen_tcp:recv socket 0 3000))
         (frame (json:decode bytes)))
    (case (map-get frame #b("kind"))
      (#b("outcome") (tuple (lists:reverse frames) frame))
      (#b("output")
       (assertEqual #b("1") (map-get frame #b("operation")))
       (assert (=< (byte_size (map-get frame #b("text"))) 8192))
       (assert (is_list
                 (unicode:characters_to_list (map-get frame #b("text")))))
       (assertEqual '#(error timeout) (gen_tcp:recv socket 0 2))
       (gen_tcp:send socket
         (json:encode (map 'kind 'ack 'position
                          (map-get frame #b("position")))))
       (drain socket (cons frame frames))))))
