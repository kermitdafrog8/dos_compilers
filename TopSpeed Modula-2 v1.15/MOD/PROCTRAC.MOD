IMPLEMENTATION MODULE ProcTrace;
IMPORT SYSTEM,IO,Lib,FIO,Str;

CONST MaxMap = 2000;
TYPE  MapRec = RECORD
                 Adr: LONGCARD;
                 Pos: CARDINAL;
               END;
VAR   Map: ARRAY [1..MaxMap] OF MapRec;
      MapInit: BOOLEAN;
      File:    FIO.File;
      FileBuf: ARRAY [1..1024+FIO.BufferOverhead] OF BYTE;

VAR
  Int60[0:180H],Old60,Int61[0:184H],Old61,str : ADDRESS;
  Base,Level,l,cs,ip                          : CARDINAL;
  Term                                        : PROC;
  MapFile                                     : ARRAY[0..63] OF CHAR;

PROCEDURE Get_Name (): Name;
CONST NoName = "(Unknown)";
VAR Adr: LONGCARD;
    seg: CARDINAL;
    N,P: CARDINAL;
    S:   ARRAY [1..100] OF CHAR;
BEGIN
  IF NOT MapInit THEN
    IO.WrStr("ProcTrace reading MAP-file..."); IO.WrLn;
    File := FIO.Open( MapFile );
    FIO.AssignBuffer( File , FileBuf );
    N := 0;
    REPEAT
      FIO.RdStr( File , S );
    UNTIL FIO.EOF OR (Str.Pos( S , ' by ' ) # MAX(CARDINAL) );
    IF FIO.EOF THEN Lib.FatalError('Invalid map file'); END;
    INCL( FIO.Separators , ':' );
    LOOP
      INC( N );
      IF N >= MaxMap-2 THEN Lib.FatalError("Map too big"); END;
      seg := FIO.RdHex( File );
      Adr := LONGCARD( seg ) << 4;
      IF NOT FIO.OK THEN EXIT; END;
      INC( Adr , LONGCARD( FIO.RdHex( File ) ) );
      Map[N].Adr := Adr;
      WHILE FIO.RdChar( File ) = ' ' DO END;
      Map[N].Pos := CARDINAL( FIO.GetPos( File ) ) - 1;
      FIO.RdStr( File , S );
      IF seg = 0 THEN DEC( N ); END;
    END;
    INC( N );
    Map[N].Adr := 100000H;
    Map[N].Pos :=  0FFFFH;
    MapInit := TRUE;
    FIO.Close( File );
    File := FIO.Open( MapFile );
  END;
  Adr := LONGCARD(cs) << 4 + LONGCARD(ip);
  P := 0FFFFH;
  N := 1;
  WHILE Map[N].Adr <= Adr DO
    P := Map[N].Pos;
    INC( N );
  END;
  IF P = 0FFFFH THEN RETURN NoName; END;
  FIO.Seek( File , LONGCARD( P ) );
  FIO.RdStr( File , S );
  RETURN Name( S );
END Get_Name;


PROCEDURE GetBase( l : CARDINAL );
BEGIN
  Base := [SYSTEM.Seg( l ):SYSTEM.Ofs( l )+4]^;
END GetBase;

PROCEDURE Monitor ( VAR W: WORD );
BEGIN
  MonAdr := ADR( W );
  MonWrd := W;
END Monitor;

PROCEDURE Check ( S: ARRAY OF CHAR );
BEGIN
  IF (MonAdr # NIL) AND (WORD(MonAdr^) # MonWrd) THEN
    IO.WrLn;
    IO.WrStr( "!!!!!!!!!!!!!!! Check: ");
    IO.WrStr( S );
    IO.WrLn;
    MonWrd := MonAdr^;
  END;
END Check;

PROCEDURE DefaultEntry;
BEGIN
  IO.WrStr('Entering  '); IO.WrStr(Get_Name()); IO.WrLn;
  Check( "Entering" );
END DefaultEntry;

PROCEDURE DefaultExit;
BEGIN
  IO.WrStr('Exiting   '); IO.WrStr(Get_Name()); IO.WrLn;
  Check( "Exiting" );
END DefaultExit;

PROCEDURE GetCsIp(): ADDRESS;
BEGIN
  RETURN [cs:ip];
END GetCsIp;

(*$J+,C FF*)
PROCEDURE EntryTrap( dummy : CARDINAL );
VAR a,t : CARDINAL;
BEGIN
  SYSTEM.EI;
  a := SYSTEM.Ofs( dummy )-4;
  t := [SYSTEM.Seg( dummy ) : a+2]^;
  cs := t-Base;
  ip := [SYSTEM.Seg( dummy ) : a]^;
  Entry;
END EntryTrap;

PROCEDURE ExitTrap( dummy : CARDINAL );
VAR a,t : CARDINAL;
BEGIN
  SYSTEM.EI;
  a := SYSTEM.Ofs( dummy )-4;
  t := [SYSTEM.Seg( dummy ) : a+2]^;
  cs :=t-Base;
  ip :=[SYSTEM.Seg( dummy ) : a]^;
  Exit;
END ExitTrap;
(*$J-,C F0*)

PROCEDURE GetDosVersion(): CARDINAL;
VAR r : SYSTEM.Registers; t : SHORTCARD;
BEGIN
  WITH r DO
    AH := 30H;
    Lib.Dos(r);
    t  := AH;
    AH :=AL;
    AL :=t;
    RETURN AX
  END;
END GetDosVersion;


PROCEDURE Finish;
BEGIN
  Int60 := Old60;
  Int61 := Old61;
  Term;
END Finish;

PROCEDURE Install;
BEGIN
  IF GetDosVersion() >= 300H THEN
     str := Lib.Environment(99);
     Str.Copy(MapFile,[SYSTEM.Seg(str^):SYSTEM.Ofs(str^)+3 Lib.CommandType]^);
     l := Str.Length( MapFile )-1;
     LOOP
        IF MapFile[l]='.' THEN EXIT END;
        IF l=0 THEN MapFile[0] := 0C; EXIT; END;
        DEC(l);
     END;
     MapFile[l+1] := 0C;
     Str.Append( MapFile,'MAP');
     IF NOT FIO.Exists(MapFile) THEN
        IO.WrStr(' MapFile ? ');
        IO.RdItem( MapFile );
      END;
  ELSE
     IO.WrStr(' MapFile ? ');
     IO.RdItem( MapFile );
  END;

  Entry := DefaultEntry;
  Exit  := DefaultExit;

  Old60 := Int60;
  Int60 := ADR( EntryTrap );
  Old61 := Int61;
  Int61 := ADR( ExitTrap );
  Lib.Terminate( Finish, Term);
  Level := 0;
END Install;

BEGIN
  GetBase(0);
  MapInit := FALSE;
  MonAdr := NIL;
END ProcTrace.
