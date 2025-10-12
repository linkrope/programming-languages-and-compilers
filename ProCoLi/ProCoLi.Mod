MODULE ProCoLi;   (* ProCoLi 03/95 *)

(*  Interpreterschleife
 *
 *  Nach der Initialisierung der Datenstrukturen werden solange Funktions-
 *  anwendungen eingelesen und ausgeführt, bis das Abbruch-Kommando aufgerufen
 *  wird oder ein fataler Fehler auftritt.
 *)


  FROM FIO IMPORT
    (* CONST     *) StandardOutput,
    (* PROCEDURE *) WrStr, WrCard, WrLn;

  FROM FreeList IMPORT
    (* PROCEDURE *) InitFreeList;

  FROM Errors IMPORT
   (* VAR        *) Abort;

  FROM LISPBase IMPORT
    (* PROCEDURE *) InitBase;

  FROM Interpreter IMPORT
    (* PROCEDURE *) Interpret;


  VAR
    Len  : CARDINAL;
    Stop : BOOLEAN;


BEGIN (* ProCoLi *)
  WrStr (StandardOutput, "ProCoLiSP-INTERPRETER");
  WrStr (StandardOutput, "      TopSpeed version of April 1996");
  WrLn (StandardOutput);
  WrLn (StandardOutput);
  InitFreeList (Len);
  WrCard (StandardOutput, Len, 5);
  WrStr (StandardOutput, " pairs allocated");
  WrLn (StandardOutput);
  InitBase;
  WrStr (StandardOutput, "LISP-base initialized");
  WrLn (StandardOutput);
  WrLn (StandardOutput);

  REPEAT
    Interpret (Stop)
  UNTIL Stop
END ProCoLi.
