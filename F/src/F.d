module F;
import runtime;
import Texts;
import Viewers;
import Oberon;
import TextFrames;

const nil = -1;
const equal = 0;
const equiv = 1;
const unequal = 2;
const unequiv = 3;
const lss = 4;
const lsseq = 5;
const grt = 6;
const grteq = 7;
const plus = 8;
const minus = 9;
const star = 10;
const slash = 11;
const neg = 12;
const left = 13;
const right = 14;
const colon = 15;
const arrow = 16;
const comma = 17;
const false = 18;
const true = 19;
const y = 20;
const tuple = 21;
const proj = 22;
const number = 23;
const ident = 24;
const and = 25;
const bool = 26;
const else
     = 27;
const if = 28;
const in  = 29;
const int = 30;
const let = 31;
const not = 32;
const or = 33;
const then = 34;
const eof = 35;
alias LExpr = LExprNode;
class LExprNode
{
}

class Con : LExprNode
{
    int Fun;
    int Arg;
}

class Var : LExprNode
{
    int Id;
}

class App : LExprNode
{
    LExpr Left;
    LExpr Right;
}

class Abs : LExprNode
{
    LExpr Var;
    LExpr Body;
}

class Ind : LExprNode
{
    LExpr Expr;
}

class Ite : LExprNode
{
    LExpr Then;
    LExpr Else;
}

class Tup : LExprNode
{
    LExpr Left;
    LExpr Right;
}

class Cls : LExprNode
{
    LExpr Abs;
    LExpr Env;
}

class Fix : LExprNode
{
    LExpr Expr;
    LExpr Env;
}

class EnvRecord
{
    int Id;
    int Type;
    int Params;
    LExpr Def;
    LExpr Ref;
}

Texts.Reader R;
Texts.Writer W;
char c;
int Tok;
int Val;
LExpr False;
LExpr True;
int NextCh;
int NextId;
int NextType;
int NextBind;
char[1000] Buf;
int[100] Repr;
int[100] Tab;
EnvRecord[100] Env;
void Error(char[] Msg)
{
    Texts.WriteLn(W);
    Texts.WriteInt(W, Texts.Pos(R) - 1, 6);
    Texts.WriteString(W, " : ");
    Texts.WriteString(W, Msg);
    Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf);
    HALT(99);
}

void Enter(char[] s)
{
    int n;
    char c;
    Repr[NextId] = NextCh;
    ++NextId;
    n = 0;
    do
    {
        c = s[n];
        Buf[NextCh] = c;
        ++n;
        ++NextCh;
    }
    while (!(c == '\x00'));
}

