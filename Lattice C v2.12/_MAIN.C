#include "dos.h"
#include "stdio.h"
#include "ctype.h"
#include "ios1.h"

#define MAXARG 32              /* maximum command line arguments */

extern int _stack,_fmode,_iomode;
extern char _iname[],_oname[],_dos;
extern struct UFB _ufbs[];

int argc;			/* arg count */
char *argv[MAXARG];		/* arg pointers */


/**
*
* name         _main - process command line, open files, and call "main"
*
* synopsis     _main(line);
*              char *line;     ptr to command line that caused execution
*
* description	This function performs the standard pre-processing for
*		the main module of a C program.  It accepts a command
*		line of the form
*
*			pgmname arg1 arg2 ...
*
*		and builds a list of pointers to each argument.  The first
*		pointer is to the program name.  For some environments, the
*		standard I/O files are also opened, using file names that
*		were set up by the OS interface module XCMAIN.
*
**/
_main(line)
char *line;
{
char c;
int x;
#if UNIX == 0
FILE *fp0, *fp1, *fp2;
extern int _bufsiz;
char *getmem();
#endif

/*
*
* Build argument pointer list
*
*/
for(argc = 0; argc < MAXARG; )
	{
	while(isspace(*line)) line++;
	if(*line == '\0') break;
	argv[argc++] = line;
	while((*line != '\0') && (isspace(*line) == 0)) line++;
	c = *line;
	*line++ = '\0';
	if(c == '\0') break;
	}
/*
*
* Open standard files
*
*/
#if UNIX == 0
if(_dos < 2)
	{
	fp0 = freopen(_iname,"r",stdin);
	if(_oname[0] != '>') fp1 = freopen(_oname,"w",stdout);
	else fp1 = freopen(&_oname[1],"a",stdout);
	fp2 = freopen("","a",stderr);
	if (fp2 == NULL) _exit(1);
	if (fp0 == NULL)
	   {
	   fputs("Can't open stdin file\n", fp2);
	   exit(1);
	   }
	setbuf(fp0, getmem(_bufsiz));	/* set stdin buffered */
	fp0->_flag &= ~_IOMYBUF;	/* allow rlsmem if later set unbuff'd */
	if (fp1 == NULL)
	   {
	   fputs("Can't open stdout file\n", fp2);
	   exit(1);
	   }
	}
else
	{
	stdin->_file = 0;
	stdin->_flag = _IOREAD;
	stdout->_file = 1;
	stdout->_flag = _IOWRT;
	stderr->_file = 2;
	stderr->_flag = _IOWRT | _IONBF;
	
	x = ((_fmode ^ _iomode) & 0x8000) ? UFB_NT : 0;
	_ufbs[0].ufbflg = UFB_OP | UFB_RA | x;
	_ufbs[1].ufbfh = 1;
	_ufbs[1].ufbflg = UFB_OP | UFB_WA | x;
	_ufbs[2].ufbfh = 2;
	_ufbs[2].ufbflg = UFB_OP | UFB_WA | x;
	if (_fgdi(1) & 0x80) stdout->_flag |= _IONBF;
	}
#endif


/*
*
* Call user's main program
*
*/
main(argc,argv);              /* call main function */
exit(0);
}
