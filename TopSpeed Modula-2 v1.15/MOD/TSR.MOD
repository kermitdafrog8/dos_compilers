(*========================================================
== JPI Modula-2 demo program:                           ==
==                                                      ==
==        TSR Shell                                     ==
==                                                      ==
== Installs a "safe" Pop Up program                     ==
==                                                      ==
========================================================*)



IMPLEMENTATION MODULE TSR ;
                   (* ======== *)

IMPORT IO,Window,Lib,Storage,Str;

FROM   SYSTEM IMPORT PROCESS,NEWPROCESS,TRANSFER,EI,DI,GetFlags,SetFlags,
                     Registers,CarryFlag,HeapBase,Seg,Ofs,In,Out ;


VAR
      ProgDTA             : ADDRESS ;
      ProgPSP             : CARDINAL ;
      DosNest             : POINTER TO SHORTCARD ;
      ActivateScan        : SHORTCARD ;
      ActivateFlags       : KBFlagSet ;
      KBFlags[40H:17H]    : KBFlagSet ;
      TSRproc             : PROC ;

(*$W+*) (* Keep volatile variables in memory *)

CONST
    KBFuseful = KBFlagSet { RShift, LShift, Ctrl, Alt } ;

TYPE
    TSRmodeType = (Sleeping,Wake,Active,Kill,Dead ) ;
VAR
    TSRmode                 : TSRmodeType ;
    MainProcess             : PROCESS;

(*$W=*) (* Restore volatile setting *)

TYPE
     IPROC   = PROCEDURE ( (* flags : *) BITSET ) ; (* Interrupt Proc *)

VAR

  Irpt[0:0],   (* Interrupt table *)
  SaveIrpt   : ARRAY [0..255] OF IPROC ;

PROCEDURE SetIrpt ( N : CARDINAL ; P : IPROC ) ;
VAR
  fl : CARDINAL ;
BEGIN
  fl := GetFlags() ; DI ;
  SaveIrpt[N] := Irpt[N] ;
  Irpt[N] := P ;
  SetFlags(fl) ;
END SetIrpt ;

PROCEDURE ResetIrpt ( N : CARDINAL ) ;
VAR
  fl : CARDINAL ;
BEGIN
  fl := GetFlags() ; DI ;
  Irpt[N] := SaveIrpt[N] ;
  SetFlags(fl) ;
END ResetIrpt ;


PROCEDURE SwapToTSR ;
VAR
   op,np : PROCESS ;
BEGIN
   TSRmode := Active ;
   np := MainProcess ;
   TRANSFER(op,np) ; (* can't use IOTRANSFER due to chaining problems
                        with other TSRs (SideKick 1, for example) *)
   TSRmode := Sleeping ;
END SwapToTSR ;


(* Interrupt Handlers *)
(* ================== *)

(*$C FF,J+*) (* Save all registers and generate IRETs *)

PROCEDURE NullInt ( flags : BITSET ) ; (* Do nothing interrupt *)
BEGIN
END NullInt;

PROCEDURE Int9 ( flags : BITSET ) ; (* Keyboard H/W interrupt *)
VAR
  sc : SHORTCARD ;
BEGIN
  sc := In(60H) ;
  IF ((sc=ActivateScan)OR(ActivateScan=0))AND
     ((KBFlags*KBFuseful)=ActivateFlags) THEN
    sc := In(61H) ;
    Out(61H,SHORTCARD(BITSET(sc)+{7}));
    Out(61H,sc);
    Out(20H,20H);
    IF TSRmode=Sleeping THEN
      TSRmode := Wake ;
    END ;
  ELSE
    SaveIrpt[09H](BITSET(GetFlags())) ; (* Chain Int 28 *)
  END ;
END Int9 ;

VAR
  Save28stack : ARRAY[0..3FFH] OF BYTE ;

PROCEDURE Int28 ( flags : BITSET ) ; (* DOS "I'm not doing much" interrupt *)
VAR
   base : CARDINAL ;
BEGIN
   Lib.Move(ADR(base),ADR(Save28stack),SIZE(Save28stack));
   SaveIrpt[28H](BITSET(GetFlags())) ; (* Chain Int 28 *)
   IF (Ofs(flags)>100H) AND (TSRmode=Wake) THEN
     SwapToTSR ;
   END ;
   Lib.Move(ADR(Save28stack),ADR(base),SIZE(Save28stack));
