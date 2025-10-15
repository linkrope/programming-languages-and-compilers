MODULE ELK;  (* MK 03.96 *)

  IMPORT Files, Texts, Viewers, Oberon, TextFrames, Sets;

  VAR R, Fix : Texts.Reader; W, Mod : Texts.Writer; c : CHAR; Err : BOOLEAN; LastPos : LONGINT;

  CONST ide = "A"; str = 22X;

  VAR Id, NextCh, NextId, NextTerm : INTEGER;
    Buf  : ARRAY 2000 OF CHAR;
    Repr : ARRAY  200 OF INTEGER;

  CONST M = MAX(SET) + 1;

  TYPE TokSet  = ARRAY (128 - 1) DIV M + 1 OF SET;

  CONST nil = - 1;

  VAR NextMemb, NextAlt, NextRule, NextDir, NextEdge, Start : INTEGER;
    Memb   : ARRAY 1000 OF INTEGER;
    Alt    : ARRAY  500 OF RECORD
                             Lo, Hi, Rule, Next : INTEGER;
                             Dir                : TokSet
                           END;
    Rule   : ARRAY  500 OF RECORD
                             Id, Alt, Edge, State : INTEGER;
                             First, Follow        : TokSet
                           END;
    AltDir : ARRAY  250 OF INTEGER;
    Edge   : ARRAY 1000 OF RECORD Dest, Next : INTEGER END;

  TYPE RuleSet = ARRAY (LEN(Rule) - 1) DIV M + 1 OF SET;

  VAR Null : RuleSet;

  PROCEDURE Busy(Mark : INTEGER);

    VAR V : Viewers.Viewer;

  BEGIN V := Oberon.Par.vwr;
    IF (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
      TextFrames.Mark(V.dsc.next(TextFrames.Frame), Mark)
    END
  END Busy;

  PROCEDURE WriteString(VAR W : Texts.Writer; s : ARRAY OF CHAR);

    CONST tab = 09X;

    VAR n : INTEGER; c : CHAR;

  BEGIN n := 0; c := s[n];
    WHILE c # 0X DO
      IF c = "\" THEN INC(n); c := s[n];
        IF c = "n" THEN Texts.WriteLn(W)
        ELSIF c = "t" THEN Texts.Write(W, tab)
        ELSIF c = "'" THEN Texts.Write(W, str)
        ELSE Texts.Write(W, c)
        END
      ELSE Texts.Write(W, c)
      END;
      INC(n); c := s[n]
    END
  END WriteString;

  PROCEDURE WriteRepr(VAR W : Texts.Writer; Id : INTEGER);

    VAR n : INTEGER;

  BEGIN FOR n := Repr[Id] TO Repr[Id + 1] - 1 DO Texts.Write(W, Buf[n]) END
  END WriteRepr;

  PROCEDURE WriteTokSet(VAR W : Texts.Writer; VAR s : TokSet);

    VAR n : INTEGER; Pass : BOOLEAN;

  BEGIN
    Texts.Write(W, "{");
    IF Sets.In(0, s) THEN Texts.Write(W, "$"); Pass := FALSE ELSE Pass := TRUE END;
    FOR n := 1 TO NextTerm DO
      IF Sets.In(n, s) THEN IF Pass THEN Pass := FALSE ELSE WriteString(W, ", ") END;
        WriteRepr(W, n - 1)
      END
    END;
    Texts.Write(W, "}")
  END WriteTokSet;

  PROCEDURE Info;

    PROCEDURE WriteRatio(VAR W : Texts.Writer; x, y : INTEGER);

    BEGIN Texts.WriteInt(W, x, 0); WriteString(W, " / "); Texts.WriteInt(W, y, 0)
    END WriteRatio;

  BEGIN
    WriteString(W, "\n\t\tterminals:\t"); WriteRatio(W, NextTerm + 1, LEN(Alt[0].Dir) * M - 1);
    WriteString(W, "\n\t\tsymbols:\t"); WriteRatio(W, NextId, LEN(Repr));
    WriteString(W, "\t("); WriteRatio(W, NextCh, LEN(Buf)); Texts.Write(W, ")");
    WriteString(W, "\n\t\talternatives:\t"); WriteRatio(W, NextAlt, LEN(Alt));
    WriteString(W, "\t("); WriteRatio(W, NextMemb, LEN(Memb)); Texts.Write(W, ")");
    WriteString(W, "\n\t\trules:\t"); WriteRatio(W, NextRule, LEN(Rule));
    WriteString(W, "\n\t\tdirector sets:\t"); WriteRatio(W, NextDir, LEN(AltDir));
    WriteString(W, "\n\t\tpairs:\t"); WriteRatio(W, NextEdge, LEN(Edge))
  END Info;

  PROCEDURE Expand;

  BEGIN Info; Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); Busy(1); HALT(99)
  END Expand;

  PROCEDURE Mark(Msg : ARRAY OF CHAR);

    VAR Pos : LONGINT;

  BEGIN Err := TRUE; Pos := Texts.Pos(R) - 1;
    IF Pos >= LastPos + 5 THEN LastPos := Pos; WriteString(W, "\n\t\t");
      Texts.WriteInt(W, Pos, 0); WriteString(W, "  "); WriteString(W, Msg);
      Texts.Append(Oberon.Log, W.buf)
    END
  END Mark;

  PROCEDURE Code(Term : CHAR);

  BEGIN WriteString(Mod, " (* "); Texts.WriteInt(Mod, Texts.Pos(R), 0); WriteString(Mod, " *) ");
    Texts.Read(R, c);
    WHILE c # Term DO IF c = 0X THEN Mark("open code at end of text"); RETURN END;
      Texts.Write(Mod, c); Texts.Read(R, c)
    END;
    Texts.Read(R, c)
  END Code;

  PROCEDURE Params;

  BEGIN
    WHILE c <= " " DO IF c = 0X THEN RETURN END; Texts.Read(R, c) END;
    IF c = "<" THEN Texts.Write(Mod, "("); Code(">"); Texts.Write(Mod, ")") END
  END Params;

  PROCEDURE Get(VAR Tok : CHAR);

    VAR m, n : INTEGER;

  BEGIN
    LOOP WHILE c <= " " DO IF c = 0X THEN Tok := c; RETURN END; Texts.Read(R, c) END;
      IF c = "%" THEN Code("%"); Texts.WriteLn(Mod)
      ELSIF c = "<" THEN Code(">"); Mark("illegal parameter code")
      ELSE EXIT
      END
    END;
    IF ("A" <= CAP(c)) & (CAP(c) <= "Z") OR (c = str) THEN Id := 0;
      IF c = str THEN Tok := " ";
        LOOP IF NextCh = LEN(Buf) THEN Expand END; Buf[NextCh] := c; INC(NextCh);
          Texts.Read(R, c);
          IF Tok = str THEN EXIT ELSE Tok := c END;
          IF (c = 0X) OR (c = 0DX) THEN Mark("string terminator not on this line");
            Tok := str; NextCh := Repr[NextId]; RETURN
          END
        END
      ELSE Tok := ide;
        REPEAT IF NextCh = LEN(Buf) THEN Expand END; Buf[NextCh] := c; INC(NextCh);
          Texts.Read(R, c)
        UNTIL (c < "0") OR ("9" < c) & (CAP(c) < "A") OR ("Z" < CAP(c))
      END;
      IF NextCh = LEN(Buf) THEN Expand END; Buf[NextCh] := 0X;
      WHILE Id < NextId DO
        m := Repr[Id]; n := Repr[NextId]; WHILE Buf[m] = Buf[n] DO INC(m); INC(n) END;
        IF (n = NextCh) & (m = Repr[Id + 1]) THEN NextCh := Repr[NextId]; RETURN END;
        INC(Id)
      END;
      INC(NextId); IF NextId = LEN(Repr) THEN Expand END; Repr[NextId] := NextCh
    ELSE Tok := c; Texts.Read(R, c)
    END
  END Get;

  PROCEDURE NewEdge(From, To : INTEGER);

  BEGIN IF NextEdge = LEN(Edge) THEN Expand END;
    Edge[NextEdge].Dest := To; Edge[NextEdge].Next := Rule[From].Edge;
    Rule[From].Edge := NextEdge; INC(NextEdge)
  END NewEdge;

  PROCEDURE Grammar;

  (*  Grammar = Term { "," Term } [ ";" Nont { "," Nont } ] "." Definition { Definition } .
   *  Term = ( ide | str ) .
   *  Nont = ide [ params ] .
   *)

    VAR Tok : CHAR;
      NextNont : INTEGER;
      Nont : ARRAY LEN(Repr) OF INTEGER;

    PROCEDURE NewMemb(Sym : INTEGER);

    BEGIN Alt[NextAlt - 1].Hi := NextMemb;
      IF NextMemb = LEN(Memb) THEN Expand END; Memb[NextMemb] := Sym; INC(NextMemb)
    END NewMemb;

    PROCEDURE NewAlt(LHS : INTEGER);

    BEGIN IF NextAlt = LEN(Alt) THEN Expand END;
      Alt[NextAlt].Lo := NextMemb; Alt[NextAlt].Hi := nil; Alt[NextAlt].Rule := LHS;
      Alt[NextAlt].Next := Rule[LHS].Alt; Rule[LHS].Alt := NextAlt; INC(NextAlt)
    END NewAlt;

    PROCEDURE NewRule(Id : INTEGER);

    BEGIN IF NextRule = LEN(Rule) THEN Expand END;
      Rule[NextRule].Id := Id; Rule[NextRule].Alt := nil; INC(NextRule)
    END NewRule;

    PROCEDURE Include(Term : CHAR);

      VAR c : CHAR;

    BEGIN Texts.Read(Fix, c);
      WHILE c # Term DO
        IF c = 0X THEN WriteString(W, "\n\t\tfatal error in include file");
          Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); Busy(1); HALT(99)
        END;
        Texts.Write(Mod, c); Texts.Read(Fix, c)
      END
    END Include;

    PROCEDURE Definition;

    (*  Definition = Nont "=" Expression "." .
     *)

      VAR RuleId : INTEGER;

      PROCEDURE Expression(LHS : INTEGER);

      (*  Expression =
       *    { ( Term | Nont ) }
       *    { ( "(" Expression { "|" Expression } ")" | "[" Expression "]" | "{" Expression "}" )
       *      { ( Term | Nont ) } } .
       *)

        VAR Cont : INTEGER;

        PROCEDURE InDir;

        BEGIN IF NextDir = LEN(AltDir) THEN Expand END; AltDir[NextDir] := NextAlt - 1;
          Texts.WriteInt(Mod, NextDir MOD M, 0); WriteString(Mod, " IN Dir[");
          Texts.WriteInt(Mod, NextDir DIV M, 0); WriteString(Mod, "][Tok]");
          INC(NextDir)
        END InDir;

      BEGIN
        LOOP
          IF (Tok = ide) OR (Tok = str) THEN NewAlt(LHS);
            REPEAT
              IF Id >= NextNont THEN Mark("undefined symbol");
                NextNont := Id + 1; Nont[Id] := NextRule; NewRule(Id)
              END;
              IF (Tok = ide) & (Id >= NextTerm) THEN NewMemb(Nont[Id]);
                Texts.Write(Mod, "x"); WriteRepr(Mod, Id);
                Params; WriteString(Mod, ";\n")
              ELSE NewMemb(- (Id + 1));
                WriteString(Mod, "IF Tok = "); Texts.WriteInt(Mod, Id + 1, 0);
                WriteString(Mod, " (* "); WriteRepr(Mod, Id); WriteString(Mod, " *)");
                WriteString(Mod, " THEN Scanner.Get(Tok)");
                WriteString(Mod, " ELSE Scanner.Mark(\'syntax error\') END;\n")
              END;
              Get(Tok)
            UNTIL (Tok # ide) & (Tok # str);
            IF (Tok ="(") OR (Tok ="[") OR (Tok ="{") THEN
              LHS := NextRule; NewMemb(LHS); NewRule(RuleId)
            ELSE EXIT
            END
          END;
          IF Tok = "(" THEN Cont := NextRule; NewRule(RuleId);
            REPEAT
              NewAlt(LHS); NewMemb(NextRule); NewMemb(Cont); NewRule(RuleId);
              WriteString(Mod, "IF "); InDir; WriteString(Mod, " THEN\n");
              Get(Tok);
              Expression(NextRule - 1);
              WriteString(Mod, "ELS")
            UNTIL Tok # "|";
            WriteString(Mod, "E Scanner.Mark(\'syntax error\')\n");
            WriteString(Mod, "END (* ALT *);\n");
            IF Tok = ")" THEN Get(Tok) ELSE Mark("\')\' expected") END;
            LHS := Cont
          ELSIF Tok = "[" THEN Cont := NextRule; NewRule(RuleId);
            NewAlt(LHS); NewMemb(NextRule); NewMemb(Cont); NewRule(RuleId);
            WriteString(Mod, "IF "); InDir; WriteString(Mod, " THEN\n");
            Get(Tok);
            Expression(NextRule - 1);
            WriteString(Mod, "END (* OPT *);\n");
            IF Tok = "]" THEN Get(Tok) ELSE Mark("\']\' expected") END;
            NewAlt(LHS); NewMemb(Cont); LHS := Cont
          ELSIF Tok = "{" THEN
            NewAlt(LHS); NewMemb(NextRule); NewMemb(LHS); NewRule(RuleId);
            WriteString(Mod, "WHILE "); InDir; WriteString(Mod, " DO\n");
            Get(Tok);
            Expression(NextRule - 1);
            WriteString(Mod, "END (* REP *);\n");
            IF Tok = "}" THEN Get(Tok) ELSE Mark("\'}\' expected") END;
            NewAlt(LHS); LHS := NextRule; NewMemb(LHS); NewRule(RuleId)
          ELSE NewAlt(LHS); EXIT
          END
        END
      END Expression;

    BEGIN RuleId := Id;
      IF Tok = ide THEN
        IF Id < NextTerm THEN Mark("nonterminal expected")
        ELSIF Id >= NextNont THEN NextNont := Id + 1; Nont[Id] := NextRule; NewRule(Id)
        ELSIF Rule[Nont[Id]].Alt # nil THEN Mark("nonterminal defined twice")
        END;
        WriteString(Mod, "PROCEDURE x"); WriteRepr(Mod, Id);
        Params; WriteString(Mod, ";\n");
        Get(Tok)
      ELSE Mark("nonterminal expected")
      END;
      IF Tok = "=" THEN WriteString(Mod, "BEGIN\n");
        Get(Tok)
      ELSE Mark("\'=\' expected")
      END;
      LOOP Expression(Nont[RuleId]);
        IF (Tok = ".") OR (Tok = 0X) OR (Tok = "=") THEN EXIT
        ELSE Mark("illegal character in expression");
          Get(Tok)
        END
      END;
      IF Tok = "." THEN WriteString(Mod, "END x"); WriteRepr(Mod, RuleId); WriteString(Mod, ";\n");
        Get(Tok)
      ELSE Mark("\'.\' expected")
      END
    END Definition;

    PROCEDURE Analyze;

      VAR Id, Sym, r, a, m : INTEGER; Pass : BOOLEAN;
        Deg : ARRAY LEN(Alt) OF INTEGER;
        Prod, Reach : RuleSet;

      VAR Top : INTEGER;
        Stack : ARRAY LEN(Rule) OF INTEGER;

      PROCEDURE TestDeg(a : INTEGER);

        VAR r : INTEGER;

      BEGIN
        IF Deg[a] = 0 THEN r := Alt[a].Rule;
          IF ~ Sets.In(r, Prod) THEN Sets.Incl(Prod, r); Stack[Top] := r; INC(Top) END
        END
      END TestDeg;

      PROCEDURE Prune;

        VAR a, e : INTEGER;

      BEGIN
        WHILE Top > 0 DO DEC(Top); e := Rule[Stack[Top]].Edge;
          WHILE e # nil DO a := Edge[e].Dest; DEC(Deg[a]); TestDeg(a); e := Edge[e].Next END
        END
      END Prune;

      PROCEDURE Traverse(r : INTEGER);

        VAR Sym, a, m : INTEGER;

      BEGIN Sets.Incl(Reach, r);
        a := Rule[r].Alt;
        WHILE a # nil DO
          FOR m := Alt[a].Lo TO Alt[a].Hi DO Sym := Memb[m];
            IF (Sym >= 0) & ~ Sets.In(Sym, Reach) THEN Traverse(Sym) END
          END;
          a := Alt[a].Next
        END
      END Traverse;

    BEGIN Top := 0; Sets.Empty(Prod); Sets.Empty(Reach);
      FOR r := 0 TO NextRule - 1 DO Rule[r].Edge := nil END;
      FOR a := 0 TO NextAlt - 1 DO Pass := TRUE; Deg[a] := 0;
        FOR m := Alt[a].Lo TO Alt[a].Hi DO Sym := Memb[m];
          IF Sym < 0 THEN Pass := FALSE ELSE INC(Deg[a]); NewEdge(Sym, a) END
        END;
        IF ~ Pass THEN INC(Deg[a], MIN(INTEGER)) ELSE TestDeg(a) END
      END;
      Prune; Null := Prod;
      FOR a := 0 TO NextAlt - 1 DO
        IF Deg[a] < 0 THEN DEC(Deg[a], MIN(INTEGER)); TestDeg(a) END
      END;
      Prune;
      Traverse(Start);
      FOR Id := NextTerm TO NextNont - 1 DO
        IF ~ Sets.In(Nont[Id], Prod) OR ~ Sets.In(Nont[Id], Reach) THEN WriteString(W, "\n\t\t");
          IF Rule[Nont[Id]].Alt = nil THEN Err := TRUE;
            WriteString(W, "undefined nonterminal ")
          ELSE WriteString(W, "useless nonterminal ")
          END;
          WriteString(W, "\'"); WriteRepr(W, Id); WriteString(W, "\'");
          Texts.Append(Oberon.Log, W.buf)
        END
      END
    END Analyze;

  BEGIN NextCh := 0; NextId := 0; Repr[NextId] := NextCh;
    Id := LEN(Nont); REPEAT DEC(Id); Nont[Id] := 0 UNTIL Id = 0;
    Include("%"); Get(Tok); WriteString(Mod, ";\n"); Include("%");
    LOOP
      IF (Tok = ide) OR (Tok = str) THEN
        IF Id >= NextTerm THEN NextTerm := Id + 1 ELSE Mark("terminal defined twice") END;
        Get(Tok)
      ELSE Mark("symbol expected")
      END;
      IF Tok = "," THEN Get(Tok)
      ELSIF (Tok = ";") OR (Tok = ".") OR (Tok = 0X) THEN EXIT
      ELSIF (Tok = "=") OR (Tok = "(") OR (Tok = "[") OR (Tok = "{") THEN EXIT
      ELSE Mark("\',\' expected");
        IF (Tok # ide) & (Tok # str) THEN Get(Tok) END
      END
    END;
    IF NextTerm + 1 >= LEN(Alt[0].Dir) * M THEN Expand END; NextNont := NextTerm;
    IF Tok = ";" THEN Get(Tok);
      LOOP
        IF Tok = ide THEN
          IF Id < NextTerm THEN Mark("nonterminal expected")
          ELSIF Id >= NextNont THEN NextNont := Id + 1; Nont[Id] := NextRule; NewRule(Id)
          ELSE Mark("nonterminal defined twice")
          END;
          WriteString(Mod, "PROCEDURE ^x"); WriteRepr(Mod, Id);
          Params; WriteString(Mod, ";\n");
          Get(Tok)
        ELSE Mark("nonterminal expected")
        END;
        IF Tok = "," THEN Get(Tok)
        ELSIF (Tok = ".") OR (Tok = 0X) THEN EXIT
        ELSIF (Tok = "=") OR (Tok = "(") OR (Tok = "[") OR (Tok = "{") THEN EXIT
        ELSE Mark("\',\' expected");
          IF Tok # ide THEN Get(Tok) END
        END
      END
    END;
    IF Tok = "." THEN Get(Tok) ELSE Mark("\'.\' expected") END;
    IF ~ Err & (Tok = ide) THEN Start := Id;
      WriteString(W, "\'"); WriteRepr(W, Id); WriteString(W, "\'");
      Texts.Append(Oberon.Log, W.buf)
    END;
    REPEAT Definition UNTIL Tok = 0X;
    Include("%");
    Include("$"); Texts.Write(Mod, "x"); WriteRepr(Mod, Start); Include("%");
    Include(0X);
    IF ~ Err THEN Start := Nont[Start]; Analyze END
  END Grammar;

  PROCEDURE ComputeDir;

    VAR Sym, r, a, m : INTEGER;
      s, u : TokSet;
      NullAlts : ARRAY (LEN(Alt) -1) DIV M + 1 OF SET;


    VAR Top : INTEGER;
      Stack : ARRAY LEN(Rule) OF INTEGER;

    PROCEDURE ComputeFirst(r : INTEGER);

      VAR Sym, a, m : INTEGER;

    BEGIN Rule[r].State := 1; Sets.Empty(Rule[r].First);
      a := Rule[r].Alt;
      REPEAT Sets.Empty(Alt[a].Dir);
        m := Alt[a].Lo;
        LOOP IF m <= Alt[a].Hi THEN Sym := Memb[m]; INC(m) ELSE EXIT END;
          IF Sym < 0 THEN Sets.Incl(Alt[a].Dir, - Sym); EXIT
          ELSE
            IF Rule[Sym].State = 0 THEN ComputeFirst(Sym) END;
            IF Rule[Sym].State = MAX(INTEGER) THEN
              Sets.Union(Alt[a].Dir, Alt[a].Dir, Rule[Sym].First)
            ELSE Err := TRUE;
              WriteString(W, "\n\t\tleft-recursive nonterminal ");
              WriteString(W, "\'"); WriteRepr(W, Rule[Sym].Id); WriteString(W, "\'");
              Texts.Append(Oberon.Log, W.buf);
              Rule[Sym].State := MAX(INTEGER)
            END;
            IF ~ Sets.In(Sym, Null) THEN EXIT END
          END
        END;
        Sets.Union(Rule[r].First, Rule[r].First, Alt[a].Dir);
        a := Alt[a].Next
      UNTIL a = nil;
      Rule[r].State := MAX(INTEGER)
    END ComputeFirst;

    PROCEDURE ComputeFollow(r : INTEGER);

      VAR r1, e, n : INTEGER;

    BEGIN Stack[Top] := r; INC(Top); n := Top; Rule[r].State := n;
      e := Rule[r].Edge;
      WHILE e # nil DO r1 := Edge[e].Dest;
        IF Rule[r1].State = 0 THEN ComputeFollow(r1) END;
        IF Rule[r1].State < Rule[r].State THEN Rule[r].State := Rule[r1].State END;
        Sets.Union(Rule[r].Follow, Rule[r].Follow, Rule[r1].Follow);
        e := Edge[e].Next
      END;
      IF Rule[r].State = n THEN
        LOOP DEC(Top); r1 := Stack[Top]; Rule[r1].State := MAX(INTEGER);
          IF Top >= n THEN Rule[r1].Follow := Rule[r].Follow ELSE EXIT END
        END
      END
    END ComputeFollow;

  BEGIN Top := 0;
    FOR r := 0 TO NextRule - 1 DO Rule[r].State := 0 END;
    FOR r := 0 TO NextRule - 1 DO IF Rule[r].State = 0 THEN ComputeFirst(r) END END;
    IF Err THEN RETURN END;
    FOR r := 0 TO NextRule - 1 DO Rule[r].Edge := nil; Sets.Empty(Rule[r].Follow) END;
    Sets.Incl(Rule[Start].Follow, 0); Sets.Empty(NullAlts);
    FOR a := 0 TO NextAlt - 1 DO Sets.Empty(u);
      m := Alt[a].Hi;
      LOOP IF m >= Alt[a].Lo THEN Sym := Memb[m]; DEC(m) ELSE Sets.Incl(NullAlts, a); EXIT END;
        IF Sym < 0 THEN Sets.Empty(u); Sets.Incl(u, - Sym); EXIT
        ELSE NewEdge(Sym, Alt[a].Rule);
          Sets.Union(Rule[Sym].Follow, Rule[Sym].Follow, u);
          IF Sets.In(Sym, Null) THEN Sets.Union(u, u, Rule[Sym].First)
          ELSE u := Rule[Sym].First; EXIT
          END
        END
      END;
      WHILE m >= Alt[a].Lo DO Sym := Memb[m]; DEC(m);
        IF Sym < 0 THEN Sets.Empty(u); Sets.Incl(u, - Sym)
        ELSE
          Sets.Union(Rule[Sym].Follow, Rule[Sym].Follow, u);
          IF Sets.In(Sym, Null) THEN Sets.Union(u, u, Rule[Sym].First)
          ELSE u := Rule[Sym].First
          END
        END
      END
    END;
    FOR r := 0 TO NextRule - 1 DO Rule[r].State := 0 END;
    FOR r := 0 TO NextRule - 1 DO IF Rule[r].State = 0 THEN ComputeFollow(r) END END;
    FOR r := 0 TO NextRule - 1 DO Sets.Empty(u);
      a := Rule[r].Alt;
      REPEAT
        IF Sets.In(a, NullAlts) THEN Sets.Union(Alt[a].Dir, Alt[a].Dir, Rule[r].Follow) END;
        IF ~ Sets.Disjoint(u, Alt[a].Dir) THEN Sets.Intersection(s, u, Alt[a].Dir);
          WriteString(W, "\n\t\tdirector set conflict in ");
          WriteString(W, "\'"); WriteRepr(W, Rule[r].Id); WriteString(W, "\'");
          WriteString(W, "\t"); WriteTokSet(W, s); Texts.Append(Oberon.Log, W.buf)
        END;
        Sets.Union(u, u, Alt[a].Dir);
        a := Alt[a].Next
      UNTIL a = nil
    END
  END ComputeDir;

  PROCEDURE Store(Name : ARRAY OF CHAR);

    VAR r : Files.Rider;
      i, j, m, n : INTEGER;
      s : SET;

  BEGIN Files.Set(r, Files.New(Name), 0);
    m := (NextDir - 1) DIV M + 1; n := NextTerm + 1;
    Files.WriteBytes(r, m, SIZE(INTEGER)); Files.WriteBytes(r, n, SIZE(INTEGER));
    FOR i := 0 TO NextDir - 1 BY M DO
      IF M <= NextDir - i THEN m := M ELSE m := NextDir - i END;
      FOR n := 0 TO NextTerm DO s := {};
        FOR j := 0 TO m - 1 DO
          IF Sets.In(n, Alt[AltDir[i + j]].Dir) THEN INCL(s, j) END
        END;
        Files.WriteBytes(r, s, SIZE(SET))
      END
    END;
    Files.Register(Files.Base(r))
  END Store;

  PROCEDURE Generate*;

    VAR S : Texts.Scanner; T : Texts.Text; V : Viewers.Viewer;
      Beg, End, Time : LONGINT;

    PROCEDURE Options(VAR i : BOOLEAN);

    BEGIN i := FALSE;
      WHILE S.nextCh = " " DO Texts.Read(S, S.nextCh) END;
      IF S.nextCh = "/" THEN
        LOOP Texts.Read(S, S.nextCh);
          IF S.nextCh = "i" THEN i := TRUE ELSE EXIT END
        END
      END
    END Options;

    PROCEDURE Process(Source : Texts.Text; Pos : LONGINT);

      VAR i : BOOLEAN;

    BEGIN Options(i); Busy(- 1);
      Texts.OpenReader(R, Source, Pos); c := " "; Err := FALSE; LastPos := - 5;
      NEW(T); Texts.Open(T, "Parser.Fix"); Texts.OpenReader(Fix, T, 0);
      NextMemb := 0; NextAlt := 0; NextRule := 0; NextDir := 0; NextEdge := 0; NextTerm := 0;
      WriteString(W, "\tgenerating "); Texts.Append(Oberon.Log, W.buf); Texts.OpenWriter(Mod);
      Grammar;
      IF ~ Err THEN NextEdge := 0; ComputeDir;
        IF ~ Err THEN
          T := TextFrames.Text(""); Texts.Append(T, Mod.buf); Texts.Close(T, "Parser.Mod");
          Store("Parser.Tab");
          WriteString(W, "\t"); Texts.WriteInt(W, NextId - NextTerm, 0);
          WriteString(W, "\t"); Texts.WriteInt(W, NextDir, 0)
        END
      END;
      IF i THEN Info END;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); Busy(1)
    END Process;

  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Char THEN
      IF S.c = "*" THEN V := Oberon.MarkedViewer();
        IF (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
          Process(V.dsc.next(TextFrames.Frame).text, 0)
        END
      ELSIF S.c = "@" THEN Oberon.GetSelection(T, Beg, End, Time);
        IF Time >= 0 THEN Process(T, Beg) END
      ELSIF S.c = "^" THEN Oberon.GetSelection(T, Beg, End, Time);
        IF Time >= 0 THEN Texts.OpenScanner(S, T, Beg); Texts.Scan(S) END
      END
    END;
    IF S.class = Texts.Name THEN NEW(T); Texts.Open(T, S.s);
      IF T.len # 0 THEN Process(T, 0)
      ELSE
        Texts.WriteString(W, S.s); WriteString(W, " not found\n"); Texts.Append(Oberon.Log, W.buf)
      END
    END
  END Generate;

BEGIN Texts.OpenWriter(W);
  WriteString(W, "ELK Parser Generator / MK 03.96\n"); Texts.Append(Oberon.Log, W.buf)
END ELK.Generate *
