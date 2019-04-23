;import settings
(import 'class/lisp.inc)
(import 'cmd/asm.inc)

(defun make-doc ()
	(defq *abi* (abi) *cpu* (cpu))
	(defun trim-whitespace (_)
		(trim-start (trim-start _ (char 9)) " "))
	(defun trim-cruft (_)
		(sym (trim-start (trim-end _ ")") "'")))
	(defun trim-parens (_)
		(sym (trim-start (trim-end _ ")") "(")))
	(defun chop (_)
		(when (defq e (find (char 0x22) _))
			(setq _ (slice 0 e _))
			(sym (slice (inc (find (char 0x22) _)) -1 _))))
	(print "Scanning source files...")
	(defq *imports* (list 'make.inc) classes (list) functions (list)
		docs (list) syntax (list) state 'x)
	(within-compile-env (lambda ()
		(include 'sys/func.inc)
		(each include (all-class-files))
		(each-mergeable (lambda (_)
			(each-line (lambda (_)
				(setq _ (trim-end _ (char 13)))
				(defq l (trim-whitespace _))
				(when (eql state 'y)
					(if (and (ge (length l) 1) (eql (elem 0 l) ";"))
						(push (elem -2 docs) (slice 1 -1 l))
						(setq state 'x)))
				(when (and (eql state 'x) (ge (length l) 10) (eql "(" (elem 0 l)))
					(defq s (split l " ") _ (elem 0 s))
					(cond
						((eql _ "(include")
							(insert-sym *imports* (trim-cruft (elem 1 s))))
						((eql _ "(def-class")
							(push classes (list (trim-cruft (elem 1 s))
								(if (eq 3 (length s)) (trim-cruft (elem 2 s)) 'null))))
						((eql _ "(dec-method")
							(push (elem -2 classes) (list (trim-cruft (elem 1 s)) (trim-cruft (elem 2 s)))))
						((eql _ "(def-method")
							(setq state 'y)
							(push docs (list))
							(push functions (f-path (trim-cruft (elem 1 s)) (trim-cruft (elem 2 s)))))
						((or (eql _ "(def-func") (eql _ "(defcfun"))
							(setq state 'y)
							(push docs (list))
							(push functions (trim-cruft (elem 1 s))))
						((and (or (eql _ "(call") (eql _ "(jump")) (eql (elem 2 s) "'repl_error"))
							(if (setq l (chop l))
								(insert-sym syntax l)))))) _)) *imports*)))
	;create classes docs
	(sort (lambda (x y)
		(cmp (elem 0 x) (elem 0 y))) classes)
	(defq stream (string-stream (cat "")))
	(write-line stream "# Classes")
	(each (lambda ((class super &rest methods))
		(write-line stream (cat "## " class))
		(write-line stream (cat "Super Class: " super))
		(each (lambda ((method function))
			(write-line stream (cat "### " class "::" method " -> " function))
			(when (and (defq i (find function functions))
					(ne 0 (length (elem i docs))))
				(write-line stream "```")
				(each (lambda (_)
					(write-line stream _)) (elem i docs))
				(write-line stream "```"))) methods)) classes)
	(save (str stream) 'doc/CLASSES.md)
	(print "-> doc/CLASSES.md")

	;create lisp syntax docs
	(each-line (lambda (_)
		(setq _ (trim-end _ (char 13)))
		(defq l (trim-whitespace _))
		(when (eql state 'y)
			(if (and (ge (length l) 1) (eql (elem 0 l) ";"))
				(insert-sym syntax (sym (slice 1 -1 l)))
				(setq state 'x)))
		(when (and (eql state 'x) (ge (length l) 10) (eql "(" (elem 0 l)))
			(defq s (split l " ") _ (elem 0 s))
			(cond
				((or (eql _ "(defun") (eql _ "(defmacro"))
					(setq state 'y))))) 'class/lisp/boot.inc)
	(sort cmp syntax)
	(defq stream (string-stream (cat "")))
	(write-line stream "# Syntax")
	(each (lambda (_)
		(defq s (split _ " ") form (trim-parens (elem 0 s)))
		(when (eql "(" (elem 0 (elem 0 s)))
			(write-line stream (cat "## " form))
			(write-line stream (cat "### " _)))) syntax)
	(save (str stream) 'doc/SYNTAX.md)
	(print "-> doc/SYNTAX.md"))

;initialize pipe details and command args, abort on error
(when (defq slave (create-slave))
	(defq args (map sym (slave-get-args slave)) all (find 'all args)
		boot (find 'boot args) platforms (find 'platforms args) doc (find 'doc args))
	(cond
		((and boot all platforms) (remake-all-platforms))
		((and boot all) (remake-all))
		((and boot platforms) (remake-platforms))
		((and all platforms) (make-all-platforms))
		(all (make-all))
		(platforms (make-platforms))
		(boot (remake))
		(doc (make-doc))
		(t (make))))
