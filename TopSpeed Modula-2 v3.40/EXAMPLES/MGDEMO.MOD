MODULE MGdemo;

IMPORT Graph, IO, Lib, SYSTEM, Storage;

TYPE
    PieInfo = RECORD
        state: CARDINAL;
        x1, y1, x2, y2: CARDINAL;
        startx, starty: CARDINAL;
        CurrentX: CARDINAL;
        CurrentY: CARDINAL;
        fill: BOOLEAN;
        color: CARDINAL;
    END;
    PieHandle = POINTER TO PieInfo;

TYPE
    ColorArray = ARRAY [0..15] OF LONGCARD;
    SmallColorArray = ARRAY [0..3] OF CARDINAL;
CONST
    Colors = ColorArray( Graph._BLACK, Graph._BLUE, Graph._GREEN, Graph._CYAN, Graph._RED, Graph._MAGENTA, Graph._BROWN,
                   Graph._WHITE, Graph._GRAY, Graph._LIGHTBLUE, Graph._LIGHTGREEN, Graph._LIGHTCYAN,
                   Graph._LIGHTRED, Graph._LIGHTMAGENTA, Graph._LIGHTYELLOW, Graph._BRIGHTWHITE);

VAR
    Mono: BOOLEAN;
    XValues: ARRAY [0..3] OF CARDINAL;
    YValues: ARRAY [0..3] OF CARDINAL;
    cv: Graph.VideoConfig;
    Patterns: ARRAY [0..4] OF Graph.FillMaskType;

PROCEDURE Max(V1, V2: CARDINAL): CARDINAL;

BEGIN
    IF V1 > V2 THEN
        RETURN V1;
    ELSE
        RETURN V2;
    END;
END Max;


  PROCEDURE TestKey;
    BEGIN
      IF CAP(IO.RdKey()) = 'X' THEN
        SYSTEM.Eval(Graph.SetVideoMode(Graph._DEFAULTMODE));
        HALT;
      END; (*IF*)
    END TestKey;

PROCEDURE InitPalette();

VAR
    i: CARDINAL;
    red, green, blue: CARDINAL;
    color: LONGCARD;
    colors: ARRAY [0..255] OF LONGCARD;
BEGIN
    i:=0;
    SYSTEM.Eval(Graph.SetVideoMode(Graph._MRES256COLOR));
    WHILE i < 256 DO
        red  :=CARDINAL(BITSET(i)* BITSET(0E0H))>>2;
        green:=CARDINAL(BITSET(i) * BITSET(01CH))<<1;
        blue :=CARDINAL(BITSET(i) * BITSET(3))<<4;
        color:= (LONGCARD(blue)<<16) + (LONGCARD(green)<<8) + LONGCARD(red);
        colors[i]:=color;
        INC(i);
    END;
    SYSTEM.Eval(Graph.RemapAllPalette(colors));
END InitPalette;

PROCEDURE AdjustRGB(VAR red, green, blue: CARDINAL);

VAR
    nr, nb, ng: CARDINAL;
BEGIN
    IF (red >= blue) AND (red >= green) THEN
        nr:=255;
        ng:=(green*255) DIV red;
        nb:=(blue*255) DIV red;
    ELSIF (green >= red) AND (green >= blue) THEN
        ng:=255;
        nr:=(red*255) DIV green;
        nb:=(blue*255) DIV green;
    ELSE
        nb:=255;
        ng:=(green*255) DIV blue;
        nr:=(red*255) DIV blue;
    END;
    red:=nr;
    blue:=nb;
    green:=ng;
END AdjustRGB;

PROCEDURE PlotRGB(x, y, red, green, blue: CARDINAL);

VAR
    r, g, b, color: CARDINAL;
BEGIN
    r:=CARDINAL(BITSET(red) * BITSET(0E0H));
    g:=CARDINAL(BITSET(green) * BITSET(0E0H))>>3;
    b:=CARDINAL(BITSET(blue) * BITSET(0C0H))>>6;
    color:= CARDINAL(BITSET(r) + BITSET(g) + BITSET(b));
    Graph.Plot(x+20, y, color);
END PlotRGB;

PROCEDURE VGATriangle();

VAR
    x, y: CARDINAL;
    red, green, blue: CARDINAL;
