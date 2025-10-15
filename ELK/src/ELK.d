module ELK;
import runtime;
import Files;
import Texts;
import Viewers;
import Oberon;
import TextFrames;
import Sets;

Texts.Reader R;
Texts.Reader Fix;
Texts.Writer W;
Texts.Writer Mod;
char c;
bool Err;
long LastPos;
const ide = "A";
const str = '\x22';
int Id;
int NextCh;
int NextId;
int NextTerm;
char[2000] Buf;
int[200] Repr;
const M = 31 + 1;
alias TokSet = uint[DIV(128 - 1, M) + 1];
const nil = -1;
class AltRecord
{
    int Lo;
    int Hi;
    int Rule;
    int Next;
    TokSet Dir;
}

class RuleRecord
{
    int Id;
    int Alt;
    int Edge;
    int State;
    TokSet First;
    TokSet Follow;
}

class EdgeRecord
{
    int Dest;
    int Next;
}

int NextMemb;
int NextAlt;
int NextRule;
int NextDir;
int NextEdge;
int Start;
int[1000] Memb;
AltRecord[500] Alt;
RuleRecord[500] Rule;
int[250] AltDir;
EdgeRecord[1000] Edge;
alias RuleSet = uint[DIV(Rule.length - 1, M) + 1];
RuleSet Null;
void Busy(int Mark)
{
    Viewers.Viewer V;
    V = Oberon.Par.vwr;
    if (V.dsc != null && V.dsc.next is TextFrames.Frame)
    {
        TextFrames.Mark(V.dsc.next(TextFrames.Frame), Mark);
    }
}

void WriteString(ref Texts.Writer W, char[] s)
{
    const tab = '\x09';
    int n;
    char c;
    n = 0;
    c = s[n];
    while (c != '\x00')
    {
        if (c == "\\")
        {
            ++n;
            c = s[n];
            if (c == "n")
            {
                Texts.WriteLn(W);
            }
            else if (c == "t")
            {
                Texts.Write(W, tab);
            }
            else if (c == "'")
            {
                Texts.Write(W, str);
            }
            else
            {
                Texts.Write(W, c);
            }
        }
        else
        {
            Texts.Write(W, c);
        }
        ++n;
        c = s[n];
    }
}

void WriteRepr(ref Texts.Writer W, int Id)
{
    int n;
    for (n = Repr[Id]; n <= Repr[Id + 1] - 1; ++n)
    {
        Texts.Write(W, Buf[n]);
    }
}

void WriteTokSet(ref Texts.Writer W, ref TokSet s)
{
    int n;
    bool Pass;
    Texts.Write(W, "{");
    if (Sets.In(0, s))
    {
        Texts.Write(W, "$");
        Pass = false;
    }
    else
    {
        Pass = true;
    }
    for (n = 1; n <= NextTerm; ++n)
    {
        if (Sets.In(n, s))
        {
            if (Pass)
            {
                Pass = false;
            }
            else
            {
                WriteString(W, ", ");
            }
            WriteRepr(W, n - 1);
        }
    }
    Texts.Write(W, "}");
}

void Info()
{
    void WriteRatio(ref Texts.Writer W, int x, int y)
    {
        Texts.WriteInt(W, x, 0);
        WriteString(W, " / ");
        Texts.WriteInt(W, y, 0);
    }

    WriteString(W, "\n\t\tterminals:\t");
    WriteRatio(W, NextTerm + 1, Alt[0].Dir.length * M - 1);
    WriteString(W, "\n\t\tsymbols:\t");
    WriteRatio(W, NextId, Repr.length);
    WriteString(W, "\t(");
    WriteRatio(W, NextCh, Buf.length);
    Texts.Write(W, ")");
    WriteString(W, "\n\t\talternatives:\t");
    WriteRatio(W, NextAlt, Alt.length);
    WriteString(W, "\t(");
    WriteRatio(W, NextMemb, Memb.length);
    Texts.Write(W, ")");
    WriteString(W, "\n\t\trules:\t");
    WriteRatio(W, NextRule, Rule.length);
    WriteString(W, "\n\t\tdirector sets:\t");
    WriteRatio(W, NextDir, AltDir.length);
    WriteString(W, "\n\t\tpairs:\t");
    WriteRatio(W, NextEdge, Edge.length);
}

