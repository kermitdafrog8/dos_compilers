MODULE RDemo;

IMPORT Window,rs,IO,Str,Lib;

TYPE  ConnectType = RECORD
                      ConnectStr : ARRAY [0..15] OF CHAR;
                      NoCon1Str  : ARRAY [0..15] OF CHAR;
                      NoCon2Str  : ARRAY [0..15] OF CHAR;
                      NoCon3Str  : ARRAY [0..15] OF CHAR;
                      NoCon4Str  : ARRAY [0..15] OF CHAR;
                      NoCon5Str  : ARRAY [0..15] OF CHAR;
                    END;


CONST PortNr = 1; BaudRate = 1200;
      WT =   Window.WinDef ( 0,0, Window.ScreenWidth-1,15,
                              Window.White,Window.Black,TRUE,TRUE,FALSE,TRUE,
                              Window.SingleFrame,Window.White,Window.Black );

      WT2 =   Window.WinDef ( 0,0, 30,2,
                              Window.White,Window.Black,TRUE,TRUE,FALSE,TRUE,
                              Window.SingleFrame,Window.White,Window.Black );
      PhoneNr   = '583 1200';
      HangupStr = '~~~~+++~~~AT H0!';
      InitString= 'AT E1 S7=60 S0=0 V1 X1 !~~AT DP '+PhoneNr+'!';
      Connect   = ConnectType('CONNECT','NO CARRIER','BUSY','NO DIAL TONE',
                              'NO ANSWER','');


VAR W,W2 : Window.WinType;

PROCEDURE SendModemContr( str : ARRAY OF CHAR );
VAR i : CARDINAL;
BEGIN
  FOR i := 0 TO Str.Length(str)-1 DO
      IF str[i]='~' THEN
         Lib.Delay(500);
      ELSIF str[i]='!' THEN
         rs.Send( CHR(13),1 );
      ELSIF str[i]='`' THEN
         rs.Break( 500 );
      ELSE
         rs.Send( str[i],1 );
         Lib.Delay(100);
      END;
  END;
END SendModemContr;



PROCEDURE HangUp;
BEGIN
  IO.WrLn;
  IO.WrStr('Hanging up please wait');
  IO.WrLn;
  SendModemContr( HangupStr );
  IO.WrStr('ok');
END HangUp;

PROCEDURE DoConnect():BOOLEAN;
VAR str : ARRAY[0..100] OF CHAR; p : CARDINAL; c : CHAR;
BEGIN
  W2 := Window.Open(WT2);
  IO.WrStr('Dialing');
  SendModemContr( InitString );
  p :=0;
  LOOP
    IF rs.RxCount()#0 THEN
       rs.Receive(str[p],1);
       IF str[p]=CHR(13) THEN
          str[p] := 0C;
          p := 0;
          IO.WrLn;
          IO.WrStr(str);
          IF Str.Pos(str,Connect.ConnectStr)#MAX(CARDINAL) THEN
             Window.Close(W2);
             RETURN TRUE;
          ELSIF (Str.Pos(str,Connect.NoCon1Str)#MAX(CARDINAL)) AND (Connect.NoCon1Str[0]#0C) OR
                (Str.Pos(str,Connect.NoCon2Str)#MAX(CARDINAL)) AND (Connect.NoCon2Str[0]#0C) OR
                (Str.Pos(str,Connect.NoCon3Str)#MAX(CARDINAL)) AND (Connect.NoCon3Str[0]#0C) OR
                (Str.Pos(str,Connect.NoCon4Str)#MAX(CARDINAL)) AND (Connect.NoCon4Str[0]#0C) OR
                (Str.Pos(str,Connect.NoCon5Str)#MAX(CARDINAL)) AND (Connect.NoCon5Str[0]#0C) THEN
             Lib.Delay(1000);
             Window.Close(W2);
             RETURN FALSE;
          END;
       ELSE
         p := p+1;
       END;
    END;
  END;
END DoConnect;


VAR c : CHAR;
BEGIN
  rs.Install(PortNr);
  rs.Init( BaudRate,7,rs.Even,TRUE,FALSE );
  W := Window.Open(WT);

  IF NOT DoConnect() THEN
     IO.WrStr('No connection');
     HangUp;
     HALT;
  END;

  LOOP
     IF IO.KeyPressed() THEN
        c := IO.RdKey();

        (*Exit on F2*)

        IF (c=0C) AND (CHR(60)=IO.RdKey()) THEN
            HangUp;
            EXIT
        END;
        WHILE rs.TxFree()=0 DO END;
        rs.Send( c,1 );
     END;
     IF rs.RxCount()#0 THEN
        rs.Receive(c,1);
        IO.WrChar(c);
     END;
  END;

END RDemo.