BEGIN
    InitPalette();
    x:=0;
    WHILE x < 256 DO
        y:=0;
        WHILE y < 200 DO
            red:=x;
            green:=(y*255) DIV 200;
            IF (red+green) < 255 THEN
                blue:=255-(red+green);
                AdjustRGB(red, green, blue);
                PlotRGB(x, y, red, green, blue);
            END;
            INC(y);
        END;
        INC(x);
    END;
    SYSTEM.Eval(Graph.SetTextColor(10));
    SYSTEM.Eval(Graph.SetTextPosition(25, 5));
    Graph.OutText('Hit Any Key To Continue,X To Exit.');
    TestKey;
    SYSTEM.Eval(Graph.SetVideoMode(Graph._ERESCOLOR));
END VGATriangle;


PROCEDURE DrawEllipses();

VAR
    n: INTEGER;
    f: BOOLEAN;
    x1, x2, y1, y2: CARDINAL;
    c: CARDINAL;
BEGIN
    n:=0;
    c:=1;
    f:=Graph._GFILLINTERIOR;
    Patterns[0] := Graph.FillMaskType(88H,  44H,  22H,  11H,  88H,  44H,  22H,  11H);
    Patterns[1] := Graph.FillMaskType(0AAH, 0AAH, 0AAH, 0AAH, 0AAH, 0AAH, 0AAH, 0AAH);
    Patterns[2] := Graph.FillMaskType(0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH);
    Patterns[3] := Graph.FillMaskType(0FFH, 40H,  0FFH, 40H,  0FFH, 40H,  0FFH, 40H);
    Patterns[4] := Graph.FillMaskType(80H,  40H,  20H,  10H,  08H,  04H,  02H,  01H);
    LOOP
        IF n = 100 THEN
            EXIT;
        END;
        INC(n);
        IF IO.KeyPressed() THEN
            EXIT;
        END;
        Graph.SetFillMask(Patterns[Lib.RANDOM(5)]);
        x1:=Lib.RANDOM(cv.numxpixels-1);
        y1:=Lib.RANDOM(cv.numypixels-1);
        x2:=Lib.RANDOM(cv.numxpixels-x1);
        y2:=Lib.RANDOM(cv.numypixels-y1);
        IF f = Graph._GFILLINTERIOR THEN
            f:=Graph._GBORDER;
        ELSE
            f:=Graph._GFILLINTERIOR;
        END;
        Graph.Ellipse(x1, y1, x2, y2, c, f);
        INC(c);
        IF c = cv.numcolors THEN
            c:=1;
        END;
    END;
    IF NOT Mono THEN
        SYSTEM.Eval(Graph.SetTextPosition(25, 1));
        Graph.OutText('Press Any Key To Continue, X To Exit');
    END;
    TestKey;
END DrawEllipses;

PROCEDURE Ellipses(scale: CARDINAL);

BEGIN
    Graph.SetClipRgn(0, 0, cv.numxpixels-1, cv.numypixels-1);
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    DrawEllipses();
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    Graph.Rectangle(49 DIV scale, 24 DIV scale, 501 DIV scale, 291 DIV scale, 3, Graph._GBORDER);
    Graph.SetClipRgn(50 DIV scale, 25 DIV scale, 500 DIV scale, 290 DIV scale);
    DrawEllipses();
    Graph.SetClipRgn(0, 0, cv.numxpixels-1, cv.numypixels-1);
END Ellipses;

PROCEDURE InitPie(x1, y1, x2, y2: CARDINAL; InitState, scale: CARDINAL; fill: BOOLEAN): PieHandle;

VAR
    p: PieHandle;
BEGIN
    Storage.ALLOCATE(p, SIZE(PieInfo));
    p^.x1:=x1 DIV scale;
    p^.y1:=y1 DIV scale;
    p^.x2:=x2 DIV scale;
    p^.y2:=y2 DIV scale;
    p^.CurrentX:=XValues[InitState];
    p^.CurrentY:=YValues[InitState];
    p^.startx:=XValues[InitState];
    p^.starty:=YValues[InitState];
    p^.state:=InitState;
    p^.fill:=fill;
    IF Mono THEN
        p^.color:=1;
    ELSE
        p^.color:=Lib.RANDOM(cv.numcolors-2)+1;
    END;
    Graph.Pie(p^.x1, p^.y1, p^.x2, p^.y2, p^.CurrentX, p^.CurrentY, p^.CurrentX, p^.CurrentY, p^.color, fill);
    RETURN p;
END InitPie;

PROCEDURE DisposePie(p: PieHandle);

BEGIN
    Storage.DEALLOCATE(p, SIZE(PieInfo));
