@echo off
rem *
rem * Link object modules with libraries into ".COM" file
rem *
rem * Copyright 1988-2020 Dave Dunfield
rem *
rem * See CC.C for comments reguarding modifications for different linkers
rem *
set MCDIR=.
echo DDS MICRO-C PC86 Link Command
if .%1 == . goto help
if .%MCDIR% == . goto nomcd
if .%1 == .-s goto small
:tiny
echo Linking TINY model...
ntvdm -c link /noi %MCDIR%\PC86RL_T %1 %2 %3 %4 %5 %6 %7 %8 %9,%1,NUL,%MCDIR%\MCLIB;
if errorlevel 1 goto fail
echo Converting...
exe2bin %1 %1.COM
del %1.EXE
goto stop
:small
if .%2 == . goto help
echo Linking SMALL model...
shift
ntvdm -c link /noi %MCDIR%\PC86RL_S %1 %2 %3 %4 %5 %6 %7 %8 %9,%1,NUL,%MCDIR%\MCLIB;
if errorlevel 1 goto fail
goto stop
:help
echo.
echo Use: "%0 [-s] <filename(s)> ..."
echo.
echo Copyright 1988-2020 Dave Dunfield
echo All rights reserved.
goto stop
:nomcd
echo Environment variable MCDIR is not set!
:fail
echo Link aborted due to errors!!!
:stop
