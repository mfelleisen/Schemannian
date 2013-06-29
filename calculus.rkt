#lang racket

(require "fundamental.rkt")

(provide deriv)

(define (deriv exp var)
  (cond ((number? exp) 0)
        ((variable? exp)
         (if (same-variable? exp var) 1 0))
        ((sum? exp)
         (make-sum (map
                    (lambda (arg-lst) (deriv arg-lst var)) 
                    (get-arg-lst exp))))
        ((product? exp)
         (map-derivation (lambda (exp) (deriv exp var)) make-product (get-arg-lst exp)))
        ((exponentiation? exp)
         (cond ((number? (exponent exp))
                (make-product (list (exponent exp)
                                    (make-exponentiation (base exp) (- (exponent exp) 1)) 
                                    (deriv (base exp) var))))
               ((number? (base exp))
                (make-product (list (log (base exp))
                                    exp
                                    (deriv (exponent exp) var))))
               (else
                (make-product (list (make-exponentiation (base exp) (make-sum (list (exponent exp) -1)))
                                    (make-sum (list (make-product (list (exponent exp)
                                                                        (deriv (base exp) var)))
                                                    (make-product (list (base exp)
                                                                        (deriv (exponent exp) var)
                                                                        (make-log (base exp)))))))))))
        ((eq? (get-op exp) 'log)
         (make-product (list (make-exponentiation (get-arg exp) -1) (deriv (get-arg exp) var))))
        ((eq? (get-op exp) 'sin)
         (make-product (list (make-cos (get-arg exp)) (deriv (get-arg exp) var))))
        ((eq? (get-op exp) 'cos)
         (make-product (list -1 (list (make-sin (get-arg exp)) (deriv (get-arg exp) var)))))
        (else
         (error "unknown expression type -- DERIV" exp))))

;(deriv '(+ x 2 x x 3) 'x) ;3
;(deriv '(+ (* x 2) (* x x y 3)) 'x) ;'(+ 2 (+ (* 3 x y) (* 3 x y)))
;(deriv '(** (+ (* 2 x) y) 3) 'x) ;'(* 6 (** (+ (* 2 x) y) 2))
;(deriv '(** 2 (* x y)) 'x) ;'(* 0.6931471805599453 (** 2 (* x y)) y)
;(deriv '(** x x) 'x) ;'(* (** x (+ -1 x)) (+ x (* x (log x)))) = '(* (** x x) (+ 1 (log x)))
;(deriv '(log (** x 3)) 'x) ;'(* (** (** x 3) -1) (* 3 (** x 2)))
;(deriv '(sin (* 3 x)) 'x) ;'(* 3 (cos (* 3 x)))

(define (integrate exp var)
  (cond ((number? exp) (make-product (list exp var)))
        ((variable? exp)
         (if (same-variable? exp var)
             (make-product (list (/ 1 2) (make-exponentiation var 2)))
             (make-product (list exp var))))
        ((sum? exp)
         (make-sum (map
                    (lambda (arg-lst) (integrate arg-lst var)) 
                    (get-arg-lst exp))))
        ((exponentiation? exp)
         (if (and (number? (exponent exp)) (eq? (base exp) var))
             (make-product (list (/ 1 (+ (exponent exp) 1))
                                 (make-exponentiation var (+ (exponent exp) 1))))
             (error "unknown expression type -- DERIV" exp)))
        (else
         (error "unknown expression type -- DERIV" exp))))

;(integrate '(+ x y 2) 'x) ;'(+ (* (1/2) (** x 2)) (* y x) (* 2 x))
;(integrate '(** x 3) 'x) ;'(* (1/4) (** x 4))