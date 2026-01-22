(*$I+,R+,S+,A-,V-,N+,O-*)
MODULE m2locate;
IMPORT Lib,Str,FIO,IO,Storage;

(* This program is used to locate an MSDOS exe file.
   The output is in Absolute Binary format,
   suitable for blowing a stand-alone system into PROM.
   The memory layout of the target system is specified in the
   .mem file, together with the linker classes which are to be
   put in the memory, for example:

   rom F0000  FFFF0 CODE FCODE
   ram 80000  E0000 DATA Dummy BSS M_DATA HEAP STACK

   The second address is a 'stop' address, so that a warning can
   be produced if there is not enough memory.

*)

CONST
  cNamePos = 4; (* change to 3 if it is required to locate segments rather than classes *)

CONST
  Delim = Str.CHARSET{' '};
  ImageBufMax=4000H;

TYPE
  StringType = ARRAY [0..31] OF CHAR;

  LongStringType = ARRAY [0..511] OF CHAR;

  UnitType = RECORD
    Name:StringType;
    Start,Stop:LONGCARD;
    StartSeg:CARDINAL;
    Diff:CARDINAL;
    Located:BOOLEAN;
    Rom:BOOLEAN;
    MemStart:LONGCARD;
  END;

  ExeHeaderType = RECORD
    magic : CARDINAL;
    sizemod512 : CARDINAL;
    sizediv512 : CARDINAL;
    numrelocitem : CARDINAL;
    headerparas : CARDINAL;
    heapminparas : CARDINAL;
    heapmaxparas : CARDINAL;
    initialss : CARDINAL;
    initialsp : CARDINAL;
    checksum : CARDINAL;
    initialip : CARDINAL;
    initialcs : CARDINAL;
    relocations : CARDINAL;
    ovrlay : CARDINAL;
    undocumented : CARDINAL;
    (* relocation items follow *)
  END;

  ImageType = RECORD
    index:CARDINAL;
    pos,size:LONGCARD;
    buf:ARRAY [0..ImageBufMax] OF SHORTCARD; (* note extra byte at start *)
    (* this is required to deal with fixups to the last byte of the buffer *)
    (* which are deferred until the next buffer load is read *)
  END;

VAR
  ExeFile,
  MapFile,
  MemFile,
  Mp2File : FIO.File;

  BinFile : ARRAY[1..4] OF FIO.File;

  MemWidth : CARDINAL;

  Image : ImageType;

  ExeHeader : ExeHeaderType;

  HeaderSize:LONGCARD; (* size of exeheader in bytes *)

  NosUnit:CARDINAL;

  Unit:ARRAY [1..300] OF UnitType;

PROCEDURE ReadHex( s:ARRAY OF BYTE; i:CARDINAL ):LONGCARD;
VAR
  res:LONGCARD;
  c:SHORTCARD;
BEGIN
  res := 0;
  LOOP
    c := SHORTCARD(s[i]);
    INC(i);
    CASE CHAR(c) OF
    | 'A'..'F': c := c - ( SHORTCARD('A') - 10 ) ;
    | '0'..'9': c := c - SHORTCARD('0');
    ELSE EXIT;
    END;
    res := res * 16 + VAL(LONGCARD, c );
  END;
  RETURN res;
END ReadHex;

PROCEDURE ReadMapFile;
VAR
  cname,token:StringType;
  line:LongStringType;
BEGIN
  NosUnit := 0;
  REPEAT
    FIO.RdStr(MapFile,line) ;
  UNTIL (line[0]<>CHAR(0)) AND (line[1]>='0') AND (line[1]<='9') ;
  LOOP
    IF Str.Length(line) < 40 THEN EXIT END;
    Str.Item( cname, line, Delim, cNamePos );
    IF ( NosUnit = 0 )
    OR ( Str.Compare(cname,Unit[NosUnit].Name) <> 0 )
    THEN
      INC(NosUnit);
      WITH Unit[NosUnit] DO
        Name := cname;
        Str.Item( token, line, Delim, 0 );
        Start := ReadHex( token,0 );
        StartSeg := CARDINAL(Start DIV 16);
        Located := FALSE;
        Rom := FALSE;
        Diff := 0;
      END;
    END;
    IF ( NosUnit <> 0 ) THEN
      Str.Item( token, line, Delim, 1 );
      Unit[NosUnit].Stop := ReadHex( token, 0 );
    END;
    FIO.RdStr(MapFile,line);
  END;
  IF NosUnit = 0 THEN
    IO.WrStr('Bad .map file');
    HALT;
  END;
  Unit[NosUnit+1] := Unit[NosUnit]; (* sentinel *)
