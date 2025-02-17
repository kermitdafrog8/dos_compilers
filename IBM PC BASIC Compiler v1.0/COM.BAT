REM  COM.BAT requires the following:
REM  . a two-drive system
REM  . BASIC diskette in drive A:
REM  . work diskette in drive B:
REM  . IBMCOM.OBJ copied to the work diskette
REM  . BASCOM-Linker diskette for the link step
REM  . COM.BAT on BASIC and BASCOM-Linker diskettes
PAUSE . . . begin the compilation
B:
A:BASCOM %1/O,,%2;
PAUSE . . insert BASCOM-Linker in drive A:
A:LINK %1+IBMCOM;
%1
