IMPLEMENTATION MODULE SExprIO;   (* ProCoLi 04/96 *)

(*  Ein-/Ausgabe von S-Ausdrücken
 *)


  FROM FIO IMPORT
    (* CONST     *) EOF, StandardInput, StandardOutput,
    (* TYPE      *) File,
    (* PROCEDURE *) RdChar,
                    WrChar, WrLn, WrStr, WrInt;

  FROM SExprs IMPORT
    (* TYPE      *) SExpr,
    (* VAR       *) Nil,
    (* PROCEDURE *) Numb, Value,
                    AssignPair, LeftPart, RightPart, HitCount,
                    ReplLeftPart, ReplRightPart, ReplHitCount,
                    SetFlag;

  FROM Registers IMPORT
    (* VAR       *) OutOfMem,
                    Expr, Val,
                    Data, Control;

  FROM FreeList IMPORT
    (* PROCEDURE *) NewPair;

  FROM Reprs IMPORT
    (* PROCEDURE *) AppChar,
                    ClearBuf,
                    WriteRepr;

  FROM PLists IMPORT
    (* PROCEDURE *) PListRepr;

  FROM ObList IMPORT
    (* PROCEDURE *) LookUpBuf;

  FROM Stacks IMPORT
    (* PROCEDURE *) Push, Pop;

  FROM Errors IMPORT
    (* TYPE      *) ErrPos, ErrMsg,
    (* VAR       *) Abort,
    (* PROCEDURE *) Error, FatalError;

  FROM Checks IMPORT
    (* PROCEDURE *) isAtom, isInt, isPList;

  FROM LISPBase IMPORT
    (* VAR       *) NilPList;


  CONST
    EOL = 12C;


  PROCEDURE WriteSExpr;

  (*  Die Ausgabe erfolgt mit dem gleichen iterativen Graphtraversierungs-
   *  verfahren, das auch im Modul 'GarbageCollector' zur Markierung aller
   *  erreichbaren Paare verwendet wird.
   *  Hier sind jedoch Atome die "Blätter", so daß Property-Listen nicht besucht
   *  (und ausgegeben) werden. Außerdem wird die Markierung eines jeden Paars
   *  beim Aufstieg wieder gelöscht, was die mehrfache Ausgabe "kollabierter
   *  Strukturen" bei Erkennung und Vermeidung von Zyklen ermöglicht.
   *)

    VAR
      Pres,
      Prev,
      Next : SExpr;


    PROCEDURE WriteAtom (f : File; sx : SExpr);

    (*  Mit 'WriteAtom (f, sx)' wird das Atom 'sx' an das Ende der Ausgabedatei
     *  'f' geschrieben. Für den ausgezeichneten S-Ausdruck 'Nil' wird der Name
     *  "NIL" ausgegeben.
     *)

    BEGIN (* WriteAtom *)
      IF sx = Nil THEN
        sx := NilPList
      END (* IF *);
      IF isPList (sx) THEN
        WriteRepr (f, PListRepr (sx))
      ELSIF isInt (sx) THEN
        WrInt (f, Value (sx), 0)
      ELSE (* isCode (sx) *)
        WrChar (f, '[');
        WrInt (f, Value (sx), 0);
        WrChar (f, ']')
      END (* IF *)
    END WriteAtom;


  BEGIN (* WriteSExpr *)
    IF isAtom (Val) THEN
      WriteAtom (StandardOutput, Val)
    ELSE
      Pres := Val;
      Prev := Val;
      WrChar (StandardOutput, '(');
      LOOP
        ReplHitCount (Pres, (HitCount (Pres) + 1) MOD 3);
        CASE HitCount (Pres) OF
          0 : (* Aufstieg zum Vorgänger *)
              Next := RightPart (Pres);
              ReplRightPart (Pres, Prev);
              Prev := Pres;
              Pres := Next;
              IF Pres = Prev THEN
                EXIT
              END (* IF *)
        | 1 : (* Abstieg zum linken Nachfolger *)
              Next := LeftPart (Pres);
              ReplLeftPart (Pres, Prev);
              IF isAtom (Next) THEN
                WriteAtom (StandardOutput, Next);
                Prev := Next
              ELSIF HitCount (Next) > 0 THEN
                WrStr (StandardOutput, "...");
                Prev := Next
              ELSE
                WrChar (StandardOutput, '(');
                Prev := Pres;
                Pres := Next
              END (* IF *)
        | 2 : (* Abstieg zum rechten Nachfolger *)
              Next := RightPart (Pres);
              ReplRightPart (Pres, LeftPart (Pres));
              ReplLeftPart (Pres, Prev);
              IF isAtom (Next) THEN
                IF Next = Nil THEN
                  WrChar (StandardOutput, ')')
                ELSE
                  WrStr (StandardOutput, " . ");
                  WriteAtom (StandardOutput, Next);
                  WrChar (StandardOutput, ')')
                END (* IF *);
                Prev := Next
              ELSIF HitCount (Next) > 0 THEN
                WrStr (StandardOutput, " ...)");
                Prev := Next
              ELSE
                WrChar (StandardOutput, ' ');
                Prev := Pres;
                Pres := Next
              END (* IF *)
        END (* CASE *)
      END (* LOOP *)
    END (* IF *)
  END WriteSExpr;


  VAR
    LookAhead : CHAR;                        (* Nächstes Zeichen  *)
    Sym       : (IDENTIFIER, NUMBER,         (* Erkanntes Symbol  *)
                 OPEN, CLOSE, DOT);


  PROCEDURE GetCh;

  (* Mit 'GetCh' wird ein Zeichen von der Standardeingabe gelesen und in
   * der Variablen 'LookAhead' abgelegt. Ein Dateiende darf dabei nicht
   * auftreten, und Zeilenendesequenzen werden durch einmaliges Melden von
   * 'LookAhead = EOF' angezeigt.
   *)

  BEGIN
    REPEAT
      LookAhead := RdChar (StandardInput);
      IF EOF THEN
        FatalError (INPUT, FileEnd)
      END
    UNTIL LookAhead # CHR (13);
    IF LookAhead = CHR (10) THEN
      LookAhead := EOL
    END
  END GetCh;


  PROCEDURE GetSym;

  (*  Mit 'GetSym' wird ein Symbol von der StandardEingabe gelesen und die
   *  entsprechende Klasse in 'Sym' angezeigt. Bei Namen und Zahlen werden
   *  zusätzlich im Register 'Val' die Property-Liste bzw. der Wert geliefert.
   *  Vor der Klassifizierung eines Symbols anhand des ersten Zeichens, müssen
   *  Leerzeichen, Zeilenwechsel und Kommentare überlesen werden.
   *  Da beim Erkennen eines Namens oder einer Zahl immer ein Zeichen zuviel
   *  gelesen wird, um das Ende festzustellen, bietet es sich an, generell ein
   *  Vorgriffs-Zeichen ('LookAhead') zu verwenden. Dieses wird mit dem Zeilen-
   *  ende-Zeichen initialisiert, da als erstes ein Kommentar eingegeben werden
   *  kann.
   *)


    PROCEDURE Identifier;

    (*  Mit 'Identifier' werden alle Zeichen eines Namens von der Standardein-
     *  gabe gelesen und in den Puffer der Repräsentationstabelle eingetragen.
     *  Die zugehörige Property-Liste wird bestimmt und im Register 'Val' gelie-
     *  fert. Für den Namen "NIL" wird der ausgezeichnete S-Ausdruck 'Nil' ge-
     *  liefert.
     *)

    BEGIN (* Identifier *)
      ClearBuf;
      REPEAT
        IF ('a' <= LookAhead) & (LookAhead <= 'z') THEN
          AppChar (CAP (LookAhead))
        ELSE
          AppChar (LookAhead)
        END (* IF *);
        IF OutOfMem THEN
          Error (INPUT, StorageExhausted);
          RETURN
        END (* IF *);
        GetCh
      UNTIL ((CAP (LookAhead) < 'A') OR ('Z' < CAP (LookAhead)))
            & ((LookAhead < '0') OR ('9' < LookAhead)) & (LookAhead # '_');
      LookUpBuf (Val);
      IF OutOfMem THEN
        Error (INPUT, StorageExhausted)
      END (* IF *);
      IF Val = NilPList THEN
        Val := Nil
      END (* IF *)
    END Identifier;


    PROCEDURE Number;

    (*  Mit 'Number' werden die Zeichen einer Zahl von der Standardeingabe gele-
     *  sen, und dabei wird ihr Wert bestimmt. Ein S-Ausdruck, der diesen Wert
     *  bezeichnet, wird im Register 'Val' geliefert.
     *)

      CONST
        MidCard = MAX (CARDINAL) DIV 2 + 1;

      VAR
        Sign : CHAR;
        n, d : CARDINAL;

    BEGIN (* Number *)
      IF (LookAhead = '+') OR (LookAhead = '-') THEN
        Sign := LookAhead;
        GetCh;
        IF (LookAhead < '0') OR ('9' < LookAhead) THEN
          Error (INPUT, IntSyntax);
          RETURN
        END (* IF *)
      ELSE
        Sign := '+'
      END (* IF *);
      n := 0;
      REPEAT
        d := ORD (LookAhead) - ORD ('0');
        IF (n > MidCard DIV 10) OR
           (n = MidCard DIV 10) & (d > MidCard MOD 10) THEN
          Error (INPUT, IntRange);
          RETURN
        END (* IF *);
        n := n * 10 + d;
        GetCh
      UNTIL (LookAhead < '0') OR ('9' < LookAhead);
      IF Sign = '-' THEN
        IF n <= MAX (INTEGER) THEN
          Val := Numb (- INTEGER (n))
        ELSE
          Val := Numb (MIN (INTEGER))
        END (* IF *)
      ELSE (* Sign = '+' *)
        IF n <= MAX (INTEGER) THEN
          Val := Numb (n)
        ELSE
          Error (INPUT, IntRange)
        END (* IF *)
      END (* IF *)
    END Number;


  BEGIN (* GetSym *)
    WHILE (LookAhead = ' ') OR (LookAhead = CHR (9)) OR (LookAhead = EOL) DO
      IF LookAhead = EOL THEN
        GetCh;
        IF LookAhead = '+' THEN
          REPEAT
            GetCh
          UNTIL LookAhead = EOL
        END (* IF *)
      ELSE
        GetCh
      END (* IF *)
    END (* WHILE *);
    CASE LookAhead OF
      'a' .. 'z',
      'A' .. 'Z' : Sym := IDENTIFIER;
                   Identifier
    | '0' .. '9',
      '+', '-'   : Sym := NUMBER;
                   Number
    | '('        : Sym := OPEN;
                   GetCh
    | ')'        : Sym := CLOSE;
                   GetCh
    | '.'        : Sym := DOT;
                   GetCh
    ELSE
      Error (INPUT, IllegalChar)
    END (* CASE *)
  END GetSym;


  PROCEDURE ReadSExpr;

  (*  Beim Lesen der eingegebenen Zeichenfolge wird der S-Ausdruck syntax-
   *  gesteuert im Speicher angelegt.
   *  Der um semantische Aktionen erweiterte (triviale) LL(1)-Parser ist
   *  "iterativ" mit einem Zustands- ('Control') und einem Datenkeller ('Data')
   *  implementiert. Ausgehend von dem Startzustand 'SEXPRESSIONREF' werden
   *  solange die zu aktuellen Zuständen gehörenden Prozeduren ausgeführt, bis
   *  ein Fehler auftritt, oder der Endzustand 'READY' erreicht wird.
   *  Bei fehlerfreier Eingabe steht der eingelesene S-Ausdruck im Register
   *  'Val', und die Keller werden so hinterlassen, wie sie beim Aufruf der
   *  Prozedur vorgefunden wurden.
   *)

    TYPE
      ProcRef = (READY, SEXPRESSIONREF, LISTREF, RESTREF, CONSTRUCTREF);

    VAR
      State  : ProcRef;


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
     *  'ProcRef', die als Ordnungszahl den Wert des Interpreter-Codes 'Code'
     *  hat.
     *)

    BEGIN (* Ref *)
      RETURN VAL (ProcRef, Value (Code))
    END Ref;


    PROCEDURE SExpression;

    (*  Mit 'SExpression' wird die Erkennung eines S-Ausdrucks begonnen.
     *  Ist das aktuelle Symbol ein Name oder eine Zahl, so ist die Erkennung
     *  auch schon beendet. Wenn das Symbol eine öffnende Klammer ist, so
     *  beginnt die Erkennung einer Folge von S-Ausdrücken. Ist bereits das
     *  nächste Symbol eine schließende Klammer, so ist die Folge leer, und NIL
     *  ist erkannt worden. Andernfalls muß ein S-Ausdruck folgen.
     *  Ein erkannter S-Ausdruck wird im Register 'Val' geliefert.
     *)

      VAR
        sx : SExpr;

    BEGIN (* SExpression *)
      LOOP
        IF (Sym = IDENTIFIER) OR (Sym = NUMBER) THEN
          EXIT
        ELSIF Sym = OPEN THEN
          GetSym;
          IF Abort THEN
            RETURN
          END (* IF *);
          IF Sym = CLOSE THEN
            Val := Nil;
            EXIT
          ELSE
            Push (Control, Code (LISTREF));
            IF OutOfMem THEN
              Error (INPUT, StorageExhausted);
              RETURN
            END (* IF *)
          END (* IF *)
        ELSE
          Error (INPUT, SExprSyntax);
          RETURN
        END (* IF *)
      END (* LOOP *);
      Pop (Control, sx);
      State := Ref (sx)
    END SExpression;


    PROCEDURE List;

    (*  Mit 'List' wird die Erkennung einer Folge von S-Ausdrücken fortgesetzt.
     *  Der zuletzt erkannte S-Ausdruck der Folge steht im Register 'Val' und
     *  wird auf den Datenkeller gelegt. Ist das aktuelle Symbol eine
     *  schließende Klammer, so ist eine Liste erkannt worden, deren
     *  Komponenten noch vom Datenkeller eingesammelt werden müssen. Wenn das
     *  Symbol ein Punkt ist, so folgt ein S-Ausdruck und eine schließende
     *  Klammer. Andernfalls ist der nächste S-Ausdruck der Folge zu erkennen.
     *)

    BEGIN (* List *)
      Push (Data, Val);
      IF OutOfMem THEN
        Error (INPUT, StorageExhausted);
        RETURN
      END (* IF *);
      GetSym;
      IF Abort THEN
        RETURN
      END (* IF *);
      IF Sym = CLOSE THEN
        Val := Nil;
        State := CONSTRUCTREF
      ELSIF Sym = DOT THEN
        Push (Control, Code (RESTREF));
        IF OutOfMem THEN
          Error (INPUT, StorageExhausted);
          RETURN
        END (* IF *);
        State := SEXPRESSIONREF;
        GetSym
      ELSE
        Push (Control, Code (CONSTRUCTREF));
        IF NOT OutOfMem THEN
          Push (Control, Code (LISTREF))
        END (* IF *);
        IF OutOfMem THEN
          Error (INPUT, StorageExhausted);
          RETURN
        END (* IF *);
        State := SEXPRESSIONREF
      END (* IF *)
    END List;


    PROCEDURE Rest;

    (*  Mit 'Rest' wird die schließende Klammer eines S-Ausdrucks mit Punkt
     *  erwartet. Die auf dem Datenkeller liegenden Komponenten müssen noch
     *  eingesammelt und mit dem im Register 'Val' stehenden S-Ausdruck
     *  verbunden werden.
     *)

    BEGIN (* Rest *)
      GetSym;
      IF Abort THEN
        RETURN
      END (* IF *);
      IF Sym = CLOSE THEN
        State := CONSTRUCTREF
      ELSE
        Error (INPUT, SExprSyntax)
      END (* IF *)
    END Rest;


    PROCEDURE Construct;

    (*  Mit 'Construct' wird ein Paar aus dem obersten Element des Datenkellers
     *  und dem S-Ausdruck im Register 'Val' gebildet, das den neuen Wert von
     *  'Val' ergibt. Dies wird wiederholt, solange der Zustand 'CONSTRUCTREF'
     *  ist.
     *)

      VAR
        sx : SExpr;

    BEGIN (* Construct *)
      REPEAT
        Pop (Data, Expr);
        NewPair (sx);
        IF OutOfMem THEN
          Error (INPUT, StorageExhausted);
          RETURN
        END (* IF *);
        AssignPair (sx, Expr, Val);
        Val := sx;
        Pop (Control, sx);
        State := Ref (sx)
      UNTIL State # CONSTRUCTREF;
      Expr := Nil
    END Construct;


  BEGIN (* ReadSExpr *)
    Push (Control, Code (READY));
    IF OutOfMem THEN
      Error (INPUT, StorageExhausted);
      RETURN
    END (* IF *);
    State := SEXPRESSIONREF;
    GetSym;
    WHILE NOT ((State = READY) OR Abort) DO
      CASE State OF
        SEXPRESSIONREF : SExpression
      | LISTREF        : List
      | RESTREF        : Rest
      | CONSTRUCTREF   : Construct
      END (* CASE *)
    END (* WHILE *)
  END ReadSExpr;


  PROCEDURE NewLine;

  (*  Zeilen-Vorschub.
   *)

  BEGIN
    WrLn (StandardOutput)
  END NewLine;


  PROCEDURE Spaces (x : INTEGER);

  (*  Leerzeichen ausgeben.
   *)

    VAR i : INTEGER;

  BEGIN
    FOR i := 1 TO x DO
      WrChar (StandardOutput, ' ')
    END (* FOR *)
  END Spaces;


  PROCEDURE Skip;

  (*  Eine angefangene Zeile wird überlesen.
   *)

  BEGIN (* Skip *)
    WHILE LookAhead # EOL DO
      GetCh
    END
  END Skip;


BEGIN (* SExprIO *)
  LookAhead := EOL
END SExprIO.
