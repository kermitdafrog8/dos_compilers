REM  SUBRT.BAT can be used to compile your BASIC program
REM  and link it with your assembly language subroutine.
REM  This batch file requires the following:
REM  .  a two-drive system
REM  .  BASIC diskette in drive A:
REM  .  work diskette in drive B:
REM  .  assembled subrtname.OBJ on the work diskette
REM  .  BASCOM-Linker diskette for the link step
REM  .  SUBRT.BAT on BASIC and BASCOM-Linker diskettes
PAUSE . . . additional documentation follows
REM  To run this batch file respond to the DOS prompt:
REM         SUBRT subrtname progname parms
REM  . subrtname indicates assembled subroutine name
REM  . progname indicates BASIC source program name
REM  . parms indicates compiler switches
PAUSE . . . begin the compilation 
B:
A:BASCOM %2/O%3;
PAUSE . . . insert BASCOM-Linker in drive A:
A:LINK %2+%1;
REM  batch file complete
