del %1.obj 2>nul
del %1.exe 2>nul

ntvdm -c bascom %1.bas,,%1.lst,
ntvdm -c link %1,,,;

del %1.lst 2>nul
del %1.map 2>nul
del %1.obj 2>nul


