(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  MATHLIB.MOD - Floating point support (see also COREMATH.A)              *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*# data(seg_name => null) *)
(*%E *)

(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)
(*# module(implementation=>off) *)

IMPLEMENTATION MODULE MATHLIB;

PROCEDURE LoadControlWord(C : BITSET); IN AsmLib;
PROCEDURE StoreControlWord() : BITSET; IN AsmLib;
PROCEDURE ClearExceptions();  IN AsmLib;
PROCEDURE StoreEnvironment(VAR Env: Environment);  IN AsmLib;
PROCEDURE InternalBcdToLong(A: PackedBcd) : LONGREAL; IN AsmLib;

PROCEDURE Rexp(VAR I : INTEGER;A : LONGREAL) : LONGREAL;

BEGIN
    RETURN CoreMath.frexp(A, I);
END Rexp;

PROCEDURE LongToBcd(A: LONGREAL)  : PackedBcd;
VAR res:PackedBcd;
BEGIN
  CoreMath._bcd(TEMPREAL(A),NearADR(res));
  RETURN res;
END LongToBcd;


PROCEDURE BcdToLong(A: PackedBcd) : LONGREAL;
BEGIN
    RETURN InternalBcdToLong(A);
END BcdToLong;

PROCEDURE IntPow(X:LONGREAL;K:INTEGER):LONGREAL;
BEGIN
    RETURN LONGREAL(CoreMath._pow_int(TEMPREAL(X),K));
END IntPow;

PROCEDURE ATan2(X,Y : LONGREAL) : LONGREAL;

BEGIN
    RETURN CoreMath.atan2(Y, X);
END ATan2;

END MATHLIB.
