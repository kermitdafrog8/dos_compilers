/*
 * DDS MICRO-C Low-Res Graphics Library definitions
 *
 * Copyright 1998-2020 Dave Dunfield
 * All rights reserved.
 */

/*
 * Common colors. These are the first 16 palette entries, and will usually
 * represent these colors, however it is possible to change them...
 */
#define	BLACK		0		/* Black */
#define	CLEAR		0		/* Black (Transparent in Sprite) */
#define	BLUE		1		/* Standard Blue */
#define	GREEN		2		/* Standard Green */
#define CYAN		3		/* Standard Cyan */
#define	RED			4		/* Standard Red */
#define	MAGENTA		5		/* Standard Magenta */
#define	BROWN		6		/* Standard Brown */
#define	WHITE		7		/* Standard White */
#define	GRAY		8		/* Gray */
#define	B_BLUE		9		/* Bright Blue */
#define	B_GREEN		10		/* Bright Green */
#define	B_CYAN		11		/* Bright Cyan */
#define	B_RED		12		/* Bright Red */
#define	B_MAGENTA	13		/* Bright Magenta */
#define	B_YELLOW	14		/* Bright Yellow */
#define	B_WHITE		15		/* Bright White */

/*
 * External definitions in LRG library
 */
extern register int	lrg_printf();
