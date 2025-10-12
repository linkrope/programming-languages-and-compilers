IMPLEMENTATION MODULE SExprs;   (* ProCoLi 04/96 *)

(*  Datentyp "S-Ausdruck" / Bereitstellung eines Pools von Paaren
 *
 *  In dieser Implementierung, die eine leichte Transliteration nach Oberon
 *  und desweiteren den Programmierpraktikanten symbolisches Debugging von
 *  S-Ausdrücken ermöglichen soll, sind S-Ausdrücke und Paare genau getreu
 *  der Modellvorstellung implementiert, d.h. gegenüber der damit verbundenen
 *  Speicherineffizienz wird den Gesichtspunkten übersichtlicher
 *  Implementierbarkeit (u. möglicherweise auch günstigerer Laufzeiteffizienz)
 *  und unkomplizierterem Debugging vorrangige Bedeutung eingeräumt.
 *
 *  'Nil' weist aus "Sicherheitsgründen" auf ein besonderes nulltes Paar,
 *  welches nicht per 'FirstPair'/'NextPair' aufzählbar ist. Damit sollen
 *  desaströse Folgen "versehentlicher" Dereferenzierungen von 'Nil'
 *  gemildert werden.
 *
 *  Schwäche dieser Implementierung auf Intel 8086-Basis u. TopSpeed-
 *  Modula-2 ist die Beschränkung des für Paare erlaubten Gesamt-Speicher-
 *  bedarfs auf 64K Byte. Da diese Beschränkung auch für dynamisch allozierte
 *  Objekte gilt, wurde sogar gänzlich auf dynamische Allokation verzichtet.
 *)


  FROM FIO IMPORT
    (* CONST     *) StandardOutput,
    (* PROCEDURE *) WrLn, WrStr;