END DisposePie;

PROCEDURE Circulate(p: PieHandle);

BEGIN
    Graph.SetFillMask(Patterns[2]);
    Graph.Rectangle(p^.x1-p^.x2, p^.y1-p^.y2, p^.x1+p^.x2, p^.y1+p^.y2, 0, Graph._GFILLINTERIOR);
    IF p^.state = 0 THEN
        IF p^.CurrentY > 0 THEN
            DEC(p^.CurrentY, 4);
        ELSE
           INC(p^.state);
        END;
    END;
    IF p^.state = 1 THEN
        IF p^.CurrentX > 0 THEN
            DEC(p^.CurrentX, 8);
        ELSE
            INC(p^.state);
        END;
    END;
    IF p^.state = 2 THEN
        IF p^.CurrentY < cv.numypixels THEN
            INC(p^.CurrentY, 4);
        ELSE
            INC(p^.state);
        END;
    END;
    IF p^.state = 3 THEN
        IF p^.CurrentX < cv.numxpixels THEN
            INC(p^.CurrentX, 8);
        ELSE
            p^.state:=0;
        END;
    END;
    IF p^.fill = Graph._GFILLINTERIOR THEN
        Graph.SetFillMask(Patterns[Lib.RANDOM(5)]);
    END;
    Graph.Pie(p^.x1, p^.y1, p^.x2, p^.y2, p^.CurrentX, p^.CurrentY,
                   p^.startx, p^.starty, p^.color, p^.fill);
END Circulate;

PROCEDURE Pies(scale: INTEGER);

VAR
    p: ARRAY [0..4] OF PieHandle;
    n: INTEGER;
BEGIN
    n:=0;
    XValues[0]:=cv.numxpixels-1;
    XValues[1]:=cv.numxpixels-1;
    XValues[2]:=0;
    XValues[3]:=0;
    YValues[0]:=cv.numypixels-1;
    YValues[1]:=0;
    YValues[2]:=0;
    YValues[3]:=cv.numypixels-1;
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    Graph.SetClipRgn(0, 0, cv.numxpixels-1, cv.numypixels-1);
    p[0]:=InitPie(80, 60, 50, 30, 0, scale, Graph._GBORDER);
    p[1]:=InitPie(510, 70, 60, 60, 1, scale, Graph._GFILLINTERIOR);
    p[2]:=InitPie(70, 255, 30, 55, 2, scale, Graph._GFILLINTERIOR);
    p[3]:=InitPie(450, 200, 55, 35, 3, scale, Graph._GBORDER);
    p[4]:=InitPie(320, 160, 45, 45, 0, scale, Graph._GFILLINTERIOR);

    IF NOT Mono THEN
        SYSTEM.Eval(Graph.SetTextPosition(25, 1));
        Graph.OutText('Press Any Key To Continue, X To Exit');
    END;
    WHILE NOT IO.KeyPressed() DO
        IF n = 5 THEN
            n:=0;
        END;
        Circulate(p[n]);
        INC(n);
    END;
    TestKey;
    n:=0;
    WHILE n < 5 DO
        DisposePie(p[n]);
        INC(n);
    END;
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    Graph.SetFillMask(Patterns[2]);
END Pies;



VAR
    spotlist: ARRAY [0..5] OF ARRAY [0..5] OF Graph.GraphCoords;

PROCEDURE DrawCircles(patnum, start, depth, width: INTEGER);

VAR
    n: INTEGER;
    x, y, xpos, ypos: CARDINAL;
BEGIN
    n:=0;
    LOOP
        x:=spotlist[patnum-1][n].xcoord;
        IF x = 0 THEN EXIT END;
        xpos:=CARDINAL(width>>2)*x;
        y:=spotlist[patnum-1][n].ycoord;
        ypos:=CARDINAL(depth>>3)*y+CARDINAL(start);
        Graph.Ellipse(xpos, ypos, 4, 4, cv.numcolors-1, Graph._GFILLINTERIOR);
        INC(n);
        IF n = 6 THEN
            EXIT;
        END;
    END;
END DrawCircles;


PROCEDURE MoveSideways(image: ADDRESS; pos: ARRAY OF CARDINAL;
                       limit: CARDINAL; incr: INTEGER): CARDINAL;

VAR
    x, y: CARDINAL;
    ret: INTEGER;
