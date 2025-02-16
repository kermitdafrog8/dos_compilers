link \lc\c\c %1 %2 %3 %4 %5 %6 %7 %8 %9,%1,,\lc\s\lc
exe2bin %1
del %1.exe
del %1.com
ren %1.bin %1.com
