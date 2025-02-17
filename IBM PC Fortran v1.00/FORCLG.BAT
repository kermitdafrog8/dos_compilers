REM - FORCLG.BAT - C)ompile, L)ink and G)o
REM - This batch procedure is used to compile, link and run a
REM - Fortran program.
REM - Assume: Drive A has this batch file, FOR1, FOR2, LINK and
REM -         COMMAND.COM.
REM - Assume: DOS default drive (B) has Fortran source file.
REM - Note: You can copy this batch file onto your FOR1, FOR2 and
REM -       LIBRARY diskettes so the batch file will always be present
REM -       during a compilation.
REM - It uses one parameter, the name of the file to run.
REM - Note: You can remove the "REM"s from this batch for your 
REM         day-to-day use.
PAUSE -- Insert the FOR1 diskette in drive A
a:FOR1 %1;
PAUSE -- Insert the FOR2 diskette in drive A
a:FOR2
PAUSE -- Insert the LIBRARY diskette in drive A
a:LINK %1;
%1
