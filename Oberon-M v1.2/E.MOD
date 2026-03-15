MODULE E;
  IMPORT LIO;

  CONST
    Digits = 200;

  VAR
    high, n: INTEGER;
    x: LONGINT;
    a: ARRAY Digits + 1 OF INTEGER;
    r: LIO.Rider;
    res: INTEGER;

  PROCEDURE Run;
  BEGIN
    LIO.OpenWrite("CON", r, res);
    
    IF res = 0 THEN (* Success *)
      high := Digits;
      x := 0;
      n := high - 1;
      WHILE n > 0 DO
        a[n] := 1;
        DEC(n)
      END;

      a[1] := 2; a[0] := 0;

      WHILE high > 9 DO
        DEC(high);
        n := high;
        WHILE n # 0 DO
          a[n] := SHORT(x MOD LONG(n));
          x := 10 * LONG(a[n - 1]) + x DIV LONG(n);
          DEC(n)
        END;
        LIO.WriteInt(r, x)
      END;

      LIO.WriteLn(r);
      LIO.Write(r, "done");
      LIO.WriteLn(r);
      LIO.Close(r)
    END
  END Run;

BEGIN
  Run
END E.
