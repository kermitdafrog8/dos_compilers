(*========================================================
== JPI-Modula/2 demo program:                           ==
==                                                      ==
==        Resident SideKick-like Calculator             ==
==                                                      ==
========================================================*)

(*$S 2000*)(*Stack size: 8K *)
(*$B-*)    (*No Ctrl-Break handling*)

MODULE TSRcalc;
    (* ==== *)

IMPORT IO,Window,Lib,SYSTEM,Storage;
IMPORT TSR ;

CONST Ix = 30;
      Iy = 10;
      Sx = 22;
      Sy = 2;

TYPE LONGSET = SET OF [0..31];

     StateType = (DigState,NumState,OptState);

     ModeType = (DecMode,HexMode,BinMode);

     ModeInfRec = RECORD
                        Name:ARRAY[1..4] OF CHAR;
                        Base:CARDINAL;
                  END;

     ModeInfArr = ARRAY ModeType OF ModeInfRec;

CONST ModeInf = ModeInfArr(ModeInfRec("Dec",10),ModeInfRec("Hex",16),ModeInfRec
         ("Bin",2));

VAR Value,Other,Memory      :LONGINT;
    Mode                    :ModeType;
    State                   :StateType;
    Q,C,Opt                 :CHAR;
    W                       :Window.WinType;
    X,Y                     :CARDINAL;


CONST KeyL = CHR(128+75);
      KeyR = CHR(128+77);
      KeyU = CHR(128+72);
      KeyD = CHR(128+80);
      Key5 = CHR(128+63);
      Key10 = CHR(128+68);

PROCEDURE BiosGetKey():CHAR;
       (* ========== *)

VAR R:SYSTEM.Registers;

BEGIN
  R.AH := 0;
  Lib.Intr(R,016H);
  IF R.AL<>0 THEN
    RETURN CHR(R.AL);
  ELSE
    RETURN CHR(128+R.AH);
  END;
END BiosGetKey;

PROCEDURE UpdateDisplay;
       (* ============== *)

CONST Width = 16;

VAR I:CARDINAL;

BEGIN
  Window.GotoXY(4,1);
  CASE Mode OF

    |  DecMode:IO.WrLngInt(Value,Width);
    |  HexMode:IO.WrLngHex(Value,Width);
    |  BinMode:FOR I := Width-1 TO 0 BY -1 DO
                 IO.WrChar(CHR(ORD('0')+ORD(I IN LONGSET(Value))));
               END;

  END;
  Window.GotoXY(4,2);
  IO.WrStr(ModeInf[Mode].Name);
  IO.WrStr("    ");
  IF Memory<>0 THEN
    IO.WrStr("M");
  ELSE
    IO.WrStr(" ");
  END;
END UpdateDisplay;

PROCEDURE Crash(L:CARDINAL);
       (* ===== *)

TYPE Sp = POINTER TO SHORTCARD;

VAR I:SHORTCARD;
    J:CARDINAL;
    P,Q:BITSET;

BEGIN
  Q := BITSET(SYSTEM.In(061H));
  P := Q*{2..7};
  J := L;
  WHILE J>0 DO
    SYSTEM.Out(061H,SHORTCARD(P));
    FOR I := 0 TO [400H:J Sp]^  DO
      P := P/{1};
    END;
    DEC(J);
  END;
  SYSTEM.Out(061H,SHORTCARD(Q));
  L := L DIV 100;
  IF (X>=L) AND (Y>=L) THEN
    FOR J := 1 TO L DO
      DEC(X);
      DEC(Y);
      Window.Change(W,X,Y,X+Sx+J+J,Y+Sy+J+J);
    END;
    FOR J := L TO 1 BY -1 DO
      INC(X);
      INC(Y);
      Window.Change(W,X,Y,X+Sx+J+J-1,Y+Sy+J+J-1);
    END;
  END
END Crash;


PROCEDURE RunCalc;
       (* ======= *)

VAR I,F:CARDINAL;
    R:SYSTEM.Registers;

