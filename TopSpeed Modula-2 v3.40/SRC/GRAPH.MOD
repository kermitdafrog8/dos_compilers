(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  GRAPH.MOD - Graphics functions                                          *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*# call(o_a_copy => off) *)
(*%T _fcall *)
(*# call(seg_name => GRAPHICS) *)
(*%E *)
(*# module(implementation=>off) *)
(*%F _fdata *)
(*# data(seg_name => null) *)
(*%E *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)


IMPLEMENTATION MODULE Graph;

  IMPORT Str,Lib,SYSTEM,Storage;
(*%T _XTD *)
  IMPORT IO,TSXLIB;
  FROM TSXLIB IMPORT SEL_A000H,SEL_B000H,SEL_B800H;
  CONST _XTDDOS = TRUE;
(*%E*)
(*%F _XTD *)
 (*%F _OS2 *)
  IMPORT IO;
  CONST _XTDDOS = TRUE;
 (*%E *)
 (*%T _OS2 *)
  (*%F _fcall *)
   IMPORT IO;
  (*%E *)
   IMPORT Dos,Vio,GraphI,CoreGraph,CoreSig;
   FROM Storage          IMPORT ALLOCATE,DEALLOCATE;
   CONST _XTDDOS = FALSE;
 (*%E _OS2 *)
(*%E _XTD *)

(*%T _XTDDOS *)

(*%F _XTD *)
  CONST
    SEL_A000H           = 0A000H;
    SEL_B000H           = 0B000H;
    SEL_B800H           = 0B800H;
(*%E*)

(*****************************************************************************)
(* Constant Definitions.                                                     *)
(*****************************************************************************)

  CONST
    HEADER_SIZE         = 4;
    FILL_MASK_SIZE      = 8;
    GRAPHICS            = 1;
    TEXT                = 0;
    LEFT                = -1;
    RIGHT               = 1;
    UP                  = -1;
    DOWN                = 1;
    MAXMODE             = _MRES256COLOR;
    CGA320Width         = 320;
    CGA640Width         = 640;
    EGA640Width         = 640;
    EGA320Width         = 320;
    EGA200Depth         = 200;
    EGA350Depth         = 350;
    EGA480Depth         = 480;

  TYPE
    ArcQuadrant         = ARRAY [0..3] OF SHORTCARD;

CONST
    _Q_CLEAR            = 5;
    _Q_1SEG             = 4;           (* one section in quadrant  *)
    _Q_2SEG             = 3;           (* two sections in quadrant *)
    _Q_STEST            = 2;           (* start vector in quadrant *)
    _Q_ETEST            = 1;           (* end vector in quadrant   *)
    _Q_NULL             = 0;

(*****************************************************************************)
(* type and function definitions.                                            *)
(*****************************************************************************)
  TYPE
    InterSect           = RECORD
                            x,y        : INTEGER;
                          END; (*InterSect*)

    FloodStart          = RECORD
                            best_quad  : INTEGER;
                            quad_type  : INTEGER;
                            flag       : INTEGER;
                          END; (*FloodStart*)
  tinyint               = [0..7];
  bs                    = SET OF tinyint;
  bp                    = POINTER TO bs;
(*# save,data(near_ptr=>off) *)
  HercMapType           = ARRAY[0..(HercDepth DIV 4)-1] OF ARRAY[0..(HercWidth DIV 8)-1] OF bs;
  CGAPointer            = POINTER TO SHORTCARD;
  VGAPointer            = POINTER TO SHORTCARD;
(*# restore *)

  VAR
(*# save,data(near_ptr=>off) *)
    HercBitMap          : ARRAY [0..1] OF ARRAY [0..3] OF POINTER TO HercMapType;
(*# restore *)
    StaticMode          : CARDINAL;
(*****************************************************************************)
(* Data Definitions and Declarations.                                        *)
(*****************************************************************************)

TYPE
  ColTableType = ARRAY [0..15] OF LONGCARD;
  EGATableType = ARRAY [0..15] OF CARDINAL;
CONST
  ColTable = ColTableType( _BLACK, _BLUE, _GREEN, _CYAN, _RED, _MAGENTA, _BROWN,
                   _WHITE, _GRAY, _LIGHTBLUE, _LIGHTGREEN, _LIGHTCYAN,
                   _LIGHTRED, _LIGHTMAGENTA, _LIGHTYELLOW, _BRIGHTWHITE);


VAR
  EGATable: EGATableType;
  ModeChanged: BOOLEAN;
(*****************************************************************************)
(* Function definitions - low level plotting and drawing.                   *)
(*****************************************************************************)

(*# save *)
(*# call(near_call=>on) *)


PROCEDURE EllipsePlot(x, y: INTEGER);

BEGIN
    IF ((x <= CoreGraph._clip_br.xcoord) AND (x >= CoreGraph._clip_tl.xcoord)
     AND (y <= CoreGraph._clip_br.ycoord) AND (y >= CoreGraph._clip_tl.ycoord)) THEN
        CoreGraph._plot(x, y, CoreGraph._fgcolor);
    END;
    RETURN;
END EllipsePlot;

PROCEDURE GetFillStart(VAR x, y: INTEGER;  ox, oy, startx, starty,
                      endx, endy: INTEGER): BOOLEAN;

VAR
    fx, fy: INTEGER;
BEGIN
    IF CoreGraph._fstart.flag = 0 THEN
        RETURN FALSE;
    END;
    IF((startx = endx) AND (starty = endy)) THEN
        RETURN FALSE;
    END;
    IF CoreGraph._fstart.quad_type =  _Q_CLEAR THEN
        CASE CoreGraph._fstart.best_quad OF
            | 0:
                fx:=ox+1;
                fy:=oy+1;
            | 1:
                fx:=ox+1;
                fy:=oy-1;
            | 2:
                fx:=ox-1;
                fy:=oy-1;
            | 3:
                fx:=ox-1;
                fy:=oy+1;
        END;
    ELSIF (CoreGraph._fstart.quad_type = _Q_STEST) THEN
        CASE CoreGraph._fstart.best_quad OF
            | 0:
                fx:=ox+(((startx-ox+1)>>1)+1);
                fy:=oy+(((starty-oy)>>1)-1);
            | 1:
                fx:=ox+(((startx-ox)>>1)-1);
                fy:=starty+(((oy-starty)>>1)-1);
            | 2:
                fx:=startx+(((ox-startx)>>1)-1);
                fy:=starty+(((oy-starty+1)>>1)+1);
            | 3:
                fx:=startx+(((ox-startx+1)>>1)+1);
                fy:=oy+(((starty-oy+1)>>1)+1);
        END;
    ELSE (* _Q_1SEG *)
        CASE CoreGraph._fstart.best_quad OF
            | 0:
                fx:=startx+((endx-startx)>>1)-1;
                fy:=endy+((starty-endy)>>1)-1;
            | 1:
                fx:=endx+((startx-endx)>>1)-1;
                fy:=endy+((starty-endy)>>1)+1;
            | 2:
                fx:=endx+((startx-endx)>>1)+1;
                fy:=starty+((endy-starty)>>1)+1;
            | 3:
                fx:=startx+((endx-startx)>>1)+1;
                fy:=starty+((endy-starty)>>1)-1;
        END;
    END;
    x:=fx;
    y:=fy;
    RETURN TRUE;
END GetFillStart;

PROCEDURE SetFillStart(quadrant: ArcQuadrant);

VAR
    q: INTEGER;

BEGIN
    q:=0;
    CoreGraph._fstart.flag:=1;
    WHILE q < 4 DO
        CASE quadrant[q] OF
            |  _Q_CLEAR:
                CoreGraph._fstart.best_quad:=q;
                CoreGraph._fstart.quad_type:=_Q_CLEAR;
                RETURN;
            |  _Q_1SEG:
                CoreGraph._fstart.best_quad:=q;
                CoreGraph._fstart.quad_type:=_Q_1SEG;
                RETURN;
            |  _Q_STEST:
                CoreGraph._fstart.best_quad:=q;
                CoreGraph._fstart.quad_type:=_Q_STEST;

        END;
        INC(q);
    END;
    RETURN;
END SetFillStart;


PROCEDURE ArcPlot(quadrant: INTEGER; flag: SHORTCARD; noclip: BOOLEAN; xp, yp, startx, endx, starty, endy: INTEGER);

VAR
    ok_to_plot: BOOLEAN;
BEGIN
    IF flag = SHORTCARD(_Q_NULL) THEN
        RETURN ;
    END;
    ok_to_plot:=FALSE;
    IF((noclip) OR (((xp <= CoreGraph._clip_br.xcoord) AND (xp >= CoreGraph._clip_tl.xcoord))
         AND((yp <= CoreGraph._clip_br.ycoord) AND (yp >= CoreGraph._clip_tl.ycoord)))) THEN
        IF flag = SHORTCARD(_Q_CLEAR) THEN
            ok_to_plot:=TRUE;
        ELSE
            CASE quadrant OF
                |  0:
                    CASE flag OF
                        |  _Q_1SEG:
                            IF((xp >= startx) AND (xp <= endx)
                            AND (yp <= starty) AND (yp >= endy)) THEN
                                ok_to_plot:=TRUE;
                            END;
                        |  _Q_2SEG:
                            IF(((xp >= startx) AND (yp <= starty))
                            OR ((xp <= endx) AND (yp >= endy))) THEN
                                ok_to_plot:=TRUE;
                            END;
                        |  _Q_ETEST:
                            IF((xp <= endx) AND (yp >= endy)) THEN
                                ok_to_plot:=TRUE;
                            END;
                        ELSE
                            IF((xp >= startx) AND (yp <= starty)) THEN
                                ok_to_plot:=TRUE;
                            END;
                    END;
                |  3:
                    CASE flag OF
                        |  _Q_1SEG:
                            IF((xp >= startx) AND (xp <= endx)
                            AND (yp >= starty) AND (yp <= endy)) THEN
                                ok_to_plot:=TRUE;
                            END;
                        |  _Q_2SEG:
                            IF(((xp >= startx) AND (yp >= starty))
                            OR ((xp <= endx) AND (yp <= endy))) THEN
                                ok_to_plot:=TRUE;
                            END;
                        |  _Q_ETEST:
                            IF((xp <= endx) AND (yp <= endy)) THEN
                                ok_to_plot:=TRUE;
                            END;
                        ELSE
                            IF((xp >= startx) AND (yp >= starty)) THEN
                                ok_to_plot:=TRUE;
                            END;
                    END;
                |  2:
                    CASE flag OF
                        |  _Q_1SEG:
                            IF((xp <= startx) AND (xp >= endx)
                            AND (yp >= starty) AND (yp <= endy)) THEN
                                ok_to_plot:=TRUE;
                            END;
                        |  _Q_2SEG:
                            IF(((xp <= startx) AND (yp >= starty))
                            OR ((xp >= endx) AND (yp <= endy))) THEN
                                ok_to_plot:=TRUE;
                            END;
                        |  _Q_ETEST:
                            IF((xp >= endx) AND (yp <= endy)) THEN
                                ok_to_plot:=TRUE;
                            END;
                        ELSE
                            IF((xp <= startx) AND (yp >= starty)) THEN
                                ok_to_plot:=TRUE;
                            END;
                    END;
                ELSE  (* quadrant := 1 *)
                    CASE flag OF
                        |  _Q_1SEG:
                            IF((xp <= startx) AND (xp >= endx)
                            AND (yp <= starty) AND (yp >= endy)) THEN
                                ok_to_plot:=TRUE;
                            END;
                        |  _Q_2SEG:
                            IF(((xp <= startx) AND (yp <= starty))
                            OR ((xp >= endx) AND (yp >= endy))) THEN
                                ok_to_plot:=TRUE;
                            END;
                        |  _Q_ETEST:
                            IF((xp >= endx) AND (yp >= endy)) THEN
                                ok_to_plot:=TRUE;
                            END;
                        ELSE
                            IF((xp <= startx) AND (yp <= starty)) THEN
                                ok_to_plot:=TRUE;
                            END;
                    END;
            END;
        END;
        IF ok_to_plot THEN
            CoreGraph._plot(xp, yp, CoreGraph._fgcolor);
        END;
    END;
    RETURN ;
END ArcPlot;

PROCEDURE GetInRange(VAR a0, b0: INTEGER);

BEGIN
  IF a0 > b0 THEN
    IF a0 > 1023 THEN
      b0 := INTEGER((LONGINT(b0)*1023) DIV LONGINT(a0));
      a0 := 1023;
    END;
  ELSE
    IF b0 > 1023 THEN
      a0 := INTEGER((LONGINT(a0)*1023) DIV LONGINT(b0));
      b0 := 1023;
    END;
  END;
END GetInRange;

PROCEDURE DrawEllipse(x0, y0, a0, b0: INTEGER; Fill: BOOLEAN);

VAR
    x, y, line, oldline: INTEGER;
    a, b: LONGINT;
    asq, asq2, bsq, bsq2: LONGINT;
    d, dx, dy: LONGINT;
    plotx, plotx2, ploty: INTEGER;
    no_clip: BOOLEAN;
    mask: CARDINAL;

BEGIN
    GetInRange(a0, b0);
    no_clip:=FALSE;
    x := 0 ;
    y := b0 ;
    a := LONGINT(a0);
    b := LONGINT(b0);
    asq := a*a ;
    asq2 := asq*2 ;
    bsq := b*b ;
    bsq2 := bsq*2 ;
    d := bsq-(asq*b)+(asq>>2) ;
    dx := 0 ;
    dy := asq2*b ;
    oldline := -(y0+y+1);
    IF ((x0+a0 <= CoreGraph._clip_br.xcoord) AND (x0-a0 >= CoreGraph._clip_tl.xcoord))
    AND ((y0+b0 <= CoreGraph._clip_br.ycoord) AND (y0-b0 >= CoreGraph._clip_tl.ycoord)) THEN
        no_clip:=TRUE;
    END;
    WHILE dx < dy DO
        plotx:=x0+x;
        ploty:=y0+y;
        IF no_clip THEN
            CoreGraph._plot(plotx, ploty, CoreGraph._fgcolor);
        ELSE
            EllipsePlot(plotx, ploty);
        END;
        plotx:=x0-x;
        ploty:=y0+y;
        IF no_clip THEN
            CoreGraph._plot(plotx, ploty, CoreGraph._fgcolor);
        ELSE
            EllipsePlot(plotx, ploty);
        END;
        plotx:=x0+x;
        ploty:=y0-y;
        IF no_clip THEN
            CoreGraph._plot(plotx, ploty, CoreGraph._fgcolor);
        ELSE
            EllipsePlot(plotx, ploty);
        END;
        plotx:=x0-x;
        ploty:=y0-y;
        IF no_clip THEN
            CoreGraph._plot(plotx, ploty, CoreGraph._fgcolor);
        ELSE
            EllipsePlot(plotx, ploty);
        END;
        IF Fill = _GFILLINTERIOR THEN
            plotx:=x0-x+1;
            plotx2:=x0+x-1;
            IF plotx2 > plotx THEN
                line:=y0+y;
                IF line # oldline THEN
                    oldline := line;
                    mask:=CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(line) * BITSET(7))])
                         +CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(line) * BITSET(7))])*100H;
                    IF mask = MAX(CARDINAL) THEN
                        CoreGraph._hline(plotx, line, plotx2, CoreGraph._fgcolor);
                    ELSE
                        CoreGraph._line(plotx, line, plotx2, line, mask);
                    END;
                    line:=y0-y;
                    mask:=CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(line) * BITSET(7))])
                         +CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(line) * BITSET(7))])*100H;
                    IF mask = MAX(CARDINAL) THEN
                        CoreGraph._hline(plotx, line, plotx2, CoreGraph._fgcolor);
                    ELSE
                        CoreGraph._line(plotx, line, plotx2, line, mask);
                    END;
                END;
            END;
        END;
        IF d > 0 THEN
            DEC(y);
            DEC(dy, asq2);
            DEC(d, dy);
        END;
        INC(x);
        INC(dx, bsq2);
        INC(d, bsq+dx);
    END;
    INC(d, (3*((asq-bsq)>>1)-((dx+dy)>>1)));
    WHILE y >= 0  DO
        plotx:=x0+x;
        ploty:=y0+y;
        IF no_clip THEN
            CoreGraph._plot(plotx, ploty, CoreGraph._fgcolor);
        ELSE
            EllipsePlot(plotx, ploty);
        END;
        plotx:=x0-x;
        ploty:=y0+y;
        IF no_clip THEN
            CoreGraph._plot(plotx, ploty, CoreGraph._fgcolor);
        ELSE
            EllipsePlot(plotx, ploty);
        END;
        plotx:=x0+x;
        ploty:=y0-y;
        IF no_clip THEN
            CoreGraph._plot(plotx, ploty, CoreGraph._fgcolor);
        ELSE
            EllipsePlot(plotx, ploty);
        END;
        plotx:=x0-x;
        ploty:=y0-y;
        IF no_clip THEN
            CoreGraph._plot(plotx, ploty, CoreGraph._fgcolor);
        ELSE
            EllipsePlot(plotx, ploty);
        END;
        IF Fill = _GFILLINTERIOR THEN
            plotx:=x0-x+1;
            plotx2:=x0+x-1;
            IF plotx2 > plotx THEN
                line:=y0+y;
                IF line # oldline THEN
                    oldline := line;
                    mask:=CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(line) * BITSET(7))])
                         +CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(line) * BITSET(7))])*100H;
                    IF mask = MAX(CARDINAL) THEN
                        CoreGraph._hline(plotx, line, plotx2, CoreGraph._fgcolor);
                    ELSE
                        CoreGraph._line(plotx, line, plotx2, line, mask);
                    END;
                    line:=y0-y;
                    mask:=CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(line) * BITSET(7))])
                         +CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(line) * BITSET(7))])*100H;
                    IF mask = MAX(CARDINAL) THEN
                        CoreGraph._hline(plotx, line, plotx2, CoreGraph._fgcolor);
                    ELSE
                        CoreGraph._line(plotx, line, plotx2, line, mask);
                    END;
                END;
            END;
        END;
        IF  d < 0  THEN
          INC(x);
          INC(dx, bsq2);
          INC(d, dx);
        END;
        DEC(y);
        DEC(dy, asq2);
        INC(d, asq-dy);
    END;
    RETURN;
