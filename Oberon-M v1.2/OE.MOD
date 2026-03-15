(*  "Main" module of names/phone organizer
    (Oberon Example)    (c) Copyright E.R.Videki 1991 *)

MODULE OE ;

        IMPORT OEIO ,   OETree ,   OENames ,   OEPhone  ;



PROCEDURE MakeName(VAR nm : OENames.NameString  ;   phoneref : OEPhone.PhonePtr ;
                        VAR p : OENames.NamePtr ) ;
VAR  i : INTEGER ;
BEGIN
        p := NIL ;
        IF nm[0] = 0X THEN RETURN END;  (* strange name... *)
        NEW(p) ;
        p.refptr := phoneref ;  (*may be NIL, but that's ok *)
        p.name := nm ;
        OENames.NewName( p ,  i );
        IF i # 0 THEN OEIO.WriteString("*** Error: can't add that name");
                OEIO.WriteLn; p := NIL
        END
END MakeName ;


PROCEDURE MakePhone(VAR ph : OEPhone.PhoneData ;  nameref : OENames.NamePtr ;
                        VAR p : OEPhone.PhonePtr ) ;
VAR i : INTEGER ;
BEGIN
        p := NIL ;
        IF ph[0] = 0X THEN RETURN END ; (* ? *)
        NEW(p);
        p.refptr := nameref ;
        p.phone := ph ;
        OEPhone.NewPhone(p, i );
        IF i # 0 THEN OEIO.WriteString("*** Error: can't add that phone number");
                OEIO.WriteLn; p := NIL
        END
END MakePhone ;


PROCEDURE FindName(VAR nm : OENames.NameString) ;
VAR p : OENames.NamePtr ;  i : INTEGER ;
BEGIN
        OENames.FindName( nm ,  i ,  p) ;       (* see if name is on the tree somewhere*)
        IF i = 0 THEN   (* name was found... display it *)
                        OEIO.WriteString("Name: ");
                        p.method( p , OENames.PutName ) ;
                                (* the node handler takes care of showing it *)
                        OEIO.WriteString("    Phone number: ");
                        IF p.refptr = NIL THEN OEIO.WriteString(" <unknown>")
                        ELSE p.refptr.method( p.refptr , OEPhone.PrtPhone )
                                (* node handler for phone number display*)
                        END ;
                        OEIO.WriteLn
        ELSE OEIO.WriteString("<not found>"); OEIO.WriteLn
        END
END FindName ;


PROCEDURE FindPhone(VAR ph : OEPhone.PhoneData ) ;
VAR p : OEPhone.PhonePtr ;  i : INTEGER;
BEGIN
        OEPhone.FindPhone( ph ,  i ,  p );
        IF i = 0 THEN   (* phone was found... *)
                        OEIO.WriteString("Phone: ");
                        p.method( p , OEPhone.PrtPhone ) ;
                                (* method displays phone number for us*)
                        OEIO.WriteString("   Name : ");
                        IF p.refptr = NIL THEN OEIO.WriteString("<nobody>")
                        ELSE  p.refptr.method( p.refptr , OENames.PutName )
                        END ;
                        OEIO.WriteLn
        ELSE  OEIO.WriteString("<not found>"); OEIO.WriteLn
        END
END FindPhone ;



(*  *** This section contains "commands" used when this application runs under the
        ETH Oberon System instead of MSDOS
        (and OEIO has been changed to use Texts) ***



PROCEDURE AddName *  ;
VAR  nm : OENames.NameString ;  pnm : OENames.NamePtr ;
        ph : OEPhone.PhoneData ; pph : OEPhone.PhonePtr ;
BEGIN
        OEIO.Init ;
        OEIO.GetInput(nm) ;
        IF nm[0] # 0X THEN (*something there! *)
                MakeName(nm, NIL, pnm ) ;
                IF pnm # NIL THEN
                        OEIO.WriteString(" Name entered ") ;
                        OEIO.GetInput(ph);
                        IF ph[0] # 0X THEN      (* phone number also supplied *)
                                MakePhone(ph, pnm, pph) ;       (* phone references name node*)
                                IF pph # NIL THEN
                                        OEIO.WriteString(" - and number entered");
                                        pnm.refptr :=  pph
                                                (* now name references the phone node too*)
                                ELSE OEIO.WriteString(" Could not add the phone number")
                                END
                        ELSE OEIO.WriteString(" No phone number added")
                        END
                END
        END ;
        OEIO.WriteLn
END AddName ;



PROCEDURE NameSearch *  ;
VAR nm : OENames.NameString ;
BEGIN
        OEIO.Init ;
        OEIO.GetInput(nm) ;
        IF nm[0] # 0X THEN FindName(nm) END
END NameSearch ;



PROCEDURE PhoneSearch * ;
VAR ph : OEPhone.PhoneData ;
BEGIN
        OEIO.Init ;
        OEIO.GetInput(ph);
        IF ph[0] # 0X THEN FindPhone(ph) END
END PhoneSearch ;


       *** End of ETH Oberon System Commands area *** *)

(* *** beginning of common routines shared among Oberon-M (MSDOS) and Oberon System from ETH *** *)
(*      (note that ShowAll is an Oberon System command also) *)


PROCEDURE * DisplayNode ( p : OETree.ApplePtr ) ;       (* used in "ShowAll" proc below*)
(* this procedure shows how to handle various kinds of type-extended records in one routine*)
VAR cmd, cmd1 : INTEGER ;
BEGIN
        IF p # NIL THEN
                OEIO.WriteString("-->");
                IF p IS OENames.NamePtr THEN cmd := OENames.PutName ;
                        cmd1 := OEPhone.PrtPhone
                ELSE cmd := OEPhone.PrtPhone ;  cmd1 := OENames.PutName
                END;
                p.method( p , cmd ) ;
                        (* record-dependent "method" for printing that kind of record *)
                IF p.refptr # NIL THEN
                        OEIO.WriteString("    linked to: ");
                        p.refptr.method( p.refptr , cmd1 ) ;
                END ;
                OEIO.WriteString("<--");  OEIO.WriteLn
        END
END DisplayNode ;


   (* NOTE: for use under Oberon System, make the export mark below uncommented! *)

PROCEDURE ShowAll (* * *);      (* A database dump of all names and phone numbers*)
BEGIN
        OEIO.WriteString("Names tree: "); OEIO.WriteLn ;
        IF OENames.NameTree = NIL THEN
                OEIO.WriteString("Names tree is empty") ; OEIO.WriteLn
        ELSE OETree.TraverseTree( DisplayNode , OENames.NameTree )
        END ;

        OEIO.WriteLn ; OEIO.WriteString("Phone tree: "); OEIO.WriteLn;
        IF OEPhone.PhoneTree = NIL THEN
                OEIO.WriteString("Phone tree is empty"); OEIO.WriteLn
        ELSE OETree.TraverseTree( DisplayNode , OEPhone.PhoneTree )
        END
END ShowAll ;

(* *** End of common routines between Oberon-M MSDOS and ETH Oberon System *** *)



(* *** Below are MSDOS specific routines.
        Note that the module initialization must invoke MainLoop *** *)

(*  *** Oberon-M main-loop for use under MSDOS ***  *)
PROCEDURE MainLoop ;
VAR nm : OENames.NameString ;   ph : OEPhone.PhoneData ;  i : INTEGER ;  ch:CHAR ;
    pnm : OENames.NamePtr ;   pph : OEPhone.PhonePtr ;
BEGIN
LOOP
        OEIO.WriteString("***Enter a number to select a function: "); OEIO.WriteLn ;
        OEIO.WriteString("    0   (Exit from the program) " ); OEIO.WriteLn;
        OEIO.WriteString("    1   (Enters a new name and phone number) " ); OEIO.WriteLn;
        OEIO.WriteString("    2   (Using a name, search for a phone number)" ); OEIO.WriteLn ;
        OEIO.WriteString("    3   (Using a phone number, search for a name)" ); OEIO.WriteLn ;
        OEIO.WriteString("    4   (List out the name and phone databases)" ); OEIO.WriteLn ;
        OEIO.GetInput(nm) ;  OEIO.WriteLn;
        (* the following is a very lazy way to handle the choices, but after all,
           this is just an example! *)
        i := 0 ;  WHILE (nm[i]  = " ") OR (nm[i] = 09X (*horizontal tab*)) DO INC(i) END;
        ch := nm[i] ;
        IF ch = "0" THEN EXIT
        ELSIF ch = "1" THEN
                        OEIO.WriteString("Enter name: ");  OEIO.GetInput(nm); OEIO.WriteLn;
                        OEIO.WriteString("Enter phone number: ");
                        OEIO.GetInput(ph) ;  OEIO.WriteLn;
                        IF nm[0] # 0X THEN  (* check for empty name *)
                                MakeName( nm, NIL, pnm) ;
                                IF (pnm # NIL) & (ph[0] # 0X) THEN MakePhone(ph, pnm, pph) ;
                                                IF pph # NIL THEN pnm.refptr := pph END
                                                (*name points to phone too*)
                                END
                        END
        ELSIF ch = "2" THEN
                        OEIO.WriteString("Enter name: "); OEIO.GetInput(nm);  OEIO.WriteLn;
                        FindName(nm)
        ELSIF ch = "3" THEN
                        OEIO.WriteString("Enter phone number: "); OEIO.GetInput(ph);
                        OEIO.WriteLn;
                        FindPhone(ph)
        ELSIF ch = "4" THEN ShowAll
        ELSE OEIO.WriteString("** ? Unknown command. Please enter one of the numbers shown.");
                OEIO.WriteLn
        END
END (*LOOP*)
END MainLoop ;

(* ETH Oberon System: put comments around the following call to MainLoop  *)
BEGIN MainLoop
END OE.



