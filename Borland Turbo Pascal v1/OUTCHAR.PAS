program outchar;

type
  regpack = record
            ax,bx,cx,dx,bp,si,di,ds,es,flags: integer;
            end;

procedure oc( var c : char );
var
  recpack:        regpack;
  ah,al,ch,cl,dh: byte;

begin
  ah := $8;
  with recpack do
  begin
    ax := ah shl 8 + al;
    dx := ord( c );
  end;
  intr( $21, recpack );

end;

var c : char;
begin { outchar }
  c := 'W';
  oc( c );
end. { outchar }
