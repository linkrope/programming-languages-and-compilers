IMPLEMENTATION MODULE Interpreter;   (* ProCoLi 02/94 *)

(*  Interpretation einer Funktionsanwendung
 *)


  FROM SYSTEM IMPORT
    (* PROCEDURE *) ADR;

  FROM FIO IMPORT
    (* CONST     *) StandardOutput,
    (* PROCEDURE *) WrLn, WrStr;

  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) isNumb, Numb, Value,
                    AssignPair, LeftPart, RightPart,
                    SetFlag;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem,
                    Expr, Args, Val,
                    Data, Control, Env,
    (* PROCEDURE *) ResetRegs;

  FROM FreeList IMPORT
    (* PROCEDURE *) NewPair;

  FROM Stacks IMPORT
    (* PROCEDURE *) EmptyStack,
                    Push, Pop;

  FROM PLists IMPORT
    (* PROCEDURE *) GetProp;

  FROM Errors IMPORT
    (* TYPE      *) ErrPos, ErrMsg,
    (* VAR       *) Abort,
    (* PROCEDURE *) Error, FatalError;

  FROM Checks IMPORT
    (* PROCEDURE *) isAtom, isCode, isPList,
                    Check0Args,
                    Check1Arg, Check2Args;

  FROM LISPBase IMPORT
    (* TYPE      *) FunRef,
                    SubrRef,
    (* VAR       *) NilPList,
                    ApValPList, VarPList,
                    ExprPList, SubrPList, FSubrPList,
                    LambdaPList, LabelPList,
    (* PROCEDURE *) Bool;

  FROM SExprIO IMPORT
    (* PROCEDURE *) WriteSExpr, ReadSExpr,
                    Skip;

  FROM LISPIO IMPORT
    (* PROCEDURE *) PrintSubr, ReadSubr, NewLineSubr, SpacesSubr;

  FROM LISPArithmetic IMPORT
    (* PROCEDURE *) PlusFSubr, TimesFSubr, MaxFSubr, MinFSubr,
                    DifferenceSubr, QuotientSubr, RemainderSubr, DivideSubr,
                    Add1Subr, Sub1Subr, MinusSubr, ExPtSubr,
                    ZeroPSubr, OnePSubr, MinusPSubr, GreaterPSubr, LessPSubr;

  FROM LISPStd IMPORT
    (* PROCEDURE *) ConsSubr, CARSubr, CDRSubr, AtomSubr, EqSubr,
                    NotSubr, NumberPSubr, RPlacASubr, RPlacDSubr,
                    DefineSubr, GetSubr, PutPropSubr, RemPropSubr;

  FROM Bindings IMPORT
    (* PROCEDURE *) Bind, UnBind, UnBindAll;


  VAR
    StopAdr : POINTER TO BOOLEAN;


  TYPE
    ProcRef = (READY,
               FROMEVALQUOTE, FROMAPPLY, FROMEVAL,
               EVALFUNREF, CALLSUBRREF, CALLFSUBRREF,
               APPLYLAMBDAREF, APPLYLABELREF, ENDAPPLYREF,
               EVALREF, EVLISREF, ENDEVLISREF,
               CONDFSUBRREF, ANDFSUBRREF, ORFSUBRREF, ENDFSUBRREF);

  VAR
    State  : ProcRef;
    Action : ARRAY [EVALFUNREF .. ENDFSUBRREF] OF PROC;

    Subr : ARRAY SubrRef OF PROC;


  PROCEDURE Code (Ref : ProcRef) : SExpr;

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


  PROCEDURE Ref (Code : SExpr) : ProcRef;

  (*  Das Resultat von 'Ref (Code)' ist die Konstante des Aufzählungstyps
   *  'ProcRef', die als Ordnungszahl den Wert des Interpreter-Codes 'Code' hat.
   *)

  BEGIN (* Ref *)
    RETURN VAL (ProcRef, Value (Code))
  END Ref;


  PROCEDURE EvalFun;

  (*  Mit 'EvalFun' wird eine Funktion ermittelt und auf ihre Argumente
   *  angewendet. Die Funktion wird durch den S-Ausdruck im Register 'Val'
   *  beschrieben, die Argumente liegen zuoberst auf dem Datenkeller, und das
   *  Ergebnis wird wieder im Register 'Val' geliefert.
   *  Wenn die Funktion durch ein Atom angegeben wird, so muß es der Name einer
   *  vordefinierten (SUBR) oder benannten (EXPR) Funktion, einer speziellen
   *  Form (FSUBR), oder einer Variablen (VAR) sein. Benannte Funktionen oder
   *  Variablen werden weiter ausgewertet.
   *  Wird die Funktion jedoch durch einen nicht-atomaren S-Ausdruck angegeben,
   *  so kann dies ein LABEL- oder LAMBDA-Ausdruck sein, oder eine Funktion, die
   *  sich nach der Auswertung mit EVAL ergibt.
   *  Auf dem Zustandskeller liegt zusätzlich die Codierung des Aufrufers von
   *  'EvalFun' ('FROMEVALQUOTE', 'FROMAPPLY' oder 'FROMEVAL').
   *  Eine spezielle Form darf nicht in APPLY vorkommen, und bei EVALQUOTE
   *  wird die Argumentliste zur weiteren Auswertung mit einer überflüssigen
   *  ersten Komponente versehen. Für eine andere Funktion müssen bei EVAL
   *  zuerst die Argumente ausgewertet werden.
   *)

    VAR
      sx    : SExpr;
      Valid : BOOLEAN;

  BEGIN (* EvalFun *)
    LOOP
      IF Abort THEN
        RETURN
      END (* IF *);
      IF isAtom (Val) THEN
        IF Val = Nil THEN
          Val := NilPList
        ELSIF NOT isPList (Val) THEN
          Error (EVALFUN, PListExpected);
          RETURN
        END (* IF *);
        GetProp (Val, ExprPList, sx, Valid);
        IF Valid THEN
          Val := sx
        ELSE
          GetProp (Val, SubrPList, sx, Valid);
          IF Valid THEN
            Val := sx;
            State := CALLSUBRREF;
            EXIT
          ELSE
            GetProp (Val, FSubrPList, sx, Valid);
            IF Valid THEN
              Val := sx;
              State := CALLFSUBRREF;
              EXIT
            ELSE
              GetProp (Val, VarPList, sx, Valid);
              IF Valid THEN
                Val := sx
              ELSE
                Error (EVALFUN, UndefFun);
                RETURN
              END (* IF *)
            END (* IF *)
          END (* IF *)
        END (* IF *)
      ELSIF LeftPart (Val) = LambdaPList THEN
        Val := RightPart (Val);
        State := APPLYLAMBDAREF;
        EXIT
      ELSIF LeftPart (Val) = LabelPList THEN
        Val := RightPart (Val);
        State := APPLYLABELREF;
        EXIT
      ELSE
        Push (Control, Code (EVALFUNREF));
        IF OutOfMem THEN
          Error (EVALFUN, StorageExhausted);
          RETURN
        END (* IF *);
        State := EVALREF;
        RETURN
      END (* IF *)
    END (* LOOP *);
    Pop (Control, sx);
    IF State = CALLFSUBRREF THEN
      IF Ref (sx) = FROMAPPLY THEN
        Error (EVALFUN, IllegalFun)
      ELSIF Ref (sx) = FROMEVALQUOTE THEN
        Pop (Data, Args);
        NewPair (sx);
        IF NOT OutOfMem THEN
          AssignPair (sx, Nil, Args);
          Args := sx;
          Push (Data, Args)
        END (* IF *);
        IF OutOfMem THEN
          Error (EVALFUN, StorageExhausted)
        END (* IF *);
        Args := Nil
      END (* IF *)
    ELSE
      IF Ref (sx) = FROMEVAL THEN
        Push (Control, Code (State));
        IF OutOfMem THEN
          Error (EVALFUN, StorageExhausted);
          RETURN
        END (* IF *);
        State := EVLISREF
      END (* IF *)
    END (* IF *)
  END EvalFun;


  PROCEDURE CallSubr;

  (*  Mit 'CallSubr' wird eine vordefinierte Funktion auf ihre Argumente
   *  angewendet. Das Register 'Val' enthält die Codierung der Funktion, die
   *  Argumente liegen auf dem Datenkeller, und das Ergebnis wird wieder im
   *  Register 'Val' geliefert.
   *)

    VAR
      sx  : SExpr;
      Fun : FunRef;

  BEGIN (* CallSubr *)
    IF isCode (Val) THEN
      Fun := VAL (FunRef, Value (Val))
    ELSE
      Error (CALLSUBR, CodeExpected);
      RETURN
    END (* IF *);
    IF (MIN (SubrRef) <= Fun) & (Fun <= MAX (SubrRef)) THEN
      Pop (Data, Args);
      Subr [Fun]
    ELSE
      Error (CALLSUBR, UnknownFun)
    END (* IF *);
    IF NOT Abort THEN
      Args := Nil;
      Pop (Control, sx);
      State := Ref (sx)
    END (* IF *)
  END CallSubr;


  PROCEDURE ExitSubr;

  (*  Mit 'ExitSubr' wird die gesamte Interpretation abgebrochen. Die Argument-
   *  liste muß leer sein.
   *)

  BEGIN (* ExitSubr *)
    Check0Args (EXITSUBR, Args);
    IF NOT Abort THEN
      StopAdr^ := TRUE;
      Val := Nil
    END (* IF *)
  END ExitSubr;


  PROCEDURE CallFSubr;

  (*  Mit 'CallFSubr' wird eine spezielle Form ausgewertet. Der Aufruf erfolgt
   *  wie bei 'CallSubr', jedoch enthält nun die Liste der Argumente eine
   *  überflüssige erste Komponente.
   *  QUOTE kann direkt ausgeführt werden; bei COND, AND und OR, wo die
   *  Auswertung der Argumente nur bedingt erfolgt, werden die entsprechenden
   *  Prozeduren mit geeigneten Startwerten aufgerufen; die übrigen speziellen
   *  Formen sind Funktionen, die beliebig viele Argumente haben können, welche
   *  zuerst mit EVLIS ausgewertet werden müssen.
   *)

    VAR
      sx : SExpr;

  BEGIN (* CallFSubr *)
    IF NOT isCode (Val) THEN
      Error (CALLFSUBR, CodeExpected);
      RETURN
    END (* IF *);
    CASE VAL (FunRef, Value (Val)) OF
      QUOTEREF : Pop (Data, Args);
                 Args := RightPart (Args);
                 Check1Arg (QUOTEFSUBR, Args, Val);
                 Args := Nil;
                 IF NOT Abort THEN
                   Pop (Control, sx);
                   State := Ref (sx)
                 END (* IF *)
    | CONDREF  : Val := Bool (FALSE);
                 State := CONDFSUBRREF
    | ANDREF   : Val := Bool (TRUE);
                 State := ANDFSUBRREF
    | ORREF    : Val := Bool (FALSE);
                 State := ORFSUBRREF
    | LISTREF,
      PLUSREF,
      TIMESREF,
      MAXREF,
      MINREF   : Push (Control, Code (ENDFSUBRREF));
                 IF OutOfMem THEN
                   Error (EVALFUN, StorageExhausted);
                   RETURN
                 END (* IF *);
                 State := EVLISREF
    ELSE
      Error (CALLFSUBR, UnknownForm)
    END (* CASE *)
  END CallFSubr;


  PROCEDURE CondFSubr;

  (*  Mit 'CondFSubr' wird die spezielle Form COND ausgewertet. Das Register
   *  'Val' enthält die zuletzt ausgewertete Bedingung, und auf dem Datenkeller
   *  liegt die Liste der restlichen Klauseln. Wenn die Bedingung nicht erfüllt
   *  ist, so wird die erste Komponente dieser Liste nicht benötigt. Das
   *  Ergebnis wird in 'Val' geliefert.
   *  Solange die Bedingungen nicht zutreffen, wird von den restlichen Klauseln
   *  immer wieder die erste abgespalten, und ihre Bedingung mit EVAL
   *  ausgewertet.
   *)

    VAR
      sx : SExpr;

  BEGIN (* CondFSubr *)
    Pop (Data, Args);
    IF Val # Nil THEN
      Check2Args (CONDFSUBR, LeftPart (Args), sx, Val);
      Args := Nil;
      State := EVALREF
    ELSE
      Args := RightPart (Args);
      IF isAtom (Args) THEN
        Error (CONDFSUBR, UndefCond)
      ELSE
        sx := LeftPart (Args);
        IF isAtom (sx) THEN
          Error (CONDFSUBR, AtomUnexpected)
        ELSE
          Val := LeftPart (sx);
          Push (Data, Args);
          Args := Nil;
          IF NOT OutOfMem THEN
            Push (Control, Code (CONDFSUBRREF))
          END (* IF *);
          IF OutOfMem THEN
            Error (CONDFSUBR, StorageExhausted);
            RETURN
          END (* IF *);
          State := EVALREF
        END (* IF *)
      END (* IF *)
    END (* IF *)
  END CondFSubr;


  PROCEDURE AndFSubr;

  (*  Mit 'AndFSubr' wird die spezielle Form AND ausgewertet. Das Register 'Val'
   *  enthält das zuletzt ausgewertete Argument, die Liste der restlichen
   *  Argumente (mit einer überflüssigen ersten Komponente) liegt auf dem
   *  Datenkeller, und das Ergebnis wird wieder in 'Val' geliefert.
   *  Die Auswertung der Argumente erfolgt schrittweise mit 'Eval', solange die
   *  Werte von 'Nil' verschieden sind.
   *)

    VAR
      sx : SExpr;

  BEGIN (* AndFSubr *)
    Pop (Data, Args);
    Args := RightPart (Args);
    IF Val = Nil THEN
      Args := Nil;
      Pop (Control, sx);
      State := Ref (sx)
    ELSIF isAtom (Args) THEN
      IF Args # Nil THEN
        Error (ANDFSUBR, ListExpected);
        RETURN
      END (* IF *);
      Val := Bool (TRUE);
      Pop (Control, sx);
      State := Ref (sx)
    ELSE
      Push (Data, Args);
      IF NOT OutOfMem THEN
        Push (Control, Code (ANDFSUBRREF))
      END (* IF *);
      IF OutOfMem THEN
        Error (ANDFSUBR, StorageExhausted);
        RETURN
      END (* IF *);
      Val := LeftPart (Args);
      Args := Nil;
      State := EVALREF
    END (* IF *)
  END AndFSubr;


  PROCEDURE OrFSubr;

  (*  Mit 'OrFSubr' wird analog zu 'AndFSubr' die spezielle Form OR ausgewertet.
   *)

    VAR
      sx : SExpr;

  BEGIN (* OrFSubr *)
    Pop (Data, Args);
    Args := RightPart (Args);
    IF Val # Nil THEN
      Args := Nil;
      Val  := Bool (TRUE);
      Pop (Control, sx);
      State := Ref (sx)
    ELSIF isAtom (Args) THEN
      IF Args # Nil THEN
        Error (ORFSUBR, ListExpected);
        RETURN
      END (* IF *);
      Val := Bool (FALSE);
      Pop (Control, sx);
      State := Ref (sx)
    ELSE
      Push (Data, Args);
      IF NOT OutOfMem THEN
        Push (Control, Code (ORFSUBRREF))
      END (* IF *);
      IF OutOfMem THEN
        Error (ORFSUBR, StorageExhausted);
        RETURN
      END (* IF *);
      Val := LeftPart (Args);
      Args := Nil;
      State := EVALREF
    END (* IF *)
  END OrFSubr;


  PROCEDURE EndFSubr;

  (*  Mit 'EndFSubr' wird eine Funktion auf die ausgewertete Liste ihrer
   *  Argumente angewendet. Das Register 'Val' enthält die Codierung der
   *  Funktion, die Argumente liegen auf dem Datenkeller, und das Ergebnis wird
   *  wieder in 'Val' geliefert.
   *)

    VAR
      sx : SExpr;

  BEGIN (* EndFSubr *)
    Pop (Data, Args);
    CASE VAL (FunRef, Value (Val)) OF
      LISTREF  : Val := Args
    | PLUSREF  : PlusFSubr
    | TIMESREF : TimesFSubr
    | MAXREF   : MaxFSubr
    | MINREF   : MinFSubr
    END (* CASE *);
    IF NOT Abort THEN
      Args := Nil;
      Pop (Control, sx);
      State := Ref (sx)
    END (* IF *)
  END EndFSubr;


  PROCEDURE ApplyLambda;

  (*  Mit 'ApplyLambda' wird ein LAMBDA-Ausdruck ausgewertet. Das Register 'Val'
   *  enthält den Rest des LAMBDA-Ausdrucks (ohne LAMBDA), die Argumente liegen
   *  auf dem Datenkeller, und das Ergebnis wird wieder im Register 'Val'
   *  geliefert.
   *  Die Variablen werden nacheinander an die Argumente gebunden, was auf dem
   *  Zustandskeller zu einem Lösen der Bindungen vermerkt wird.
   *  Anschließend wird die Form mit EVAL ausgewertet.
   *)

    VAR
      VarList,
      sx      : SExpr;

  BEGIN (* ApplyLambda *)
    Check2Args (APPLYLAMBDA, Val, VarList, sx);
    IF NOT Abort THEN
      Pop (Data, Args);
      WHILE NOT isAtom (VarList) DO
        IF isAtom (Args) THEN
          Error (APPLYLAMBDA, TooFewArgs);
          RETURN
        END (* IF *);
        Bind (LeftPart (VarList), LeftPart (Args));
        IF Abort THEN
          RETURN
        END (* IF *);
        Push (Control, Code (ENDAPPLYREF));
        IF OutOfMem THEN
          Error (APPLYLAMBDA, StorageExhausted);
          RETURN
        END (* IF *);
        VarList := RightPart (VarList);
        Args    := RightPart (Args)
      END (* WHILE *);
      IF VarList # Nil THEN
        Error (APPLYLAMBDA, ListExpected);
        RETURN
      END (* IF *);
      Check0Args (APPLYLAMBDA, Args);
      IF NOT Abort THEN
        Val := sx;
        State := EVALREF
      END (* IF *)
    END (* IF *)
  END ApplyLambda;


  PROCEDURE ApplyLabel;

  (*  Mit 'ApplyLabel' wird ein LABEL-Ausdruck ausgewertet. Der Aufruf erfolgt
   *  wie bei 'ApplyLambda'.
   *  Der Name wird an die Funktion gebunden, und diese wird dann auf die
   *  Argumente angewendet.
   *)

    VAR
      PList,
      sx    : SExpr;

  BEGIN (* ApplyLabel *)
    Check2Args (APPLYLABEL, Val, PList, sx);
    IF NOT Abort THEN
      Bind (PList, sx);
      IF NOT Abort THEN
        Push (Control, Code (ENDAPPLYREF));
        IF NOT OutOfMem THEN
          Push (Control, Code (FROMAPPLY))
        END (* IF *);
        IF OutOfMem THEN
          Error (EVAL, StorageExhausted);
          RETURN
        END (* IF *);
        Val := sx;
        State := EVALFUNREF
      END (* IF *)
    END (* IF *)
  END ApplyLabel;


  PROCEDURE EndApply;

  (*  Mit 'EndApply' werden Bindungen gelöst.
   *)

    VAR
      sx : SExpr;

  BEGIN (* EndApply *)
    REPEAT
      UnBind;
      Pop (Control, sx);
      State := Ref (sx)
    UNTIL State # ENDAPPLYREF
  END EndApply;


  PROCEDURE Eval;

  (*  Mit 'Eval' wird eine Form ausgewertet. Das Register 'Val' enthält die Form
   *  und nach der Auswertung das Ergebnis.
   *  Ein Atom ist eine Zahl, oder der Name einer Konstanten oder Variablen.
   *  Eine nicht-atomare Form beschreibt die Anwendung einer Funktion auf ihre
   *  Argumente.
   *)

    VAR
      sx    : SExpr;
      Valid : BOOLEAN;

  BEGIN (* Eval *)
    IF isAtom (Val) THEN
      IF NOT isNumb (Val) THEN
        IF Val = Nil THEN
          Val := NilPList
        END (* IF *);
        GetProp (Val, ApValPList, sx, Valid);
        IF Valid THEN
          Check1Arg (EVALAPVAL, sx, Val);
          IF Abort THEN
            RETURN
          END (* IF *)
        ELSE
          GetProp (Val, VarPList, sx, Valid);
          IF Valid THEN
            Val := sx
          ELSE
            Error (EVAL, UnboundVar);
            RETURN
          END (* IF *)
        END (* IF *)
      END (* IF *);
      Pop (Control, sx);
      State := Ref (sx)
    ELSE (* NOT isAtom (Val) *)
      Push (Data, Val);
      IF NOT OutOfMem THEN
        Push (Control, Code (FROMEVAL))
      END (* IF *);
      IF OutOfMem THEN
        Error (EVAL, StorageExhausted);
        RETURN
      END (* IF *);
      Val := LeftPart (Val);
      State := EVALFUNREF
    END (* IF *)
  END Eval;


  PROCEDURE EvLis;

  (*  Mit 'EvLis' wird eine Argumentliste ausgewertet. Dabei liegt die Liste der
   *  noch auszuwertenden Argumente (mit einer überflüssigen ersten Komponente)
   *  immer oben auf dem Datenkeller, und das Register 'Val' enthält beim ersten
   *  Aufruf die Funktion, und bei den weiteren Aufrufen das jeweils ausge-
   *  wertete Argument. Beim letzten Aufruf wird die Liste der Werte auf dem
   *  Datenkeller geliefert, und das Register 'Val' enthält wieder die Funktion.
   *  Die Auswertung erfolgt schrittweise mit EVAL, wobei vorher der Inhalt des
   *  Registers 'Val' auf den Datenkeller gerettet wird, was auf dem Zustands-
   *  keller zur Verkettung der Werte vermerkt wird.
   *)

  BEGIN (* EvLis *)
    Pop (Data, Args);
    Args := RightPart (Args);
    IF isAtom (Args) THEN
      IF Args # Nil THEN
        Error (EVLIS, ListExpected);
        RETURN
      END (* IF *);
      State := ENDEVLISREF
    ELSE
      Push (Data, Val);
      IF NOT OutOfMem THEN
        Push (Control, Code (ENDEVLISREF));
        IF NOT OutOfMem THEN
          Push (Data, Args);
          IF NOT OutOfMem THEN
            Push (Control, Code (EVLISREF))
          END (* IF *)
        END (* IF *)
      END (* IF *);
      IF OutOfMem THEN
        Error (EVLIS, StorageExhausted);
        RETURN
      END (* IF *);
      Val := LeftPart (Args);
      Args := Nil;
      State := EVALREF
    END (* IF *)
  END EvLis;


  PROCEDURE EndEvLis;

  (*  Mit 'EndEvLis' werden die Werte auf dem Keller verkettet.
   *)

    VAR
      sx : SExpr;

  BEGIN (* EndEvLis *)
    LOOP
      Pop (Control, sx);
      State := Ref (sx);
      IF State # ENDEVLISREF THEN
        EXIT
      END (* IF *);
      NewPair (sx);
      IF OutOfMem THEN
        Error (EVLIS, StorageExhausted);
        RETURN
      END (* IF *);
      AssignPair (sx, Val, Args);
      Args := sx;
      Pop (Data, Val)
    END (* LOOP *);
    Push (Data, Args);
    IF OutOfMem THEN
      Error (EVLIS, StorageExhausted)
    END (* IF *)
  END EndEvLis;


  PROCEDURE Interpret (VAR Stop : BOOLEAN);

  (*  Die Register und Anzeigen werden initialisiert, zwei S-Ausdrücke werden
   *  eingelesen, und dann beginnt die Interpretation. Der Interpreter ist
   *  "iterativ" mit einem Zustands- ('Control') und einem Datenkeller ('Data')
   *  implementiert, und ruft solange die zu Zuständen gehörenden Prozeduren
   *  auf, bis ein Fehler auftritt oder die Interpretation beendet ist.
   *  Im Fehlerfall wird der Rest der Eingabezeile überlesen und die Bindungen
   *  werden ordnungsgemäß gelöst. Andernfalls wird das berechnete Ergebnis
   *  ausgegeben.
   *  Mit einer Heuristik wird der Interpreter abgebrochen, wenn es schon bei
   *  der Eingabe der Funktionsanwendung zu einem Speicherüberlauf kommt.
   *)

    CONST
      Prompt = ">>> ";

  BEGIN (* Interpret *)
    Abort := FALSE;
    Stop  := FALSE;
    StopAdr := ADR (Stop);
    ResetRegs;
    Data    := EmptyStack ();
    Control := EmptyStack ();
    Env     := EmptyStack ();
    WrLn (StandardOutput);
    WrStr (StandardOutput, Prompt);
    ReadSExpr;
    IF NOT Abort THEN
      Push (Data, Val);
      Val := Nil;
      IF NOT OutOfMem THEN
        ReadSExpr;
        IF NOT Abort THEN
          Args := Val;
          Pop (Data, Val);
          Push (Data, Args);
          Args := Nil;
          IF NOT OutOfMem THEN
            Push (Control, Code (READY));
            IF NOT OutOfMem THEN
              Push (Control, Code (FROMEVALQUOTE))
            END (* IF *)
          END (* IF *)
        END (* IF *)
      END (* IF *)
    END (* IF *);
    IF OutOfMem THEN
      FatalError (EVALQUOTE, StorageExhausted);
      RETURN
    END (* IF *);
    State := EVALFUNREF;
    WHILE NOT ((State = READY) OR Abort OR Stop) DO
      Action [State]
    END (* WHILE *);
    IF Abort THEN
      UnBindAll;
      Skip
    ELSIF NOT Stop THEN
      WriteSExpr
    END (* IF *)
  END Interpret;


