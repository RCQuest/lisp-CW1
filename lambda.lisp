; CM20214/CM20221
; Advanced Programming Principles/Programming II
; Assessed Coursework Assignment 1
; Due: 5pm., Friday 12th Dec 2014, via Moodle
; Implement simple polynomial arithmetic in Lisp, with the polynomials 
; represented in some suitable way within Lisp.
; Your code should
; • implement the three polynomial arithmetic operations +, − and ∗. 
;   The functions should be named p+, p- and p*
; • expand and collect together like terms, 
;   e.g., the sum of x + y and x should be 2x + y 
;   rather than x + y + x while the product of (x + y) and (x + z) 
;   should be x2 + xz + xy + yz. The order of the terms is your choice.
; • p+, p-, p* should all be functions of exactly 
;   two arguments, both being polynomials presented in your chosen 
;   format, and should return a polynomial in your chosen format. 
;   Thus, if p1 is x + y + 1 and p2 is 2xy + x + z,
;   then (p+ p1 p2) returns your representation for 2xy+2x+y+z+1; 
;   and (p- (p+ p1 p2) p2) returns
;   your representation for x + y + 1.

; REPRESENTATION:
; (expression)
; where:
; expression = ((expression) operator (expression)) [EXPRESSION]
; OR
; expression = (coefficient (x exponent)+) [TERM]
; coefficient = [0..9]+
; x = [A..Z,a..z]
; exponent = [0..9]+
; operator = [x, +, -]
; term with (x 0) indicates a constant
; (x exponent)s are sorted alphabetically
; inputs and results must always be a list of binary operations, such as:
; ((x + (2x + y)) * 2x)

; FUNCTION DEFS:
(defun pIsIn (term expression)
    "gets a representative TERM and a representative EXPRESSION 
    and returns true if it contains the term"
    (if expression
        (if (equal term (car (car expression))) 
            t 
            (pIsIn term (cdr expression)))
        nil))

(defun squish* (x y)
    "takes 2 representative TERMs without 
    coefficients and multiplies them"
    (if y 
        (squish* 
            (append 
                (map 'list 
                    #'(lambda (foo) 
                        (if (equal (car (car y)) (car foo)) 
                            (list 
                                (car foo) 
                                (+ (car (cdr foo)) (car (cdr (car y)))))
                            foo))
                    x)
                (if (pIsIn (car (car y)) x) 
                    '() 
                    (list (car y))))
        (cdr y))
        x))

