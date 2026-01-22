  (***********************************************************************)
  (*                                                                     *)
  (*          StdMem - Include file for Standard Memory Management       *)
  (*                   Module.                                           *)
  (*                                                                     *)
  (*                 Release 3.10                                        *)
  (*                 Copyright 1991-1992 Clarion Software Corporation    *)
  (***********************************************************************)

include "standard.inc"

  (***********************************************************************)
  (* Guards - Standard Guard Values                                      *)
  (***********************************************************************)
HEAP_GUARD              = 4350H
STACK_GUARD             = 1234H

  (***********************************************************************)
  (* StdMem - Standard Core Memory Management Section                    *)
  (***********************************************************************)
memThreshold            = 4000H        (* OS Allocation Threshold        *)

memSegOverhead          = 8            (* Must be mult of 4              *)

memLargestFree          = 4
memHeapSize             = 6

memFreeOverhead         = 4
memFreeSize             = 0
memNextFree             = 2

memEntrySize            = 4
memInitEntries          = 256

memLargest              = 0
memSelector             = 2
memTerminator           = memEntrySize + memSelector

memSegEmpty             = 0 - memSegOverhead