BEGIN (* Interpreter *)
  Action [EVALFUNREF]     := EvalFun;
  Action [CALLSUBRREF]    := CallSubr;
  Action [CALLFSUBRREF]   := CallFSubr;
  Action [APPLYLAMBDAREF] := ApplyLambda;
  Action [APPLYLABELREF]  := ApplyLabel;
  Action [ENDAPPLYREF]    := EndApply;
  Action [EVALREF]        := Eval;
  Action [EVLISREF]       := EvLis;
  Action [ENDEVLISREF]    := EndEvLis;
  Action [CONDFSUBRREF]   := CondFSubr;
  Action [ANDFSUBRREF]    := AndFSubr;
  Action [ORFSUBRREF]     := OrFSubr;
  Action [ENDFSUBRREF]    := EndFSubr;

  Subr [CONSREF]       := ConsSubr;
  Subr [CARREF]        := CARSubr;
  Subr [CDRREF]        := CDRSubr;
  Subr [ATOMREF]       := AtomSubr;
  Subr [EQREF]         := EqSubr;
  Subr [NOTREF]        := NotSubr;
  Subr [NUMBERPREF]    := NumberPSubr;
  Subr [RPLACAREF]     := RPlacASubr;
  Subr [RPLACDREF]     := RPlacDSubr;
  Subr [DEFINEREF]     := DefineSubr;
  Subr [GETREF]        := GetSubr;
  Subr [PUTPROPREF]    := PutPropSubr;
  Subr [REMPROPREF]    := RemPropSubr;
  Subr [DIFFERENCEREF] := DifferenceSubr;
  Subr [QUOTIENTREF]   := QuotientSubr;
  Subr [REMAINDERREF]  := RemainderSubr;
  Subr [DIVIDEREF]     := DivideSubr;
  Subr [ADD1REF]       := Add1Subr;
  Subr [SUB1REF]       := Sub1Subr;
  Subr [MINUSREF]      := MinusSubr;
  Subr [EXPTREF]       := ExPtSubr;
  Subr [ZEROPREF]      := ZeroPSubr;
  Subr [ONEPREF]       := OnePSubr;
  Subr [MINUSPREF]     := MinusPSubr;
  Subr [GREATERPREF]   := GreaterPSubr;
  Subr [LESSPREF]      := LessPSubr;
  Subr [PRINTREF]      := PrintSubr;
  Subr [READREF]       := ReadSubr;
  Subr [NEWLINEREF]    := NewLineSubr;
  Subr [SPACESREF]     := SpacesSubr;
  Subr [EXITREF]       := ExitSubr
END Interpreter.
