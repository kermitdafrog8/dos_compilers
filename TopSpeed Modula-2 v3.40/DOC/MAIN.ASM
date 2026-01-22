RetCode      EQU  0             ; return value for main
RegParam     EQU  0             ; Register parameter passing
StkFrame     EQU  1             ; Standard C parameter passing
SSinDGROUP   EQU  1             ; Stack in data segment

SmallModel   EQU  1             ; memory models
CompactModel EQU  2
MediumModel  EQU  4
LargeModel   EQU  8
XLargeModel  EQU 16

MemoryModel       EQU LargeModel      ; select model
CallingConvention EQU RegParam        ; calling convention

IF  MemoryModel EQ SmallModel
    .MODEL  SMALL
    frame   EQU 4
ENDIF
IF  MemoryModel EQ CompactModel
    .MODEL  COMPACT
    frame   EQU 4
ENDIF
IF  MemoryModel EQ MediumModel
    .MODEL  MEDIUM
    frame   EQU 6
ENDIF
IF  MemoryModel EQ LargeModel
    .MODEL  LARGE
    frame   EQU 6
ENDIF
IF  MemoryModel EQ XLargeModel
    .MODEL  HUGE
    frame   EQU 6
ENDIF

IF CallingConvention EQ RegParam

    IF @datasize EQ 1                  ; Far data pointer models M, L, MT
        EnvV  EQU WORD PTR [bp+frame]  ; ArgC = ax, ArgV = cx:bx
                                       ; Near data pointer models S, C
                                       ; ArgC = ax, ArgV = bx, EnvV = cx *)
    ENDIF
ELSE

    IF @datasize EQ 0                  ; Near data pointer models S, M
        ArgC  EQU WORD PTR [bp+frame]
        ArgV  EQU WORD PTR [bp+2+frame]
        EnvV  EQU WORD PTR [bp+4+frame]
    ELSE
        ArgC  EQU WORD PTR [bp+frame]
        ArgVl EQU WORD PTR [bp+2+frame]
        ArgVh EQU WORD PTR [bp+4+frame]
        EnvVl EQU WORD PTR [bp+6+frame]
        EnvVh EQU WORD PTR [bp+8+frame]
    ENDIF
ENDIF

EXTRN  __main_args3:FAR                  ; main entry points in library
EXTRN  __main_args2:FAR
EXTRN  __call_main:FAR

    .CODE
IF @codesize EQ 0
    _main PROC NEAR
ELSE
    _main PROC FAR
ENDIF
    PUBLIC _main

    push bp
    mov  bp, sp
IF @datasize EQ 2
    push ds
    mov  ax, @data
    mov  ds, ax
ENDIF
                                    ; your stuff here
    mov  ax, RetCode
IF @datasize EQ 2
    pop  ds
ENDIF
    pop  bp
IF CallingConvention EQ RegParam
IF @datasize GT 0
    ret  4
ELSE
    ret
ENDIF
ELSE
    ret
ENDIF

_main ENDP

    .DATA
                                    ; One option must be True

Main0Args  EQU 0                    ; no main parameters
Main2Args  EQU 0                    ; Brings in command line only
Main3Args  EQU 1                    ; Brings in command line and environment

STACK_SIZE EQU  4000H               ; Sets Stack size
HEAP_SIZE  EQU 0FFFFH               ; Sets Heap Size

    PUBLIC __initx

IF Main3Args EQ 1
__initx    DW __main_args3, @code
ENDIF

IF Main2Args EQ 1
__initx    DW __main_args2, @code
ENDIF

IF Main0Args EQ 1
__initx    DW __call_main, @code
ENDIF

           DW STACK_SIZE            ; Stack size
           DW HEAP_SIZE             ; Heap Size
           DB SSinDGROUP            ; Near or far stack

_DATA ENDS

NEAR_STACK SEGMENT WORD PUBLIC 'BSS'

    PUBLIC __near_stack_start
   __near_stack_start LABEL WORD
IF SSinDGROUP EQ 1
    ORG STACK_SIZE
ENDIF
IF SSinDGROUP EQ 0
    ORG 1
ENDIF
NEAR_STACK ENDS

NEAR_HEAP SEGMENT WORD PUBLIC 'BSS'

    PUBLIC __near_heap_start
    __near_heap_start LABEL WORD
    ORG HEAP_SIZE

NEAR_HEAP ENDS

END

