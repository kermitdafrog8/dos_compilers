PAUSE  Put COBOL COMPILER in drive A, source files on drive B
A:COBOL DEMO,,CON/D;
A:COBOL BUILD,,CON/D;
A:COBOL UPDATE,,CON/D;
PAUSE  Put LINK.EXE and COBOL libraries in drive A
A:LINK DEMO+BUILD,,NUL,A:;
A:LINK UPDATE,,NUL,A:;
                   