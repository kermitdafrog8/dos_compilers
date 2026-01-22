(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  FIO.MOD - File input/output                                             *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*# data(seg_name => null) *)
(*%E *)
(*# call(o_a_copy => off) *)
(*# check(stack=>off,index=>off,range=>off,overflow=>off,nil_ptr=>off) *)

IMPLEMENTATION MODULE FIO;

IMPORT CoreFile,CoreIO,CoreMain,CoreSig,Lib,Str,SYSTEM;
(*%T _OS2 *)
IMPORT Dos,Err;

FROM Dos IMPORT QCurDisk, FindFirst, FindNext;
(*%E *)

(*%T _mthread *)
IMPORT Process, CoreProc;
(*%E *)
CONST
  TrueStr   = 'TRUE';

VAR
(*  CoreFile.BufInf : ARRAY[0..MaxHandle] OF FileInf; *) (* NB in CoreFile *)
(*%T _mthread *)
   IOR: ARRAY [1..Process.MaxProcess] OF CARDINAL;
   OKTable:  ARRAY [1..Process.MaxProcess] OF BOOLEAN;
   EOFTable: ARRAY [1..Process.MaxProcess] OF BOOLEAN;
(*%E *)
(*%F _mthread *)
   IOR: CARDINAL;
(*%E *)
TYPE
  Str80 = ARRAY[0..79] OF CHAR;

(*%T _mthread *)
PROCEDURE SetIOR(Num: CARDINAL);

BEGIN
  IOR[CoreProc._getTID()] := Num;
END SetIOR;

PROCEDURE SetThreadOK( b : BOOLEAN);

BEGIN
  OKTable[CoreProc._getTID()] := b;
END SetThreadOK;

PROCEDURE SetThreadEOF( b : BOOLEAN);

BEGIN
  EOFTable[CoreProc._getTID()] := b;
END SetThreadEOF;



(*%E *)



PROCEDURE ErrorCheck(Code: CARDINAL; ErrNum: CARDINAL; Msg, Name: ARRAY OF CHAR);

VAR
    ErrMsg: ARRAY [0..119] OF CHAR;
    NumStr: ARRAY [0..19] OF CHAR;
    OK: BOOLEAN;
BEGIN
    IF ErrNum = 0 THEN
      ErrNum := Lib.SysErrno();
    END;
    IF IOcheck THEN
        Str.Copy(ErrMsg, Msg);
        Str.Append(ErrMsg, Name);
        Str.Append(ErrMsg, '. Dos Error Code ');
        Str.CardToStr(LONGCARD(ErrNum), NumStr, 10, OK);
        Str.Append(ErrMsg, NumStr);
(*      Lib.WrDosError(SHORTCARD(ErrNum)); *)
        Lib.RunTimeError(CoreSig._FatalErrorPos(), Code+0A0H, ErrMsg);
    END;
(*%T _mthread *)
    SetIOR(ErrNum);
(*%E *)
(*%F _mthread *)
    IOR := ErrNum;
(*%E *)
END ErrorCheck;

PROCEDURE IOresult () : CARDINAL;
BEGIN
(*%T _mthread *)
  RETURN IOR[CoreProc._getTID()];
(*%E *)
(*%F _mthread *)
  RETURN IOR;
(*%E *)
END IOresult;

(*%T _OS2 *)
(*%T _mthread *)
PROCEDURE StreamLock(F: FileInf);

VAR
  ThisThread: SHORTCARD;
BEGIN
  ThisThread := SHORTCARD(CoreProc._getTID());
  IF F^.Ctrl # ThisThread THEN
    IF Dos.SemRequest(ADR(F^.Sem), -1) # 0 THEN ErrorCheck(18H, 0, 'StreamLock : ', Lib.NilStr) END;
    F^.Ctrl := ThisThread;
  END;
  INC(F^.SCnt);
END StreamLock;

PROCEDURE StreamUnlock(F: FileInf);

BEGIN
  DEC(F^.SCnt);
  IF F^.SCnt = 0 THEN
    IF Dos.SemClear(ADR(F^.Sem)) # 0 THEN ErrorCheck(19H, 0, 'StreamUnlock : ', Lib.NilStr) END;
    F^.Ctrl := 0;
  END;
END StreamUnlock;

(*%E *)

(*%E *)

  PROCEDURE FlsBuf(F: FileInf): INTEGER;
    VAR
      Wnum              : CARDINAL;
      nr,sr             : INTEGER;
      Pos               : LONGINT;
      zbuf              : ARRAY [0..127] OF CHAR;
    BEGIN
      WITH F^ DO
        IF (Flag = {}) OR ((Flag * (CoreIO._F_ERR + CoreIO._F_EOF + CoreIO._F_IN)) # {}) THEN
          RETURN -1;
        END; (*IF*)
        IF (Flag >= CoreIO._F_RST) THEN          (* set up reset buffer for output *)
          Flag := Flag - CoreIO._F_RST;
          Flag := Flag + CoreIO._F_OUT;
          Cnt := Size;
          Ptr := Base;
          RETURN 1;                           (* return - buffer wasn't full *)
        END; (*IF*)
        IF Cnt < 0 THEN
          Cnt := 0;
        END; (*IF*)
        Wnum := Size - Cnt;
        IF Wnum = 0 THEN
          RETURN 0;
        END; (*IF*)
        IF (Flag >= CoreIO._F_APP) THEN
          Pos := CoreIO.lseek(Handle,-128,CoreIO.SEEK_END);      (* append *)
          IF Pos < 0 THEN
            CoreIO.lseek(Handle,0,CoreIO.SEEK_SET);
          END; (*IF*)
          nr := CoreIO._read(Handle,ADR(zbuf),128);
          sr := nr;
          IF nr = -1 THEN
            RETURN -1;
          END; (*IF*)
          REPEAT
            DEC(sr);
          UNTIL (sr < 0) OR (zbuf[sr] # 26C);
          Pos := LONGINT(sr) - LONGINT(nr) + 1;
          CoreIO.lseek(Handle,Pos,CoreIO.SEEK_END);   (* append after first cltZ *)
        END; (*IF*)
        IF CoreIO._write(Handle,Base,Wnum) # INTEGER(Wnum) THEN
          Flag := Flag + CoreIO._F_ERR;
          Cnt := 0;
          RETURN -1;
        END; (*IF*)
        Cnt := Size;                       (* set buffer pointers *)
        Ptr := Base;
        Flag := Flag + CoreIO._F_OUT;         (* set output flag *)
        RETURN Wnum;
      END; (*WITH*)
    END FlsBuf;

PROCEDURE FilBuf(F: FileInf): INTEGER;

VAR
  NumRead: INTEGER;
BEGIN
  WITH F^ DO
    IF (Flag = {}) OR ((Flag * (CoreIO._F_ERR  + CoreIO._F_OUT)) # {}) THEN
        RETURN -1;
    END;
    IF (Flag >= CoreIO._F_EOF) THEN
        RETURN 0;
    END;
    IF (Flag >= CoreIO._F_RST) THEN
      Flag := Flag - CoreIO._F_RST;
    END;
    NumRead := CoreIO._read(Handle, Base, Size);
    Ptr := Base;
    IF (NumRead = -1) AND (NumRead # Size) THEN
      Flag := Flag + CoreIO._F_ERR;
      Cnt := 0;
      RETURN -1;
    END;
    Cnt := NumRead;                   (* reset pointers *)
    Flag := Flag + CoreIO._F_IN;         (* set input flag *)
    IF NumRead = 0 THEN
      Flag := Flag + CoreIO._F_EOF;      (* end of file *)
(*%T _mthread *)
      SetThreadEOF(TRUE);
(*%E *)
      EOF := TRUE;
      RETURN 0;
    END;
    RETURN NumRead;
  END;
END FilBuf;

  PROCEDURE WrBin(F:File;Buf:ARRAY OF BYTE;Count:CARDINAL);
    VAR
      NumWrit           : INTEGER;
      NumToWrite        : INTEGER;
      NumLeft           : CARDINAL;
      ST                : POINTER TO CoreFile.CStream;
      Buffer            : CoreFile.StreamPtr;
    BEGIN
(*%T _mthread *)
      SetIOR(0);
      SetThreadOK(TRUE);
(*%E *)
(*%F _mthread *)
      IOR := 0;
(*%E *)
      OK := TRUE;
      NumWrit := 0;
      IF Count # 0 THEN
        IF (F <= CoreFile._open_max) & (CoreFile.BufInf[F] # NIL) THEN
          WITH CoreFile.BufInf[F]^ DO
            IF (Flag = {}) OR ((Flag * (CoreIO._F_ERR + CoreIO._F_EOF)) # {}) THEN
              ErrorCheck(6, CoreIO.EBADF, 'WrBin : ', Lib.NilStr);
(*%T _mthread *)
              SetThreadOK(FALSE);
(*%E *)
              OK := FALSE;
              RETURN;
            END; (*IF*)
            IF ((Flag * CoreIO._F_WRIT) = {}) OR (Flag >= CoreIO._F_IN) THEN
              Flag := Flag + CoreIO._F_ERR;
              ErrorCheck(6, CoreIO.EACCES, 'WrBin : ', Lib.NilStr);
(*%T _mthread *)
              SetThreadOK(FALSE);
(*%E *)
              OK := FALSE;
              RETURN;
            END;
(*%T _mthread *)
(*%F _OS2 *)
            Process.Lock();
(*%E *)
(*%T _OS2 *)
            StreamLock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
            Flag := Flag + CoreIO._F_OUT;
            IF Flag * CoreIO._F_RST # {} THEN
              IF FlsBuf(CoreFile.BufInf[F]) <= 0 THEN
                ErrorCheck(6, 0, 'WrBin : ', Lib.NilStr);
(*%T _mthread *)
                SetThreadOK(FALSE);
(*%E *)
                OK := FALSE;
(*%T _mthread *)
(*%F _OS2 *)
                Process.Unlock();
(*%E *)
(*%T _OS2 *)
                StreamUnlock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
                RETURN;
              END; (*IF*)
            END; (*IF*)
            NumLeft := Count;
            Buffer  := CoreFile.StreamPtr(ADR(Buf));
            LOOP
              IF(CARDINAL(Cnt) >= NumLeft) THEN  (* write entire item *)
                NumToWrite := INTEGER(NumLeft);
              ELSE
                NumToWrite := Cnt;               (* write entire buffer *)
              END; (*IF*)
              IF NumToWrite > 0 THEN
                Lib.Move(Buffer,Ptr,NumToWrite);
                DEC(Cnt,NumToWrite);
                INC(CARDINAL(Buffer),NumToWrite);
                INC(CARDINAL(Ptr),NumToWrite);
                DEC(NumLeft,CARDINAL(NumToWrite));
                INC(NumWrit,NumToWrite);
              END; (*IF*)
              IF (Cnt = 0) & (FlsBuf(CoreFile.BufInf[F]) <= 0) THEN  (* flush full buffer *)
                EXIT;             (* error or EOF *)
              END; (*IF*)
              IF NumLeft = 0 THEN
                EXIT;
              END; (*IF*)
            END; (*LOOP*)
            IF (Flag >= CoreIO._F_LBUF) & (FlsBuf(CoreFile.BufInf[F]) < 0) THEN
              ErrorCheck(6, 0, 'WrBin : ', Lib.NilStr);
(*%T _mthread *)
              SetThreadOK(FALSE);
(*%E *)
              OK := FALSE;
            END; (*IF*)
          END; (*WITH*)
(*%T _mthread *)
(*%F _OS2 *)
          Process.Unlock();
(*%E *)
(*%T _OS2 *)
          StreamUnlock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
        ELSE
(*%T _mthread *)
(*%F _OS2 *)
          Process.Lock();
(*%E *)
(*%E *)
          IF CoreFile._openfd[F] >= CoreIO.O_APPEND THEN
            CoreIO.lseek(F, 0, CoreIO.SEEK_END);
          END; (*IF*)
          NumWrit := CoreIO._write(F,CoreFile.StreamPtr(ADR(Buf)),Count);
(*%T _mthread *)
(*%F _OS2 *)
          Process.Unlock();
(*%E *)
(*%E *)
        END; (*IF*)
        IF CARDINAL(NumWrit) # Count THEN
          ErrorCheck(6, CoreIO.EDISKFUL, 'WrBin : ', Lib.NilStr);
          OK := FALSE;
(*%T _mthread *)
          SetThreadOK(FALSE);
(*%E *)
        END; (*IF*)
      END; (*IF*)
    END WrBin;

PROCEDURE Flush(F: File);

VAR
  ret: INTEGER;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  IF (F > CoreFile._open_max) OR (CoreFile.BufInf[F] = NIL) THEN RETURN END;
  WITH CoreFile.BufInf[F]^ DO
    IF (Flag = {}) OR ((Flag * (CoreIO._F_ERR + CoreIO._F_EOF)) # {}) THEN
        RETURN;
    END;
(*%T _mthread *)
(*%F _OS2 *)
      Process.Lock();
(*%E *)
(*%T _OS2 *)
      StreamLock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
    IF (Flag >= CoreIO._F_OUT) THEN
        ret :=FlsBuf(CoreFile.BufInf[F]);       (* flush output buffer *)
        IF ret < 0 THEN
            ErrorCheck(8, 0, 'Flush : ', Lib.NilStr);
        END;
    ELSIF (Flag * CoreIO._F_DEV = {}) THEN
      Seek(F, GetPos(F));
    END;
    WITH CoreFile.BufInf[F]^ DO
      Pback := 0;                        (* reset buffer *)
      Cnt   := 0;
      Flag  := Flag + CoreIO._F_RST;
      Flag  := Flag - (CoreIO._F_OUT + CoreIO._F_IN);
    END;
(*%T _mthread *)
(*%F _OS2 *)
      Process.Unlock();
(*%E *)
(*%T _OS2 *)
      StreamUnlock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
  END;
  RETURN;
END Flush;

(*%F _OS2 *)
PROCEDURE Truncate(F: File);

BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
(*%T _mthread *)
  Process.Lock();
(*%E *)
  Flush( F );
  IF CoreIO._write(F, NIL, 0) = -1 THEN
    ErrorCheck(0CH, 0, 'Truncate : ', Lib.NilStr);
  END;
(*%T _mthread *)
   Process.Unlock();
(*%E *)
END Truncate;
(*%E *)

(*%T _OS2 *)
PROCEDURE Truncate(F: File);
VAR IOR, r : CARDINAL; l : LONGCARD;
BEGIN
  Flush(F);
  IOR := Dos.ChgFilePtr(F,0,1,l);
  IF IOR = 0 THEN IOR := Dos.NewSize(F,l) END;
  IF IOR # 0 THEN ErrorCheck(0CH, IOR, 'Truncate : ', Lib.NilStr) END;
END Truncate;
(*%E *)


PROCEDURE RdBin(F: File; VAR Buf: ARRAY OF BYTE; Count: CARDINAL) : CARDINAL;
VAR
  NumRead : CARDINAL;
  NumToRead : CARDINAL;
  NumLeft : LONGCARD;
  Buffer : CoreFile.StreamPtr;
  Res : INTEGER;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  OK := TRUE;
(*%T _mthread *)
  SetThreadOK(TRUE);
  SetThreadEOF(FALSE);
(*%E *)
  EOF := FALSE;
  Res := 0;
  NumRead := 0;
  IF Count = 0 THEN RETURN 0 END;
  IF (F <= CoreFile._open_max) AND (CoreFile.BufInf[F] # NIL) THEN
    WITH CoreFile.BufInf[F]^ DO
      IF (Flag = {}) OR ((Flag * (CoreIO._F_ERR + CoreIO._F_EOF)) # {}) THEN
        ErrorCheck(7, CoreIO.EBADF, 'RdBin : ', Lib.NilStr);
        OK := FALSE;
(*%T _mthread *)
        SetThreadOK(FALSE);
(*%E *)
        RETURN MAX(CARDINAL);
      END;
      IF (Flag >= CoreIO._F_OUT) OR ((Flag * CoreIO._F_READ) = {} ) THEN
        Flag := Flag + CoreIO._F_ERR;
        ErrorCheck(7, CoreIO.EACCES, 'RdBin : ', Lib.NilStr);
        OK := FALSE;
(*%T _mthread *)
        SetThreadOK(FALSE);
(*%E *)
        RETURN MAX(CARDINAL);
      END;
(*%T _mthread *)
(*%F _OS2 *)
      Process.Lock();
(*%E *)
(*%T _OS2 *)
      StreamLock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
      Flag := Flag + CoreIO._F_IN;
      NumLeft := LONGCARD(Count);
      NumRead := 0;
      Buffer := CoreFile.StreamPtr(ADR(Buf));
      LOOP
        IF Cnt = 0 THEN        (* fill empty buffer *)
          Res := FilBuf(CoreFile.BufInf[F]);
          IF (INTEGER(Res) = -1)OR(Res = 0) THEN
            EXIT;              (* error or EOF *)
          END;
        END;
        IF(LONGCARD(Cnt) >= NumLeft) THEN (* read entire item *)
          NumToRead := CARDINAL(NumLeft);
        ELSE
          NumToRead := Cnt;    (* read entire buffer *)
        END;
        Lib.Move(Ptr, Buffer, NumToRead);
        DEC(Cnt,NumToRead);
        INC(CARDINAL(Buffer), NumToRead);
        INC(CARDINAL(Ptr), NumToRead);
        NumLeft := NumLeft - LONGCARD(NumToRead);
        INC(NumRead, NumToRead);
        IF NumLeft = 0 THEN EXIT END;
      END;
    END;
(*%T _mthread *)
(*%F _OS2 *)
    Process.Unlock();
(*%E *)
(*%T _OS2 *)
    StreamUnlock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
  ELSE
(*%T _mthread *)
(*%F _OS2 *)
      Process.Lock();
(*%E *)
(*%E *)
      NumRead := CoreIO._read(F, CoreFile.StreamPtr(ADR(Buf)), Count);
      IF NumRead=MAX(CARDINAL) THEN Res := -1 END;
(*%T _mthread *)
(*%F _OS2 *)
      Process.Unlock();
(*%E *)
(*%E *)
  END;
  IF NumRead # Count THEN
(*%T _mthread *)
      SetThreadOK(FALSE);
(*%E *)
      OK := FALSE;
      IF Res = -1 THEN
          ErrorCheck(7, 0, 'RbBin : ', Lib.NilStr);
          NumRead := 0;
      ELSE
(*%T _mthread *)
          SetThreadEOF(TRUE);
(*%E *)
          EOF := TRUE;
      END;
  END;
  RETURN NumRead;
END RdBin;


PROCEDURE WrStr(F: File; Buf: ARRAY OF CHAR);
BEGIN
  WrBin( F,Buf,Str.Length( Buf ) );
END WrStr;

PROCEDURE WrLn(F: File);
TYPE a = ARRAY [ 0..1 ] OF CHAR;
BEGIN
  WrBin( F, a( CHR( 13 ),CHR( 10 ) ), 2 )
END WrLn;

PROCEDURE RdChar(F: File ) : CHAR;
VAR c : CHAR;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  OK := TRUE;
(*%T _mthread *)
  SetThreadOK(TRUE);
(*%E *)
  IF (F <= CoreFile._open_max) AND (CoreFile.BufInf[F] # NIL) THEN
(*%T _mthread *)
(*%F _OS2 *)
    Process.Lock();
(*%E *)
(*%T _OS2 *)
    StreamLock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
    WITH CoreFile.BufInf[F]^ DO
      DEC(Cnt);
      IF Cnt < 0 THEN
        IF FilBuf(CoreFile.BufInf[F]) <= 0 THEN;
(*%T _mthread *)
          SetThreadEOF((Flag >= CoreIO._F_EOF));
(*%E *)
          EOF := (Flag >= CoreIO._F_EOF);
(*%T _mthread *)
          SetThreadOK(FALSE);
(*%E *)
          OK := FALSE;
(*%T _mthread *)
(*%F _OS2 *)
          Process.Unlock();
(*%E *)
(*%T _OS2 *)
          StreamUnlock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
          RETURN CHR(26);
        END;
        DEC(Cnt);
      END;
      c := Ptr^;
      INC(CARDINAL(Ptr), 1);
(*%T _mthread *)
      SetThreadEOF((Flag >= CoreIO._F_EOF) OR (c = CHR(26)));
(*%E *)
      EOF := ((Flag >= CoreIO._F_EOF) OR (c = CHR(26)));
(*%T _mthread *)
(*%F _OS2 *)
      Process.Unlock();
(*%E *)
(*%T _OS2 *)
      StreamUnlock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
      RETURN c;
    END;
  END;
(*%T _mthread *)
(*%F _OS2 *)
      Process.Lock();
(*%E *)
(*%E *)
  IF CoreIO._read(F, CoreFile.StreamPtr(ADR(c)), 1) <= 0 THEN
    OK := FALSE;
(*%T _mthread *)
    SetThreadOK(FALSE);
(*%E *)
    c  := CHR(26);
  END;
(*%T _mthread *)
  SetThreadEOF((c = CHR(26)));
(*%E *)
  EOF := (c = CHR(26));
(*%T _mthread *)
(*%F _OS2 *)
      Process.Unlock();
(*%E *)
(*%E *)
  RETURN c;
END RdChar;


PROCEDURE RdStr(F: File; VAR Buf: ARRAY OF CHAR);
VAR
  i,h : CARDINAL;
  c   : CHAR;
BEGIN
  i  := 0;
  h  := HIGH( Buf );
(*%T _mthread *)
  SetThreadOK(TRUE);
(*%E *)
  OK := TRUE;
  LOOP
     IF i > h THEN RETURN END;
     c := RdChar( F );
     IF c = CHR( 26 ) THEN
       Buf[ i ] := CHR(0);
(*%T _mthread *)
       SetThreadEOF((i = 0));
(*%E *)
       EOF := (i = 0);
       RETURN;
     ELSIF c = EOL THEN
       Buf[ i ] := CHR(0);
       RETURN;
     ELSIF (c # CHR( 10 )) AND (c # CHR( 13 )) THEN
       Buf[ i ] := c;
       INC( i );
     END;
  END;
END RdStr;

PROCEDURE RdItem( F : File; VAR S : ARRAY OF CHAR );
VAR c : CHAR; i,L : CARDINAL;
BEGIN
  i := 0;
  LOOP
    c := RdChar( F );
    IF NOT (*%T _mthread *) ThreadOK() (*%E *) (*%F _mthread *) OK (*%E *)
       OR NOT (c IN Separators) THEN EXIT; END;
  END;
  L := HIGH( S );
  LOOP
    IF NOT (*%T _mthread *) ThreadOK() (*%E *) (*%F _mthread *) OK (*%E *)
       OR ( c IN Separators ) THEN EXIT; END;
    S[i] := c;
    INC( i );
    IF i > L THEN
      EXIT;
    ELSE
      c := RdChar( F );
      IF c = CHR(26) THEN
(*%T _mthread *)
        SetThreadOK(TRUE);
(*%E *)
        OK := TRUE;
        EXIT;
      ELSIF c = CHR(13) THEN
        c := RdChar(F);
        EXIT;
      END;
    END;
  END;
  IF i <= L THEN S[i] := 0C; END;
END RdItem;

(*# save,
    call(o_a_copy => on) *)

PROCEDURE WrStrAdj(F: File; S: ARRAY OF CHAR; Length: INTEGER);
VAR
  L : CARDINAL;
  a : INTEGER;
BEGIN
(*%T _mthread *)
  SetThreadOK(TRUE);
(*%E *)
  OK := TRUE;
  L  := Str.Length( S );
  a  := ABS( Length ) - INTEGER( L );
  IF (a < 0) AND ChopOff THEN
    L := CARDINAL(ABS(Length));
    IF L>HIGH(S) THEN
      L := HIGH(S)+1;
    ELSE
      S[L] := CHR(0);
    END;
    WHILE (L>0) DO DEC(L) ; S[L] := '?'; END;
(*%T _mthread *)
    SetThreadOK(FALSE);
(*%E *)
    OK := FALSE;
    a  := 0;
  END;
  IF (Length > 0) AND (a > 0) THEN WrCharRep( F, PrefixChar, a ); END;
  WrStr( F,S );
  IF (Length < 0) AND (a > 0) THEN WrCharRep( F, SuffixChar, a ); END;
END WrStrAdj;

(*# restore *)

PROCEDURE WrChar(F: File; V: CHAR);
BEGIN
(*%T _mthread *)
  SetThreadOK(TRUE);
(*%E *)
  OK := TRUE;
  IF (F <= CoreFile._open_max) AND (CoreFile.BufInf[F] # NIL) THEN
(*%T _mthread *)
(*%F _OS2 *)
    Process.Lock();
(*%E *)
(*%T _OS2 *)
    StreamLock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
    WITH CoreFile.BufInf[F]^ DO
        DEC(Cnt);
        IF Cnt < 0 THEN
          IF FlsBuf(CoreFile.BufInf[F]) <= 0 THEN
(*%T _mthread *)
            SetThreadOK(FALSE);
(*%E *)
            OK := FALSE;
(*%T _mthread *)
(*%F _OS2 *)
      Process.Unlock();
(*%E *)
(*%T _OS2 *)
      StreamUnlock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
            RETURN;
          END;
          DEC(Cnt);
        END;
        Ptr^ := V;
        INC(CARDINAL(Ptr), 1);
        RETURN;
    END;
  END;
(*%T _mthread *)
(*%F _OS2 *)
  Process.Lock();
(*%E *)
(*%E *)
  IF CoreIO._write(F, CoreFile.StreamPtr(ADR(V)), 1) = 0 THEN
(*%T _mthread *)
    SetThreadOK(FALSE);
(*%E *)
    OK := FALSE;
  END;
(*%T _mthread *)
(*%F _OS2 *)
  Process.Unlock();
(*%E *)
(*%E *)
  RETURN;
END WrChar;

PROCEDURE WrCharRep(F: File; V: CHAR ; Count: CARDINAL);
VAR
  S   : Str80;
  i,j : CARDINAL;
BEGIN
  WHILE Count>0 DO
    i := SIZE(S);
    IF i > Count THEN i := Count END;
    DEC(Count,i);
    FOR j := 0 TO i-1 DO S[j] := V END;
    WrBin( F,S,i );
    IF NOT (*%T _mthread *) ThreadOK() (*%E *) (*%F _mthread *) OK (*%E *) THEN RETURN END ;
  END;
END WrCharRep;

PROCEDURE WrBool(F: File; V: BOOLEAN; Length: INTEGER);
BEGIN
  IF V THEN
    WrStrAdj( F,TrueStr,Length );
  ELSE
    WrStrAdj( F,'FALSE',Length );
  END;
END WrBool;

PROCEDURE WrShtInt(F: File; V: SHORTINT; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.IntToStr( LONGINT(V),S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrShtInt;

PROCEDURE WrInt(F: File; V: INTEGER; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.IntToStr( LONGINT(V),S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrInt;

PROCEDURE WrLngInt(F: File; V: LONGINT; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.IntToStr( V,S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrLngInt;

PROCEDURE WrShtCard(F: File; V: SHORTCARD; Length: INTEGER);
VAR S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(LONGCARD(V),S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrShtCard;

PROCEDURE WrCard(F: File; V: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(LONGCARD(V),S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrCard;

PROCEDURE WrLngCard(F: File; V: LONGCARD; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(V,S,10,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrLngCard;

PROCEDURE WrShtHex(F: File; V: SHORTCARD; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(LONGCARD(V),S,16,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrShtHex;

PROCEDURE WrHex(F: File; V: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(LONGCARD(V),S,16,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrHex;

PROCEDURE WrLngHex(F: File; V: LONGCARD; Length: INTEGER);
VAR S : Str80;
  b : BOOLEAN;
BEGIN
  Str.CardToStr(V,S,16,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrLngHex;

PROCEDURE WrReal(F: File; V: REAL; Precision: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.RealToStr( LONGREAL ( V ),Precision,Eng,S,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrReal;

PROCEDURE WrFixReal(F: File; V: REAL; Precision: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.FixRealToStr( LONGREAL ( V ),Precision,S,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrFixReal;

PROCEDURE WrLngReal(F: File; V : LONGREAL; Precision: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.RealToStr( V,Precision,Eng,S,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrLngReal;

PROCEDURE WrFixLngReal(F: File; V: LONGREAL; Precision: CARDINAL; Length: INTEGER);
VAR
  S : Str80;
  b : BOOLEAN;
BEGIN
  Str.FixRealToStr(V,Precision,S,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  IF b THEN
    WrStrAdj(F,S,Length );
  END;
  OK := b;
END WrFixLngReal;

PROCEDURE RdBool(F: File): BOOLEAN;
VAR s : Str80;
BEGIN
  RdItem( F,s );
  RETURN Str.Compare( s,TrueStr )=0;
END RdBool;

PROCEDURE RdShtInt(F: File) : SHORTINT;
VAR
  S : Str80;
  i : LONGINT;
  b : BOOLEAN;
BEGIN
  RdItem(F,S );
  i  := Str.StrToInt( S,10,b );
(*%T _mthread *)
  SetThreadOK(b AND (i >= -80H) AND (i < 80H));
(*%E *)
  OK := b AND (i >= -80H) AND (i < 80H);
  RETURN SHORTINT( i );
END RdShtInt;

PROCEDURE RdInt(F: File) : INTEGER;
VAR
  S : Str80;
  i : LONGINT;
  b : BOOLEAN;
BEGIN
  RdItem(F,S);
  i  := Str.StrToInt( S,10,b );
(*%T _mthread *)
  SetThreadOK(b AND (i >= -8000H) AND (i < 8000H));
(*%E *)
  OK := b AND (i >= -8000H) AND (i < 8000H);
  RETURN INTEGER(i);
END RdInt;

PROCEDURE RdLngInt(F: File) : LONGINT;
VAR
  S : Str80;
  i : LONGINT;
  b : BOOLEAN;
BEGIN
  RdItem(F,S);
  i  := Str.StrToInt( S,10,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  OK := b;
  RETURN i;
END RdLngInt;

PROCEDURE RdShtCard(F: File) : SHORTCARD;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(F,S);
  i  := Str.StrToCard( S,10,b );
(*%T _mthread *)
  SetThreadOK(b AND (i < 100H));
(*%E *)
  OK := b AND (i < 100H);
  RETURN SHORTCARD( i );
END RdShtCard;

PROCEDURE RdShtHex(F: File) : SHORTCARD;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(F,S);
  i  := Str.StrToCard( S,16,b );
(*%T _mthread *)
  SetThreadOK(b AND (i < 100H));
(*%E *)
  OK := b AND (i < 100H);
  RETURN SHORTCARD( i );
END RdShtHex;

PROCEDURE RdCard(F: File) : CARDINAL;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(F,S);
  i  := Str.StrToCard( S,10,b );
(*%T _mthread *)
  SetThreadOK(b AND (i < 10000H));
(*%E *)
  OK := b AND (i < 10000H);
  RETURN CARDINAL( i );
END RdCard;

PROCEDURE RdHex(F: File) : CARDINAL;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(F,S);
  i  := Str.StrToCard( S,16,b );
(*%T _mthread *)
  SetThreadOK(b AND (i < 10000H));
(*%E *)
  OK := b AND (i < 10000H);
  RETURN CARDINAL( i );
END RdHex;

PROCEDURE RdLngCard(F: File) : LONGCARD;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(F,S);
  i  := Str.StrToCard( S,10,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  OK := b;
  RETURN i;
END RdLngCard;

PROCEDURE RdLngHex(F: File) : LONGCARD;
VAR
  S : Str80;
  i : LONGCARD;
  b : BOOLEAN;
BEGIN
  RdItem(F,S);
  i  := Str.StrToCard( S,16,b );
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  OK := b;
  RETURN i;
END RdLngHex ;

PROCEDURE RdReal(F: File) : REAL;
VAR
  S   : Str80;
  r   : LONGREAL;
  b : BOOLEAN;
BEGIN
  RdItem(F,S );
  r  := Str.StrToReal( S,b);
(*%T _mthread *)
  SetThreadOK(b AND (ABS(r) <= 3.4E38 ));
(*%E *)
  OK := b AND (ABS(r) <= 3.4E38 );
  RETURN REAL ( r );
END RdReal;

PROCEDURE RdLngReal(F: File) : LONGREAL;
VAR
  S : Str80;
  r : LONGREAL;
  b : BOOLEAN;
BEGIN
  RdItem(F,S);
  r  := Str.StrToReal( S,b);
(*%T _mthread *)
  SetThreadOK(b);
(*%E *)
  OK := b;
  RETURN r;
END RdLngReal;


PROCEDURE GetName(name: ARRAY OF CHAR; VAR fn: PathStr);
(* Makes Null terminated filename, also sets IOR to 0 *)
BEGIN
  Str.Copy(fn,name);
  fn[HIGH(fn)] := CHR(0);
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
END GetName;

PROCEDURE Open(Name: ARRAY OF CHAR) : File;
VAR
  fn: PathStr;
  H: File;
BEGIN
  GetName(Name,fn);
(*%F _OS2 *)
  H := CoreIO._open(fn, CARDINAL(CoreIO.O_RDWR + ShareMode));
(*%E *)
(*%T _OS2 *)
  H := CoreIO._os2_open(fn, CARDINAL(CoreIO.O_RDWR + ShareMode), 0, 1);
(*%E *)
  IF H <> MAX(CARDINAL) THEN
    CoreFile._openfd[H] := (CoreIO.O_RDWR+CoreIO.O_BINARY);
    IF CoreIO.isatty(H) # 0 THEN
      CoreFile._openfd[H] := CoreFile._openfd[H] + CoreIO.O_DEVICE;
    END;
  ELSE
    ErrorCheck(2, 0, 'Open : ', fn);
  END;
  RETURN H;
END Open;

PROCEDURE OpenRead( Name: ARRAY OF CHAR) : File;
VAR
  fn: PathStr;
  H: File;
BEGIN
  GetName(Name,fn);
(*%F _OS2 *)
  H := CoreIO._open(fn, CARDINAL(CoreIO.O_RDONLY + ShareMode));
(*%E *)
(*%T _OS2 *)
  H := CoreIO._os2_open(fn, CARDINAL(CoreIO.O_RDONLY + ShareMode), 1, 1);
(*%E *)
  IF H <> MAX(CARDINAL) THEN
    CoreFile._openfd[H] := (CoreIO.O_RDONLY+CoreIO.O_BINARY);
    IF CoreIO.isatty(H) # 0 THEN
      CoreFile._openfd[H] := CoreFile._openfd[H] + CoreIO.O_DEVICE;
    END;
  ELSE
    ErrorCheck(3, 0, 'OpenRead : ', fn);
  END;
  RETURN H;
END OpenRead;

(*%F _OS2 *)
PROCEDURE Exists(Name: ARRAY OF CHAR) : BOOLEAN;
VAR
  r : SYSTEM.Registers ;
  fn: PathStr;
BEGIN
  GetName(Name,fn);
  r.AX := 4300H ;      (* get file attr *)
  r.DS := Seg(fn);
  r.DX := Ofs(fn);
  Lib.Dos(r);
  RETURN NOT(SYSTEM.CarryFlag IN r.Flags);
END Exists;
(*%E *)

(*%T _OS2 *)
PROCEDURE Exists(Name: ARRAY OF CHAR) : BOOLEAN;
VAR a : CARDINAL ;
    fn: PathStr;
BEGIN
  GetName(Name,fn);
  RETURN Dos.QFileMode(fn,a,0)=0;
END Exists;
(*%E *)


PROCEDURE Append(Name: ARRAY OF CHAR) : File;
VAR
  fn: PathStr;
  H: File;
BEGIN
  GetName(Name,fn);
(*%F _OS2 *)
  H := CoreIO._open(fn, CARDINAL(CoreIO.O_RDWR));
(*%E *)
(*%T _OS2 *)
  H := CoreIO._os2_open(fn, CARDINAL(CoreIO.O_RDWR), 0, 1H);
(*%E *)
  IF H <> MAX(CARDINAL) THEN
    CoreFile._openfd[H] := (CoreIO.O_RDWR+CoreIO.O_BINARY+CoreIO.O_APPEND);
    Seek(H, Size(H));
    IF CoreIO.isatty(H) # 0 THEN
      CoreFile._openfd[H] := CoreFile._openfd[H] + CoreIO.O_DEVICE;
    END;
  ELSE
    ErrorCheck(4, 0, 'Append : ', fn);
  END;
  RETURN H;
END Append;

PROCEDURE Create(Name: ARRAY OF CHAR) : File;
VAR
  fn: PathStr;
  H: File;
BEGIN
  GetName(Name,fn);
(*%F _OS2 *)
  H := CoreIO._creat_trunc(fn, 0);
(*%E *)
(*%T _OS2 *)
  H := CoreIO._os2_open(fn, CARDINAL(CoreIO.O_RDWR), 0, 12H);
(*%E *)
  IF H <> MAX(CARDINAL) THEN
    CoreFile._openfd[H] := (CoreIO.O_RDWR+CoreIO.O_BINARY);
  ELSE
    ErrorCheck(5, 0, 'Create : ', Name);
  END;
  RETURN H;
END Create;

PROCEDURE Close(F: File);
VAR
  x : FileInf;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  IF F <= CoreFile._open_max THEN
    IF CoreFile.BufInf[F] # NIL THEN
(*%T _mthread *)
(*%F _OS2 *)
      Process.Lock();
(*%E *)
(*%T _OS2 *)
     StreamLock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
      Flush( F );
      CoreFile.BufInf[F]^.Flag := {};
(*%T _mthread *)
(*%T _OS2 *)
      x := CoreFile.BufInf[F];
(*%E *)
(*%E *)
      CoreFile.BufInf[F] := NIL;
(*%T _mthread *)
(*%F _OS2 *)
      Process.Unlock();
(*%E *)
(*%T _OS2 *)
     StreamUnlock(x);
(*%E *)
(*%E *)
    END;
    CoreFile._openfd[F] := {};
  END;
  IF CoreIO._close(F) = -1 THEN
    ErrorCheck(0, 0, 'Close : ', Lib.NilStr);
  END;
  RETURN;
END Close;

PROCEDURE GetPos(F: File) : LONGCARD;
VAR
  Ret, Pos: LONGCARD;
BEGIN
(*%T _mthread *)
    SetIOR(0);
(*%E *)
(*%F _mthread *)
    IOR := 0;
(*%E *)
    OK := TRUE;
(*%T _mthread *)
    OKTable[CoreProc._getTID()] := TRUE;
(*%E *)
(*%T _mthread *)
(*%F _OS2 *)
    Process.Lock();
(*%E *)
(*%E *)
    IF (F > CoreFile._open_max) OR (CoreFile.BufInf[F] = NIL) OR (CoreFile.BufInf[F]^.Flag >= CoreIO._F_RST) THEN
      Ret := CoreIO.tell(F);
    ELSE
(*%T _mthread *)
(*%T _OS2 *)
      StreamLock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
      IF ( CoreFile.BufInf[F]^.Flag = {}) OR (CoreFile.BufInf[F]^.Flag >= CoreIO._F_ERR) THEN
        ErrorCheck(9, CoreIO.EBADF, 'GetPos : ', Lib.NilStr);
        Ret := MAX(LONGCARD);
      END;
      IF (CoreFile.BufInf[F]^.Flag >= CoreIO._F_OUT) THEN
        IF FlsBuf(CoreFile.BufInf[F]) # -1 THEN        (* flush stream  *)
          Ret := CoreIO.tell(F);
        ELSE
          Ret := MAX(LONGCARD);
        END;
      ELSE
        Pos := CoreIO.tell(F);                   (* input stream *)
        IF CoreFile.BufInf[F]^.Pback # 0 THEN
          DEC(Pos);
        END;
        Ret := Pos-LONGCARD(CoreFile.BufInf[F]^.Cnt);
      END;
(*%T _mthread *)
(*%T _OS2 *)
      StreamUnlock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
    END;
(*%T _mthread *)
(*%F _OS2 *)
      Process.Unlock();
(*%E *)
(*%E *)
    IF Ret = MAX(LONGCARD) THEN
        ErrorCheck(9, 0, 'GetPos : ', Lib.NilStr);
        OK := FALSE;
(*%T _mthread *)
        OKTable[CoreProc._getTID()] := FALSE;
(*%E *)
    END;
    RETURN Ret;
END GetPos;


PROCEDURE Seek( F : File; pos:LONGCARD );
VAR Ret: LONGINT;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
(*%T _mthread *)
(*%F _OS2 *)
  Process.Lock();
(*%E *)
(*%E *)
  IF (F > CoreFile._open_max) OR (CoreFile.BufInf[F] = NIL) THEN
    Ret := CoreIO.lseek(F, pos, CoreIO.SEEK_SET);
  ELSE
(*%T _mthread *)
(*%T _OS2 *)
    StreamLock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
    WITH CoreFile.BufInf[F]^ DO
      IF (Flag = {}) OR (Flag >= CoreIO._F_ERR) THEN
        Ret := -1;
      ELSE
        IF (Flag >= CoreIO._F_OUT) THEN    (* flush output buffer *)
          IF FlsBuf(CoreFile.BufInf[F]) = -1 THEN
              Ret := -1;
          END;
        END;
        Pback := 0;                     (* reset buffer *)
        Cnt := 0;
        Flag := Flag + CoreIO._F_RST;
        Ret := CoreIO.lseek(F, pos, CoreIO.SEEK_SET);
        Flag := Flag - (CoreIO._F_IN + CoreIO._F_OUT +CoreIO._F_EOF +CoreIO._F_CTZ);
      END;
    END;
(*%T _mthread *)
(*%T _OS2 *)
    StreamUnlock(CoreFile.BufInf[F]);
(*%E *)
(*%E *)
  END;
  CoreFile._openfd[F] := CoreFile._openfd[F] - (CoreIO._O_EOF);
(*%T _mthread *)
(*%F _OS2 *)
  Process.Unlock();
(*%E *)
(*%E *)
  IF Ret = -1 THEN
    ErrorCheck(0AH, 0, 'Seek : ', Lib.NilStr);
  END;
END Seek;


PROCEDURE Size(F: File) : LONGCARD;
VAR
  Ret: LONGCARD;
  CurPos: LONGCARD;
BEGIN
(*%T _mthread *)
  Process.Lock();
(*%E *)
  CurPos := GetPos(F);
  IF NOT (*%T _mthread *) ThreadOK() (*%E *) (*%F _mthread *) OK (*%E *)  THEN RETURN 0 END;
  Ret := CoreIO.lseek(F, 0, CoreIO.SEEK_END);
  Seek(F, CurPos);
(*%T _mthread *)
  Process.Unlock();
(*%E *)
  RETURN Ret;
END Size;


PROCEDURE Erase(Name:ARRAY OF CHAR);

VAR
  fn : PathStr;
BEGIN
  GetName(Name,fn);
  IF(CoreIO.unlink(fn) = -1) THEN
    ErrorCheck(0EH, 0, 'Erase : ', fn);
  END;
END Erase;


PROCEDURE Rename(Name,newname: ARRAY OF CHAR);
VAR
  fn: PathStr;
  fn2: PathStr;
BEGIN
  GetName(Name,fn);
  GetName(newname,fn2);
  IF(CoreIO.rename(fn, fn2) = -1) THEN
    ErrorCheck(0FH, 0, 'Rename : ', fn);
  END;
END Rename;

(*%F _OS2 *)
PROCEDURE ReadFirstEntry ( DirName : ARRAY OF CHAR;
                           Attr    : FileAttr;
                           VAR D   : DirEntry) : BOOLEAN;
VAR
  r  : SYSTEM.Registers;
  fn : PathStr;
BEGIN
  GetName(DirName,fn);
  WITH r DO
    AH := 1AH;
    DS := Seg(D);
    DX := Ofs(D);
    Lib.Dos(r);    (* set DTA *)
    AH := 4EH;
    DS := Seg(fn);
    DX := Ofs(fn);
    CL := SHORTCARD(Attr);
    CH := SHORTCARD(0);
    Lib.Dos(r);
    IF (BITSET{SYSTEM.CarryFlag} * Flags) # BITSET{} THEN
      IF (AX <> 18) THEN
          ErrorCheck(14H, AX, 'ReadFirstEntry : ', DirName);
      END;
      RETURN FALSE;
    END;
  END;
  RETURN TRUE;
END ReadFirstEntry;

PROCEDURE ReadNextEntry(VAR D: DirEntry) : BOOLEAN;
VAR
  r : SYSTEM.Registers;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  WITH r DO
    AH := 1AH;
    DS := Seg(D);
    DX := Ofs(D);
    Lib.Dos(r);    (* set DTA *)
    AH := 4FH;
    Lib.Dos(r);
    IF (BITSET{SYSTEM.CarryFlag} * Flags) # BITSET{} THEN
      IF (AX <> 18) THEN
          ErrorCheck(15H, AX, 'ReadNextEntry : ', Lib.NilStr);
      END;
      RETURN FALSE;
    END;
  END;
  RETURN TRUE;
END ReadNextEntry;
(*%E *)

(*%T _OS2 *)
CONST
    GuardHandle = MAX(CARDINAL)-1;

PROCEDURE CopyResult(VAR D: DirEntry; VAR d: Dos.FILEFINDBUF);

BEGIN
    D.attr:=FileAttr(d.attrFile);
    D.time:=d.ftimeCreation;
    D.date:=d.fdateCreation;
    D.size:=d.fileSize;
    Str.Copy(D.Name, d.name);
END CopyResult;


PROCEDURE ReadFirstEntry ( DirName : ARRAY OF CHAR;
                           Attr    : FileAttr;
                           VAR D   : DirEntry) : BOOLEAN;

    PROCEDURE WildInName(): BOOLEAN;
    BEGIN
      RETURN    (Str.CharPos(DirName, '*') # MAX(CARDINAL))
             OR (Str.CharPos(DirName, '?') # MAX(CARDINAL));
    END WildInName;

VAR
  b  : Dos.FILEFINDBUF;
  fn : PathStr;
  status: CARDINAL;
  Handle, Count: CARDINAL;
BEGIN
  GetName(DirName,fn);
  Handle:=MAX(CARDINAL);
  Count:=1;
  status:=FindFirst(fn, Handle, CARDINAL(SHORTCARD(Attr)), b, SIZE(b), Count, LONGCARD(0));
  IF  status # 0 THEN
      IF status <> Err.ERROR_NO_MORE_FILES THEN
          ErrorCheck(14H, status, 'ReadFirstEntry : ', fn);
      END;
      RETURN FALSE;
  END;
  IF WildInName() THEN
    D.Reserved_Handle:=Handle;
  ELSE
    D.Reserved_Handle:=GuardHandle;
    Dos.FindClose(Handle);
  END;
  CopyResult(D, b);
  RETURN TRUE;
END ReadFirstEntry;

PROCEDURE ReadNextEntry(VAR D: DirEntry) : BOOLEAN;

VAR
  b  : Dos.FILEFINDBUF;
  status: CARDINAL;
  Handle, Count: CARDINAL;
BEGIN
  Handle:=(D.Reserved_Handle);
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  IF Handle = GuardHandle THEN
    RETURN FALSE;
  END;
  Count:=1;
  status:=FindNext(Handle, b, SIZE(b), Count);
  IF  status # 0 THEN
      Dos.FindClose(Handle);
      IF status <> Err.ERROR_NO_MORE_FILES THEN
          ErrorCheck(15H, status, 'ReadNextEntry : ', Lib.NilStr);
      END;
      RETURN FALSE;
  END;
  CopyResult(D, b);
  RETURN TRUE;
END ReadNextEntry;
(*%E *)

PROCEDURE ChDir(Name: ARRAY OF CHAR);
VAR
  fn : PathStr;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  GetName(Name,fn);
  IF CoreIO.chdir(fn) = -1 THEN
    ErrorCheck(10H, 0, 'ChDir : ', Name);
    RETURN;
  END;
  IF (Str.Length(Name) > 1) AND (Name[1] = ':') THEN
    IF SetDrive(SHORTCARD(CAP(Name[0]) - 'A') + 1) = 0 THEN
      ErrorCheck(10H, 0, 'ChDir : ', Name);
    END;
  END;
END ChDir;

PROCEDURE MkDir(Name: ARRAY OF CHAR);
VAR
  fn : PathStr;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  GetName(Name,fn);
  IF CoreIO.mkdir(fn) = -1 THEN
    ErrorCheck(11H, 0, 'MkDir : ', Name);
  END;
END MkDir;

PROCEDURE RmDir(Name: ARRAY OF CHAR);
VAR
  fn : PathStr;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  GetName(Name,fn);
  IF CoreIO.rmdir(fn) = -1 THEN
    ErrorCheck(12H, 0, 'RmDir : ', Name);
  END;
END RmDir;

PROCEDURE GetDir(drive: SHORTCARD; VAR Name: ARRAY OF CHAR);
VAR
  fn : PathStr;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  IF CoreIO.getcurdir(CARDINAL(drive), fn) = -1 THEN
    ErrorCheck(13H, 0, 'GetDir : ', Lib.NilStr);
  END;
  Str.Concat(Name,'\',fn);
END GetDir;

  PROCEDURE AssignBuffer(F:File;VAR Buf:ARRAY OF BYTE);

    PROCEDURE FindFreeStream():FileInf;
      VAR
        n               : CARDINAL;
      BEGIN
        n := 0;
(*%T _mthread *)
        Process.Lock();
(*%E *)
        WHILE n < CoreFile._open_max DO
          IF CoreFile._iob[n].Flag = {} THEN
(*%T _mthread *)
            Process.Unlock();
(*%E *)
            RETURN FileInf(ADR(CoreFile._iob[n]));
          END; (*IF*)
          INC(n);
        END; (*WHILE*)
(*%T _mthread *)
        Process.Unlock();
(*%E *)
        RETURN NIL;
      END FindFreeStream;

    BEGIN
(*%T _mthread *)
      SetIOR(0);
(*%E *)
(*%F _mthread *)
      IOR := 0;
(*%E *)
      IF (F > CoreFile._open_max) (*%F _WINDOWS *) OR (CoreFile._openfd[F] = {}) (*%E *) THEN
        ErrorCheck(19H,CoreIO.EBADF,'AssignBuffer : ',Lib.NilStr);
        RETURN;
      END; (*IF*)
      IF (HIGH(Buf) = 0) OR (HIGH(Buf) > MAX(INTEGER)) THEN
        ErrorCheck(1AH,CoreIO.EINVAL,'AssignBuffer : ',Lib.NilStr);
        RETURN;
      END; (*IF*)
(*%T _WINDOWS *)
      IF (CoreFile._openfd[F] = {}) THEN
        CoreFile._openfd[F] := (CoreIO.O_RDWR + CoreIO.O_BINARY);
      END; (*IF*)
(*%E *)
      IF CoreFile.BufInf[F] # NIL THEN
        RETURN;
      END; (*IF*)
      CoreFile.BufInf[F] := FindFreeStream();
      IF CoreFile.BufInf[F] = NIL THEN
        ErrorCheck(1BH,CoreIO.EMFILE,'AssignBuffer : ',Lib.NilStr);
        RETURN;
      END; (*IF*)
      WITH CoreFile.BufInf[F]^ DO
        Ptr    := CoreFile.StreamPtr(ADR(Buf));
        Base   := Ptr;
        Size   := HIGH(Buf) + 1;
        Cnt    := 0;
        Pback  := 0;
        Handle := F;
        IF (CoreFile._openfd[F] >= CoreIO.O_DEVICE) THEN
          Flag := CoreIO._F_DEV;
        ELSE
          Flag := {};
        END; (*IF*)
        IF (CoreFile._openfd[F] * CoreIO.O_RDWR # {}) OR (CoreFile._openfd[F] * CoreIO.O_WRONLY # {}) THEN
          Flag := Flag + CoreIO._F_RDWR;
        ELSE
          Flag := Flag + CoreIO._F_READ;
        END; (*IF*)
        IF CoreFile._openfd[F] >= CoreIO.O_APPEND THEN
          Flag := Flag + CoreIO._F_APP;
        END; (*IF*)
        Flag := Flag + (CoreIO._F_BIN + CoreIO._F_UBUF + CoreIO._F_RST);
      END; (*WITH*)
    END AssignBuffer;

PROCEDURE AppendHandle(F: File; ReadOnly: BOOLEAN);

BEGIN
  IF F < CoreFile._open_max THEN
    IF ReadOnly THEN
      CoreFile._openfd[F] := (CoreIO.O_RDONLY+CoreIO.O_BINARY);
    ELSE
      CoreFile._openfd[F] := (CoreIO.O_RDWR+CoreIO.O_BINARY);
    END;
    IF CoreIO.isatty(F) # 0 THEN
      CoreFile._openfd[F] := CoreFile._openfd[F] + CoreIO.O_DEVICE;
    END;
  END;
END AppendHandle;


PROCEDURE AppendStream(St: FileInf): File;

VAR
    F: File;
BEGIN
    F := St^.Handle;
    CoreFile.BufInf[F] := St;
    RETURN F;
END AppendStream;

PROCEDURE GetStreamPointer(F: File): FileInf;

BEGIN
    RETURN CoreFile.BufInf[F];
END GetStreamPointer;

(*%F _OS2 *)
PROCEDURE GetDrive() : SHORTCARD ;

(* Returns the currently selected drive *)
(* A=1,B=2,C=3 etc                      *)

VAR
  r  : SYSTEM.Registers;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  r.AH := 19H ;
  Lib.Dos(r);
  RETURN r.AL+1 ;
END GetDrive ;

PROCEDURE SetDrive(Drive: SHORTCARD): SHORTCARD;

(* Sets the default drive *)
(* A=1,B=2,C=3 etc                      *)

VAR
  r  : SYSTEM.Registers;
BEGIN
(*%T _mthread *)
  SetIOR(0);
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  r.AH := 0EH ;
  r.DL := Drive-1;
  Lib.Dos(r);
  RETURN r.AL;
END SetDrive ;

PROCEDURE GetCurrentDate () : LONGCARD ;
VAR r : SYSTEM.Registers;
    l : RECORD
          CASE : BOOLEAN OF
            TRUE  :  fl,fh : CARDINAL; |
            FALSE :  l     : LONGCARD;
          END;
        END;
BEGIN
  WITH r DO
       AH := 2CH;
       Lib.Dos(r);
       l.fl := (VAL(CARDINAL,CH) << 11)+(VAL(CARDINAL,CL) << 5)+(VAL(CARDINAL,DH)>>1);
       AH := 2AH ;
       Lib.Dos(r);
       l.fh := ((CX-1980)<< 9)+(VAL(CARDINAL,DH)<<5)+VAL(CARDINAL,DL);
  END;
  RETURN l.l;
END GetCurrentDate ;

PROCEDURE GetFileDate( f : File) : LONGCARD;
VAR r : SYSTEM.Registers;
    l : RECORD
          CASE : BOOLEAN OF
            TRUE  :  fl,fh : CARDINAL; |
            FALSE :  l     : LONGCARD;
          END;
        END;
BEGIN
  WITH r DO
       AX := 5700H;
       BX := f;
       Lib.Dos(r);
       l.fl := CX;
       l.fh := DX;
  END;
  RETURN l.l;
END GetFileDate;

PROCEDURE SetFileDate( f : File ; d : LONGCARD ) ;
VAR r : SYSTEM.Registers;
    l : RECORD
          CASE : BOOLEAN OF
            TRUE  :  fl,fh : CARDINAL; |
            FALSE :  l     : LONGCARD;
          END;
        END;
BEGIN
  WITH r DO
       l.l := d ;
       AX := 5701H;
       BX := f;
       CX := l.fl ;
       DX := l.fh ;
       Lib.Dos(r);
  END;
END SetFileDate;
(*%E *)

(*%T _OS2 *)
PROCEDURE GetDrive() : SHORTCARD ;

(* Returns the currently selected drive *)
(* A=1,B=2,C=3 etc                      *)

VAR
  Dr  : CARDINAL;
  BitMap: LONGCARD;
BEGIN
  SYSTEM.Eval(QCurDisk(Dr, BitMap));
  RETURN SHORTCARD(Dr);
END GetDrive ;

PROCEDURE SetDrive(Drive: SHORTCARD): SHORTCARD;

(* Sets the default drive *)
(* A=1,B=2,C=3 etc                      *)

BEGIN
  SYSTEM.Eval(Dos.SelectDisk(CARDINAL(Drive)));
  RETURN MAX(SHORTCARD);
END SetDrive ;

PROCEDURE GetCurrentDate () : LONGCARD ;

VAR
    l : RECORD
          CASE : BOOLEAN OF
            TRUE  :  fl,fh : CARDINAL; |
            FALSE :  l     : LONGCARD;
          END;
        END;
    Info: Dos.DATETIME;
BEGIN
  SYSTEM.Eval(Dos.GetDateTime(Info));
       l.fl := (CARDINAL(Info.hours) << 11)+(CARDINAL(Info.minutes) << 5)+(CARDINAL(Info.seconds)>>1);
       l.fh := ((Info.year-1980)<< 9)+(CARDINAL(Info.month)<<5)+CARDINAL(Info.day);
  RETURN l.l;
END GetCurrentDate ;

TYPE
    FileInfo = RECORD
        CDate, CTime, ADate, ATime, WDate, WTime: CARDINAL;
        CBFile, CGFileA: LONGCARD;
        Attr: SHORTCARD;
        cchName: SHORTCARD;
        achName: ARRAY [0..12] OF CHAR;
    END;
    DT = RECORD
        CASE : BOOLEAN OF
            TRUE  :  fl,fh : CARDINAL; |
            FALSE :  l     : LONGCARD;
        END;
    END;

PROCEDURE GetFileDate( f : File) : LONGCARD;

VAR
    Buffer: FileInfo;
    T: DT;
BEGIN
    IF Dos.QFileInfo(f, CARDINAL(1), FarADR(Buffer), SIZE(Buffer)) # 0 THEN
        RETURN MAX(LONGCARD);
    END;
    T.fh := Buffer.WDate;
    T.fl := Buffer.WTime;
    RETURN T.l;
END GetFileDate;

PROCEDURE SetFileDate( f : File ; d : LONGCARD ) ;

VAR
    Buffer: FileInfo;
    T: DT;
BEGIN
    IF Dos.QFileInfo(f, CARDINAL(1), FarADR(Buffer), SIZE(Buffer)) # 0 THEN RETURN END;
    T.l:= d;
    Buffer.WDate := T.fh;
    Buffer.WTime := T.fl;
    IF Dos.SetFileInfo(f, CARDINAL(1), FarADR(Buffer), SIZE(Buffer)) # 0 THEN END;
END SetFileDate;
(*%E *)

PROCEDURE ThreadEOF(): BOOLEAN;

BEGIN
(*%T _mthread *)
  RETURN EOFTable[CoreProc._getTID()];
(*%E *)
(*%F _mthread *)
  RETURN EOF;
(*%E *)
END ThreadEOF;

PROCEDURE ThreadOK(): BOOLEAN;

BEGIN
(*%T _mthread *)
  RETURN OKTable[CoreProc._getTID()];
(*%E *)
(*%F _mthread *)
  RETURN OK;
(*%E *)
END ThreadOK;

PROCEDURE GetFileStamp(f : File ; VAR b: FileStamp) : BOOLEAN;

VAR
    DT : RECORD
          CASE : BOOLEAN OF
            TRUE  :  ft,fd : CARDINAL; |
            FALSE :  l     : LONGCARD;
          END;
        END;
BEGIN
  DT.l := GetFileDate(f);
  IF DT.l = MAX(LONGCARD) THEN
    RETURN FALSE;
  ELSE
    b.Year  := SHORTCARD(DT.fd>>9+80) ;
    b.Month := SHORTCARD((DT.fd>>5) MOD 16) ;
    b.Day   := SHORTCARD(DT.fd MOD 32) ;
    b.Hour  := SHORTCARD(DT.ft>>11) ;
    b.Min   := SHORTCARD((DT.ft>>5) MOD 64) ;
    b.Sec   := SHORTCARD(DT.ft MOD 32) ;
    RETURN TRUE;
  END;
END GetFileStamp;

(*# save,call(c_conv=>on) *)
  PROCEDURE Cleanup();
    VAR
      n                 : CARDINAL;
    BEGIN
      FOR n := 0 TO CoreFile._open_max - 1 DO
        IF CoreFile._iob[n].Flag # {} THEN
          CoreFile.BufInf[n] := ADR(CoreFile._iob[n]);
          Flush(n);
        END; (*IF*)
      END; (*FOR*)
    END Cleanup;
(*# restore *)

(*%T _mthread *)
VAR
  n : [1..Process.MaxProcess];
(*%E *)
BEGIN
(*%T _mthread *)
  n := 1;
  WHILE  n <= Process.MaxProcess DO
    IOR[n] := 0;
    EOFTable[n] := FALSE;
    OKTable[n]  := TRUE;
    INC(n);
  END;
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  Eng     := FALSE;
  IOcheck := TRUE;
  OK      := TRUE;
  ChopOff := FALSE;
  EOF     := FALSE;
  EOL     := CHR (10);
  PrefixChar    := ' ';
  SuffixChar    := ' ';
  ShareMode := ShareCompat;
  Separators := Str.CHARSET{CHR(9),CHR(10),CHR(13),CHR(26),' '};
  CoreFile.BufInf[StandardInput]  := ADR(CoreFile._iob[StandardInput]);
  CoreFile.BufInf[StandardOutput] := ADR(CoreFile._iob[StandardOutput]);
  CoreMain._exit_io := Cleanup;
END FIO.