void Get()
{
    /**
* number = digit {digit}.
*  digit = "0" | ... | "9".
*/
    void Number()
    {
        int d;
        Tok = number;
        Val = 0;
        do
        {
            d = ORD(c) - ORD("0");
            Texts.Read(R, c);
            if (Val < DIV(int.max, 10) || Val == DIV(int.max, 10) && d <= MOD(int.max, 10))
            {
                Val = Val * 10 + d;
            }
            else
            {
                Error("number out of range");
            }
        }
        while (!(c < "0" || "9" < c));
    }
    /**
* ident = letter {letter | digit}.
*  letter = "a" | ... | "z" | "A" | ... | "Z".
*/
    void Ident()
    {
        int NextCh1;
        int n;
        int m;
        Tok = ident;
        Val = 0;
        NextCh1 = NextCh;
        do
        {
            if (NextCh >= Buf.length - 1)
            {
                Error("identifiers too long");
            }
            Buf[NextCh] = c;
            ++NextCh;
            Texts.Read(R, c);
        }
        while (!(c < "0" || "9" < c && CAP(c) < "A" || "Z" < CAP(c)));
        Buf[NextCh] = " ";
        while (Val < NextId)
        {
            n = NextCh1;
            m = Repr[Val];
            while (Buf[n] == Buf[m])
            {
                ++n;
                ++m;
            }
            if (n == NextCh && Buf[m] == '\x00')
            {
                NextCh = NextCh1;
                if (Val <= then - and)
                {
                    Tok = and + Val;
                }
                return;
            }
            else
            {
                ++Val;
            }
        }
        if (NextId >= Repr.length)
        {
            Error("too many identifiers");
        }
        Repr[NextId] = NextCh1;
        ++NextId;
        Buf[NextCh] = '\x00';
        ++NextCh;
    }

    while (true)
    {
        while (c <= " ")
        {
            if (c != '\x00')
            {
                Texts.Read(R, c);
            }
            else
            {
                Tok = eof;
                return;
            }
        }
        if (c == "!")
        {
            do
            {
                Texts.Read(R, c);
            }
            while (!(c == '\x0d' || c == '\x00'));
        }
        else if (c == "~")
        {
            c = '\x00';
        }
        else
        {
            break;
        }
    }
    switch (c)
    {
    case "(":
        Tok = left;
        break;
    case ")":
        Tok = right;
        break;
    case "*":
        Tok = star;
        break;
    case "+":
        Tok = plus;
        break;
    case ",":
        Tok = comma;
        break;
    case "-":
        Texts.Read(R, c);
        if (c == ">")
        {
            Tok = arrow;
        }
        else
        {
            Tok = minus;
            return;
        }
        break;
    case "/":
        Tok = slash;
        break;
    case "0": .. case "9":
        Number;
        return;
        break;
    case ":":
        Tok = colon;
        break;
    case "<":
        Texts.Read(R, c);
        if (c == "=")
        {
            Tok = lsseq;
        }
        else if (c == ">")
        {
            Tok = unequal;
        }
        else
        {
            Tok = lss;
            return;
        }
        break;
    case "=":
        Tok = equal;
        break;
    case ">":
        Texts.Read(R, c);
        if (c == "=")
        {
            Tok = grteq;
        }
        else
        {
            Tok = grt;
            return;
        }
        break;
    case "A": .. case "Z":
        Ident;
        return;
        break;
    case "a": .. case "z":
        Ident;
        return;
        break;
    default:
        Tok = nil;
        Error("ill char");
    }
    Texts.Read(R, c);
}

LExpr Bool(bool Cond)
{
    if (Cond)
    {
        return True;
    }
    else
    {
        return False;
    }
}

Con NewCon(int Fun, int Arg)
{
    Con Code;
    NEW(Code);
    Code.Fun = Fun;
    Code.Arg = Arg;
    return Code;
}

Var NewVar()
{
    Var Code;
    NEW(Code);
    return Code;
}

App NewApp(LExpr Left, LExpr Right)
{
    App Code;
    NEW(Code);
    Code.Left = Left;
    Code.Right = Right;
    return Code;
}

Abs NewAbs(LExpr Var, LExpr Body)
{
    Abs Code;
    NEW(Code);
    Code.Var = Var;
    Code.Body = Body;
    return Code;
}

Ind NewInd(LExpr Expr)
{
    Ind Code;
    NEW(Code);
    Code.Expr = Expr;
    return Code;
}

Ite NewIte(LExpr Then, LExpr Else)
{
    Ite Code;
    NEW(Code);
    Code.Then = Then;
    Code.Else = Else;
    return Code;
}

Tup NewTup(LExpr Left, LExpr Right)
{
    Tup Code;
    NEW(Code);
    Code.Left = Left;
    Code.Right = Right;
    return Code;
}

Cls NewCls(LExpr Abs, LExpr Env)
{
    Cls Code;
    NEW(Code);
    Code.Abs = Abs;
    Code.Env = Env;
    return Code;
}

Fix NewFix(LExpr Expr, LExpr Env)
{
    Fix Code;
    NEW(Code);
    Code.Expr = Expr;
    Code.Env = Env;
    return Code;
}

