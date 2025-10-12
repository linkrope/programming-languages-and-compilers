Asm.Load @
Asm.Exec 0  47 11

FP = 29
SP = 30

x  = - 1
y  = - 2
z  = - 3

multiply*
  ADDI  SP, 0, 1024
  PSH   LNK, SP, 1
  PSH   FP, SP, 1
  ADD   FP, 0, SP
  SUBI  SP, SP, 3

  RD    1
  STW   1, FP, x
  RD    1
  STW   1, FP, y
  STW   0, FP, z

while
  LDW   1, FP, x
  BLE   1, end_while - PC
  LDW   1, FP, x
  MODI  1, 1, 2
  BEQ   1, end_if - PC
  LDW   1, FP, z
  LDW   2, FP, y
  ADD   1, 1, 2
  STW   1, FP, z

end_if
  LDW   1, FP, y
  MULI  1, 1, 2
  STW   1, FP, y
  LDW   1, FP, x
  DIVI  1, 1, 2
  STW   1, FP, x
  BEQ   0, while - PC

end_while
  LDW   1, FP, z
  WD    1
  WL    0

  ADD   SP, 0, FP
  POP   FP, SP, 1
  POP   LNK, SP, 1
  RET   LNK
