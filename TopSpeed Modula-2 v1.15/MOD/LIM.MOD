IMPLEMENTATION MODULE LIM; (* LIM expanded memory *)
IMPORT SYSTEM,Str,Lib ;

PROCEDURE EMMError( e : SHORTCARD );
VAR str : ARRAY [0..79] OF CHAR;
    err : ARRAY [0..79] OF CHAR ;
    Done : BOOLEAN;
CONST
    Errors = 'Internal EMS driver Error|'+
             'Hardware failure|'+
             'Busy|'+
             'Invalid handle|'+
             'Undefined function|'+
             'No more EMS handles available|'+
             'Error in save or restore of map context|'+
             'Not enough logical pages physically available|'+
             'Not enough pages available|'+
             'Zero allocation|'+
             'Logical page number out of range|'+
             'Illegal physical page number|'+
             'Illegal physical page in mapping request|'+
             'Mapping save area full|'+
             'Mapping context save failed (already saved)|'+
             'Mapping context restore failed (not saved)|'+
             'Subfunction parameter undefined';
BEGIN
  IF e<>0 THEN
    str := 'LIM EMS error ' ;
    Str.CardToStr( LONGCARD(e),err,16,Done );
    Str.Append(str,err) ;
    IF (e>80H)AND(e<=8FH) THEN
      Str.ItemS(err,Errors,'|',CARDINAL(e-81H)) ;
      Str.Append(str,' : ');
      Str.Append(str,err);
    END ;
    Lib.FatalError( str );
  END ;
END EMMError;

PROCEDURE GetStatus() : SHORTCARD;
VAR r : SYSTEM.Registers;
BEGIN
  WITH r DO
       AH := 40H;
       Lib.Intr(r,67H);
       RETURN AH;
  END;
END GetStatus;

PROCEDURE GetPageFrame(): CARDINAL;
VAR r : SYSTEM.Registers;
BEGIN
  WITH r DO
       AH := 41H;
       Lib.Intr(r,67H);
       IF AH#0 THEN EMMError( AH ); END;
       RETURN BX;
  END;
END GetPageFrame;

PROCEDURE AllocatePages( n : CARDINAL ) : CARDINAL;
VAR r : SYSTEM.Registers;
BEGIN
  WITH r DO
       AH := 43H;
       BX := n;
       Lib.Intr(r,67H);
       IF AH#0 THEN EMMError( AH ); END;
       RETURN DX;
  END;
END AllocatePages;

PROCEDURE FreePages() : CARDINAL;
VAR r : SYSTEM.Registers;
BEGIN
  WITH r DO
       AH := 42H;
       Lib.Intr(r,67H);
       IF AH#0 THEN EMMError( AH ); END;
       RETURN BX;
  END;
END FreePages;

PROCEDURE MapPage( PPage,LPage,Handle : CARDINAL ): CARDINAL;
VAR r : SYSTEM.Registers;
BEGIN
  WITH r DO
       AH := 44H;
       AL := SHORTCARD(PPage);
       BX := LPage;
       DX := Handle;
       Lib.Intr(r,67H);
       IF AH#0 THEN EMMError( AH ); END;
       RETURN PPage << 14;
  END;
END MapPage;

PROCEDURE DeAllocatePages( Handle : CARDINAL );
VAR r : SYSTEM.Registers;
BEGIN
  WITH r DO
       AH := 45H;
       DX := Handle;
       Lib.Intr(r,67H);
       IF AH#0 THEN EMMError( AH ); END;
  END;
END DeAllocatePages;

VAR Int67 [0:19CH] : ADDRESS;
TYPE b8 = ARRAY [0..7] OF CHAR;
BEGIN
  LIMPresent := FALSE;
  IF (Int67 # [0:0]) AND (b8([[0:19CH+2]^:0AH]^) = b8('EMMXXXX0')) THEN
     LIMPresent := GetStatus()=0;
     IF LIMPresent THEN PageFr := GetPageFrame(); END;
  END;
END LIM.