END Int28 ;


PROCEDURE Int1C ( flags : BITSET ) ; (* Timer Interrupt *)
BEGIN
   SaveIrpt[1CH](BITSET(GetFlags())) ; (* Chain Int 1C *)
   IF (Ofs(flags)>100H)AND(DosNest^ = 0)AND(TSRmode=Wake) THEN
     Out(20H,20H) ; (* Send EOI to timer *)
     SwapToTSR ;
   END ;
END Int1C ;

(*$C FE*) (* Save all registers (except AX : function result) *)
PROCEDURE Int24 ( flags : BITSET ) : CARDINAL ; (* Critical Error Interrupt *)
BEGIN
   RETURN 0 ;
END Int24;


(*$C F0,J-*)
PROCEDURE Resident;
       (* ======== *)

VAR I,F       : CARDINAL;
    R         : Registers;
    SaveDTA   : ADDRESS ;
    SavePSP   : CARDINAL ;
    SaveBrk   : SHORTCARD ;
BEGIN
(* Set Critical Error Handler and break handlers *)
  SetIrpt(24H,IPROC(Int24)) ;
  SetIrpt(1BH,NullInt);
  SetIrpt(23H,NullInt);
(* Change DTA *)
  R.AH := 2FH ;
  Lib.Dos(R) ;
  SaveDTA := [R.ES:R.BX] ;
  R.AH := 1AH ;
  R.DS := Seg(ProgDTA^) ;
  R.DX := Ofs(ProgDTA^) ;
  Lib.Dos(R) ;
(* Change PSP *)
  R.AX := 5100H ;
  Lib.Dos(R) ;
  SavePSP := R.BX ;
  R.BX := ProgPSP ;
  R.AX := 5000H ;
  Lib.Dos(R) ;
(* Turn off break flag *)
  R.AX := 3300H ;
  Lib.Dos(R) ;
  SaveBrk := R.DL ;
  R.DL := 0 ;
  R.AX := 3301H ;
  Lib.Dos(R) ;
  R.AH := 3;
  R.BH := 0;
  Lib.Intr(R,010H);
  Window.Use(Window.FullScreen);
  Window.CursorOff;
  Window.SnapShot;
  TSRproc() ;
  R.AH := 0DH ;
  Lib.Dos(R) ;
  Window.Use(Window.FullScreen);
  Window.CursorOn;
  R.AH := 2;
  R.BH := 0;
  Lib.Intr(R,010H);

(* Restore break flag *)
  R.DL := SaveBrk ;
  R.AX := 3301H ;
  Lib.Dos(R) ;
(* Restore PSP *)
  R.BX := SavePSP ;
  R.AX := 5000H ;
  Lib.Dos(R) ;
(* Restore DTA *)
  R.AH := 1AH ;
  R.DS := Seg(SaveDTA^) ;
  R.DX := Ofs(SaveDTA^) ;
  Lib.Dos(R) ;
(* Restore Critical irpt and break handlers *)
  ResetIrpt(24H);
  ResetIrpt(1BH);
  ResetIrpt(23H);
END Resident;

VAR
  HeapSize : CARDINAL ;

PROCEDURE TermProc ;
VAR
  R : Registers ;
BEGIN
  R.AX := 03100H; (*Terminate and stay resident*)
  R.DX := HeapBase+HeapSize-Lib.PSP ;
  Lib.Intr(R,21H); (* Use Intr, so as not to trigger the
                      Dos re-entry run-time check  *)
  (* No Return *)
END TermProc ;

VAR
  EnvPtr[0:4H*4]  : POINTER TO RECORD
                        op  : SHORTCARD;
                        ad  : ADDRESS;
                        str : ARRAY[0..5] OF CHAR;
                    END ;
PROCEDURE InEnv () : BOOLEAN ;
BEGIN
  RETURN (EnvPtr<>NIL)AND (Str.Compare(EnvPtr^.str,'ENVREH')=0) ;
END InEnv ;

PROCEDURE SKinstalled () : BOOLEAN ;
TYPE
  AP = POINTER TO ADDRESS ;
