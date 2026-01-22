(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  SYSTEM.MOD - Machine-level support                                      *
*                                                                          *
*  COPYRIGHT (C) 1988..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*# data(seg_name => null) *)
(*%E *)
(*# module(implementation=>off) *)
(*# call(o_a_copy => off) *)
(*# check(stack=>off,index=>off,range=>off,overflow=>off,nil_ptr=>off) *)

IMPLEMENTATION MODULE SYSTEM;
(*%F _OS2 *)
IMPORT CoreMain;
(*%E *)
(*%T _OS2 *)
IMPORT Lib,Dos,CoreSig,CoreMath;
(*%E *)

(*%F _OS2 *)
PROCEDURE NEWPROCESS(P: PROC; A: FarADDRESS; S: CARDINAL; VAR P1: FarADDRESS); IN CoreProc;
PROCEDURE TRANSFER  (VAR P1,P2: FarADDRESS); IN CoreProc;
PROCEDURE IOTRANSFER (VAR P1,P2: FarADDRESS; I: CARDINAL); IN CoreProc;
PROCEDURE CurrentProcess():ADDRESS; IN CoreProc;
PROCEDURE initprocess(); IN CoreProc;
PROCEDURE CurrentPriority() : CARDINAL; IN CoreProc;
PROCEDURE NewPriority(PR: CARDINAL); IN CoreProc;
PROCEDURE Listen(Mask: BITSET); IN CoreProc;
PROCEDURE InterruptRegisters(P: FarADDRESS): FarADDRESS; IN CoreProc;
(*%E *)

(*%T _OS2 *)
CONST
  OS2MaxThreads = 64;

VAR
  ProcessSem : ARRAY[1..OS2MaxThreads] OF LONGCARD;
               (* ADR(ProcessSem[T]) is process id and HSEM *)

  LaunchSem  : LONGCARD; (* Set when launching new process *)
  LaunchProc : PROC;
  LI         : Dos.PLINFOSEG;


(*# save *)
(*# call(near_call=>off, reg_param=>(), reg_saved=>(di,si,ds,st1,st2)) *)
PROCEDURE Launch; (* Stub to launch new process *)
                  (* Input LaunchProc *)
VAR
  p  : Dos.THREAD;
  mp : Dos.HSEM;
  r  : CARDINAL;
BEGIN
  mp := FarADR(ProcessSem[LI^.tidCurrent]);
  p := Dos.THREAD(LaunchProc);
  r := Dos.SemSet(mp);
  r := Dos.SemClear(FarADR(LaunchSem));
  r := Dos.SemWait(mp,Dos.SEM_INDEFINITE_WAIT);
  p();
  Lib.RunTimeError(CoreSig._FatalErrorPos(), 0CDH, Lib.NilStr);
END Launch;
(*#restore *)

PROCEDURE NEWPROCESS(P: PROC; A: FarADDRESS; S: CARDINAL; VAR P1: FarADDRESS);
VAR mp    : Dos.HSEM;
    r     : CARDINAL;
    tid   : CARDINAL;
BEGIN
(*%T _mthread *)
  CoreMath._FloatInitInstance(CARDINAL(LONGCARD(A) >> 16));
  INC(CARDINAL(A),S);
  r := Dos.SemRequest(FarADR(LaunchSem),Dos.SEM_INDEFINITE_WAIT);
  LaunchProc := P;
  IF  Dos.CreateThread(Launch,tid,A) # 0 THEN   (* Start process *)
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 0CAH, Lib.NilStr);
  END;
  IF tid>OS2MaxThreads THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 0CBH, Lib.NilStr);
  END;
  r := Dos.SemWait(FarADR(LaunchSem),Dos.SEM_INDEFINITE_WAIT);
  P1 := FarADR(ProcessSem[tid]);
(*%E *)
END NEWPROCESS;

PROCEDURE TRANSFER  (VAR P1,P2: FarADDRESS);
VAR mp,pp : Dos.HSEM;
    r : CARDINAL ;
BEGIN
(*%T _mthread *)
  pp := P2;
  mp := FarADR(ProcessSem[LI^.tidCurrent]);
  P1 := mp;
  r := Dos.SemSet(mp);
  r := Dos.SemClear(pp);
  r := Dos.SemWait(mp,Dos.SEM_INDEFINITE_WAIT);
(*%E *)
END TRANSFER;

PROCEDURE IOTRANSFER (VAR P1,P2: FarADDRESS; I: CARDINAL);
VAR mp,pp : Dos.HSEM;
    r : CARDINAL ;
BEGIN
(*%T _mthread *)
  IF (I<>8) THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 0CCH, Lib.NilStr);
  END;
  pp := P2;
  mp := FarADR(ProcessSem[LI^.tidCurrent]);
  P1 := mp;
  r := Dos.SemSet(mp);
  r := Dos.SemClear(pp);
  r := Dos.SemWait(mp,20);
  P2 := FarADR(ProcessSem[LI^.tidCurrent]);
(*%E *)
END IOTRANSFER;


PROCEDURE CurrentProcess() : ADDRESS;
BEGIN
  RETURN ADR(ProcessSem[LI^.tidCurrent]);
END CurrentProcess;

PROCEDURE initprocess();

BEGIN

END initprocess;

PROCEDURE CurrentPriority() : CARDINAL;

TYPE
  PrType = RECORD
     CASE:  BOOLEAN OF
       | TRUE :
         var: CARDINAL;
       | FALSE :
         pl, pc: SHORTCARD;
     END;
  END;
VAR
  Pr: PrType;
BEGIN
  Dos.GetPrty(2, Pr.var, 0);
  RETURN CARDINAL(Pr.pl);
END CurrentPriority;

PROCEDURE NewPriority(PR: CARDINAL);

BEGIN
  Dos.SetPrty(2, 0, PR, 0);
END NewPriority;

PROCEDURE Init;
VAR i,g,l : CARDINAL;
BEGIN
  FOR i := 1 TO OS2MaxThreads DO ProcessSem[i] := 0 END;
  LI := FarNIL;
  IF Lib.ProtectedMode() THEN
    Dos.GetInfoSeg(g,l);
    LI := [l:0];
  END;
END Init;

PROCEDURE Listen(Mask: BITSET);

BEGIN
END Listen;

PROCEDURE InterruptRegisters(P: FarADDRESS): FarADDRESS;

BEGIN
  RETURN FarNIL;
END InterruptRegisters;

(*%E*)

VAR
  HB: FarADDRESS;

BEGIN
(*%F _OS2 *)
  HB := CoreMain._getheapbase();
  HeapBase := Seg(HB^);
(*%T _mthread *)
  initprocess();
(*%E *)
(*%E *)
(*%T _OS2 *)
  Init;
(*%E *)
END SYSTEM.

