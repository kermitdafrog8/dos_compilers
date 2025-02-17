REM  EASY.BAT completely automates the compile,
REM  link and run steps for a BASIC program. 
REM  You will not have to change diskettes.
REM  This batch file requires the following:
REM  .  a two-drive system
REM  .  BASRUN-Linker diskette in drive A:
REM     with copies of BASRUN.EXE, EASY.BAT,
REM     and BASCOM.COM on the diskette
REM  .  work diskette in drive B:
REM  To run this batch file respond to the DOS prompt with:
REM         EASY progname parms
PAUSE . . . begin the compilation
B:
A:BASCOM %1%2;
A:LINK %1;
%1
