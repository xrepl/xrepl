(defmodule xrepl-prompt-tests
  "Unit and integration tests for xrepl:shell-label/1 and shell-name->label/1.

  Amendment: xs-shell cannot be instantiated via
  (xrepl-session-manager:create #m(shell xs-shell)) because xs-shell:init/1
  requires a pre-built state in opts (xs-shell is entered only via xs:run /
  the shell-switch mechanism). The xs label path is therefore covered by the
  pure shell-name->label/1 tests; shell-label/1 is tested with a live LFE
  session (→ xrepl) and a dead session-id (→ xrepl via try/catch)."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

(defun setup ()
  (application:ensure_all_started 'xrepl)
  'ok)

(defun teardown ()
  (lists:foreach
    (lambda (sid)
      (try (xrepl-session-manager:destroy sid)
           (catch ((tuple _ _ _) 'ok))))
    (xrepl-session-manager:list))
  (xrepl-session-manager:clear-current)
  'ok)

;;; ----------------------------------------------------------------
;;; shell-name->label/1 — pure, no session needed
;;; ----------------------------------------------------------------

(deftest shell-name->label-xs-returns-xs
  "shell-name->label #\"xs\" (xs-shell describe name) returns \"xs\"."
  (is-equal "xs" (xrepl:shell-name->label #"xs")))

(deftest shell-name->label-lfe-returns-xrepl
  "shell-name->label #\"lfe\" (default LFE shell name) returns \"xrepl\"."
  (is-equal "xrepl" (xrepl:shell-name->label #"lfe")))

(deftest shell-name->label-echo-returns-xrepl
  "shell-name->label #\"echo\" (echo shell name) returns \"xrepl\"."
  (is-equal "xrepl" (xrepl:shell-name->label #"echo")))

;;; ----------------------------------------------------------------
;;; shell-label/1 — integration (live session)
;;; ----------------------------------------------------------------

(deftest shell-label-default-session-returns-xrepl
  "A default LFE session's shell-label is \"xrepl\"."
  (setup)
  (case (xrepl-session-manager:create (map 'name "prompt-lfe"))
    (`#(ok ,id)
     (is-equal "xrepl" (xrepl:shell-label id)))
    (_ (is 'false)))
  (teardown))

(deftest shell-label-bad-session-id-returns-xrepl
  "shell-label on a dead/unknown session-id returns \"xrepl\" via try/catch."
  (is-equal "xrepl" (xrepl:shell-label "nonexistent-session-id-12345")))

;;; ----------------------------------------------------------------
;;; xs-shell describe name validates the xs label path end-to-end
;;; ----------------------------------------------------------------

(deftest xs-shell-describe-name-is-xs
  "xs-shell:describe/1 returns name #\"xs\", which shell-name->label maps to \"xs\".
  Proves the xs prompt label path without requiring a live xs-shell session."
  (let* ((desc (xs-shell:describe (map)))
         (name (maps:get 'name desc)))
    (is-equal #"xs" name)
    (is-equal "xs" (xrepl:shell-name->label name))))
