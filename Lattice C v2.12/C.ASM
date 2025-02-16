	TITLE	C - Initiate execution of a Lattice C program
	SUBTTL	Copyright 1982 by Lattice, Inc.
	NAME	C
	INCLUDE	DOS.MAC
;**
;
; name		C -- initiate execution of C program
;
; description	This is the main module for a C program on the
;		MS-DOS implementation.  It initializes the segment
;		registers, sets up the stack, and calls the C main
;		function _main with a pointer to the remainder of
;		the command line.
;
;		Also defined in this module: the exit entry point
;		XCEXIT, and the stack overflow entry XCOVF.
;
;**
 	IF	S8086
PGROUP	GROUP	BASE,PROG,TAIL
BASE	SEGMENT	WORD PUBLIC 'PROG'
	DW 	0
BASE	ENDS
	ENDIF

	IF	P8086
BASE	SEGMENT	WORD
	DW	1
BASE	ENDS
	ENDIF

	IF	D8086
CGROUP	GROUP	BASE,CODE
BASE	SEGMENT	WORD PUBLIC 'CODE'
	DW	2
BASE	ENDS
	ENDIF

	IF	L8086
BASE	SEGMENT WORD
	DW	3
BASE	ENDS
	ENDIF

	IF	LPROG
	EXTRN	_MAIN:FAR
	EXTRN	RBRK:FAR
ECODE	EQU	4		;offset of error code for XCEXIT
	ELSE
ECODE	EQU	2		;offset of error code for XCEXIT
	ENDIF

DGROUP	GROUP	DATA,STACK


;
; The data segment defines locations which contain the offsets
; of the base and top of the stack.
;
DATA	SEGMENT PARA PUBLIC 'DATA'
	EXTRN	_STACK:WORD
	PUBLIC	_VER,_TOP,_BASE,_INAME,_ONAME,_PSP,_MBASE,_MNEXT,_MSIZE
	PUBLIC	_ENV,_DOS,_TSIZE,_ESIZE,_SS,_SP
NULL	DW	0
_VER	DB	"Lattice C 2.1"
_DOS	DB	0			; DOS major version number
	DB	0			; DOS minor version number
_SS	DW	0			; stack segment number
_SP	DW	0			; SP reset value
_TOP	DW	0			; top of stack (relative to SS)
_BASE	DW	OFFSET DGROUP:SBASE	; base of stack (relative to DS)
_INAME	DB	32 DUP(0)		; input file name
_ONAME	DB	32 DUP(0)		; output file name
_PSP	DD	0			; program segment prefix pointer
_MBASE	DD	0			; base of memory pool
_MNEXT	DD	0			; next available memory location
_MSIZE	DD 	0 			; number of bytes left in pool
_TSIZE	DW	0			; total size in paragraphs
_ENV	DD	0			; pointer to environment
_ESIZE	DW	0			; environment size in bytes
STKERR	DB	"Invalid stack size",0DH,0AH,"$"
NAMERR	DB 	"Invalid I/O redirection",0DH,0AH,"$"
MEMERR	DB	"Insufficient memory",0DH,0AH,"$"
OVFERR	DB	"*** STACK OVERFLOW ***",0DH,0AH,"$"
DATA	ENDS
;
; The stack segment is included to prevent the warning from the
; linker, and also to define the base (lowest address) of the stack.
;
STKRSV	EQU	128			; reserved stack size
STKMIN	EQU	512			; minimum run-time stack size
	IF	COM
STACK	SEGMENT	'DATA'
	ELSE
STACK	SEGMENT STACK 'DATA'
	ENDIF
SBASE	DB	STKRSV DUP (?)
STACK	ENDS

TAB	EQU	09H			; tab character
;
; The main program must set up the initial segment registers
; and the stack pointer, and set up a far return to the MS-DOS
; exit point at ES:0.  The command line bytes from the program
; segment prefix are moved onto the stack, and a pointer to
; them supplied to the C main module _main (which calls main).
;
	IF	S8086
PROG	SEGMENT	BYTE PUBLIC 'PROG'
	ASSUME	CS:PGROUP
	ENDIF

	IF	D8086
CODE	SEGMENT	BYTE PUBLIC 'CODE'
	ASSUME	CS:CGROUP
	ENDIF

	IF	P8086
_CODE	SEGMENT	BYTE
	ASSUME	CS:_CODE
	ENDIF

	IF	L8086
_PROG	SEGMENT	BYTE
	ASSUME	CS:_PROG
	ENDIF

	ASSUME	DS:DGROUP

	IF	LPROG EQ 0
	EXTRN	_MAIN:NEAR
	EXTRN	RBRK:NEAR
	ENDIF

	PUBLIC	C
	IF	COM
	ORG	0FEH
	ENDIF
