
MODULE prog7;
(* Sorts lines of a file into order, deleting duplicates *)
IMPORT IO, FIO, Lib, Storage, Str;

TYPE
  StringType = ARRAY [0..255] OF CHAR;
  StringPointerType = POINTER TO StringType;
VAR
  p : ARRAY [1..10000] OF StringPointerType;

PROCEDURE Less(i,j:CARDINAL):BOOLEAN;
BEGIN
  RETURN Str.Compare(p[i]^, p[j]^)  < 0 ;
END Less;

PROCEDURE Swap(i,j:CARDINAL);
VAR tmp:StringPointerType;
BEGIN
  tmp := p[i]; p[i] := p[j]; p[j] := tmp;
END Swap;

VAR s: StringType;
    len:CARDINAL;
    i,n:CARDINAL;
    InFile,OutFile:FIO.File;
    buffer:ARRAY [1..512+FIO.BufferOverhead] OF BYTE;
BEGIN
  (* check parameters *)
  IF Lib.ParamCount() <> 2 THEN
    IO.WrStr('Try again : prog7 input-file output-file');
    IO.WrLn;
    HALT;
  END;

  (* read file in *)
  Lib.ParamStr(s, 1); InFile := FIO.Open(s);
  FIO.AssignBuffer(InFile, buffer);
  n := 0;
  LOOP
    FIO.RdStr(InFile, s);
    IF FIO.EOF THEN
      EXIT;
    END;
    IF n = HIGH(p) THEN
      IO.WrStr('Too many lines!');
      IO.WrLn;
      EXIT;
    END;
    INC(n);
    len := Str.Length(s);
    Storage.ALLOCATE(p[n], len + 1);
    Lib.Move(ADR(s), ADR(p[n]^), len + 1);
  END;

  FIO.Close(InFile);

  (* sort file in memory *)
  Lib.HSort(n, Less, Swap);

  (* write file out *)
  Lib.ParamStr(s, 2); OutFile := FIO.Create(s);
  FIO.AssignBuffer(OutFile, buffer);
  FOR i := 1 TO n DO
    IF (i = 1) OR (Str.Compare(p[i]^, p[i-1]^) <> 0) THEN
      FIO.WrStr(OutFile, p[i]^);
      FIO.WrLn(OutFile);
    END;
  END;
  FIO.Close(OutFile);

END prog7.


