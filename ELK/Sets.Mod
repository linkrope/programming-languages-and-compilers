MODULE Sets;  (* MK 09.95 *)

  CONST M = MAX(SET) + 1;

  PROCEDURE Empty*(VAR s0 : ARRAY OF SET);

    VAR n : INTEGER;

  BEGIN FOR n := 0 TO SHORT(LEN(s0)) - 1 DO s0[n] := {} END
  END Empty;

  PROCEDURE Incl*(VAR s0 : ARRAY OF SET; n : INTEGER);

  BEGIN INCL(s0[n DIV M], n MOD M)
  END Incl;

  PROCEDURE Excl*(VAR s0 : ARRAY OF SET; n : INTEGER);

  BEGIN EXCL(s0[n DIV M], n MOD M)
  END Excl;

  PROCEDURE Complement*(VAR s0, s1 : ARRAY OF SET);

    VAR n : INTEGER;

  BEGIN FOR n := 0 TO SHORT(LEN(s0)) - 1 DO s0[n] := - s1[n] END
  END Complement;

  PROCEDURE Union*(VAR s0, s1, s2 : ARRAY OF SET);

    VAR n : INTEGER;

  BEGIN FOR n := 0 TO SHORT(LEN(s0)) - 1 DO s0[n] := s1[n] + s2[n] END
  END Union;

  PROCEDURE Difference*(VAR s0, s1, s2 : ARRAY OF SET);

    VAR n : INTEGER;

  BEGIN FOR n := 0 TO SHORT(LEN(s0)) - 1 DO s0[n] := s1[n] - s2[n] END
  END Difference;

  PROCEDURE Intersection*(VAR s0, s1, s2 : ARRAY OF SET);

    VAR n : INTEGER;

  BEGIN FOR n := 0 TO SHORT(LEN(s0)) - 1 DO s0[n] := s1[n] * s2[n] END
  END Intersection;

  PROCEDURE SymmetricDifference*(VAR s0, s1, s2 : ARRAY OF SET);

    VAR n : INTEGER;

  BEGIN FOR n := 0 TO SHORT(LEN(s0)) - 1 DO s0[n] := s1[n] / s2[n] END
  END SymmetricDifference;

  PROCEDURE In*(n : INTEGER; VAR s1 : ARRAY OF SET) : BOOLEAN;

  BEGIN RETURN n MOD M IN s1[n DIV M]
  END In;

  PROCEDURE IsEmpty*(VAR s1 : ARRAY OF SET) : BOOLEAN;

    VAR n : INTEGER;

  BEGIN FOR n := 0 TO SHORT(LEN(s1)) - 1 DO IF s1[n] # {} THEN RETURN FALSE END END;
    RETURN TRUE
  END IsEmpty;

  PROCEDURE Equal*(VAR s1, s2 : ARRAY OF SET) : BOOLEAN;

    VAR n : INTEGER;

  BEGIN FOR n := 0 TO SHORT(LEN(s1)) - 1 DO IF s1[n] # s2[n] THEN RETURN FALSE END END;
    RETURN TRUE
  END Equal;

  PROCEDURE Disjoint*(VAR s1, s2 : ARRAY OF SET) : BOOLEAN;

    VAR n : INTEGER;

  BEGIN FOR n := 0 TO SHORT(LEN(s1)) - 1 DO IF s1[n] * s2[n] # {} THEN RETURN FALSE END END;
    RETURN TRUE
  END Disjoint;

END Sets.
