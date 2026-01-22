(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  PROCESS.MOD - Multi-process support                                     *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*# call(seg_name => PROCESS) *)
(*# module(implementation=>off) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)
(*# call(o_a_copy=>off) *)


IMPLEMENTATION MODULE Process;

(*%F _OS2 *)
FROM Storage IMPORT ALLOCATE;
IMPORT SYSTEM, Storage, Lib, CoreSig, CoreProc;

TYPE

  SIGNAL = POINTER TO SigRec;


(* change to task descriptor *)

  SigRec = RECORD
             count   : INTEGER;
             waiting : CoreProc.Task;
           END;


PROCEDURE QInsert(T: CoreProc.Task; VAR Q: CoreProc.Task);
(* inserts task after last task in Q with greater or equal priority *)
VAR
  q,qb : CoreProc.Task;
BEGIN
  q  := Q;
  qb := NIL;
  WHILE (q<>NIL)AND(T^.priority<=q^.priority) DO
    qb := q;
    q := q^.next;
  END;
  IF qb=NIL THEN
    Q := T;
  ELSE
    qb^.next := T;
  END;
  T^.next := q;
END QInsert;


PROCEDURE AddReadyProcess(T: CoreProc.Task);
(* adds new process to ready list
   NB gets added ahead of current process if at same priority
*)
VAR
  mp    : SYSTEM.PROCESS;
  oldcp : CoreProc.Task;
  ie    : CARDINAL;
BEGIN
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
  IF CoreProc._cp=NIL THEN
    QInsert(T,CoreProc._cp);          (* add new process *)
  ELSE
    oldcp := CoreProc._cp;            (* remove current process *)
    CoreProc._cp := CoreProc._cp^.next;
    QInsert(T,CoreProc._cp);          (* add new process *)
    QInsert(oldcp,CoreProc._cp);      (* add current process *)
  END;
  mp := CoreProc._cp^.cor;
  SYSTEM.TRANSFER (mp,mp);
  SYSTEM.SetFlags(ie);
END AddReadyProcess;



  PROCEDURE StartProcess(P:PROC;N,Pr:CARDINAL);
    VAR
      np                : CoreProc.Task;
    BEGIN
      INC(Pr);
      IF N < 32000 THEN
        INC(N, 512);                                       (* FP Overhead *)
      END; (*IF*)
      Storage.ALLOCATE(np,SIZE(CoreProc.TaskDescriptor));
      Storage.ALLOCATE(np^.wsp,N);
      np^.priority := Pr;
      np^.wspsize  := N;
      SYSTEM.NEWPROCESS(P,np^.wsp,N,np^.cor);
      AddReadyProcess(np);
    END StartProcess;

(* new stop me procedure *)

PROCEDURE StopProcess;
VAR
  t0 : CoreProc.Task;
  mp : SYSTEM.PROCESS;
  ie : CARDINAL;
BEGIN
  CoreProc._ProcIds[CoreProc._getTID()-1] := 0;
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
  t0 := CoreProc._cp ;
  CoreProc._cp := CoreProc._cp^.next;
  Storage.DEALLOCATE(t0^.wsp,t0^.wspsize);
  Storage.DEALLOCATE(t0,SIZE(CoreProc.TaskDescriptor));
  mp := CoreProc._cp^.cor;
  SYSTEM.TRANSFER (mp,mp);
  SYSTEM.SetFlags(ie);
END StopProcess;



PROCEDURE SEND(s: SIGNAL);
VAR
  t0 : CoreProc.Task;
  ie : CARDINAL;
BEGIN
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
  IF s^.count <> MAX(INTEGER) THEN
    INC(s^.count);
    IF s^.count <= 0 THEN (* somebody waiting *)
      t0 := s^.waiting;
      s^.waiting := t0^.next;
      AddReadyProcess(t0);
    END;
  END;
  SYSTEM.SetFlags(ie);
END SEND;


PROCEDURE Notify(s: SIGNAL);
VAR
  t0 : CoreProc.Task;
  ie : CARDINAL;
BEGIN
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
  IF s^.count < 0 THEN (* somebody waiting *)
    INC(s^.count);
    t0 := s^.waiting;
    s^.waiting := t0^.next;
    (* add to waiting q *)
    t0^.nextdue := CoreProc._wq;
    CoreProc._wq := t0;
  END;
  SYSTEM.SetFlags(ie);
END Notify;


PROCEDURE WAIT (s: SIGNAL);
VAR
  t0 : CoreProc.Task;
  mp : SYSTEM.PROCESS;
  ie : CARDINAL;
BEGIN (* insert CoreProc._cp in queue s *)
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
  DEC(s^.count);
  IF s^.count < 0 THEN (* wait *)
    t0 := CoreProc._cp;
    CoreProc._cp := CoreProc._cp^.next;
    QInsert(t0,s^.waiting);
    mp := CoreProc._cp^.cor;
    SYSTEM.TRANSFER (mp,mp);
  END;
  SYSTEM.SetFlags(ie);
END WAIT;

PROCEDURE Awaited(s: SIGNAL) : BOOLEAN;
BEGIN
  RETURN (s^.count<0);
END Awaited;


PROCEDURE Init(VAR s: SIGNAL);
BEGIN
  NEW(s);
  s^.waiting := NIL;
  s^.count := 0;
END Init;


PROCEDURE CheckTimeQ;
VAR
  ta,tb,tn : CoreProc.Task;
BEGIN
  ta := CoreProc._dq;
  tb := NIL;
  WHILE ta <> NIL DO
    tn := ta^.nextdue;
    IF ta^.due = CoreProc._SchedTime THEN
      IF tb = NIL THEN CoreProc._dq := tn ELSE tb^.nextdue := tn END;
      ta^.nextdue := CoreProc._wq;
      CoreProc._wq := ta;
    ELSE
      tb := ta;
    END;
    ta := tn;
  END;
END CheckTimeQ;

PROCEDURE Slice;
(* Clears waiting queue *)
(* Then schedules next ready process if it is of equal priority *)
VAR
  nextt,oldt,ta : CoreProc.Task;
BEGIN
  IF CoreProc._LockNestMonster = 0 THEN
    (* move waiting queue to the ready queue *)
    (* set up by CheckTimeQueue *)
    WHILE CoreProc._wq <> NIL DO
      ta := CoreProc._wq; CoreProc._wq := CoreProc._wq^.nextdue;
      QInsert(ta,CoreProc._cp);
    END;
    (* now do slice *)
    nextt := CoreProc._cp^.next;
    IF (nextt <> NIL) AND (nextt^.priority = CoreProc._cp^.priority) THEN (* slice *)
      oldt := CoreProc._cp; CoreProc._cp := nextt;
      QInsert(oldt,CoreProc._cp); (* insert old CoreProc._cp at end of processes *)
    END;
  END;
END Slice;


MODULE SS[1]; (* IRQ 1: timer interrupt *)

 IMPORT SYSTEM;
 IMPORT CoreProc,Slice,CheckTimeQ;
 EXPORT Scheduler;


PROCEDURE Scheduler;
VAR
  nextt,
  oldt  : CoreProc.Task;
  op,np : SYSTEM.PROCESS;
  Int8  : PROC;

TYPE
  code  = ARRAY[0..2] OF SHORTCARD;

CONST
  Int8code = code(0CDH,08H,0CBH); (* INT 08H / RETF *)

BEGIN
  SYSTEM.DI;
  Int8 := PROC(ADR(Int8code));
  CoreProc.Stop := FALSE;
  CoreProc._SchedTime := 0;
  LOOP
    np := CoreProc._cp^.cor;
    LOOP
      SYSTEM.IOTRANSFER(op,np,8);
      Int8;
      INC(CoreProc._SchedTime);
      IF CoreProc.Stop THEN EXIT END;
      CheckTimeQ;
      Slice;
      np := CoreProc._cp^.cor;
    END;
    CoreProc.Stop := FALSE;
    SYSTEM.TRANSFER(op,np); (* no return until restarted *)
  END;
END Scheduler;


END SS;


PROCEDURE Idler; (* always on CoreProc._cp chain *)
VAR
  i : CARDINAL;
BEGIN
  LOOP INC(i);
  END;
END Idler;

PROCEDURE StartScheduler;
VAR
  ie : CARDINAL;
BEGIN
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
  IF NOT CoreProc._Started THEN
    CoreProc._Started := TRUE;
    IF CoreProc._SchedStack = NIL THEN (* first time *)
      Storage.ALLOCATE( CoreProc._SchedStack, 1024 );
      SYSTEM.NEWPROCESS( Scheduler, CoreProc._SchedStack, 1024, CoreProc._SchedProc );
    END;
    SYSTEM.TRANSFER( CoreProc._cp^.cor, CoreProc._SchedProc );
  END;
  SYSTEM.SetFlags(ie);
END StartScheduler;

PROCEDURE StopScheduler;
VAR
  ie : CARDINAL;
BEGIN
  ie := SYSTEM.GetFlags();
  IF CoreProc._Started THEN
    SYSTEM.EI ;
    CoreProc._Started := FALSE;
    CoreProc.Stop := TRUE;
    WHILE CoreProc.Stop DO END;
  END;
  SYSTEM.SetFlags(ie);
END StopScheduler;

PROCEDURE Delay(T: CARDINAL);
(* Waits T time slices *)
(* 0 will swap to next process of equal priority, without delaying *)
VAR
  mp : SYSTEM.PROCESS;
  ie : CARDINAL;
BEGIN
  IF NOT CoreProc._Started THEN RETURN END;
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
  IF T = 0 THEN
    mp := CoreProc._cp^.cor;
    Slice;
    IF mp = CoreProc._cp^.cor THEN
      SYSTEM.SetFlags(ie);
      RETURN
    END; (* no other processes ready *)
  ELSE
    CoreProc._cp^.due := CoreProc._SchedTime + T;
    CoreProc._cp^.nextdue := CoreProc._dq;
    CoreProc._dq := CoreProc._cp;
    CoreProc._cp := CoreProc._cp^.next;
  END;
  mp := CoreProc._cp^.cor;
  SYSTEM.TRANSFER(mp,mp);
  SYSTEM.SetFlags(ie);
END Delay;


PROCEDURE Lock;
(* Critical region lock - prevents timeslicing *)
(* may be nested *)
BEGIN
  INC(CoreProc._LockNestMonster);
END Lock;

PROCEDURE Unlock;
(* Unlock procedure, always paired with a call to Lock.
   Will de-schedule current process if there are ready processes
   of equal priority *)

VAR
  ie : CARDINAL;
BEGIN
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
  IF CoreProc._LockNestMonster <= 1 THEN
    CoreProc._LockNestMonster := 0; Delay(0);
  ELSE
    DEC(CoreProc._LockNestMonster);
  END;
  SYSTEM.SetFlags(ie);
END Unlock;


BEGIN
  IF CoreProc._proc_init = FALSE THEN
      SYSTEM.initprocess();
      CoreProc._dq := NIL;
      CoreProc._wq := NIL;
      Storage.ALLOCATE(CoreProc._cp, SIZE(CoreProc.TaskDescriptor));
      IF CoreProc._cp = NIL THEN
          CoreSig._FatalError(CoreSig._FatalErrorPos(), 044H);
      END;
      CoreProc._cp^.next := NIL;
      CoreProc._cp^.priority := 2;
      CoreProc._cp^.cor  := SYSTEM.CurrentProcess();
      CoreProc._NextThread:=2;
      StartProcess( Idler, 512, MAX(CARDINAL));
      CoreProc._SchedStack := NIL;
      CoreProc._Started  := FALSE;
      CoreProc._LockNestMonster := 0;
      CoreProc._exit_proc:=StopScheduler;
  END;
  CoreProc._core_lock:=Lock;
  CoreProc._core_unlock:=Unlock;
  CoreProc._core_delay := Delay;
(*%E *)

(*%T _OS2 *)
IMPORT Storage, Lib, Str, Dos, CoreProc, CoreSig;
FROM Storage IMPORT ALLOCATE;

TYPE

  SIGNAL = POINTER TO SigRec;

  SigRec = RECORD
             count   : INTEGER;
             sem     : LONGCARD;
           END;

PROCEDURE ErrorNamed ( IOR   : CARDINAL; Code: CARDINAL; Msg: ARRAY OF CHAR);
VAR
  s  : ARRAY[0..100] OF CHAR;

BEGIN
  IF IOR#0 THEN
    Lib.RunTimeError(CoreSig._FatalErrorPos(), Code, Msg);
  END;
END ErrorNamed;


PROCEDURE StartScheduler;
VAR i : [0..MaxProcess];
BEGIN
  Lock;
  FOR i := 1 TO MaxProcess DO
      IF CoreProc._ProcIds[i] # 0 THEN ErrorNamed(Dos.ResumeThread(CoreProc._ProcIds[i]), 0C0H, 'DosResumeThread') END;
  END;
  CoreProc._Started := TRUE;
  Unlock;
END StartScheduler;

PROCEDURE StartProcess(P: PROC; N: CARDINAL; Pr: CARDINAL);

VAR
  ID: CARDINAL;
BEGIN
  Lock;
  DEC(Pr);
  INC(CoreProc._LastProc);
  IF CoreProc._LastProc = MaxProcess THEN
    ErrorNamed(0, 0C0H, 'StartProcess');
  END;
  IF N < 32000 THEN
    INC(N, 512);                            (* FP Overhead *)
  END;
  ID := CoreProc._dosbeginthread(P, N, NIL);
  IF ID < 0 THEN
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 0C1H, Lib.NilStr);
  END;
  CoreProc._ProcIds[ID-1] := ID;
  ErrorNamed(Dos.SetPrty(2,0,INTEGER(Pr),ID), 0C2H, 'DosSetPrty');
  IF NOT CoreProc._Started THEN
    ErrorNamed(Dos.SuspendThread(ID), 0C3H, 'DosSuspendThread');
  END;
  Unlock;
END StartProcess;


PROCEDURE StopProcess();

BEGIN
  CoreProc._ProcIds[CoreProc._getTID()-1] := 0;
  CoreProc._dosendthread();
END StopProcess;

PROCEDURE StopScheduler();

BEGIN
END StopScheduler;


PROCEDURE SEND(s: SIGNAL);
BEGIN
  Lock;
  IF s^.count < 0 THEN
     ErrorNamed(Dos.SemClear(FarADR(s^.sem)), 0C4H, 'DosSemClear');;
  END;
  INC(s^.count);
  Unlock;
END SEND;

PROCEDURE WAIT(s: SIGNAL);
BEGIN
  Lock;
  DEC(s^.count);
  IF s^.count < 0 THEN
     Unlock;
     ErrorNamed(Dos.SemRequest(FarADR(s^.sem),-1), 0C5H, 'DosSemRequest');
  ELSE
     Unlock;
  END;
END WAIT;

PROCEDURE Notify(s: SIGNAL);
BEGIN
  Lock;
  IF s^.count < 0 THEN
     ErrorNamed(Dos.SemClear(FarADR(s^.sem)), 0C6H, 'DosSemClear');
     INC(s^.count);
  END;
  Unlock;
END Notify;

PROCEDURE Awaited(s: SIGNAL) : BOOLEAN;
BEGIN
  RETURN s^.count < 0;
END Awaited;


PROCEDURE Lock;
VAR
 tid : CARDINAL ;
BEGIN
 tid := CoreProc._getTID();
 IF (CoreProc._LockCount=0)OR(CoreProc._LockedThread<>tid) THEN
    IF Dos.SemRequest(FarADR(CoreProc._LockSem),-1)=0 THEN END;
    CoreProc._LockedThread := tid ;
 END;
 INC(CoreProc._LockCount);
END Lock;

PROCEDURE Unlock;
BEGIN
  DEC(CoreProc._LockCount);
  IF CoreProc._LockCount=0 THEN
    IF Dos.SemClear(FarADR(CoreProc._LockSem))=0 THEN END;
    IF Dos.Sleep(0)=0 THEN END;
  END;
END Unlock;


PROCEDURE Init(VAR s: SIGNAL);
BEGIN
  NEW(s);
  s^.sem := 0;
  ErrorNamed(Dos.SemSet(FarADR(s^.sem)), 0C7H, 'DosSemSet');
  s^.count := 0;
END Init;

PROCEDURE Delay(T: CARDINAL);
BEGIN
  ErrorNamed(Dos.Sleep(LONGCARD(T)*50), 0C8H, 'DosSleep');
END Delay;

PROCEDURE Idler();

END Idler;

BEGIN
  CoreProc._Started := FALSE;
  CoreProc._LastProc := 0;
  CoreProc._LockCount := 0;
  CoreProc._LockSem := 0;
  CoreProc._LockedThread := 0 ;
  CoreProc._core_lock := Lock;
  CoreProc._core_unlock := Unlock;
  CoreProc._core_delay := Delay;
  CoreProc._NextThread:=2;
(*%E *)

END Process.
