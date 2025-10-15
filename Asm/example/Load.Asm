! Asm.Load @
! Asm.Exec 0

x = 1111 * 1111

_2_8  = 2 * 2 * 2 * 2 * 2 * 2 * 2 * 2
_2_16 = _2_8 * _2_8

  ADDI  1, 0, x / _2_16
  SHLI  1, 1, 8
  ORI   1, 1, x % _2_16 / _2_8
  SHLI  1, 1, 8
  ORI   1, 1, x % _2_8

  WD    1
  WL    0

  ADDI  1, 0, - 1 - x / _2_16
  SHLI  1, 1, 16
  ORI   1, 1, _2_16 - 1 - x % _2_16
  XORI  1, 1, - 1

  WD    1
  WL    0

  RET   LNK
