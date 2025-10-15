module RISC;
import runtime;
import SYSTEM;
import Texts;

Texts.Writer W;
const add = 0;
const sub = 1;
const mul = 2;
const div = 3;
const mod = 4;
const cmp = 5;
const or = 8;
const and = 9;
const bic = 10;
const xor = 11;
const shl = 12;
const sha = 13;
const chk = 14;
const addi = 16;
const subi = 17;
const muli = 18;
const divi = 19;
const modi = 20;
const cmpi = 21;
const ori = 24;
const andi = 25;
const bici = 26;
const xori = 27;
const shli = 28;
const shai = 29;
const chki = 30;
const ldw = 32;
const stw = 33;
const pop = 34;
const psh = 35;
const beq = 40;
const bne = 41;
const blt = 42;
const bge = 43;
const ble = 44;
const bgt = 45;
const bsr = 48;
const ret = 49;
const rd = 56;
const wd = 57;
const wh = 58;
const wl = 59;
long PC;
long IR;
long[32] R;
long[1024] M;
void Execute(long Start, ref Texts.Scanner In, Texts.Text Out)
{
    const lnk = 31;
    long Op;
    long a;
    long b;
    long c;
    long Next;
    R[lnk] = 0;
    PC = Start;
    while (true)
    {
        R[0] = 0;
        Next = PC + 1;
        IR = M[PC];
        Op = MOD(DIV(IR, 67108864), 64);
        a = MOD(DIV(IR, 2097152), 32);
        b = MOD(DIV(IR, 65536), 32);
        c = MOD(IR, 65536);
        if (Op < addi)
        {
            c = R[MOD(c, 32)];
        }
        else if (c >= 32768)
        {
            DEC(c, 65536);
        }
        switch (Op)
        {
        case add:
        case addi:
            R[a] = R[b] + c;
            break;
        case sub:
        case subi:
            R[a] = R[b] - c;
            break;
        case mul:
        case muli:
            R[a] = R[b] * c;
            break;
        case div:
        case divi:
            R[a] = DIV(R[b], c);
            break;
        case mod:
        case modi:
            R[a] = MOD(R[b], c);
            break;
        case cmp:
        case cmpi:
            if (R[b] > c)
            {
                R[a] = 1;
            }
            else if (R[b] < c)
            {
                R[a] = -1;
            }
            else
            {
                R[a] = 0;
            }
            break;
        case or:
        case ori:
            R[a] = SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, R[b]) + SYSTEM.VAL(SET, c));
            break;
        case and:
        case andi:
            R[a] = SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, R[b]) * SYSTEM.VAL(SET, c));
            break;
        case bic:
        case bici:
            R[a] = SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, R[b]) - SYSTEM.VAL(SET, c));
            break;
        case xor:
        case xori:
            R[a] = SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, R[b]) / SYSTEM.VAL(SET, c));
            break;
        case shl:
        case shli:
            R[a] = SYSTEM.LSH(R[b], c);
            break;
        case sha:
        case shai:
            R[a] = ASH(R[b], c);
            break;
        case chk:
        case chki:
            if (R[a] < 0 || c <= R[a])
            {
                Texts.WriteString(W, "  Trap  (PC = ");
                Texts.WriteInt(W, PC, 0);
                Texts.Write(W, ")");
                Texts.WriteLn(W);
                Texts.Append(Out, W.buf);
                break;
            }
            break;
        case ldw:
            R[a] = M[R[b] + c];
            break;
        case stw:
            M[R[b] + c] = R[a];
            break;
        case pop:
            R[a] = M[R[b]];
            INC(R[b], c);
            break;
        case psh:
            DEC(R[b], c);
            M[R[b]] = R[a];
            break;
        case beq:
            if (R[a] == 0)
            {
                Next = PC + c;
            }
            break;
        case bne:
            if (R[a] != 0)
            {
                Next = PC + c;
            }
            break;
        case blt:
            if (R[a] < 0)
            {
                Next = PC + c;
            }
            break;
        case bge:
            if (R[a] >= 0)
            {
                Next = PC + c;
            }
            break;
        case ble:
            if (R[a] <= 0)
            {
                Next = PC + c;
            }
            break;
        case bgt:
            if (R[a] > 0)
            {
                Next = PC + c;
            }
            break;
        case bsr:
            Next = PC + c;
            R[lnk] = PC + 1;
            break;
        case ret:
            Next = R[MOD(c, 32)];
            if (Next == 0)
            {
                break;
            }
            break;
        case rd:
            Texts.Scan(In);
            R[a] = In.i;
            break;
        case wd:
            Texts.Write(W, '\x09');
            Texts.WriteInt(W, R[c], 0);
            break;
        case wh:
            Texts.WriteHex(W, R[c]);
            break;
        case wl:
            Texts.WriteLn(W);
            Texts.Append(Out, W.buf);
            break;
        }
        PC = Next;
    }
}

static this()
{
    Texts.OpenWriter(W);
}
