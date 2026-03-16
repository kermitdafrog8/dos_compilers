MODULE Sieve;
  IMPORT LIO;

  CONST
    Size = 8190;
    Iterations = 10;

  (* declare all variables as globals to improve performance by 16% *)
  VAR
    flags: ARRAY 8191 OF BOOLEAN; (* Explicit size *)
    res, i, prime, k, count, iter: INTEGER;
    r: LIO.Rider;

  PROCEDURE Run;
  BEGIN
    LIO.OpenWrite("CON", r, res);
    IF res = 0 THEN
      LIO.Write(r, "10 iterations"); LIO.WriteLn(r);
      iter := 1;
      WHILE iter <= Iterations DO
        count := 0;
        i := 0;
        WHILE i <= Size DO
            flags[i] := TRUE;
            INC(i);
        END;
        i := 0;
        WHILE i <= Size DO
          IF flags[i] THEN
            prime := i + i + 3;
            k := i + prime;
            WHILE k <= Size DO
              flags[k] := FALSE;
              k := k + prime
            END;
            INC(count)
          END;
          INC(i)
        END;
        INC(iter)
      END;
      LIO.WriteInt(r, LONG(count)); 
      LIO.Write(r, " primes"); 
      LIO.WriteLn(r);
      LIO.Close(r)
    END
  END Run;

BEGIN
  Run
END Sieve.
