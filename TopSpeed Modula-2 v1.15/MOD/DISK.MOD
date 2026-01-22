MODULE disk;

IMPORT Str,Window,biosfio,Lib,IO,FIO,Lib;



TYPE chaine_octet = ARRAY[0..1] OF CHAR;
     t_disquette  = RECORD
                     unite              : SHORTCARD;
                     nbre_secteurs      : SHORTCARD;
                     nbre_pistes        : SHORTCARD;
                    END;
     t_domaine    = (haut,bas);


CONST fenetre1 = Window.WinDef(1,4,80,21,Window.White,Window.Black,FALSE,FALSE,
                               FALSE,TRUE,Window.DoubleFrame,Window.White,
                               Window.Black);
      fenetre2 = Window.WinDef(1,1,80,3,Window.White,Window.Black,FALSE,FALSE,
                               FALSE,TRUE,Window.DoubleFrame,Window.White,
                               Window.Black);
      fenetre3 = Window.WinDef(1,22,80,25,Window.White,Window.Black,TRUE,TRUE,
                               FALSE,FALSE,"        ",Window.Black,
                               Window.Black);
      un       = " nombre-pistes : ";
      deux     =" | nombre-secteurs : ";
      trois    = " | unit‚ : ";

VAR tampon : ARRAY[0..511] OF BYTE;
    i,x    : SHORTCARD;
    piste,secteur,tete,
    drive             : SHORTCARD;
    fen1,fen2,fen3    : Window.WinType;
    ascii             : ARRAY[0..255] OF CHAR;
    j                 : CARDINAL;
    nom_de_fichier1,
    nom_de_fichier2,
    nom_de_fichier3   : ARRAY[0..20] OF CHAR;
    fichier1,
    fichier2,
    fichier3          : FIO.File;
    f1,f2,f3          : BOOLEAN;
    ma_disquette      : t_disquette;
    titre             : ARRAY[0..79] OF CHAR;
    car               : CHAR;
    c1,c2,c3          : ARRAY[0..4] OF CHAR;
    ok                : BOOLEAN;
    z                 : SHORTCARD;
    mon_domaine       : t_domaine;
    ecran             : Window.WinType;


        PROCEDURE octet_hexa(x : BYTE):chaine_octet;

         TYPE t_hexa = ARRAY[0..15] OF CHAR;

         CONST c_hexa = t_hexa('0123456789ABCDEF');

         VAR c : chaine_octet;
             y : CARDINAL;

        BEGIN
         c:= "";
         y := VAL(CARDINAL,x);
         Str.Concat(c,c_hexa[y DIV 16],c_hexa[y MOD 16]);
         RETURN c;
        END octet_hexa;

    PROCEDURE affiche_secteur(domaine : t_domaine);

   (* domaine indique quelle partie des 512 octets … afficher *)
   (* octets 0 … 255 ou octets 256 … 512                      *)

     VAR   a,b  : CARDINAL;
           aa,bb: CARDINAL;

    BEGIN
     Window.Use(fen1);
     Window.Clear;
     IF domaine = haut THEN
      aa := 0;
      bb := 15;
     ELSE
      aa := 16;
      bb := 31;
     END;
         FOR a :=aa TO bb DO
           IO.WrChar(" ");
           IO.WrHex(a*16,4);
           IO.WrStr(" "+CHR(0B3H));
           FOR b := 0 TO 7 DO
            IO.WrStrAdj(octet_hexa(tampon[b+a*16]),3);
           END;
           IO.WrStr(" ");
           FOR b := 8 TO 15 DO
            IO.WrStrAdj(octet_hexa(tampon[b+a*16]),3);
           END;
           IO.WrStr(" "+CHR(0B3H)+" ");
           FOR b := 0 TO 15 DO
             IO.WrChar(ascii[ORD(tampon[b+a*16])]);
           END;
           IF  a < bb THEN  IO.WrLn END;
          END;
    END affiche_secteur;

 PROCEDURE message( d : ARRAY OF CHAR);

  BEGIN
   Window.Use(fen2);
   Window.Clear;
   IO.WrStr(d);
  END message;


  PROCEDURE teste_disquette( VAR d : t_disquette);

  VAR s,p,h : SHORTCARD;
      nbre_essai : CARDINAL;
      oui : BOOLEAN;

   BEGIN
    message("************************* test de la disquette ******************************");
    WITH d DO
     unite := 0;  (* … modifier si lecteur <> A *)
     (* d‚termination du nombre de secteurs  >= 1 *)
     s := 7;
     WHILE biosfio.lit_secteur (3,0,s,1,drive,tampon) = 0 DO
      INC(s)
     END;
     nbre_secteurs := s-1;
     h :=biosfio.reset();
     (* d‚termination du nombre de pistes >= 0 *)
     p := 35;
     WHILE biosfio.lit_secteur(p,0,1,1,drive,tampon) = 0 DO
      INC(p);
     END;
     nbre_pistes := p-1;
    END;
     h :=biosfio.reset();
   END teste_disquette;


  PROCEDURE bip();

   BEGIN
    Lib.Sound(440);
    Lib.Delay(100);
    Lib.NoSound;
   END bip;


 PROCEDURE init;

  BEGIN
     bip();
     Window.CursorOff;
     mon_domaine := haut;
     Lib.Fill(ADR(ascii),256,46);
     Lib.Fill(ADR(tampon),512,67);
     FOR j := 20H TO 255 DO
      ascii[j] := CHR(j)
     END;
     f1 := FALSE;
     f2 := FALSE;
     f3 := FALSE;
     piste := 0;
     secteur := 1;
     tete := 0;
  END init;

  PROCEDURE affichage;

   BEGIN
     fen1 := Window.Open(fenetre1);
     Window.CursorOff;
     fen2 := Window.Open(fenetre2);
     Window.CursorOff;
     Window.Use(fen2);
     Window.SetTitle(fen2,"   Eric Streit                    D‚cembre 91",Window.CenterUpperTitle);
     fen3 := Window.Open(fenetre3);
     Window.Use(fen3);
     Window.CursorOff;
     Window.GotoXY(1,22);
     IO.WrStr("  F1 :                     F2 :                      F3 :                     ");
     IO.WrLn;
     IO.WrStr(" [ : piste-1] [ : piste+1] [ : secteur-1] ["+CHR(26)+" : secteur+1] [ESC : Quitter]");
     IO.WrLn;
     IO.WrStr(" [Home : d‚but]    [END : Fin ]     [Tab  : commute partie haute/basse] ");
  END affichage;

  PROCEDURE affiche_caracteristiques;

  BEGIN
     WITH ma_disquette DO
      Str.CardToStr(VAL(LONGCARD,nbre_pistes+1),c1,10,ok);
      Str.CardToStr(VAL(LONGCARD,nbre_secteurs),c2,10,ok);
      Str.Concat(titre,un,c1);
      Str.Concat(titre,titre,deux);
      Str.Concat(titre,titre,c2);
      Str.Concat(titre,titre,trois);
      Str.Concat(titre,titre,CHR(VAL(CARDINAL,drive)+ 65));
     END;
     Window.SetTitle(fen1,titre,Window.CenterUpperTitle);
  END affiche_caracteristiques;


 PROCEDURE fichiers;

  BEGIN
     message(" ******************** Entrez un nom de fichier *******************************");
     Window.Use(fen3);
     Window.CursorOn;
     Window.GotoXY(8,1);
     IO.RdStr(nom_de_fichier1);
     Window.GotoXY(33,1);
     IO.RdStr(nom_de_fichier2);
     Window.GotoXY(59,1);
     IO.RdStr(nom_de_fichier3);
     IF Str.Length(nom_de_fichier1) > 0 THEN
      fichier1 :=  FIO.Create(nom_de_fichier1);
      f1 := TRUE;
     END;
     IF Str.Length(nom_de_fichier2) > 0 THEN
      fichier2 :=  FIO.Create(nom_de_fichier2);
      f2 := TRUE;
     END;
     IF Str.Length(nom_de_fichier3) > 0 THEN
      fichier3 :=  FIO.Create(nom_de_fichier3);
      f3 := TRUE;
     END;
     Window.CursorOff;
   END fichiers;

  PROCEDURE affiche;

    BEGIN
     message(" Piste :        Tˆte :       Secteur : ");
     Window.GotoXY(10,1);
     IO.WrShtCard(piste,3);
     Window.GotoXY(24,1);
     IO.WrShtCard(tete,3);
     Window.GotoXY(40,1);
     IO.WrShtCard(secteur,3);
     affiche_secteur(mon_domaine);
   END affiche;


 PROCEDURE mon_lecteur_est_il_pret;

    CONST fenetre4 = Window.WinDef(10,10,70,15,Window.White,Window.Black,FALSE,FALSE,
                               FALSE,TRUE,Window.DoubleFrame,Window.White,
                               Window.Black);
    VAR fen4 :Window.WinType;

   BEGIN
     fen4 := Window.Open(fenetre4);
     IO.WrStr(" ASSUREZ-VOUS D'AVOIR BIEN LE LECTEUR A ANALYSER PRET !!! ");
     IO.WrLn;
     IO.WrLn;
     IO.WrStr(" Entrz le nom du lecteur ( une seule lettre ) : ");
     drive := VAL(SHORTCARD,ORD(CAP(IO.RdChar()))-65);
     Window.Close(fen4);
    END mon_lecteur_est_il_pret;

