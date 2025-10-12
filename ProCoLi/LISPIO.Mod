IMPLEMENTATION MODULE LISPIO;   (* ProCoLi 02/94 *)

(*  Ein-/Ausgabe-LISP-Funktionen
 *)


  FROM SExprs IMPORT
    (* VAR       *) Nil;

  FROM Registers IMPORT
    (* VAR       *) Args, Val;

  FROM Errors IMPORT
    (* TYPE      *) ErrMsg, ErrPos,
    (* VAR       *) Abort,
    (* PROCEDURE *) Error;

  FROM Checks IMPORT
    (* PROCEDURE *) Check0Args,
                    Check1Arg, Check1Int;

  FROM SExprIO IMPORT
    (* PROCEDURE *) WriteSExpr, ReadSExpr, NewLine, Spaces;


  PROCEDURE PrintSubr;

  (*  Die Argumentliste darf nur eine Komponente haben, die ausgegeben und im
   *  Register 'Val' geliefert wird. Die Ausgabe wird mit einem Zeilenwechsel
   *  beendet.
   *)

  BEGIN (* PrintSubr *)
    Check1Arg (PRINTSUBR, Args, Val);
    IF NOT Abort THEN
      WriteSExpr
    END (* IF *)
  END PrintSubr;


  PROCEDURE ReadSubr;

  (*  Die Argumentliste muß leer sein. Ein S-Ausdruck wird gelesen und im
   *  Register 'Val' geliefert.
   *)

  BEGIN (* ReadSubr *)
    Check0Args (READSUBR, Args);
    IF NOT Abort THEN
      ReadSExpr
    END (* IF *)
  END ReadSubr;


  PROCEDURE NewLineSubr;

  (*  Die Argumentliste muß leer sein. Es wird ein Zeilen-Vorschub erzeugt.
   *  Register 'Val' enthält dann den Wert NIL.
   *)

  BEGIN (* NewLineSubr *)
    Check0Args (NEWLINESUBR, Args);
    IF NOT Abort THEN
      NewLine
    END (* IF *);
    Val := Nil
  END NewLineSubr;


  PROCEDURE SpacesSubr;

  (*  Die Argumentliste darf nur eine Komponente enthalten. Diese Komponente
   *  muß eine Zahl sein. Register 'Val' enthält anschließend den Wert NIL.
   *)

    VAR x : INTEGER;

  BEGIN (* SpacesSubr *)
    Check1Int (SPACESSUBR, Args, x);
    IF NOT Abort THEN
      IF x < 0 THEN
        Error (SPACESSUBR, NatExpected)
      ELSE
        Spaces (x)
      END (* IF *)
    END (* IF *);
    Val := Nil
  END SpacesSubr;


END LISPIO.
