(defmodule xs-engine-tests
  "Unit tests for xs-engine — as-list, enter/2, handle/3.

  Fixtures use neutral invented ids: start (scene), gate (prompt),
  vault (ending). No story content."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

(defun setup () 'ok)

;;; ----------------
;;; Fixture node maps (shaped as xs-bundle would produce)
;;; ----------------

(defun start-node ()
  "scene: on-enter set; bare body string; reveal on 2nd visit;
   image; bare single choice; bare single item with on-take."
  (map
    'id      'start
    'type    'scene
    ;; Single body string — BARE (2-elem list case from parse-keyword-list)
    'body    "You are at the start."
    ;; Single on-enter (set) — BARE
    'on-enter '(set visited true)
    ;; Reveal with multiple parts → stored as list
    'reveal  (list '(when (>= visits 2)) "A key glints here.")
    'image   "start.png"
    ;; Single choice — BARE
    'choices '(choice (cmd "north") (to gate))
    ;; Single item — BARE; takeable on 2nd visit
    'items   '(item (id key)
                    (takeable (>= visits 2))
                    (on-take "You take the key." (set has-key true)))))

(defun gate-node ()
  "prompt: bare body; bare back-choice; password; on-success; fail-text."
  (map
    'id          'gate
    'type        'prompt
    'body        "The gate is locked."
    ;; Single choice — BARE
    'choices     '(choice (cmd "back") (to start))
    'password    "xyzzy"
    'on-success  'vault
    'fail-text   "The gate does not open."))

(defun vault-node ()
  "ending: bare body."
  (map
    'id   'vault
    'type 'ending
    'body "You are in the vault!"))

(defun fresh-world ()
  (xs-world:new (map 'entry 'start
                     'flags (list (map 'id 'visited  'type 'bool 'default 'false)
                                  (map 'id 'has-key  'type 'bool 'default 'false)))))

;;; ----------------
;;; Phase A — as-list tests
;;; ----------------

(deftest as-list-empty
  "'() stays '()."
  (setup)
  (is-equal '() (xs-engine:as-list '())))

(deftest as-list-bare-string
  "A bare string (printable list) is wrapped in a list."
  (setup)
  (is-equal (list "x") (xs-engine:as-list "x")))

(deftest as-list-list-of-strings
  "A list whose head is a string is already a list of elements."
  (setup)
  (is-equal (list "a" "b") (xs-engine:as-list (list "a" "b"))))

(deftest as-list-single-tagged-form-stream
  "(stream \"x\") is a single tagged form — wrapped."
  (setup)
  (is-equal (list '(stream "x")) (xs-engine:as-list '(stream "x"))))

(deftest as-list-single-tagged-form-choice
  "(choice (cmd \"go\") (to a)) is a single tagged form — wrapped."
  (setup)
  (is-equal (list '(choice (cmd "go") (to a)))
            (xs-engine:as-list '(choice (cmd "go") (to a)))))

(deftest as-list-list-of-choices
  "A list of choices (head is list) is returned unchanged."
  (setup)
  (let ((cs (list '(choice (cmd "go") (to a)) '(choice (cmd "back") (to b)))))
    (is-equal cs (xs-engine:as-list cs))))

(deftest as-list-single-set-form
  "(set f v) is a single tagged form — wrapped."
  (setup)
  (is-equal (list '(set f v)) (xs-engine:as-list '(set f v))))

;;; ----------------
;;; Phase B — enter/2 tests
;;; ----------------

(deftest enter-start-first-visit
  "1st enter: body emitted; on-enter flag set; visits[start]=1; reveal absent."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,outs) (xs-engine:enter (start-node) w0)))
    ;; Body text emitted
    (is (lists:any
          (lambda (o) (case o (`#(text ,_) 'true) (_ 'false)))
          outs))
    ;; Image emitted
    (is (lists:member (tuple 'image "start.png") outs))
    ;; on-enter flag set
    (is-equal 'true (xs-world:flag w1 'visited))
    ;; Visit count bumped
    (is-equal 1 (xs-world:visits w1 'start))
    ;; Reveal NOT shown on 1st visit
    (is-not (lists:any
              (lambda (o)
                (case o
                  (`#(text ,b) (=/= 'nomatch (binary:match b #"key")))
                  (_ 'false)))
              outs))))

(deftest enter-start-second-visit
  "2nd enter: visits[start]=2; reveal shown."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (start-node) w0))
         (`#(,w2 ,outs2) (xs-engine:enter (start-node) w1)))
    (is-equal 2 (xs-world:visits w2 'start))
    ;; Reveal shown
    (is (lists:any
          (lambda (o)
            (case o
              (`#(text ,b) (=/= 'nomatch (binary:match b #"key")))
              (_ 'false)))
          outs2))))

(deftest enter-gate
  "enter gate: body emitted; no tail (prompt node)."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,_w1 ,outs) (xs-engine:enter (gate-node) w0)))
    (is (lists:any
          (lambda (o) (case o (`#(text ,_) 'true) (_ 'false)))
          outs))
    ;; No done/suspend
    (is-not (lists:member 'done outs))
    (is-not (lists:member 'suspend outs))))

(deftest enter-vault
  "enter vault (ending): body emitted then 'done."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,_w1 ,outs) (xs-engine:enter (vault-node) w0)))
    (is (lists:any
          (lambda (o) (case o (`#(text ,_) 'true) (_ 'false)))
          outs))
    (is (lists:member 'done outs))))

;;; ----------------
;;; Phase C — handle/3 tests
;;; ----------------

(deftest handle-choice-north
  "handle start 'north' → #(goto gate)."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (start-node) w0))
         (`#(,_w2 ,outs) (xs-engine:handle (start-node) #"north" w1)))
    (is (lists:member (tuple 'goto 'gate) outs))))

(deftest handle-wrong-password
  "handle gate 'wrong' → fail-text as #(text …); world unchanged."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (gate-node) w0))
         (`#(,w2 ,outs) (xs-engine:handle (gate-node) #"wrong" w1)))
    ;; fail-text emitted
    (is (lists:any
          (lambda (o)
            (case o
              (`#(text ,b)
               (=/= 'nomatch (binary:match b #"does not open")))
              (_ 'false)))
          outs))
    ;; No goto
    (is-not (lists:any (lambda (o) (case o (`#(goto ,_) 'true) (_ 'false)))
                       outs))
    ;; World unchanged
    (is-equal w1 w2)))

(deftest handle-correct-password
  "handle gate 'xyzzy' → #(goto vault)."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (gate-node) w0))
         (`#(,_w2 ,outs) (xs-engine:handle (gate-node) #"xyzzy" w1)))
    (is (lists:member (tuple 'goto 'vault) outs))))

(deftest handle-back-choice
  "handle gate 'back' → #(goto start)."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (gate-node) w0))
         (`#(,_w2 ,outs) (xs-engine:handle (gate-node) #"back" w1)))
    (is (lists:member (tuple 'goto 'start) outs))))

(deftest handle-take-key-not-takeable-1st-visit
  "take key on 1st visit (visits=1) → can't take (takeable cond fails)."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (start-node) w0))
         ;; visits[start]=1; takeable=(>= visits 2) → false
         ;; Must set current node to 'start for eval-cond
         (w1b (xs-world:set-node w1 'start))
         (`#(,_w2 ,outs) (xs-engine:handle (start-node) #"take key" w1b)))
    (is (lists:any
          (lambda (o)
            (case o
              (`#(text ,b) (=/= 'nomatch (binary:match b #"can't")))
              (_ 'false)))
          outs))))

(deftest handle-take-key-2nd-visit
  "take key on 2nd visit → on-take text + has-key set + item held."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (start-node) w0))
         (`#(,w2 ,_) (xs-engine:enter (start-node) w1))
         ;; Set current node so visits check works
         (w2b (xs-world:set-node w2 'start))
         (`#(,w3 ,outs) (xs-engine:handle (start-node) #"take key" w2b)))
    ;; on-take text emitted
    (is (lists:any
          (lambda (o)
            (case o
              (`#(text ,b) (=/= 'nomatch (binary:match b #"take")))
              (_ 'false)))
          outs))
    ;; has-key flag set
    (is-equal 'true (xs-world:flag w3 'has-key))
    ;; Item held
    (is (xs-world:has-item w3 'key))))

(deftest handle-inventory-empty
  "inventory when holding nothing → 'You are carrying nothing.'."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (start-node) w0))
         (`#(,_w2 ,outs) (xs-engine:handle (start-node) #"inventory" w1)))
    (is (lists:any
          (lambda (o)
            (case o
              (`#(text ,b) (=/= 'nomatch (binary:match b #"nothing")))
              (_ 'false)))
          outs))))

(deftest handle-help
  "help → a help text output."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (start-node) w0))
         (`#(,_w2 ,outs) (xs-engine:handle (start-node) #"help" w1)))
    (is (lists:any
          (lambda (o) (case o (`#(text ,_) 'true) (_ 'false)))
          outs))))

(deftest handle-unmatched-scene
  "Unmatched input in a scene → \"You can't do that.\"."
  (setup)
  (let* ((w0 (fresh-world))
         (`#(,w1 ,_) (xs-engine:enter (start-node) w0))
         (`#(,_w2 ,outs) (xs-engine:handle (start-node) #"zzz" w1)))
    (is (lists:any
          (lambda (o)
            (case o
              (`#(text ,b) (=/= 'nomatch (binary:match b #"can't")))
              (_ 'false)))
          outs))))
