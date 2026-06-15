(defmodule xs
  "Entry point for the xs story shell.

  Calling (xs:run) from the LFE REPL loads priv/support.xsf and
  switches the session into xs-shell. If support.xsf is absent (the
  bundle has not been packed yet), it returns a graceful formatted
  message instead.

  The return value is the generic xrepl-switch-shell sentinel that
  xrepl-shell-lfe:eval/3 recognises and converts into a #(switch-shell …)
  response, completing the breadcrumb seeded in Arc6 slice5."
  (export
   (run 0)
   (run 1)))

(defun run ()
  "Switch to the story shell using the default trigger name.

  Returns:
    #(xrepl-switch-shell xs-shell #m(state S) #(formatted Opening))
  or
    #(formatted #\"There is nothing here yet.\") if support.xsf is absent"
  (run 'support))

(defun run (_trigger)
  "Load priv/support.xsf and switch to xs-shell, or degrade gracefully.

  _trigger is the word the player typed (e.g. 'pwd, 'passwd, …) — passed
  from the did-you-mean breadcrumb in Arc6 slice5; ignored here.

  Returns:
    #(xrepl-switch-shell xs-shell #m(state S) #(formatted Opening))
  or
    #(formatted #\"There is nothing here yet.\") when support.xsf is absent"
  (let ((xsf-path (filename:join
                    (list (code:priv_dir 'xrepl)
                          "support.xsf"))))
    (case (xs-shell:start xsf-path)
      (`#(ok ,state ,opening)
       (tuple 'xrepl-switch-shell 'xs-shell
              (map 'state state)
              (tuple 'formatted opening)))
      (`#(error ,_)
       (tuple 'formatted #"There is nothing here yet.")))))
