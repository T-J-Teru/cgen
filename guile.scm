(define *guile-major-version* (string->number (major-version)))
(define *guile-minor-version* (string->number (minor-version)))

(if (= *guile-major-version* 1)
    (load "guile1.scm")
    (load "guile2.scm"))
