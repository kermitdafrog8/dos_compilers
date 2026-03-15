MODULE IO;      (* ERV, 1989/91 *)
  IMPORT SYS:=SYSTEM;

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

PROCEDURE WL * ;
CONST cr = 0AX; lf = 0DX;
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

PROCEDURE Wch * (ch:CHAR);
VAR s:ARRAY 4 OF CHAR;
BEGIN s[0] := ch;  s[1] := 0X; WSv(s)
END Wch;

PROCEDURE ItoS * (i:INTEGER; VAR s:ARRAY OF CHAR);
VAR j,k:INTEGER;
    arr:ARRAY 10 OF INTEGER;
BEGIN
  k := 0;
  IF i < 0 THEN s[0] := "-";  i := -i; j := 1  ELSE j := 0 END;
  WHILE i > 0 DO
    arr[k] := i MOD 10;  INC(k);
    i := i DIV 10
  END;
  IF k = 0 THEN s[0] := "0";  j := 1
  ELSE
    WHILE k > 0 DO
      DEC(k); s[j] := CHR(arr[k] + ORD("0") );
      INC(j)
    END
  END;
  s[j] := 00X
END ItoS;

PROCEDURE WI * (x:INTEGER);
VAR s:ARRAY 16 OF CHAR;
BEGIN
  ItoS(x,s); WSv(s)
END WI;

PROCEDURE RCh * (VAR ch:CHAR);
BEGIN SYS.CODE(
  0B4H, 01H,         (* mov  ah,01h  *)
  0CDH, 21H,         (* int  21h     *)
  0C4H, 5EH, 06H,    (* les  bx,dword ptr [bp+6] *)
  26H, 88H, 07H)     (* mov  es:[bx],al       ;return byte *)
END RCh;

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

PROCEDURE FileOpen * (VAR s:ARRAY OF CHAR; VAR handle:INTEGER; rw:INTEGER);
BEGIN SYS.CODE(
  1EH,            (*  push ds  *)
  0C5H, 56H, 0CH, (*  lds dx,dword ptr [bp+12] ;file name *)
  8BH, 46H, 06H,  (*  mov ax,word ptr [bp+06 ] ; rw type *)
  0B4H, 3DH,      (*  mov ah,3Dh *)
  0CDH, 21H,      (*  int 21h    *)
  73H, 03H,       (*  jnc FOok   *)
  0B8H, 00H,00H,  (*  mov   ax,0 *)
                  (*FOok:        *)
  0C5H, 5EH, 08H, (*  lds bx,dword ptr[bp+8];handle  *)
  89H, 07H,       (*  mov word ptr[bx],ax     *)
  1FH)            (*  pop ds                  *)
END FileOpen;


PROCEDURE FileCreate * (VAR s:ARRAY OF CHAR; VAR handle:INTEGER; attr:INTEGER);
BEGIN SYS.CODE(
  1EH,            (*  push ds  *)
  0C5H, 56H, 0CH, (*  lds dx,dword ptr [bp+12] ;file name *)
  8BH, 4EH, 06H,  (*  mov cx,word ptr [bp+06] ; attr *)
  0B4H, 3CH,      (*  mov ah,3Ch *)
  0CDH, 21H,      (*  int 21h    *)
  73H, 03H,       (*  jnc FOok   *)
  0B8H, 00H,00H,  (*  mov   ax,0 *)
                  (*FOok:        *)
  0C5H, 5EH, 08H, (*  lds bx,dword ptr[bp+8];handle  *)
  89H, 07H,       (*  mov word ptr[bx],ax     *)
  1FH)            (*  pop ds                  *)
END FileCreate;

PROCEDURE FileClose * (handle:INTEGER);
BEGIN SYS.CODE(
  8BH, 5EH, 06H,   (*mov bx,word ptr[bp+6]*)
  0B4H, 3EH,       (*mov ah,3Eh           *)
  0CDH, 21H)       (*int 21h              *)
END FileClose;

PROCEDURE FileRd * (VAR buff:ARRAY OF SYS.BYTE;
                 handle:INTEGER; size:INTEGER; VAR read:INTEGER);
BEGIN SYS.CODE(
 1EH,              (*  push ds  *)
 0C5H, 56H, 0EH,   (*  lds dx,dword ptr [bp+14] ;buf ptr   *)
 8BH, 5EH, 0CH,    (*  mov bx,word ptr[bp+12]   ;handle    *)
 8BH, 4EH, 0AH,    (*  mov cx,word ptr[bp+10]  ;size      *)
 0B4H, 3FH,        (*  mov ah,3Fh ;read code              *)
 0CDH, 21H,        (*  int 21h                            *)
 73H, 02H,         (*  jnc RDok                           *)
 0F7H, 0D8H,       (*  neg ax ;neg 'read' means error code*)
                   (* RDok:                               *)
 0C5H, 5EH, 06H,   (*  lds bx,dword ptr[bp+6 ];read       *)
 89H, 07H,         (*  mov word ptr [bx],ax               *)
 1FH)              (*  pop ds                             *)
END FileRd;


PROCEDURE FileWrt * (VAR buff:ARRAY OF SYS.BYTE;
                 handle:INTEGER; size:INTEGER; VAR wrt:INTEGER);
BEGIN SYS.CODE(
 1EH,              (*  push ds  *)
 0C5H, 56H, 0EH,   (*  lds dx,dword ptr [bp+14] ;buf ptr   *)
 8BH, 5EH, 0CH,    (*  mov bx,word ptr[bp+12]   ;handle    *)
 8BH, 4EH, 0AH,    (*  mov cx,word ptr[bp+10]  ;size      *)
 0B4H, 40H,        (*  mov ah,40h ;write code             *)
 0CDH, 21H,        (*  int 21h                            *)
 73H, 02H,         (*  jnc RDok                           *)
 0F7H, 0D8H,       (*  neg ax ;neg 'read' means error code*)
                   (* RDok:                               *)
 0C5H, 5EH, 06H,   (*  lds bx,dword ptr[bp+6 ];wrt        *)
 89H, 07H,         (*  mov word ptr [bx],ax               *)
 1FH)              (*  pop ds                             *)
END FileWrt;

PROCEDURE ChangeFileMode * (VAR fn:ARRAY OF CHAR; attr:INTEGER);
BEGIN SYS.CODE(
  1EH,            (*push ds      *)
  0C5H, 56H, 08H, (*lds dx,dword ptr[bp+8] ;fn *)
  0B8H, 01H, 43H, (*mov ax,4301H               *)
  8BH, 4EH, 06H,  (*mov cx,word ptr [bp+6] ;attr*)
  0CDH, 21H,      (*int 21h *)
  1FH)            (*pop ds  *)
END ChangeFileMode;

END IO.
