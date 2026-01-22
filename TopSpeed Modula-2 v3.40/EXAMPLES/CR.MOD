(* =========================================== *)
(* (c) 1990-1992 Clarion Software Corporation  *)
(* =========================================== *)

MODULE CR;

    (* Prints a cross-reference table of Modula-2 program. All user-defined
       words are listed in alphabetical order together with the count of
       the number of references and a list of all reference line numbers.

        This program will cross reference the words in comments as well
        as those in the source code.
    *)

    IMPORT Table, IO, Str, Lib, FIO;

    (* Modula-2 Keywords and Predefined Identifiers *)

    CONST

        KeyWords =
            'BY DO IF IN OF OR TO AND DIV END FOR MOD NOT SET VAR CASE ELSE '+
            'EXIT FROM GOTO LOOP THEN TYPE WITH ARRAY BEGIN CONST ELSIF LABEL '+
            'UNTIL WHILE EXPORT IMPORT MODULE RECORD REPEAT RETURN FORWARD '+
            'POINTER PROCEDURE DEFINITION IMPLEMENTATION QUALIFIED CLASS'+
            'SHORTINT INTEGER LONGINT BOOLEAN CHAR BYTE SHORTCARD CARDINAL '+
            'WORD LONGCARD LONGWORD REAL LONGREAL ADDRESS SHORTADDR BITSET '+
            'TRUE FALSE NIL PROC HALT NULLPROC CAP ABS CHR FLOAT HIGH ODD '+
            'TRUNC VAL DEC EXCL INC INCL SIZE VSIZE ADR ORD NEW DISPOSE MAX MIN ';


    TYPE
        SymTabPtr = POINTER TO SymTab;
        CLASS SymTab(Table.Element);        (* Symbol table entry *)

            Count  : INTEGER;               (* Reference count *)
            LRef   : Table.TABLE;           (* Cross-Ref List *)
            Name   : ARRAY [0..30] OF CHAR; (* This word *)

            VIRTUAL PROCEDURE Compare( p : Table.ElementPtr ) : INTEGER;

        END SymTab ;

        CLASS IMPLEMENTATION SymTab;

            VIRTUAL PROCEDURE Compare( p : Table.ElementPtr ) : INTEGER;
            BEGIN
                RETURN Str.Compare(Name,SymTabPtr(p)^.Name);
            END Compare;

        BEGIN
        END SymTab ;

