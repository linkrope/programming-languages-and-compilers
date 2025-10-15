MODULE Asm;  (* MK 06.96 *)

  IMPORT Display, Texts, Oberon, TextDocs, LongInt, RISC;

  VAR R:Texts.Reader; W: Texts.Writer; c: CHAR; Err: BOOLEAN; LastPos, Pos: LONGINT;

  CONST id = "A"; op = "O"; num = "0";

  TYPE
    OpenBuf = POINTER TO ARRAY OF CHAR;
    OpenSym = POINTER TO ARRAY OF RECORD Repr: INTEGER; Def: BOOLEAN; Val: LONGINT END;

  VAR Id, NextCh, NextId, PCId: INTEGER; Num: LONGINT;
    Buf: OpenBuf;
    Sym: OpenSym;

  PROCEDURE Init;

    PROCEDURE New(s: ARRAY OF CHAR; Val: LONGINT);

      VAR n: INTEGER;

    BEGIN
      n := 0; REPEAT Buf[NextCh] := s[n]; INC(NextCh); INC(n) UNTIL s[n] = 0X;
      Sym[NextId].Def := TRUE; Sym[NextId].Val := Val;
      INC(NextId); Sym[NextId].Repr := NextCh
    END New;

  BEGIN c := " "; Err := FALSE; LastPos := - 1;
    NextCh := 0; NextId := 0; Sym[NextId].Repr := NextCh;
    New("ADD", RISC.add); New("SUB", RISC.sub); New("MUL", RISC.mul); New("DIV", RISC.div);
    New("MOD", RISC.mod); New("CMP", RISC.cmp);
    New("OR", RISC.or); New("AND", RISC.and); New("BIC", RISC.bic); New("XOR", RISC.xor);
    New("SHL", RISC.shl); New("SHA", RISC.sha); New("CHK", RISC.chk);
    New("ADDI", RISC.addi); New("SUBI", RISC.subi); New("MULI", RISC.muli); New("DIVI", RISC.divi);
    New("MODI", RISC.modi); New("CMPI", RISC.cmpi);
    New("ORI", RISC.ori); New("ANDI", RISC.andi); New("BICI", RISC.bici); New("XORI", RISC.xori);
    New("SHLI", RISC.shli); New("SHAI", RISC.shai); New("CHKI", RISC.chki);
    New("LDW", RISC.ldw); New("STW", RISC.stw); New("POP", RISC.pop); New("PSH", RISC.psh);
    New("BEQ", RISC.beq); New("BNE", RISC.bne); New("BLT", RISC.blt); New("BGE", RISC.bge);
    New("BLE", RISC.ble); New("BGT", RISC.bgt);
    New("BSR", RISC.bsr); New("RET", RISC.ret);
    New("RD", RISC.rd); New("WD", RISC.wd); New("WH", RISC.wh); New("WL", RISC.wl);
    PCId := NextId; New("PC", 0); New("LNK", 31)
  END Init;

  PROCEDURE Expand;

  VAR n: LONGINT;
    Buf1: OpenBuf;
    Sym1: OpenSym;

  BEGIN
    IF NextCh = LEN(Buf^) THEN NEW(Buf1, LEN(Buf^) * 2);
      FOR n := 0 TO LEN(Buf^) - 1 DO Buf1[n] := Buf[n] END;
      Buf := Buf1
    END;
    IF NextId = LEN(Sym^) THEN NEW(Sym1, LEN(Sym^) * 2);
      FOR n := 0 TO LEN(Sym^) - 1 DO Sym1[n] := Sym[n] END;
      Sym := Sym1
    END
  END Expand;

  PROCEDURE WriteString(VAR W: Texts.Writer; s: ARRAY OF CHAR);

    CONST tab = 09X; str = 22X;

    VAR n: INTEGER; c: CHAR;

  BEGIN n := 0; c := s[n];
    WHILE c # 0X DO
      IF c = "\" THEN INC(n); c := s[n];
        IF    c = "n" THEN Texts.WriteLn(W)
        ELSIF c = "t" THEN Texts.Write(W, tab)
        ELSIF c = "'" THEN Texts.Write(W, str)
        ELSE Texts.Write(W, c)
        END
      ELSE Texts.Write(W, c)
      END;
      INC(n); c := s[n]
    END
  END WriteString;

  PROCEDURE WriteRepr(VAR W: Texts.Writer; Id: INTEGER);

    VAR n: INTEGER;

  BEGIN
    FOR n := Sym[Id].Repr TO Sym[Id + 1].Repr - 1 DO Texts.Write(W, Buf[n]) END
  END WriteRepr;

  PROCEDURE ReportErr(Pos: LONGINT; Msg: ARRAY OF CHAR);

  BEGIN
    WriteString(W, "\n\t\t"); Texts.WriteInt(W, Pos, 0); WriteString(W, "\t"); WriteString(W, Msg);
    Texts.Append(Oberon.Log, W.buf)
  END ReportErr;

  PROCEDURE Mark(Msg: ARRAY OF CHAR);

  BEGIN Err := TRUE;
    IF Pos > LastPos THEN LastPos := Pos; ReportErr(Pos, Msg) END
  END Mark;

  PROCEDURE Get(VAR Tok: CHAR);

    CONST cr = 0DX;

    PROCEDURE Ident;

    (*  id = (letter | "_") {letter | "_" | digit}.
     *  letter = "A" | ... | "Z" | "a" | ... | "z.
     *)

      VAR m, n: INTEGER;

    BEGIN Tok := id; Id := 0;
      REPEAT IF NextCh = LEN(Buf^) THEN Expand END; Buf[NextCh] := c; INC(NextCh);
        Texts.Read(R, c)
      UNTIL (c < "0") OR ("9" < c) & (CAP(c) < "A") OR ("Z" < CAP(c)) & (c # "_");
      IF NextCh = LEN(Buf^) THEN Expand END; Buf[NextCh] := 0X;
      WHILE Id < NextId DO
        m := Sym[Id].Repr; n := Sym[NextId].Repr; WHILE Buf[m] = Buf[n] DO INC(m); INC(n) END;
        IF (n = NextCh) & (m = Sym[Id + 1].Repr) THEN NextCh := Sym[NextId].Repr;
          IF Id < PCId THEN Tok := op END;
          RETURN
        END;
        INC(Id)
      END;
      Sym[NextId].Def := FALSE;
      INC(NextId); IF NextId = LEN(Sym^) THEN Expand END; Sym[NextId].Repr := NextCh
    END Ident;

    PROCEDURE Number;

    (*  num = digit {digit}.
     *  digit = "0" | ... | "9".
     *)

      VAR d: INTEGER;

    BEGIN Tok := num; Num := 0;
      REPEAT d := ORD(c) - ORD("0"); Texts.Read(R, c);
        IF (Num < MAX(LONGINT) DIV 10) OR
           (Num = MAX(LONGINT) DIV 10) & (d <= MAX(LONGINT) MOD 10) THEN Num := Num * 10 + d
        ELSE Mark("number out of range");
          Num := 0
        END
      UNTIL (c < "0") OR ("9" < c)
    END Number;

  BEGIN
    LOOP
      WHILE (c # 0X) & (c <= " ") DO Texts.Read(R, c) END;
      IF c = "!" THEN REPEAT Texts.Read(R, c) UNTIL (c = cr) OR (c = 0X)
      ELSE EXIT
      END
    END;
    Pos := Texts.Pos(R) - 1;
    IF ("A" <= CAP(c)) & (CAP(c) <= "Z") OR (c = "_") THEN Ident
    ELSIF ("0" <= c) & (c <= "9") THEN Number
    ELSIF c = 0X THEN Tok := 0X
    ELSE Tok := c; Texts.Read(R, c)
    END
  END Get;

  PROCEDURE Program;

  (*  Program = {{id ["*"]} (id ["*"] "=" ConstExpression | Statement)}.
   *)

    VAR Tok: CHAR; Id1: INTEGER; Marked: BOOLEAN;

    TYPE ExprDesc = RECORD END;
      Expr  = POINTER TO ExprDesc;
      Const = POINTER TO RECORD (ExprDesc) Val: LONGINT END;
      Var   = POINTER TO RECORD (ExprDesc) Id: INTEGER END;
      BinOp = POINTER TO RECORD (ExprDesc) Pos: LONGINT; Op: CHAR; Left, Right: Expr END;

    VAR E: Expr; Val: LONGINT;

    TYPE Stmt = POINTER TO StmtDesc;
      StmtDesc = RECORD PC, Pos: LONGINT; Op: INTEGER; E1, E2, E3: Expr; Next: Stmt END;

    VAR Patch: Stmt;

    PROCEDURE NewLabel(Id: INTEGER; Marked: BOOLEAN; Val: LONGINT);

    BEGIN
      IF Sym[Id].Def & (Id # PCId) THEN Mark("label defined twice")
      ELSE Sym[Id].Def := TRUE; Sym[Id].Val := Val;
        IF Marked THEN
          WriteString(W, "\n\t\t");
          WriteRepr(W, Id); WriteString(W, " = "); Texts.WriteInt(W, Val, 0);
          Texts.Append(Oberon.Log, W.buf)
        END
      END
    END NewLabel;

    PROCEDURE Emit(PC, Pos: LONGINT;  Op: INTEGER; a, b, c: LONGINT);

      VAR OK: BOOLEAN;

      PROCEDURE IsReg(x: LONGINT): BOOLEAN;

      BEGIN RETURN (0 <= x) & (x < 20H)
      END IsReg;

      PROCEDURE IsInt(x: LONGINT): BOOLEAN;

      BEGIN RETURN (MIN(INTEGER) <= x) & (x <= MAX(INTEGER))
      END IsInt;

    BEGIN
      IF IsReg(a) & IsReg(b) THEN
        CASE Op OF
          RISC.add .. RISC.sha:
            OK := IsReg(c)
        | RISC.chk:
            OK := (b = 0) & IsReg(c)
        | RISC.addi .. RISC.shai, RISC.ldw, RISC.stw, RISC.pop, RISC.psh:
            OK := IsInt(c)
        | RISC.chki, RISC.beq .. RISC.bgt:
            OK := (b = 0) & IsInt(c)
        | RISC.bsr, RISC.ret:
            OK := (a = 0) & (b = 0) & IsInt(c)
        | RISC.rd:
            OK := (b = 0) & (c = 0)
        | RISC.wd, RISC.wh:
            OK := (a = 0) & (b = 0) & IsReg(c)
        | RISC.wl:
            OK := (a = 0) & (b = 0) & (c = 0)
        END
      ELSE OK := FALSE; a := a MOD 20H; b := b MOD 20H
      END;
      IF ~ OK THEN ReportErr(Pos, "illegal instruction format");
        Err := TRUE
      END;
      IF Op >= 20H THEN DEC(Op, 40H) END;
      RISC.M[PC] := ASH(ASH(ASH(Op, 5) + a, 5) + b, 16) + (c MOD 10000H)
    END Emit;

    PROCEDURE NewConst (Val: LONGINT): Const;

      VAR E: Const;

    BEGIN NEW(E); E.Val := Val; RETURN E
    END NewConst;

    PROCEDURE NewVar(Id: INTEGER): Var;

      VAR E: Var;

    BEGIN NEW(E); E.Id := Id; RETURN E
    END NewVar;

    PROCEDURE NewBinOp(Pos: LONGINT; Op: CHAR; Left, Right: Expr): BinOp;

      VAR E: BinOp;

    BEGIN NEW(E); E.Pos := Pos; E.Op := Op; E.Left := Left; E.Right := Right; RETURN E
    END NewBinOp;

    PROCEDURE Eval(E: Expr): LONGINT;

      VAR E1: BinOp; Val: LONGINT;

    BEGIN
      IF E IS Const THEN RETURN E(Const).Val
      ELSIF E IS Var THEN RETURN Sym[E(Var).Id].Val
      ELSE E1 := E(BinOp);
        IF    E1.Op = "+" THEN LongInt.Add(Val, Eval(E1.Left), Eval(E1.Right))
        ELSIF E1.Op = "-" THEN LongInt.Sub(Val, Eval(E1.Left), Eval(E1.Right))
        ELSIF E1.Op = "*" THEN LongInt.Mul(Val, Eval(E1.Left), Eval(E1.Right))
        ELSIF E1.Op = "/" THEN LongInt.Div(Val, Eval(E1.Left), Eval(E1.Right))
        ELSIF E1.Op = "%" THEN LongInt.Mod(Val, Eval(E1.Left), Eval(E1.Right))
        END;
        IF ~ LongInt.OK THEN ReportErr(E1.Pos, "value out of range");
          Err := TRUE; Val := 1
        END;
        RETURN Val
      END
    END Eval;

    PROCEDURE NewPatch(PC, Pos: LONGINT; Op: INTEGER; E1, E2, E3: Expr);

      VAR Patch1: Stmt;

    BEGIN NEW(Patch1);
      Patch1.PC := PC; Patch1.Pos := Pos;
      Patch1.Op := Op; Patch1.E1 := E1; Patch1.E2 := E2; Patch1.E3 := E3;
      Patch1.Next := Patch; Patch := Patch1
    END NewPatch;

    PROCEDURE Expression(VAR E: Expr; VAR Val: LONGINT);

    (*  Expression = ["+" | "-"] Term {("+" | "-") Term}.
     *)

      VAR Pos1: LONGINT; Op: CHAR; E1: Expr; Val1: LONGINT;

      PROCEDURE Term(VAR E: Expr; VAR Val: LONGINT);

      (*  Term = Factor {("*" | "/" | "%") Factor}.
       *)

        VAR Pos1: LONGINT; Op: CHAR; E1: Expr; Val1: LONGINT;

        PROCEDURE Factor(VAR E: Expr; VAR Val: LONGINT);

        (*  Factor = id | num | "(" Expression ")".
         *)

        BEGIN
          IF Tok = id THEN
            IF Sym[Id].Def THEN E := NIL; Val := Sym[Id].Val ELSE E := NewVar(Id) END;
            Get(Tok)
          ELSIF Tok = num THEN E := NIL; Val := Num; Get(Tok)
          ELSIF Tok = "(" THEN Get(Tok);
            Expression(E, Val);
            IF Tok = ")" THEN Get(Tok) ELSE Mark("\')\' expected") END
          ELSE Mark("expression expected");
            E := NIL; Val := 1
          END
        END Factor;

      BEGIN
        Factor(E, Val);
        WHILE (Tok = "*") OR (Tok = "/") OR (Tok = "%") DO Pos1 := Pos; Op := Tok; Get(Tok);
          Factor(E1, Val1);
          IF (E = NIL) & (E1 = NIL) THEN
            IF Op = "*" THEN LongInt.Mul(Val, Val, Val1)
            ELSIF Op = "/" THEN LongInt.Div(Val, Val, Val1) ELSE LongInt.Mod(Val, Val, Val1)
            END;
            IF ~ LongInt.OK THEN ReportErr(Pos1, "value out of range");
              Err := TRUE; Val := 1
            END
          ELSE
            IF E = NIL THEN E := NewConst(Val) END;
            IF E1 = NIL THEN E1 := NewConst(Val1) END;
            E := NewBinOp(Pos1, Op, E, E1)
          END
        END
      END Term;

    BEGIN
      IF (Tok = "+") OR (Tok = "-") THEN Pos1 := Pos; Op := Tok; Get(Tok) ELSE Op := "+" END;
      Term(E, Val);
      IF Op = "-" THEN
        IF E = NIL THEN LongInt.Neg(Val, Val);
          IF ~ LongInt.OK THEN ReportErr(Pos1, "value out of range");
            Err := TRUE; Val := 1
          END
        ELSE E := NewBinOp(Pos1, Op, NewConst(0), E)
        END
      END;
      WHILE (Tok = "+") OR (Tok = "-") DO Pos1 := Pos; Op := Tok; Get(Tok);
        Term(E1, Val1);
        IF (E = NIL) & (E1 = NIL) THEN
          IF Op = "+" THEN LongInt.Add(Val, Val, Val1) ELSE LongInt.Sub(Val, Val, Val1) END;
          IF ~ LongInt.OK THEN ReportErr(Pos1, "value out of range");
            Err := TRUE; Val := 1
          END
        ELSE
          IF E = NIL THEN E := NewConst(Val) END;
          IF E1 = NIL THEN E1 := NewConst(Val1) END;
          E := NewBinOp(Pos1, Op, E, E1)
        END
      END
    END Expression;

    PROCEDURE Statement;

    (*  Statement = op Expression ["," Expression ["," Expression]].
     *)

      VAR Pos1: LONGINT; Op: INTEGER; E1, E2, E3: Expr; Val1, Val2, Val3: LONGINT;

      PROCEDURE Put(Op: INTEGER;
                    E1: Expr; Val1: LONGINT; E2: Expr; Val2: LONGINT; E3: Expr; Val3: LONGINT);

        VAR PC: LONGINT;

      BEGIN PC := Sym[PCId].Val;
        IF (PC < 0) OR (LEN(RISC.M) <= PC) THEN ReportErr(Pos1, "PC out of memory");
          Err := TRUE; PC := 0
        END;
        IF (E1 = NIL) & (E2 = NIL) & (E3 = NIL) THEN
          Emit(PC, Pos1, Op, Val1, Val2, Val3)
        ELSE
          IF E1 = NIL THEN E1 := NewConst(Val1) END;
          IF E2 = NIL THEN E2 := NewConst(Val2) END;
          IF E3 = NIL THEN E3 := NewConst(Val3) END;
          NewPatch(PC, Pos1, Op, E1, E2, E3)
        END;
        INC(PC); Sym[PCId].Val := PC
      END Put;

    BEGIN
      IF Tok = op THEN Pos1 := Pos; Op := SHORT(Sym[Id].Val); Get(Tok);
        Expression(E1, Val1);
        IF Tok = "," THEN Get(Tok);
          Expression(E2, Val2);
          IF Tok = "," THEN Get(Tok);
            Expression(E3, Val3);
            Put(Op, E1, Val1, E2, Val2, E3, Val3)
          ELSE
            CASE Op OF
              RISC.chk, RISC.chki, RISC.beq .. RISC.bgt:
                Put(Op, E1, Val1, NIL, 0, E2, Val2)
            ELSE ReportErr(Pos1, "illegal instruction format");
              Err := TRUE
            END
          END
        ELSE
          CASE Op OF
            RISC.bsr, RISC.ret, RISC.wd, RISC.wh:
              Put(Op, NIL, 0, NIL, 0, E1, Val1)
          | RISC.rd:
              Put(Op, E1, Val1, NIL, 0, NIL, 0)
          | RISC.wl:
              Put(Op, NIL, 0, NIL, 0, NIL, 0)
          ELSE ReportErr(Pos1, "illegal instruction format");
            Err := TRUE
          END
        END
      ELSE Mark("instruction expected");
        WHILE (Tok # op) & (Tok # 0X) DO Get(Tok) END
      END
    END Statement;

  BEGIN Get(Tok); Patch := NIL;
    WHILE Tok # 0X DO
      IF Tok = id THEN Id1 := Id; Get(Tok);
        IF Tok = "*" THEN Marked := TRUE; Get(Tok) ELSE Marked := FALSE END;
        WHILE Tok = id DO NewLabel(Id1, Marked, Sym[PCId].Val); Id1 := Id; Get(Tok);
          IF Tok = "*" THEN Marked := TRUE; Get(Tok) ELSE Marked := FALSE END
        END;
        IF Tok = "=" THEN Get(Tok);
          Expression(E, Val);
          IF E = NIL THEN NewLabel(Id1, Marked, Val) ELSE Mark("value undefined") END
        ELSE NewLabel(Id1, Marked, Sym[PCId].Val); Statement
        END
      ELSE Statement
      END
    END;
    IF ~ Err THEN
      FOR Id1 := PCId TO NextId - 1 DO
        IF ~ Sym[Id1].Def THEN Err := TRUE;
          WriteString(W, "\n\t\t\'"); WriteRepr(W, Id1); WriteString(W, "\' undefined");
          Texts.Append(Oberon.Log, W.buf)
        END
      END;
      IF ~ Err THEN
        WHILE Patch # NIL DO
          Emit(Patch.PC, Patch.Pos, Patch.Op, Eval(Patch.E1), Eval(Patch.E2), Eval(Patch.E3));
          Patch := Patch.Next
        END
      END
    END
  END Program;

  PROCEDURE Load*;

    VAR S: Texts.Scanner; T: Texts.Text; F: Display.Frame;
      Beg, End, Time: LONGINT;

    PROCEDURE Process(Source: Texts.Text; Pos: LONGINT);

    BEGIN Texts.OpenReader(R, Source, Pos); Init;
      WriteString(W, "\tassembling\t"); Program; Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf)
    END Process;

  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Char THEN
      IF S.c = "*" THEN T := TextDocs.GetText(F);
        IF T # NIL THEN Process(T, 0) END
      ELSIF S.c = "@" THEN Oberon.GetSelection(T, Beg, End, Time);
        IF Time >= 0 THEN Process(T, Beg) END
      ELSIF S.c = "^" THEN Oberon.GetSelection(T, Beg, End, Time);
        IF Time >= 0 THEN Texts.OpenScanner(S, T, Beg); Texts.Scan(S) END
      END
    END;
    IF S.class = Texts.Name THEN NEW(T); Texts.Open(T, S.s);
      IF T.len # 0 THEN Process(T, 0)
      ELSE
        Texts.WriteString(W, S.s); WriteString(W, " not found\n");
        Texts.Append(Oberon.Log, W.buf)
      END
    END
  END Load;

  PROCEDURE Exec*;

    VAR S: Texts.Scanner;

  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN RISC.Execute(S.i, S, Oberon.Log) END
  END Exec;

BEGIN Texts.OpenWriter(W); NEW(Buf, 2000); NEW(Sym, 250);
  WriteString(W, "RISC Assembler / MK 06.96\n");
  Texts.Append(Oberon.Log, W.buf)
END Asm.Load *
