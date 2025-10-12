MODULE F;  (* MaKro 01.96 *)

  IMPORT Texts, Viewers, Oberon, TextFrames;

  CONST nil = - 1;
    equal   =  0; equiv   =  1; unequal =  2; unequiv =  3; lss     =  4; lsseq   =  5;
    grt     =  6; grteq   =  7; plus    =  8; minus   =  9; star    = 10; slash   = 11;
    neg     = 12; left    = 13; right   = 14; colon   = 15; arrow   = 16; comma   = 17;
    false   = 18; true    = 19; y       = 20; tuple   = 21; proj    = 22; number  = 23;
    ident   = 24; and     = 25; bool    = 26; else    = 27; if      = 28; in      = 29;
    int     = 30; let     = 31; not     = 32; or      = 33; then    = 34; eof     = 35;

  TYPE LExpr = POINTER TO LExprNode; LExprNode = RECORD END;
    Con = POINTER TO RECORD (LExprNode) Fun, Arg  : INTEGER END;
    Var = POINTER TO RECORD (LExprNode) Id        : INTEGER END;
    App = POINTER TO RECORD (LExprNode) Left, Right : LExpr END;
    Abs = POINTER TO RECORD (LExprNode) Var, Body   : LExpr END;
    Ind = POINTER TO RECORD (LExprNode) Expr        : LExpr END;
    Ite = POINTER TO RECORD (LExprNode) Then, Else  : LExpr END;
    Tup = POINTER TO RECORD (LExprNode) Left, Right : LExpr END;
    Cls = POINTER TO RECORD (LExprNode) Abs, Env    : LExpr END;
    Fix = POINTER TO RECORD (LExprNode) Expr, Env   : LExpr END;

  VAR R : Texts.Reader; W : Texts.Writer; c : CHAR; Tok, Val : INTEGER; False, True : LExpr;
    NextCh, NextId, NextType, NextBind : INTEGER;
    Buf  : ARRAY 1000 OF CHAR;
    Repr : ARRAY  100 OF INTEGER;
    Tab  : ARRAY  100 OF INTEGER;
    Env  : ARRAY  100 OF RECORD
                           Id, Type, Params : INTEGER;
                           Def, Ref : LExpr
                         END;

  PROCEDURE Error(Msg : ARRAY OF CHAR);

  BEGIN Texts.WriteLn(W); Texts.WriteInt(W, Texts.Pos(R) - 1, 6); Texts.WriteString(W, " : ");
    Texts.WriteString(W, Msg); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); HALT(99)
  END Error;

  PROCEDURE Enter(s : ARRAY OF CHAR);

    VAR n : INTEGER; c : CHAR;

  BEGIN Repr[NextId] := NextCh; INC(NextId);
    n := 0; REPEAT c := s[n]; Buf[NextCh] := c; INC(n); INC(NextCh) UNTIL c = 0X
  END Enter;

  PROCEDURE Get;

    PROCEDURE Number;

    (*  number = digit {digit}.
     *  digit = "0" | ... | "9".
     *)

      VAR d : INTEGER;

    BEGIN Tok := number; Val := 0;
      REPEAT d := ORD(c) - ORD("0"); Texts.Read(R, c);
        IF (Val < MAX(INTEGER) DIV 10) OR
           (Val = MAX(INTEGER) DIV 10) & (d <= MAX(INTEGER) MOD 10) THEN Val := Val * 10 + d
        ELSE Error("number out of range")
        END
      UNTIL (c < "0") OR ("9" < c)
    END Number;

    PROCEDURE Ident;

    (*  ident = letter {letter | digit}.
     *  letter = "a" | ... | "z" | "A" | ... | "Z".
     *)

      VAR NextCh1, n, m : INTEGER;

    BEGIN Tok := ident; Val := 0; NextCh1 := NextCh;
      REPEAT IF NextCh >= LEN(Buf) - 1 THEN Error("identifiers too long") END;
        Buf[NextCh] := c; INC(NextCh); Texts.Read(R, c)
      UNTIL (c < "0") OR ("9" < c) & (CAP(c) < "A") OR ("Z" < CAP(c));
      Buf[NextCh] := " "; (* sentinel *)
      WHILE Val < NextId DO
        n := NextCh1; m := Repr[Val]; WHILE Buf[n] = Buf[m] DO INC(n); INC(m) END;
        IF (n = NextCh) & (Buf[m] = 0X) THEN NextCh := NextCh1;
          IF Val <= then - and THEN Tok := and + Val END;
          RETURN
        ELSE INC(Val)
        END
      END;
      IF NextId >= LEN(Repr) THEN Error("too many identifiers") END;
      Repr[NextId] := NextCh1; INC(NextId); Buf[NextCh] := 0X; INC(NextCh)
    END Ident;

  BEGIN
    LOOP WHILE c <= " " DO IF c # 0X THEN Texts.Read(R, c) ELSE Tok := eof; RETURN END END;
      IF c = "!" THEN REPEAT Texts.Read(R, c) UNTIL (c = 0DX) OR (c = 0X)
      ELSIF c = "~" THEN c := 0X
      ELSE EXIT
      END
    END;
    CASE c OF
      "("      : Tok := left
    | ")"      : Tok := right
    | "*"      : Tok := star
    | "+"      : Tok := plus
    | ","      : Tok := comma
    | "-"      : Texts.Read(R, c);
                 IF c = ">" THEN Tok := arrow ELSE Tok := minus; RETURN END
    | "/"      : Tok := slash
    | "0".."9" : Number; RETURN
    | ":"      : Tok := colon
    | "<"      : Texts.Read(R, c);
                 IF c = "=" THEN Tok := lsseq ELSIF c = ">" THEN Tok := unequal
                 ELSE Tok := lss; RETURN
                 END
    | "="      : Tok := equal
    | ">"      : Texts.Read(R, c);
                 IF c = "=" THEN Tok := grteq ELSE Tok := grt; RETURN END
    | "A".."Z" : Ident; RETURN
    | "a".."z" : Ident; RETURN
    ELSE Tok := nil; Error("ill char")
    END;
    Texts.Read(R, c)
  END Get;

  PROCEDURE Bool(Cond : BOOLEAN) : LExpr;

  BEGIN IF Cond THEN RETURN True ELSE RETURN False END
  END Bool;

  PROCEDURE NewCon(Fun, Arg : INTEGER) : Con;

    VAR Code : Con;

  BEGIN NEW(Code); Code.Fun := Fun; Code.Arg := Arg; RETURN Code
  END NewCon;

  PROCEDURE NewVar() : Var;

    VAR Code : Var;

  BEGIN NEW(Code); RETURN Code
  END NewVar;

  PROCEDURE NewApp(Left, Right : LExpr) : App;

    VAR Code : App;

  BEGIN NEW(Code); Code.Left := Left; Code.Right := Right; RETURN Code
  END NewApp;

  PROCEDURE NewAbs(Var, Body : LExpr) : Abs;

    VAR Code : Abs;

  BEGIN NEW(Code); Code.Var := Var; Code.Body := Body; RETURN Code
  END NewAbs;

  PROCEDURE NewInd(Expr : LExpr) : Ind;

    VAR Code : Ind;

  BEGIN NEW(Code); Code.Expr := Expr; RETURN Code
  END NewInd;

  PROCEDURE NewIte(Then, Else : LExpr) : Ite;

    VAR Code : Ite;

  BEGIN NEW(Code); Code.Then := Then; Code.Else := Else; RETURN Code
  END NewIte;

  PROCEDURE NewTup(Left, Right : LExpr) : Tup;

    VAR Code : Tup;

  BEGIN NEW(Code); Code.Left := Left; Code.Right := Right; RETURN Code
  END NewTup;

  PROCEDURE NewCls(Abs, Env : LExpr) : Cls;

    VAR Code : Cls;

  BEGIN NEW(Code); Code.Abs := Abs; Code.Env := Env; RETURN Code
  END NewCls;

  PROCEDURE NewFix(Expr, Env : LExpr) : Fix;

    VAR Code : Fix;

  BEGIN NEW(Code); Code.Expr := Expr; Code.Env := Env; RETURN Code
  END NewFix;

  PROCEDURE SECDMachine(VAR Code : LExpr);

    CONST apply = NIL;

    VAR S, E, C, D, Top, Top1, Top2 : LExpr;
      n : INTEGER;

    PROCEDURE Push(Top : LExpr; VAR Stack : LExpr);

    BEGIN Stack := NewApp(Top, Stack)
    END Push;

    PROCEDURE Pop(VAR Top, Stack : LExpr);

    BEGIN Top := Stack(App).Left; Stack := Stack(App).Right;
    END Pop;

    PROCEDURE LookUp(Var, Env : LExpr) : LExpr;

    BEGIN WHILE Var # Env(App).Left DO Env := Env(App).Right(App).Right END;
      RETURN Env(App).Right(App).Left
    END LookUp;

    PROCEDURE Switch(Body, Env : LExpr);

    BEGIN Push(C, D); Push(E, D); Push(S, D); S := NIL; E := Env; C := NIL; Push(Body, C)
    END Switch;

  BEGIN S := NIL; E := NIL; C := NIL; Push(Code, C); D := NIL;
    LOOP
      IF C = NIL THEN
      	IF D = NIL THEN EXIT
      	ELSE Pop(Top, S); Pop(S, D); Pop(E, D); Pop(C, D); Push(Top, S)
      	END
      ELSE Pop(Top, C);
        IF Top = apply THEN Pop(Top, S); Pop(Top1, S);
          IF Top IS Cls THEN Top2 := Top(Cls).Env;
            Push(Top1, Top2); Push(Top(Cls).Abs(Abs).Var, Top2);
            Switch(Top(Cls).Abs(Abs).Body, Top2)
          ELSIF Top IS Con THEN
            IF Top(Con).Fun = y THEN Top2 := NewFix(Top1(Cls).Abs(Abs).Body, Top1(Cls).Env);
              Push(Top2, Top2(Fix).Env); Push(Top1(Cls).Abs(Abs).Var, Top2(Fix).Env);
              IF Top2(Fix).Expr IS Tup THEN Push(Top2, S)
              ELSE Switch(Top2(Fix).Expr, Top2(Fix).Env)
              END
            ELSIF Top(Con).Fun = proj THEN Top2 := Top1(Fix).Expr;
              FOR n := 2 TO Top(Con).Arg DO Top2 := Top2(Tup).Right END;
              Switch(Top2(Tup).Left, Top1(Fix).Env)
            ELSE
              CASE Top(Con).Fun OF
                neg     : Top := NewCon(number, - Top1(Con).Arg)
              | not     : Top := Bool(Top1(Con).Fun # true)
              ELSE Top := NewApp(Top, Top1)
              END;
              Push(Top, S)
            END
          ELSE Top2 := Top1; Top1 := Top(App).Right; Top := Top(App).Left;
            CASE Top(Con).Fun OF
              equal   : Top := Bool(Top1(Con).Arg =  Top2(Con).Arg)
            | equiv   : Top := Bool(Top1(Con).Fun =  Top2(Con).Fun)
            | unequal : Top := Bool(Top1(Con).Arg #  Top2(Con).Arg)
            | unequiv : Top := Bool(Top1(Con).Fun #  Top2(Con).Fun)
            | lss     : Top := Bool(Top1(Con).Arg <  Top2(Con).Arg)
            | lsseq   : Top := Bool(Top1(Con).Arg <= Top2(Con).Arg)
            | grt     : Top := Bool(Top1(Con).Arg >  Top2(Con).Arg)
            | grteq   : Top := Bool(Top1(Con).Arg >= Top2(Con).Arg)
            | plus    : Top := NewCon(number, Top1(Con).Arg  +  Top2(Con).Arg)
            | minus   : Top := NewCon(number, Top1(Con).Arg  -  Top2(Con).Arg)
            | star    : Top := NewCon(number, Top1(Con).Arg  *  Top2(Con).Arg)
            | slash   : Top := NewCon(number, Top1(Con).Arg DIV Top2(Con).Arg)
            | and     : Top := Bool((Top1(Con).Fun = true) &  (Top2(Con).Fun = true))
            | or      : Top := Bool((Top1(Con).Fun = true) OR (Top2(Con).Fun = true))
            END;
            Push(Top, S)
          END
        ELSE
          IF Top IS Con THEN Push(Top, S)
          ELSIF Top IS Var THEN Top := LookUp(Top, E);
            IF ~ (Top IS Fix) OR (Top(Fix).Expr IS Tup) THEN Push(Top, S)
            ELSE Switch(Top(Fix).Expr, Top(Fix).Env)
            END
          ELSIF Top IS App THEN Push(apply, C); Push(Top(App).Left, C); Push(Top(App).Right, C)
          ELSIF Top IS Abs THEN Top := NewCls(Top, E); Push(Top, S)
          ELSIF Top IS Ind THEN Push(Top(Ind).Expr, C)
          ELSIF Top IS Ite THEN Pop(Top1, C); Pop(Top1, S);
            IF Top1(Con).Fun = true THEN Push(Top(Ite).Then, C) ELSE Push(Top(Ite).Else, C) END
          END
        END
      END
    END;
    Pop(Code, S)
  END SECDMachine;

  PROCEDURE Find(Id, Scope : INTEGER; VAR Bind : INTEGER);

  BEGIN Bind := NextBind;
    WHILE Bind > Scope DO DEC(Bind); IF Id = Env[Bind].Id THEN RETURN END END;
    Bind := NextBind
  END Find;

  PROCEDURE EvaluationUnit(Source : Texts.Text; Pos : LONGINT);

    VAR Type : INTEGER; Code : LExpr;

    PROCEDURE ^Expression(VAR Type : INTEGER; VAR Code : LExpr);

    PROCEDURE Signature(Bind : INTEGER);

    (*  Signature = ident ":" TypeTuple "->" SimpleType.
     *)

      PROCEDURE SimpleType(VAR Type : INTEGER);

      (*  SimpleType = "BOOL" | "INT".
       *)

      BEGIN
        IF (Tok = bool) OR (Tok = int) THEN Type := Tok; Get
        ELSE Error("type expected")
        END
      END SimpleType;

      PROCEDURE TypeTuple(VAR Params : INTEGER);

      (*  TypeTuple = [SimpleType {"*" SimpleType}].
       *)

        VAR Type : INTEGER;

      BEGIN
        IF (Tok = bool) OR (Tok = int) THEN Params := NextType;
          LOOP SimpleType(Type);
            IF NextType >= LEN(Tab) - 1 THEN Error("too many parameters") END;
            Tab[NextType] := Type; INC(NextType);
            IF Tok = star THEN Get ELSE EXIT END
          END;
          Tab[NextType] := 0; INC(NextType)
        ELSE Params := nil
        END
      END TypeTuple;

    BEGIN IF Bind # NextBind THEN Error("identifier declared twice") END;
      IF NextBind >= LEN(Env) THEN Error("too many bindings") END; INC(NextBind);
      Env[Bind].Id := Val; Env[Bind].Def := NIL; Get;
      TypeTuple(Env[Bind].Params);
      IF Tok = arrow THEN Get ELSE Error("'->' expected") END;
      SimpleType(Env[Bind].Type)
    END Signature;

    PROCEDURE Definition(Bind : INTEGER);

    (*  Definition = ident FormalParams "=" Expression.
     *)

      VAR Scope, Type : INTEGER; Code : LExpr;

      PROCEDURE FormalParams(Params, Scope : INTEGER);

      (*  FormalParams = ["(" ident {"," ident} ")"].
       *)

        VAR Bind : INTEGER;

      BEGIN
        IF Tok = left THEN Get;
          IF Params = nil THEN Error("definition different from signature") END;
          LOOP
            IF Tab[Params] = 0 THEN Error("definition different from signature") END;
            IF Tok # ident THEN Error("identifier expected") END;
            Find(Val, Scope, Bind); Get;
            IF Bind # NextBind THEN Error("identifier declared twice") END;
            IF NextBind >= LEN(Env) THEN Error("too many bindings") END; INC(NextBind);
            Env[Bind].Id := Val; Env[Bind].Type := Tab[Params];
            Env[Bind].Params := nil; Env[Bind].Ref:= NewVar(); INC(Params);
            IF Tok = comma THEN Get ELSE EXIT END
          END;
          IF Tok = right THEN Get ELSE Error("')' expected") END;
          IF Tab[Params] # 0 THEN Error("definition different from signature") END
        ELSIF Params # nil THEN Error("definition different from signature")
        END
      END FormalParams;

    BEGIN IF Bind = NextBind THEN Error("undeclared identifier") END;
      IF Env[Bind].Def # NIL THEN Error("identifier defined twice") END;
      Scope := NextBind; FormalParams(Env[Bind].Params, Scope);
      IF Tok = equal THEN Get ELSE Error("'=' expected") END;
      Expression(Type, Code);
      IF Type # Env[Bind].Type THEN Error("definition different from signature") END;
      WHILE Scope < NextBind DO DEC(NextBind);
        Code := NewAbs(Env[NextBind].Ref, Code)
      END;
      Env[Bind].Def := Code
    END Definition;

    PROCEDURE Declarations(Scope : INTEGER; VAR Ref, Code : LExpr);

    (*  Declarations = (Signature | Definition) {Signature | Definition}.
     *)

      VAR Bind : INTEGER; Code1 : LExpr;

    BEGIN IF Tok # ident THEN Error("identifier expected") END;
      REPEAT Find(Val, Scope, Bind); Get;
        IF Tok = colon THEN Signature(Bind);
          IF Bind = Scope THEN Ref := NewVar(); Env[Bind].Ref := NewInd(Ref)
          ELSE
            IF Bind = Scope + 1 THEN Env[Scope].Ref(Ind).Expr := NewApp(NewCon(proj, 1), Ref);
            END;
            Env[Bind].Ref := NewApp(NewCon(proj, Bind - Scope + 1), Ref)
          END
        ELSE Definition(Bind)
        END
      UNTIL Tok # ident;
      Code := Env[Scope].Def; IF Code = NIL THEN Error("undefined identifier") END;
      IF NextBind - Scope > 1 THEN Code := NewTup(Code, NIL); Code1 := Code; INC(Scope);
        REPEAT IF Env[Scope].Def = NIL THEN Error("undefined identifier") END;
          Code1(Tup).Right := NewTup(Env[Scope].Def, NIL); Code1 := Code1(Tup).Right; INC(Scope)
        UNTIL Scope = NextBind
      END;
      Code := NewApp(NewCon(y, 0), NewAbs(Ref, Code))
    END Declarations;

    PROCEDURE Expression(VAR Type : INTEGER; VAR Code : LExpr);

    (*  Expression = SimpleExpr [Relation SimpleExpr] | IfExpr | LetExpr.
     *  Relation = "=" | "<>" | "<" | "<=" | ">" | ">=".
     *)

      VAR Type1 : INTEGER; Code1 : LExpr;

      PROCEDURE SimpleExpr(VAR Type : INTEGER; VAR Code : LExpr);

      (*  SimpleExpr = ["+" | "-"] Term {AddOperator Term}.
       *  AddOperator = "+" | "-" | "OR".
       *)

        VAR Neg : BOOLEAN; Type1 : INTEGER; Code1 : LExpr;

        PROCEDURE Term(Neg : BOOLEAN; VAR Type : INTEGER; VAR Code : LExpr);

        (*  Term = Factor {MulOperator Factor}.
         *  MulOperator = "*" | "/" | "AND".
         *)

          VAR Type1 : INTEGER; Code1 : LExpr;

          PROCEDURE Factor(VAR Type : INTEGER; VAR Code : LExpr);

          (*  Factor = number | ident ActualParams | "NOT" Factor | "(" Expression ")".
           *)

            VAR Bind : INTEGER;

            PROCEDURE ActualParams(Params : INTEGER; Code1 : LExpr; VAR Code : LExpr);

            (*  ActualParams = ["(" Expression {"," Expression} ")"].
             *)

              VAR Type : INTEGER;

            BEGIN Code := Code1;
              IF Tok = left THEN Get;
                IF Params = nil THEN Error("use different from signature") END;
                LOOP Expression(Type, Code1); Code := NewApp(Code, Code1);
                  IF Type # Tab[Params] THEN Error("use different from signature") END;
                  INC(Params);
                  IF Tok = comma THEN Get ELSE EXIT END
                END;
                IF Tok = right THEN Get ELSE Error("')' expected") END;
                IF Tab[Params] # 0 THEN Error("use different from signature") END
              ELSIF Params # nil THEN Error("use different from signature")
              END
            END ActualParams;

          BEGIN
            IF Tok = number THEN Type := int; Code := NewCon(number, Val); Get
            ELSIF Tok = ident THEN Find(Val, 0, Bind); Get;
              IF Bind = NextBind THEN Error("undeclared identifier") END;
              Type := Env[Bind].Type;
              ActualParams(Env[Bind].Params, Env[Bind].Ref, Code)
            ELSIF Tok = not THEN Get; Factor(Type, Code);
              IF Type # bool THEN Error("condition expected") END;
              Code := NewApp(NewCon(not, 0), Code)
            ELSIF Tok = left THEN Get; Expression(Type, Code);
              IF Tok = right THEN Get ELSE Error("')' expected") END
            ELSE Error("factor expected")
            END
          END Factor;

        BEGIN Factor(Type, Code);
          IF Neg THEN Code := NewApp(NewCon(neg, 0), Code) END;
          WHILE (Tok = star) OR (Tok = slash) OR (Tok = and) DO
            IF (Type = bool) # (Tok = and) THEN Error("incompatible types") END;
            Code := NewApp(NewCon(Tok, 0), Code); Get;
            Factor(Type1, Code1); Code := NewApp(Code, Code1);
            IF Type # Type1 THEN Error("incompatible types") END
          END
        END Term;

      BEGIN
        IF (Tok = plus) OR (Tok = minus) THEN Neg := Tok = minus; Get;
          Term(Neg, Type, Code); IF Type # int THEN Error("incompatible types") END
        ELSE Term(FALSE, Type, Code)
        END;
        WHILE (Tok = plus) OR (Tok = minus) OR (Tok = or) DO
          IF (Type = bool) # (Tok = or) THEN Error("incompatible types") END;
          Code := NewApp(NewCon(Tok, 0), Code); Get;
          Term(FALSE, Type1, Code1); Code := NewApp(Code, Code1);
          IF Type # Type1 THEN Error("incompatible types") END
        END
      END SimpleExpr;

      PROCEDURE IfExpr(VAR Type : INTEGER; VAR Code : LExpr);

      (*  IfExpr = "IF" Expression "THEN" Expression "ELSE" Expression.
       *)

        VAR Type1 : INTEGER; Code1, Code2 : LExpr;

      BEGIN Get;
        Expression(Type1, Code2); IF Type1 # bool THEN Error("condition expected") END;
        IF Tok = then THEN Get ELSE Error("'THEN' expected") END;
        Expression(Type, Code);
        IF Tok = else THEN Get ELSE Error("'ELSE' expected") END;
        Expression(Type1, Code1); Code := NewApp(NewIte(Code, Code1), Code2);
        IF Type # Type1 THEN Error("incompatible types") END
      END IfExpr;

      PROCEDURE LetExpr(VAR Type : INTEGER; VAR Code : LExpr);

      (*  LetExpr = "LET" Declarations "IN" Expression.
       *)

        VAR Scope : INTEGER; Code1, Ref : LExpr;

      BEGIN Get; Scope := NextBind; Declarations(Scope, Ref, Code1);
        IF Tok = in THEN Get ELSE Error("'IN' expected") END;
        Expression(Type, Code); Code := NewApp(NewAbs(Ref, Code), Code1);
        NextBind := Scope
      END LetExpr;

    BEGIN
      IF Tok = if THEN IfExpr(Type, Code) ELSIF Tok = let THEN LetExpr(Type, Code)
      ELSE SimpleExpr(Type, Code);
        IF (equal <= Tok) & (Tok <= grteq) THEN
          IF Type = bool THEN
            IF (Tok = equal) OR (Tok = unequal) THEN INC(Tok)
            ELSE Error("incompatible types")
            END
          END;
          Code := NewApp(NewCon(Tok, 0), Code); Get;
          SimpleExpr(Type1, Code1); Code := NewApp(Code, Code1);
          IF Type # Type1 THEN Error("incompatible types") END; Type := bool
        END
      END
    END Expression;

  BEGIN Texts.OpenReader(R, Source, Pos);
    Texts.Write(W, 09X); Texts.WriteString(W, "evaluating "); Texts.Append(Oberon.Log, W.buf);
    c := " "; NextCh := 0; NextId := 0; NextType := 0; NextBind := 0;
    Enter("AND"); Enter("BOOL"); Enter("ELSE"); Enter("IF"); Enter("IN");
    Enter("INT"); Enter("LET"); Enter("NOT"); Enter("OR"); Enter("THEN");
    Env[NextBind].Id := NextId; Env[NextBind].Type := bool; Env[NextBind].Params := nil;
    Env[NextBind].Ref := Bool(FALSE); Enter("FALSE"); INC(NextBind);
    Env[NextBind].Id := NextId; Env[NextBind].Type := bool; Env[NextBind].Params := nil;
    Env[NextBind].Ref := Bool(TRUE); Enter("TRUE"); INC(NextBind);
    Get; Expression(Type, Code); IF Tok # eof THEN Error("end of file expected") END;
    SECDMachine(Code); Texts.Write(W, 09X);
    IF Type = int THEN Texts.WriteInt(W, Code(Con).Arg, 6)
    ELSE
      IF Code(Con).Fun = true THEN Texts.WriteString(W, "TRUE")
      ELSE Texts.WriteString(W, "FALSE")
      END
    END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END EvaluationUnit;

  PROCEDURE Eval*;

    VAR S : Texts.Scanner; T : Texts.Text; V : Viewers.Viewer;
      Beg, End, Time : LONGINT;

  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "*") THEN V := Oberon.MarkedViewer();
      IF (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
        EvaluationUnit(V.dsc.next(TextFrames.Frame).text, 0)
      END
    ELSIF (S.class = Texts.Char) & (S.c = "@") THEN Oberon.GetSelection(T, Beg, End, Time);
        IF Time >= 0 THEN EvaluationUnit(T, Beg) END
    ELSE
      IF (S.class = Texts.Char) & (S.c = "^") THEN Oberon.GetSelection(T, Beg, End, Time);
        IF Time >= 0 THEN Texts.OpenScanner(S, T, Beg); Texts.Scan(S) ELSE RETURN END
      END;
      IF S.class = Texts.Name THEN NEW(T); Texts.Open(T, S.s);
        IF T.len # 0 THEN EvaluationUnit(T, 0)
        ELSE Texts.WriteString(W, S.s); Texts.WriteString(W, " not found"); Texts.WriteLn(W);
          Texts.Append(Oberon.Log, W.buf)
        END
      END
    END
  END Eval;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "F Interpreter / MaKro 01.96"); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf); False := NewCon(false, 0); True := NewCon(true, 0)
END F.Eval @
