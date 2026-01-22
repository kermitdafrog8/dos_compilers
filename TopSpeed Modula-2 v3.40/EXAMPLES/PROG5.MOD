MODULE prog5;
(* this program lists the 9-digit numbers, containing every
   digit from 1 to 9 which are a product of three 3-digit
   numbers, which also contain every digit from 1 to 9 *)
IMPORT IO;
FROM perms IMPORT NextPerm;

PROCEDURE check(n:LONGCARD):BOOLEAN;
(* Checks if the digits of n are a permutation of 1..9 *)
VAR i:[1..9];
    digit:[0..9];
    seen:ARRAY [0..9] OF BOOLEAN;
BEGIN
  seen[0] := TRUE;
  FOR i := 1 TO 9 DO
    seen[i] := FALSE;
  END;
  FOR i := 1 TO 9 DO
    digit := CARDINAL(n MOD 10); (* n MOD 10 is the remainder
                                    when n is divided by 10 *)
    IF seen[ digit ] THEN
      RETURN FALSE;
    ELSE
      seen[ digit ] := TRUE;
    END;
    n := n DIV 10; (* DIV means whole number division *)
  END;
  RETURN TRUE;
END check;

VAR d:ARRAY[0..8] OF SHORTCARD;
    a,b,c:CARDINAL;
    n:LONGCARD;
    i:CARDINAL;
    wrap:BOOLEAN;
BEGIN
  FOR i := 0 TO 8 DO
    d[i] := SHORTCARD(i) + 1;
  END;

  REPEAT
    a := CARDINAL(d[0])*100 + CARDINAL( d[1]*10 + d[2] );
    b := CARDINAL(d[3])*100 + CARDINAL( d[4]*10 + d[5] );
    c := CARDINAL(d[6])*100 + CARDINAL( d[7]*10 + d[8] );
    n := LONGCARD(a) * LONGCARD(b) * LONGCARD(c);

    IF check(n) THEN
      IO.WrStr('A solution is ');
      IO.WrCard(a, 1);
      IO.WrStr(' x ');
      IO.WrCard(b, 1);
      IO.WrStr(' x ');
      IO.WrCard(c, 1);
      IO.WrStr(' = ');
      IO.WrLngCard(n, 1);
      IO.WrLn;
    END;
    NextPerm(9,d,wrap);
  UNTIL wrap;
END prog5.

