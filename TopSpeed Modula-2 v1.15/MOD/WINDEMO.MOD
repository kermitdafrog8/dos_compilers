(*$I-,R-,O-*)
MODULE WinDemo ;

IMPORT SYSTEM,Window,IO,Lib,Str,Process ;

VAR
  IsBW : BOOLEAN ;

TYPE KBFlagSet = SET OF ( RShift, LShift, Ctrl, Alt, Scroll, Num, Cap, Ins ) ;
VAR  KeyFlags [40H:17H] : KBFlagSet ;

PROCEDURE CheckScrollLock () ;
BEGIN
  IF Scroll IN KeyFlags THEN
    Process.Lock ;
    WHILE Scroll IN KeyFlags DO
      Lib.Delay(10) ;
    END ;
    Process.Unlock ;
  END ;
END CheckScrollLock ;

PROCEDURE SetC ( cc,bwc : Window.Color ) ;
BEGIN
  IF IsBW THEN cc := bwc END ;
  Window.TextColor(cc) ;
END SetC ;



PROCEDURE Intro ;
(* Display startup and demonstration description *)

TYPE W   = RECORD x,y : CARDINAL END ;
     WW  = ARRAY[0..29] OF W ;
CONST
 ww = WW( W(0,0)  ,W(5,0) ,W(10,0),W(15,0),W(20,0),
          W(10,2) ,W(10,4),W(10,6),W(10,8),W(10,10),
          W(5,10) ,W(0,10),W(35,4),W(35,2),W(35,0),
          W(40,0), W(45,0),W(50,2),W(50,4),W(45,6),
          W(40,6), W(35,6),W(35,8),W(35,10),W(65,0),
          W(65,2), W(65,4),W(65,6),W(65,8),W(65,10)
        ) ;

PROCEDURE IntroText ;
BEGIN
  SetC(Window.White,Window.LightGray);
  IO.WrLn ;  IO.WrStr('       This is a demonstration of the ');
  SetC(Window.Yellow,Window.White);    IO.WrStr('Window') ;
  SetC(Window.White,Window.LightGray); IO.WrStr(' and ') ;
  SetC(Window.Yellow,Window.White) ;   IO.WrStr('Process') ;
  SetC(Window.White,Window.LightGray); IO.WrStr(' Modules') ;
  IO.WrLn ;
  IO.WrLn ;
  SetC(Window.LightGray,Window.LightGray);
  IO.WrStr('           9 time-sliced processes are created, which output to,');IO.WrLn;
  IO.WrStr('           move, re-size and re-colour  4 overlapping windows');IO.WrLn;
  IO.WrLn ;
  SetC(Window.White,Window.White);
  IO.WrStr('     Press any key to start, Esc to finish and ScrollLock to freeze ');
END IntroText ;

VAR
   WD      : Window.WinDef ;
   w       : Window.WinType ;
   title   : ARRAY[0..39] OF CHAR ;
   Win     : ARRAY[0..29] OF Window.WinType ;
   i,j,wn  : CARDINAL ;
   num     : ARRAY[0..6] OF CHAR ;
   b,up    : BOOLEAN ;
   DescWin : Window.WinType ;
   delay   : CARDINAL ;
   exit,
   change  : BOOLEAN ;
CONST
   targetX = 32 ;
   targetY = 5 ;