void SECDMachine(ref LExpr Code)
{
    const apply = null;
    LExpr S;
    LExpr E;
    LExpr C;
    LExpr D;
    LExpr Top;
    LExpr Top1;
    LExpr Top2;
    int n;
    void Push(LExpr Top, ref LExpr Stack)
    {
        Stack = NewApp(Top, Stack);
    }

    void Pop(ref LExpr Top, ref LExpr Stack)
    {
        Top = Stack(App).Left;
        Stack = Stack(App).Right;
    }

    LExpr LookUp(LExpr Var, LExpr Env)
    {
        while (Var != Env(App).Left)
        {
            Env = Env(App).Right(App).Right;
        }
        return Env(App).Right(App).Left;
    }

    void Switch(LExpr Body, LExpr Env)
    {
        Push(C, D);
        Push(E, D);
        Push(S, D);
        S = null;
        E = Env;
        C = null;
        Push(Body, C);
    }

    S = null;
    E = null;
    C = null;
    Push(Code, C);
    D = null;
    while (true)
    {
        if (C == null)
        {
            if (D == null)
            {
                break;
            }
            else
            {
                Pop(Top, S);
                Pop(S, D);
                Pop(E, D);
                Pop(C, D);
                Push(Top, S);
            }
        }
        else
        {
            Pop(Top, C);
            if (Top == apply)
            {
                Pop(Top, S);
                Pop(Top1, S);
                if (Top is Cls)
                {
                    Top2 = Top(Cls).Env;
                    Push(Top1, Top2);
                    Push(Top(Cls).Abs(Abs).Var, Top2);
                    Switch(Top(Cls).Abs(Abs).Body, Top2);
                }
                else if (Top is Con)
                {
                    if (Top(Con).Fun == y)
                    {
                        Top2 = NewFix(Top1(Cls).Abs(Abs).Body, Top1(Cls).Env);
                        Push(Top2, Top2(Fix).Env);
                        Push(Top1(Cls).Abs(Abs).Var, Top2(Fix).Env);
                        if (Top2(Fix).Expr is Tup)
                        {
                            Push(Top2, S);
                        }
                        else
                        {
                            Switch(Top2(Fix).Expr, Top2(Fix).Env);
                        }
                    }
                    else if (Top(Con).Fun == proj)
                    {
                        Top2 = Top1(Fix).Expr;
                        for (n = 2; n <= Top(Con).Arg; ++n)
                        {
                            Top2 = Top2(Tup).Right;
                        }
                        Switch(Top2(Tup).Left, Top1(Fix).Env);
                    }
                    else
                    {
                        switch (Top(Con).Fun)
                        {
                        case neg:
                            Top = NewCon(number, -Top1(Con).Arg);
                            break;
                        case not:
                            Top = Bool(Top1(Con).Fun != true);
                            break;
                        default:
                            Top = NewApp(Top, Top1);
                        }
                        Push(Top, S);
                    }
                }
                else
                {
                    Top2 = Top1;
                    Top1 = Top(App).Right;
                    Top = Top(App).Left;
                    switch (Top(Con).Fun)
                    {
                    case equal:
                        Top = Bool(Top1(Con).Arg == Top2(Con).Arg);
                        break;
                    case equiv:
                        Top = Bool(Top1(Con).Fun == Top2(Con).Fun);
                        break;
                    case unequal:
                        Top = Bool(Top1(Con).Arg != Top2(Con).Arg);
                        break;
                    case unequiv:
                        Top = Bool(Top1(Con).Fun != Top2(Con).Fun);
                        break;
                    case lss:
                        Top = Bool(Top1(Con).Arg < Top2(Con).Arg);
                        break;
                    case lsseq:
                        Top = Bool(Top1(Con).Arg <= Top2(Con).Arg);
                        break;
                    case grt:
                        Top = Bool(Top1(Con).Arg > Top2(Con).Arg);
                        break;
                    case grteq:
                        Top = Bool(Top1(Con).Arg >= Top2(Con).Arg);
                        break;
                    case plus:
                        Top = NewCon(number, Top1(Con).Arg + Top2(Con).Arg);
                        break;
                    case minus:
                        Top = NewCon(number, Top1(Con).Arg - Top2(Con).Arg);
                        break;
                    case star:
                        Top = NewCon(number, Top1(Con).Arg * Top2(Con).Arg);
                        break;
                    case slash:
                        Top = NewCon(number, DIV(Top1(Con).Arg, Top2(Con).Arg));
                        break;
                    case and:
                        Top = Bool(Top1(Con).Fun == true && Top2(Con).Fun == true);
                        break;
                    case or:
                        Top = Bool(Top1(Con).Fun == true || Top2(Con).Fun == true);
                        break;
                    }
                    Push(Top, S);
                }
            }
            else
            {
                if (Top is Con)
                {
                    Push(Top, S);
                }
                else if (Top is Var)
                {
                    Top = LookUp(Top, E);
                    if (!(Top is Fix) || Top(Fix).Expr is Tup)
                    {
                        Push(Top, S);
                    }
                    else
                    {
                        Switch(Top(Fix).Expr, Top(Fix).Env);
                    }
                }
                else if (Top is App)
                {
                    Push(apply, C);
                    Push(Top(App).Left, C);
                    Push(Top(App).Right, C);
                }
                else if (Top is Abs)
                {
                    Top = NewCls(Top, E);
                    Push(Top, S);
                }
                else if (Top is Ind)
                {
                    Push(Top(Ind).Expr, C);
                }
                else if (Top is Ite)
                {
                    Pop(Top1, C);
                    Pop(Top1, S);
                    if (Top1(Con).Fun == true)
                    {
                        Push(Top(Ite).Then, C);
                    }
                    else
                    {
                        Push(Top(Ite).Else, C);
                    }
                }
            }
        }
    }
    Pop(Code, S);
}

