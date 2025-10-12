IMPLEMENTATION MODULE FreeList;   (* ProCoLi 06/92 *)

(*  Freispeicherliste
 *
 *  Die Liste unbenutzter Paare wird als LISP-Liste dargestellt. Dabei sind die
 *  Komponenten der Liste (hier 'Nil') unwichtig, denn es kommt nur auf die zur
 *  Verkettung verwendeten Paare an.
 *)


  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) AssignPair, RightPart, HitCount,
                    ReplHitCount,

    (* VAR       *) FirstPair,
    (* PROCEDURE *) NextPair;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem;

  FROM GarbageCollector IMPORT
    (* PROCEDURE *) CollectPairs;


  VAR
    FreeLst : SExpr;


  PROCEDURE NewPair (VAR PairPtr : SExpr);

  (*  Wenn die Freispeicherliste leer ist, entsteht beim Garbage Collection eine
   *  neue Liste. War die Speicherwiedergewinnung jedoch erfolglos, so liegt ein
   *  Speicherüberlauf vor und die Anforderung kann nicht erfüllt werden.
   *  Sonst wird das erste Paar der Freispeicherliste abgetrennt und ein Zeiger
   *  darauf in 'PairPtr' geliefert.
   *)

  BEGIN (* NewPair *)
    IF FreeLst = Nil THEN
      CollectPairs;
      IF OutOfMem THEN
        RETURN
      END (* IF *)
    END (* IF *);
    PairPtr  := FreeLst;
    FreeLst := RightPart (FreeLst)
  END NewPair;


  PROCEDURE FreePair (PairPtr : SExpr);

  (*  Das Paar, auf das der durch 'PairPtr' bezeichnete Zeiger weist, wird vorn
   *  an die Freispeicherliste angehängt.
   *)

  BEGIN (* FreePair *)
    AssignPair (PairPtr, Nil, FreeLst);
    FreeLst := PairPtr
  END FreePair;


  PROCEDURE InitFreeList (VAR Len : CARDINAL);

  (*  Alle Paare werden in die anfangs leere Freispeicherliste eingefügt und
   *  gezählt.
   *)

    VAR
      PairPtr : SExpr;
      Valid   : BOOLEAN;

  BEGIN (* InitFreeList *)
    FreeLst := Nil;
    Len := 0;
    PairPtr := FirstPair;
    REPEAT
      AssignPair (PairPtr, Nil, FreeLst);
      FreeLst := PairPtr;
      INC (Len);
      NextPair (PairPtr, Valid)
    UNTIL NOT Valid
  END InitFreeList;


  PROCEDURE BuildFreeList (VAR Len : CARDINAL);

  (*  Die Folge aller Paare im Speicher wird durchlaufen, und bei markierten
   *  Paaren wird die Markierung gelöscht, während unmarkierte Paare in eine
   *  neue Freispeicherliste eingefügt und gezählt werden.
   *)

    VAR
      PairPtr : SExpr;
      Valid   : BOOLEAN;

  BEGIN (* BuildFreeList *)
    FreeLst := Nil;
    Len := 0;
    PairPtr := FirstPair;
    REPEAT
      IF HitCount (PairPtr) > 0 THEN
        ReplHitCount (PairPtr, 0)
      ELSE
        AssignPair (PairPtr, Nil, FreeLst);
        FreeLst := PairPtr;
        INC (Len)
      END (* IF *);
      NextPair (PairPtr, Valid)
    UNTIL NOT Valid
  END BuildFreeList;


END FreeList.
