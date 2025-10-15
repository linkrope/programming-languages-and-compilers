LET
  Ackermann : INT * INT -> INT  ! Ackermann-Funktion

  Ackermann(n, m) =
    IF n = 0 THEN m + 1 ELSE
    IF m = 0 THEN Ackermann(n - 1, 1) ELSE
      Ackermann(n - 1, Ackermann(n, m - 1))
IN
  Ackermann(2, 3)
~

LET
  Fac : INT -> INT  ! "n!"

  Fac(n) =
    IF n = 0 THEN 1 ELSE n * Fac(n - 1)
IN
  Fac(5)
~

LET
  Fibonacci : INT -> INT  ! n-te Fibonacci-Zahl

  Fibonacci(n) =
    IF n <= 1 THEN n ELSE Fibonacci(n - 1) + Fibonacci(n - 2)
IN
  Fibonacci(9)
~

LET
  Id : INT -> INT  ! keine Endlosschleife !

  Id(Flip) =
    LET
      Flop : -> INT
      Flop = Flip

      Flip : -> INT
      Flip = Flop
    IN
      Flip
IN
  Id(42)
~

LET
  ThreeNPlusOne : INT -> INT  ! "3 n + 1" - Funktion

  ThreeNPlusOne(n) =
    LET
      Even : INT -> BOOL
      Odd  : INT -> BOOL

      Even(n) = IF n = 0 THEN TRUE ELSE Odd(n - 1)
      Odd(n)  = NOT Even(n)
    IN
      IF n = 1 THEN n ELSE ThreeNPlusOne(IF Even(n) THEN n / 2 ELSE 3 * n + 1)
IN
  ThreeNPlusOne(9)
~

LET
  NthPrime : INT -> INT  ! n-te Primzahl

  NthPrime(n) =
    LET
      F     : INT -> INT  ! F(m) ist die kleinste Primzahl nach m
      Prime : INT -> BOOL

      F(m)     = LET
                   m1 : -> INT

                   m1 = m + 1
                 IN
                   IF Prime(m1) THEN m1 ELSE F(m1)
      Prime(m) = LET
                   Divides : INT * INT -> BOOL

                   Divides(k, m) = m / k * k = m

                   F : INT -> BOOL  ! F(k) gdw. m nicht bis zur k-ten Primzahl teilbar ist

                   F(k) = IF k = 0 THEN TRUE ELSE F(k - 1) AND NOT Divides(NthPrime(k), m)
                 IN
                   F(n - 1)
    IN
      IF n = 1 THEN 2 ELSE F(NthPrime(n - 1))
IN
  NthPrime(5)
~
