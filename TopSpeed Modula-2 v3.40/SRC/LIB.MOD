(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  LIB.MOD - General library functions                                     *
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

IMPLEMENTATION MODULE Lib;

IMPORT SYSTEM,Str,SPAWN,CoreMain,CoreSig,CoreMath;
(*%F _OS2 *)
(*%T _WINDOWS*)
IMPORT Windows;
(*%E *)
(*%E *)
(*%T _OS2 *)
FROM Dos IMPORT DATETIME,GetDateTime,SIGHANDLER,SetSigHandler,Sleep,
                SIG_CTRLC,SIG_CTRLBREAK,Beep,RESULTCODES,ExecPgm,
                SearchPath,GetMessage,GetEnv,EXEC_SYNC, SetDateTime, Write;
(*%E *)

CONST
  _DLLOVL = (_DLL OR _OVL) AND NOT _OS2;
  _NOTDLLORENV = (NOT _DLLOVL) OR _ENV;

(* Implemented In AsmLib *)
(*# save *)
(*%T _DLL *)
(*# call(seg_name=>LibDLL) *)
(*%E *)
PROCEDURE AddFarAddr(A: FarADDRESS; increment: CARDINAL) : FarADDRESS; IN AsmLib;
PROCEDURE SubFarAddr(A: FarADDRESS; decrement: CARDINAL) : FarADDRESS; IN AsmLib;
PROCEDURE IncFarAddr(VAR A: FarADDRESS; increment: CARDINAL); IN AsmLib;
PROCEDURE DecFarAddr(VAR A: FarADDRESS; decrement: CARDINAL); IN AsmLib;

(*%F _fdata *)
PROCEDURE NearMove    (Source,Dest:NearADDRESS;Count:CARDINAL); IN AsmLib;
PROCEDURE NearFastMove(Source,Dest:NearADDRESS;Count:CARDINAL); IN AsmLib;
PROCEDURE NearWordMove(Source,Dest:NearADDRESS;WordCount:CARDINAL); IN AsmLib;
(*%E *)
PROCEDURE Move    (Source,Dest:ADDRESS;Count:CARDINAL); IN AsmLib;
PROCEDURE FastMove(Source,Dest:ADDRESS;Count:CARDINAL); IN AsmLib;
PROCEDURE WordMove(Source,Dest:ADDRESS;WordCount:CARDINAL); IN AsmLib;

PROCEDURE FarMove (Source,Dest:FarADDRESS;Count:CARDINAL); IN AsmLib;
PROCEDURE FarFastMove(Source,Dest:FarADDRESS;Count:CARDINAL); IN AsmLib;
PROCEDURE FarWordMove(Source,Dest:FarADDRESS;WordCount:CARDINAL); IN AsmLib;

PROCEDURE Fill(Dest: ADDRESS; Count: CARDINAL; Value: BYTE); IN AsmLib;
PROCEDURE FarFill(Dest: FarADDRESS; Count: CARDINAL; Value: BYTE);  IN AsmLib;

PROCEDURE WordFill(Dest: ADDRESS; WordCount: CARDINAL; Value: WORD);  IN AsmLib;
PROCEDURE FarWordFill(Dest: FarADDRESS; WordCount: CARDINAL; Value: WORD);  IN AsmLib;

PROCEDURE HashString(S: ARRAY OF CHAR; Range: CARDINAL) : CARDINAL; IN AsmLib;
PROCEDURE Terminate(P : PROC; VAR C: PROC); IN AsmLib;
PROCEDURE SetReturnCode(code: SHORTCARD); IN AsmLib;
PROCEDURE SetInProgramFlag(State: BOOLEAN); IN AsmLib;
PROCEDURE GetInProgramFlag(): BOOLEAN; IN AsmLib;

PROCEDURE CpuId ( VAR r : CpuRec ); IN AsmLib;

PROCEDURE ScanR  (Dest: ADDRESS; Count: CARDINAL; Value: BYTE) : CARDINAL; IN AsmLib;
PROCEDURE ScanL  (Dest: ADDRESS; Count: CARDINAL; Value: BYTE) : CARDINAL; IN AsmLib;
PROCEDURE ScanNeR(Dest: ADDRESS; Count: CARDINAL; Value: BYTE) : CARDINAL; IN AsmLib;
PROCEDURE ScanNeL(Dest: ADDRESS; Count: CARDINAL; Value: BYTE) : CARDINAL; IN AsmLib;
PROCEDURE Compare(Source,Dest: ADDRESS; Len: CARDINAL) : CARDINAL; IN AsmLib;

PROCEDURE UserBreak; IN AsmLib;
PROCEDURE Sound(FreqHz: CARDINAL); IN AsmLib;
PROCEDURE NoSound; IN AsmLib;
PROCEDURE Dos(VAR R: SYSTEM.Registers); (* INT 21H Function Call *) IN AsmLib;
PROCEDURE Intr(VAR R: SYSTEM.Registers; I: CARDINAL); IN AsmLib;

PROCEDURE AddressOK      ( A : ADDRESS ) : BOOLEAN; IN AsmLib;
PROCEDURE SelectorLimit  ( S : CARDINAL ) : CARDINAL; IN AsmLib;
PROCEDURE ProtectedMode  () : BOOLEAN; IN AsmLib;

PROCEDURE SetJmp (VAR Lbl: LongLabel) : CARDINAL; IN AsmLib;
PROCEDURE LongJmp(VAR Lbl: LongLabel; result: CARDINAL); IN AsmLib;

(*%F _OS2 *)
(*# save *)
(*# call(near_call=>off, reg_param=>()) *)
PROCEDURE DosExec(name: ARRAY OF CHAR; paramblock: FarADDRESS) : CARDINAL; IN AsmLib;
(*# restore *)
PROCEDURE InternalEnableBreakCheck; IN AsmLib;
PROCEDURE InternalDisableBreakCheck; IN AsmLib;
PROCEDURE InternalDelay(Time: CARDINAL); IN AsmLib;
PROCEDURE InternalSound(Freq: CARDINAL); IN AsmLib;
PROCEDURE InternalNoSound(); IN AsmLib;
(*%E *)
(*# restore *)

PROCEDURE IsOfClass(Child, Parent: MTablePtr): BOOLEAN;

VAR
    ThisObject: MTablePtr;

BEGIN
    ThisObject:= Child;
    IF ThisObject = Parent THEN RETURN TRUE END;
(*%T _fdata *)
    WHILE ThisObject^.Parent # FarNIL DO
(*%E *)
(*%F _fdata *)
    WHILE ThisObject^.Parent # NearNIL DO
(*%E *)
        IF ThisObject^.Parent = Parent THEN RETURN TRUE END;
        ThisObject := ThisObject^.Parent;
    END;
    RETURN FALSE;
END IsOfClass;



PROCEDURE HSort(N: CARDINAL; Less: CompareProc; Swap: SwapProc);
VAR
  i,j,k : CARDINAL;
BEGIN
  IF N > 1 THEN
    i := N DIV 2;
    REPEAT
      j := i;
      LOOP (* Note that total repeats <= N/4 * 1 + N/8 * 2 + N/16 * 3 + .... *)
        k := j * 2;
        IF k > N THEN EXIT END;
        IF (k < N) AND Less(k,k+1) THEN INC(k) END;
        IF Less(j,k) THEN Swap(j,k) ELSE EXIT END;
        j := k;
      END;
      DEC(i);
    UNTIL i = 0;

    i := N;
    REPEAT
      j := 1;
      Swap(j,i);
      DEC(i);
      LOOP
        k := j * 2;
        IF k > i THEN EXIT END;
        IF ( k < i ) AND Less(k,k+1) THEN INC(k) END;
        Swap(j,k);
        j := k;
      END;
      LOOP
        k := j DIV 2;
        IF (k > 0) AND Less(k,j) THEN Swap(j,k); j := k ELSE EXIT END;
      END;
    UNTIL i = 0;
  END;
END HSort;


PROCEDURE QSort(N: CARDINAL; Less: CompareProc; Swap: SwapProc);

  PROCEDURE Sort(l,r: CARDINAL);
  VAR
    i,j:CARDINAL;
  BEGIN
    WHILE r > l DO
      i := l+1;
      j := r;
      WHILE i <= j DO
        WHILE (i <= j) AND NOT Less(l,i) DO INC(i) END;
        WHILE (i <= j) AND Less(l,j) DO DEC(j) END;
        IF i <= j THEN Swap(i,j); INC(i); DEC(j) END;
      END;
      IF j # l THEN Swap(j,l) END;
      IF j+j > r+l THEN (* small one recursively *)
        Sort(j+1,r);
        r := j-1;
      ELSE
        Sort(l,j-1);
        l := j+1;
      END;
    END;
  END Sort;

BEGIN
  Sort(1,N);
END QSort;


  PROCEDURE GetVector(Int:SHORTCARD):FarADDRESS;
(*%F _OS2 *)
    VAR
      r                   : SYSTEM.Registers;
    BEGIN
      r.AH := 35H;
      r.AL := Int;
      Dos(r);
      RETURN [r.ES:r.BX];
(*%E *)
(*%T _OS2 *)
    BEGIN
      RETURN FarNIL;
(*%E *)
    END GetVector;

  PROCEDURE SetVector(Int:SHORTCARD;Vector:FarADDRESS);
(*%F _OS2 *)
    VAR
      r                   : SYSTEM.Registers;
    BEGIN
      r.AH := 25H;
      r.AL := Int;
      r.DS := Seg(Vector^);
      r.DX := Ofs(Vector^);
      Dos(r);
(*%E *)
    END SetVector;

(*%F _OS2 *)
PROCEDURE Execute(Name        : ARRAY OF CHAR;
                  CommandLine : ARRAY OF CHAR;
                  StoreAddr   : FarADDRESS;   (* storage to execute in *)
                  StoreLen    : CARDINAL      (* length of store paragraphs *)
                  ):CARDINAL;
    CONST
      MinHeapNeeded     = 4;

    VAR
      fullpath          : ARRAY[0..80] OF CHAR;
      cline             : RECORD
                            len        : SHORTCARD;
                            txt        : ARRAY[0..255] OF CHAR;
                          END; (*cline*)
      reply             : CARDINAL;
      LoadRec           : RECORD
                            envseg  : CARDINAL;
                            comline : FarADDRESS;
                            FCB1    : FarADDRESS;
                            FCB2    : FarADDRESS;
                          END; (*LoadRec*)
      Progbase          : CARDINAL;
      MaxProgSize       : CARDINAL;
      residue           : CARDINAL;

(*%T _NOTDLLORENV*)
    PROCEDURE GiveBackHeap(StoreAddr:FarADDRESS; (* storage to execute in *)
                           StoreLen :CARDINAL);  (* length of store paragraphs *)
      VAR
        R               : SYSTEM.Registers;
        temp            : CARDINAL;
      BEGIN
        Progbase := Seg(StoreAddr^);
        R.AH := 4AH;
        R.ES := PSP;
        R.BX := Seg(StoreAddr^)-PSP;
        Lib.Dos(R);                (* modify so all after seg free *)
        R.BX := StoreLen-2;
        R.AH := 48H;
        Lib.Dos(R);                (* allocate the seg we want *)
        temp := R.AX;
        R.BX := 0FFFFH;            (* allocate all the rest *)
        R.AH := 48H;
        Lib.Dos(R);                (* returns allocated in BX *)
        R.AH := 48H;
        Lib.Dos(R);                (* do allocation *)
        residue := R.AX;
        R.AH := 49H;
        R.ES := temp;
        Lib.Dos(R);                (* now free the bit we want *)
      END GiveBackHeap;

    PROCEDURE RetrieveHeap;
      VAR
        R               : SYSTEM.Registers;
      BEGIN
        R.AH := 49H;
        R.ES := residue;
        Lib.Dos(R);                (* now free the residue *)
        R.BX := 0FFFFH;            (* now modify PSP back to full size *)
        R.AH := 4AH;
        R.ES := PSP;
        Lib.Dos(R);                (* returns allocated in BX *)
        R.AH := 4AH;
        Lib.Dos(R);                (* do modify *)
      END RetrieveHeap;
(*%E *)

(*%F _NOTDLLORENV*)
    PROCEDURE GiveBackHeap(StoreAddr:FarADDRESS;StoreLen:CARDINAL);
      BEGIN
        CoreMain._res_mem;
      END GiveBackHeap;

    PROCEDURE RetrieveHeap;
      BEGIN
        CoreMain._shr_mem;
      END RetrieveHeap;
(*%E *)

    BEGIN
      GiveBackHeap(StoreAddr,StoreLen);
      cline.len := SHORTCARD(Str.Length(CommandLine));
      Str.Concat(cline.txt,CommandLine,CHR(13));
      Str.Copy(fullpath,Name);
      LoadRec.envseg  := [PSP:2CH]^;
      LoadRec.comline := FarADR(cline);
      LoadRec.FCB1    := [PSP:5CH];
      LoadRec.FCB2    := [PSP:6CH];
      reply := DosExec(fullpath,FarADR(LoadRec));
      RetrieveHeap;
      RETURN reply;
    END Execute;
(*%E *)

(*%T _OS2 *)
PROCEDURE Environment(N: CARDINAL): CommandType;

VAR
  Ret: FarADDRESS;
BEGIN
  Ret := FarADR(CoreMain._env_var[N]^);
  IF Ret = FarNIL THEN
    RETURN CommandType(FarADR(NilStr));
  ELSE
    RETURN CommandType(Ret);
  END;
END Environment;
(*%E *)

PROCEDURE EnvironmentFind ( name : ARRAY OF CHAR;
                            VAR result : ARRAY OF CHAR );
(* Find a string in the DOS environment *)
VAR
  n, p : CARDINAL;
  pi : ARRAY[0..14] OF CHAR;
  pp : Lib.CommandType;
  c: CHAR;
BEGIN
  n := 0;
  LOOP
      pp := Lib.Environment(n);
      p := 0;
      REPEAT          (* Don't use Str.Copy or it will stop after 126 chars *)
        c := pp^[p];
        result[p] := c;
        INC(p);
      UNTIL (c = 0C) OR (p > HIGH(result));
      IF result[0] = CHR(0) THEN
         RETURN;
      END;
      Str.ItemS(pi,result,' =',0);
      IF Str.Match(pi,name) THEN
         n := Str.CharPos(result, '=');
         IF n=MAX(CARDINAL) THEN
           n := Str.CharPos(result, ' ');
           IF n=MAX(CARDINAL) THEN
             result[0]:=0C;
             RETURN;
           END;
         END;
         Str.Delete(result, 0, n+1);
         RETURN;
      END;
      INC(n);
  END;
END EnvironmentFind;

(*%T _OS2 *)
PROCEDURE Exec ( Path : ARRAY OF CHAR; Command : ARRAY OF CHAR; Env : ExecEnvPtr): CARDINAL;

VAR
    ParamArray: ARRAY [0..2] OF ADDRESS;
BEGIN
    ParamArray[0]:=ADR(Path);
    ParamArray[1]:=ADR(Command);
    ParamArray[2]:=NIL;
    RETURN SPAWN._beget(Path, ADR(ParamArray), Env, CARDINAL(ExecSearchPath));
END Exec;
(*%E *)

(*%T _OS2 *)
  PROCEDURE ExecCmd(command:ARRAY OF CHAR):CARDINAL;
    VAR
      Path              : ARRAY [0..80] OF CHAR;
      Params            : ARRAY [0..3] OF ADDRESS;
    BEGIN
      EnvironmentFind('COMSPEC', Path);
      IF Path[0] = 0C THEN
        Str.Copy(Path, "\CMD.EXE");
      END; (*IF*)
      Params[0] := ADR(Path);
      Params[1] := ADR("/C");
      Params[2] := ADR(command);
      Params[3] := NIL;
      RETURN SPAWN._beget(Path,ADR(Params),NIL,0);
    END ExecCmd;
(*%E *)

CONST
  HistoryMax = 54;

VAR
  HistoryPtr : CARDINAL;
  LowerPtr   : CARDINAL;
  History    : ARRAY [0..HistoryMax] OF CARDINAL;

  PROCEDURE SEED(v:CARDINAL);
    VAR
      x                 : LONGCARD;
      i                 : CARDINAL;
    BEGIN
      HistoryPtr := HistoryMax;
      LowerPtr := 23;
      x := LONGCARD(v);
      i := 0;
      REPEAT
        x := (x*3141592621+17);
        History[i] := CARDINAL(x DIV 10000H);
        INC(i);
      UNTIL i > HistoryMax;
    END SEED;

PROCEDURE RANDOM(Range: CARDINAL) : CARDINAL;
VAR res:CARDINAL;
BEGIN
  IF HistoryPtr = 0 THEN
    IF LowerPtr = 0 THEN
      SEED(12345);
    ELSE
      HistoryPtr := HistoryMax;
      LowerPtr   := LowerPtr-1;
    END;
  ELSE
    HistoryPtr := HistoryPtr-1;
    IF LowerPtr = 0 THEN
      LowerPtr := HistoryMax;
    ELSE
      LowerPtr := LowerPtr-1;
    END;
  END;
  res := History[HistoryPtr]+History[LowerPtr];
  History[HistoryPtr] := res;
  IF Range = 0 THEN
    RETURN res;
  ELSE
    RETURN res MOD Range;
  END;
END RANDOM;

PROCEDURE RANDOMIZE;
(*%T _WINDOWS *)
  BEGIN
    SEED(CARDINAL(Windows.GetCurrentTime()));
(*%E *)

(*%F _WINDOWS *)
(*%T _OS2 *)
VAR d : DATETIME;
    r : CARDINAL;
BEGIN
    r := GetDateTime(d);
    SEED(CARDINAL(d.hundredths)*CARDINAL(d.seconds));
(*%E *)
(*%F _OS2 *)
VAR R : SYSTEM.Registers;
BEGIN
  WITH R DO
    AH := 2CH;
    Lib.Dos(R);
    SEED(DX+CX);
  END;
(*%E *)
(*%E *)
END RANDOMIZE;

PROCEDURE RAND(): REAL;
VAR
  x:RECORD low,high:CARDINAL END;
BEGIN
  x.low := RANDOM(0);
  x.high := RANDOM(0);
  RETURN REAL(LONGCARD(x))/(REAL(MAX(LONGCARD))+1.1);  (* NB Temp Fix *)
END RAND;


  PROCEDURE ParamStr(VAR S: ARRAY OF CHAR; N: CARDINAL);
    BEGIN
      IF N >= CoreMain._argc THEN
        S[0] := 0C;
      ELSE
        Str.Copy(S,CoreMain._argv[N]^);
      END;
    END ParamStr;

PROCEDURE ParamCount() : CARDINAL;

BEGIN
 RETURN CoreMain._argc-1;
END ParamCount;

(*%T _OS2 *)
VAR
  nullp[0:0]  : SIGHANDLER;
  nullac[0:0] : CARDINAL;

PROCEDURE EnableBreakCheck;
BEGIN
  SetSigHandler(SIGHANDLER(0),nullp,nullac,0,SIG_CTRLC);
  SetSigHandler(SIGHANDLER(0),nullp,nullac,0,SIG_CTRLBREAK);
END EnableBreakCheck;

PROCEDURE DisableBreakCheck;
BEGIN
  SetSigHandler(SIGHANDLER(0),nullp,nullac,1,SIG_CTRLC);
  SetSigHandler(SIGHANDLER(0),nullp,nullac,1,SIG_CTRLBREAK);
END DisableBreakCheck;

PROCEDURE Delay(t:CARDINAL);
BEGIN
  Sleep(LONGCARD(t));
END Delay;

PROCEDURE Speaker(FreqHz,TimeMs: CARDINAL);
BEGIN
  Beep(FreqHz,TimeMs);
END Speaker;

(*%E *)

CONST
  MErr = 'Math Error : ';

PROCEDURE MathError(R: LONGREAL; STR: ARRAY OF CHAR);
VAR str : ARRAY[0..40] OF CHAR;
BEGIN
  Str.Concat ( str,MErr,STR );
  RunTimeError(CoreSig._FatalErrorPos(), 0D0H, str);
END MathError;

PROCEDURE MathError2(R1,R2: LONGREAL; STR: ARRAY OF CHAR);
VAR str : ARRAY[0..40] OF CHAR;
BEGIN
  RunTimeError(CoreSig._FatalErrorPos(), 0D1H, str);
END MathError2;

(*%F _OS2 *)
PROCEDURE EnableBreakCheck;
BEGIN
  InternalEnableBreakCheck;
END EnableBreakCheck;


PROCEDURE DisableBreakCheck;
BEGIN
  InternalDisableBreakCheck;
END DisableBreakCheck;

PROCEDURE Environment(N: CARDINAL): CommandType;

TYPE
(*# save *)
(*# data(near_ptr=>off) *)
  CardPtr = POINTER TO CARDINAL;
(*# restore *)
VAR
  Ret: CommandType;
  c: CHAR;
BEGIN
  Ret := [[PSP: 2CH CardPtr]^: 0];
  WHILE N # 0 DO
    IF Ret^[0] = 0C THEN
      RETURN FarNIL;
    END;
    REPEAT
      c := Ret^[0];
      INC(CARDINAL(Ret));
    UNTIL c = 0C;
    DEC(N);
  END;
  RETURN Ret;
END Environment;


PROCEDURE Delay(Time: CARDINAL);
BEGIN
  InternalDelay(Time);
END Delay;

PROCEDURE Speaker(FreqHz,TimeMs: CARDINAL);
BEGIN
  Sound(FreqHz);
  Delay(TimeMs);
  NoSound;
END Speaker;

PROCEDURE Exec(Path:ARRAY OF CHAR;Command:ARRAY OF CHAR;Env:ExecEnvPtr):CARDINAL;
VAR
  Params: ARRAY [0..2] OF ADDRESS;
BEGIN
  Params[0] := ADR(Path);
  Params[1] := ADR(Command);
  Params[2] := NIL;
  RETURN SPAWN._beget(Path,ADR(Params),Env,CARDINAL(ExecSearchPath));
END Exec;

PROCEDURE ExecCmd(command:ARRAY OF CHAR):CARDINAL;
VAR
  Path              : ARRAY [0..80] OF CHAR;
  ComLine           : ARRAY [0..128] OF CHAR;
  p, n              : CARDINAL;
  PBlock            : CoreMain.ParamBlock;
BEGIN
(*%F _ENV*)
  IF CoreMain._fmemsetup THEN
    IF CoreMain._shr_mem() # 0 THEN
      RunTimeError(CoreSig._FatalErrorPos(),4AH,command);
    END; (*IF*)
  END; (*IF*)
(*%E*)
  EnvironmentFind('COMSPEC',Path);
  IF Path[0] = 0C THEN
    Str.Copy(Path,"\COMMAND.COM");
  END; (*IF*)
  ComLine[1] := '/';               (* construct command line *)
  ComLine[2] := 'C';
  ComLine[3] := ' ';
  n := 4;
  p := 0;
  WHILE command[p] # 0C DO
    ComLine[n] := command[p];
    IF n > 127 THEN
      RunTimeError(CoreSig._FatalErrorPos(),4BH,command);
    END; (*IF*)
    INC(p);
    INC(n);
  END; (*WHILE*)
  ComLine[n] := CHR(0DH);
  ComLine[0] := CHR(n);
  PBlock.Com := FarADR(ComLine);
  PBlock.Env := 0;
  IF CoreMain._exec(Path,PBlock) # 0 THEN
    RunTimeError(CoreSig._FatalErrorPos(),4CH,command);
  END; (*IF*)
  IF (CoreMain._fmemsetup) THEN
    CoreMain._res_mem();
  END; (*IF*)
  RETURN CoreMain._get_retcode();
END ExecCmd;


PROCEDURE GetTime ( VAR Hrs,Mins,Secs,Hsecs : CARDINAL );
VAR
  R : SYSTEM.Registers;
BEGIN
  WITH R DO
    AH := 2CH;
(*%T _WINDOWS *)
    DS := Seg(R);
    ES := Seg(R);
(*%E *)
    Lib.Dos(R);
    Hrs   := CARDINAL(CH);
    Mins  := CARDINAL(CL);
    Secs  := CARDINAL(DH);
    Hsecs := CARDINAL(DL);
  END;
END GetTime;

  PROCEDURE SetTime(Hrs,Mins,Secs,Hsecs:CARDINAL):BOOLEAN;
    VAR
      R                 : SYSTEM.Registers;
    BEGIN
      WITH R DO
        AH := 2DH;
        CH := SHORTCARD(Hrs);
        CL := SHORTCARD(Mins);
        DH := SHORTCARD(Secs);
        DL := SHORTCARD(Hsecs);
        Lib.Dos(R);
        RETURN AX=0;
      END; (*WITH*)
    END SetTime;

PROCEDURE GetDate(VAR Year,Month,Day : CARDINAL;
                    VAR DayOfWeek : DayType );
VAR
  R : SYSTEM.Registers;
BEGIN
  WITH R DO
    AH := 2AH;
(*%T _WINDOWS *)
    DS := Seg(R);
    ES := Seg(R);
(*%E *)
    Lib.Dos(R);
    Year := CX;
    Month := CARDINAL(DH);
    Day := CARDINAL(DL);
    DayOfWeek := DayType(AL);
  END;
END GetDate;

  PROCEDURE SetDate(Year,Month,Day:CARDINAL):BOOLEAN;
    VAR
      R                 : SYSTEM.Registers;
    BEGIN
      WITH R DO
        AX := 2B00H;
        CX := Year;
        DH := SHORTCARD(Month);
        DL := SHORTCARD(Day);
(*%T _WINDOWS *)
        DS := Seg(R);
        ES := Seg(R);
(*%E *)
        Lib.Dos(R);
        RETURN AX=0;
      END; (*WITH*)
    END SetDate;

TYPE
    ErrStr = ARRAY [0..79] OF CHAR;
    ErrStrPtr = POINTER TO ErrStr;
    LA3 = ARRAY [0..2] OF SHORTCARD;
CONST
    Ln = LA3(0DH, 0AH, 0);


PROCEDURE WriteErrorString(Err: ErrStrPtr);

VAR
    R: SYSTEM.Registers;
BEGIN
    R.AH := 40H;
    R.BX := 1;
    R.CX := Str.Length(Err^);
    R.DX := Ofs(Err^);
    R.DS := Seg(Err^);
    Dos(R);
END WriteErrorString;
(*%E *)

(*%T _OS2 *)
VAR
  nullstr[0:0] : ARRAY[0..3] OF CHAR;

PROCEDURE Execute (Name        : ARRAY OF CHAR; (* full name of program *)
                   CommandLine : ARRAY OF CHAR; (* command line for program *)
                   StoreAddr   : FarADDRESS;   (* storage to execute in, MSDOS only *)
                   StoreLen    : CARDINAL   (* length of store paragraphs, MSDOS only *)
                  ) : CARDINAL;                 (* DOS reply (0=OK) *)
CONST
  max = 299;
VAR
  retcode:RESULTCODES; ObjNameBuf:ARRAY [0..49] OF CHAR;
  i,j:CARDINAL;
  cline:ARRAY [0..max] OF CHAR;
  Ret: CARDINAL;
BEGIN
  Str.Concat(cline,Name,' ');
  i := Str.Length(cline)-1;
  Str.Append(cline,CommandLine);
  j := Str.Length(cline);
  IF j<max THEN cline[j+1] := 0C END;
  cline[i]:= 0C;
  CoreMath._FloatExecSave;
  Ret := ExecPgm(ObjNameBuf,SIZE(ObjNameBuf),EXEC_SYNC,cline,
                       nullstr,retcode,Name);
  CoreMath._FloatExecRestore;
  RETURN Ret;
END Execute;

PROCEDURE OSErrorMessage ( N : CARDINAL; VAR S : ARRAY OF CHAR );
CONST
  msgpath      = 'OSO001.MSG';
VAR
  dummy,len : CARDINAL;
  msg       : ARRAY[0..255] OF CHAR;
  b         : BOOLEAN;
  i,r       : CARDINAL;
  path      : ARRAY[0..64] OF CHAR;
BEGIN
  IF ProtectedMode() THEN
    r := SearchPath(3,'DPATH',msgpath,FarADR(path),SIZE(path));
  ELSE
    Str.Copy(path,msgpath);
    r := 0;
  END;
  IF (r=0) AND (GetMessage(FarADR(dummy),0,msg,SIZE(msg)-1,N,path,len)=0) THEN
     IF len<SIZE(msg) THEN msg[len] := 0C END;
     Str.Concat(S,'Error: ',msg);
  ELSE
     i := 5;
     msg[i] := 0C;
     REPEAT
       DEC(i);
       msg[i] := CHR(ORD('0')+(N MOD 10));
       N := N DIV 10;
     UNTIL (N=0)OR(i=0);
     WHILE (i>0) DO DEC(i); msg[i] := ' ' END;
     Str.Concat(S,'OS/2 ERROR ',msg);
  END;
END OSErrorMessage;

PROCEDURE OSFatalError( S : ARRAY OF CHAR;
                        N : CARDINAL );
VAR
  msg : ARRAY[0..255] OF CHAR;
BEGIN
  IF N=0 THEN RETURN END;
  OSErrorMessage(N,msg);
  Str.Concat(msg,' ',msg);
  Str.Concat(msg,S,msg);
  RunTimeError(CoreSig._FatalErrorPos(), 0D2H, msg);
END OSFatalError;

PROCEDURE GetTime ( VAR Hrs,Mins,Secs,Hsecs : CARDINAL );

VAR d : DATETIME;
    r : CARDINAL;
BEGIN
    r := GetDateTime(d);
    Hrs   := CARDINAL(d.hours);
    Mins  := CARDINAL(d.minutes);
    Secs  := CARDINAL(d.seconds);
    Hsecs := CARDINAL(d.hundredths);
END GetTime;

PROCEDURE SetTime (Hrs,Mins,Secs,Hsecs : CARDINAL ): BOOLEAN;

VAR d : DATETIME;
    r : CARDINAL;
BEGIN
    r := GetDateTime(d);
    d.hours:=SHORTCARD(Hrs);
    d.minutes:=SHORTCARD(Mins);
    d.seconds:=SHORTCARD(Secs);
    d.hundredths:=SHORTCARD(Hsecs);
    r := SetDateTime(d);
    RETURN BOOLEAN(r);
END SetTime;

PROCEDURE GetDate ( VAR Year,Month,Day : CARDINAL;
                    VAR DayOfWeek : DayType );

VAR d : DATETIME;
    r : CARDINAL;
BEGIN
    r := GetDateTime(d);
    Year := CARDINAL(d.year);
    Month := CARDINAL(d.month);
    Day := CARDINAL(d.day);
    DayOfWeek := DayType(d.weekday);
END GetDate;

PROCEDURE SetDate (Year,Month,Day : CARDINAL): BOOLEAN;

VAR d : DATETIME;
    r : CARDINAL;
BEGIN
    r := GetDateTime(d);
    d.year:=CARDINAL(Year);
    d.month:=SHORTCARD(Month);
    d.day:=SHORTCARD(Day);
    r := SetDateTime(d);
    RETURN BOOLEAN(r);
END SetDate;


TYPE
    ErrStr = ARRAY [0..79] OF CHAR;
    ErrStrPtr = POINTER TO ErrStr;
    LA3 = ARRAY [0..2] OF SHORTCARD;
CONST
    Ln = LA3(0DH, 0AH, 0);

PROCEDURE WriteErrorString(Err: ErrStrPtr);

VAR
    NumWrit: CARDINAL;
BEGIN
    IF Write(1, FarADR(Err^), Str.Length(Err^)+1, NumWrit) = 0 THEN END;
END WriteErrorString;
(*%E *)

PROCEDURE FatalError(S : ARRAY OF CHAR);

BEGIN
    WriteErrorString(ADR(S));
    WriteErrorString(ADR(Ln));
    HALT;
END FatalError;

PROCEDURE WrDosError ( ErrorNo : SHORTCARD );

VAR
    EStr: ErrStrPtr;
    Temp: ARRAY [0..9] OF CHAR;
    OK: BOOLEAN;
BEGIN
  CASE ErrorNo OF
      0  : EStr := ADR('OK');
    | 1  : EStr := ADR('Invalid function number');
    | 2  : EStr := ADR('File not found');
    | 3  : EStr := ADR('Path not found');
    | 4  : EStr := ADR('Too many open files (no handles left)');
    | 5  : EStr := ADR('Access denied');
    | 6  : EStr := ADR('Invalid handle');
    | 7  : EStr := ADR('Memory control blocks destroyed');
    | 8  : EStr := ADR('Insufficient memory');
    | 9  : EStr := ADR('Invalid memory block address');
    | 10 : EStr := ADR('Invalid environment');
    | 11 : EStr := ADR('Invalid format');
    | 12 : EStr := ADR('Invalid access code');
    | 13 : EStr := ADR('Invalid data');
    (*14 : Reserved *)
    | 15 : EStr := ADR('Invalid drive was specified');
    | 16 : EStr := ADR('Attempt to remove the current directory');
    | 17 : EStr := ADR('Not same device');
    | 18 : EStr := ADR('No more files');
    | 19 : EStr := ADR('Attempt to write on write-protected diskette');
    | 20 : EStr := ADR('Unknown unit');
    | 21 : EStr := ADR('Drive not ready');
    | 22 : EStr := ADR('Unknown command');
    | 23 : EStr := ADR('Data error (CRC)');
    | 24 : EStr := ADR('Bad request structure length');
    | 25 : EStr := ADR('Seek error');
    | 26 : EStr := ADR('Unknown media type');
    | 27 : EStr := ADR('Sector not found');
    | 28 : EStr := ADR('Printer out of paper');
    | 29 : EStr := ADR('Write fault');
    | 30 : EStr := ADR('Read fault');
    | 31 : EStr := ADR('General failure');
    | 32 : EStr := ADR('Sharing Violation');
    | 33 : EStr := ADR('Lock Violation');
    | 34 : EStr := ADR('Invalid disk change');
    | 35 : EStr := ADR('FCB unavailable');
    (*36..79 : Reserved *)
    | 80 : EStr := ADR('File exists');
    (*81 : Reserved *)
    | 82 : EStr := ADR('Cannot Make');
    | 83 : EStr := ADR('Fail on INT 24');
    | 0F0H:EStr := ADR('Disk Full (write failed)'); (* JPI internal *)
  ELSE
      WriteErrorString(ADR('Unknown DOS Error : '));
      Str.CardToStr(LONGCARD(ErrorNo), Temp, 4, OK);
      WriteErrorString(ADR(Temp));
      RETURN;
  END;
  WriteErrorString(EStr);
  WriteErrorString(ADR(Ln));
END WrDosError;

(*%F _OS2 *)
PROCEDURE OSErrorMessage ( N : CARDINAL; VAR S : ARRAY OF CHAR );
VAR
  NS : ARRAY[0..5] OF CHAR;
  i : CARDINAL;
  EStr: POINTER TO ErrStr;
BEGIN
  CASE N OF
      0  : EStr := ADR('OK');
    | 1  : EStr := ADR('Invalid function number');
    | 2  : EStr := ADR('File not found');
    | 3  : EStr := ADR('Path not found');
    | 4  : EStr := ADR('Too many open files (no handles left)');
    | 5  : EStr := ADR('Access denied');
    | 6  : EStr := ADR('Invalid handle');
    | 7  : EStr := ADR('Memory control blocks destroyed');
    | 8  : EStr := ADR('Insufficient memory');
    | 9  : EStr := ADR('Invalid memory block address');
    | 10 : EStr := ADR('Invalid environment');
    | 11 : EStr := ADR('Invalid format');
    | 12 : EStr := ADR('Invalid access code');
    | 13 : EStr := ADR('Invalid data');
    (*14 : Reserved *)
    | 15 : EStr := ADR('Invalid drive was specified');
    | 16 : EStr := ADR('Attempt to remove the current directory');
    | 17 : EStr := ADR('Not same device');
    | 18 : EStr := ADR('No more files');
    | 19 : EStr := ADR('Attempt to write on write-protected diskette');
    | 20 : EStr := ADR('Unknown unit');
    | 21 : EStr := ADR('Drive not ready');
    | 22 : EStr := ADR('Unknown command');
    | 23 : EStr := ADR('Data error (CRC)');
    | 24 : EStr := ADR('Bad request structure length');
    | 25 : EStr := ADR('Seek error');
    | 26 : EStr := ADR('Unknown media type');
    | 27 : EStr := ADR('Sector not found');
    | 28 : EStr := ADR('Printer out of paper');
    | 29 : EStr := ADR('Write fault');
    | 30 : EStr := ADR('Read fault');
    | 31 : EStr := ADR('General failure');
    | 32 : EStr := ADR('Sharing Violation');
    | 33 : EStr := ADR('Lock Violation');
    | 34 : EStr := ADR('Invalid disk change');
    | 35 : EStr := ADR('FCB unavailable');
    (*36..79 : Reserved *)
    | 80 : EStr := ADR('File exists');
    (*81 : Reserved *)
    | 82 : EStr := ADR('Cannot Make');
    | 83 : EStr := ADR('Fail on INT 24');
    | 0F0H:EStr := ADR('Disk Full (write failed)'); (* JPI internal *)
  ELSE
      Str.Copy(S,'Unknown DOS Error : ');
      NS := '     ';
      i := 4;
      REPEAT
        NS[i] := CHR(48+N MOD 10);
        DEC(i);
        N := N DIV 10;
      UNTIL N=0;
      Str.Append(S,NS);
      RETURN;
  END;
  Str.Copy(S, EStr^);
END OSErrorMessage;

PROCEDURE OSFatalError   ( S : ARRAY OF CHAR; N : CARDINAL );
VAR
  S2:ARRAY[0..127] OF CHAR;
BEGIN
  OSErrorMessage(N,S2);
  Str.Concat(S2,S,S2);
  WriteErrorString(ADR(S2));
  RunTimeError(CoreSig._FatalErrorPos(), 0D2H, S);
END OSFatalError;
(*%E *)

PROCEDURE SysErrno(): CARDINAL;

VAR
    EP: CoreSig.ErrnoPtr;
BEGIN
    EP:=CoreSig._errno__();
    RETURN CARDINAL(EP^);
END SysErrno;

PROCEDURE RunTimeErrorHandler(ErrAdd: LONGCARD; Code: CARDINAL; Msg: ARRAY OF CHAR);

BEGIN
    WriteErrorString(ADR(Msg));
    WriteErrorString(ADR(Ln));
    CoreSig._FatalError(ErrAdd, Code);
END RunTimeErrorHandler;


PROCEDURE MakeAllPath(VAR Path: ARRAY OF CHAR; Drive, Dir, Name, Ext: ARRAY OF CHAR);

VAR
   Pos: CARDINAL;
BEGIN
    Str.Copy(Path, Drive);
    IF Dir[0] # CHAR(0) THEN
        Str.Append(Path, Dir);
        Pos:=Str.Length(Path)-1;
        IF NOT((Path[Pos] = '\') OR (Path[Pos] = '/')) THEN
            Path[Pos+1]:='\';
            Path[Pos+2]:=CHAR(0);
        END;
    END;
    Str.Append(Path, Name);
    IF Ext[0] # CHAR(0) THEN
        IF Ext[0] # '.'THEN
            Pos:=Str.Length(Path);
            Path[Pos]:='.';
            Path[Pos+1]:=CHAR(0);
        END;
        Str.Append(Path, Ext);
    END;
    RETURN;
END MakeAllPath;

PROCEDURE SplitAllPath(Path: ARRAY OF CHAR; VAR Drive: ARRAY OF CHAR;
                    VAR Dir: ARRAY OF CHAR; VAR Name: ARRAY OF CHAR; VAR Ext: ARRAY OF CHAR);

VAR
    n, p: CARDINAL;
    Dir_start, Name_start, Ext_start, Path_end: CARDINAL;
    c: CHAR;
BEGIN
    n := 0;
    IF (Path[0] # 0C) AND ((Path[1] = ':') OR (Path[2] = ':')) THEN
      REPEAT
        c := Path[n];
        Drive[n] := c;
        INC(n);
      UNTIL ((c = ':') OR (n > HIGH(Drive)));
    END;
    IF n <= HIGH(Drive) THEN
      Drive[n] := 0C;
    END;
    Dir_start := n;
    Name_start := n;
    Ext_start := MAX(CARDINAL);
    LOOP
      c := Path[n];
      IF c = 0C THEN EXIT END;
      CASE c OF
       | '.' :
          IF(NOT((Path[n+1] = '.') OR (Path[n+1] = '\') OR (Path[n+1] = '/'))) THEN
            Ext_start := n;
          END;
          INC(n);
       | '/', '\' :
          INC(n);
          Name_start := n;
       ELSE
          INC(n);
      END;
    END;
    Path_end := n;
    IF Ext_start = MAX(CARDINAL) THEN
      Ext_start := n;
    END;
    n:= Dir_start;
    p := 0;
    WHILE ((n < Name_start) AND (p <= HIGH(Dir)) AND (n<Ext_start)) DO
      Dir[p] := Path[n];
      INC(p);
      INC(n);
    END;
    IF p <= HIGH(Dir) THEN
      Dir[p] := 0C;
    END;
    n := Name_start;
    p := 0;
    WHILE (n < Ext_start) AND (p <= HIGH(Name)) DO
      Name[p] := Path[n];
      INC(n);
      INC(p);
    END;
    IF p <= HIGH(Name) THEN
      Name[p] := 0C;
    END;
    p := 0;
    IF(Ext_start >= Name_start) THEN
      n := Ext_start;
      WHILE (n < Path_end) AND (p <= HIGH(Ext)) DO
        Ext[p] := Path[n];
        INC(n);
        INC(p);
      END;
    END;
    IF p <= HIGH(Ext) THEN
      Ext[p] := 0C;
    END;
END SplitAllPath;

(*%F _OS2 *)
TYPE
(*# save,data(near_ptr=>off) *)
  FarCharPtr = POINTER TO CHAR;
(*# restore *)
VAR
  n: CARDINAL;
BEGIN
  HistoryPtr     := 0;
  LowerPtr       := 0;
  ExecSearchPath := TRUE;
  NilStr[0]      := 0C;
(*%F _WINDLL *)
  PSP            := CoreMain._psp;
  [PSP: 81H+CARDINAL([PSP:80H FarCharPtr]^) FarCharPtr]^ := 0C;
  CommandLine    := [PSP: 81H CommandType];
  n := 0;
  WHILE CommandLine^[n] = ' ' DO
    INC(n);
  END;
  INC(CARDINAL(CommandLine),n);
(*%E *)
  RunTimeError   := RunTimeErrorHandler;
(*%E *)

(*%T _OS2 *)
(*# save *)
(*# data(near_ptr=>off) *)
TYPE bp=POINTER TO SHORTCARD;
     wp=POINTER TO CARDINAL;
(*# restore *)

VAR
  seg, ofs, lim, n : CARDINAL;

BEGIN
  HistoryPtr := 0;
  LowerPtr   := 0;
  ExecSearchPath := TRUE;
  NilStr[0]  := 0C;
  IF (GetEnv(seg,ofs)=0) THEN END;
(*%F _XTD *)
  lim := SelectorLimit(seg);
  LOOP
    INC(ofs);
    IF ofs>lim THEN (* bug in 1.0/Codeview *)
        ofs := 1;
        [seg:0 wp]^ := 0;
        [seg:2 wp]^ := 0;
        EXIT;
    END;
    IF [seg:ofs-1 bp]^ = 0 THEN EXIT END;
  END;
  CommandLine := [seg:ofs];
  IF CommandLine # FarNIL THEN
    n := 0;
    WHILE CommandLine^[n] = ' ' DO
      INC(n);
    END;
    INC(CARDINAL(CommandLine), n);
  END;
(*%E *)
(*%T _XTD*)
  WHILE [seg:ofs bp]^ # 0 DO
    INC(ofs);
  END; (*WHILE*)
  REPEAT
    INC(ofs);
  UNTIL [seg:ofs bp]^ # 20H;
  CommandLine := [seg:ofs];
  PSP := CoreMain._psp;
(*%E*)
  RunTimeError:=RunTimeErrorHandler;
(*%E *)
END Lib.
