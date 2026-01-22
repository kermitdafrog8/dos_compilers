IMPLEMENTATION MODULE biosfio;

PROCEDURE erreur(x : SHORTCARD): CARDINAL;

 BEGIN
  IF x < 0BH THEN RETURN CARDINAL(x)
  ELSE
   CASE x OF
    | 10H : RETURN 10;
    | 20H : RETURN 11
    | 40H : RETURN 12;
    | 80H : RETURN 13;
   ELSE RETURN 255
   END;
  END;
 END erreur;

PROCEDURE reset(): SHORTCARD;

 VAR regs : Registers;

 BEGIN
  regs.AH := 00H;
  Intr(regs,13H);
  RETURN VAL(SHORTCARD,regs.AX);
 END reset;

PROCEDURE lit_secteur ( piste,tete,secteur,nbre_secteurs,drive : SHORTCARD ;
                        VAR buffer : ARRAY OF BYTE) : SHORTCARD ;

  VAR     nbre_essais : CARDINAL;

  VAR regs : Registers;


 BEGIN
  nbre_essais := 0;
  LOOP
      INC(nbre_essais);
      WITH regs DO
       AH := 02H;             (* code de la fonction 13H      *)
       AL := nbre_secteurs; (* nombre de secteurs … lire    *)
       CH := piste;
       CL := secteur;       (* numero du 1er secteur … lire *)
       DH := tete;          (* numero de tete ou face       *)
       DL := drive;         (* numero du lecteur            *)
       ES := Seg(buffer);   (* adresse ou ranger les donn‚es*)
       BX := Ofs(buffer);   (*                              *)
       Intr(regs,13H);
       AH := 01H;
       DL := drive;
       Intr(regs,13H);
       RETURN SHORTCARD(AH);
      END;
      IF (regs.AH = 0) OR (nbre_essais > 20) THEN EXIT END;
   END;
 END lit_secteur;


PROCEDURE ecrit_secteur ( piste,tete,secteur,nbre_secteurs,drive : SHORTCARD ;
                          VAR buffer : ARRAY OF BYTE) : SHORTCARD ;

  VAR regs : Registers;

  VAR nbre_essais : CARDINAL;



 BEGIN
  nbre_essais := 0;
  LOOP
      INC(nbre_essais);
      WITH regs DO
       AH := 03H;             (* code de la fonction 13H      *)
       AL := nbre_secteurs; (* nombre de secteurs … lire    *)
       CH := piste;
       CL := secteur;       (* numero du 1er secteur … lire *)
       DH := tete;          (* numero de tete ou face       *)
       DL := drive;         (* numero du lecteur            *)
       ES := Seg(buffer);   (* adresse ou ranger les donn‚es*)
       BX := Ofs(buffer);   (*                              *)
       Intr(regs,13H);
       AH := 01H;
       DL := drive;
       Intr(regs,13H);
       RETURN SHORTCARD(AH);
      END;
      IF (regs.AH = 0) OR (nbre_essais > 20) THEN EXIT END;
  END;
 END ecrit_secteur;


END biosfio.