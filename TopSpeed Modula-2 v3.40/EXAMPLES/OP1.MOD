(*# module(init_code=>off) *) (* overlayed modules are not allowed to have initcode *)
IMPLEMENTATION MODULE op1;
IMPORT IO;
PROCEDURE p1;
BEGIN
  IO.WrStr('procedure p1 in op1');
  IO.WrLn;
END p1;

END  op1.
