module Asm;
import runtime;
import Display;
import Texts;
import Oberon;
import TextDocs;
import LongInt;
import RISC;

Texts.Reader R;
Texts.Writer W;
char c;
bool Err;
long LastPos;
long Pos;
const id = "A";
const op = "O";
const num = "0";
alias OpenBuf = char[];
class Sym
{
    int Repr;
    bool Def;
    long Val;
}

alias OpenSym = Sym[];
int Id;
int NextCh;
int NextId;
int PCId;
long Num;
OpenBuf Buf;
OpenSym Sym;
void Init()
{
    void New(char[] s, long Val)
    {
        int n;
        n = 0;
        do
        {
            Buf[NextCh] = s[n];
            ++NextCh;
            ++n;
        }
        while (!(s[n] == '\x00'));
        Sym[NextId].Def = true;
        Sym[NextId].Val = Val;
        ++NextId;
        Sym[NextId].Repr = NextCh;
    }

    c = " ";
    Err = false;
    LastPos = -1;
    NextCh = 0;
    NextId = 0;
    Sym[NextId].Repr = NextCh;
    New("ADD", RISC.add);
    New("SUB", RISC.sub);
    New("MUL", RISC.mul);
    New("DIV", RISC.div);
    New("MOD", RISC.mod);
    New("CMP", RISC.cmp);
    New("OR", RISC.or);
    New("AND", RISC.and);
    New("BIC", RISC.bic);
    New("XOR", RISC.xor);
    New("SHL", RISC.shl);
    New("SHA", RISC.sha);
    New("CHK", RISC.chk);
    New("ADDI", RISC.addi);
    New("SUBI", RISC.subi);
    New("MULI", RISC.muli);
    New("DIVI", RISC.divi);
    New("MODI", RISC.modi);
    New("CMPI", RISC.cmpi);
    New("ORI", RISC.ori);
    New("ANDI", RISC.andi);
    New("BICI", RISC.bici);
    New("XORI", RISC.xori);
    New("SHLI", RISC.shli);
    New("SHAI", RISC.shai);
    New("CHKI", RISC.chki);
    New("LDW", RISC.ldw);
    New("STW", RISC.stw);
    New("POP", RISC.pop);
    New("PSH", RISC.psh);
    New("BEQ", RISC.beq);
    New("BNE", RISC.bne);
    New("BLT", RISC.blt);
    New("BGE", RISC.bge);
    New("BLE", RISC.ble);
    New("BGT", RISC.bgt);
    New("BSR", RISC.bsr);
    New("RET", RISC.ret);
    New("RD", RISC.rd);
    New("WD", RISC.wd);
    New("WH", RISC.wh);
    New("WL", RISC.wl);
    PCId = NextId;
    New("PC", 0);
    New("LNK", 31);
}

void Expand()
{
    long n;
    OpenBuf Buf1;
    OpenSym Sym1;
    if (NextCh == Buf.length)
    {
        NEW(Buf1, Buf.length * 2);
        for (n = 0; n <= Buf.length - 1; ++n)
        {
            Buf1[n] = Buf[n];
        }
        Buf = Buf1;
    }
    if (NextId == Sym.length)
    {
        NEW(Sym1, Sym.length * 2);
        for (n = 0; n <= Sym.length - 1; ++n)
        {
            Sym1[n] = Sym[n];
        }
        Sym = Sym1;
    }
}

void WriteString(ref Texts.Writer W, char[] s)
{
    const tab = '\x09';
    const str = '\x22';
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
    for (n = Sym[Id].Repr; n <= Sym[Id + 1].Repr - 1; ++n)
    {
        Texts.Write(W, Buf[n]);
    }
}

void ReportErr(long Pos, char[] Msg)
{
    WriteString(W, "\n\t\t");
    Texts.WriteInt(W, Pos, 0);
    WriteString(W, "\t");
    WriteString(W, Msg);
    Texts.Append(Oberon.Log, W.buf);
}

void Mark(char[] Msg)
{
    Err = true;
    if (Pos > LastPos)
    {
        LastPos = Pos;
        ReportErr(Pos, Msg);
    }
}

