MODULE Term;    (* ERV, 1989/91 *)
  IMPORT SYS:=SYSTEM;

CONST
    (* some extended function key values when first RdKey is 00X *)
       ardown * = 80;   arup   * = 72;
       arleft * = 75;   arrt   * = 77;
       home   * = 71;   end    * = 79;
       pgup   * = 73;   pgdn   * = 81;
       ins    * = 82;   del    * = 83;
       F1     * = 59;   F11    * = 84; (*F11-F20 is F+shift*)
       F21    * = 94;                  (*F21-F30 is F+CTRL*)
       F31    * =104;                  (*F31-F40 is F+ALT*)
       Carleft* =115;   Carrt  * = 116;(*CTRL+arleft/right*)
       Chome  * =119;   Cend   * = 117;(*CTRL+home/end*)
       Cpgup  * =132;   Cpgdn  * = 118;(*CTRL+pageup/down*)


PROCEDURE RdKey * (VAR ch:CHAR);
BEGIN SYS.CODE(
  0B4H, 08H,         (* mov  ah,08h  *)
  0CDH, 21H,         (* int  21h     *)
  0C4H, 5EH, 06H,    (* les  bx,dword ptr [bp+6] *)
  26H, 88H, 07H)     (* mov  es:[bx],al       ;return byte *)
END RdKey;

PROCEDURE Put(VAR s:ARRAY OF CHAR);
BEGIN
 SYS.CODE(
 0B4H, 09H,     (*mov ah,09H  *)
 1EH,           (*push ds     *)
 0C5H, 56H, 04H,(*lds dx,dword ptr [bp+4] ;fetch ptr to buffer *)
 0CDH, 21H,     (*int 21h  *)
 1FH            (*pop ds   *)
 )
END Put;

PROCEDURE Wch * (ch:CHAR);
VAR s:ARRAY 3 OF CHAR;
BEGIN s[0] := ch;  s[1] := "$"; Put(s)
END Wch;

PROCEDURE WL * ;
CONST lf = 0AX; cr = 0DX;
VAR s1:ARRAY 6 OF CHAR;
BEGIN
  s1[0] := cr;  s1[1] := lf;  s1[2] := "$";  Put(s1)
END WL;

PROCEDURE WSv * (VAR s:ARRAY OF CHAR);
VAR i:INTEGER;
BEGIN
 i := ORD(s[0]);  i := i * 3 ;  i := i ;
  i := 0;
  WHILE s[i] # 00X DO INC(i) END;
  s[i] := "$" ;  Put(s);  s[i] := 00X
END WSv;

PROCEDURE WS * (s:ARRAY OF CHAR);
BEGIN WSv(s)
END WS;

PROCEDURE RS * (VAR s:ARRAY OF CHAR);
CONST maxbuf = 80;
TYPE ibuf = ARRAY maxbuf OF CHAR;
VAR ib:ibuf;  i,j,k:INTEGER;
  PROCEDURE RB(VAR s:ibuf);
  BEGIN SYS.CODE(
    0B4H, 0AH,      (*mov ah,0Ah *)
    1EH,            (*push ds    *)
    0C5H, 56H, 04H, (*lds dx,dword ptr [bp+4] *)
                    (*   ;fetch ptr to buffer, char[0] is len allowed *)
                    (*   ; and char[1] is len returned to caller      *)
    0CDH, 21H,      (*int 21h    *)
    1FH)            (*pop ds     *)
  END RB;
BEGIN (*RS*)
  ib[0] := CHR(maxbuf - 2);  ib[1] := 00X;
  RB(ib);  WL;
  i := ORD(ib[1]);  j := 2;  k := 0;
  WHILE i > 0 DO
    s[k] := ib[j];  INC(k); INC(j); DEC(i)
  END;
  s[k] := 00X
END RS;

PROCEDURE WI * (li:LONGINT);
VAR i:INTEGER; buf:ARRAY 30 OF INTEGER;
BEGIN i := 0;  IF li < 0 THEN li := -li;  Wch("-") END;
  REPEAT buf[i] := SHORT(li MOD 10);  li := li DIV 10; INC(i) UNTIL li = 0;
  REPEAT DEC(i); Wch(CHR(buf[i] + ORD("0"))) UNTIL i = 0
END WI;

END Term.
