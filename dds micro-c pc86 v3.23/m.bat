@echo off

set _extlist=map lst obj crf t1 t2 asm tmp

( for %%e in (%_extlist%) do (
    del %1.%%e 2>nul
))

del %1.exe 2>nul
del %1.com 2>nul

ntvdm -c mcp l=.\ %1.c %1.t1
if %errorlevel% neq 0 ( goto _alldone )

ntvdm -c mcc %1.t1 %1.t2
if %errorlevel% neq 0 ( goto _alldone )

ntvdm -c mco %1.t2 %1.asm
if %errorlevel% neq 0 ( goto _alldone )

ntvdm -h masm /Zi /Zd /z /l %1,,,;
if %errorlevel% neq 0 ( goto _alldone )

ntvdm -h link /CP:1 %1+PC86RL_S.OBJ,,%1,mclib.lib,nul.def
if %errorlevel% neq 0 ( goto _alldone )

( for %%e in (%_extlist%) do (
    del %1.%%e 2>nul
))

:_alldone

