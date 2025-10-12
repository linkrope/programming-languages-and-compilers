IMPLEMENTATION MODULE Checks;   (* ProCoLi 04/96 *)

(*  Klassifizierung von S-Ausdrücken / Überprüfung von Argumentlisten
 *)


  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) isPairPtr, isNumb,
                    Value,
                    LeftPart, RightPart,
                    Flag;

  FROM Errors IMPORT
    (* VAR       *) Abort,
    (* TYPE      *) ErrPos, ErrMsg,
    (* PROCEDURE *) Error;


  PROCEDURE isAtom (sx : SExpr) : BOOLEAN;

  (*  Es wird getestet, ob 'sx' ein gekennzeichneter Zeiger auf ein Paar, eine
   *  ganze Zahl oder der ausgezeichnete S-Ausdruck 'Nil' ist, ...
   *)

  BEGIN (* isAtom *)
    RETURN Flag (sx) OR isNumb (sx) OR (sx = Nil)
  END isAtom;


  PROCEDURE isInt (sx : SExpr) : BOOLEAN;

  (*  ... ob 'sx' eine ganze Zahl ohne Kennzeichnung ist, ...
   *)

  BEGIN (* isInt *)
    RETURN isNumb (sx) & NOT Flag (sx)
  END isInt;


  PROCEDURE isCode (sx : SExpr) : BOOLEAN;

  (*  ... ob 'sx' ein Interpreter-Code ist, ...
   *)

  BEGIN (* isCode *)
    RETURN isNumb (sx) & Flag (sx)
  END isCode;


  PROCEDURE isPList (sx : SExpr) : BOOLEAN;

  (*  ... ob 'sx' ein gekennzeichneter Zeiger auf ein Paar ist, ...
   *)

  BEGIN (* isPList *)
    RETURN isPairPtr (sx) & Flag (sx)
  END isPList;


  PROCEDURE isInd (sx : SExpr) : BOOLEAN;

  (*  ... oder ob 'sx' eine ganze Zahl ohne Kennzeichnung oder ein
   *  gekennzeichneter Zeiger auf ein Paar ist.
   *)

  BEGIN (* isInd *)
    RETURN isPairPtr (sx) = Flag (sx)
  END isInd;


  PROCEDURE Check0Args (Pos : ErrPos; ArgList : SExpr);

  (*  Es wird überprüft, ob 'ArgList' eine leere Liste ist, ...
   *)

  BEGIN (* Check0Args *)
    IF NOT isAtom (ArgList) THEN
      Error (Pos, TooManyArgs)
    ELSIF ArgList # Nil THEN
      Error (Pos, ListExpected)
    END (* IF *)
  END Check0Args;


  PROCEDURE Check1Arg (Pos : ErrPos; ArgList : SExpr;
                       VAR Arg : SExpr);

  (*  ... ob 'ArgList' eine Liste mit einer Komponente ist, ...
   *)

  BEGIN (* Check1Arg *)
    IF isAtom (ArgList) THEN
      Error (Pos, TooFewArgs)
    ELSE
      Arg := LeftPart (ArgList);
      Check0Args (Pos, RightPart (ArgList))
    END (* IF *)
  END Check1Arg;


  PROCEDURE Check2Args (Pos : ErrPos; ArgList : SExpr;
                        VAR Arg1, Arg2 : SExpr);

  (*  ... ob 'ArgList' eine Liste mit zwei Komponenten ist, ...
   *)

  BEGIN (* Check2Args *)
    IF isAtom (ArgList) THEN
      Error (Pos, TooFewArgs)
    ELSE
      Arg1 := LeftPart (ArgList);
      Check1Arg (Pos, RightPart (ArgList), Arg2)
    END (* IF *)
  END Check2Args;


  PROCEDURE Check3Args (Pos : ErrPos; ArgList : SExpr;
                        VAR Arg1, Arg2, Arg3 : SExpr);

  (*  ... oder ob 'ArgList' eine Liste mit drei Komponenten ist.
   *)

  BEGIN (* Check3Args *)
    IF isAtom (ArgList) THEN
      Error (Pos, TooFewArgs)
    ELSE
      Arg1 := LeftPart (ArgList);
      Check2Args (Pos, RightPart (ArgList), Arg2, Arg3)
    END (* IF *)
  END Check3Args;


  PROCEDURE Check1Int (Pos : ErrPos; ArgList : SExpr;
                       VAR Int : INTEGER);

  (*  Es wird überprüft, ob 'ArgList' eine Liste mit einer ganzen Zahl als
   *  Komponente ist, ...
   *)

    VAR
      Arg : SExpr;

  BEGIN (* Check1Int *)
    Check1Arg (Pos, ArgList, Arg);
    IF NOT Abort THEN
      IF isInt (Arg) THEN
        Int := Value (Arg)
      ELSE
        Error (Pos, IntExpected)
      END (* IF *)
    END (* IF *)
  END Check1Int;


  PROCEDURE Check2Ints (Pos : ErrPos; ArgList : SExpr;
                        VAR Int1, Int2 : INTEGER);

  (*  ... oder ob 'ArgList' eine Liste mit zwei ganzen Zahlen als Komponenten
   *  ist.
   *)

    VAR
      Arg1, Arg2 : SExpr;

  BEGIN (* Check2Ints *)
    Check2Args (Pos, ArgList, Arg1, Arg2);
    IF NOT Abort THEN
      IF isInt (Arg1) & isInt (Arg2) THEN
        Int1 := Value (Arg1);
        Int2 := Value (Arg2)
      ELSE
        Error (Pos, IntExpected)
      END
    END (* IF *)
  END Check2Ints;


END Checks.