(*$I-,O-,R-,S-,W-,Z-   Top-Speed-Modula2: Compiler-Checks aus *)

  PROCEDURE isPairPtr (sx : SExpr) : BOOLEAN;

  (*  Wenn 'NUMB' nicht gesetzt ist, bezeichnet 'sx' einen Zeiger auf ein Paar.
   *)

  BEGIN (* isPairPtr *)
    RETURN sx.Kind = PAIRPTR
  END isPairPtr;


  PROCEDURE isNumb (sx : SExpr) : BOOLEAN;

  (*  Wenn 'NUMB' gesetzt ist, bezeichnet 'sx' eine Zahl.
   *)

  BEGIN (* isNumb *)
    RETURN sx.Kind = NUMB
  END isNumb;


  PROCEDURE Numb (Value : INTEGER) : SExpr;

  (*  Ein S-Ausdruck, der eine ganze Zahl mit dem Wert 'Value' bezeichnet, wird
   *  geliefert.
   *)

    VAR
      sx : SExpr;

  BEGIN (* Numb *)
    sx.Flag := FALSE;
    sx.Kind := NUMB;
    sx.Value := Value;
    RETURN sx
  END Numb;


  PROCEDURE Value (Numb : SExpr) : INTEGER;

  (*  Der Wert der durch 'Numb' bezeichneten Zahl wird geliefert.
   *)

  BEGIN (* Value *)
    RETURN Numb.Value
  END Value;


  PROCEDURE AssignPair (VAR PairPtr : SExpr; LeftPart, RightPart : SExpr);

  (*  Der Linksteil und der Rechtsteil des Paars, auf das der durch 'PairPtr'
   *  bezeichnete Zeiger weist, werden durch 'LeftPart' bzw. 'RightPart'
   *  ersetzt. Ferner werden der Trefferzähler dieses Paars auf Null gesetzt
   *  und die Kennzeichnung von 'PairPtr' zurückgesetzt.
   *)

  BEGIN (* AssignPair *)
    Pool[PairPtr.PairPtr].LeftPart := LeftPart;
    Pool[PairPtr.PairPtr].RightPart := RightPart;
    Pool[PairPtr.PairPtr].HitCount := 0;
    PairPtr.Flag := FALSE;
  END AssignPair;


  PROCEDURE LeftPart (PairPtr : SExpr) : SExpr;

  (*  Der Linksteil des Paares, auf das 'PairPtr' verweist, wird geliefert.
   *)

  BEGIN (* LeftPart *)
    RETURN Pool[PairPtr.PairPtr].LeftPart
  END LeftPart;


  PROCEDURE RightPart (PairPtr : SExpr) : SExpr;

  (*  Der Rechtsteil des Paares, auf das 'PairPtr' verweist, wird geliefert.
   *)

  BEGIN (* RightPart *)
    RETURN Pool[PairPtr.PairPtr].RightPart
  END RightPart;


  PROCEDURE HitCount (PairPtr : SExpr) : CARDINAL;

  (*  Der Trefferzähler des Paars, auf das 'PairPtr' verweist, wird geliefert.
   *)

  BEGIN (* HitCount *)
    RETURN Pool[PairPtr.PairPtr].HitCount
  END HitCount;


  PROCEDURE ReplLeftPart (PairPtr, LeftPart : SExpr);

  (*  Der Linksteil des Paars, aus das 'PairPtr' verweist, wird durch
   *  'LeftPart' ersetzt.
   *)

  BEGIN (* ReplLeftPart *)
    Pool[PairPtr.PairPtr].LeftPart := LeftPart
  END ReplLeftPart;


  PROCEDURE ReplRightPart (PairPtr, RightPart : SExpr);

  (*  Der Rechtsteil des Paars, aus das 'PairPtr' verweist, wird durch
   *  'RightPart' ersetzt.
   *)

  BEGIN (* ReplRightPart *)
    Pool[PairPtr.PairPtr].RightPart := RightPart
  END ReplRightPart;


  PROCEDURE ReplHitCount (PairPtr : SExpr; HitCount : CARDINAL);

  (*  Der Trefferzähler des Paars, auf das 'PairPtr' verweist, wird durch
   *  'HitCount' ersetzt.
   *)

  BEGIN (* ReplHitCount *)
    Pool[PairPtr.PairPtr].HitCount := HitCount
  END ReplHitCount;


  PROCEDURE SetFlag (VAR sx : SExpr);

  (*  Die Kennzeichnung von 'sx' wird gesetzt...
   *)

  BEGIN (* SetFlag *)
    sx.Flag := TRUE
  END SetFlag;


  PROCEDURE Flag (sx : SExpr) : BOOLEAN;

  (*  ... und entsprechend abgefragt.
   *)

  BEGIN (* Flag *)
    RETURN sx.Flag
  END Flag;


  PROCEDURE NextPair (VAR PairPtr : SExpr; VAR Valid : BOOLEAN);

  (*  Der Zeiger auf das nächste Paar im Speicher kann durch einfaches Inkre-
   *  mentieren gewonnen werden.
   *)

  BEGIN (* NextPair *)
    Valid := PairPtr.PairPtr < NrOfPairs - 1;
    IF Valid THEN INC (PairPtr.PairPtr) END
  END NextPair;


  PROCEDURE InitPairs;

  (*  Mit 'InitPairs' wird der Speicher für Paare von S-Ausdrücken reserviert.
   *  Der "Zeiger" 'FirstPair' auf das erste letzte Paar wird gesetzt.
   *  'Nil' wird der gekennzeichnete Zeiger auf das 0-te Paar.
   *)

    VAR
      i  : CARDINAL;
      sx : SExpr;

  BEGIN (* InitPairs *)
    sx.Flag := FALSE;
    sx.Kind := NUMB;
    sx.Value := 0;
    Pool[0].LeftPart := sx;
    Pool[0].RightPart := sx;
    Pool[0].HitCount := 0;
    FOR i := 1 TO NrOfPairs - 1 DO
      Pool[i] := Pool[0]
    END;
    Nil.Flag := FALSE;
    Nil.Kind := PAIRPTR;
    Nil.PairPtr := 0;
    FirstPair.Flag := FALSE;
    FirstPair.Kind := PAIRPTR;
    FirstPair.PairPtr := 1
  END InitPairs;


BEGIN (* SExprs *)
  InitPairs;
END SExprs.
