MODULE Scanner;  (* MK 09.95 *)

  IMPORT SYSTEM, Reals, Texts, Oberon;

  CONST tab = 09X; cr  = 0DX; str = 22X; del = 7FX;

  CONST
    eot        =   0; left       =   1; right      =   2; lbrace     =   3; rbrace     =   4;
    lbracket   =   5; rbracket   =   6; eq         =   7; uneq       =   8; less       =   9;
    lesseq     =  10; greater    =  11; greatereq  =  12; and        =  13; not        =  14;
    arrow      =  15; plus       =  16; minus      =  17; star       =  18; slash      =  19;
    bar        =  20; comma      =  21; semicolon  =  22; colon      =  23; becomes    =  24;
    dot        =  25; dotdot     =  26; integer    =  27; real       =  28; long       =  29;
    char       =  30; string     =  31; ident      =  32;                   illegal    = 127;

  VAR R : Texts.Reader; W : Texts.Writer; c : CHAR; Err* : BOOLEAN; LastPos : LONGINT;
    Int*  : LONGINT;
    Real* : REAL;
    Long* : LONGREAL;
    Str*  : ARRAY 256 OF CHAR;
    Id*   : INTEGER;

  CONST nil = - 1;

  TYPE Node* = RECORD Repr*, Link : INTEGER END;

  VAR NextCh*, LenBuf*, NextId, LenTab, Reserved : INTEGER;
    Buf* : POINTER TO ARRAY MAX(INTEGER) OF CHAR;
    Tab* : POINTER TO ARRAY MAX(INTEGER) OF Node;
    List : ARRAY 97 OF INTEGER;

  PROCEDURE Mark*(Msg : ARRAY OF CHAR);

    VAR Pos : LONGINT;

  BEGIN Err := TRUE; Pos := Texts.Pos(R) - 1;
    IF Pos >= LastPos + 5 THEN LastPos := Pos;
      Texts.WriteLn(W); Texts.Write(W, tab); Texts.Write(W, tab);
      Texts.WriteInt(W, Pos, 0); Texts.WriteString(W, "  "); Texts.WriteString(W, Msg);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); HALT(99)
    END;
  END Mark;

  PROCEDURE Expand*;

    PROCEDURE ReAllocate(VAR a : SYSTEM.PTR; VAR Len : INTEGER; Size : INTEGER);

      VAR a1 : SYSTEM.PTR; Len1 : INTEGER;

    BEGIN
      IF Len > 0 THEN Len1 := Len + 1024 DIV Size; SYSTEM.NEW(a1, Len1 * Size);
        SYSTEM.MOVE(SYSTEM.ADR(a^), SYSTEM.ADR(a1^), Len * Size); a := a1; Len := Len1
      ELSE Len := (1024 - SIZE(LONGINT)) DIV Size; SYSTEM.NEW(a, Len * Size)
      END
    END ReAllocate;

  BEGIN
    IF NextCh = LenBuf THEN ReAllocate(Buf, LenBuf, SIZE(CHAR)) END;
    IF NextId = LenTab THEN ReAllocate(Tab, LenTab, SIZE(Node)) END
  END Expand;

  PROCEDURE Insert*(VAR Id : INTEGER);

    VAR h, k, n, m : INTEGER;

  BEGIN n := NextCh - Tab[NextId].Repr;
    IF NextCh = LenBuf THEN Expand END; Buf[NextCh] := 0X;
    h := ORD(Buf[NextCh - n]); k := ORD(Buf[NextCh - 1]);
    h := (((h + k) * 2 - n) * 4 - h) MOD LEN(List); Id := List[h];
    IF Id = nil THEN List[h] := NextId
    ELSE k := Tab[NextId].Repr;
      LOOP
        m := Tab[Id].Repr; n := k; WHILE Buf[m] = Buf[n] DO INC(m); INC(n) END;
        IF (n = NextCh) & (m = Tab[Id + 1].Repr) THEN NextCh := k; RETURN END;
        IF Tab[Id].Link = nil THEN EXIT ELSE Id := Tab[Id].Link END
      END;
      Tab[Id].Link := NextId
    END;
    Id := NextId; Tab[Id].Link := nil;
    INC(NextId); IF NextId = LenTab THEN Expand END; Tab[NextId].Repr := NextCh
  END Insert;

  PROCEDURE New*(s : ARRAY OF CHAR);

    VAR h, k, n : INTEGER;

  BEGIN
    n := 0; REPEAT Buf[NextCh] := s[n]; INC(NextCh); INC(n) UNTIL s[n] = 0X;
    h := ORD(s[0]); k := ORD(s[n - 1]);
    h := (((h + k) * 2 - n) * 4 - h) MOD LEN(List); Id := List[h];
    IF Id = nil THEN Tab[NextId].Link := nil; List[h] := NextId
    ELSE Tab[NextId].Link := Tab[Id].Link; Tab[Id].Link := NextId
    END;
    INC(NextId); Tab[NextId].Repr := NextCh
  END New;

  PROCEDURE Init*(Source : Texts.Text; Pos : LONGINT);

    VAR h : INTEGER;

  BEGIN Texts.OpenReader(R, Source, Pos); c := " "; Err := FALSE; LastPos := - 5;
    NextCh := 0; LenBuf := 0; NextId := 0; LenTab := 0; Expand; Tab[NextId].Repr := NextCh;
    FOR h := 0 TO LEN(List) - 1 DO List[h] := nil END;
    New("ARRAY"); New("BEGIN"); New("BY"); New("CASE"); New("CONST"); New("DIV"); New("DO");
    New("ELSE"); New("ELSIF"); New("END"); New("EXIT"); New("FOR"); New("IF"); New("IMPORT");
    New("IN"); New("IS"); New("LOOP"); New("MOD"); New("MODULE"); New("NIL"); New("OF");
    New("OR"); New("POINTER"); New("PROCEDURE"); New("RECORD"); New("REPEAT"); New("RETURN");
    New("THEN"); New("TO"); New("TYPE"); New("UNTIL"); New("VAR"); New("WHILE"); New("WITH");
    Reserved := NextId
  END Init;

  PROCEDURE Get*(VAR Tok : INTEGER);

    PROCEDURE Comment;

      VAR n : INTEGER; c1 : CHAR;

    BEGIN n := 1; c := " ";
      LOOP c1 := c; Texts.Read(R, c);
        IF (c1 = "(") & (c = "*") THEN INC(n); Texts.Read(R, c)
        ELSIF (c1 = "*") & (c = ")") THEN DEC(n); Texts.Read(R, c); IF n = 0 THEN EXIT END
        END;
        IF c = 0X THEN Mark("open comment at end of text"); EXIT END
      END
    END Comment;

    PROCEDURE Number;

      VAR n : INTEGER;

      PROCEDURE IntNumber;

        VAR d, m : INTEGER;

      BEGIN Tok := integer; Int := 0;
        IF ("A" <= c) & (c <= "F") OR (c = "H") OR (c = "X") THEN
          WHILE ("0" <= c) & (c <= "9") OR ("A" <= c) & (c <= "F") DO
            IF n < LEN(Str) THEN Str[n] := c; INC(n) END;
            Texts.Read(R, c)
          END;
          IF (c = "H") OR (c = "X") THEN IF c ="X" THEN Tok := char END;
            Texts.Read(R, c);
            IF n > 0 THEN
              d := ORD(Str[0]) - ORD("0"); IF d > 9 THEN DEC(d, ORD("A") - ORD("0") - 10) END;
              IF (n <= 8) & (Tok = integer) OR (n <= 2) THEN
                IF (n = 8) & (d > 7) THEN Int := d - 10H ELSE Int := d END;
                FOR m := 1 TO n - 1 DO
                  d := ORD(Str[m]) - ORD("0"); IF d > 9 THEN DEC(d, ORD("A") - ORD("0") - 10) END;
                  Int := Int * 10H + d
                END
              ELSE Mark("number out of range")
              END
            END
          ELSE Mark("illegal character in number")
          END
        ELSIF n > 0 THEN Int := ORD(Str[0]) - ORD("0");
          FOR m := 1 TO n - 1 DO d := ORD(Str[m]) - ORD("0");
            IF (Int < MAX(LONGINT) DIV 10) OR
               (Int = MAX(LONGINT) DIV 10) & (d <= MAX(LONGINT) MOD 10) THEN Int := Int * 10 + d
            ELSE Mark("number out of range"); Int := 0; RETURN
            END
          END
        END
      END IntNumber;

      PROCEDURE RealNumber;

        VAR m, Exp : INTEGER; Neg : BOOLEAN;

      BEGIN Tok := real; Real := 0; Exp := 0; m := n;
        IF m = 0 THEN WHILE c = "0" DO DEC(m); Texts.Read(R, c) END END;
        WHILE ("0" <= c) & (c <= "9") DO IF n < LEN(Str) THEN Str[n] := c; INC(n) END;
          Texts.Read(R, c)
        END;
        IF (c = "E") OR (c = "D") THEN IF c = "D" THEN Tok := long; Long := 0 END;
          Texts.Read(R, c); Neg := c = "-";
          IF (c = "+") OR (c = "-") THEN Texts.Read(R, c) END;
          IF ("0" <= c) & (c <= "9") THEN
            REPEAT IF Exp < 1000 THEN Exp := Exp * 10 + ORD(c) - ORD("0") END;
              Texts.Read(R, c)
            UNTIL (c < "0") OR ("9" < c);
            IF Neg THEN Exp := - Exp END
          ELSE Mark("illegal character in number"); RETURN
          END
        END;
        IF m < LEN(Str) THEN INC(Exp, m - 1);
          IF n > 0 THEN
            IF Tok = real THEN
              REPEAT DEC(n); Real := Real / 10 + (ORD(Str[n]) - ORD("0")) UNTIL n = 0;
              IF (Exp < 38) OR (Exp = 38) & (Real <= 3.402823) THEN
                Real := Real * Reals.Ten(Exp)
              ELSE Mark("number out of range"); Real := 0
              END
            ELSE
              REPEAT DEC(n); Long := Long / 10 + (ORD(Str[n]) - ORD("0")) UNTIL n = 0;
              IF (Exp < 308) OR (Exp = 308) & (Long <= 1.797693) THEN
                Long := Long * Reals.TenL(Exp)
              ELSE Mark("number out of range"); Long := 0
              END
            END
          END
        ELSE Mark("number out of range")
        END
      END RealNumber;

    BEGIN n := 0; WHILE c = "0" DO Texts.Read(R, c) END;
      WHILE ("0" <= c) & (c <= "9") DO IF n < LEN(Str) THEN Str[n] := c; INC(n) END;
        Texts.Read(R, c)
      END;
      IF c = "." THEN Texts.Read(R, c); IF c = "." THEN IntNumber; c := del ELSE RealNumber END
      ELSE IntNumber
      END
    END Number;

    PROCEDURE String;

      VAR Term : CHAR; n : INTEGER;

    BEGIN Tok := string; Term := c; n := 0;
      LOOP Texts.Read(R, c);
        IF c = Term THEN Texts.Read(R, c); EXIT
        ELSIF (c = 0X) OR (c = cr) THEN Mark("string terminator not on this line");
          Str[0] := 0X; RETURN
        ELSIF n < LEN(Str) THEN Str[n] := c; INC(n)
        END
      END;
      IF n < LEN(Str) THEN Str[n] := 0X ELSE Mark("string too long"); Str[0] := 0X END
    END String;

    PROCEDURE Ident;

    BEGIN Tok := ident;
      REPEAT IF NextCh = LenBuf THEN Expand END; Buf[NextCh] := c; INC(NextCh); Texts.Read(R, c)
      UNTIL (c < "0") OR ("9" < c) & (CAP(c) < "A") OR ("Z" < CAP(c));
      Insert(Id); IF Id < Reserved THEN INC(Tok, Id + 1) END
    END Ident;

  BEGIN
    LOOP WHILE c <= " " DO IF c = 0X THEN Tok := eot; RETURN END; Texts.Read(R, c) END;
      IF c = "(" THEN Texts.Read(R, c); IF c = "*" THEN Comment ELSE Tok := left; RETURN END
      ELSE EXIT
      END
    END;
    CASE c OF
      str      : String; RETURN
    | "#"      : Tok := uneq
    | "&"      : Tok := and
    | ")"      : Tok := right
    | "*"      : Tok := star
    | "+"      : Tok := plus
    | ","      : Tok := comma
    | "-"      : Tok := minus
    | "."      : Texts.Read(R, c);
                 IF c = "." THEN Tok := dotdot ELSE Tok := dot; RETURN END
    | "/"      : Tok := slash
    | "0".."9" : Number; RETURN
    | ":"      : Texts.Read(R, c);
                 IF c = "=" THEN Tok := becomes ELSE Tok := colon; RETURN END
    | ";"      : Tok := semicolon
    | "<"      : Texts.Read(R, c);
                 IF c = "=" THEN Tok := lesseq ELSE Tok := less; RETURN END
    | "="      : Tok := eq
    | ">"      : Texts.Read(R, c);
                 IF c = "=" THEN Tok := greatereq ELSE Tok := greater; RETURN END
    | "A".."Z" : Ident; RETURN
    | "["      : Tok := lbracket
    | "]"      : Tok := rbracket
    | "^"      : Tok := arrow
    | "a".."z" : Ident; RETURN
    | "{"      : Tok := lbrace
    | "|"      : Tok := bar
    | "}"      : Tok := rbrace
    | "~"      : Tok := not
    | del      : Tok := dotdot
    ELSE Tok := illegal
    END;
    Texts.Read(R, c)
  END Get;

BEGIN Texts.OpenWriter(W)
END Scanner.
