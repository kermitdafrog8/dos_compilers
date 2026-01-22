(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  BIOSIO.MOD - BIOS level i/o                                             *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*%E *)
(*# module(implementation=>off) *)
(*# data(seg_name => null) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE BiosIO ;

IMPORT Lib,IO,SYSTEM;


PROCEDURE KeyPressed() : BOOLEAN ;
VAR R : SYSTEM.Registers;
BEGIN
   IF LastChar = CHR(0) THEN
     RETURN TRUE ;
   ELSE
     R.AH := 1;
     IF EnhancedBIOS THEN R.AH := 11H END ;
     Lib.Intr(R,16H);
     RETURN NOT (SYSTEM.ZeroFlag IN R.Flags) ;
   END ;
END KeyPressed;

PROCEDURE RdKey () : CHAR ;
VAR R : SYSTEM.Registers;
BEGIN
  IF LastChar = CHR(0) THEN
     LastChar := CHR(0FFH) ;
     RETURN CHR(LastScan) ;
  ELSE
     IF EnhancedBIOS THEN
       R.AH := 10H ;
       Lib.Intr(R,16H);
       IF (R.AL=0E0H)AND(R.AH<>0) THEN R.AL := 0 END ;
     ELSE
       R.AH := 0 ;
       Lib.Intr(R,16H);
     END ;
     IF R.AX=0 THEN END ; (* break *)
     LastChar := CHR(R.AL) ;
     LastScan := R.AH ;
     RETURN LastChar ;
   END;
END RdKey ;



PROCEDURE RdChar () : CHAR ;
(* reads and echoes char (if not extended) *)
VAR C : CHAR ;
BEGIN
  IF LastChar = CHR(0) THEN RETURN RdKey() END ;
  C := RdKey() ;
  IF C<>CHR(0) THEN
    IO.WrChar( C );
  END ;
  RETURN C ;
END RdChar ;

PROCEDURE KBFlags () : KBFlagSet ;
VAR R : SYSTEM.Registers;
BEGIN
   R.AH := 2 ;
   Lib.Intr(R,16H);
   RETURN KBFlagSet(R.AL) ;
END KBFlags ;

PROCEDURE Init ;
VAR R : SYSTEM.Registers ;
    i : CARDINAL ;
BEGIN
  LastScan    := 0 ;
  LastChar    := CHR(0FFH) ;
  EnhancedBIOS := FALSE ;
  (* Check for enhanced BIOS *)
  R.AX := 5FFH ;
  R.CX := 0FFFFH ;
  Lib.Intr(R,16H);     (* Put FFFF into Kbd buffer *)
  IF R.AL=0 THEN
    i := 256 ;
    LOOP
      R.AH := 11H ;
      Lib.Intr(R,16H);     (* And try and read it back *)
      IF SYSTEM.ZeroFlag IN R.Flags THEN EXIT END ;
      R.AH := 10H ;
      Lib.Intr(R,16H);     (* And try and read it back *)
      IF (R.AX=0FFFFH) OR (i=0) THEN EXIT END ;
      DEC (i);
    END ;
    IF R.AX=0FFFFH THEN
      EnhancedBIOS := TRUE ;
    END ;
  END ;
END Init ;

BEGIN
  Init ;
END BiosIO.

