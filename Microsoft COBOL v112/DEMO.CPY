
      *  ************* START OF COPIED FILE *************
           DISPLAY SPACE.
           DISPLAY SPACE.
           DISPLAY TEN-SPACES, 
           " This is program DEMO, the first program in the".
           DISPLAY TEN-SPACES, 
           " MS-COBOL demonstration suite. In this suite".
           DISPLAY TEN-SPACES, 
           " of programs, you will see several information and".
           DISPLAY TEN-SPACES, 
           " menu screens which will guide you through the ".
           DISPLAY TEN-SPACES, 
           " demonstration.". 
           DISPLAY SPACE.
           DISPLAY TEN-SPACES, 
           " If you see the words COBRUN UN-INSTALLED after". 
           DISPLAY TEN-SPACES, 
           " several screen lines, and the screen appears jumbled,". 
           DISPLAY TEN-SPACES, 
           " then you have not run the INSTALL utility, which allows ".
           DISPLAY TEN-SPACES, 
           " you to use different types of terminals. ". 
           DISPLAY SPACE.
           DISPLAY TEN-SPACES, 
           " If this happens, please cancel this program (typing the".
           DISPLAY TEN-SPACES, 
           ' letter "E" a large number of times will work, otherwise'.
           DISPLAY TEN-SPACES, 
           " restart your system), and see the MS-COBOL Users Guide".
           DISPLAY TEN-SPACES, 
           " for instructions on running the INSTALL utility. ".
           DISPLAY SPACE.
           DISPLAY TEN-SPACES, 
           " After running INSTALL, you can successfully run this".
           DISPLAY TEN-SPACES, 
           " demonstration. You can cancel this program now by typing"
           DISPLAY TEN-SPACES,
           " E (for End) followed by ENTER.".
           DISPLAY " ".
           DISPLAY TEN-SPACES,
           " Please hit ENTER by itself to continue. ".
           ACCEPT WS-OPTION.

           IF NOT (END-OPTION)
               PERFORM P005-PROCESS.
      *  ************* END OF COPIED FILE *************


                           