BEGIN
  FOR i := 0 TO 29 DO
    WITH WD DO
      IF i<30 THEN
        IF IsBW THEN
          IF ODD(i) THEN
            Background := Window.Black ;
            Foreground := Window.White ;
          ELSE
            Background := Window.LightGray ;
            Foreground := Window.Black ;
          END ;
        ELSE
          Background := Window.Color(i MOD 8) ;
          Foreground := Window.Color(15-i MOD 8) ;
        END ;
        X1 := ww[i].x ; Y1 := ww[i].y ;
        X2 := X1+9 ;  Y2 := Y1+3 ;
      END ;
      CursorOn   := FALSE ;
      WrapOn     := FALSE ;
      Hidden     := FALSE ;
      FrameOn    := TRUE ;
      FrameDef   := Window.SingleFrame ;
      IF NOT IsBW AND (Background=Window.Black) THEN
        FrameBack  := Window.Green ;
      ELSE
        FrameBack  := Background ;
      END ;
      (* Window.Color(ORD(Foreground)MOD 8) *) ;
      IF FrameBack=Window.LightGray THEN FrameFore  := Window.Black ;
                                    ELSE FrameFore  := Window.LightGray ;
      END ;
    END ;
    Win[i] := Window.Open(WD) ;
    Window.SetTitle(Win[i],'JPI',Window.CenterUpperTitle);
    Str.CardToStr(LONGCARD(i+1),num,10,b) ;
    (*
    IF (i=29)OR(ww[i].x+5<>ww[i+1].x) THEN IO.WrChar(' '); END ;
    *)
    IO.WrStr('TopSpeed');
    IO.WrLn ;
    IO.WrStr('Modula-2');
  END ;
  WD := Window.WinDef(0,15,75,24,Window.White,Window.Black,
                      FALSE,TRUE,FALSE,TRUE,
                      Window.DoubleFrame,Window.Blue,Window.LightGray) ;
  IF IsBW THEN WD.FrameFore := Window.Black END ;
  DescWin := Window.Open(WD) ;
  Window.SetTitle(DescWin,' JPI TopSpeed Modula-2 : Window Demonstration ',Window.CenterUpperTitle);
  IntroText ;
  delay := 1000 ;
  i := 0 ;
  WHILE NOT IO.KeyPressed() DO
    CheckScrollLock ;
    IF delay>100 THEN DEC(delay,20)
    ELSIF delay>1 THEN DEC(delay) ;
    END ;
    Lib.Delay(delay) ;
    Window.PutOnTop(Win[i]) ;
    i := (i+1)MOD 30 ;
  END ;
  REPEAT
    exit := TRUE ;
    FOR i := 0 TO 29 DO
      Window.Info(Win[i],WD) ;
      change := TRUE ;
      IF    WD.X1<targetX-3 THEN INC(WD.X1,3);INC(WD.X2,3);
      ELSIF WD.X1>targetX+3 THEN DEC(WD.X1,3);DEC(WD.X2,3);
      ELSIF WD.Y1=targetY THEN change := FALSE ;
      END ;
      IF    WD.Y1<targetY THEN INC(WD.Y1);INC(WD.Y2);
      ELSIF WD.Y1>targetY THEN DEC(WD.Y1);DEC(WD.Y2);
      END ;
      IF change THEN
         Window.Change(Win[i],WD.X1,WD.Y1,WD.X2,WD.Y2) ;
         exit := FALSE ;
      END ;
    END ;
  UNTIL exit ;
  FOR i := 0 TO 30 DO
    w := Window.Top() ;
    Lib.Delay(10) ;
    Window.Close(w) ;
   END ;
  IF IO.RdKey()=CHR(27) THEN HALT END ;
END Intro;

(* Actual demo starts here *)
(* ----------------------- *)




VAR
    W1,W2,W3,W4     : Window.WinType;
    DS              : Process.SIGNAL ;
    Initialize      : BOOLEAN ;
    pal             : Window.PaletteDef ;


(* Random Colouring *)

  PROCEDURE RandPalette ( VAR p : Window.PaletteDef ) ;
  VAR
    i : SHORTCARD ;
  TYPE  BW3 = ARRAY[0..2] OF Window.Color ;
  CONST bw3 = BW3(Window.Black,Window.LightGray,Window.White) ;
  BEGIN
      FOR i := 0 TO Window.PaletteMax DO
          IF IsBW THEN
            p[i].Fore := bw3[Lib.RANDOM(3)] ;
          ELSE
            p[i].Fore := VAL(Window.Color,Lib.RANDOM(16)) ;
          END ;
          REPEAT
            IF IsBW THEN
              p[i].Back := bw3[Lib.RANDOM(2)] ;
            ELSE
              p[i].Back := VAL(Window.Color,Lib.RANDOM(8)) ;
            END ;
          UNTIL p[i].Back<>p[i].Fore ;
      END ;
  END RandPalette ;

