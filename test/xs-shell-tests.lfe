(defmodule xs-shell-tests
  "Integration tests for xs-shell, xs:run, and the xrepl-shell-lfe
  switch-sentinel addition.

  All fixtures use neutral invented names: start/gate/vault. No story words."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

(defun setup ()
  (application:ensure_all_started 'xrepl)
  'ok)

;;; ----------------
;;; In-test bundle builder (same pattern as xs-bundle-tests)
;;; ----------------

(defun make-xsf (manifest-src node-pairs)
  (let* ((m-entry   (tuple "manifest.lfe" (list_to_binary manifest-src)))
         (n-entries (lists:map
                      (lambda (p)
                        (tuple (++ "nodes/" (element 1 p))
                               (list_to_binary (element 2 p))))
                      node-pairs))
         (entries   (cons m-entry n-entries)))
    (case (zip:create "bundle.xsf" entries '(memory))
      (`#(ok #(,_ ,bin)) bin)
      (err (error (tuple 'fixture-failed err))))))

;;; ---- Neutral source strings ----

(defun mfst-src ()
  "(story (title \"Neutral Test\") (schema \"1.0\") (version \"1\")
          (entry start) (protocol \"xrepl\")
          (assets (images-dir \"assets/images\")))")

(defun start-src ()
  "(node (id start) (type scene) (title \"Start\")
         (body \"You are at the start.\")
         (choices (choice (cmd \"north\") (to gate))))")

(defun gate-src ()
  "(node (id gate) (type prompt) (title \"Gate\")
         (body \"The gate is locked.\")
         (choices (choice (cmd \"back\") (to start)))
         (password \"xyzzy\")
         (on-success vault)
         (fail-text \"The gate does not open.\"))")

(defun vault-src ()
  "(node (id vault) (type ending) (title \"Vault\")
         (body \"You are in the vault!\"))")

(defun test-bundle-bin ()
  (make-xsf (mfst-src)
             (list (tuple "start.lfe" (start-src))
                   (tuple "gate.lfe"  (gate-src))
                   (tuple "vault.lfe" (vault-src)))))

;;; ----------------
;;; xs-shell:start/1
;;; ----------------

(deftest start-returns-ok-and-opening
  "start/1 loads the bundle and returns the opening room text."
  (setup)
  (let ((bin (test-bundle-bin)))
    (case (xs-shell:start bin)
      (`#(ok ,_state ,opening)
       (is (is_binary opening))
       (is (> (byte_size opening) 0))
       ;; Opening must contain start node body text
       (is (=/= 'nomatch (binary:match opening #"start"))))
      (other
       (is-equal (tuple 'expected-ok 'got) other)))))

;;; ----------------
;;; xs-shell:eval/3 — turn-by-turn tests
;;; ----------------

(deftest eval-north-goes-to-gate
  "eval 'north' → goto gate → enter gate → Opening shows gate body text."
  (setup)
  (let ((bin (test-bundle-bin)))
    (case (xs-shell:start bin)
      (`#(ok ,state0 ,_opening)
       (case (xs-shell:eval "north" state0 (map))
         (`#(ok #(formatted ,t) ,_state1)
          (is (=/= 'nomatch (binary:match t #"gate"))))
         (other
          (is-equal (tuple 'expected-ok-formatted 'got) other))))
      (_ (is 'false)))))

(deftest eval-wrong-password-returns-fail-text
  "eval 'wrong' at gate → fail-text; current node still gate."
  (setup)
  (let ((bin (test-bundle-bin)))
    (case (xs-shell:start bin)
      (`#(ok ,state0 ,_)
       ;; Get to gate
       (case (xs-shell:eval "north" state0 (map))
         (`#(ok ,_ ,state1)
          ;; Try wrong password
          (case (xs-shell:eval "wrong" state1 (map))
            (`#(ok #(formatted ,t) ,state2)
             ;; fail-text present
             (is (=/= 'nomatch (binary:match t #"does not open")))
             ;; current node still gate
             (let ((world (xs-shell:snapshot state2)))
               (is-equal 'gate (xs-world:current-node world))))
            (other (is-equal (tuple 'expected-ok 'got) other))))
         (_ (is 'false))))
      (_ (is 'false)))))

(deftest eval-correct-password-ends-story
  "eval 'xyzzy' at gate → vault (ending) → switch-shell back to LFE."
  (setup)
  (let ((bin (test-bundle-bin)))
    (case (xs-shell:start bin)
      (`#(ok ,state0 ,_)
       ;; Get to gate
       (case (xs-shell:eval "north" state0 (map))
         (`#(ok ,_ ,state1)
          ;; Enter correct password
          (case (xs-shell:eval "xyzzy" state1 (map))
            (`#(switch-shell xrepl-shell-lfe ,_opts #(formatted ,t))
             ;; Vault body text present in final output
             (is (=/= 'nomatch (binary:match t #"vault"))))
            (other
             (is-equal (tuple 'expected-switch-shell 'got) other))))
         (_ (is 'false))))
      (_ (is 'false)))))

(deftest eval-back-choice-returns-to-start
  "eval 'back' at gate → goto start → show start body."
  (setup)
  (let ((bin (test-bundle-bin)))
    (case (xs-shell:start bin)
      (`#(ok ,state0 ,_)
       (case (xs-shell:eval "north" state0 (map))
         (`#(ok ,_ ,state1)
          (case (xs-shell:eval "back" state1 (map))
            (`#(ok #(formatted ,t) ,state2)
             (is (=/= 'nomatch (binary:match t #"start")))
             (let ((world (xs-shell:snapshot state2)))
               (is-equal 'start (xs-world:current-node world))))
            (other (is-equal (tuple 'expected-ok 'got) other))))
         (_ (is 'false))))
      (_ (is 'false)))))

;;; ----------------
;;; xs-shell callbacks: describe / prompt / snapshot
;;; ----------------

(deftest describe-name-is-xs
  "describe returns a map with name = #\"xs\"."
  (setup)
  (let ((bin (test-bundle-bin)))
    (case (xs-shell:start bin)
      (`#(ok ,state ,_)
       (let ((desc (xs-shell:describe state)))
         (is (is_map desc))
         (is-equal #"xs" (maps:get 'name desc))))
      (_ (is 'false)))))

(deftest prompt-returns-gt
  "prompt returns the #\"> \" binary."
  (setup)
  (let ((bin (test-bundle-bin)))
    (case (xs-shell:start bin)
      (`#(ok ,state ,_)
       (is-equal #"> " (xs-shell:prompt state)))
      (_ (is 'false)))))

(deftest snapshot-returns-world
  "snapshot returns a map (the xs-world World) with a 'node key."
  (setup)
  (let ((bin (test-bundle-bin)))
    (case (xs-shell:start bin)
      (`#(ok ,state ,_)
       (let ((snap (xs-shell:snapshot state)))
         (is (is_map snap))
         (is (maps:is_key 'node snap))))
      (_ (is 'false)))))

;;; ----------------
;;; Switch-sentinel recognition in xrepl-shell-lfe
;;; ----------------

(deftest sentinel-recognised-by-lfe-shell
  "A function returning #(xrepl-switch-shell M O R) through xrepl-shell-lfe
  yields #(switch-shell M O R) — the generic shell-switch mechanism."
  (setup)
  (case (xrepl-shell-lfe:init (map))
    (`#(ok ,lfe-state)
     ;; Evaluate a form that returns the sentinel tuple
     (let ((sentinel-code
             "(tuple 'xrepl-switch-shell 'echo #m() #(formatted #\"hi\"))"))
       (case (xrepl-shell-lfe:eval sentinel-code lfe-state (map))
         (`#(switch-shell echo ,_opts #(formatted ,bin))
          (is-equal #"hi" bin))
         (other
          (is-equal (tuple 'expected-switch-shell 'got) other)))))
    (_ (is 'false))))

;;; ----------------
;;; xs:run — graceful degradation when support.xsf is absent
;;; ----------------

(deftest xs-run-graceful-when-no-xsf
  "xs:run returns #(formatted …) when priv/support.xsf does not exist."
  (setup)
  ;; priv/support.xsf is absent — xs:run must not crash
  (case (xs:run)
    (`#(formatted ,msg)
     (is (is_binary msg))
     (is (> (byte_size msg) 0)))
    ;; If somehow it loads (xsf exists in test env), also acceptable
    (`#(xrepl-switch-shell xs-shell ,_ ,_)
     (is 'true))
    (other
     (is-equal (tuple 'expected-formatted 'got) other))))

;;; ----------------
;;; Multi-text render path (addendum)
;;; ----------------

(deftest multi-text-body-joined-by-newline
  "A room with a multi-element body renders both paragraphs joined by \\n.

  Exercises the binary:join branch of join-texts and the multi-output
  accumulation in process-outputs. A (body \"P1\" \"P2\") node stores
  body as a list of two strings; each becomes a #(text Bin) output;
  process-outputs accumulates both; join-texts joins with newline."
  (setup)
  (let* ((multi-body-start
           "(node (id start) (type scene) (title \"Start\")
                  (body \"First line.\" \"Second line.\")
                  (choices (choice (cmd \"go\") (to vault))))")
         (bin (make-xsf (mfst-src)
                        (list (tuple "start.lfe" multi-body-start)
                              (tuple "vault.lfe" (vault-src))))))
    (case (xs-shell:start bin)
      (`#(ok ,_state ,opening)
       ;; Both paragraphs must appear in the output
       (is (=/= 'nomatch (binary:match opening #"First line.")))
       (is (=/= 'nomatch (binary:match opening #"Second line.")))
       ;; They must be separated by a newline (binary:join behaviour)
       (is (=/= 'nomatch (binary:match opening #"First line.\nSecond line."))))
      (other
       (is-equal (tuple 'expected-multi-text-opening 'got) other)))))
