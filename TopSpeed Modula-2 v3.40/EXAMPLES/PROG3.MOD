MODULE prog3;
(* This program plays musical scales *)
FROM Lib IMPORT Speaker, Delay;
FROM MATHLIB IMPORT Exp,Log;

CONST MiddleC = 131.0;
TYPE NoteType = SHORTINT;
TYPE ScaleType = ARRAY [1..8] OF NoteType;
CONST major = ScaleType(0,2,4,5,7,9,11,12);
CONST minor = ScaleType(0,2,3,5,7,8,11,12);

PROCEDURE PlayScale(mode : ScaleType; key : NoteType);
VAR
  i:[1..8];
  note:NoteType;
  freq:LONGREAL;
BEGIN
  FOR i := 1 TO 8 DO
    note := key + mode[i];
    freq := MiddleC * Exp(LONGREAL(note) * (Log(2.0)/12.0));
    Speaker(CARDINAL(freq),200);
  END;
  Delay(500);
END PlayScale;

BEGIN
  PlayScale(major, 0); (* C major *)
  PlayScale(minor, 2); (* D minor *)
END prog3.