void Expand()
{
    Info;
    Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf);
    Busy(1);
    HALT(99);
}

void Mark(char[] Msg)
{
    long Pos;
    Err = true;
    Pos = Texts.Pos(R) - 1;
    if (Pos >= LastPos + 5)
    {
        LastPos = Pos;
        WriteString(W, "\n\t\t");
        Texts.WriteInt(W, Pos, 0);
        WriteString(W, "  ");
        WriteString(W, Msg);
        Texts.Append(Oberon.Log, W.buf);
    }
}

void Code(char Term)
{
    WriteString(Mod, " (* ");
    Texts.WriteInt(Mod, Texts.Pos(R), 0);
    WriteString(Mod, " *) ");
    Texts.Read(R, c);
    while (c != Term)
    {
        if (c == '\x00')
        {
            Mark("open code at end of text");
            return;
        }
        Texts.Write(Mod, c);
        Texts.Read(R, c);
    }
    Texts.Read(R, c);
}

void Params()
{
    while (c <= " ")
    {
        if (c == '\x00')
        {
            return;
        }
        Texts.Read(R, c);
    }
    if (c == "<")
    {
        Texts.Write(Mod, "(");
        Code(">");
        Texts.Write(Mod, ")");
    }
}

void Get(ref char Tok)
{
    int m;
    int n;
    while (true)
    {
        while (c <= " ")
        {
            if (c == '\x00')
            {
                Tok = c;
                return;
            }
            Texts.Read(R, c);
        }
        if (c == "%")
        {
            Code("%");
            Texts.WriteLn(Mod);
        }
        else if (c == "<")
        {
            Code(">");
            Mark("illegal parameter code");
        }
        else
        {
            break;
        }
    }
    if ("A" <= CAP(c) && CAP(c) <= "Z" || c == str)
    {
        Id = 0;
        if (c == str)
        {
            Tok = " ";
            while (true)
            {
                if (NextCh == Buf.length)
                {
                    Expand;
                }
                Buf[NextCh] = c;
                ++NextCh;
                Texts.Read(R, c);
                if (Tok == str)
                {
                    break;
                }
                else
                {
                    Tok = c;
                }
                if (c == '\x00' || c == '\x0d')
                {
                    Mark("string terminator not on this line");
                    Tok = str;
                    NextCh = Repr[NextId];
                    return;
                }
            }
        }
        else
        {
            Tok = ide;
            do
            {
                if (NextCh == Buf.length)
                {
                    Expand;
                }
                Buf[NextCh] = c;
                ++NextCh;
                Texts.Read(R, c);
            }
            while (!(c < "0" || "9" < c && CAP(c) < "A" || "Z" < CAP(c)));
        }
        if (NextCh == Buf.length)
        {
            Expand;
        }
        Buf[NextCh] = '\x00';
        while (Id < NextId)
        {
            m = Repr[Id];
            n = Repr[NextId];
            while (Buf[m] == Buf[n])
            {
                ++m;
                ++n;
            }
            if (n == NextCh && m == Repr[Id + 1])
            {
                NextCh = Repr[NextId];
                return;
            }
            ++Id;
        }
        ++NextId;
        if (NextId == Repr.length)
        {
            Expand;
        }
        Repr[NextId] = NextCh;
    }
    else
    {
        Tok = c;
        Texts.Read(R, c);
    }
}

