(* General Tree Handler Module		
  (Oberon Example)	(c) Copyright E. R. Videki 1991 *)
MODULE OETree ;


TYPE	ApplePtr * = POINTER TO Apple ;	(* One blob on a tree stem... *)

	CmdHandler * = PROCEDURE ( p : ApplePtr ;  cmd : INTEGER );
	(* general handler of commands sent to a particular node; set by creator
	of the extended record type *)

	Apple * =	
		RECORD	(* a node on the tree.  You may extend this any way you like. *)
		left  , right  : ApplePtr ;	(* notice that the fields are not 
						exported, because
						they are only handled by this module *)
		refptr  * : ApplePtr ;	(* application-specific reference to another node *)
		method * : CmdHandler 	(* application-specific handler of events to this node*)
		END;


	SearchProc = PROCEDURE ( p , ref : ApplePtr ;  VAR result : INTEGER );
	(* search procedure is called to inform us whether we need to
	descend to the left (ie: lower collating sequence) or right
	branches of the tree, or to stop.  The result variable must indicate:
		< 0	- continue search at left branch (lower sequence)
		zero	- stop the search, node 'p' is the matching one
		> 0	- continue search at right branch (higher in sequence)
	The 'ref' parameter is passed unchanged from calling Search (cf. below), so you can
	use it to compare the 'p' node under consideration with some field of
	your own in 'ref' (or not, as you wish) . *)


	TraverseProc = PROCEDURE ( p : ApplePtr ) ;	
	(* a procedure used in the TraverseTree procedure below, which you supply,
	 which does whatever you wish at each node of the tree as the tree is
	 traversed from low-to-high order *)
							   



PROCEDURE Search * (  treehead, ref : ApplePtr ;  
			VAR found : ApplePtr ;  VAR result : INTEGER ;
			searchproc : SearchProc );
(* result has 0 when search was successful, non zero if not.  When successful,
then 'found' points to the searched-for tree element.  You define the way the search
happens by your searchproc.  'ref' is as explained above in the search proc type definition.*)
BEGIN
	result := 1 ;   found := NIL ; (*assume failure at first *)
	LOOP
		IF treehead = NIL THEN EXIT END;
		searchproc( treehead , ref , result );
		IF result = 0 THEN EXIT
		ELSIF result < 0 THEN treehead := treehead.left
		ELSE treehead := treehead.right
		END
	END ; 
	found := treehead
END Search;



PROCEDURE AddNew * ( treehead , new : ApplePtr ; 
			VAR result : INTEGER;  searchproc : SearchProc ) ;
(* add a new tree node, which you must have performed a NEW on (and filled in any 
extensions you need to the data type).  'result' will contain 0 only if there was no other
matching node (as you decide in the searchproc) and the new node was added to the
tree *)
VAR p : ApplePtr ;  ans : INTEGER;
BEGIN
	result := 0 ;	(* assume success *)
	new.left := NIL;   new.right := NIL ;
	p := treehead ;
	LOOP
		IF p = NIL THEN EXIT END;
		searchproc( p , new , ans );
		IF ans  < 0 THEN
			IF p.left # NIL THEN p := p.left  ELSE  p.left := new ; EXIT END
		ELSIF ans  > 0 THEN
			IF p.right # NIL THEN p := p.right  ELSE  p.right := new ;  EXIT END
		ELSE  result  := 1 ; EXIT  (*node already present; can't add same one again *)
		END
	END (* LOOP *)
END AddNew ;


PROCEDURE TraverseTree * (  userproc : TraverseProc ;  treehead : ApplePtr  ) ;

	PROCEDURE NeXT( p : ApplePtr ) ;
	BEGIN
		LOOP
			IF p = NIL THEN EXIT END ;
			IF p.left # NIL THEN NeXT(p.left) END ;
			userproc(p) ;
			p := p.right
		END
	END NeXT ;

BEGIN  NeXT(treehead)
END TraverseTree ;


END OETree .							
