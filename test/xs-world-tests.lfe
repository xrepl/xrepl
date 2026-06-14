(defmodule xs-world-tests
  "Unit tests for xs-world — state operations and total condition evaluator.

  Fixtures use neutral invented ids (room-a, room-b, has-rock, bearing).
  No story content."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

(defun setup () 'ok)

;;; ----------------
;;; Fixture helpers
;;; ----------------

(defun test-manifest ()
  "Minimal manifest map as xs-bundle would produce."
  (map 'entry 'room-a
       'flags (list (map 'id 'has-rock 'type 'bool 'default 'false)
                    (map 'id 'bearing  'type 'bool 'default 'false))))

(defun fresh-world ()
  "A new world seeded from test-manifest."
  (xs-world:new (test-manifest)))

(defun cond-world ()
  "World for condition tests: has-rock=true, current=room-a, room-a visits=2."
  (let* ((w0 (fresh-world))
         (w1 (xs-world:set-flag   w0 'has-rock 'true))
         (w2 (xs-world:set-node   w1 'room-a))
         (w3 (xs-world:bump-visit w2 'room-a))
         (w4 (xs-world:bump-visit w3 'room-a)))
    w4))

;;; ----------------
;;; new/1 and current-node/1
;;; ----------------

(deftest new-seeds-flag-defaults
  "new/1 sets each flag to its manifest default."
  (setup)
  (let ((w (fresh-world)))
    (is-equal 'false (xs-world:flag w 'has-rock))
    (is-equal 'false (xs-world:flag w 'bearing))))

(deftest new-sets-entry-node
  "new/1 sets current-node to the manifest entry."
  (setup)
  (let ((w (fresh-world)))
    (is-equal 'room-a (xs-world:current-node w))))

(deftest new-visits-empty
  "new/1 starts with zero visits for every node."
  (setup)
  (let ((w (fresh-world)))
    (is-equal 0 (xs-world:visits w 'room-a))
    (is-equal 0 (xs-world:visits w 'room-b))))

(deftest new-items-empty
  "new/1 starts with an empty inventory."
  (setup)
  (let ((w (fresh-world)))
    (is-not (xs-world:has-item w 'widget))))

;;; ----------------
;;; set-node / current-node
;;; ----------------

(deftest set-node-round-trips
  "set-node/2 updates current-node/1."
  (setup)
  (let* ((w0 (fresh-world))
         (w1 (xs-world:set-node w0 'room-b)))
    (is-equal 'room-b (xs-world:current-node w1))
    ;; original unchanged
    (is-equal 'room-a (xs-world:current-node w0))))

;;; ----------------
;;; flag / set-flag
;;; ----------------

(deftest flag-set-flag-round-trip
  "set-flag/3 and flag/2 round-trip; unknown flag defaults to false."
  (setup)
  (let* ((w0 (fresh-world))
         (w1 (xs-world:set-flag w0 'has-rock 'true))
         (w2 (xs-world:set-flag w1 'bearing  'true)))
    ;; Set values
    (is-equal 'true  (xs-world:flag w2 'has-rock))
    (is-equal 'true  (xs-world:flag w2 'bearing))
    ;; Reset to false
    (let ((w3 (xs-world:set-flag w2 'has-rock 'false)))
      (is-equal 'false (xs-world:flag w3 'has-rock)))
    ;; Unknown flag
    (is-equal 'false (xs-world:flag w2 'no-such-flag))))

;;; ----------------
;;; visits / bump-visit
;;; ----------------

(deftest visits-start-at-zero
  "visits/2 returns 0 for any unvisited node."
  (setup)
  (let ((w (fresh-world)))
    (is-equal 0 (xs-world:visits w 'room-a))
    (is-equal 0 (xs-world:visits w 'room-b))))

(deftest bump-visit-increments
  "bump-visit/2 increments the count; successive bumps accumulate."
  (setup)
  (let* ((w0 (fresh-world))
         (w1 (xs-world:bump-visit w0 'room-a))
         (w2 (xs-world:bump-visit w1 'room-a)))
    (is-equal 1 (xs-world:visits w1 'room-a))
    (is-equal 2 (xs-world:visits w2 'room-a))))

(deftest bump-visit-per-node-isolation
  "Bumping room-a does not affect room-b's count."
  (setup)
  (let* ((w0 (fresh-world))
         (w1 (xs-world:bump-visit w0 'room-a)))
    (is-equal 1 (xs-world:visits w1 'room-a))
    (is-equal 0 (xs-world:visits w1 'room-b))))

;;; ----------------
;;; items
;;; ----------------

(deftest add-item-has-item-round-trip
  "add-item/2 and has-item/2 round-trip; absent item returns false."
  (setup)
  (let* ((w0 (fresh-world))
         (w1 (xs-world:add-item w0 'widget)))
    (is      (xs-world:has-item w1 'widget))
    (is-not  (xs-world:has-item w1 'gadget))
    (is-not  (xs-world:has-item w0 'widget)))) ;; original unchanged

;;; ----------------
;;; eval-cond — one assertion per grammar form
;;; ----------------

(deftest eval-cond-flag-truthy
  "(flag? has-rock) returns true when has-rock = true."
  (setup)
  (let ((w (cond-world)))
    (is-equal 'true (xs-world:eval-cond '(flag? has-rock) w))))

(deftest eval-cond-flag-falsy
  "(flag? bearing) returns false when bearing = false."
  (setup)
  (let ((w (cond-world)))
    (is-equal 'false (xs-world:eval-cond '(flag? bearing) w))))

(deftest eval-cond-not
  "(not ...) negates the sub-condition."
  (setup)
  (let ((w (cond-world)))
    (is-equal 'false (xs-world:eval-cond '(not (flag? has-rock)) w))
    (is-equal 'true  (xs-world:eval-cond '(not (flag? bearing))  w))))

(deftest eval-cond-and-all-true
  "(and ...) returns true when all sub-conditions are true."
  (setup)
  (let ((w (cond-world)))
    (is-equal 'true (xs-world:eval-cond '(and true true) w))
    (is-equal 'true (xs-world:eval-cond '(and (flag? has-rock) true) w))))

(deftest eval-cond-and-one-false
  "(and ...) returns false when any sub-condition is false."
  (setup)
  (let ((w (cond-world)))
    (is-equal 'false
              (xs-world:eval-cond '(and (flag? has-rock) (flag? bearing)) w))))

(deftest eval-cond-or
  "(or ...) returns true when any sub-condition is true."
  (setup)
  (let ((w (cond-world)))
    (is-equal 'true
              (xs-world:eval-cond '(or (flag? bearing) (flag? has-rock)) w))
    (is-equal 'false
              (xs-world:eval-cond '(or (flag? bearing) false) w))))

(deftest eval-cond-visits-gte
  "(>= visits N) checks current-node visit count."
  (setup)
  ;; cond-world: room-a has 2 visits, current-node = room-a
  (let ((w (cond-world)))
    (is-equal 'true  (xs-world:eval-cond '(>= visits 2) w))
    (is-equal 'true  (xs-world:eval-cond '(>= visits 1) w))
    (is-equal 'false (xs-world:eval-cond '(>= visits 3) w))))

(deftest eval-cond-visits-eq
  "(= visits N) checks current-node visit count for exact equality."
  (setup)
  (let ((w (cond-world)))
    (is-equal 'true  (xs-world:eval-cond '(= visits 2) w))
    (is-equal 'false (xs-world:eval-cond '(= visits 1) w))))

(deftest eval-cond-literals
  "Literal true/false atoms evaluate to themselves."
  (setup)
  (let ((w (fresh-world)))
    (is-equal 'true  (xs-world:eval-cond 'true  w))
    (is-equal 'false (xs-world:eval-cond 'false w))))

;;; ----------------
;;; Totality tests
;;; ----------------

(deftest eval-cond-unknown-form-returns-false
  "An unrecognised list form returns false without crashing."
  (setup)
  (let ((w (fresh-world)))
    (is-equal 'false (xs-world:eval-cond '(bogus-form 1 2) w))))

(deftest eval-cond-non-list-atom-returns-false
  "A bare unrecognised atom (not true/false) returns false."
  (setup)
  (let ((w (fresh-world)))
    (is-equal 'false (xs-world:eval-cond 'whatever w))))

(deftest eval-cond-bad-subform-degrades-gracefully
  "A bad sub-form inside (and ...) returns false, not a crash."
  (setup)
  (let ((w (cond-world)))
    ;; (and (flag? has-rock) (broken 99)) — broken sub-form degrades to false
    (is-equal 'false
              (xs-world:eval-cond '(and (flag? has-rock) (broken 99)) w))))
