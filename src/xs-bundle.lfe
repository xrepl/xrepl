(defmodule xs-bundle
  "Load and validate an interactive-fiction bundle from a .xsf zip archive.

  A .xsf bundle contains:
    manifest.lfe      — one (story ...) s-expr
    nodes/**/*.lfe    — one (node ...) s-expr per file
    assets/images/**  — binary image files (bytes fetched lazily by callers)

  xs-bundle indexes and validates structure only. Body, choices, conditions,
  and other sub-forms are kept as raw s-exprs for xs-world/xs-engine.

  Validation failures (return {error,...}):
    {error, {dangling, Where, Id}}   (to/on-success/entry) names missing node
    {error, {dup-node, Id}}          two node files share the same id
    {error, no-entry}                manifest missing (entry ...)
    {error, no-manifest}             zip has no manifest.lfe

  Soft warning (logger:warning, still loads):
    node (image Id) references an asset id not present in the bundle

  DEFERRED: flag-reference validation — checking that (set f …) / (flag? f)
  names a flag declared in (story … (flags …)) requires walking the full
  condition/set grammar, which xs-world owns. It is explicitly NOT done here."
  (export
   (load 1)
   (load-file 1)
   (node 2)
   (entry-node 1)
   (manifest 1)))

;;; ----------------
;;; Public API
;;; ----------------

(defun load (binary)
  "Load a bundle from a .xsf zip binary.

  Args:
    binary: raw .xsf file bytes

  Returns:
    #(ok Bundle) | #(error Reason)"
  (case (zip:zip_open binary '(memory))
    (`#(ok ,handle)
     (let ((result
             (try
               (load-from-handle handle)
               (catch
                 ((tuple _ r _)
                  (tuple 'error (tuple 'load-exception r)))))))
       (zip:zip_close handle)
       result))
    (`#(error ,r)
     (tuple 'error (tuple 'zip-open r)))))

(defun load-file (path)
  "Load a bundle from a .xsf file on disk.

  Args:
    path: filesystem path string or binary

  Returns:
    #(ok Bundle) | #(error Reason)"
  (case (file:read_file path)
    (`#(ok ,binary) (load binary))
    (`#(error ,r)   (tuple 'error (tuple 'read-file r)))))

(defun node (bundle id)
  "Look up a node by its id atom.

  Args:
    bundle: a loaded Bundle map
    id:     node id atom

  Returns:
    #(ok NodeMap) | error"
  (case (maps:get id (maps:get 'nodes bundle (map)) 'missing)
    ('missing 'error)
    (n         (tuple 'ok n))))

(defun entry-node (bundle)
  "Return the entry-node id atom from the manifest.

  Args:
    bundle: a loaded Bundle map

  Returns:
    atom id"
  (maps:get 'entry (maps:get 'manifest bundle (map)) 'undefined))

(defun manifest (bundle)
  "Return the parsed manifest map.

  Args:
    bundle: a loaded Bundle map

  Returns:
    map"
  (maps:get 'manifest bundle (map)))

;;; ----------------
;;; Load implementation
;;; ----------------

(defun load-from-handle (handle)
  "Core load: enumerate entries, parse manifest + nodes, build Bundle."
  (case (zip:zip_list_dir handle)
    (`#(ok ,entries)
     (let* ((names      (zip-filenames entries))
            (node-names (lists:filter
                          (lambda (n)
                            (andalso
                              (=/= 'nomatch (string:prefix n "nodes/"))
                              (== ".lfe" (filename:extension n))))
                          names))
            (img-names  (lists:filter
                          (lambda (n)
                            (andalso
                              (=/= 'nomatch
                                   (string:prefix n "assets/images/"))
                              (=/= "" (filename:extension n))))
                          names)))
       (if (not (lists:member "manifest.lfe" names))
         (tuple 'error 'no-manifest)
         (case (read-zip-lfe handle "manifest.lfe")
           (`#(ok ,mform)
            (let* ((mmap       (parse-story mform))
                   (images-dir (maps:get 'images-dir
                                         (maps:get 'assets mmap (map))
                                         "assets/images"))
                   (img-pfx    (++ images-dir "/"))
                   (asset-ids  (lists:filtermap
                                 (lambda (n)
                                   (case (string:prefix n img-pfx)
                                     ('nomatch 'false)
                                     (rest     (tuple 'true rest))))
                                 img-names))
                   (img-assets (lists:foldl
                                 (lambda (id m) (maps:put id 'true m))
                                 (map)
                                 asset-ids)))
              (case (parse-node-files handle node-names)
                (`#(ok ,nodes)
                 (case (validate mmap nodes img-assets)
                   ('ok
                    (tuple 'ok
                           (map 'manifest    mmap
                                'nodes       nodes
                                'flags       (maps:get 'flags mmap '())
                                'images-dir  images-dir
                                'image-assets img-assets)))
                   (`#(error ,r)
                    (tuple 'error r))))
                (`#(error ,r) (tuple 'error r)))))
           (`#(error ,r)
            (tuple 'error (tuple 'manifest-parse r)))))))
    (`#(error ,r)
     (tuple 'error (tuple 'zip-list r)))))

(defun zip-filenames (entries)
  "Extract filename strings from zip directory entries.

  zip_file record: {zip_file, Name, Info, Comment, Offset, CompSize}"
  (lists:filtermap
    (lambda (entry)
      (case entry
        ((tuple 'zip_file name _ _ _ _) (tuple 'true name))
        (_ 'false)))
    entries))

(defun read-zip-lfe (handle name)
  "Read a .lfe entry from the zip handle; return the first parsed form."
  (case (zip:zip_get name handle)
    (`#(ok #(,_ ,binary))
     (case (lfe_io:read_string (binary_to_list binary))
       (`#(ok ,forms)
        (case forms
          ((cons form _) (tuple 'ok form))
          ('()           (tuple 'error (tuple 'empty-lfe name)))))
       ;; lfe_io:read_string returns {error, Info} — 2-tuple (not 3)
       (`#(error ,r) (tuple 'error (tuple 'lfe-parse name r)))))
    (`#(error ,r)
     (tuple 'error (tuple 'zip-get name r)))))

(defun parse-node-files (handle names)
  "Parse all node .lfe files into #{id => NodeMap}, or first error."
  (lists:foldl
    (lambda (name acc)
      (case acc
        (`#(error ,_) acc)
        (`#(ok ,nodes)
         (case (read-zip-lfe handle name)
           (`#(ok ,form)
            (case (parse-node form)
              (`#(ok ,nmap)
               (let ((id (maps:get 'id nmap 'undefined)))
                 (if (maps:is_key id nodes)
                   (tuple 'error (tuple 'dup-node id))
                   (tuple 'ok (maps:put id nmap nodes)))))
              (`#(error ,r)
               (tuple 'error r))))
           (`#(error ,r)
            (tuple 'error r))))))
    (tuple 'ok (map))
    names))

;;; ----------------
;;; Parsing
;;; ----------------

(defun parse-story (form)
  "Parse a (story ...) form into a map."
  (case form
    ((cons 'story kv) (parse-keyword-list kv))
    (_                (map))))

(defun parse-node (form)
  "Parse a (node ...) form into {ok, NodeMap} | {error, Reason}."
  (case form
    ((cons 'node kv)
     (let ((nmap (parse-keyword-list kv)))
       (case (maps:get 'id nmap 'undefined)
         ('undefined (tuple 'error 'node-missing-id))
         (_          (tuple 'ok nmap)))))
    (_
     (tuple 'error (tuple 'unexpected-node-form form)))))

(defun parse-keyword-list (pairs)
  "Convert a keyword list ((key val …) …) into a map.

  Pattern order matters:
    (flags …)  → list of flag-definition maps
    (assets …) → recursively parsed sub-map
    (key val)  → single value stored directly
    (key v1 …) → value list stored (multi-value or sub-forms)"
  (lists:foldl
    (lambda (pair acc)
      (case pair
        ((cons 'flags flag-forms)
         (maps:put 'flags (parse-flags flag-forms) acc))
        ((cons 'assets sub)
         (maps:put 'assets (parse-keyword-list sub) acc))
        ((list key val)
         (maps:put key val acc))
        ((cons key vals)
         (maps:put key vals acc))
        (_ acc)))
    (map)
    pairs))

(defun parse-flags (flag-forms)
  "Parse ((flag ...) ...) into a list of flag-definition maps."
  (lists:filtermap
    (lambda (f)
      (case f
        ((cons 'flag kv) (tuple 'true (parse-keyword-list kv)))
        (_               'false)))
    flag-forms))

;;; ----------------
;;; Validation
;;; ----------------

(defun validate (mmap nodes img-assets)
  "Run all validations. Returns 'ok or {error, Reason}."
  (case (validate-entry mmap nodes)
    ('ok
     (case (validate-node-refs nodes)
       ('ok
        (validate-image-warnings nodes img-assets)
        'ok)
       (err err)))
    (err err)))

(defun validate-entry (mmap nodes)
  "Check that the manifest (entry ...) atom names an existing node."
  (case (maps:get 'entry mmap 'undefined)
    ('undefined
     (tuple 'error 'no-entry))
    (entry-id
     (if (maps:is_key entry-id nodes)
       'ok
       (tuple 'error (tuple 'dangling 'entry entry-id))))))

(defun validate-node-refs (nodes)
  "Check every (to ...) and (on-success ...) across all nodes."
  (maps:fold
    (lambda (node-id nmap acc)
      (case acc
        (`#(error ,_) acc)
        ('ok
         (let* ((raw-ch     (maps:get 'choices nmap '()))
                (on-succ    (maps:get 'on-success nmap 'none))
                (to-ids     (collect-to-targets raw-ch))
                (refs       (if (== on-succ 'none)
                              to-ids
                              (cons on-succ to-ids))))
           (check-refs node-id refs nodes)))))
    'ok
    nodes))

(defun check-refs (node-id refs nodes)
  "Assert every id in refs exists in nodes."
  (lists:foldl
    (lambda (target acc)
      (case acc
        (`#(error ,_) acc)
        ('ok
         (if (maps:is_key target nodes)
           'ok
           (tuple 'error (tuple 'dangling node-id target))))))
    'ok
    refs))

(defun validate-image-warnings (nodes img-assets)
  "Log a warning for any node whose (image ...) asset is absent from the zip."
  (maps:foreach
    (lambda (node-id nmap)
      (case (maps:get 'image nmap 'none)
        ('none 'ok)
        (img-id
         (if (maps:is_key img-id img-assets)
           'ok
           (logger:warning
             "xs-bundle: node ~p references image ~p not in bundle"
             (list node-id img-id))))))
    nodes))

;;; ----------------
;;; Ref-finding helpers
;;; ----------------

(defun collect-to-targets (choices-val)
  "Collect all (to <id>) target atoms from the raw choices value.

  Handles three shapes produced by parse-keyword-list:
    '()                       — no choices
    (choice (cmd ..) (to X))  — single choice stored bare (2-elem list case)
    ((choice ..) (choice ..)) — list of multiple choice forms"
  (case choices-val
    ('() '())
    ;; Single bare choice form: choices-val IS the choice (head = 'choice)
    ((cons 'choice parts)
     (to-targets-in-parts parts))
    ;; List whose first element is a choice form
    ((cons (cons 'choice parts) rest)
     (++ (to-targets-in-parts parts)
         (collect-to-targets rest)))
    ;; Non-choice element — skip and continue
    ((cons _ rest)
     (collect-to-targets rest))))

(defun to-targets-in-parts (parts)
  "Extract (to <id>) atoms from the key-value parts of one choice form."
  (lists:filtermap
    (lambda (p)
      (case p
        ((list 'to target) (tuple 'true target))
        (_ 'false)))
    parts))