END ReadMapFile;

PROCEDURE ClassSearch( cname:ARRAY OF CHAR ):CARDINAL;
VAR i:CARDINAL;
BEGIN
  i := 1;
  WHILE ( i <= NosUnit ) AND ( Str.Compare( Unit[i].Name, cname ) <> 0 ) DO
    INC(i);
  END;
  RETURN i;
END ClassSearch;

PROCEDURE ReadMemFile;
VAR
  cname,token:StringType;
  line:LongStringType;
  memstart,memstop:LONGCARD;
  rom:BOOLEAN;
  ram:BOOLEAN;
  i,item:CARDINAL;
BEGIN
  MemWidth := 1; (* default width *)
  LOOP
    FIO.RdStr(MemFile,line);
    Str.Item( token, line, Delim, 0 );
    ram := FALSE;
    rom := FALSE;
    IF Str.Compare(token,'') = 0 THEN
      EXIT;
    ELSIF Str.Compare(token,'rom') = 0 THEN
      rom := TRUE;
    ELSIF Str.Compare(token,'ram') = 0 THEN
      ram := TRUE;
    ELSIF Str.Compare(token,'width') = 0 THEN
      Str.Item( token, line, Delim, 1 );
      MemWidth := CARDINAL( ReadHex( token,0 ) );
    ELSE
      IO.WrStr('Bad .mem file');
      HALT;
    END;
    IF rom OR ram THEN
      Str.Item( token, line, Delim, 1 );
      memstart := ReadHex( token,0 );
      Str.Item( token, line, Delim, 2 );
      memstop := ReadHex( token,0 );
      item := 3;
      LOOP
        Str.Item( cname, line, Delim, item );
        INC(item);
        IF cname[0]=CHAR(0) THEN
          EXIT;
        END;
        (* search table *)
        i := ClassSearch( cname );
        IF i > NosUnit THEN
          IO.WrStr('Warning: ');
          IO.WrStr(cname);
          IO.WrStr(' not found in .map file');
          IO.WrLn;
        ELSE
          INC( memstart, LONGCARD( CARDINAL(Unit[i].Start-memstart) MOD 16 ));
          Unit[i].MemStart := memstart;
          IF Unit[i].Located THEN
            IO.WrStr('Warning : ');
            IO.WrStr(cname);
            IO.WrStr(' specified more than once in .mem file');
            IO.WrLn;
          END;
          Unit[i].Located := TRUE;
          Unit[i].Rom := rom;
          Unit[i].Diff := CARDINAL( (Unit[i].Start-memstart) DIV 16 );
          INC( memstart, Unit[i].Stop - Unit[i].Start );
          IF memstart > memstop THEN
            IO.WrStr('Warning: not enough memory for ');
            IO.WrStr(cname);
            IO.WrLn;
          END;
        END;
      END;
    END;
  END;
END ReadMemFile;

PROCEDURE NewSeg( seg,off:CARDINAL ):CARDINAL;
VAR loc:LONGCARD;
    k:CARDINAL;
BEGIN
  loc := 16*VAL(LONGCARD,seg) + VAL(LONGCARD,off);
  k := 1;
  (* search for location segment = k *)
  WHILE ( k <= NosUnit ) AND ( loc >= Unit[k].Start ) DO INC(k) END;
  DEC(k);
  RETURN seg - Unit[k].Diff;
END NewSeg;

PROCEDURE ChkRead( VAR buf:ARRAY OF BYTE; count:CARDINAL );
BEGIN
  IF FIO.RdBin( ExeFile, buf, count ) <> count THEN
    IO.WrStr('?? on read');
    HALT;
  END;
END ChkRead;

PROCEDURE GetByte():SHORTCARD;
VAR
  pindex:CARDINAL;
  fixlocabs:LONGCARD;
  target:CARDINAL;
  wp:POINTER TO CARDINAL;
  exefix:RECORD off,seg:CARDINAL END;
  dummy:CARDINAL;
  i,j:CARDINAL;
