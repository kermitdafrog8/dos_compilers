/* Copyright (C) 1982, 1984 by Manx Software Systems */
#define fgetc getc
#define fputc putc
#define NULL (void *)0
#define EOF -1


#define BUFSIZ 1024
#define MAXSTREAM	20

#define _BUSY	0x01
#define _ALLBUF	0x02
#define _DIRTY	0x04
#define _EOF	0x08
#define _IOERR	0x10
#define _TEMP	0x20	/* temporary file (delete on close) */

typedef struct {
	char *_bp;			/* current position in buffer */
	char *_bend;		/* last character in buffer + 1 */
	char *_buff;		/* address of buffer */
	char _flags;		/* open mode, etc. */
	char _unit;			/* token returned by open */
	char _bytbuf;		/* single byte buffer for unbuffer streams */
	int	_buflen;		/* length of buffer */
	char *_tmpname;		/* name of file for temporaries */
} FILE;

extern FILE Cbuffs[];
FILE *fopen(), *freopen();
FILE *fdopen();
long ftell();

#define stdin (&Cbuffs[0])
#define stdout (&Cbuffs[1])
#define stderr (&Cbuffs[2])
#define getchar() agetc(stdin)
#define putchar(c) aputc(c, stdout)
#define feof(fp) (((fp)->_flags&_EOF)!=0)
#define ferror(fp) (((fp)->_flags&_IOERR)!=0)
#define clearerr(fp) ((fp)->_flags &= ~(_IOERR|_EOF))
#define fileno(fp) ((fp)->_unit)
#define fflush(fp) flsh_(fp,-1)

#define	P_tmpdir	""
#define L_tmpnam	40