END DrawEllipse;

PROCEDURE GetArc(VAR quadrant: ArcQuadrant; x, y, sx, sy, ex, ey: INTEGER): BOOLEAN;

BEGIN
    IF ((sx = ex) AND (sy = ey)) THEN
        RETURN TRUE;
    END;
    DEC(sx, x);
    DEC(ex, x);
    DEC(sy, y);
    DEC(ey, y);
    IF((sx > 0) AND (sy > 0)) THEN  (* start in quad 0 *)
        quadrant[0]:=SHORTCARD(_Q_STEST);
        IF((ey <= 0) AND (ex > 0)) THEN
            quadrant[1]:=SHORTCARD(_Q_ETEST);
            quadrant[2]:=SHORTCARD(_Q_NULL);
            quadrant[3]:=SHORTCARD(_Q_NULL);
        ELSIF((ey <= 0) AND (ex <= 0)) THEN
            quadrant[1]:=SHORTCARD(_Q_CLEAR);
            quadrant[2]:=SHORTCARD(_Q_ETEST);
            quadrant[3]:=SHORTCARD(_Q_NULL);
        ELSIF((ey > 0) AND (ex <= 0)) THEN
            quadrant[1]:=SHORTCARD(_Q_CLEAR);
            quadrant[2]:=SHORTCARD(_Q_CLEAR);
            quadrant[3]:=SHORTCARD(_Q_ETEST);
        ELSIF((ey > 0) AND (ex > 0)) THEN
            IF(sx < ex) THEN
                quadrant[0]:=SHORTCARD(_Q_1SEG);
                quadrant[1]:=SHORTCARD(_Q_NULL);
                quadrant[2]:=SHORTCARD(_Q_NULL);
                quadrant[3]:=SHORTCARD(_Q_NULL);
            ELSE
                quadrant[0]:=SHORTCARD(_Q_2SEG);
                quadrant[1]:=SHORTCARD(_Q_CLEAR);
                quadrant[2]:=SHORTCARD(_Q_CLEAR);
                quadrant[3]:=SHORTCARD(_Q_CLEAR);
            END;
        ELSE
            RETURN FALSE;
        END;
    ELSIF((sx > 0) AND (sy <= 0)) THEN  (* start in quad 1 *)
        quadrant[1]:=_Q_STEST;
        IF((ey <= 0) AND (ex <= 0)) THEN
            quadrant[2]:=SHORTCARD(_Q_ETEST);
            quadrant[3]:=SHORTCARD(_Q_NULL);
            quadrant[0]:=SHORTCARD(_Q_NULL);
        ELSIF((ey > 0) AND (ex <= 0)) THEN
            quadrant[2]:=SHORTCARD(_Q_CLEAR);
            quadrant[3]:=SHORTCARD(_Q_ETEST);
            quadrant[0]:=SHORTCARD(_Q_NULL);
        ELSIF((ey > 0) AND (ex > 0)) THEN
            quadrant[2]:=SHORTCARD(_Q_CLEAR);
            quadrant[3]:=SHORTCARD(_Q_CLEAR);
            quadrant[0]:=SHORTCARD(_Q_ETEST);
        ELSIF((ey <= 0) AND (ex > 0)) THEN
            IF(sx >= ex) THEN
                quadrant[1]:=SHORTCARD(_Q_1SEG);
                quadrant[2]:=SHORTCARD(_Q_NULL);
                quadrant[3]:=SHORTCARD(_Q_NULL);
                quadrant[0]:=SHORTCARD(_Q_NULL);
            ELSE
                quadrant[1]:=SHORTCARD(_Q_2SEG);
                quadrant[2]:=SHORTCARD(_Q_CLEAR);
                quadrant[3]:=SHORTCARD(_Q_CLEAR);
                quadrant[0]:=SHORTCARD(_Q_CLEAR);
            END;
        ELSE
            RETURN FALSE;
        END;
    ELSIF((sx <= 0) AND (sy <= 0)) THEN (* start in quad 2 *)
        quadrant[2]:=SHORTCARD(_Q_STEST);
        IF((ey > 0) AND (ex <= 0)) THEN
            quadrant[3]:=SHORTCARD(_Q_ETEST);
            quadrant[0]:=SHORTCARD(_Q_NULL);
            quadrant[1]:=SHORTCARD(_Q_NULL);
        ELSIF((ey > 0) AND (ex > 0)) THEN
            quadrant[3]:=SHORTCARD(_Q_CLEAR);
            quadrant[0]:=SHORTCARD(_Q_ETEST);
            quadrant[1]:=SHORTCARD(_Q_NULL);
        ELSIF((ey <= 0) AND (ex > 0)) THEN
            quadrant[3]:=SHORTCARD(_Q_CLEAR);
            quadrant[0]:=SHORTCARD(_Q_CLEAR);
            quadrant[1]:=SHORTCARD(_Q_ETEST);
        ELSIF((ey <= 0) AND (ex <= 0)) THEN
            IF(sx >= ex) THEN
                quadrant[2]:=SHORTCARD(_Q_1SEG);
                quadrant[3]:=SHORTCARD(_Q_NULL);
                quadrant[0]:=SHORTCARD(_Q_NULL);
                quadrant[1]:=SHORTCARD(_Q_NULL);
            ELSE
                quadrant[2]:=SHORTCARD(_Q_2SEG);
                quadrant[3]:=SHORTCARD(_Q_CLEAR);
                quadrant[0]:=SHORTCARD(_Q_CLEAR);
                quadrant[1]:=SHORTCARD(_Q_CLEAR);
            END;
        ELSE
            RETURN FALSE;
        END;
    ELSIF((sx <= 0) AND (sy > 0)) THEN (* start in quad 3 *)
        quadrant[3]:=SHORTCARD(_Q_STEST);
        IF((ey > 0) AND (ex > 0)) THEN
            quadrant[0]:=SHORTCARD(_Q_ETEST);
            quadrant[1]:=SHORTCARD(_Q_NULL);
            quadrant[2]:=SHORTCARD(_Q_NULL);
        ELSIF((ey <= 0) AND (ex > 0)) THEN
            quadrant[0]:=SHORTCARD(_Q_CLEAR);
            quadrant[1]:=SHORTCARD(_Q_ETEST);
            quadrant[2]:=SHORTCARD(_Q_NULL);
        ELSIF((ey <= 0) AND (ex <= 0)) THEN
            quadrant[0]:=SHORTCARD(_Q_CLEAR);
            quadrant[1]:=SHORTCARD(_Q_CLEAR);
            quadrant[2]:=SHORTCARD(_Q_ETEST);
        ELSIF((ey > 0) AND (ex <= 0)) THEN
            IF(sx < ex) THEN
                quadrant[3]:=SHORTCARD(_Q_1SEG);
                quadrant[0]:=SHORTCARD(_Q_NULL);
                quadrant[1]:=SHORTCARD(_Q_NULL);
                quadrant[2]:=SHORTCARD(_Q_NULL);
            ELSE
                quadrant[3]:=SHORTCARD(_Q_2SEG);
                quadrant[0]:=SHORTCARD(_Q_CLEAR);
                quadrant[1]:=SHORTCARD(_Q_CLEAR);
                quadrant[2]:=SHORTCARD(_Q_CLEAR);
            END;
        ELSE
            RETURN FALSE;
        END;
    ELSE
        RETURN FALSE;
    END;
    RETURN TRUE;
END GetArc;


PROCEDURE DrawArc(x0, y0, a0, b0, startx, starty, endx, endy: INTEGER): BOOLEAN;

VAR
    x, y: INTEGER;
    xp, yp: INTEGER;
    a, b: LONGINT;
    asq, asq2, bsq, bsq2: LONGINT;
    d, dx, dy: LONGINT;
    quadrant: ArcQuadrant;
    no_clip: BOOLEAN;
BEGIN
    GetInRange(a0, b0);
    no_clip:=FALSE;
    quadrant:=ArcQuadrant(_Q_CLEAR,_Q_CLEAR,_Q_CLEAR,_Q_CLEAR);
    CoreGraph._fstart.flag:=0;
    x := 0 ;
    y := b0 ;
    a := LONGINT(a0);
    b := LONGINT(b0);
    asq := a*a ;
    asq2 := asq*2 ;
    bsq := b*b ;
    bsq2 := bsq*2 ;
    d := bsq-(asq*b)+(asq>>2) ;
    dx := 0 ;
    dy := asq2*b ;
    IF ~GetArc(quadrant, x0, y0, startx, starty, endx, endy) THEN
        RETURN FALSE;
    END;
    SetFillStart(quadrant);
    IF(((x0+a0 <= CoreGraph._clip_br.xcoord) AND (x0-a0 >= CoreGraph._clip_tl.xcoord))
     AND((y0+b0 <= CoreGraph._clip_br.ycoord) AND (y0-b0 >= CoreGraph._clip_tl.ycoord))) THEN
        no_clip:=TRUE;
    END;
    WHILE dx < dy DO
        xp:=x0+x;
        yp:=y0+y;
        ArcPlot(0, quadrant[0], no_clip, xp, yp, startx, endx, starty, endy);
        xp:=x0-x;
        yp:=y0+y;
        ArcPlot(3, quadrant[3], no_clip, xp, yp, startx, endx, starty, endy);
        xp:=x0+x;
        yp:=y0-y;
        ArcPlot(1, quadrant[1], no_clip, xp, yp, startx, endx, starty, endy);
        xp:=x0-x;
        yp:=y0-y;
        ArcPlot(2, quadrant[2], no_clip, xp, yp, startx, endx, starty, endy);
        IF d > 0 THEN
            DEC(y);
            DEC(dy, asq2);
            DEC(d, dy);
        END;
        INC(x);
        INC(dx, bsq2);
        INC(d, bsq+dx);
    END;
    INC(d, (3*((asq-bsq)>>1)-((dx+dy)>>1)));
    WHILE  y >= 0 DO
        xp:=x0+x;
        yp:=y0+y;
        ArcPlot(0, quadrant[0], no_clip, xp, yp, startx, endx, starty, endy);
        xp:=x0-x;
        yp:=y0+y;
        ArcPlot(3, quadrant[3], no_clip, xp, yp, startx, endx, starty, endy);
        xp:=x0+x;
        yp:=y0-y;
        ArcPlot(1, quadrant[1], no_clip, xp, yp, startx, endx, starty, endy);
        xp:=x0-x;
        yp:=y0-y;
        ArcPlot(2, quadrant[2], no_clip, xp, yp, startx, endx, starty, endy);
        IF d<0  THEN
            INC(x);
            INC(dx, bsq2);
            INC(d, dx);
        END;
        DEC(y);
        DEC(dy, asq2);
        INC(d, asq-dy);
    END;
    RETURN TRUE;
END DrawArc;


PROCEDURE GetVec(x0, y0, a0, b0, vx, vy: INTEGER): InterSect;

VAR
    x, y: INTEGER;
    a, b: LONGINT;
    asq, asq2, bsq, bsq2: LONGINT;
    d, dx, dy: LONGINT;
    px, py, qx, qy: INTEGER;
    Ret: InterSect;
    flag: INTEGER;
    last_difference: LONGCARD;
    res: LONGINT;