BEGIN
    x:=0;
    y:=0;
    ret:=0;
    LOOP
        IF x = pos[limit] THEN EXIT END;
        Graph.PutImage(x, y, image, Graph._GXOR);
        INC(x, incr);
        Graph.PutImage(x, y, image, Graph._GPSET);
        IF IO.KeyPressed() THEN
            TestKey;
            ret:=1;
            EXIT;
        END;
    END;
    RETURN ret;
END MoveSideways;

PROCEDURE MoveDown(image: ADDRESS; pos: ARRAY OF CARDINAL;
                   limit: CARDINAL; xpos: CARDINAL; incr: INTEGER): INTEGER;

VAR
    y: CARDINAL;
    ret: INTEGER;
BEGIN
    y:=0;
    ret:=0;
    LOOP
        IF y = pos[limit] THEN EXIT END;
        Graph.PutImage(xpos, y, image, Graph._GXOR);
        INC(y, incr);
        Graph.PutImage(xpos, y, image, Graph._GPSET);
        IF IO.KeyPressed() THEN
            TestKey;
            ret:=1;
            EXIT;
        END;
    END;
    RETURN ret;
END MoveDown;

PROCEDURE DrawSpots(number, start, depth, width: INTEGER);

VAR
    pattern: ARRAY [0..2] OF CARDINAL;
    n: CARDINAL;
BEGIN
    IF number = 0 THEN RETURN END;
    CASE number OF
        | 1:
            pattern[0]:=1;
            pattern[1]:=0;
        | 2:
            pattern[0]:=2;
            pattern[1]:=0;
        | 3:
            pattern[0]:=2;
            pattern[1]:=1;
            pattern[2]:=0;
        | 4:
            pattern[0]:=4;
            pattern[1]:=0;
        | 5:
            pattern[0]:=4;
            pattern[1]:=1;
            pattern[2]:=0;
        | 6:
            pattern[0]:=6;
            pattern[1]:=0;
    END;
    n:=0;
    WHILE pattern[n] # 0 DO
        DrawCircles(pattern[n], start, depth, width);
        INC(n);
    END;
END DrawSpots;

PROCEDURE DrawDomino(depth, width: INTEGER);

VAR
    spots: INTEGER;
BEGIN
    Graph.Rectangle(0, 0, width, depth, cv.numcolors-1, Graph._GBORDER);
    Graph.Line(0, depth DIV 2, width, depth DIV 2, cv.numcolors-1);
    spots:=Lib.RANDOM(7);
    DrawSpots(spots, 0, depth, width);
    spots:=Lib.RANDOM(7);
    DrawSpots(spots, depth DIV 2, depth, width);
END DrawDomino;


PROCEDURE MakeDomino(depth, width: INTEGER): ADDRESS;

VAR
    Buffer: ADDRESS;
    size: LONGCARD;
BEGIN
    size:=Graph.ImageSize(0, 0, width, depth);
    Storage.ALLOCATE(Buffer, CARDINAL(size));
    DrawDomino(depth, width);
    Graph.GetImage(0, 0, width, depth, Buffer);
    RETURN Buffer;
END MakeDomino;

PROCEDURE Animation(adapter: CARDINAL);

VAR
    ColPosition: ARRAY [0..10] OF CARDINAL;
    RowPosition: ARRAY [0..2] OF CARDINAL;
    count, width, depth, incr: INTEGER;
    MaxRow, MaxCol, clear: INTEGER;
    CurrentRow, CurrentCol: INTEGER;
    image: ADDRESS;
