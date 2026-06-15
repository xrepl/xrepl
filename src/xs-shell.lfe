(defmodule xs-shell
  "xrepl-shell behaviour implementation that drives xs-engine over a bundle.

  Enter a node → show the room → take a command → move rooms → reach an
  ending → return to the LFE shell. Pure except for engine calls; no IO,
  no zip, no image bytes (those are a later slice).

  Deferred (not built here):
    Images: #(image Id) → real bytes via xrepl-term-graphics:render-data/2
    Save/resume: /quit→/game world persistence in session metadata (slice2)
    Env preservation: switching back to LFE uses a fresh env (#m()); the
      player's LFE bindings are not stashed/restored in v1."
  (behaviour xrepl-shell)
  (export
   (start 1)
   (init 1)
   (eval 3)
   (describe 1)
   (snapshot 1)
   (save 1)
   (resume 2)
   (prompt 1)))

;;; ----------------
;;; Shell state
;;; ----------------

(defrecord xs-shell-state
  bundle  ;; xs-bundle Bundle map (reloadable; not persisted in snapshot)
  world)  ;; xs-world World map (pure data; persisted in snapshot)

;;; ----------------
;;; start/1 — load a bundle and enter the opening room
;;; ----------------

(defun start (binary-or-path)
  "Load a .xsf bundle and enter the opening node.

  Args:
    binary-or-path: the raw .xsf bytes (binary) OR a filesystem path

  Returns:
    #(ok ShellState RenderedOpening) | #(error Reason)"
  (let ((load-result
          (if (is_binary binary-or-path)
            (xs-bundle:load binary-or-path)
            (xs-bundle:load-file binary-or-path))))
    (case load-result
      (`#(ok ,bundle)
       (let* ((mfst    (xs-bundle:manifest bundle))
              (world0  (xs-world:new mfst))
              (w0      (xs-world:set-node world0 (xs-bundle:entry-node bundle)))
              (entry-id (xs-bundle:entry-node bundle)))
         (case (xs-bundle:node bundle entry-id)
           (`#(ok ,nd)
            (let* ((`#(,w1 ,outs) (xs-engine:enter nd w0))
                   (opening       (join-texts (flatten-texts outs))))
              ;; Render opening room images best-effort (slice3)
              (render-images bundle (flatten-image-ids outs))
              (tuple 'ok
                     (make-xs-shell-state bundle bundle world w1)
                     opening)))
           ('error
            (tuple 'error (tuple 'missing-entry entry-id))))))
      (`#(error ,r)
       (tuple 'error r)))))

;;; ----------------
;;; Behaviour callbacks
;;; ----------------

(defun init (opts)
  "Adopt a pre-built shell state from xs:run.

  xs:run calls xs-shell:start, then returns {xrepl-switch-shell, xs-shell,
  #m(state State), Response} so the opening room reaches the player via
  the switch Response without an extra init round-trip.

  Args:
    opts: map with key 'state -> ShellState

  Returns:
    #(ok ShellState) | #(error no-state)"
  (case (maps:get 'state opts 'undefined)
    ('undefined (tuple 'error 'no-state))
    (state      (tuple 'ok state))))

(defun eval (input shell-state ctx)
  "Process one player command through xs-engine.

  Normalises Input (lowercase + trim), runs xs-engine:handle on the
  current node, folds the Output list (text/stream accumulated; goto
  triggers enter which adds more outputs; done/suspend triggers a shell
  switch back to xrepl-shell-lfe).

  Args:
    input:       raw input — binary, char list, or any term
    shell-state: xs-shell-state record
    ctx:         session context (unused in slice1)

  Returns:
    #(ok #(formatted Bin) ShellState2)                  - normal turn
    #(switch-shell xrepl-shell-lfe #m() #(formatted B)) - story ended/suspended"
  (let* ((bundle     (xs-shell-state-bundle shell-state))
         (world      (xs-shell-state-world  shell-state))
         (nd-id      (xs-world:current-node world))
         (input-bin  (normalize-input input))
         (session-id (maps:get 'session-id ctx 'undefined)))
    ;; Intercept quit/exit BEFORE engine — save world and leave story
    (if (orelse (== input-bin #"quit") (== input-bin #"exit"))
      (progn
        (save-to-session session-id world)
        (tuple 'switch-shell 'xrepl-shell-lfe (map)
               (tuple 'formatted #"Progress saved. Until next time.")))
      ;; Normal engine path
      (case (xs-bundle:node bundle nd-id)
        (`#(ok ,nd)
         (let* ((`#(,w1 ,outs) (xs-engine:handle nd input-bin world))
                (`#(,w2 ,texts ,image-ids ,terminal)
                 (process-outputs outs bundle w1 '() '() 'none))
                (output-bin (join-texts texts))
                (state2     (make-xs-shell-state bundle bundle world w2)))
           ;; Render images best-effort before returning text response
           (render-images bundle image-ids)
           (if (=/= terminal 'none)
             (progn
               ;; done → clear the save; suspend → save current world
               (if (== terminal 'done)
                 (clear-session-save session-id)
                 (save-to-session session-id w2))
               (tuple 'switch-shell 'xrepl-shell-lfe (map)
                      (tuple 'formatted output-bin)))
             (tuple 'ok (tuple 'formatted output-bin) state2))))
        ('error
         ;; Current node missing from bundle — degenerate state
         (tuple 'ok
                (tuple 'formatted #"(The story state is lost.)")
                shell-state))))))

(defun describe (_shell-state)
  "Return the xs-shell capability map.

  Returns:
    map with atom keys: name, kind, prompt"
  (map 'name #"xs" 'kind #"story" 'prompt #"> "))

(defun save (shell-state)
  "Return the world map — the save blob (pure data, serializable).

  The bundle is excluded (it is reloadable from the .xsf file).

  Args:
    shell-state: xs-shell-state record

  Returns:
    World map"
  (xs-shell-state-world shell-state))

(defun snapshot (shell-state)
  "Return the world map for xrepl session persistence (delegates to save/1).

  Returns:
    World map"
  (save shell-state))

(defun resume (saved-world bundle)
  "Rebuild shell state from a saved world + a freshly loaded bundle.

  Renders the current room WITHOUT applying on-enter or bumping the visit
  (the player is resuming mid-play, not re-entering). If the saved current
  node is absent from the bundle (stale save), returns {error, stale-save}.

  Args:
    saved-world: World map from a prior save/1 call
    bundle:      freshly loaded xs-bundle Bundle map

  Returns:
    #(ok ShellState RenderedRoom) | #(error stale-save)"
  (let ((nd-id (xs-world:current-node saved-world)))
    (case (xs-bundle:node bundle nd-id)
      ('error
       (tuple 'error 'stale-save))
      (`#(ok ,nd)
       (let* ((room-outs (xs-engine:render-room nd saved-world))
              (room-bin  (join-texts (flatten-texts room-outs)))
              (state     (make-xs-shell-state bundle bundle
                                              world  saved-world)))
         ;; Render resumed room images best-effort (slice3)
         (render-images bundle (flatten-image-ids room-outs))
         (tuple 'ok state room-bin))))))

(defun prompt (_shell-state)
  "Return the xs-shell prompt binary.

  Returns:
    binary"
  #"> ")

;;; ----------------
;;; Output processing
;;; ----------------

(defun process-outputs (outs bundle world acc-texts acc-images terminal)
  "Fold a list of xs-engine Outputs into {World2, Texts, ImageIds, Terminal}.

  goto: load + enter the target node; fold its outputs first (prepend).
  done/suspend: mark terminal (story over, return to LFE shell).
  image: collect the asset id for lazy rendering in eval/3.
  text/stream: accumulated (in order; reversed by caller).

  Returns:
    #(World2 TextsInOrder ImageIdsInOrder Terminal)"
  (case outs
    ('()
     (tuple world (lists:reverse acc-texts) (lists:reverse acc-images) terminal))
    ((cons out rest)
     (case out
       (`#(text ,bin)
        (process-outputs rest bundle world (cons bin acc-texts) acc-images terminal))
       (`#(stream ,bin)
        (process-outputs rest bundle world (cons bin acc-texts) acc-images terminal))
       (`#(image ,img-id)
        ;; Collect image id; bytes are rendered best-effort in eval/3
        (process-outputs rest bundle world acc-texts (cons img-id acc-images) terminal))
       (`#(goto ,nd-id)
        (let ((w1 (xs-world:set-node world nd-id)))
          (case (xs-bundle:node bundle nd-id)
            (`#(ok ,nd)
             (let* ((`#(,w2 ,enter-outs) (xs-engine:enter nd w1)))
               ;; Prepend enter-outs so they appear before remaining rest
               (process-outputs (++ enter-outs rest) bundle w2
                                acc-texts acc-images terminal)))
            ('error
             ;; Unknown node id — skip goto
             (process-outputs rest bundle world acc-texts acc-images terminal)))))
       ('done
        (process-outputs rest bundle world acc-texts acc-images 'done))
       ('suspend
        (process-outputs rest bundle world acc-texts acc-images 'suspend))
       (_
        (process-outputs rest bundle world acc-texts acc-images terminal))))))

;;; ----------------
;;; Helpers
;;; ----------------

(defun normalize-input (input)
  "Convert raw player input to a lowercased, trimmed binary."
  (let ((s (cond
              ((is_binary input) (binary_to_list input))
              ((is_list input)   input)
              ('true             (io_lib:format "~p" (list input))))))
    (list_to_binary (string:strip (string:to_lower s)))))

(defun flatten-texts (outs)
  "Extract text/stream binaries from an Output list (in order)."
  (lists:filtermap
    (lambda (o)
      (case o
        (`#(text ,bin)   (tuple 'true bin))
        (`#(stream ,bin) (tuple 'true bin))
        (_ 'false)))
    outs))

(defun flatten-image-ids (outs)
  "Extract image asset ids from an Output list (in order)."
  (lists:filtermap
    (lambda (o)
      (case o
        (`#(image ,id) (tuple 'true id))
        (_ 'false)))
    outs))

(defun render-images (bundle image-ids)
  "Render each image id best-effort via xrepl-term-graphics:render-data/2.

  Missing images and non-graphics terminals are silently skipped so a
  failing render never breaks the text response (text always wins).
  In-process/local transport only — remote delivery is deferred."
  (lists:foreach
    (lambda (id)
      (case (xs-bundle:image-bytes bundle id)
        (`#(ok ,bin)
         (try
           (xrepl-term-graphics:render-data bin
                                             (map 'name (list_to_binary id)))
           (catch
             ;; Non-graphics terminal or other render error: skip silently
             ((tuple _ _ _) 'ok))))
        ('error 'ok)))  ;; missing image: skip
    image-ids))

(defun join-texts (texts)
  "Join text binaries with newlines into one binary (portable to OTP 25+).

  lists:join/2 is OTP-19+; iolist_to_binary/1 is ancient. Replaces
  binary:join/2 which is OTP-28+ only. Handles empty/single/multi uniformly."
  (iolist_to_binary (lists:join #"\n" texts)))

;;; ----------------
;;; Session save helpers (Phase B)
;;; ----------------

(defun save-to-session (session-id world)
  "Write World to session metadata under 'xs-save.
  No-op when session-id is 'undefined (no session context).

  Uses xrepl-store:set-metadata/2 which merges, so this adds/updates
  the 'xs-save key without touching other metadata."
  (if (=/= session-id 'undefined)
    (xrepl-store:set-metadata session-id (map 'xs-save world))
    'ok))

(defun clear-session-save (session-id)
  "Mark the save slot as empty (story ended cleanly — done output).
  Sets 'xs-save to 'none rather than removing the key (set-metadata
  merges; remove would require update-session). xs:run treats 'none
  the same as absent.
  No-op when session-id is 'undefined."
  (if (=/= session-id 'undefined)
    (xrepl-store:set-metadata session-id (map 'xs-save 'none))
    'ok))
