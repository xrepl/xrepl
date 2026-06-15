(defmodule xrepl-session
  "Session management for xrepl.

  Each session is a gen_server that delegates evaluation to a per-session
  active shell (default xrepl-shell-lfe). The shell owns parse, eval, and
  env serialisation; the session owns process isolation, persistence, and
  OTP lifecycle."
  (behaviour gen_server)
  ;; API
  (export
   (start_link 1)
   (stop 1)
   (eval 2)
   (get-env 1)
   (save-state 1)
   (describe 1)
   (process-name 1))
  ;; Callbacks
  (export
   (init 1)
   (handle_call 3)
   (handle_cast 2)
   (handle_info 2)
   (terminate 2)
   (code_change 3)))

;;; ----------------
;;; State record
;;; ----------------

(defrecord session-state
  id            ;; Session UUID
  shell         ;; Shell module atom (default 'xrepl-shell-lfe)
  shell-state   ;; Opaque shell state (threaded through evaluator-loop)
  evaluator     ;; PID of evaluator process
  eval-pending  ;; Reply-to for pending evaluation
  last-save     ;; Timestamp of last state save
  save-interval) ;; How often to save (ms)

;;; ----------------
;;; API functions
;;; ----------------

(defun start_link (session-id)
  "Start a session gen_server.

  Args:
    session-id: Unique session identifier

  Returns:
    #(ok pid)"
  (gen_server:start_link (tuple 'local (process-name session-id))
                          (MODULE)
                          session-id
                          '()))

(defun stop (session-id)
  "Stop a session.

  Args:
    session-id: Session identifier

  Returns:
    ok"
  (gen_server:call (process-name session-id) 'stop))

(defun eval (session-id input)
  "Send raw input to the session for evaluation.

  Input may be a char-list string (e.g. \"(+ 1 2)\") or an already-parsed
  LFE form (e.g. '(set x 42) or the atom 'x). Parsing is delegated to
  the active shell's eval/3, which calls prepare-form internally.

  Args:
    session-id: Session identifier
    input: char-list string or LFE form

  Returns:
    #(ok value) on success
    #(error reason) on failure"
  (gen_server:call (process-name session-id) (tuple 'eval input) 5000))

(defun get-env (session-id)
  "Get the current LFE environment from the session's active shell.

  NOTE: LFE-shell-specific. Returns the lfe_env from xrepl-shell-lfe's
  shell state. Not meaningful for shells that do not use lfe_env.

  Args:
    session-id: Session identifier

  Returns:
    The current LFE environment (lfe_env opaque term)"
  (gen_server:call (process-name session-id) 'get-env))

(defun save-state (session-id)
  "Manually save session state.

  Args:
    session-id: Session identifier

  Returns:
    ok | #(error reason)"
  (gen_server:call (process-name session-id) 'save-state))

(defun describe (session-id)
  "Return the active shell's describe/1 capability map.

  Args:
    session-id: Session identifier

  Returns:
    map() from the active shell's describe/1"
  (gen_server:call (process-name session-id) 'describe))

(defun process-name (session-id)
  "Generate process name for session.

  Args:
    session-id: Session identifier string

  Returns:
    Atom process name"
  (binary_to_atom
    (list_to_binary (++ "xrepl-session-" session-id))
    'utf8))

;;; ----------------
;;; gen_server callbacks
;;; ----------------

(defun init (session-id)
  "Initialise a session. Reads active shell from stored metadata (set by
  xrepl-session-manager:create before the process starts). Defaults to
  'xrepl-shell-lfe. Delegates env lifecycle to the chosen shell."
  (process_flag 'trap_exit 'true)

  ;; Initialise session-specific history
  (let ((history-opts (map 'history_enabled
                               (application:get_env 'xrepl 'history_enabled 'true)
                           'history_file
                               (application:get_env 'xrepl 'history_file
                                                    (xrepl-history:default-file)))))
    (xrepl-history:init session-id history-opts))

  ;; Read full session data once: transport, snapshot, and active shell
  (let* ((transport-type (get-transport-type session-id))
         (remote? (is-remote-transport? transport-type))
         (session-data (case (xrepl-store:get-session session-id)
                         (`#(ok ,sd) sd)
                         (`#(error ,_) (map))))
         (snapshot (maps:get 'env-snapshot session-data 'undefined))
         (metadata (maps:get 'metadata session-data (map)))
         ;; Shell chosen by create/1 opts; default is xrepl-shell-lfe
         (shell (maps:get 'shell metadata 'xrepl-shell-lfe)))
    (case (call shell 'init (map 'remote? remote?
                                 'session-id session-id
                                 'snapshot snapshot))
      (`#(ok ,ss)
       (let* ((evaluator (start-evaluator session-id shell ss))
              (now (erlang:monotonic_time 'millisecond)))
         (tuple 'ok (make-session-state id session-id
                                        shell shell
                                        shell-state ss
                                        evaluator evaluator
                                        eval-pending 'undefined
                                        last-save now
                                        save-interval 60000))))
      (`#(error ,reason)
       (tuple 'stop (tuple 'shell-init-failed reason))))))

(defun handle_call
  "Handle synchronous calls."
  ;; Evaluate raw input (string or form) — parsing delegated to the shell
  ((`#(eval ,input) from state)
   (! (session-state-evaluator state) (tuple 'eval input (self)))
   (tuple 'noreply (set-session-state-eval-pending state from)))

  ;; Get environment — LFE-shell-specific; returns 'undefined for other shells
  (('get-env _from state)
   (let* ((shell (session-state-shell state))
          (env (if (== shell 'xrepl-shell-lfe)
                 (xrepl-shell-lfe:env-of (session-state-shell-state state))
                 'undefined)))
     (tuple 'reply env state)))

  ;; Return the active shell's capability map
  (('describe _from state)
   (let* ((shell (session-state-shell state))
          (ss (session-state-shell-state state))
          (desc (call shell 'describe ss)))
     (tuple 'reply desc state)))

  ;; Save state manually
  (('save-state _from state)
   (case (save-state-to-store (session-state-id state) state)
     ('ok
      (tuple 'reply 'ok (set-session-state-last-save
                          state
                          (erlang:monotonic_time 'millisecond))))
     (`#(error ,reason)
      (tuple 'reply (tuple 'error reason) state))))

  ;; Stop session
  (('stop _from state)
   (let ((eval-pid (session-state-evaluator state)))
     (if (is_process_alive eval-pid)
       (exit eval-pid 'shutdown)))
   (tuple 'stop 'normal 'ok state))

  ;; Unknown call
  ((message _from state)
   (tuple 'reply (tuple 'error 'unknown-command) state)))

(defun handle_cast (_msg state)
  "Handle asynchronous casts."
  (tuple 'noreply state))

(defun handle_info
  "Handle info messages."
  ;; Successful eval result — thread new shell-state back into session
  ((`#(eval-result ,value ,ss2) state)
   (case (session-state-eval-pending state)
     ('undefined
      (tuple 'noreply state))
     (from
      (gen_server:reply from (tuple 'ok value))
      (let* ((updated-state (set-session-state-shell-state
                              (set-session-state-eval-pending state 'undefined)
                              ss2))
             (saved-state (maybe-save-state updated-state)))
        (xrepl-store:touch-session (session-state-id saved-state))
        (tuple 'noreply saved-state)))))

  ;; Shell switched mid-turn — reply with Response, update active shell
  ((`#(eval-result-switch ,response ,mod ,new-ss) state)
   (case (session-state-eval-pending state)
     ('undefined
      (tuple 'noreply state))
     (from
      (gen_server:reply from (tuple 'ok response))
      (let* ((updated-state
               (set-session-state-shell-state
                 (set-session-state-shell
                   (set-session-state-eval-pending state 'undefined)
                   mod)
                 new-ss))
             (saved-state (maybe-save-state updated-state)))
        (xrepl-store:touch-session (session-state-id saved-state))
        (tuple 'noreply saved-state)))))

  ;; Error from shell eval — map to a message string and reply
  ((`#(eval-error ,error-info) state)
   (case (session-state-eval-pending state)
     ('undefined
      (tuple 'noreply state))
     (from
      (let ((error-msg (eval-error-to-msg error-info)))
        (gen_server:reply from (tuple 'error error-msg))
        (tuple 'noreply (set-session-state-eval-pending state 'undefined))))))

  ;; Evaluator exited normally
  ((`#(EXIT ,eval-pid normal) state)
   (case (== eval-pid (session-state-evaluator state))
     ('true (tuple 'noreply state))
     ('false (tuple 'noreply state))))

  ;; Evaluator crashed — restart with current shell + shell-state
  ((`#(EXIT ,eval-pid ,reason) state)
   (case (== eval-pid (session-state-evaluator state))
     ('true
      (io:format "Evaluator crashed (~p), restarting...~n" (list reason))
      (let* ((session-id (session-state-id state))
             (shell (session-state-shell state))
             (ss (session-state-shell-state state))
             (new-evaluator (start-evaluator session-id shell ss)))
        (case (session-state-eval-pending state)
          ('undefined 'ok)
          (from (gen_server:reply from (tuple 'error 'evaluator-crashed))))
        (tuple 'noreply (set-session-state-evaluator
                         (set-session-state-eval-pending state 'undefined)
                         new-evaluator))))
     ('false
      (tuple 'noreply state))))

  ;; Other messages
  ((_msg state)
   (tuple 'noreply state)))

(defun terminate (_reason state)
  "Cleanup on termination."
  (let ((eval-pid (session-state-evaluator state)))
    (if (is_process_alive eval-pid)
      (exit eval-pid 'shutdown)))
  'ok)

(defun code_change (_old-version state _extra)
  "Handle code changes."
  (tuple 'ok state))


;;; ----------------
;;; Evaluator process
;;; ----------------

(defun start-evaluator (session-id shell shell-state)
  "Start an evaluator process for the given shell.

  The evaluator process registers its session via set-current/1 so that
  any eval'd code (e.g. xs:run) can call get-current and find its session.
  This is per-process dict — it does not affect the dispatcher/client.

  Args:
    session-id: Session identifier
    shell: Shell module atom
    shell-state: Initial shell state

  Returns:
    Evaluator PID"
  (spawn_link (lambda ()
                ;; Register this session in the evaluator process's dict
                ;; so eval'd code can call xrepl-session-manager:get-current
                (xrepl-session-manager:set-current session-id)
                (evaluator-loop session-id shell shell-state))))

(defun evaluator-loop (session-id shell shell-state)
  "Main evaluator loop — delegates to the active shell's eval/3.

  Receives:
    #(eval Input ReplyTo)

  Sends back:
    #(eval-result Value ShellState2)   - on success
    #(eval-error ErrorInfo)            - on shell error or exception"
  (receive
    (`#(eval ,input ,reply-to)
     ;; Record the input in session history
     (xrepl-history:add session-id (format-input input))
     ;; Delegate evaluation to the shell
     (let ((ctx (map 'session-id session-id)))
       (try
         (case (call shell 'eval input shell-state ctx)
           (`#(ok ,value ,ss2)
            (! reply-to (tuple 'eval-result value ss2))
            (evaluator-loop session-id shell ss2))
           (`#(error ,error-info)
            (! reply-to (tuple 'eval-error error-info))
            (evaluator-loop session-id shell shell-state))
           (`#(switch-shell ,mod ,opts ,response)
            (case (call mod 'init opts)
              (`#(ok ,new-ss)
               (! reply-to (tuple 'eval-result-switch response mod new-ss))
               (evaluator-loop session-id mod new-ss))
              (`#(error ,r)
               (! reply-to (tuple 'eval-error (tuple 'switch-init-failed r)))
               (evaluator-loop session-id shell shell-state)))))
         (catch
           ((tuple class reason stack)
            (! reply-to
               (tuple 'eval-error
                      (tuple 'exception class reason stack)))
            (evaluator-loop session-id shell shell-state))))))))

;;; ----------------
;;; Helper functions
;;; ----------------

(defun format-input (input)
  "Render input as a history string.
  Char-list strings (list of char codes) are used as-is; forms are printed.
  Uses andalso for short-circuit: (car input) is only called when is_list."
  (cond
    ((== input '()) "")
    ((andalso (is_list input) (is_integer (car input))) input)
    ('true (format-form input))))

(defun format-form (form)
  "Convert form to string for history.

  Args:
    form: LFE form

  Returns:
    String representation"
  (lfe_io:print1 form))

(defun eval-error-to-msg (error-info)
  "Map an xrepl-shell error-info term to a flat error message string."
  (case error-info
    ;; Shell's eval-form returned {error, Str} — already formatted
    (`#(eval ,str) str)
    ;; Shell's prepare-form returned {error, Reason}
    (`#(parse ,r)
     (lists:flatten (io_lib:format "parse error: ~p" (list r))))
    ;; Exception escaped shell eval/3 (safety net)
    (`#(exception ,class ,reason ,stack)
     (xrepl-io:format-error class reason stack))
    ;; Shell switch init failed
    (`#(switch-init-failed ,r)
     (lists:flatten (io_lib:format "shell switch failed: ~p" (list r))))
    ;; Unknown error shape
    (_
     (lists:flatten (io_lib:format "error: ~p" (list error-info))))))

;;; ----------------
;;; State persistence helpers
;;; ----------------

(defun save-state-to-store (session-id state)
  "Save session state to xrepl-store.

  Calls the shell's snapshot/1 to serialise the env, stored under
  the literal key 'env-snapshot (preserves existing storage contract)."
  (try
    (let* ((shell (session-state-shell state))
           (ss (session-state-shell-state state))
           (env-snapshot (call shell 'snapshot ss)))
      (xrepl-store:update-session
        session-id
        (lambda (session-data)
          (maps:put 'env-snapshot env-snapshot session-data)))
      'ok)
    (catch
      ((tuple _ reason _)
       (logger:warning "Failed to save session state: ~p" (list reason))
       (tuple 'error reason)))))

(defun maybe-save-state (state)
  "Save state if enough time has passed since last save."
  (let ((now (erlang:monotonic_time 'millisecond))
        (last-save (session-state-last-save state))
        (interval (session-state-save-interval state)))
    (if (> (- now last-save) interval)
      (progn
        (save-state-to-store (session-state-id state) state)
        (set-session-state-last-save state now))
      state)))

;;; ----------------
;;; Transport detection helpers
;;; ----------------

(defun get-transport-type (session-id)
  "Get transport type from session metadata.

  Args:
    session-id: Session identifier

  Returns:
    Transport type atom ('stdio, 'tcp, 'unix) or 'stdio (default)"
  (case (xrepl-store:get-session session-id)
    (`#(ok ,session-data)
     (let ((metadata (maps:get 'metadata session-data (map))))
       (maps:get 'transport-type metadata 'stdio)))
    (`#(error ,_)
     'stdio)))

(defun is-remote-transport? (transport-type)
  "Determine if transport type is remote (not stdio).

  Args:
    transport-type: Transport type atom

  Returns:
    true if remote (tcp/unix), false if local (stdio)"
  (case transport-type
    ('stdio 'false)
    (_ 'true)))