void NewEdge(int From, int To)
{
    if (NextEdge == Edge.length)
    {
        Expand;
    }
    Edge[NextEdge].Dest = To;
    Edge[NextEdge].Next = Rule[From].Edge;
    Rule[From].Edge = NextEdge;
    ++NextEdge;
}
/**
* Grammar = Term { "," Term } [ ";" Nont { "," Nont } ] "." Definition { Definition } .
*  Term = ( ide | str ) .
*  Nont = ide [ params ] .
*/
void Grammar()
{
    char Tok;
    int NextNont;
    int[Repr.length] Nont;
    void NewMemb(int Sym)
    {
        Alt[NextAlt - 1].Hi = NextMemb;
        if (NextMemb == Memb.length)
        {
            Expand;
        }
        Memb[NextMemb] = Sym;
        ++NextMemb;
    }

    void NewAlt(int LHS)
    {
        if (NextAlt == Alt.length)
        {
            Expand;
        }
        Alt[NextAlt].Lo = NextMemb;
        Alt[NextAlt].Hi = nil;
        Alt[NextAlt].Rule = LHS;
        Alt[NextAlt].Next = Rule[LHS].Alt;
        Rule[LHS].Alt = NextAlt;
        ++NextAlt;
    }

    void NewRule(int Id)
    {
        if (NextRule == Rule.length)
        {
            Expand;
        }
        Rule[NextRule].Id = Id;
        Rule[NextRule].Alt = nil;
        ++NextRule;
    }

    void Include(char Term)
    {
        char c;
        Texts.Read(Fix, c);
        while (c != Term)
        {
            if (c == '\x00')
            {
                WriteString(W, "\n\t\tfatal error in include file");
                Texts.WriteLn(W);
                Texts.Append(Oberon.Log, W.buf);
                Busy(1);
                HALT(99);
            }
            Texts.Write(Mod, c);
            Texts.Read(Fix, c);
        }
    }
    /**
* Definition = Nont "=" Expression "." .
*/
    void Definition()
    {
        int RuleId;
        /**
* Expression =
*    { ( Term | Nont ) }
*    { ( "(" Expression { "|" Expression } ")" | "[" Expression "]" | "{" Expression "}" )
*      { ( Term | Nont ) } } .
*/
        void Expression(int LHS)
        {
            int Cont;
            void InDir()
            {
                if (NextDir == AltDir.length)
                {
                    Expand;
                }
                AltDir[NextDir] = NextAlt - 1;
                Texts.WriteInt(Mod, MOD(NextDir, M), 0);
                WriteString(Mod, " IN Dir[");
                Texts.WriteInt(Mod, DIV(NextDir, M), 0);
                WriteString(Mod, "][Tok]");
                ++NextDir;
            }

            while (true)
            {
                if (Tok == ide || Tok == str)
                {
                    NewAlt(LHS);
                    do
                    {
                        if (Id >= NextNont)
                        {
                            Mark("undefined symbol");
                            NextNont = Id + 1;
                            Nont[Id] = NextRule;
                            NewRule(Id);
                        }
                        if (Tok == ide && Id >= NextTerm)
                        {
                            NewMemb(Nont[Id]);
                            Texts.Write(Mod, "x");
                            WriteRepr(Mod, Id);
                            Params;
                            WriteString(Mod, ";\n");
                        }
                        else
                        {
                            NewMemb(-(Id + 1));
                            WriteString(Mod, "IF Tok = ");
                            Texts.WriteInt(Mod, Id + 1, 0);
                            WriteString(Mod, " (* ");
                            WriteRepr(Mod, Id);
                            WriteString(Mod, " *)");
                            WriteString(Mod, " THEN Scanner.Get(Tok)");
                            WriteString(Mod, " ELSE Scanner.Mark(\'syntax error\') END;\n");
                        }
                        Get(Tok);
                    }
                    while (!(Tok != ide && Tok != str));
                    if (Tok == "(" || Tok == "[" || Tok == "{")
                    {
                        LHS = NextRule;
                        NewMemb(LHS);
                        NewRule(RuleId);
                    }
                    else
                    {
                        break;
                    }
                }
                if (Tok == "(")
                {
                    Cont = NextRule;
                    NewRule(RuleId);
                    do
                    {
                        NewAlt(LHS);
                        NewMemb(NextRule);
                        NewMemb(Cont);
                        NewRule(RuleId);
                        WriteString(Mod, "IF ");
                        InDir;
                        WriteString(Mod, " THEN\n");
                        Get(Tok);
                        Expression(NextRule - 1);
                        WriteString(Mod, "ELS");
                    }
                    while (!(Tok != "|"));
                    WriteString(Mod, "E Scanner.Mark(\'syntax error\')\n");
                    WriteString(Mod, "END (* ALT *);\n");
                    if (Tok == ")")
                    {
                        Get(Tok);
                    }
                    else
                    {
                        Mark("\')\' expected");
                    }
                    LHS = Cont;
                }
                else if (Tok == "[")
                {
                    Cont = NextRule;
                    NewRule(RuleId);
                    NewAlt(LHS);
                    NewMemb(NextRule);
                    NewMemb(Cont);
                    NewRule(RuleId);
                    WriteString(Mod, "IF ");
                    InDir;
                    WriteString(Mod, " THEN\n");
                    Get(Tok);
                    Expression(NextRule - 1);
                    WriteString(Mod, "END (* OPT *);\n");
                    if (Tok == "]")
                    {
                        Get(Tok);
                    }
                    else
                    {
                        Mark("\']\' expected");
                    }
                    NewAlt(LHS);
                    NewMemb(Cont);
                    LHS = Cont;
                }
                else if (Tok == "{")
                {
                    NewAlt(LHS);
                    NewMemb(NextRule);
                    NewMemb(LHS);
                    NewRule(RuleId);
                    WriteString(Mod, "WHILE ");
                    InDir;
                    WriteString(Mod, " DO\n");
                    Get(Tok);
                    Expression(NextRule - 1);
                    WriteString(Mod, "END (* REP *);\n");
                    if (Tok == "}")
                    {
                        Get(Tok);
                    }
                    else
                    {
                        Mark("\'}\' expected");
                    }
                    NewAlt(LHS);
                    LHS = NextRule;
                    NewMemb(LHS);
                    NewRule(RuleId);
                }
                else
                {
                    NewAlt(LHS);
                    break;
                }
            }
        }

        RuleId = Id;
        if (Tok == ide)
        {
            if (Id < NextTerm)
            {
                Mark("nonterminal expected");
            }
            else if (Id >= NextNont)
            {
                NextNont = Id + 1;
                Nont[Id] = NextRule;
                NewRule(Id);
            }
            else if (Rule[Nont[Id]].Alt != nil)
            {
                Mark("nonterminal defined twice");
            }
            WriteString(Mod, "PROCEDURE x");
            WriteRepr(Mod, Id);
            Params;
            WriteString(Mod, ";\n");
            Get(Tok);
        }
        else
        {
            Mark("nonterminal expected");
        }
        if (Tok == "=")
        {
            WriteString(Mod, "BEGIN\n");
            Get(Tok);
        }
        else
        {
            Mark("\'=\' expected");
        }
        while (true)
        {
            Expression(Nont[RuleId]);
            if (Tok == "." || Tok == '\x00' || Tok == "=")
            {
                break;
            }
            else
            {
                Mark("illegal character in expression");
                Get(Tok);
            }
        }
        if (Tok == ".")
        {
            WriteString(Mod, "END x");
            WriteRepr(Mod, RuleId);
            WriteString(Mod, ";\n");
            Get(Tok);
        }
        else
        {
            Mark("\'.\' expected");
        }
    }

    void Analyze()
    {
        int Id;
        int Sym;
        int r;
        int a;
        int m;
        bool Pass;
        int[Alt.length] Deg;
        RuleSet Prod;
        RuleSet Reach;
        int Top;
        int[Rule.length] Stack;
        void TestDeg(int a)
        {
            int r;
            if (Deg[a] == 0)
            {
                r = Alt[a].Rule;
                if (!Sets.In(r, Prod))
                {
                    Sets.Incl(Prod, r);
                    Stack[Top] = r;
                    ++Top;
                }
            }
        }

        void Prune()
        {
            int a;
            int e;
            while (Top > 0)
            {
                --Top;
                e = Rule[Stack[Top]].Edge;
                while (e != nil)
                {
                    a = Edge[e].Dest;
                    --Deg[a];
                    TestDeg(a);
                    e = Edge[e].Next;
                }
            }
        }

        void Traverse(int r)
        {
            int Sym;
            int a;
            int m;
            Sets.Incl(Reach, r);
            a = Rule[r].Alt;
            while (a != nil)
            {
                for (m = Alt[a].Lo; m <= Alt[a].Hi; ++m)
                {
                    Sym = Memb[m];
                    if (Sym >= 0 && !Sets.In(Sym, Reach))
                    {
                        Traverse(Sym);
                    }
                }
                a = Alt[a].Next;
            }
        }

        Top = 0;
        Sets.Empty(Prod);
        Sets.Empty(Reach);
        for (r = 0; r <= NextRule - 1; ++r)
        {
            Rule[r].Edge = nil;
        }
        for (a = 0; a <= NextAlt - 1; ++a)
        {
            Pass = true;
            Deg[a] = 0;
            for (m = Alt[a].Lo; m <= Alt[a].Hi; ++m)
            {
                Sym = Memb[m];
                if (Sym < 0)
                {
                    Pass = false;
                }
                else
                {
                    ++Deg[a];
                    NewEdge(Sym, a);
                }
            }
            if (!Pass)
            {
                INC(Deg[a], int.min);
            }
            else
            {
                TestDeg(a);
            }
        }
        Prune;
        Null = Prod;
        for (a = 0; a <= NextAlt - 1; ++a)
        {
            if (Deg[a] < 0)
            {
                DEC(Deg[a], int.min);
                TestDeg(a);
            }
        }
        Prune;
        Traverse(Start);
        for (Id = NextTerm; Id <= NextNont - 1; ++Id)
        {
            if (!Sets.In(Nont[Id], Prod) || !Sets.In(Nont[Id], Reach))
            {
                WriteString(W, "\n\t\t");
                if (Rule[Nont[Id]].Alt == nil)
                {
                    Err = true;
                    WriteString(W, "undefined nonterminal ");
                }
                else
                {
                    WriteString(W, "useless nonterminal ");
                }
                WriteString(W, "\'");
                WriteRepr(W, Id);
                WriteString(W, "\'");
                Texts.Append(Oberon.Log, W.buf);
            }
        }
    }

    NextCh = 0;
    NextId = 0;
    Repr[NextId] = NextCh;
    Id = Nont.length;
    do
    {
        --Id;
        Nont[Id] = 0;
    }
    while (!(Id == 0));
    Include("%");
    Get(Tok);
    WriteString(Mod, ";\n");
    Include("%");
    while (true)
    {
        if (Tok == ide || Tok == str)
        {
            if (Id >= NextTerm)
            {
                NextTerm = Id + 1;
            }
            else
            {
                Mark("terminal defined twice");
            }
            Get(Tok);
        }
        else
        {
            Mark("symbol expected");
        }
        if (Tok == ",")
        {
            Get(Tok);
        }
        else if (Tok == ";" || Tok == "." || Tok == '\x00')
        {
            break;
        }
        else if (Tok == "=" || Tok == "(" || Tok == "[" || Tok == "{")
        {
            break;
        }
        else
        {
            Mark("\',\' expected");
            if (Tok != ide && Tok != str)
            {
                Get(Tok);
            }
        }
    }
    if (NextTerm + 1 >= Alt[0].Dir.length * M)
    {
        Expand;
    }
    NextNont = NextTerm;
    if (Tok == ";")
    {
        Get(Tok);
        while (true)
        {
            if (Tok == ide)
            {
                if (Id < NextTerm)
                {
                    Mark("nonterminal expected");
                }
                else if (Id >= NextNont)
                {
                    NextNont = Id + 1;
                    Nont[Id] = NextRule;
                    NewRule(Id);
                }
                else
                {
                    Mark("nonterminal defined twice");
                }
                WriteString(Mod, "PROCEDURE ^x");
                WriteRepr(Mod, Id);
                Params;
                WriteString(Mod, ";\n");
                Get(Tok);
            }
            else
            {
                Mark("nonterminal expected");
            }
            if (Tok == ",")
            {
                Get(Tok);
            }
            else if (Tok == "." || Tok == '\x00')
            {
                break;
            }
            else if (Tok == "=" || Tok == "(" || Tok == "[" || Tok == "{")
            {
                break;
            }
            else
            {
                Mark("\',\' expected");
                if (Tok != ide)
                {
                    Get(Tok);
                }
            }
        }
    }
    if (Tok == ".")
    {
        Get(Tok);
    }
    else
    {
        Mark("\'.\' expected");
    }
    if (!Err && Tok == ide)
    {
        Start = Id;
        WriteString(W, "\'");
        WriteRepr(W, Id);
        WriteString(W, "\'");
        Texts.Append(Oberon.Log, W.buf);
    }
    do
    {
        Definition;
    }
    while (!(Tok == '\x00'));
    Include("%");
    Include("$");
    Texts.Write(Mod, "x");
    WriteRepr(Mod, Start);
    Include("%");
    Include('\x00');
    if (!Err)
    {
        Start = Nont[Start];
        Analyze;
    }
}

