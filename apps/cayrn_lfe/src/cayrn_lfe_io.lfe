;;;; Immutable operation attribution, including output from late writers.
(defmodule cayrn_lfe_io
  (export (loop 2) (start 2)))

(defspec (start 2) (((pid) (binary)) (pid)))

(defun start (owner operation)
  "Start linked capture with one immutable operation identity."
  (spawn_link (MODULE) 'loop (list owner operation)))

(defspec (loop 2) (((pid) (binary)) (no_return)))

(defun loop (owner operation)
  "Run the native I/O protocol until its owner terminates it."
  (loop owner operation 'false))

(defun loop (owner operation closed)
  (receive
    ((tuple 'seal incoming-owner) (when (=:= incoming-owner owner))
     (! owner (tuple 'sealed (self)))
     (loop owner operation 'true))
    ((tuple 'io_request from ref _) (when (=:= closed 'true))
     (! from (tuple 'io_reply ref (tuple 'error 'terminated)))
     (loop owner operation closed))
    ((tuple 'io_request from ref request)
     (case (output request)
       ((tuple 'ok text) (when (=< (byte_size text) 8192))
        (! owner (tuple 'capture from ref operation text)))
       ((tuple 'ok _)
        (! from (tuple 'io_reply ref (tuple 'error 'emsgsize))))
       ((tuple 'error reason)
        (! from (tuple 'io_reply ref (tuple 'error reason)))))
     (loop owner operation closed))
    (_ (loop owner operation closed))))

(defun output
  (((tuple 'put_chars encoding chars)) (text chars encoding))
  (((tuple 'put_chars chars)) (text chars 'unicode))
  (((tuple 'put_chars encoding module function args))
   (try (text (apply module function args) encoding)
     (catch ((tuple _ _ _) (tuple 'error 'badarg)))))
  (((tuple 'put_chars module function args))
   (output (tuple 'put_chars 'unicode module function args)))
  ((_) (tuple 'error 'enotsup)))

(defun text (chars encoding)
  (try
    (case (unicode:characters_to_binary chars encoding 'utf8)
      (bytes (when (is_binary bytes)) (tuple 'ok bytes))
      (_ (tuple 'error 'badarg)))
    (catch ((tuple _ _ _) (tuple 'error 'badarg)))))
