(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  FILESYST.MOD - File utilities                                           *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*# call(o_a_copy=>off) *)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*%E *)

(*# data(seg_name => null) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE FileSystem;

IMPORT Str, Storage, CoreIO;

VAR
    LastTempExt: ARRAY [0..8] OF CHAR;


PROCEDURE  GetTempFileName(VAR Name: FileNameType): BOOLEAN;

VAR
    n, p: INTEGER;
BEGIN
    n:=Str.Length(Name)-8;
    IF n < 0 THEN
	RETURN FALSE;
    END;	
    p:=0;
    WHILE p < 8 DO		       (* append previous extension *)
	Name[n]:=LastTempExt[p];
	INC(p);
	INC(n);
    END;
    DEC(n, 5);
    p:=3;			       (* if yes increment counters *)
    REPEAT
        LOOP
            IF Name[n] < '9' THEN
                INC(Name[n]);
        	INC(LastTempExt[p]);
        	EXIT;
            END;
            IF p >= 0 THEN
                Name[n]:='0';
                DEC(n);
        	LastTempExt[p]:='0';
        	DEC(p);
            ELSE
                RETURN FALSE;
            END;
        END;
    UNTIL NOT FIO.Exists(Name);
    RETURN TRUE;
END GetTempFileName;

PROCEDURE  SetErrorType(VAR f: File);

BEGIN
    CASE FIO.IOresult() OF
        | 0 :
            f.res:=done;
        | 1 :
            f.res:=callerror;
        | 2 :
            f.res:=unknownfile;
        | 3 :
            f.res:=unknownpath;
        | 4 :
            f.res:=toomanyfiles;
        | 5 :
            f.res:=softprotected;
        | 15 :
            f.res:=unknownmedium;
        | 19 :
            f.res:=hardprotected;
        ELSE
            f.res:=notdone;
    END;
END SetErrorType;


PROCEDURE Create(VAR f: File; Device: ARRAY OF CHAR);

BEGIN
    f.flags:=FlagSet{};
    f.eof:=FALSE;
    f.fileno:=MAX(CARDINAL);
    Str.Copy(f.name, Device);
    Str.Append(f.name, '\');
    Str.Append(f.name, 'FSYSXXXX.XXX');
    IF GetTempFileName(f.name) = FALSE THEN
        f.res:=toomanyfiles;
        RETURN;
    END;
    f.fileno:=FIO.Create(f.name);
    IF f.fileno = MAX(CARDINAL) THEN
        SetErrorType(f);
        RETURN;
    END;
    Storage.ALLOCATE(f.buffer, BufferSize);
    FIO.AssignBuffer(f.fileno, f.buffer^);
    INCL(f.flags, tf);
    f.res:=done;
    RETURN;
END Create;

PROCEDURE Close(VAR f: File);

BEGIN
    FIO.Close(f.fileno);
    Storage.DEALLOCATE(f.buffer, BufferSize);
    IF tf IN f.flags THEN
        FIO.Erase(f.name);
    END;
    f.flags:=FlagSet{};
    f.fileno:=MAX(CARDINAL);
    f.res:=done;
END Close;

PROCEDURE Lookup(VAR f: File; Filename: ARRAY OF CHAR; New: BOOLEAN);

VAR
    OK: BOOLEAN;
BEGIN
    f.flags:=FlagSet{};
    f.eof:=FALSE;
    f.fileno:=MAX(CARDINAL);
    OK:=TRUE;
    Str.Copy(f.name, Filename);
    IF FIO.Exists(f.name) THEN
        f.fileno:=FIO.Open(f.name);
        IF f.fileno = MAX(CARDINAL) THEN
            OK:=FALSE;
        END;
    ELSIF New THEN
        f.fileno:=FIO.Create(f.name);
        IF f.fileno = MAX(CARDINAL) THEN
            OK:=FALSE;
        END;
    ELSE
        OK:=FALSE;
    END;
    IF NOT OK THEN
        f.res:=notdone;
        RETURN;
    END;
    Storage.ALLOCATE(f.buffer, BufferSize);
    FIO.AssignBuffer(f.fileno, f.buffer^);
    f.res:=done;
    RETURN;
END Lookup;

PROCEDURE Rename(VAR f: File; Filename: ARRAY OF CHAR);

VAR
    NewName: FileNameType;
BEGIN
    EXCL(f.flags, tf);
    Close(f);
    IF Filename[0] = CHAR(0) THEN
        Str.Copy(NewName, '\');
        Str.Append(NewName, 'FSYSXXXX.XXX');
        IF GetTempFileName(NewName) = FALSE THEN
            f.res:=toomanyfiles;
            RETURN;
        END;
        FIO.Rename(f.name, NewName);
        Lookup(f, NewName, FALSE);
        IF f.res # done THEN RETURN END;
        INCL(f.flags, tf);
    ELSE
        FIO.Rename(f.name, Filename);
        Lookup(f, Filename, FALSE);
        IF f.res # done THEN RETURN END;
    END;
    f.res:=done;
END Rename;

PROCEDURE SetRead(VAR f: File);

VAR
    CurrentPos: LONGCARD;
BEGIN
    CurrentPos:=FIO.GetPos(f.fileno);
    FIO.Seek(f.fileno, CurrentPos);
    f.flags:= f.flags - FlagSet{wr, mo};
    INCL(f.flags, rd);
    f.res:=done;
END SetRead;

PROCEDURE SetWrite(VAR f: File);

VAR
    CurrentPos: LONGCARD;
BEGIN
    CurrentPos:=FIO.GetPos(f.fileno);
    FIO.Seek(f.fileno, CurrentPos);
    f.flags:=f.flags - FlagSet{rd ,mo};
    f.flags:=f.flags + FlagSet{pi, wr};
    f.res:=done;
END SetWrite;

PROCEDURE SetModify(VAR f: File);

VAR
    CurrentPos: LONGCARD;
BEGIN
    CurrentPos:=FIO.GetPos(f.fileno);
    FIO.Seek(f.fileno, CurrentPos);
    f.flags:=f.flags - FlagSet{rd, wr};
    INCL(f.flags, mo);
    f.res:=done;
END SetModify;

PROCEDURE SetOpen(VAR f: File);

VAR
    CurrentPos: LONGCARD;
BEGIN
    CurrentPos:=FIO.GetPos(f.fileno);
    FIO.Seek(f.fileno, CurrentPos);
    f.flags:=f.flags - FlagSet{rd, mo, wr};
    f.res:=done;
END SetOpen;

PROCEDURE FillBuffer(f: File);

VAR
    F: FIO.FileInf;
    NumRead: INTEGER;
BEGIN
    F:=FIO.GetStreamPointer(f.fileno);
    WITH F^ DO
      IF (Flag = {}) OR ((Flag * (CoreIO._F_ERR  + CoreIO._F_OUT)) # {}) THEN
          f.res:=callerror;
          RETURN
      END;
      IF (Flag >= CoreIO._F_EOF) THEN
          f.eof:=TRUE;
          f.res:=notdone;
          RETURN;
      END;
      IF (Flag >= CoreIO._F_RST) THEN
        Flag := Flag - CoreIO._F_RST;
      END;
      NumRead := CoreIO.read(Handle, Base, Size);
      Ptr := Base;
      IF (NumRead = -1) AND (NumRead # Size) THEN
        Flag := Flag + CoreIO._F_ERR;
        Cnt := 0;
        f.res:=notdone;
        RETURN;
      END;
      Cnt := NumRead;	            (* reset pointers *)
      Flag := Flag + CoreIO._F_IN;         (* set input flag *)
      IF NumRead = 0 THEN
        Flag := Flag + CoreIO._F_EOF;      (* end of file *)
        f.eof:=TRUE;
        f.res:=notdone;
        RETURN;
      END;
      f.res:=done;
      RETURN;
    END;
END FillBuffer;

PROCEDURE Doio(VAR f: File);

VAR
    CurPos: LONGCARD;
BEGIN
    IF (rd IN f.flags) THEN
        CurPos:=FIO.GetPos(f.fileno);
        FIO.Seek(f.fileno, CurPos);
        FillBuffer(f);
    ELSIF (wr IN f.flags) THEN
        FIO.Flush(f.fileno);
    ELSIF (mo IN f.flags) THEN
        FIO.Flush(f.fileno);
        FillBuffer(f);
    ELSE
        f.res:=done;
    END;


END Doio;


PROCEDURE SetPos(VAR f: File; HighPos, LowPos: CARDINAL);

VAR
    Pos: LONGCARD;
BEGIN
    Pos:=LONGCARD(LowPos)+LONGCARD(HighPos)<<16;
    FIO.Seek(f.fileno, Pos);
    INCL(f.flags, pi);
    f.res:=done;
END SetPos;


PROCEDURE GetPos(VAR f: File; VAR HighPos, LowPos: CARDINAL);

VAR
    Pos: LONGCARD;
BEGIN
    Pos:=FIO.GetPos(f.fileno);
    IF Pos = MAX(LONGCARD) THEN
        SetErrorType(f);
        RETURN;
    END;
    LowPos:=CARDINAL(Pos);
    HighPos:=CARDINAL(Pos>>16);
    f.res:=done;
END GetPos;


PROCEDURE Length(VAR f: File; VAR HighPos, LowPos: CARDINAL);

VAR
    Len: LONGCARD;
BEGIN
    Len:=FIO.Size(f.fileno);
    IF Len = MAX(LONGCARD) THEN
        SetErrorType(f);
        RETURN;
    END;
    LowPos:=CARDINAL(Len);
    HighPos:=CARDINAL(Len>>16);
    f.res:=done;
    RETURN;
END Length;


PROCEDURE Reset(VAR f: File);

BEGIN
    SetPos(f, 0, 0);
    f.flags:=f.flags - FlagSet{rd, mo, wr};
    f.eof:=FALSE;
    f.res:=done;
END Reset;


PROCEDURE Again(VAR f: File);

BEGIN
    IF f.flags * FlagSet{mo, rd} # FlagSet{} THEN
        INCL(f.flags, ag);
        f.res:=done;
    ELSE
        f.res:=callerror;
    END;
    RETURN;
END Again;


PROCEDURE ReadWord(VAR f: File; VAR w: WORD);

BEGIN
    IF wr IN f.flags THEN
        f.res:=callerror;
        RETURN;
    ELSIF f.flags * FlagSet{mo, rd} = FlagSet{} THEN
        INCL(f.flags, rd);
    END;
    FIO.EOF:=FALSE;
    IF ag IN f.flags THEN
        EXCL(f.flags, ag);
        w:=f.again;
        f.res:=done;
        RETURN;
    END;
    IF FIO.RdBin(f.fileno, w, SIZE(WORD)) # SIZE(WORD) THEN
        SetErrorType(f);
        f.eof:=FIO.EOF;
    ELSE
        f.again:=w;
        f.res:=done;
    END;
    RETURN;
END ReadWord;


PROCEDURE WriteWord(VAR f: File; w: WORD);

BEGIN
    IF rd IN f.flags THEN
        f.res:=callerror;
        RETURN;
    ELSIF f.flags * FlagSet{mo, wr} = FlagSet{} THEN
        INCL(f.flags, wr);
    END;
    FIO.WrBin(f.fileno, w, SIZE(WORD));
    f.res:=done;
    RETURN;
END WriteWord;

PROCEDURE ReadChar(VAR f: File; VAR ch: CHAR);

BEGIN
    IF wr IN f.flags THEN
        f.res:=callerror;
        RETURN;
    ELSIF f.flags * FlagSet{mo, rd} = FlagSet{} THEN
        INCL(f.flags, rd);
    END;
    FIO.EOF:=FALSE;
    IF ag IN f.flags THEN
        EXCL(f.flags, ag);
        ch:=CHAR(f.again);
        f.res:=done;
        RETURN;
    END;
    ch:=FIO.RdChar(f.fileno);
    IF ch = CHAR(0DH) THEN
        ch:=FIO.RdChar(f.fileno);
    END;
    IF ch = CHR(26) THEN
        SetErrorType(f);
        f.eof:=FIO.EOF;
        f.res:=notdone;
    ELSE
        f.again:=WORD(ch);
        f.res:=done;
    END;
END ReadChar;

PROCEDURE WriteChar(VAR f: File; ch: CHAR);

VAR
    HighEnd, LowEnd: CARDINAL;
BEGIN
    IF rd IN f.flags THEN
        f.res:=callerror;
        RETURN;
    ELSIF f.flags * FlagSet{mo, wr} = FlagSet{} THEN
        f.flags:= f.flags + FlagSet{pi, wr};
    END;
    IF pi IN f.flags THEN
        Length(f, HighEnd, LowEnd);
        SetPos(f, HighEnd, LowEnd);
        EXCL(f.flags, pi);
    END;
    IF ch = EOL THEN
        FIO.WrLn(f.fileno);
    ELSE
        FIO.WrChar(f.fileno, ch);
    END;
    f.res:=done;
    RETURN;
END WriteChar;


BEGIN
   FIO.IOcheck:=FALSE;
   LastTempExt:= "0000.$$$";
END FileSystem.

