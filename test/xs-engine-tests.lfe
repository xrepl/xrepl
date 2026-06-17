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

(defun nav-node ()
  "scene: 3 (to …) choices with multi-synonym cmds + 1 (action help) choice.
  Used for movement-prefix stripping and exits tests (F-1…F-7)."
  (map
    'id      'nav
    'type    'scene
    'body    "A neutral junction."
    'choices (list '(choice (cmd "back" "down" "away") (to open-area))
                   '(choice (cmd "woods" "flats" "trail") (to forest))
                   '(choice (cmd "left") (to left-path))
                   '(choice (cmd "help") (action help)))))

(defun exitless-node ()
  "scene: one (action help) choice only; no (to …) choices.
  Used for F-7: exits/help on a node with no destination choices."
  (map
    'id      'exitless
    'type    'scene
    'body    "A dead end."
    'choices '(choice (cmd "help") (action help))))

(defun nav-world ()
  (xs-world:new (map 'entry 'nav 'flags '())))

(defun exitless-world ()
  (xs-world:new (map 'entry 'exitless 'flags '())))

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

;;; ----------------
;;; Phase D — movement-prefix stripping (F-1, F-2, F-3)
;;; ----------------

(deftest go-prefix-matches-bare-cmd
  "F-1: 'go back' strips 'go ' and matches the (to open-area) choice."
  (setup)
  (let* ((w0 (nav-world))
         (`#(,_w1 ,outs) (xs-engine:handle (nav-node) #"go back" w0)))
    (is (lists:member (tuple 'goto 'open-area) outs))))

(deftest all-movement-prefixes-match
  "F-2: walk/move/head/run prefixes and bare cmd all reach their choices."
  (setup)
  (let* ((w0 (nav-world))
         (`#(,_  ,o1) (xs-engine:handle (nav-node) #"walk woods" w0))
         (`#(,_  ,o2) (xs-engine:handle (nav-node) #"move left"  w0))
         (`#(,_  ,o3) (xs-engine:handle (nav-node) #"head back"  w0))
         (`#(,_  ,o4) (xs-engine:handle (nav-node) #"run back"   w0))
         (`#(,_  ,o5) (xs-engine:handle (nav-node) #"back"       w0)))
    (is (lists:member (tuple 'goto 'forest)    o1))
    (is (lists:member (tuple 'goto 'left-path) o2))
    (is (lists:member (tuple 'goto 'open-area) o3))
    (is (lists:member (tuple 'goto 'open-area) o4))
    (is (lists:member (tuple 'goto 'open-area) o5))))

(deftest go-prefix-no-false-match
  "F-3: 'go nowhere' strips to 'nowhere'; no choice matches; falls to can't-do-that."
  (setup)
  (let* ((w0 (nav-world))
         (`#(,_w1 ,outs) (xs-engine:handle (nav-node) #"go nowhere" w0)))
    (is-not (lists:any
              (lambda (o) (case o (`#(goto ,_) 'true) (_ 'false)))
              outs))
    (is (lists:any
          (lambda (o)
            (case o
              (`#(text ,b) (=/= 'nomatch (binary:match b #"can't")))
              (_ 'false)))
          outs))))

;;; ----------------
;;; Phase E — help lists exits + exits command (F-4…F-7)
;;; ----------------

(deftest help-lists-exits
  "F-4/slice4: help output contains 'Moves' and each (to …) choice's first synonym."
  (setup)
  (let* ((w0 (nav-world))
         (`#(,_w1 ,outs) (xs-engine:handle (nav-node) #"help" w0))
         (text (iolist_to_binary
                 (lists:filtermap
                   (lambda (o) (case o (`#(text ,b) (tuple 'true b)) (_ 'false)))
                   outs))))
    (is (=/= 'nomatch (binary:match text #"Moves")))
    (is (=/= 'nomatch (binary:match text #"back")))
    (is (=/= 'nomatch (binary:match text #"woods")))
    (is (=/= 'nomatch (binary:match text #"left")))))

(deftest exits-command-lists-exits
  "F-5: 'exits' meta-verb lists the node's (to …) choices."
  (setup)
  (let* ((w0 (nav-world))
         (`#(,_w1 ,outs) (xs-engine:handle (nav-node) #"exits" w0))
         (text (iolist_to_binary
                 (lists:filtermap
                   (lambda (o) (case o (`#(text ,b) (tuple 'true b)) (_ 'false)))
                   outs))))
    (is (=/= 'nomatch (binary:match text #"back")))
    (is (=/= 'nomatch (binary:match text #"woods")))
    (is (=/= 'nomatch (binary:match text #"left")))))

(deftest exits-excludes-action-choices
  "F-6: node-exits returns only (to …) choices; (action help) is excluded."
  (setup)
  (let ((exits (xs-engine:node-exits (nav-node))))
    (is (lists:member #"back"  exits))
    (is (lists:member #"woods" exits))
    (is (lists:member #"left"  exits))
    (is-equal 3 (length exits))))

(deftest exitless-node-help-exits
  "F-7: help and exits on a node with no (to …) choices say 'none obvious'; no crash."
  (setup)
  (let* ((w0 (exitless-world))
         (`#(,_w1 ,help-outs)  (xs-engine:handle (exitless-node) #"help"  w0))
         (`#(,_w2 ,exits-outs) (xs-engine:handle (exitless-node) #"exits" w0))
         (help-text  (iolist_to_binary
                       (lists:filtermap
                         (lambda (o) (case o (`#(text ,b) (tuple 'true b)) (_ 'false)))
                         help-outs)))
         (exits-text (iolist_to_binary
                       (lists:filtermap
                         (lambda (o) (case o (`#(text ,b) (tuple 'true b)) (_ 'false)))
                         exits-outs))))
    (is (=/= 'nomatch (binary:match help-text  #"none obvious")))
    (is (=/= 'nomatch (binary:match exits-text #"none obvious")))))

;;; ----------------
;;; Phase F — Unicode render fix + help/moves polish (slice6 F-1…F-7)
;;; ----------------

;;; ---- Fixtures ----

(defun em-bytes () (list 226 128 148))

(defun make-xsf (manifest-src node-pairs)
  "Build a .xsf bundle binary in memory from LFE source strings."
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

(defun uni-mfst ()
  "(story (title \"Neutral\") (schema \"1.0\") (version \"1\") (entry room-a) (protocol \"xrepl\"))")

(defun uni-room-a-src ()
  "scene room-a: two body paras, one with em-dash bytes; choice to room-b."
  (++ "(node (id room-a) (type scene) (title \"A\")"
      " (body \"Plain text.\" \"Em"
      (em-bytes)
      "dash.\")"
      " (choices (choice (cmd \"next\") (to room-b))))"))

(defun uni-room-b-src ()
  "scene room-b: two body paras, one with em-dash bytes; choice back."
  (++ "(node (id room-b) (type scene) (title \"B\")"
      " (body \"Room B.\" \"Also em"
      (em-bytes)
      "dash.\")"
      " (choices (choice (cmd \"back\") (to room-a))))"))

(defun uni-bundle-bin ()
  (make-xsf (uni-mfst)
             (list (tuple "room-a.lfe" (uni-room-a-src))
                   (tuple "room-b.lfe" (uni-room-b-src)))))

;;; ---- Tests ----

(deftest unicode-paragraph-renders
  "F-1: render-element of a byte list with em-dash bytes returns #(text …), not '()."
  (setup)
  (let* ((em-para (++ "Hello " (em-bytes) " world."))
         (world   (xs-world:new (map 'entry 'u 'flags '())))
         (result  (xs-engine:render-element em-para world)))
    (is-equal (list (tuple 'text (list_to_binary em-para)))
              result)))

(deftest multi-paragraph-unicode-enter
  "F-2: enter/2 with two body paragraphs (unicode + ASCII) renders both."
  (setup)
  (let* ((em-para   (++ "Em" (em-bytes) "dash."))
         (nd        (map 'id 'u 'type 'scene
                         'body (list "Plain text." em-para)))
         (world     (xs-world:new (map 'entry 'u 'flags '())))
         (`#(,_ ,outs) (xs-engine:enter nd world))
         (combined  (iolist_to_binary
                      (lists:filtermap
                        (lambda (o) (case o (`#(text ,b) (tuple 'true b)) (_ 'false)))
                        outs))))
    (is (=/= 'nomatch (binary:match combined #"Plain text.")))
    (is (=/= 'nomatch (binary:match combined (list_to_binary (em-bytes)))))))

(deftest scene-change-prints-room
  "F-3: navigating to a scene with Unicode body yields the full body text."
  (setup)
  (case (xs-shell:start (uni-bundle-bin))
    (`#(ok ,state0 ,_opening)
     (case (xs-shell:eval "next" state0 (map))
       (`#(ok #(formatted ,text) ,_state1)
        (is (=/= 'nomatch (binary:match text #"Room B.")))
        (is (=/= 'nomatch (binary:match text (list_to_binary (em-bytes))))))
       (other (is-equal (tuple 'expected-ok 'got) other))))
    (other (is-equal (tuple 'expected-ok-start 'got) other))))

(deftest look-prints-full-body
  "F-4: 'look' returns the current node's full body including Unicode paragraphs."
  (setup)
  (case (xs-shell:start (uni-bundle-bin))
    (`#(ok ,state0 ,_opening)
     (case (xs-shell:eval "look" state0 (map))
       (`#(ok #(formatted ,text) ,_state1)
        (is (=/= 'nomatch (binary:match text #"Plain text.")))
        (is (=/= 'nomatch (binary:match text (list_to_binary (em-bytes))))))
       (other (is-equal (tuple 'expected-ok 'got) other))))
    (other (is-equal (tuple 'expected-ok-start 'got) other))))

(deftest help-mentions-movement
  "F-5: help text includes a movement hint (go <exit>)."
  (setup)
  (let* ((w0 (nav-world))
         (`#(,_w1 ,outs) (xs-engine:handle (nav-node) #"help" w0))
         (text (iolist_to_binary
                 (lists:filtermap
                   (lambda (o) (case o (`#(text ,b) (tuple 'true b)) (_ 'false)))
                   outs))))
    (is (=/= 'nomatch (binary:match text #"go ")))))

(deftest help-blank-line-before-moves
  "F-6: help text has a blank line (\\n\\n) immediately before 'Moves'."
  (setup)
  (let* ((w0 (nav-world))
         (`#(,_w1 ,outs) (xs-engine:handle (nav-node) #"help" w0))
         (text (iolist_to_binary
                 (lists:filtermap
                   (lambda (o) (case o (`#(text ,b) (tuple 'true b)) (_ 'false)))
                   outs))))
    (is (=/= 'nomatch (binary:match text #"\n\nMoves")))))

(deftest moves-label
  "F-7: 'moves' and 'exits' both produce text with the 'Moves:' label."
  (setup)
  (let* ((w0 (nav-world))
         (`#(,_  ,m-outs) (xs-engine:handle (nav-node) #"moves" w0))
         (`#(,_  ,e-outs) (xs-engine:handle (nav-node) #"exits" w0))
         (extract (lambda (outs)
                    (iolist_to_binary
                      (lists:filtermap
                        (lambda (o) (case o (`#(text ,b) (tuple 'true b)) (_ 'false)))
                        outs))))
         (m-text (funcall extract m-outs))
         (e-text (funcall extract e-outs)))
    (is (=/= 'nomatch (binary:match m-text #"Moves:")))
    (is (=/= 'nomatch (binary:match e-text #"Moves:")))))
