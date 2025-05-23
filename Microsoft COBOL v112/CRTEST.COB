       IDENTIFICATION DIVISION.
       PROGRAM-ID.     CRTEST.

           THIS PROGRAM TESTS THE FUNCTIONS OF THE
           CRT DRIVERS USED WITH MS-COBOL.

           UPDATED 10.9.83 LN

       AUTHOR.         MICROSOFT.
       DATE-WRITTEN.   15 FEBRUARY 1983
       SECURITY.       NONE.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  ACCEPT-FIELDS.
           03  IN-FIELD         PIC X(6).
           03  IN-CHAR          PIC X.
           03  WAIT-CHAR        PIC X.
           03  ESC-CODE         PIC 99.

       SCREEN SECTION.

       01  CLEAR-SCREEN.
           03  BLANK SCREEN.

       01  BLINK-SCREEN.
           03  BLANK SCREEN
                   VALUE "SCREEN ATTRIBUTE TEST.".
           03  LINE 3 HIGHLIGHT
                   VALUE "THIS MESSAGE SHOULD BE HIGHLIGHTED.".
           03  LINE 4 BLINK    
                   VALUE "THIS MESSAGE SHOULD BLINK.".
           03  LINE 5 REVERSE-VIDEO
                   VALUE "THIS MESSAGE SHOULD BE IN REVERSE-VIDEO.".
           03  LINE 6 UNDERLINE
                   VALUE "THIS MESSAGE SHOULD BE UNDERLINED.".
           03  LINE 7     
                   VALUE "THIS MESSAGE SHOULD BE IN NORMAL VIDEO.".

       01  BLANK-LINE-SCREEN.
           03  LINE 10  PIC X(80) FROM ALL "X".
           03  LINE 11  PIC X(80) FROM ALL "X".
           03  LINE 12  PIC X(80) FROM ALL "X".
           03  LINE 13  PIC X(80) FROM ALL "X".
           03  LINE 14  PIC X(80) FROM ALL "X".

           03  LINE 11 COLUMN 20 BLANK LINE
                   VALUE "B".
           03  LINE 12 COLUMN 40 BLANK LINE
                   VALUE "B".
           03  LINE 13 COLUMN 60 BLANK LINE
                   VALUE "B".
           03  LINE 16 BLANK LINE.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM INITIAL-SCREEN.
           PERFORM ERASE-TEST.
           PERFORM POSITION-TEST.
           PERFORM TERMINATOR-TEST.
           PERFORM EDIT-TEST.
           PERFORM ALARM-TEST.
           PERFORM BLINK-TEST.
           PERFORM BLANK-LINE-TEST.

           DISPLAY (22, 1) "END OF TESTS.".
           DISPLAY " ".

           STOP RUN.





       INITIAL-SCREEN.
           DISPLAY "1.  THIS PROGRAM TESTS THE CRT DRIVER.".
           DISPLAY "2.  IF YOUR TERMINAL HAS THE ABILITY TO"
           DISPLAY "3.  TURN THE CURSOR ON AND OFF, THEN"
           DISPLAY "4.  YOU SHOULD SEE THE CURSOR STAY ON"
           DISPLAY "5.  THE SCREEN ONLY WHEN ASKED TO ENTER"
           DISPLAY "6.  DATA."
           DISPLAY "7.".
           DISPLAY "8.  A 24 BY 80 DISPLAY IS ASSUMED.".
           DISPLAY "9.".



       ERASE-TEST.
           DISPLAY "10. *****************************************".
           DISPLAY "11.".
           DISPLAY "12. CURSOR POSITION AND ERASE TEST.".
           DISPLAY "13. FIRST, LINES 12-24 OF THE".
           DISPLAY "14. SCREEN SHOULD BE ERASED. THEN"
           DISPLAY "15. THE CURSOR SHOULD HOME (TO THE"
           DISPLAY "16. TOP LEFT CORNER) AND THE FULL"
           DISPLAY "17. SCREEN SHOULD BE ERASED."

           DISPLAY "18.".
           DISPLAY "19. TYPE ANY CHARACTER TO CONTINUE.".
           ACCEPT (, ) WAIT-CHAR  WITH AUTO-SKIP.
           DISPLAY (12,  1) ERASE.
           PERFORM WAIT-FOR-INPUT.  
           DISPLAY ( 1,  1) ERASE.

           PERFORM WAIT-FOR-INPUT.




       POSITION-TEST.
           DISPLAY ( 1,  1) ERASE.
           DISPLAY ( 1,  1) "GENERAL CURSOR POSITION TEST.".
           DISPLAY ( 2,  1) "THIS TEST DISPLAYS TEXT IN THE"
           DISPLAY ( 3,  1) "POSITIONS DESCRIBED BY THE"
           DISPLAY ( 4,  1) "TEXT ITSELF."

           PERFORM WAIT-FOR-INPUT.  

           DISPLAY ( 1,  1) ERASE.
           DISPLAY ( 1,  1) "TOP LEFT CORNER".
           DISPLAY (24, 61) "BOTTOM RIGHT CORNER".
           DISPLAY ( 1, 65) "TOP RIGHT CORNER".
           DISPLAY (24,  1) "BOTTOM LEFT CORNER".
           DISPLAY (12, 30) "CENTER (MORE OR LESS)".
           DISPLAY ( 1, 35) "TOP CENTER".
           DISPLAY (24, 34) "BOTTOM CENTER".
           DISPLAY (12,  1) "LEFT CENTER".
           DISPLAY (12, 69) "RIGHT CENTER".

           PERFORM WAIT-FOR-INPUT.




       TERMINATOR-TEST.
           DISPLAY (1, 1) ERASE
                   "TERMINATOR KEY TEST.".

           DISPLAY (3, 1) "THIS TESTS WHETHER THE TERMINATOR "
                          "AND FUNCTION KEYS ARE RECOGNIZED CORRECTLY.".

           DISPLAY (5, 1) "EACH TIME THE PROMPT IS GIVEN, ENTER "
                          "ONE OF THE TERMINATOR OR FUNCTION KEYS".
           DISPLAY (6, 5) "SUCH AS RETURN, TAB, ESC, OR BACK TAB,".
           DISPLAY (7, 5) "DESCRIBED IN THE MS-COBOL USERS' GUIDE.".
           DISPLAY (8, 1) "THIS PROGRAM WILL RESPOND WITH THE "
                          "ESCAPE CODE FOR THAT KEY.".

           DISPLAY (10, 1) "THE TEST WILL TERMINATE WHEN YOU ENTER "
                          "ANY NON-SPACE KEY BEFORE THE TERMINATOR.".

           MOVE SPACE TO IN-CHAR.
           PERFORM GET-TERMINATOR
               UNTIL IN-CHAR NOT = SPACE.

       GET-TERMINATOR.
           DISPLAY (13, 1) ERASE.
           DISPLAY (12, 1) "ENTER TERMINATOR KEY: ".
           ACCEPT (, ) IN-CHAR WITH PROMPT.
           ACCEPT ESC-CODE FROM ESCAPE KEY.
           DISPLAY (13, 1) "ESCAPE CODE IS " ESC-CODE.
           PERFORM WAIT-FOR-INPUT.  





       EDIT-TEST.
           DISPLAY (1, 1) ERASE
                          "EDIT KEY TEST.".

           DISPLAY (3, 1) "THE FOLLOWING ABBREVIATIONS ARE USED "
                          "TO REPRESENT THE EDITING KEYS:".
           DISPLAY (5, 10) "[LD] = LINE (FIELD) DELETE KEY"
                   (6, 10) "[CD] = CHARACTER DELETE KEY"
                   (7, 10) "[BS] = BACKSPACE KEY"
                   (8, 10) "[FS] = FORWARD SPACE KEY".

           DISPLAY (10, 1) "THE MS-COBOL USERS' GUIDE DESCRIBES "
                            "WHICH TERMINAL KEYS PERFORM ".
           DISPLAY (11, 1) "THESE EDITING FUNCTIONS.".
           MOVE SPACE TO IN-CHAR.
           PERFORM GET-EDIT-FIELD 
               UNTIL IN-CHAR NOT = SPACE.

       GET-EDIT-FIELD.

           DISPLAY (13, 1) ERASE
                           "ENTER ABCDE[LD]+-XXX[CD]"
                           "[BS][BS]W[FS]YZ    ".

           MOVE SPACES TO IN-FIELD.
           ACCEPT (, ) IN-FIELD.
           IF  IN-FIELD NOT = "+-WXYZ"
               DISPLAY (15, 1) "*** RESULT WAS " IN-FIELD
               DISPLAY (16, 1) "SHOULD HAVE BEEN +-WXYZ"
           ELSE DISPLAY (15, 1) "RESULT WAS CORRECT.".

           DISPLAY (18, 1) "THIS TEST WILL TERMINATE WHEN YOU ENTER "
                          "ANY NON-SPACE KEY HERE.".

           ACCEPT (, ) IN-CHAR WITH PROMPT.
           IF IN-CHAR NOT = SPACE
                PERFORM WAIT-FOR-INPUT.



       ALARM-TEST.
           DISPLAY (1, 1) ERASE "ALARM ($ALARM) TEST.".

           DISPLAY (3, 1) "THE AUDIBLE TONE SHOULD SOUND "
                          "WHEN THIS MESSAGE IS PRINTED.".

           DISPLAY (5, 1) "TYPE ANY CHARACTER TO CONTINUE.".

           ACCEPT (, ) WAIT-CHAR  WITH AUTO-SKIP BEEP.




       BLINK-TEST.
           DISPLAY BLINK-SCREEN.
           PERFORM WAIT-FOR-INPUT.





       BLANK-LINE-TEST.
           DISPLAY (1, 1) ERASE "BLANK LINE ($EOL) TEST.".

           DISPLAY (3, 1) "LINES 10-14 WILL BE FILLED WITH X.".
           DISPLAY (4, 1) "THEN LINES 11-13 SHOULD BE BLANKED "
                          "FOLLOWING THE 'B' CHARACTER.".

           DISPLAY BLANK-LINE-SCREEN.
           PERFORM WAIT-FOR-INPUT.



       WAIT-FOR-INPUT.
           DISPLAY " ".
           DISPLAY " ".
           DISPLAY  "TYPE ANY CHARACTER TO CONTINUE.".
           ACCEPT (, ) WAIT-CHAR  WITH AUTO-SKIP.
    