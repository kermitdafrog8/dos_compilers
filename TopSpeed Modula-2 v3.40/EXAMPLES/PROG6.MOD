MODULE prog6;
(* This program draws patterns on the screen *)
FROM Lib IMPORT RANDOM,RANDOMIZE;
FROM Graph IMPORT Circle,Disc,GraphMode,TextMode,Width,Depth;
IMPORT IO;

TYPE
  FunnyType = RECORD
    q : INTEGER;   (* value *)
    d : INTEGER;   (* rate of change *)
    min : INTEGER;
    max : INTEGER;
  END;

PROCEDURE init(VAR v:FunnyType);
BEGIN
  v.q := v.min;
  v.d := INTEGER(RANDOM(v.max-v.min));
END init;

PROCEDURE bounce(VAR v:FunnyType);
(* Update v.q, 'bouncing' when it goes out of range *)
BEGIN
  WITH v DO
    q := q + d;
    IF q < min   THEN
      q := 2*min-q;
      d := -d;
    END;
    IF q > max THEN
      q := 2*max-q;
      d := -d;
    END;
  END;
END bounce;

VAR
  x,y : FunnyType;
  color,radius : CARDINAL;
BEGIN
  RANDOMIZE;
  x.max := Width-1; x.min := 0;
  y.max := Depth-1; y.min := 0;

  IO.WrStr('Press space to continue, any other key to stop');
  IO.WrLn;
  WHILE NOT IO.KeyPressed() DO
  END;

  GraphMode;
  WHILE IO.RdKey() = ' ' DO
    init(x);
    init(y);

    REPEAT
      color := RANDOM(16);
    UNTIL color MOD 5 <> 0; (* fill using 2 colors *)

    radius := 2 + RANDOM(5);
    WHILE NOT IO.KeyPressed() DO
      bounce(x);
      bounce(y);
      Disc(x.q, y.q, radius, color);
      Circle(x.q, y.q, radius, color MOD 4);
    END;

    Disc(0,0,Width+Depth, 0); (* clear screen *)
  END;
  TextMode;
END prog6.