BEGIN
     ecran := Window.Open(Window.FullScreenDef);
     Window.CursorOff;
     mon_lecteur_est_il_pret;
     affichage;
     init;
     teste_disquette(ma_disquette);
     affiche_caracteristiques;
     fichiers;
     Window.CursorOff;
     z := biosfio.lit_secteur(piste,tete,secteur,1,0,tampon);
     LOOP
      affiche;
      car := IO.RdKey();
      CASE car OF
       | CHR(27) : EXIT;
       | CHR(9)  : IF mon_domaine = haut THEN
                      mon_domaine := bas
                   ELSE mon_domaine := haut;
                   END;
       | CHR(0): car := IO.RdKey();
                  CASE car OF
                   | CHR(79) : tete := 1;
                               piste := ma_disquette.nbre_pistes;
                               secteur := ma_disquette.nbre_secteurs;
                               z := biosfio.lit_secteur(piste,tete,secteur,1,0,tampon);
                   | CHR(71) : tete := 0;
                               piste :=0;
                               secteur := 1;
                               z := biosfio.lit_secteur(piste,tete,secteur,1,0,tampon);
                   | CHR(72) : IF piste > 0 THEN DEC(piste);
                                z := biosfio.lit_secteur(piste,tete,secteur,1,0,tampon);
                               ELSE bip();
                               END;
                   | CHR(80) : IF piste < ma_disquette.nbre_pistes THEN
                                INC(piste);
                                z := biosfio.lit_secteur(piste,tete,secteur,1,0,tampon);
                               ELSE bip();
                               END;
                   | CHR(59) : IF f1 THEN FIO.WrBin(fichier1,tampon,512) END;
                   | CHR(60) : IF f2 THEN FIO.WrBin(fichier2,tampon,512) END;
                   | CHR(61) : IF f3 THEN FIO.WrBin(fichier3,tampon,512) END;
                   | CHR(75) : IF secteur > 1 THEN DEC(secteur)
                               ELSIF tete = 1 THEN
                                tete := 0;
                                secteur := ma_disquette.nbre_secteurs;
                               ELSIF piste > 0 THEN
                                DEC(piste);
                                tete := 1;
                                secteur := ma_disquette.nbre_secteurs;
                               ELSE bip();
                               END;
                               z := biosfio.lit_secteur(piste,tete,secteur,1,0,tampon);
                               mon_domaine := haut;
                   | CHR(77) : IF secteur < ma_disquette.nbre_secteurs THEN
                                INC(secteur)
                               ELSIF tete = 0 THEN
                                tete := 1;
                                secteur := 1;
                               ELSIF piste < ma_disquette.nbre_pistes THEN
                                INC(piste);
                                tete := 0;
                                secteur := 1;
                               ELSE bip();
                               END;
                               z := biosfio.lit_secteur(piste,tete,secteur,1,0,tampon);
                               mon_domaine := haut;
                  END;
       END;
      END; (* LOOP *)
    IF f1 THEN FIO.Close(fichier1) END;
    IF f2 THEN FIO.Close(fichier2) END;
    IF f3 THEN FIO.Close(fichier3) END;
    Window.Close(ecran);
END disk.