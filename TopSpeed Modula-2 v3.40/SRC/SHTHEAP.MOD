(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  SHTHEAP.MOD - Short heaps                                               *
*                                                                          *
*  COPYRIGHT (C) 1987..1992 Clarion Software Corporation.                  *
*  All Rights Reserved                                                     *
*                                                                          *
*--------------------------------------------------------------------------*)

(*# call(o_a_copy => on,
         o_a_size => on) *)
(*%F _fdata *)
(*# call(seg_name => null) *)
(*# data(seg_name => null) *)
(*%E *)
(*# module(implementation=>off) *)
(*# check(stack=>off,
          index=>off,
          range=>off,
          overflow=>off,
          nil_ptr=>off) *)

IMPLEMENTATION MODULE ShtHeap ;

IMPORT Lib, SYSTEM, CoreSig;

TYPE   Offset = CARDINAL;
       Block  = RECORD
                  Siz: Size;
                  Nxt: Pointer;
                END;


  PROCEDURE Initialize ( H: Segment; Z: Size );
  VAR B,F: POINTER H TO Block;
  BEGIN
    Z := (Z DIV Align) * Align;
    IF Z < 10 THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 9AH, 'ShtHeap.Initialize : Size Too Small');
    END;
    B := Pointer ( 0 );
    F := Pointer ( Align );
    B^.Siz := Z;
    B^.Nxt := F;
    F^.Siz := Z - Align;
    F^.Nxt := Nil;
  END Initialize;


  PROCEDURE Increase ( H: Segment; Z: Size );
  VAR B,L,I: POINTER H TO Block;
  BEGIN
    IF Debug THEN
      Test ( H );
    END;
    Z := (Z DIV Align) * Align;
    B := Pointer ( 0 );
    IF Z > MAX(Size) - B^.Siz THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 9BH, 'ShtHeap.Increase : Size Too Large');
    END;
    I := B;
    REPEAT
      L := I;
      I := I^.Nxt;
    UNTIL I = Nil;
    IF (L # B) AND (Offset ( L ) + L^.Siz = B^.Siz) THEN
      INC ( L^.Siz , Z );
    ELSE
      I := Pointer ( B^.Siz );
      L^.Nxt := I;
      I^.Siz := Z;
      I^.Nxt := Nil;
    END;
    INC ( B^.Siz , Z );
  END Increase;


  PROCEDURE Allocate ( H: Segment; VAR P: Pointer; Z: Size );
  VAR B,F,G,N: POINTER H TO Block;
  BEGIN
    IF Debug THEN
      Test ( H );
    END;
    Z := ( (Z+Align-1) DIV Align) * Align;
    IF Z = 0 THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 9CH, 'ShtHeap.Allocate : Size Too Small');
    END;
    B := Pointer ( 0 );
    G := B;
    LOOP
      F := G^.Nxt;
      IF F = Nil THEN
        IF Check THEN
            Lib.RunTimeError(CoreSig._FatalErrorPos(), 9DH, 'ShtHeap.Allocate : Out Of Memory');
        ELSE
            P := Nil;
            RETURN;
        END;
      ELSIF F^.Siz >= Z THEN
        EXIT;
      END;
      G := F;
    END;
    IF F^.Siz = Z THEN
      G^.Nxt := F^.Nxt;
    ELSE
      N := Pointer ( Offset ( F ) + Z );
      G^.Nxt := N;
      N^.Siz := F^.Siz - Z;
      N^.Nxt := F^.Nxt;
    END;
    IF Clear THEN
      Lib.WordFill ( ADR(F^) , Z DIV 2 , 0 );
    END;
    P := F;
  END Allocate;


  PROCEDURE Free ( H: Segment; VAR P: Pointer; Z: Size );
  VAR B,F,G,Q: POINTER H TO Block;
  BEGIN
    IF Debug THEN
      Test ( H );
    END;
    Z := ( (Z+Align-1) DIV Align) * Align;
    Q := P;
    P := Nil;
    IF Q = Nil THEN
        Lib.RunTimeError(CoreSig._FatalErrorPos(), 9EH, 'ShtHeap.Free : Invalid Argument');
    END;
    B := Pointer ( 0 );
    G := B;
    LOOP
      F := G^.Nxt;
      IF (F = Nil) OR (Offset ( Q ) < Offset ( F )) THEN EXIT; END;
      G := F;
    END;
    IF Offset ( G ) + G^.Siz = Offset ( Q ) THEN
      INC ( G^.Siz , Z );
      Q := G;
    ELSE
      G^.Nxt := Q;
      Q^.Nxt := F;
      Q^.Siz := Z;
    END;
    IF Offset ( Q ) + Q^.Siz = Offset ( F ) THEN
      INC ( Q^.Siz , F^.Siz );
      Q^.Nxt := F^.Nxt;
    END;
  END Free;


  PROCEDURE Largest ( H: Segment ): Size;
  VAR P: POINTER H TO Block;
      Z: Size;
  BEGIN
    IF Debug THEN
      Test ( H );
    END;
    P := Pointer ( 0 );
    P := P^.Nxt;
    Z := 0;
    WHILE P # Nil DO
      IF Z < P^.Siz THEN
        Z := P^.Siz;
      END;
      P := P^.Nxt;
    END;
    RETURN Z;
  END Largest;


  PROCEDURE Total ( H: Segment ): Size;
  VAR P: POINTER H TO Block;
      Z: Size;
  BEGIN
    IF Debug THEN
      Test ( H );
    END;
    P := Pointer ( 0 );
    P := P^.Nxt;
    Z := 0;
    WHILE P # Nil DO
      INC ( Z , P^.Siz );
      P := P^.Nxt;
    END;
    RETURN Z;
  END Total;


  PROCEDURE Test ( H: Segment );
  VAR B,F,G: POINTER H TO Block;
  BEGIN
    B := Pointer ( 0 );
    IF B^.Siz MOD Align # 0 THEN
        Lib.RunTimeError(CoreSig._FatalErrorPos(), 9FH, 'ShtHeap.Test : Non-aligned heap size.');
    END;
    G := B;
    LOOP
      F := G^.Nxt;
      IF F = Nil THEN EXIT; END;
      IF    Offset ( F ) >= B^.Siz THEN
        Lib.RunTimeError(CoreSig._FatalErrorPos(), 9FH, "ShtHeap.Test: Free block out of range" );
      ELSIF Offset ( F ) MOD Align # 0 THEN
        Lib.RunTimeError(CoreSig._FatalErrorPos(), 9FH,  "ShtHeap.Test: Non-aligned free block" );
      ELSIF F^.Siz MOD Align # 0 THEN
        Lib.RunTimeError(CoreSig._FatalErrorPos(), 9FH,  "ShtHeap.Test: Non-aligned free block size" );
      ELSIF Offset ( F ) < Offset ( G ) THEN
        Lib.RunTimeError(CoreSig._FatalErrorPos(), 9FH,  "ShtHeap.Test: Unordered free list" );
      ELSIF (G # B) AND (Offset ( G ) + G^.Siz = Offset ( F )) THEN
        Lib.RunTimeError(CoreSig._FatalErrorPos(), 9FH,  "ShtHeap.Test: Unjoined free list" );
      ELSIF (G # B) AND (Offset ( G ) + G^.Siz > Offset ( F )) THEN
        Lib.RunTimeError(CoreSig._FatalErrorPos(), 9FH,  "ShtHeap.Test: Overlapping free list" );
      END;
      G := F;
    END;
  END Test;


BEGIN
  IF SIZE ( Block ) > Align THEN
    Lib.FatalError ( "ShtHeap: Alignment too small" );
  END;
  Clear := FALSE;
  Check := TRUE;
  Debug := FALSE;
END ShtHeap.
