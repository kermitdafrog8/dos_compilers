echo off
REM IBM Personal Computer FORTRAN Compiler (SETUP.BAT)
REM (C)Copyright IBM Corp 1982, 1984
cls
a:
if %1.==rerun. goto h
if not %1.==. goto nh
:h
cls
echo This program is designed to help you create a set of work
echo diskettes or fixed disk directory from the backup copies of
echo your master FORTRAN diskettes.
echo To use it, type
echo		       SETUP  dd  mathlib  dos	sides
echo where
echo		 dd = The destination drive - MUST include colon.
echo	    mathlib = Type of math library you want in your
echo		      FORTRAN.LIB.  It can be one of the following:
echo				EMULATOR - very precise
echo					   with 8087 - very fast runtime
echo					   without 8087 - average runtime
echo				8087ONLY - must have 8087 installed
echo					   very fast runtime
echo					   very precise
echo				REGMATH  - won't utilize 8087
echo					   fast runtime
echo					   average precision
echo		dos = DOS version your FORTRAN program runs under.
echo		      Use DOS20 or DOS11 (Read book for DOS11).
echo	      sides = Number of sides on destination drive.
echo		      Can be 1 or 2 (leave blank for fixed disk)
if %1.==rerun. echo Please rerun SETUP program.
goto f
:nh
cls
echo Program is running
if not exist %1nul goto e1
if %1==A: goto e1
if %1==a: goto e1
goto ne1
:e1
cls
echo 
echo Destination drive must be a drive letter followed by a colon.
echo Drive %1 is not allowed.
pause
setup rerun
:ne1
if .%2==.8087only goto ne2
if .%2==.emulator goto ne2
if .%2==.regmath goto ne2
if .%2==.8087ONLY goto ne2
if .%2==.EMULATOR goto ne2
if .%2==.REGMATH goto ne2
if .%2==.8087Only goto ne2
if .%2==.Emulator goto ne2
if .%2==.Regmath goto ne2
cls
echo 
echo %2 is an incorrect library parameter.  Strike any key
echo for instructions, then rerun SETUP.
pause
setup rerun
:ne2
if .%3==.dos11 goto ne3
if .%3==.dos20 goto ne3
if .%3==.DOS11 goto ne3
if .%3==.DOS20 goto ne3
if .%3==.Dos11 goto ne3
if .%3==.Dos20 goto ne3
cls
echo 
echo %3 is an incorrect DOS version.  Strike any key
echo for instructions, then rerun SETUP.
pause
setup rerun
:ne3
if %4.==. goto ne4
if %4==1 goto ne4
if %4==2 goto ne4
cls
echo 
echo Incorrect number of sides.  Strike any key for
echo instructions, then rerun SETUP.
pause
setup rerun
:ne4
if %4.==. goto mkd
echo 
cls
echo Insert a blank, formatted diskette in drive B:
pause
goto nhd2
:mkd
md %1\fortran
cd %1\fortran
:nhd2
copy for1.exe %1
cls
echo 
echo Insert the FOR2 diskette in drive A:
pause
if %4.==. goto T
if %4==2 goto T
echo 
cls
echo Remove the diskette from drive B:, label it the FOR1
echo diskette, and insert a blank, formatted diskette in drive B:
pause
:T
copy for2.exe %1
copy for3.exe %1
if %4.==. goto hd
if %4==2 goto C
cls
echo 
echo Remove the diskette from drive B:, label it the FOR2
echo diskette, and insert a blank, formatted diskette in drive B:
pause
goto hd
:C
cls
echo 
echo Remove the diskette from drive B:, label it the FOR1, FOR2
echo diskette, and insert a blank, formatted diskette in drive B:
pause
:hd
copy link.exe %1
copy dos20.lib %1
makelib %1 %2 %3 %4
:f
echo on
