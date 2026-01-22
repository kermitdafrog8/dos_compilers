(* Copyright (C) 1987 Jensen & Partners International *)

IMPLEMENTATION MODULE FloatExc;

FROM SYSTEM  IMPORT In,Out,DI,GetFlags,SetFlags,Seg,Ofs,Registers;
FROM Lib     IMPORT FatalError,Terminate,Intr;
FROM MATHLIB IMPORT StoreControlWord,LoadControlWord,ClearExceptions,
                    StoreEnvironment,Environment;
IMPORT Str;


VAR
  Nmi[0:2*4], OldNmi : ADDRESS;
  Term               : PROC;
  Base               : CARDINAL;
  AT                 : BOOLEAN;


(*$J+,C FF*)

PROCEDURE NmiTrap(Dummy: CARDINAL);
VAR
  e     : Environment;
  s1,s2 : ARRAY [0..49] OF CHAR;
  Done  : BOOLEAN;
  l     : LONGCARD;
CONST
  A = Str.Append;
BEGIN
  IF AT THEN Out(20H,20H); END;
  e := StoreEnvironment(); 
  ClearExceptions;
  l := LONGCARD(e.IP)+LONGCARD(e.Opcode DIV 1000H)*10000H;
  Str.CardToStr(l,s2,16,Done);
  s1 := '['; s1 \A\ s2; s1 \A\ '-';
  l := l-LONGCARD(Base)*10H;
  Str.CardToStr(l,s2,16,Done);
  s1 \A\ s2; s1 \A\ '] Float Error : ';
  IF     0 IN e.StatusWord THEN s1 \A\ 'invalid operation ';   FatalError( s1 );
  ELSIF  1 IN e.StatusWord THEN s1 \A\ 'denormalized operand'; FatalError( s1 );
  ELSIF  2 IN e.StatusWord THEN s1 \A\ 'divide by zero ';      FatalError( s1 );
  ELSIF  3 IN e.StatusWord THEN s1 \A\ 'overflow';             FatalError( s1 );
  ELSE   FatalError('RAM Parity error'); END;
END NmiTrap;

(*$J-,C F0*)

PROCEDURE EnableExceptionHandling;
BEGIN
  LoadControlWord(StoreControlWord()-{0,1,2,3});
END EnableExceptionHandling;

PROCEDURE DisableExceptionHandling;
BEGIN
  LoadControlWord(StoreControlWord()+{0,1,2,3});
END DisableExceptionHandling;

PROCEDURE CloseDown;
VAR
  f : CARDINAL;
TYPE
  sb = SET OF [0..7];
BEGIN
  DisableExceptionHandling;
  IF AT THEN
    (* disable interrupt 5 on secondary controler *)
    Out( 0A1H, SHORTCARD( sb(In(0A1H))+sb{5} ) );
  END;
  f := GetFlags(); DI; Nmi := OldNmi;  
  SetFlags(f); Term;
END CloseDown;

PROCEDURE InstallTrap(d : CARDINAL);
VAR
  f  : CARDINAL;
TYPE
  sb = SET OF [0..7];
  bp = POINTER TO SHORTCARD;
BEGIN
  Base := [Seg(d):Ofs(d)+4]^;  (* get program base *)
  f := GetFlags(); DI; OldNmi := Nmi; Nmi := ADR(NmiTrap);
  Terminate( CloseDown, Term );
  IF [0F000H:0FFFEH bp]^ = 0FCH THEN
    (* enable interrupt 5 on secondary controler *)
    Out( 0A1H, SHORTCARD( sb(In(0A1H))-sb{5} ) );
    AT := TRUE;
  ELSE
    AT := FALSE;
  END;
  EnableExceptionHandling; SetFlags(f);
END InstallTrap;

BEGIN
  InstallTrap(0);
END FloatExc.
