(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  MATHLIB0.MOD - Trigonometry (core library)                              *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

IMPLEMENTATION MODULE MathLib0;

FROM MATHLIB IMPORT ATan, Cos, Exp, Log, Sin, Sqrt;


PROCEDURE arctan( r: REAL) : REAL;
BEGIN
    RETURN REAL( ATan( LONGREAL( r)));
END arctan;


PROCEDURE cos( r: REAL) : REAL;
BEGIN
    RETURN REAL( Cos( LONGREAL( r)));
END cos;


PROCEDURE entier( r: REAL) : INTEGER;
VAR
    i : INTEGER;
BEGIN
    i := TRUNC( r);
    IF (r < 0.0) AND (r <> FLOAT( i)) THEN
        DEC( i);
    END;
    RETURN i;
END entier;


PROCEDURE exp( r: REAL) : REAL;
BEGIN
    RETURN REAL( Exp( LONGREAL( r)));
END exp;


PROCEDURE ln( r: REAL) : REAL;
BEGIN
    RETURN REAL( Log( LONGREAL( r)));
END ln;


PROCEDURE real( i: INTEGER) : REAL;
BEGIN
    RETURN REAL( i);
END real;


PROCEDURE sin( r:REAL) : REAL;
BEGIN
    RETURN REAL( Sin( LONGREAL( r)));
END sin;


PROCEDURE sqrt( r:REAL) : REAL;
BEGIN
    RETURN REAL( Sqrt( LONGREAL( r)));
END sqrt;


END MathLib0.