void ComputeDir()
{
    int Sym;
    int r;
    int a;
    int m;
    TokSet s;
    TokSet u;
    uint[DIV(Alt.length - 1, M) + 1] NullAlts;
    int Top;
    int[Rule.length] Stack;
    void ComputeFirst(int r)
    {
        int Sym;
        int a;
        int m;
        Rule[r].State = 1;
        Sets.Empty(Rule[r].First);
        a = Rule[r].Alt;
        do
        {
            Sets.Empty(Alt[a].Dir);
            m = Alt[a].Lo;
            while (true)
            {
                if (m <= Alt[a].Hi)
                {
                    Sym = Memb[m];
                    ++m;
                }
                else
                {
                    break;
                }
                if (Sym < 0)
                {
                    Sets.Incl(Alt[a].Dir, -Sym);
                    break;
                }
                else
                {
                    if (Rule[Sym].State == 0)
                    {
                        ComputeFirst(Sym);
                    }
                    if (Rule[Sym].State == int.max)
                    {
                        Sets.Union(Alt[a].Dir, Alt[a].Dir, Rule[Sym].First);
                    }
                    else
                    {
                        Err = true;
                        WriteString(W, "\n\t\tleft-recursive nonterminal ");
                        WriteString(W, "\'");
                        WriteRepr(W, Rule[Sym].Id);
                        WriteString(W, "\'");
                        Texts.Append(Oberon.Log, W.buf);
                        Rule[Sym].State = int.max;
                    }
                    if (!Sets.In(Sym, Null))
                    {
                        break;
                    }
                }
            }
            Sets.Union(Rule[r].First, Rule[r].First, Alt[a].Dir);
            a = Alt[a].Next;
        }
        while (!(a == nil));
        Rule[r].State = int.max;
    }

    void ComputeFollow(int r)
    {
        int r1;
        int e;
        int n;
        Stack[Top] = r;
        ++Top;
        n = Top;
        Rule[r].State = n;
        e = Rule[r].Edge;
        while (e != nil)
        {
            r1 = Edge[e].Dest;
            if (Rule[r1].State == 0)
            {
                ComputeFollow(r1);
            }
            if (Rule[r1].State < Rule[r].State)
            {
                Rule[r].State = Rule[r1].State;
            }
            Sets.Union(Rule[r].Follow, Rule[r].Follow, Rule[r1].Follow);
            e = Edge[e].Next;
        }
        if (Rule[r].State == n)
        {
            while (true)
            {
                --Top;
                r1 = Stack[Top];
                Rule[r1].State = int.max;
                if (Top >= n)
                {
                    Rule[r1].Follow = Rule[r].Follow;
                }
                else
                {
                    break;
                }
            }
        }
    }

    Top = 0;
    for (r = 0; r <= NextRule - 1; ++r)
    {
        Rule[r].State = 0;
    }
    for (r = 0; r <= NextRule - 1; ++r)
    {
        if (Rule[r].State == 0)
        {
            ComputeFirst(r);
        }
    }
    if (Err)
    {
        return;
    }
    for (r = 0; r <= NextRule - 1; ++r)
    {
        Rule[r].Edge = nil;
        Sets.Empty(Rule[r].Follow);
    }
    Sets.Incl(Rule[Start].Follow, 0);
    Sets.Empty(NullAlts);
    for (a = 0; a <= NextAlt - 1; ++a)
    {
        Sets.Empty(u);
        m = Alt[a].Hi;
        while (true)
        {
            if (m >= Alt[a].Lo)
            {
                Sym = Memb[m];
                --m;
            }
            else
            {
                Sets.Incl(NullAlts, a);
                break;
            }
            if (Sym < 0)
            {
                Sets.Empty(u);
                Sets.Incl(u, -Sym);
                break;
            }
            else
            {
                NewEdge(Sym, Alt[a].Rule);
                Sets.Union(Rule[Sym].Follow, Rule[Sym].Follow, u);
                if (Sets.In(Sym, Null))
                {
                    Sets.Union(u, u, Rule[Sym].First);
                }
                else
                {
                    u = Rule[Sym].First;
                    break;
                }
            }
        }
        while (m >= Alt[a].Lo)
        {
            Sym = Memb[m];
            --m;
            if (Sym < 0)
            {
                Sets.Empty(u);
                Sets.Incl(u, -Sym);
            }
            else
            {
                Sets.Union(Rule[Sym].Follow, Rule[Sym].Follow, u);
                if (Sets.In(Sym, Null))
                {
                    Sets.Union(u, u, Rule[Sym].First);
                }
                else
                {
                    u = Rule[Sym].First;
                }
            }
        }
    }
    for (r = 0; r <= NextRule - 1; ++r)
    {
        Rule[r].State = 0;
    }
    for (r = 0; r <= NextRule - 1; ++r)
    {
        if (Rule[r].State == 0)
        {
            ComputeFollow(r);
        }
    }
    for (r = 0; r <= NextRule - 1; ++r)
    {
        Sets.Empty(u);
        a = Rule[r].Alt;
        do
        {
            if (Sets.In(a, NullAlts))
            {
                Sets.Union(Alt[a].Dir, Alt[a].Dir, Rule[r].Follow);
            }
            if (!Sets.Disjoint(u, Alt[a].Dir))
            {
                Sets.Intersection(s, u, Alt[a].Dir);
                WriteString(W, "\n\t\tdirector set conflict in ");
                WriteString(W, "\'");
                WriteRepr(W, Rule[r].Id);
                WriteString(W, "\'");
                WriteString(W, "\t");
                WriteTokSet(W, s);
                Texts.Append(Oberon.Log, W.buf);
            }
            Sets.Union(u, u, Alt[a].Dir);
            a = Alt[a].Next;
        }
        while (!(a == nil));
    }
}

