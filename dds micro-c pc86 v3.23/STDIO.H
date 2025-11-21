/*
 * DDS MICRO-C standard I/O definitions for MS-DOS
 *
 * Copyright 1988-2021 Dave Dunfield
 * All rights reserved.
 */
#define	_MICROC_

#define	FILE	unsigned	/* FILE = 16 bit value */
#define	EOF		-1			/* End of file indicator */
#define	NULL	0			/* General NULL indicator */

extern register printf(), fprintf(), sprintf(),
				scanf(), fscanf(), sscanf(),
				concat();
extern char		*fgets();
extern FILE		*fopen(), *stdin, *stdout, stderr[];

// Micro-C being at 16 bit compiler does not know about "short". I chose
// not to implement it when I wrote Micro-C because it would have done
// "nothing" - the native int/unsiged size is 16 bits. Later I came to
// regret not doing so because "short" was critical in code for some other
// compilers when I "wanted" 16 bits. I could have modifier the compiler to
// implement a non-functional "shows" however I decide to simply do this: It
// defined "short" as a blank function using the limited pre-processor built
// into the Micro-C - that way it does'nt use any of MCPs storage space and
// does'nt show to "#ifdef" etc, which makes it "appear" as an actual compiler
// function.
#define	_DeFiNe_	#define
_DeFiNe_ short
#forget _DeFiNe_
