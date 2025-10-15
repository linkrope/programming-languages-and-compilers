module Scanner;
import runtime;
import SYSTEM;
import Reals;
import Texts;
import Oberon;

const tab = '\x09';
const cr = '\x0d';
const str = '\x22';
const del = '\x7f';
const eot = 0;
const left = 1;
const right = 2;
const lbrace = 3;
const rbrace = 4;
const lbracket = 5;
const rbracket = 6;
const eq = 7;
const uneq = 8;
const less = 9;
const lesseq = 10;
const greater = 11;
const greatereq = 12;
const and = 13;
const not = 14;
const arrow = 15;
const plus = 16;
const minus = 17;
const star = 18;
const slash = 19;
const bar = 20;
const comma = 21;
const semicolon = 22;
const colon = 23;
const becomes = 24;
const dot = 25;
const dotdot = 26;
const integer = 27;
const real = 28;
const long = 29;
const char = 30;
const string = 31;
const ident = 32;
const illegal = 127;
Texts.Reader R;
Texts.Writer W;
char c;
bool Err;
long LastPos;
long Int;
float Real;
double Long;
char[256] Str;
int Id;
const nil = -1;
class Node
{
    int Repr;
    int Link;
}

int NextCh;
int LenBuf;
int NextId;
int LenTab;
int Reserved;
char[int.max] Buf;
Node[int.max] Tab;
int[97] List;
void Mark(char[] Msg)
{
    long Pos;
    Err = true;
    Pos = Texts.Pos(R) - 1;
    if (Pos >= LastPos + 5)
    {
        LastPos = Pos;
        Texts.WriteLn(W);
        Texts.Write(W, tab);
        Texts.Write(W, tab);
        Texts.WriteInt(W, Pos, 0);
        Texts.WriteString(W, "  ");
        Texts.WriteString(W, Msg);
        Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
        HALT(99);
    }
}

void Expand()
{
    void ReAllocate(ref SYSTEM.PTR a, ref int Len, int Size)
    {
        SYSTEM.PTR a1;
        int Len1;
        if (Len > 0)
        {
            Len1 = Len + DIV(1024, Size);
            SYSTEM.NEW(a1, Len1 * Size);
            SYSTEM.MOVE(SYSTEM.ADR(a), SYSTEM.ADR(a1), Len * Size);
            a = a1;
            Len = Len1;
        }
        else
        {
            Len = DIV(1024 - SIZE(LONGINT), Size);
            SYSTEM.NEW(a, Len * Size);
        }
    }

    if (NextCh == LenBuf)
    {
        ReAllocate(Buf, LenBuf, SIZE(CHAR));
    }
    if (NextId == LenTab)
    {
        ReAllocate(Tab, LenTab, SIZE(Node));
    }
}

void Insert(ref int Id)
{
    int h;
    int k;
    int n;
    int m;
    n = NextCh - Tab[NextId].Repr;
    if (NextCh == LenBuf)
    {
        Expand;
    }
    Buf[NextCh] = '\x00';
    h = ORD(Buf[NextCh - n]);
    k = ORD(Buf[NextCh - 1]);
    h = MOD(((h + k) * 2 - n) * 4 - h, List.length);
    Id = List[h];
    if (Id == nil)
    {
        List[h] = NextId;
    }
    else
    {
        k = Tab[NextId].Repr;
        while (true)
        {
            m = Tab[Id].Repr;
            n = k;
            while (Buf[m] == Buf[n])
            {
                ++m;
                ++n;
            }
            if (n == NextCh && m == Tab[Id + 1].Repr)
            {
                NextCh = k;
                return;
            }
            if (Tab[Id].Link == nil)
            {
                break;
            }
            else
            {
                Id = Tab[Id].Link;
            }
        }
        Tab[Id].Link = NextId;
    }
    Id = NextId;
    Tab[Id].Link = nil;
    ++NextId;
    if (NextId == LenTab)
    {
        Expand;
    }
    Tab[NextId].Repr = NextCh;
}

void New(char[] s)
{
    int h;
    int k;
    int n;
    n = 0;
    do
    {
        Buf[NextCh] = s[n];
        ++NextCh;
        ++n;
    }
    while (!(s[n] == '\x00'));
    h = ORD(s[0]);
    k = ORD(s[n - 1]);
    h = MOD(((h + k) * 2 - n) * 4 - h, List.length);
    Id = List[h];
    if (Id == nil)
    {
        Tab[NextId].Link = nil;
        List[h] = NextId;
    }
    else
    {
        Tab[NextId].Link = Tab[Id].Link;
        Tab[Id].Link = NextId;
    }
    ++NextId;
    Tab[NextId].Repr = NextCh;
}

