IMPLEMENTATION MODULE Int24 ;
(*========================================================
== TopSpeed Modula-2 V3                                 ==
== demo program:                                        ==
==                                                      ==
==        Int24 handler                                 ==
==                                                      ==
== Skeleton handler for "critical errors"               ==
==                                                      ==
========================================================*)
(*# check(stack=>off,index=>off,range=>off,overflow=>off,nil_ptr=>off) *)

(* Example of defining an interrupt handler in Modula-2 *)

IMPORT SYSTEM,Lib,Str ;

CONST
  ContinueProg = FALSE;    (* Set this to TRUE if you want to continue
                              after an abort (returning 255 to the
                              calling program).
                              If ContinueProg is set to FALSE then the
                              program will terminate on 'abort' *)

(*----------------------------------------------------------------------*)

(* These are "safe" version of IO routines,
   i.e. they do not call any  DOS function > 12
   Alternatively "Window" routines could be used.
*)

PROCEDURE WrStr(string: ARRAY OF CHAR);
VAR R : SYSTEM.Registers;
    i : CARDINAL;
BEGIN
  i := 0;
  WHILE (i<SIZE(string))AND(string[i]<>CHR(0)) DO
    R.DL := SHORTCARD(string[i]);
    R.AH := 6;
    Lib.Intr( R ,21H ); (* Don't use Lib.Dos as this will trigger
                           re-entered check *)
    INC(i);
  END;
END WrStr;

PROCEDURE WrLn;
TYPE
  a3 = ARRAY [0..1] OF CHAR;
CONST
  crlf = a3(CHR(13),CHR(10));
BEGIN
  WrStr( crlf );
END WrLn;

PROCEDURE RdKey(): CHAR;
VAR R : SYSTEM.Registers;
BEGIN
  R.AH := 7;
  Lib.Intr( R ,21H ); (* Don't use Lib.Dos as this will trigger
                         re-entered check *)
  RETURN CHAR(R.AL);
END RdKey;

(*----------------------------------------------------------------------*)
(* The pop stack inline code is required if the program should
   continue after an abort (returning 255 to the calling program).
*)

TYPE
  Code26 = ARRAY[0..25] OF SHORTCARD ;

(*# save,
    call( reg_saved=>(dx,ax,bx,cx,si,di,es,ds,st1,st2),
          inline=>on )
*)

PROCEDURE PopStack()=Code26(
       08BH,0E5H,           (*  mov   sp,bp           *)
       083H,0C4H,01CH,      (*  add   sp,1CH          *)
       058H,                (*  pop   ax              *)
       05BH,                (*  pop   bx              *)
       059H,                (*  pop   cx              *)
       05AH,                (*  pop   dx              *)
       05EH,                (*  pop   si              *)
       05FH,                (*  pop   di              *)
       058H,                (*  pop   ax              *)
       01FH,                (*  pop   ds              *)
       007H,                (*  pop   es              *)
       08BH,0ECH,           (*  mov   bp,sp           *)
       080H,04EH,004H,001H, (*  or    byte [bp][4],1  *)
       08BH,0E8H,           (*  mov   bp,ax           *)
       0B8H,0FFH,000H,      (*  mov   ax,0FFH         *)
       0CFH);               (*  iret                  *)


(*----------------------------------------------------------------------*)
(* Actual Int24 Interrupt Handler
*)

(* pragmas for interrupt handler *)
(*# save,
    call(interrupt => on,
         reg_param => (),
         same_ds   => off
        )
*)

(* NB, The interrupt pragma sets up the registers as parameters to the
       procedure in the order defined below. This allows easy access to
       the entry registers
*)
PROCEDURE Irpt24 ( Flags : BITSET;        (* Registers on entry *)
                   CS,IP : CARDINAL;
                   AX,CX : CARDINAL;
                   DX,BX : CARDINAL;
                   SP,BP : CARDINAL;
                   SI,DI : CARDINAL;
                   DS,ES : CARDINAL ) ;
VAR
    s       : ARRAY[0..40] OF CHAR ;
    k       : CHAR ;
    saveipf : BOOLEAN ;
    P_AL    : POINTER TO SHORTCARD;
BEGIN
  (* N.B. Only DOS functions <= 12 may be called from a critical
     error handler
  *)
  CASE DI OF
  0 : s := 'Disk write protected' |
  2 : s := 'Drive not ready'      |
  9 : s := 'Printer out of paper' |
  ELSE
    s := 'Disk error' ;
  END ;
  Str.Append(s,'. Abort, Retry, Ignore?');
  WrStr(s) ; WrLn ;
  REPEAT
    k := CAP(RdKey()) ;
  UNTIL (k='R') OR (k='I') OR (k='A') ;
  P_AL := ADR(AX);
  IF k='I'    THEN P_AL^ := 0 ;  (* ignore *)
  ELSIF k='R' THEN P_AL^ := 1 ;  (* retry  *)
  ELSE                           (* abort  *)
    IF ContinueProg THEN
      PopStack; (* Removes MSDOS call frame and Return 255 to caller *)
      (* Does not return here *)
    ELSE
      HALT ;
    END ;
  END ;
END Irpt24;
(*# restore *)


VAR
  Int24Vec[0:24H*4]   : FarADDRESS;
VAR
  h : CARDINAL;
BEGIN
  SYSTEM.DI ;
  (* Install interrupt 24 *)
  Int24Vec := FarADR(Irpt24) ;
  SYSTEM.EI ;
END Int24.
