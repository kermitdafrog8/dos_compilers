1000 '  IBM Personal Computer BASIC Compiler Demonstration Program
1010 '  Version 1.00 (C)Copyright IBM Corp 1982
1015 '  Licensed Material - Program Property of IBM
1020 '
1030 ON ERROR GOTO 2680
1040 HIGH=0:NM$="BASCOM"
1050 DEFINT A-Z
1060 DIM S.STAT(20),S.X(20),S.Y(20),S.SP(20),S.PAT(20),S.PIC$(20,1),S.SCORE(20)
1070 DIM S.LEN(20),BUL(80),SND$(5)
1080 DIM B.X(20),B.Y(20),B.ACT(20)
1090 DIM N.PIC$(10,1),N.SCORE(10),N.SP(10),N.LEN(10)
1100 DIM X.TOP$(6),X.BOT$(6)
1110 WIDTH 80:WD=80
1120 KEY OFF : COLOR 7,0,0 : CLS
1130 IF WD=80 THEN SCREEN 0,1:LOCATE ,,0
1140 M$="IBM Personal Computer" : Y=8 : GOSUB 2670
1150 M$="BASIC Compiler" : Y=10 : GOSUB 2670
1160 M$="Demonstration Program" : Y=12 : GOSUB 2670
1170 M$="Do you have a color monitor (Y/N)? " : Y=16 : GOSUB 2670
1180 A$=INKEY$:IF A$="" THEN GOTO 1180
1190 IF A$="Y" OR A$="y" THEN CLR=1:GOTO 1230
1200 IF A$="n" OR A$="N" THEN CLR=0:GOTO 1230
1210 IF A$=CHR$(3) THEN END
1220 GOTO 1180
1230 '
1240 '
1250 '      Target Program
1260 '
1270 CLS
1280 M$="TTTTT   AAA   RRRR    GGGG  EEEEE  TTTTT" : Y=4 : GOSUB 2670
1290 M$="  T    A   A  R   R  G      E        T  " : Y=5 : GOSUB 2670
1300 M$="  T    A   A  R   R  G      E        T  " : Y=6 : GOSUB 2670
1310 M$="  T    AAAAA  RRRR   G  GG  EEE      T  " : Y=7 : GOSUB 2670
1320 M$="  T    A   A  R R    G   G  E        T  " : Y=8 : GOSUB 2670
1330 M$="  T    A   A  R  R   G   G  E        T  " : Y=9 : GOSUB 2670
1340 M$="  T    A   A  R   R   GGGG  EEEEE    T  " : Y=10: GOSUB 2670
1350 LOCATE 13,1 : PRINT "Instructions:" : PRINT
1360 PRINT "Press space bar   to fire"
1370 PRINT "Press left  arrow to move left"
1380 PRINT "Press right arrow to move right"
1390 PRINT "Press ESC         to return to menu"
1400 PRINT "Press Ctrl-Break  to exit the program"
1410 PRINT : PRINT "NOTE - Only 1 shell per position"
1420 PRINT : PRINT "Press any key to continue"
1430 A$=INKEY$:IF A$="" THEN 1430
1440 IF A$=CHR$(3) THEN SCREEN 0,0,0:END
1450 NL = 24 : WIDTH WD :LOCATE ,,0
1460 IF CLR THEN COLOR 7,1,1
1470 CLS
1480 M.S=12
1490 M.B=12
1500 M.N=5 : GOSUB 2550
1510 FOR I=1 TO 5
1520   X.TOP$(I)="\"+STRING$(I,"|")+"/" : X.BOT$(I)="/"+STRING$(I,"|")+"\"
1530   IF A=3 THEN END
1540 NEXT I
1550 BULLIT$=CHR$(127)
1560 PLAY "mbt255l32"
1570 LOCATE 25,1 : IF WD=80 THEN PRINT "IBM Personal Computer ";
1580 PRINT "Basic Compiler Demo"; :
1590 M$="(ESC to restart)" : LOCATE 25,WD-LEN(M$) : PRINT M$;
1600 D.T=12: M.T=(WD-5)*D.T-1
1610 LOCATE NL-1,3 : PRINT STRING$(WD-5,BULLIT$);
1620 FOR I=3 TO WD-3 : BUL(I)=1 : NEXT : NB=WD-5
1630 FOR I=2 TO NL-1
1640   LOCATE I,1 : PRINT CHR$(186); : LOCATE I,WD-1 : PRINT CHR$(186);
1650 NEXT
1660 LOCATE 1,1 : PRINT CHR$(201);STRING$(WD-3,205);CHR$(187);
1670 LOCATE NL,1 : PRINT CHR$(200);STRING$(WD-3,205);CHR$(188);
1680 LOCATE NL-2,1 : PRINT CHR$(199);STRING$(WD-3,196);CHR$(182);
1690 BX=WD\2 : LOCATE NL-2,BX : PRINT CHR$(208);
1700 LOCATE 1,8*(WD/40):PRINT " SCORE = ";SCORE:LOCATE 1,26*(WD/40):PRINT " TIME LEFT";(899-C.T)\10
1710 FOR C.T=1 TO M.T
1720   FOR I=3 TO M.S
1730     ON S.STAT(I)+1 GOTO 1740,1800,1930,1960,2080,2120
1740     ' Inactive
1750     IF RND>.17 THEN 2190
1760     J=4*RND
1770     S.STAT(I)=1 : S.X(I)=3 : S.Y(I)=I : S.SP(I)=N.SP(J) : S.PAT(I)=0
1780     S.PIC$(I,0)=N.PIC$(J,0):S.PIC$(I,1)=N.PIC$(J,1) : S.SCORE(I)=N.SCORE(J)
1790     S.LEN(I)=N.LEN(J):LOCATE S.Y(I),S.X(I)-1:PRINT S.PIC$(I,0); : GOTO 2190
1800     ' Fly
1810     X1=S.X(I) : Y=S.Y(I) : X2=S.X(I)+S.LEN(I)
1820     IF C.T AND S.SP(I) THEN X2=X2-1 : GOTO 1860
1830     LOCATE S.Y(I),X1
1840     PRINT S.PIC$(I,S.PAT(I)); : X1=X1+1 : S.X(I)=X1
1850     S.PAT(I)=1-S.PAT(I) : IF X1=WD-7 THEN S.STAT(I)=2
1860     FOR J=0 TO M.B
1870       IF B.ACT(J)=0 THEN 1910
1880       IF B.Y(J)<>Y THEN 1910
1890       IF B.X(J)>=X1 THEN IF B.X(J)<=X2 THEN 1900 ELSE 1910 ELSE 1910
1900       S.STAT(I)=3 : B.ACT(J)=0 : SCORE=SCORE+S.SCORE(I)
1910     NEXT J
1920     GOTO 2190
1930     ' Final
1940     LOCATE S.Y(I),S.X(I) : PRINT "      "; : S.STAT(I)=0
1950     GOTO 2190
1960     ' Hit
1970     PLAY SND$(S.LEN(I)-1)
1980     X=S.X(I) : Y=S.Y(I) : LN=S.LEN(I)
1990     IF CLR THEN COLOR 4
2000     LOCATE Y-1,X-1 : PRINT X.TOP$(LN);
2010     LOCATE Y,X-1 : PRINT "-";
2020     LOCATE Y,X+LN : PRINT "-";
2030     LOCATE Y+1,X-1 : PRINT X.BOT$(LN);
2040     IF CLR THEN COLOR 7
2050     S.STAT(I)=4
2060     LOCATE 1,8*(WD/40):PRINT " SCORE = ";SCORE
2070     GOTO 2190
2080     ' Blown
2090     LOCATE S.Y(I),S.X(I) : PRINT SPC(S.LEN(I));
2100     S.STAT(I)=5
2110     GOTO 2190
2120     ' Down
2130     X=S.X(I) : Y=S.Y(I) : LN=S.LEN(I)+2
2140     LOCATE Y-1,X-1 : PRINT SPC(LN);
2150     LOCATE Y,X-1 : PRINT SPC(LN);
2160     LOCATE Y+1,X-1 : PRINT SPC(LN);
2170     S.STAT(I)=0
2180     GOTO 2190
2190   NEXT I
2200   FOR I=0 TO M.B
2210     IF B.ACT(I)=0 THEN 2250
2220     IF B.Y(I)=NL-2 THEN 2240
2230     LOCATE B.Y(I),B.X(I):PRINT " ";:IF B.Y(I)=2 THEN B.ACT(I)=0:GOTO 2350
2240     B.Y(I)=B.Y(I)-1 : LOCATE B.Y(I),B.X(I) : PRINT BULLIT$; : GOTO 2350
2250     A$=INKEY$ : IF LEN(A$)=0 THEN 2350
2260     A=ASC(A$) : IF A<>32 THEN IF A=3 THEN SCREEN 0,0,0:COLOR 7,0:END ELSE GOTO 2300
2270     IF BUL(BX)=0 THEN 2300
2280     BUL(BX)=0 : B.X(I)=BX : B.Y(I)=NL-2 : B.ACT(I)=1:NB=NB-1
2290     LOCATE NL-1,BX : PRINT " "; : PLAY "N35"
2300 '
2310     IF A=0 THEN A=ASC(MID$(A$,2))-23
2320     IF A=52 AND BX>3 THEN BX=BX-1 : LOCATE NL-2,BX : PRINT CHR$(208);CHR$(196); : GOTO 2350
2330     IF A=54 AND BX<WD-3 THEN LOCATE NL-2, BX : BX=BX+1 : PRINT CHR$(196);CHR$(208);
2340     IF A=27 THEN SCORE = 0:GOTO 1270
2350   NEXT I
2360 IF NB<>0 THEN GOTO 2390
2370 NB=WD-5:FOR I=3 TO WD-3:BUL(I)=1:NEXT
2380 LOCATE NL-1,3:PRINT STRING$(WD-5,BULLIT$);
2390 LOCATE 1,26*(WD/40):PRINT " TIME LEFT";(899-C.T)\10:NEXT  C.T
2400 FOR I=0 TO M.B
2410 B.Y(I)=2
2420 NEXT I
2430 CLS:LOCATE 10,16*(WD/40):PRINT "YOUR SCORE WAS ";SCORE
2440 IF SCORE<=HIGH THEN GOTO 2470
2450 HIGH=SCORE:LOCATE 11,10*(WD/40):PRINT "CONGRATULATIONS! THAT'S THE NEW HIGH SCORE!"
2460 LOCATE 15,15*(WD/40):INPUT "TYPE IN YOUR NAME-",NM$:FOR I=1 TO 20000:NEXT:CLS:SCORE=0:GOTO 1610
2470 LOCATE 12,17*(WD/40):PRINT "NICE TRY, BUT "
2480 BEGN=WD/2-LEN(NM$)/2:LOCATE 14,BEGN:PRINT NM$:SCORE=0
2490 LOCATE 16,13*(WD/40):PRINT "STILL HAS THE HIGH SCORE -";HIGH
2500 LOCATE 25,30:PRINT "HIT ENTER TO CONTINUE"
2510 A$=INKEY$:IF A$="" THEN GOTO 2510
2520 IF A$=CHR$(13) THEN CLS:GOTO 1610
2530 IF A$=CHR$(3) THEN SCREEN 0,0,0:COLOR 7,0:END
2540 GOTO 2510
2550 N.PIC$(0,0)=" *"     : N.PIC$(0,1)=" +"     : N.SCORE(0)=30 : N.SP(0)=0
2560 N.PIC$(1,0)=" **"    : N.PIC$(1,1)=" ++"    : N.SCORE(1)=20 : N.SP(1)=1
2570 N.PIC$(2,0)=" ***"   : N.PIC$(2,1)=" +++"   : N.SCORE(2)=15 : N.SP(2)=1
2580 N.PIC$(3,0)=" ****"  : N.PIC$(3,1)=" ++++"  : N.SCORE(3)=10 : N.SP(3)=3
2590 N.PIC$(4,0)=" *****" : N.PIC$(4,1)=" +++++" : N.SCORE(4)= 5 : N.SP(4)=7
2600 FOR I=0 TO 10 : N.LEN(I)=I+1 : NEXT
2610 SND$(0)="N65N56"
2620 SND$(1)="N37N47N33"
2630 SND$(2)="n37N28N35"
2640 SND$(3)="N45N35N55N35"
2650 SND$(4)="N55N35N45N65"
2660 RETURN
2670 LOCATE Y,(WD-LEN(M$)+2)\2 : PRINT M$; : RETURN
2680 IF ERR=51 THEN PRINT "INTERNAL ERROR":BEEP:END
2690 PRINT "ERROR ";ERR;" ON LINE ";ERL:END
)+2)\2 : PRINT M$; : RETURN
2680 IF ERR=51 THEN PRINT "INTERNAL ERROR":BEEP:END