void Init(Texts.Text Source, long Pos)
{
    int h;
    Texts.OpenReader(R, Source, Pos);
    c = " ";
    Err = false;
    LastPos = -5;
    NextCh = 0;
    LenBuf = 0;
    NextId = 0;
    LenTab = 0;
    Expand;
    Tab[NextId].Repr = NextCh;
    for (h = 0; h <= List.length - 1; ++h)
    {
        List[h] = nil;
    }
    New("ARRAY");
    New("BEGIN");
    New("BY");
    New("CASE");
    New("CONST");
    New("DIV");
    New("DO");
    New("ELSE");
    New("ELSIF");
    New("END");
    New("EXIT");
    New("FOR");
    New("IF");
    New("IMPORT");
    New("IN");
    New("IS");
    New("LOOP");
    New("MOD");
    New("MODULE");
    New("NIL");
    New("OF");
    New("OR");
    New("POINTER");
    New("PROCEDURE");
    New("RECORD");
    New("REPEAT");
    New("RETURN");
    New("THEN");
    New("TO");
    New("TYPE");
    New("UNTIL");
    New("VAR");
    New("WHILE");
    New("WITH");
    Reserved = NextId;
}

void Get(ref int Tok)
{
    void Comment()
    {
        int n;
        char c1;
        n = 1;
        c = " ";
        while (true)
        {
            c1 = c;
            Texts.Read(R, c);
            if (c1 == "(" && c == "*")
            {
                ++n;
                Texts.Read(R, c);
            }
            else if (c1 == "*" && c == ")")
            {
                --n;
                Texts.Read(R, c);
                if (n == 0)
                {
                    break;
                }
            }
            if (c == '\x00')
            {
                Mark("open comment at end of text");
                break;
            }
        }
    }

    void Number()
    {
        int n;
        void IntNumber()
        {
            int d;
            int m;
            Tok = integer;
            Int = 0;
            if ("A" <= c && c <= "F" || c == "H" || c == "X")
            {
                while ("0" <= c && c <= "9" || "A" <= c && c <= "F")
                {
                    if (n < Str.length)
                    {
                        Str[n] = c;
                        ++n;
                    }
                    Texts.Read(R, c);
                }
                if (c == "H" || c == "X")
                {
                    if (c == "X")
                    {
                        Tok = char;
                    }
                    Texts.Read(R, c);
                    if (n > 0)
                    {
                        d = ORD(Str[0]) - ORD("0");
                        if (d > 9)
                        {
                            DEC(d, ORD("A") - ORD("0") - 10);
                        }
                        if (n <= 8 && Tok == integer || n <= 2)
                        {
                            if (n == 8 && d > 7)
                            {
                                Int = d - 16;
                            }
                            else
                            {
                                Int = d;
                            }
                            for (m = 1; m <= n - 1; ++m)
                            {
                                d = ORD(Str[m]) - ORD("0");
                                if (d > 9)
                                {
                                    DEC(d, ORD("A") - ORD("0") - 10);
                                }
                                Int = Int * 16 + d;
                            }
                        }
                        else
                        {
                            Mark("number out of range");
                        }
                    }
                }
                else
                {
                    Mark("illegal character in number");
                }
            }
            else if (n > 0)
            {
                Int = ORD(Str[0]) - ORD("0");
                for (m = 1; m <= n - 1; ++m)
                {
                    d = ORD(Str[m]) - ORD("0");
                    if (Int < DIV(long.max, 10) || Int == DIV(long.max, 10) && d <= MOD(long.max,
                            10))
                    {
                        Int = Int * 10 + d;
                    }
                    else
                    {
                        Mark("number out of range");
                        Int = 0;
                        return;
                    }
                }
            }
        }
        void RealNumber()
        {
            int m;
            int Exp;
            bool Neg;
            Tok = real;
            Real = 0;
            Exp = 0;
            m = n;
            if (m == 0)
            {
                while (c == "0")
                {
                    --m;
                    Texts.Read(R, c);
                }
            }
            while ("0" <= c && c <= "9")
            {
                if (n < Str.length)
                {
                    Str[n] = c;
                    ++n;
                }
                Texts.Read(R, c);
            }
            if (c == "E" || c == "D")
            {
                if (c == "D")
                {
                    Tok = long;
                    Long = 0;
                }
                Texts.Read(R, c);
                Neg = c == "-";
                if (c == "+" || c == "-")
                {
                    Texts.Read(R, c);
                }
                if ("0" <= c && c <= "9")
                {
                    do
                    {
                        if (Exp < 1000)
                        {
                            Exp = Exp * 10 + ORD(c) - ORD("0");
                        }
                        Texts.Read(R, c);
                    }
                    while (!(c < "0" || "9" < c));
                    if (Neg)
                    {
                        Exp = -Exp;
                    }
                }
                else
                {
                    Mark("illegal character in number");
                    return;
                }
            }
            if (m < Str.length)
            {
                INC(Exp, m - 1);
                if (n > 0)
                {
                    if (Tok == real)
                    {
                        do
                        {
                            --n;
                            Real = Real / 10 + ORD(Str[n]) - ORD("0");
                        }
                        while (!(n == 0));
                        if (Exp < 38 || Exp == 38 && Real <= 3.402823)
                        {
                            Real = Real * Reals.Ten(Exp);
                        }
                        else
                        {
                            Mark("number out of range");
                            Real = 0;
                        }
                    }
                    else
                    {
                        do
                        {
                            --n;
                            Long = Long / 10 + ORD(Str[n]) - ORD("0");
                        }
                        while (!(n == 0));
                        if (Exp < 308 || Exp == 308 && Long <= 1.797693)
                        {
                            Long = Long * Reals.TenL(Exp);
                        }
                        else
                        {
                            Mark("number out of range");
                            Long = 0;
                        }
                    }
                }
            }
            else
            {
                Mark("number out of range");
            }
        }
        n = 0;
        while (c == "0")
        {
            Texts.Read(R, c);
        }
        while ("0" <= c && c <= "9")
        {
            if (n < Str.length)
            {
                Str[n] = c;
                ++n;
            }
            Texts.Read(R, c);
        }
        if (c == ".")
        {
            Texts.Read(R, c);
            if (c == ".")
            {
                IntNumber;
                c = del;
            }
            else
            {
                RealNumber;
            }
        }
        else
        {
            IntNumber;
        }
    }
    void String()
    {
        char Term;
        int n;
        Tok = string;
        Term = c;
        n = 0;
        while (true)
        {
            Texts.Read(R, c);
            if (c == Term)
            {
                Texts.Read(R, c);
                break;
            }
            else if (c == '\x00' || c == cr)
            {
                Mark("string terminator not on this line");
                Str[0] = '\x00';
                return;
            }
            else if (n < Str.length)
            {
                Str[n] = c;
                ++n;
            }
        }
        if (n < Str.length)
        {
            Str[n] = '\x00';
        }
        else
        {
            Mark("string too long");
            Str[0] = '\x00';
        }
    }

    void Ident()
    {
        Tok = ident;
        do
        {
            if (NextCh == LenBuf)
            {
                Expand;
            }
            Buf[NextCh] = c;
            ++NextCh;
            Texts.Read(R, c);
        }
        while (!(c < "0" || "9" < c && CAP(c) < "A" || "Z" < CAP(c)));
        Insert(Id);
        if (Id < Reserved)
        {
            INC(Tok, Id + 1);
        }
    }

    while (true)
    {
        while (c <= " ")
        {
            if (c == '\x00')
            {
                Tok = eot;
                return;
            }
            Texts.Read(R, c);
        }
        if (c == "(")
        {
            Texts.Read(R, c);
            if (c == "*")
            {
                Comment;
            }
            else
            {
                Tok = left;
                return;
            }
        }
        else
        {
            break;
        }
    }
    switch (c)
    {
    case str : String;
        return;
        break;
    case "#" : Tok = uneq;
        break;
    case "&" : Tok = and;
        break;
    case ")" : Tok = right;
        break;
    case "*" : Tok = star;
        break;
    case "+" : Tok = plus;
        break;
    case "," : Tok = comma;
        break;
    case "-" : Tok = minus;
        break;
    case "." : Texts.Read(R, c);
        if (c == ".")
        {
            Tok = dotdot;
        }
        else
        {
            Tok = dot;
            return;
        }
        break;
    case "/" : Tok = slash;
        break;
    case "0": .. case "9" : Number;
        return;
        break;
    case ":" : Texts.Read(R, c);
        if (c == "=")
        {
            Tok = becomes;
        }
        else
        {
            Tok = colon;
            return;
        }
        break;
    case ";" : Tok = semicolon;
        break;
    case "<" : Texts.Read(R, c);
        if (c == "=")
        {
            Tok = lesseq;
        }
        else
        {
            Tok = less;
            return;
        }
        break;
    case "=" : Tok = eq;
        break;
    case ">" : Texts.Read(R, c);
        if (c == "=")
        {
            Tok = greatereq;
        }
        else
        {
            Tok = greater;
            return;
        }
        break;
    case "A": .. case "Z" : Ident;
        return;
        break;
    case "[" : Tok = lbracket;
        break;
    case "]" : Tok = rbracket;
        break;
    case "^" : Tok = arrow;
        break;
    case "a": .. case "z" : Ident;
        return;
        break;
    case "{" : Tok = lbrace;
        break;
    case "|" : Tok = bar;
        break;
    case "}" : Tok = rbrace;
        break;
    case "~" : Tok = not;
        break;
    case del : Tok = dotdot;
        break;
    default : Tok = illegal;
    }
    Texts.Read(R, c);
}
static this()
{
    Texts.OpenWriter(W);
}
