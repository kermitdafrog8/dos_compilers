(* This I/O module is easily tailored to run on Oberon-M in
	the MSDOS environment, or under the closed-environment
	Oberon System from ETH Zurich.  Just use the bracketing
	comment fields to control which system you are using.   
   (Oberon Example)  (c) Copyright E. R. Videki, 1991 *)
	
MODULE OEIO ;

(*   Oberon System  I/O  **********

	IMPORT Texts , Oberon ;

VAR W : Texts.Writer ;
	lastpos : LONGINT ;

PROCEDURE Write * (ch:CHAR) ;
BEGIN Texts.Write(W,ch)
END Write;

PROCEDURE WriteString * (s:ARRAY OF CHAR);
BEGIN Texts.WriteString(W,s)
END WriteString ;


PROCEDURE WriteLn * ;
BEGIN Texts.WriteLn(W);  Texts.Append(Oberon.Log, W.buf)
END WriteLn ;


PROCEDURE GetInput * (VAR s:ARRAY OF CHAR) ;
CONST CR = 0DX ;  LF = 0AX ;  HT = 09X ;
VAR par : Oberon.ParList ;   R : Texts.Reader ;
	i , j : INTEGER ;   ch : CHAR ;
BEGIN
	s[0] := 0X ;	i := 0 ;   j := SHORT( LEN(s) );
	par := Oberon.Par ;	
	Texts.OpenReader(R, par.text,  lastpos ) ;
	Texts.Read(R,ch) ;
	WHILE (~R.eot) & ((ch = " ") OR (ch = HT)) DO Texts.Read(R,ch) END;  (*blank elim*)
	WHILE (~R.eot) & (ch > " ") DO
		s[i] := ch ;  INC(i);  Texts.Read(R,ch) 
	END;
	s[i] := 0X ;
	lastpos := Texts.Pos(R)
	
END GetInput ;


PROCEDURE Init * ;
BEGIN lastpos := Oberon.Par.pos
END Init ;

BEGIN
	Init; 	Texts.OpenWriter(W)
	
	
******* End of Oberon System I/O    *)




(* MSDOS I/O (using the distributed Oberon-M I/O modules)  ********   *)

	IMPORT Term ;

PROCEDURE Write * (ch:CHAR) ;
BEGIN Term.Wch(ch)
END Write;

PROCEDURE WriteString * (s:ARRAY OF CHAR);
BEGIN Term.WSv(s)
END WriteString ;


PROCEDURE WriteLn * ;
BEGIN  Term.WL
END WriteLn ;


PROCEDURE GetInput * (VAR s:ARRAY OF CHAR) ;
BEGIN Term.RS(s)
END GetInput ;


PROCEDURE Init * ;
(* only has use under the Oberon System, not under MSDOS *)
END Init ;



(*  ******** End of MSDOS I/O *)

END OEIO .
