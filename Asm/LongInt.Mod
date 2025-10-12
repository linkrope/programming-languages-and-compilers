MODULE LongInt;  (* MK 03.96 *)

  VAR OK*: BOOLEAN;

  PROCEDURE Inc*(VAR z: LONGINT);

  BEGIN
    OK := z < MAX(LONGINT);
    IF OK THEN INC(z) END
  END Inc;

  PROCEDURE Dec*(VAR z: LONGINT);

  BEGIN
    OK := z > MIN(LONGINT);
    IF OK THEN DEC(z) END
  END Dec;

  PROCEDURE Neg*(VAR z: LONGINT; x: LONGINT);

  BEGIN
    OK := z # MIN(LONGINT);
    IF OK THEN z := - x END
  END Neg;

  PROCEDURE Add*(VAR z: LONGINT; x, y: LONGINT);

  BEGIN
    OK := ((x >= 0) # (y >= 0)) OR
          (y >= 0) & (x <= MAX(LONGINT) - y) OR (y < 0) & (x >= MIN(LONGINT) - y);
    IF OK THEN z := x + y END
  END Add;

  PROCEDURE Sub*(VAR z: LONGINT; x, y: LONGINT);

  BEGIN
    OK := ((x >= 0) = (y >= 0)) OR
          (y < 0) & (x <= MAX(LONGINT) + y) OR (y >= 0) & (x >= MIN(LONGINT) + y);
    IF OK THEN z := x - y END
  END Sub;

  PROCEDURE Mul*(VAR z: LONGINT; x, y: LONGINT);

  BEGIN
    IF y = 0 THEN OK := TRUE
    ELSE
      IF x >= 0 THEN
        IF y > 0 THEN OK := x <= MAX(LONGINT) DIV y
        ELSE OK := (y = - 1) OR (x <= MIN(LONGINT) DIV y)
        END
      ELSE
        IF y > 0 THEN OK := x >= MIN(LONGINT) DIV y
        ELSE OK := x >= MAX(LONGINT) DIV y
        END
      END
    END;
    IF OK THEN z := x * y END
  END Mul;

  PROCEDURE Div*(VAR z: LONGINT; x, y: LONGINT);

  BEGIN
    OK := y # 0;
    IF OK THEN
      IF (x = MIN(LONGINT)) & (y = - 1) THEN OK := FALSE ELSE z := x DIV y END
    END
  END Div;

  PROCEDURE Mod*(VAR z: LONGINT; x, y: LONGINT);

  BEGIN
    OK := y # 0;
    IF OK THEN
      IF (x = MIN(LONGINT)) & (y = - 1) THEN z := 0 ELSE  z := x MOD y END
    END
  END Mod;

END LongInt.
