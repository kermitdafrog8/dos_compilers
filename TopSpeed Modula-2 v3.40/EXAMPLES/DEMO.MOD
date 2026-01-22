(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)


(*%F _mthread*) This program is only valid in multithread model (*%E*)
MODULE Demo;
IMPORT SYSTEM,IO,Window,Lib,Process ;
FROM Lib IMPORT RANDOM ;


CONST
  xNum          = Window.ScreenWidth;
  yNum          = Window.ScreenDepth;
  CarNum        = 100 ;

TYPE
  xCoord        = [0..xNum-1] ;
  yCoord        = [0..yNum-1] ;

  Coord         = RECORD
                    x : xCoord ;
                    y : yCoord ;
                  END ;

  Direction     = (East,South,North,West) ;

  DirSet        = SET OF Direction ;

  Location      = RECORD
                    Entry,Exit : DirSet ;
                    Occupied   : BOOLEAN ;
                    Scenery    : SHORTCARD ;
                  END ;

  DA            = ARRAY Direction OF Direction ;

  CarRange      = [0..CarNum-1] ;

CONST

  Reverse       = DA(West,North,South,East) ;  (* reverse of Direction *)


VAR

  World         : ARRAY xCoord,yCoord OF Location;

  Car           : ARRAY CarRange OF
                    RECORD
                      Pos   : Coord;
                      Color : Window.Color;
                      Speed : CARDINAL ; (* MPH*10 *)
                      LastD : Direction ;
                    END;

  ToNorth       : ARRAY yCoord OF CARDINAL ;
  ToSouth       : ARRAY yCoord OF CARDINAL ;
  ToEast        : ARRAY xCoord OF CARDINAL ;
  ToWest        : ARRAY xCoord OF CARDINAL ;

  IsBW          : BOOLEAN ;

VAR (*W+*) (* Volatile *)

  AvSpeed       : CARDINAL;
  MaxCar        : CarRange ;

(*$W=*)


PROCEDURE Plot(x : xCoord; y : yCoord );

TYPE
  Chars = ARRAY SHORTCARD [0..15] OF SHORTCARD ;
CONST
  Road = Chars(176,32,32,201,32,200,186,204,32,205,187,203,188,202,185,206);
VAR
  loc   : Location;
  sc    : SHORTCARD ;
  color : Window.Color ;
BEGIN
  loc := World[x,y] ;
  sc := Road[SHORTCARD(loc.Entry+loc.Exit)];
  IF sc=176 THEN
    IF IsBW THEN color := Window.LightGray
            ELSE color := Window.Brown
    END ;
  ELSIF sc=32 THEN RETURN
  ELSE color := Window.LightGray ;
  END ;
  Window.TextColor(color);
  Window.DirectWrite(x+1,y+1,ADR(sc),1) ;
END Plot;

PROCEDURE PlotCar( v : CarRange ; dir : Direction );

TYPE
  Chars = ARRAY Direction OF SHORTCARD ;
CONST
  CarSym  = Chars(16,31,30,17) ;
BEGIN
  Window.TextColor(Car[v].Color);
  Window.DirectWrite(Car[v].Pos.x+1,Car[v].Pos.y+1,ADR(CarSym[dir]),1) ;
END PlotCar;



PROCEDURE NewCar ;
VAR
  x : xCoord ;
  y : yCoord ;
  v : CarRange ;
  d : Direction ;
BEGIN
  INC(MaxCar) ;
  v := MaxCar ;
  d := MAX(Direction);
  LOOP
    IF d=MAX(Direction) THEN
      REPEAT
        x := RANDOM(xNum); y := RANDOM(yNum) ;
      UNTIL NOT World[x,y].Occupied ;
      d := MIN(Direction) ;
    ELSE
      INC(d) ;
    END ;
    IF d IN World[x,y].Exit THEN EXIT END ;
  END ;
  World[x,y].Occupied := TRUE ;
  WITH Car[v] DO
    Pos.x := x ; Pos.y := y ;
    Speed := RANDOM(100) ;
    LastD := Direction(RANDOM(4));
  END ;
  IF IsBW THEN Car[v].Color := Window.White ;
          ELSE Car[v].Color := Window.Color( 9+RANDOM(7) ) ;
  END ;
  PlotCar(v,d) ;
