/*
 * DDS MICRO-C Command Coordinator
 *
 * This program integrates the various commands required to compile a
 * program into a single command.
 *
 * The following assemblers and linkers have been reported to work with
 * MICRO-C, using the indicated command line options:
 *
 * Vendor		Name	Versions(s)			Options
 * ------------------------------------------------
 * Arrowsoft	ASM	     1.00d (PD)			/ml
 * Arrowsoft	ASM      2.00c (PD)			/s/ml
 * Microsoft	MASM     3.0				/ml
 * Microsoft	MASM     4.0, 5.1			/t/ml
 * Borland		TASM     1.0, 2.01, 3.0		/t/ml
 * Watcom		WASM     1.0				/q
 * Japleth      JWASM    2.07a				-q -Cp -Zm
 * Isaacson     A86      4.04				+c +O +S +E +G24 [+L]	*1
 * Isaacson     A386     4.04				+c +O +S +E +G24 [+L]	*1
 * Troendle		VAL      None (PD)			/nci [/COM]				*2
 * Microsoft	LINK     3.x, 5.x			/noi
 * Borland		TLINK    2.0, 3.01, 4.01	/c [/t]
 * Watcom		WLINK    10.0				form DOS [COM]
 * Hyperkinetix	FREELINK 2.50 (freeware)	[/c]					*3
 *
 *1 A[3]86 < v4.04 does not work correctly with Micro-C.
 *2	Original VAL does not work in TINY model. Fix available from DDS.
 *3 FREELINK has no case-sensitive option. See FIXLINK.C in examples.
 *
 * If your assembler and linker are not compatible with the command lines
 * hard coded in this program, do the following:
 *
 * - Modify CC.C, LC.BAT and PC86.IDE to use acceptable commands
 * - Compile CC.C using DDSIDE
 *         - or -
 * - Compile CC.C by running MCP, MCC, Assembler and LC commands:
 *       MCP CC.C CC.C1 l=.
 *       MCC CC.C1 CC.ASM
 *       Assemble with your assembler to get CC.OBJ
 *       LC CC
 * - Test CC.COM by re-compiling itself: CC CC -fop
 *
 * Where possible, the assembler and linker should be run with appropriate
 * options to cause them to be CASE SENSITIVE, and QUIET in operation (no
 * output messages). If either your assembler OR linker does not support
 * case sensitive operation, run BOTH of them in case insensitive mode,
 * and be sure not to use any global symbols which differ only in case.
 *
 * Copyright 1990-2020 Dave Dunfield
 * All rights reserved.
 *
 * Compile command: cc cc -fop
 */
#include <stdio.h>

#define	NOFILE	2		// EXEC return code for file not found
#define	NOPATH	3		// EXEC return code for path not found
#define	SYMS	4		// #symbols

unsigned
	Stop;
unsigned char
	*Ptr,
	*Fnptr,
	*SymDef[SYMS],
	Opt,
	Step,
	SStep,
	Mcdir[65],
	Temp[65],
	Ifile[65],
	Ofile[65],
	Tail[150],
	Mcparm[80];

int Model=0;
unsigned char *Models[] = { "TINY", "SMALL" };

unsigned char Htext[] = { "\n\
Use: CC <name> [-cdklsqw --fpcoalv h= m= t=] [symbol=value]\n\n\
opts:	(can be strung together, only Capital letter should be used)\n\
	-Comment	-Dupwarn	-Keeptemp	-Listing\n\
	-Symbolic	-Quiet		-shoW\n\n\
	--don'tFoldliteral			--don'tPreprocess\n\
	--don'tCompile/optimize/asm/link	--don'tOptimize\n\
	--don'tAsm				--don'tLink\n\
	--don'tExe2bin	(Tiny model only)\n\n\
	H=homepath		M=TS(model)		T=temprefix\n\n\
Copyright 1990-2020 Dave Dunfield\nAll rights reserved.\n" };

#define	O_SYMB		0x01
#define	O_CMNT		0x02
#define	O_DWARN		0x04
#define	O_KEEP		0x10
#define	O_LIST		0x20
#define	O_QUIET		0x40
#define	O_SHOW		0x80

#define	S_PREPROC	0x01
#define	S_COMPILE	0x02
#define	S_OPTIMIZE	0x04
#define	S_ASM		0x08
#define	S_LINK		0x10
#define	S_CVT		0x20
#define	S_FOLD		0x80
#define	S_ALL		0xBF

