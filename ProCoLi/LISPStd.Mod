IMPLEMENTATION MODULE LISPStd;   (* ProCoLi 06/92 *)

(*  Standard-LISP-Funktionen und -Prädikate
 *)


  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) AssignPair, LeftPart, RightPart, HitCount,
                    ReplLeftPart, ReplRightPart, ReplHitCount;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem,
                    Args, Val;

  FROM FreeList IMPORT
    (* PROCEDURE *) NewPair;

  FROM PLists IMPORT
    (* PROCEDURE *) GetProp, PutProp, RemProp;

  FROM Errors IMPORT
    (* TYPE      *) ErrPos, ErrMsg,
    (* VAR       *) Abort,
    (* PROCEDURE *) Error;

  FROM Checks IMPORT
    (* PROCEDURE *) isAtom, isInt, isPList, isInd,
                    Check1Arg, Check2Args, Check3Args;

  FROM LISPBase IMPORT
    (* VAR       *) NilPList, ExprPList,
    (* PROCEDURE *) Bool;


  PROCEDURE ConsSubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben. Ein neues Paar mit den
   *  beiden S-Ausdrücken als Linksteil bzw. Rechtsteil wird erzeugt.
   *)

    VAR
      sx1, sx2 : SExpr;

  BEGIN (* ConsSubr *)
    Check2Args (CONSSUBR, Args, sx1, sx2);
    IF NOT Abort THEN
      NewPair (Val);
      IF OutOfMem THEN
        Error (CONSSUBR, StorageExhausted)
      ELSE
        AssignPair (Val, sx1, sx2)
      END (* IF *)
    END (* IF *)
  END ConsSubr;


  PROCEDURE CARSubr;

  (*  Die Argumentliste muß genau eine Komponente haben, die ein Paar ist.
   *  Der Linksteil des Paars wird geliefert, ...
   *)

  BEGIN (* CARSubr *)
    Check1Arg (CARSUBR, Args, Val);
    IF NOT Abort THEN
      IF isAtom (Val) THEN
        Error (CARSUBR, AtomUnexpected)
      ELSE
        Val := LeftPart (Val)
      END (* IF *)
    END (* IF *)
  END CARSubr;


  PROCEDURE CDRSubr;

  (*  ... oder der Rechtsteil des Paars wird geliefert.
   *)

  BEGIN (* CDRSubr *)
    Check1Arg (CDRSUBR, Args, Val);
    IF NOT Abort THEN
      IF isAtom (Val) THEN
        Error (CDRSUBR, AtomUnexpected)
      ELSE
        Val := RightPart (Val)
      END (* IF *)
    END (* IF *)
  END CDRSubr;


  PROCEDURE AtomSubr;

  (*  Die Argumentliste muß genau eine Komponente haben. Es wird überprüft, ob
   *  der S-Ausdruck ein Atom ist.
   *)

  BEGIN (* AtomSubr *)
    Check1Arg (ATOMSUBR, Args, Val);
    IF NOT Abort THEN
      Val := Bool (isAtom (Val))
    END (* IF *)
  END AtomSubr;


  PROCEDURE EqSubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben. Es wird überprüft, ob
   *  die beiden S-Ausdrücke identisch sind.
   *)

    VAR
      sx1, sx2 : SExpr;

  BEGIN (* EqSubr *)
    Check2Args (EQSUBR, Args, sx1, sx2);
    IF NOT Abort THEN
      Val := Bool (sx1 = sx2)
    END (* IF *)
  END EqSubr;


  PROCEDURE NotSubr;

  (*  Die Argumentliste muß genau eine Komponente haben. Es wird überprüft, ob
   *  der S-Ausdruck gleich 'Nil' ist, ...
   *)

  BEGIN (* NotSubr *)
    Check1Arg (NOTSUBR, Args, Val);
    IF NOT Abort THEN
      Val := Bool (Val = Nil)
    END (* IF *)
  END NotSubr;


  PROCEDURE NumberPSubr;

  (*  ... oder ob der S-Ausdruck eine ganze Zahl bezeichnet.
   *)

  BEGIN (* NumberPSubr *)
    Check1Arg (NUMBERPSUBR, Args, Val);
    IF NOT Abort THEN
      Val := Bool (isInt (Val))
    END (* IF *)
  END NumberPSubr;


  PROCEDURE RPlacASubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben, von denen die erste
   *  ein Paar ist. Der Linksteil des Paars wird durch den zweiten S-Ausdruck
   *  ersetzt, ...
   *)

    VAR
      sx : SExpr;

  BEGIN (* RPlacASubr *)
    Check2Args (RPLACASUBR, Args, Val, sx);
    IF NOT Abort THEN
      IF isAtom (Val) THEN
        Error (RPLACASUBR, AtomUnexpected)
      ELSE
        ReplLeftPart (Val, sx)
      END (* IF *)
    END (* IF *)
  END RPlacASubr;


  PROCEDURE RPlacDSubr;

  (*  ... oder der Rechtsteil des Paars wird durch den zweiten S-Ausdruck
   *  ersetzt.
   *)

    VAR
      sx : SExpr;

  BEGIN (* RPlacDSubr *)
    Check2Args (RPLACDSUBR, Args, Val, sx);
    IF NOT Abort THEN
      IF isAtom (Val) THEN
        Error (RPLACDSUBR, AtomUnexpected)
      ELSE
        ReplRightPart (Val, sx)
      END (* IF *)
    END (* IF *)
  END RPlacDSubr;


  PROCEDURE CheckPListAndInd (Pos : ErrPos; VAR PList, Ind : SExpr);

  (*  Mit 'CheckPListAndInd (Pos, PList, Ind)' wird getestet, ob 'PList' eine
   *  Property-Liste und 'Ind' ein Indikator ist. Der ausgezeichnete S-Ausdruck
   *  'Nil' wird dabei durch den Namen "NIL" ersetzt.
   *  Im Fehlerfall wird eine Meldung mit dem Fehlerort 'Pos' ausgegeben.
   *)

  BEGIN (* CheckPListAndInd *)
    IF NOT isPList (PList) THEN
      IF PList = Nil THEN
        PList := NilPList
      ELSE
        Error (Pos, PListExpected);
        RETURN
      END (* IF *)
    END (* IF *);
    IF NOT isInd (Ind) THEN
      IF Ind = Nil THEN
        Ind := NilPList
      ELSE
        Error (Pos, IndExpected)
      END (* IF *)
    END (* IF *)
  END CheckPListAndInd;


  PROCEDURE DefineSubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben, von denen die erste
   *  eine Property-Liste ist. Ein Eintrag unter dem Indikator EXPR mit dem
   *  zweiten S-Ausdruck als Eigenschaft wird erzeugt.
   *)

    VAR
      Fun : SExpr;

  BEGIN (* DefineSubr *)
    Check2Args (DEFINESUBR, Args, Val, Fun);
    IF NOT Abort THEN
      CheckPListAndInd (PUTPROPSUBR, Val, ExprPList);
      IF NOT Abort THEN
        PutProp (Val, ExprPList, Fun);
        IF OutOfMem THEN
          Error (DEFINESUBR, StorageExhausted)
        END (* IF *)
      END (* IF *)
    END (* IF *)
  END DefineSubr;


  PROCEDURE GetSubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben, von denen die erste
   *  eine Property-Liste und die zweite ein Indikator ist. Die Eigenschaft des
   *  entsprechenden Eintrags wird geliefert.
   *)

    VAR
      PList, Ind : SExpr;
      Valid      : BOOLEAN;

  BEGIN (* GetSubr *)
    Check2Args (GETSUBR, Args, PList, Ind);
    IF NOT Abort THEN
      CheckPListAndInd (GETSUBR, PList, Ind);
      IF NOT Abort THEN
        GetProp (PList, Ind, Val, Valid);
        IF NOT Valid THEN
          Val := Nil
        END (* IF *)
      END (* IF *)
    END (* IF *)
  END GetSubr;


  PROCEDURE PutPropSubr;

  (*  Die Argumentliste muß genau drei Komponenten haben, von denen die erste
   *  eine Property-Liste und die zweite ein Indikator ist. Ein entsprechender
   *  Eintrag mit dem dritten S-Ausdruck als Eigenschaft wird erzeugt.
   *)

    VAR
      PList, Ind : SExpr;

  BEGIN (* PutPropSubr *)
    Check3Args (PUTPROPSUBR, Args, PList, Ind, Val);
    IF NOT Abort THEN
      CheckPListAndInd (PUTPROPSUBR, PList, Ind);
      IF NOT Abort THEN
        PutProp (PList, Ind, Val);
        IF OutOfMem THEN
          Error (PUTPROPSUBR, StorageExhausted)
        END (* IF *)
      END (* IF *)
    END (* IF *)
  END PutPropSubr;


  PROCEDURE RemPropSubr;

  (*  Die Argumentliste muß genau zwei Komponenten haben, von denen die erste
   *  eine Property-Liste und die zweite ein Indikator ist. Der entsprechende
   *  Eintrag wird gelöscht.
   *)

    VAR
      PList, Ind : SExpr;

  BEGIN (* RemPropSubr *)
    Check2Args (REMPROPSUBR, Args, PList, Ind);
    IF NOT Abort THEN
      CheckPListAndInd (REMPROPSUBR, PList, Ind);
      IF NOT Abort THEN
        RemProp (PList, Ind);
        Val := Nil
      END (* IF *)
    END (* IF *)
  END RemPropSubr;


END LISPStd.
