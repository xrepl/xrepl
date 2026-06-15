(defmodule xs-bundle-tests
  "Unit tests for xs-bundle — load, parse, and validate .xsf bundles.

  All fixtures use neutral, invented node ids (room-a, room-b, etc.).
  No story content; no real narrative words."
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

(defun setup ()
  (application:ensure_all_started 'xrepl)
  'ok)

;;; ----------------
;;; In-test fixture builders
;;; ----------------

(defun make-xsf (manifest-src node-pairs)
  "Build a .xsf binary from LFE source strings.

  manifest-src: char list — the (story ...) source
  node-pairs:   [{filename-string, node-source-string}]"
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

(defun make-xsf-with-images (manifest-src node-pairs image-pairs)
  "Like make-xsf but also includes asset/image entries.

  image-pairs: [{zip-path-string, binary-content}]"
  (let* ((m-entry    (tuple "manifest.lfe" (list_to_binary manifest-src)))
         (n-entries  (lists:map
                       (lambda (p)
                         (tuple (++ "nodes/" (element 1 p))
                                (list_to_binary (element 2 p))))
                       node-pairs))
         (img-entries (lists:map
                        (lambda (p) (tuple (element 1 p) (element 2 p)))
                        image-pairs))
         (entries    (++ (cons m-entry n-entries) img-entries)))
    (case (zip:create "bundle.xsf" entries '(memory))
      (`#(ok #(,_ ,bin)) bin)
      (err (error (tuple 'fixture-failed err))))))

;;; ---- Neutral source strings ----

(defun mfst ()
  "(story (title \"Test Bundle\") (schema \"1.0\") (version \"1\")
          (entry room-a) (protocol \"xrepl\")
          (assets (images-dir \"assets/images\")))")

(defun node-a ()
  "(node (id room-a) (type scene) (title \"Room A\")
         (body \"Desc A.\")
         (choices (choice (cmd \"go\") (to room-b))))")

(defun node-b ()
  "(node (id room-b) (type ending) (title \"Room B\")
         (body \"Desc B.\"))")

;;; ----------------
;;; Good-bundle tests
;;; ----------------

(deftest good-bundle-loads
  "A valid 2-node bundle loads successfully."
  (setup)
  (let ((bin (make-xsf (mfst)
                       (list (tuple "room-a.lfe" (node-a))
                             (tuple "room-b.lfe" (node-b))))))
    (case (xs-bundle:load bin)
      (`#(ok ,bundle)
       ;; entry-node/1
       (is-equal 'room-a (xs-bundle:entry-node bundle))
       ;; manifest/1 has the title
       (is-equal "Test Bundle"
                 (maps:get 'title (xs-bundle:manifest bundle)))
       ;; node/2 — present nodes
       (case (xs-bundle:node bundle 'room-a)
         (`#(ok ,n) (is-equal 'room-a (maps:get 'id n)))
         (_ (is 'false)))
       (case (xs-bundle:node bundle 'room-b)
         (`#(ok ,n) (is-equal 'room-b (maps:get 'id n)))
         (_ (is 'false)))
       ;; node/2 — absent node returns 'error
       (is-equal 'error (xs-bundle:node bundle 'nowhere)))
      (other
       (is-equal (tuple 'expected-ok 'got) other)))))

(deftest node-type-and-choices-stored
  "Node type and choices sub-form are accessible from the loaded node."
  (setup)
  (let ((bin (make-xsf (mfst)
                       (list (tuple "room-a.lfe" (node-a))
                             (tuple "room-b.lfe" (node-b))))))
    (case (xs-bundle:load bin)
      (`#(ok ,bundle)
       (case (xs-bundle:node bundle 'room-a)
         (`#(ok ,n)
          (is-equal 'scene (maps:get 'type n))
          ;; choices is present (raw form kept for xs-engine)
          (is (maps:is_key 'choices n)))
         (_ (is 'false))))
      (_ (is 'false)))))

;;; ----------------
;;; Validation error tests
;;; ----------------

(deftest dangling-to-ref
  "(to missing-node) in a choice returns {error, {dangling, node-id, target}}."
  (setup)
  (let* ((bad-node
           "(node (id room-a) (type scene) (title \"A\") (body \".\")
                  (choices (choice (cmd \"go\") (to nowhere))))")
         (bin (make-xsf (mfst)
                        (list (tuple "room-a.lfe" bad-node)
                              (tuple "room-b.lfe" (node-b))))))
    (case (xs-bundle:load bin)
      (`#(error #(dangling ,_where ,target))
       (is-equal 'nowhere target))
      (other
       (is-equal (tuple 'expected-dangling-error 'got) other)))))

(deftest dangling-entry
  "Manifest entry pointing at a non-existent node returns {error, {dangling, entry, Id}}."
  (setup)
  (let* ((bad-mfst
           "(story (title \"T\") (schema \"1\") (version \"1\")
                   (entry does-not-exist) (protocol \"xrepl\")
                   (assets (images-dir \"assets/images\")))")
         (bin (make-xsf bad-mfst
                        (list (tuple "room-b.lfe" (node-b))))))
    (case (xs-bundle:load bin)
      (`#(error #(dangling entry ,id))
       (is-equal 'does-not-exist id))
      (other
       (is-equal (tuple 'expected-dangling-entry 'got) other)))))

(deftest duplicate-node-id
  "Two node files with the same id atom return {error, {dup-node, Id}}."
  (setup)
  (let ((bin (make-xsf (mfst)
                       (list (tuple "room-a.lfe"  (node-a))
                             (tuple "room-a2.lfe" (node-a)) ;; same id
                             (tuple "room-b.lfe"  (node-b))))))
    (case (xs-bundle:load bin)
      (`#(error #(dup-node ,id))
       (is-equal 'room-a id))
      (other
       (is-equal (tuple 'expected-dup-node 'got) other)))))

(deftest missing-image-warns-but-loads
  "A node (image ...) with no matching asset entry loads; bundle is functional."
  (setup)
  (let* ((node-with-img
           "(node (id room-a) (type scene) (title \"A\") (body \".\")
                  (image \"no-such-img.png\")
                  (choices (choice (cmd \"go\") (to room-b))))")
         ;; No assets/images/no-such-img.png in the zip
         (bin (make-xsf (mfst)
                        (list (tuple "room-a.lfe" node-with-img)
                              (tuple "room-b.lfe" (node-b))))))
    (case (xs-bundle:load bin)
      (`#(ok ,bundle)
       ;; Bundle is functional despite missing image
       (is-equal 'room-a (xs-bundle:entry-node bundle))
       ;; The missing asset is NOT in image-assets
       (let ((img-assets (maps:get 'image-assets bundle (map))))
         (is-not (maps:is_key "no-such-img.png" img-assets))))
      (other
       (is-equal (tuple 'expected-ok-despite-missing-image 'got) other)))))

(deftest known-image-in-image-assets
  "An image file present in the zip appears in image-assets."
  (setup)
  (let* ((node-with-img
           "(node (id room-a) (type scene) (title \"A\") (body \".\")
                  (image \"tile.png\")
                  (choices (choice (cmd \"go\") (to room-b))))")
         (bin (make-xsf-with-images
                (mfst)
                (list (tuple "room-a.lfe" node-with-img)
                      (tuple "room-b.lfe" (node-b)))
                ;; Add the image file to the zip
                (list (tuple "assets/images/tile.png" #"PNG")))))
    (case (xs-bundle:load bin)
      (`#(ok ,bundle)
       ;; tile.png must appear in image-assets
       (let ((img-assets (maps:get 'image-assets bundle (map))))
         (is (maps:is_key "tile.png" img-assets))))
      (other
       (is-equal (tuple 'expected-ok-with-image 'got) other)))))

;;; ----------------
;;; image-bytes/2 tests (slice3)
;;; ----------------

(defun img-bundle-bin ()
  "A bundle with an image asset for testing image-bytes/2."
  (make-xsf-with-images
    (mfst)
    (list (tuple "room-a.lfe" (node-a))
          (tuple "room-b.lfe" (node-b)))
    (list (tuple "assets/images/pic-a.png" #"PNGBYTES"))))

(deftest image-bytes-stem-match
  "image-bytes with stem 'pic-a' resolves 'assets/images/pic-a.png'."
  (setup)
  (case (xs-bundle:load (img-bundle-bin))
    (`#(ok ,bundle)
     ;; Stem match: asset-id without extension
     (is-equal (tuple 'ok #"PNGBYTES")
               (xs-bundle:image-bytes bundle "pic-a")))
    (_ (is 'false))))

(deftest image-bytes-exact-match
  "image-bytes with full filename 'pic-a.png' resolves the same entry."
  (setup)
  (case (xs-bundle:load (img-bundle-bin))
    (`#(ok ,bundle)
     ;; Exact match: full filename including extension
     (is-equal (tuple 'ok #"PNGBYTES")
               (xs-bundle:image-bytes bundle "pic-a.png")))
    (_ (is 'false))))

(deftest image-bytes-missing-returns-error
  "image-bytes for an absent asset id returns 'error."
  (setup)
  (case (xs-bundle:load (img-bundle-bin))
    (`#(ok ,bundle)
     (is-equal 'error (xs-bundle:image-bytes bundle "nope")))
    (_ (is 'false))))
