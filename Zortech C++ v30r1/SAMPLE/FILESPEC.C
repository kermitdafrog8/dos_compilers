/*_ filespec.c   Mon Jul  3 1989   Modified by: Walter Bright */
/* $Header: /proj/products/merlin/port/RCS/filespec.c,v 1.22 90/04/30 15:20:36 dietz Exp Locker: bright $ */
/* Copyright (C) 1986-1987 by Northwest Software	*/
/* All Rights Reserved					*/
/* Written by Walter Bright				*/

/* Package with which to manipulate filespecs	*/

#ifndef STDIO_H
#include <stdio.h>
#endif

#ifndef FILESPEC_H
#include	"filespec.h"
#endif
#ifndef MEM_H
#include	"mem.h"
#endif

#ifndef VAX11C
#include <string.h>
#endif

#if BSDUNIX
#include	<pwd.h>
#endif

#if MSDOS || __OS2__ || M_UNIX || M_XENIX
#include	<direct.h>
#include	<ctype.h>
#if M_UNIX || M_XENIX
#include	<stdlib.h>
#endif
#endif

#ifndef assert
#include	<assert.h>
#endif

/* Macro to determine if char is a path or drive delimiter	*/
#if MSDOS || __OS2__
#define ispathdelim(c)	((c) == '\\' || (c) == ':' || (c) == '/')
#else
#ifdef VMS
#define ispathdelim(c)  ((c)==':' || (c)=='[' || (c)==']' )
#else
#ifdef MPW
#define ispathdelim(c)	((c) == ':')
#else
#define ispathdelim(c)	((c) == '/')
#endif /* MPW */
#endif /* VMS */
#endif /* MSDOS || __OS2__ */

/**********************/

char * pascal filespecaddpath(path,filename)
char *path;
char *filename;
{   register char *filespec;
    register unsigned pathlen;

    if (!path || (pathlen = strlen(path)) == 0)
	filespec = mem_strdup(filename);
    else
    {
	filespec = (char *) mem_malloc(pathlen + 1 + strlen(filename) + 1);
	if (filespec)
	{   strcpy(filespec,path);
#if MSDOS || __OS2__
	    if (!ispathdelim(filespec[pathlen - 1]))
		strcat(filespec,"\\");
#else
#if VMS
#else
#if MPW
	    if (!ispathdelim(filespec[pathlen - 1]))
		strcat(filespec,":");
#else
	    if (!ispathdelim(filespec[pathlen - 1]))
		strcat(filespec,"/");
#endif /* MPW	*/
#endif /* VMS	*/
#endif
	    strcat(filespec,filename);
	}
    }
    return filespec;
}

