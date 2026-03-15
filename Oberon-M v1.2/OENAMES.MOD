(* Module to handle name type nodes on the general tree structure
   (Oberon Example)  (c) Copyright E. R. Videki 1991 *)

MODULE OENames ;
	IMPORT OETree , OEIO  ;


CONST	MaxName * = 25 ;	(* maximum size of a name we will remember *)
	PutName * = 0 ;		(* the command we recognize in our handler *)



TYPE	NameString *  = ARRAY MaxName OF CHAR ;
	NamePtr * = POINTER TO Name ;

	Name * = 	
		RECORD (OETree.Apple)	(* an extension of the basic node type *)
			name * : NameString
		END ;


VAR NameTree *  : NamePtr ;
	refnode : NamePtr ;


PROCEDURE * Handler ( p : OETree.ApplePtr ;  cmd : INTEGER ) ;
(* handles commands sent to an object that is a name type.  At the moment, the only 
command we process is to pass the name to an I/O routine.  Note the compiler
hint "*" which indicates that this procedure is placed into a variable (field in the
name record) *)
BEGIN
	IF cmd = PutName THEN
			OEIO.WriteString(  p(NamePtr).name  )
		(* note how the type of p is expanded to the extended type we deal with
		in this module.  Also, this type guard checks that p is in fact pointing to
		a name record we are assuming was passed to us. *)
	END (*ignore all unrecognized commands *)
END Handler;


PROCEDURE * NameSearch( p , ref : OETree.ApplePtr ;   VAR result : INTEGER );	
			(*see OETree's SearchProc type *)
(* (note the compiler hint "*" that indicates this procedure is called via a 
procedural-type variable
when it is the parameter to one of the OETree routines ) *)
VAR i : INTEGER ;
BEGIN
	result := 1 ;
	IF p IS NamePtr THEN	
	(* guard against some other kind of tree elements (generic safety checking) *)
		WITH p : NamePtr DO (* expand the scope to include our extended record type *)
			WITH ref : NamePtr DO 	
			(* this makes one efficient check for correct extended type of ref *)
				i := 0 ;
				WHILE ( i < MaxName) & ( p.name[i] # 0X) & 
				   (p.name[i] = ref.name[i]) DO INC(i) END;
				result :=  ORD(ref.name[i]) - ORD(p.name[i])
			END
		END
	ELSE result := -1 (* searching  for names on wrong kind of tree *)
	END
END NameSearch ;



PROCEDURE NewName * ( p : NamePtr ;  VAR result : INTEGER ) ;	
(* add new name element p^ to tree *)
BEGIN
	p.method := Handler ;	
		(* indicate our handler procedure for this type of extended record *)
	OETree.AddNew( NameTree, p , result, NameSearch) 
END NewName ;


PROCEDURE FindName * (VAR nm : NameString ; VAR result : INTEGER ; VAR p : NamePtr );	
(* search for existing name *)
VAR p1 : OETree.ApplePtr ;
BEGIN
	refnode.name := nm ;
	OETree.Search( NameTree, refnode , p1 , result, NameSearch) ;
	IF result = 0 THEN p := p1(NamePtr)	
		(* expand scope of pointer type for caller; it is name record node *)
	ELSE p := NIL
	END
END FindName ;


PROCEDURE Init ;
VAR result : INTEGER;
BEGIN
	NEW(refnode) ;	(* for reference of searches *)
	refnode.name[0] := 0X ;
	NEW(NameTree) ;	(* put a dummy head-of-tree element *)
	NameTree.name[0] := 0X ;
	NameTree.refptr := NIL;  NameTree.method := Handler  ;
	OETree.AddNew( NIL , NameTree , result, NameSearch) 	
			(*this inits tree links controlled by OETree*)
END Init;





BEGIN	Init 
END OENames .

