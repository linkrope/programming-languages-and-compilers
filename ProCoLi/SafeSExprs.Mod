IMPLEMENTATION MODULE SafeSExprs;

(*  Sicherheitsumschlag für das Modul "SExprs".
 *
 *  Autor: mdiers 11.10.93
 *
 *  Änderungen:
 *    mdiers 18.10.93 -- Behandlung von Nil-Zugriffen erweitert
 *                       und aufgeräumt.
 *    mdiers 04.11.93 -- Funktionsfähigkeit überprüft
 *    kan    09.06.94 -- (Nochmal) umgestellt auf TopSpeed-Modula-2.
 *    kan    28.03.95 -- Sicherheitslücken geflickt.
 *)


  FROM FIO IMPORT
    (* VAR       *) StandardOutput,
    (* PROCEDURE *) WrLn, WrStr;

  IMPORT SExprs;
    (*  unqualifizierter Import, da sonst Namenskonflikte mit den
        gleichlautenden Bezeichnern dieses Moduls.
     *)


  (*  Nun denn, wo und wie ist das Programm denn nun gescheitert?
   *)

  TYPE
    FatalError = (NilOp, NilAccess, NotANumber, NotAPair);


  PROCEDURE Bomb (error : FatalError; where : ARRAY OF CHAR);
  BEGIN
    WrLn (StandardOutput);
    WrStr (StandardOutput, "------------------------------------------------------------------------------");
    WrLn (StandardOutput);
    WrLn (StandardOutput);
    WrStr (StandardOutput, "Au weia! Fataler Fehler im Modul 'SafeSExprs', Prozedur '");
    WrStr (StandardOutput, where);
    WrStr (StandardOutput, "':");
    WrLn (StandardOutput);
    WrLn (StandardOutput);
    WrStr (StandardOutput, "  ");
    CASE error OF
      NilOp:
        WrStr (StandardOutput, "das mache ich nicht mit SExprs.Nil!");
    | NilAccess:
        WrStr (StandardOutput, "kann auf Teile von SExprs.Nil nicht zugreifen")
    | NotANumber:
        WrStr (StandardOutput, "der dieser Prozedur übergebene S-Ausdruck ist keine Zahl")
    | NotAPair:
        WrStr (StandardOutput, "der dieser Prozedur übergebene S-Ausdruck ist kein Paar")
    END;
    WrStr (StandardOutput, "!");
    WrLn (StandardOutput);
    WrLn (StandardOutput);
    WrStr (StandardOutput, "Brzzzt! Wrong... you lose.");
    WrLn (StandardOutput);
    WrLn (StandardOutput);
    WrStr (StandardOutput, "------------------------------------------------------------------------------");
    HALT
  END Bomb;


  (*  Prädikate werden direkt abgebildet auf die zugrundeliegenden
      Funktionen in SExprs.
   *)

  PROCEDURE isPairPtr (sx : SExpr) : BOOLEAN;
  BEGIN
    RETURN SExprs.isPairPtr (sx)
  END isPairPtr;


  PROCEDURE isNumb (sx : SExpr) : BOOLEAN;
  BEGIN
    RETURN SExprs.isNumb (sx)
  END isNumb;


  (*  Überprüfung des Parameters geschieht durch Compiler und Laufzeitsystem.
   *)

  PROCEDURE Numb (Value : INTEGER) : SExpr;
  BEGIN
    RETURN SExprs.Numb (Value)
  END Numb;


  (*  Die folgenden Prozeduren sind potentielle Kandidaten für den GAU.
      Deshalb müssen kritische Parameter überprüft werden, bevor schließlich
      die "verletzlichen" Prozeduren aus SExprs aufgerufen werden dürfen.
   *)

  PROCEDURE Value (Numb : SExpr) : INTEGER;
  BEGIN
    IF isNumb (Numb) THEN
      RETURN SExprs.Value (Numb)
    ELSIF Numb = Nil THEN
      Bomb (NilOp, "Value")
    ELSE
      Bomb (NotANumber, "Value")
    END
  END Value;


  PROCEDURE AssignPair (VAR PairPtr : SExpr; LeftPart, RightPart : SExpr);
  BEGIN
    IF PairPtr = Nil THEN
      Bomb (NilOp, "AssignPair")
    ELSIF isPairPtr (PairPtr) THEN
      SExprs.AssignPair (PairPtr, LeftPart, RightPart)
    ELSE
      Bomb (NotAPair, "AssignPair")
    END
  END AssignPair;


  PROCEDURE LeftPart (PairPtr : SExpr) : SExpr;
  BEGIN
    IF PairPtr = Nil THEN
      Bomb (NilAccess, "LeftPart")
    ELSIF isPairPtr (PairPtr) THEN
      RETURN SExprs.LeftPart (PairPtr)
    ELSE
      Bomb (NotAPair, "LeftPart")
    END
  END LeftPart;


  PROCEDURE RightPart (PairPtr : SExpr) : SExpr;
  BEGIN
    IF PairPtr = Nil THEN
      Bomb (NilAccess, "RightPart")
    ELSIF isPairPtr (PairPtr) THEN
      RETURN SExprs.RightPart (PairPtr)
    ELSE
      Bomb (NotAPair, "RightPart")
    END
  END RightPart;


  PROCEDURE HitCount (PairPtr : SExpr) : CARDINAL;
  BEGIN
    IF PairPtr = Nil THEN
      Bomb (NilOp, "HitCount")
    ELSIF isPairPtr (PairPtr) THEN
      RETURN SExprs.HitCount (PairPtr)
    ELSE
      Bomb (NotAPair, "HitCount")
    END
  END HitCount;


  PROCEDURE ReplLeftPart (PairPtr, LeftPart : SExpr);
  BEGIN
    IF PairPtr = Nil THEN
      Bomb (NilOp, "ReplLeftPart")
    ELSIF isPairPtr (PairPtr) THEN
      SExprs.ReplLeftPart (PairPtr, LeftPart)
    ELSE
      Bomb (NotAPair, "ReplLeftPart")
    END
  END ReplLeftPart;


  PROCEDURE ReplRightPart (PairPtr, RightPart : SExpr);
  BEGIN
    IF PairPtr = Nil THEN
      Bomb (NilOp, "ReplRightPart")
    ELSIF isPairPtr (PairPtr) THEN
      SExprs.ReplRightPart (PairPtr, RightPart)
    ELSE
      Bomb (NotAPair, "ReplRightPart")
    END
  END ReplRightPart;


  PROCEDURE ReplHitCount (PairPtr : SExpr; HitCount : CARDINAL);
  BEGIN
    IF PairPtr = Nil THEN
      Bomb (NilOp, "ReplHitCount")
    ELSIF isPairPtr (PairPtr) THEN
      SExprs.ReplHitCount (PairPtr, HitCount)
    ELSE
      Bomb (NotAPair, "ReplHitCount")
    END
  END ReplHitCount;


  PROCEDURE SetFlag (VAR sx : SExpr);
  BEGIN
    IF sx = Nil THEN
      Bomb (NilOp, "SetFlag")
    ELSE
      SExprs.SetFlag (sx)
    END
  END SetFlag;


  PROCEDURE Flag (sx : SExpr) : BOOLEAN;
  BEGIN
    RETURN SExprs.Flag (sx)
  END Flag;


  (*  Hier kann's ein letztes Mal daneben gehen.
   *)

  PROCEDURE NextPair (VAR PairPtr : SExpr; VAR Valid : BOOLEAN);
  BEGIN
    IF PairPtr = Nil THEN
      Bomb (NilOp, "NextPair")
    ELSIF isPairPtr (PairPtr) THEN
      SExprs.NextPair (PairPtr, Valid)
    ELSE
      Bomb (NotAPair, "NextPair")
    END
  END NextPair;


BEGIN
  FirstPair := SExprs.FirstPair;
  Nil := SExprs.Nil
END SafeSExprs.
