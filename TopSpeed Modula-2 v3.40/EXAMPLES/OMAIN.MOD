MODULE omain;
(*%F _fdata*) Make program in XLarge or MThread model (*%E*)

IMPORT Ovl117,op1,op2,op3;

IMPORT IO; (* IO is used in op1-op3, and therefore must be initialized
              before op1-op3 are used, this import ensures this *)

PROCEDURE x;
BEGIN
  Ovl117.Load(1);
  op1.p1;
  Ovl117.UnLoad(1);
  Ovl117.Load(2);
  op2.p2;
  op3.p3;
  Ovl117.UnLoad(2);
END x;

BEGIN
  x;
END omain.


