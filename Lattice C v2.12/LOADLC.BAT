rem ***INSERT DISK #1 INTO DRIVE A***
pause
c:
cd \lc
copy a:*.bat
copy a:*.exe
copy a:*.h
cd source
copy a:*.asm
copy a:*.c
cd \lc\c
copy a:cc.obj c.obj
copy a:cm8086.mac
cd \lc
rem ***INSERT DISK #2 INTO DRIVE A***
pause
copy a:*.exe
copy a:*.com
rem ***INSERT DISK#3 INTO DRIVE A***
pause
cd \lc\s
copy a:cs.obj c.obj
copy a:ios1s.obj ios1.obj
copy a:lcs.lib lc.lib
copy a:sm8086.mac dos.mac
rem ***INSERT DISK #4 INTO DRIVE A***
pause
cd \lc\p
copy a:cp.obj c.obj
copy a:ios1p.obj ios1.obj
copy a:lcp.lib lc.lib
copy a:pm8086.mac dos.mac
rem ***INSERT DISK #5 INTO DRIVE A***
pause
cd \lc\d
copy a:cd.obj c.obj
copy a:ios1d.obj ios1.obj
copy a:lcd.lib lc.lib
copy a:dm8086.mac dos.mac
rem ***INSERT DISK #6 INTO DRIVE A*** 
pause
cd \lc\l
copy a:cl.obj c.obj
copy a:ios1l.obj ios1.obj
copy a:lcl.lib lc.lib
copy a:lm8086.mac dos.mac
cd \
rem ***FINISHED***