BEGIN
  IF Image.pos >= Image.size THEN
    INC(Image.pos);
    RETURN 99H;
  END;
  IF Image.index >= ImageBufMax THEN
    IF Image.pos = 0 THEN
      Image.index := 1;
    ELSE
      Image.buf[0] := Image.buf[ImageBufMax];
      Image.index := 0;
    END;
    FIO.Seek( ExeFile, HeaderSize+Image.pos+LONGCARD(1-Image.index) );
    dummy := FIO.RdBin( ExeFile, Image.buf[1], SIZE(Image.buf)-1 );

    (* now apply segment fixups for this buffer *)
    FIO.Seek( ExeFile, LONGCARD(ExeHeader.relocations) );
    FOR i := 1 TO ExeHeader.numrelocitem DO
      ChkRead( exefix, SIZE(exefix) );
      fixlocabs := VAL(LONGCARD,exefix.off)+16*VAL(LONGCARD,exefix.seg);
      IF fixlocabs - Image.pos <= ImageBufMax THEN
        pindex := CARDINAL(fixlocabs-Image.pos) + Image.index;
        IF pindex < ImageBufMax THEN
          wp := ADR(Image.buf[pindex]);
          target := wp^;
          j := 0;
          LOOP (* search for target segment = j *)
            INC(j);
            IF ( j > NosUnit ) OR ( target < Unit[j].StartSeg ) THEN
              EXIT;
            END;
          END;
          DEC(j);
          wp^ := target - Unit[j].Diff;
        END;
      END;
    END;
  END;
  INC(Image.pos);
  INC(Image.index);
  RETURN Image.buf[Image.index-1];
END GetByte;

VAR OutPos : LONGCARD;

PROCEDURE PutByte( b:SHORTCARD );
BEGIN
  FIO.WrBin( BinFile[1+(CARDINAL(OutPos) MOD MemWidth)], b, 1 );
  INC( OutPos );
END PutByte;

PROCEDURE PutUnit( unit:UnitType );
VAR
  total:LONGCARD;
  dummy:SHORTCARD;
  buf:ARRAY [0..15] OF SHORTCARD;
  i,count,seg,off:CARDINAL;
BEGIN
  IF NOT unit.Located THEN
    IO.WrStr('Warning: ');
    IO.WrStr(unit.Name);
    IO.WrStr(' not located ');
    IO.WrLn;
  END;
  total := unit.Stop-unit.Start;
  IF total > 0 THEN
    IF unit.Rom THEN
      WHILE Image.pos < unit.Start DO
        dummy := GetByte();
      END;
      IF unit.Start <> Image.pos THEN
        IO.WrStr('Overshoot error??');
        IO.WrLngHex(unit.Start,6);
        IO.WrLngHex(Image.pos,6);
        HALT;
      END;
      IF OutPos = 0 THEN
        OutPos := unit.MemStart;
      ELSE
        WHILE OutPos < unit.MemStart DO
          PutByte(0FFH);
        END;
      END;
      WHILE total > 0 DO
        PutByte( GetByte() );
        DEC(total);
      END;
    END;
  END;
END PutUnit;

PROCEDURE WriteBinFile;
VAR
  i:CARDINAL;
BEGIN
  ChkRead( ExeHeader, SIZE(ExeHeader) );
  HeaderSize := VAL(LONGCARD,ExeHeader.headerparas)*16;
  Image.size := FIO.Size(ExeFile)-HeaderSize;
  Image.pos := 0;
  Image.index := ImageBufMax;
  OutPos := 0;
  FOR i := 1 TO NosUnit DO
    PutUnit( Unit[i] );
  END;
END WriteBinFile;

PROCEDURE Hex(n:CARDINAL):CHAR;
BEGIN
  n := n MOD 16;
  IF n > 9 THEN
    RETURN CHAR( n + ORD('A') - 10 )
  ELSE
    RETURN CHAR( n + ORD('0') );
  END;
END Hex;

PROCEDURE EditMap;
VAR
  line:LongStringType;
  i:CARDINAL;
  seg,off:CARDINAL;
  addr:LONGCARD;
  k:CARDINAL;
  cname:StringType;
  start:RECORD
    off,seg:CARDINAL;
  END;
