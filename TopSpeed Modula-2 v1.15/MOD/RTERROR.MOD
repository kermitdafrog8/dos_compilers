IMPLEMENTATION MODULE RTerror;


  IMPORT Lib, SYSTEM;


  CONST
    MaxProcs     = 8;    (* number of handlers which may be installed *)
    IndexCode    = 95H;
    OverflowCode = 90H;
    StackCode    = 91H;
    SubrangeCode = 92H;
    EnumCode     = 93H;
    NILCode      = 94H;
    NoRETURNCode = 97H;


  TYPE
    SP = POINTER TO SHORTCARD;


  VAR
    Int4VecRTL : SYSTEM.ADDRESS;               (* saved int 4 set by rtl.a *)
    Int4Procs : ARRAY[1..MaxProcs] OF RTproc;  (* the user handlers *)
    CurrInt4Proc : CARDINAL;                   (* the top of Int4Procs *)
    Int4Vec [0:4*4] : SYSTEM.ADDRESS;          (* the interrupt vector *)
    trapped : BOOLEAN;                         (* TRUE if we have int 4 *)


(*$C FF,J+,S-*)  (* save all regs, issue IRET for return, no stack check *)
  PROCEDURE Int4Handler(flags : BITSET);
    VAR
      stack : POINTER TO RECORD             (* the stack frame *)
                           IP,
                           CS : CARDINAL;
                           FLAGS : BITSET;
                         END;
      code : RTtype;
      aseg,
      rseg : CARDINAL;
    BEGIN
      Int4Vec := Int4VecRTL;  (* restore rtl.a handler, so that if an error
                                 occurs, we don't enter this procedure
                                 recursively *)
      stack := [SYSTEM.Seg(flags):SYSTEM.Ofs(flags)-4];  (* point to the
                                                            stack frame *)
      CASE [stack^.CS:stack^.IP SP]^ OF  (* the error code *)
          IndexCode    : code := IndexOutOfRange;
        | OverflowCode : code := ArithmeticOverflow;
(* This will be handled by ELSE...
        | StackCode    : DEC(stack^.IP,2);
                         CurrInt4Proc := 0;
                         RETURN;
*)
        | SubrangeCode : code := SubOutOfRange;
        | EnumCode     : code := EnumValue;
        | NILCode      : code := NILusage;
(* This will be handled by ELSE...
        | NoRETURNCode : DEC(stack^.IP,2);
                         CurrInt4Proc := 0;
                         RETURN;
*)
        ELSE
          DEC(stack^.IP,2);  (* will return to int 4 which brought us here *)
          CurrInt4Proc := 0; (* all user-installed handlers are forgotten *)
          RETURN;            (* which will invoke the rtl.a int 4 routine *)
      END;
      aseg := stack^.CS;  (* absolute segment of error *)
      IF (aseg < Lib.PSP+16) OR (aseg > SYSTEM.HeapBase) THEN
        (* if absolute segment is outside of program... *)
        rseg := 0FFFFH;  (* then flag it *)
      ELSE
        rseg := aseg-Lib.PSP-16;  (* relative segment *)
      END;
      IF NOT Int4Procs[CurrInt4Proc](aseg,rseg,stack^.IP,code) THEN
        (* if user-installed handler returns FALSE... *)
        DEC(stack^.IP,2);  (* then return to int 4 which brought us here *)
        CurrInt4Proc := 0; (* all user-installed handlers are forgotten *)
        RETURN;
      END;
      INC(stack^.IP);  (* otherwise, skip error code *)
      Int4Vec := SYSTEM.ADR(Int4Handler);  (* and rehook vector *)
    END Int4Handler;
(*$C F0,J-,S=*)  (* back to saving DS, ES, SI, DI, issue RET for return,
                    restore previous stack-checking state *)


  PROCEDURE InstallRT(handler : RTproc);
    BEGIN
      IF CurrInt4Proc = 0 THEN               (* are any handlers installed? *)
        Int4Vec := SYSTEM.ADR(Int4Handler);  (* no - trap the interrupt *)
      END;
      IF CurrInt4Proc < MaxProcs THEN        (* can we install another one? *)
        INC(CurrInt4Proc);                   (* yes - so do it *)
        Int4Procs[CurrInt4Proc] := handler;
      END;
    END InstallRT;


  PROCEDURE UnInstallRT;
    BEGIN
      IF CurrInt4Proc > 0 THEN  (* are there any handlers installed? *)
        DEC(CurrInt4Proc);      (* yes - remove the last one *)
        IF CurrInt4Proc = 0 THEN  (* are all the handlers gone? *)
          Int4Vec := Int4VecRTL;  (* yes - untrap the interrupt *)
        END;
      END;
    END UnInstallRT;


  BEGIN
    CurrInt4Proc := 0;      (* no handler installed *)
    Int4VecRTL := Int4Vec;  (* get interrupt vector that rtl.a installed *)
    trapped := FALSE;
  END RTerror.
