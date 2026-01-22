MODULE CompDemo;

(* This module demonstrates the use of virtual pointers and the Compact
module to implement a heap the does not suffer from fragmentation.
Note however that the heap is very slow *)

(*%F _fptr *)
This demo program will only work in memory models with far data pointers
(*%E *)

IMPORT Compact,IO,Str;

TYPE
  SString=ARRAY[0..63] OF CHAR;
  LString=ARRAY[0..255] OF CHAR;
  StrP=POINTER TO LString;


INLINE PROCEDURE StrDeref(x:Compact.HandleType):StrP;
  BEGIN
    RETURN StrP(Compact.DerefHandle(x))
  END StrDeref;

TYPE
  MovableStrP=VIRTUAL POINTER StrDeref;

VAR
  StrArray:ARRAY[1..1000] OF MovableStrP;
  OK:BOOLEAN;
  I,TotDone:CARDINAL;

BEGIN
  IO.WrStr('First to allocate as many strings of length 64 as possible');
  IO.WrLn;
  I:=1;
  LOOP
    StrArray[I]:=MovableStrP(Compact.Allocate(64));
    IF StrArray[I]=MovableStrP(Compact.NotAHandle) THEN EXIT END;
    Str.CardToStr(LONGCARD(I),StrArray[I]^,10,OK);
    I:=I+1
  END;
  TotDone:=I-1;
  IO.WrStr('Able to create ');
  IO.WrCard(TotDone,5);
  IO.WrStr(' such strings. ');
  IO.WrLn;
  IO.WrStr('Each contains the string form of the index number');
  IO.WrLn;
  IO.WrStr('For example Value[100]=');
  IO.WrStr(StrArray[100]^);
  IO.WrLn;
  IO.WrStr('Now release every OTHER string leaving lots of 64 byte holes in heap');
  IO.WrLn;
  I:=1;
  WHILE (I<TotDone) DO
    Compact.Deallocate(Compact.HandleType(StrArray[I]));
    I:=I+2;
  END;
  IO.WrStr('With a normal heap manager the largest element you could allocate would');
  IO.WrLn;
  IO.WrStr('be 64 bytes. But with this heap manager a request for >64 bytes will');
  IO.WrLn;
  IO.WrStr('result in a heap compaction freeing up all space to be allocated in');
  IO.WrLn;
  IO.WrStr('one block. Now to allocate some 256 byte strings.');
  I:=1;
  LOOP
    StrArray[I]:=MovableStrP(Compact.Allocate(256));
    IF StrArray[I]=MovableStrP(Compact.NotAHandle) THEN EXIT END;
    I:=I+2
  END;
  IO.WrLn;
  IO.WrStr('Managed ');
  IO.WrCard((I-1) DIV 2,5);
  IO.WrLn;
  IO.WrStr('Just to prove the old values have not been lost as a result here is Value[100]');
  IO.WrLn;
  IO.WrStr('again :');
  IO.WrStr(StrArray[100]^);
  IO.WrLn;
  IO.WrStr('And the really clever thing is that these pointers are dereferenced');
  IO.WrLn;
  IO.WrStr('using the usual syntax as examining the code will show.');
END CompDemo.