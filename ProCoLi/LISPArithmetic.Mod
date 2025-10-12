IMPLEMENTATION MODULE LISPArithmetic;   (* ProCoLi 02/94 *)

(*  Arithmetische LISP-Funktionen und -Prädikate
 *)


  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) Numb, Value,
                    AssignPair, LeftPart, RightPart;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem,
                    Expr, Args, Val;

  FROM FreeList IMPORT
    (* PROCEDURE *) NewPair;

  FROM Errors IMPORT
    (* TYPE      *) ErrPos, ErrMsg,
    (* VAR       *) Abort,
    (* PROCEDURE *) Error;

  FROM Checks IMPORT
    (* PROCEDURE *) isInt,
                    Check1Int, Check2Ints;

  FROM LISPBase IMPORT
    (* PROCEDURE *) Bool;

  FROM Int IMPORT
    (* TYPE      *) RetCode,
    (* PROCEDURE *) Inc, Dec, Neg, Add, Sub, Mult, Div, Mod;


  PROCEDURE IntError (Pos : ErrPos; rc : RetCode);

  (*  Mit 'IntError (Pos, rc)' wird ein Fehler mit dem Fehlerort 'Pos' und der
   *  durch den Rückgabewert 'rc' beschriebenen Fehlerursache gemeldet.
   *)

  BEGIN (* IntError *)
    CASE rc OF
      OVERFLOW  : Error (Pos, IntOverflow)
    | UNDERFLOW : Error (Pos, IntUnderflow)
    | ZERODIV   : Error (Pos, IntZeroDiv)
    END (* CASE *)
  END IntError;


  PROCEDURE PlusFSubr;

  (*  Das Register 'Args' enthält mit Sicherheit eine Liste (wegen EVLIS)!
   *  Die Komponenten der Argumentliste müssen ganze Zahlen sein, deren Summe
   *  schrittweise berechnet wird. Beim ersten Fehler wird mit einer Meldung
   *  abgebrochen.
   *)

    VAR
      Sum : INTEGER;
      rc  : RetCode;
      sx  : SExpr;

  BEGIN (* PlusFSubr *)
    Sum := 0;
    WHILE Args # Nil DO
      sx := LeftPart (Args);
      Args := RightPart (Args);
      IF NOT isInt (sx) THEN
        Error (PLUSFSUBR, IntExpected);
        RETURN
      END (* IF *);
      Add (Sum, Value (sx), Sum, rc);
      IF rc # OK THEN
        IntError (PLUSFSUBR, rc);
        RETURN
      END (* IF *)
    END (* WHILE *);
    Val := Numb (Sum)
  END PlusFSubr;


  PROCEDURE TimesFSubr;

  (*  Das Produkt wird entsprechend der Summe berechnet.
   *)

    VAR
      Prod : INTEGER;
      rc   : RetCode;
      sx   : SExpr;

  BEGIN (* TimesFSubr *)
    Prod := 1;
    WHILE Args # Nil DO
      sx := LeftPart (Args);
      Args := RightPart (Args);
      IF NOT isInt (sx) THEN
        Error (TIMESFSUBR, IntExpected);
        RETURN
      END (* IF *);
      Mult (Prod, Value (sx), Prod, rc);
      IF rc # OK THEN
        IntError (TIMESFSUBR, rc);
        RETURN
      END (* IF *)
    END (* WHILE *);
    Val := Numb (Prod)
  END TimesFSubr;


  PROCEDURE MaxFSubr;

  (*  Die Argumentliste muss mindestens eine Komponente enthalten, und die
   *  Komponenten müssen ganze Zahlen sein. Deren Maximum wird schrittweise
   *  bestimmt. Beim ersten Fehler wird mit einer Meldung abgebrochen.
   *)

    VAR
      Max, x : INTEGER;
      sx     : SExpr;

  BEGIN (* MaxFSubr *)
    IF Args = Nil THEN
      Error (MAXFSUBR, TooFewArgs);
      RETURN
    END (* IF *);
    Max := MIN (INTEGER);
    REPEAT
      sx := LeftPart (Args);
      Args := RightPart (Args);
      IF NOT isInt (sx) THEN
        Error (MAXFSUBR, IntExpected);
        RETURN
      END (* IF *);
      x := Value (sx);
      IF x > Max THEN
        Max := x
      END (* IF *)
    UNTIL Args = Nil;
    Val := Numb (Max)
  END MaxFSubr;


  PROCEDURE MinFSubr;

  (*  Das Minimum wird entsprechend dem Maximum bestimmt.
   *)

    VAR
      Min, x : INTEGER;
      sx     : SExpr;

  BEGIN (* MinFSubr *)
    IF Args = Nil THEN
      Error (MINFSUBR, TooFewArgs);
      RETURN
    END (* IF *);
    Min := MAX (INTEGER);
    REPEAT
      sx := LeftPart (Args);
      Args := RightPart (Args);
      IF NOT isInt (sx) THEN
        Error (MINFSUBR, IntExpected);
        RETURN
      END (* IF *);
      x := Value (sx);
      IF x < Min THEN
        Min := x
      END (* IF *)
    UNTIL Args = Nil;
    Val := Numb (Min)
  END MinFSubr;


  PROCEDURE DifferenceSubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben, die beide ganze Zahlen
   *  sind. Die Differenz der beiden Zahlen wird bestimmt, ...
   *)

    VAR
      x, y, z : INTEGER;
      rc      : RetCode;

  BEGIN (* DifferenceSubr *)
    Check2Ints (DIFFERENCESUBR, Args, x, y);
    IF NOT Abort THEN
      Sub (x, y, z, rc);
      IF rc = OK THEN
        Val := Numb (z)
      ELSE
        IntError (DIFFERENCESUBR, rc)
      END (* IF *)
    END (* IF *)
  END DifferenceSubr;


  PROCEDURE QuotientSubr;

  (*  ... der Quotient der beiden Zahlen wird bestimmt, ...
   *)

    VAR
      x, y, z : INTEGER;
      rc      : RetCode;

  BEGIN (* QuotientSubr *)
    Check2Ints (QUOTIENTSUBR, Args, x, y);
    IF NOT Abort THEN
      Div (x, y, z, rc);
      IF rc = OK THEN
        Val := Numb (z)
      ELSE
        IntError (QUOTIENTSUBR, rc)
      END (* IF *)
    END (* IF *)
  END QuotientSubr;


  PROCEDURE RemainderSubr;

  (*  ... oder der Rest der Division der beiden Zahlen wird bestimmt.
   *)

    VAR
      x, y, z : INTEGER;
      rc      : RetCode;

  BEGIN (* RemainderSubr *)
    Check2Ints (REMAINDERSUBR, Args, x, y);
    IF NOT Abort THEN
      Mod (x, y, z, rc);
      IF rc = OK THEN
        Val := Numb (z)
      ELSE
        IntError (REMAINDERSUBR, rc)
      END (* IF *)
    END (* IF *)
  END RemainderSubr;


  PROCEDURE DivideSubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben, die beide ganze Zahlen
   *  sind. Der Quotient und der Rest der Division der beiden Zahlen werden
   *  berechnet und in eine neu erzeugte Liste eingetragen.
   *)

    VAR
      x, y, q, r : INTEGER;
      rc         : RetCode;

  BEGIN (* DivideSubr *)
    Check2Ints (DIVIDESUBR, Args, x, y);
    IF NOT Abort THEN
      Div (x, y, q, rc);
      IF rc = OK THEN
        Mod (x, y, r, rc)
      END (* IF *);
      IF rc # OK THEN
        IntError (DIVIDESUBR, rc);
        RETURN
      END (* IF *);
      NewPair (Expr);
      IF NOT OutOfMem THEN
        AssignPair (Expr, Numb (r), Nil);
        NewPair (Val)
      END (* IF *);
      IF OutOfMem THEN
        Error (DIVIDESUBR, StorageExhausted);
        RETURN
      END (* IF *);
      AssignPair (Val, Numb (q), Expr);
      Expr := Nil
    END (* IF *)
  END DivideSubr;


  PROCEDURE Add1Subr;

  (*  Die Argumentliste muß genau eine Komponente haben, die eine ganze Zahl
   *  ist. Diese Zahl wird um eins erhöht, ...
   *)

    VAR
      x  : INTEGER;
      rc : RetCode;

  BEGIN (* Add1Subr *)
    Check1Int (ADD1SUBR, Args, x);
    IF NOT Abort THEN
      Inc (x, rc);
      IF rc = OK THEN
        Val := Numb (x)
      ELSE
        IntError (ADD1SUBR, rc)
      END (* IF *)
    END (* IF *)
  END Add1Subr;


  PROCEDURE Sub1Subr;

  (*  ... die Zahl wird um eins vermindert, ...
   *)

    VAR
      x  : INTEGER;
      rc : RetCode;

  BEGIN (* Sub1Subr *)
    Check1Int (SUB1SUBR, Args, x);
    IF NOT Abort THEN
      Dec (x, rc);
      IF rc = OK THEN
        Val := Numb (x)
      ELSE
        IntError (SUB1SUBR, rc)
      END (* IF *)
    END (* IF *)
  END Sub1Subr;


  PROCEDURE MinusSubr;

  (*  ... oder das Vorzeichen der Zahl wird umgekehrt.
   *)

    VAR
      x  : INTEGER;
      rc : RetCode;

  BEGIN (* MinusSubr *)
    Check1Int (MINUSSUBR, Args, x);
    IF NOT Abort THEN
      Neg (x, rc);
      IF rc = OK THEN
        Val := Numb (x)
      ELSE
        IntError (MINUSSUBR, rc)
      END (* IF *)
    END (* IF *)
  END MinusSubr;


  PROCEDURE ExPtSubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben, die beide ganze Zahlen
   *  sind. Der Potenzwert der beiden Zahlen wird bestimmt.
   *  Zur Vermeidung von Fehlern und überflüssigen Berechnungen werden folgende
   *  Fälle besonders behandelt:
   *     [ x  = 0]               x ^ y   =  (y > 0  -->  0  |  undefiniert)
   *     [|x| = 1]               x ^ y   =  (y ist gerade  -->  1  |  x)
   *     [|x| > 1, y < 0]   int (x ^ y)  =  0
   *  In den übrigen Fällen wird durch fortgesetzte Multiplikation potenziert
   *  und beim ersten Fehler abgebrochen.
   *)

    VAR
      x, y, z : INTEGER;
      rc      : RetCode;
      i       : CARDINAL;

  BEGIN (* ExPtSubr *)
    Check2Ints (EXPTSUBR, Args, x, y);
    IF NOT Abort THEN
      IF x = 0 THEN
        IF y < 0 THEN
          Error (EXPTSUBR, Raise0ToNegPower)
        ELSIF y = 0 THEN
          Error (EXPTSUBR, Raise0To0)
        ELSE (* y > 0 *)
          Val := Numb (0)
        END (* IF *)
      ELSIF (x = 1) OR (x = - 1) THEN
        IF ODD (y) THEN
          Val := Numb (x)
        ELSE (* EVEN (y) *)
          Val := Numb (1)
        END (* IF *)
      ELSIF y < 0 THEN
        Val := Numb (0)
      ELSE (* (ABS (x) > 1) & (y >= 0) *)
        z := 1;
        FOR i := 1 TO y DO
          Mult (z, x, z, rc);
          IF rc # OK THEN
            IntError (EXPTSUBR, rc);
            RETURN
          END (* IF *)
        END (* FOR *);
        Val := Numb (z)
      END (* IF *)
    END (* IF *)
  END ExPtSubr;


  PROCEDURE ZeroPSubr;

  (*  Die Argumentliste muß genau eine Komponente haben, die eine ganze Zahl
   *  ist. Es wird überprüft, ob die Zahl den Wert null hat, ...
   *)

    VAR
      x : INTEGER;

  BEGIN (* ZeroPSubr *)
    Check1Int (ZEROPSUBR, Args, x);
    IF NOT Abort THEN
      Val := Bool (x = 0)
    END (* IF *)
  END ZeroPSubr;


  PROCEDURE OnePSubr;

  (*  ... ob die Zahl den Wert eins hat, ...
   *)

    VAR
      x : INTEGER;

  BEGIN (* OnePSubr *)
    Check1Int (ONEPSUBR, Args, x);
    IF NOT Abort THEN
      Val := Bool (x = 1)
    END (* IF *)
  END OnePSubr;


  PROCEDURE MinusPSubr;

  (*  ... oder ob die Zahl einen negativen Wert hat.
   *)

    VAR
      x : INTEGER;

  BEGIN (* MinusPSubr *)
    Check1Int (MINUSPSUBR, Args, x);
    IF NOT Abort THEN
      Val := Bool (x < 0)
    END (* IF *)
  END MinusPSubr;


  PROCEDURE GreaterPSubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben, die beide ganze Zahlen
   *  sind. Es wird überprüft, ob die erste Zahl größer als die zweite ist, ...
   *)

    VAR
      x, y : INTEGER;

  BEGIN (* GreaterPSubr *)
    Check2Ints (GREATERPSUBR, Args, x, y);
    IF NOT Abort THEN
      Val := Bool (x > y)
    END (* IF *)
  END GreaterPSubr;


  PROCEDURE LessPSubr;

  (*  ... oder ob die erste Zahl kleiner als die zweite ist.
   *)

    VAR
      x, y : INTEGER;

  BEGIN (* LessPSubr *)
    Check2Ints (LESSPSUBR, Args, x, y);
    IF NOT Abort THEN
      Val := Bool (x < y)
    END (* IF *)
  END LessPSubr;


END LISPArithmetic.
