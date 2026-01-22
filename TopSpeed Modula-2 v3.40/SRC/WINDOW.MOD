(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  WINDOW.MOD - Clipping text windows                                      *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*# data(seg_name => null) *)
(*%E *)
(*# module(implementation=>off) *)
(*# call(o_a_copy=>off) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE Window;

(*%F _OS2 *)
IMPORT SYSTEM, Str, Lib, IO, CoreSig;
(*%E *)
(*%T _OS2 *)
IMPORT SYSTEM, Str, Lib, Vio, Dos, IO, CoreSig;
(*%E *)
(*%T _mthread *)
IMPORT Process;
(*%E *)
FROM Storage IMPORT ALLOCATE,DEALLOCATE;

TYPE
  UseListPtr  = POINTER TO UseListLink;
  UseListLink = RECORD
                  Next : UseListPtr;
                  Proc : ADDRESS;
                  Wind : WinType;
                END;
VAR
(*%T _mthread *)
  Lock,Unlock  : LockProc;
(*%E *)


CONST
  GuardConst = 4A4EH;


  PROCEDURE CheckWindow(W:WinType);
    BEGIN
      IF W^.Guard - Seg(W^) # GuardConst THEN
        Lib.RunTimeError(CoreSig._FatalErrorPos(),30H,'Invalid Window');
      END; (*IF*)
    END CheckWindow;

PROCEDURE  ClipFrame ( W : WinType );
VAR
  i : CARDINAL;
BEGIN
  WITH W^ DO
    IF WDef.FrameOn THEN i := 1 ELSE i := 0 END;
    IF XA < WDef.X1+i THEN
      XA := WDef.X1+i
    ELSIF XA > WDef.X2-i THEN
      XA := WDef.X2-i
    END;
    IF XB > WDef.X2-i THEN
      XB := WDef.X2-i
    ELSIF XB < WDef.X1+i THEN
      XB := WDef.X1+i
    END;
    IF YA < WDef.Y1+i THEN
      YA := WDef.Y1+i
    ELSIF YA > WDef.Y2-i THEN
      YA := WDef.Y2-i
    END;
    IF YB > WDef.Y2-i THEN
      YB := WDef.Y2-i
    ELSIF YB < WDef.Y1+i THEN
      YB := WDef.Y1+i
    END;
    Width := XB-XA+1; Depth := YB-YA+1;
  END;
END ClipFrame;

PROCEDURE ClipXY ( W : WinType; VAR X,Y : RelCoord );
VAR
  mw,md : CARDINAL;
BEGIN
  WITH W^ DO
    mw := Width; md := Depth;
    IF WDef.FrameOn AND NOT WDef.WrapOn THEN
      INC(md); INC(mw)
    ELSE
      IF X=0 THEN X := 1 END;
      IF Y=0 THEN Y := 1 END;
    END;
    IF X>mw THEN X := mw END;
    IF Y>md THEN Y := md END;
  END;
END ClipXY;


PROCEDURE  BufferSpaceFill ( W : WinType; pos : CARDINAL; len : CARDINAL );
BEGIN
  WITH W^ DO
    IF IsPalette THEN
      Lib.WordFill(ADR(Buffer^[pos]),len,32
               +VAL(CARDINAL,CurPalColor)*256);
    ELSE
      Lib.WordFill(ADR(Buffer^[pos]),len,32+
               ORD(WDef.Foreground)*256+ORD(WDef.Background)*4096);
    END;
  END;
END BufferSpaceFill;


  PROCEDURE  CurWin () : WinType;
    (* Returns The current window being used for output for this process *)
    (* If no window assigned by Use then returns Top.                    *)
    (* NB Locks window system and leaves locked if _mthread set.         *)
    VAR
      u                 : UseListPtr;
      p                 : ADDRESS;
    BEGIN
(*%T _mthread *)
        Lock();
(*%E *)
      IF CoreWind._multip THEN
(*%T _mthread *)
        p := SYSTEM.CurrentProcess();
(*%E *)
(*%F _mthread *)
        p := NIL;
(*%E *)
        u := UseListPtr(CoreWind._uselist)^.Next;
        LOOP
          IF u = NIL THEN
            RETURN WinType(CoreWind._windowstack); (* Top() *)
          ELSIF p = u^.Proc THEN
            RETURN u^.Wind;
          END; (*IF*)
          u := u^.Next;
        END; (*LOOP*)
      END; (*IF*)
      u := UseListPtr(CoreWind._uselist)^.Next;
      IF u = NIL THEN
        RETURN WinType(CoreWind._windowstack); (* Top() *)
      END; (*IF*)
      RETURN u^.Wind;
    END CurWin;

(*%F _OS2 *)
PROCEDURE  ResetCursor;
VAR
  R    : SYSTEM.Registers;
  mode : CARDINAL;
BEGIN
  IF (CoreWind._cursorstack = NIL) OR
     ObscuredAt(WinType(CoreWind._cursorstack),WinType(CoreWind._cursorstack)^.CurrentX,WinType(CoreWind._cursorstack)^.CurrentY) THEN
    mode := 2000H;
  ELSE
    WITH WinType(CoreWind._cursorstack)^ DO
      WITH R DO
        AH := 2;
        BH := SHORTCARD(CoreWind._activepage());
        DL := SHORTCARD(XA+CurrentX-1);
        DH := SHORTCARD(YA+CurrentY-1);
      END;
      Lib.Intr(R,10H);
    END;
    mode := CoreWind._cursorlines;
  END;
  R.AH := 1;
  R.CX := mode;
  Lib.Intr(R,10H);
END ResetCursor;
(*%E *)

(*%T _OS2 *)
VAR
  CursorInfo   : Vio.CURSORINFO;
  RealMode     : BOOLEAN;

PROCEDURE  ResetCursor;
VAR   r  : CARDINAL;
BEGIN
  IF (CoreWind._cursorstack = NIL) OR
     ObscuredAt(WinType(CoreWind._cursorstack),WinType(CoreWind._cursorstack)^.CurrentX,WinType(CoreWind._cursorstack)^.CurrentY) THEN
     CursorInfo.attr := MAX(CARDINAL);
  ELSE
    WITH WinType(CoreWind._cursorstack)^ DO
      r := Vio.SetCurPos(YA+CurrentY-1,XA+CurrentX-1,0 );
    END;
     CursorInfo.attr := 0;
  END;
  r := Vio.SetCurType( CursorInfo,0);
END ResetCursor;
(*%E *)

PROCEDURE  UnlinkCursor ( W : WinType );
VAR
  w : WinType;
BEGIN
  w := WinType(CoreWind._cursorstack);
  IF w = W THEN CoreWind._cursorstack := w^.CursorChain END;
  LOOP
    IF w = NIL THEN RETURN END;
    IF w^.CursorChain = W THEN
      w^.CursorChain := W^.CursorChain;
      RETURN;
    END;
    w := w^.CursorChain;
  END;
END UnlinkCursor;

(* ------------------------- *)
(* Cursor Control            *)
(* ------------------------- *)



PROCEDURE  CursorOn;
VAR
  w,cw : WinType;
BEGIN
  cw := CurWin();
  UnlinkCursor(cw);
  cw^.WDef.CursorOn := TRUE;
  IF NOT cw^.WDef.Hidden THEN
    cw^.CursorChain := WinType(CoreWind._cursorstack);
    CoreWind._cursorstack := cw;
  END;
  ResetCursor;
(*%T _mthread *)
  Unlock();
(*%E *)
END CursorOn;

PROCEDURE  CursorOff;
VAR
  w,cw : WinType;
BEGIN
  cw := CurWin();
  UnlinkCursor(cw);
  cw^.WDef.CursorOn := FALSE;
  ResetCursor;
(*%T _mthread *)
  Unlock();
(*%E *)
END CursorOff;

(* ------------------------- *)
(* Window creation           *)
(* ------------------------- *)


PROCEDURE  MakeWindow ( VAR WD : WinDef ) : WinType;

(*
  Creates a new Window descriptor
  The size is Inclusive of frame if needed
  does not allocate buffer
*)
VAR W : WinType; min : CARDINAL;
BEGIN
  NEW(W);
  WITH W^ DO
    WITH WD DO
      IF X2 >= ScreenWidth THEN X2:=ScreenWidth-1 END;
      IF Y2 >= CurrentScreenDepth THEN Y2:=CurrentScreenDepth-1 END;
      IF WD.FrameOn THEN min := 2 ELSE min := 0 END;
      IF (X1+min>X2) THEN X2 := X1+min END;
      IF (Y1+min>Y2) THEN Y2 := Y1+min END;
      XA  := X1; YA  := Y1; XB := X2; YB := Y2;
      Width := X2-X1+1; Depth := Y2-Y1+1;
    END;
    WDef := WD;
    OWidth := Width; ODepth := Depth;
    CurrentX   := 1;
    CurrentY   := 1;
    Next       := NIL;
    Buffer     := NIL;
    UserRecord  := NIL;
    IsPalette   := FALSE;
    CurPalColor := NormalPaletteColor;
    TMode       := NoTitle;
    Guard       := GuardConst+CARDINAL(Seg(W^));
    CursorChain := NIL;
    Title       := NIL;
  END;
  ClipFrame(W);
  RETURN W;
END MakeWindow;

PROCEDURE  Open ( WD : WinDef ) : WinType;
(*
  Opens a window on the screen ready for use
*)
VAR
  W : WinType;
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  W := MakeWindow (WD);
  WITH W^ DO
    ALLOCATE ( Buffer,OWidth*ODepth*2);
    BufferSpaceFill(W,0,OWidth*ODepth);
    IF WD.FrameOn THEN
      SetFrame(W,WDef.FrameDef,WDef.FrameFore,WDef.FrameBack);
    END;
  END;
  IF WD.Hidden THEN
    Use ( W )
  ELSE
    PutOnTop ( W )
  END;
(*%T _mthread *)
  Unlock();
(*%E *)
  RETURN W;
END Open;


(* ------------------------- *)
(* Window stack manipulation *)
(* and screen redraw         *)
(* ------------------------- *)



PROCEDURE  Use ( W : WinType );
(*
   Causes all subsequent output (by the current process)
   to appear in the specified Window
   NB does not have to be Top Window (or in fact on the screen at all)
   UseListPtr(CoreWind._uselist) is the MRU window
*)
VAR
  p  : ADDRESS;
  u  : UseListPtr;
  up : UseListPtr;
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  CheckWindow(W);
(*%T _mthread *)
  p  := SYSTEM.CurrentProcess();
(*%E *)
(*%F _mthread *)
  p := NIL;
(*%E *)
  up := UseListPtr(CoreWind._uselist);
  u  := up^.Next;
  LOOP
    IF u = NIL THEN NEW(u); u^.Proc := p; EXIT END;
    IF p = u^.Proc THEN up^.Next := u^.Next; EXIT END;
    up := u; u := u^.Next;
  END;
  u^.Next := UseListPtr(CoreWind._uselist)^.Next;
  UseListPtr(CoreWind._uselist)^.Next := u;
  u^.Wind := W;
(*%T _mthread *)
  Unlock();
(*%E *)
END Use;

PROCEDURE  TakeOffStack ( W : WinType ); (* Private *)
VAR pw : WinType;
BEGIN
  IF W = WinType(CoreWind._windowstack) THEN
    CoreWind._windowstack := W^.Next;
  ELSE
    pw := WinType(CoreWind._windowstack);
    IF W # pw THEN
      LOOP
        IF (pw = NIL) THEN EXIT END;
        IF (pw^.Next = W) THEN pw^.Next := W^.Next; EXIT END;
        pw := pw^.Next;
      END;
    END;
  END;
  W^.Next := NIL;
END TakeOffStack;



PROCEDURE  UpdateScreen ( W : WinType; X,Y : AbsCoord; Len : CARDINAL );
(* Updates the screen from the window buffer *)
VAR
  NextLen,
  NextX : AbsCoord;
  w     : WinType;
  oxa,oxb,ax,bx : AbsCoord;
  buff  : ARRAY[0..ScreenWidth-1] OF CARDINAL;
  a     : ADDRESS;
BEGIN
  IF W^.WDef.Hidden THEN RETURN END;
  WHILE Len#0 DO
    (* adjust co ordinates for crossing windows *)
    NextLen := 0;
    w := WinType(CoreWind._windowstack);
    ax := X; bx := X+Len-1;
    LOOP
      IF (w = W)OR(w=NIL) THEN EXIT END;
      WITH w^ DO
        IF (Y>=WDef.Y1) AND (Y<=WDef.Y2) THEN
          oxa := WDef.X1; oxb := WDef.X2;
          IF (ax>=oxa) AND (bx<=oxb) THEN    (* wiped out *)
            ax := bx+1; EXIT;
          ELSIF (ax<=oxb) AND (bx>=oxa) THEN (* some interaction *)
            IF (ax<oxa) AND (bx>oxb) THEN    (* cut into two *)
              bx := oxa-1;
              NextX := oxb+1;
              NextLen := X+Len-NextX;
            ELSIF (bx>oxb) THEN (* left edge cut off *)
              ax := oxb+1;
            ELSIF (ax<oxa) THEN (* right edge cut off *)
              bx := oxa-1;
            END;
          END;
        END;
        w := Next;
      END;
    END;
    Len := bx-ax+1;
    IF Len # 0 THEN
      WITH W^ DO
        a := ADR(Buffer^[(ax-WDef.X1)+(Y-WDef.Y1)*OWidth]);
        IF IsPalette THEN
          CoreWind._palxlat(ADR(buff),a,Len,ADR(PalAttr));
          a := ADR(buff);
        END;
        CoreWind._buffertoscreen ( ax,Y,a,Len);
      END;
    END;
    X   := NextX;
    Len := NextLen;
  END;
END UpdateScreen;


PROCEDURE  RedrawSection ( W : WinType;
                                 X1,Y1,X2,Y2 : AbsCoord ); (* Private *)
(* redraws rectangular portion of the window from the buffer *)
VAR
  Y : AbsCoord;
BEGIN
  FOR Y := Y1 TO Y2 DO
    UpdateScreen(W,X1,Y,X2-X1+1);
  END;
END RedrawSection;

PROCEDURE  RedrawWindow ( W : WinType ); (* Private *)
BEGIN
  WITH W^ DO
    RedrawSection ( W,WDef.X1,WDef.Y1,WDef.X2,WDef.Y2 );
  END;
END RedrawWindow;

PROCEDURE  RedrawWindowPane ( W : WinType ); (* Private *)
BEGIN
  WITH W^ DO
    RedrawSection ( W,XA,YA,XB,YB );
  END;
END RedrawWindowPane;


PROCEDURE  DisplayBeneath ( W : WinType; NW : WinType ); (* Private *)
(* Re-displays windows Obscured by W from NW *)
VAR
  x1,x2,y1,y2 : AbsCoord;
BEGIN
  WITH W^ DO
    WHILE NW#NIL DO
      IF ((WDef.X2>=NW^.WDef.X1)AND(NW^.WDef.X2>=WDef.X1) AND
          (WDef.Y2>=NW^.WDef.Y1)AND(NW^.WDef.Y2>=WDef.Y1)) THEN (* windows cross *)
         (* calculate Intersection *)
         IF WDef.X1>NW^.WDef.X1 THEN
           x1 := WDef.X1
         ELSE
           x1 := NW^.WDef.X1
         END;
         IF WDef.X2<NW^.WDef.X2 THEN
           x2 := WDef.X2
         ELSE
           x2 := NW^.WDef.X2
         END;
         IF WDef.Y1>NW^.WDef.Y1 THEN
           y1 := WDef.Y1
         ELSE
           y1 := NW^.WDef.Y1
         END;
         IF WDef.Y2<NW^.WDef.Y2 THEN
           y2 := WDef.Y2
         ELSE
           y2 := NW^.WDef.Y2
         END;
         RedrawSection (NW, x1,y1,x2,y2 );
      END;
      NW := NW^.Next;
    END;
  END;
END DisplayBeneath;




PROCEDURE  PutOnTop ( W : WinType );
(*
   Puts the specified window on the top of the window stack
   Ensuring that it is fully visible.
   If this results in other windows becoming obscured then a buffer
   is allocated for each of these windows.
   All otherwise undirected output (ie with no Use) will appear
   within this window.
*)

BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  CheckWindow(W);
  IF W # WinType(CoreWind._windowstack) THEN
    TakeOffStack( W );
    W^.Next     := WinType(CoreWind._windowstack);
    CoreWind._windowstack := W;
    WITH W^ DO
      WDef.Hidden := FALSE;
      RedrawWindow ( W );
      IF WDef.CursorOn THEN
        Use ( W );
        CursorOn;
      END;
    END;
  END;
  Use ( W );
  ResetCursor;
(*%T _mthread *)
  Unlock();
(*%E *)
END PutOnTop;


PROCEDURE  Hide ( W : WinType );
(*
    Removes window from the Window stack and also the screen
    Placing the windows contents in a buffer for possible re-display later
    Uncovers obscured windows
*)
VAR
  p : WinType;
  w : WinType;
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  CheckWindow(W);
  WITH W^ DO
    IF NOT WDef.Hidden THEN
      w := W^.Next;
      TakeOffStack ( W );
      DisplayBeneath ( W, w );
      IF WDef.CursorOn THEN CursorOff; WDef.CursorOn := TRUE; END;
      WDef.Hidden := TRUE;
    END;
  END;
  ResetCursor;
(*%T _mthread *)
  Unlock();
(*%E *)
END Hide;

PROCEDURE  PutBeneath ( W : WinType; WA : WinType );
(*
    Puts window W beneath window WA
*)
VAR
  p : WinType;
  w : WinType;
BEGIN
  Hide(W);
(*%T _mthread *)
  Lock();
(*%E *)
  CheckWindow(WA);
  WITH WA^ DO
    IF NOT WDef.Hidden THEN
      w := Next;
      Next := W;
      W^.Next := w;
      W^.WDef.Hidden := FALSE;
      RedrawWindow ( W );
    END;
  END;
  ResetCursor;
(*%T _mthread *)
  Unlock();
(*%E *)
END PutBeneath;

PROCEDURE  SnapShot;
(* Updates the Window buffer from the screen *)
(* only works with non palette windows       *)
VAR
  W : WinType;
  y : CARDINAL;
  p : CARDINAL;
BEGIN
  W := CurWin();
  WITH W^ DO
    WITH WDef DO
      IF NOT IsPalette THEN
        p := 0;
        FOR y := Y1 TO Y2 DO
          CoreWind._screentobuffer(X1,y,ADR(Buffer^[p]),OWidth);
          INC(p,OWidth);
        END;
      END;
    END;
  END;
(*%T _mthread *)
  Unlock();
(*%E *)
END SnapShot;


(* ------------------------- *)
(* Window disposal           *)
(* ------------------------- *)

PROCEDURE  DisposeTitle ( W : WinType );
BEGIN
  WITH W^ DO
    IF TMode # NoTitle THEN
      DEALLOCATE(Title,Str.Length(Title^)+1);
      TMode := NoTitle;
    END;
  END;
END DisposeTitle;



PROCEDURE  Close ( VAR W : WinType );
(*
     removes the specified window from the screen
     deletes window descriptor and
     de-allocates any buffers previously allocated.
*)
VAR
  w       : WinType;
  u,up,un : UseListPtr;
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  Hide ( W );
  TakeOffStack (W);
  UnlinkCursor(W);
  WITH W^ DO
    IF (Buffer # NIL) THEN DEALLOCATE(Buffer,OWidth * ODepth * 2); END;
  END;
  up := UseListPtr(CoreWind._uselist);
  u := up^.Next;
  WHILE (u#NIL) DO
    un := u^.Next;
    IF (u^.Wind = W) THEN
      up^.Next := un;
      DISPOSE(u);
    ELSE
      up := u;
    END;
    u := un;
  END;
  DisposeTitle(W);
  W^.Guard := GuardConst; (* Invalidate guard *)
  DISPOSE(W);
(*%T _mthread *)
  Unlock();
(*%E *)
END Close;




PROCEDURE  Used () : WinType;
(*
    Returns The current window being used for output for this process
    If no window assigned by Use then returns Top
*)
VAR
  w : WinType;
BEGIN
  w := CurWin();
(*%T _mthread *)
  Unlock();
(*%E *)
  RETURN w;
END Used;

PROCEDURE  Top () : WinType;
(*
    Returns The current top Window
*)
VAR w : WinType;
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  w := WinType(CoreWind._windowstack);
(*%T _mthread *)
  Unlock();
(*%E *)
  RETURN w;
END Top;



PROCEDURE  At (X,Y : AbsCoord) : WinType;
(*
    Returns the window displayed at the absolute position X,Y
*)
VAR
  W : WinType;
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  W := WinType(CoreWind._windowstack);
  LOOP
    IF W = NIL THEN EXIT END;
    WITH W^ DO
      IF (Y >= WDef.Y1) AND (Y <= WDef.Y2) AND
         (X >= WDef.X1) AND (X <= WDef.X2) THEN
        EXIT
      END;
      W := Next;
    END;
  END;
(*%T _mthread *)
  Unlock();
(*%E *)
  RETURN W;
END At;

PROCEDURE  ObscuredAt (W : WinType; X,Y : RelCoord ) : BOOLEAN;
(*
    Returns if the specified window is obscured at the specified position
*)
VAR
  b : BOOLEAN;
  w : WinType;
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  CheckWindow(W);
  WITH W^ DO
    IF WDef.Hidden THEN
      b:= TRUE;
    ELSE
      INC(X,XA-1); INC(Y,YA-1);
      w := WinType(CoreWind._windowstack);
      LOOP
        IF w = W   THEN b := FALSE; EXIT END;
        IF w = NIL THEN b := TRUE;  EXIT END;
        WITH w^ DO
          IF (Y>=WDef.Y1) AND (Y<=WDef.Y2) AND
             (X>=WDef.X1) AND (X<=WDef.X2) THEN
            b := TRUE;
            EXIT
          END;
          w := Next;
        END;
      END;
    END;
  END;
(*%T _mthread *)
  Unlock();
(*%E *)
  RETURN b;
END ObscuredAt;



PROCEDURE  WindowWrite ( W     : WinType;
                               x,y   : RelCoord;
                               Len   : CARDINAL;
                               str   : ADDRESS;
                               frame : BOOLEAN ); (* Private *)
VAR
  Attr : CARDINAL;
  X,Y  : AbsCoord;
BEGIN
  IF Len>0 THEN
    WITH W^ DO
      IF IsPalette THEN
        IF frame THEN
          Attr := VAL(CARDINAL,FramePaletteColor);
        ELSE
          Attr := VAL(CARDINAL,CurPalColor);
        END;
      ELSIF frame THEN
        Attr := ORD(WDef.FrameFore)+ORD(WDef.FrameBack)*16;
      ELSE
        Attr := ORD(WDef.Foreground)+ORD(WDef.Background)*16;
      END;
      X := x+XA-1; Y := y+YA-1;
      IF Len+X-1 > WDef.X2 THEN Len := WDef.X2+1-X END;
      CoreWind._bufferwrite (ADR(Buffer^[X-WDef.X1+(Y-WDef.Y1)*OWidth]),str,Len,Attr);
      UpdateScreen(W,X,Y,Len);
    END;
  END;
END WindowWrite;

PROCEDURE  DrawFrame ( W : WinType );
VAR
  s      : ARRAY[0..81] OF CHAR;
  w,l,tl : CARDINAL;
  i      : CARDINAL;

  PROCEDURE PutTitle ( mode : CARDINAL; row : CARDINAL );
  VAR
    i,j : CARDINAL;
  BEGIN
    WITH W^ DO
      CASE mode OF
        0 : i := 1                     |
        1 : i := (Width-tl) DIV 2 + 1; |
        2 : i := Width+1-tl            |
      ELSE
        i := MAX(CARDINAL);
      END;
      j := 0;
      WHILE (i<=Width)AND(j<tl) DO
        s[i] := Title^[j]; INC(i); INC(j)
      END;
      WindowWrite (W,0,row,OWidth,ADR(s),TRUE);
    END;
  END PutTitle;


BEGIN
  WITH W^ DO
    IF NOT WDef.FrameOn THEN
      IF (OWidth<3)OR(ODepth<3) THEN RETURN END; (* No Room *)
      WDef.FrameOn := TRUE;
      ClipFrame(W);
      ResetCursor;
    END;
    s[0] := WDef.FrameDef[0];
    Lib.Fill(ADR(s[1]),Width,WDef.FrameDef[1]);
    s[Width+1] := WDef.FrameDef[2];
    IF TMode # NoTitle THEN
      tl := Str.Length(Title^);
      IF tl>Width THEN tl := Width END;
    END;
    PutTitle(ORD(TMode-LeftUpperTitle),0);
    (* Sides *)
    FOR i := 1 TO Depth DO
      WindowWrite(W,0,i,1,ADR(WDef.FrameDef[3]),TRUE);
      WindowWrite(W,Width+1,i,1,ADR(WDef.FrameDef[4]),TRUE);
    END;
    s[0] := WDef.FrameDef[5];
    Lib.Fill(ADR(s[1]),Width,WDef.FrameDef[6]);
    s[Width+1] := WDef.FrameDef[7];
    PutTitle(ORD(TMode-LeftLowerTitle),Depth+1);
  END;
END DrawFrame;



PROCEDURE   SetFrame ( W     : WinType;
                             Frame : FrameStr;
                             Fore, Back  : Color );
(*
   Put a frame around the specified window
   With Title String and border definition (see above)
   having specified fore/background colours for the border
*)
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  CheckWindow(W);
  WITH W^ DO
    WDef.FrameDef := Frame;
    WDef.FrameFore := Fore;
    WDef.FrameBack := Back;
  END;
  DrawFrame(W);
(*%T _mthread *)
  Unlock();
(*%E *)
END SetFrame;



PROCEDURE  MergeWindows ( s,d : WinType );
(* slightly complicated procedure to merge two windows
   s is new (hidden) window
   d is old window to be merged into
*)
VAR
  w : WinDescriptor;
  r,wd        : CARDINAL;
  sw,sd,so,sp : CARDINAL;
  dw,dd,do,dp : CARDINAL;
BEGIN
  s^.CurrentX    := d^.CurrentX;
  s^.CurrentY    := d^.CurrentY;
  s^.CursorChain := d^.CursorChain;
  s^.UserRecord  := d^.UserRecord;
  s^.CurPalColor := d^.CurPalColor;
  s^.Title       := d^.Title;
  s^.TMode       := d^.TMode;
  d^.TMode       := NoTitle;
  d^.WDef.CursorOn  := FALSE;
  w := d^; d^ := s^; s^ := w;
  WITH s^ DO
    sw := OWidth; sd := ODepth;
    IF WDef.FrameOn THEN
      DEC(sw,2); DEC(sd,2);
      sp := (OWidth+1);
    ELSE
      sp := 0;
    END;
    Guard := GuardConst+CARDINAL(Seg(s^));
  END;
  WITH d^ DO
    dw := OWidth; dd := ODepth;
    IF WDef.FrameOn THEN
      DEC(dw,2); DEC(dd,2);
      dp := OWidth+1;
    ELSE
      dp := 0;
    END;
    Guard := GuardConst+CARDINAL(Seg(d^));
  END;
  IF sd < dd THEN wd := sd ELSE wd := dd END;
  FOR r := 0 TO wd-1 DO
    IF sw>=dw THEN
      Lib.WordMove(ADR(s^.Buffer^[sp]),ADR(d^.Buffer^[dp]),dw);
    ELSE
      Lib.WordMove(ADR(s^.Buffer^[sp]),ADR(d^.Buffer^[dp]),sw);
      BufferSpaceFill(d,dp+sw,dw-sw);
    END;
    INC(sp,s^.OWidth); INC(dp,d^.OWidth);
  END;
  (* now fill rest *)
  IF wd<dd THEN
    FOR r := wd TO dd-1 DO
      BufferSpaceFill(d,dp,dw);
      INC(dp,d^.OWidth);
    END
  END;
  IF d^.WDef.FrameOn THEN DrawFrame(d) END;
  IF NOT s^.WDef.Hidden THEN
    d^.Next := s;
    d^.WDef.Hidden := FALSE;
    RedrawWindow(d);
  END;
  Close(s);
END MergeWindows;


PROCEDURE  IGotoXY ( W : WinType; X,Y : RelCoord );
(*
    Sets the current X Y position of the pane currently being used
*)
BEGIN
  WITH W^ DO CurrentX := X; CurrentY := Y END;
  IF WinType(CoreWind._cursorstack) = W THEN ResetCursor END;
END IGotoXY;




(* ------------------------- *)
(* Palette procedures        *)
(* ------------------------- *)



PROCEDURE  GetPal ( W : WinType; VAR Pal : PaletteDef );
VAR
  i : PaletteRange;
BEGIN
  CheckWindow(W);
  WITH W^ DO
    FOR i := 0 TO PaletteMax DO
      Pal[i].Fore := Color(PalAttr[i] MOD 16);
      Pal[i].Back := Color(PalAttr[i] DIV 16);
    END;
  END;
END GetPal;

PROCEDURE  SetPal ( W : WinType; VAR Pal : PaletteDef );
VAR
  i : PaletteRange;
BEGIN
  CheckWindow(W);
  WITH W^ DO
    FOR i := 0 TO PaletteMax DO
      PalAttr[i] := VAL(SHORTCARD,ORD(Pal[i].Fore)+ORD(Pal[i].Back)*16);
    END;
    IsPalette := TRUE;
  END;
END SetPal;




PROCEDURE  PaletteOpen(WD: WinDef; Pal: PaletteDef) : WinType;
(*
  Opens a window on the screen ready for use
*)
VAR
  W : WinType;
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  W := MakeWindow (WD);
  SetPal(W,Pal);
  WITH W^ DO
    ALLOCATE ( Buffer,OWidth*ODepth*2);
    BufferSpaceFill(W,0,OWidth*ODepth);
    IF WD.FrameOn THEN
      SetFrame(W,WDef.FrameDef,WDef.FrameFore,WDef.FrameBack);
    END;
  END;
  IF WD.Hidden THEN
    Use ( W )
  ELSE
    PutOnTop ( W )
  END;
(*%T _mthread *)
  Unlock();
(*%E *)
  RETURN W;
END PaletteOpen;


PROCEDURE  SetPaletteColor ( c : PaletteRange );
VAR
  W : WinType;
BEGIN
  W := CurWin();
  W^.CurPalColor := c;
(*%T _mthread *)
  Unlock();
(*%E *)
END SetPaletteColor;


PROCEDURE  PaletteColor() : PaletteRange;
VAR
  W : WinType;
BEGIN
  W := CurWin();
(*%T _mthread *)
  Unlock();
(*%E *)
  RETURN W^.CurPalColor;
END PaletteColor;

PROCEDURE  SetPalette(W: WinType; Pal: PaletteDef);
(*
   Changes the Palette of the specified window,
   redisplaying the changed colors
*)
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  SetPal(W,Pal);
  RedrawWindow(W);
(*%T _mthread *)
  Unlock();
(*%E *)
END SetPalette;


PROCEDURE  PaletteColorUsed(W: WinType; pc: PaletteRange) : BOOLEAN;
(*
   Returns if color in use anywhere in the window
*)
VAR
  p  : CARDINAL;
  l  : CARDINAL;
  m  : CARDINAL;
  ba : POINTER TO ARRAY[0..MAX(CARDINAL)-1] OF SHORTCARD;
BEGIN
  CheckWindow(W);
  WITH W^ DO
    ba := ADR(Buffer^);
    p  := 0;
    m  := OWidth*ODepth*2;
    LOOP
      l := m-p;
      p := p+Lib.ScanR(ADR(ba^[p]),l,pc);
      IF p >= m THEN RETURN FALSE END;
      IF ODD(p) THEN RETURN TRUE END;
      INC(p);
    END;
  END;
END PaletteColorUsed;



(* ------------------------- *)
(* Move resize procedure     *)
(* ------------------------- *)




  PROCEDURE Change(W:WinType;X1,Y1,X2,Y2:AbsCoord);
    (* Changes the size and/or position of the specified window The      *)
    (* contents of the window will be moved with it                      *)
    VAR
      nw                : WinType;
      wd                : WinDef;
      pal               : PaletteDef;
      save              : WinType;
      min               : CARDINAL;
    BEGIN
      CheckWindow(W);
      save := CurWin();
      WITH W^ DO
        IF X2 >= ScreenWidth THEN
          X2 := ScreenWidth - 1;
        END; (*IF*)
        IF Y2 >= CurrentScreenDepth THEN
          Y2 := CurrentScreenDepth - 1;
        END; (*IF*)
        wd := WDef;
        IF wd.FrameOn THEN
          min := 2;
        ELSE
          min := 0;
        END; (*IF*)
        IF (X1 + min > X2) OR (Y1 + min > Y2) THEN
(*%T _mthread *)
          Unlock();
(*%E *)
          RETURN;
        END; (*IF*)
        wd.X1 := X1;
        wd.Y1 := Y1;
        wd.X2 := X2;
        wd.Y2 := Y2;
        wd.Hidden := TRUE;
        IF IsPalette THEN
          GetPal(W,pal);
          nw := PaletteOpen(wd,pal);
        ELSE
          nw := Open(wd);
        END; (*IF*)
        MergeWindows(nw,W);
        ClipFrame (W);
        IF CurrentX > Width THEN
          CurrentX := Width;
        END; (*IF*)
        IF CurrentY > Depth THEN
          CurrentY := Depth;
        END; (*IF*)
        ResetCursor;
      END; (*WITH*)
      Use(save); (* restore used window *)
(*%T _mthread *)
      Unlock();
(*%E *)
    END Change;

(* ------------------------- *)
(* Multi process support     *)
(* ------------------------- *)

PROCEDURE  NullProc;
BEGIN
END NullProc;

PROCEDURE  SetProcessLocks ( LockProc,UnlockProc : LockProc );
BEGIN
(*%T _mthread *)
  Lock   := LockProc;
  Unlock := UnlockProc;
  CoreWind._multip := TRUE;
(*%E *)
END SetProcessLocks;

(* ------------------------- *)
(* Window output             *)
(* ------------------------- *)


PROCEDURE  DeleteLine ( W : WinType; Y : RelCoord );
VAR
  r,p : CARDINAL;
BEGIN
  CheckWindow(W);
  WITH W^ DO
    p := XA-WDef.X1+(YA-WDef.Y1+Y-1)*OWidth;
    FOR r := Y TO Depth-1 DO
      Lib.Move(ADR(Buffer^[p+OWidth]),ADR(Buffer^[p]),Width*2);
      INC(p,OWidth);
    END;
    BufferSpaceFill(W,p,Width);
    RedrawSection ( W,XA,Y+YA-1,XB,YB );
  END;
END DeleteLine;



PROCEDURE  Clear;
(*
  clears the current window
*)
VAR
  r,p : CARDINAL;
  W   : WinType;
BEGIN
  W := CurWin();
  WITH W^ DO
    p := XA-WDef.X1+(YA-WDef.Y1)*OWidth;
    FOR r := 1 TO Depth DO
      BufferSpaceFill(W,p,Width);
      INC(p,OWidth);
    END;
    RedrawWindowPane(W);
  END;
  IGotoXY(W,1,1);
(*%T _mthread *)
  Unlock();
(*%E *)
END Clear;

PROCEDURE  ClrEol;
(*
   clears from the cursor to the end of line
*)
VAR
  W : WinType;
BEGIN
  W := CurWin();
  WITH W^ DO
    BufferSpaceFill(W,XA-WDef.X1+CurrentX-1+(YA-WDef.Y1+CurrentY-1)*OWidth,
          Width-CurrentX+1);
    RedrawSection ( W,XA-1+CurrentX,YA-1+CurrentY,XB,YA-1+CurrentY );
  END;
(*%T _mthread *)
  Unlock();
(*%E *)
END ClrEol;

(*%F _OS2 *)
PROCEDURE Bell;
VAR
  R : SYSTEM.Registers;
BEGIN
  WITH R DO
    AX := 0E07H;
    BL := 0;
    Lib.Intr(R,10H);
  END;
END Bell;
(*%E *)

(*%T _OS2 *)
PROCEDURE Bell;
BEGIN
  Dos.Beep(1000,300);
END Bell;
(*%E *)

PROCEDURE  WriteC ( W : WinType; C : CHAR);
VAR
  nx : CARDINAL;
BEGIN
  WITH W^ DO
    CASE C OF
       CHR(12) : Clear;
                 IGotoXY(W,1,1);
     | CHR(10) : IF CurrentY=Depth THEN
                   DeleteLine ( W, 1 );
                 ELSE
                   IGotoXY(W,CurrentX,CurrentY+1);
                 END;
     | CHR(13) : (*ClrEol; change 1/7/88*) IGotoXY(W,1,CurrentY);
     | CHR(08) : IF CurrentX>1 THEN
                   IGotoXY(W,CurrentX-1,CurrentY); WriteC(W,' ');
                   IGotoXY(W,CurrentX-1,CurrentY);
                 END;
     | CHR(7)  : Bell;
    ELSE
        IF CurrentX > Width THEN RETURN END;
        WindowWrite(W,CurrentX,CurrentY,1,ADR(C),FALSE);
        IF (CurrentX#Width)OR NOT WDef.WrapOn THEN
          IGotoXY(W,CurrentX+1,CurrentY);
        ELSE
          IF CurrentY=Depth THEN
            DeleteLine ( W, 1 );
            IGotoXY(W,1,CurrentY);
          ELSE
            IGotoXY(W,1,CurrentY+1);
          END;
        END;
    END;
  END;
END WriteC;

PROCEDURE  WriteOut (S : ARRAY OF CHAR);
VAR
  W     : WinType;
  p,q,m : CARDINAL;
  ss    : CARDINAL;
BEGIN
  W := CurWin();
  WITH W^ DO
    ss := HIGH(S)+1;
    p := 0;
    q := 0;
    LOOP
      (* first accumulate normal chars on same line *)
      m := Width+p-CurrentX;
      IF NOT W^.WDef.WrapOn THEN INC(m) END; (* can fit another char in *)
      IF m > ss THEN m := ss END;
      WHILE (q<m)AND(S[q]>=' ') DO INC(q) END;
      (* now output the line *)
      IF q > p THEN
        WindowWrite(W,CurrentX,CurrentY,q-p,ADR(S[p]),FALSE);
        IGotoXY(W,CurrentX+q-p,CurrentY);
      END;
      (* now output the special char *)
      IF (S[q] = CHR(0)) OR (q > HIGH(S)) THEN EXIT ELSE WriteC(W,S[q]);
      END;
      INC(q);
      p := q;
    END;
  END;
(*%T _mthread *)
  Unlock();
(*%E *)
END WriteOut;

PROCEDURE  DirectWrite ( X,Y : RelCoord;      (* start co-ords *)
                               A   : ADDRESS;       (* address of char array *)
                               Len : CARDINAL );    (* length to be written *)
(*
   writes directly to current window at the specified X,Y coordinates
   with no check for special (ie control) chars or eol wrap
*)
VAR
  W : WinType;
BEGIN
  W := CurWin();
  WindowWrite(W,X,Y,Len,A,FALSE);
(*%T _mthread *)
  Unlock();
(*%E *)
END DirectWrite;


PROCEDURE  GotoXY ( X,Y : RelCoord );
VAR
  W : WinType;
BEGIN
  W := CurWin();
  ClipXY(W,X,Y);
  IGotoXY(W,X,Y);
(*%T _mthread *)
  Unlock();
(*%E *)
END GotoXY;

PROCEDURE  WhereX ( ) : RelCoord;
VAR
  W : WinType;
BEGIN
  W := CurWin();
(*%T _mthread *)
  Unlock();
(*%E *)
  RETURN W^.CurrentX;
END WhereX;

PROCEDURE  WhereY ( ) : RelCoord;
VAR
  W : WinType;
BEGIN
  W := CurWin();
(*%T _mthread *)
  Unlock();
(*%E *)
  RETURN W^.CurrentY;
END WhereY;

PROCEDURE  ConvertCoords ( W         : WinType ;
                                 X,Y       : RelCoord;
                                 VAR XO,YO : AbsCoord );
BEGIN
  CheckWindow(W);
  XO := X+W^.XA-1; YO := Y+W^.YA-1;
END ConvertCoords;


PROCEDURE  InsLine;
VAR
  W : WinType;
  r,p,p1 : CARDINAL;
BEGIN
  W := CurWin();
  WITH W^ DO
    p := XA-WDef.X1+(YA-WDef.Y1+Depth-1)*OWidth;
    FOR r := CurrentY TO Depth-1 DO
      DEC(p,OWidth);
      Lib.Move(ADR(Buffer^[p]),ADR(Buffer^[p+OWidth]),Width*2);
    END;
    BufferSpaceFill(W,p,Width);
    RedrawSection ( W,XA,CurrentY+YA-1,XB,YB );
  END;
(*%T _mthread *)
  Unlock();
(*%E *)
END InsLine;

PROCEDURE  DelLine;
VAR
  W : WinType;
BEGIN
  W := CurWin();
  DeleteLine(W,W^.CurrentY);
(*%T _mthread *)
  Unlock();
(*%E *)
END DelLine;

PROCEDURE  TextColor ( c : Color );
VAR
  W : WinType;
BEGIN
  W := CurWin();
  W^.WDef.Foreground := c;
(*%T _mthread *)
  Unlock();
(*%E *)
END TextColor;

PROCEDURE  TextBackground ( c : Color );
VAR
  W : WinType;
BEGIN
  W := CurWin();
  W^.WDef.Background := c;
(*%T _mthread *)
  Unlock();
(*%E *)
END TextBackground;

PROCEDURE  SetWrap ( on : BOOLEAN );
VAR
  W : WinType;
BEGIN
  W := CurWin();
  W^.WDef.WrapOn := on;
(*%T _mthread *)
  Unlock();
(*%E *)
END SetWrap;

PROCEDURE Info  ( W : WinType; VAR WD : WinDef );
(* gets information for specified window *)
BEGIN
(*%T _mthread *)
  Lock();
(*%E *)
  WD := W^.WDef;
(*%T _mthread *)
  Unlock();
(*%E *)
END Info;


(* ------------------------- *)
(* Title procedure           *)
(* ------------------------- *)
PROCEDURE SetTitle ( W        : WinType;
                     NewTitle : ARRAY OF CHAR;
                     Mode     : TitleMode );
(*
  updates the window title within the window frame,
  positioning it in the position defined by the title mode
*)
VAR
  l : CARDINAL;
BEGIN
  CheckWindow(W);
(*%T _mthread *)
  Lock();
(*%E *)
  DisposeTitle(W);
  WITH W^ DO
    IF Mode # NoTitle THEN
      l := Str.Length(NewTitle);
      ALLOCATE(Title,l+1);
      Lib.Move(ADR(NewTitle),ADR(Title^),l);
      Title^[l] := CHR(0);
    END;
    TMode := Mode;
  END;
  DrawFrame(W);
(*%T _mthread *)
  Unlock;
(*%E *)
END SetTitle;


PROCEDURE ReadString  ( VAR string : ARRAY OF CHAR );
VAR
  c   : CHAR;
  line: ARRAY[0..82] OF CHAR;
  p,H : CARDINAL;
  W   : WinType;
  con : BOOLEAN;
BEGIN
  W := CurWin();
  PutOnTop(W);
  con := W^.WDef.CursorOn;
  CursorOn;
  H := HIGH(string);
  IF H>79 THEN H := 79 END;
  p := 0;
  LOOP
    c := IO.RdKey();
    IF (c=CHR(8))OR(c=CHR(127)) THEN
      IF p>0 THEN DEC(p); IO.WrChar(CHR(8)) END;
    ELSIF (c>=' ') THEN
      IF p<=H THEN
        IO.WrChar(c);
        line[p] := c;
        INC(p);
      END;
    ELSIF c=CHR(13) THEN
      EXIT;
    END;
  END;
  line[p] := CHR(0);
  Str.Copy(string,line);
  IF NOT con THEN CursorOff END;
(*%T _mthread *)
  Unlock;
(*%E *)
  IO.WrLn;
END ReadString;

(* Low level routines to read and write to the window buffer direct *)

PROCEDURE  RdBufferLn ( W    : WinType;        (* Source window *)
                              X,Y  : RelCoord;      (* start co-ords *)
                              Dest : ADDRESS;       (* address of buffer *)
                              Len  : CARDINAL );    (* length in WORDs *)
VAR
  AX,AY  : AbsCoord;
BEGIN
  WITH W^ DO
      AX := X+XA-1; AY := Y+YA-1;
      Lib.WordMove(ADR(Buffer^[AX-WDef.X1+(AY-WDef.Y1)*OWidth]),Dest,Len);
  END;
END RdBufferLn;

PROCEDURE  WrBufferLn ( W    : WinType;       (* Dest window *)
                              X,Y  : RelCoord;      (* start co-ords *)
                              Src  : ADDRESS;       (* address of buffer *)
                              Len  : CARDINAL );    (* length in WORDs *)
VAR
  AX,AY  : AbsCoord;
BEGIN
  WITH W^ DO
      AX := X+XA-1; AY := Y+YA-1;
      Lib.WordMove(Src,ADR(Buffer^[AX-WDef.X1+(AY-WDef.Y1)*OWidth]),Len);
      UpdateScreen(W,AX,AY,Len);
  END;
END WrBufferLn;

PROCEDURE InputStr ( VAR S : ARRAY OF CHAR );
VAR
  ins     : BOOLEAN;
  k       : CHAR;
  x,y,p,l : CARDINAL;
BEGIN
  x := WhereX(); y := WhereY();
  p := MAX(CARDINAL);
  p := 0;
  ins := TRUE; (* Insert mode *)
  LOOP
    l := Str.Length(S);
    IF p>l THEN p := l END;
    IO.WrStr(S); ClrEol;
    GotoXY(x+p,y);
    k := IO.RdCharDirect();
    IF k = 0C THEN  (* Extended character *)
      CASE IO.RdCharDirect() OF
      | CHR(75) : k := CHR(19);   (* LeftArr  -> ^S *)
      | CHR(77) : k := CHR(4) ;   (* RightArr -> ^D *)
      | CHR(71) : k := CHR(1) ;   (* Home     -> ^A *)
      | CHR(79) : k := CHR(6) ;   (* End      -> ^F *)
      | CHR(83) : k := CHR(7) ;   (* Del      -> ^G *)
      | CHR(82) : k := CHR(22);   (* Ins      -> ^V *)
      END;
    END;
    CASE k OF
    | ' '..'~' : IF ins    THEN Str.Insert(S,k,p);
                 ELSIF p=l THEN Str.Append(S,k);
                 ELSE S[p] := k;
                 END;
                 INC(p);
    | CHR(1)   : p := 0;                 (* Home    *)
    | CHR(6)   : p := l;                 (* End     *)
    | CHR(19)  : IF p>0 THEN DEC(p) END; (* Left    *)
    | CHR(4)   : IF p<l THEN INC(p) END; (* Right   *)
    | CHR(7)   : IF p<l THEN              (* Del     *)
                   Str.Delete(S,p,1);
                 END;
    | CHR(8)   : IF p>0 THEN              (* BackSpace *)
                   DEC(p); Str.Delete(S,p,1);
                 END;
    | CHR(22)  : ins := NOT ins;         (* Toggle Ins/Ovr *)
    | CHR(13)  : RETURN;                 (* Enter *)
    END;
    GotoXY(x,y);
  END;
END InputStr;


(* ------------------------- *)
(* Main initialization       *)
(* ------------------------- *)

CONST
  ClearOnEntry = TRUE;    (* Change to FALSE if automatic clear *)

(*%F _OS2 *)
VAR
  R : SYSTEM.Registers;
  WD : WinDef;

BEGIN
(*%T _mthread *)
  Lock := NullProc;
  Unlock := NullProc;
(*%E *)
  CoreWind._multip := FALSE;
  IO.WrStrRedirect := WriteOut;
  IO.RdStrRedirect := ReadString;
  CurrentScreenDepth := AbsCoord(CoreWind._getscreendepth());
  IF NOT CoreWind._winsetup THEN
      CoreWind._initscreentype(CGASnow);
      R.AH := 3;
      R.BH := SHORTCARD(CoreWind._activepage());
      Lib.Intr(R,10H);
      IF (R.CH<20H)AND(R.CL>0)  THEN
         CoreWind._cursorlines := R.CX;
      ELSE
         CoreWind._cursorlines := 0607H;
      END;
      CoreWind._windowstack := NIL;
      NEW(UseListPtr(CoreWind._uselist));
      UseListPtr(CoreWind._uselist)^.Next := NIL;        (* dummy *)
      CoreWind._cursorstack := NIL;
      WD := FullScreenDef;
      WD.Y2 := CurrentScreenDepth;
      IF ClearOnEntry THEN
        FullScreen       := Open(WD);
      ELSE
        WD.Hidden := TRUE;
        FullScreen       := Open(WD);
        SnapShot;
        PutOnTop(FullScreen);
        GotoXY(ORD(R.DL)+1,ORD(R.DH)+1);
      END;
   ELSE
      FullScreen:=CoreWind._fullscreen;
   END;

(*%E *)


(*%T _OS2 *)
VAR
  Row, Col: CARDINAL;
  WD: WinDef;
BEGIN
(*%T _mthread *)
  Lock   := Process.Lock;
  Unlock := Process.Unlock;
(*%E *)
  IO.WrStrRedirect := WriteOut;
  IO.RdStrRedirect := ReadString;
  CurrentScreenDepth := AbsCoord(CoreWind._getscreendepth());
  IF NOT CoreWind._winsetup THEN
      RealMode := NOT Lib.ProtectedMode();
      IF Vio.GetCurType( CursorInfo, 0 ) = 0 THEN END;
      CoreWind._initscreentype(CGASnow);
      CoreWind._windowstack := NIL;
      NEW(UseListPtr(CoreWind._uselist));
      UseListPtr(CoreWind._uselist)^.Next := NIL;        (* dummy *)
      CoreWind._cursorstack := NIL;
      WD := FullScreenDef;
      WD.Y2 := CurrentScreenDepth;
      IF ClearOnEntry THEN
        FullScreen       := Open(WD);
      ELSE
        WD.Hidden := TRUE;
        FullScreen       := Open(WD);
        SnapShot;
        PutOnTop(FullScreen);
        Vio.GetCurPos(Row, Col, 0);
        GotoXY(Col+1, Row+1);
      END;
  ELSE
      FullScreen := CoreWind._fullscreen;
  END;
(*%E *)

END Window.
