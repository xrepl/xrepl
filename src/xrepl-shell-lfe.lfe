(defmodule xrepl-shell-lfe
  "Default LFE shell implementing the xrepl-shell behaviour.

  Owns the full env lifecycle: build (via xrepl-env:new), restore from
  snapshot, inject $session-id, eval (via xrepl-eval:eval-form), thread
  history vars (via xrepl-env:update-shell-vars), and serialise back to
  a snapshot. xrepl-session delegates to this module for all evaluation."
  (behaviour xrepl-shell)
  (export
   (init 1)
   (eval 3)
   (describe 1)
   (prompt 1)
   (snapshot 1)
   (env-of 1)))

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
      env        - pre-built LFE environment (for tests; skips new/restore)
      remote?    - bool, build a remote-mode env if true (default 'false)
      session-id - session identifier string (default: 'undefined)
      snapshot   - stored snapshot map | 'undefined (default: 'undefined)

  Returns:
    #(ok ShellState) | #(error Reason)"
  (let* ((id (maps:get 'session-id opts 'undefined))
         (remote? (maps:get 'remote? opts 'false))
         (snap (maps:get 'snapshot opts 'undefined))
         (base-env (maps:get 'env opts (xrepl-env:new "" '() remote?)))
         (restored-env (if (=/= snap 'undefined)
                         (restore-from-snapshot snap base-env)
                         base-env))
         (final-env (lfe_env:add_vbinding '$session-id id restored-env)))
    (tuple 'ok (make-lfe-shell-state env final-env
                                     session-id id))))

(defun eval (input shell-state ctx)
  "Evaluate Input in the shell's current LFE environment.

  Reproduces the semantics previously split across xrepl-session:prepare-form/1
  (parse), xrepl-eval:eval-form/2 (eval), and xrepl-env:update-shell-vars/3
  (thread history vars).

  Includes a did-you-mean hook: if the parsed form is a call to an unbound
  symbol in the suggestion table (e.g. pwd, passwd, password), a hint is
  returned without evaluating and without changing shell state.

  Args:
    input:       raw input — char list string OR already-parsed LFE form
    shell-state: lfe-shell-state record
    ctx:         context map (session-id, transport-type, etc.)

  Returns:
    #(ok Value ShellState2)             - normal turn
    #(ok #(formatted Text) ShellState)  - did-you-mean hint (state unchanged)
    #(error #(parse Reason))            - input could not be parsed
    #(error #(eval Reason))             - xrepl-eval returned an error
    #(error #(exception Class Rsn Stk)) - unexpected exception escaped"
  (let ((env (lfe-shell-state-env shell-state)))
    (case (prepare-form input)
      (`#(ok ,form)
       ;; Did-you-mean hook: intercept before calling eval-form
       (case (check-suggestion form env)
         (`#(suggest ,text)
          ;; Return hint; env and shell state are unchanged
          (tuple 'ok (tuple 'formatted text) shell-state))
         ('no-match
          ;; Normal eval path
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
               (tuple 'error (tuple 'exception class reason stack))))))))
      (`#(error ,reason)
       (tuple 'error (tuple 'parse reason))))))

(defun describe (shell-state)
  "Return a capability map for the LFE shell.

  Merged into the xrepl describe op response (slice4).

  Args:
    shell-state: lfe-shell-state record (reserved for per-session flags)

  Returns:
    map with atom keys: name, kind, prompt"
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

(defun snapshot (shell-state)
  "Serialise the shell's env to a storable snapshot map.

  Returns the same shape stored under 'env-snapshot in xrepl-store, so
  the session's save/restore path stays unchanged across the rewire.

  Uses lfe_env:get_vars/1 (the correct exported API) to extract variable
  bindings. xrepl-env:get-bindings calls lfe_env:get_vbindings which does
  not exist in LFE 2.2 — lfe_env:get_vars is the correct replacement.

  Args:
    shell-state: lfe-shell-state record

  Returns:
    #m(bindings [...]) with only serialisable name/value pairs"
  (let ((env (lfe-shell-state-env shell-state)))
    (try
      (let ((bindings (maps:to_list (lfe_env:get_vars env))))
        (map 'bindings (filter-bindings bindings)))
      (catch
        ((tuple _ _ _)
         (map 'bindings '()))))))

(defun env-of (shell-state)
  "Return the LFE environment from the shell state.

  Used by xrepl-session:handle_call 'get-env. LFE-shell-specific; other
  shell implementations are not required to expose an lfe_env.

  Args:
    shell-state: lfe-shell-state record

  Returns:
    the live LFE environment (lfe_env opaque term)"
  (lfe-shell-state-env shell-state))

;;; ----------------
;;; Private helpers
;;; ----------------

(defun prepare-form (input)
  "Parse Input into an LFE form, or return it as-is if already a form.

  Corrects the latent bug in xrepl-session:prepare-form/1 (~L285):
  lfe_io:read_string/1 returns {error, Info} (2-tuple), not {error,_,_}.

  Args:
    input: char list string, empty list, non-string list, or any term

  Returns:
    #(ok Form) | #(error Reason)"
  (if (is_list input)
    (case input
      ('() (tuple 'ok '()))
      ((cons first _)
       (if (is_integer first)
         (case (lfe_io:read_string input)
           (`#(ok ,forms)
            (case forms
              ((cons form _) (tuple 'ok form))
              ('() (tuple 'error "empty input"))))
           (`#(error ,_)
            (tuple 'error "parse error"))
           ('eof
            (tuple 'error "unexpected eof")))
         (tuple 'ok input))))
    (tuple 'ok input)))

(defun restore-from-snapshot (snapshot env)
  "Restore serialisable bindings from a snapshot map into env.

  Mirrors xrepl-session:restore-env-from-snapshot/2 (~L434)."
  (let ((bindings (maps:get 'bindings snapshot '())))
    (lists:foldl
      (lambda (binding e)
        (case binding
          (`#(,name ,value)
           (xrepl-env:add-binding name value e))))
      env
      bindings)))