BEGIN
    spotlist[0][0]:= Graph.GraphCoords(2, 2);
    spotlist[1][0]:= Graph.GraphCoords(1, 1);
    spotlist[1][1]:= Graph.GraphCoords(3, 3);
    spotlist[2][0]:= Graph.GraphCoords(0, 0);
    spotlist[3][0]:= Graph.GraphCoords(1, 1);
    spotlist[3][1]:= Graph.GraphCoords(3, 1);
    spotlist[3][2]:= Graph.GraphCoords(1, 3);
    spotlist[3][3]:= Graph.GraphCoords(3, 3);
    spotlist[4][0]:= Graph.GraphCoords(0, 0);
    spotlist[5][0]:= Graph.GraphCoords(1, 1);
    spotlist[5][1]:= Graph.GraphCoords(3, 1);
    spotlist[5][2]:= Graph.GraphCoords(1, 2);
    spotlist[5][3]:= Graph.GraphCoords(3, 2);
    spotlist[5][4]:= Graph.GraphCoords(1, 3);
    spotlist[5][5]:= Graph.GraphCoords(3, 3);
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    Graph.SetFillMask(Patterns[2]);
    IF (adapter = Graph._EGA) OR (adapter = Graph._HGC) THEN
        width:=50;
        depth:=100;
        MaxRow:=2;
        MaxCol:=9;
        clear:=20;
        incr:=10;
    ELSE
        width:=50;
        depth:=90;
        MaxRow:=1;
        MaxCol:=4;
        clear:=10;
        incr:=5;
    END;
    count:=0;
    WHILE count <= MaxCol DO
        ColPosition[count]:=count*(width+10);
        INC(count);
    END;
    count:=0;
    WHILE count <= MaxRow DO
        RowPosition[count]:=count*(depth+clear);
        INC(count);
    END;
    CurrentCol:=MaxCol;
    CurrentRow:=MaxRow;

    LOOP
        IF CurrentCol < 0 THEN EXIT END;
        image:=MakeDomino(depth, width);
        IF CurrentCol > 0 THEN
            IF MoveSideways(image, ColPosition, CurrentCol, incr) # 0 THEN
                EXIT;
            END;
        END;
        IF CurrentRow > 0 THEN
            IF MoveDown(image, RowPosition, CurrentRow, ColPosition[CurrentCol], incr) # 0 THEN
                EXIT;
            END;
            DEC(CurrentRow);
        ELSE
            DEC(CurrentCol);
            CurrentRow:=MaxRow;
        END;
        Storage.DEALLOCATE(image, CARDINAL(Graph.ImageSize(0, 0, width, depth)));
        IF IO.KeyPressed() THEN
            EXIT;
        END;
    END;
    IF NOT Mono THEN
        SYSTEM.Eval(Graph.SetTextPosition(25, 1));
        Graph.OutText('Press Any Key To Continue, X To Exit.');
    END;
    TestKey;
END Animation;




PROCEDURE Bars(scale: INTEGER);

VAR
    x1, y1,x2, y2, x3, y3, x4, y4: CARDINAL;
    NewMask: Graph.FillMaskType;
BEGIN
    Graph.SetClipRgn(0, 0, cv.numxpixels-1, cv.numypixels-1);
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    x1:=460 DIV scale;
    y1:=150 DIV scale;
    x2:=140 DIV scale;
    y2:=130 DIV scale;
    x4:=300 DIV scale;
    y4:=260 DIV scale;
    x3:=620 DIV scale;
    y3:=260 DIV scale;
    Graph.Pie(x1, y1, x2, y2, x3, y3, x4, y4, Max(4 MOD cv.numcolors, 1), Graph._GFILLINTERIOR);

    x1:=460 DIV scale;
    y1:=170 DIV scale;
    x2:=140 DIV scale;
    y2:=130 DIV scale;
    x3:=300 DIV scale;
    y3:=280 DIV scale;
    x4:=620 DIV scale;
    y4:=280 DIV scale;
    Graph.Pie(x1, y1, x2, y2, x3, y3, x4, y4, Max(3 MOD cv.numcolors, 1), Graph._GBORDER);


    NewMask[0]:=88H;
    NewMask[1]:=44H;
    NewMask[2]:=22H;
    NewMask[3]:=11H;
    NewMask[4]:=88H;
    NewMask[5]:=44H;
    NewMask[6]:=22H;
    NewMask[7]:=11H;
    Graph.SetFillMask(NewMask);
    x1:=19 DIV scale;
    y1:=10 DIV scale;
    x2:=x1;
    y2:=321 DIV scale;
    x3:=600 DIV scale;
    y3:=y2;

    Graph.Line(x1, y1, x2, y2, cv.numcolors-1);
    Graph.Line(x2, y2, x3, y3, cv.numcolors-1);
    IF NOT Mono THEN
        SYSTEM.Eval(Graph.SetTextPosition(25, 13 DIV scale));
        Graph.OutText('Bar Graphs and Pie Charts');
    END;
    x1:=20 DIV scale;
    y1:=20 DIV scale;
    x2:=59 DIV scale;
    y2:=320 DIV scale;
    Graph.Cube(Graph._GTOP, x1, y1, x2, y2, 20 DIV scale, Max(1 MOD cv.numcolors, 1), Graph._GFILLINTERIOR);


    x1:=60 DIV scale;
    y1:=120 DIV scale;
    x2:=99 DIV scale;
    y2:=320 DIV scale;
    Graph.Cube(Graph._GTOP, x1, y1, x2, y2, 20 DIV scale, Max(2 MOD cv.numcolors, 1),Graph._GFILLINTERIOR);

    
    x1:=100 DIV scale;
    y1:=80 DIV scale;
    x2:=139 DIV scale;
    y2:=320 DIV scale;
    Graph.Cube(Graph._GTOP, x1, y1, x2, y2, 20 DIV scale, Max(3 MOD cv.numcolors, 1), Graph._GFILLINTERIOR );

    
    x1:=140 DIV scale;
    y1:=200 DIV scale;
    x2:=179 DIV scale;
    y2:=320 DIV scale;
    Graph.Cube(Graph._GTOP, x1, y1, x2, y2, 20 DIV scale, Max(4 MOD cv.numcolors, 1), Graph._GFILLINTERIOR);

    SYSTEM.Eval(IO.RdKey());
