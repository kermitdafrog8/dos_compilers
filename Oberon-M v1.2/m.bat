@echo off

rem note: to use ntvdm, libraries must be rebuilt for the 8086 (not 80186) using comp86em.bat

ntvdm -c -r:. oc %1.mod 8086
ntvdm -c -r:. link %1+lio+sys ;

