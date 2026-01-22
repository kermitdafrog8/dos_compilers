(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  GRAPHI.MOD - OS/2 graphics functions requiring IOPL                     *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*# call(o_a_copy=>off) *)
(*# module(implementation=>off) *)
(*%F _fdata *)
(*# data(seg_name => null) *)
(*%E *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE GraphI;

(*# call(near_call=>off,
         seg_name=>GRAPH_IOPL,
         iopl=>on) *)

IMPORT Graph, Dos;

CONST
  CGAWidth           = 320 ;
  CGADepth           = 200 ;
  CGANumColor        = 4 ;
  EGAWidth           = 640 ;
  EGADepth           = 350 ;
  VGAWidth           = 640 ;
  VGADepth           = 350 ;
  EGANumColor        = 16 ;
  VGA256Width        = 320 ;
  VGA256Depth        = 200 ;
  VGANumColor        = 16 ;

CONST
  HercWidth          = 720 ;
  HercDepth          = 348 ;
  HercNumColor       = 2 ;
  ATTWidth           = 640 ;
  ATTDepth           = 400 ;
  ATTNumColor        = 2 ;


PROCEDURE SaveScreen;
VAR
  BitMap : CARDINAL;
  bp : CGABuffPtr;
BEGIN
  IF IsCGA THEN
    bp := FarADR(CBuffer);
    GRCopy(bp, [VideoSel:0 CGABuffPtr], 4000H);
  ELSE
    FOR BitMap := 0 TO MaxBitMap DO
      Out(3CEH,4);
      Out(3CFH,SHORTCARD(BitMap));
      GRCopy(Buffer[BitMap], [VideoSel:0 BMP], BitMapSize);
    END;
  END;
END SaveScreen;


PROCEDURE RestoreScreen();
VAR
  BitMap      : CARDINAL;
BEGIN
  IF IsCGA THEN
    GRCopy([VideoSel:0 CGABuffPtr], FarADR(CBuffer), 4000H);
  ELSE
    FOR BitMap := 0 TO MaxBitMap DO
      Out( 3C4H,2);Out( 3C5H,SHORTCARD(1<<BitMap));
      GRCopy([VideoSel:0 BMP], Buffer[BitMap], BitMapSize);
    END;
  END ;
END RestoreScreen;


PROCEDURE EGAPlot( x,y,c : CARDINAL); (* Also VGA *)
VAR
(*# save, data(volatile=>on) *)
  t:BS;
(*# restore *)
  p,b,s,i,bi:CARDINAL;
BEGIN
   IF (x < EGAWidth) AND (y < Graph.Depth) THEN
      bi := (7-(x MOD 8));
      p := y*80+(x DIV 8);
      IF Virtual THEN
        FOR i := 0 TO 3 DO
          IF i IN BS(c) THEN
            INCL(BS(Buffer[i]^[p]),bi)
          ELSE
            EXCL(BS(Buffer[i]^[p]),bi);
          END;
        END;
      ELSE
        b := 1 << bi;

        Out( 3CEH,8);Out( 3CFH,SHORTCARD(b));
        Out( 3C4H,2);Out( 3C5H,0FH);
        s := VideoSel;
        t := [s:p BP]^;
        [s:p BP]^ := BS{};
        Out( 3C4H,2);Out( 3C5H,SHORTCARD(c));
        [s:p BP]^ := BS{0..7};
        Out( 3CEH,8);Out( 3CFH,0FFH);
        Out( 3C4H,2);Out( 3C5H,0FH);

      END;
   END;
END EGAPlot;

PROCEDURE EGAPoint(x,y:CARDINAL) : CARDINAL; (* Also VGA *)
VAR
  t:BS;
  p,b,s,i:CARDINAL;
  c:CARDINAL;
BEGIN
  c := 0;
  IF (x < EGAWidth) AND (y < Graph.Depth) THEN
    b := 1 << (7-(x MOD 8));
    p := y*80+(x DIV 8  );

    IF Virtual THEN
      FOR i := 3 TO 0 BY -1 DO
        t := BS(Buffer[i]^[p])*BS(b);
        c := c * 2 + CARDINAL( SHORTCARD(t) );
      END;
    ELSE
      s := VideoSel;

      Out( 3CEH, 4 ); (* read map sel *)

      Out( 3CFH, 3 );
      t := [s:p BP]^;
      t := t * BS(b);
      c := CARDINAL( SHORTCARD(t) );

      Out( 3CFH, 2 );
      t := [s:p BP]^;
      t := t * BS(b);
      c := c * 2 + CARDINAL( SHORTCARD(t) );

      Out( 3CFH, 1 );
      t := [s:p BP]^;
      t := t * BS(b);
      c := c * 2 + CARDINAL( SHORTCARD(t) );

      Out( 3CFH, 0 );
      t := [s:p BP]^;
      t := t * BS(b);
      c := c * 2 + CARDINAL( SHORTCARD(t) );

    END;
    c := c >> ( 7 - ( x MOD 8 ) );
  END;
  RETURN c;
END EGAPoint;

PROCEDURE EGAHLine ( x,y,x2 : CARDINAL; c:CARDINAL ); (* Also VGA *)
VAR c1,c2,i : CARDINAL;
BEGIN
  IF y >= Graph.Depth THEN RETURN END;
  IF INTEGER(x) >= INTEGER(EGAWidth) THEN RETURN END;
  IF INTEGER(x) < 0 THEN x := 0; END;
  IF x2 >= EGAWidth THEN x2 := EGAWidth-1 END;
  WHILE (x MOD 8 # 0)  AND (x <= x2) DO
    EGAPlot( x  , y , c ); INC( x  );
  END;
  WHILE (x2 MOD 8 # 7) AND (x <= x2) DO
    EGAPlot( x2 , y , c ); DEC( x2 );
  END;
  IF INTEGER(x) > INTEGER(x2) THEN RETURN; END;
  y := y*80;
  x := x DIV 8;
  x2 := x2 DIV 8;
  IF Virtual THEN
    INC(y,x);
    WHILE x <= x2 DO
      FOR i := 0 TO 3 DO
          IF i IN BS(c) THEN
          Buffer[i]^[y] := BS{0..7};
        ELSE
          Buffer[i]^[y] := BS{};
        END;
      END;
      INC( x );
      INC( y );
    END;
  ELSE
    Out( 3CEH,8);Out( 3CFH,0FFH);
    Out( 3C4H,2);Out( 3C5H,0FH);
    Out( 3CEH,5);Out( 3CFH,2);
    WHILE x <= x2 DO
      [VideoSel:y+x BP]^ := BS(c);
      INC( x );
    END;
  END ;
  Out( 3CEH,5);Out( 3CFH,0);
END EGAHLine;

(* -- CGA routines -- *)

PROCEDURE SaveCGAScreen;
BEGIN
    GRCopy([VideoSel:0 CGABuffPtr], FarADR(CBuffer), 4000H);
END SaveCGAScreen;


PROCEDURE RestoreCGAScreen();
VAR
  bp : CGABuffPtr;
BEGIN
  bp := FarADR(CBuffer);
  GRCopy(bp, [VideoSel:0 CGABuffPtr], 4000H);
END RestoreCGAScreen;


PROCEDURE CGAPlot(x,y:CARDINAL;c:CARDINAL);
VAR
  off : CARDINAL;
  seg : CARDINAL;
  tmp : CARDINAL;
BEGIN
  IF (x >= CGAWidth) OR (y >= CGADepth) THEN RETURN END;
  off := x >> 2;
  IF ODD(y) THEN INC( off, 2000H - 40 ) END;
  INC( y, y << 2 );
  INC( off, y << 3 );
  x := 3 - CARDINAL( BITSET(x) * BITSET(3) );
  x := x << 1;
  seg := VideoSel;
  [seg:off BP]^ := ( [seg:off BP]^ - BS(3<<x) ) + BS(c<<x);
END CGAPlot;

PROCEDURE CGAPoint(x,y:CARDINAL) : CARDINAL;
VAR
  off : CARDINAL;
  seg : CARDINAL;
  tmp : CARDINAL;
BEGIN
  IF (x >= CGAWidth) OR (y >= CGADepth) THEN RETURN MAX(CARDINAL) END;
  off := x >> 2;
  IF ODD(y) THEN INC( off, 2000H - 40 ) END;
  INC( y, y << 2 );
  INC( off, y << 3 );
  x := 3 - CARDINAL( BITSET(x) * BITSET(3) );
  x := x << 1;
  seg := VideoSel;
  RETURN CARDINAL( [seg:off BP]^ * BS(3<<x) ) >> x;
END CGAPoint;

PROCEDURE CGAHLine ( x,y,x2 : CARDINAL; c:CARDINAL );
VAR
  off  : CARDINAL;
  seg  : CARDINAL;
  tmp  : CARDINAL;
  n,i  : CARDINAL;
  w    : BS;
  mask : BS;
  fillc: SHORTCARD;
BEGIN
  IF y > CGADepth-1 THEN RETURN END;
  IF INTEGER(x) >= INTEGER(CGAWidth) THEN RETURN END;
  IF INTEGER(x) < 0 THEN x := 0; END;
  IF x2 >= CGAWidth THEN x2 := CGAWidth-1 END;

  n := ( x2 - x ) + 1;
  off := x >> 2;
  IF ODD(y) THEN
    INC( off, 2000H - 40 );
    c := ( c >> 2 + c << 2 ) MOD 16;
  END;
  c := c + c * 16;
  INC( y, y << 2 );
  INC( off, y << 3 );
  x := 3 - CARDINAL( BITSET(x) * BITSET(3) );
  x := x << 1;
  seg := VideoSel;

  w := [seg:off BP]^;
  REPEAT
    mask := BS(3 << x);
    w := ( w - mask ) + BS(c)*mask;
    DEC(n);
    DEC(x,2);
  UNTIL (n=0) OR (x=CARDINAL(-2));
  [seg:off BP]^ := w;

  INC(off);
  FOR i := 1 TO (n>>2) DO
    [seg:off BP]^ := BS(c);
    INC(off);
  END;
  n := n MOD 4;
  x := 6;
  w := [seg:off BP]^;
  WHILE n <> 0 DO
    mask := BS(3 << x);
    w := ( w - mask ) + BS(c)*mask;
    DEC(n);
    DEC(x,2);
  END;
  [seg:off BP]^ := w;
END CGAHLine;

PROCEDURE Plot( x,y,c : CARDINAL); (* CGA/EGA/VGA *)
BEGIN
  IF IsCGA THEN
    CGAPlot(x,y,c);
  ELSE
    EGAPlot(x,y,c);
  END;
END Plot;


PROCEDURE HLine ( x,y,x2 : CARDINAL; c:CARDINAL ); (* CGA/EGA/VGA *)
BEGIN
  IF IsCGA THEN
    CGAHLine(x,y,x2,c);
  ELSE
    EGAHLine(x,y,x2,c);
  END;
END HLine;


PROCEDURE Line(x1,y1,x2,y2: CARDINAL; c: CARDINAL);
VAR
  dx,dy,e,tmp : INTEGER;
BEGIN
  IF x1 > x2 THEN (* ensure that x2 >= x1 *)
    tmp := x1; x1 := x2; x2 := tmp;
    tmp := y1; y1 := y2; y2 := tmp;
  END;

  dx := x2-x1;
  e  := 0;
  IF y1 <= y2 THEN (* case where y increases *)
    dy := (y2-y1);
    IF dx >= dy THEN
      LOOP
        Plot( x1,y1,c );
        IF x1 = x2 THEN EXIT END;
        INC(x1);
        INC(e,dy);
        INC(e,dy);
        IF e > dx THEN
          DEC(e,dx);
          DEC(e,dx);
          INC(y1);
        END;
      END;
    ELSE
      LOOP
        Plot( x1,y1,c );
        IF y1 = y2 THEN EXIT END;
        INC(y1);
        INC(e,dx);
        INC(e,dx);
        IF e > dy THEN
          DEC(e,dy);
          DEC(e,dy);
          INC(x1);
        END;
      END;
    END;
  ELSE
    (* case where y decreases *)
    dy := (y1-y2);
    IF dx >= dy THEN
      LOOP
        Plot( x1,y1,c );
        IF x1 = x2 THEN EXIT END;
        INC(x1);
        INC(e,dy);
        INC(e,dy);
        IF e > dx THEN
          DEC(e,dx);
          DEC(e,dx);
          DEC(y1);
        END;
      END;
    ELSE
      LOOP
        Plot( x1,y1,c );
        IF y1 = y2 THEN EXIT END;
        DEC(y1);
        INC(e,dx);
        INC(e,dx);
        IF e > dy THEN
          DEC(e,dy);
          DEC(e,dy);
          INC(x1);
        END;
      END;
    END;
  END;
END Line;


CONST
  dx = 2;
  dy = 2;

PROCEDURE Disc(x0,y0,r: CARDINAL; c: CARDINAL);
VAR
  e   : INTEGER;
  x,y : CARDINAL;
BEGIN
  x := r; y := 0; e := 0;
  WHILE INTEGER(y) <= INTEGER(x) DO
    HLine(x0-x,y0+y,x0+x,c);
    HLine(x0-x,y0-y,x0+x,c);
    INC(y);
    INC(e,y*dy-1);
    IF e > INTEGER(x) THEN
      DEC(x);
      DEC(e,x*dx+1);
      HLine(x0-y,y0+x,x0+y,c);
      HLine(x0-y,y0-x,x0+y,c);
    END;
  END;
END Disc;

PROCEDURE Circle(x0,y0,r: CARDINAL; c: CARDINAL);
VAR
  e   : INTEGER;
  x,y : CARDINAL;
BEGIN
  x := r; y := 0; e := 0;
  WHILE INTEGER(y) <= INTEGER(x) DO
    Plot(x0+x,y0+y,c);
    Plot(x0-x,y0+y,c);
    Plot(x0+x,y0-y,c);
    Plot(x0-x,y0-y,c);
    Plot(x0+y,y0+x,c);
    Plot(x0-y,y0+x,c);
    Plot(x0+y,y0-x,c);
    Plot(x0-y,y0-x,c);
    INC(y);
    INC(e,y*dy-1);
    IF e > INTEGER(x) THEN
      DEC(x);
      DEC(e,x*dx+1);
    END;
  END;
END Circle;

PROCEDURE Ellipse ( x0,y0 : CARDINAL ;  (* center *)
                    a0,b0 : CARDINAL ;  (* semi-axes *)
                    c     : CARDINAL ;  (* color *)
                    fill  : BOOLEAN ) ; (* wether filled *)
VAR
  x,y : CARDINAL ;
  a,b : LONGINT ;
  asq,asq2,bsq,bsq2 : LONGINT ;
  d,dx,dy           : LONGINT ;
BEGIN
  x := 0 ;
  y := b0 ;
  a := LONGINT(a0) ;
  b := LONGINT(b0) ;
  asq := a*a ;
  asq2 := asq*2 ;
  bsq := b*b ;
  bsq2 := bsq*2 ;
  d := bsq-(asq*b)+(asq DIV 4) ;
  dx := 0 ;
  dy := asq2*b ;
  WHILE dx<dy DO
    IF fill THEN
      HLine(x0-x,y0+y,x0+x,c);
      HLine(x0-x,y0-y,x0+x,c);
    ELSE
      Plot(x0+x,y0+y,c) ;
      Plot(x0-x,y0+y,c) ;
      Plot(x0+x,y0-y,c) ;
      Plot(x0-x,y0-y,c) ;
    END ;
    IF d>0 THEN
      DEC(y) ;
      DEC(dy,asq2) ;
      DEC(d,dy) ;
    END ;
    INC(x) ;
    INC(dx,bsq2) ;
    INC(d,bsq+dx) ;
  END ;
  INC(d,(3*(asq-bsq)DIV 2-(dx+dy))DIV 2) ;
  WHILE INTEGER(y)>=0 DO
    IF fill THEN
      HLine(x0-x,y0+y,x0+x,c);
      HLine(x0-x,y0-y,x0+x,c);
    ELSE
      Plot(x0+x,y0+y,c) ;
      Plot(x0-x,y0+y,c) ;
      Plot(x0+x,y0-y,c) ;
      Plot(x0-x,y0-y,c) ;
    END ;
    IF d<0 THEN
      INC(x) ;
      INC(dx,bsq2) ;
      INC(d,dx) ;
    END ;
    DEC(y) ;
    DEC(dy,asq2) ;
    INC(d,asq-dy) ;
  END ;
END Ellipse ;


PROCEDURE Polygon(n: CARDINAL; px,py: ARRAY OF CARDINAL; c: CARDINAL);
CONST
  MaxPts = 20;
VAR
  y,miny,maxy,x0,y0,x1,y1,temp,i,edge,next_edge,active : INTEGER;
  xord : ARRAY [0..MaxPts] OF INTEGER;
  x    : ARRAY [0..MaxPts] OF CARDINAL;
  e    : ARRAY [0..MaxPts] OF INTEGER;

(*# save *)
(*# call(reg_saved=>(ax,bx,cx,ds,si,di,st1,st2)) *)
PROCEDURE quicksort(l,r: INTEGER);
VAR
  i,j,temp : INTEGER;
  key : CARDINAL;
BEGIN
  WHILE ( l < r ) DO
    i := l; j := r; key := x[xord[j]];
    REPEAT
      WHILE ( i < j ) AND ( x[xord[i]] <= key ) DO i := i + 1 END;
      WHILE ( i < j ) AND ( key <= x[xord[j]] ) DO j := j - 1 END;
      IF i < j THEN
        temp := xord[i]; xord[i] := xord[j]; xord[j] := temp;
      END;
    UNTIL ( i >= j );
    temp := xord[i]; xord[i] := xord[r]; xord[r] := temp;
    IF (i-l < r-i) THEN
      quicksort( l, i-1 ); l := i+1;
    ELSE
      quicksort( i+1, r ); r := i-1;
    END;
  END;
END quicksort;
(*# restore *)

BEGIN
  IF n > MaxPts THEN n := MaxPts END;

  (* find extremal y points *)
  miny := py[0]; maxy := miny;
  FOR i := 0 TO n-1 DO
    IF INTEGER(py[i]) < miny THEN miny := py[i]; END;
    IF INTEGER(py[i]) > maxy THEN maxy := py[i]; END;
  END;

  FOR y := miny TO maxy DO
    active := -1;
    FOR edge := 0 TO n-1 DO
      IF edge = INTEGER(n-1) THEN next_edge := 0 ELSE next_edge := edge + 1; END;
      x0 := px[edge]; y0 := py[edge];
      x1 := px[next_edge]; y1 := py[next_edge];
      IF y0 > y1 THEN temp := x0; x0 := x1; x1 := temp;
                      temp := y0; y0 := y1; y1 := temp END;
      IF y = y0 THEN e[edge] :=  0; x[edge] := x0
      ELSIF ( y0 <= y ) AND ( y <= y1 ) THEN
        IF x1 >= x0 THEN (* x increases with y *)
          INC( e[edge], 2*(x1-x0) );
          WHILE e[edge] > INTEGER(y1-y0) DO
            DEC( e[edge], 2*(y1-y0) ); INC(x[edge]);
          END;
        ELSE (* x decreases with y *)
          INC( e[edge], 2*(x0-x1) );
          WHILE e[edge] > INTEGER(y1-y0) DO
            DEC( e[edge], 2*(y1-y0) ); DEC(x[edge]);
          END;
        END;
        active := active + 1;
        xord[active] := edge;
      END;
    END;
    quicksort(0,active);
    i := 0;
    WHILE i < active DO
      HLine( x[xord[i]], y, x[xord[i+1]], c );
      i := i + 2;
    END;
  END; (* for y := .. *)
END Polygon;

BEGIN
  Dos.PortAccess(0, 0, 3C4H, 3C5H);
  Dos.PortAccess(0, 0, 3CEH, 3CFH);
END GraphI.
