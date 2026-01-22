(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  TERMINAL.MOD - Terminal i/o (core library)                              *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*$V-*)
IMPLEMENTATION MODULE Terminal ;

(* Core library interface *)

IMPORT Str,IO,ASCII ;

VAR
  CharBuffered : BOOLEAN ;
  SaveChar     : CHAR ;

PROCEDURE Read ( VAR v : CHAR ) ;
BEGIN
  IF CharBuffered THEN
    v := SaveChar ;
    CharBuffered := FALSE ;
  ELSE
    SaveChar := IO.RdKey() ;
    v := SaveChar ;
  END ;
END Read ;


PROCEDURE ReadAgain ;
BEGIN
  CharBuffered := TRUE ;
END ReadAgain ;


PROCEDURE ReadString  ( VAR v : ARRAY OF CHAR ) ;
VAR
  c : CHAR ;
  line : ARRAY[0..255] OF CHAR ;
  p : CARDINAL ;
BEGIN
  p := 0 ;
  REPEAT Read(c) UNTIL c<>' ' ;
  LOOP
     IF (c=ASCII.bs)OR(c=ASCII.del) THEN
       IF p>0 THEN
         DEC(p) ;
         Write(ASCII.bs);
         Write(' ');
         Write(ASCII.bs);
       END ;
     ELSIF (c>' ')AND(c<CHR(80H)) THEN
       Write(c) ;
       IF p<SIZE(line) THEN
         line[p] := c ;
         INC(p) ;
       END ;
     ELSE EXIT ;
     END ;
     Read(c) ;
  END ;
  termCH := c ;
  IF p<SIZE(line) THEN line[p] := CHR(0) END ;
  Str.Copy(v,line) ;
END ReadString ;


PROCEDURE Write    ( v : CHAR ) ;
BEGIN
  IO.WrChar(v) ;
END Write ;

PROCEDURE WriteLn ;
BEGIN
  IO.WrLn ;
END WriteLn ;

PROCEDURE WriteString ( s : ARRAY OF CHAR ) ;
BEGIN
  IO.WrStr(s) ;
END WriteString ;

BEGIN
  CharBuffered := FALSE ;
  SaveChar := CHR(0) ;
END Terminal.