END NewCar ;

PROCEDURE ParkCar ( v : CarRange ) ;
VAR
  x : xCoord ;
  y : yCoord ;
BEGIN
  x := Car[v].Pos.x ; y := Car[v].Pos.y ;
  IF MaxCar = 0 THEN HALT END ;
  World[x,y].Occupied := FALSE ;
  Plot(x,y);
  WHILE v<MaxCar DO
    Car[v] := Car[v+1] ; INC(v) ;
  END ;
  DEC(MaxCar) ;
END ParkCar ;



PROCEDURE MoveCar ( v:CarRange ) ;
VAR
  exit      : Direction;
  x,newx    : xCoord ;
  y,newy    : yCoord ;
  tried     : DirSet ;
CONST
  SpeedLimit = 450 ; (* 30 MPH ?! *)
BEGIN
  WITH Car[v] DO
    IF Speed < SpeedLimit THEN
      INC(Speed,RANDOM(80)) ;
      IF Speed>SpeedLimit THEN Speed := SpeedLimit END ;
      IF Speed<RANDOM(SpeedLimit) THEN RETURN END ;
    END ;
    x := Pos.x; y := Pos.y;
  END ;
  tried := DirSet{};
  LOOP
    exit := Direction(RANDOM(4));
    IF exit IN World[x,y].Exit THEN
      newx := x; newy := y;
      CASE exit OF
      | East  : newx := ToEast[x];
      | South : newy := ToSouth[y];
      | North : newy := ToNorth[y];
      | West  : newx := ToWest[x];
      END;
      IF World[newx,newy].Occupied  THEN
        Car[v].Speed := Car[v].Speed DIV 4 (* Brake *) ; RETURN ;
      ELSE
        World[x,y].Occupied := FALSE ;
        Plot(x,y);
        World[newx,newy].Occupied := TRUE ;
        WITH Car[v] DO
          Pos.x := newx; Pos.y := newy;
          IF LastD<>exit THEN
            (* Cornering *)
            Speed := Speed DIV 2 ;
            LastD := exit ;
          END ;
        END ;
        PlotCar(v,exit);
        RETURN ;
      END;
    END;
    INCL(tried,exit);
    IF tried = DirSet{East..West} THEN
        Car[v].Speed := 0 (* Stop *) ; RETURN ;
        RETURN ;
    END;
  END;
END MoveCar;





PROCEDURE InitWorld;

    PROCEDURE ok( x:xCoord ; y:yCoord ) : BOOLEAN;

    (* Returns whether we have planning permission to build road at x,y *)
    (* Tries to avoid making very small plots of land *)

    BEGIN
      RETURN ( World[ x,y ].Exit                   = DirSet{} ) OR
             ( World[ ToEast[x],y ].Exit           = DirSet{} ) OR
             ( World[ ToEast[x],ToSouth[y] ].Exit  = DirSet{} ) OR
             ( World[ x,ToSouth[y] ].Exit          = DirSet{} ) ;
    END ok;


VAR
  x,newx  : xCoord ;
  y,newy  : yCoord ;
  n       : CARDINAL;
  newdir,
  newentry: Direction;
  v       : CarRange ;
