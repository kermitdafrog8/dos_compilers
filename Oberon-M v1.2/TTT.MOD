MODULE TTT;
  IMPORT LIO;

  CONST
    ScoreWin = 6; ScoreTie = 5; ScoreLose = 4;
    ScoreMax = 9; ScoreMin = 2; ScoreInvalid = 0;
    PieceBlank = 0; PieceX = 1; PieceO = 2;

  TYPE
    BoardType = ARRAY 9 OF INTEGER;

  VAR
    evaluated: LONGINT;
    board: BoardType;
    r: LIO.Rider;
    res: INTEGER;

  PROCEDURE Proc0(): INTEGER;
    VAR x: INTEGER;
  BEGIN
    x := board[0];
    IF x # PieceBlank THEN
      IF (x = board[1]) & (x = board[2]) THEN RETURN x END;
      IF (x = board[3]) & (x = board[6]) THEN RETURN x END;
      IF (x = board[4]) & (x = board[8]) THEN RETURN x END
    END;
    RETURN PieceBlank
  END Proc0;

  PROCEDURE Proc1(): INTEGER;
    VAR x: INTEGER;
  BEGIN
    x := board[1];
    IF x # PieceBlank THEN
      IF (x = board[0]) & (x = board[2]) THEN RETURN x END;
      IF (x = board[4]) & (x = board[7]) THEN RETURN x END
    END;
    RETURN PieceBlank
  END Proc1;

  PROCEDURE Proc2(): INTEGER;
    VAR x: INTEGER;
  BEGIN
    x := board[2];
    IF x # PieceBlank THEN
      IF (x = board[0]) & (x = board[1]) THEN RETURN x END;
      IF (x = board[5]) & (x = board[8]) THEN RETURN x END;
      IF (x = board[4]) & (x = board[6]) THEN RETURN x END
    END;
    RETURN PieceBlank
  END Proc2;

  PROCEDURE Proc3(): INTEGER;
    VAR x: INTEGER;
  BEGIN
    x := board[3];
    IF x # PieceBlank THEN
      IF (x = board[4]) & (x = board[5]) THEN RETURN x END;
      IF (x = board[0]) & (x = board[6]) THEN RETURN x END
    END;
    RETURN PieceBlank
  END Proc3;

  PROCEDURE Proc4(): INTEGER;
    VAR x: INTEGER;
  BEGIN
    x := board[4];
    IF x # PieceBlank THEN
      IF (x = board[0]) & (x = board[8]) THEN RETURN x END;
      IF (x = board[2]) & (x = board[6]) THEN RETURN x END;
      IF (x = board[1]) & (x = board[7]) THEN RETURN x END;
      IF (x = board[3]) & (x = board[5]) THEN RETURN x END
    END;
    RETURN PieceBlank
  END Proc4;

  PROCEDURE Proc5(): INTEGER;
    VAR x: INTEGER;
  BEGIN
    x := board[5];
    IF x # PieceBlank THEN
      IF (x = board[3]) & (x = board[4]) THEN RETURN x END;
      IF (x = board[2]) & (x = board[8]) THEN RETURN x END
    END;
    RETURN PieceBlank
  END Proc5;

  PROCEDURE Proc6(): INTEGER;
    VAR x: INTEGER;
  BEGIN
    x := board[6];
    IF x # PieceBlank THEN
      IF (x = board[7]) & (x = board[8]) THEN RETURN x END;
      IF (x = board[0]) & (x = board[3]) THEN RETURN x END;
      IF (x = board[4]) & (x = board[2]) THEN RETURN x END
    END;
    RETURN PieceBlank
  END Proc6;

  PROCEDURE Proc7(): INTEGER;
    VAR x: INTEGER;
  BEGIN
    x := board[7];
    IF x # PieceBlank THEN
      IF (x = board[6]) & (x = board[8]) THEN RETURN x END;
      IF (x = board[1]) & (x = board[4]) THEN RETURN x END
    END;
    RETURN PieceBlank
  END Proc7;

  PROCEDURE Proc8(): INTEGER;
    VAR x: INTEGER;
  BEGIN
    x := board[8];
    IF x # PieceBlank THEN
      IF (x = board[6]) & (x = board[7]) THEN RETURN x END;
      IF (x = board[2]) & (x = board[5]) THEN RETURN x END;
      IF (x = board[0]) & (x = board[4]) THEN RETURN x END
    END;
    RETURN PieceBlank
  END Proc8;

  PROCEDURE Winner(move: INTEGER): INTEGER;
  BEGIN
    CASE move OF
    | 0: RETURN Proc0()
    | 1: RETURN Proc1()
    | 2: RETURN Proc2()
    | 3: RETURN Proc3()
    | 4: RETURN Proc4()
    | 5: RETURN Proc5()
    | 6: RETURN Proc6()
    | 7: RETURN Proc7()
    | 8: RETURN Proc8()
    ELSE
      RETURN PieceBlank
    END
  END Winner;

  PROCEDURE MinMax(alpha, beta, move, depth: INTEGER): INTEGER;
    VAR p, value, pieceMove, score: INTEGER;
  BEGIN
    evaluated := evaluated + 1;
    IF depth >= 4 THEN
      p := Winner(move);
      IF p # PieceBlank THEN
        IF p = PieceX THEN RETURN ScoreWin ELSE RETURN ScoreLose END
      ELSIF depth = 8 THEN
        RETURN ScoreTie
      END
    END;

    IF ODD(depth) THEN
      value := ScoreMin; pieceMove := PieceX
    ELSE
      value := ScoreMax; pieceMove := PieceO
    END;

    p := 0;
    REPEAT
      IF board[p] = PieceBlank THEN
        board[p] := pieceMove;
        score := MinMax(alpha, beta, p, depth + 1);
        board[p] := PieceBlank;
        IF ODD(depth) THEN
          IF score = ScoreWin THEN RETURN ScoreWin END;
          IF score > value THEN
            value := score;
            IF value >= beta THEN RETURN value END;
            IF value > alpha THEN alpha := value END
          END
        ELSE
          IF score = ScoreLose THEN RETURN ScoreLose END;
          IF score < value THEN
            value := score;
            IF value <= alpha THEN RETURN value END;
            IF value < beta THEN beta := value END
          END
        END
      END;
      INC(p)
    UNTIL p > 8;
    RETURN value
  END MinMax;

PROCEDURE RunIt(move: INTEGER);
  VAR score, i: INTEGER;
BEGIN
  i := 0;
  WHILE i <= 8 DO
    board[i] := PieceBlank;
    INC(i)
  END;

  board[move] := PieceX;
  score := MinMax(ScoreMin, ScoreMax, move, 0);
END RunIt;

BEGIN
  LIO.OpenWrite("CON", r, res);
  IF res = 0 THEN

    evaluated := 0;

    RunIt(0);
    RunIt(1);
    RunIt(4);

    LIO.Write(r, "Total evaluated: ");
    LIO.WriteInt(r, evaluated);
    LIO.WriteLn(r);

    LIO.Close(r)
  END
END TTT.