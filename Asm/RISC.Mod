MODULE RISC;

  IMPORT SYSTEM, Texts;

  VAR W: Texts.Writer;

  CONST
    add*  =  0; sub*  =  1; mul*  =  2; div*  =  3; mod*  =  4; cmp*  =  5;
    or*   =  8; and*  =  9; bic*  = 10; xor*  = 11; shl*  = 12; sha*  = 13; chk*  = 14;
    addi* = 16; subi* = 17; muli* = 18; divi* = 19; modi* = 20; cmpi* = 21;
    ori*  = 24; andi* = 25; bici* = 26; xori* = 27; shli* = 28; shai* = 29; chki* = 30;
    ldw*  = 32; stw*  = 33; pop*  = 34; psh*  = 35;
    beq*  = 40; bne*  = 41; blt*  = 42; bge*  = 43; ble*  = 44; bgt*  = 45;
    bsr*  = 48; ret*  = 49;
    rd*   = 56; wd*   = 57; wh*   = 58; wl*   = 59;

  VAR PC, IR: LONGINT;
    R*: ARRAY 32 OF LONGINT;
    M*: ARRAY 1024 OF LONGINT;

  PROCEDURE Execute*(Start: LONGINT; VAR In: Texts.Scanner; Out: Texts.Text);

    CONST lnk = 31;

    VAR Op, a, b, c, Next: LONGINT;

  BEGIN R[lnk] := 0; PC := Start;
    LOOP R[0] := 0; Next := PC + 1;
      IR := M[PC];
      Op := IR DIV 4000000H MOD 40H;
      a := IR DIV 200000H MOD 20H; b := IR DIV 10000H MOD 20H; c := IR MOD 10000H;
      IF Op < addi THEN c := R[c MOD 20H]
      ELSIF c >= 8000H THEN DEC(c, 10000H)
      END;
      CASE Op OF
        add, addi: R[a] := R[b] + c
      | sub, subi: R[a] := R[b] - c
      | mul, muli: R[a] := R[b] * c
      | div, divi: R[a] := R[b] DIV c
      | mod, modi: R[a] := R[b] MOD c
      | cmp, cmpi: IF R[b] > c THEN R[a] := 1 ELSIF R[b] < c THEN R[a] := - 1 ELSE R[a] := 0 END
      | or, ori:   R[a] := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, R[b]) + SYSTEM.VAL(SET, c))
      | and, andi: R[a] := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, R[b]) * SYSTEM.VAL(SET, c))
      | bic, bici: R[a] := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, R[b]) - SYSTEM.VAL(SET, c))
      | xor, xori: R[a] := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, R[b]) / SYSTEM.VAL(SET, c))
      | shl, shli: R[a] := SYSTEM.LSH(R[b], c)
      | sha, shai: R[a] := ASH(R[b], c)
      | chk, chki: IF (R[a] < 0) OR (c <= R[a]) THEN
                      Texts.WriteString(W, "  Trap  (PC = "); Texts.WriteInt(W, PC, 0);
                      Texts.Write(W, ")");  Texts.WriteLn(W);
                      Texts.Append(Out, W.buf); EXIT
                    END

      | ldw: R[a] := M[R[b] + c]
      | stw: M[R[b] + c] := R[a]
      | pop: R[a] := M[R[b]]; INC(R[b], c)
      | psh: DEC(R[b], c); M[R[b]] := R[a]

      | beq: IF R[a] = 0 THEN Next := PC + c END
      | bne: IF R[a] # 0 THEN Next := PC + c END
      | blt: IF R[a] < 0 THEN Next := PC + c END
      | bge: IF R[a] >= 0 THEN Next := PC + c END
      | ble: IF R[a] <= 0 THEN Next := PC + c END
      | bgt: IF R[a] > 0 THEN Next := PC + c END

      | bsr: Next := PC + c; R[lnk] := PC + 1
      | ret: Next := R[c MOD 20H]; IF Next = 0 THEN EXIT END

      | rd:  Texts.Scan(In); R[a] := In.i
      | wd:  Texts.Write(W, 09X); Texts.WriteInt(W, R[c], 0)
      | wh:  Texts.WriteHex(W, R[c])
      | wl:  Texts.WriteLn(W); Texts.Append(Out, W.buf)
      END;
      PC := Next
    END
  END Execute;

BEGIN Texts.OpenWriter(W)
END RISC.
