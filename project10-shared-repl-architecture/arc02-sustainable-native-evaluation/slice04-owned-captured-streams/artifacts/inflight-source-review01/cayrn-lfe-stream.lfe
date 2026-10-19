;;;; Incremental supported chardata conversion in an owned disposable worker.
(defmodule cayrn-lfe-stream
  (export (start 4)))

(defspec (start 4)
  (((pid) (reference) (term) (tuple)) (pid)))
(defun start (collector job encoding payload)
  "Create a linked paused formatter; no apply or conversion before grant."
  (spawn_link
    (lambda ()
      (receive
        ((tuple 'stream_activate sender incoming)
         (when (=:= sender collector) (=:= incoming job))
         (let ((status (format-payload collector job encoding payload)))
           (! collector (tuple 'stream_done (self) job status))))))))

(defun format-payload (collector job encoding payload)
  (case (payload-value payload)
    ((tuple 'ok chars)
     (case (convert '() encoding)
       ((tuple 'ok #b())
        (stream collector job encoding (list (tuple 'root chars))
                #b() 1 'false))
       (_ '#(error badarg))))
    (error error)))

(defun payload-value
  (((tuple 'chars chars)) (tuple 'ok chars))
  (((tuple 'mfa module function args))
   ;; This is the user-code boundary, not a catch around our state machine.
   (try (tuple 'ok (apply module function args))
     (catch ((tuple _ _ _) '#(error badarg))))))

(defun convert (prefix encoding)
  (try
    (case (unicode:characters_to_binary prefix encoding 'utf8)
      (good (when (is_binary good)) (tuple 'ok good))
      ((tuple 'incomplete good rest) (tuple 'incomplete good rest))
      ((tuple 'error good _rest) (tuple 'error good)))
    (catch ((tuple 'error 'badarg _) '#(error badarg)))))

(defun stream (collector job encoding stack carry index emitted)
  (let* (((tuple prefix remaining disposition) (gather stack 1024 '()))
         (converted (convert (list carry prefix) encoding)))
    (case converted
      ((tuple 'ok good)
       (next-prefix collector job encoding remaining #b() index emitted
                    disposition good))
      ((tuple 'incomplete good rest)
       (let (('true (=< (byte_size rest) 3)))
         (next-prefix collector job encoding remaining (binary:copy rest)
                      index emitted disposition good)))
      ((tuple 'error good) (when (is_binary good))
       (emit-prefix collector job index good)
       '#(error badarg))
      ('#(error badarg) '#(error badarg)))))

(defun next-prefix (collector job encoding stack carry index emitted
                    disposition good)
  (let* (('true (=< (byte_size good) 4100))
         (wrote (> (byte_size good) 0))
         (next-index (if wrote
                       (progn (emit collector job index good) (+ index 1))
                       index))
         (has-output (orelse emitted wrote)))
    (case disposition
      ('badarg '#(error badarg))
      ('eof
       (if (=:= carry #b())
         (progn
           (if has-output 'ok (emit collector job next-index #b()))
           'ok)
         '#(error badarg)))
      ('more (stream collector job encoding stack carry next-index
                     has-output)))))

(defun emit-prefix (collector job index good)
  (if (> (byte_size good) 0) (emit collector job index good) 'ok))

(defun emit (collector job index bytes)
  (let (('true (=< (byte_size bytes) 8192)))
    (! collector
       (tuple 'stream_chunk (self) job index (binary:copy bytes)))
    (receive
      ((tuple 'stream_continue sender incoming chunk)
       (when (=:= sender collector) (=:= incoming job) (=:= chunk index))
       'ok)
      (_message (error 'invalid_stream_credit)))))

;;; Stack roles preserve improper binary tails and reject integer roots/tails.
(defun gather
  (('() _budget prefix) (tuple (lists:reverse prefix) '() 'eof))
  ((stack 0 prefix) (tuple (lists:reverse prefix) stack 'more))
  (((cons (tuple _role '()) rest) budget prefix)
   (gather rest budget prefix))
  (((cons (tuple role (cons head tail)) rest) budget prefix)
   (when (orelse (=:= role 'root) (=:= role 'tail) (=:= role 'element)))
   (gather (cons (tuple 'element head) (cons (tuple 'tail tail) rest))
           budget prefix))
  (((cons (tuple role bytes) rest) budget prefix)
   (when (is_binary bytes)
         (orelse (=:= role 'root) (=:= role 'tail) (=:= role 'element)))
   (let* ((count (min budget (byte_size bytes)))
          ((binary (part (size count) binary) (tail binary)) bytes)
          (stack (if (=:= tail #b()) rest
                   (cons (tuple role tail) rest))))
     (gather stack (- budget count) (cons part prefix))))
  (((cons (tuple 'element codepoint) rest) budget prefix)
   (when (is_integer codepoint))
   (gather rest (- budget 1) (cons codepoint prefix)))
  ((_stack _budget prefix)
   (tuple (lists:reverse prefix) '() 'badarg)))
