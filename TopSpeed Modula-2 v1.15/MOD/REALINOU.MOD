(*$V-*)
IMPLEMENTATION MODULE RealInOut ;

(* Core library interface *)

IMPORT IO,Str,InOut ;



PROCEDURE ReadReal  ( VAR v : REAL ) ;
VAR s : ARRAY[0..80] OF CHAR;
    r,a : LONGREAL;
BEGIN
  InOut.ReadString( s );
  r := Str.StrToReal( s,Done );
  a := ABS( r );
  Done := Done AND (a >= 1.2E-38 ) AND (a <= 3.4E38 );
  v := REAL(r) ;
END ReadReal;

PROCEDURE WriteReal ( v : REAL ; w : CARDINAL ) ;
BEGIN
  IO.WrReal(v,MAX(CARDINAL),INTEGER(w)) ;
  Done := IO.OK ;
END WriteReal ;

BEGIN
  Done := TRUE ;
END RealInOut.
