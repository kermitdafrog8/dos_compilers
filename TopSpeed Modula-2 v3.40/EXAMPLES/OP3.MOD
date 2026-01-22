(*# module(init_code=>off) *) (* overlayed modules are not allowed to have initcode *)
IMPLEMENTATION MODULE op3;
IMPORT IO;
PROCEDURE p3;
BEGIN
  IO.WrStr('procedure p3 in op3');
  IO.WrLn;
END p3;

END  op3.