int option(void)
{
	unsigned c;
a1:	switch(c = toupper(*Ptr++)) {
	case 0	:	return 0;
	case 'S':	c = O_SYMB;		goto o1;
	case 'C':	c = O_CMNT;		goto o1;
	case 'D':	c = O_DWARN;	goto o1;
	case 'K':	c = O_KEEP;		goto o1;
	case 'L':	c = O_LIST;		goto o1;
	case 'Q':	c = O_QUIET;	goto o1;
	case 'W':	c = O_SHOW|O_QUIET;
o1:		Opt |= c;
		goto a1; }
	switch((c << 8) | toupper(*Ptr++)) {
	default	:	return 255;
	case'-F':	c = S_FOLD;								goto s1;
	case'-P':	c = S_PREPROC;							goto s1;
	case'-C':	c = S_COMPILE|S_OPTIMIZE|S_ASM|S_LINK;	goto s1;
	case'-O':	c = S_OPTIMIZE;							goto s1;
	case'-A':	c = S_ASM|S_LINK;						goto s1;
	case'-L':	c = S_LINK;								goto s1;
	case'-E':	c = S_CVT;
s1:		SStep |= c;
		goto a1; }
}

/*
 * Main program, process options & invoke appropriate commands
 */
main(int argc, char *argv[])
{
	int i, j;
	char c;

	/* Get default directories from environment */
	if(!getenv("MCDIR", Mcdir)) {	/* Get MICRO-C directory */
		message("Environment variable MCDIR is not set!\n\n");
		strcpy(Mcdir, "C:\\MC"); }
	if(!getenv("MCTMP", Temp)) {	/* Get temporary directory */
		if(getenv("TEMP", Temp)) {
			if(Temp[(i = strlen(Temp))-1] != '\\') {
				Temp[i] = '\\';
				Temp[i+1] = 0; } } }

	for(i=1; i < argc; ++i) {
		switch(j = toupper(*(Ptr = argv[i]))) {
		case '?':	goto he;
		case '/':
		case '-':	++Ptr;
			if(option()) {
badopt:			printf("Bad option: %s\n", argv[i]);
he:				abort(Htext); }
			continue; }
		switch((j << 8) | toupper(Ptr[1])) {
		case 'H=':	strcpy(Mcdir, Ptr+2);		continue;
		case 'T=':	strcpy(Temp, Ptr+2);		continue;
		case 'M=':
			c = toupper(*(Ptr+2));
			for(Model=0; *Models[Model] != c; ++Model) {
				if(Model >= (sizeof(Models)/2))
					goto badopt; }
			continue; }

		j = 0;
a1:		switch(Ptr[j++]) {
		default:	goto a1;
		case '=':
			if(Stop >= SYMS)
				abort("Too many '=' symbols");
			SymDef[Stop++] = Ptr;
			continue;
		case 0	: ; }

		if(*Ifile)
			goto badopt;
		strcpy(Ifile, Fnptr = Ptr);
		j = 0;
a2:		c = 0;
a3:		switch(Ifile[j++]) {
		case ':':
		case'\\':	Fnptr = Ptr+j;	goto a2;
		case '.':	c = 255;
		default	:					goto a3;
		case 0	:	if(!c) strcpy(Ifile+j-1, ".C"); } }

	Step = (~SStep) & S_ALL;
	message("DDS MICRO-C PC86 Compiler v3.23\n");

	if(!*Ifile)
		abort(Htext);

	message(Fnptr);
	message(": ");
	j = 0;
a4:	switch(Fnptr[j]) {
	default	:	++j;	goto a4;
	case '.':	Fnptr[j] = 0;
	case 0	: 	; }

	/* Pre-process to source file */
	if(Step & S_PREPROC) {
		message("Preprocess... ");
		sprintf(Ofile,"%s%s.CP", Temp, Fnptr);
		sprintf(Tail,"%s %s l=%s -q -l%s%s", Ifile, Ofile, Mcdir,
			(Opt & O_DWARN) ? " -d" : "", Mcparm);
		j = 0;
		for(i=0; i <  Stop; ++i) {
			while(Tail[j]) ++j;
			Tail[j++] = ' ';
			strcpy(Tail+j, SymDef[i]); }
		docmd("MCP.EXE");
		strcpy(Ifile, Ofile); }

	/* Compile to assembly language */
	message("Compile... ");
	sprintf(Ofile,"%s%s.%s", (Step & (S_OPTIMIZE|S_ASM)) ? Temp : "", Fnptr,
		(Step & S_OPTIMIZE) ? "CO" : "ASM");
	sprintf(Tail,"%s %s -q%s%s%s%s", Ifile, Ofile,
		(Step & S_PREPROC) ? " -l" : "", (Opt & O_CMNT) ? " -c" : "",
			(Step & S_FOLD) ? " -f" : "", (Opt & O_SYMB) ? " -s" : "");
	docmd("MCC.EXE");
	if(Step & S_PREPROC)
		erase(Ifile);
	strcpy(Ifile, Ofile);

	/* Optimize the assembly language */
	if(Step & S_OPTIMIZE) {
		message("Optimize... ");
		sprintf(Ofile,"%s%s.ASM", (Step & S_ASM) ? Temp : "", Fnptr);
		sprintf(Tail, "%s %s -q", Ifile, Ofile);
		docmd("MCO.COM");
		erase(Ifile);
		strcpy(Ifile, Ofile); }


	/* Assemble into object module */
	if(Step & S_ASM) {
		sprintf(Ofile,"%s%s.OBJ", (Step & S_LINK) ? Temp : "", Fnptr);
		sprintf(Mcparm, (Opt & O_LIST) ? ",%s.LST" : "", Fnptr);
		message("Assemble... ");
		sprintf(Tail,"/t/ml %s,%s%s;", Ifile, Ofile, Mcparm);
		docmd("MASM.EXE");
		erase(Ifile);
		strcpy(Ifile, Ofile);

	/* Link into executable program */
		if(Step & S_LINK) {
			sprintf(Tail, "Link %s...\n", Models[Model]);
			message(Tail);
			sprintf(Mcparm, (Opt & O_LIST) ? "%s.MAP" : "NUL", Fnptr);
			sprintf(Ofile,"%s.EXE", Fnptr);
			sprintf(Tail,"/noi %s\\PC86RL_%c %s,%s,%s,%s\\MCLIB;",
				Mcdir, *Models[Model], Ifile, Ofile, Mcparm, Mcdir);
			docmd("LINK.EXE");
			erase(Ifile);
			if((Step & S_CVT) && !Model) {
				message("Convert... ");
				sprintf(Tail,"%s %s.COM", Ofile, Fnptr);
				docmd("EXE2BIN.COM");
				erase(Ofile); }
			} }

	message("All done.\n");
}