void Store(char[] Name)
{
    Files.Rider r;
    int i;
    int j;
    int m;
    int n;
    uint s;
    Files.Set(r, Files.New(Name), 0);
    m = DIV(NextDir - 1, M) + 1;
    n = NextTerm + 1;
    Files.WriteBytes(r, m, SIZE(INTEGER));
    Files.WriteBytes(r, n, SIZE(INTEGER));
    for (i = 0; i <= NextDir - 1; i = i + M)
    {
        if (M <= NextDir - i)
        {
            m = M;
        }
        else
        {
            m = NextDir - i;
        }
        for (n = 0; n <= NextTerm; ++n)
        {
            s = Set;
            for (j = 0; j <= m - 1; ++j)
            {
                if (Sets.In(n, Alt[AltDir[i + j]].Dir))
                {
                    INCL(s, j);
                }
            }
            Files.WriteBytes(r, s, SIZE(SET));
        }
    }
    Files.Register(Files.Base(r));
}

void Generate()
{
    Texts.Scanner S;
    Texts.Text T;
    Viewers.Viewer V;
    long Beg;
    long End;
    long Time;
    void Options(ref bool i)
    {
        i = false;
        while (S.nextCh == " ")
        {
            Texts.Read(S, S.nextCh);
        }
        if (S.nextCh == "/")
        {
            while (true)
            {
                Texts.Read(S, S.nextCh);
                if (S.nextCh == "i")
                {
                    i = true;
                }
                else
                {
                    break;
                }
            }
        }
    }

    void Process(Texts.Text Source, long Pos)
    {
        bool i;
        Options(i);
        Busy(-1);
        Texts.OpenReader(R, Source, Pos);
        c = " ";
        Err = false;
        LastPos = -5;
        NEW(T);
        Texts.Open(T, "Parser.Fix");
        Texts.OpenReader(Fix, T, 0);
        NextMemb = 0;
        NextAlt = 0;
        NextRule = 0;
        NextDir = 0;
        NextEdge = 0;
        NextTerm = 0;
        WriteString(W, "\tgenerating ");
        Texts.Append(Oberon.Log, W.buf);
        Texts.OpenWriter(Mod);
        Grammar;
        if (!Err)
        {
            NextEdge = 0;
            ComputeDir;
            if (!Err)
            {
                T = TextFrames.Text("");
                Texts.Append(T, Mod.buf);
                Texts.Close(T, "Parser.Mod");
                Store("Parser.Tab");
                WriteString(W, "\t");
                Texts.WriteInt(W, NextId - NextTerm, 0);
                WriteString(W, "\t");
                Texts.WriteInt(W, NextDir, 0);
            }
        }
        if (i)
        {
            Info;
        }
        Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
        Busy(1);
    }

    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S);
    if (S.class == Texts.Char)
    {
        if (S.c == "*")
        {
            V = Oberon.MarkedViewer();
            if (V.dsc != null && V.dsc.next is TextFrames.Frame)
            {
                Process(V.dsc.next(TextFrames.Frame).text, 0);
            }
        }
        else if (S.c == "@")
        {
            Oberon.GetSelection(T, Beg, End, Time);
            if (Time >= 0)
            {
                Process(T, Beg);
            }
        }
        else if (S.c == "^")
        {
            Oberon.GetSelection(T, Beg, End, Time);
            if (Time >= 0)
            {
                Texts.OpenScanner(S, T, Beg);
                Texts.Scan(S);
            }
        }
    }
    if (S.class == Texts.Name)
    {
        NEW(T);
        Texts.Open(T, S.s);
        if (T.len != 0)
        {
            Process(T, 0);
        }
        else
        {
            Texts.WriteString(W, S.s);
            WriteString(W, " not found\n");
            Texts.Append(Oberon.Log, W.buf);
        }
    }
}
static this()
{
    Texts.OpenWriter(W);
    WriteString(W, "ELK Parser Generator / MK 03.96\n");
    Texts.Append(Oberon.Log, W.buf);
}
