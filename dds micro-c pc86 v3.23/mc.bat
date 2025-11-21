@echo off

rem if you've built cc.exe for masm/link (using m.bat), you can use cc.exe to build other apps like this:

set _extlist=map lst obj crf t1 t2 asm tmp

( for %%e in (%_extlist%) do (
    del %1.%%e 2>nul
))

del %1.exe 2>nul
del %1.com 2>nul

ntvdm -e:MCDIR=. cc %1 m=S -q

