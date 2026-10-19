;;;; Renderer budgets and actual native4 retained-environment controls.
(defmodule cayrn_lfe_preview_tests
  (export
   (conservative_list_boundaries_test 0)
   (delimiter_reservations_test 0)
   (depth_boundaries_test 0)
   (huge_integer_test 0)
   (integer_byte_boundaries_test 0)
   (native_cancel_reports_false_test_ 0)
   (native_error_previews_preserve_environment_test_ 0)
   (native_large_values_preserve_environment_test_ 0)
   (scalar_spellings_test 0)
   (structural_types_test 0)
   (unicode_boundary_test 0)
   (wide_collections_test_ 0)))

(include-lib "eunit/include/eunit.hrl")

(defun scalar_spellings_test ()
  "Keep scalar spelling, short strings, escapes and literal ellipses honest."
  (lists:foreach
    (match-lambda
      (((tuple value expected))
       (assertEqual (tuple expected 'false) (checked value))))
    (list (tuple '() #b("()")) (tuple 0 #b("0"))
          (tuple -42 #b("-42")) (tuple 1.5 #b("1.5"))
          (tuple 'hello #b("hello")) (tuple '|a b| #b("|a b|"))
          (tuple '|...| #b("...")) (tuple "..." #b("\"...\""))
          (tuple (list 34 92 10) #b("\"\\\"\\\\\\n\""))
          (tuple (list 19990 30028) (utf8 (list 34 19990 30028 34)))
          (tuple #b() #b("#\"\""))
          (tuple #b("abc") #b("#\"abc\""))
          (tuple (tuple) #b("#()")) (tuple (map) #b("#M()")))))

(defun structural_types_test ()
  "Cover improper lists, invalid binary, bit tails, identities and functions."
  (assertEqual (tuple #b("(1 . 2)") 'false) (checked (cons 1 2)))
  (assertEqual (tuple #b("(55296)") 'false) (checked (list 55296)))
  (assertEqual (tuple #b("#(1 2)") 'false) (checked (tuple 1 2)))
  (assertEqual (tuple #b("#M(a 1)") 'false) (checked (map 'a 1)))
  (assertEqual (tuple #b("#B(255 0)") 'false) (checked #b(255 0)))
  (assertEqual (tuple #b("#B(255 (5 (size 3)))") 'false)
    (checked (binary 255 (5 (size 3)))))
  (assertEqual (tuple #b("#B((1 (size 1)))") 'false)
    (checked (binary (1 (size 1)))))
  (assertEqual (tuple #b("(function erlang abs 1)") 'false)
    (checked #'erlang:abs/1))
  (let* ((function (lambda (x) x))
         ((tuple text omitted) (checked function)))
    (assertNot omitted)
    (assertEqual 0 (element 1 (binary:match text #b("#Fun<"))))
    (assertEqual #b("/1>") (binary:part text (- (byte_size text) 3) 3)))
  (assertEqual
    (tuple (iolist_to_binary (list "#Pid" (pid_to_list (self)))) 'false)
    (checked (self)))
  (let ((ref (make_ref)))
    (assertEqual (tuple (list_to_binary (erlang:ref_to_list ref)) 'false)
      (checked ref)))
  (let (((tuple 'ok port) (gen_tcp:listen 0 '(binary #(active false)))))
    (try
      (assertEqual (tuple (list_to_binary (erlang:port_to_list port)) 'false)
        (checked port))
      (after (gen_tcp:close port)))))

(defun conservative_list_boundaries_test ()
  "Conservative marker reservation may omit a representation that would fit."
  (let (((tuple text omitted) (checked (lists:duplicate 4094 1))))
    (assertEqual 8189 (byte_size text))
    (assertNot omitted))
  (lists:foreach
    (lambda (count)
      (let (((tuple _text omitted) (checked (lists:duplicate count 1))))
        (assert omitted)))
    '(4095 4096)))

(defun integer_byte_boundaries_test ()
  "Exact root byte boundaries have no arbitrary smaller integer cap."
  (let* ((digits (list_to_binary (lists:duplicate 8192 57)))
         (value (binary_to_integer digits)))
    (assertEqual (tuple digits 'false) (checked value))
    (assertEqual (tuple #b("...") 'true) (checked (* value 10))))
  (let* ((digits (list_to_binary (cons 45 (lists:duplicate 8191 57))))
         (value (binary_to_integer digits)))
    (assertEqual (tuple digits 'false) (checked value))
    (assertEqual (tuple #b("...") 'true) (checked (* value 10)))))

(defun huge_integer_test ()
  "A million-bit integer is fenced before decimal conversion in both signs."
  (let ((value (bsl 1 1000000)))
    (assertEqual (tuple #b("...") 'true) (checked value))
    (assertEqual (tuple #b("...") 'true) (checked (- value)))))

(defun depth_boundaries_test ()
  "32 structural levels fit; a33rd compound reports depth omission."
  (let* ((at-limit (nest 32)) (over-limit (nest 33))
         ((tuple _complete omitted) (checked at-limit))
         ((tuple preview truncated) (checked over-limit)))
    (assertNot omitted) (assert truncated)
    (assertNotEqual 'nomatch (binary:match preview #b("...")))))

(defun nest (depth)
  (lists:foldl (lambda (_ value) (tuple value)) 1 (lists:seq 1 depth)))

(defun unicode_boundary_test ()
  "Byte counting never splits a multibyte atom or encoded short string."
  (let* ((atom (list_to_atom (list 19990 30028)))
         ((tuple small omitted) (checked atom)))
    (assertEqual (utf8 '(19990 30028)) small) (assertNot omitted)
    (let (((tuple _text truncated) (checked (lists:duplicate 2000 atom))))
      (assert truncated))
    (lists:foreach
      (lambda (remaining)
        (checked (tuple (padding (- 8188 remaining)) atom)))
      '(3 4 5 6 7 8 9 10))))

(defun wide_collections_test_ ()
  "100k-wide values use structural previews, never a full collection print."
  (tuple 'timeout 30
    (lambda ()
      (let ((items (lists:duplicate 100000 1)))
        (lists:foreach
          (lambda (value)
            (let (((tuple _text omitted) (checked value))) (assert omitted)))
          (list items (list_to_tuple items) (binary:copy #b("a") 100000)
                (maps:from_list
                  (lists:map (lambda (i) (tuple i i))
                             (lists:seq 1 100000)))))))))

(defun delimiter_reservations_test ()
  "Exercise minimal child/map-pair/improper/bit-tail budgets via render/1."
  (let ((values (list (list 1) (cons 1 0) (tuple 1)
                      (map (tuple 1) (cons 2 0)) #b(0 255)
                      (binary (5 (size 3))))))
    (lists:foreach
      (lambda (remaining)
        (lists:foreach
          (lambda (value)
            (let (((tuple text _omitted)
                   (checked (tuple (padding (- 8188 remaining)) value))))
              (balanced (binary_to_list text) 0))) values))
      (lists:seq 3 24))))

(defun padding (digits)
  (list_to_integer (lists:duplicate digits 57)))

(defun balanced
  (('() count) (assertEqual 0 count))
  (((cons 40 tail) count) (balanced tail (+ count 1)))
  (((cons 41 tail) count)
   (assert (> count 0)) (balanced tail (- count 1)))
  (((cons _ tail) count) (balanced tail count)))

(defun native_large_values_preserve_environment_test_ ()
  "Actual native4 large bound values succeed, then their full bindings work."
  (tuple 'timeout 60
    (lambda ()
      (with-context
        (lambda (socket)
          (lists:foreach
            (match-lambda
              (((tuple index source query))
               (let ((result
                       (evaluate socket (integer_to_binary index) source)))
                 (assert-report result #b("succeeded") 'true)
                 (let ((small (evaluate socket (integer_to_binary (+ index 1))
                                       query)))
                   (assert-report small #b("succeeded") 'false)
                   (assertEqual #b("100000") (map-get small #b("value")))))))
            (list
              (tuple 1 #b("(set saved-list (lists:duplicate 100000 1))")
                       #b("(length saved-list)"))
              (tuple 3 #b("(set saved-map (maps:from_list (lists:map "
                          "(lambda (i) (tuple i i)) (lists:seq 1 100000))))")
                       #b("(map_size saved-map)"))
              (tuple 5 #b("(set saved-binary (binary:copy #b(0) 100000))")
                       #b("(byte_size saved-binary)"))
              (tuple 7 #b("(set saved-tuple (list_to_tuple "
                          "(lists:duplicate 100000 1)))")
                       #b("(tuple_size saved-tuple)")))))))))

(defun native_error_previews_preserve_environment_test_ ()
  "Huge exceptions and parse errors preserve the previously committed env."
  (tuple 'timeout 30
    (lambda ()
      (with-context
        (lambda (socket)
          (assert-report (evaluate socket #b("1") #b("(set keep 41)"))
                         #b("succeeded") 'false)
          (assert-report
            (evaluate socket #b("2")
              #b("(progn (set keep 99) "
                 "(erlang:error (lists:duplicate 100000 1)))"))
            #b("failed") 'true)
          (let ((saved (evaluate socket #b("3") #b("keep"))))
            (assert-report saved #b("succeeded") 'false)
            (assertEqual #b("41") (map-get saved #b("value"))))
          (let ((parse (evaluate socket #b("4") #b("("))))
            (assert-report parse #b("failed") 'false))
          (assert-report (evaluate socket #b("5") #b("(/ 1 0)"))
                         #b("failed") 'false)
          (assertEqual #b("41")
            (map-get (evaluate socket #b("6") #b("keep")) #b("value"))))))))

(defun native_cancel_reports_false_test_ ()
  "Cancel an output-blocked root deterministically; fixed text reportsfalse."
  (tuple 'timeout 30
    (lambda ()
      (with-context
        (lambda (socket)
          (dispatch socket #b("1")
            #b("(progn (io:format \"PREVIEW-CANCEL\" ()) 42)"))
          (let ((gate (read-frame socket)))
            (assertEqual #b("output") (map-get gate #b("kind")))
            (assertEqual #b("PREVIEW-CANCEL") (map-get gate #b("text")))
            ;; Root is held by its actual unacknowledged synchronous write.
            (send-frame socket (map 'kind 'cancel 'operation #b("1")))
            (assert-report (until-outcome socket) #b("cancelled") 'false)))))))

(defun checked (value)
  (let* (((= (tuple text omitted) result) (cayrn-lfe-preview:render value))
         (chars (unicode:characters_to_list text)))
    (assert (is_binary text))
    (assert (=< (byte_size text) 8192))
    (assert (is_boolean omitted))
    (assert (is_list chars))
    (assertEqual text (unicode:characters_to_binary chars))
    result))

(defun utf8 (text) (unicode:characters_to_binary text))

(defun assert-report (result phase omitted)
  (assertEqual #b("outcome") (map-get result #b("kind")))
  (assertEqual phase (map-get result #b("phase")))
  (assertEqual (map #b("truncated") omitted) (map-get result #b("preview")))
  (let ((value (map-get result #b("value"))))
    (assert (=< (byte_size value) 8192))
    (assert (is_list (unicode:characters_to_list value)))))

(defun with-context (function)
  (cayrn_lfe_authority_tests:with-peer
    (lambda (peer path)
      (let* (((tuple authority grant)
              (cayrn_lfe_authority_tests:authority path #b("a")))
             ((tuple socket _pid)
              (cayrn_lfe_authority_tests:context peer path grant #b("1")
                #b("preview") #b("a"))))
        (try (funcall function socket)
          (after (gen_tcp:close socket) (gen_tcp:close authority)))))))

(defun evaluate (socket operation source)
  (dispatch socket operation source)
  (until-outcome socket))

(defun dispatch (socket operation source)
  (send-frame socket
    (map 'kind 'dispatch 'operation operation 'source source
         'generation #b("g") 'authority #b("a"))))

(defun until-outcome (socket)
  (let ((frame (read-frame socket)))
    (case (map-get frame #b("kind"))
      (#b("outcome") frame)
      (#b("output")
       (send-frame socket (map 'kind 'ack 'position
                              (map-get frame #b("position"))))
       (until-outcome socket)))))

(defun send-frame (socket frame)
  (let (('ok (gen_tcp:send socket (json:encode frame)))) 'ok))

(defun read-frame (socket)
  (let (((tuple 'ok bytes) (gen_tcp:recv socket 0 3000))) (json:decode bytes)))
