(defmodule xs-engine
  "Pure interactive-fiction step functions for the xs engine.

  No IO, no zip, no protocol, no xrepl deps. Data in, data out.
  Designed to re-port to a future Lykn→JS browser reader.

  xs-bundle (slice1) produces NodeMaps; xs-world (slice2) owns World state
  and the condition evaluator. xs-engine drives the scene/prompt/ending/
  suspend transitions.

  IR-consumption note: xs-bundle's parse-keyword-list stores a single-valued
  multi-element field BARE and a multi-element one as a list. Every access
  to body/choices/items/on-enter/on-take must go through as-list/1.

  Note on naming: 'nd' is used throughout as the NodeMap parameter; 'node'
  is an Erlang BIF and causes lfe_lint errors if used as a variable name."
  (export
   (handle 3)
   (enter 2)
   (as-list 1)
   (string? 1)))

;;; ----------------
;;; Phase A — as-list normaliser
;;; ----------------

(defun string? (v)
  "Return true when V is a non-empty printable char list (an LFE string).

  Used by as-list to distinguish a bare body string from a tagged form."
  (andalso (is_list v)
           (=/= v '())
           (io_lib:printable_list v)))

(defun as-list (v)
  "Normalise a possibly-bare xs-bundle field value to a proper list.

  xs-bundle's parse-keyword-list stores a 2-element (key val) pair with val
  BARE, but a (key v1 v2 …) pair as a list of values. This produces:

    '()                → '()        ; empty stays empty
    \"string\"          → (\"string\") ; bare string wrapped
    (stream \"x\")      → ((stream \"x\")); single tagged form wrapped (atom head)
    (choice …)        → ((choice …)); single tagged form wrapped
    ((choice …) (choice …)) → unchanged ; already a list of elements
    (\"a\" \"b\")       → (\"a\" \"b\") ; list of strings (head is string)

  Decision: if the head of V is itself a list OR a string → already a list
  of elements. If the head is an atom → V is a single tagged form → wrap."
  (cond
    ((== v '()) '())
    ((string? v) (list v))
    ((is_list v)
     (let ((h (car v)))
       (if (orelse (is_list h) (string? h))
         v          ;; already a list of elements
         (list v))));; single tagged form (atom head)
    ('true (list v))))

;;; ----------------
;;; Shared helpers
;;; ----------------

(defun to-bin (v)
  "Coerce V to binary."
  (cond
    ((is_binary v) v)
    ((is_list v)   (list_to_binary v))
    ('true         (list_to_binary (io_lib:format "~p" (list v))))))

(defun apply-sets (set-forms world)
  "Apply a list of (set F V) forms to World; malformed forms are ignored."
  (lists:foldl
    (lambda (form w)
      (case form
        ((list 'set f v) (xs-world:set-flag w f v))
        (_ w)))
    world
    set-forms))

(defun render-element (elem world)
  "Render a single body element to a list of Outputs.

  string           → [#(text Binary)]
  (stream \"…\")    → [#(stream Binary)]
  (if Cond Then)   → render Then if cond holds, else []
  (if Cond T E)    → conditional branch
  anything else    → []"
  (cond
    ((string? elem)
     (list (tuple 'text (to-bin elem))))
    ((andalso (is_list elem) (=/= elem '()) (== (car elem) 'stream))
     (case elem
       ((list 'stream text) (list (tuple 'stream (to-bin text))))
       (_ '())))
    ((andalso (is_list elem) (=/= elem '()) (== (car elem) 'if))
     (case elem
       ((list 'if cond then)
        (if (xs-world:eval-cond cond world)
          (render-element then world) '()))
       ((list 'if cond then else)
        (if (xs-world:eval-cond cond world)
          (render-element then world)
          (render-element else world)))
       (_ '())))
    ('true '())))

(defun emit-reveal (nd world)
  "Emit reveal elements when the reveal condition holds.

  reveal value shape: [(when Cond) Elem …] — first element is the guard."
  (case (maps:get 'reveal nd 'none)
    ('none '())
    (rval
     (case (as-list rval)
       ('() '())
       ((cons (list 'when cond) elems)
        (if (xs-world:eval-cond cond world)
          (lists:flatmap (lambda (e) (render-element e world)) elems)
          '()))
       (_ '())))))

(defun emit-image (nd)
  "Emit #(image Id) if the NodeMap has an image field."
  (case (maps:get 'image nd 'none)
    ('none  '())
    (img-id (list (tuple 'image img-id)))))

(defun parse-kv-pairs (parts)
  "Convert a list of (key val …) pairs into a map."
  (lists:foldl
    (lambda (part acc)
      (case part
        ((list key val) (maps:put key val acc))
        ((cons key vals) (maps:put key vals acc))
        (_ acc)))
    (map)
    parts))

;;; ----------------
;;; Phase B — enter/2
;;; ----------------

(defun enter (nd world)
  "Apply on-enter + bump-visit + emit body/reveal/image + kind tail.

  Order: on-enter sets → bump-visit → body → reveal → image → kind-tail.
  Visit is bumped BEFORE reveal so (>= visits 2) conditions trigger on
  the 2nd entry.

  Args:
    nd:    NodeMap from xs-bundle
    world: World from xs-world

  Returns:
    #(World2 Outputs)"
  (let* (;; 1. Apply on-enter sets
         (on-enter (as-list (maps:get 'on-enter nd '())))
         (w1       (apply-sets on-enter world))
         ;; 2. Bump this node's visit
         (nd-id    (maps:get 'id nd 'undefined))
         (w2       (xs-world:bump-visit w1 nd-id))
         ;; 3. Emit body
         (body     (as-list (maps:get 'body nd '())))
         (body-out (lists:flatmap (lambda (e) (render-element e w2)) body))
         ;; 4. Reveal (condition evaluated against w2 so visit bump counts)
         (rev-out  (emit-reveal nd w2))
         ;; 5. Image
         (img-out  (emit-image nd))
         ;; 6. Kind tail
         (kind     (maps:get 'type nd 'scene))
         (tail     (case kind
                     ('ending  (list 'done))
                     ('suspend (list 'suspend))
                     (_ '())))
         (outputs  (++ body-out rev-out img-out tail)))
    (tuple w2 outputs)))

;;; ----------------
;;; Phase C — handle/3
;;; ----------------

(defun handle (nd input world)
  "Process one player input line against the current node.

  Input is a binary, already lowercased and trimmed by the caller.
  Precedence: choice → meta verbs → (prompt) password → unmatched.

  Args:
    nd:    NodeMap from xs-bundle
    input: binary player input
    world: World from xs-world

  Returns:
    #(World2 Outputs)"
  (let ((nd-type (maps:get 'type nd 'scene)))
    (case (try-choices nd input world)
      (`#(matched ,out ,w2)
       (tuple w2 out))
      ('no-match
       (case (try-meta-verb nd input world)
         (`#(matched ,out ,w2)
          (tuple w2 out))
         ('no-match
          (case nd-type
            ('prompt
             (try-password nd input world))
            (_
             (tuple world
                    (list (tuple 'text #"You can't do that.")))))))))))

;;; ---- Choice matching ----

(defun try-choices (nd input world)
  "Try every choice in order; return first match or 'no-match."
  (try-choice-list (as-list (maps:get 'choices nd '())) nd input world))

(defun try-choice-list (choices nd input world)
  (case choices
    ('() 'no-match)
    ((cons choice rest)
     (case (match-choice choice nd input world)
       (`#(matched ,out ,w2) (tuple 'matched out w2))
       ('no-match (try-choice-list rest nd input world))))))

(defun match-choice (choice nd input world)
  "Match one raw (choice …) form against Input.

  nd is needed so the 'look action can re-emit the current node's body.
  Returns #(matched Outputs World2) or 'no-match."
  (case choice
    ((cons 'choice parts)
     (let* ((cm     (parse-kv-pairs parts))
            (cmds   (as-list (maps:get 'cmd cm '())))
            (to-id  (maps:get 'to cm 'none))
            (if-g   (maps:get 'if cm 'true))
            (set-fv (maps:get 'set cm 'none))
            (action (maps:get 'action cm 'none))
            (cond?  (xs-world:eval-cond if-g world))
            (match? (cmd-matches? cmds input)))
       (if (andalso cond? match?)
         (let* ((w1   (apply-choice-set set-fv world))
                (outs (cond
                        ((=/= to-id 'none)
                         (list (tuple 'goto to-id)))
                        ((=/= action 'none)
                         (run-action action nd world))
                        ('true '()))))
           (tuple 'matched outs w1))
         'no-match)))
    (_ 'no-match)))

(defun apply-choice-set (set-fv world)
  "Apply a choice's optional (set F V) to World."
  (case set-fv
    ('none world)
    ((list f v) (xs-world:set-flag world f v))
    (_ world)))

(defun cmd-matches? (cmds input)
  "True when any cmd string (char list) equals Input (binary)."
  (lists:any
    (lambda (cmd) (== (to-bin cmd) input))
    cmds))

(defun run-action (action nd world)
  "Execute a meta action from a choice (look / inventory / help)."
  (case action
    ('look
     (let* ((body    (as-list (maps:get 'body nd '())))
            (b-out   (lists:flatmap (lambda (e) (render-element e world)) body))
            (rev-out (emit-reveal nd world))
            (img-out (emit-image nd)))
       (++ b-out rev-out img-out)))
    ('inventory
     (inventory-output world))
    ('help
     (list (tuple 'text #"Commands: look, help, inventory (i), take <item>.")))
    (_ '())))

;;; ---- Meta verbs ----

(defun try-meta-verb (nd input world)
  "Handle look / take / inventory / help; return #(matched …) or 'no-match."
  (let ((s (binary_to_list input)))
    (cond
      ((== s "look")
       (let* ((body    (as-list (maps:get 'body nd '())))
              (b-out   (lists:flatmap (lambda (e) (render-element e world)) body))
              (rev-out (emit-reveal nd world))
              (img-out (emit-image nd)))
         (tuple 'matched (++ b-out rev-out img-out) world)))

      ((take-cmd? s)
       (let ((item-atom (list_to_atom (take-target s))))
         (try-take nd item-atom world)))

      ((orelse (== s "inventory") (== s "i"))
       (tuple 'matched (inventory-output world) world))

      ((== s "help")
       (tuple 'matched
              (list (tuple 'text
                           #"Commands: look, help, inventory (i), take <item>."))
              world))

      ('true 'no-match))))

(defun take-cmd? (s)
  "True when S starts with 'take ' or 'get '."
  (orelse (=/= 'nomatch (string:prefix s "take "))
          (=/= 'nomatch (string:prefix s "get "))))

(defun take-target (s)
  "Extract the item name string from 'take foo' or 'get foo'."
  (case (string:find s " ")
    ('nomatch "")
    (suffix (string:trim suffix))))

(defun inventory-output (world)
  "Build the inventory text output."
  (let ((items (maps:keys (maps:get 'items world (map)))))
    (if (== items '())
      (list (tuple 'text #"You are carrying nothing."))
      (let ((names (string:join
                     (lists:map (lambda (a) (atom_to_list a)) items)
                     ", ")))
        (list (tuple 'text (to-bin (++ "You are carrying: " names "."))))))))

;;; ---- Items ----

(defun try-take (nd item-id world)
  "Try to take an item by id atom."
  (try-take-list (as-list (maps:get 'items nd '())) item-id world))

(defun try-take-list (items item-id world)
  (case items
    ('()
     (tuple 'matched (list (tuple 'text #"You can't take that.")) world))
    ((cons item rest)
     (case item
       ((cons 'item parts)
        (let* ((im (parse-kv-pairs parts))
               (id (maps:get 'id im 'none)))
          (if (== id item-id)
            (let ((takeable (maps:get 'takeable im 'false)))
              (if (xs-world:eval-cond takeable world)
                (take-item im item-id world)
                (tuple 'matched
                       (list (tuple 'text #"You can't take that."))
                       world)))
            (try-take-list rest item-id world))))
       (_ (try-take-list rest item-id world))))))

(defun take-item (item-map item-id world)
  "Apply on-take: render text elements, apply sets, add item to inventory."
  (let* ((on-take-all (as-list (maps:get 'on-take item-map '())))
         (parts       (lists:partition
                        (lambda (e)
                          (andalso (is_list e) (=/= e '())
                                   (== (car e) 'set)))
                        on-take-all))
         (sets        (element 1 parts))
         (elems       (element 2 parts))
         (w1          (apply-sets sets world))
         (w2          (xs-world:add-item w1 item-id))
         (outs        (lists:flatmap (lambda (e) (render-element e w2)) elems)))
    (tuple 'matched outs w2)))

;;; ---- Prompt password ----

(defun try-password (nd input world)
  "For prompt nodes: match Input against password; emit goto or fail-text."
  (let ((pw       (maps:get 'password nd 'none))
        (on-succ  (maps:get 'on-success nd 'none))
        (fail-txt (maps:get 'fail-text nd "Nothing happens.")))
    (if (== pw 'none)
      (tuple world (list (tuple 'text #"You can't do that.")))
      (if (== input (to-bin pw))
        (let ((outs (if (== on-succ 'none) '()
                      (list (tuple 'goto on-succ)))))
          (tuple world outs))
        (tuple world
               (list (tuple 'text (to-bin fail-txt))))))))