END Bars;


PROCEDURE RandColor(): CARDINAL;

VAR
    color: CARDINAL;
BEGIN
    color:=Lib.RANDOM(cv.numcolors);
    IF color = 0 THEN
        color:=cv.numcolors-1;
    END;
    RETURN color;
END RandColor;


PROCEDURE DrawLines();

VAR
    x, y, col: CARDINAL;
    MaxX, MaxY: CARDINAL;
    top, left, bottom, right: CARDINAL;
    i, limit: INTEGER;
BEGIN
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    top:=0;
    left:=0;
    bottom:=cv.numypixels - 1;
    right :=cv.numxpixels - 1;
    MaxX:=cv.numxpixels - 1;
    MaxY:=cv.numypixels - 1;
    limit:=cv.numcolors-1;
    col:=0;
    i := 0;
    WHILE (i <= limit) & ~IO.KeyPressed() DO
        INC(col);
        Graph.SetClipRgn(left, top, right, bottom);
        INC(top, 4);
        INC(left, 4);
        DEC(bottom, 4);
        DEC(right, 4);
        x := 0;
        WHILE x <= MaxX DO
            Graph.Line(x, 0, MaxX - x,MaxY, col);
            INC(x, 4);
        END;
        y := 0;
        WHILE y <= MaxY DO
            Graph.Line(MaxX, y, 0, MaxY - y, col);
            INC(y, 2);
        END;
        INC(i);
    END;
    SYSTEM.Eval(Graph.SetTextPosition(25, 1));
    Graph.SetClipRgn(0, 0, cv.numxpixels-1, cv.numypixels-1);
    IF NOT Mono THEN
        Graph.OutText('Press Any Key To Continue, X To Exit.');
    END;
    TestKey;
    Graph.ClearScreen(Graph._GCLEARSCREEN);
END DrawLines;

PROCEDURE DrawLogo(scale: INTEGER; Cols: SmallColorArray);

VAR
    mode: BOOLEAN;