#ifndef MPW
/**********************/
char * pascal filespecrootpath(filespec)
char *filespec;
{
#if SUN || M_UNIX || M_XENIX
#define DIRCHAR '/'
#endif
#if MSDOS || __OS2__
#define DIRCHAR '\\'
#endif
#ifdef MPW
#define DIRCHAR ':'
#endif

    char *cwd, *cwd_t, cwd_d[132];
    char *p, *p2;

    if (!filespec)
	return filespec;
#if MSDOS || __OS2__
    /* if already absolute (with \ or drive:) ... */
    if (*filespec == DIRCHAR ||	(isalpha(*filespec) && *(filespec+1) == ':')) 
	return filespec;	/*	... return input string */
#else
    if (*filespec == DIRCHAR)	/* already absolute ... */
	return filespec;	/*	... return input string */
#endif

    /* get current working directory path */
#if SUN || M_UNIX || M_XENIX
    cwd_t = (char *)getcwd(NULL, 256);
#endif
#if MSDOS || __OS2__
    if (getcwd(cwd_d, sizeof(cwd_d)))
       cwd_t = cwd_d;
    else
       cwd_t = NULL;
#endif
    
    if (cwd_t == NULL)
    {
	mem_free(filespec);
	return NULL;	/* error - path too long (more than 256 chars !)*/
    }
    cwd = mem_strdup(cwd_t);	/* convert cwd to mem package */
#if MSDOS
    assert(strlen(cwd) > 0);
    if (cwd[strlen(cwd) - 1] == DIRCHAR)
	cwd[strlen(cwd) - 1] = '\0';        
#endif
#if SUN || M_UNIX || M_XENIX
    free(cwd_t);	
#endif
    p = filespec;
    while (p != NULL)
    {
	p2 = (char *)strchr(p, DIRCHAR);
	if (p2 != NULL)
	{
	    *p2 = '\0';
	    if (strcmp(p, "..") == 0)	/* move up cwd */
		/* remove last directory from cwd */
		*((char *)strrchr(cwd, DIRCHAR)) = '\0';  
	    else if (strcmp(p, ".") != 0) /* not current directory */
	    {
		cwd_t = cwd;
		cwd = (char *)mem_calloc(strlen(cwd_t) + 1 + strlen(p) + 1);
#if SUN || M_UNIX || M_XENIX
		sprintf(cwd, "%s/%s", cwd_t, p);  /* add relative directory */
#endif
#if MSDOS || __OS2__
		sprintf(cwd, "%s\\%s", cwd_t, p);  /* add relative directory */
#endif
		mem_free(cwd_t);
	    }
	    /* else if ".", then ignore - it means current directory */
	    *p2 = DIRCHAR;
	    p2++;
	}
	else if (strcmp(p,"..") == 0)	/* move up cwd */
	{   
	    /* remove last directory from cwd */
	    *((char *)strrchr(cwd, DIRCHAR)) = '\0';
	}				
	else if (strcmp(p,".") != 0) /* no more subdirectories ... */
	{   /* ... save remaining string */
	    cwd_t = cwd;
	    cwd = (char *)mem_calloc(strlen(cwd_t) + 1 + strlen(p) + 1);
#if SUN || M_UNIX || M_XENIX
	    sprintf(cwd, "%s/%s", cwd_t, p);  /* add relative directory */
#endif
#if MSDOS || __OS2__
	    sprintf(cwd, "%s\\%s", cwd_t, p);  /* add relative directory */
#endif
	    mem_free(cwd_t);
	}
	p = p2;
    }
    mem_free(filespec);
  
    return cwd;    
#ifdef VMS
    assert(0);
#endif
}
#endif

/**********************/

char * pascal filespecdotext(filespec)
char *filespec;
{   register char *p;
    register int len;

    if ((p = filespec) != NULL)
    {	p += (len = strlen(p));
	while (1)
	{	if (*p == '.')
		    break;
		if (p <= filespec || ispathdelim(*p))
		{   p = filespec + len;
		    break;
		}
		p--;
	}
    }
    return p;
}

/**********************/

char * pascal filespecname(filespec)
register char *filespec;
{   register char *p;

    /* Start at end of string and back up till we find the beginning	*/
    /* of the filename or a path.					*/
    for (p = filespec + strlen(filespec);
	 p != filespec && !ispathdelim(*(p - 1));
	 p--
	)
	    ;
    return p;
}

/***********************/

char * pascal filespecgetroot(name)
char *name;
{	char *root,*p,c;

	p = filespecdotext(name);
	c = *p;
	*p = 0;
	root = mem_strdup(name);
	*p = c;
	return root;
}

/*****************************/

char * pascal filespecforceext(filespec,ext)
char *filespec,*ext;
{   register char *p,*pext;

    if ((p = filespec) != NULL)
    {	pext = filespecdotext(filespec);
	if (ext)
	{   int n = pext - filespec;
	    p = (char *) mem_malloc(n + 1 + strlen(ext) + 1);
	    if (p)
	    {	memcpy(p,filespec,n);
		p[n] = '.';
		strcpy(&p[n + 1],ext);
	    }
	}
	else
	    p = mem_strdup(filespec);
    }
    return p;
}

/*****************************/