(* Random Movement *)

  PROCEDURE Rmove ( W : Window.WinType ) ;
  (* random move process *)
  VAR
    dx1,dy1 : CARDINAL ;
    ix,iy,nx,ny : CARDINAL ;
  BEGIN
    CheckScrollLock ;
    LOOP

      Process.Delay(5+Lib.RANDOM(15)) ;
      REPEAT
        dx1 := W^.WDef.X1+(Lib.RANDOM(16)-8)*2 ;
        dy1 := W^.WDef.Y1+Lib.RANDOM(16)-8 ;
      UNTIL (dx1<80)AND(dy1<24)
            AND(dx1+W^.OWidth<=80)AND(dy1+W^.ODepth<=24) ;
      IF dx1>W^.WDef.X1 THEN ix := 2 ELSE ix := 0 END ;
      IF dy1>W^.WDef.Y1 THEN iy := 2 ELSE iy := 0 END ;
      WHILE (dx1<>W^.WDef.X1) AND (dy1<>W^.WDef.Y1) DO
        IF (dx1<>W^.WDef.X1) THEN nx := W^.WDef.X1+ix-1 END ;
        IF (dy1<>W^.WDef.Y1) THEN ny := W^.WDef.Y1+iy-1 END ;
        Window.Change(W,nx,ny,nx+W^.OWidth-1,ny+W^.ODepth-1) ;
      END ;
    END ;
  END Rmove ;

(* Random Change Size *)

  PROCEDURE RChangeSize ( W : Window.WinType ) ;
  (* this randomly changes the size of a window *)
  VAR
    nx,ny : CARDINAL ;
  BEGIN
    CheckScrollLock ;
      REPEAT
        nx := W^.WDef.X2+(Lib.RANDOM(16)-8)*2 ;
        ny := W^.WDef.Y2+Lib.RANDOM(16)-8 ;
      UNTIL (nx-W^.WDef.X1<70)AND(ny-W^.WDef.Y1<18)
         AND(nx-W^.WDef.X1>10)AND(ny-W^.WDef.Y1>4) ;
      Window.Change(W,W^.WDef.X1,W^.WDef.Y1,nx,ny) ;
  END RChangeSize ;


(* Processes *)


(* P1 prints out numbers in Hex, Dec and Binary *)

  PROCEDURE P1;
  VAR S : ARRAY[0..30] OF CHAR;
      i : CARDINAL;
      b : BOOLEAN ;
  BEGIN
    Window.Use(W1) ;
    LOOP
      FOR i := 0 TO 1000 DO
        Str.CardToStr(VAL(LONGCARD,i),S,2,b); IO.WrStr(S);
        IO.WrCharRep(' ',16-Str.Length(S));
        IO.WrCard(i,5) ;
        IO.WrStr('   ') ;
        Str.CardToStr(VAL(LONGCARD,i),S,16,b); IO.WrStr(S);
        IO.WrCharRep(' ',5-Str.Length(S));
        IO.WrLn;
      END;
    END ;
  END P1;

(* P2 displays out a sideways barchart *)



  PROCEDURE P2;
  VAR i,j : CARDINAL;
      V : ARRAY[1..9] OF CARDINAL ;
      WD : Window.WinDef ;

    PROCEDURE DrawBar ( x,y : CARDINAL ; val : CARDINAL ; on : BOOLEAN ) ;
    BEGIN
      IF ODD(y) THEN
        IF IsBW THEN Window.TextColor(Window.White) ;
                ELSE Window.TextColor(Window.Red) ;
        END ;
      ELSE
        Window.TextColor(Window.LightGray) ;
      END ;
      IF val>0 THEN
        DEC(val) ;
        Window.GotoXY(x+val DIV 2,y) ;
        IF on THEN
          IF ODD(val) THEN IO.WrChar('Û') ELSE IO.WrChar('Ý') END ;
        ELSE
          IF ODD(val) THEN IO.WrChar('Ý') ELSE IO.WrChar(' ') END ;
        END ;
      END ;
    END DrawBar ;

  BEGIN
    Window.Use(W2) ;
    i := 0 ;
    FOR i := 1 TO 9 DO
      V[i] := Lib.RANDOM(50) ;
      FOR j := 0 TO V[i] DO
        DrawBar(1,i,j,TRUE) ;
      END ;
    END ;
    LOOP
      FOR i := 1 TO 9 DO
        Window.Info(W2,WD) ;
        IF i<WD.X2-WD.X1-2 THEN
          IF Lib.RANDOM(2)=0 THEN
            IF V[i]<50 THEN INC(V[i]) ; DrawBar(1,i,V[i],TRUE) END ;
          ELSE
            IF V[i]>0 THEN DrawBar(1,i,V[i],FALSE) ; DEC(V[i]) ; END ;
          END ;
        END ;
      END ;
      CheckScrollLock ;
    END ;
  END P2;

