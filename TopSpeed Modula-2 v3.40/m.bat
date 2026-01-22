@echo off
setlocal

rem build using a project file
ntvdm -r:. -e:path=c:\sys sys\tsc /m %1.pr

del terminal.obj 1>nul 2>nul
del ascii.obj 1>nul 2>nul
del inout.obj 1>nul 2>nul
del %1.obj 1>nul 2>nul

rem NOT IN USE
rem build using discrete comple and link steps
rem ntvdm -e:path=c:\sys;LIB=C:\LIB;OBJ=C:\LIB -r:. sys\tsc /ms %1.mod
rem link fails and I can't figure out how to fix it
rem ntvdm -e:path=c:\sys;LIB=C:\LIB;OBJ=C:\LIB -r:. sys\tsc /ms %1 /l

