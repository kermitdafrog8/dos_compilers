REM - EDFOR.BAT - Repeated edit and compile
REM - This batch procedure is used for repeated editing and compiling
REM - of a Fortran program.  No .OBJ is kept, .LST is displayed.
REM - Assume: Drive A has this batch file, EDLIN, FOR1 and
REM -         COMMAND.COM.
REM - Assume: DOS default drive (B) has Fortran source file.
REM - Note: You can copy this batch file onto your FOR1
REM -       diskette so the batch file will always be present
REM -       during a compilation.
REM - It has uses parameter, the name of the file to run.
REM - Note: You can remove the "REM"s from this batch for your 
REM         day-to-day use.
a:EDLIN %1.for
REM - If hardcopy wanted, press CNTL-PRTSC to echo listing to printer.
REM - To pause the listing, use CNTL-NUMLOCK.
PAUSE -- Insert the FOR1 diskette in drive A
a:FOR1 %1,nul,user;
PAUSE - Press CNTL-BREAK to not edit source again.
a:edfor %1