char * pascal filespecdefaultext(filespec,ext)
char *filespec,*ext;
{	register char *p,*pext;

	pext = filespecdotext(filespec);
	if (*pext == '.')		/* if already got an extension	*/
	    p = mem_strdup(filespec);
	else
	{   int n = pext - filespec;
	    p = (char *) mem_malloc(n + 1 + strlen(ext) + 1);
	    if (p)
	    {
	    	memcpy(p,filespec,n);
		p[n] = '.';
		strcpy(&p[n + 1],ext);
	    }
	}
	return p;
}

/************************************/

#if !(MSDOS || __OS2__)

char *filespectilde(filespec)
char *filespec;
{
#if BSDUNIX
    struct passwd *passwdPtr;
    register char *f;

    if (filespec && *filespec == '~')
    {
	passwdPtr = NULL;
	if (filespec[1] == '/' || filespec[1] == 0)	/* if ~/... or ~ */
	{   f = filespec + 1;
	    passwdPtr = getpwuid(getuid());
	}
	else				/* else ~name	*/
	{
	    char c;

	    f = strpbrk(filespec," /");
	    if (!f)
		f = filespec + strlen(filespec); /* point at trailing 0 */
	    c = *f;
	    *f = 0;
	    passwdPtr = getpwnam(filespec + 1);
	    *f = c;
	}
	if (passwdPtr)
	{   char *p;

	    p = (char *) mem_malloc(strlen(passwdPtr->pw_dir) + strlen(f) + 1);
	    if (p)
	    {
		strcpy(p,passwdPtr->pw_dir);
		strcat(p,f);
		mem_free(filespec);
		filespec = p;
	    }
	}
    }
#endif
#if MSDOS || __OS2__
#endif
#if VMS
    assert(0);
#endif
    return filespec;
}

/************************************/

char *filespecmultitilde(string)
char *string;
{
    register char *p, *p2, *p3, *p4;

    string = filespectilde(string);	/* expand if first character is a '~' */
     
    if (string)
    {
       for (p = string; *p != '\0'; p++)
       {
	   if (*p == '~')
           {
	      *p = '\0';	/* terminate sub string */
	      p2 = mem_strdup(string); /* get new sub string from old string */	
	      *p = '~';	/* reset ~ character */
              for (p3 = p + 1; *p3 != ' ' && *p3 != '\0'; p3++)
                  ; /* scan to next name, or end of the string */
              p4 = NULL;
              if (*p3 == ' ')
              {
                 p4 = mem_strdup(p3);  /* save reminder of the string */
                 *p3 = '\0';
              } 
	      p = mem_strdup(p);    /* get tilde string */
	      mem_free(string);
	      p = filespectilde(p);

              /* reconstruct the string from pieces */
              if (p4)
              {
	         string = (char *)
                       mem_calloc(strlen(p2) + strlen(p) + strlen(p4) + 1);
	         sprintf(string, "%s%s%s", p2, p, p4);
              }
              else
              {
	         string = (char *)
                       mem_calloc(strlen(p2) + strlen(p) + 1);
	         sprintf(string, "%s%s", p2, p);
              }
	      mem_free(p);
	      p = string + strlen(p2) + 2;
	      mem_free(p2);
              if (p4)
	         mem_free(p4);
	   }	    
       }
    }	    
    return string;
}

#endif

#ifndef MPW
/************************************/

char * pascal filespecbackup(filespec)
char *filespec;
{
#if MSDOS || __OS2__
    return filespecforceext(filespec,"BAK");
#endif
#if BSDUNIX
    char *p,*f;

    /* Prepend .B to file name, if it isn't already there	*/
    if (!filespec)
	return filespec;
    p = filespecname(filespec);
    if (p[0] == '.' && p[1] == 'B')
	return mem_strdup(filespec);
    f = (char *) mem_malloc(strlen(filespec) + 2 + 1);
    if (f)
    {	strcpy(f,filespec);
	strcpy(&f[p - filespec],".B");
	strcat(f,p);
    }
    return f;
#endif
}
#endif
