/*_ filespec.h   Fri Jul  8 1988   Modified by: bright */
/* $Header: /proj/products/merlin/port/RCS/filespec.h,v 1.12 89/07/03 13:44:48 bright Exp Locker: bright $ */
/* Copyright (C) 1986-1987 by Northwest Software	*/
/* All Rights Reserved					*/
/* Written by Walter Bright				*/

#ifndef	FILESPEC_H
#define FILESPEC_H	1

#ifndef P
#include	"toolkit.h"
#endif

/*********************************
 * String compare of filenames.
 */

#if MSDOS || __OS2__ || VMS
#define filespeccmp(f1,f2)	strcmpl((f1),(f2))
#endif
#if BSDUNIX || M_UNIX || M_XENIX
#define filespeccmp(f1,f2)	strcmp((f1),(f2))
#endif

/****************************
 * Combine path and filename to form a filespec.
 * Input:
 *	path		Path, with or without trailing /
 *			(can be NULL)
 *	filename	Cannot be NULL
 * Returns:
 *	filespec	mem_malloc'd file specification
 *	NULL		Out of memory
 */

char * pascal filespecaddpath P((char *,char *));

/******************************* filespecrootpath **************************
 * Purpose: To expand a relative path into an absolute path.
 *
 * Side Effects: mem_frees input string.
 *
 * Returns: mem_malloced string with absolute path.
 *	    NULL if some failure.
 */

char * pascal filespecrootpath P((char *));

/*****************************
 * Add extension onto filespec, if one isn't already there.
 * Input:
 *	filespec	Cannot be NULL
 *	ext		Extension (without the .)
 * Returns:
 *	mem_malloc'ed string (NULL if error)
 */

char * pascal filespecdefaultext P((char *,char *));

/**********************
 * Return string that is the dot and extension.
 * The string returned is NOT mem_malloc'ed.
 * Return pointer to the 0 at the end of filespec if dot isn't found.
 * Return NULL if filespec is NULL.
 */

char * pascal filespecdotext P((char *));

/*****************************
 * Force extension onto filespec.
 * Input:
 *	filespec	String that may or may not contain an extension
 *	ext		Extension that doesn't contain a .
 * Returns:
 *	mem_malloc'ed string (NULL if error)
 *	NULL if filespec is NULL
 *	If ext is NULL, return mem_strdup(filespec)
 */

char * pascal filespecforceext P((char *,char *));

/***********************
 * Get root name of file name.
 * That is, return a mem_strdup()'d version of the filename without
 * the .ext.
 */

char * pascal filespecgetroot P((char *));

/**********************
 * Return string that is the filename plus dot and extension.
 * The string returned is NOT mem_malloc'ed.
 */

char * pascal filespecname P((char *));

/************************************
 * If first character of filespec is a ~, perform tilde-expansion.
 * Output:
 *	Input filespec is mem_free'd.
 * Returns:
 *	mem_malloc'd string
 */

#if MSDOS || __OS2__
#define filespectilde(f)	(f)
#else
char * pascal filespectilde P((char *));
#endif

/************************************
 * Expand all ~ in the given string.
 *
 * Output:
 *	Input filespec is mem_free'd.
 * Returns:
 *	mem_malloc'd string
 */

#if MSDOS || __OS2__
#define filespecmultitilde(f)	(f)
#else
char * pascal filespecmultitilde P((char *));
#endif

/*****************************
 * Convert filespec into a backup filename appropriate for the
 * operating system. For instance, under MS-DOS path\filename.ext will
 * be converted to path\filename.bak.
 * Input:
 *	filespec	String that may or may not contain an extension
 * Returns:
 *	mem_malloc'ed string (NULL if error)
 *	NULL if filespec is NULL
 */

char * pascal filespecbackup P((char *));

#endif /* FILESPEC_H */
