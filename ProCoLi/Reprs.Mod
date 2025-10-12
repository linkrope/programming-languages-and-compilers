IMPLEMENTATION MODULE Reprs;   (* ProCoLi 02/94 *)

(*  Repräsentationen von Namen
 *
 *  Die Repräsentationstabelle ist durch ein Zeichenfeld implementiert, das die
 *  Repräsentationen und am Ende den Pufferinhalt, jeweils getrennt mit einem
 *  Sonderzeichen, in der Reihenfolge ihrer Eintragung enthält.
 *  Als Codierung einer Repräsentation wird der um eins verminderte Anfangs-
 *  index der Zeichenfolge verwendet.
 *  Am Anfang liegt der Puffer am Beginn der Tabelle und ist leer.
 *)


  FROM FIO IMPORT
    (* PROCEDURE *) WrChar;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem;

  FROM GarbageCollector IMPORT
    (* PROCEDURE *) CollectChars;


  CONST
    STOP    = 0C;              (* Trennzeichen                      *)

    TabSize = 5000;            (* Größe der Repräsentationstabelle  *)

  VAR
    Tab    : ARRAY [1 .. TabSize] OF CHAR;

    Buf,                       (* "Anfang" des Pufferbereichs       *)
    BufLen : CARDINAL;         (* Größe des Pufferbereichs          *)


  PROCEDURE AppChar (c : CHAR);

  (*  Wenn möglich, wird der Pufferbereich vergrößert und das Zeichen 'c' hinten
   *  an die Zeichenfolge angehängt.
   *)

  BEGIN (* AppChar *)
    IF Buf + BufLen >= TabSize THEN
      CollectChars;
      IF OutOfMem THEN
        RETURN
      END (* IF *)
    END (* IF *);
    INC (BufLen);
    Tab [Buf + BufLen] := c
  END AppChar;


  PROCEDURE eqBuf (Repr : CARDINAL) : BOOLEAN;

  (*  Der Pufferinhalt wird zeichenweise mit der durch 'Repr' codierten Zeichen-
   *  folge verglichen. Beide müssen die gleiche Länge haben.
   *)

    VAR
      i : CARDINAL;

  BEGIN (* eqBuf *)
    FOR i := 1 TO BufLen DO
      IF Tab [Buf + i] # Tab [Repr + i] THEN
        RETURN FALSE
      END (* IF *)
    END (* FOR *);
    RETURN Tab [Repr + BufLen + 1] = STOP
  END eqBuf;


  PROCEDURE ClearBuf;

  (*  Der Puffer wird gelöscht, indem seine Länge auf Null gesetzt wird.
   *)

  BEGIN (* ClearBuf *)
    BufLen := 0
  END ClearBuf;


  PROCEDURE EnterBuf (VAR Repr : CARDINAL);

  (*  Wenn möglich, wird die Zeichenfolge im Puffer mit einem Trennzeichen
   *  abgeschlossen. Dann wird der "Anfang" des Pufferbereichs als Codierung der
   *  Repräsentation geliefert und ein neuer leerer Puffer im nachfolgenden
   *  freien Teil der Tabelle angelegt.
   *)

  BEGIN (* EnterBuf *)
    AppChar (STOP);
    IF OutOfMem THEN
      RETURN
    END (* IF *);
    Repr := Buf;
    INC (Buf, BufLen);
    BufLen := 0
  END EnterBuf;


  PROCEDURE WriteRepr (f : File; Repr : CARDINAL);

  (*  Die durch 'Repr' codierte Zeichenfolge wird zeichenweise ausgegeben.
   *)

    VAR
      i : CARDINAL;

  BEGIN (* WriteRepr *)
    i := 1;
    WHILE Tab [Repr + i] # STOP DO
      WrChar (f, Tab [Repr + i]);
      INC (i)
    END (* WHILE *)
  END WriteRepr;


  VAR
    LastUsed : CARDINAL;         (* Ende des kompakten Bereichs  *)


  PROCEDURE MoveRepr (VAR Repr :CARDINAL);

  (*  Die durch 'Repr' codierte Zeichenfolge wird zeichenweise nach vorn hinter
   *  das Ende des kompakten Bereichs kopiert. Dadurch wird dieser vergrößert,
   *  und die Codierung der Zeichenfolge kann sich ändern.
   *)

    VAR
      i : CARDINAL;

  BEGIN (* MoveRepr *)
    i := 0;
    REPEAT
      INC (i);
      Tab [LastUsed + i] := Tab [Repr + i]
    UNTIL Tab [Repr + i] = STOP;
    Repr := LastUsed;
    INC (LastUsed, i)
  END MoveRepr;


  PROCEDURE EndCompactReprs (VAR Len : CARDINAL);

  (*  Zum Abschluß der Kompaktifizierung muß noch der Pufferbereich verschoben
   *  werden. Die Größe des freien Teils der Repräsentationstabelle wird
   *  bestimmt, und die nächste Kompaktifizierung wird vorbereitet.
   *)

    VAR
      i : CARDINAL;

  BEGIN (* EndCompactReprs *)
    FOR i := 1 TO BufLen DO
      Tab [LastUsed + i] := Tab [Buf + i]
    END (* FOR *);
    Buf := LastUsed;
    INC (LastUsed, BufLen);
    Len := TabSize - LastUsed;
    LastUsed := 0
  END EndCompactReprs;


BEGIN (* Reprs *)
  Buf := 0;
  BufLen := 0;
  LastUsed := 0
END Reprs.
