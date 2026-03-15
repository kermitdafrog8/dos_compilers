MODULE Parms;   (* ERV, 1989/91 *)
  IMPORT SYS:=SYSTEM;

TYPE ParmString * = ARRAY 128 OF CHAR;
     ParmStrPtr = POINTER TO ParmString;
     ParmPtr = POINTER TO ParmRec ;
     ParmRec = RECORD
                next : ParmPtr;
                parmp : ParmStrPtr
               END;

VAR ParmCnt : INTEGER;
    ParmHead : ParmPtr;

PROCEDURE Init;
VAR fn:INTEGER;  i,j:INTEGER;
    cr:RECORD offset, segment : INTEGER END;
    PPC : ParmStrPtr;
    psp:ParmStrPtr;
    p,p0:ParmPtr;
BEGIN  PPC := NIL;  ParmHead := NIL;  ParmCnt := 0;
  fn := 0;
  SYS.CALL(fn, cr.segment);
  cr.offset := 80H ;
  PPC := SYS.VAL(ParmStrPtr, cr);
  i := ORD(PPC[0]);  (* length of parms following*)
  j := 1 ;      (*place to start looking for them*)
  LOOP
    WHILE (i > 0) & (PPC[j] <= " ") DO INC(j); DEC(i) END;
    IF i <= 0 THEN EXIT END;
    INC(ParmCnt);
    NEW(p);
    IF ParmHead = NIL THEN ParmHead := p
    ELSE p0.next := p
    END;
    p0 := p;  p.next := NIL;
    cr.offset := 80H + j ;
    p.parmp := SYS.VAL(ParmStrPtr, cr);
    WHILE (i > 0) & (PPC[j] > " ") DO INC(j); DEC(i) END;
    PPC[j] := 00X (*terminate this string*); INC(j);  DEC(i)
  END
END Init;

PROCEDURE ParmCount * (VAR parmcnt:INTEGER);
BEGIN parmcnt := ParmCnt
END ParmCount;

PROCEDURE Parm * (n:INTEGER; VAR parm:ParmString);
VAR p:ParmPtr;
BEGIN parm[0] := 0X;
  IF (0 < n) & (n <= ParmCnt) THEN
    p := ParmHead;  DEC(n);
    WHILE n > 0 DO DEC(n); p := p.next END;
    parm := p.parmp^
  END
END Parm;

BEGIN Init
END Parms.
