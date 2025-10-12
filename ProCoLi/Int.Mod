IMPLEMENTATION MODULE Int;   (* ProCoLi 02/89 *)

(*  Arithmetische Operationen auf ganzen Zahlen mit Fehleranzeige
 *
 *  Ein möglicher Fehler wird durch eine vorherige Abfrage erkannt und
 *  vermieden.
 *  Undefinierte Berechnungen (Division durch Null) kann man durch direkte Tests
 *  der Operanden erkennen.
 *  Fehler durch Implementierungsbeschränkungen liegen dann vor, wenn das
 *  Ergebnis einer Operation außerhalb des implementierten Intervalls der
 *  ganzen Zahlen liegt. Mit einem direkten Test der Operanden kann die
 *  mögliche Art des Fehlers festgestellt werden (zu großes/kleines Ergebnis).
 *     [Bsp.:
 *      Die Addition von zwei positiven Zahlen kann höchstens ein zu großes
 *      Ergebnis liefern.]
 *  Mit einem weiteren Test wird nun erkannt, ob tatsächlich ein Fehler
 *  vorliegt. Dieser Test ist aus der zu überprüfenden Bedingung durch
 *  Umformung unter Verwendung der inversen Operation hervorgegangen und
 *  führt garantiert nicht selbst zu einem Fehler.
 *     [Bsp.: (s.o.)
 *      Fehlerbedingung:  x + y > MaxInt;
 *      Fehlertest:       x > MaxInt - y.
 *      (Für positive Werte y liegt  MaxInt - y  im implementierten Intervall!)]
 *  Im Fehlerfall werden die Prozeduren frühzeitig verlassen, so daß die
 *  eigentliche Berechnung nur einmal am Prozedurende auftritt.
 *  Es wird vorausgesetzt, daß  'MinInt' = - 'MaxInt' - 1  gilt.
 *)


  PROCEDURE Inc (VAR x : INTEGER; VAR rc : RetCode);

  (*  Wenn möglich, wird der Wert von 'x' um eins erhöht.
   *  Wird 'MaxInt' um eins erhöht, kommt es zu einem zu großen Ergebnis.
   *)

  BEGIN (* Inc *)
    IF x = MAX (INTEGER) THEN
      rc := OVERFLOW;
      RETURN
    END (* IF *);
    rc := OK;
    INC (x)
  END Inc;


  PROCEDURE Dec (VAR x : INTEGER; VAR rc : RetCode);

  (*  Wenn möglich, wird der Wert von 'x' um eins vermindert.
   *  Wird 'MinInt' um eins vermindert, kommt es zu einem zu kleinen Ergebnis.
   *)

  BEGIN (* Dec *)
    IF x = MIN (INTEGER) THEN
      rc := UNDERFLOW;
      RETURN
    END (* IF *);
    rc := OK;
    DEC (x)
  END Dec;


  PROCEDURE Neg (VAR x : INTEGER; VAR rc : RetCode);

  (*  Wenn möglich, wird das Vorzeichen des Werts von 'x' umgekehrt.
   *  Bei 'MinInt' kommt es zu einem zu großen Ergebnis, da nach Voraussetzung
   *  gilt:
   *     - MinInt = MaxInt + 1
   *)

  BEGIN (* Neg *)
    IF x = MIN (INTEGER) THEN
      rc := OVERFLOW;
      RETURN
    END (* IF *);
    rc := OK;
    x := - x
  END Neg;


  PROCEDURE Add (x, y : INTEGER; VAR z : INTEGER; VAR rc : RetCode);

  (*  Wenn möglich, werden die Werte von 'x' und 'y' addiert und die Summe
   *  in 'z' geliefert.
   *  Die Addition von zwei positiven Zahlen kann höchstens ein zu großes
   *  Ergebnis liefern; bei zwei negativen Zahlen kann das Ergebnis zu klein
   *  sein.
   *)

  BEGIN (* Add *)
    IF (x >= 0) & (y >= 0) THEN
      IF MAX (INTEGER) - y < x THEN
        rc := OVERFLOW;
        RETURN
      END (* IF *)
    ELSIF (x < 0) & (y < 0) THEN
      IF MIN (INTEGER) - y > x THEN
        rc := UNDERFLOW;
        RETURN
      END (* IF *)
    END (* IF *);
    rc := OK;
    z := x + y
  END Add;


  PROCEDURE Sub (x, y : INTEGER; VAR z : INTEGER; VAR rc : RetCode);

  (*  Wenn möglich, werden die Werte von 'x' und 'y' subtrahiert und die
   *  Differenz in 'z' geliefert.
   *  Die Subtraktion einer negativen von einer positiven Zahl kann höchstens
   *  ein zu großes Ergebnis liefern; umgekehrt kann das Ergebnis zu klein
   *  sein.
   *)

  BEGIN (* Sub *)
    IF (x >= 0) & (y < 0) THEN
      IF MAX (INTEGER) + y < x THEN
        rc := OVERFLOW;
        RETURN
      END (* IF *)
    ELSIF (x < 0) & (y >= 0) THEN
      IF MIN (INTEGER) + y > x THEN
        rc := UNDERFLOW;
        RETURN
      END (* IF *)
    END (* IF *);
    rc := OK;
    z := x - y
  END Sub;


  PROCEDURE Mult (x, y : INTEGER; VAR z : INTEGER; VAR rc : RetCode);

  (*  Wenn möglich, werden die Werte von 'x' und 'y' multipliziert und das
   *  Produkt in 'z' geliefert.
   *  Die Multiplikation von zwei positiven oder zwei negativen Zahlen kann
   *  höchstens ein zu großes Ergebnis liefern; bei einer positiven und einer
   *  negativen Zahl kann das Ergebnis zu klein sein.
   *  Bei  'y' = 0  würde es wegen der Verwendung der inversen Operation (DIV)
   *  zu einer undefinierten Berechnung kommen. Ebenso käme es bei  'y' = - 1
   *  beim Test auf ein zu kleines Ergebnis zu einem Fehler durch
   *  Implementierungsbeschränkungen.
   *  Diese Fehler lassen sich jedoch durch zusätzliche Abfragen vermeiden,
   *  da in den genannten Fällen ohnehin kein zu großes/kleines Ergebnis
   *  möglich ist.
   *)

  BEGIN (* Mult *)
    IF (x >= 0) & (y > 0) THEN
      IF MAX (INTEGER) DIV y < x THEN
        rc := OVERFLOW;
        RETURN
      END (* IF *)
    ELSIF (x < 0) & (y < 0) THEN
      IF MAX (INTEGER) DIV y > x THEN
        rc := OVERFLOW;
        RETURN
      END (* IF *)
    ELSIF (x < 0) & (y > 0) THEN
      IF MIN (INTEGER) DIV y > x THEN
        rc := UNDERFLOW;
        RETURN
      END (* IF *)
    ELSIF (x >= 0) & (y < 0) THEN
      IF (y # - 1) & (MIN (INTEGER) DIV y < x) THEN
        rc := UNDERFLOW;
        RETURN
      END (* IF *)
    END (* IF *);
    rc := OK;
    z := x * y
  END Mult;


  PROCEDURE Div (x, y : INTEGER; VAR z : INTEGER; VAR rc : RetCode);

  (*  Wenn möglich, werden die Werte von 'x' und 'y' dividiert und der Quotient
   *  in 'z' geliefert.
   *  Bei  'y' = 0  liegt eine undefinierte Berechnung vor.
   *  Bei  'x' = 'MinInt'  und  'y' = - 1  (Vorzeichenumkehr) ist das Ergebnis
   *  zu groß.
   *)

  BEGIN (* Div *)
    IF y = 0 THEN
      rc := ZERODIV;
      RETURN
    ELSIF (x = MIN (INTEGER)) & (y = - 1) THEN
      rc := OVERFLOW;
      RETURN
    END (* IF *);
    rc := OK;
    z := x DIV y
  END Div;


  PROCEDURE Mod (x, y : INTEGER; VAR z : INTEGER; VAR rc : RetCode);

  (*  Wenn möglich, werden die Werte von 'x' und 'y' dividiert und der Rest
   *  in 'z' geliefert.
   *  Bei  'y' = 0  liegt eine undefinierte Berechnung vor.
   *  Bei  'x' = 'MinInt'  und  'y' = - 1  ist das Ergebnis null, aber MOD führt
   *  zu einem Fehler. Deshalb wird dieser Fall getrennt behandelt.
   *)

  BEGIN (* Mod *)
    IF y = 0 THEN
      rc := ZERODIV;
      RETURN
    END (* IF *);
    rc := OK;
    IF (x = MIN (INTEGER)) & (y = - 1) THEN
      z := 0
    ELSE
      z := x MOD y
    END (* IF *)
  END Mod;


END Int.
