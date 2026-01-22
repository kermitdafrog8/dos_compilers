(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  FIOR.MOD - Redirection file support                                     *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*# call(o_a_copy=>off) *)
(*%F _fdata *)
(*# call(seg_name => null) *)
(*# data(seg_name => null) *)
(*%E *)
(*# module(implementation=>off) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE FIOR ;

(*# call(o_a_copy=>off) *)
FROM Storage  IMPORT ALLOCATE,DEALLOCATE,Available ;

(*%F _OS2 *)
IMPORT Str, Lib, SYSTEM, CoreMain;
(*%E *)
(*%T _OS2 *)
IMPORT Str, Lib, SYSTEM, Dos, CoreMain;
(*%E *)
(*%T _mthread *)
IMPORT Process, CoreProc;
(*%E *)

TYPE

   String   = ARRAY[0..255] OF CHAR ;
   StrPtr  = POINTER TO String ;
   STP     = POINTER TO PathStr ;

   OpenMode = ( OMopen, OMcreate, OMopenrw ) ;


CONST
  StrTabSize = 8192 ;
  StrTabMax  = StrTabSize-1 ;

VAR
  StrTab      : ARRAY [0..StrTabMax] OF CHAR ;
  FilesBase   : CARDINAL ;
  NoOfStrings : CARDINAL ;
  LastDelPtr  : CARDINAL ;
  StrTabPtr   : CARDINAL ;

CONST
   MaxNoOfConversions = 50 ;


VAR
   NoOfConversions : CARDINAL ;
   Conversion      : ARRAY[1..MaxNoOfConversions] OF CARDINAL ;
(*%F _mthread *)
   IOR             : CARDINAL ;
(*%E *)
(*%T _mthread *)
   IOR: ARRAY [1..Process.MaxProcess] OF CARDINAL;
(*%E *)

PROCEDURE SetIOR(Num: CARDINAL);

BEGIN
(*%T _mthread *)
  IOR[CoreProc._getTID()] := Num;
(*%E *)
(*%F _mthread *)
  IOR := Num;
(*%E *)
END SetIOR;

PROCEDURE AddText ( s : ARRAY OF CHAR ) : CARDINAL ;
VAR
  len : CARDINAL ;
  p   : CARDINAL ;
BEGIN
  len := Str.Length(s) ;
  IF (len+StrTabPtr+1 >= SIZE(StrTab)) THEN RETURN 0 END ;
  p := StrTabPtr ;
  Lib.Move(ADR(s),ADR(StrTab[StrTabPtr]),len) ;
  INC(StrTabPtr,len) ;
  StrTab[StrTabPtr] := 0C ;
  INC(StrTabPtr) ;
  RETURN p ;
END AddText ;


CONST
  FileBuffSize = 4096 ;
  FileBuffMax  = FileBuffSize-1 ;

TYPE
  FileBuffPtr  = POINTER TO CHAR ;
VAR
  FileBuff     : FileBuffPtr ;
  FileBuffBase : FileBuffPtr ;


PROCEDURE OpenTextFile ( name : ARRAY OF CHAR ) : BOOLEAN ;
VAR
  s  : ARRAY[0..79] OF CHAR ;
  fb : FileBuffPtr ;
BEGIN
  TextFile := Open(name) ;
  IF TextFile = Null THEN RETURN FALSE END ;
  ALLOCATE(fb, FileBuffSize+1) ;
  FileBuffBase := fb ;
  FileBuff := fb ;
  INC(CARDINAL(FileBuff), FileBuffSize);
  RETURN TRUE ;
END OpenTextFile ;




PROCEDURE ReadTextLn ( VAR l : ARRAY OF CHAR ) ;
VAR c : CHAR ;
    i : CARDINAL ;

PROCEDURE ReadTextChar () : CHAR ;
VAR
  count : CARDINAL ;
  fbp   : FileBuffPtr ;
BEGIN
  INC(CARDINAL(FileBuff), 1);
  IF CARDINAL(FileBuff) - CARDINAL(FileBuffBase) >=FileBuffSize THEN
    FileBuff := FileBuffBase;
    count := FIO.RdBin(TextFile,FileBuff^,FileBuffSize) ;
    IF count<>FileBuffSize THEN
      fbp := Lib.AddAddr(FileBuffBase, count) ;
      fbp^ := CHR(26) ;
    END ;
  END ;
  RETURN FileBuff^ ;
END ReadTextChar ;


BEGIN
   i := 0 ;
   FileBuff := FileBuff ;
   REPEAT (* clear LFs *)
     IF CARDINAL(FileBuff) - CARDINAL(FileBuffBase) >=FileBuffMax THEN c := ReadTextChar()
     ELSE
       INC(CARDINAL(FileBuff), 1);
       c := FileBuff^ ;
     END ;
   UNTIL c<>CHR(10) ;
   IF c=CHR(26) THEN l[0] := c ; INC(i) ;  (* check for EOF *)
   ELSE
     LOOP
       IF (c>=' ')AND(i<HIGH(l)) THEN l[i] := c ; INC(i) ;
       ELSIF (c = CHR(13))OR(c=CHR(26)) THEN EXIT  (* EOF treated as end of line *)
       END ;
       IF CARDINAL(FileBuff) - CARDINAL(FileBuffBase) >=FileBuffMax THEN c := ReadTextChar()
       ELSE
         INC(CARDINAL(FileBuff), 1);
         c := FileBuff^ ;
       END ;
     END ;
   END ;
   l[i] := 0C ;
END ReadTextLn ;

PROCEDURE CloseTextFile ;
VAR
  fb : POINTER TO ARRAY[0..FileBuffMax] OF CHAR ;
BEGIN
  IF TextFile<>Null THEN
    FIO.Close(TextFile) ;
  END ;
  SetIOR(FIO.IOresult());
  DEALLOCATE(FileBuffBase, FileBuffSize+1) ;
END CloseTextFile ;

(*%F _OS2 *)
PROCEDURE DosCall ( VAR R : SYSTEM.Registers ) : BOOLEAN ;
BEGIN
(*%T _mthread *)
(*%F _OS2 *)
  Process.Lock();
(*%E *)
(*%E *)
  Lib.Dos(R) ;
(*%T _mthread *)
(*%F _OS2 *)
  Process.Unlock();
(*%E *)
(*%E *)
  WITH R DO
    IF (BITSET{SYSTEM.CarryFlag}*Flags)#BITSET{} THEN
      SetIOR(AX);
      RETURN TRUE ;
    ELSE
      SetIOR(0) ;
      RETURN FALSE ;
    END ;
  END ;
END DosCall ;

PROCEDURE GetDosVersion (): CARDINAL;
VAR r : SYSTEM.Registers; t : SHORTCARD;
BEGIN
  WITH r DO
    AH := 30H;
    Lib.Dos(r);
    t  := AH;
    AH :=AL;
    AL :=t;
    RETURN AX
  END;
END GetDosVersion;

PROCEDURE ExpandPath (     path     : ARRAY OF CHAR ;
                           VAR fullpath : ARRAY OF CHAR ) ;

VAR
  i,p,l : CARDINAL ;
  c     : CHAR ;
  hp    : CARDINAL ;
  lim   : CARDINAL ;
  R     : SYSTEM.Registers ;
  ps    : ARRAY[0..13] OF CHAR ;
  po    : PathStr ;

BEGIN
  WITH R DO
    i := 0 ;
    hp := HIGH(path) ;
    IF (hp=0)OR(path[1]<>':')OR(path[0]=0C) THEN
       AH := 19H ;
       Lib.Dos(R) ;
       po[0] := CHR(SHORTCARD('A')+AL) ;
       p := 0 ;
    ELSE
       po[0] := CAP(path[0]) ;
       p := 2 ;
    END ;
    po[1] := ':' ;
    po[2] := '\' ;
    IF path[p]<>'\' THEN
      DL := SHORTCARD(po[0])-SHORTCARD('A')+1 ;
      DS := Seg(po) ;
      SI := Ofs(po[3]) ;
      AH := 47H ;
      IF DosCall(R) THEN
         fullpath[0] := 0C ;
         RETURN ;
      END ;
      i := Str.Length(po) ;
      IF (i>3) THEN po[i] := '\' ; INC(i) ; END ;
    ELSE
      i := 3 ; INC(p) ;
    END ;
    po[i] :=CHR (0) ;
    LOOP
      i := 0 ;
      lim := 8 ;
      LOOP
        IF (p>hp) THEN ps[i] := '\' ; INC(i); EXIT; END ;
        c := path[p] ; INC(p) ;
        IF (c=0C)OR(c='\') THEN ps[i] := '\' ; INC(i); EXIT; END;
        IF (c='.')           THEN ps[i] := c   ; INC(i); lim := 3;
        ELSIF (lim>0)        THEN ps[i] := c   ; INC(i); DEC(lim) ;
        END ;
      END ;
      ps[i] := 0C ;
      IF (i>1) THEN
         IF ps[0] = '.' THEN                    (* .. = parent *)
            IF (i=3)AND(ps[1]='.') THEN
               l := Str.Length(po)-1 ;
               IF l>2 THEN
                 WHILE (po[l-1]<>'\') DO DEC(l) END ;
               END ;
               po[l] := 0C ;
            ELSIF i<>2 THEN
               Str.Append(po,ps) ;
            END ;
         ELSE
            Str.Append(po,ps) ;
         END ;
      END ;
      IF c=0C THEN EXIT END ;
    END ;
    l := Str.Length(po)-1 ;
    IF (l>2) AND (po[l] = '\') THEN po[l] := 0C END ;
    Str.Copy(fullpath,po) ;
    Str.Caps(fullpath) ;
  END ;
END ExpandPath ;
(*%E *)

(*%T _OS2 *)
PROCEDURE GetDosVersion(): CARDINAL;

VAR
  Version: CARDINAL;

BEGIN
  Dos.GetVersion(Version);
  RETURN Version;
END GetDosVersion;

(* Utility routines *)

PROCEDURE ExpandPath (     path     : ARRAY OF CHAR ;
                           VAR fullpath : ARRAY OF CHAR ) ;

VAR
  i,p,l : CARDINAL ;
  c     : CHAR ;
  hp    : CARDINAL ;
  lim   : CARDINAL ;
  ps    : ARRAY[0..13] OF CHAR ;
  po    : PathStr ;
  Drive, Length : CARDINAL;
  Map: LONGCARD;

BEGIN
    i := 0 ;
    hp := HIGH(path) ;
    IF (hp=0)OR(path[1]<>':')OR(path[0]=0C) THEN
       SYSTEM.Eval(Dos.QCurDisk(Drive, Map));
       po[0] := CHR(CARDINAL('A')+Drive-1) ;
       p := 0 ;
    ELSE
       po[0] := CAP(path[0]) ;
       p := 2 ;
    END ;
    po[1] := ':' ;
    po[2] := '\' ;
    IF path[p]<>'\' THEN
      Drive := CARDINAL(po[0])-CARDINAL('A')+1 ;
      Length := 77;
      SYSTEM.Eval(Dos.QCurDir(Drive, FarADR(po[3]), Length));
      i := Str.Length(po) ;
      IF (i>3) THEN po[i] := '\' ; INC(i) ; END ;
    ELSE
      i := 3 ; INC(p) ;
    END ;
    po[i] :=CHR (0) ;
    LOOP
      i := 0 ;
      lim := 8 ;
      LOOP
        IF (p>hp) THEN ps[i] := '\' ; INC(i); EXIT; END ;
        c := path[p] ; INC(p) ;
        IF (c=0C)OR(c='\') THEN ps[i] := '\' ; INC(i); EXIT; END;
        IF (c='.')           THEN ps[i] := c   ; INC(i); lim := 3;
        ELSIF (lim>0)        THEN ps[i] := c   ; INC(i); DEC(lim) ;
        END ;
      END ;
      ps[i] := 0C ;
      IF (i>1) THEN
         IF ps[0] = '.' THEN                    (* .. = parent *)
            IF (i=3)AND(ps[1]='.') THEN
               l := Str.Length(po)-1 ;
               IF l>2 THEN
                 WHILE (po[l-1]<>'\') DO DEC(l) END ;
               END ;
               po[l] := 0C ;
            ELSIF i<>2 THEN
               Str.Append(po,ps) ;
            END ;
         ELSE
            Str.Append(po,ps) ;
         END ;
      END ;
      IF c=0C THEN EXIT END ;
    END ;
    l := Str.Length(po)-1 ;
    IF (l>2) AND (po[l] = '\') THEN po[l] := 0C END ;
    Str.Copy(fullpath,po) ;
    Str.Caps(fullpath) ;
END ExpandPath ;
(*%E *)

PROCEDURE AbsolutePath ( name : ARRAY OF CHAR ) : BOOLEAN ;
BEGIN
  RETURN (name[0]='\')OR(name[1]=':')  ;
END AbsolutePath ;

PROCEDURE SplitPath (     path : ARRAY OF CHAR ;
                      VAR head,tail : ARRAY OF CHAR ) ;
VAR
   L : CARDINAL ;
   c : CHAR ;
   i : CARDINAL ;
BEGIN
   i := Str.Length(path) ;
   LOOP
     IF (i=0) THEN EXIT END ;
     DEC(i) ; c := path[i] ;
     IF (c='\') THEN EXIT END ;
     IF (c=':') THEN INC(i) ; EXIT END ;
   END ;
   Str.Slice(head,path,0,i) ;
   IF c='\' THEN INC(i) END ;
   Str.Slice(tail,path,i,HIGH(tail)+1) ;
   Str.Caps(head) ; Str.Caps(tail) ;
END SplitPath ;

PROCEDURE MakePath (  VAR path : ARRAY OF CHAR  ;
                             head,tail : ARRAY OF CHAR ) ;
VAR
  l : CARDINAL ;
BEGIN
  ExpandPath(head,path);
  l := Str.Length(path) ;
  IF (path[l-1]<>'\') THEN
    IF (tail[0]<>'\')AND(l<HIGH(path)) THEN
      path[l] := '\' ;
      path[l+1] := 0C ;
    END ;
  ELSIF (tail[0]='\') THEN
    path[l-1] := 0C ;
  END ;
  Str.Append(path,tail) ;
  ExpandPath(path,path) ;
END MakePath ;

PROCEDURE ExtensionPos ( VAR s : ARRAY OF CHAR ) : CARDINAL ;
VAR
  c : CHAR ;
  l,i : CARDINAL ;
BEGIN
  l := Str.Length(s) ;
  IF l=0 THEN RETURN MAX(CARDINAL) END ;
  i := l ;
  REPEAT
    DEC(i) ;
    c := s[i] ;
  UNTIL (i=0) OR (c='\') OR (c=':') OR (c='.') ;
  IF (c='.') THEN RETURN i END ;
  RETURN MAX(CARDINAL) ;
END ExtensionPos ;



PROCEDURE AddExtension ( VAR s : ARRAY OF CHAR ; ext : ARRAY OF CHAR ) ;
BEGIN
  IF ExtensionPos(s)=MAX(CARDINAL) THEN
    Str.Append(s,'.') ;
    IF (ext[0]<=' ') THEN RETURN END ;
    Str.Append(s,ext) ;
  END ;
END AddExtension ;

PROCEDURE RemoveExtension ( VAR s : ARRAY OF CHAR ) ;
VAR
  p : CARDINAL ;
BEGIN
  p := ExtensionPos(s) ;
  IF p<>MAX(CARDINAL) THEN s[p] := 0C END ;
END RemoveExtension ;


PROCEDURE ChangeExtension ( VAR s : ARRAY OF CHAR ; ext : ARRAY OF CHAR ) ;
BEGIN
  RemoveExtension(s) ;
  AddExtension(s,ext) ;
END ChangeExtension ;

PROCEDURE IsExtension ( s : ARRAY OF CHAR ; ext : ARRAY OF CHAR ) : BOOLEAN ;
VAR
  es: PathStr;
BEGIN
  Str.Concat(es, '*.', ext);
  RETURN Str.Match(s, es);
END IsExtension ;


PROCEDURE FindAndOpenPath ( name    : ARRAY OF CHAR ;
                                   om      : OpenMode ;
                                   VAR fullname  : PathStr ;
                                   VAR h       : File ) : BOOLEAN ;
VAR
  l      : CARDINAL ;
  i,p    : CARDINAL ;
  sp     : StrPtr ;
  path   : PathStr ;

  amatch : BOOLEAN ;
  savep  : CARDINAL ;

  PROCEDURE TestFileExists ( name : ARRAY OF CHAR ) : BOOLEAN ;
  VAR
    path : PathStr ;
    found : BOOLEAN ;
  BEGIN
    ExpandPath(name,path) ;
    IF om=OMcreate THEN found := TRUE
    ELSE
        IF om=OMopen THEN
          h :=  FIO.OpenRead(path) ;
        ELSE
          h :=  FIO.Open(path) ;
        END;
        SetIOR(FIO.IOresult());
        found := (IOresult()=0) ;
        IF (IOresult()<>0) THEN h := Null END ;
    END ;
    IF found THEN Str.Copy(fullname,path) END ;
    RETURN found ;
  END TestFileExists ;


BEGIN
  SetIOR(0);
  amatch := FALSE ;
  h := Null ;
  IF AbsolutePath(name) THEN i := NoOfConversions
                        ELSE i := 0 ;
  END ;
  LOOP
    INC(i) ;
    IF i>NoOfConversions THEN
      IF NOT amatch THEN
         IF TestFileExists ( name ) THEN
            RETURN TRUE
         END ;
      END ;
      RETURN FALSE ;
    END ;
    p := Conversion[i] ;
    sp := ADR(StrTab[p]) ;
    IF Str.Match(name,sp^) THEN
       amatch := TRUE ;
       LOOP
         INC(p,Str.Length(sp^)+1) ;
         sp := ADR(StrTab[p]) ;
         IF sp^[0]=0C THEN EXIT END ;
         MakePath(path,sp^,name) ;
         IF TestFileExists ( path ) THEN
           RETURN TRUE ;
         END ;
       END ;
    END ;
  END ;
END FindAndOpenPath ;

PROCEDURE FindPath     ( name    : ARRAY OF CHAR ;
                         VAR fullname  : PathStr ) : BOOLEAN ;
VAR
  h : File ;
  b : BOOLEAN ;
BEGIN
  b := FindAndOpenPath(name,OMopen,fullname,h) ;
  IF h<>Null THEN FIO.Close(h) END ;
  RETURN b ;
END FindPath ;

PROCEDURE FindNewPath (     name    : ARRAY OF CHAR ;
                        VAR fullname  : PathStr ) : BOOLEAN ;
VAR
  h : File ;
  b : BOOLEAN ;
BEGIN
  b := FindAndOpenPath(name,OMcreate,fullname,h) ;
  IF h<>Null THEN FIO.Close(h) END ;
  RETURN b ;
END FindNewPath ;



PROCEDURE OpenOrCreateFile ( name    : ARRAY OF CHAR ;
                             om      : OpenMode ) : CARDINAL ;
VAR
  h      : File ;
BEGIN
  h := Null ;
  SetIOR(0);
  IF FindAndOpenPath(name,om,LastPath,h) THEN
    IF (h=Null)OR(IOresult()<>0) THEN
      IF h<>Null THEN FIO.Close(h) END ;
      ExpandPath(LastPath,LastPath) ;
      IF om=OMcreate     THEN h := FIO.Create(LastPath)
      ELSIF om=OMopen    THEN h :=  FIO.OpenRead(LastPath) ;
                         ELSE h :=  FIO.Open(LastPath) ;
      END;
      SetIOR(FIO.IOresult());
    END ;
  ELSE
    IF IOresult()=0 THEN SetIOR(2) END ;
  END ;
  IF IOresult()<>0 THEN
    h := Null ;
  END ;
  RETURN h ;
END OpenOrCreateFile ;


PROCEDURE Create ( name    : ARRAY OF CHAR ) : File ;
BEGIN
  RETURN OpenOrCreateFile(name,OMcreate) ;
END Create ;


PROCEDURE Open ( name    : ARRAY OF CHAR ) : File ;
BEGIN
  RETURN OpenOrCreateFile(name,OMopen) ;
END Open ;

PROCEDURE OpenRW ( name    : ARRAY OF CHAR ) : File ;
BEGIN
  RETURN OpenOrCreateFile(name,OMopenrw) ;
END OpenRW ;



(* Redirected calls *)


PROCEDURE Erase ( name    : ARRAY OF CHAR ) ;
VAR
  path : PathStr ;
BEGIN
  IF FindPath(name,path) THEN
    FIO.Erase(path) ;
  END ;
END Erase ;

PROCEDURE DelLeading ( VAR R : ARRAY OF CHAR ) ;
BEGIN
  WHILE (R[0]>0C)AND(R[0]<=' ') DO Str.Delete(R,0,1) END ;
END DelLeading ;




PROCEDURE ReadRedirectionFile ( name : ARRAY OF CHAR ) ;
TYPE
  Str3 = ARRAY[0..2] OF CHAR ;
VAR
  line  : ARRAY[0..255] OF CHAR ;
  item  : ARRAY[0..64] OF CHAR ;
  outp  : BOOLEAN ;
  pat   : CARDINAL ;
  n,i   : CARDINAL ;
  path  : PathStr ;
BEGIN
  NoOfConversions := 0 ;
  IF FindExePath(name,TRUE,path) THEN END ;
  IF NOT OpenTextFile(path) THEN
    RETURN
  END ;
  outp := TRUE ;
  LOOP
    ReadTextLn(line) ;
    IF line[0]=CHR(26) THEN EXIT END ;
    Str.Caps(line) ;
    DelLeading(line) ;
    Str.ItemS(item,line,' ,=;',0) ;
    IF item[0]<>0C THEN
      INC(NoOfConversions) ;
      Conversion[NoOfConversions] := AddText(item) ;
      i := 0 ;
      REPEAT
        INC(i) ;
        Str.ItemS(item,line,' =,;',i) ;
        n := AddText(item) ;
      UNTIL item[0]=0C ;
    END ;
    IF NoOfConversions=MaxNoOfConversions THEN EXIT END ;
  END ;
  CloseTextFile ;
  StrTabPtr := 1 ;
END ReadRedirectionFile ;


PROCEDURE FindExePath ( path    : ARRAY OF CHAR ;
                        ovl     : BOOLEAN ;
                        VAR outpath : PathStr ) : BOOLEAN ;
VAR
  fp      : PathStr ;
  str     : StrPtr ;
  l       : CARDINAL ;
  envpath : String ;
  n       : CARDINAL ;
BEGIN
  Str.Copy(outpath,path) ;
  IF FindPath(path,outpath) THEN
    RETURN TRUE ;
  END ;
  IF AbsolutePath(path) THEN RETURN FALSE END ;
  IF ovl AND (GetDosVersion() >= 300H) THEN
     str := StrPtr(CoreMain._argv[0]);
     Str.Copy(fp,str^) ;
     l := Str.Length( fp ) ;
     LOOP
        IF l=0 THEN fp[0] := 0C; EXIT; END;
        DEC(l);
        IF fp[l]='\' THEN EXIT END;
     END;
     fp[l+1] := 0C;
     MakePath(fp,fp,path) ;
     IF FindPath(fp,outpath) THEN RETURN TRUE END ;
  END;
  Lib.EnvironmentFind('PATH',envpath) ;
  n := 0 ;
  LOOP
    Str.ItemS(fp,envpath,' =;,',n) ;
    IF fp[0]=0C THEN RETURN FALSE END ;
    MakePath(fp,fp,path) ;
    IF FindPath(fp,outpath) THEN RETURN TRUE END ;
    INC(n) ;
  END ;
END FindExePath ;

PROCEDURE IOresult () : CARDINAL ;
BEGIN
(*%F _mthread *)
  RETURN IOR ;
(*%E *)
(*%T _mthread *)
  RETURN IOR[CoreProc._getTID()] ;
(*%E *)
END IOresult ;


PROCEDURE Init ;

VAR
  RedFile: ARRAY [0..80] OF CHAR;
BEGIN
  NoOfConversions := 0 ;
  StrTab[0] := 0C ;
  StrTabPtr := 1 ;
  LastDelPtr := 0 ;
  NoOfStrings := 0 ;
  FIO.IOcheck := FALSE ;
  Lib.EnvironmentFind('TSRED', RedFile);
  IF RedFile[0] = 0C THEN
    RedFile := 'TS.RED';
  END;
  ReadRedirectionFile(RedFile);
END Init ;

(*%T _mthread *)
VAR
  n : [1..Process.MaxProcess];
(*%E *)
BEGIN
(*%T _mthread *)
  n := 1;
  WHILE  n <= Process.MaxProcess DO
    IOR[n] := 0;
    INC(n);
  END;
(*%E *)
(*%F _mthread *)
  IOR := 0;
(*%E *)
  Init ;
END FIOR.
