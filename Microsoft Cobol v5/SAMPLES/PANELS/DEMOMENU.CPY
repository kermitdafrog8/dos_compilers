      ******************************************************************
      *  Menu texts and control tables used by PANELEX2.
      *
      *  Copyright (c) Micro Focus 1987.
      *
      ******************************************************************

      ******************************************************************
      *  Main menu bar control table and text.
      ******************************************************************

       01 Menu-Bar-Text.
	03 FILLER	   PIC X(10) VALUE " F1=Help  ".
	03 FILLER	   PIC X(26) VALUE "F2=Alter Parameter Block  ".
	03 FILLER	   PIC X(12) VALUE "F3=Execute	".
	03 FILLER	   PIC X(14) VALUE "F4=Edit Text  ".
	03 FILLER	   PIC X(08) VALUE "Esc=Exit".
	03 FILLER	   PIC X(23) VALUE SPACES.

       01 Menu-Bar-Control-Table.
	03 FILLER			   PIC 9(2) COMP VALUE 0.
	03 FILLER			   PIC 9(2) COMP VALUE 9.
	03 FILLER			   PIC 9(2) COMP VALUE 9.
	03 FILLER			   PIC 9(2) COMP VALUE 26.
	03 FILLER			   PIC 9(2) COMP VALUE 35.
	03 FILLER			   PIC 9(2) COMP VALUE 12.
	03 FILLER			   PIC 9(2) COMP VALUE 47.
	03 FILLER			   PIC 9(2) COMP VALUE 14.
	03 FILLER			   PIC 9(2) COMP VALUE 61.
	03 FILLER			   PIC 9(2) COMP VALUE 10.
       01 FILLER REDEFINES Menu-Bar-Control-Table.
	03 FILLER OCCURS 5.
	 05 Menu-Option-Start		   PIC 9(2) COMP.
	 05 Menu-Option-Length		   PIC 9(2) COMP.

      ******************************************************************
      *  Main Pull Down Panel Text
      ******************************************************************

       01 Main-Pull-Down-Text.
	03 FILLER		  PIC X(49) VALUE
	       "쳐컴컴컴컴컴컴컴컴컴컴컴컨컴컴컴컴컴컴컴컴컴컴컴�".
	03 FILLER		  PIC X(44) VALUE
	       "쿑unction	      PIC 9(2) COMP VALUE   ".
	03 MPD-Function 	  PIC Z9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(44) VALUE
	       "쿞tatus 	      PIC 9(2) COMP VALUE   ".
	03 MPD-Status		  PIC Z9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿛anel ID	      PIC 9(4) COMP VALUE ".
	03 MPD-Panel-ID 	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(49) VALUE
	       "쿛anel Control Group				�".
	03 FILLER		  PIC X(49) VALUE
	       "쿛anel Update Group				�".
	03 FILLER		  PIC X(45) VALUE
	       "쿑ill Character       PIC X	    VALUE   """.
	03 MPD-Fill-Character	  PIC X.
	03 FILLER		  PIC X(3) VALUE """ �".
	03 FILLER		  PIC X(44) VALUE
	       "쿑ill Attribute       PIC X	    VALUE X""".
	03 MPD-Fill-Attribute	  PIC XX.
	03 FILLER		  PIC X(3) VALUE """ �".
	03 FILLER		  PIC X(44) VALUE
	       "쿢pdate Mask	      PIC X	    VALUE X""".
	03 MPD-Update-Mask	  PIC XX.
	03 FILLER		  PIC X(3) VALUE """ �".
	03 FILLER		  PIC X(44) VALUE
	       "쿞croll Direction     PIC 9(2) COMP VALUE   ".
	03 MPD-Scroll-Direction   PIC Z9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿞croll Count	      PIC 9(4) COMP VALUE ".
	03 MPD-Scroll-Count	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(49) VALUE
	       "읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�".

      ******************************************************************
      *  Panel Control Group Pop-Up Text
      ******************************************************************

       01 Panel-Control-Group-Text.
	03 FILLER		  PIC X(49) VALUE
	       "旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�".
	03 FILLER		  PIC X(42) VALUE
	       "쿛anel Width	      PIC 9(4) COMP VALUE ".
	03 MPD-Panel-Width	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿛anel Height	      PIC 9(4) COMP VALUE ".
	03 MPD-Panel-Height	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿣isible-Width	      PIC 9(4) COMP VALUE ".
	03 MPD-Visible-Width	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿣isible Height       PIC 9(4) COMP VALUE ".
	03 MPD-Visible-Height	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿑irst Visible Col    PIC 9(4) COMP VALUE ".
	03 MPD-First-Visible-Col  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿑irst Visible Row    PIC 9(4) COMP VALUE ".
	03 MPD-First-Visible-Row  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿛anel Start Column   PIC 9(4) COMP VALUE ".
	03 MPD-Panel-Start-Column PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿛anel Start Row      PIC 9(4) COMP VALUE ".
	03 MPD-Panel-Start-Row	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(49) VALUE
	       "읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�".

      ******************************************************************
      *  Panel Update Group Pop-Up Text
      ******************************************************************

       01 Panel-Update-Group-Text.
	03 FILLER		  PIC X(49) VALUE
	       "旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�".
	03 FILLER		  PIC X(42) VALUE
	       "쿍uffer Offset	      PIC 9(4) COMP VALUE ".
	03 MPD-Buffer-Offset	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿣ertical Stride      PIC 9(4) COMP VALUE ".
	03 MPD-Vertical-Stride	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿢pdate Count	      PIC 9(4) COMP VALUE ".
	03 MPD-Update-Count	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿝ectangle Offset     PIC 9(4) COMP VALUE ".
	03 MPD-Rectangle-Offset   PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿢pdate Start Col     PIC 9(4) COMP VALUE ".
	03 MPD-Update-Start-Col   PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿢pdate Start Row     PIC 9(4) COMP VALUE ".
	03 MPD-Update-Start-Row   PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿢pdate Width	      PIC 9(4) COMP VALUE ".
	03 MPD-Update-Width	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(42) VALUE
	       "쿢pdate Height	      PIC 9(4) COMP VALUE ".
	03 MPD-Update-Height	  PIC ZZZ9.
	03 FILLER		  PIC X(3) VALUE "  �".
	03 FILLER		  PIC X(49) VALUE
	       "읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�".

      ******************************************************************
      *  Message Panel Text
      ******************************************************************

       01 Message-Panel-Text.
	03 FILLER		    PIC X VALUE "�".
	03 Message-Text-Top-Bar     PIC X(79).
	03 FILLER		    PIC X VALUE "�".
	03 Message-Text-Area	    PIC X(79).
	03 FILLER		    PIC X VALUE "�".
	03 Message-Text-Second-Line PIC X(79).
	03 FILLER		    PIC X VALUE "�".
	03 Message-Text-Prompt.
	 05 FILLER		    PIC X(29) VALUE
	   "Press any key to continue ...".
	 05 Message-Text-Prompt-End PIC X(50).
	03 FILLER		    PIC X VALUE "�".
	03 Message-Text-Bottom-Bar  PIC X(79).

      /*****************************************************************
      *  Prompting Control Table
      *
      *  This table controls which parameter gets updated depending
      *  where we are in the current pop-up panel.
      *
      *  Control-Byte	    : Determines what sort of value is prompted
      * 		      for :
      *
      * 			0 : 2 digit number.
      * 			1 : 4 digit number.
      * 			2 : 2 digit hex.
      * 			3 : 1 character.
      * 			4 : No prompt required. A another
      * 			    pop-up panel is displayed.
      * 			    Param-Block-Start is not used in
      * 			    this case.
      *
      *  Param-Block-Start  : Determines where in the Panels parameter
      * 		      the initial block is to be read from and
      * 		      where the result is to be placed.
      *
      *  Help-Screen	    : The help screen to be displayed if F1 is
      * 		      pressed in this field.
      *
      ******************************************************************

       01 Prompting-Control-Table.
	03 FILLER		   PIC X(3) VALUE X"000103".
	03 FILLER		   PIC X(3) VALUE X"000204".
	03 FILLER		   PIC X(3) VALUE X"010305".
	03 FILLER		   PIC X(3) VALUE X"040000".
	03 FILLER		   PIC X(3) VALUE X"040000".
	03 FILLER		   PIC X(3) VALUE X"032516".
	03 FILLER		   PIC X(3) VALUE X"022617".
	03 FILLER		   PIC X(3) VALUE X"022718".
	03 FILLER		   PIC X(3) VALUE X"002819".
	03 FILLER		   PIC X(3) VALUE X"01291A".
	03 FILLER		   PIC X(3) VALUE X"010506".
	03 FILLER		   PIC X(3) VALUE X"010707".
	03 FILLER		   PIC X(3) VALUE X"010908".
	03 FILLER		   PIC X(3) VALUE X"010B09".
	03 FILLER		   PIC X(3) VALUE X"010D0A".
	03 FILLER		   PIC X(3) VALUE X"010F0B".
	03 FILLER		   PIC X(3) VALUE X"01110C".
	03 FILLER		   PIC X(3) VALUE X"01130D".
	03 FILLER		   PIC X(3) VALUE X"01150E".
	03 FILLER		   PIC X(3) VALUE X"01170F".
	03 FILLER		   PIC X(3) VALUE X"011910".
	03 FILLER		   PIC X(3) VALUE X"011B11".
	03 FILLER		   PIC X(3) VALUE X"011D12".
	03 FILLER		   PIC X(3) VALUE X"011F13".
	03 FILLER		   PIC X(3) VALUE X"012114".
	03 FILLER		   PIC X(3) VALUE X"012315".
       01 FILLER REDEFINES Prompting-Control-Table.
	03 FILLER OCCURS 26.
	 05 Control-Byte	   PIC 9(2) COMP.
	 05 Param-Block-Start	   PIC 9(2) COMP.
	 05 Help-Screen 	   PIC 9(2) COMP.
