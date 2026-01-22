IMPLEMENTATION MODULE Int24 ;

(* Int 24 - Critical Error handler *)

IMPORT SYSTEM,AsmLib,Str,IO ;

(* The pop stack inline code is required if the program should
   continue after an abort (returning 255 to the calling program).
   If ContinueProg is set to FALSE then the program will terminate
   on 'abort' ;
*)

CONST
  ContinueProg = FALSE ;

TYPE
  Code = ARRAY[0..27] OF SHORTCARD ;
CONST
  PopStackCode = Code(
58H,             (* POP    AX    *)
58H,             (* POP    AX    *)
58H,             (* POP    AX    *)
5BH,             (* POP    BX    *)
89H,0C4H,        (* MOV    SP,AX *)
9DH,             (* POPF         *)
58H,             (* POP    AX    *)
5BH,             (* POP    BX    *)
59H,             (* POP    CX    *)
5AH,             (* POP    DX    *)
5EH,             (* POP    SI    *)
5FH,             (* POP    DI    *)
58H,             (* POP    AX    *)
1FH,             (* POP    DS    *)
07H,             (* POP    ES    *)
89H,0E5H,        (* MOV    BP,SP *)
80H,4EH,04H,01H, (* OR     Byte Ptr [BP+04],01 ; set carry *)
89H,0C5H,        (* MOV    BP,AX *)
0B8H,0FFH,00H,   (* MOV    AX,00FF *)  (* Return error *)
0CFH) ;          (* IRET         *)

TYPE PopStackProc = PROCEDURE ( VAR CARDINAL ) ;

(*$C 00,N*) PROCEDURE (*$F*) ForceSave(p : CARDINAL) : CARDINAL; FORWARD; (*$C F0,F*)

(* NB! Has to be forward otherwise compiler will spot that
       registers are not being used
*)

(*$C FF,J+*)
PROCEDURE Int24Handler( Dummy : CARDINAL );

TYPE IntReg1 = RECORD
                 DI,SI,ES,DS : CARDINAL;
                 CASE : BOOLEAN OF
                   TRUE  : BX,DX,CX,AX : CARDINAL; |
                   FALSE : BL,BH,DL,DH,CL,CH,AL,AH : SHORTCARD;
                 END;
               END;
VAR
    RegP1 : POINTER TO IntReg1;
    PopStack : PopStackProc ;
    saveipf : BOOLEAN ;
    s : ARRAY[0..40] OF CHAR ;
    k : CHAR ;
BEGIN
     RegP1 := [SYSTEM.Seg( Dummy ):ForceSave(0)+2]; (* must be first in procedure *)
     saveipf := AsmLib.GetInProgramFlag() ;
     AsmLib.SetInProgramFlag( TRUE );
     WITH RegP1^ DO

        CASE DI OF
        0 : s := 'Disk write protected' |
        2 : s := 'Drive not ready'      |
        9 : s := 'Printer out of paper' |
        ELSE
          s := 'Disk error' ;
        END ;
        Str.Append(s,'. Abort, Retry, Ignore?');
        IO.WrStr(s) ; IO.WrLn ;

        REPEAT
          k := CAP(IO.RdKey()) ;
        UNTIL (k='R') OR (k='I') OR (k='A') ;

        IF k='I'    THEN AL := 0 ;  (* ignore *)
        ELSIF k='R' THEN AL := 1 ;  (* retry  *)
        ELSE                        (* abort  *)
           IF ContinueProg THEN
             PopStack := PopStackProc(ADR(PopStackCode)) ;
             PopStack(Dummy);
             (* Remove MSDOS call frame and Return 255 to caller *)
             (* Does not return here *)
           ELSE
             HALT ;
           END ;
        END ;
     END;
     AsmLib.SetInProgramFlag( saveipf ); (* returning to DOS *)
END Int24Handler;
(*$C F0,J-*)

PROCEDURE ForceSave( p : CARDINAL): CARDINAL;
BEGIN
  RETURN SYSTEM.Ofs( p );
END ForceSave;

VAR
  Int24Vec[0:24H*4]   : PROCEDURE ( CARDINAL ) ;

BEGIN
  SYSTEM.DI ;
  (* Install interrupt 24 *)
  Int24Vec := Int24Handler ;
  SYSTEM.EI ;
END Int24.
