(defmodule xrepl-shell-echo
  "Throwaway toy echo shell for testing shell switching.

  Echoes input back with an 'echo: ' prefix. Responds to 'quit' or 'exit'
  by switching back to xrepl-shell-lfe. Content-agnostic; no story words."
  (behaviour xrepl-shell)
  (export
   (init 1)
   (eval 3)
   (describe 1)
   (snapshot 1)
   (prompt 1)))

;;; ----------------
;;; Behaviour callbacks
;;; ----------------

(defun init (_opts)
  "Initialise the echo shell. State is trivial (empty map).

  Returns:
    #(ok #m())"
  (tuple 'ok (map)))

(defun eval (input state _ctx)
  "Echo Input back. 'quit'/'exit' triggers a switch to xrepl-shell-lfe.

  Args:
    input:  raw input — char list string or already-parsed LFE form
    state:  echo shell state (empty map, ignored)
    _ctx:   session context (ignored)

  Returns:
    #(ok #(formatted Text) State)           - normal echo turn
    #(switch-shell xrepl-shell-lfe #m() R)  - on 'quit' or 'exit'"
  (let ((text (input-to-string input)))
    (if (orelse (== text "quit") (== text "exit"))
      (tuple 'switch-shell 'xrepl-shell-lfe (map)
             (tuple 'formatted #"Leaving echo shell."))
      (tuple 'ok (tuple 'formatted (++ "echo: " text)) state))))

(defun describe (_state)
  "Return the echo shell capability map.

  Returns:
    map with atom keys: name, kind, prompt"
  (map 'name #"echo"
       'kind #"toy"
       'prompt #"echo> "))

(defun snapshot (_state)
  "Return an empty snapshot (echo shell has no persistent state).

  Returns:
    #m()"
  (map))

(defun prompt (_state)
  "Return the echo shell prompt binary.

  Returns:
    binary prompt string"
  #"echo> ")

;;; ----------------
;;; Private helpers
;;; ----------------

(defun input-to-string (input)
  "Convert any input type to a char-list string for echoing.

  Char lists are used as-is; binaries are decoded; atoms and other
  forms are printed via lfe_io:print1."
  (cond
    ((is_binary input) (binary_to_list input))
    ((== input '()) "")
    ((andalso (is_list input) (is_integer (car input))) input)
    ((is_atom input) (atom_to_list input))
    ('true (lists:flatten (lfe_io:print1 input)))))
