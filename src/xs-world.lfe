(defmodule xs-world
  "Per-play-through world state and total condition evaluator for xs-engine.

  Pure data — atoms/numbers/maps only — so the whole World serializes for
  free (Arc8 stores it in session metadata via xs-shell).

  World shape:
    #m(node    Id           ; current node id atom
       flags   #{f => bool} ; flag-id -> true | false
       visits  #{Id => N}   ; per-node visit count
       items   #{id => true}); held item ids

  Condition grammar (eval-cond/2):
    (flag? F)        flag F is true
    (not C)          logical negation
    (and C ...)      all sub-conditions true  (short-circuit via foldl)
    (or  C ...)      any sub-condition true   (short-circuit via foldl)
    (>= visits N)    current-node visits >= N
    (=  visits N)    current-node visits =  N
    true / false     literals

  Totality rule: any unrecognised or malformed form returns 'false and
  emits a logger:warning. A bad bundle must never crash a play-through.

  Implementation note: LFE 2.2's lfe_codelift has trouble with closures
  inside try blocks; eval-cond uses a plain case + named helpers instead."
  (export
   (new 1)
   (current-node 1)
   (set-node 2)
   (flag 2)
   (set-flag 3)
   (visits 2)
   (bump-visit 2)
   (has-item 2)
   (add-item 2)
   (eval-cond 2)))

;;; ----------------
;;; World construction
;;; ----------------

(defun new (manifest)
  "Initialise a fresh World from a parsed manifest map.

  Flags are seeded from the manifest's flag-definition list (each entry is
  #m(id <atom> type bool default <bool>)). Visit counts and items start
  empty. Current node is set to the manifest entry atom.

  Args:
    manifest: parsed manifest map from xs-bundle

  Returns:
    World map"
  (let* ((flag-defs (maps:get 'flags manifest '()))
         (entry-id  (maps:get 'entry manifest 'undefined))
         (flags     (lists:foldl
                      (lambda (def acc)
                        (let ((id      (maps:get 'id def 'undefined))
                              (default (maps:get 'default def 'false)))
                          (if (== id 'undefined)
                            acc
                            (maps:put id default acc))))
                      (map)
                      flag-defs)))
    (map 'node   entry-id
         'flags  flags
         'visits (map)
         'items  (map))))

;;; ----------------
;;; Node tracking
;;; ----------------

(defun current-node (world)
  "Return the current node id atom.

  Args:
    world: World map

  Returns:
    atom id"
  (maps:get 'node world 'undefined))

(defun set-node (world id)
  "Set the current node id atom.

  Args:
    world: World map
    id:    node id atom

  Returns:
    updated World"
  (maps:put 'node id world))

;;; ----------------
;;; Flags
;;; ----------------

(defun flag (world f)
  "Return the boolean value of flag F. Defaults to 'false if unset.

  Args:
    world: World map
    f:     flag id atom

  Returns:
    true | false"
  (maps:get f (maps:get 'flags world (map)) 'false))

(defun set-flag (world f v)
  "Set flag F to boolean value V.

  Args:
    world: World map
    f:     flag id atom
    v:     true | false

  Returns:
    updated World"
  (maps:put 'flags
            (maps:put f v (maps:get 'flags world (map)))
            world))

;;; ----------------
;;; Visit counts
;;; ----------------

(defun visits (world id)
  "Return the visit count for node Id. Defaults to 0 if unvisited.

  Args:
    world: World map
    id:    node id atom

  Returns:
    non-negative integer"
  (maps:get id (maps:get 'visits world (map)) 0))

(defun bump-visit (world id)
  "Increment the visit count for node Id by 1.

  Args:
    world: World map
    id:    node id atom

  Returns:
    updated World"
  (let ((n (visits world id)))
    (maps:put 'visits
              (maps:put id (+ n 1) (maps:get 'visits world (map)))
              world)))

;;; ----------------
;;; Inventory
;;; ----------------

(defun has-item (world id)
  "Return true if item Id is in the player's inventory.

  Args:
    world: World map
    id:    item id atom

  Returns:
    true | false"
  (maps:is_key id (maps:get 'items world (map))))

(defun add-item (world id)
  "Add item Id to the player's inventory.

  Args:
    world: World map
    id:    item id atom

  Returns:
    updated World"
  (maps:put 'items
            (maps:put id 'true (maps:get 'items world (map)))
            world))

;;; ----------------
;;; Condition evaluator
;;; ----------------

(defun eval-cond (cond world)
  "Evaluate a condition s-expr against World. Always returns true or false.

  Covers the full §1.6 grammar. Unrecognised or malformed forms return
  'false and emit logger:warning — a bad bundle must not crash a session.

  Args:
    cond:  a condition s-expr (atom, list, or any term)
    world: World map

  Returns:
    true | false"
  (case cond
    ;; Literals
    ('true  'true)
    ('false 'false)
    ;; (flag? F)
    ((list 'flag? f)
     (flag world f))
    ;; (not C)
    ((list 'not c)
     (if (eval-cond c world) 'false 'true))
    ;; (and C ...) — short-circuits via foldl; each sub-form via eval-cond
    ((cons 'and cs)
     (eval-cond-and cs world))
    ;; (or C ...) — short-circuits via foldl
    ((cons 'or cs)
     (eval-cond-or cs world))
    ;; (>= visits N) — current-node's visit count
    ((list '>= 'visits n)
     (if (>= (visits world (current-node world)) n) 'true 'false))
    ;; (= visits N)
    ((list '= 'visits n)
     (if (== (visits world (current-node world)) n) 'true 'false))
    ;; Unrecognised — total: warn and return false
    (_
     (logger:warning "xs-world: unrecognised condition ~p" (list cond))
     'false)))

(defun eval-cond-and (cs world)
  "Evaluate (and C ...) with short-circuit; bad sub-forms degrade to false."
  (lists:foldl
    (lambda (c acc)
      (if (== acc 'false)
        'false
        (eval-cond c world)))
    'true
    cs))

(defun eval-cond-or (cs world)
  "Evaluate (or C ...) with short-circuit; bad sub-forms degrade to false."
  (lists:foldl
    (lambda (c acc)
      (if (== acc 'true)
        'true
        (eval-cond c world)))
    'false
    cs))
