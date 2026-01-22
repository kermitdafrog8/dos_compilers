(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  INOUT.MOD - input/output (core library)                                 *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*$V-*)
IMPLEMENTATION MODULE InOut ;
IMPORT FIO,Str,Terminal,ASCII ;
VAR
  InputFile,
  OutputFile : CARDINAL ;

PROCEDURE AddExt ( VAR fn : ARRAY OF CHAR ; ext : ARRAY OF CHAR ) ;
VAR
  i,p : CARDINAL ;
BEGIN
  p := Str.Length(fn) ;
  i := 1 ;
  LOOP
    IF (i>p)OR(i=5)OR(fn[p-i] = '\') THEN
      Str.Append(fn,'.');
      Str.Append(fn,ext);
      RETURN ;
    END ;
    IF fn[p-i]='.' THEN RETURN END ;
    INC(i) ;
  END ;
END AddExt ;

PROCEDURE OpenInput   ( defext : ARRAY OF CHAR ) ;
VAR
  fn : FIO.PathStr ;
BEGIN
  CloseInput ;
  Terminal.WriteString('IN>');
  Terminal.ReadString(fn) ;
  Terminal.WriteLn ;
  IF fn[0]=0C THEN RETURN END ;
  AddExt(fn,defext) ;
  InputFile := FIO.Open(fn) ;
  Done := (FIO.IOresult()=0) ;
  IF NOT Done THEN
    InputFile := FIO.StandardInput ;
  END ;
END OpenInput ;

PROCEDURE OpenOutput  ( defext : ARRAY OF CHAR ) ;
VAR
  fn : FIO.PathStr ;
BEGIN
  CloseOutput ;
  Terminal.WriteString('OUT>');
  Terminal.ReadString(fn) ;
  Terminal.WriteLn ;
  IF fn[0]=0C THEN RETURN END ;
  AddExt(fn,defext) ;
  OutputFile := FIO.Create(fn) ;
  Done := (FIO.IOresult()=0) ;
  IF NOT Done THEN
    OutputFile := FIO.StandardOutput ;
  END ;
END OpenOutput ;

PROCEDURE CloseInput ;
BEGIN
  IF InputFile<>FIO.StandardInput THEN
    FIO.Close(InputFile) ;
    Done := (FIO.IOresult()=0) ;
    InputFile := FIO.StandardInput ;
  ELSE
    Done := TRUE ;
  END ;
END CloseInput ;

PROCEDURE CloseOutput ;
BEGIN
  IF OutputFile<>FIO.StandardOutput THEN
    FIO.Close(OutputFile) ;
    Done := (FIO.IOresult()=0) ;
    OutputFile := FIO.StandardOutput ;
  ELSE
    Done := TRUE ;
  END ;
END CloseOutput ;

PROCEDURE Read ( VAR v : CHAR ) ;
VAR
  b : BOOLEAN ;
BEGIN
  REPEAT
    IF InputFile=FIO.StandardInput THEN
      Terminal.Read(v) ;
      Done := (v<>CHR(26)) ;
    ELSE
      v := FIO.RdChar(InputFile) ;
      Done := (FIO.IOresult()=0)AND(v<>CHR(26)) ;
    END ;
  UNTIL v<>ASCII.lf ; (* LF ignored *)
  IF v=ASCII.cr THEN
    v := EOL ;
  END ;
END Read ;

PROCEDURE ReadString  ( VAR v : ARRAY OF CHAR ) ;
VAR
  c : CHAR ;
  line : ARRAY[0..255] OF CHAR ;
  p : CARDINAL ;
BEGIN
  v[0] := 0C ;
  IF InputFile=FIO.StandardInput THEN
    Terminal.ReadString(v) ;
    termCH := Terminal.termCH ;
    Done := (termCH<>CHR(26)) ;
  ELSE
    p := 0 ;
    REPEAT Read(c) UNTIL (c<>' ') OR NOT Done ;
    LOOP
      IF NOT Done THEN EXIT END ;
       IF (c>' ') THEN
         IF p<SIZE(line) THEN
           line[p] := c ;
           INC(p) ;
         END ;
       ELSE EXIT ;
       END ;
       Read(c) ;
    END ;
    termCH := c ;
    IF p<SIZE(line) THEN line[p] := CHR(0) END ;
    Str.Copy(v,line) ;
  END ;
  Done := (termCH<>CHR(26)) ;
END ReadString ;

PROCEDURE ReadCard    ( VAR v : CARDINAL ) ;
VAR
  r : LONGCARD ;
  line : ARRAY[0..79] OF CHAR ;
BEGIN
  ReadString(line) ;
  r := Str.StrToCard(line,10,Done) ;
  Done := Done AND (r<=MAX(CARDINAL)) ;
  v := CARDINAL(r) ;
END ReadCard ;

PROCEDURE ReadInt     ( VAR v : INTEGER ) ;
VAR
  r : LONGINT ;
  line : ARRAY[0..79] OF CHAR ;
BEGIN
  ReadString(line) ;
  r := Str.StrToInt(line,10,Done) ;
  Done := Done AND (r>=MIN(INTEGER)) AND (r<=MAX(INTEGER)) ;
  v := INTEGER(r) ;
END ReadInt ;



PROCEDURE Write       ( v : CHAR ) ;
BEGIN
  IF OutputFile=FIO.StandardOutput THEN
    IF v=EOL THEN Terminal.WriteLn() ;
             ELSE Terminal.Write(v) ;
    END ;
    Done := TRUE ;
  ELSE
    IF v=EOL THEN FIO.WrLn(OutputFile) ;
             ELSE FIO.WrChar(OutputFile,v) ;
    END ;
    Done := (FIO.IOresult()=0) ;
  END ;
END Write ;

PROCEDURE WriteLn ;
BEGIN
  Write(EOL) ;
END WriteLn ;

PROCEDURE WriteString ( v : ARRAY OF CHAR ) ;
VAR
  buff : ARRAY[0..256] OF CHAR ;
  i,j  : CARDINAL ;
  c    : CHAR ;

  PROCEDURE OutBuff ;
  BEGIN
    IF Done THEN
      buff[j] := CHR(0) ;
      IF OutputFile=FIO.StandardOutput THEN
         Terminal.WriteString(buff) ;
         Done := TRUE ;
      ELSE
        FIO.WrStr(OutputFile,buff) ;
        Done := (FIO.IOresult()=0) ;
      END ;
      j := 0 ;
    END ;
  END OutBuff;

BEGIN
  i := 0 ; j := 0 ;
  Done := TRUE ;
  LOOP
    IF i>HIGH(v) THEN OutBuff ; RETURN END ;
    c := v[i] ; INC(i) ;
    IF c=CHR(0) THEN OutBuff ; RETURN END ;
    IF c=EOL THEN OutBuff ; WriteLn
    ELSE
      buff[j] := c ; INC(j) ;
      IF j=SIZE(buff)-1 THEN OutBuff END ;
    END ;
    IF NOT Done THEN RETURN END ;
  END ;
END WriteString ;

PROCEDURE WriteCard   ( v : CARDINAL ;      w : CARDINAL ) ;
BEGIN
  FIO.WrCard(OutputFile,v,INTEGER(w)) ;
  Done := (FIO.IOresult()=0) ;
END WriteCard ;

PROCEDURE WriteInt    ( v : INTEGER ;       w : CARDINAL ) ;
BEGIN
  FIO.WrInt(OutputFile,v,INTEGER(w)) ;
  Done := (FIO.IOresult()=0) ;
END WriteInt ;

PROCEDURE WriteOct    ( v : CARDINAL ;      w : CARDINAL ) ;
VAR s : ARRAY[0..80] OF CHAR;
BEGIN
  Str.CardToStr( VAL( LONGCARD,v ),s,8,Done );
  IF Done THEN
    FIO.WrStrAdj(OutputFile,s,INTEGER(w) );
    Done := (FIO.IOresult()=0) ;
  END;
END WriteOct ;

PROCEDURE WriteHex    ( v : CARDINAL ;      w : CARDINAL ) ;
BEGIN
  FIO.WrHex(OutputFile,v,INTEGER(w)) ;
  Done := (FIO.IOresult()=0) ;
END WriteHex ;

BEGIN
  Done   := TRUE ;
  termCH := CHR(0) ;
  InputFile := FIO.StandardInput ;
  OutputFile := FIO.StandardOutput ;
  FIO.IOcheck := FALSE ;
END InOut.
