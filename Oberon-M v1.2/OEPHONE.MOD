(* Phone number recording   
   (Oberon Example) (c) Copyright E. R. Videki 1991 *)
MODULE OEPhone ;
	IMPORT OETree , OEIO ;


(* this module is structured much like OENames.Mod, which has more comments
about what is going on *)


CONST MaxPhone * = 20 ;	

      PrtPhone * = 1 ;	(* command we will handle in our record nodes *)


TYPE	PhoneData * = ARRAY MaxPhone OF CHAR ;
	PhonePtr * = POINTER TO Phone ;
	Phone * = 	
		RECORD(OETree.Apple)
			phone *  : PhoneData 
		END ;


VAR PhoneTree *  : PhonePtr ;
    refnode : PhonePtr ;


PROCEDURE * Handler ( p : OETree.ApplePtr ;  cmd : INTEGER );
BEGIN
	IF cmd = PrtPhone THEN
		OEIO.WriteString(   p(PhonePtr).phone  )
	END
END Handler;



PROCEDURE * PhoneSearch(p,ref:OETree.ApplePtr;  VAR result:INTEGER); 
VAR i:INTEGER;
BEGIN
	IF p IS PhonePtr THEN
		WITH p : PhonePtr DO
			WITH ref : PhonePtr DO
				i := 0 ;
				WHILE (i < MaxPhone) & (p.phone[i] # 0X) & 
					(p.phone[i] = ref.phone[i]) DO INC(i) END;
				result := ORD(ref.phone[i]) - ORD(p.phone[i])
			END
		END
	ELSE result := -1 
	END
END PhoneSearch ;



PROCEDURE NewPhone * ( p : PhonePtr ;  VAR result : INTEGER) ;
BEGIN
	p.method := Handler ;
	OETree.AddNew( PhoneTree, p , result, PhoneSearch) 
END NewPhone;


PROCEDURE FindPhone * (VAR ph : PhoneData ;  VAR result:INTEGER;  VAR p : PhonePtr );
VAR p1 : OETree.ApplePtr ;
BEGIN
	refnode.phone := ph ;
	OETree.Search( PhoneTree, refnode, p1, result, PhoneSearch);
	IF result = 0 THEN p := p1(PhonePtr)
		(* expand scope for caller, from that of OETree's result *)
	ELSE p := NIL
	END
END FindPhone;


PROCEDURE Init;
VAR result : INTEGER;
BEGIN
	NEW(refnode);  refnode.phone[0] := 0X ;
	NEW(PhoneTree); PhoneTree.phone[0] := 0X;
	PhoneTree.refptr := NIL;   PhoneTree.method := Handler ;
	OETree.AddNew(NIL,PhoneTree,result,PhoneSearch)	(*set links in OETree's private flds*)
END Init;

BEGIN Init
END OEPhone.

