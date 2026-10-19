;;;; Private bounded native ownership records, shared with owned-peer tests.
(defrecord registry
  (boot #b() (binary))
  (last-lease 0 (non_neg_integer))
  (leases (map) (map))
  (contexts (map) (map))
  (sids (map) (map)))

(defrecord lease
  (owner 'undefined (UNION 'undefined (pid)))
  (monitor 'undefined (UNION 'undefined (reference)))
  (authority #b() (binary))
  (last-ticket 0 (non_neg_integer)))

(defrecord context
  (pid 'undefined (UNION 'undefined (pid)))
  (monitor 'undefined (UNION 'undefined (reference)))
  (lease 0 (non_neg_integer))
  (sid #b() (binary))
  (generation #b() (binary))
  (ticket 0 (non_neg_integer))
  (socket 'undefined (UNION 'undefined (port))))
