IMPLEMENTATION MODULE Bindings;   (* ProCoLi 06/92 *)

(*  Variablenbindung
 *
 *  Die aktuellen Werte von gebundenen Variablen sind in den entsprechenden
 *  Property-Listen eingetragen. Der Bindungskeller 'Env' enthält dagegen die
 *  Informationen zum Lösen von Bindungen. Dabei bezieht sich das oberste
 *  Kellerelement immer auf die zuletzt gebundene Variable.
 *  Für eine vorher ungebundene Variable liegt nur ihr Name auf dem Keller,
 *  während eine vorher gebundene Variable durch ein Paar aus dem Namen und dem
 *  altem Wert angezeigt wird.
 *)


  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) AssignPair, LeftPart, RightPart;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem,
                    Expr,
                    Env;

  FROM FreeList IMPORT
    (* PROCEDURE *) NewPair, FreePair;

  FROM Stacks IMPORT
    (* PROCEDURE *) isEmptyStack,
                    Push, Pop;

  FROM PLists IMPORT
    (* PROCEDURE *) GetProp, PutProp, RemProp;

  FROM Errors IMPORT
    (* TYPE      *) ErrPos, ErrMsg,
    (* PROCEDURE *) Error;

  FROM Checks IMPORT
    (* PROCEDURE *) isAtom, isPList;

  FROM LISPBase IMPORT
    (* VAR       *) NilPList,
                    VarPList;


  PROCEDURE Bind (Var, Arg : SExpr);

  (*  Zuerst wird überprüft, ob 'Var' eine Property-Liste ist. Der
   *  ausgezeichnete S-Ausdruck 'Nil' wird dabei durch den Namen "NIL" ersetzt.
   *  Im Fehlerfall wird eine Meldung ausgegeben.
   *  Sonst wird der Wert der alten Bindung in der Property-Liste bestimmt.
   *  Existiert ein solcher Wert, so wird ein Paar aus dem Namen der Variablen
   *  und diesem Wert gebildet und auf den Bindungskeller gelegt. Andernfalls
   *  war die Variable bisher ungebunden, und nur ihr Name wird auf dem Keller
   *  abgelegt.
   *  Der neue Wert wird in die Property-Liste eingetragen. Kommt es zu einem
   *  Speicherüberlauf, so muß die Information zum Lösen der (nicht durch-
   *  geführten) Bindung vom Keller entfernt werden.
   *)

    VAR
      Old   : SExpr;
      Valid : BOOLEAN;

  BEGIN (* Bind *)
    IF Var = Nil THEN
      Var := NilPList
    ELSIF NOT isPList (Var) THEN
      Error (BIND, PListExpected);
      RETURN
    END (* IF *);
    GetProp (Var, VarPList, Old, Valid);
    IF Valid THEN
      NewPair (Expr);
      IF NOT OutOfMem THEN
        AssignPair (Expr, Var, Old);
        Push (Env, Expr);
        Expr := Nil
      END (* IF *);
      IF OutOfMem THEN
        Error (BIND, StorageExhausted);
        RETURN
      END (* IF *);
      PutProp (Var, VarPList, Arg)
    ELSE (* isUnBound (Var) *)
      Push (Env, Var);
      IF OutOfMem THEN
        Error (BIND, StorageExhausted);
        RETURN
      END (* IF *);
      PutProp (Var, VarPList, Arg);
      IF OutOfMem THEN
        Error (BIND, StorageExhausted);
        Pop (Env, Var)
      END (* IF *)
    END (* IF *)
  END Bind;


  PROCEDURE UnBind;

  (*  Die zuletzt durchgeführte Bindung wird gelöst. Ein Atom auf dem Bindungs-
   *  keller zeigt eine vorher ungebundene Variable an. Sonst liegt ein Paar aus
   *  Name und Wert auf dem Keller, das nach dem Wiederherstellen der alten
   *  Bindung freigegeben werden kann.
   *)

  BEGIN (* UnBind *)
    Pop (Env, Expr);
    IF isAtom (Expr) THEN
      RemProp (Expr, VarPList)
    ELSE
      PutProp (LeftPart (Expr), VarPList, RightPart (Expr));
      FreePair (Expr)
    END (* IF *);
    Expr := Nil
  END UnBind;


  PROCEDURE UnBindAll;

  (*  Alle Bindungen werden gelöst.
   *)

  BEGIN (* UnBindAll *)
    WHILE NOT isEmptyStack (Env) DO
      UnBind
    END (* WHILE *)
  END UnBindAll;


END Bindings.