BEGIN
  Window.PutOnTop(W);
  Window.Use(W);
  LOOP
    CASE C OF
      |  'c':Value := 0;
             Other := 0;
             Opt := '=';
      |  '0'..'9','A'..'F',
         Key5..Key10:IF C<='9' THEN
                       DEC(C,ORD('0'));
                     ELSIF (C>='A')AND(C<='F') THEN
                       DEC(C,ORD('A'));
                       INC(C,10);
                     ELSE
                       DEC(C,ORD(Key5));
                       INC(C,10);
                     END;
                     IF ORD(C)<ModeInf[Mode].Base THEN
                       IF State<>DigState THEN
                         Value := 0;
                       END;
                       State := DigState;
                       IF Value<=MAX(LONGINT) DIV LONGINT(ModeInf[Mode].Base)
                           THEN
                         Value := Value*LONGINT(ModeInf[Mode].Base)+LONGINT(ORD
                            (C));
                       ELSE
                         Crash(50);
                       END;
                     ELSE
                       Crash(100);
                     END;
      |  10C:IF State = DigState THEN
               Value := Value DIV LONGINT(ModeInf[Mode].Base);
             END;
      |  'e':Value := 0;
             State := NumState;

      |  '+','-','*','/','a','o','x','=',CHR(13),'X','O':
             IF State<>OptState THEN
               CASE Opt OF

                 |  '+':Other := Other+Value;
                 |  '-':Other := Other-Value;
                 |  '*':Other := Other*Value;
                 |  '/':Other := Other DIV Value;
                 |  'a':Other := LONGINT(LONGSET(Other)*LONGSET(Value));
                 |  'O',
                    'o':Other := LONGINT(LONGSET(Other)+LONGSET(Value));
                 |  'X',
                    'x':Other := LONGINT(LONGSET(Other)/LONGSET(Value));
                 |  CHR(13),
                    '=':Other := Value;

               END;
               Value := Other;
               State := OptState;
             END;
             Opt := C;
      |  'd':Mode := DecMode;
             State := NumState;
      |  'H',
         'h':Mode := HexMode;
             State := NumState;
      |  'b':Mode := BinMode;
             State := NumState;
      |  'M',
         'm':C := BiosGetKey();
             CASE CAP(C) OF

               |  '+':Memory := Memory+Value;
               |  '-':Memory := Memory-Value;
               |  '*':Memory := Memory*Value;
               |  '/':Memory := Memory DIV Value;
               |  'R':Value := Memory;
                      State := NumState;
               |  'C':Memory := 0;
               |  '=':Memory := Value;

             END;
             State := NumState;
      |  KeyL,KeyR,
         KeyU,KeyD:

              IF    (C = KeyL) AND (X>0)     THEN DEC(X);
              ELSIF (C = KeyR) AND (X+Sx<78) THEN INC(X);
              ELSIF (C = KeyU) AND (Y>0)     THEN DEC(Y);
              ELSIF (C = KeyD) AND (Y+Sy<23) THEN INC(Y);
              ELSE
                F := 2000;
                WHILE (X<>Ix) OR (Y<>Iy) DO
                  FOR I := 1 TO 10 DO
                    Lib.Sound(F);
                    Lib.Delay(5);
                    DEC(F,F DIV 50);
                  END;
                  IF X>Ix THEN DEC(X); END;
                  IF X<Ix THEN INC(X); END;
                  IF Y>Iy THEN DEC(Y); END;
                  IF Y<Iy THEN INC(Y); END;
                  Window.Change(W,X,Y,X+Sx+1,Y+Sy+1);
                END;
                Lib.NoSound;
                Crash(800);
                C := ' ';
                EXIT;
              END;
              Window.Change(W,X,Y,X+Sx+1,Y+Sy+1);
      |  ' ':;
      |  CHR(27):
              C := ' ';
              EXIT;
      |  CHR(45+128): (* ALT X *)
              TSR.DeInstall ;
              EXIT ;
      |
     ELSE
       Crash(200);
    END;
    UpdateDisplay;
    C := BiosGetKey();
  END;
  Window.Hide(W);
END RunCalc;



BEGIN
  IO.WrStr("Installing JPI-CALC,"); IO.WrLn;
  IO.WrStr("AltZ to activate."); IO.WrLn;
  X := Ix;
  Y := Iy;
  W := Window.Open(Window.WinDef(Ix,Iy,Ix+Sx+1,Iy+Sy+1,
                                 Window.White,Window.Black,
                                 FALSE,FALSE,TRUE,TRUE,
                                 Window.DoubleFrame,Window.Black,
                                 Window.Green));
  Window.SetTitle(W," JPI-CALC ",Window.CenterUpperTitle);
  Memory := 0;
  Mode := DecMode;
  State := NumState;
  C := 'c';
  TSR.Install(RunCalc,TSR.KBFlagSet{TSR.Alt},44,400H) ; (* ALT Z *)
  Window.Clear ;
  IO.WrStr("JPI-CALC Deinstalled.");
  IO.WrLn;
END TSRcalc.
(*======================================================*)

