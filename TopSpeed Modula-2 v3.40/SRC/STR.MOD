(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  STR.MOD - String functions                                              *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*%E *)
(*%T _fdata *)
(*# call(seg_name => STR) *)
(*# data(seg_name => null) *)
(*%E *)
(*# module(implementation=>off) *)
(*# call(o_a_copy => off) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE Str;


IMPORT Lib, MATHLIB, SYSTEM;

CONST
  StrictRealConv = FALSE ;

(*# save *)
(*%T _DLL *)
(*# call(seg_name=>STRDLL) *)
(*%E *)
PROCEDURE Caps(VAR S: ARRAY OF CHAR); IN AsmLib;
PROCEDURE Lows(VAR S: ARRAY OF CHAR); IN AsmLib;
PROCEDURE Compare(S1,S2: ARRAY OF CHAR) : INTEGER; IN AsmLib;
PROCEDURE Length(S : ARRAY OF CHAR) : CARDINAL; IN AsmLib;
PROCEDURE Concat(VAR R: ARRAY OF CHAR; S1,S2: ARRAY OF CHAR); IN AsmLib;
PROCEDURE Append(VAR R: ARRAY OF CHAR; S: ARRAY OF CHAR); IN AsmLib;
PROCEDURE Copy  (VAR R: ARRAY OF CHAR; S: ARRAY OF CHAR); IN AsmLib;
PROCEDURE Slice (VAR R: ARRAY OF CHAR; S: ARRAY OF CHAR; P,L: CARDINAL); IN AsmLib;
PROCEDURE Pos(S,P: ARRAY OF CHAR) : CARDINAL; IN AsmLib;
PROCEDURE NextPos(S,P: ARRAY OF CHAR; Place: CARDINAL) : CARDINAL; IN AsmLib;
PROCEDURE CharPos(S: ARRAY OF CHAR; C: CHAR) : CARDINAL; IN AsmLib;
PROCEDURE RCharPos(S: ARRAY OF CHAR; C: CHAR) : CARDINAL; IN AsmLib;
  PROCEDURE Same(Stg,Pattern:ARRAY OF CHAR):BOOLEAN; IN AsmLib;
  PROCEDURE Count(Stg:ARRAY OF CHAR;Ch:CHAR):CARDINAL; IN AsmLib;
(*# restore *)

PROCEDURE Prepend(VAR S1: ARRAY OF CHAR; S2: ARRAY OF CHAR);

VAR
    ShiftLen: CARDINAL;
    S1Len, S2Len: CARDINAL;
BEGIN
    S1Len:=Length(S1)+1;
    S2Len:=Length(S2);
    IF S2Len > HIGH(S1) THEN
        Copy(S1, S2);
        RETURN;
    END;
    ShiftLen:=HIGH(S1)-S2Len + 1;
    IF ShiftLen > S1Len THEN ShiftLen:=S1Len END;
    Lib.Move(ADR(S1), ADR(S1[S2Len]), ShiftLen);
    Lib.Move(ADR(S2), ADR(S1), S2Len);
END Prepend;

PROCEDURE Subst(VAR S1: ARRAY OF CHAR; Target: ARRAY OF CHAR; New: ARRAY OF CHAR);

VAR
    TargetPos, TargetLen: CARDINAL;
BEGIN
    TargetPos:=Pos(S1, Target);
    IF TargetPos = MAX(CARDINAL) THEN RETURN END;
    TargetLen:=Length(Target);
    Lib.Move(ADR(S1[TargetPos+TargetLen]), ADR(S1[TargetPos]), Length(S1)-TargetLen-TargetPos+1);
    Insert(S1, New, TargetPos);
END Subst;

PROCEDURE Delete(VAR S: ARRAY OF CHAR; P,L: CARDINAL);
VAR
  Le,I : CARDINAL;
BEGIN
  IF L # 0 THEN
    Le := Length(S);
    IF P < Le THEN
      IF L < Le - P THEN
        I := P+L;
        REPEAT
          S[P] := S[I];
          INC(P);
          INC(I);
        UNTIL I=Le;
      END;
      S[P] := CHR(0);
    END;
  END;
END Delete;

PROCEDURE Insert(VAR S1: ARRAY OF CHAR; S2: ARRAY OF CHAR; P: CARDINAL);
VAR
  I,J,C,L : CARDINAL;
BEGIN
  L := Length(S1);
  I := Length(S2);
  C := L;
  IF C < P THEN P := C END;
  DEC(C,P);
  FOR J := C TO 0 BY -1 DO
    IF (J+P+I <= HIGH(S1)) THEN S1[J+P+I] := S1[J+P]; END;
  END;
  J := 0;
  WHILE (J<I) AND (P+J <= HIGH(S1)) DO
    S1[P+J] := S2[J];
    INC(J);
  END;
END Insert;

PROCEDURE Item(VAR R: ARRAY OF CHAR; S: ARRAY OF CHAR; T: CHARSET; N: CARDINAL);
VAR
  I,J  : CARDINAL;
  HR,L : CARDINAL;
BEGIN
  I := 0;
  L := Length(S);
  LOOP
    WHILE (I < L) AND (S[I] IN T) DO INC(I); END; (* Skip separators *)
    IF (N = 0) OR (I = L) THEN EXIT END;
    DEC(N);
    WHILE (I < L) AND NOT (S[I] IN T) DO INC(I); END; (* Skip item *)
  END;
  J  := 0;
  HR := HIGH(R);
  WHILE (I < L) AND NOT (S[I] IN T) AND (J <= HR) DO
    R[J] := S[I];
    INC(I);
    INC(J);
  END;
  IF (J <= HR) THEN R[J] := CHR(0); END;
END Item;

PROCEDURE ItemS(VAR R: ARRAY OF CHAR; S: ARRAY OF CHAR;
                    T: ARRAY OF CHAR; N: CARDINAL);
VAR
  CS : CHARSET;
  I  : CARDINAL;
BEGIN
  I  := Length(T);
  CS := CHARSET{};
  WHILE I>0 DO
    DEC(I);
    INCL(CS,T[I]);
  END;
  Item(R,S,CS,N);
END ItemS;

PROCEDURE Match(Source,Pattern: ARRAY OF CHAR) : BOOLEAN;
(*
  returns TRUE if the string in Source matches the string in Pattern
  The pattern may contain any number of the wild characters '*' and '?'
  '?' matches any single character
  '*' matches any sequence of charcters (including a zero length sequence)
  EG '*m?t*i*' will match 'Automatic'
*)

   PROCEDURE Rmatch(VAR s: ARRAY OF CHAR; i: CARDINAL;
                    VAR p: ARRAY OF CHAR; j: CARDINAL) : BOOLEAN;

   (* s = to be tested ,    i = position in s *)
   (* p = pattern to match ,j = position in p *)

   VAR
     matched: BOOLEAN;
     k      : CARDINAL;
   BEGIN
     IF p[0]=CHR(0) THEN RETURN TRUE END;
     LOOP
       IF ((i > HIGH(s)) OR (s[i] = CHR(0))) AND
          ((j > HIGH(p)) OR (p[j] = CHR(0))) THEN
         RETURN TRUE
       ELSIF ((j > HIGH(p)) OR (p[j] = CHR(0))) THEN
         RETURN FALSE
       ELSIF (p[j] = '*') THEN
         k :=i;
         IF ((j = HIGH(p)) OR (p[j+1] = CHR(0))) THEN
           RETURN TRUE
         ELSE
           LOOP
             matched := Rmatch(s,k,p,j+1);
             IF matched OR (k > HIGH(s)) OR (s[k] = CHR(0)) THEN
               RETURN matched;
             END;
             INC(k);
           END;
         END
       ELSIF ((p[j]='?')AND(s[i]<>0C)) OR (CAP(p[j]) = CAP(s[i])) THEN
         INC(i);
         INC(j);
       ELSE
         RETURN FALSE;
       END;
     END;
   END Rmatch;

BEGIN
  RETURN Rmatch(Source,0,Pattern,0);
END Match;

TYPE
  ConvIntType = ARRAY ['0'..'F'] OF SHORTCARD;
  BA          = ARRAY[0..1] OF SHORTCARD;

CONST
  ConvStr = '0123456789ABCDEF';
  ConvInt = ConvIntType( 0,1,2,3,4,5,6,7,8,9,255,255,255,255,255,255,255,10,11,12,13,14,15 );
  Div     = BA(0,4);

VAR FloatUse : BOOLEAN;

(*%F _WINDOWS *)
  PROCEDURE FixRealToStr(V:LONGREAL;Precision:CARDINAL;VAR S:ARRAY OF CHAR;VAR OK:BOOLEAN);
    VAR
      j,i,l             : CARDINAL;
      X                 : MATHLIB.PackedBcd;
      c                 : CHAR;
      NoDigits          : BOOLEAN;
      Z                 : LONGREAL;
    BEGIN
      OK := TRUE;
      IF Precision > 17 THEN
        Precision := 17;
      END;
      l := HIGH(S);
      j := 0;
      NoDigits := TRUE;
      IF ABS(V)  >= 1.0E18 THEN
        S[0] := '?';
        INC(j);
        OK := FALSE;
      ELSE
        LOOP
          Z := V * MATHLIB.IntPow(10.0,Precision);
          IF ABS(Z)  < 1.0E18 THEN
            EXIT;
          END;
          DEC(Precision);
        END;
        X := MATHLIB.LongToBcd(Z);
        IF X[9]=80H THEN
          S[0] := '-';
          INC(j);
        END;
        FOR i := 17 TO 0 BY -1 DO
          c := CHAR(SHORTCARD('0') + (X[i DIV 2] >> Div[i MOD 2]) MOD 16);
          IF (c # '0') OR (i = Precision) OR NOT NoDigits THEN
            NoDigits := FALSE;
            IF j > l THEN
              OK := FALSE;
              RETURN;
            END;
            S[j] := c;
            INC(j);
          END;
          IF (i = Precision) AND (i # 0) THEN
            IF j > l THEN
              OK := FALSE;
              RETURN;
            END;
            S[j] := '.';
            INC(j);
          END;
        END;
      END;
      IF j <= l THEN
        S[j] := CHR(0);
      END;
    END FixRealToStr;
(*%E *)

(*%T _WINDOWS *)
  PROCEDURE FixRealToStr(V:LONGREAL;Precision:CARDINAL;VAR S:ARRAY OF CHAR;VAR OK:BOOLEAN);
    VAR
      j,l,m             : INTEGER;
      t                 : LONGREAL;
    BEGIN
      OK := TRUE;
      IF V = 0.0 THEN
        FOR j := 0 TO Precision + 1 DO
          S[j] := '0';
        END; (*FOR*)
        S[1] := '.';
        S[Precision+2] := 0C;
      ELSE
        S[0] := 0C;
        IF V < 0.0 THEN
          Copy(S,'-');
          V := -V;
        END; (*IF*)
        t := MATHLIB.IntPow(10.0,INTEGER(Precision));
        V := (V * t + 0.5) / t;
        m := TRUNC(MATHLIB.Log10(V));
        IF m <= 0 THEN
          l := 0;
          t := V;
        ELSE
          l := m;
          t := V / MATHLIB.IntPow(10.0,m);
        END; (*IF*)
        FOR j := l TO (-INTEGER(Precision)) BY -1 DO
          Append(S,CHR(TRUNC(t) + 48));
          IF j = 0 THEN
            Append(S,'.');
          END; (*IF*)
          t := (t - LONGREAL(TRUNC(t))) * 10.0;
        END; (*FOR*)
      END; (*IF*)
    END FixRealToStr;
(*%E *)

PROCEDURE CheckBase(VAR b: CARDINAL);
BEGIN
  IF b < 2  THEN b := 2; END;
  IF b > 16 THEN b := 16; END;
END CheckBase;

PROCEDURE Reverse(VAR s: ARRAY OF CHAR; l,h: CARDINAL);
VAR T : CHAR;
BEGIN
  WHILE l < h DO
    T := s[l];
    s[l] := s[h];
    s[h] := T;
    INC(l);
    DEC(h);
  END;
END Reverse;


PROCEDURE IntToStr(V: LONGINT;VAR S: ARRAY OF CHAR; Base: CARDINAL; VAR OK: BOOLEAN);
VAR
  i,l : CARDINAL;
  b   : LONGCARD;
BEGIN
  OK := TRUE;
  l  := HIGH(S);
  CheckBase( Base );
  b := VAL( LONGCARD,Base );
  IF V < 0 THEN
    S[0] := '-';
    i := 1;
    V := -V;
  ELSIF FloatUse THEN
    S[0] := '+';
    i := 1;
  ELSE
    i := 0;
  END;

  LOOP
    IF i > l THEN OK := FALSE; EXIT; END;
    S[i] := ConvStr[CARDINAL( LONGCARD(V) MOD b )];
    INC(i);
    V := LONGCARD(V) DIV b;
    IF V = 0 THEN EXIT END;
  END;
  IF i <= l THEN S[i] := CHR(0); END;
  IF S[0] < '0' THEN
    Reverse( S,1,i-1 );
  ELSE
    Reverse( S,0,i-1 );
  END;
END IntToStr;


PROCEDURE CardToStr(V: LONGCARD; VAR S: ARRAY OF CHAR;
                    Base: CARDINAL; VAR OK: BOOLEAN);
VAR
  i,l : CARDINAL;
  b   : LONGCARD;
BEGIN
  OK := TRUE;
  l  := HIGH(S);
  CheckBase( Base );
  b := VAL( LONGCARD,Base );
  i := 0;
  LOOP
    IF i > l THEN OK := FALSE; EXIT END;
    S[i] := ConvStr[CARDINAL( V MOD b )];
    INC(i);
    V := V DIV b;
    IF V = 0 THEN EXIT END;
  END;
  IF i <= l THEN S[i] := CHR(0); END;
  Reverse( S,0,i-1 );
END CardToStr;


(*$V-*)
PROCEDURE StrToCI(S: ARRAY OF CHAR; Base: CARDINAL; VAR OK: BOOLEAN) : LONGCARD;
VAR
  i,l   : CARDINAL;
  b,t,y : LONGCARD;
  c     : CHAR;
  x     : SHORTCARD;
BEGIN
  CheckBase( Base );
  b := VAL( LONGCARD,Base);
  i := 0;
  l := HIGH( S );
  IF (S[0] = '-') OR (S[0] = '+') THEN
    i := 1;
  END;
  t := 0;
  IF S[i] = CHR(0) THEN OK := FALSE; END;
  WHILE (i <= l) AND (S[i] # CHR(0)) DO
    c := S[i];
    IF (c < '0') OR (c > 'F') THEN
      OK := FALSE;
      RETURN t;
    END;
    x := ConvInt[c];
    IF (x > SHORTCARD(b)-1 ) OR (t > (MAX(LONGCARD)-LONGCARD(x)) DIV b) THEN OK := FALSE; END;
    t := t*b+VAL( LONGCARD,x );
    INC( i );
  END;
  RETURN t;
END StrToCI;


PROCEDURE StrToInt(S: ARRAY OF CHAR; Base: CARDINAL; VAR OK: BOOLEAN) : LONGINT;
VAR t : LONGCARD;
BEGIN
  OK := TRUE;
  t  := StrToCI( S,Base,OK);
  IF t > 7FFFFFFFH THEN OK := FALSE; END;
  IF S[0] = '-' THEN
    RETURN -LONGINT(t)
  ELSE
    RETURN LONGINT(t);
  END;
END StrToInt;


PROCEDURE StrToCard(S: ARRAY OF CHAR; Base: CARDINAL; VAR OK: BOOLEAN) : LONGCARD;
VAR t : LONGCARD;
BEGIN
  OK := TRUE;
  t  := StrToCI( S,Base,OK);
  IF S[0] = '-' THEN OK := FALSE; END;
  RETURN t;
END StrToCard;


  PROCEDURE StrToReal(S: ARRAY OF CHAR; VAR OK: BOOLEAN) : LONGREAL;
    CONST
      Zero              = 0.0;
    VAR
      c,expsign         : CHAR;
      exp,after         : INTEGER;
      i                 : CARDINAL;
      res,p10           : LONGREAL;
      Neg               : BOOLEAN;
    BEGIN
      OK  := TRUE;
      c   := S[0];
      Neg := FALSE;
      IF c = '+' THEN
        i := 1;
      ELSIF c = '-' THEN
        i := 1;
        Neg := TRUE;
      ELSE
        i := 0;
      END; (*IF*)
      res := Zero;
      c := S[i];
      WHILE (c # '.') & (i <= HIGH(S)) DO
        IF (c > '9') OR (c < '0') THEN
          IF StrictRealConv & (c = 0C) THEN
            OK := FALSE;
            RETURN Zero;
          ELSE
            c := '.';
            DEC(i) ;
          END; (*IF*)
        ELSE
          res := res * 10.0 + VAL(LONGREAL,ORD(c) - ORD('0'));
          INC(i);
          c := S[i];
        END; (*IF*)
      END; (*WHILE*)
      after := 0;
      IF i >= HIGH(S) THEN
        IF StrictRealConv THEN
          OK := FALSE;
          RETURN Zero;
        ELSE
          RETURN res;
        END; (*IF*)
      END; (*IF*)
      INC(i);
      c := S[i];
      WHILE (i <= HIGH(S)) & (c # 0C) & (c # 'E') DO
        IF (c > '9') OR (c < '0') THEN
          OK := FALSE;
          RETURN Zero;
        END; (*IF*)
        res := res * 10.0 + VAL(LONGREAL,ORD(c) - ORD('0'));
        INC(i);
        INC(after);
        c := S[i];
      END; (*WHILE*)
      IF c = 'E' THEN
        INC(i);
        expsign := S[i];
        IF expsign = '+' THEN
          INC(i)
        ELSIF expsign = '-' THEN
          INC(i)
        END; (*IF*)
        c := S[i];
        exp := 0;
        WHILE (i <= HIGH(S)) & (c # 0C) DO
          IF (c > '9') OR (c < '0') THEN
            OK := FALSE;
            RETURN Zero;
          END; (*IF*)
          exp := exp * 8 + exp * 2 + INTEGER(ORD(c) - ORD('0'));
          INC(i);
          c := S[i];
        END; (*WHILE*)
        IF expsign = '-' THEN
          exp := -exp;
        END; (*IF*)
      ELSE
        exp := 0;
      END; (*IF*)
      exp := exp - after;
      p10 := 1.0;
      FOR i := 1 TO ABS(exp) DO
        p10 := p10 * 10.0;
      END; (*FOR*)
      IF Neg THEN
        res := - res;
      END; (*IF*)
      IF exp < 0 THEN
        RETURN res / p10;
      ELSE
        RETURN res * p10;
      END; (*IF*)
    END StrToReal;

(*%F _WINDOWS *)
PROCEDURE RealToStr(V: LONGREAL; Precision: CARDINAL; Eng: BOOLEAN;
                    VAR S: ARRAY OF CHAR; VAR OK: BOOLEAN);
VAR
  X        : MATHLIB.PackedBcd;
  i,j,l    : CARDINAL;
  r,t      : LONGREAL;
  Exp,m    : INTEGER;
  Str      : ARRAY[0..7] OF CHAR;
  tb,
  FirstTime: BOOLEAN;

BEGIN
  OK := TRUE;
  l  := HIGH( S );
  IF Precision = 0 THEN
    Precision := 1;
  ELSIF Precision > 17 THEN
    Precision := 17;
  END;
  FirstTime := TRUE;

  IF V # 0.0 THEN
    t := MATHLIB.Log10( ABS( V ) );
  ELSE
    t := 1.0;
  END;

  Exp := TRUNC( t );
  LOOP
    m := 1;
    IF Eng THEN
      IF (ABS(V) < 1.0) THEN
        DEC(m,ABS(Exp) MOD 3 );
        IF m < 1 THEN INC(m,3); END;
      ELSE
        INC(m,Exp MOD 3 );
      END;
    END;

    X := MATHLIB.LongToBcd( V*MATHLIB.IntPow(10.0,INTEGER(Precision)-Exp-1) );
    j := 0;
    IF NOT FirstTime THEN
      EXIT;
    ELSIF (X[Precision DIV 2] >> Div[Precision MOD 2 ] ) MOD 16 # 0 THEN
      INC( Exp );
      FirstTime := FALSE;
    ELSIF (X[(Precision-1) DIV 2] >> Div[(Precision-1) MOD 2 ] ) MOD 16 = 0 THEN
      DEC( Exp );
      FirstTime := FALSE;
    ELSE
      EXIT;
    END;

  END;
  IF X[9]=80H THEN
    S[0] := '-';
  ELSE
    S[0] := ' ';
  END;
  INC(j);

  FOR i := Precision-1 TO 0 BY -1 DO
    IF j > l THEN OK := FALSE; RETURN; END;

    S[j] := CHAR( SHORTCARD('0') + (X[i DIV 2] >> Div[i MOD 2 ] ) MOD 16 );
    INC( j );
    IF i = Precision-CARDINAL(m) THEN
      IF j > l THEN OK := FALSE; RETURN; END;
      S[j] := '.';
      INC(j);
    END;
  END;

  IF j > l THEN OK := FALSE; RETURN; END;
  S[j] := 'E';
  INC( j );
  IF j <= l THEN S[j] := CHR(0); END;

  tb := FloatUse;
  FloatUse := TRUE;

  IntToStr( VAL( LONGINT,Exp-m+1 ),Str,10,OK );

  FloatUse := tb;

  IF ( Length( Str ) + j )-1 > l THEN OK := FALSE; END;
  Append( S,Str );
END RealToStr;
(*%E *)

(*%T _WINDOWS *)
  PROCEDURE RealToStr(V:LONGREAL;Precision:CARDINAL;Eng:BOOLEAN;VAR S:ARRAY OF CHAR;VAR OK:BOOLEAN);
    VAR
      j,w               : CARDINAL;
      m,i               : INTEGER;
      t                 : LONGREAL;
    BEGIN
      OK := TRUE;
      S[0] := 0C;
      m := 0;
      IF Precision > 17 THEN
        Precision := 17;
      END; (*IF*)
      IF V < 0.0 THEN
        Copy(S,'-');
        V := -V;
      END; (*IF*)
      IF V # 0.0 THEN
        m := TRUNC(MATHLIB.Log10(V));
        IF m > 0 THEN
          V := V / MATHLIB.IntPow(10.0,m);
        END; (*IF*)
        IF V < 1.0 THEN
          V := V * 10.0;
          DEC(m);
        END;
        t := MATHLIB.IntPow(10.0,INTEGER(Precision));
        V := (V * t + 0.5) / t;
        IF V >= 10.0 THEN
          V := V / 10.0;
          INC(m);
        END; (*IF*)
        IF Eng THEN
          i := m;
          IF m > 0 THEN
            m := ((m + 2) DIV 3) * 3;
          ELSE
            m := ((m - 2) DIV 3) * 3;
          END; (*IF*)
          V := V / MATHLIB.IntPow(10.0,m - i);
        END; (*IF*)
      END; (*IF*)
      w := TRUNC(V);
      V := (V - LONGREAL(w)) * 10.0;
      IF Eng & (Precision > 0) THEN
        IF w DIV 100 > 0 THEN
          Str.Append(S,CHR((w DIV 100) + 48));
          w := w MOD 100;
          DEC(Precision);
        END; (*IF*)
        IF (w DIV 10 > 0) & (Precision > 0) THEN
          Str.Append(S,CHR((w DIV 10) + 48));
          w := w MOD 10;
          DEC(Precision);
        END; (*IF*)
      END; (*IF*)
      IF Precision > 0 THEN
        Str.Append(S,CHR(w + 48));
        DEC(Precision);
        Str.Append(S,'.');
        IF Precision > 0 THEN
          FOR j := 1 TO Precision DO
            Append(S,CHR(TRUNC(V) + 48));
            V := (V - LONGREAL(TRUNC(V))) * 10.0;
          END; (*FOR*)
        END; (*IF*)
      END; (*IF*)
      IF m < 0 THEN
        Str.Append(S,'E-');
        m := -m;
      ELSE
        Str.Append(S,'E+');
      END; (*IF*)
      IF m DIV 100 > 0 THEN
        Str.Append(S,CHR((m DIV 100) + 48));
        m := m MOD 100;
      END; (*IF*)
      IF m DIV 10 > 0 THEN
        Str.Append(S,CHR((m DIV 10) + 48));
      END; (*IF*)
      Str.Append(S,CHR((m MOD 10) + 48));
    END RealToStr;
(*%E *)

(*# save,call(o_a_copy=>off,o_a_size=>on)*)
  PROCEDURE FindSubStr(Source,Pattern:ARRAY OF CHAR;VAR Pos:ARRAY OF PosLen):BOOLEAN;
    VAR
      s,p,n,l           : CARDINAL;
    BEGIN
      Lib.Fill(ADR(Pos),SIZE(Pos),0FFH);
      IF Length(Source) = 0 THEN
        RETURN FALSE;
      END; (*IF*)
      l := Length(Pattern);
      IF l = 0 THEN
        Pos[0] := PosLen(0,0);
        RETURN TRUE;
      END; (*IF*)
      IF (Pattern[0] = '*') OR (Pattern[0] = '?') THEN
        IF l = 1 THEN
          Pos[0].Pos := 0;
          IF Pattern[0] = '*' THEN
            Pos[0].Pos := 0;
            Pos[0].Len := Length(Source);
          ELSE
            Pos[0] := PosLen(0,1);
          END; (*IF*)
          RETURN TRUE;
        ELSE
          s := 0;
        END; (*IF*)
      ELSE
        s := CharPos(Source,Pattern[0]);
        IF s = MAX(CARDINAL) THEN
          RETURN FALSE;
        END; (*IF*)
      END; (*IF*)
      n := 0;
      p := 1;
      WHILE p < l DO
        INC(s);
        IF (s > HIGH(Source)) OR (Source[s] = 0C) THEN
          RETURN FALSE;
        END; (*IF*)
        CASE Pattern[p] OF
          '?'           : IF n <= HIGH(Pos) THEN
                            Pos[n].Pos := s;
                            Pos[n].Len := 1;
                            INC(n);
                          END; (*IF*)                                     |
          '*'           : IF n <= HIGH(Pos) THEN
                            Pos[n].Pos := s;
                            IF (p >= HIGH(Pattern)) OR (Pattern[p+1] = 0C) THEN
                              RETURN TRUE;
                            ELSE
                              Pos[n].Len := NextPos(Source,Pattern[p+1],s); (* s/b NextCharPos *)
                              IF Pos[n].Len = MAX(CARDINAL) THEN
                                RETURN FALSE;
                              ELSE
                                DEC(Pos[n].Len,s);
                                INC(s,Pos[n].Len);
                                INC(n);
                              END; (*IF*)
                            END; (*IF*)
                          END; (*IF*)
                          INC(p);                                         |
        ELSE
          IF CAP(Pattern[p]) # CAP(Source[s]) THEN
            RETURN FALSE;
          END; (*IF*)
        END; (*CASE*)
        INC(p);
      END; (*WHILE*)
      RETURN TRUE;
    END FindSubStr;
(*# restore *)
(* The following are Implemented in asmlib

PROCEDURE CapS(VAR S: ARRAY OF CHAR);
VAR I : CARDINAL;
BEGIN
  FOR I := 0 TO HIGH(S) DO S[I] := CAP(S[I]); END;
END CapS;


PROCEDURE Compare(S1,S2: ARRAY OF CHAR) : INTEGER;
VAR
  L1,L2,L,Index : CARDINAL;
BEGIN
  L1 := Length(S1);
  L2 := Length(S2);
  IF L1<L2 THEN L := L1 ELSE L := L2 END;
  Index := Lib.Compare(ADR(S1),ADR(S2),L);
  IF (Index<L) THEN
    IF S1[Index] < S2[Index] THEN
      RETURN -1
    ELSE
      RETURN 1;
    END;
  ELSIF (L1=L2) THEN
    RETURN 0
  ELSIF (L1<L2) THEN
    RETURN -1
  ELSE
    RETURN 1;
  END;
END Compare;


PROCEDURE Length(S1: ARRAY OF CHAR) : CARDINAL;
VAR I : CARDINAL;
BEGIN
  RETURN Lib.ScanR(ADR(S1),HIGH(S1)+1,0);
END Length;


PROCEDURE Append(VAR Ns: ARRAY OF CHAR; S: ARRAY OF CHAR);
VAR
  I,J : CARDINAL;
  c : CHAR;
BEGIN
  I := Length(Ns);
  J := 0;
  WHILE (I <= HIGH(Ns)) AND (J <= HIGH(S))  AND (S[J] <> CHR(0)) DO
    Ns[I] := S[J];
    INC(I);
    INC(J);
  END;
  IF I<=HIGH(Ns) THEN Ns[I] := CHR(0) END;
END Append;


PROCEDURE Copy(VAR Ns: ARRAY OF CHAR; S: ARRAY OF CHAR);
VAR
  H,L : CARDINAL;
BEGIN
  H := HIGH(Ns)+1;
  L := Length(S);
  IF L > H THEN L := H END;
  Lib.Move(ADR(S),ADR(Ns),L);
  IF L < H THEN Ns[L] := CHR(0) END;
END Copy;


PROCEDURE Concat(VAR Ns: ARRAY OF CHAR; S1,S2: ARRAY OF CHAR);
VAR
  I,J : CARDINAL;
BEGIN
  J := 0;
  WHILE (J <= HIGH(Ns)) AND (J <= HIGH(S1)) AND (S1[J] <> CHAR(0)) DO
    Ns[J] := S1[J];
    INC(J);
  END;

  I := 0;
  LOOP
    IF (J > HIGH(Ns)) THEN EXIT; END;
    IF (I > HIGH(S2)) THEN Ns[J] := CHR(0); EXIT; END;
    Ns[J] := S2[I];
    IF S2[I] = CHR(0) THEN EXIT; END;
    INC(I);
    INC(J);
  END;
END Concat;


PROCEDURE Pos(S,P: ARRAY OF CHAR) : CARDINAL;
VAR
  I,J,K,HP,HS : CARDINAL;
BEGIN
  HP := HIGH(P);
  HS := HIGH(S);
  I  := 0;
  LOOP
    IF (I > HS) OR (S[I] = CHR(0)) THEN RETURN MAX(CARDINAL) END;
    J := 0;
    K := I;
    LOOP
      IF (J > HP) OR (P[J] = CHR(0)) THEN RETURN I END;
      IF K > HS THEN RETURN MAX( CARDINAL ); END;
      IF S[K] # P[J] THEN EXIT END;
      INC(J);
      INC(K);
    END;
    INC(I);
  END;
END Pos;

*)

PROCEDURE StrToC(S: ARRAY OF CHAR; VAR D: ARRAY OF CHAR): BOOLEAN;

VAR
  n: CARDINAL;
  c: CHAR;
BEGIN
  n := 0;
  LOOP
    IF n > HIGH(D) THEN
      RETURN FALSE;
    END;
    IF n > HIGH(S) THEN
      c := 0C;
    ELSE
      c := S[n];
    END;
    D[n] := c;
    IF c = 0C THEN
      RETURN TRUE
    END;
    INC(n);
  END;
END StrToC;

PROCEDURE StrToPas(S: ARRAY OF CHAR; VAR D: ARRAY OF CHAR): BOOLEAN;

VAR
  n: CARDINAL;
  c: CHAR;
BEGIN
  n := 1;
  LOOP
    IF n > HIGH(D) THEN
      D[0] := 0C;
      RETURN FALSE;
    END;
    IF n > SIZE(S) THEN
      c := 0C;
    ELSE
      c := S[n-1];
    END;
    IF c = 0C THEN
      D[0] := CHAR(n-1);
      RETURN TRUE
    END;
    D[n] := c;
    INC(n);
  END;
END StrToPas;

BEGIN
  FloatUse := FALSE;
END Str.