BEGIN
    Ret:=InterSect(0,0);
    x := 0 ;
    y := b0 ;
    a := LONGINT(a0);
    b := LONGINT(b0);
    qx:=vx-x0;
    qy:=vy-y0;
    asq := a*a ;
    asq2 := asq*2 ;
    bsq := b*b ;
    bsq2 := bsq*2 ;
    d := bsq-(asq*b)+(asq>>2) ;
    dx := 0 ;
    dy := asq2*b ;
    last_difference:=MAX(LONGCARD);
    WHILE dx < dy DO
        IF((qx >= 0) AND (qy >= 0)) THEN
            px:=x0+x;
            py:=y0+y;
            flag:=0;
        ELSIF((qx < 0) AND (qy >= 0)) THEN
            px:=x0-x;
            py:=y0+y;
            flag:=1;
        ELSIF((qx >= 0) AND (qy < 0)) THEN
            px:=x0+x;
            py:=y0-y;
            flag:=2;
        ELSIF((qx < 0) AND (qy < 0)) THEN
            px:=x0-x;
            py:=y0-y;
            flag:=3;
        END;
        res:=(LONGINT(px-x0)*LONGINT(qy)) - (LONGINT(py-y0)*LONGINT(qx));
        IF res < 0 THEN
           res:=-res;
        END;
        IF LONGCARD(res) > last_difference THEN
            RETURN Ret;
        END;
        last_difference:=res;
        Ret.x:=px;
        Ret.y:=py;
        IF d > 0 THEN
          DEC(y);
          DEC(dy, asq2);
          DEC(d, dy);
        END;
        INC(x);
        INC(dx, bsq2);
        INC(d, bsq+dx);
    END;
    INC(d, (3*((asq-bsq)>>1)-((dx+dy)>>1)));
    last_difference:=MAX(LONGCARD);
    WHILE  y >0 DO
        IF flag = 0 THEN
            px:=x0+x;
            py:=y0+y;
        ELSIF flag = 1 THEN
            px:=x0-x;
            py:=y0+y;
        ELSIF flag = 2 THEN
            px:=x0+x;
            py:=y0-y;
        ELSIF flag = 3 THEN
            px:=x0-x;
            py:=y0-y;
        END;
        res:=LONGINT(px-x0)*LONGINT(qy) - LONGINT(py-y0)*LONGINT(qx);
        IF res < 0 THEN
           res:=-res;
        END;
        IF LONGCARD(res) > last_difference THEN
            RETURN Ret;
        END;
        last_difference:=res;
        Ret.x:=px;
        Ret.y:=py;
        IF  d < 0 THEN
          INC(x);
          INC(dx, bsq2);
          INC(d, dx);
        END;
        DEC(y);
        DEC(dy, asq2);
        INC(d, asq-dy);
    END;
    RETURN Ret;
END GetVec;


PROCEDURE HscanLine(VAR xlp, xrp: INTEGER; y, border: INTEGER);

VAR
  mask: CARDINAL;
BEGIN
  CoreGraph._hscan(xlp, xrp, y, border);
  mask:=CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(y)*BITSET(7))])
       +CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(y)*BITSET(7))])*100H;
  IF mask = MAX(CARDINAL) THEN
      CoreGraph._hline(xlp, y, xrp, CoreGraph._fgcolor);
  ELSE
      CoreGraph._line(xlp, y, xrp, y, mask);
  END;
END HscanLine;


PROCEDURE LagFill(xl, xr, y, direction, llim, rlim, border: INTEGER);

LABEL
    ReStart;
VAR
    x, xsl, v: INTEGER;
    mask: CARDINAL;
