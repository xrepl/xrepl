(defmodule xrepl-shell-lfe
  "Default LFE shell implementing the xrepl-shell behaviour.

  Reproduces the current parse -> eval -> thread-env path that lives in
  xrepl-session and xrepl-eval, making those semantics reachable through
  the shell abstraction without touching the live session path. This is
  the contract that slice3 will rely on when rewiring the session."
  (behaviour xrepl-shell)
  (export
   (init 1)
   (eval 3)
   (describe 1)
   (prompt 1)))

;;; ----------------
;;; State record
;;; ----------------

(defrecord lfe-shell-state
  env          ;; the LFE environment (lfe_env)
  session-id)  ;; session id string, or 'undefined

;;; ----------------
;;; Behaviour callbacks
;;; ----------------

(defun init (opts)
  "Initialise the LFE shell state from Opts.

  Args:
    opts: map with optional keys:
      env        - LFE environment to use (default: fresh base env)
      session-id - session identifier string (default: 'undefined)

  Returns:
    #(ok ShellState) | #(error Reason)"
  (let* ((env (maps:get 'env opts (xrepl-env:new "" '() 'false)))
         (id (maps:get 'session-id opts 'undefined)))
    (tuple 'ok (make-lfe-shell-state env env
                                     session-id id))))

(defun eval (input shell-state ctx)
  "Evaluate Input in the shell's current LFE environment.

  Reproduces the semantics currently split across xrepl-session:prepare-form/1
  (parse), xrepl-eval:eval-form/2 (eval), and xrepl-env:update-shell-vars/3
  (thread history vars).

  Args:
    input:       raw input — char list string OR already-parsed LFE form
    shell-state: lfe-shell-state record
    ctx:         context map (session-id, transport-type, etc.) — not used
                 by this shell but forwarded for protocol compliance

  Returns:
    #(ok Value ShellState2)             - normal turn
    #(error #(parse Reason))            - input could not be parsed
    #(error #(eval Reason))             - xrepl-eval returned an error
    #(error #(exception Class Rsn Stk)) - unexpected exception escaped"
  (let ((env (lfe-shell-state-env shell-state)))
    (case (prepare-form input)
      (`#(ok ,form)
       (try
         (case (xrepl-eval:eval-form form env)
           (`#(ok ,value ,new-env)
            (let ((final-env (xrepl-env:update-shell-vars
                               form value new-env)))
              (tuple 'ok value
                     (set-lfe-shell-state-env shell-state final-env))))
           (`#(error ,reason)
            (tuple 'error (tuple 'eval reason))))
         (catch
           ((tuple class reason stack)
            (tuple 'error (tuple 'exception class reason stack))))))
      (`#(error ,reason)
       (tuple 'error (tuple 'parse reason))))))

(defun describe (shell-state)
  "Return a capability map for the LFE shell.

  Merged into the xrepl describe op response (slice4).

  Args:
    shell-state: lfe-shell-state record (not used yet; reserved for
                 future per-session capability flags)

  Returns:
    map with keys: name, kind, prompt"
  (map 'name #"lfe"
       'kind #"language"
       'prompt #"lfe> "))

(defun prompt (shell-state)
  "Return the prompt binary for the LFE shell.

  Args:
    shell-state: lfe-shell-state record (reserved for per-session overrides)

  Returns:
    binary prompt string"
  #"lfe> ")

;;; ----------------
;;; Private helpers
;;; ----------------

(defun prepare-form (input)
  "Parse Input into an LFE form, or return it as-is if already a form.

  Mirrors xrepl-session:prepare-form/1 (session.lfe ~L262-294).

  Args:
    input: char list string, empty list, non-string list, or any term

  Returns:
    #(ok Form) | #(error Reason)"
  (if (is_list input)
    (case input
      ;; Empty list is a valid form
      ('()
       (tuple 'ok '()))
      ((cons first _)
       (if (is_integer first)
         ;; Char list (string) — parse it
         ;; lfe_io:read_string returns {ok,[forms]}, eof, or {error,Info}
         ;; where Info is {Line,lfe_parse,Desc} (a 2-tuple at the top level)
         (case (lfe_io:read_string input)
           (`#(ok ,forms)
            (case forms
              ((cons form _) (tuple 'ok form))
              ('() (tuple 'error "empty input"))))
           (`#(error ,_)
            (tuple 'error "parse error"))
           ('eof
            (tuple 'error "unexpected eof")))
         ;; Non-string list — already a form
         (tuple 'ok input))))
    ;; Atom or other non-list term — use as-is
    (tuple 'ok input)))
