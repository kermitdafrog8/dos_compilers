'BEGIN' 'INTEGER' IN,OUT,C;

'COMMENT' THIS PROGRAM CONVERTS FROM
THE UPPER/LOWER CASE CONVENTION TO
THE UPPER CASE IN QUOTES CONVENTION;

'PROCEDURE' SETO(A);
'VALUE' A; 'INTEGER' A; IOC(31);

'INTEGER' 'PROCEDURE' SWLIST;
IOC(39);

'PROCEDURE' GETC;
'BEGIN' C:=CHIN(IN);
	'IF' C<0 'OR' C=&^Z 'THEN' 'GOTO' FIN
'END' ;


'PROCEDURE' UOUT;
'IF' C>=97 'AND' C<=122 'THEN' CHOUT(OUT,C-32)
'ELSE' CHOUT(OUT,C);


	SETO(SWLIST+13);
	TEXT(10,"ALG");	{DEFAULT EXTENSION}
A1:	IOC(2); IN:=INPUT;
	'IF' IN<1 'THEN' 'GOTO' A1;
	OUT:=OUTPUT;
	'IF' OUT<1 'THEN' 
	'BEGIN' CLOSE(IN); 'GOTO' A1;
	'END' ;

LOOP:	GETC;
	'IF' C=&" 'THEN' 
	'BEGIN' UOUT;
A2:		GETC; UOUT;
		'IF' C=&** 'THEN' 
		'BEGIN' GETC; UOUT;
		'END' 'ELSE' 
		'IF' C=&" 'THEN' 'GOTO' LOOP;
		'GOTO' A2;
	'END' 'ELSE' 
	'IF' C=&*C 'THEN' 
	'BEGIN' UOUT; 'GOTO' LOOP 'END' 'ELSE' 
	'IF' C=&& 'THEN' 
	'BEGIN' UOUT; GETC; UOUT;
		'IF' C=&** 'OR' C=&*^ 'THEN' 
		'BEGIN' GETC; UOUT
		'END' ;
		'GOTO' LOOP;
	'END' 'ELSE' 
	'IF' C>=&A 'AND' C<=&Z 'THEN' 
	'BEGIN' CHOUT(OUT,&'); UOUT;
A3:		GETC;
		'IF' C>=&A 'AND' C<=&Z 'THEN' 
		'BEGIN' UOUT; 'GOTO' A3
		'END' ;
		CHOUT(OUT,&'); UOUT;
		'GOTO' LOOP;
	'END' 'ELSE' UOUT;
	'GOTO' LOOP;

FIN:	CHOUT(OUT,&^Z); CLOSE(OUT);
	CLOSE(IN); 'GOTO' A1
'END'
'FINISH'

