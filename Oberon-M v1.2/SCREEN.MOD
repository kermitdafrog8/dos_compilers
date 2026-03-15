MODULE Screen ;         (* ERV, 1989/91 *)
  IMPORT SYS:=SYSTEM;

CONST  minrow * = 0 ;   maxrow * = 24 ;
       mincol * = 0 ;   maxcol * = 79 ;

TYPE maptyp = ARRAY maxrow+1, maxcol+1 OF INTEGER ;
     Styp = POINTER TO maptyp ;

VAR S : Styp ;  Color * : INTEGER;
    ColorScreen * : BOOLEAN;

PROCEDURE SetAddr ;
TYPE ptyp = POINTER TO ARRAY 1 OF SET;
VAR cr:RECORD low, high : INTEGER END;
    p:ptyp;
BEGIN
  cr.low := 10H;  cr.high := 40H; (*equipflag in bios*)
  p := SYS.VAL(ptyp,cr);
  IF (5 IN p^) & (4 IN p^) THEN cr.high := 0B000H (*monochrome screen*);
    ColorScreen := FALSE
  ELSE cr.high := 0B800H (*color screen*); ColorScreen := TRUE
  END;
  cr.low := 0;  S := SYS.VAL(Styp,cr)
END SetAddr;


PROCEDURE WrtCh * (ch:CHAR; row, col : INTEGER);
BEGIN S[row,col] := 07H * 256 + ORD(ch)
END WrtCh;

PROCEDURE WrtStr * (s:ARRAY OF CHAR; row, col : INTEGER);
VAR i,cl:INTEGER;
BEGIN cl := Color * 256;
  i := 0;
  WHILE s[i] # 00X DO S[row,col] := cl + ORD(s[i]);
    INC(i);  INC(col);
    IF col > maxcol THEN INC(row); col := mincol;
       IF row > maxrow THEN row := minrow END
    END
  END
END WrtStr;

PROCEDURE WrtHi * (s:ARRAY OF CHAR; row, col : INTEGER);
VAR i:INTEGER;
BEGIN
  i := 0;
  WHILE s[i] # 00X DO S[row,col] := 70H * 256 + ORD(s[i]);
    INC(i);  INC(col);
    IF col > maxcol THEN INC(row); col := mincol;
       IF row > maxrow THEN row := minrow END
    END
  END
END WrtHi;

PROCEDURE WrtSp * (VAR s:ARRAY OF SYS.BYTE;
                   index,limit:INTEGER; row,col:INTEGER);
VAR ch:CHAR; i,j:INTEGER;  cl:INTEGER;
BEGIN cl := Color * 256;
  ch := CHR(s[index]);  j := limit - index ;
  IF j > maxcol THEN j := maxcol END;
  WHILE (j > 0) & (ch # 0X) DO
    S[row,col] := cl + ORD(ch);
    INC(index);  INC(col);  DEC(j);
    ch := CHR(s[index])
  END ;
  WHILE col < maxcol DO S[row,col] := cl + ORD(" "); INC(col) END
END WrtSp;


PROCEDURE Clear * ;
VAR cl:INTEGER;
BEGIN cl := Color * 256;
SYS.CODE(
 0B8H, 00H,06H,     (*   mov ax,0600h  ;scroll entire screen down*)
 0B9H, 00H,00H,     (*   mov cx,0            *)
 0BAH, 4FH,18H,     (*   mov dx,(24*256) + 79*)
 8BH, 5EH, 0FCH,    (*   mov bx,[bp-4];get color cl into bh*)
 0CDH, 10H          (*   int 10h             *)
 )
END Clear;

PROCEDURE EraseLine * (row:INTEGER);
VAR col,cl:INTEGER;
BEGIN col := mincol;  cl := Color * 256;
  WHILE col < maxcol DO S[row,col] := cl + ORD(" "); INC(col) END
END EraseLine;

PROCEDURE SetCursorOn *;
BEGIN SYS.CODE(
 0B4H, 01H,     (*mov ah,1      ;set cursor size *)
 0B9H, 07H,06H, (*mov cx, 0607h ; start/end lines(visible on color)*)
 0CDH, 10H      (*int 10h  *)
)
END SetCursorOn;

PROCEDURE SetCursorOff *;
BEGIN SYS.CODE(
 0B4H, 01H,     (*mov ah,1      ;set cursor size *)
 0B9H, 01H,0FH, (*mov cx, 0F01h ; start/end lines(invisible)*)
 0CDH, 10H      (*int 10h  *)
 )
END SetCursorOff;

PROCEDURE MoveCursor * (row,col:INTEGER);
BEGIN col := row*256 + col;
SYS.CODE(
 0B4H, 02H,     (* mov ah,2      ;set cursor position                    *)
 8BH, 56H, 06H, (* mov dx,word ptr[bp+6] ; get parm for row/col position *)
 0B7H, 00H,     (* mov bh,0      ;page number                            *)
 0CDH, 10H      (* int 10h                                               *)
)
END MoveCursor;

BEGIN SetAddr;  Color := 07H
END Screen.
