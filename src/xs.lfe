(defmodule xs
  "Entry point for the xs story shell.

  Calling (xs:run) from the LFE REPL loads priv/support.xsf and switches
  the session into xs-shell. Resumes from the last save point when one
  exists in session metadata ('xs-save key); starts fresh otherwise.
  Graceful when support.xsf is absent (bundle not yet packed).

  The return value is the generic xrepl-switch-shell sentinel that
  xrepl-shell-lfe:eval/3 recognises and converts into a #(switch-shell …)
  response, completing the breadcrumb seeded in Arc6 slice5."
  (export
   (run 0)
   (run 1)))

(defun run ()
  "Switch to the story shell (resume if save exists, else fresh start).

  Returns:
    #(xrepl-switch-shell xs-shell #m(state S) #(formatted Text))
  or
    #(formatted #\"There is nothing here yet.\") if support.xsf is absent"
  (run 'support))

(defun run (_trigger)
  "Load priv/support.xsf and switch to xs-shell, resuming or starting fresh.

  _trigger is the word the player typed (from the did-you-mean breadcrumb
  in Arc6 slice5); ignored here.

  Resume path: reads 'xs-save from the current session's metadata via
  xrepl-session-manager:get-current + xrepl-store:get-metadata, then calls
  xs-shell:resume/2 to rebuild state at the saved node + render that room.

  Returns:
    #(xrepl-switch-shell xs-shell #m(state S) #(formatted Text))
  or
    #(formatted #\"There is nothing here yet.\") when support.xsf is absent"
  (let ((xsf-path (filename:join
                    (list (code:priv_dir 'xrepl) "support.xsf")))
        (saved    (read-saved-world))
        (sid      (xrepl-session-manager:get-current)))
    (if (=/= saved 'none)
      ;; Try resume path (requires loading the bundle)
      (case (xs-bundle:load-file xsf-path)
        (`#(ok ,bundle)
         (case (xs-shell:resume saved bundle)
           (`#(ok ,state ,room)
            (tuple 'xrepl-switch-shell 'xs-shell
                   (map 'state state)
                   (tuple 'formatted room)))
           (`#(error stale-save)
            ;; Stale node — clear the bad save and fall through to fresh
            (clear-save sid)
            (fresh-start xsf-path))))
        (`#(error ,_)
         (tuple 'formatted #"There is nothing here yet.")))
      ;; No save — fresh start
      (fresh-start xsf-path))))

;;; ----------------
;;; Private helpers
;;; ----------------

(defun read-saved-world ()
  "Read 'xs-save from the current session's metadata.
  Returns the World map if present and non-none, else 'none."
  (let ((sid (xrepl-session-manager:get-current)))
    (if (orelse (== sid 'undefined) (== sid 'no-session))
      'none
      (case (xrepl-store:get-metadata sid)
        (`#(ok ,meta)
         (let ((saved (maps:get 'xs-save meta 'none)))
           (if (== saved 'none) 'none saved)))
        (_ 'none)))))

(defun fresh-start (xsf-path)
  "Load the bundle fresh and switch into xs-shell."
  (case (xs-shell:start xsf-path)
    (`#(ok ,state ,opening)
     (tuple 'xrepl-switch-shell 'xs-shell
            (map 'state state)
            (tuple 'formatted opening)))
    (`#(error ,_)
     (tuple 'formatted #"There is nothing here yet."))))

(defun clear-save (sid)
  "Set 'xs-save to 'none in session metadata (clear stale save).
  No-op when sid is undefined or no-session."
  (if (orelse (== sid 'undefined) (== sid 'no-session))
    'ok
    (xrepl-store:set-metadata sid (map 'xs-save 'none))))
