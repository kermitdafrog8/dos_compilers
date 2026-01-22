(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  IO.MOD - Terminal input/output                                          *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*# data(seg_name => null) *)
(*%E *)
(*# module(implementation=>off) *)
(*# call(o_a_copy => off) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE IO;

(*%F _OS2 *)
IMPORT Lib, Str, SYSTEM, CoreIO, CoreSig;
(*%E *)
(*%T _OS2 *)
IMPORT Str,Dos,Vio,Kbd,Lib,CoreIO,CoreSig;
(*%E *)
(*%T _mthread *)
IMPORT Process, CoreProc;
(*%E *)
CONST
  TrueStr = 'TRUE';
  ConStr  = 'CON';

VAR
  VIOoutput : BOOLEAN;
  LWW     : BOOLEAN;
  Buffer  : ARRAY[0..MaxRdLength-1] OF CHAR;
  s,e     : CARDINAL;
(*%T _mthread *)
   OKTable:  ARRAY [1..Process.MaxProcess] OF BOOLEAN;
(*%E *)

TYPE
  Str80   = ARRAY[0..79] OF CHAR;
  PathStr = Str80;

(*%F _OS2 *)
PROCEDURE KeyPressed (): BOOLEAN;
VAR R : SYSTEM.Registers;
BEGIN
  WITH R DO
    AH := 0BH;
    Lib.Dos(R);
    RETURN AL=0FFH;
  END;
END KeyPressed;

PROCEDURE TerminalRdStr(VAR string: ARRAY OF CHAR);
VAR
  R : SYSTEM.Registers;
  H : CARDINAL;
  I : CARDINAL;
  InputBuffer : RECORD
                  LenBuf : CHAR;
                  Len    : CHAR;
                  Buf    : ARRAY[0..81] OF CHAR;
                END;
BEGIN
  IF Prompt AND NOT LWW THEN WrStr('?'); END;
  LWW := FALSE;
  H := HIGH(string);
  IF H > 80 THEN
    InputBuffer.LenBuf := CHR(82);
  ELSE
    InputBuffer.LenBuf := CHR(H+2);
  END;
  InputBuffer.Len := CHR(0);
  WITH R DO
    DS := Seg(InputBuffer);
    DX := Ofs(InputBuffer);
    AH := 0AH;
    Lib.Dos(R);
  END;
  I := ORD(InputBuffer.Len);
  IF I <= H  THEN
    string[I] := CHR(0);
  END;
  WHILE (I>0) DO
    DEC(I);
    string[I] := InputBuffer.Buf[I];
  END;
  WrLn;
END TerminalRdStr;
(*%E *)

PROCEDURE GetName(name: ARRAY OF CHAR; VAR fn: PathStr);
(* Makes Null terminated filename, also sets IOR to 0 *)
BEGIN
  Str.Copy(fn,name);
  fn[HIGH(fn)] := CHR(0);
END GetName;


(*%T _OS2 *)

VAR tchar : CHAR;

PROCEDURE KeyPressed():BOOLEAN;
VAR r : CARDINAL; k : Kbd.KEYINFO;
BEGIN
  k.char := 0C;
  k.scan := 0;
  k.nlsShift := 0;
  r := Kbd.Peek(k,0);
  RETURN (tchar#0C) OR (k.scan#0) OR (k.char#0C);
END KeyPressed;

PROCEDURE FileRdStr(VAR string: ARRAY OF CHAR);
VAR
  NumRead: CARDINAL;
BEGIN
  IF Dos.Read(0, FarADR(string), HIGH(string), NumRead) # 0 THEN END;
  string[NumRead] := CHR(0);
END FileRdStr;

PROCEDURE TerminalRdStr(VAR string: ARRAY OF CHAR);
VAR l  : Kbd.STRINGINBUF;
    r  : CARDINAL;
BEGIN
  IF Prompt AND NOT LWW THEN WrStr('?'); END;
  LWW := FALSE;
  IF NOT InputRedirected THEN
    l.b := HIGH(string);
    r := Kbd.StringIn( string,l,0,0);
    IF l.chIn < l.b THEN
       string[l.chIn]:= 0C;
    END;
    WrLn;
  ELSE
    FileRdStr(string);
  END;
END TerminalRdStr;
(*%E *)


(*%T _mthread *)
PROCEDURE SetThreadOK( b : BOOLEAN);

BEGIN
  OKTable[CoreProc._getTID()] := b;
END SetThreadOK;
(*%E *)



PROCEDURE WrStr(s: ARRAY OF CHAR);
BEGIN
  WrStrRedirect(s);
END WrStr;

PROCEDURE RdStr ( VAR s : ARRAY OF CHAR );
BEGIN
  RdStrRedirect(s);
END RdStr;


PROCEDURE RdBuff;
VAR
  p,h : CARDINAL;
BEGIN
  RdStrRedirect(Buffer);
  p := Str.Length(Buffer);
  h := SIZE(Buffer)-1;
  IF p>h-1 THEN p := h-1; END;
  Buffer[p] := CHR(13); INC(p);
  Buffer[p] := CHR(10); INC(p);
  IF p<=h THEN Buffer[p] := CHR(0) END;
  e := p; s := 0;
END RdBuff;

(*%F _OS2 *)
PROCEDURE TerminalWrStr(string: ARRAY OF CHAR);
VAR R : SYSTEM.Registers;
BEGIN
  LWW := TRUE;
  WITH R DO
    BX := 1;
    AH := 40H;
    DS := Seg( string );
    DX := Ofs( string );
    CX := Str.Length(string);
    Lib.Dos( R );
  END;
END TerminalWrStr;

PROCEDURE RdKey() : CHAR;
VAR R : SYSTEM.Registers;
BEGIN
  WITH R DO
    AH := 8;
    Lib.Dos(R);
    IF AL=0E0H THEN AL := 0 END;
    RETURN CHR(AL);
  END;
END RdKey;
(*%E *)

(*%T _OS2 *)
PROCEDURE TerminalWrStr(string: ARRAY OF CHAR);
VAR r : CARDINAL;
    n : CARDINAL ;
BEGIN
  LWW := TRUE;
  IF (VIOoutput) AND (NOT OutputRedirected) THEN
    r := Vio.WrtTTY(string,Str.Length(string),0);
  ELSE
    r := Dos.Write(1,FarADR(string),Str.Length(string),n);
  END ;
END TerminalWrStr;


PROCEDURE RdKey() : CHAR;
VAR k : Kbd.KEYINFO; r : CARDINAL; c:CHAR;
BEGIN
  IF (tchar#0C) THEN
     c := tchar;
     tchar:=0C;
     RETURN c;
  ELSE
    r := Kbd.CharIn( k,0,0 );
    IF (k.char=0C) OR (k.char=CHR(0E0H)) THEN
       tchar := CHAR(k.scan);
       k.char := 0C;
    END;
    RETURN (k.char);
  END;
END RdKey;
(*%E *)

(*# save,
    call(o_a_copy => on) *)

PROCEDURE WrStrAdj( S : ARRAY OF CHAR; Length : INTEGER );
VAR
  L : CARDINAL;
  a : INTEGER;
BEGIN
  OK := TRUE;
(*%T _mthread *)
  SetThreadOK(TRUE);
(*%E *)
  IF RdLnOnWr  THEN RdLn; END;
  L := Str.Length( S );
  a := ABS( Length ) - INTEGER( L );
  IF (a < 0) AND ChopOff THEN
    L := CARDINAL(ABS(Length));
    IF L<=HIGH(S) THEN S[L] := CHR(0); END;
    WHILE (L>0) DO DEC(L); S[L] := '?'; END;
    OK := FALSE;
(*%T _mthread *)
    SetThreadOK(FALSE);
(*%E *)
    a  := 0;
  END;
  IF (Length > 0) AND (a > 0) THEN WrCharRep( PrefixChar,a ); END;
  WrStr( S );
  IF (Length < 0) AND (a > 0) THEN WrCharRep( SuffixChar,a ); END;
END WrStrAdj;

(*# restore *)

PROCEDURE WrChar( V: CHAR );
BEGIN
  IF RdLnOnWr THEN RdLn; END;
  WrStr( V );
END WrChar;

PROCEDURE WrCharRep(V: CHAR; count: CARDINAL);
VAR
  s   : Str80;
  i,j : CARDINAL;
BEGIN
  IF RdLnOnWr THEN RdLn; END;
  WHILE count>0 DO
    i := SIZE(s)-2;
    IF i>count THEN i := count END;
    DEC(count,i);
    j := 0;
    WHILE (j<i) DO s[j] := V; INC(j) END;
    s[j] := CHR(0);
    WrStr(s);
  END;
END WrCharRep;

PROCEDURE WrBool(V: BOOLEAN; Length: INTEGER);
BEGIN
  IF V THEN
    WrStrAdj(TrueStr,Length);
  ELSE
    WrStrAdj('FALSE',Length);
  END;
END WrBool;

PROCEDURE WrShtInt(V: SHORTINT; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.IntToStr( LONGINT(V),S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrShtInt;

PROCEDURE WrInt(V: INTEGER; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.IntToStr( LONGINT(V),S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrInt;

PROCEDURE WrLngInt(V: LONGINT; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.IntToStr( V,S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrLngInt;

PROCEDURE WrShtCard(V: SHORTCARD; Length: INTEGER);
VAR S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(LONGCARD(V),S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrShtCard;

PROCEDURE WrCard(V: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(LONGCARD(V),S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrCard;

PROCEDURE WrLngCard(V: LONGCARD; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(V,S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrLngCard;

PROCEDURE WrShtHex(V: SHORTCARD; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(LONGCARD(V),S,16,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrShtHex;

PROCEDURE WrHex(V: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(LONGCARD(V),S,16,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrHex;

PROCEDURE WrLngHex(V: LONGCARD; Length: INTEGER);
VAR S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(V,S,16,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrLngHex;

PROCEDURE WrReal(V: REAL; Precision: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.RealToStr( LONGREAL ( V ),Precision,Eng,S,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrReal;

PROCEDURE WrFixReal(V: REAL; Precision: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.FixRealToStr( LONGREAL ( V ),Precision,S,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrFixReal;

PROCEDURE WrLngReal(V : LONGREAL; Precision: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.RealToStr( V,Precision,Eng,S,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrLngReal;

PROCEDURE WrFixLngReal(V: LONGREAL; Precision: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.FixRealToStr(V,Precision,S,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(S,Length );
  END;
  OK := b;
END WrFixLngReal;

PROCEDURE WrLn;
TYPE
  a3 = ARRAY [0..1] OF CHAR;
CONST
  crlf = a3(CHR(13),CHR(10));
BEGIN
  IF RdLnOnWr THEN RdLn; END;
  WrStr( crlf );
  LWW := FALSE;
END WrLn;

PROCEDURE RdBool() : BOOLEAN;
VAR s : Str80;
BEGIN
  RdItem( s );
  RETURN Str.Compare( s,TrueStr )=0;
END RdBool;

PROCEDURE RdShtInt() : SHORTINT;
VAR
  S : Str80;
  i : LONGINT;
  b : BOOLEAN;
BEGIN
  RdItem(S );
  i  := Str.StrToInt( S,10,b );
(*%T _mthread *)
  SetThreadOK(b AND (i >= -80H) AND (i < 80H));
(*%E *)
  OK := b AND (i >= -80H) AND (i < 80H);
  RETURN SHORTINT( i );
END RdShtInt;

PROCEDURE RdInt() : INTEGER;
VAR
  S : Str80;
  i : LONGINT;
  b : BOOLEAN;
BEGIN
  RdItem(S);
  i  := Str.StrToInt( S,10,b );
(*%T _mthread *)
  SetThreadOK(b AND (i >= -8000H) AND (i < 8000H));
(*%E *)
  OK := b AND (i >= -8000H) AND (i < 8000H);
  RETURN INTEGER(i);
END RdInt;

PROCEDURE RdLngInt() : LONGINT;
VAR
  S : Str80;
  i : LONGINT;
  b : BOOLEAN;
BEGIN
  RdItem(S);
  i  := Str.StrToInt( S,10,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  OK := b;
  RETURN i;
END RdLngInt;

PROCEDURE RdShtCard() : SHORTCARD;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(S);
  i  := Str.StrToCard( S,10,b );
(*%T _mthread *)
  SetThreadOK(b AND (i < 100H));
(*%E *)
  OK := b AND (i < 100H);
  RETURN SHORTCARD( i );
END RdShtCard;

PROCEDURE RdShtHex() : SHORTCARD;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(S);
  i  := Str.StrToCard( S,16,b );
(*%T _mthread *)
  SetThreadOK(b AND (i < 100H));
(*%E *)
  OK := b AND (i < 100H);
  RETURN SHORTCARD( i );
END RdShtHex;

PROCEDURE RdCard() : CARDINAL;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(S);
  i  := Str.StrToCard( S,10,b );
(*%T _mthread *)
  SetThreadOK(b AND (i < 10000H));
(*%E *)
  OK := b AND (i < 10000H);
  RETURN CARDINAL( i );
END RdCard;

PROCEDURE RdHex() : CARDINAL;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(S);
  i  := Str.StrToCard( S,16,b );
(*%T _mthread *)
  SetThreadOK(b AND (i < 10000H));
(*%E *)
  OK := b AND (i < 10000H);
  RETURN CARDINAL( i );
END RdHex;

PROCEDURE RdLngCard() : LONGCARD;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(S);
  i  := Str.StrToCard( S,10,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  OK := b;
  RETURN i;
END RdLngCard;

PROCEDURE RdLngHex() : LONGCARD;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(S);
  i  := Str.StrToCard( S,16,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  OK := b;
  RETURN i;
END RdLngHex ;

PROCEDURE RdReal() : REAL;
VAR
  S   : Str80;
  r   : LONGREAL;
  b : BOOLEAN;
BEGIN
  RdItem(S );
  r  := Str.StrToReal( S,b);
(*%T _mthread *)
  SetThreadOK(b AND (ABS(r) <= 3.4E38 ));
(*%E *)
  OK := b AND (ABS(r) <= 3.4E38 );
  RETURN REAL ( r );
END RdReal;

PROCEDURE RdLngReal() : LONGREAL;
VAR
  S : Str80;
  r : LONGREAL;
  b : BOOLEAN;
BEGIN
  RdItem(S);
  r  := Str.StrToReal( S,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  OK := b;
  RETURN r;
END RdLngReal;


PROCEDURE RdLn;
BEGIN
  s:=e;
END RdLn;

PROCEDURE EndOfRd(Skip: BOOLEAN) : BOOLEAN;
BEGIN
  IF Skip THEN
     WHILE (s < e) AND (Buffer[s] IN Separators) DO INC(s) END;
  END;
  RETURN s = e;
END EndOfRd;

PROCEDURE RdItem(VAR V: ARRAY OF CHAR);
VAR L,i : CARDINAL;
BEGIN
  OK := TRUE;
(*%T _mthread *)
  SetThreadOK(TRUE);
(*%E *)
  L := HIGH(V);
  REPEAT
    IF s=e THEN RdBuff(); END;
    WHILE (s<e) AND ( Buffer[s] IN Separators ) DO INC(s); END;
    i := 0;
    WHILE (s<e) AND (i<=L) AND NOT ( Buffer[s] IN Separators )  DO
      V[i] := Buffer[s];
      INC(s);
      INC(i);
    END;
    IF i <= L THEN V[i] := CHR(0); END;
  UNTIL V[0] # CHR(0);
END RdItem;

PROCEDURE RdChar() : CHAR;
VAR
  c : CHAR;
  t : BOOLEAN;
BEGIN
  IF s >= e THEN RdBuff; END;
  INC (s);
  RETURN Buffer[s-1];
END RdChar;

(*%F _OS2 *)
PROCEDURE RedirectInput(FileName: ARRAY OF CHAR);
VAR c : CARDINAL;
    r : SYSTEM.Registers;
    fn: PathStr;
BEGIN
  GetName(FileName,fn);
  WITH r DO
    BX := 0;
    AH := 3EH; (* close file *)
    Lib.Dos(r);
    DS := Seg(fn);
    DX := Ofs(fn);
    CX := 0;
    AX := 3D00H;   (* open for read *)
    Lib.Dos(r);
  END;
  InputRedirected := (Str.Compare(fn,ConStr) # 0);
END RedirectInput;

PROCEDURE RedirectOutput(FileName: ARRAY OF CHAR);
VAR c : CARDINAL;
    r : SYSTEM.Registers;
    fn: PathStr;
BEGIN
  GetName(FileName,fn);
  WITH r DO
    BX := 1;
    AH := 3EH; (* close file *)
    Lib.Dos(r);
    DS := Seg(fn);
    DX := Ofs(fn);
    CX := 0;
    AX := 3C00H;   (* Create *)
    Lib.Dos(r);
  END ;
  OutputRedirected := (Str.Compare(fn,ConStr) # 0);
END RedirectOutput;
(*%E *)

(*%T _OS2 *)
PROCEDURE RedirectInput(FileName: ARRAY OF CHAR);
VAR
  InputHandle, NewHandle: CARDINAL;
  ErrMsg: ARRAY [0..99] OF CHAR;
  fn: PathStr;
BEGIN
  GetName(FileName,fn);
  InputHandle := 0;
  NewHandle := CoreIO._os2_open(fn, CARDINAL(CoreIO.O_RDONLY), 1, 1);
  IF NewHandle = MAX(CARDINAL) THEN
    Str.Concat(ErrMsg,'RedirectInput: ',fn);
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 0BEH, ErrMsg);
  END;
  Dos.DupHandle(NewHandle, InputHandle);
  Dos.Close(NewHandle);
  InputRedirected := (Str.Compare(fn,ConStr) # 0);
END RedirectInput;

PROCEDURE RedirectOutput(FileName: ARRAY OF CHAR);
VAR
  OutputHandle, NewHandle: CARDINAL;
  ErrMsg: ARRAY [0..99] OF CHAR;
  fn: PathStr;
BEGIN
  GetName(FileName,fn);
  OutputHandle := 1;
  NewHandle := CoreIO._os2_open(FileName, CARDINAL(CoreIO.O_RDWR), 0, 12H);
  IF NewHandle = MAX(CARDINAL) THEN
    Str.Concat(ErrMsg,'RedirectOutput: ',fn);
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 0BFH, ErrMsg);
  END;
  Dos.DupHandle(NewHandle, OutputHandle);
  Dos.Close(NewHandle);
  OutputRedirected := (Str.Compare(fn,ConStr) # 0);
END RedirectOutput;
(*%E *)

PROCEDURE ThreadOK(): BOOLEAN;

BEGIN
(*%T _mthread *)
  RETURN OKTable[CoreProc._getTID()];
(*%E *)
(*%F _mthread *)
  RETURN OK;
(*%E *)
END ThreadOK;

(*%T _mthread *)
VAR
  n : [1..Process.MaxProcess];
(*%E *)
BEGIN
(*%T _mthread *)
  n := 1;
  WHILE  n <= Process.MaxProcess DO
    OKTable[n]  := TRUE;
    INC(n);
  END;
(*%E *)
(*%F _OS2 *)
  Prompt        := TRUE;
  RdLnOnWr      := FALSE;
  WrStrRedirect := TerminalWrStr;
  RdStrRedirect := TerminalRdStr;
  s             := e;
  OK            := TRUE;
  ChopOff       := FALSE;
  Separators    := CHARSET{CHR(9),CHR(10),CHR(13),CHR(26),' '};
  Eng           := FALSE;
  LWW           := FALSE;
  InputRedirected := FALSE;
  OutputRedirected := FALSE;
  PrefixChar    := ' ';
  SuffixChar    := ' ';
(*%E *)

(*%T _OS2 *)
  Prompt        := FALSE;
  RdLnOnWr      := FALSE;
  VIOoutput     := FALSE;
  InputRedirected  := FALSE;
  OutputRedirected  := FALSE;
  WrStrRedirect := TerminalWrStr;
  RdStrRedirect := TerminalRdStr;
  s             := e;
  OK            := TRUE;
  ChopOff       := FALSE;
  Separators    := CHARSET{CHR(9),CHR(10),CHR(13),CHR(26),' '};
  Eng           := FALSE;
  LWW           := FALSE;
  tchar         := 0C;
  InputRedirected := FALSE;
  OutputRedirected := FALSE;
  PrefixChar    := ' ';
  SuffixChar    := ' ';
(*%E *)
END IO.