BEGIN
  k := 0;
  FIO.Seek(MapFile,0);
  LOOP
    FIO.RdStr(MapFile,line);
    IF FIO.EOF THEN EXIT END;
    IF ( line[0] = ' ' ) AND ( line[6] = 'H' ) THEN
      Str.Item( cname, line, Delim, cNamePos );
      k := ClassSearch(cname);
      IF k <= NosUnit THEN
        FOR i := 0 TO 7 BY 7 DO
          addr := ReadHex(line,i+1);
          seg := CARDINAL(addr DIV 16);
          off := CARDINAL(addr) MOD 16;
          seg := seg - Unit[k].Diff;
          line[i+4] := Hex(seg); seg := seg DIV 16;
          line[i+3] := Hex(seg); seg := seg DIV 16;
          line[i+2] := Hex(seg); seg := seg DIV 16;
          line[i+1] := Hex(seg); seg := seg DIV 16;
        END;
      END;
    ELSIF ( line[0] = 'P' ) THEN
      seg := CARDINAL(ReadHex(line,23));
      off := CARDINAL(ReadHex(line,28));
      seg := NewSeg(seg,off);
      start.seg := seg;
      start.off := off;
      line[26] := Hex(seg); seg := seg DIV 16;
      line[25] := Hex(seg); seg := seg DIV 16;
      line[24] := Hex(seg); seg := seg DIV 16;
      line[23] := Hex(seg); seg := seg DIV 16;
    ELSE
      FOR i := 5 TO Str.Length(line) DO
        IF ( line[i] = ':' ) THEN
          seg := CARDINAL(ReadHex(line,i-4));
          off := CARDINAL(ReadHex(line,i+1));
          seg := NewSeg( seg, off );
          line[i-1] := Hex(seg); seg := seg DIV 16;
          line[i-2] := Hex(seg); seg := seg DIV 16;
          line[i-3] := Hex(seg); seg := seg DIV 16;
          line[i-4] := Hex(seg); seg := seg DIV 16;
        END;
      END;
    END;
    IF line[0] <> CHAR(0) THEN
      FIO.WrStr(Mp2File,line);
    END;
    FIO.WrLn(Mp2File);
  END;
END EditMap;

PROCEDURE PrintSummary;
VAR i:CARDINAL;
BEGIN
  FOR i := 1 TO NosUnit DO
    WITH Unit[i] DO
      IO.WrStr(' Start=');  IO.WrLngHex(Start,6);
      IO.WrStr(' ');
      IO.WrStr(' Stop=');  IO.WrLngHex(Stop,6);
      IO.WrStr(' ');
      IF Located THEN
        IO.WrStr('MemStart=');
        IO.WrLngHex(MemStart,6);
        IO.WrStr(' ');
      ELSE
        IO.WrStr('Not located ');
      END;
      IO.WrStr(Name);
      IO.WrLn;
    END;
  END;
END PrintSummary;

PROCEDURE GiveBuf( f:FIO.File );
TYPE buf = ARRAY [1..800H+FIO.BufferOverhead] OF SHORTCARD;
VAR bufp :POINTER TO buf;
BEGIN
  Storage.ALLOCATE(bufp,SIZE(buf));
  FIO.AssignBuffer(f,bufp^);
END GiveBuf;

PROCEDURE Create(ext:ARRAY OF CHAR):FIO.File;
VAR
  filename:FIO.PathStr;
  res:FIO.File;
BEGIN
  Str.Concat( filename, Lib.CommandLine^, ext );
  res := FIO.Create(filename);
  GiveBuf(res);
  RETURN res;
END Create;

PROCEDURE Open(ext:ARRAY OF CHAR):FIO.File;
VAR
  filename:FIO.PathStr;
  res:FIO.File;
BEGIN
  Str.Concat( filename, Lib.CommandLine^, ext );
  res := FIO.Open(filename);
  GiveBuf(res);
  RETURN res;
END Open;

BEGIN
  IO.WrStr('TopSpeed Locator Version 1.10');
  IO.WrLn;
  IO.WrStr('Copyright (C) 1987,1988 Jensen & Partners International');
  IO.WrLn;

  ExeFile := Open('.exe'); (* no buffering because random access *)
  MemFile := Open('.mem');
  MapFile := Open('.map');
  Mp2File := Create('.mp2');
  ReadMapFile;
  ReadMemFile;
  BinFile[1] := Create('.bn1');
  IF MemWidth > 1 THEN
    BinFile[2] := Create('.bn2');
  END;
  IF MemWidth > 2 THEN
    BinFile[3] := Create('.bn3');
    BinFile[4] := Create('.bn4');
  END;
  (*PrintSummary;*)
  WriteBinFile;
  EditMap;
  FIO.Close(ExeFile);
  FIO.Close(MemFile);
  FIO.Close(MapFile);
  FIO.Close(Mp2File);
  FIO.Close(BinFile[1]);
  IF MemWidth > 1 THEN
    FIO.Close(BinFile[2]);
  END;
  IF MemWidth > 2 THEN
    FIO.Close(BinFile[3]);
    FIO.Close(BinFile[4]);
  END;
END m2locate.
