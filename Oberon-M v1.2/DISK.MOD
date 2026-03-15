MODULE Disk;    (* ERV, 1989/91 *)
  IMPORT SYS:=SYSTEM;

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

END Disk.
