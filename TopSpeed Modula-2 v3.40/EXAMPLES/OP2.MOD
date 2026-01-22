(*# module(init_code=>off) *) (* overlayed modules are not allowed to have initcode *)
IMPLEMENTATION MODULE op2;
IMPORT IO;
PROCEDURE p2;
BEGIN
  IO.WrStr('procedure p2 in op2');
  IO.WrLn;
END p2;

END  op2.
