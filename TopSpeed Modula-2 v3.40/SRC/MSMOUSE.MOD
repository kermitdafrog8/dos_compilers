(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  MSMOUSE.MOD - Microsoft mouse drivers                                   *
*                                                                          *
*  COPYRIGHT (C) 1989..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*# data(seg_name => null) *)
(*%E *)
(*# module(implementation=>off) *)
(*# call(o_a_copy => off) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE MsMouse;

(* MSDOS Only  *)

IMPORT Lib, SYSTEM, CoreMain;

PROCEDURE Reset(): INTEGER;

VAR
    r: SYSTEM.Registers;
    status: CARDINAL;
BEGIN
    r.AX:=0;
    Lib.Intr(r, 33H);
    status:=r.AX;
    IF status = MAX(CARDINAL) THEN
        RETURN(r.BX);
    END;
    RETURN MAX(INTEGER);
END Reset;

PROCEDURE Cursor(Mode: BOOLEAN);

VAR
    r: SYSTEM.Registers;
BEGIN
    IF Mode = _MS_HIDE THEN
        r.AX:=2;
    ELSIF Mode = _MS_SHOW THEN
        r.AX:=1;
    ELSE
        RETURN;
    END;
    Lib.Intr(r, 33H);
    RETURN;
END Cursor;

PROCEDURE GetStatus(VAR mp: MsData);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=3;
    Lib.Intr(r, 33H);
    mp.row:=r.DX;
    mp.col:=r.CX;
    mp.left_pressed:=0 IN BITSET(r.BX);
    mp.right_pressed:=1 IN BITSET (r.BX);
    mp.middle_pressed:=2 IN BITSET(r.BX);
    RETURN;
END GetStatus;

PROCEDURE SetPosition(Row, Col: INTEGER);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=4;
    r.CX:=Col;
    r.DX:=Row;
    Lib.Intr(r, 33H);
    RETURN;
END SetPosition;

PROCEDURE GetPress(Button: INTEGER; VAR mp: MsData);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=5;
    r.BX:=Button;
    Lib.Intr(r, 33H);
    mp.row:=r.DX;
    mp.col:=r.CX;
    mp.left_pressed:=0 IN BITSET(r.AX);
    mp.right_pressed:=1 IN BITSET(r.AX);
    mp.middle_pressed:=2 IN BITSET(r.AX);
    mp.actions:=r.BX;
    RETURN;
END GetPress;

PROCEDURE GetRelease(Button: INTEGER; VAR mp: MsData);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=6;
    r.BX:=Button;
    Lib.Intr(r, 33H);
    mp.row:=r.DX;
    mp.col:=r.CX;
    mp.left_pressed:=0 IN BITSET(r.AX);
    mp.right_pressed:=1 IN BITSET (r.AX);
    mp.middle_pressed:=2 IN BITSET(r.AX);
    mp.actions:=r.BX;
    RETURN;
END GetRelease;

PROCEDURE SetRange(mp: MsRange);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=7;
    r.CX:=mp.min_col;
    r.DX:=mp.max_col;
    Lib.Intr(r, 33H);
    r.AX:=8;
    r.CX:=mp.min_row;
    r.DX:=mp.max_row;
    Lib.Intr(r, 33H);
    RETURN;
END SetRange;

PROCEDURE SetGraphCursor(VAR mp: MsGraphcur);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=9;
    r.BX:=mp.col;
    r.CX:=mp.row;
    r.DX:=Ofs(mp.screen_mask);
    r.ES:=Seg(mp.screen_mask);
    Lib.Intr(r, 33H);
    RETURN;
END SetGraphCursor;

PROCEDURE SetTextCursor(mp: MsTextCur);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=0AH;
    r.BX:=CARDINAL(mp.type);
    IF mp.type = _MS_HARD THEN
        r.CX:=mp.H.start_scan;
        r.DX:=mp.H.end_scan;
    ELSE
        r.CX:=mp.S.screen_mask;
        r.DX:=mp.S.cursor_mask;
    END;
    Lib.Intr(r, 33H);
    RETURN;
END SetTextCursor;

PROCEDURE GetMotion(VAR mp: MsMotion);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=0BH;
    Lib.Intr(r, 33H);
    mp.horiz:=r.CX;
    mp.vert:=r.DX;
    RETURN;
END GetMotion;

TYPE
    tr = RECORD
           CASE : BOOLEAN OF
             | TRUE : IFunc: MouseFuncType;
             | FALSE : A: ARRAY [0..1] OF CARDINAL;
           END;
         END;

PROCEDURE SetInterrupt(VAR mp: MsInterrupt);

VAR
    r: SYSTEM.Registers;
    temp: tr;
BEGIN
    temp.IFunc := mp.IntFunc;
    r.AX:=0CH;
    r.CX:=mp.mask;
    r.DX:=temp.A[0];
    r.ES:=temp.A[1];
    Lib.Intr(r, 33H);
    RETURN;
END SetInterrupt;

PROCEDURE SwapInterrupt(VAR mp: MsInterrupt);

VAR
    r: SYSTEM.Registers;
    temp: tr;
BEGIN
    temp.IFunc := mp.IntFunc;
    r.AX:=14H;
    r.CX:=mp.mask;
    r.DX:=temp.A[0];
    r.ES:=temp.A[1];
    Lib.Intr(r, 33H);
    mp.mask:=r.CX;
    mp.IntFunc:=MouseFuncType([r.ES: r.DX]);
    RETURN;
END SwapInterrupt;

PROCEDURE LightPen(Mode: BOOLEAN);

VAR
    r: SYSTEM.Registers;
BEGIN
    IF Mode = _MS_ON THEN
        r.AX:=0DH;
    ELSE
        r.AX:=0EH;
    END;
    Lib.Intr(r, 33H);
    RETURN;
END LightPen;

PROCEDURE SetMickeys(Vert, Horiz: INTEGER);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=0FH;
    r.CX:=Horiz;
    r.DX:=Vert;
    Lib.Intr(r, 33H);
    RETURN;
END SetMickeys;

PROCEDURE UpdateScreen(x1, y1, x2, y2: INTEGER);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=10H;
    r.CX:=x1;
    r.DX:=y1;
    r.SI:=x2;
    r.DI:=y2;
    Lib.Intr(r, 33H);
    RETURN;
END UpdateScreen;

PROCEDURE SetDouble(Threshold: INTEGER);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=13H;
    r.DX:=Threshold;
    Lib.Intr(r, 33H);
    RETURN;
END SetDouble;

PROCEDURE DriverSize(): CARDINAL;

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=15H;
    Lib.Intr(r, 33H);
    RETURN(r.BX);
END DriverSize;

PROCEDURE SaveDriver(Buffer: ADDRESS);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=16H;
    r.DX:=Ofs(Buffer^);
    r.ES:=Seg(Buffer^);
    Lib.Intr(r, 33H);
    RETURN;
END SaveDriver;

PROCEDURE RestoreDriver(Buffer: ADDRESS);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=017H;
    r.DX:=Ofs(Buffer^);
    r.ES:=Seg(Buffer^);
    Lib.Intr(r, 33H);
    RETURN;
END RestoreDriver;

PROCEDURE GetSensitivity(VAR mp: MsSense);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=01BH;
    Lib.Intr(r, 33H);
    mp.v_speed:=r.CX;
    mp.h_speed:=r.BX;
    mp.threshold:=r.DX;
    RETURN;
END GetSensitivity;

PROCEDURE SetSensitivity(mp: MsSense);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=01AH;
    r.BX:=mp.h_speed;
    r.CX:=mp.v_speed;
    r.DX:=mp.threshold;
    Lib.Intr(r, 33H);
    RETURN;
END SetSensitivity;

PROCEDURE SetPage(Page: CARDINAL);

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=01DH;
    r.BX:=Page;
    Lib.Intr(r, 33H);
    RETURN;
END SetPage;

PROCEDURE GetPage(): CARDINAL;

VAR
    r: SYSTEM.Registers;
BEGIN
    r.AX:=01EH;
    Lib.Intr(r, 33H);
    RETURN(r.BX);
END GetPage;


END MsMouse.