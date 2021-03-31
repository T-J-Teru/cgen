(define *guile-major-version* (string->number (major-version)))
(define *guile-minor-version* (string->number (minor-version)))

(if (= *guile-major-version* 1)
    (begin
      (display "APB: Loading guile1.scm\n\n")
      (load "guile1.scm"))
    (begin
      (display "APB: Loading guile2.scm\n\n")
      (load "guile2.scm")))