BEGIN
    IF Mono THEN
        mode:=Graph._GBORDER;
    ELSE
        mode:=Graph._GFILLINTERIOR;
    END;
    Graph.Rectangle(140 DIV scale, 20 DIV scale, 500 DIV scale, 330 DIV scale, Cols[0], mode);
    Graph.Line(225 DIV scale, 110 DIV scale, 320 DIV scale, 140 DIV scale, Cols[1]);
    Graph.Line(320 DIV scale, 140 DIV scale, 415 DIV scale, 110 DIV scale, Cols[1]);
    Graph.Line(415 DIV scale, 110 DIV scale, 460 DIV scale, 125 DIV scale, Cols[1]);
    Graph.Line(460 DIV scale, 125 DIV scale, 460 DIV scale, 225 DIV scale, Cols[1]);
    Graph.Line(460 DIV scale, 225 DIV scale, 365 DIV scale, 255 DIV scale, Cols[1]);
    Graph.Line(365 DIV scale, 255 DIV scale, 365 DIV scale, 285 DIV scale, Cols[1]);
    Graph.Line(365 DIV scale, 285 DIV scale, 320 DIV scale, 300 DIV scale, Cols[1]);
    Graph.Line(320 DIV scale, 300 DIV scale, 180 DIV scale, 255 DIV scale, Cols[1]);
    Graph.Line(180 DIV scale, 255 DIV scale, 180 DIV scale, 190 DIV scale, Cols[1]);
    Graph.Line(180 DIV scale, 190 DIV scale, 225 DIV scale, 205 DIV scale, Cols[1]);
    Graph.Line(225 DIV scale, 205 DIV scale, 225 DIV scale, 235 DIV scale, Cols[1]);
    Graph.Line(225 DIV scale, 235 DIV scale, 270 DIV scale, 250 DIV scale, Cols[1]);
    Graph.Line(270 DIV scale, 250 DIV scale, 270 DIV scale, 190 DIV scale, Cols[1]);
    Graph.Line(270 DIV scale, 190 DIV scale, 180 DIV scale, 160 DIV scale, Cols[1]);
    Graph.Line(180 DIV scale, 160 DIV scale, 180 DIV scale, 125 DIV scale, Cols[1]);
    Graph.Line(180 DIV scale, 125 DIV scale, 225 DIV scale, 110 DIV scale, Cols[1]);

    Graph.Line(180 DIV scale, 125 DIV scale, 320 DIV scale, 170 DIV scale, Cols[1]);
    Graph.Line(320 DIV scale, 170 DIV scale, 460 DIV scale, 125 DIV scale, Cols[1]);
    Graph.Line(320 DIV scale, 170 DIV scale, 320 DIV scale, 300 DIV scale, Cols[1]);

    Graph.Line(365 DIV scale, 190 DIV scale, 415 DIV scale, 175 DIV scale, Cols[1]);
    Graph.Line(415 DIV scale, 175 DIV scale, 415 DIV scale, 210 DIV scale, Cols[1]);
    Graph.Line(415 DIV scale, 210 DIV scale, 365 DIV scale, 225 DIV scale, Cols[1]);
    Graph.Line(365 DIV scale, 225 DIV scale, 365 DIV scale, 190 DIV scale, Cols[1]);
    Graph.Line(365 DIV scale, 190 DIV scale, 415 DIV scale, 210 DIV scale, Cols[1]);

    Graph.Line(225 DIV scale, 205 DIV scale, 270 DIV scale, 190 DIV scale, Cols[1]);
    Graph.Line(225 DIV scale, 235 DIV scale, 270 DIV scale, 220 DIV scale, Cols[1]);
    Graph.Line(180 DIV scale, 190 DIV scale, 225 DIV scale, 175 DIV scale, Cols[1]);

    IF NOT Mono THEN
        Graph.FloodFill(250 DIV scale, 130 DIV scale, Cols[1], Cols[1]);
        Graph.FloodFill(230 DIV scale, 180 DIV scale, Cols[1], Cols[1]);
        Graph.FloodFill(260 DIV scale, 240 DIV scale, Cols[1], Cols[1]);
        Graph.FloodFill(380 DIV scale, 210 DIV scale, Cols[1], Cols[1]);

        Graph.FloodFill(200 DIV scale, 230 DIV scale, Cols[2], Cols[1]);
        Graph.FloodFill(250 DIV scale, 220 DIV scale, Cols[2], Cols[1]);
        Graph.FloodFill(400 DIV scale, 190 DIV scale, Cols[2], Cols[1]);
        Graph.FloodFill(440 DIV scale, 190 DIV scale, Cols[2], Cols[1]);
    END;
END DrawLogo;

PROCEDURE Rotate(Colors: ARRAY OF LONGCARD);

VAR
    n: CARDINAL;
BEGIN
    n:=0;
    Colors[15]:=Colors[0];
    WHILE n < 15 DO
        Colors[n]:=Colors[n+1];
        INC(n);
    END;
END Rotate;

PROCEDURE CGAIntro();

VAR
    c: SmallColorArray;
BEGIN
    c:=SmallColorArray(1,2,3,4);
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    DrawLogo(2, c);
    SYSTEM.Eval(Graph.SetTextPosition(4, 9));
    SYSTEM.Eval(Graph.SetTextColor(2));
    Graph.OutText('TopSpeed Modula-2  Graphics');
    SYSTEM.Eval(Graph.SetTextPosition(25, 1));
    Graph.OutText('Press Any Key To Continue, X To Exit.');
    TestKey;
END CGAIntro;

PROCEDURE EGAIntro();

VAR
    n                   : INTEGER;
    c                   : SmallColorArray;

  PROCEDURE GetKey():CHAR;
    VAR
      c                 : CHAR;
    BEGIN
      c := IO.RdKey();
      IF CAP(c) = 'X' THEN
        SYSTEM.Eval(Graph.SetVideoMode(Graph._DEFAULTMODE));
        HALT;
      END; (*IF*)
      RETURN c;
    END GetKey;