void Find(int Id, int Scope, ref int Bind)
{
    Bind = NextBind;
    while (Bind > Scope)
    {
        --Bind;
        if (Id == Env[Bind].Id)
        {
            return;
        }
    }
    Bind = NextBind;
}

void EvaluationUnit(Texts.Text Source, long Pos)
{
    int Type;
    LExpr Code;
    /**
* Signature = ident ":" TypeTuple "->" SimpleType.
*/
    void Signature(int Bind)
    {
        /**
* SimpleType = "BOOL" | "INT".
*/
        void SimpleType(ref int Type)
        {
            if (Tok == bool || Tok == int)
            {
                Type = Tok;
                Get;
            }
            else
            {
                Error("type expected");
            }
        }
        /**
* TypeTuple = [SimpleType {"*" SimpleType}].
*/
        void TypeTuple(ref int Params)
        {
            int Type;
            if (Tok == bool || Tok == int)
            {
                Params = NextType;
                while (true)
                {
                    SimpleType(Type);
                    if (NextType >= Tab.length - 1)
                    {
                        Error("too many parameters");
                    }
                    Tab[NextType] = Type;
                    ++NextType;
                    if (Tok == star)
                    {
                        Get;
                    }
                    else
                    {
                        break;
                    }
                }
                Tab[NextType] = 0;
                ++NextType;
            }
            else
            {
                Params = nil;
            }
        }
        if (Bind != NextBind)
        {
            Error("identifier declared twice");
        }
        if (NextBind >= Env.length)
        {
            Error("too many bindings");
        }
        ++NextBind;
        Env[Bind].Id = Val;
        Env[Bind].Def = null;
        Get;
        TypeTuple(Env[Bind].Params);
        if (Tok == arrow)
        {
            Get;
        }
        else
        {
            Error("'->' expected");
        }
        SimpleType(Env[Bind].Type);
    }
    /**
* Definition = ident FormalParams "=" Expression.
*/
    void Definition(int Bind)
    {
        int Scope;
        int Type;
        LExpr Code;
        /**
* FormalParams = ["(" ident {"," ident} ")"].
*/
        void FormalParams(int Params, int Scope)
        {
            int Bind;
            if (Tok == left)
            {
                Get;
                if (Params == nil)
                {
                    Error("definition different from signature");
                }
                while (true)
                {
                    if (Tab[Params] == 0)
                    {
                        Error("definition different from signature");
                    }
                    if (Tok != ident)
                    {
                        Error("identifier expected");
                    }
                    Find(Val, Scope, Bind);
                    Get;
                    if (Bind != NextBind)
                    {
                        Error("identifier declared twice");
                    }
                    if (NextBind >= Env.length)
                    {
                        Error("too many bindings");
                    }
                    ++NextBind;
                    Env[Bind].Id = Val;
                    Env[Bind].Type = Tab[Params];
                    Env[Bind].Params = nil;
                    Env[Bind].Ref = NewVar();
                    ++Params;
                    if (Tok == comma)
                    {
                        Get;
                    }
                    else
                    {
                        break;
                    }
                }
                if (Tok == right)
                {
                    Get;
                }
                else
                {
                    Error("')' expected");
                }
                if (Tab[Params] != 0)
                {
                    Error("definition different from signature");
                }
            }
            else if (Params != nil)
            {
                Error("definition different from signature");
            }
        }

        if (Bind == NextBind)
        {
            Error("undeclared identifier");
        }
        if (Env[Bind].Def != null)
        {
            Error("identifier defined twice");
        }
        Scope = NextBind;
        FormalParams(Env[Bind].Params, Scope);
        if (Tok == equal)
        {
            Get;
        }
        else
        {
            Error("'=' expected");
        }
        Expression(Type, Code);
        if (Type != Env[Bind].Type)
        {
            Error("definition different from signature");
        }
        while (Scope < NextBind)
        {
            --NextBind;
            Code = NewAbs(Env[NextBind].Ref, Code);
        }
        Env[Bind].Def = Code;
    }
    /**
* Declarations = (Signature | Definition) {Signature | Definition}.
*/
    void Declarations(int Scope, ref LExpr Ref, ref LExpr Code)
    {
        int Bind;
        LExpr Code1;
        if (Tok != ident)
        {
            Error("identifier expected");
        }
        do
        {
            Find(Val, Scope, Bind);
            Get;
            if (Tok == colon)
            {
                Signature(Bind);
                if (Bind == Scope)
                {
                    Ref = NewVar();
                    Env[Bind].Ref = NewInd(Ref);
                }
                else
                {
                    if (Bind == Scope + 1)
                    {
                        Env[Scope].Ref(Ind).Expr = NewApp(NewCon(proj, 1), Ref);
                    }
                    Env[Bind].Ref = NewApp(NewCon(proj, Bind - Scope + 1), Ref);
                }
            }
            else
            {
                Definition(Bind);
            }
        }
        while (!(Tok != ident));
        Code = Env[Scope].Def;
        if (Code == null)
        {
            Error("undefined identifier");
        }
        if (NextBind - Scope > 1)
        {
            Code = NewTup(Code, null);
            Code1 = Code;
            ++Scope;
            do
            {
                if (Env[Scope].Def == null)
                {
                    Error("undefined identifier");
                }
                Code1(Tup).Right = NewTup(Env[Scope].Def, null);
                Code1 = Code1(Tup).Right;
                ++Scope;
            }
            while (!(Scope == NextBind));
        }
        Code = NewApp(NewCon(y, 0), NewAbs(Ref, Code));
    }
    /**
* Expression = SimpleExpr [Relation SimpleExpr] | IfExpr | LetExpr.
*  Relation = "=" | "<>" | "<" | "<=" | ">" | ">=".
*/
    void Expression(ref int Type, ref LExpr Code)
    {
        int Type1;
        LExpr Code1;
        /**
* SimpleExpr = ["+" | "-"] Term {AddOperator Term}.
*  AddOperator = "+" | "-" | "OR".
*/
        void SimpleExpr(ref int Type, ref LExpr Code)
        {
            bool Neg;
            int Type1;
            LExpr Code1;
            /**
* Term = Factor {MulOperator Factor}.
*  MulOperator = "*" | "/" | "AND".
*/
            void Term(bool Neg, ref int Type, ref LExpr Code)
            {
                int Type1;
                LExpr Code1;
                /**
* Factor = number | ident ActualParams | "NOT" Factor | "(" Expression ")".
*/
                void Factor(ref int Type, ref LExpr Code)
                {
                    int Bind;
                    /**
* ActualParams = ["(" Expression {"," Expression} ")"].
*/
                    void ActualParams(int Params, LExpr Code1, ref LExpr Code)
                    {
                        int Type;
                        Code = Code1;
                        if (Tok == left)
                        {
                            Get;
                            if (Params == nil)
                            {
                                Error("use different from signature");
                            }
                            while (true)
                            {
                                Expression(Type, Code1);
                                Code = NewApp(Code, Code1);
                                if (Type != Tab[Params])
                                {
                                    Error("use different from signature");
                                }
                                ++Params;
                                if (Tok == comma)
                                {
                                    Get;
                                }
                                else
                                {
                                    break;
                                }
                            }
                            if (Tok == right)
                            {
                                Get;
                            }
                            else
                            {
                                Error("')' expected");
                            }
                            if (Tab[Params] != 0)
                            {
                                Error("use different from signature");
                            }
                        }
                        else if (Params != nil)
                        {
                            Error("use different from signature");
                        }
                    }

                    if (Tok == number)
                    {
                        Type = int;
                        Code = NewCon(number, Val);
                        Get;
                    }
                    else if (Tok == ident)
                    {
                        Find(Val, 0, Bind);
                        Get;
                        if (Bind == NextBind)
                        {
                            Error("undeclared identifier");
                        }
                        Type = Env[Bind].Type;
                        ActualParams(Env[Bind].Params, Env[Bind].Ref, Code);
                    }
                    else if (Tok == not)
                    {
                        Get;
                        Factor(Type, Code);
                        if (Type != bool)
                        {
                            Error("condition expected");
                        }
                        Code = NewApp(NewCon(not, 0), Code);
                    }
                    else if (Tok == left)
                    {
                        Get;
                        Expression(Type, Code);
                        if (Tok == right)
                        {
                            Get;
                        }
                        else
                        {
                            Error("')' expected");
                        }
                    }
                    else
                    {
                        Error("factor expected");
                    }
                }
                Factor(Type, Code);
                if (Neg)
                {
                    Code = NewApp(NewCon(neg, 0), Code);
                }
                while (Tok == star || Tok == slash || Tok == and)
                {
                    if (Type == bool != Tok == and)
                    {
                        Error("incompatible types");
                    }
                    Code = NewApp(NewCon(Tok, 0), Code);
                    Get;
                    Factor(Type1, Code1);
                    Code = NewApp(Code, Code1);
                    if (Type != Type1)
                    {
                        Error("incompatible types");
                    }
                }
            }
            if (Tok == plus || Tok == minus)
            {
                Neg = Tok == minus;
                Get;
                Term(Neg, Type, Code);
                if (Type != int)
                {
                    Error("incompatible types");
                }
            }
            else
            {
                Term(false, Type, Code);
            }
            while (Tok == plus || Tok == minus || Tok == or)
            {
                if (Type == bool != Tok == or)
                {
                    Error("incompatible types");
                }
                Code = NewApp(NewCon(Tok, 0), Code);
                Get;
                Term(false, Type1, Code1);
                Code = NewApp(Code, Code1);
                if (Type != Type1)
                {
                    Error("incompatible types");
                }
            }
        }
        /**
* IfExpr = "IF" Expression "THEN" Expression "ELSE" Expression.
*/
        void IfExpr(ref int Type, ref LExpr Code)
        {
            int Type1;
            LExpr Code1;
            LExpr Code2;
            Get;
            Expression(Type1, Code2);
            if (Type1 != bool)
            {
                Error("condition expected");
            }
            if (Tok == then)
            {
                Get;
            }
            else
            {
                Error("'THEN' expected");
            }
            Expression(Type, Code);
            if (Tok == else
                    )
                {
                    Get;
                }
            else
                {
                    Error("'ELSE' expected");
                }

                Expression(Type1, Code1);
                Code = NewApp(NewIte(Code, Code1), Code2);
                if (Type != Type1)
                {
                    Error("incompatible types");
                }
                }
                /**
* LetExpr = "LET" Declarations "IN" Expression.
*/
                void LetExpr(ref int Type, ref LExpr Code)
                {
                    int Scope;
                    LExpr Code1;
                    LExpr Ref;
                    Get;
                    Scope = NextBind;
                    Declarations(Scope, Ref, Code1);
                    if (Tok ==  in )
                    {
                        Get;
                    }
                    else
                    {
                        Error("'IN' expected");
                    }

                    Expression(Type, Code);
                    Code = NewApp(NewAbs(Ref, Code), Code1);
                    NextBind = Scope;
                }
                if (Tok == if)
                {
                    IfExpr(Type, Code);
                }
                else if (Tok == let)
                {
                    LetExpr(Type, Code);
                }
                else
                {
                    SimpleExpr(Type, Code);
                    if (equal <= Tok && Tok <= grteq)
                    {
                        if (Type == bool)
                        {
                            if (Tok == equal || Tok == unequal)
                            {
                                ++Tok;
                            }
                            else
                            {
                                Error("incompatible types");
                            }
                        }
                        Code = NewApp(NewCon(Tok, 0), Code);
                        Get;
                        SimpleExpr(Type1, Code1);
                        Code = NewApp(Code, Code1);
                        if (Type != Type1)
                        {
                            Error("incompatible types");
                        }
                        Type = bool;
                    }
                }
                }
                Texts.OpenReader(R, Source, Pos);
                Texts.Write(W, '\x09');
                Texts.WriteString(W, "evaluating ");
                Texts.Append(Oberon.Log, W.buf);
                c = " ";
                NextCh = 0;
                NextId = 0;
                NextType = 0;
                NextBind = 0;
                Enter("AND");
                Enter("BOOL");
                Enter("ELSE");
                Enter("IF");
                Enter("IN");
                Enter("INT");
                Enter("LET");
                Enter("NOT");
                Enter("OR");
                Enter("THEN");
                Env[NextBind].Id = NextId;
                Env[NextBind].Type = bool;
                Env[NextBind].Params = nil;
                Env[NextBind].Ref = Bool(false);
                Enter("FALSE");
                ++NextBind;
                Env[NextBind].Id = NextId;
                Env[NextBind].Type = bool;
                Env[NextBind].Params = nil;
                Env[NextBind].Ref = Bool(true);
                Enter("TRUE");
                ++NextBind;
                Get;
                Expression(Type, Code);
                if (Tok != eof)
                {
                    Error("end of file expected");
                }
                SECDMachine(Code);
                Texts.Write(W, '\x09');
                if (Type == int)
                {
                    Texts.WriteInt(W, Code(Con).Arg, 6);
                }
                else
                {
                    if (Code(Con).Fun == true)
                    {
                        Texts.WriteString(W, "TRUE");
                    }
                    else
                    {
                        Texts.WriteString(W, "FALSE");
                    }
                }
                Texts.WriteLn(W);
                Texts.Append(Oberon.Log, W.buf);
                }
                void Eval()
                {
                    Texts.Scanner S;
                    Texts.Text T;
                    Viewers.Viewer V;
                    long Beg;
                    long End;
                    long Time;
                    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
                    Texts.Scan(S);
                    if (S.class == Texts.Char && S.c == "*")
                    {
                        V = Oberon.MarkedViewer();
                        if (V.dsc != null && V.dsc.next is TextFrames.Frame)
                        {
                            EvaluationUnit(V.dsc.next(TextFrames.Frame).text, 0);
                        }
                    }
                    else if (S.class == Texts.Char && S.c == "@")
                    {
                        Oberon.GetSelection(T, Beg, End, Time);
                        if (Time >= 0)
                        {
                            EvaluationUnit(T, Beg);
                        }
                    }
                    else
                    {
                        if (S.class == Texts.Char && S.c == "^")
                        {
                            Oberon.GetSelection(T, Beg, End, Time);
                            if (Time >= 0)
                            {
                                Texts.OpenScanner(S, T, Beg);
                                Texts.Scan(S);
                            }
                            else
                            {
                                return;
                            }
                        }
                        if (S.class == Texts.Name)
                        {
                            NEW(T);
                            Texts.Open(T, S.s);
                            if (T.len != 0)
                            {
                                EvaluationUnit(T, 0);
                            }
                            else
                            {
                                Texts.WriteString(W, S.s);
                                Texts.WriteString(W, " not found");
                                Texts.WriteLn(W);
                                Texts.Append(Oberon.Log, W.buf);
                            }
                        }
                    }
                }
                static this()
                {
                    Texts.OpenWriter(W);
                    Texts.WriteString(W, "F Interpreter / MaKro 01.96");
                    Texts.WriteLn(W);
                    Texts.Append(Oberon.Log, W.buf);
                    False = NewCon(false, 0);
                    True = NewCon(true, 0);
                }
