IMPLEMENTATION MODULE Stacks;   (* ProCoLi 06/92 *)

(*  Datentyp "Keller"
 *
 *  Die Keller werden als LISP-Listen dargestellt, wobei die leere Liste einem
 *  leeren Keller entspricht und die erste Komponente der Liste das oberste
 *  Kellerelement ist.
 *)


  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) AssignPair, LeftPart, RightPart;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem;

  FROM FreeList IMPORT
    (* PROCEDURE *) NewPair, FreePair;


  PROCEDURE isEmptyStack (Stack : SExpr) : BOOLEAN;

  (*  Es wird getestet, ob 'Stack' die leere Liste ist.
   *)

  BEGIN (* isEmptyStack *)
    RETURN Stack = Nil
  END isEmptyStack;


  PROCEDURE EmptyStack () : SExpr;

  (*  Die leere Liste wird geliefert.
   *)

  BEGIN (* EmptyStack *)
    RETURN Nil
  END EmptyStack;


  PROCEDURE Top (Stack : SExpr) : SExpr;

  (*  Die erste Komponente der nichtleeren Liste 'Stack' wird geliefert.
   *)

  BEGIN (* Top *)
    RETURN LeftPart (Stack)
  END Top;


  PROCEDURE Push (VAR Stack : SExpr; sx : SExpr);

  (*  Wenn möglich, wird der S-Ausdruck 'sx' vorn an die Liste 'Stack'
   *  angehängt.
   *)

    VAR
      PairPtr : SExpr;

  BEGIN (* Push *)
    NewPair (PairPtr);
    IF NOT OutOfMem THEN
      AssignPair (PairPtr, sx, Stack);
      Stack := PairPtr
    END (* IF *)
  END Push;


  PROCEDURE Pop (VAR Stack, sx : SExpr);

  (*  Die erste Komponente der nichtleeren Liste 'Stack' wird in 'sx'
   *  geliefert und aus der Liste entfernt. Das zur Verkettung verwendete Paar
   *  wird freigegeben.
   *)

    VAR
      PairPtr : SExpr;

  BEGIN (* Pop *)
    PairPtr := Stack;
    sx    := LeftPart  (PairPtr);
    Stack := RightPart (PairPtr);
    FreePair (PairPtr)
  END Pop;


END Stacks.
