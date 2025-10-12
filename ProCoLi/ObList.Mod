IMPLEMENTATION MODULE ObList;   (* ProCoLi 04/96 *)

(*  Symboltabelle
 *
 *  Die Symboltabelle wird als LISP-Liste von Property-Listen in der Reihenfolge
 *  ihrer Eintragung dargestellt (lineares Suchen in der Repräsentations-
 *  tabelle). Die aktuelle Property-Liste wird durch den Teil der Liste aller
 *  Property-Listen angegeben, der mit der aktuellen beginnt.
 *  Am Anfang ist die Liste der Property-Listen leer.
 *)


  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) AssignPair, LeftPart, RightPart, HitCount,
                    ReplRightPart, ReplHitCount;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem,
                    Temp;

  FROM FreeList IMPORT
    (* PROCEDURE *) NewPair;

  FROM Reprs IMPORT
    (* PROCEDURE *) eqBuf, ClearBuf, EnterBuf,

    (* PROCEDURE *) MoveRepr, EndCompactReprs;

  FROM PLists IMPORT
    (* PROCEDURE *) NewPList, PListRepr, PutRepr;


  VAR
    ObLst,
    ObLstEnd,
    Current  : SExpr;


  PROCEDURE LookUpBuf (VAR PList : SExpr);

  (*  Die Liste aller Property-Listen wird nach einer Komponente durchsucht,
   *  deren Repräsentation gleich der Zeichenfolge im Puffer ist. Existiert
   *  solch eine Property-Liste, so wird sie geliefert und der Puffer wird
   *  gelöscht. Andernfalls wird eine neue Property-Liste mit dem Pufferinhalt
   *  als Repräsentation erzeugt und an die Liste aller Property-Listen
   *  angehängt. Dabei muß diese neue Property-Liste in einem Register
   *  zwischenzeitlich vor dem Garbage Collection bewahrt werden.
   *)

    VAR
      PairPtr     : SExpr;
      Repr        : CARDINAL;

  BEGIN (* LookUpBuf *)
    PairPtr := ObLst;
    WHILE PairPtr # Nil DO
      PList := LeftPart (PairPtr);
      IF eqBuf (PListRepr (PList)) THEN
        ClearBuf;
        RETURN
      END (* IF *);
      PairPtr := RightPart (PairPtr)
    END (* WHILE *);
    NewPList (PList);
    Temp := PList;
    IF NOT OutOfMem THEN
      EnterBuf (Repr);
      IF NOT OutOfMem THEN
        PutRepr (PList, Repr);
        NewPair (PairPtr);
        IF NOT OutOfMem THEN
          AssignPair (PairPtr, PList, Nil);
          IF ObLst = Nil THEN
            ObLst := PairPtr
          ELSE
            ReplRightPart (ObLstEnd, PairPtr)
          END (* IF *);
          ObLstEnd := PairPtr
        END (* IF *)
      END (* IF *)
    END (* IF *);
    Temp := Nil
  END LookUpBuf;


  PROCEDURE GetFirstPList (VAR PList : SExpr; VAR Valid : BOOLEAN);

  (*  Die erste Property-Liste wird durch die gesamte Liste aller Property-
   *  Listen angegeben.
   *)

  BEGIN (* GetFirstPList *)
    Current := ObLst;
    Valid := Current # Nil;
    IF Valid THEN
      PList := LeftPart (Current)
    END (* IF *)
  END GetFirstPList;


  PROCEDURE GetNextPList (VAR PList : SExpr; VAR Valid : BOOLEAN);

  (*  Die nächste Property-Liste wird durch die Restliste der Property-Listen
   *  ohne die erste Komponente angegeben.
   *)

  BEGIN (* GetNextPList *)
    Current := RightPart (Current);
    Valid := Current # Nil;
    IF Valid THEN
      PList := LeftPart (Current)
    END (* IF *)
  END GetNextPList;


  PROCEDURE CompactObList (VAR Len : CARDINAL);

  (*  Die alte Liste aller Property-Listen wird durchlaufen und eine neue Liste
   *  wird aus den markierten Property-Listen aufgebaut, wobei deren
   *  Repräsentationen kompaktifiziert werden. Die zur Verkettung der neuen
   *  Liste benötigten Paare werden markiert. Der Verweis 'Last' auf das
   *  letzte Listenpaar in der Ob-List wird nach Kompaktifizierung
   *  aktualisiert; dies gewährleistet, daß 'LookUpBuf' auch dann noch das
   *  tatsächlich letzte Paar in der Ob-List ohne deren Neutraversierung
   *  im direkten Zugriff hat, wenn dort just das Neuanlegen einer P-List ein
   *  Garbage Collection und somit eine mögliche Umstrukturierung der
   *  Ob-List verursachte.
   *)

    VAR
      PairPtr,
      PList,
      ObLstEnd : SExpr;
      Repr     : CARDINAL;

  BEGIN (* CompactObList *)
    PairPtr := ObLst;
    ObLst := Nil;
    WHILE PairPtr # Nil DO
      PList := LeftPart (PairPtr);
      IF HitCount (PList) > 0 THEN
        Repr := PListRepr (PList);
        MoveRepr (Repr);
        PutRepr (PList, Repr);
        ReplHitCount (PairPtr, 3);
        IF ObLst = Nil THEN
          ObLst := PairPtr;
        ELSE
          ReplRightPart (ObLstEnd, PairPtr)
        END (* IF *);
        ObLstEnd := PairPtr
      END (* IF *);
      PairPtr := RightPart (PairPtr)
    END (* WHILE *);
    IF ObLst # Nil THEN
      ReplRightPart (ObLstEnd, Nil)
    END (* IF *);
    EndCompactReprs (Len)
  END CompactObList;


BEGIN (* ObList *)
  ObLst := Nil;
END ObList.
