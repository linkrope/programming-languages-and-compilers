IMPLEMENTATION MODULE PLists;   (* ProCoLi 06/92 *)

(*  Datentyp "Property-Liste"
 *
 *  Die Property-Listen werden als LISP-Listen dargestellt. Die erste Komponente
 *  ist ein Interpreter-Code (siehe 'SExprs') der Repräsentation des Namens.
 *  Die Restliste enthält abwechselnd Indikatoren und die entsprechenden
 *  Eigenschaften.
 *  Der Zeiger auf das erste Paar der Property-Liste ist gekennzeichnet.
 *)

  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) Numb, Value,
                    AssignPair, LeftPart, RightPart,
                    ReplLeftPart, ReplRightPart,
                    SetFlag;

  FROM FreeList IMPORT
    (* PROCEDURE *) NewPair, FreePair;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem;


  PROCEDURE NewPList (VAR PList : SExpr);

  (*  Wenn möglich wird eine leere Property-Liste erzeugt. Die Codierung der
   *  Repräsentation wird zunächst auf Nil gesetzt (undefiniert).
   *)

  BEGIN (* NewPList *)
    NewPair (PList);
    IF NOT OutOfMem THEN
      AssignPair (PList, Nil, Nil);
      SetFlag (PList)
    END (* IF *)
  END NewPList;


  PROCEDURE PListRepr (PList : SExpr) : CARDINAL;

  (*  Die Codierung der Repräsentation der Property-Liste 'PList' wird
   *  geliefert.
   *)

  BEGIN (* PListRepr *)
    RETURN Value (LeftPart (PList))
  END PListRepr;


  PROCEDURE PutRepr (PList : SExpr; Repr : CARDINAL);

  (*  Die Codierung der Repräsentation der Property-Liste 'PList' wird durch
   *  'Repr' ersetzt.
   *)

    VAR
      PName : SExpr;

  BEGIN (* PutRepr *)
    PName := Numb (Repr);
    SetFlag (PName);
    ReplLeftPart (PList, PName)
  END PutRepr;


  PROCEDURE isEmptyPList (PList : SExpr) : BOOLEAN;

  (*  Es wird getestet, ob die Property-Liste 'PList' keine Einträge enthält.
   *)

  BEGIN (* isEmptyPList *)
    RETURN RightPart (PList) = Nil
  END isEmptyPList;


  PROCEDURE GetProp (PList, Ind : SExpr; VAR Prop : SExpr; VAR Valid : BOOLEAN);

  (*  Die Einträge der Property-Liste 'PList' werden nach dem Indikator 'Ind'
   *  durchsucht. Existiert ein solcher Eintrag, so wird die entsprechende
   *  Eigenschaft in 'Prop' geliefert.
   *)

    VAR
      PairPtr : SExpr;

  BEGIN (* GetProp *)
    PairPtr := RightPart (PList);
    WHILE PairPtr # Nil DO
      IF LeftPart (PairPtr) = Ind THEN
        Prop := LeftPart (RightPart (PairPtr));
        Valid := TRUE;
        RETURN
      END (* IF *);
      PairPtr := RightPart (RightPart (PairPtr))
    END (* WHILE *);
    Valid := FALSE
  END GetProp;


  PROCEDURE PutProp (PList, Ind, Prop : SExpr);

  (*  Ein evtl. vorhandener Eintrag mit dem Indikator 'Ind' in der Property-
   *  Liste 'PList' wird gelöscht. Es wird ein neuer Eintrag mit dem Indikator
   *  'Ind' und der Eigenschaft 'Prop' erzeugt und vorn in die Property-Liste
   *  eingefügt. Dabei wird das Paar, das die Eigenschafts-Komponente enthält,
   *  sofort eingefügt um beim möglichen Garbage Collection für die Beschaffung
   *  des zweiten Paars nicht verloren zu gehen. Diese Änderung führt zwischen-
   *  zeitlich zu einer inkonsistenten Property-Liste und muß bei einem
   *  Speicherüberlauf rückgängig gemacht werden.
   *)

    VAR
      PairPtr : SExpr;

  BEGIN (* PutProp *)
    RemProp (PList, Ind);
    NewPair (PairPtr);
    IF NOT OutOfMem THEN
      AssignPair (PairPtr, Prop, RightPart (PList));
      ReplRightPart (PList, PairPtr);
      NewPair (PairPtr);
      IF NOT OutOfMem THEN
        AssignPair (PairPtr, Ind, RightPart (PList));
        ReplRightPart (PList, PairPtr)
      ELSE
        ReplRightPart (PList, RightPart (RightPart (PList)))
      END (* IF *)
    END (* IF *)
  END PutProp;


  PROCEDURE RemProp (PList, Ind : SExpr);

  (*  Die Einträge der Property-Liste 'PList' werden nach dem Indikator 'Ind'
   *  durchsucht. Existiert ein solcher Eintrag, so wird er aus der Liste
   *  ausgehängt. Die nicht mehr benötigten Paare werden freigegeben.
   *)

    VAR
      PrevPairPtr,
      PairPtr     : SExpr;

  BEGIN (* RemProp *)
    PrevPairPtr := PList;
    PairPtr := RightPart (PrevPairPtr);
    WHILE PairPtr # Nil DO
      IF LeftPart (PairPtr) = Ind THEN
        ReplRightPart (PrevPairPtr, RightPart (RightPart (PairPtr)));
        FreePair (RightPart (PairPtr));
        FreePair (PairPtr);
        RETURN
      END (* IF *);
      PrevPairPtr := RightPart (PairPtr);
      PairPtr := RightPart (PrevPairPtr)
    END (* WHILE *)
  END RemProp;


END PLists.
