REM  BIG.BAT can be used to compile and
REM  link large BASIC programs.
REM  This batch file requires the following:
REM  .  a two-drive system
REM  .  BASIC diskette in drive A:
REM  .  work diskette in drive B:
REM  .  runfile diskette for the .EXE file
REM  .  BASCOM-Linker diskette for the link step
REM  .  BIG.BAT on BASIC and BASCOM-Linker diskettes
REM  To run this batch file respond to the DOS prompt with:
REM         BIG progname parms
PAUSE . . . begin the compilation
B:
A:BASCOM %1/O%2;
PAUSE . . . insert BASCOM-Linker in drive A:
REM  You will be prompted to change diskettes when the
REM  linker is ready to generate the .EXE file. Replace the 
REM  work diskette with the runfile diskette when prompted.
A:LINK %1/p;
REM  batch file complete
