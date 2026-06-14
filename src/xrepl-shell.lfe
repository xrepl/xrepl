(defmodule xrepl-shell
  "Behaviour for xrepl shells: pluggable read/eval/print front-ends.

  A shell interprets a session's input line and produces a result value plus
  its own next state. The default shell (xrepl-shell-lfe) evaluates LFE; other
  shells may implement entirely different languages or command sets over the
  same xrepl protocol. Shell state is per-session and opaque to the session."
  (export (behaviour_info 1)))

(defun behaviour_info
  "Define the xrepl-shell behaviour callbacks."
  (('callbacks)
   '(;; (init Opts) -> {ok, ShellState} | {error, Reason}
     ;;   Opts is a map. Build the shell's initial per-session state.
     #(init 1)

     ;; (eval Input ShellState Ctx) ->
     ;;     {ok, Value, ShellState2}            ; normal turn
     ;;   | {switch-shell, Mod, Opts, Value}    ; hand off to another shell
     ;;   | {error, ErrorInfo}                  ; diegetic/normal error
     ;;   Input is the raw input (string, or already-parsed term).
     ;;   Ctx is a map (session-id, transport-type, ...).
     ;;   Value flows back as the eval result the dispatcher interprets
     ;;   (a normal term, or #(formatted Text), or a switch tuple).
     #(eval 3)

     ;; (describe ShellState) -> map()
     ;;   Capability map for this shell, merged into the `describe` op.
     #(describe 1)

     ;; (snapshot ShellState) -> map()
     ;;   Return a serialisable snapshot of the shell's state, stored
     ;;   under the key 'env-snapshot in xrepl-store. Must round-trip
     ;;   through init/1 (via the 'snapshot key in Opts).
     #(snapshot 1)))
  ((_) 'undefined))
