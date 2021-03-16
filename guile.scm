; Guile-specific functions.
; Copyright (C) 2000, 2004, 2009 Red Hat, Inc.
; This file is part of CGEN.
; See file COPYING.CGEN for details.

(define *guile-major-version* (string->number (major-version)))
(define *guile-minor-version* (string->number (minor-version)))

; A version of eval that only takes 1 argument and evaluates it in the
; current module.
(define (eval1 expr)
  (eval expr (current-module)))

; Redefine load.
(define (load file)
  (begin
    (primitive-load-path file))
)

; FIXME: to be deleted
(define =? =)
(define >=? >=)

; An alias for `stat'.  Should probably get rid of this and just use
; `stat' directly.
(define %stat stat)

; Enable backtrace on error.  This should be on by default, but this
; doesn't hurt.
(debug-enable 'backtrace)

(define (debug-write . objs)
  (map (lambda (o)
	 ((if (string? o) display write) o (current-error-port)))
       objs)
  (newline (current-error-port)))

;; Guile 1.8 no longer has "." in %load-path so relative path loads
;; no longer work.

(if (or (> *guile-major-version* 1)
	(>= *guile-minor-version* 8))
    (set! %load-path (append %load-path (list ".")))
)


;;; Enabling and disabling debugging features of the host Scheme.

;;; For the initial load proces, turn everything on.  We'll disable it
;;; before we start doing the heavy computation.
(if (memq 'debug-extensions *features*)
    (begin
      (debug-enable 'backtrace)
      (debug-enable 'debug)
      (debug-enable 'backwards)
      (debug-set! depth 2000)
      (debug-set! maxdepth 2000)
      (debug-set! stack 100000)
      (debug-set! frames 10)))
(read-enable 'positions)

;;; Call THUNK, with debugging enabled if FLAG is true, or disabled if
;;; FLAG is false.
;;;
;;; (On systems other than Guile, this needn't actually do anything at
;;; all, beyond calling THUNK, so long as your backtraces are still
;;; helpful.  In Guile, the debugging evaluator is slower, so we don't
;;; want to use it unless the user asked for it.)
(define (cgen-call-with-debugging flag thunk)
  (if (memq 'debug-extensions *features*)
      ((if flag debug-enable debug-disable) 'debug))

  ;; Now, make that debugging / no-debugging setting actually take
  ;; effect.
  ;;
  ;; Guile has two separate evaluators, one that does the extra
  ;; bookkeeping for backtraces, and one which doesn't, but runs
  ;; faster.  However, the evaluation process (in either evaluator)
  ;; ordinarily never consults the variable that says which evaluator
  ;; to use: whatever evaluator was running just keeps rolling along.
  ;; There are certain primitives, like some of the eval variants,
  ;; that do actually check.  start-stack is one such primitive, but
  ;; we don't want to shadow whatever other stack id is there, so we
  ;; do all the real work in the ID argument, and do nothing in the
  ;; EXP argument.  What a kludge.
  (start-stack (begin (thunk) #t) #f))


;;; Apply PROC to ARGS, marking that application as the bottom of the
;;; stack for error backtraces.
;;;
;;; (On systems other than Guile, this doesn't really need to do
;;; anything other than apply PROC to ARGS, as long as something
;;; ensures that backtraces will work right.)
(define (cgen-debugging-stack-start proc args)

  ;; Naming this procedure, rather than using an anonymous lambda,
  ;; allows us to pass less fragile cut info to save-stack.
  (define (handler . args)
		;;(display args (current-error-port))
		;;(newline (current-error-port))
		;; display-error takes 6 arguments.
		;; If `quit' is called from elsewhere, it may not have 6
		;; arguments.  Not sure how best to handle this.
		(if (= (length args) 5)
		    (begin
		      (apply display-error #f (current-error-port) (cdr args))
		      ;; Grab a copy of the current stack,
		      (save-stack handler 0)
		      (backtrace)))
		(quit 1))

  ;; Apply proc to args, and if any uncaught exception is thrown, call
  ;; handler WITHOUT UNWINDING THE STACK (that's the 'lazy' part).  We
  ;; need the stack left alone so we can produce a backtrace.
  (lazy-catch #t
	      (lambda ()
		;; I have no idea why the 'load-stack' stack mark is
		;; not still present on the stack; we're still loading
		;; cgen-APP.scm, aren't we?  But stack-id returns #f
		;; in handler if we don't do a start-stack here.
		(start-stack proc (apply proc args)))
	      handler))

;; To support transitioning to later versions of guile define
;; `eval-when', so that these calls can be added to the rest of CGEN
;; without tripping up guile 1.8.x.
;;
;; As guile 1.8.x doesn't have the same phased execution model as
;; guile 2+, `eval-when' just unconditionally executes the body in all
;; cases.
(defmacro eval-when (states body)
  body)
