MODULE Abu ;    (*  ERV, 1989 *)
 IMPORT Screen, Disk, Term, Parms;

CONST maxbuff = 32000 ;
      Maxrow = Screen.maxrow - 1 ;
      maxfname = 12;

TYPE  BuffTyp = ARRAY maxbuff OF CHAR ;
      BuffPtr = POINTER TO BuffTyp ;
      LinePtr = POINTER TO LineRec;
      LineRec = RECORD
                  next,prior : LinePtr;
                  offset,limit : INTEGER
                END ;
      SrchStg = ARRAY 40 OF CHAR;
      Fname = ARRAY maxfname+1 OF CHAR;

      XferPtr = POINTER TO Xfer;
      Xfer = RECORD
              next, prior :XferPtr;
              name : Fname;
              Buff:BuffPtr; BuffEnd:INTEGER;
              TOF,BOF,topline : LinePtr;
              lastsrch:SrchStg; coldelta:INTEGER
             END;

      FileNameTyp = ARRAY 64 OF CHAR;

VAR fhandle : INTEGER;

    BuffEnd : INTEGER;
    coldelta: INTEGER;
    Buff : BuffPtr ;
    TOF,BOF,topline : LinePtr ;
    lastsrch : SrchStg;

    XFcurrent:XferPtr;


PROCEDURE Err(s:ARRAY OF CHAR);
VAR cl:INTEGER; ch:CHAR;
BEGIN
  cl := Screen.Color;  Screen.Color := 70H;
  Screen.EraseLine(0); Screen.WrtStr(s,0,0);
  Screen.EraseLine(1); Screen.WrtStr("Press any key to continue",1,0);
  Term.RdKey(ch); IF ch = 0X THEN Term.RdKey(ch) END;
  Screen.Color := cl
END Err;


PROCEDURE FileToStrings ;
VAR i:INTEGER; ch:CHAR;  p,p0:LinePtr;
BEGIN i := 0;
  p0 := TOF ;  NEW(p);  p.offset := i;
  WHILE i < BuffEnd DO
    ch := Buff[i];
    IF ch = 0AX THEN Buff[i] := 00X;
         p.limit := i;
         p.next := p0.next;  p.prior := p0;  p.next.prior := p;
         p0.next := p;  p0 := p;
         NEW(p);  p.offset := i + 1
    ELSIF ch < " " THEN Buff[i] := " "
    END;
    INC(i)
  END
END FileToStrings;


PROCEDURE GetFile(VAR fn:ARRAY OF CHAR) : BOOLEAN ;
VAR ans:BOOLEAN; p:LinePtr;
BEGIN  ans := fn[0] # 0X ;
  IF ans THEN
    Disk.FileOpen(fn, fhandle, 0) ;
    IF fhandle = 0 THEN Err("Cannot find file") ; ans := FALSE END;
    IF ans THEN
      Disk.FileRd(Buff^, fhandle, maxbuff, BuffEnd);
      IF BuffEnd = 0 THEN Err("File is empty"); ans := FALSE
      ELSE FileToStrings
      END ;
      Disk.FileClose(fhandle)
    END
  END;
  IF ~ans THEN
    NEW(p); p.next := BOF; p.prior := TOF; p.limit := 0; p.offset := 0;
    TOF.next := p; BOF.prior := p; Buff[0] := 0X
  END;
  RETURN ans
END GetFile;