BEGIN
  FOR x := MIN(xCoord) TO MAX(xCoord) DO
    ToEast[x] := (x+1)MOD xNum ;
    ToWest[x] := (x+xNum-1)MOD xNum ;
  END ;
  FOR y := MIN(yCoord) TO MAX(yCoord) DO
    ToSouth[y] := (y+1)MOD yNum ;
    ToNorth[y] := (y+yNum-1)MOD yNum ;
  END ;
  Lib.Fill(ADR(World),SIZE(World),0) ;
  x := xNum DIV 2; y := yNum DIV 2;
  newx := x; newy := y;
  newdir := Direction(RANDOM(4));
  n := 1000 + RANDOM(1000);
  (* initialise map using randomish walk of n steps *)
  WHILE n <> 0 DO
    DEC(n);
    IF RANDOM(4)=0 THEN
      newdir := Direction(RANDOM(4));
    END;
    WHILE newdir IN World[x,y].Entry DO (* enforce one-way streets *)
      newdir := Direction(RANDOM(4)) ;
    END;
    newx := x; newy := y;
    CASE newdir OF
    | East  : newx := ToEast[x] ;
    | South : newy := ToSouth[y] ;
    | North : newy := ToNorth[y] ;
    | West  : newx := ToWest[x] ;
    END;
    newentry := Reverse[newdir] ;
    IF NOT ( newentry IN World[newx,newy].Entry ) THEN
      INCL( World[newx,newy].Entry, newentry  );
      IF (RANDOM(50)=0) OR
         ( ok( newx, newy )                  AND
           ok( ToWest[newx], newy )          AND
           ok( ToWest[newx], ToNorth[newy] ) AND
           ok( newx, ToNorth[newy] )
         )
      THEN
        INCL( World[x,y].Exit, newdir );
        Plot( x, y          );
        Plot( newx,newy     );
        Plot( ToEast[x],y   );
        Plot( ToWest[x],y   );
        Plot( x, ToNorth[y] );
        Plot( x, ToSouth[y] );
        x := newx; y := newy;
      ELSE
        EXCL( World[newx,newy].Entry, newentry );
      END;
    ELSE
      x := newx; y := newy;
    END;
  END;
  (* make some cars *)
  MaxCar := MAX(CARDINAL) ;
  FOR v := 1 TO CarNum-RANDOM(50) DO
    NewCar ;
  END;
END InitWorld;



PROCEDURE Statistics ;
CONST
  MsgWindowDef = Window.WinDef ( 5,5, 37,10,
                                 Window.Blue,Window.LightGray,
                                 FALSE,TRUE,FALSE,TRUE,
                                 Window.SingleFrame,
                                 Window.Red, Window.LightGray );
VAR
  MsgW      : Window.WinType;
  MsgX,MsgY : CARDINAL;
  WD        : Window.WinDef ;
  count     : CARDINAL ;
  change    : BOOLEAN ;
BEGIN
  WD   := MsgWindowDef ;
  IF IsBW THEN
    WD.Foreground := Window.Black ;
    WD.FrameBack := Window.LightGray ;
    WD.FrameFore := Window.Black ;
  END ;

  MsgW := Window.Open( WD );
  Window.SetTitle(MsgW,' TopSpeed Modula-2 Demo ',Window.CenterUpperTitle) ;
  MsgX := 5 ; MsgY := 5 ;
  Window.Use(MsgW);
  count := 200 ;
  LOOP
    Process.Delay(1) ;
    IO.WrLn;
    IO.WrStr('Cars: ');IO.WrCard(MaxCar+1,1) ;
    IO.WrStr('  Average Speed: ');IO.WrCard(AvSpeed DIV 10, 1 );
    IO.WrChar('.');IO.WrCard(AvSpeed MOD 10, 1 );
    IF count=0 THEN
      MsgX := RANDOM(50);
      MsgY := RANDOM(20);
      count := 200 ;
    ELSE
      DEC(count) ;
    END ;
    change := TRUE ;
    IF    WD.X1+2<MsgX THEN INC(WD.X1,3);INC(WD.X2,3);
    ELSIF WD.X1>MsgX+2 THEN DEC(WD.X1,3);DEC(WD.X2,3);
    ELSIF WD.Y1=MsgY THEN change := FALSE ;
    END ;
    IF    WD.Y1<MsgY THEN INC(WD.Y1);INC(WD.Y2);
    ELSIF WD.Y1>MsgY THEN DEC(WD.Y1);DEC(WD.Y2);
    END ;
    IF change THEN
       Window.Change(MsgW,WD.X1,WD.Y1,WD.X2,WD.Y2) ;
    END ;
  END ;
END Statistics;


