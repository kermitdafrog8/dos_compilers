;***
;version.inc - defines current memory model
;
;	Copyright (c) 1987-1988, Microsoft Corporation.  All rights reserved.
;
;Purpose:
;	This file defines the current memory model being used.
;
;*******************************************************************************

?PLM=	0
?WIN=	0

ifdef	mem_s
	memS	equ	1	; small model
endif

ifdef	mem_m
	memM	equ	1	; medium model
endif

ifdef	mem_c
	memC	equ	1	; compact model
endif

ifdef	mem_l
	memL	equ	1	; large model
endif
