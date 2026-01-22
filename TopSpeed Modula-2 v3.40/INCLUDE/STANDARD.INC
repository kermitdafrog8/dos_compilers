(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  STANDARD.INC - Core library include file                                *
*                                                                          *
*  COPYRIGHT (C) 1991..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

TRUE                    = 1
FALSE                   = 0

_DLLOVL                 = (_OVL) | (_DLL & ~_OS2)
TSProtMode              = (_OS2 | _XTD)(* TopSpeed Protected Modes       *)
                                       (* OS/2 or TopSpeed DOS Extender  *)

FarPointer              = 4
NearPointer             = 2

(*%T _fptr *)
DataPointer             = FarPointer
(*%E *)
(*%F _fptr *)
DataPointer             = NearPointer
(*%E *)

(*%T _fcall *)
CodePointer             = FarPointer
(*%E *)
(*%F _fcall *)
CodePointer             = NearPointer
(*%E *)

FarFrame                = 2 + FarPointer
NearFrame               = 2 + NearPointer

(*%T _fcall *)
Frame                   = FarFrame     (* bp stack frame, far call       *)
(*%E *)
(*%F _fcall *)
Frame                   = NearFrame    (* bp stack frame, near call      *)
(*%E *)

bxFrame                 = Frame - 2    (* bx stack frame                 *)

  (***********************************************************************)
  (* StdInit - Standard Core Initialization Section                      *)
  (***********************************************************************)
INIT_MAGIC              = 1234H

initPri0                = 30
initPri1                = 29
initPri2                = 28
initPri3                = 27
initPri4                = 26
initPri5                = 25
initPriLow              = 20

initPriMax              = 32

initMagic               = 0
initPriority            = 2
initProcVar             = 3

StackSize               = 0
HeapSize                = 2
SSisDS                  = 4

  (***********************************************************************)
  (* Operating System Error Codes                                        *)
  (***********************************************************************)
ERROR_FILENOTFOUND      = 2
ERROR_PATHNOTFOUND      = 3
ERROR_ACCESSDENIED      = 5
ERROR_INVALIDHANDLE     = 6
ERROR_TOOBIG            = 7
ERROR_NOMEMORY          = 8
ERROR_HEAPCORRUPT       = 146
ERROR_MEMINIT           = 16

StandardInput           = 0
StandardOutput          = 1
StandardError           = 2

  (***********************************************************************)
  (* Program Segment Prefix Offsets                                      *)
  (***********************************************************************)
pspTopOfMemory          = 002H
pspAvailMemory          = 006H
pspEnviron              = 02CH
pspFCB1                 = 05CH
pspFCB2                 = 06CH
pspCommandTail          = 080H