(* P3 displays a character grid with randomly changing pallette colours *)

  PROCEDURE P3;
  VAR
      X,Y,D : CARDINAL;
      CH : CHAR;
  BEGIN
    CH := '*' ;
    D := 0 ;
    Window.Use(W3) ;
    LOOP
      FOR X := 1 TO 8 DO
        FOR Y := 1 TO 8 DO
          Window.SetPaletteColor(VAL(SHORTCARD,(Y*7+X+D))MOD 8) ;
          Window.GotoXY(X,Y);
          IO.WrChar(CH);
          Window.GotoXY(1,10);
          Window.SetPaletteColor(0) ;
          IO.WrCard(X,2);
          IO.WrChar(',');
          IO.WrCard(Y,2);
        END;
      END;
      RandPalette ( pal ) ;
      Window.SetPalette(W3,pal) ;
      INC(D) ;
      CheckScrollLock ;
    END ;
  END P3;

(* P4 displays some text *)

  PROCEDURE P4;
  VAR i : CARDINAL ;
  BEGIN
    Window.Use(W4) ;
    REPEAT
      FOR i := 1 TO 100 DO
        IO.WrStr('This is a test of 9 time-sliced processes, and also of window writing, moving, rearranging and resizing.');
        W4^.WDef.Foreground := Window.White ;
        IF IsBW THEN
          W4^.WDef.Background := Window.Black ;
        END ;
        IO.WrStr(' Press any key to terminate, ScrollLock to freeze.  ');
        W4^.WDef.Foreground := Window.Black ;
        IF IsBW THEN
          W4^.WDef.Background := Window.LightGray
        END ;
      END;
      CheckScrollLock ;
    UNTIL IO.KeyPressed() ;
    Process.StopScheduler ;
    Window.Use(Window.FullScreen) ;
    Window.SnapShot ;
    Window.PutOnTop(Window.FullScreen) ;
    Window.GotoXY(1,Window.ScreenDepth-1);
    Window.CursorOn ;
    IF IO.RdKey()=' ' THEN END ;
    HALT ;
  END P4;

(* P5 Re-sizes and Re-arranges text *)

  PROCEDURE P5;
  BEGIN
    LOOP
      Process.Delay(10+Lib.RANDOM(20)) ;
      CASE Lib.RANDOM(4) OF
        0 : Window.PutOnTop(W1) |
        1 : Window.PutOnTop(W2) |
        2 : Window.PutOnTop(W3) |
        3 : Window.PutOnTop(W4)
      END ;
      Process.Delay(10+Lib.RANDOM(20)) ;
      CASE Lib.RANDOM(4) OF
        0 : RChangeSize(W1) |
        1 : |
        2 : |
        3 : RChangeSize(W4)
      END ;
    END  ;
  END P5;

(* P6 Moves window 1 *)

  PROCEDURE P6 ;
  BEGIN
    Rmove(W1) ;
  END P6 ;

(* P7 Moves window 2 *)

  PROCEDURE P7 ;
  BEGIN
    Rmove(W2) ;
  END P7;

(* P8 Moves window 2 *)

  PROCEDURE P8 ;
  BEGIN
    Rmove(W3) ;
  END P8;

(* P9 Moves window 2 *)

  PROCEDURE P9 ;
  BEGIN
    Rmove(W4) ;
  END P9 ;


PROCEDURE Demo ;
VAR
   WD : Window.WinDef ;