(defun removec0 (exp)
    "takes a flat list of terms to be summed without and removes 
    a term if it has a zero coefficient"
    (if (> (list-length exp) 1)
        (remove-if #'(lambda (term) (equal 0 (car term))) exp)
        (if (equal 0 (car exp)) 
            '() 
            exp)))

(defun removex0 (exp) 
    "removes a zero exponent from raw squish'd terms ((x 1) (y 2) ...) 
    if not the only term, 
    and also 0 coeff terms"
    (if (> (list-length exp) 1)
            (remove-if #'(lambda (term) (equal 0 (car (cdr term)))) exp)
            exp)) 

(defun orderInner (exp)
    "extensible wrapper for the quicksort function"
    (qsort exp))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; modified version of brunocodutra's functional qsort
; sourced from: http://stackoverflow.com/questions/19082032/quicksort-in-lisp

(defun qsort (L)
    (cond ((null L) nil)
          (t (append 
                (qsort (list< (car L) (cdr L)))
                (cons (car L) nil) 
                (qsort (list>= (car L) (cdr L)))))))

(defun list< (a b)
    (cond
        ((or (null a) (null b)) nil)
        ((< 
            (char-code (character (car a))) 
            (char-code (character (car (car b))))) 
        (list< a (cdr b)))
        (t (cons (car b) (list< a (cdr b))))))

(defun list>= (a b)
    (cond
        ((or ( null a) (null b)) nil)
        ((>= 
            (char-code (character (car a))) 
            (char-code (character (car (car b))))) (list>= a (cdr b)))
        (t(cons (car b) (list>= a (cdr b))))))

; end of qsort
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun binarify (exp)
    "takes a flat list of representational EXPRESSIONs and TERMs delimited by 
    + and returns a single sided binary tree of expressions
    e.g. (a + b + c):=(a + (b + c)"
    (if (> (list-length exp) 1)
        (list (car exp) (car (cdr exp)) (binarify (cdr (cdr exp)))) 
        (car exp)))

(defun dive (exp)
    "gets a representational EXPRESSION and evaluates it 
    depending on it's contents, or returns if exp is a 
    TERM"
    (let ((foo (collect exp)))
            (cond ((equal '+ (car (cdr foo))) 
                    (p+ (car foo) (car (cdr (cdr foo)))))
                  ((equal '- (car (cdr foo))) 
                    (p- (car foo) (car (cdr (cdr foo)))))
                  ((equal '* (car (cdr foo))) 
                    (p* (car foo) (car (cdr (cdr foo)))))
                  (t foo))))

(defun p+ (exp1 exp2)
    "sums two representational EXPRESSIONs or TERMs"
    (let ((x (dive exp1)) (y (dive exp2)))
            (if (equal (cdr x) (cdr y))
                (list (+ (car x) (car y)) (car (cdr x)))
                (list x '+ y))))

(defun p- (exp1 exp2)
    "subtracts EXPRESSION or TERM exp1 from 
    EXPRESSION or TERM exp2"
    (let ((x (dive exp1)) (y (dive exp2)))
            (if (equal (cdr x) (cdr y))
                (list (- (car x) (car y)) (car (cdr x)))
                (list x '- y))))

(defun pickPermute* (x op1 op2 y)
    "gets two representational expressions and their signage,
    and returns their product"
    (if (equal op1 op2) 
        (p* x y)
        (p* y (p* x '(-1 (x 0))))))

(defun delimit+ (exp)
    "takes a flat list of representational expressions that 
    need to be added together and delimits them with +"
    (if (cdr exp) 
        (append (list (car exp)) (append (list '+) (delimit+ (cdr exp)))) 
        exp))

(defun p* (exp1 exp2) 
    "multiplies EXPRESSION or TERM exp1 from 
    EXPRESSION or TERM exp2"
    (let ((x (dive exp1)) (y (dive exp2)))
                (if (not (isTerm x))
                    (if (not (isTerm y))
                        (let ((p1 (pickPermute* 
                                    (car x) '+ '+ (car y)))
                              (p2 (pickPermute* 
                                    (car x) 
                                    '+ 
                                    (car (cdr y)) 
                                    (car (cdr (cdr y)))))
                              (p3 (pickPermute* 
                                    (car (cdr (cdr x))) 
                                    (car (cdr y)) 
                                    '+ 
                                    (car y)))
                              (p4 (pickPermute* 
                                    (car (cdr (cdr x))) 
                                    (car (cdr x)) 
                                    (car (cdr y)) 
                                    (car (cdr (cdr y))))))
                            (dive (binarify (delimit+ (remove '() 
                                    (list p1 p2 p3 p4))))))
                        (let ((p1 (pickPermute* 
                                (car x) '+ '+ y))
                              (p2 (pickPermute* 
                                (car (cdr (cdr x))) 
                                '+ 
                                (car (cdr x)) 
                                y)))
                             (dive (binarify (delimit+ (remove '() 
                                (list p1 p2)))))))
                    (if (not (isTerm y))
                        (let ((p1 (pickPermute* 
                                (car y) '+ '+ x))
                              (p2 (pickPermute* 
                                (car (cdr (cdr y))) '+ (car (cdr y)) x)))
                            (dive (binarify (delimit+ (remove '() (list p1 p2))))))
                        (append
                            (list (* (car x) (car y))) 
                            (orderInner (removex0 (squish* (cdr x) (cdr y)))))))))

(defun simplify (exp)
    "extensible wrapper for the dive function"
    (dive exp))

(defun debugPrint (exp message)
    "used for debugging scaffolds"
    (print message)
    (print exp))

(defun isTerm (exp)
    "returns true if exp is a representational TERM
    and false otherwise"
    (cond ((equal '+ (car (cdr exp))) nil)
          ((equal '- (car (cdr exp))) nil)
          ((equal '* (car (cdr exp))) nil)
          (t exp)))

(defun sumTerms-it (term old new)
    "takes a term and a flat list of representational terms,
    adds it (if it can) to every other term in the list, 
    returns them appended to new"
    (if old
            (if (equal (cdr (car old)) (cdr term)) 
                (sumTerms-it (p+ term (car old)) (cdr old) new) 
                (sumTerms-it term (cdr old) (append new (list (car old)))))
            (list old new term)))

(defun sumTerms (old new)
    "takes a flat list of representational terms, sums like terms, and returns them 
    appended to new"
    (let ((it (sumTerms-it (car old) (cdr old) new)))
            (if old 
                (sumTerms 
                    (car it) 
                    (append (list (car (cdr (cdr it)))) (car (cdr it))))
                new)))

(defun collect-it (old new)
    "gets a representational expression and returns a flattened 
    list of terms which can be summed together"
    (cond ((equal '+ (car (cdr old))) 
            (append new 
                (collect-it (car old) new) 
                (collect-it (car (cdr (cdr old))) new)))
          ((equal '- (car (cdr old))) 
            (append new 
                (collect-it (car old) new) 
                (collect-it (p* '(-1 (x 0)) (car (cdr (cdr old)))) new)))
          ((equal '* (car (cdr old))) 
            (append new (list old)))
          (t 
            (append new (list old)))))

(defun collect (exp)
    "collects like representational terms in the expression"
    (if (isTerm exp) ; if the argument is one term
            exp
            (binarify (delimit+ (removec0 (sumTerms (collect-it exp '()) '()))))))

; TESTS:

(format t "~%Hello world! Let's do some maths.")
(format t "~%~%Poly functions:")

(print (collect (p+ '(1 (x 1)) '((1 x 1) + (1 y 1)))))
(print (equal (p+ '(1 (x 1)) '((1 x 1) + (1 y 1))) '((2 (x 1)) + (1 (y 1)))))