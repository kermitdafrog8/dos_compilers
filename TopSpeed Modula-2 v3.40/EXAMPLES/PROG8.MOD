MODULE prog8;
(* This program implements a simple interactive calculator *)
IMPORT IO,Str,Storage;

TYPE
  TokenType = (number, add, sub, mul, div, LeftParen,
                RightParen, end);
  SyntacticType = (main, exp, term, factor);
  TreeType = POINTER TO TreeRecordType;

  TreeRecordType = RECORD
    CASE kind:TokenType OF
    | number :
      NumberValue : LONGREAL;
    | add,sub,mul,div :
      left : TreeType;
      right : TreeType;
    END;
  END;

VAR
  c:CHAR;
  token:TokenType;
  TokenNumberValue:LONGREAL;

PROCEDURE error(s:ARRAY OF CHAR);
BEGIN
  IO.WrStr(s);
  IO.WrLn;
  HALT;
END error;

PROCEDURE readtoken;
VAR
  s:ARRAY[0..99] OF CHAR;
  i:[0..99];
  done:BOOLEAN;
  oldc:CHAR;
BEGIN
  LOOP
    oldc := c;
    c := IO.RdChar();
    CASE oldc OF
    | ' ' :
    | '+' : token := add; EXIT;
    | '-' : token := sub; EXIT;
    | '*' : token := mul; EXIT;
    | '/' : token := div; EXIT;
    | '(' : token := LeftParen; EXIT;
    | ')' : token := RightParen; EXIT;
    | CHAR(10),CHAR(13),CHAR(26) : token := end; EXIT;

    | '0'..'9' : (* read a real number *)
      i := 1; s[0] := oldc;
      WHILE (c >= '0') AND (c <= '9') DO
        s[i] := c;
        INC(i);
        c := IO.RdChar();
      END;
      IF c<>'.' THEN (* add decimal point if none in input *)
        s[i] := '.';
        INC(i);
      ELSE
        REPEAT (* read fraction part *)
          s[i] := c;
          INC(i);
          c := IO.RdChar();
        UNTIL (c < '0') OR (c > '9');
      END;
      s[i] := CHAR(0);
      TokenNumberValue := Str.StrToReal(s, done);
      IF NOT done THEN
        error('Bad number?');
      END;
      token := number;
      EXIT;
    ELSE
      error('Bad character');
    END;
  END;
END readtoken;

PROCEDURE read(what:SyntacticType):TreeType;
VAR t,t1:TreeType;
BEGIN
  CASE what OF
  | factor :
    IF token = LeftParen THEN
      readtoken;
      t := read(exp);
      IF token = RightParen THEN
        readtoken;
      ELSE
        error("Missing ')'");
      END;
    ELSIF token = number THEN
      Storage.ALLOCATE(t, SIZE(t^));
      t^.kind := number;
      t^.NumberValue := TokenNumberValue;
      readtoken;
    ELSE
      error('Missing number?');
    END;
  | term:
    t := read(factor);
    WHILE (token = mul) OR (token = div) DO
      t1 := t;
      Storage.ALLOCATE(t, SIZE(t^));
      t^.kind := token;
      readtoken;
      t^.left := t1;
      t^.right := read(factor);
    END;
  | exp:
    t := read(term);
    WHILE (token = add) OR (token = sub) DO
      t1 := t;
      Storage.ALLOCATE(t, SIZE(t^));
      t^.kind := token;
      readtoken;
      t^.left := t1;
      t^.right := read(term);
    END;
  | main :
    c := IO.RdChar();
    readtoken;
    t := read(exp);
    IF (token <> end) THEN
      error('Missing operator?');
    END;
  END;
  RETURN t;
END read;

PROCEDURE eval(t:TreeType):LONGREAL;
BEGIN
  CASE t^.kind OF
  | number : RETURN t^.NumberValue;
  | add : RETURN eval(t^.left) + eval(t^.right);
  | sub : RETURN eval(t^.left) - eval(t^.right);
  | mul : RETURN eval(t^.left) * eval(t^.right);
  | div : RETURN eval(t^.left) / eval(t^.right);
  END;
END eval;

VAR
  t:TreeType;
  result:LONGREAL;
BEGIN
  LOOP
    IO.WrStr('Enter expression : ');
    t := read(main);
    result := eval(t);
    IO.WrStr(' = ');
    IO.WrLngReal(result, 4, 0);
    IO.WrLn;
  END;
END prog8.