BEGIN
    c:=SmallColorArray(9, 8, 15, 6);
    Graph.OutText('TopSpeed Modula-2 Graphics');
    SYSTEM.Eval(Graph.SetActivePage(1));
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    DrawLogo(1, c);
    SYSTEM.Eval(Graph.SetTextPosition(4, 20));
    SYSTEM.Eval(Graph.SetTextColor(4));
    Graph.OutText('TopSpeed  Modula-2  Graphics  Library  Demo');
    SYSTEM.Eval(Graph.SetVisualPage(1));
    SYSTEM.Eval(Graph.SetTextColor(10));
    SYSTEM.Eval(Graph.SetTextPosition(25, 23));
    Graph.OutText('Press Any Key To Continue, X To Exit');
    IF CAP(GetKey()) = 'C' THEN
        n:=1;
        WHILE NOT IO.KeyPressed() DO
            SYSTEM.Eval(Graph.RemapPalette(6, Colors[(6+n) MOD 16]));
            SYSTEM.Eval(Graph.RemapPalette(8, Colors[(8+n) MOD 16]));
            SYSTEM.Eval(Graph.RemapPalette(9, Colors[(9+n) MOD 16]));
            SYSTEM.Eval(Graph.RemapPalette(15, Colors[(15+n) MOD 16]));
            Lib.Delay(100);
            INC(n);
        END;
        SYSTEM.Eval(IO.RdKey());
        WHILE NOT IO.KeyPressed() DO
            SYSTEM.Eval(Graph.RemapAllPalette(Colors));
            Lib.Delay(1000);
            Rotate(Colors);
        END;
        SYSTEM.Eval(IO.RdKey());
    END;
    SYSTEM.Eval(Graph.SetActivePage(0));
    SYSTEM.Eval(Graph.SetVisualPage(0));
    Graph.ClearScreen(Graph._GCLEARSCREEN);
END EGAIntro;

PROCEDURE HercIntro();

VAR
    c: SmallColorArray;
BEGIN
    c:=SmallColorArray(1, 1, 1, 1);
    Graph.ClearScreen(Graph._GCLEARSCREEN);
    DrawLogo(1, c);
    TestKey;
    Graph.ClearScreen(Graph._GCLEARSCREEN);
END HercIntro;

PROCEDURE HercDemo();


BEGIN
    SYSTEM.Eval(Graph.SetVideoMode(Graph._HERCMONO));
    Graph.GetVideoConfig(cv);
    HercIntro();
    Ellipses(1);
    DrawLines();
    Animation(Graph._HGC);
    Pies(1);
    Bars(1);
END HercDemo;

PROCEDURE EGADemo();

BEGIN
    SYSTEM.Eval(Graph.SetVideoMode(Graph._ERESCOLOR));
    Graph.GetVideoConfig(cv);
    EGAIntro();
    Ellipses(1);
    DrawLines();
    Animation(Graph._EGA);
    Pies(1);
    Bars(1);
END EGADemo;

PROCEDURE VGADemo();

BEGIN
    SYSTEM.Eval(Graph.SetVideoMode(Graph._ERESCOLOR));
    Graph.GetVideoConfig(cv);
    EGAIntro();
    VGATriangle();
    Ellipses(1);
    DrawLines();
    Animation(Graph._EGA);
    Pies(1);
    Bars(1);
END VGADemo;

PROCEDURE CGADemo();

BEGIN
    SYSTEM.Eval(Graph.SetVideoMode(Graph._MRES4COLOR));
    Graph.GetVideoConfig(cv);
    CGAIntro();
    Ellipses(2);
    DrawLines();
    Animation(Graph._CGA);
    Pies(2);
    Bars(2);
END CGADemo;


BEGIN
    Mono := FALSE;
    Graph.GetVideoConfig(cv);
    CASE cv.adapter OF
        |  Graph._HGC :
            Mono:= TRUE;
            HercDemo();
        | Graph._MDPA :
            IO.WrStr('A Color Graphics Card Is Not Installed');
            IO.WrLn();
            HALT;
        | Graph._CGA, Graph._MCGA :
            CGADemo();
        | Graph._VGA :
            VGADemo();
        | Graph._EGA :
            EGADemo();
        ELSE
            IO.WrStr('Graphics Card Not Supported');
            IO.WrLn();
            HALT;
    END;
    SYSTEM.Eval(Graph.SetVideoMode(Graph._DEFAULTMODE));
END MGdemo.