TYPE

        LinTabPtr = POINTER TO LinTab;

        CLASS LinTab(Table.Element);       (* Line number table entry *)

            RefLn : INTEGER;               (* Line number *)

            VIRTUAL PROCEDURE Compare( p : Table.ElementPtr ) : INTEGER;

        END LinTab ;

        CLASS IMPLEMENTATION LinTab;       (* Line number table entry *)

            VIRTUAL PROCEDURE Compare( p : Table.ElementPtr ) : INTEGER;
            BEGIN
                IF (RefLn < LinTabPtr(p)^.RefLn) THEN
                    RETURN -1;
                ELSIF (RefLn > LinTabPtr(p)^.RefLn) THEN
                    RETURN  1;
                ELSE
                    RETURN  0;
                END;
            END Compare;

        BEGIN
        END LinTab ;


    VAR
        ni : CARDINAL; (* Column count for printing routines *)

    PROCEDURE PrintLineNo( p : Table.ElementPtr );
        (* Prints the line-number information for 'p', which is of
           CLASS 'LinTab'.
        *)

    VAR
        t, l : CARDINAL;
    BEGIN
        (* These first few lines count the number of digits in 'p.val' and
           then check if there's enough room on the line for it.
        *)
        t := LinTabPtr(p)^.RefLn;
        l := 1;
        REPEAT
            INC(l);
            t := t DIV 10;
        UNTIL  t=0;        (* l := number of digits in line number *)
        IF (ni < l) THEN   (* Not enough room *)
           ni := 40;
           IO.WrLn;
           IO.WrCharRep(' ',37);
        END;
        IO.WrInt(LinTabPtr(p)^.RefLn,1);
        IO.WrChar(' ');
        DEC(ni,l);
    END PrintLineNo;

    PROCEDURE PrintSymbol( r : Table.ElementPtr );
        (* Prints the symbol, definition line and cross-reference lines
           of the symbol 'r' (of type 'SymtabPtr') *)
    BEGIN
        IO.WrStrAdj(SymTabPtr(r)^.Name,-30);
        IO.WrInt(SymTabPtr(r)^.Count,-4);
        IO.WrStr(' : ');
        ni := 40;
        SymTabPtr(r)^.LRef.Apply(PrintLineNo);
        (* List line numbers for symbol *)
        IO.WrLn;
    END PrintSymbol;

    VAR

        SymbolTable,                    (* Actual table *)
        Predef       : Table.TABLE;     (* Key word table *)
        LineNr       : LinTab;          (* Work Area *)
        i,Item       : CARDINAL;
        Symbol       : SymTab;          (* Word Area *)
        FileName     : ARRAY [0..100] OF CHAR;
        File         : FIO.File;
        Buffer       : ARRAY [1..(1024 + FIO.BufferOverhead)] OF CHAR;
        Line         : ARRAY [0..1023] OF CHAR;


    PROCEDURE FillPre;
        (* Fill 'PreDef' with keyword from 'KeyWords' *)
        VAR
            i, j : CARDINAL;
            x    : SymTab;
    BEGIN
        Predef.Init;                        (* Initialize TABLE *)
        i := 0;
        WHILE (KeyWords[i] # 0C) DO
            j := 0;
            WHILE (KeyWords[i] # ' ') DO
                x.Name[j] := KeyWords[i];
                INC(j);
                INC(i);
            END;
            x.Name[j] := 0C;
            IF (j # 0) THEN
                Predef.Insert(x);
            END;
            INC(i);
        END (* WHILE *);
    END FillPre;

BEGIN
    (* check parameters *)
    IF Lib.ParamCount() <> 1 THEN
      IO.WrStr('Try again : cr input-file');
      IO.WrLn;
      HALT;
    END;
  
    SymbolTable.Init;                   (* Initialize symbol table        *)
    Lib.ParamStr(FileName,1);           (* Get filename from command line *)
    File := FIO.OpenRead(FileName);     (* Open - only need to read it    *)
    FIO.AssignBuffer(File,Buffer);      (* Associate a buffer with file
                                           to speed up access             *)
    LineNr.RefLn := 1;                  (* Initialise line counter        *)
    LOOP
        FIO.RdStr(File,Line);           (* Read line from file            *)
        IF FIO.EOF THEN                 (* Check for end-of-file          *)
            EXIT;
        END;
        Item := 0;
        LOOP
            Str.Item(Symbol.Name,Line,
                     Str.CHARSET{ 0C..CHAR(255) } -
                     Str.CHARSET{ 'A'..'Z','a'..'z','_','0'..'9','.' },Item);
                     (* Extracts a single word from 'Line'. Each word
                        is delimited by any characters except a digit, a letter,
                        an underbar or a '.'.
                     *)
            IF (Symbol.Name[0] = 0C) THEN (* Check that there was a word *)
                EXIT;
            END;
            INC(Item);
            IF (Symbol.Name[0] > '9') THEN (* Don't enter numbers in table *)
                IF (SymbolTable.Find(Symbol)) THEN
                                             (* Is word already in tabel? *)
                    INC(Symbol.Count);       (* If, yes, increment count *)
                ELSE
                    Symbol.Count := 1;
                    Symbol.LRef.Init;        (* Initailize line number table *)
                END;
                Symbol.LRef.Insert(LineNr);  (* Insert cross-reference *)
                SymbolTable.Insert(Symbol);  (* Insert/Update symbol entry *)
            END;
        END (* LOOP through line *);
        INC(LineNr.RefLn);                     (* Next line *)
    END (* LOOP - File *);
    FillPre;                        (* Build table of predefined words *)
    SymbolTable.Excl(Predef);       (* Exclude predefined words from table *)
    SymbolTable.Apply(PrintSymbol); (* Display table *)
    Predef.Dispose;                 (* Reclaim storage for predefined words *)
    SymbolTable.Dispose;            (* Reclaim storage other names *)
END CR.
