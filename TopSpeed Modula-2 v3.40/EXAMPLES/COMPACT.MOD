IMPLEMENTATION MODULE Compact;

(* A memory handler that allows the heap to be compacted *)
(* For the time being will only work with one 64K segment *)
(* Note that this is for demonstration purposes and therefore is designed
to be visible rather than fast. A rewrite would be in order before using
this thing in anger*)

IMPORT Storage,Lib;

VAR
  Head:MemRecP;  (* If more that one segment this would be more complex *)
  NextHandle:HandleType;

PROCEDURE MergeBlanks();
  VAR
    Finger:MemRecP;
  BEGIN
    Finger:=Head;
    WHILE (Finger<>NIL) AND (Finger^.Next<>NIL) DO
      IF (Finger^.Handle=NotAHandle) AND (Finger^.Next^.Handle=NotAHandle) THEN
        Finger^.Length:=Finger^.Length+Finger^.Next^.Length+SIZE(MemRec);
        Finger^.Next:=Finger^.Next^.Next
      ELSE
        Finger:=Finger^.Next;
      END;
    END
  END MergeBlanks;

PROCEDURE Deallocate(x:HandleType);
  VAR
    Finger:MemRecP;
  BEGIN
    Finger:=Head;
    WHILE (Finger<>NIL) AND (Finger^.Handle<>x) DO
      Finger:=Finger^.Next
    END;
    IF Finger<>NIL THEN
      Finger^.Handle:=NotAHandle;
      MergeBlanks();
    END
  END Deallocate;

PROCEDURE CompactMemory();
  VAR
    Temp,Finger:MemRecP;
    OldSize,ComingSize:CARDINAL;
  BEGIN
    Finger:=Head;
    WHILE (Finger<>NIL) AND (Finger^.Next<>NIL) DO
      IF Finger^.Handle=NotAHandle THEN (* Two blanks so merge *)
        ComingSize:=Finger^.Next^.Length+SIZE(MemRec);
        IF Finger^.Next^.Handle=NotAHandle THEN
          Finger^.Length:=Finger^.Length+ComingSize;
          Finger^.Next:=Finger^.Next^.Next;
        ELSE
          OldSize:=Finger^.Length;
          Lib.Move(Finger^.Next,Finger,ComingSize);  (* Move data down *)
          Temp:=Lib.AddAddr(Finger,ComingSize);  (* Create the new blank record *)
          Temp^.Handle:=NotAHandle;
          Temp^.Length:=OldSize;
          Temp^.Next:=Finger^.Next;
          Finger^.Next:=Temp;
        END
      ELSE
        Finger:=Finger^.Next;
      END
    END;
  END CompactMemory;

PROCEDURE DerefHandle(x:HandleType):ADDRESS;
  VAR
    Finger:MemRecP;
  BEGIN
    Finger:=Head;
    WHILE (Finger<>NIL) AND (Finger^.Handle<>x) DO
      Finger:=Finger^.Next
    END;
    IF Finger=NIL THEN
      RETURN ADDRESS(0)
    ELSE
      RETURN Lib.AddAddr(Finger,SIZE(MemRec))
    END
  END DerefHandle;

PROCEDURE Allocate(size:CARDINAL):HandleType;
  VAR
    SecondTry:BOOLEAN;
    Value:HandleType;
    Temp,Finger:MemRecP;
  BEGIN
    SecondTry:=TRUE;
    IF size<SmallestAlloc THEN
      size:=SmallestAlloc
    END;
    Value:=NotAHandle;
    REPEAT
      SecondTry:=NOT SecondTry;
      Finger:=Head;
      WHILE (Finger<>NIL) AND (
            (Finger^.Handle<>NotAHandle) OR (Finger^.Length<size)) DO
        Finger:=Finger^.Next
      END;
      IF Finger=NIL THEN
        IF NOT SecondTry THEN
          CompactMemory
        END
      ELSE
        INC(NextHandle);
        Value:=NextHandle;
        IF Finger^.Length>size+SIZE(MemRec) THEN (* Insert new blank record *)
          Temp:=Lib.AddAddr(Finger,size+SIZE(MemRec));
          Temp^.Length:=Finger^.Length-size-SIZE(MemRec);
          Temp^.Handle:=NotAHandle;
          Temp^.Next:=Finger^.Next;
          Finger^.Next:=Temp;
          Finger^.Length:=size;
        ELSE
          size:=Finger^.Length;
        END;
        Finger^.Handle:=Value;
      END;
    UNTIL SecondTry OR (Value<>NotAHandle);
    RETURN Value;
  END Allocate;

BEGIN
  Storage.ALLOCATE(Head,64*1024);
  Head^.Length:=64*1024-SIZE(MemRec);
  Head^.Next:=NIL;
  Head^.Handle:=MAX(CARDINAL);
  NextHandle:=NotAHandle;
END Compact.