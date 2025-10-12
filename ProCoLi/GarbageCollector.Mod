IMPLEMENTATION MODULE GarbageCollector;   (* ProCoLi 06/92 *)

(*  Speicherwiedergewinnung
 *
 *  Mit einer Heuristik wird frühzeitig ein Speicherüberlauf angezeigt, wenn die
 *  Größe des wiederbeschafften Speicherplatzes unter einer bestimmten Grenze
 *  liegt, um wiederholte Aufrufe des Garbage Collectors kurz vor Abbruch bei
 *  einem "wirklichen" Speicherüberlauf (z.B. Endlosrekursion) zu vermeiden.
 *)


  FROM FIO IMPORT
    (* CONST     *) StandardOutput,
    (* PROCEDURE *) WrLn, WrStr, WrCard;

  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) isNumb,
                    LeftPart, RightPart, HitCount,
                    ReplLeftPart, ReplRightPart, ReplHitCount;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem,
                    Temp,
                    Expr, Args, Val,
                    Data, Control, Env;

  FROM FreeList IMPORT
    (* PROCEDURE *) BuildFreeList;

  FROM PLists IMPORT
    (* PROCEDURE *) isEmptyPList;

  FROM ObList IMPORT
    (* PROCEDURE *) GetFirstPList, GetNextPList,
                    CompactObList;


  PROCEDURE MarkAll (sx : SExpr);

  (*  Mit 'MarkAll (sx)' werden alle Paare, die zum S-Ausdruck 'sx' gehören
   *  markiert. Dazu wird ein iteratives Graphtraversierungsverfahren nach
   *  Schorr/Waite durchgeführt:
   *  Wenn der S-Ausdruck 'sx' eine ganze Zahl oder 'Nil' ist, oder das erste
   *  Paar schon markiert ist, so bleibt nichts zu tun.
   *  Ein Paar wird beim ersten Auftreffen markiert, so daß der Abstieg zu
   *  einem markierten Paar einen Zyklus oder einen gemeinsamen Untergraphen
   *  anzeigt; der Aufstieg erfolgt jedoch immer zu einem markierten Paar.
   *  Beim Abstieg zum linken oder rechten Nachfolger des Paars wird der Links-
   *  teil bzw. der Rechtsteil zur Speicherung des Vorgängers des Paars
   *  verwendet. Die Abbruchbedingung muß offensichtlich nur beim Aufstieg
   *  überprüft werden.
   *)

    VAR
      Pres,
      Prev,
      Next : SExpr;

  BEGIN (* MarkAll *)
    IF NOT (isNumb (sx) OR (sx = Nil) OR (HitCount (sx) > 0)) THEN
      Pres := sx;
      Prev := sx;
      LOOP
        ReplHitCount (Pres, HitCount (Pres) + 1);
        CASE HitCount (Pres) OF
          1 : (* Abstieg zum linken Nachfolger *)
              Next := LeftPart (Pres);
              ReplLeftPart (Pres, Prev);
              IF isNumb (Next) OR (Next = Nil) OR (HitCount (Next) > 0) THEN
                Prev := Next
              ELSE
                Prev := Pres;
                Pres := Next
              END (* IF *)
        | 2 : (* Abstieg zum rechten Nachfolger *)
              Next := RightPart (Pres);
              ReplRightPart (Pres, LeftPart (Pres));
              ReplLeftPart (Pres, Prev);
              IF isNumb (Next) OR (Next = Nil) OR (HitCount (Next) > 0) THEN
                Prev := Next
              ELSE
                Prev := Pres;
                Pres := Next
              END (* IF *)
        | 3 : (* Aufstieg zum Vorgänger *)
              Next := RightPart (Pres);
              ReplRightPart (Pres, Prev);
              Prev := Pres;
              Pres := Next;
              IF Pres = Prev THEN
                EXIT
              END (* IF *)
        END (* CASE *)
      END (* LOOP *)
    END (* IF *)
  END MarkAll;


  PROCEDURE GarbageCollection (VAR Pairs, Chars : CARDINAL);

  (*  Mit 'GarbageCollection (Pairs, Chars)' werden alle Paare, die zu
   *  Registern, nichtleeren Property-Listen und zur Symboltabelle gehören,
   *  markiert. Die Repräsentationen von markierten Property-Listen werden
   *  kompaktifiziert, und die nicht markierten Property-Listen werden aus der
   *  Symboltabelle entfernt. Abschließend werden alle nicht markierten Paare
   *  zu einer neuen Freispeicherliste zusammengefaßt, deren Länge in 'Pairs'
   *  geliefert wird. 'Chars' gibt die Anzahl der freien Zeichen in der
   *  Repräsentationstabelle an.
   *)

    VAR
      PList : SExpr;
      Valid : BOOLEAN;

  BEGIN (* GarbageCollection *)
    MarkAll (Temp);
    MarkAll (Expr);
    MarkAll (Args);
    MarkAll (Val);
    MarkAll (Data);
    MarkAll (Control);
    MarkAll (Env);
    GetFirstPList (PList, Valid);
    WHILE Valid DO
      IF NOT isEmptyPList (PList) THEN
        MarkAll (PList)
      END (* IF *);
      GetNextPList (PList, Valid)
    END (* WHILE *);
    CompactObList (Chars);
    BuildFreeList (Pairs);
    WrLn (StandardOutput);
    WrCard (StandardOutput, Pairs, 0);
    WrStr (StandardOutput, " pairs and ");
    WrCard (StandardOutput, Chars, 0);
    WrStr (StandardOutput, " characters free");
    WrLn (StandardOutput)
  END GarbageCollection;


  PROCEDURE CollectPairs;

  (*  Das Garbage Collection ist erfolglos, wenn danach weniger als 'MinPairs'
   *  Paare frei sind.
   *)

    CONST
      MinPairs = 50;

    VAR
      Pairs, Chars : CARDINAL;

  BEGIN (* CollectPairs *)
    GarbageCollection (Pairs, Chars);
    OutOfMem := Pairs < MinPairs
  END CollectPairs;


  PROCEDURE CollectChars;

  (*  Das Garbage Collection ist erfolglos, wenn danach weniger als 'MinChars'
   *  Zeichen frei sind.
   *)

    CONST
      MinChars = 50;

    VAR
      Pairs, Chars : CARDINAL;

  BEGIN (* CollectChars *)
    GarbageCollection (Pairs, Chars);
    OutOfMem := Chars < MinChars
  END CollectChars;


END GarbageCollector.
