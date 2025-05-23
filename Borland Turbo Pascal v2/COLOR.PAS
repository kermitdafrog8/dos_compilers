program ColorDemo;

type
  AnyString = string[40];


procedure Check;
var
  Ch: char;
begin
  writeln('This program will only work if you have the color graphics adapter installed');
  write('Continue Y/N ');
  repeat read (Kbd,Ch)  until Upcase(Ch) in ['Y','N'];
  if Upcase(Ch)='N' then Halt;
end;



procedure PaletteDemo;
var
  Ch: Char;
  PaletteNumber, Background: integer;
  PaletteChange: boolean;

  procedure DrawBoxes;
  var
    Y: integer;
  begin
    for Y:=1 to 24 do Draw(10,10*8+Y,320,10*8+Y,1);
    for Y:=1 to 24 do Draw(10,13*8+Y,320,13*8+Y,2);
    for Y:=1 to 24 do Draw(10,16*8+Y,320,16*8+Y,3);
  end {DrawBoxes};

  procedure Msg(X,Y: integer; S: AnyString);
  { write the string S at X,Y }
  begin
    GotoXY(X,Y);
    Write(S);
  end {Msg};

  procedure Help;
  begin { write the help text}
    Msg(1,1,'           TURBO COLOR DEMO ');
    Msg(1,3,'Procedures used:');
    Msg(1,6,' To make  background: ');
    Msg(1,7,' To select a palette:  ');
    Msg(1,9,'Colors in selected palette are:');
    Msg(1,12,'1');
    Msg(1,15,'2');
    Msg(1,18,'3');
    Msg(1,21,'Use arrows to change palette number');
    Msg(1,22,'or press B to change Background');
    GotoXY(1,25);
    write('Press ESC twice to exit');
  end {Help};


  procedure Update;
  begin
    GotoXY(22,6); write('GraphBackground(',Background,') ');
    GotoXY(22,7); write('Palette(',PaletteNumber,')');
    GraphBackground(Background);
    Palette(PaletteNumber);
    if PaletteChange then
    begin
      GotoXY(1,21);
      writeln('Use arrows to change palette number    ');
      write('Press B to change Background ');
    end else
    begin
      GotoXY(1,21);
      writeln('Use arrows to change background number');
      write('or press P to change Palette    ');
    end;
  end {Update};

begin {PaletteDemo}
  GraphColorMode;
  BackGround:=0;
  PaletteNumber:=0;
  GraphBackground(BackGround);
  Palette(PaletteNumber);
  DrawBoxes;
  Help;
  Update;
  repeat
    repeat read(Kbd,Ch) until Ch in ['P','p','B','b',#27];
    case Upcase(Ch) of
      'P': PaletteChange:=true;
      'B': PaletteChange:=false;
      #27: begin
             read(Kbd,Ch);
             case Ch of
               'P': begin
                      if PaletteChange then
                      begin
                        PaletteNumber:=PaletteNumber-1;
                        if PaletteNumber<0 then PaletteNumber:=0;
                      end else
                      begin
                        Background:=BackGround-1;
                        if BackGround<0 then BackGround:=0;
                      end;
                    end;
               'H': begin
                      if PaletteChange then
                      begin
                        PaletteNumber:=PaletteNumber+1;
                        if PaletteNumber>3 then PaletteNumber:=3;
                      end else
                      begin
                        Background:=BackGround+1;
                        if BackGround>15 then BackGround:=15;
                      end;
                    end;
           end;
         end;
    end;
    Update;
  until Ch=#27;
end {Palettedemo};



begin {Main program}
  Check;
  PaletteDemo;
  TextMode;
end.