C	PROC	FAR
	CLI
	IF	COM
	MOV	AX,OFFSET PGROUP:TAIL	; set up DS/SS for .COM file
	ADD	AX,16
	MOV	CL,4
	SHR	AX,CL
	MOV	BX,CS
	ADD	AX,BX
	MOV	DS,AX
	MOV	SS,AX
	MOV	SP,OFFSET DGROUP:SBASE+STKRSV
	ELSE
	MOV	AX,DGROUP		; set up DS/SS for .EXE file
	MOV	DS,AX
	MOV	AX,STACK
	MOV	SS,AX
	MOV	SP,STKRSV
	ENDIF
	STI
	MOV	AH,30H			; get DOS version number
	INT	21H
	OR	AL,AL
	JNZ	M0
	MOV	AX,1			; assume 1.00 if null return
M0:	MOV	WORD PTR _DOS,AX
	MOV	_PSP+2,ES		; set up pointer to prog seg prefix
;
; Examine the environment string area
;
	CMP	_DOS,2
	JL	M01
	MOV	AX,ES:[2CH]
	MOV	_ENV+2,AX		; set up pointer to environment
	OR	AX,AX
	JZ	M01			; branch if null
	PUSH	ES			; determine number of bytes
	CLD
	LES	DI,_ENV
	XOR	AX,AX
	MOV	CX,7FFFH
M0A:	REPNZ	SCASB
	JNZ	M0B
	SCASB
	JNZ	M0A
	INC	DI
	AND	DI,0FFFEH
	MOV	_ESIZE,DI
M0B:	POP	ES
;
; Examine command line
;
M01:	MOV	SI,80H			; check command line
	MOV	CL,ES:[SI]
	XOR	CH,CH
	JCXZ	M12			; branch if null
M1:	INC	SI			; scan for first arg
	MOV	AL,ES:[SI]
	CMP	_DOS,2
	JGE	M10
	CMP	AL,'<'
	JE	M2			; branch if input file name
	CMP	AL,'>'
	JE	M3			; branch if output file name
M10:	CMP	AL,'='
	JE	M4			; branch if stack size
	CMP	AL,' '
	JE	M11			; branch if white space
	CMP	AL,TAB
	JNE	M12			; branch if normal arg
M11:	DEC	CX
	JG	M1
	XOR	CX,CX
M12:	JMP	M5			; branch if no args found
;
; Get input file name
;
M2:	MOV	DI,OFFSET DGROUP:_INAME
	JMP	M31
;
; Get output file name
;
M3: 	MOV	DI,OFFSET DGROUP:_ONAME
;
; Save file name in data area
;
M31:	XOR	AH,AH
M32:	DEC	CX
	JZ	M33
	INC	SI
	MOV	AL,ES:[SI]
	CMP	AL,' '
	JZ	M33
	CMP	AL,TAB
	JZ	M33
	MOV	DS:[DI],AL
	INC	DI
	INC	AH
	CMP	AH,32
	JE	M34
	JMP	M32
M33:	MOV	BYTE PTR DS:[DI],0
	JMP	M11
M34:	MOV	DX,OFFSET DGROUP:NAMERR
	JMP	ABORT
;
; Get stack size from command line
;
M4:	XOR	BX,BX			; get stack size arg
M41:	DEC	CX
	JZ	M42
	INC	SI
	MOV	AL,ES:[SI]
	CMP	AL,' '
	JE	M42
	CMP	AL,TAB
	JE	M42
	SUB	AL,'0'
	JL	M43
	CMP	AL,9
	JG	M43
	ADD	BX,BX
	JC	M43
	MOV	DX,BX
	ADD	BX,BX
	JC	M43
	ADD	BX,BX
	JC	M43
	ADD	BX,DX
	JC	M43
	XOR	AH,AH
	ADD	BX,AX
	JC	M43
	JMP	M41
M42:	OR	BX,BX
	JZ	M43			; branch if stack size arg is null
	MOV	_STACK,BX
	JMP	M11
M43:	MOV	DX,OFFSET DGROUP:STKERR
	JMP	ABORT
;
; Set up the stack
;
	IF	LDATA EQ 0
M5:	MOV	AX,_ESIZE		; reserve space for environment
	ELSE
M5:	XOR	AX,AX
	ENDIF
	MOV	BX,_STACK		; get stack size
	SHR	BX,1			; make size even
	ADD	BX,BX
	CMP	BX,STKMIN
	JA	M51
	MOV	BX,STKMIN		; use default if too small
	MOV	_STACK,BX
M51:	ADD	BX,AX			; add environment size
	JC	M54			; abort if overflow
	MOV	DX,ES:2			; compute available paragraphs
	MOV	AX,SS
	SUB	DX,AX
	TEST	DX,0F000H
	JNZ	M52			; branch if greater than 64Kbytes
	SHL	DX,1			; convert to bytes
	SHL	DX,1
	SHL	DX,1
	SHL	DX,1
	JMP	M53
M52:	MOV	DX,0FFF0H		; use largest value
	IF	LDATA
M53:	CMP	DX,BX			; check if stack will fit
	JA	M55
	ELSE
M53:	ADD	BX,_BASE		; check if stack will fit
	JC	M54
	CMP	DX,AX
	JA	M55
	ENDIF
M54:	MOV	DX,OFFSET DGROUP:MEMERR	; abort if insufficient memory
	JMP	ABORT
