(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  FLOATEXC.MOD - Floating-point exception handlers                        *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*# call(seg_name => null,
         ds_entry=>null) *)
(*# data(seg_name => null) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE FloatExc;

IMPORT CoreSig;

VAR
  Handler, OldHandler, Dummy: CoreSig.SigProcType;
  Init: BOOLEAN;

PROCEDURE EnableExceptionHandling;
BEGIN
  IF Init THEN
    Dummy :=  CoreSig.signal(8, CoreSig.SigProcType(Handler));
  END;
END EnableExceptionHandling;

PROCEDURE DisableExceptionHandling;
BEGIN
  IF Init THEN
    Dummy :=  CoreSig.signal(8, CoreSig.SigProcType(OldHandler));
  END;
END DisableExceptionHandling;

PROCEDURE InstallHandler(H: FloatErrHandler);

BEGIN
  Handler := CoreSig.SigProcType(H);
  OldHandler :=  CoreSig.signal(8, CoreSig.SigProcType(H));
  Init := TRUE;
END InstallHandler;

BEGIN
  Init := FALSE;
END FloatExc.
