IMPLEMENTATION MODULE BiosIO ;

FROM SYSTEM IMPORT Registers,ZeroFlag ;

IMPORT Lib,IO ;

VAR
  EnhancedBIOS : BOOLEAN ;


PROCEDURE KeyPressed() : BOOLEAN ;
VAR R : Registers;
BEGIN
   IF LastChar = CHR(0) THEN
     RETURN TRUE ;
   ELSE
     R.AH := 1;
     IF EnhancedBIOS THEN R.AH := 11H END ;
     Lib.Intr(R,16H);
     RETURN NOT (ZeroFlag IN R.Flags) ;
   END ;
END KeyPressed;

PROCEDURE RdKey () : CHAR ;
VAR R : Registers;
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
VAR R : Registers;
BEGIN
   R.AH := 2 ;
   Lib.Intr(R,16H);
   RETURN KBFlagSet(R.AL) ;
END KBFlags ;

PROCEDURE Init ;
VAR R : Registers ;
BEGIN
  LastScan    := 0 ;
  LastChar    := CHR(0FFH) ;
  EnhancedBIOS := FALSE ;
  (* Check for enhanced BIOS *)
  R.AH := 5 ;
  R.CX := 0FFFFH ;
  Lib.Intr(R,16H);     (* Put FFFF into Kbd buffer *)
  R.AH := 11H ;
  Lib.Intr(R,16H);     (* And try and read it back *)
  IF R.AX=0FFFFH THEN
    R.AH := 10H ;
    Lib.Intr(R,16H);   (* clear FFFF *)
    EnhancedBIOS := TRUE ;
  END ;
END Init ;

BEGIN
  Init ;
END BiosIO.

