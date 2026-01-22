@echo off
setlocal

ntvdm /r:. m2 /c %1
ntvdm /r:. m2 /l %1

del obj\%1.obj 1>nul 2>nul

