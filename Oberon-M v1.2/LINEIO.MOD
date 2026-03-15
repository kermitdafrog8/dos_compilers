MODULE LineIO ;         (* ERV, 1989/91 *)
  IMPORT SYS:=SYSTEM;

CONST MaxBuffer = 4096 ;

TYPE  Buffer   = RECORD
                   handle : INTEGER;
                   n : INTEGER; (*index into bufdata*)
                   m : INTEGER; (*max amount read into bufdata*)
                   out : BOOLEAN; (*TRUE on output file*)
                   bufdata : ARRAY MaxBuffer OF CHAR ;
                   slop : LONGINT (*slop in case read file used for writing*)
                 END;

      Rider * = POINTER TO Buffer ;

      OpenProcTyp =
           PROCEDURE (VAR s:ARRAY OF CHAR; VAR handle:INTEGER; rw:INTEGER);


PROCEDURE * FileOpen(VAR s:ARRAY OF CHAR; VAR handle:INTEGER; rw:INTEGER);
(* rw = 0 for read, 1 for write, 2 for r/w  *)
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


PROCEDURE * FileCreate(VAR s:ARRAY OF CHAR; VAR handle:INTEGER; attr:INTEGER);
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

PROCEDURE * FileClose(handle:INTEGER);
BEGIN SYS.CODE(
  8BH, 5EH, 06H,   (*mov bx,word ptr[bp+6]*)
  0B4H, 3EH,       (*mov ah,3Eh           *)
  0CDH, 21H)       (*int 21h              *)
END FileClose;

PROCEDURE * FileRd(VAR buff:ARRAY OF SYS.BYTE;
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


PROCEDURE * FileWrt(VAR buff:ARRAY OF SYS.BYTE;
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



PROCEDURE Open(VAR s:ARRAY OF CHAR; VAR r:Rider; VAR result:INTEGER;
               mode:INTEGER; Proc : OpenProcTyp );
(* result = 0 for ok, 1 for failure *)
BEGIN
  NEW(r);  r.handle := 0;  r.n := 0 ;  r.m := 0;  r.out := mode > 0 ;
  Proc(s, r.handle, mode);
  IF r.handle # 0 THEN result := 0 ELSE result := 1 END
END Open;

PROCEDURE OpenRead * (s:ARRAY OF CHAR; VAR r:Rider; VAR result:INTEGER);
BEGIN Open(s,r,result,0,FileOpen)
END OpenRead;

PROCEDURE OpenWrite * (s:ARRAY OF CHAR; VAR r:Rider; VAR result:INTEGER);
BEGIN Open(s,r,result,1,FileOpen)
END OpenWrite;

PROCEDURE OpenCreate * (s:ARRAY OF CHAR; VAR r:Rider; VAR result:INTEGER);
BEGIN Open(s,r,result,20H,FileCreate)
END OpenCreate;

PROCEDURE FillBuff(r:Rider);
BEGIN
  FileRd( r.bufdata, r.handle, MaxBuffer, r.m );
  r.n := 0
END FillBuff;

PROCEDURE ReadLn * (r:Rider; VAR s:ARRAY OF CHAR);
VAR i,j,k:INTEGER;  ch:CHAR;
BEGIN
  s[0] := 00X ;
  IF ~r.out THEN
    IF r.n >= r.m THEN FillBuff(r) END;
    i := 0; j := LEN(s,1) - 1 ;
    k := r.m - r.n ;
    IF k > j THEN k := j END;
    ch := r.bufdata[r.n];
    WHILE (i < k) & (ch # 0DX) DO
      s[i] := ch;  INC(i);  INC(r.n);  ch := r.bufdata[r.n]
    END;
    IF ch = 0DX (*carriage return*) THEN
      INC(r.n, 2); (*pass CR/LF sequence*)
      IF i = 0 THEN s[0] := " "; i := 1 END  (*nul line is 1 blank to caller*)
    END;
    s[i] := 00X
  END
END ReadLn;


PROCEDURE DumpBuff(r:Rider);
VAR i:INTEGER;
BEGIN
  IF r.n > 0 THEN
     IF r.out THEN FileWrt(r.bufdata, r.handle, r.n, i) END;
     r.n := 0
  END
END DumpBuff;

PROCEDURE WriteLn * (r:Rider);
BEGIN
  r.bufdata[r.n] := 0DX;  r.bufdata[r.n + 1] := 0AX ;  INC(r.n, 2); (*CR/LF*)
  DumpBuff(r)
END WriteLn;


PROCEDURE Writev * (r:Rider; VAR s:ARRAY OF CHAR);
VAR i,j:INTEGER; ch:CHAR;
BEGIN
  i := r.n ;   j := 0 ;
  WHILE s[j] # 00X DO
    IF i >= MaxBuffer THEN DumpBuff(r); i := 0 END;
    r.bufdata[i] := s[j] ;
    INC(i); INC(j)
  END ;
  r.n := i
END Writev;

PROCEDURE Write * (r:Rider; s:ARRAY OF CHAR);
BEGIN Writev(r,s)
END Write;

PROCEDURE WriteCh * (r:Rider; ch:CHAR);
VAR s:ARRAY 4 OF CHAR;
BEGIN s[0] := ch;  s[1] := 00X;  Writev(r,s)
END WriteCh;


PROCEDURE Close * (VAR r:Rider);
BEGIN
 IF r.out & (r.n > 0) THEN WriteLn(r) END;
 FileClose(r.handle);  r := NIL
END Close;


PROCEDURE WriteHex * (r:Rider; li:LONGINT);
VAR i,j,b0,b1,b2,b3:INTEGER;
  PROCEDURE TwoDig(n:INTEGER);
  VAR c,x:INTEGER;  buf:ARRAY 2 OF INTEGER;
  BEGIN c := 0;
    REPEAT x := n MOD 16;  n := n DIV 16;
      IF x > 10 THEN x := x+ORD("A")-10 ELSE x := x+ORD("0") END;
      buf[c] := x; INC(c)
    UNTIL c = 2;
    REPEAT DEC(c); WriteCh(r,CHR(buf[c])) UNTIL c = 0
  END TwoDig;
BEGIN
  b2:= SYS.HI(li);  b3 := SYS.LO(li);
  b0 := SYS.HI(b2);  b1 := SYS.LO(b2);  b2 := SYS.HI(b3);  b3 := SYS.LO(b3);
  IF b0 >= 0A0H THEN WriteCh(r,"0") END;
  IF (b0 # 0) OR (b1 # 0) THEN TwoDig(b0); TwoDig(b1)
  ELSIF b2 >= 0A0H THEN WriteCh(r,"0")
  END;
  TwoDig(b2); TwoDig(b3); WriteCh(r,"H")
END WriteHex;

PROCEDURE WriteInt * (r:Rider; li:LONGINT);
VAR i:INTEGER; buf:ARRAY 30 OF INTEGER;
BEGIN i := 0;  IF li < 0 THEN li := -li;  WriteCh(r,"-") END;
  REPEAT buf[i] := SHORT(li MOD 10);  li := li DIV 10; INC(i) UNTIL li = 0;
  REPEAT DEC(i); WriteCh(r, CHR(buf[i] + ORD("0"))) UNTIL i = 0
END WriteInt;


END LineIO.