void Get(ref char Tok)
{
    const cr = '\x0d';
    /**
* id = (letter | "_") {letter | "_" | digit}.
*  letter = "A" | ... | "Z" | "a" | ... | "z.
*/
    void Ident()
    {
        int m;
        int n;
        Tok = id;
        Id = 0;
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
        while (!(c < "0" || "9" < c && CAP(c) < "A" || "Z" < CAP(c) && c != "_"));
        if (NextCh == Buf.length)
        {
            Expand;
        }
        Buf[NextCh] = '\x00';
        while (Id < NextId)
        {
            m = Sym[Id].Repr;
            n = Sym[NextId].Repr;
            while (Buf[m] == Buf[n])
            {
                ++m;
                ++n;
            }
            if (n == NextCh && m == Sym[Id + 1].Repr)
            {
                NextCh = Sym[NextId].Repr;
                if (Id < PCId)
                {
                    Tok = op;
                }
                return;
            }
            ++Id;
        }
        Sym[NextId].Def = false;
        ++NextId;
        if (NextId == Sym.length)
        {
            Expand;
        }
        Sym[NextId].Repr = NextCh;
    }
    /**
* num = digit {digit}.
*  digit = "0" | ... | "9".
*/
    void Number()
    {
        int d;
        Tok = num;
        Num = 0;
        do
        {
            d = ORD(c) - ORD("0");
            Texts.Read(R, c);
            if (Num < DIV(long.max, 10) || Num == DIV(long.max, 10) && d <= MOD(long.max, 10))
            {
                Num = Num * 10 + d;
            }
            else
            {
                Mark("number out of range");
                Num = 0;
            }
        }
        while (!(c < "0" || "9" < c));
    }

    while (true)
    {
        while (c != '\x00' && c <= " ")
        {
            Texts.Read(R, c);
        }
        if (c == "!")
        {
            do
            {
                Texts.Read(R, c);
            }
            while (!(c == cr || c == '\x00'));
        }
        else
        {
            break;
        }
    }
    Pos = Texts.Pos(R) - 1;
    if ("A" <= CAP(c) && CAP(c) <= "Z" || c == "_")
    {
        Ident;
    }
    else if ("0" <= c && c <= "9")
    {
        Number;
    }
    else if (c == '\x00')
    {
        Tok = '\x00';
    }
    else
    {
        Tok = c;
        Texts.Read(R, c);
    }
}
/**
* Program = {{id ["*"]} (id ["*"] "=" ConstExpression | Statement)}.
*/
void Program()
{
    char Tok;
    int Id1;
    bool Marked;
    class ExprDesc
    {
    }

    alias Expr = ExprDesc;
    class Const : ExprDesc
    {
        long Val;
    }

    class Var : ExprDesc
    {
        int Id;
    }

    class BinOp : ExprDesc
    {
        long Pos;
        char Op;
        Expr Left;
        Expr Right;
    }

    Expr E;
    long Val;
    alias Stmt = StmtDesc;
    class StmtDesc
    {
        long PC;
        long Pos;
        int Op;
        Expr E1;
        Expr E2;
        Expr E3;
        Stmt Next;
    }

    Stmt Patch;
    void NewLabel(int Id, bool Marked, long Val)
    {
        if (Sym[Id].Def && Id != PCId)
        {
            Mark("label defined twice");
        }
        else
        {
            Sym[Id].Def = true;
            Sym[Id].Val = Val;
            if (Marked)
            {
                WriteString(W, "\n\t\t");
                WriteRepr(W, Id);
                WriteString(W, " = ");
                Texts.WriteInt(W, Val, 0);
                Texts.Append(Oberon.Log, W.buf);
            }
        }
    }

    void Emit(long PC, long Pos, int Op, long a, long b, long c)
    {
        bool OK;
        bool IsReg(long x)
        {
            return 0 <= x && x < 32;
        }

        bool IsInt(long x)
        {
            return int.min <= x && x <= int.max;
        }

        if (IsReg(a) && IsReg(b))
        {
            switch (Op)
            {
            case RISC.add: .. case RISC.sha:
                OK = IsReg(c);
                break;
            case RISC.chk:
                OK = b == 0 && IsReg(c);
                break;
            case RISC.addi: .. case RISC.shai:
            case RISC.ldw:
            case RISC.stw:
            case RISC.pop:
            case RISC.psh:
                OK = IsInt(c);
                break;
            case RISC.chki:
            case RISC.beq: .. case RISC.bgt:
                OK = b == 0 && IsInt(c);
                break;
            case RISC.bsr:
            case RISC.ret:
                OK = a == 0 && b == 0 && IsInt(c);
                break;
            case RISC.rd:
                OK = b == 0 && c == 0;
                break;
            case RISC.wd:
            case RISC.wh:
                OK = a == 0 && b == 0 && IsReg(c);
                break;
            case RISC.wl:
                OK = a == 0 && b == 0 && c == 0;
                break;
            }
        }
        else
        {
            OK = false;
            a = MOD(a, 32);
            b = MOD(b, 32);
        }
        if (!OK)
        {
            ReportErr(Pos, "illegal instruction format");
            Err = true;
        }
        if (Op >= 32)
        {
            DEC(Op, 64);
        }
        RISC.M[PC] = ASH(ASH(ASH(Op, 5) + a, 5) + b, 16) + MOD(c, 65536);
    }

    Const NewConst(long Val)
    {
        Const E;
        NEW(E);
        E.Val = Val;
        return E;
    }

    Var NewVar(int Id)
    {
        Var E;
        NEW(E);
        E.Id = Id;
        return E;
    }

    BinOp NewBinOp(long Pos, char Op, Expr Left, Expr Right)
    {
        BinOp E;
        NEW(E);
        E.Pos = Pos;
        E.Op = Op;
        E.Left = Left;
        E.Right = Right;
        return E;
    }

    long Eval(Expr E)
    {
        BinOp E1;
        long Val;
        if (E is Const)
        {
            return E(Const).Val;
        }
        else if (E is Var)
        {
            return Sym[E(Var).Id].Val;
        }
        else
        {
            E1 = E(BinOp);
            if (E1.Op == "+")
            {
                LongInt.Add(Val, Eval(E1.Left), Eval(E1.Right));
            }
            else if (E1.Op == "-")
            {
                LongInt.Sub(Val, Eval(E1.Left), Eval(E1.Right));
            }
            else if (E1.Op == "*")
            {
                LongInt.Mul(Val, Eval(E1.Left), Eval(E1.Right));
            }
            else if (E1.Op == "/")
            {
                LongInt.Div(Val, Eval(E1.Left), Eval(E1.Right));
            }
            else if (E1.Op == "%")
            {
                LongInt.Mod(Val, Eval(E1.Left), Eval(E1.Right));
            }
            if (!LongInt.OK)
            {
                ReportErr(E1.Pos, "value out of range");
                Err = true;
                Val = 1;
            }
            return Val;
        }
    }

    void NewPatch(long PC, long Pos, int Op, Expr E1, Expr E2, Expr E3)
    {
        Stmt Patch1;
        NEW(Patch1);
        Patch1.PC = PC;
        Patch1.Pos = Pos;
        Patch1.Op = Op;
        Patch1.E1 = E1;
        Patch1.E2 = E2;
        Patch1.E3 = E3;
        Patch1.Next = Patch;
        Patch = Patch1;
    }
    /**
* Expression = ["+" | "-"] Term {("+" | "-") Term}.
*/
    void Expression(ref Expr E, ref long Val)
    {
        long Pos1;
        char Op;
        Expr E1;
        long Val1;
        /**
* Term = Factor {("*" | "/" | "%") Factor}.
*/
        void Term(ref Expr E, ref long Val)
        {
            long Pos1;
            char Op;
            Expr E1;
            long Val1;
            /**
* Factor = id | num | "(" Expression ")".
*/
            void Factor(ref Expr E, ref long Val)
            {
                if (Tok == id)
                {
                    if (Sym[Id].Def)
                    {
                        E = null;
                        Val = Sym[Id].Val;
                    }
                    else
                    {
                        E = NewVar(Id);
                    }
                    Get(Tok);
                }
                else if (Tok == num)
                {
                    E = null;
                    Val = Num;
                    Get(Tok);
                }
                else if (Tok == "(")
                {
                    Get(Tok);
                    Expression(E, Val);
                    if (Tok == ")")
                    {
                        Get(Tok);
                    }
                    else
                    {
                        Mark("\')\' expected");
                    }
                }
                else
                {
                    Mark("expression expected");
                    E = null;
                    Val = 1;
                }
            }

            Factor(E, Val);
            while (Tok == "*" || Tok == "/" || Tok == "%")
            {
                Pos1 = Pos;
                Op = Tok;
                Get(Tok);
                Factor(E1, Val1);
                if (E == null && E1 == null)
                {
                    if (Op == "*")
                    {
                        LongInt.Mul(Val, Val, Val1);
                    }
                    else if (Op == "/")
                    {
                        LongInt.Div(Val, Val, Val1);
                    }
                    else
                    {
                        LongInt.Mod(Val, Val, Val1);
                    }
                    if (!LongInt.OK)
                    {
                        ReportErr(Pos1, "value out of range");
                        Err = true;
                        Val = 1;
                    }
                }
                else
                {
                    if (E == null)
                    {
                        E = NewConst(Val);
                    }
                    if (E1 == null)
                    {
                        E1 = NewConst(Val1);
                    }
                    E = NewBinOp(Pos1, Op, E, E1);
                }
            }
        }

        if (Tok == "+" || Tok == "-")
        {
            Pos1 = Pos;
            Op = Tok;
            Get(Tok);
        }
        else
        {
            Op = "+";
        }
        Term(E, Val);
        if (Op == "-")
        {
            if (E == null)
            {
                LongInt.Neg(Val, Val);
                if (!LongInt.OK)
                {
                    ReportErr(Pos1, "value out of range");
                    Err = true;
                    Val = 1;
                }
            }
            else
            {
                E = NewBinOp(Pos1, Op, NewConst(0), E);
            }
        }
        while (Tok == "+" || Tok == "-")
        {
            Pos1 = Pos;
            Op = Tok;
            Get(Tok);
            Term(E1, Val1);
            if (E == null && E1 == null)
            {
                if (Op == "+")
                {
                    LongInt.Add(Val, Val, Val1);
                }
                else
                {
                    LongInt.Sub(Val, Val, Val1);
                }
                if (!LongInt.OK)
                {
                    ReportErr(Pos1, "value out of range");
                    Err = true;
                    Val = 1;
                }
            }
            else
            {
                if (E == null)
                {
                    E = NewConst(Val);
                }
                if (E1 == null)
                {
                    E1 = NewConst(Val1);
                }
                E = NewBinOp(Pos1, Op, E, E1);
            }
        }
    }
    /**
* Statement = op Expression ["," Expression ["," Expression]].
*/
    void Statement()
    {
        long Pos1;
        int Op;
        Expr E1;
        Expr E2;
        Expr E3;
        long Val1;
        long Val2;
        long Val3;
        void Put(int Op, Expr E1, long Val1, Expr E2, long Val2, Expr E3, long Val3)
        {
            long PC;
            PC = Sym[PCId].Val;
            if (PC < 0 || RISC.M.length <= PC)
            {
                ReportErr(Pos1, "PC out of memory");
                Err = true;
                PC = 0;
            }
            if (E1 == null && E2 == null && E3 == null)
            {
                Emit(PC, Pos1, Op, Val1, Val2, Val3);
            }
            else
            {
                if (E1 == null)
                {
                    E1 = NewConst(Val1);
                }
                if (E2 == null)
                {
                    E2 = NewConst(Val2);
                }
                if (E3 == null)
                {
                    E3 = NewConst(Val3);
                }
                NewPatch(PC, Pos1, Op, E1, E2, E3);
            }
            ++PC;
            Sym[PCId].Val = PC;
        }

        if (Tok == op)
        {
            Pos1 = Pos;
            Op = SHORT(Sym[Id].Val);
            Get(Tok);
            Expression(E1, Val1);
            if (Tok == ",")
            {
                Get(Tok);
                Expression(E2, Val2);
                if (Tok == ",")
                {
                    Get(Tok);
                    Expression(E3, Val3);
                    Put(Op, E1, Val1, E2, Val2, E3, Val3);
                }
                else
                {
                    switch (Op)
                    {
                    case RISC.chk:
                    case RISC.chki:
                    case RISC.beq: .. case RISC.bgt:
                        Put(Op, E1, Val1, null, 0, E2, Val2);
                        break;
                    default:
                        ReportErr(Pos1, "illegal instruction format");
                        Err = true;
                    }
                }
            }
            else
            {
                switch (Op)
                {
                case RISC.bsr:
                case RISC.ret:
                case RISC.wd:
                case RISC.wh:
                    Put(Op,
                            null, 0, null, 0, E1, Val1);
                    break;
                case RISC.rd:
                    Put(Op, E1, Val1, null, 0, null, 0);
                    break;
                case RISC.wl:
                    Put(Op, null, 0, null, 0, null, 0);
                    break;
                default:
                    ReportErr(Pos1, "illegal instruction format");
                    Err = true;
                }
            }
        }
        else
        {
            Mark("instruction expected");
            while (Tok != op && Tok != '\x00')
            {
                Get(Tok);
            }
        }
    }

    Get(Tok);
    Patch = null;
    while (Tok != '\x00')
    {
        if (Tok == id)
        {
            Id1 = Id;
            Get(Tok);
            if (Tok == "*")
            {
                Marked = true;
                Get(Tok);
            }
            else
            {
                Marked = false;
            }
            while (Tok == id)
            {
                NewLabel(Id1, Marked, Sym[PCId].Val);
                Id1 = Id;
                Get(Tok);
                if (Tok == "*")
                {
                    Marked = true;
                    Get(Tok);
                }
                else
                {
                    Marked = false;
                }
            }
            if (Tok == "=")
            {
                Get(Tok);
                Expression(E, Val);
                if (E == null)
                {
                    NewLabel(Id1, Marked, Val);
                }
                else
                {
                    Mark("value undefined");
                }
            }
            else
            {
                NewLabel(Id1, Marked, Sym[PCId].Val);
                Statement;
            }
        }
        else
        {
            Statement;
        }
    }
    if (!Err)
    {
        for (Id1 = PCId; Id1 <= NextId - 1; ++Id1)
        {
            if (!Sym[Id1].Def)
            {
                Err = true;
                WriteString(W, "\n\t\t\'");
                WriteRepr(W, Id1);
                WriteString(W, "\' undefined");
                Texts.Append(Oberon.Log, W.buf);
            }
        }
        if (!Err)
        {
            while (Patch != null)
            {
                Emit(Patch.PC, Patch.Pos, Patch.Op, Eval(Patch.E1),
                        Eval(Patch.E2), Eval(Patch.E3));
                Patch = Patch.Next;
            }
        }
    }
}

void Load()
{
    Texts.Scanner S;
    Texts.Text T;
    Display.Frame F;
    long Beg;
    long End;
    long Time;
    void Process(Texts.Text Source, long Pos)
    {
        Texts.OpenReader(R, Source, Pos);
        Init;
        WriteString(W, "\tassembling\t");
        Program;
        Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
    }

    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S);
    if (S.class == Texts.Char)
    {
        if (S.c == "*")
        {
            T = TextDocs.GetText(F);
            if (T != null)
            {
                Process(T, 0);
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
void Exec()
{
    Texts.Scanner S;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S);
    if (S.class == Texts.Int)
    {
        RISC.Execute(S.i, S, Oberon.Log);
    }
}
static this()
{
    Texts.OpenWriter(W);
    NEW(Buf, 2000);
    NEW(Sym, 250);
    WriteString(W, "RISC Assembler / MK 06.96\n");
    Texts.Append(Oberon.Log, W.buf);
}