M55:	CLI
	MOV	_TOP,BX			; set top-of-stack
	MOV	SP,BX			; set stack pointer
	IF	LDATA EQ 0
	MOV	AX,DS
	MOV	SS,AX
	ENDIF
	MOV	_SS,SS
	STI
;
; Set up memory allocation pointers
;
 	PUSH	CX			; save command byte count
	ADD	BX,15			; compute mem pool base segment number
	MOV	CL,4
	SHR	BX,CL
	MOV	AX,SS
	ADD	AX,BX
	MOV	_MBASE+2,AX
	MOV	_MNEXT+2,AX
	MOV	BX,ES:2			; get top segment number
	SUB	BX,AX			; compute memory pool size
	JBE	M54			; branch if insufficient memory
	MOV	CL,4			; compute number of bytes
	ROL	BX,CL
	MOV	AX,BX
	AND	AX,15
	AND	BX,0FFF0H
	MOV	_MSIZE,BX
	MOV	_MSIZE+2,AX
	CALL	RBRK			; reset memory pool
	OR	AX,AX
	JNZ	M54
	POP	DX			; restore command line length
;
; Put return address at top of stack
;
	PUSH	ES			; return is to 1st word of prog prefix
	XOR	AX,AX
	PUSH	AX
	MOV	BP,SP			; BP contains stack linkage
;
; Move environment to stack for small data models
;
	IF	LDATA EQ 0
	LES	DI,_ENV
	MOV	DI,_ESIZE
M6:	SUB	DI,2
	JL	M61
	PUSH	ES:[DI]
	JMP	M6
M61:	MOV	ES,_PSP+2
	MOV	_ENV,SP
	MOV	_ENV+2,SS
	ENDIF
;
; copy command line to stack
;
	MOV	BX,DX			; get residual command line length
	MOV	CX,DX
	ADD	BX,4			;3 bytes additional, 1 for rounding
	AND	BX,0FFFEH	 	;force even number of bytes
	SUB	SP,BX		 	;allocate space on stack
	MOV	DI,SP
	MOV	BYTE PTR SS:[DI],'c'	;store dummy program name
	INC	DI
	JCXZ	M8	 		;skip if no bytes to move
	MOV	BYTE PTR SS:[DI],' '
	INC	DI
M7:	MOV	AL,ES:[SI]	 	;move bytes to stack
	MOV	SS:[DI],AL
	INC	SI
	INC	DI
	LOOP	M7
M8:	MOV	BYTE PTR SS:[DI],0	; append null byte

;
; set up args for _main and call it
;
	MOV	_SP,SP			; save stack pointer reset value
	MOV	AX,SP			; push pointer to command line
	IF	LDATA
	PUSH	SS
	ENDIF
	PUSH	AX
	PUSH	DS			; make ES same as DS
	POP	ES
	CALL	_MAIN	 		;call C main
	CMP	_DOS,2
	JL	M9
	MOV	AX,4C00H
	INT	21H			; exit with zero code
M9:	MOV	SP,BP		 	;restore ptr to far return
	RET				;return to MS-DOS
;
; Come here to abort 
;
ABORT:	MOV	AH,9			; print error message
	INT	21H
	CMP	_DOS,2
	JL	A1
	MOV	AX,4C01H
	INT	21H
A1:	PUSH	ES
	XOR	AX,AX
	PUSH	AX
	RET
C	ENDP
	PAGE
;**
;
; name		XCOVF -- terminate execution after stack overflow
;
; description	This entry point is reached from a C module when its
;		entry sequence detects a stack overflow.  Control is
;		passed to XCOVF by a direct jump.
;
;**
	PUBLIC	XCOVF
XCOVF	PROC	FAR
	MOV	AX,_TOP
	SUB	AX,4
	MOV	SP,AX		; RESET STACK POINTER
	MOV	DX,OFFSET DGROUP:OVFERR
	MOV	AH,9
	INT	21H		; GENERATE ERROR MESSAGE
	CMP	_DOS,2
	JL	OVF1
	MOV	AX,4C01H
	INT	21H		; EXIT WITH ERROR CODE
OVF1:	RET			; RETURN TO MS-DOS
XCOVF	ENDP
;**
;
; name		XCEXIT -- terminate execution of C program
;
; description	This function terminates execution of the current
;		program by returning to MS-DOS.  The error code
;		argument normally supplied to XCEXIT is ignored 
;		in this implementation.
;
;**
	PUBLIC	XCEXIT
XCEXIT	PROC	FAR
	CMP	_DOS,2
	JL	EXIT1
	MOV	BP,SP
	MOV	AX,[BP+ECODE]	; GET ERROR CODE
	MOV	AH,4CH
	INT	21H		; EXIT
EXIT1:	MOV	AX,_TOP
	SUB	AX,4
	MOV	SP,AX
	RET
XCEXIT	ENDP

;**
;
; Dummy segment to establish top of program for small program models
;
 	IF	S8086
TAIL	SEGMENT	WORD 'PROG'
 	DW	-1
TAIL	ENDS
	ENDIF

	ENDPS
	END	C
