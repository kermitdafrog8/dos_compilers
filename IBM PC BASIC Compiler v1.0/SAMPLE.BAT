B:
A:BASCOM %1,,%2;
DIR
COPY %1.LST LPT1:
ERASE %1.LST
PAUSE . . insert BASRUN-Linker in drive A: 
A:LINK %1;
DIR
%1
