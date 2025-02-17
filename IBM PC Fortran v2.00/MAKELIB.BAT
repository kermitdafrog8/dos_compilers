echo off
REM IBM Personal Computer FORTRAN Compiler (MAKELIB.BAT)
REM (C)Copyright IBM Corp 1982, 1984
echo 
cls
echo Insert the LIBRARY diskette in drive A:
pause
if %2==8087only goto M8
if %2==emulator goto ME
if %2==regmath goto MR
if %2==8087ONLY goto M8
if %2==EMULATOR goto ME
if %2==REGMATH goto MR
if %2==8087Only goto M8
if %2==Emulator goto ME
if %2==Regmath goto MR
echo Incorrect library parameter - start the program over.
goto f
:M8
:ME
echo 
cls
echo Your FORTRAN library will now be created.
echo This will take 5-10 minutes.
if %3==dos20 goto d
if %3==DOS20 goto d
lib partial.lib/p:512+ieeemath.lib+%2.lib+%3.lib,nul,%1fortran.lib;
goto ex
:d
lib partial.lib/p:512+ieeemath.lib+%2.lib+%1%3.lib,nul,%1fortran.lib;
goto ex
:MR
echo 
cls
echo Your FORTRAN library will now be created.
echo This will take 5-10 minutes.
if %3==dos20 goto r
if %3==DOS20 goto r
lib partial.lib/p:512+%2.lib+%3.lib,nul,%1fortran.lib;
goto ex
:r
lib partial.lib/p:512+%2.lib+%1%3.lib,nul,%1fortran.lib;
:ex
del %1dos20.lib
if %4.==. goto s4
cls
echo 
echo Remove the diskette from drive B: and label it the LIBRARY diskette
pause
:s4
cls
echo 
echo The setup operation is complete.
if %4.==. goto s5
echo Your work diskettes are now ready to use.
goto f
:s5
echo Your compiler is in directory \fortran on drive %1
:f
echo on