VAR
  id1 : POINTER TO LONGCARD ;
  id2 : POINTER TO CARDINAL ;

BEGIN
  id1 := Lib.SubAddr([0:8*4 AP]^,4) ;
  id2 := Lib.SubAddr([0:25H*4 AP]^,2) ;
  RETURN (id1^=049424B53H)OR(id2^=04B53H) ;
END SKinstalled ;



PROCEDURE Install ( P        : PROC ;      (* Procedure to be invoked *)
                    KBF      : KBFlagSet;  (* Shift state to invoke *)
                    Scan     : SHORTCARD ; (* Invoking scancode (0=All) *)
                    heapsize : CARDINAL    (* Minimum heap required *)
                  ) ;
VAR
  hp,nhp  : Storage.HeapRecPtr ;
  R       : Registers ;
  stack   : ARRAY[0..1023] OF BYTE ;
  termp   : PROCESS ;

BEGIN
  IF InEnv() THEN
    Lib.FatalError('Failed to install TSR: should be installed outside the JPI Environment');
  END ;
  IF SKinstalled() THEN
    Lib.FatalError('Failed to install TSR: should be installed BEFORE SideKick ');
  END ;
  ActivateScan := Scan ;
  ActivateFlags := KBF ;
  TSRproc := P ;
  hp := Storage.MainHeap ;
  (* Truncate Main Heap *)
  LOOP
    nhp := hp^.next ;
    IF nhp^.size = 0FFFFH THEN
      nhp := [HeapBase+heapsize-1:0] ;
      IF (Seg(hp^)+hp^.size<>Seg(nhp))
         AND (Seg(nhp^)>Seg(hp^)) THEN
        hp^.next := nhp ;
        hp^.size := Seg(nhp^)-Seg(hp^) ;
        nhp^.next := [HeapBase:0] ;
        nhp^.size := 0FFFFH ;
      ELSE
        Lib.FatalError('Not enough storage');
      END ;
      EXIT ;
    END ;
    hp := nhp ;
  END ;
  (* Release Environment *)

  R.ES := CARDINAL([Lib.PSP:2CH]^) ;
  R.AX := 04900H ;
  Lib.Dos(R);
  R.AH := 52 ;
  Lib.Dos(R) ;
  DosNest := [R.ES:R.BX] ; (* Dos nesting count *)
  R.AH := 2FH ;
  Lib.Dos(R) ;
  ProgDTA := [R.ES:R.BX] ; (* Current DTA *)
  R.AX := 5100H ;
  Lib.Dos(R) ;
  ProgPSP := R.BX ;        (* Current PSP *)

(* Install Interrupt handlers *)
  SetIrpt(09H,Int9);
  SetIrpt(1CH,Int1C);
  SetIrpt(28H,Int28);
  NEWPROCESS( TermProc, ADR(stack), SIZE(stack) , termp );
  HeapSize := heapsize ;
  TSRmode := Sleeping ;
  REPEAT
    TRANSFER(MainProcess,termp) ;
    Resident ;
  UNTIL TSRmode = Dead ;
END Install ;

PROCEDURE DeInstall ;
TYPE
  BP = POINTER TO SHORTCARD ;
  CP = POINTER TO CARDINAL ;
VAR
  s : CARDINAL ;
  R : Registers ;
BEGIN
  IF TSRmode<>Dead THEN
    TSRmode := Dead ;
    ResetIrpt(09H);
    ResetIrpt(1CH);
    ResetIrpt(28H);
    R.AH := 52H ;
    Lib.Dos(R);
    s := [R.ES:R.BX-2 CP]^;
    WHILE [s:0 BP]^ = 4DH DO
      IF [s:1 CP]^ = ProgPSP THEN
        R.AH := 49H ;
        R.ES := s+1 ;
        Lib.Dos(R) ;
      END ;
      INC(s,[s:3 CP]^+1);
    END ;
  END ;
END DeInstall ;

VAR
  Continue  : PROC ;

PROCEDURE Closedown ;
BEGIN
     DeInstall ;
     Continue() ;
END Closedown ;


BEGIN
  TSRmode := Dead ;
  Lib.Terminate(Closedown,Continue) ;
END TSR.

(*======================================================*)

