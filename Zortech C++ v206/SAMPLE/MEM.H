/*_ mem.h   Fri May 26 1989   Modified by: Walter Bright */
/* $Header: /proj/products/merlin/port/RCS/mem.h,v 1.9 89/06/19 15:15:08 bright Exp $ */
/* Copyright 1986-1988 by Northwest Software	*/
/* All Rights Reserved				*/
/* Written by Walter Bright			*/

#ifndef MEM_H
#define MEM_H	1

#ifndef TOOLKIT_H
#include	"toolkit.h"
#endif

/*
 * Memory management routines.
 *
 * Compiling:
 *
 *	#define MEM_DEBUG 1 when compiling to enable extended debugging
 *	features.
 *
 * Features always enabled:
 *
 *	o mem_init() is called at startup, and mem_term() at
 *	  close, which checks to see that the number of alloc's is
 *	  the same as the number of free's.
 *	o Behavior on out-of-memory conditions can be controlled
 *	  via mem_setexception().
 *
 * Extended debugging features:
 *
 *	o Enabled by #define MEM_DEBUG 1 when compiling.
 *	o Check values are inserted before and after the alloc'ed data
 *	  to detect pointer underruns and overruns.
 *	o Free'd pointers are checked against alloc'ed pointers.
 *	o Free'd storage is cleared to smoke out references to free'd data.
 *	o Realloc'd pointers are always changed, and the previous storage
 *	  is cleared, to detect erroneous dependencies on the previous
 *	  pointer.
 *	o The routine mem_checkptr() is provided to check an alloc'ed
 *	  pointer.
 */

/********************* GLOBAL VARIABLES *************************/

extern int mem_inited;		/* != 0 if mem package is initialized.	*/
				/* Test this if you have other packages	*/
				/* that depend on mem being initialized	*/

/********************* PUBLIC FUNCTIONS *************************/

/***********************************
 * Set behavior when mem runs out of memory.
 * Input:
 *	flag =	MEM_ABORTMSG:	Abort the program with the message
 *				'Fatal error: out of memory' sent
 *				to stdout. This is the default behavior.
 *		MEM_ABORT:	Abort the program with no message.
 *		MEM_RETNULL:	Return NULL back to caller.
 *		MEM_CALLFP:	Call application-specified function.
 *				fp must be supplied.
 *	fp			Optional function pointer. Supplied if
 *				(flag == MEM_CALLFP). This function returns
 *				MEM_XXXXX, indicating what mem should do next.
 *				The function could do things like swap
 *				data out to disk to free up more memory.
 *	fp could also return:
 *		MEM_RETRY:	Try again to allocate the space. Be
 *				careful not to go into an infinite loop.
 */

#if __ZTC__
enum MEM_E { MEM_ABORTMSG, MEM_ABORT, MEM_RETNULL, MEM_CALLFP, MEM_RETRY };
void mem_setexception(_2(enum MEM_E,...));
#else
#define MEM_ABORTMSG	0
#define MEM_ABORT	1
#define MEM_RETNULL	2
#define MEM_CALLFP	3
#define MEM_RETRY	4
void mem_setexception(_2(int,...));
#endif


/****************************
 * Allocate space for string, copy string into it, and
 * return pointer to the new string.
 * This routine doesn't really belong here, but it is used so often
 * that I gave up and put it here.
 * Use:
 *	char *mem_strdup(const char *s);
 * Returns:
 *	pointer to copied string if succussful.
 *	else returns NULL (if MEM_RETNULL)
 */

char *mem_strdup(_1(const char *));

/**************************
 * Function so we can have a pointer to function mem_free().
 * This is needed since mem_free is sometimes defined as a macro,
 * and then the preprocessor screws up.
 * The pointer to mem_free() is used frequently with the list package.
 * Use:
 *	void mem_freefp(void *p);
 */

/***************************
 * Check for errors. This routine does a consistency check on the
 * storage allocator, looking for corrupted data. It should be called
 * when the application has CPU cycles to burn.
 * Use:
 *	void mem_check(void);
 */

void mem_check(_0);

/***************************
 * Check ptr to see if it is in the range of allocated data.
 * Cause assertion failure if it isn't.
 * Use:
 *	void mem_checkptr(void *ptr);
 */

void mem_checkptr(_1(void *));

/***************************
 * Allocate and return a pointer to numbytes of storage.
 * Use:
 *	void *mem_malloc(unsigned numbytes);
 *	void *mem_calloc(unsigned numbytes); allocated memory is cleared
 * Input:
 *	numbytes	Number of bytes to allocate
 * Returns:
 *	if (numbytes > 0)
 *		pointer to allocated data, NULL if out of memory
 *	else
 *		return NULL
 */

void *mem_malloc(_1(unsigned)),*mem_calloc(_1(unsigned));

/*****************************
 * Reallocate memory.
 * Use:
 *	void *mem_realloc(void *ptr,unsigned numbytes);
 */

void *mem_realloc(_2(void *,unsigned));

/*****************************
 * Free memory allocated by mem_malloc(), mem_calloc() or mem_realloc().
 * Use:
 *	void mem_free(void *ptr);
 */

void mem_free(_1(void *));

/***************************
 * Initialize memory handler.
 * Use:
 *	void mem_init(void);
 * Output:
 *	mem_inited = 1
 */

void mem_init(_0);

/***************************
 * Terminate memory handler. Useful for checking for errors.
 * Use:
 *	void mem_term(void);
 * Output:
 *	mem_inited = 0
 */

void mem_term(_0);

/* The following stuff forms the implementation rather than the
 * definition, so ignore it.
 */

#if MEM_DEBUG		/* if creating debug version	*/
#define mem_strdup(p)	mem_strdup_debug((p),__FILE__,__LINE__)
#define mem_malloc(u)	mem_malloc_debug((u),__FILE__,__LINE__)
#define mem_calloc(u)	mem_calloc_debug((u),__FILE__,__LINE__)
#define mem_realloc(p,u)	mem_realloc_debug((p),(u),__FILE__,__LINE__)
#define mem_free(p)	mem_free_debug((p),__FILE__,__LINE__)

#if PROTOTYPING
extern char *mem_strdup_debug(const char *,char *,int);
extern void *mem_calloc_debug(unsigned,char *,int),
	*mem_malloc_debug(unsigned,char *,int),
	*mem_realloc_debug(void *,unsigned,char *,int);
extern void mem_free_debug(void *,char *,int),mem_freefp(void *);
#else
extern char *mem_strdup_debug();
extern void *mem_calloc_debug(),*mem_malloc_debug(),*mem_realloc_debug();
extern void mem_free_debug(),mem_freefp();
#endif

void mem_setnewfileline(_3(void *,char *,int));

#else

#define mem_freefp	mem_free
#define mem_check()
#define mem_checkptr(p)

#endif /* MEM_DEBUG */

#endif /* MEM_H */