PROCEDURE ShowScreen ;
VAR r,c:INTEGER; p:LinePtr;  s:ARRAY 4 OF CHAR;
BEGIN r := Screen.minrow;  c := Screen.mincol;  p := topline ;  s[0] := 00X;
  WHILE (p # BOF) & (r <= Maxrow) DO
    Screen.WrtSp(Buff^, p.offset+coldelta, p.limit, r, c);
    INC(r);  p := p.next
  END;
  WHILE r <= Maxrow DO Screen.WrtSp(s,0,0,r,c); INC(r) END
END ShowScreen;

PROCEDURE PageDown;
VAR i:INTEGER;
BEGIN
  i := Maxrow - Screen.minrow - 1; (*bottom line shows as new top line*)
  WHILE (i > 0) & (topline.next # BOF) DO
    topline := topline.next;  DEC(i)
  END;
  ShowScreen
END PageDown;

PROCEDURE PageUp;
VAR i:INTEGER;
BEGIN
  i := Maxrow - Screen.minrow;
  WHILE (i > 0) & (topline.prior # TOF) DO
    topline := topline.prior;  DEC(i)
  END;
  ShowScreen
END PageUp;

PROCEDURE Query(VAR s:ARRAY OF CHAR; prompt:ARRAY OF CHAR);
VAR cl,i:INTEGER;
BEGIN
  i := 0; WHILE prompt[i] # 0X DO INC(i) END;
  IF i > 0 THEN
    cl := Screen.Color;  Screen.Color := 70H;
    Screen.EraseLine(0); Screen.WrtStr(prompt,0,0);
    Screen.MoveCursor(0,i); Screen.SetCursorOn;  Term.RS(s);
    Screen.SetCursorOff;
    Screen.Color := cl;
  END;
  IF s[0] = 0X THEN ShowScreen END
END Query;

PROCEDURE Search(repeat:BOOLEAN);
VAR g,h,i,j,k:INTEGER; s:SrchStg; line:LinePtr;
BEGIN
  IF ~repeat THEN
    Query(s, "Search for:");
    line := TOF^.next;  g := line.offset;
  ELSE s := lastsrch; (*repeat last search starting on next line*)
    line := topline.next; g := line.offset
  END;
  i := 0;  WHILE s[i] # 0X DO INC(i) END;
  IF i > 0 THEN lastsrch := s;
    LOOP
      IF line = BOF THEN EXIT
      ELSIF i + g > line.limit THEN line := line.next; g := line.offset
      ELSE j := g; k := i;  h := 0;
        WHILE (k > 0) & (Buff[j] = s[h]) DO
          DEC(k); INC(j); INC(h)
        END;
        IF k = 0 THEN topline := line; EXIT
        ELSE INC(g)
        END
      END
    END
  END;
  ShowScreen
END Search;


PROCEDURE GetFileName(VAR filename:ARRAY OF CHAR);
VAR s:Parms.ParmString;  i:INTEGER;  ch:CHAR;
BEGIN
  filename[0] := 0X ;
  Parms.ParmCount(i);
  IF i > 0 THEN Parms.Parm(1,s);
    i := 0;
    REPEAT ch := s[i];  filename[i] := ch;  INC(i) UNTIL ch = 0X
  END
END GetFileName;

PROCEDURE ShowName;
BEGIN Screen.WrtHi(XFcurrent.name,Screen.maxrow,0)
END ShowName;

PROCEDURE SaveXF;
BEGIN
 XFcurrent.Buff := Buff;  XFcurrent.BuffEnd := BuffEnd;
 XFcurrent.TOF := TOF; XFcurrent.BOF := BOF;
 XFcurrent.topline := topline;
 XFcurrent.lastsrch := lastsrch;  XFcurrent.coldelta := coldelta;
END SaveXF;

PROCEDURE RestoreXF;
BEGIN
 Buff := XFcurrent.Buff;  BuffEnd := XFcurrent.BuffEnd;
 TOF := XFcurrent.TOF;  BOF := XFcurrent.BOF;
 topline := XFcurrent.topline;
 lastsrch := XFcurrent.lastsrch;  coldelta := XFcurrent.coldelta;
END RestoreXF;

PROCEDURE NextFile;
BEGIN
 SaveXF; XFcurrent := XFcurrent.next;  RestoreXF; ShowName
END NextFile;

PROCEDURE InitXF(first:BOOLEAN) : BOOLEAN;
VAR p:XferPtr;  s:FileNameTyp; ans:BOOLEAN;  i:INTEGER;
BEGIN ans := FALSE;
  IF first THEN GetFileName(s) ELSE Query(s,"New file name:") END;
  IF s[0] # 0X THEN
    NEW(p);  p.next := NIL;  p.prior := NIL;
    i := 0;
    WHILE (i < maxfname) & (s[i] # 0X) DO p.name[i] := s[i]; INC(i) END;
    WHILE i < maxfname DO p.name[i] := " "; INC(i) END;
    p.name[maxfname] := 0X;
    NEW(p.Buff);  p.BuffEnd := 0;
    NEW(p.BOF);  p.BOF.next := NIL;  p.BOF.offset := 0;
    NEW(p.TOF);  p.TOF.next := p.BOF;  p.TOF.offset := 0;
    p.BOF.prior := p.TOF;  p.topline := p.BOF;
    p.lastsrch[0] := 00X;  p.coldelta := 0;
    IF XFcurrent = NIL THEN XFcurrent := p; p.next := p;  p.prior := p;
        RestoreXF
    ELSE p.next := XFcurrent.next;  p.next.prior := p;  p.prior := XFcurrent;
      XFcurrent.next := p; NextFile
    END ;
    ans := GetFile(s);
    topline := TOF.next ;
    ShowName; ShowScreen
  END;
  RETURN ans
END InitXF;

PROCEDURE MainLoop;
VAR ch:CHAR;
BEGIN
  LOOP
    Term.RdKey(ch);
    IF ch = 0X THEN Term.RdKey(ch);
      CASE ORD(ch) OF
        Term.arup  :
           IF topline.prior # TOF THEN topline := topline.prior; ShowScreen END
      | Term.ardown:
           IF topline.next # BOF THEN topline := topline.next; ShowScreen END
      | Term.arleft: IF coldelta > 0 THEN DEC(coldelta); ShowScreen END
      | Term.arrt  : IF coldelta < 512 THEN INC(coldelta); ShowScreen END
      | Term.pgdn  : PageDown
      | Term.pgup  : PageUp
      | Term.home  : coldelta := 0; topline := TOF^.next;  ShowScreen
      | Term.end   : coldelta := 0; topline := BOF;  PageUp
      | Term.Carleft: coldelta := 0; ShowScreen
      ELSE (*nothing*)
      END
    ELSIF ch = 1BX (*ESC*) THEN EXIT
    ELSIF ch = "/" THEN Search(FALSE)
    ELSIF ch = "\" THEN Search(TRUE)
    ELSIF CAP(ch) = "N" THEN
      IF InitXF(FALSE) THEN (*nop*) END
    ELSIF CAP(ch) = "F" THEN NextFile; ShowScreen
    END
  END
END MainLoop;


BEGIN  (*Abu*)
  IF Screen.ColorScreen THEN
     Screen.Color := 1FH   (* blue background,white letters,intense*)
  ELSE Screen.Color := 07H  (*white on black*)
  END;
  Screen.Clear;  Screen.SetCursorOff;
  Screen.WrtHi(
  "             | ESC-exit  /-search  \-search again  N-new file  F-next file",
   Screen.maxrow,0);
  IF InitXF(TRUE) THEN MainLoop END;
  Screen.Color := 07H ; (* black background, white letters*)
  Screen.Clear;  Screen.MoveCursor(0,0);  Screen.SetCursorOn
END Abu .
