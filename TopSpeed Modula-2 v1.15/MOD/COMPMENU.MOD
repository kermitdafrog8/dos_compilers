IMPLEMENTATION MODULE compmenu;

IMPORT IO,FIO,FIOR,Str,Storage,Window,SYSTEM;
FROM Storage IMPORT ALLOCATE,DEALLOCATE;

CONST   fenetre   =       Window.WinDef(10,10,47,13,Window.Black,Window.White,
                                        FALSE,FALSE,FALSE,TRUE,Window.SingleFrame,
                                        Window.White,Window.Black);


 VAR    ligne     :       ARRAY[0..100] OF CHAR;
        fichier   :       FIO.File;
        t_fenetre :       Window.WinType;

 VAR    menu_principal  :       BOOLEAN;
        type_menu       :       (PopUp,Pull_Down,LinePull);

 PROCEDURE compare(x,y:ARRAY OF CHAR): BOOLEAN;

  BEGIN
   RETURN  Str.Compare(x,y) = 0;
  END compare;

 CONST  message1 = "Il n'y a pas de fichier menu cr‚‚ !!";
        message2 = "      Tapez sur une touche          ";

 PROCEDURE erreur(x,y:ARRAY OF CHAR);

  BEGIN
   t_fenetre := Window.Open(fenetre);
   IO.WrStr(x);
   IO.WrLn;
   IO.WrStr(y);
   REPEAT UNTIL IO.KeyPressed();
   Window.Close(t_fenetre);
   HALT;
  END erreur;

 PROCEDURE init_menu(nom_de_fichier : FIO.PathStr);

  BEGIN
   FIO.EOF := FALSE;
   IF FIO.Exists(nom_de_fichier) THEN
    fichier := FIO.Open(nom_de_fichier);
   ELSE erreur(message1,message2);
   END;
  END init_menu;


TYPE    t_symbole = (t_decalage,t_mode,t_identificateur);

VAR ptr1,ptr2,ptr3,ptr4,ptr5 : ADDRESS;
    main,p_compile,
    p_ligne_debut,
    p_ligne_suivante,p_courant,
    p_lis_symbole,p5         : ADDRESS;
    symbole                  : RECORD
                                son_type : t_symbole;
                                nom : ARRAY[0..79] OF CHAR;
                               END;
    numero_ligne             : CARDINAL;
    position                 : CARDINAL;

 PROCEDURE lis_symbole;


        (* liste des symboles :

           ! !! PopUp LinePull PullDown Help [ ] | < > '
           { } Key

        *)
 TYPE   le_symbole = RECORD
                      CASE   : t_symbole OF
                       | t_decalage       : CARDINAL;
                       | t_identificateur : ARRAY[0..35] OF CHAR;
                      END;
                     END;


 CONST  blanc = " ";

  VAR ligne : ARRAY[0..127] OF CHAR;
      numero_item     : CARDINAL;
      fin_ligne       : CARDINAL;
      i               : CARDINAL;

  BEGIN
   LOOP
    WHILE NOT FIO.EOF DO
     REPEAT
      FIO.RdStr(fichier,ligne);
      Str.Item(symbole,ligne,Str.CHARSET{" "},1);
     UNTIL  (ligne[0]<>CHR(0)) AND NOT (compare(symbole,"!!"));
     fin_ligne := Str.Length(ligne);
     (* extraction des symboles de la phrase *)
     (****************************************)
     (*** calcul du d‚calage de chaque ligne *)
     decalage := 0;
     WHILE ligne[i] = blanc INC(decalage);
     (*** fin de ce calcul *******************)

     CASE ligne[i] OF

      symbole_suivant;
      SYSTEM.TRANSFER(p_lis_symbole,p_courant);

     (* fin de l'extraction des symboles *)
     (************************************)
    END; (* REPEAT *)
   END; (* LOOP *)
  END lis_symbole;

 PROCEDURE ligne_debut;

  BEGIN
   LOOP
    p_courant := SYSTEM.CurrentProcess();
    SYSTEM.TRANSFER(p_ligne_debut,p_lis_symbole);
         (***********************************)
        IF compare(symbole,"!") THEN
         IO.WrStr("ligne d‚but rencontr‚‚");IO.WrLn;
             (***********************)
             SYSTEM.TRANSFER(p_ligne_debut,p_lis_symbole);
               IF compare(symbole,"PopUp") THEN
                IO.WrStr("mode popup ");IO.WrLn;
               ELSIF compare(symbole,"LinePull") THEN
                IO.WrStr("mode LinePull");IO.WrLn
               ELSIF compare(symbole,"PullUp") THEN
                IO.WrStr("mode pullup");IO.WrLn;
               ELSE erreur("Erreur de syntaxe dans","ligne d‚but")
               END; (* IF *)
               (************)
               SYSTEM.TRANSFER(p_ligne_debut,p_lis_symbole);
               IF compare(symbole,"|") THEN
                IO.WrStr("pas de titre !!!");IO.WrLn;
                (*           SUITE                   *)
               ELSIF compare(symbole[0],"[") AND
                     compare(symbole[Str.Length(symbole)-1],"]") THEN
                Str.Item(symbole,symbole,Str.CHARSET{"[","]"},0);
                IO.WrStr("le titre est : ");IO.WrStr(symbole);IO.WrLn;
               ELSE erreur("Erreur de syntaxe dans","ligne d‚but")
               END; (* IF *)
               (****************)
             (***********************)
        ELSE erreur("Erreur de d‚finition du menu ","tapez sur une touche");
        END; (*IF*)
         (***********************************)
   END;(* LOOP *)
  END ligne_debut;

 PROCEDURE ligne_suivante;

  BEGIN
   LOOP

   END;(*LOOP *)
  END ligne_suivante;

 PROCEDURE compile;

  BEGIN
   Storage.ALLOCATE(ptr2,20000);
   SYSTEM.NEWPROCESS(ligne_debut,ptr2,20000,p_ligne_debut);
   SYSTEM.TRANSFER(p_compile,p_ligne_debut); (* DEFINITION du menu *)
   Storage.DEALLOCATE(ptr2,20000);
   LOOP
    IF FIO.EOF THEN SYSTEM.TRANSFER(p_compile,main) (* compilation finie *)
    ELSE SYSTEM.TRANSFER(p_compile,p_ligne_suivante);   (* lignes suivantes du menu *)
    END; (*IF*)
   END;
  END compile;

BEGIN
 init_menu("menu5.txt");
 Storage.ALLOCATE(ptr1,20000);
 Storage.ALLOCATE(ptr3,20000);
 Storage.ALLOCATE(ptr4,20000);
 main := SYSTEM.CurrentProcess();
 SYSTEM.NEWPROCESS(compile,ptr1,20000,p_compile);
 SYSTEM.NEWPROCESS(ligne_suivante,ptr3,20000,p_ligne_suivante);
 SYSTEM.NEWPROCESS(lis_symbole,ptr4,5000,p_lis_symbole);
 SYSTEM.TRANSFER(main,p_compile);
 Storage.DEALLOCATE(ptr1,20000);
 Storage.DEALLOCATE(ptr3,20000);
 Storage.DEALLOCATE(ptr4,20000);
END compmenu.