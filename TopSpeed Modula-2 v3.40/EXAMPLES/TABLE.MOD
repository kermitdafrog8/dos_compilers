(* ==================================================== *)
(* Copyright (C) 1990-1992 Clarion Software Corporation *)
(* ==================================================== *)

IMPLEMENTATION MODULE Table;

    IMPORT Lib;
    FROM Storage IMPORT ALLOCATE, DEALLOCATE;


        CLASS IMPLEMENTATION Element;

            VIRTUAL PROCEDURE Compare( p : ElementPtr ) : INTEGER;
            (* It is an error not to supply an implementation of this
               method. The client MUST supply a method to compare
               'THIS' with 'p'.
            *)
            BEGIN
                Lib.FatalError(' implemeted by client ');
                RETURN 0;
            END Compare;

        BEGIN
        END Element ;

        CLASS GenElem (Element) ;
            GenericData : CHAR;
        END GenElem;

        CLASS IMPLEMENTATION GenElem;
        BEGIN
        END GenElem;

TYPE
        GenElemPtr = POINTER TO GenElem;
            (* The above definitions are a skeleton for all the
               implementation of the 'Element' CLASS. This enables
               the 'TABLE' class to successfully copy any client
               implementation of 'Element'
            *)


        CLASS IMPLEMENTATION TABLE;

            PROCEDURE Insert( VAR  x : Element );
                (* Insert a new element 'x' in 'THIS' table *)

                PROCEDURE Search( VAR p : ElementPtr; VAR h : BOOLEAN);
                (* Searches a tree 'p' for the element 'x'. If it is found
                   then the new value replaces the old. If 'x' is not
                   in the tree, then 'x' becomes a new leaf of the tree.
                *)
                    VAR
                        p1    : ElementPtr;
                        p2    : ElementPtr;

                BEGIN
                    IF (p = NIL) THEN       (* Create new leaf *)
                        ALLOCATE(p,SIZE(x));
                        Lib.Move(ADR(x),p,SIZE(x));
                        p^.Bal := 0;
                        p^.Left := NIL;
                        p^.Right := NIL;
                        h := TRUE;          (* Tree requires balancing *)
                    ELSE
                        IF (x.Compare(p) < 0) THEN (* 'THIS' is < 'p' *)
                            (* Search the 'Left' branch of 'p' recursively
                               until 'x' is either found or created.
                            *)
                            Search(p^.Left,h);
                            IF h THEN        (* i.e. requires balancing *)
                                CASE p^.Bal OF
                                |  1 :
                                    p^.Bal := 0;
                                    h      := FALSE;
                                |  0 :
                                    p^.Bal := -1;
                                | -1 :
                                    p1 := p^.Left;
                                    IF (p1^.Bal = -1) THEN
                                        p^.Left   := p1^.Right;
                                        p1^.Right := p;
                                        p^.Bal    := 0;
                                        p         := p1;
                                    ELSE
                                        p2        := p1^.Right;
                                        p1^.Right := p2^.Left;
                                        p2^.Left  := p1;
                                        p^.Left   := p2^.Right;
                                        p2^.Right := p;
                                        IF (p2^.Bal = -1) THEN
                                            p^.Bal  :=  1;
                                        ELSE
                                            p^.Bal  :=  0;
                                        END;
                                        IF (p2^.Bal = 1) THEN
                                            p1^.Bal := -1;
                                        ELSE
                                            p1^.Bal :=  0;
                                        END;
                                        p := p2;
                                    END;
                                    p^.Bal := 0;
                                    h      := FALSE; (* Balancing done *)
                                END (* CASE *);
                            END (* of balancing 'Left' sub-tree *);
                        ELSIF (x.Compare(p) > 0) THEN (* 'THIS' > 'p' *)
                            (* Search the 'Right' branch of 'p' recursively
                               until 'x' is either found or created.
                            *)
                            Search( p^.Right,h);
                            IF h THEN          (* i.e. tree needs balancing *)
                                CASE p^.Bal OF
                                | -1 :
                                    p^.Bal := 0;
                                    h      := FALSE;
                                |  0 :
                                    p^.Bal := 1;
                                |  1 :
                                    p1 := p^.Right;
                                    IF (p1^.Bal = 1) THEN
                                        p^.Right := p1^.Left;
                                        p1^.Left := p;
                                        p^.Bal   := 0;
                                        p        := p1;
                                    ELSE
                                        p2        := p1^.Left;
                                        p1^.Left  := p2^.Right;
                                        p2^.Right := p1;
                                        p^.Right  := p2^.Left;
                                        p2^.Left  := p;
                                        IF (p2^.Bal = 1) THEN
                                            p^.Bal  := -1;
                                        ELSE
                                            p^.Bal  :=  0;
                                        END;
                                        IF (p2^.Bal = -1) THEN
                                            p1^.Bal :=  1;
                                        ELSE
                                            p1^.Bal :=  0;
                                        END;
                                        p := p2;
                                    END;
                                    p^.Bal := 0;
                                    h      := FALSE; (* Tree balanced *)
                                END (* CASE *);
                            END (* Balancing 'Right' sub-tree *);
                        ELSE (* 'THIS' and 'p' are the same *)
                           h := FALSE;
                           Lib.Move(ADR(GenElemPtr(ADR(x))^.GenericData),
                                    ADR(GenElemPtr(p)^.GenericData),
                                    SIZE(x)-VSIZE(Element.Bal));
                        END (* Possible comaprison results *);
                    END;
                END Search;

                VAR
                    h : BOOLEAN;

            BEGIN
                IF (Root # NIL) AND (ADR(Root^.Compare) # ADR(x.Compare)) THEN
                    (* All table elements must be homogeneous; i.e. they must be of
                       the same CLASS
                    *)
                    Lib.FatalError('object not compatible with table');
                END;
                Search(Root,h);
            END Insert;

            PROCEDURE Find( VAR x : Element ) : BOOLEAN;
                (* Search for 'x' in 'THIS' tree; if 'x' is found in
                   'THIS' tree then the function returns 'TRUE' and 'x'
                   is set to the mathing element. Otherwise the
                   method returns 'FALSE'.
                *)

                PROCEDURE _Find( r : ElementPtr ) : ElementPtr;
                    (* Implements the search algorithm *)
                BEGIN
                    LOOP
                        IF (r = NIL) THEN             (* No match *)
                            RETURN r;
                        ELSIF (x.Compare(r) < 0) THEN (* 'THIS' < r *)
                            r := r^.Left;
                        ELSIF (x.Compare(r) > 0) THEN (* 'THIS' > r *)
                            r := r^.Right;
                        ELSE                          (* FOUND IT! *)
                            RETURN r;
                        END;
                   END (* LOOP *);
                END _Find;

                VAR
                    p : ElementPtr;

            BEGIN
                p := _Find(Root);
                IF (p # NIL) THEN (* Element Located *)
                    Lib.Move(p,ADR(x),SIZE(x));
                    RETURN TRUE;
                ELSE
                    RETURN FALSE;
                END;
            END Find;

            PROCEDURE Delete( VAR x : Element );
                (* Locate the element 'x' in 'THIS' tree and delete it *)
                VAR
                   q : ElementPtr;

                PROCEDURE r_Balance( VAR p : ElementPtr; VAR h : BOOLEAN);
                    (* Blance a right sub-tree *)
                    VAR
                        p1 : ElementPtr;
                        p2 : ElementPtr;
                        b1 : BalanceFlag;
                        b2 : BalanceFlag;
                BEGIN
                    CASE p^.Bal OF
                    | -1 :
                        p^.Bal := 0;
                    |  0 :
                        p^.Bal := 1;
                        h      := FALSE;
                    |  1 :
                        p1 := p^.Right;
                        b1 := p1^.Bal;
                        IF (b1 >= 0) THEN
                            p^.Right := p1^.Left;
                            p1^.Left := p;
                            IF (b1 = 0) THEN
                                p^.Bal  := 1;
                                p1^.Bal := -1;
                                h       := FALSE
                            ELSE
                                p^.Bal  := 0;
                                p1^.Bal := 0;
                            END;
                            p := p1;
                        ELSE
                            p2 := p1^.Left;
                            b2 := p2^.Bal;
                            p1^.Left  := p2^.Right;
                            p2^.Right := p1;
                            p^.Right  := p2^.Left;
                            p2^.Left  := p;
                            IF (b2 = 1) THEN
                                p^.Bal  := -1;
                            ELSE
                                p^.Bal  :=  0;
                            END;
                            IF (b2 = -1) THEN
                                p1^.Bal :=  1;
                            ELSE
                                p1^.Bal :=  0;
                            END;
                            p       := p2;
                            p2^.Bal := 0;
                        END;
                    END (* CASE *);
                END r_Balance;

                PROCEDURE l_Balance( VAR p : ElementPtr; VAR h : BOOLEAN);
                    (* Balance a left sub-tree *)
                    VAR
                       p1 : ElementPtr;
                       p2 : ElementPtr;
                       b1 : BalanceFlag;
                       b2 : BalanceFlag;
                BEGIN
                    CASE p^.Bal OF
                    |  1 :
                        p^.Bal := 0;
                    |  0 :
                        p^.Bal := -1;
                        h      := FALSE;
                    | -1 :
                        p1 := p^.Left;
                        b1 := p1^.Bal;
                        IF (b1 <= 0) THEN
                            p^.Left   := p1^.Right;
                            p1^.Right := p;
                            IF (b1 = 0) THEN
                                p^.Bal  := -1;
                                p1^.Bal := 1;
                                h       := FALSE
                            ELSE
                                p^.Bal  := 0;
                                p1^.Bal := 0;
                            END;
                            p := p1;
                        ELSE
                            p2        := p1^.Right;
                            b2        := p2^.Bal;
                            p1^.Right := p2^.Left;
                            p2^.Left  := p1;
                            p^.Left   := p2^.Right;
                            p2^.Right := p;
                            IF (b2 = -1) THEN
                                p^.Bal  :=  1;
                            ELSE
                                p^.Bal  :=  0;
                            END;
                            IF (b2 = 1) THEN
                                p1^.Bal := -1;
                            ELSE
                                p1^.Bal :=  0;
                            END;
                            p       := p2;
                            p2^.Bal := 0;
                        END;
                    END (* CASE *);
                END l_Balance;

                PROCEDURE DeleteLeaf( VAR r : ElementPtr; VAR h : BOOLEAN );
                    (* Recursively search for extreme right-hand node of
                       the sub-tree 'r' and move data into 'q'
                    *)
                BEGIN
                    IF (r^.Right # NIL) THEN
                        DeleteLeaf(r^.Right,h);
                        IF h THEN
                            l_Balance(r,h);
                        END;
                    ELSE
                        Lib.Move(ADR(GenElemPtr(r)^.GenericData),
                                 ADR(GenElemPtr(q)^.GenericData),
                                 SIZE(x)-VSIZE(Element.Bal));
                        q := r;
                        r := r^.Left;
                        h := TRUE;
                     END;
                END DeleteLeaf;

                PROCEDURE _Delete( VAR p : ElementPtr; VAR h : BOOLEAN );
                    (* Main recursive deletion procedure *)
                BEGIN
                    IF (p = NIL) THEN                (* Not found *)
                        h := FALSE;
                    ELSIF (x.Compare(p) < 0) THEN    (* 'THIS' < 'p' *)
                        _Delete(p^.Left,h);
                        IF h THEN
                            r_Balance(p,h);
                        END;
                    ELSIF (x.Compare(p) > 0) THEN    (* 'THIS' > 'p' *)
                        _Delete(p^.Right,h);
                        IF h THEN
                            l_Balance(p,h);
                        END;
                    ELSE                             (* Found it! *)
                        q := p;
                        IF (q^.Right = NIL) THEN
                            p := q^.Left;
                            h := TRUE;
                        ELSIF (q^.Left = NIL) THEN
                            p := q^.Right;
                            h := TRUE;
                        ELSE
                            DeleteLeaf(q^.Left,h);
                            IF h THEN
                                r_Balance(p,h);
                            END;
                        END;
                        DISPOSE(q);
                    END;
                END _Delete;

                VAR
                   h : BOOLEAN;

            BEGIN
                IF (Root = NIL) THEN
                    RETURN;
                END;
                IF (Root # NIL) AND (ADR(x.Compare) # ADR(Root^.Compare)) THEN
                    (* 'x' is not the same type as tree members *)
                    Lib.FatalError('object not compatible with table');
                END;
                _Delete(Root,h);
            END Delete;

            PROCEDURE Apply( p : Action );
                (* Apply a procedure to all table elements in order *)

                PROCEDURE ApplyToElement( s : ElementPtr );
                    (* Apply 'p' to left sub-tree of s, then s, then the
                       right sub-tree of s.
                    *)
                BEGIN
                    IF (s = NIL) THEN
                        RETURN;
                    ELSE
                        ApplyToElement(s^.Left);
                        p(s);
                        ApplyToElement(s^.Right);
                    END;
                END ApplyToElement;

            BEGIN
                ApplyToElement(Root);
            END Apply;

            PROCEDURE Init;
                (* Initialise a tree *)
            BEGIN
                Root := NIL;
            END Init;


            PROCEDURE Eq( t2 : TABLE ) : INTEGER;
                (* Compare 'THIS' to 't2'. Return values:

                    <0  'THIS' is less than 't2'
                     0  'THIS' is equal to 't2'
                    >0  'THIS' is greater than 't2'

                   The trees are searched from the bottom up (i.e. in
                   order) and the elements compared. The procedure
                   returns immediately a difference is detected or
                   when both trees are exhausted (and, therefore, they
                   must be equal). This process is implemented iteratively
                   rather than recursively.
                *)

                VAR
                  S1,
                  S2    : ARRAY [1..32] OF ElementPtr;
                  r1,
                  r2    : ElementPtr;
                  sp1,
                  sp2   : CARDINAL;
                  res   : INTEGER;

            BEGIN
                r1 := Root;
                r2 := t2.Root;
                IF (r1 # NIL) AND (r1 # r2) AND (ADR(r1^.Compare) # ADR(r2^.Compare)) THEN
                    (* Both trees must contain the same sort of element *)
                    Lib.FatalError(' not compareable ');
                END;
                sp1 := 0;
                sp2 := 0;
                LOOP
                    WHILE (r1 # NIL) DO (* Build left edge array for 'THIS' *)
                        INC(sp1);
                        S1[sp1] := r1;
                        r1 := r1^.Left;
                    END;
                    WHILE (r2 # NIL) DO (* Build left edge array for 't2' *)
                        INC(sp2);
                        S2[sp2] := r2;
                        r2 := r2^.Left;
                    END;
                    IF (sp1 = 0) THEN (* No left sub-tree for 'THIS' *)
                        IF (sp2 = 0) THEN (* No left sub-tree for 't2' *)
                            RETURN 0; (* Implies they are equal *)
                        ELSE
                            RETURN -1; (* 'THIS' < 't2' *)
                        END;
                    ELSIF (sp2 = 0) THEN (* No left sub-tree for 't2' *)
                        RETURN 1; (* 'THIS' > 't2' *)
                    ELSE
                        r1 := S1[sp1];
                        DEC(sp1);
                        r2 := S2[sp2];
                        DEC(sp2);
                    END;
                    res := r1^.Compare(r2); (* Compare extreme left of both *)
                    IF (res # 0) THEN (* These are different! *)
                        RETURN res; (* Return how they are different *)
                    END;
                    r1 := r1^.Right;
                    r2 := r2^.Right;
                END (* LOOP *);
            END Eq;

            PROCEDURE SubSet( t2 : TABLE ) : BOOLEAN;
                (* Are the elements of 'THIS' table a sub set of the elements
                   of the table 't2'?
                   The procedure scans scans the trees in order looking for
                   an initial point of equality. Then 'THIS' is compared to
                   this sub-tree of 't2' until either an element greater than
                   the current 'THIS' element is found, or 'THIS' is exhuasted.
                   The process is implemented iteratively rather than
                   recursively.
                *)
                VAR
                    S1,
                    S2    : ARRAY [1..32] OF ElementPtr;
                    r1,
                    r2,
                    cr    : ElementPtr;
                    sp1,
                    sp2   : CARDINAL;
                    res   : INTEGER;
            BEGIN
                IF (Root # NIL) AND (t2.Root # Root) AND (ADR(Root^.Compare) # ADR(t2.Root^.Compare)) THEN
                    (* Both trees must contain the same type of element *)
                    Lib.FatalError('different types');
                END;
                r1 := Root;
                r2 := t2.Root;
                sp1 := 0;
                sp2 := 0;
                LOOP
                    WHILE (r1 # NIL) DO
                        INC(sp1);
                        S1[sp1] := r1;
                        r1 := r1^.Left;
                    END;
                    IF (sp1 = 0) THEN       (* End of 'THIS' => is a sub-tree *)
                        RETURN TRUE;
                    END;
                    r1 := S1[sp1];
                    DEC(sp1);
                    cr := r1;
                    r1 := r1^.Right;
                    LOOP
                        WHILE (r2 # NIL) DO
                            INC(sp2);
                            S2[sp2] := r2;
                            r2 := r2^.Left;
                        END;
                        IF (sp2 = 0) THEN    (* End of 't2' => not a sub-tree *)
                            RETURN FALSE;
                        ELSE
                            r2 := S2[sp2];
                            DEC(sp2);
                        END;
                        res := cr^.Compare(r2);
                        r2 := r2^.Right;
                        IF (res < 0) THEN
                            RETURN FALSE;
                        ELSIF (res = 0) THEN
                            EXIT;
                        END;
                    END (* LOOP *);
                END (* LOOP *);
            END SubSet;

            PROCEDURE Copy() : TABLE;
                (* Make a copy of 'THIS' *)

                PROCEDURE _Copy( r : ElementPtr ) : ElementPtr;
                    (* Recursively generate a copy of 'r' *)
                    VAR
                        x : ElementPtr;
                BEGIN
                    IF (r # NIL) THEN
                        ALLOCATE(x,SIZE(r^));
                        Lib.Move(r,x,SIZE(r^));
                        x^.Left  := _Copy(r^.Left);
                        x^.Right := _Copy(r^.Right);
                        RETURN x;
                    ELSE
                        RETURN r;
                    END;
                END _Copy;

            VAR
                NewTree : TABLE;
            BEGIN
                NewTree.Root := _Copy(Root);
               RETURN NewTree;
            END Copy;

            PROCEDURE Incl( t2 : TABLE);
               (* Include 't2' in 'THIS' tree *)

               PROCEDURE _Incl( r : ElementPtr );
                   (* Recursively insert 'r' into 'THIS' *)
               BEGIN
                   IF (r # NIL) THEN
                       _Incl(r^.Left);
                       _Incl(r^.Right);
                       Insert(r^);
                   END;
               END _Incl;

            BEGIN
                IF (Root # NIL) AND (t2.Root # Root) AND (ADR(Root^.Compare) # ADR(t2.Root^.Compare)) THEN
                    Lib.FatalError('different types');
                END;
                _Incl(t2.Root);
            END Incl;


            PROCEDURE Excl( t2 : TABLE);
                (* Exclude elements of 't2' from 'THIS' *)

                PROCEDURE _Excl( r: ElementPtr );
                    (* Recursively exclude 'r' from 'THIS' *)
                BEGIN
                    IF (r # NIL) THEN
                        _Excl(r^.Left);
                        _Excl(r^.Right);
                        Delete(r^);
                    END;
                END _Excl;

            BEGIN
                IF (Root # NIL) AND (t2.Root # Root) AND (ADR(Root^.Compare) # ADR(t2.Root^.Compare)) THEN
                    Lib.FatalError('different types');
                END;
                _Excl(t2.Root);
            END Excl;

            PROCEDURE Empty() : BOOLEAN;
                (* Is 'THIS' empty? *)
            BEGIN
                RETURN (Root = NIL);
            END Empty;

            PROCEDURE Dispose;
                (* Dispose of entire tree *)

               PROCEDURE _Dispose( r : ElementPtr );
                   (* Recursively dispose of each element of 'r' *)
               BEGIN
                   IF (r # NIL) THEN
                       _Dispose(r^.Left);   (* Delete left sub-tree *)
                       _Dispose(r^.Right);  (* Delete right sub-tree *)
                       DISPOSE(r);
                   END;
               END _Dispose;

            BEGIN
                _Dispose(Root);
            END Dispose;

        BEGIN

        END TABLE ;


END Table.