BEGIN
   Lib.RANDOMIZE ;
   Initialize := TRUE ;
   Window.SetProcessLocks(Process.Lock,Process.Unlock) ;
   Window.CursorOff ;
   Window.Clear ;
    WITH WD DO
      X1 := 10 ; Y1 := 2 ;
      X2 := 60 ; Y2 := 8 ;
      Foreground := Window.White ;
      IF IsBW THEN
        Background := Window.Black ;
      ELSE
        Background := Window.Red ;
      END ;
      CursorOn   := FALSE ;
      WrapOn     := TRUE ;
      Hidden     := FALSE ;
      FrameOn    := TRUE ;
      FrameDef   := Window.SingleFrame ;
      FrameFore  := Window.White ;
      FrameBack  := Background ;
    END ;
    W1 := Window.Open(WD) ;
    Window.SetTitle(W1,' Process 1 ',Window.CenterUpperTitle);
    WITH WD DO
      X1 := 40 ; Y1 := 2 ;
      X2 := 70 ; Y2 := 12 ;
      Foreground := Window.White ;
      Background := Window.Blue ;
      CursorOn   := FALSE ;
      WrapOn     := TRUE ;
      Hidden     := FALSE ;
      FrameOn    := TRUE ;
      FrameDef   := Window.DoubleFrame ;
      FrameFore  := Window.Black ;
      FrameBack  := Window.Cyan ;
      IF IsBW THEN
         Background := Window.Black ;
         FrameBack := Window.LightGray
      END ;
    END ;
    W2 := Window.Open(WD) ;
    Window.SetTitle(W2,' Process 2 ',Window.CenterUpperTitle);
    RandPalette(pal) ;
    WITH WD DO
      X1 := 40 ; Y1 := 6 ;
      X2 := 50 ; Y2 := 17 ;
      pal[0].Fore:= Window.Yellow ;
      pal[0].Back:= Window.Black ;
      CursorOn   := FALSE ;
      WrapOn     := TRUE ;
      Hidden     := FALSE ;
      FrameOn    := TRUE ;
      FrameDef   := Window.SingleFrame ;
      pal[1].Fore:= Window.White ;
      pal[1].Back:= Window.Green ;
      IF IsBW THEN
         pal[0].Fore:= Window.LightGray ;
         pal[1].Back:= Window.Black ;
      END ;
    END ;
    W3 := Window.PaletteOpen(WD,pal) ;
    Window.SetTitle(W3,'Process 3',Window.CenterUpperTitle);
    WITH WD DO
      X1 := 10 ; Y1 := 10 ;
      X2 := 70 ; Y2 := 20 ;
      Foreground := Window.Black ;
      Background := Window.LightGray ;
      CursorOn   := FALSE ;
      WrapOn     := TRUE ;
      Hidden     := FALSE ;
      FrameOn    := TRUE ;
      FrameDef   := Window.DoubleFrame ;
      FrameFore  := Window.White ;
      FrameBack  := Window.Green ;
      IF IsBW THEN
        FrameBack  := Window.Black ;
      END ;
    END ;
    W4 := Window.Open(WD) ;
    Window.SetTitle(W4,' Process 4 ',Window.CenterUpperTitle);

    Process.StartScheduler ;

    Process.StartProcess(P1,2000,1) ;
    Process.StartProcess(P2,2000,1) ;
    Process.StartProcess(P3,2000,1) ;
    Process.StartProcess(P4,2000,1) ;
    Process.StartProcess(P5,2000,1) ;
    Process.StartProcess(P6,2000,1) ;
    Process.StartProcess(P7,2000,1) ;
    Process.StartProcess(P8,2000,1) ;
    Process.StartProcess(P9,2000,1) ;
    Process.Init(DS) ;
    Process.WAIT(DS) ;
    Window.CursorOn ;
END Demo;

PROCEDURE CheckBW ;
VAR
  R : SYSTEM.Registers ;
BEGIN
     R.AH := 15 ;
     Lib.Intr(R,10H) ;
     IsBW := (R.AL = 0)OR(R.AL = 2)OR(R.AL = 5)OR(R.AL = 6)OR(R.AL = 7) ;
END CheckBW ;


BEGIN
  CheckBW ;
  Intro;
  Demo;
END WinDemo.