/*
 * Execute a command, looking for it in the MICRO-C directory,
 * and also in any directories found in the PATH environment
 * variable. Operands to the command have been previously
 * defined in the global variable 'Tail'.
 */
docmd(char *cmd)
{
	int rc;
	char command[65], *ptr, *ptr1, c;
	static char path[2000];

	if(Opt & O_SHOW) {
		fputs(cmd, stdout);
		putc(' ', stdout);
		fputs(Tail, stdout);
		putc('\n', stdout);
		return; }

	ptr = Mcdir;						/* First try MC home dir */
	if(!getenv("PATH", ptr1 = path))	/* And then search  PATH */
		ptr1 = "";
	do {	/* Search MCDIR & PATH for commands */
		sprintf(command,"%s%s%s", ptr, "\\"+(ptr[strlen(ptr)-1] == '\\'), cmd);
		rc = exec(command, Tail);
		ptr = ptr1;						/* Point to next directory */
		while(c = *ptr1) {				/* Advance to end of entry */
			++ptr1;
			if(c == ';') {
				*(ptr1 - 1) = 0;		/* Zero terminate */
				break; } } }
	while(((rc == NOFILE) || (rc == NOPATH)) && *ptr);
	if(rc) {
		fprintf(stderr,"%s failed (%d)\n", cmd, rc);
		exit(-1); }
}

/*
 * Output an informational message (verbose mode only)
 */
message(char *ptr)
{
	if(!(Opt & O_QUIET))
		fputs(ptr, stderr);
}

/*
 * Erase temporary file (if enabled)
 */
erase(char *file)
{
	if(!(Opt & O_KEEP))
		delete(file);
}