(defun filter-bindings (bindings)
  "Keep only serialisable bindings from a list of #(name value) pairs."
  (lists:filtermap
    (lambda (binding)
      (case binding
        (`#(,_name ,value)
         (if (serializable? value)
           (tuple 'true binding)
           'false))))
    bindings))

(defun serializable? (value)
  "Return true if value can be stored in an env-snapshot."
  (cond
    ((is_atom value) 'true)
    ((is_number value) 'true)
    ((is_binary value) 'true)
    ((is_list value) (lists:all (fun serializable? 1) value))
    ((is_tuple value)
     (lists:all (fun serializable? 1) (tuple_to_list value)))
    ((is_map value) 'true)
    ('true 'false)))

;;; ----------------
;;; Did-you-mean hook
;;; ----------------

(defun suggestion-table ()
  "Atoms whose unbound calls return an xs:run suggestion instead of an error.

  Never include xs:run itself. Extend by adding atoms here; the hook
  substitutes the actual symbol name into the hint text automatically."
  '(pwd passwd password))

(defun check-suggestion (form env)
  "Check whether form is an unbound call to a table symbol.

  Returns #(suggest Text) if a hint should be shown, 'no-match otherwise.
  Guards against hijacking user-defined functions: the hint only fires when
  lfe_env:is_fbound/3 (verified exported from lfe_env.erl) returns false.

  Conditions that must ALL hold:
    1. form is a list whose head is an atom (a function-call shape)
    2. that atom is in suggestion-table/0
    3. the atom is NOT bound in env at the called arity"
  (case form
    ((cons sym args)
     (when (is_atom sym))
     (if (andalso (lists:member sym (suggestion-table))
                  (not (lfe_env:is_fbound sym (length args) env)))
       (tuple 'suggest (suggest-text sym))
       'no-match))
    (_ 'no-match)))

(defun suggest-text (sym)
  "Build the did-you-mean hint string for the given symbol."
  (++ "Did you mean (xs:run '" (atom_to_list sym) ")?"))
