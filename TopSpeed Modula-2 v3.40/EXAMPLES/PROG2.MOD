MODULE prog2;
(* This program writes out some Pythagorean triples *)
FROM IO IMPORT WrStr, WrLngCard, WrLn;
VAR a,b,c:LONGCARD;
BEGIN
  FOR c := 1 TO 100 DO
    FOR b := 1 TO c DO
      FOR a := 1 TO b DO
        IF a*a + b*b = c*c THEN
          WrLngCard(a,1); 
          WrStr(', '); 
          WrLngCard(b,1); 
          WrStr(', ');
          WrLngCard(c,1);
          WrLn;
        END;
      END;
    END;
  END;
END prog2.
