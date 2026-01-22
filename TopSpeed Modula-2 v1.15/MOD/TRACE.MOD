MODULE trace;

IMPORT IO,Graph,Lib,MATHLIB;


TYPE t_fenetre = RECORD      (* 1,2 = X; 3,4 = Y *)
                  W1,W2,W3,W4 : REAL;           (* monde r‚el *)
                  V1,V2,V3,V4 : CARDINAL;       (* monde graphique *)
                  temp1,temp2,
                  temp3,temp4 : REAL;
                 END;

PROCEDURE window ( VAR  a       : t_fenetre;
                   i,j,k,l      : REAL);

 BEGIN
  WITH a DO
   W1 := i;
   W2 := j;
   W3 := k;
   W4 := l;
  END;
 END window;

PROCEDURE viewport ( VAR  a     : t_fenetre;
                     x1,x2,y1,y2: CARDINAL);

 (* d‚pend de la r‚solution de l'‚cran *)

 BEGIN
  WITH a DO
   IF x1 < 0 THEN V1 := 0 ELSE V1 := x1  END;
   IF y1 < 0 THEN V3 := 0 ELSE V3 := y1  END;
   IF x2 > 640 THEN V2 := 640 ELSE V2 := x2 END;
   IF y2 > 480 THEN V4 := 480 ELSE V4 := y2 END;
   temp1 := (VAL(REAL,V2)-VAL(REAL,V1))/(W2-W1);
   temp2 := ((VAL(REAL,V1)*W2)-(VAL(REAL,V2)*W1))/(W2-W1);
   temp3 := (VAL(REAL,V4)-VAL(REAL,V3))/(W4-W3);
   temp4 := ((VAL(REAL,V3)*W4)-(VAL(REAL,V4)*W3))/(W4-W3);
   Graph.SetClipRgn(V1,V3,V2,V4);
  END;
 END viewport;

PROCEDURE ROUND( x : REAL): CARDINAL;

 BEGIN
  RETURN(ABS(TRUNC(x+0.5)))
 END ROUND;

PROCEDURE fx( VAR a : t_fenetre;
                  b : REAL     ):CARDINAL;

 BEGIN
  WITH a DO
   RETURN  ROUND(temp1 * b + temp2);
  END;
 END fx;

PROCEDURE fy( VAR a : t_fenetre;
                  b : REAL   ): CARDINAL;

 BEGIN
  WITH a DO
   RETURN ROUND(temp3 * b + temp4)
  END;
 END fy;

 PROCEDURE cadrage ( VAR a : t_fenetre);

  BEGIN
   WITH a DO
 (*   Graph.Rectangle(V1,V3,V2,V4,5,TRUE );*)
   END;
  END cadrage;



PROCEDURE axis ( VAR a   : t_fenetre);

 VAR p,q : REAL;

 BEGIN
  WITH a DO
   p := W1;
   q := W3;
   IF (W1 < 0.0) AND (W2 > 0.0) THEN p := 0.0 END;
   IF (W3 < 0.0) AND (W4 > 0.0) THEN q := 0.0 END;
   Graph.HLine(fx(a,W1),fy(a,q),fx(a,W2),15);
   Graph.Line( fx(a,p), fy(a,W3),fx(a,p),fy(a,W4),15);
  END;
 END axis;

VAR t : t_fenetre;
    i : BOOLEAN;
    video : Graph.VideoConfig;

PROCEDURE fonction (x : REAL) : REAL;

 BEGIN
  RETURN VAL(REAL,MATHLIB.Sin(2.0*VAL(LONGREAL,x)) * MATHLIB.Exp(-0.1*VAL(LONGREAL,x)))
 END fonction;

VAR f : INTEGER;
    g : REAL;

BEGIN
 Graph.GetVideoConfig(video);
(* i := Graph.SetVideoMode(video.mode);*)
 Graph.InitVGA;
 Graph.GraphMode;
 window(t,-10.0,+20.0,-1.6,+1.7);
 cadrage(t);
 viewport(t,100,400,100,400);
 axis(t);
 FOR f := -200 TO 900-1 DO
  g := VAL(REAL,f)/10.0;
  Graph.Line(fx(t,g),fy(t,fonction(g)),fx(t,g+0.1),fy(t,fonction(g+0.1)),15);
 END;
 REPEAT UNTIL IO.KeyPressed();
 i := Graph.SetVideoMode(Graph._TEXTC80);
END trace.
