IMPLEMENTATION MODULE Errors;   (* ProCoLi 06/92 *)

(*  Fehlermeldungen
 *)


  FROM Lib IMPORT
    (* PROCEDURE *) SetReturnCode;

  FROM FIO IMPORT
    (* CONST     *) StandardOutput,
    (* PROCEDURE *) WrLn, WrStr;


  CONST
    StrLen = 42;

  TYPE
    String = ARRAY [0 .. StrLen - 1] OF CHAR;

  VAR
    PosStr : ARRAY ErrPos OF String;     (* Meldungen für Fehlerorte      *)
    MsgStr : ARRAY ErrMsg OF String;     (* Meldungen für Fehlerursachen  *)


  PROCEDURE Error (Pos : ErrPos; Msg : ErrMsg);

  (*  Die Fehlermeldung wird ausgegeben, und der Fehler wird in 'Abort'
   *  angezeigt.
   *)

  BEGIN (* Error *)
    WrLn (StandardOutput);
    WrStr (StandardOutput, " *** ERROR:  ");
    WrStr (StandardOutput, MsgStr [Msg]);
    WrStr (StandardOutput, " - ");
    WrStr (StandardOutput, PosStr [Pos]);
    WrLn (StandardOutput);
    Abort := TRUE
  END Error;


  PROCEDURE FatalError (Pos : ErrPos; Msg : ErrMsg);

  (*  Nach Ausgabe der Fehlermeldung wird die Ausführung des Programms
   *  abgebrochen (ohne PMD).
   *)

  BEGIN (* FatalError *)
    WrLn (StandardOutput);
    WrStr (StandardOutput, " *** FATAL ERROR:  ");
    WrStr (StandardOutput, MsgStr [Msg]);
    WrStr (StandardOutput, " - ");
    WrStr (StandardOutput, PosStr [Pos]);
    WrLn (StandardOutput);
    SetReturnCode (1);
    HALT
  END FatalError;


BEGIN (* Errors *)
  PosStr [INIT]           := "INIT";
  PosStr [INPUT]          := "INPUT";
  PosStr [EVALQUOTE]      := "EVALQUOTE";
  PosStr [EVALFUN]        := "EVAL-FUNCTION";
  PosStr [APPLYLAMBDA]    := "APPLY-LAMBDA";
  PosStr [APPLYLABEL]     := "APPLY-LABEL";
  PosStr [BIND]           := "BIND";
  PosStr [EVAL]           := "EVAL";
  PosStr [EVALAPVAL]      := "EVAL-APVAL";
  PosStr [EVLIS]          := "EVLIS";
  PosStr [CALLSUBR]       := "CALL-SUBR";
  PosStr [CALLFSUBR]      := "CALL-FSUBR";

  PosStr [QUOTEFSUBR]     := "QUOTE";
  PosStr [LISTFSUBR]      := "LIST";
  PosStr [CONDFSUBR]      := "COND";
  PosStr [ANDFSUBR]       := "AND";
  PosStr [ORFSUBR]        := "OR";
  PosStr [PLUSFSUBR]      := "PLUS";
  PosStr [TIMESFSUBR]     := "TIMES";
  PosStr [MAXFSUBR]       := "MAX";
  PosStr [MINFSUBR]       := "MIN";

  PosStr [CONSSUBR]       := "CONS";
  PosStr [CARSUBR]        := "CAR";
  PosStr [CDRSUBR]        := "CDR";
  PosStr [ATOMSUBR]       := "ATOM";
  PosStr [EQSUBR]         := "EQ";
  PosStr [NOTSUBR]        := "NOT";
  PosStr [NUMBERPSUBR]    := "NUMBERP";
  PosStr [RPLACASUBR]     := "RPLACA";
  PosStr [RPLACDSUBR]     := "RPLACD";
  PosStr [DEFINESUBR]     := "DEFINE";
  PosStr [GETSUBR]        := "GET";
  PosStr [PUTPROPSUBR]    := "PUTPROP";
  PosStr [REMPROPSUBR]    := "REMPROP";
  PosStr [DIFFERENCESUBR] := "DIFFERENCE";
  PosStr [QUOTIENTSUBR]   := "QUOTIENT";
  PosStr [REMAINDERSUBR]  := "REMAINDER";
  PosStr [DIVIDESUBR]     := "DIVIDE";
  PosStr [ADD1SUBR]       := "ADD1";
  PosStr [SUB1SUBR]       := "SUB1";
  PosStr [MINUSSUBR]      := "MINUS";
  PosStr [EXPTSUBR]       := "EXPT";
  PosStr [ZEROPSUBR]      := "ZEROP";
  PosStr [ONEPSUBR]       := "ONEP";
  PosStr [MINUSPSUBR]     := "MINUSP";
  PosStr [GREATERPSUBR]   := "GREATERP";
  PosStr [LESSPSUBR]      := "LESSP";
  PosStr [PRINTSUBR]      := "PRINT";
  PosStr [READSUBR]       := "READ";
  PosStr [NEWLINESUBR]    := "NEWLINE";
  PosStr [SPACESSUBR]     := "SPACES";
  PosStr [EXITSUBR]       := "EXIT";

  MsgStr [StorageExhausted] := "Storage Exhausted";
  MsgStr [CyclicList]       := "Cyclic List";
  MsgStr [IllegalChar]      := "Illegal Character";
  MsgStr [FileEnd]          := "Unexpected End-Of-File";
  MsgStr [IntSyntax]        := "Syntax Error in Integer";
  MsgStr [IntRange]         := "Integer Out of Range";
  MsgStr [SExprSyntax]      := "Syntax Error in S-Expression";
  MsgStr [UnboundVar]       := "Unbound Variable";
  MsgStr [UndefFun]         := "Undefined Function";
  MsgStr [IllegalFun]       := "Illegal Function";
  MsgStr [UndefCond]        := "Conditional Unsatisfied";
  MsgStr [UnknownFun]       := "Unknown Function!";
  MsgStr [UnknownForm]      := "Unknown Special Form!";
  MsgStr [TooManyArgs]      := "Too Many Arguments";
  MsgStr [TooFewArgs]       := "Not Enough Arguments";
  MsgStr [ListExpected]     := "List Expected";
  MsgStr [AtomUnexpected]   := "Non-Atomic S-Expression Expected";
  MsgStr [NatExpected]      := "Non-Negative Integer Expected";
  MsgStr [IntExpected]      := "Integer Expected";
  MsgStr [PListExpected]    := "P-List Expected";
  MsgStr [IndExpected]      := "Indicator Expected";
  MsgStr [CodeExpected]     := "Internal Code Expected";
  MsgStr [IntOverflow]      := "Overflow in Integer Arithmetic";
  MsgStr [IntUnderflow]     := "Underflow in Integer Arithmetic";
  MsgStr [IntZeroDiv]       := "Tried to Divide by Zero";
  MsgStr [Raise0To0]        := "Tried to Raise 0 to 0";
  MsgStr [Raise0ToNegPower] := "Tried to Raise 0 to Negative Power"
END Errors.
