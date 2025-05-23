{ Copyright (c) 1985, 88 by Borland International, Inc. }

program Circular;
{ Simple program that demonstrates newly-permitted circular
  unit references via a USES clause in the implementation
  section.

  Note that it is NOT possible for the two units to
  "USE" each other in their interface sections. It is possible
  for AA's interface to use BB, and BB's implementation to use
  AA, but this is tricky and depends on compilation order. We
  won't document or recommend it.
}

uses
  Crt, Display, Error;

begin
  ClrScr;
  WriteXY(1, 1, 'Upper left');
  WriteXY(100, 100, 'Off the screen');
  WriteXY(81 - Length('Back to reality'), 15, 'Back to reality');
end.