PROCEDURE RunSimulation ;
VAR
  v        : CARDINAL;
  i        : CARDINAL;
  SumSpeed : CARDINAL ;
  up       : BOOLEAN ;
  c        : CHAR ;
BEGIN
  up := TRUE ;
  LOOP
    SumSpeed := 0;
    v := MaxCar+1 ;
    REPEAT
        DEC(v) ;
        MoveCar(v) ;
        SumSpeed := SumSpeed + Car[v].Speed ;
    UNTIL v=0;
    IF IO.KeyPressed() THEN
      c := IO.RdKey() ;
      EXIT
    END ;
    AvSpeed := SumSpeed DIV (MaxCar+1);
    (* Add or subtract card *)
    IF RANDOM(5)=0 THEN
      IF MaxCar=1 THEN up := TRUE
      ELSIF MaxCar=CarNum-1 THEN up := FALSE ;
      END ;
      IF up THEN NewCar ELSE ParkCar(RANDOM(MaxCar+1)) END ;
      Window.TextColor(Window.Black) ;
    END ;
  END ;
END RunSimulation ;

PROCEDURE Intro ;
VAR
  DescWin : Window.WinType ;
  r       : CARDINAL ;
BEGIN
  Window.CursorOff ;
  Window.SetProcessLocks(Process.Lock,Process.Unlock) ;
  DescWin := Window.Open(Window.WinDef(0,11,79,25,Window.LightGray,Window.Black,
                       FALSE,TRUE,FALSE,TRUE,
                       Window.DoubleFrame,Window.Black,Window.LightGray)) ;

  Window.SetTitle(DescWin,' TopSpeed Modula-2 : Traffic Simulation ',Window.CenterUpperTitle);
  IO.WrLn;
  IO.WrStr(' This program is a simple simulation of traffic flow in a closed road system.');
  IO.WrLn;
  IO.WrStr(' Up to 200 cars move randomly within a one-way network of roads.');IO.WrLn;
  IO.WrLn;
  IO.WrStr(' The average speed is monitored by a separate process and displayed in');IO.WrLn;
  IO.WrStr(' the Statistics window. 30.0 MPH indicates no congestion.');IO.WrLn;
  IO.WrLn;
  IO.WrStr(' Any resemblance to rush-hour traffic in New York is purely coincidental.');IO.WrLn;
  IO.WrLn; IO.WrLn; Window.TextColor(Window.White) ;
  IO.WrStr('    Press any key to start the simulation and then any key to terminate.');IO.WrLn;
  Window.Use(Window.FullScreen);
  Window.SetWrap(FALSE) ;
  Window.TextBackground(Window.Black) ;
  IF IsBW THEN
    Window.TextColor(Window.LightGray) ;
  ELSE
    Window.TextColor(Window.Green) ;
  END ;
  FOR r := 1 TO Window.ScreenDepth DO
    Window.GotoXY(1,r) ;
    IO.WrCharRep(CHAR(178),Window.ScreenWidth) ;
  END ;
  Window.TextBackground(Window.Black) ;
  Lib.RANDOMIZE;
  InitWorld;
  WHILE NOT IO.KeyPressed() DO END ;
  IF IO.RdKey()=' ' THEN END ;
  Window.Close(DescWin) ;
END Intro;

(*%F _OS2*)
PROCEDURE CheckBW ;
VAR
  R : SYSTEM.Registers ;
BEGIN
     R.AH := 15 ;
     Lib.Intr(R,10H) ;
     IsBW :=  (R.AL = 0)OR(R.AL = 2)OR(R.AL = 5)OR(R.AL = 6)OR(R.AL = 7) ;
END CheckBW ;
(*%E*)

BEGIN
(*%F _OS2*)
  CheckBW ;
(*%E*)
  Intro ;
  AvSpeed := 300 ;
  Process.StartScheduler ;
  Process.StartProcess(Statistics,2000H,1) ;
  RunSimulation ;
(*%F _OS2*)
  Lib.NoSound ;
(*%E*)
  Window.GotoXY(1,Window.ScreenDepth);
  Window.CursorOn ;
END Demo.