BEGIN
ReStart:
    DEC(y, direction);
    IF (CoreGraph._clip_tl.ycoord <= y) AND (y <= CoreGraph._clip_br.ycoord) THEN
        mask:=CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(y)*BITSET(7))]);
        x:=xl;
        WHILE x <= llim-1 DO
            IF (BITSET(1<<(CARDINAL(BITSET(x)*BITSET(7)))) * BITSET(mask) # {}) THEN
                v:=CoreGraph._point(x, y);
                IF((v # border) AND (v # CoreGraph._fgcolor)) THEN
                    xsl := x;
                    HscanLine (xsl, x, y, border);
                    LagFill(xsl, x, y, -direction, xl, xr, border);
                END;
            END;
            INC(x);
        END;
        x:=rlim+1;
        WHILE x <= xr DO
            IF (BITSET(1<<(CARDINAL(BITSET(x)*BITSET(7)))) * BITSET(mask) # {}) THEN
                v:=CoreGraph._point(x, y);
                IF((v # border) AND (v # CoreGraph._fgcolor)) THEN
                    xsl := x;
                    HscanLine(xsl, x, y, border);
                    LagFill(xsl, x, y, -direction, xl, xr, border);
                END;
            END;
            INC(x);
        END;
    END;
    INC(y, direction + direction);
    IF ( y >= CoreGraph._clip_tl.ycoord) AND (y <= CoreGraph._clip_br.ycoord ) THEN
        mask:=CARDINAL(CoreGraph._fill_mask[CARDINAL(BITSET(y)*BITSET(7))]);
        x:=xl;
        WHILE x <= xr DO
            IF (BITSET(1<<(CARDINAL(BITSET(x)*BITSET(7)))) * BITSET(mask) # {}) THEN
                v:=CoreGraph._point(x, y);
                IF((v # CoreGraph._fgcolor) AND (v # border)) THEN
                    xsl := x;
                    HscanLine (xsl, x, y, border);
                    IF(x > xr-1) THEN
                                (* Do last one iteratively... *)
                        llim := xl;
                        rlim := xr;
                        xl := xsl;
                        xr := x;
                        GOTO ReStart;
                    ELSE
                        LagFill(xsl, x, y, direction, xl, xr, border);
                    END;
                END;
            END;
            INC(x);
        END;
    END;
    RETURN;
END LagFill;
(*# restore *)
(*****************************************************************************)
(* Function definitions -   CGA specIFic                                     *)
(*****************************************************************************)

(*# save *)
(*# call(reg_param => (ax,bx,cx,dx,st0,st6,st5,st4,st3), reg_saved=>(ds, di, si,st1,st2), c_conv=>off) *)


PROCEDURE _CGA320Plot(x, y, c: INTEGER);

VAR
    ptr: CGAPointer;
    ofs: CARDINAL;
BEGIN
    ofs:=(CARDINAL(x)>>2)+((2000H-40)* CARDINAL( BITSET(y)*BITSET(1) ) )+ (40*CARDINAL(y));
    ptr := [SEL_B800H:ofs];
    x := 3 - INTEGER(BITSET(x)*BITSET(3));
    x := x << 1;
    ptr^ := SHORTCARD((BITSET(ptr^) - BITSET(3<<x)) + BITSET(c<<x));
    RETURN;
END _CGA320Plot;

PROCEDURE _CGA640Plot(x,  y,  c: INTEGER);

VAR
    ptr: CGAPointer;
    ofs: CARDINAL;
    mask: CARDINAL;
BEGIN
    ofs:=(CARDINAL(x)>>3)+((2000H-40)* CARDINAL( BITSET(y)*BITSET(1) ) )+ (40*CARDINAL(y));
    ptr := [SEL_B800H:ofs];
    x:= INTEGER(BITSET(x) * BITSET(7));
    mask:=80H>>x;
    IF(c # 0) THEN
        c:=mask;
    END;
    ptr^ := SHORTCARD((BITSET(ptr^) - BITSET(mask)) + BITSET(c));
    RETURN;
END _CGA640Plot;

PROCEDURE  _CGA320Point(x, y: INTEGER): INTEGER;

VAR
    ptr: CGAPointer;
    ofs: CARDINAL;
BEGIN
    ofs:=(CARDINAL(x)>>2)+((2000H-40)* CARDINAL( BITSET(y)*BITSET(1) ) )+ (40*CARDINAL(y));
    ptr := [SEL_B800H:ofs];
    x := 3 - INTEGER(BITSET(x)*BITSET(3));
    x := (x<<1);
    RETURN( CARDINAL(BITSET(ptr^) * BITSET(3<<x)) >> CARDINAL(x));
END _CGA320Point;

PROCEDURE  _CGA640Point(x,  y: INTEGER): INTEGER;

VAR
    c: SHORTCARD;
    ptr: CGAPointer;
    ofs: CARDINAL;
BEGIN
    ofs:=(CARDINAL(x)>>3)+((2000H-40)* CARDINAL( BITSET(y)*BITSET(1) ) )+ (40*CARDINAL(y));
    ptr := [SEL_B800H:ofs];
    x:=INTEGER(BITSET(x) * BITSET(7));
    c:=SHORTCARD(80H>>x);
    IF(BITSET(ptr^)* BITSET(c) # {}) THEN
        RETURN 1;
    END;
    RETURN 0;
END _CGA640Point;

PROCEDURE _CGA320HScan(VAR xl, xr: INTEGER; y, border: INTEGER);

VAR
    row, left, right: INTEGER;
BEGIN
    left:=xl;
    right:=xr;
    row:=((2000H-40)*INTEGER(BITSET(y) * BITSET(1)))+(40*y);
    xl:=CoreGraph._CGA320leftscan((left>>2)+row, border, CoreGraph._clip_tl.xcoord, left);
    xr:=CoreGraph._CGA320rightscan((right>>2)+row, border, CoreGraph._clip_br.xcoord, right);
END _CGA320HScan;

PROCEDURE _CGA640HScan(VAR xl, xr: INTEGER; y, border: INTEGER);

VAR
    row, left, right: INTEGER;
BEGIN
    left:=xl;
    right:=xr;
    IF border # 0 THEN
        border:=1;
    END;
    row:=((2000H-40)*INTEGER(BITSET(y)*BITSET(1)))+(40*y);
    xl:=CoreGraph._CGA640leftscan((left>>3)+row, border, CoreGraph._clip_tl.xcoord, left);
    xr:=CoreGraph._CGA640rightscan((right>>3)+row, border, CoreGraph._clip_br.xcoord, right);
END _CGA640HScan;

(*****************************************************************************)
(* Function definitions -   VGA 256 color specIFic.                          *)
(*****************************************************************************)


PROCEDURE _VGAPlot(x, y, c: INTEGER);

VAR
    ptr: VGAPointer;
BEGIN
    ptr := [SEL_A000H:y*(VGA256Width)+x];
    ptr^:= SHORTCARD(c);
END _VGAPlot;

PROCEDURE _VGAHScan(VAR xl, xr: INTEGER; y, border: INTEGER);

VAR
    left, right: INTEGER;
    ptr: CARDINAL;
BEGIN
    left:=xl;
    right:=xr;
    y:=y*(VGA256Width);
    ptr:=y+left;
    xl:=CoreGraph._VGAleftscan(ptr, border, CoreGraph._clip_tl.xcoord, left);
    ptr:=y+right;
    xr:=CoreGraph._VGArightscan(ptr, border, CoreGraph._clip_br.xcoord, right);
    RETURN;
END _VGAHScan;

(*****************************************************************************)
(* Function definitions -   VGA and EGA native mode specIFic.                *)
(*****************************************************************************)

  PROCEDURE EGAHScan(VAR xl, xr: INTEGER; y, border: INTEGER);
    VAR
      left,right          : INTEGER;
      p,pp                : CARDINAL;
      ptr                 : FarADDRESS;
    BEGIN
      IF CoreGraph._EGAtranslate # 0 THEN
        border:=CoreGraph._EGAxlat(border);
      END; (*IF*)
      left  := xl;
      right := xr;
      pp    := (CARDINAL(y) * CoreGraph._width) + (CoreGraph._active_page*CoreGraph._page_size) << 4;
      p     := CARDINAL(left>>3) + pp;
      ptr   := [SEL_A000H:p];
      xl    := CoreGraph._EGAleftscan(ptr, border, CoreGraph._clip_tl.xcoord, left);
      p     := CARDINAL(right>>3) + pp;
      ptr   := [SEL_A000H:p];
      xr    := CoreGraph._EGArightscan(ptr, border, CoreGraph._clip_br.xcoord, right);
    END EGAHScan;

PROCEDURE GenericHScan(VAR xl, xr: INTEGER; y, border: INTEGER);

VAR
    v, left, right: INTEGER;
BEGIN
    left:=xl;
    right:=xr;
    REPEAT
        DEC(left);
        v:=CoreGraph._point(left, y);
    UNTIL (v = border) OR (v = CoreGraph._fgcolor) OR (left < CoreGraph._clip_tl.xcoord);
    INC(left);
    REPEAT
        INC(right);
        v:=CoreGraph._point(right, y);
    UNTIL (v = border) OR (v = CoreGraph._fgcolor) OR (right > CoreGraph._clip_br.xcoord);
    DEC(right);
    xl:=left;
    xr:=right;
END GenericHScan;

(*****************************************************************************)
(* Function definitions -   Hercules specIFic.                               *)
(*****************************************************************************)

PROCEDURE HercPlot(x,y,c: INTEGER);

VAR
  Byte: bs;
BEGIN
  IF (x > HercWidth) OR (y > HercDepth) THEN
    RETURN;
  END;
  Byte:=HercBitMap[CoreGraph._active_page][y MOD 4]^[y >> 2][x >> 3];
  IF c = 0 THEN
    Byte:=Byte - bs{(7-(CARDINAL(x) MOD 8))};
  ELSE
    Byte:=Byte + bs{(7-(CARDINAL(x) MOD 8))};
  END;
  HercBitMap[CoreGraph._active_page][y MOD 4]^[y >> 2][x >> 3]:=Byte;
END HercPlot;

PROCEDURE HercPoint(x,y: INTEGER) : INTEGER;
BEGIN
  IF (x > HercWidth) OR (y > HercDepth) THEN RETURN MAX(CARDINAL); END;
  IF bs{7-(CARDINAL(x) MOD 8)} * HercBitMap[CoreGraph._active_page][y MOD 4]^[y >> 2][x >> 3] # bs(0) THEN
      RETURN 1;
  ELSE
      RETURN 0;
  END;
END HercPoint;

(*# restore *)

PROCEDURE HercGraphMode;
TYPE
  DataType = ARRAY[0..11] OF SHORTCARD ;
CONST
  Data = DataType(35H,2DH,2EH,07H,5BH,02H,57H,57H,02H,03H,00H,00H);
VAR
  I: CARDINAL;
BEGIN
    SYSTEM.Out(3BFH,03H);    (* Remove this if do NOT want to override
                                the hercules text mode lock *)
    Lib.Delay(10);
    SYSTEM.Out(3B8H,02H);
    FOR I:= 0 TO 11 DO
        SYSTEM.Out(3B4H,SHORTCARD(I));
        SYSTEM.Out(3B5H,Data[I])
    END;
    Lib.FarWordFill([SEL_B000H:0],4000H,0);
    Lib.Delay(500);
    SYSTEM.Out(3B8H,0AH)
END HercGraphMode;

PROCEDURE HercTextMode;
TYPE
  DataType = ARRAY[0..11] OF SHORTCARD ;
CONST
  Data = DataType(61H,50H,52H,0FH,19H,06H,19H,19H,02H,0DH,0BH,0CH);
VAR
  I: CARDINAL;
BEGIN
    SYSTEM.Out(3B8H,20H);
    FOR I:= 0 TO 11 DO
        SYSTEM.Out(3B4H,SHORTCARD(I));
        SYSTEM.Out(3B5H,Data[I])
    END;
    Lib.FarWordFill([SEL_B000H:0],2000,720H);
    Lib.Delay(500);
    SYSTEM.Out(3B8H,28H)
END HercTextMode;


PROCEDURE  InternalInitCGA(mode: CARDINAL);

BEGIN
    IF((mode = 4) OR (mode = 5)) THEN
        CoreGraph._plot  := _CGA320Plot;
        CoreGraph._point := _CGA320Point;
        CoreGraph._hline := CoreGraph._CGA320HLine;
        CoreGraph._line  := CoreGraph._CGA320Line;
        CoreGraph._hscan := _CGA320HScan;
        CoreGraph._put   := CoreGraph._CGA320Put;
        CoreGraph._get   := CoreGraph._CGA320Get;
        CoreGraph._width := CGA320Width-1;
    ELSE
        CoreGraph._plot  := _CGA640Plot ;
        CoreGraph._point := _CGA640Point ;
        CoreGraph._line  := CoreGraph._CGA640Line ;
        CoreGraph._hline := CoreGraph._CGA640HLine ;
        CoreGraph._hscan := _CGA640HScan;
        CoreGraph._put   := CoreGraph._CGA640Put;
        CoreGraph._get   := CoreGraph._CGA640Get;
        CoreGraph._width := CGA640Width-1;
    END;
    CoreGraph._depth:=CGADepth-1;
END InternalInitCGA;

PROCEDURE  InternalInitEGA(mode: CARDINAL);

BEGIN
    IF mode = 13 THEN
        CoreGraph._width     := 40;
        CoreGraph._depth     := EGA200Depth-1;
    ELSIF mode = 14 THEN
        CoreGraph._width     := 80;
        CoreGraph._depth     := EGA200Depth-1;
    ELSIF mode <= 16 THEN
        CoreGraph._width     := 80;
        CoreGraph._depth     := EGA350Depth-1;
    ELSIF mode <= 18 THEN
        CoreGraph._width     := 80;
        CoreGraph._depth     := EGA480Depth-1;
    END;
    CoreGraph._EGAtranslate:=0;
    IF mode = 15 THEN
        CoreGraph._EGAStartPlane:=2;
        CoreGraph._EGAPlaneShift:=2;
        CoreGraph._EGAtranslate:=1;
    ELSIF mode = 17 THEN
        CoreGraph._EGAStartPlane:=0;
        CoreGraph._EGAPlaneShift:=1;
    ELSE
        CoreGraph._EGAStartPlane:=3;
        CoreGraph._EGAPlaneShift:=1;
    END;
    IF((CoreGraph._EGA64K = TRUE) AND ((mode = _ERESCOLOR) OR (mode = _ERESNOCOLOR))) THEN
        CoreGraph._EGAStartPlane:=2;
        CoreGraph._EGAPlaneShift:=2;
        CoreGraph._EGAtranslate:=1;
        CoreGraph._hscan:= GenericHScan;
    ELSE
        CoreGraph._hscan:= EGAHScan;
    END;
    CoreGraph._put       := CoreGraph._EGAPut;
    CoreGraph._get       := CoreGraph._EGAGet;
    IF mode = _VRES2COLOR THEN
        CoreGraph._line     := CoreGraph._EGA2Line;
        CoreGraph._plot     := CoreGraph._EGA2Plot;
        CoreGraph._point    := CoreGraph._EGA2Point;
        CoreGraph._hline    := CoreGraph._EGA2HLine;
    ELSE
        CoreGraph._line     := CoreGraph._EGALine;
        CoreGraph._plot     := CoreGraph._EGAPlot;
        CoreGraph._point    := CoreGraph._EGAPoint;
        CoreGraph._hline    := CoreGraph._EGAHLine;
    END;
(*    _resetEGA();*)
END InternalInitEGA;

PROCEDURE  InternalInitVGA256();

BEGIN
    CoreGraph._width     := VGA256Width;
    CoreGraph._depth     := VGA256Depth-1;
    CoreGraph._plot      := _VGAPlot;
    CoreGraph._point     := CoreGraph._VGAPoint;
    CoreGraph._line      := CoreGraph._VGALine;
    CoreGraph._hline     := CoreGraph._VGAHLine;
    CoreGraph._hscan     := _VGAHScan;
    CoreGraph._put       := CoreGraph._VGAPut;
    CoreGraph._get       := CoreGraph._VGAGet;
END InternalInitVGA256;

PROCEDURE InternalInitHerc();

BEGIN
    CoreGraph._depth     := HercDepth-1;
    CoreGraph._width     := HercWidth-1;
    CoreGraph._plot      := HercPlot ;
    CoreGraph._point     := HercPoint ;
    CoreGraph._line      := CoreGraph._HercLine ;
    CoreGraph._hline     := CoreGraph._HercHLine ;
    CoreGraph._hscan     := GenericHScan ;
    CoreGraph._put       := CoreGraph._HercPut;
    CoreGraph._get       := CoreGraph._HercGet;
    HercBitMap[0][0]:= [SEL_B000H:0];      (* Initialise BitMap pointers *)
    HercBitMap[0][1]:= [SEL_B000H:02000H];
    HercBitMap[0][2]:= [SEL_B000H:04000H];
    HercBitMap[0][3]:= [SEL_B000H:06000H];
    HercBitMap[1][0]:= [SEL_B800H:0];      (* 2nd Page *)
    HercBitMap[1][1]:= [SEL_B800H:02000H];
    HercBitMap[1][2]:= [SEL_B800H:04000H];
    HercBitMap[1][3]:= [SEL_B800H:06000H];
END InternalInitHerc;

(*****************************************************************************)
(* Function definitions -   Misc low level and initialisation.               *)
(*****************************************************************************)

CONST
    MDA    =  1;
    CGA    =  2;
    EGA    =  3;
    MCGA   =  4;
    VGA    =  5;
    HGC    = 80H;
    HGCPlus= 81H;
    InColor= 82H;

    MDADisplay      =  1;
    CGADisplay      =  2;
    EGAColorDisplay =  3;
    PS2MonoDisplay  =  4;
    PS2ColorDisplay =  5;

(*# save *)
(*# call(near_call=>on) *)
PROCEDURE SetLimits(VAR v: CoreGraph.VideoConfig);

BEGIN
    CASE v.mode OF
        |   0:
            v.numxpixels        := 0;
            v.numypixels        := 0;
            v.numtextcols       := 40;
            v.numtextrows       := 25;
            v.numcolors         := 32;
            v.bitsperpixel      := 0;
            v.numvideopages     := 8;
            CoreGraph._txcolor  := 15;
            CoreGraph._scr_attr := 7;
        |   1:
            v.numxpixels        := 0;
            v.numypixels        := 0;
            v.numtextcols       := 40;
            v.numtextrows       := 25;
            v.numcolors         := 32;
            v.bitsperpixel      := 0;
            v.numvideopages     := 8;
            CoreGraph._txcolor  := 15;
            CoreGraph._scr_attr := 7;
        |   2:
            v.numxpixels        := 0;
            v.numypixels        := 0;
            v.numtextcols       := 80;
            v.numtextrows       := 25;
            v.numcolors         := 32;
            v.bitsperpixel      := 0;
            v.numvideopages     := 4;
            CoreGraph._txcolor  := 15;
            CoreGraph._scr_attr := 7;
        |   3:
            v.numxpixels        := 0;
            v.numypixels        := 0;
            v.numtextcols       := 80;
            v.numtextrows       := 25;
            v.numcolors         := 32;
            v.bitsperpixel      := 0;
            v.numvideopages     := 4;
            CoreGraph._txcolor  := 15;
            CoreGraph._scr_attr := 7;
        |   4:
            v.numxpixels        := 320;
            v.numypixels        := 200;
            v.numtextcols       := 40;
            v.numtextrows       := 25;
            v.numcolors         := 4;
            v.bitsperpixel      := 2;
            v.numvideopages     := 1;
            CoreGraph._fgcolor  := 3;
            CoreGraph._scr_attr := 0;
        |   5:
            v.numxpixels        := 320;
            v.numypixels        := 200;
            v.numtextcols       := 40;
            v.numtextrows       := 25;
            v.numcolors         := 4;
            v.bitsperpixel      := 2;
            v.numvideopages     := 1;
            CoreGraph._page_size:= 0;
            CoreGraph._scr_attr := 0;
            CoreGraph._fgcolor  := 3;
        |   6:
            v.numxpixels        := 640;
            v.numypixels        := 200;
            v.numtextcols       := 80;
            v.numtextrows       := 25;
            v.numcolors         := 2;
            v.bitsperpixel      := 1;
            v.numvideopages     := 1;
            CoreGraph._page_size:= 0;
            CoreGraph._scr_attr := 0;
            CoreGraph._fgcolor  := 1;
        |   7:
            v.numxpixels        := 0;
            v.numypixels        := 0;
            v.numtextcols       := 80;
            v.numtextrows       := 25;
            v.numcolors         := 2;
            v.bitsperpixel      := 0;
            v.numvideopages     := 4;
            CoreGraph._txcolor  := 1;
            CoreGraph._scr_attr := 7;
        |   8:
            v.numxpixels        := 720;
            v.numypixels        := 348;
            v.numtextcols       := 80;
            v.numtextrows       := 25;
            v.numcolors         := 2;
            v.bitsperpixel      := 1;
            v.numvideopages     := 2;
            CoreGraph._page_size:= 800H;
            CoreGraph._fgcolor  := 1;
            CoreGraph._scr_attr := 0;
        |   13:
            v.numxpixels        := 320;
            v.numypixels        := 200;
            v.numtextcols       := 40;
            v.numtextrows       := 25;
            v.numcolors         := 16;
            v.bitsperpixel      := 4;
            v.numvideopages     := CoreGraph._current_video.memory DIV 32;
            CoreGraph._page_size:= 200H;
            CoreGraph._fgcolor  := 15;
            CoreGraph._scr_attr := 0;
        |   14:
            v.numxpixels        := 640;
            v.numypixels        := 200;
            v.numtextcols       := 80;
            v.numtextrows       := 25;
            v.numcolors         := 16;
            v.bitsperpixel      := 4;
            v.numvideopages     := CoreGraph._current_video.memory DIV 64;
            CoreGraph._page_size:= 400H;
            CoreGraph._fgcolor  := 15;
            CoreGraph._scr_attr := 0;
        |   15:
            v.numxpixels        := 640;
            v.numypixels        := 350;
            v.numtextcols       := 80;
            v.numtextrows       := 25;
            v.numcolors         := 4;
            v.bitsperpixel      := 2;
            v.numvideopages     := 2;
            CoreGraph._page_size:= 800H;
            CoreGraph._fgcolor  := 3;
            CoreGraph._scr_attr := 0;
        |   16:
            v.numxpixels        := 640;
            v.numypixels        := 350;
            v.numtextcols       := 80;
            v.numtextrows       := 25;
            v.numcolors         := 16;
            v.bitsperpixel      := 4;
            v.numvideopages     := 2;
            CoreGraph._page_size:= 800H;
            CoreGraph._fgcolor  := 15;
            CoreGraph._scr_attr := 0;
        |   17:
            v.numxpixels        := 640;
            v.numypixels        := 480;
            v.numtextcols       := 80;
            v.numtextrows       := 30;
            v.numcolors         := 2;
            v.bitsperpixel      := 1;
            v.numvideopages     := 1;
            CoreGraph._page_size:= 0;
            CoreGraph._fgcolor  := 1;
            CoreGraph._scr_attr := 0;
        |   18:
            v.numxpixels        := 640;
            v.numypixels        := 480;
            v.numtextcols       := 80;
            v.numtextrows       := 30;
            v.numcolors         := 16;
            v.bitsperpixel      := 4;
            v.numvideopages     := 1;
            CoreGraph._fgcolor  := 15;
            CoreGraph._page_size:= 0;
            CoreGraph._scr_attr := 0;
        |   19:
            v.numxpixels        := 320;
            v.numypixels        := 200;
            v.numtextcols       := 40;
            v.numtextrows       := 25;
            v.numcolors         := 256;
            v.bitsperpixel      := 8;
            v.numvideopages     := 1;
            CoreGraph._fgcolor  := 255;
            CoreGraph._page_size:= 0;
            CoreGraph._scr_attr := 0;
    END;
    CoreGraph._clip_tl.xcoord   :=0;
    CoreGraph._clip_tl.ycoord   :=0;
    CoreGraph._clip_br.xcoord   :=v.numxpixels-1;
    CoreGraph._clip_br.ycoord   :=v.numypixels-1;
    CoreGraph._text_tl.row      :=0;
    CoreGraph._text_tl.col      :=0;
    CoreGraph._text_br.row      :=v.numtextrows-1;
    CoreGraph._text_br.col      :=v.numtextcols-1;
END SetLimits;

PROCEDURE GEnter();

BEGIN
    IF CoreGraph._cursor_state = _GCURSORON THEN
        CoreGraph._gcur(0, CoreGraph._current_text.row, CoreGraph._current_text.col, CoreGraph._visual_page);
        INC(CoreGraph._cursor_lock);
    END;
END GEnter;

PROCEDURE GExit();

BEGIN
    IF(CoreGraph._cursor_state = _GCURSORON) THEN
        DEC(CoreGraph._cursor_lock);
        IF (CoreGraph._cursor_lock = 0) THEN
            CoreGraph._gcur(CoreGraph._txcolor, CoreGraph._current_text.row, CoreGraph._current_text.col, CoreGraph._visual_page);
        END;
    END;
END GExit;

PROCEDURE EGAcolXlat(Color: LONGCARD): INTEGER;

TYPE
    LongSet = SET OF [0..31];
VAR
    ncol, blue, green, red: CARDINAL;
BEGIN
    blue:= CARDINAL(LONGCARD(LongSet(Color)*LongSet(0FF0000H))>>16);
    green:= CARDINAL(LONGCARD(LongSet(Color)*LongSet(0FF00H))>>8);
    red:= CARDINAL(LongSet(Color)*LongSet(0FFH));

    IF red = 0 THEN
        ncol:=0;
    ELSIF red <= 015H THEN
        ncol:=32;
    ELSIF red <= 02AH THEN
        ncol:=4;
    ELSE
        ncol:=36;
    END;
    IF green # 0 THEN
        IF green <= 015H THEN
            INC(ncol, 16);
        ELSIF green <= 02AH THEN
            INC(ncol, 2);
        ELSE
            INC(ncol, 18);
        END;
    END;
    IF blue # 0 THEN
        IF blue <= 015H THEN
            INC(ncol, 8);
        ELSIF blue <= 02AH THEN
            INC(ncol, 1);
        ELSE
            INC(ncol, 9);
        END;
    END;
    RETURN ncol;
END EGAcolXlat;

PROCEDURE ColXlat(Color: LONGCARD): INTEGER;

VAR
    n: INTEGER;
BEGIN
    n:=0;
    LOOP
        IF n = 16 THEN EXIT END;
        IF ColTable[n] = Color THEN EXIT END;
        INC(n);
    END;
    RETURN n;
END ColXlat;

PROCEDURE Scroll();

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=0601H;
    r.BH:=SHORTCARD(CoreGraph._scr_attr);
    r.CH:=SHORTCARD(CoreGraph._text_tl.row);
    r.CL:=SHORTCARD(CoreGraph._text_tl.col);
    r.DH:=SHORTCARD(CoreGraph._text_br.row);
    r.DL:=SHORTCARD(CoreGraph._text_br.col);
    Lib.Intr(r, 10H);
END Scroll;

(*# restore *)

(*****************************************************************************)
(* Public Function definitions.                                              *)
(*****************************************************************************)

PROCEDURE GetVideoConfig(VAR V: VideoConfig);

BEGIN
    IF CoreGraph._defaultmode = 0 THEN RETURN END;
    Lib.FastMove(ADR(CoreGraph._current_video), ADR(V), SIZE(VideoConfig));
END GetVideoConfig;

PROCEDURE SetClipRgn(x1, y1, x2, y2: CARDINAL);

    PROCEDURE Max(A, B: CARDINAL): CARDINAL;

    BEGIN
        IF A > B THEN
            RETURN A;
        ELSE
            RETURN B;
        END;
    END Max;

    PROCEDURE Min(A, B: CARDINAL): CARDINAL;

    BEGIN
        IF A < B THEN
            RETURN A;
        ELSE
            RETURN B;
        END;
    END Min;

BEGIN
    CoreGraph._clip_tl.xcoord:=Max(x1, 0);
    CoreGraph._clip_tl.ycoord:=Max(y1, 0);
    CoreGraph._clip_br.xcoord:=Min(x2, CoreGraph._current_video.numxpixels-1);
    CoreGraph._clip_br.ycoord:=Min(y2, CoreGraph._current_video.numypixels-1);
END SetClipRgn;

PROCEDURE GetBkColor(): LONGCARD;

BEGIN
    RETURN CoreGraph._bkcolor;
END GetBkColor;

PROCEDURE GetFillMask(VAR Mask: FillMaskType);

BEGIN
    Lib.FastMove(ADR(CoreGraph._fill_mask), ADR(Mask), SIZE(CoreGraph.FillMaskType));
END GetFillMask;



PROCEDURE GetLinestyle(): CARDINAL;

BEGIN
    RETURN CoreGraph._current_linestyle;
END GetLinestyle;

PROCEDURE SetBkColor(Color: LONGCARD): LONGCARD;

VAR
    Ret: LONGCARD;
    r: SYSTEM.Registers;

BEGIN
    Ret:=CoreGraph._bkcolor;
    IF Ret = Color THEN
      RETURN Ret;
    END;
    IF (CoreGraph._current_video.mode = _MRES4COLOR) OR (CoreGraph._current_video.mode = _MRESNOCOLOR) THEN
        r.AH:= 0BH;
        r.BH:= 0;
        r.BL:= SHORTCARD(ColXlat(Color));
        Lib.Intr(r, 10H);
    ELSIF CoreGraph._current_video.mode > _MRES16COLOR THEN
        SYSTEM.Eval(RemapPalette(0, Color));
    END;
    CoreGraph._bkcolor:= Color;
    RETURN Ret;
END SetBkColor;

PROCEDURE SetFillMask(Mask: CoreGraph.FillMaskType);

BEGIN
    CoreGraph._current_mask:= CoreGraph.FillMaskPtr(ADR(Mask));
    Lib.FastMove(ADR(Mask), ADR(CoreGraph._fill_mask), SIZE(CoreGraph.FillMaskType));
END SetFillMask;

PROCEDURE SetLinestyle(Mask: CARDINAL);

BEGIN
   CoreGraph._current_linestyle:=Mask;
END SetLinestyle;

PROCEDURE DisplayCursor(Toggle: BOOLEAN): BOOLEAN;

VAR
    Ret: BOOLEAN;
BEGIN
    Ret:=CoreGraph._cursor_state;
    CoreGraph._cursor_state:=Toggle;
    RETURN Ret;
END DisplayCursor;



PROCEDURE GetTextColor(): CARDINAL;

BEGIN
    RETURN CoreGraph._txcolor;
END GetTextColor;

PROCEDURE GetTextPosition(): TextCoords;

VAR
    Ret: TextCoords;
BEGIN
    Ret.row:=CoreGraph._current_text.row-CoreGraph._text_tl.row+1;
    Ret.col:=CoreGraph._current_text.col-CoreGraph._text_tl.col+1;
    RETURN Ret;
END GetTextPosition;


PROCEDURE SetTextColor(Color: CARDINAL): CARDINAL;

VAR
    Ret: CARDINAL;
BEGIN
    Ret:=CoreGraph._txcolor;
    CoreGraph._txcolor:=Color;
    RETURN Ret;
END SetTextColor;

PROCEDURE SetTextPosition(row, col: CARDINAL): TextCoords;

VAR
    Ret: TextCoords;
BEGIN
    Ret:=CoreGraph._current_text;
    GEnter();
    CoreGraph._current_text.row:=INTEGER(row)+CoreGraph._text_tl.row-1;
    CoreGraph._current_text.col:=INTEGER(col)+CoreGraph._text_tl.col-1;
    CoreGraph._setcur(CoreGraph._current_text.row, CoreGraph._current_text.col, CoreGraph._active_page);
    GExit();
    RETURN Ret;
END SetTextPosition;

PROCEDURE SetTextWindow(r1, c1, r2, c2: CARDINAL);

BEGIN
    CoreGraph._text_tl.row:=r1-1;
    CoreGraph._text_tl.col:=c1-1;
    CoreGraph._text_br.row:=r2-1;
    CoreGraph._text_br.col:=c2-1;
    SYSTEM.Eval(SetTextPosition(1, 1));
END SetTextWindow;

PROCEDURE Wrapon(Opt: BOOLEAN): BOOLEAN;

VAR
    Ret: BOOLEAN;

BEGIN
    Ret:=CoreGraph._wrap_state;

    CoreGraph._wrap_state:=Opt;
    RETURN Ret;
END Wrapon;


PROCEDURE OutText(Text: ARRAY OF CHAR);

VAR
    c: CHAR;
    n, h: CARDINAL;
BEGIN
    n:=0;
    h:=HIGH(Text);
    GEnter();
    LOOP
        IF n > h THEN EXIT END;
        c:= Text[n];
        INC(n);
        IF c = CHAR(0) THEN EXIT END;
        CoreGraph._setcur(CoreGraph._current_text.row, CoreGraph._current_text.col, CoreGraph._active_page);
        IF c = CHAR(0AH) THEN
            IF CoreGraph._current_text.row < CoreGraph._text_br.row THEN
                INC(CoreGraph._current_text.row);
            ELSE
                Scroll();
            END;
            CoreGraph._current_text.col:=CoreGraph._text_tl.col;
        ELSIF c = CHAR(0DH) THEN
            CoreGraph._current_text.col:=CoreGraph._text_tl.col;
        ELSE
            CoreGraph._txt_out(INTEGER(c));
            IF CoreGraph._current_text.col = CoreGraph._text_br.col THEN
                CoreGraph._current_text.col:=CoreGraph._text_tl.col;
                IF CoreGraph._current_text.row < CoreGraph._text_br.row THEN
                    INC(CoreGraph._current_text.row);
                ELSE
                    Scroll();
                END;
                IF CoreGraph._wrap_state = _GWRAPOFF THEN EXIT END;
            ELSE
                INC(CoreGraph._current_text.col);
            END;
        END;
    END;
    CoreGraph._setcur(CoreGraph._current_text.row, CoreGraph._current_text.col, CoreGraph._active_page);
    GExit();
END OutText;

PROCEDURE g_charoutput(c: CARDINAL);

BEGIN
    GEnter();
    CoreGraph._setcur(CoreGraph._current_text.row, CoreGraph._current_text.col, CoreGraph._active_page);
    IF c = 0AH THEN
        IF CoreGraph._current_text.row < CoreGraph._text_br.row THEN
            INC(CoreGraph._current_text.row);
        ELSE
            Scroll();
        END;
        CoreGraph._current_text.col:=CoreGraph._text_tl.col;
    ELSIF c = 0DH THEN
        CoreGraph._current_text.col:=CoreGraph._text_tl.col;
    ELSIF c = 8 THEN
        IF CoreGraph._current_text.col = CoreGraph._text_tl.col THEN
            IF CoreGraph._current_text.row > CoreGraph._text_tl.row THEN
                DEC(CoreGraph._current_text.row);
                CoreGraph._current_text.col:=CoreGraph._text_br.col;
            END;
        ELSE
            DEC(CoreGraph._current_text.col);
        END;
        CoreGraph._setcur(CoreGraph._current_text.row, CoreGraph._current_text.col, CoreGraph._active_page);
        CoreGraph._txt_out(INTEGER('\ '));
    ELSE
        CoreGraph._txt_out(INTEGER(c));
        IF CoreGraph._current_text.col = CoreGraph._text_br.col THEN
            CoreGraph._current_text.col:=CoreGraph._text_tl.col;
            IF CoreGraph._current_text.row < CoreGraph._text_br.row THEN
                INC(CoreGraph._current_text.row);
            ELSE
              Scroll();
            END;
        ELSE
            INC(CoreGraph._current_text.col);
        END;
    END;
    CoreGraph._setcur(CoreGraph._current_text.row, CoreGraph._current_text.col, CoreGraph._active_page);
    GExit();
END g_charoutput;

PROCEDURE g_strinput(String: ARRAY OF CHAR);

VAR
    c: CHAR;
    p, n: CARDINAL;
BEGIN
    p:=2;
    n:=0;
    LOOP
        IF n = HIGH(String) THEN EXIT END;
        c:= IO.RdChar();
        IF (c = CHAR(8)) OR (c = CHAR(127)) THEN
            IF n > 0 THEN
                DEC(p);
                DEC(n);
                g_charoutput(8);
            END;
        ELSIF ( c > CHAR(' ')) THEN
            g_charoutput(CARDINAL(c));
            String[p]:=c;
            INC(p);
            INC(n);
        ELSIF c = CHAR(13) THEN
            g_charoutput(CARDINAL(0AH));
            EXIT;
        END;
    END;
    String[p]:=CHAR(0);
END g_strinput;

PROCEDURE SetVideoMode(Mode: CARDINAL): BOOLEAN;

TYPE
    PalRegType = ARRAY [0..16] OF SHORTCARD;
    PalColType = ARRAY [0..15] OF LONGCARD;
CONST
    PalRegs = PalRegType(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0);
    PalCols = PalColType(_BLACK, _BLUE, _GREEN, _CYAN, _RED, _MAGENTA, _BROWN,
                         _WHITE, _GRAY, _LIGHTBLUE, _LIGHTGREEN, _LIGHTCYAN,
                         _LIGHTRED, _LIGHTMAGENTA, _LIGHTYELLOW, _BRIGHTWHITE);
VAR
    R: SYSTEM.Registers;
    n: CARDINAL;

    PROCEDURE CheckMode(): BOOLEAN;

    VAR
        Ret: BOOLEAN;
    BEGIN
        Ret:=TRUE;

        IF Mode = _DEFAULTMODE THEN
            RETURN Ret;
        END;
        IF CoreGraph._current_video.adapter = _MDPA THEN
            IF Mode # _TEXTMONO THEN
                Ret:=FALSE;
            END;
        ELSIF CoreGraph._current_video.adapter = _HGC THEN
            IF (Mode # _TEXTMONO) AND (Mode # _HERCMONO) THEN
                Ret:=FALSE;
            END;
        ELSE
            CASE Mode OF
                | _TEXTBW40, _TEXTC40, _TEXTBW80, _TEXTC80,
                  _MRES4COLOR, _MRESNOCOLOR, _HRESBW:
                    Ret:=TRUE;
                | _TEXTMONO, _MRES16COLOR, _HRES16COLOR,
                 _ERESNOCOLOR, _ERESCOLOR:
                    IF (CoreGraph._current_video.adapter # _VGA) AND (CoreGraph._current_video.adapter # _EGA) THEN
                        Ret:=FALSE;
                    END;
                | _VRES2COLOR:
                    IF (CoreGraph._current_video.adapter # _VGA) AND (CoreGraph._current_video.adapter # _MCGA) THEN
                        Ret:=FALSE;
                    END;
                | _VRES16COLOR, _HERCMONO:
                    IF CoreGraph._current_video.adapter # _VGA THEN   (* HGC already checked *)
                        Ret:=FALSE;
                    END;
                | _MRES256COLOR:
                    IF (CoreGraph._current_video.adapter # _VGA) AND (CoreGraph._current_video.adapter # _MCGA) THEN
                        Ret:=FALSE;
                    END;
                ELSE
                    Ret:=FALSE;
            END;
        END;
        RETURN Ret;
    END CheckMode;

    BEGIN
      IF ~CheckMode() THEN
        RETURN FALSE;
      END; (*IF*)
      IF Mode = _DEFAULTMODE THEN
        Mode := CoreGraph._defaultmode;
      END; (*IF*)
      CoreGraph._display_state := ~(((Mode >= 0) & (Mode <= 3)) OR (Mode = 7));
      IF (Mode >= 4) & (Mode <= 6) THEN
        InternalInitCGA(Mode);
      ELSIF Mode = 8 THEN
        InternalInitHerc;
      ELSIF (Mode >= 13) & (Mode < 19) THEN
        InternalInitEGA(Mode);
      ELSIF Mode = 19 THEN
        InternalInitVGA256;
      END; (*IF*)
      IF CoreGraph._lastmode = 8 THEN
        HercTextMode;
      END; (*IF*)
      IF Mode = 8 THEN
        HercGraphMode;
      ELSE
        CoreGraph._setbiosmode(Mode);
        IF (Mode >= 13) AND (Mode < 19) THEN
          R.AX := 1002H;
          R.ES := Seg(PalRegs);
          R.DX := Ofs(PalRegs);
          Lib.Intr(R,10H);
          FOR n := 0 TO 15 DO
            R.AX := 1010H;
            R.BH := SHORTCARD(n);      (* Trial Fix 12/02/91 *)
            R.BL := SHORTCARD(n);
            R.DH := SHORTCARD(PalCols[n]);
            R.CH := SHORTCARD(PalCols[n] >> 8);
            R.CL := SHORTCARD(PalCols[n] >> 16);
            Lib.Intr(R,10H);
          END; (*FOR*)
        END; (*IF*)
      END; (*IF*)
      CoreGraph._current_video.mode := Mode;
      SetLimits(CoreGraph._current_video);
      CoreGraph._lastmode := Mode;
      ModeChanged := TRUE;
      RETURN TRUE;
    END SetVideoMode;

PROCEDURE SetActivePage(Page: CARDINAL): CARDINAL;


VAR
    Ret: CARDINAL;
BEGIN
    Ret:=CoreGraph._active_page;
    IF (Page < 0) OR (Page > CoreGraph._current_video.numvideopages-1) THEN
        RETURN MAX(CARDINAL);
    END;
    CoreGraph._active_page:=Page;
    RETURN Ret;
END SetActivePage;

  PROCEDURE SetVisualPage(Page:CARDINAL):CARDINAL;
    VAR
      r                 : SYSTEM.Registers;
      Ret               : CARDINAL;
    BEGIN
      Ret := CoreGraph._visual_page;
      IF (Page < 0) OR (Page > CoreGraph._current_video.numvideopages-1) THEN
        RETURN MAX(CARDINAL);
      END; (*IF*)
      CoreGraph._visual_page := Page;
      IF CoreGraph._current_video.mode # _HERCMONO THEN
        r.AH:=5;
        r.AL:=SHORTCARD(Page);
        Lib.Intr(r,10H);
      ELSIF Page = 0 THEN
        SYSTEM.Out(3B8H,0AH);
      ELSE
        SYSTEM.Out(3B8H,08AH);
      END; (*IF*)
      RETURN Ret;
    END SetVisualPage;

PROCEDURE ClearScreen(Area: CARDINAL);

VAR
    r: SYSTEM.Registers;
    LineNum: INTEGER;
BEGIN
    GEnter();
    IF Area = _GWINDOW THEN
        r.AX:=0600H;
        IF CoreGraph._display_state = FALSE THEN
            r.BH:=SHORTCARD(7+(CoreGraph._bkcolor<<4));
        ELSE
            r.BH:=0;
        END;
        r.CH:=SHORTCARD(CoreGraph._text_tl.row);
        r.CL:=SHORTCARD(CoreGraph._text_tl.col);
        r.DH:=SHORTCARD(CoreGraph._text_br.row);
        r.DL:=SHORTCARD(CoreGraph._text_br.col);
        Lib.Intr(r, 10H);
        SYSTEM.Eval(SetTextPosition(1, 1));
    ELSIF Area = _GVIEWPORT THEN
        IF CoreGraph._display_state = TRUE THEN
            LineNum:=CoreGraph._clip_tl.ycoord;
            WHILE LineNum <= CoreGraph._clip_br.ycoord DO
                CoreGraph._hline(CoreGraph._clip_tl.xcoord, LineNum, CoreGraph._clip_br.xcoord, 0);
                INC(LineNum);
            END;
        END;
    ELSIF CoreGraph._current_video.mode = _HERCMONO THEN
        CoreGraph._clear_Herc();
        SYSTEM.Eval(SetTextPosition(1, 1));
    ELSE
        r.AX:=0600H;
        IF CoreGraph._display_state = FALSE THEN
            r.BH:=SHORTCARD(7+(CoreGraph._bkcolor<<4));
        ELSE
            r.BH:=SHORTCARD(CoreGraph._bkcolor);
        END;
        r.CX:=0000H;
        r.DH:=SHORTCARD(CoreGraph._current_video.numtextrows-1);
        r.DL:=SHORTCARD(CoreGraph._current_video.numtextcols-1);
        Lib.Intr(r, 10H);
        SYSTEM.Eval(SetTextPosition(1, 1));
    END;
    GExit();
END ClearScreen;

PROCEDURE Line(x1, y1, x2, y2: CARDINAL; Color: CARDINAL);

BEGIN
    GEnter();
    CoreGraph._fgcolor:=Color;
    IF (y1 = y2) AND (CoreGraph._current_linestyle = MAX(CARDINAL)) THEN
        CoreGraph._hline(x1, y1, x2, Color);
    ELSE
        CoreGraph._line(x1, y1, x2, y2, CoreGraph._current_linestyle);
    END;
    GExit();
END Line;

PROCEDURE HLine(x1, y1, x2: CARDINAL; Color: CARDINAL);

BEGIN
    GEnter();
    CoreGraph._hline(x1, y1, x2, Color);
    GExit();
END HLine;

PROCEDURE Rectangle(x1, y1, x2, y2: CARDINAL; Color: CARDINAL;Fill: BOOLEAN);

VAR
    Mask: CARDINAL;
BEGIN
    GEnter();
    CoreGraph._fgcolor:=Color;
    IF CoreGraph._current_linestyle = MAX(CARDINAL) THEN
        CoreGraph._hline(x1, y1, x2, Color);
        CoreGraph._line(x2, y1, x2, y2, CoreGraph._current_linestyle);
        CoreGraph._hline(x2, y2, x1, Color);
        CoreGraph._line(x1, y2, x1, y1, CoreGraph._current_linestyle);
    ELSE
        CoreGraph._line(x1, y1, x2, y1, CoreGraph._current_linestyle);
        CoreGraph._line(x2, y1, x2, y2, CoreGraph._current_linestyle);
        CoreGraph._line(x2, y2, x1, y2, CoreGraph._current_linestyle);
        CoreGraph._line(x1, y2, x1, y1, CoreGraph._current_linestyle);
    END;
    IF Fill = _GFILLINTERIOR THEN
        INC(x1);
        INC(y1);
        DEC(x2);
        DEC(y2);
        IF x1 = x2 THEN
            GExit();
            RETURN;
        END;
        WHILE y1 <= y2 DO
            Mask:=CARDINAL(CoreGraph._fill_mask[y1 MOD 8])
                 +CARDINAL(CoreGraph._fill_mask[y1 MOD 8])*100H;
            IF Mask =  MAX(CARDINAL) THEN
                CoreGraph._hline(x1, y1, x2, Color);
            ELSE
                CoreGraph._line(x1, y1, x2, y1, Mask);
            END;
            INC(y1);
        END;
    END;
    GExit();
END Rectangle;

PROCEDURE Ellipse(x0, y0, a0, b0: CARDINAL; Color: CARDINAL; Fill: BOOLEAN);

BEGIN
    GEnter();
    CoreGraph._fgcolor:= Color;
    DrawEllipse(x0, y0, a0, b0, Fill);
    GExit();
END Ellipse;

PROCEDURE Disc(x0, y0, r: CARDINAL; Color: CARDINAL);

BEGIN
    Ellipse(x0, y0, r, r, Color, TRUE);
END Disc;

PROCEDURE Circle(x0, y0, r: CARDINAL; Color: CARDINAL);

BEGIN
    Ellipse(x0, y0, r, r, Color, FALSE);
END Circle;

PROCEDURE Arc(x1, y1, a, b, x3, y3, x4, y4: CARDINAL; Color: CARDINAL);

VAR
    start, end: InterSect;
BEGIN
    GEnter();
    CoreGraph._fgcolor:=Color;
    start:=GetVec(x1, y1, a, b, x3, y3);
    end:=GetVec(x1, y1, a, b, x4, y4);
    SYSTEM.Eval(DrawArc(x1, y1, a, b, start.x, start.y, end.x, end.y));
    GExit();
END Arc;

PROCEDURE Pie(x1, y1, a, b, x3, y3, x4, y4: CARDINAL; Color: CARDINAL; Fill: BOOLEAN);

VAR
    Ret: BOOLEAN;
    fx, fy: INTEGER;
    start, end: InterSect;
BEGIN
    GEnter();
    CoreGraph._fgcolor:=Color;
    start:=GetVec(x1, y1, a, b, x3, y3);
    end:=GetVec(x1, y1, a, b, x4, y4);
    Ret:=DrawArc(x1, y1, a, b, start.x, start.y, end.x, end.y);
    IF Ret = FALSE THEN
        RETURN ;
    END;
    CoreGraph._line(x1, y1, start.x, start.y, CoreGraph._current_linestyle);
    CoreGraph._line(x1, y1, end.x, end.y, CoreGraph._current_linestyle);
    IF (Fill = _GFILLINTERIOR) AND (GetFillStart(fx, fy, x1, y1, start.x, start.y,
                                                                     end.x, end.y)) THEN
        FloodFill(fx, fy, CoreGraph._fgcolor, CoreGraph._fgcolor);
    END;
    GExit();
END Pie;

PROCEDURE Plot(x, y: CARDINAL; Color: CARDINAL);

BEGIN
    GEnter();
    IF (INTEGER(x) > CoreGraph._clip_br.xcoord) OR (INTEGER(x) < CoreGraph._clip_tl.xcoord)
    OR (INTEGER(y) > CoreGraph._clip_br.ycoord) OR (INTEGER(y) < CoreGraph._clip_tl.ycoord) THEN
        RETURN;
    END;
    CoreGraph._plot(x, y, Color);
    GExit();
END Plot;

PROCEDURE Point(x, y: CARDINAL): CARDINAL;

BEGIN
    IF (INTEGER(x) > CoreGraph._clip_br.xcoord) OR (INTEGER(x) < CoreGraph._clip_tl.xcoord)
    OR (INTEGER(y) > CoreGraph._clip_br.ycoord) OR (INTEGER(y) < CoreGraph._clip_tl.ycoord) THEN
        RETURN MAX(CARDINAL);
    END;
    RETURN CoreGraph._point(x, y);
END Point;

PROCEDURE FloodFill(x, y: CARDINAL; Color: CARDINAL; Boundary: CARDINAL);

VAR
    xl, xr, v, i, nx, ny: INTEGER;
BEGIN
    CoreGraph._fgcolor:=Color;
    i:=0;
    WHILE ( i < FILL_MASK_SIZE) DO
        IF  CoreGraph._fill_mask[i] = 0  THEN
            StackFill(x, y, Color, Boundary);
            RETURN;
        END;
        INC(i);
    END;
    GEnter();
    nx := INTEGER(x);
    ny := INTEGER(y);
    IF Boundary >= CoreGraph._current_video.numcolors THEN
        Boundary:=CoreGraph._current_video.numcolors-1;
    END;
    IF (nx > CoreGraph._clip_br.xcoord) OR (nx < CoreGraph._clip_tl.xcoord) THEN
        RETURN;
    END;
    IF (ny > CoreGraph._clip_br.ycoord) OR (ny < CoreGraph._clip_tl.ycoord) THEN
        RETURN;
    END;
    v:=CoreGraph._point(x, y);
    IF v = INTEGER(Boundary) THEN
        RETURN;
    END;
    xr := x;
    xl := xr;
    HscanLine (xl, xr, y, Boundary);
    LagFill(xl, xr, y, UP, xl, xl-1, Boundary);
    GExit();
END FloodFill;

PROCEDURE StackFill(x, y: CARDINAL; Color: CARDINAL; Boundary: CARDINAL);

VAR
    xl, xr, xp, yp, nx, ny, direction: INTEGER;
BEGIN
    nx := INTEGER(x);
    ny := INTEGER(y);
    GEnter();
    CoreGraph._fgcolor:=Color;
    IF Boundary >= CoreGraph._current_video.numcolors THEN
        Boundary:=CoreGraph._current_video.numcolors-1;
    END;
    IF (nx > CoreGraph._clip_br.xcoord) OR (nx < CoreGraph._clip_tl.xcoord) THEN
        RETURN;
    END;
    IF (ny > CoreGraph._clip_br.ycoord) OR (ny < CoreGraph._clip_tl.ycoord) THEN
        RETURN;
    END;
    IF CoreGraph._point(x, y) = INTEGER(Boundary) THEN
        RETURN;
    END;
    xr := x;
    xl := xr;
    xp:=x;
    yp:=y;
    HscanLine ( xl, xr, y, Boundary );

    direction := +1;
    LOOP
        ny := yp;
        nx := xl;
        xp := xr;
        LOOP
            INC(ny, direction);
            IF (ny < CoreGraph._clip_tl.ycoord) OR (CoreGraph._clip_br.ycoord < ny) THEN
                EXIT;
            END;
            WHILE (nx <= xp) AND (CoreGraph._point ( nx, ny ) = INTEGER(Boundary)) DO
                INC(nx);
            END;
            IF nx > xp THEN
                EXIT;
            END;
            xp := nx;
            HscanLine (nx, xp, ny, INTEGER(Boundary));
        END;
        IF direction < 0 THEN
            EXIT;
        END;
        direction := -1;
    END;
    GExit();
END StackFill;

PROCEDURE RemapPalette(Pixel: CARDINAL; Color: LONGCARD): LONGCARD;

TYPE
    LongSet = SET OF [0..31];
VAR
    r: SYSTEM.Registers;
    OldColor: LONGCARD;
    n: CARDINAL;
    ColSet: LongSet;
BEGIN
    GEnter();
    IF (CoreGraph._current_video.adapter = _VGA) OR (CoreGraph._current_video.adapter = _MCGA) THEN
      ColSet:=LongSet(Color);
      r.AX:=01015H;
      r.BX:=Pixel;
      Lib.Intr(r, 10H);
      OldColor:= LONGCARD(r.DH);
      OldColor:= OldColor+LONGCARD(r.CH)<<8;
      OldColor:= OldColor+LONGCARD(r.CL)<<16;
      r.AX:=01010H;
      r.BX:=Pixel;
      r.DH:=SHORTCARD(LONGCARD(ColSet));
      r.CH:=SHORTCARD(LONGCARD(ColSet*LongSet(0FF00H))>>8);
      r.CL:=SHORTCARD(LONGCARD(ColSet*LongSet(0FF0000H))>>16);
      Lib.Intr(r, 10H);
    ELSIF (CoreGraph._current_video.adapter = _EGA) THEN
      n:=EGAcolXlat(Color);
      r.AX:=01000H;
      r.BL:=SHORTCARD(Pixel);
      r.BH:=SHORTCARD(n);
      Lib.Intr(r, 10H);
      OldColor:=ColTable[EGATable[Pixel]];
      EGATable[Pixel]:=n;
    ELSE
      OldColor := MAX(LONGCARD);
    END;
    GExit();
    RETURN OldColor;
END RemapPalette;

PROCEDURE RemapAllPalette(Colarray: ARRAY OF LONGCARD): CARDINAL;

VAR
    num, Count: CARDINAL;
    Colors: ARRAY [0..256] OF ARRAY [0..2] OF SHORTCARD;
    ColRegs: ARRAY [0..16] OF CHAR;
    r: SYSTEM.Registers;

BEGIN
    num:=CoreGraph._current_video.numcolors;
    Count:=0;
    GEnter();

    IF (CoreGraph._current_video.adapter = _VGA) OR (CoreGraph._current_video.adapter = _MCGA) THEN
      WHILE Count < num DO
        Lib.Move(ADR(Colarray[Count]), ADR(Colors[Count]), 3);
        INC(Count);
      END;
      r.AX:=01012H;
      r.BX:=0;
      r.CX:=num;

      r.DX:=Ofs(Colors);
      r.ES:=Seg(Colors);
      Lib.Intr(r, 10H);
    ELSIF (CoreGraph._current_video.adapter = _EGA) THEN
      Count:=0;
      WHILE Count < num DO
          ColRegs[Count]:=CHAR(EGAcolXlat(Colarray[Count]));
          INC(Count);
      END;
      ColRegs[16]:=CHAR(0);
      r.AX:=1002H;
      r.DX:=Ofs(ColRegs);
      r.ES:=Seg(ColRegs);
      Lib.Intr(r, 10H);
      Lib.Move(ADR(ColRegs), ADR(EGATable), 17);
    END;
    GExit();
    RETURN Count;
END RemapAllPalette;

VAR
    OldPalette: CARDINAL;

PROCEDURE SelectPalette(Palnum: CARDINAL): CARDINAL;

VAR
    r: SYSTEM.Registers;
    Ret: CARDINAL;
BEGIN
    Ret:=OldPalette;
    IF (CoreGraph._current_video.mode # _MRES4COLOR) AND (CoreGraph._current_video.mode # _MRESNOCOLOR) THEN
        RETURN MAX(CARDINAL);
    END;
    GEnter();
    OldPalette:=Palnum;
    r.AH:=0BH;
    r.BH:=1;
    r.BL:=SHORTCARD(Palnum);
    Lib.Intr(r, 10H);
    GExit();
    RETURN Ret;
END SelectPalette;

PROCEDURE GetImage(x1, y1, x2, y2: CARDINAL; Buffer: ADDRESS);

BEGIN
    GEnter();
    CoreGraph._get(FarADR(Buffer^), x1, y1, x2, y2);
    GExit();
END GetImage;

PROCEDURE PutImage(x, y: CARDINAL; Buffer: ADDRESS; Action: CARDINAL);

BEGIN
    GEnter();
    CoreGraph._put(x, y, FarADR(Buffer^), Action);
    GExit();
END PutImage;

PROCEDURE ImageSize(x1, y1, x2, y2: CARDINAL): LONGCARD;

VAR
    Size: LONGCARD;
    ywidth, xwidth: LONGCARD;
BEGIN
    xwidth:=LONGCARD(ABS(INTEGER(x1)-INTEGER(x2))+1);
    ywidth:=LONGCARD(ABS(INTEGER(y1)-INTEGER(y2))+1);
    Size:=((xwidth DIV 8)+1) * ywidth * LONGCARD(CoreGraph._current_video.bitsperpixel);
    RETURN Size+HEADER_SIZE;
END ImageSize;

PROCEDURE Cube(top: BOOLEAN; x1, y1, x2, y2, depth: CARDINAL; Color: CARDINAL; Fill: BOOLEAN);

VAR
    px, py: ARRAY [0..3] OF CARDINAL;
    height: CARDINAL;
    FillVal: BOOLEAN;
BEGIN
    GEnter();
    FillVal:=FillState;
    FillState:=Fill;
    CoreGraph._fgcolor:=Color;
    height:=y2-y1;
    px[0]:=x2;
    py[0]:=y2;
    px[1]:=x2+depth;
    py[1]:=y2-(depth>>1);
    px[2]:=px[1];
    py[2]:=py[1]-height;
    px[3]:=px[0];
    py[3]:=py[0]-height;
    Polygon(4, px, py, Color);
    IF top THEN
        px[0]:=x1;
        py[0]:=y1;
        px[1]:=x1+depth;
        py[1]:=y1-(depth>>1);
        DEC(px[2]);
        DEC(px[3]);
        Polygon(4, px, py, Color);
    END;
    Rectangle(x1, y1, x2, y2, Color, Fill);
    FillState:=FillVal;
    GExit();
END Cube;

CONST
    MaxPts = 20;
VAR
    xord: ARRAY [0..MaxPts] OF CARDINAL;
    x: ARRAY [0..MaxPts] OF CARDINAL;

PROCEDURE QuickSort(l,r: INTEGER);
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
      QuickSort( l, i-1 ); l := i+1;
    ELSE
      QuickSort( i+1, r ); r := i-1;
    END;
  END;
END QuickSort;

PROCEDURE Polygon(n: CARDINAL; px, py: ARRAY OF CARDINAL; Color: CARDINAL);

VAR
    y, miny, maxy, x0, y0, x1, y1: INTEGER;
    temp, i, edge, next_edge, active: INTEGER;
    e: ARRAY [0..MaxPts] OF INTEGER;
    plotl, plotr: INTEGER;
    Mask: CARDINAL;
BEGIN
    IF n > MaxPts THEN RETURN END;
    GEnter();
    CoreGraph._fgcolor:=Color;
    i:=0;
    WHILE i < INTEGER(n) DO
        IF i < INTEGER(n-1) THEN
            CoreGraph._line(px[i], py[i], px[i+1], py[i+1], CoreGraph._current_linestyle);
        ELSE
            CoreGraph._line(px[i], py[i], px[0], py[0], CoreGraph._current_linestyle);
        END;
        INC(i);
    END;
    IF FillState = _GBORDER THEN
        GExit();
        RETURN;
    END;
    miny:=py[0];                      (* find extremal y points *)
    maxy:=miny;
    i:=0;
    WHILE i < INTEGER(n) DO
        IF INTEGER(py[i]) < miny THEN
            miny:=py[i];
        END;
        IF INTEGER(py[i]) > maxy THEN
            maxy:=py[i];
        END;
        INC(i);
    END;
    y:=miny;
    WHILE y <= maxy DO
        active:=-1;
        edge:= 0;
        WHILE edge < INTEGER(n) DO
            IF edge = INTEGER(n-1) THEN
                next_edge:=0;
            ELSE
                next_edge:=edge+1;
            END;
            x0:=px[edge];
            y0:=py[edge];
            x1:=px[next_edge];
            y1:=py[next_edge];
            IF y0 > y1 THEN
                temp:=x0;
                x0:=x1;
                x1:=temp;
                temp:=y0;
                y0:=y1;
                y1:=temp;
            END;
            IF y = y0 THEN
                e[edge]:=0;
                x[edge]:=x0;
            ELSIF (y0 <= y) AND (y <= y1) THEN
                IF x1 >= x0 THEN (* x increases with y *)
                    INC(e[edge], (2*(x1-x0)));
                    WHILE e[edge] > (y1-y0) DO
                        DEC(e[edge], (2*(y1-y0)));
                        INC(x[edge]);
                    END;
                ELSE (* x decreases with y *)
                    INC(e[edge], (2*(x0-x1)));
                    WHILE e[edge] > (y1-y0) DO
                        DEC(e[edge], (2*(y1-y0)));
                        DEC(x[edge]);
                    END;
                END;
                INC(active);
                xord[active]:=edge;
            END;
            INC(edge);
        END;
        QuickSort(0, active);
        i:=0;
        WHILE i < active DO
            plotl:=x[xord[i]]+1;
            plotr:=x[xord[i+1]]-1;
            IF plotr >= plotl THEN
                CoreGraph._fgcolor:=Color;
                Mask:=CARDINAL(CoreGraph._fill_mask[y MOD 8])
                     +CARDINAL(CoreGraph._fill_mask[y MOD 8])*100H;
                IF Mask = MAX(CARDINAL) THEN
                    CoreGraph._hline(plotl, y, plotr, Color);
                ELSE
                    CoreGraph._line(plotl, y, plotr, y, Mask);
                END;
            END;
            INC(i, 2);
        END;
        INC(y);
    END; (* for y = .. *)
    GExit();
END Polygon;


PROCEDURE GraphMode();

BEGIN
(*%T AutoDetect *)
    CASE CoreGraph._current_video.adapter OF
    | _HGC :
        Width:=HercWidth;
        Depth:=HercDepth;
        NumColor:=HercNumColor;
        IF SetVideoMode(_HERCMONO) THEN END;
    | _CGA, _MCGA:
        Width:=CGAWidth;
        Depth:=CGADepth;
        NumColor:=CGANumColor;
        IF SetVideoMode(_MRES4COLOR) THEN END;
    | _EGA, _VGA :
        Width:=EGAWidth;
        Depth:=EGADepth;
        NumColor:=EGANumColor;
        IF SetVideoMode(_ERESCOLOR) THEN END;
    ELSE
        RETURN;
    END;
(*%E *)
(*%F AutoDetect *)
    CoreGraph._display_state:=TRUE;
    IF StaticMode = _HERCMONO THEN
        HercGraphMode();
    ELSE
        CoreGraph._setbiosmode(StaticMode);
    END;
    CoreGraph._current_video.mode:= StaticMode;
    SetLimits(CoreGraph._current_video);
    CoreGraph._lastmode:=StaticMode;
(*%E *)
END GraphMode;

PROCEDURE TextMode();

BEGIN
(*%T AutoDetect *)
    IF SetVideoMode(_DEFAULTMODE) THEN END;
(*%E *)
(*%F AutoDetect *)
    CoreGraph._display_state:=FALSE;
    IF StaticMode = _HERCMONO THEN
        HercTextMode();
    ELSE
        CoreGraph._setbiosmode(CoreGraph._defaultmode);
    END;
    CoreGraph._current_video.mode:= CoreGraph._defaultmode;
    SetLimits(CoreGraph._current_video);
    CoreGraph._lastmode:=CoreGraph._defaultmode;
(*%E *)
END TextMode;

PROCEDURE  InitCGA();

BEGIN
    InternalInitCGA(_MRES4COLOR);
    CoreGraph._current_video.adapter := _CGA;
    StaticMode:=_MRES4COLOR;
    Width:=CGAWidth;
    Depth:=CGADepth;
    NumColor:=CGANumColor;
END InitCGA;

PROCEDURE  InitEGA();

BEGIN
    InternalInitEGA(_ERESCOLOR);
    CoreGraph._current_video.adapter := _EGA;
    StaticMode:=_ERESCOLOR;
    Width:=EGAWidth;
    Depth:=EGADepth;
    NumColor:=EGANumColor;
END InitEGA;

PROCEDURE  InitVGA();

BEGIN
    InternalInitVGA256();
    CoreGraph._current_video.adapter := _VGA;
    StaticMode:=_MRES256COLOR;
    Width:=VGA256Width;
    Depth:=VGA256Depth;
    NumColor:=VGANumColor;
END InitVGA;

PROCEDURE  InitHerc();

BEGIN
    InternalInitHerc();
    CoreGraph._current_video.adapter := _HGC;
    StaticMode:=_HERCMONO;
    Width:=HercWidth;
    Depth:=HercDepth;
    NumColor:=HercNumColor;
END InitHerc;


  PROCEDURE InitGraph();
    VAR
      display           : CoreGraph.VideoType;
      Disp              : CARDINAL;
    BEGIN
      CoreGraph._defaultmode        := CoreGraph._getvideomode();
      CoreGraph._lastmode           := CoreGraph._defaultmode;
      CoreGraph._current_video.mode := CoreGraph._defaultmode;
      SetLimits(CoreGraph._current_video);
      CoreGraph._getsystem(display);
      Disp := SetActivePage(0);
      Disp := SetVisualPage(0);
      CASE display.sys0 OF
        MDA             : CoreGraph._current_video.adapter:=_MDPA;        |
        CGA             : CoreGraph._current_video.adapter:=_CGA;
                          Width:=CGAWidth;
                          Depth:=CGADepth;
                          NumColor:=CGANumColor;                          |
        EGA             : CoreGraph._current_video.adapter:=_EGA;
                          CoreGraph._current_video.memory:=CoreGraph._getmemory();
                          IF (CoreGraph._current_video.memory = 64 )THEN
                            CoreGraph._EGA64K:=TRUE;
                          END; (*IF*)
                          Width:=EGAWidth;
                          Depth:=EGADepth;
                          NumColor:=EGANumColor;                          |
        MCGA            : CoreGraph._current_video.adapter:=_MCGA;
                          CoreGraph._current_video.memory:=CoreGraph._getmemory();
                          Width:=CGAWidth;
                          Depth:=CGADepth;
                          NumColor:=CGANumColor;                          |
        VGA             : CoreGraph._current_video.adapter:=_VGA;
                          CoreGraph._current_video.memory:=CoreGraph._getmemory();
                          Width := VGAWidth;
                          Depth := VGADepth;
                          NumColor:=EGANumColor;                          |
        HGC             : CoreGraph._current_video.adapter:=_HGC;
                          CoreGraph._current_video.memory:=64;
                          Width:=HercWidth;
                          Depth:=HercDepth;
                          NumColor:=HercNumColor;                         |
        HGCPlus,
        InColor         : CoreGraph._current_video.adapter:=-1;           |
      END; (*CASE*)
      CASE display.dis0 OF
          |  MDADisplay:
              CoreGraph._current_video.monitor:=_MONO;
          |  CGADisplay:
              CoreGraph._current_video.monitor:=_COLOR;
          |  EGAColorDisplay:
              CoreGraph._current_video.monitor:=_ENHCOLOR;
          |  PS2MonoDisplay:
              CoreGraph._current_video.monitor:=_MONO;
          |  PS2ColorDisplay:
              CoreGraph._current_video.monitor:=_ANALOG;
      END;
    END InitGraph;

PROCEDURE TrueDisc(x0,y0,r: CARDINAL; c: CARDINAL);
VAR b:CARDINAL;
BEGIN
  IF CoreGraph._width=CGAWidth-1    THEN b := (r*5)DIV 6;
  ELSIF CoreGraph._depth=EGADepth-1 THEN b := (r*73)DIV 100;
  ELSE b := r;
  END;
  Ellipse (x0,y0,r,b,c,TRUE) ;
END TrueDisc;

PROCEDURE TrueCircle(x0,y0,r: CARDINAL; c: CARDINAL);
VAR b:CARDINAL;
BEGIN
  IF CoreGraph._width=CGAWidth-1    THEN b := (r*5)DIV 6;
  ELSIF CoreGraph._depth=EGADepth-1 THEN b := (r*73)DIV 100;
  ELSE b := r;
  END;
  Ellipse (x0,y0,r,b,c,FALSE) ;
END TrueCircle;

VAR
    C: PROC;

PROCEDURE GraphTerminate();

BEGIN
    IF (CoreGraph._display_state = TRUE) AND (ModeChanged = TRUE) THEN
      IF SetVideoMode(_DEFAULTMODE) THEN END;
    END;
    C;
END GraphTerminate;

(*%E _XTDDOS *)

(*%F _XTDDOS *)
PROCEDURE GenericGraphMode;
VAR r : CARDINAL;
    BitMap : CARDINAL;
BEGIN
  WHILE GraphI.Virtual DO Lib.Delay(100) END;
  GraphI.CurMode.b := SIZE(GraphI.CurMode);
  GraphI.CurMode.col := 80;
  GraphI.CurMode.row := 25;
  GraphI.CurMode.hres := Width;
  GraphI.CurMode.vres := Depth;
  IF Width<EGAWidth THEN GraphI.CurMode.col := 40 ELSE GraphI.CurMode.col := 80 END;
  IF Depth<VGADepth THEN GraphI.CurMode.row := 25 ELSE GraphI.CurMode.row := 30 END;
  IF    NumColor=0   THEN GraphI.CurMode.color := 0
  ELSIF NumColor<=2  THEN GraphI.CurMode.color := 1
  ELSIF NumColor<=4  THEN GraphI.CurMode.color := 2
  ELSIF NumColor<=16 THEN GraphI.CurMode.color := 4
  ELSE  GraphI.CurMode.color := 8
  END;
  GraphI.CurMode.type := 3;
  r := Vio.SetMode(GraphI.CurMode,0);
  Lib.OSFatalError('Vio.SetMode ',r);
  IF GraphI.IsCGA THEN
    Lib.FarWordFill(GraphI.Buffer[0],2000H,0);
  ELSE
    FOR BitMap := 0 TO GraphI.MaxBitMap DO
      Lib.FarWordFill(GraphI.Buffer[BitMap],SIZE(GraphI.Buffer[BitMap]^) DIV 2,0);
    END;
  END;
  GraphI.RestoreScreen;
  GraphI.GraphM := TRUE ;
END GenericGraphMode;

PROCEDURE CGAPlot(x,y:CARDINAL;c:CARDINAL);
BEGIN
  GraphI.CGAPlot(x,y,c);
END CGAPlot;

PROCEDURE CGAPoint(x,y:CARDINAL) : CARDINAL;
BEGIN
  RETURN GraphI.CGAPoint(x,y);
END CGAPoint;

PROCEDURE CGAHLine ( x,y,x2 : CARDINAL; c:CARDINAL );
BEGIN
  GraphI.CGAHLine(x,y,x2,c);
END CGAHLine;

(* == EGA/VGA specific routines == *)

PROCEDURE EGAPlot( x,y,c : CARDINAL); (* Also VGA *)
VAR
  t:GraphI.BS;
  p,b,s:CARDINAL;
BEGIN
  GraphI.EGAPlot(x,y,c);
END EGAPlot;

PROCEDURE EGAPoint(x,y:CARDINAL) : CARDINAL; (* Also VGA *)
BEGIN
  RETURN GraphI.EGAPoint(x,y);
END EGAPoint;

PROCEDURE EGAHLine ( x,y,x2 : CARDINAL; c:CARDINAL ); (* Also VGA *)
BEGIN
  GraphI.EGAHLine(x,y,x2,c);
END EGAHLine;

PROCEDURE CGAGraphMode;
BEGIN
  GenericGraphMode;
END CGAGraphMode;

PROCEDURE CGATextMode; (* General Text Mode *)
VAR r : CARDINAL;
BEGIN
  WHILE GraphI.Virtual DO Lib.Delay(100) END;
  GraphI.CurMode.b := VSIZE(Vio.MODEINFO.type);
  GraphI.CurMode.type := 1;
  r := Vio.SetMode(GraphI.CurMode,0);
  GraphI.GraphM := FALSE;
END CGATextMode;

PROCEDURE EGAGraphMode; (* Also VGA *)
BEGIN
  GenericGraphMode;
END EGAGraphMode;

PROCEDURE InitVGA ;
BEGIN
  InitEGA ;
  Depth := VGADepth ; (* Width same as EGA *)
END InitVGA ;

PROCEDURE Line(x1,y1,x2,y2: CARDINAL; c: CARDINAL);
BEGIN
  GraphI.Line(x1,y1,x2,y2,c);
END Line;

PROCEDURE Disc(x0,y0,r: CARDINAL; c: CARDINAL);
BEGIN
  GraphI.Disc(x0,y0,r,c);
END Disc;

PROCEDURE Circle(x0,y0,r: CARDINAL; c: CARDINAL);
BEGIN
  GraphI.Circle(x0,y0,r,c);
END Circle;

PROCEDURE TrueCircle(x0,y0,r: CARDINAL; c: CARDINAL);
VAR b:CARDINAL;
BEGIN
  IF Width=CGAWidth    THEN b := (r*5)DIV 6;
  ELSIF Depth=EGADepth THEN b := (r*73)DIV 100;
  ELSE b := r;
  END;
  Ellipse (x0,y0,r,b,c,FALSE) ;
END TrueCircle;

PROCEDURE TrueDisc(x0,y0,r: CARDINAL; c: CARDINAL);
VAR b:CARDINAL;
BEGIN
  IF Width=CGAWidth    THEN b := (r*5)DIV 6;
  ELSIF Depth=EGADepth THEN b := (r*73)DIV 100;
  ELSE b := r;
  END;
  Ellipse (x0,y0,r,b,c,TRUE) ;
END TrueDisc;

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
BEGIN
  GraphI.Polygon(n,px,py,c);
END Polygon;


VAR
  SwapStack  : ARRAY [0..1023] OF BYTE;
  SwapThread : CARDINAL;

PROCEDURE SwapProcess;
VAR r,action,svs : CARDINAL;
BEGIN
  GraphI.Virtual := FALSE;
  Lib.OSFatalError('Dos.SetPrty',
    Dos.SetPrty(2,3,0,SwapThread));
  LOOP
    Lib.OSFatalError('Vio.SavRedrawWait',
      Vio.SavRedrawWait(0,action,0));
    IF GraphI.GraphM THEN
       IF (action=1)AND GraphI.Virtual THEN (* restore *)
         Dos.EnterCritSec;
         GraphI.VideoSel := svs;
         GraphI.Virtual := FALSE;
         GraphI.RestoreScreen;
         Dos.ExitCritSec;
         r := Vio.SetMode(GraphI.CurMode,0);
       ELSIF (action=0)AND NOT GraphI.Virtual THEN (* save *)
         Dos.EnterCritSec;
         svs := GraphI.VideoSel;
         GraphI.SaveScreen;
         GraphI.VideoSel := SYSTEM.Seg(GraphI.Buffer[0]^);
         GraphI.Virtual := TRUE;
         Dos.ExitCritSec;
         Lib.Delay(100); (* wait for pending operations to finish *)
       END;
    END;
  END;
END SwapProcess;


PROCEDURE GraphMode;

BEGIN
    GraphI.G_GraphMode;
END GraphMode;

PROCEDURE TextMode;
BEGIN
    GraphI.G_TextMode;
END TextMode;


PROCEDURE InitCGA ;
VAR
  r           : CARDINAL;
  sl          : Vio.PHYSBUF;
BEGIN
  sl.bufaddr := 0B8000H;
  sl.buflen  := 004000H;
  r := Vio.GetPhysBuf(sl,0);
  GraphI.VideoSel := sl.sel[0];
  Width := CGAWidth ;
  Depth := CGADepth ;
  NumColor := 4 ;
  GraphI.G_TextMode := CGATextMode ;
  GraphI.G_GraphMode := CGAGraphMode ;
  GraphI.G_Plot := CGAPlot ;
  GraphI.G_Point := CGAPoint ;
  GraphI.G_HLine := CGAHLine ;
  IF GraphI.Buffer[0]=FarNIL THEN
    Storage.FarAllocate(GraphI.Buffer[0], GraphI.BitMapSize);
  END;
  GraphI.IsCGA := TRUE;
END InitCGA ;


PROCEDURE InitEGA ;
VAR
  BitMap      : CARDINAL;
  r           : CARDINAL;
  sl          : Vio.PHYSBUF;
BEGIN
  FOR BitMap := 0 TO GraphI.MaxBitMap DO
    IF GraphI.Buffer[BitMap]=FarNIL THEN
      Storage.FarAllocate(GraphI.Buffer[BitMap], GraphI.BitMapSize);
    END;
  END;
  sl.bufaddr := 0A0000H;
  sl.buflen  := 010000H;
  r := Vio.GetPhysBuf(sl,0);
  GraphI.VideoSel := sl.sel[0];
  Width     := EGAWidth ;
  Depth     := EGADepth ;
  Depth := EGADepth;
  NumColor  := 16 ;
  GraphI.G_TextMode  := CGATextMode ;
  GraphI.G_GraphMode := EGAGraphMode ;
  GraphI.G_Plot      := EGAPlot ;
  GraphI.G_Point     := EGAPoint ;
  GraphI.G_HLine     := EGAHLine ;
  GraphI.IsCGA := FALSE;
END InitEGA ;


PROCEDURE Plot(x,y: CARDINAL; Color: CARDINAL);

BEGIN
    GraphI.G_Plot(x, y, Color);
END Plot;


PROCEDURE Point(x,y: CARDINAL) : CARDINAL;

BEGIN
    RETURN GraphI.G_Point(x, y);
END Point;


PROCEDURE HLine(x,y,x2: CARDINAL; FillColor: CARDINAL);

BEGIN
    GraphI.G_HLine(x, y, x2, FillColor);
END HLine;


PROCEDURE NotSupported(Func: ARRAY OF CHAR);

VAR
    Msg: ARRAY [0..79] OF CHAR;
BEGIN
    Str.Concat(Msg, Func, ': Not Supported Under OS2.');
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 0D1H, Msg);
END NotSupported;

PROCEDURE GetVideoConfig(VAR V: VideoConfig);

BEGIN
    NotSupported('GetVideoConfig');
END GetVideoConfig;

PROCEDURE SetClipRgn(x1, y1, x2, y2: CARDINAL);

BEGIN
    NotSupported('SetClipRgn');
END SetClipRgn;

PROCEDURE GetBkColor(): LONGCARD;

BEGIN
    NotSupported('GetBkColor');
    RETURN 0;
END GetBkColor;

PROCEDURE GetFillMask(VAR Mask: FillMaskType);

BEGIN
    NotSupported('GetFillMask');
END GetFillMask;

PROCEDURE GetLinestyle(): CARDINAL;

BEGIN
    NotSupported( 'GetLineStyle');
    RETURN 0;
END GetLinestyle;

PROCEDURE SetBkColor(Color: LONGCARD): LONGCARD;

BEGIN
    NotSupported( 'SetBkColor');
    RETURN 0;
END SetBkColor;

PROCEDURE SetFillMask(Mask: FillMaskType);

BEGIN
    NotSupported( 'SetFillMask');
END SetFillMask;

PROCEDURE SetLinestyle(Mask: CARDINAL);

BEGIN
    NotSupported( 'SetLinestyle');
END SetLinestyle;

PROCEDURE GetTextColor(): CARDINAL;

BEGIN
    NotSupported( 'GetTextColor');
    RETURN 0;
END GetTextColor;

PROCEDURE GetTextPosition(): TextCoords;

BEGIN
    NotSupported( 'GetTextPosition');
    RETURN TextCoords(0,0);
END GetTextPosition;

PROCEDURE DisplayCursor(Mode: BOOLEAN): BOOLEAN;

BEGIN
    NotSupported( 'DisplayCursor');
    RETURN FALSE;
END DisplayCursor;

PROCEDURE SetTextPosition(row, col: CARDINAL): TextCoords;

BEGIN
    NotSupported( 'SetTextPosition');
    RETURN TextCoords(0,0);
END SetTextPosition;

PROCEDURE SetTextWindow(r1, c1, r2, c2: CARDINAL);

BEGIN
    NotSupported( 'SetTextWindow');
END SetTextWindow;

PROCEDURE Wrapon(Opt: BOOLEAN): BOOLEAN;

BEGIN
    NotSupported( 'Wrapon');
    RETURN FALSE;
END Wrapon;

PROCEDURE OutText(Text: ARRAY OF CHAR);

BEGIN
    NotSupported( 'OutText');
END OutText;

PROCEDURE SetVideoMode(Mode: CARDINAL): BOOLEAN;

BEGIN
    NotSupported( 'SetVideoMode');
    RETURN FALSE;
END SetVideoMode;

PROCEDURE SetActivePage(Page: CARDINAL): CARDINAL;

BEGIN
    NotSupported('SetActivePage');
    RETURN 0;
END SetActivePage;

PROCEDURE SetVisualPage(Page: CARDINAL): CARDINAL;

BEGIN
    NotSupported( 'SetVisualPage');
    RETURN 0;
END SetVisualPage;

PROCEDURE ClearScreen(Area: CARDINAL);

BEGIN
    NotSupported( 'ClearScreen');
END ClearScreen;

PROCEDURE Rectangle(x1, y1, x2, y2: CARDINAL; Color: CARDINAL;Fill: BOOLEAN);

BEGIN
    NotSupported( 'Rectangle');
END Rectangle;

PROCEDURE Arc(x1, y1, x2, y2, x3, y3, x4, y4: CARDINAL; Color: CARDINAL);

BEGIN
    NotSupported( 'Arc');
END Arc;

PROCEDURE Pie(x1, y1, x2, y2, x3, y3, x4, y4: CARDINAL; Colr: CARDINAL; Fill: BOOLEAN);

BEGIN
    NotSupported( 'Pie');
END Pie;

PROCEDURE FloodFill(x, y: CARDINAL; Color: CARDINAL; Boundary: CARDINAL);

BEGIN
    NotSupported( 'FloodFill');
END FloodFill;

PROCEDURE StackFill(x, y: CARDINAL; Color: CARDINAL; Boundary: CARDINAL);

BEGIN
    NotSupported( 'StackFill');
END StackFill;

PROCEDURE RemapPalette(Pixel: CARDINAL; Color: LONGCARD): LONGCARD;

BEGIN
    NotSupported( 'RemapPalette');
    RETURN 0;
END RemapPalette;

PROCEDURE RemapAllPalette(Colarray: ARRAY OF LONGCARD): CARDINAL;

BEGIN
    NotSupported( 'RemapAllPalette');
    RETURN 0;
END RemapAllPalette;

PROCEDURE SelectPalette(Palnum: CARDINAL): CARDINAL;

BEGIN
    NotSupported( 'SelectPalette');
    RETURN 0;
END SelectPalette;

PROCEDURE GetImage(x1, y1, x2, y2: CARDINAL; Buffer: ADDRESS);

BEGIN
    NotSupported( 'GetImage');
END GetImage;

PROCEDURE PutImage(x, y: CARDINAL; Buffer: ADDRESS; Action: CARDINAL);

BEGIN
    NotSupported( 'PutImage');
END PutImage;

PROCEDURE ImageSize(x1, y1, x2, y2: CARDINAL): LONGCARD;

BEGIN
    NotSupported( 'ImageSize');
    RETURN 0;
END ImageSize;

PROCEDURE Cube(top: BOOLEAN; x1, y1, x2, y2, depth: CARDINAL; Color: CARDINAL; Fill: BOOLEAN);

BEGIN
    NotSupported( 'Cube');
END Cube;

PROCEDURE InitHerc();

BEGIN
    NotSupported( 'InitHerc');
END InitHerc;

PROCEDURE InitGraph();

BEGIN
    NotSupported( 'InitGraph');
END InitGraph;

PROCEDURE SetTextColor(Col: CARDINAL): CARDINAL;

BEGIN
    NotSupported( 'SetTextColor');
    RETURN 0;
END SetTextColor;

PROCEDURE Init;
VAR
  i,r : CARDINAL;
BEGIN
  GraphI.GraphM := FALSE;
  r := Dos.CreateThread(Dos.THREAD(SwapProcess),SwapThread,FarADR(SwapStack[HIGH(SwapStack)]));
  FOR i := 0 TO 4 DO
    GraphI.Buffer[i] := FarNIL;
  END;
  InitCGA;
END Init;

(*%E _XTDDOS *)

BEGIN (*Initialization*)
(*%T _XTDDOS *)
 (*%T _XTD *)
    TSXLIB.InitInt10;
 (*%E *)
 (*%T AutoDetect *)
    InitGraph();
 (*%E *)
 (*%F AutoDetect *)
    InitCGA;
 (*%E *)
    Lib.Terminate(GraphTerminate, C);
    FillState:=_GFILLINTERIOR;
    ModeChanged := FALSE;
    EGATable := EGATableType( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
(*%E *)
(*%F _XTDDOS *)
 (*%F _fcall *)
  IO.WrStr('OS/2 Graphics Not Supported In This Model.');
  IO.WrLn;
  HALT;
 (*%E *)
  Init;
(*%E _XTDDOS *)
END Graph.
