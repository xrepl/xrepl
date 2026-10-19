;;;; Pure byte- and depth-bounded native value previews.
(defmodule cayrn-lfe-preview
  "Render native terms without materializing unbounded representations."
  (export (render 1)))

(defspec (render 1) (((term)) (tuple (binary) (boolean))))
(defun render (value)
  "Return at most 8192 UTF-8 bytes and an explicit budget-omission report."
  (let (((tuple 'fit data _used omitted) (attempt value 8192 32)))
    (tuple (iolist_to_binary data) omitted)))

;;; Scalar conversions have bounded inputs or an explicit preconversion fence.
(defun attempt
  ((_value remaining _depth) (when (=< remaining 0)) 'no_fit)
  (('() remaining _depth) (scalar #b("()") remaining))
  ((value remaining _depth) (when (is_atom value))
   (scalar (unicode:characters_to_binary (lfe_io_write:symbol value))
           remaining))
  ((value remaining _depth) (when (is_integer value))
   (integer value remaining))
  ((value remaining _depth) (when (is_float value))
   (scalar (unicode:characters_to_binary (io_lib_format:fwrite_g value))
           remaining))
  (((= (cons _ _) value) remaining depth)
   (if (short-string? value 256)
     (scalar (unicode:characters_to_binary (lfe_io_write:string value 34))
             remaining)
     (compound #b("(") (tuple 'list value) remaining depth)))
  ((value remaining depth) (when (is_tuple value))
   (if (=:= 0 (tuple_size value))
     (scalar #b("#()") remaining)
     (compound #b("#(") (tuple 'tuple value 1) remaining depth)))
  ((value remaining depth) (when (is_map value))
   (if (=:= 0 (map_size value))
     (scalar #b("#M()") remaining)
     (compound #b("#M(") (tuple 'map (maps:next (maps:iterator value)))
               remaining depth)))
  ((value remaining depth) (when (is_binary value) (=< (byte_size value) 256))
   (case (unicode:characters_to_list value)
     (chars (when (is_list chars))
      (if (io_lib:printable_unicode_list chars)
        (scalar (unicode:characters_to_binary
                  (list 35 (lfe_io_write:string chars 34))) remaining)
        (compound #b("#B(") (tuple 'bits value) remaining depth)))
     (_ (compound #b("#B(") (tuple 'bits value) remaining depth))))
  ((value remaining depth) (when (is_bitstring value))
   (compound #b("#B(") (tuple 'bits value) remaining depth))
  ((value remaining _depth) (when (is_pid value))
   (scalar (iolist_to_binary (list "#Pid" (pid_to_list value))) remaining))
  ((value remaining _depth) (when (is_port value))
   (scalar (list_to_binary (erlang:port_to_list value)) remaining))
  ((value remaining _depth) (when (is_reference value))
   (scalar (list_to_binary (erlang:ref_to_list value)) remaining))
  ((value remaining _depth) (when (is_function value))
   (scalar (function-text value) remaining)))

(defun scalar (text remaining)
  (if (=< (byte_size text) remaining)
    (tuple 'fit text (byte_size text) 'false)
    (omission remaining)))

(defun omission
  ((remaining) (when (>= remaining 3)) (tuple 'fit #b("...") 3 'true))
  ((_remaining) 'no_fit))

(defun integer (value remaining)
  (let ((threshold (bsl 1 (* 4 remaining))))
    (if (orelse (>= value threshold) (=< value (- threshold)))
      (omission remaining)
      ;; Only this fenced value is converted, at most 2*remaining+1 bytes.
      (scalar (integer_to_binary value) remaining))))

(defun short-string?
  (('() _left) 'true)
  ((_value 0) 'false)
  (((cons head tail) left) (when (is_integer head))
   (andalso (short-string? tail (- left 1))
            ;; Validate only the bounded prefix, never the original long list.
            (io_lib:printable_unicode_list (list head))))
  ((_value _left) 'false))

(defun function-text (function)
  (let* (((tuple 'arity arity) (erlang:fun_info function 'arity))
         ((tuple 'type type) (erlang:fun_info function 'type)))
    (case type
      ('external
       (let (((tuple 'module module) (erlang:fun_info function 'module))
             ((tuple 'name name) (erlang:fun_info function 'name)))
         (unicode:characters_to_binary
           (list "(function " (lfe_io_write:symbol module) " "
                 (lfe_io_write:symbol name) " " (integer_to_list arity) ")"))))
      ('local
       (unicode:characters_to_binary
         (list (lists:droplast (erlang:fun_to_list function)) "/"
               (integer_to_list arity) ">"))))))

;;; Every compound reserves its closer and a whole omission before descending.
(defun compound
  ((_prefix _cursor remaining 0) (omission remaining))
  ((prefix cursor remaining depth)
   (let ((overhead (+ (byte_size prefix) 1)))
     (if (< remaining (+ overhead 3))
       'no_fit
       (case (sequence cursor (- remaining overhead) (- depth 1)
                       '() 0 'false #b())
         ((tuple 'fit body used omitted)
          (tuple 'fit (list prefix body #b(")")) (+ overhead used) omitted))
         ('no_fit 'no_fit))))))

(defun sequence
  ((cursor _remaining _depth acc used omitted _separator)
   (when (=:= cursor 'done))
   (tuple 'fit (lists:reverse acc) used omitted))
  ((cursor remaining depth acc used omitted separator)
   (let* (((tuple item rest) (step cursor))
          (separator-size (byte_size separator))
          (reserve (remainder-reserve rest)))
     (if (< remaining (+ separator-size reserve))
       (omit-rest separator remaining acc used)
       (case (item-attempt item (- remaining separator-size reserve) depth)
         ('no_fit (omit-rest separator remaining acc used))
         ((tuple 'fit text size child-omitted)
          (sequence rest (- remaining separator-size size) depth
                    (cons text (cons separator acc))
                    (+ used separator-size size) (orelse omitted child-omitted)
                    (separator-for rest))))))))

(defun omit-rest (separator remaining acc used)
  (let ((size (+ (byte_size separator) 3)))
    (if (>= remaining size)
      (tuple 'fit (lists:reverse (cons #b("...") (cons separator acc)))
             (+ used size) 'true)
      'no_fit)))

(defun remainder-reserve
  (('done) 0)
  ((cursor) (+ (byte_size (separator-for cursor)) 3)))

(defun separator-for
  (((tuple 'list tail)) (when (not (is_list tail))) #b(" . "))
  ((_cursor) #b(" ")))

(defun list-cursor
  (('()) 'done)
  ((tail) (tuple 'list tail)))

(defun tuple-cursor (value index)
  (if (> index (tuple_size value)) 'done (tuple 'tuple value index)))

(defun map-cursor
  (('none) 'done)
  ((entry) (tuple 'map entry)))

(defun bits-cursor
  ((#b()) 'done)
  ((tail) (tuple 'bits tail)))

(defun step
  (((tuple 'list (cons head tail)))
   (tuple (tuple 'value head) (list-cursor tail)))
  (((tuple 'list tail)) (tuple (tuple 'value tail) 'done))
  (((tuple 'tuple value index))
   (tuple (tuple 'value (element index value))
          (tuple-cursor value (+ index 1))))
  (((tuple 'map (tuple key value iterator)))
   (tuple (tuple 'pair key value) (map-cursor (maps:next iterator))))
  (((tuple 'bits (binary (byte (size 8)) (tail bitstring))))
   (tuple (tuple 'value byte) (bits-cursor tail)))
  (((tuple 'bits tail))
   (let* ((size (bit_size tail))
          ((binary (value (size size))) tail))
     (tuple (tuple 'raw
              (iolist_to_binary (list "(" (integer_to_binary value)
                                     " (size " (integer_to_binary size) "))")))
            'done))))

(defun item-attempt
  (((tuple 'value value) remaining depth) (attempt value remaining depth))
  (((tuple 'raw text) remaining _depth) (scalar text remaining))
  (((tuple 'pair key value) remaining depth)
   (if (< remaining 4)
     'no_fit
     (case (attempt key (- remaining 4) depth)
       ('no_fit 'no_fit)
       ((tuple 'fit key-text key-size key-omitted)
        (case (attempt value (- remaining key-size 1) depth)
          ('no_fit 'no_fit)
          ((tuple 'fit value-text value-size value-omitted)
           (tuple 'fit (list key-text #b(" ") value-text)
                  (+ key-size 1 value-size)
                  (orelse key-omitted value-omitted)))))))))
