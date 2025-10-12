IMPLEMENTATION MODULE LISPBase;   (* ProCoLi 02/89 *)

(*  Vordefinierte LISP-Namen
 *)


  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) Numb,
                    AssignPair,
                    SetFlag;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem,
                    Expr, Val,
    (* PROCEDURE *) ResetRegs;

  FROM FreeList IMPORT
    (* PROCEDURE *) NewPair;

  FROM Reprs IMPORT
    (* PROCEDURE *) AppChar,
                    ClearBuf;

  FROM PLists IMPORT
    (* PROCEDURE *) PutProp;

  FROM ObList IMPORT
    (* PROCEDURE *) LookUpBuf;

  FROM Errors IMPORT
    (* TYPE      *) ErrPos, ErrMsg,
    (* PROCEDURE *) FatalError;


  PROCEDURE Bool (b : BOOLEAN) : SExpr;

  (*  Der entsprechende S-Ausdruck wird geliefert.
   *)

  BEGIN (* Bool *)
    IF b THEN
      RETURN TPList
    ELSE
      RETURN Nil
    END (* IF *)
  END Bool;


  PROCEDURE InitBase;

  (*  Die Property-Listen aller vordefinierten Namen werden initialisiert.
   *  Bei Konstanten wird eine Liste der Länge eins im Register 'Val' angelegt.
   *  Die Funktion NULL hat den gleichen Interpreter-Code wie NOT.
   *)

    VAR
      SysPList,
      PList    : SExpr;


    PROCEDURE Code (Ref : FunRef) : SExpr;

    (*  Das Resultat von 'Code (Ref)' ist der Interpreter-Code, dessen Wert die
     *  Ordnungszahl von 'Ref' angibt.
     *)

      VAR
        sx : SExpr;

    BEGIN (* Code *)
      sx := Numb (ORD (Ref));
      SetFlag (sx);
      RETURN sx
    END Code;


    PROCEDURE EnterName (s : ARRAY OF CHAR; VAR PList : SExpr);

    (*  Mit 'EnterName (s, PList)' wird die Zeichenkette 's' in den Puffer der
     *  Repräsentationstabelle eingetragen und die zugehörige Property-Liste
     *  bestimmt und in 'PList' geliefert.
     *)

      CONST
        EOS = 0C;

      VAR
        i : CARDINAL;

    BEGIN (* EnterName *)
      ClearBuf;
      i := 0;
      WHILE (i <= HIGH (s)) & (s [i] # EOS) DO
        AppChar (s [i]);
        IF OutOfMem THEN
          FatalError (INIT, StorageExhausted)
        END (* IF *);
        INC (i)
      END (* WHILE *);
      LookUpBuf (PList);
      IF OutOfMem THEN
        FatalError (INIT, StorageExhausted)
      END (* IF *)
    END EnterName;


    PROCEDURE EnterProp (PList, Ind, Prop : SExpr);

    (*  Mit 'EnterProp (PList, Ind, Prop)' wird die Eigenschaft 'Prop' mit dem
     *  Indikator 'Ind' in die Property-Liste 'PList' eingetragen.
     *  Die Property-Liste wird zwischenzeitlich in einem Register vor dem
     *  Garbage Collection geschützt.
     *)

    BEGIN (* EnterProp *)
      Expr := PList;
      PutProp (PList, Ind, Prop);
      Expr := Nil;
      IF OutOfMem THEN
        FatalError (INIT, StorageExhausted)
      END (* IF *)
    END EnterProp;


  BEGIN (* InitBase *)
    ResetRegs;

    EnterName ("SYS", SysPList);
      EnterProp (SysPList, SysPList, Nil);

    EnterName ("APVAL", ApValPList);
      EnterProp (ApValPList, SysPList, Nil);
    EnterName ("VAR", VarPList);
      EnterProp (VarPList, SysPList, Nil);
    EnterName ("EXPR", ExprPList);
      EnterProp (ExprPList, SysPList, Nil);
    EnterName ("SUBR", SubrPList);
      EnterProp (SubrPList, SysPList, Nil);
    EnterName ("FSUBR", FSubrPList);
      EnterProp (FSubrPList, SysPList, Nil);

    EnterName ("LAMBDA", LambdaPList);
      EnterProp (LambdaPList, SysPList, Nil);
    EnterName ("LABEL", LabelPList);
      EnterProp (LabelPList, SysPList, Nil);

    EnterName ("NIL", NilPList);
      EnterProp (NilPList, SysPList, Nil);
      NewPair (Val);
      IF OutOfMem THEN
        FatalError (INIT, StorageExhausted)
      END (* IF *);
      AssignPair (Val, Nil, Nil);
      EnterProp (NilPList, ApValPList, Val);
    EnterName ("T", TPList);
      EnterProp (TPList, SysPList, Nil);
      NewPair (Val);
      IF OutOfMem THEN
        FatalError (INIT, StorageExhausted)
      END (* IF *);
      AssignPair (Val, TPList, Nil);
      EnterProp (TPList, ApValPList, Val);
      Val := Nil;

    EnterName ("QUOTE", PList);
      EnterProp (PList, FSubrPList, Code (QUOTEREF));
    EnterName ("LIST", PList);
      EnterProp (PList, FSubrPList, Code (LISTREF));
    EnterName ("COND", PList);
      EnterProp (PList, FSubrPList, Code (CONDREF));
    EnterName ("AND", PList);
      EnterProp (PList, FSubrPList, Code (ANDREF));
    EnterName ("OR", PList);
      EnterProp (PList, FSubrPList, Code (ORREF));
    EnterName ("PLUS", PList);
      EnterProp (PList, FSubrPList, Code (PLUSREF));
    EnterName ("TIMES", PList);
      EnterProp (PList, FSubrPList, Code (TIMESREF));
    EnterName ("MAX", PList);
      EnterProp (PList, FSubrPList, Code (MAXREF));
    EnterName ("MIN", PList);
      EnterProp (PList, FSubrPList, Code (MINREF));

    EnterName ("CONS", PList);
      EnterProp (PList, SubrPList, Code (CONSREF));
    EnterName ("CAR", PList);
      EnterProp (PList, SubrPList, Code (CARREF));
    EnterName ("CDR", PList);
      EnterProp (PList, SubrPList, Code (CDRREF));
    EnterName ("ATOM", PList);
      EnterProp (PList, SubrPList, Code (ATOMREF));
    EnterName ("EQ", PList);
      EnterProp (PList, SubrPList, Code (EQREF));
    EnterName ("NOT", PList);
      EnterProp (PList, SubrPList, Code (NOTREF));
    EnterName ("NULL", PList);
      EnterProp (PList, SubrPList, Code (NOTREF));
    EnterName ("NUMBERP", PList);
      EnterProp (PList, SubrPList, Code (NUMBERPREF));
    EnterName ("RPLACA", PList);
      EnterProp (PList, SubrPList, Code (RPLACAREF));
    EnterName ("RPLACD", PList);
      EnterProp (PList, SubrPList, Code (RPLACDREF));
    EnterName ("DEFINE", PList);
      EnterProp (PList, SubrPList, Code (DEFINEREF));
    EnterName ("GET", PList);
      EnterProp (PList, SubrPList, Code (GETREF));
    EnterName ("PUTPROP", PList);
      EnterProp (PList, SubrPList, Code (PUTPROPREF));
    EnterName ("REMPROP", PList);
      EnterProp (PList, SubrPList, Code (REMPROPREF));
    EnterName ("DIFFERENCE", PList);
      EnterProp (PList, SubrPList, Code (DIFFERENCEREF));
    EnterName ("QUOTIENT", PList);
      EnterProp (PList, SubrPList, Code (QUOTIENTREF));
    EnterName ("REMAINDER", PList);
      EnterProp (PList, SubrPList, Code (REMAINDERREF));
    EnterName ("DIVIDE", PList);
      EnterProp (PList, SubrPList, Code (DIVIDEREF));
    EnterName ("ADD1", PList);
      EnterProp (PList, SubrPList, Code (ADD1REF));
    EnterName ("SUB1", PList);
      EnterProp (PList, SubrPList, Code (SUB1REF));
    EnterName ("MINUS", PList);
      EnterProp (PList, SubrPList, Code (MINUSREF));
    EnterName ("EXPT", PList);
      EnterProp (PList, SubrPList, Code (EXPTREF));
    EnterName ("ZEROP", PList);
      EnterProp (PList, SubrPList, Code (ZEROPREF));
    EnterName ("ONEP", PList);
      EnterProp (PList, SubrPList, Code (ONEPREF));
    EnterName ("MINUSP", PList);
      EnterProp (PList, SubrPList, Code (MINUSPREF));
    EnterName ("GREATERP", PList);
      EnterProp (PList, SubrPList, Code (GREATERPREF));
    EnterName ("LESSP", PList);
      EnterProp (PList, SubrPList, Code (LESSPREF));
    EnterName ("PRINT", PList);
      EnterProp (PList, SubrPList, Code (PRINTREF));
    EnterName ("READ", PList);
      EnterProp (PList, SubrPList, Code (READREF));
    EnterName ("NEWLINE", PList);
      EnterProp (PList, SubrPList, Code (NEWLINEREF));
    EnterName ("SPACES", PList);
      EnterProp (PList, SubrPList, Code (SPACESREF));
    EnterName ("EXIT", PList);
      EnterProp (PList, SubrPList, Code (EXITREF))
  END InitBase;


END LISPBase.
