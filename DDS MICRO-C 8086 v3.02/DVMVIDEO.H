/* Monochrome video attributes (Monochrome adapters only) */
#define	NORMAL		0x07		/* Monochrome normal video */
#define REVERSE		0x70		/* Monochrome reverse video */
#define UNDERLINE	0x01		/* Monochrome underline video */

extern int		V_BASE, V_XY;
extern char		V_ATTR;
extern register	vprintf();

// Special characters recognized by Vputc
#define _CL 	0x85			/* clear entire display */
#define _CD		0x86			/* clear to end of display */
#define _CE 	0x87			/* clear to end of line */
#define _SO 	0x88			/* Begin standout mode */
#define _SE 	0x89			/* end standout mode */

// Cursor types used by Vcursor()
#define CURSOR_NONE		0
#define CURSOR_BLOCK	1
#define CURSOR_LINE		2

void Vopen(unsigned char a)
{
	vopen();
	V_ATTR = a;
}
void Vputc(unsigned char c)
{
	switch(c) {
	case _CL:	vclscr();			return;
	case _CD:	vcleos();			return;
	case _CE:	vcleol();			return;
	case _SO:	V_ATTR = REVERSE;	return;
	case _SE:	V_ATTR = NORMAL;	return;
	} vputc(c);
}
void Vcursor(unsigned c)
{
	switch(c) {
	case CURSOR_BLOCK:
		vcursor_block();
		return;
	case CURSOR_LINE:
		vcursor_line();
		return; }
	vcursor_off();
}

#define	Vcleol		vcleol
#define	Vcleos		vcleos
#define	Vclose()
#define	Vclscr		vclscr
#define	Vcolor(c)	(V_ATTR = c)
#define	Vgetc		vgetc
#define	Vgetk		vgetc
#define	Vgets		vgets
#define	Vgotoxy		vgotoxy
#define	Vprintf		vprintf
#define	Vputs		vputs

// Special keys returned by Vgetc() and Vgetk()
#define	_KBS	0xff8c			/* Backspace	*/
#define	_K1		0xff8d			/* Function 1	*/
#define	_K2		0xff8e			/* Function 2	*/
#define	_K3		0xff8f			/* Function 3	*/
#define	_K4		0xff90			/* Function 4	*/
#define	_K5		0xff91			/* Function 5	*/
#define	_K6		0xff92			/* Function 6	*/
#define	_K7		0xff93			/* Function 7	*/
#define	_K8		0xff94			/* Function 8	*/
#define	_K9		0xff95			/* Function 9	*/
#define	_K10	0xff96			/* Function 10	*/
//#define	_K11	0x285
//#define	_K12	0x286
#define	_KUA	0xff80			/* Up    arrow	*/
#define	_KDA	0xff81			/* Down  arrow	*/
#define	_KLA	0xff82			/* Left  arrow	*/
#define	_KRA	0xff83			/* Right arrow	*/
#define	_KHO	0xff86			/* Home			*/
#define	_KEN	0xff87			/* End			*/
#define	_KPU	0xff84			/* PgUp			*/
#define	_KPD	0xff85			/* PgDn			*/
#define	_KIN	0xff8a			/* Insert key	*/
#define	_KDL	0xff8b			/* Delete key	*/

#define	_CHO	0xff99			/* Control Home */
#define	_CEN	0xff9a			/* Control End  */
#define	_CPU	0xff97			/* Control PgUp */
#define	_CPD	0xff98			/* Control PgDn */


// Colors used by Vinit(), Vcolor(), VFcolor() and VBcolor()
// Vinit() and Vcolor() use (background<<8) | foreground
//#define BLACK			0
//#define BLUE			1
//#define GREEN			2
//#define CYAN			3
//#define RED				4
//#define MAGENTA			5
//#define BROWN			6
//#define LIGHTGRAY		7
//#define DARKGRAY		8
//#define LIGHTBLUE		9
//#define LIGHTGREEN		10
//#define LIGHTCYAN		11
//#define LIGHTRED		12
//#define LIGHTMAGENTA	13
//#define YELLOW			14
//#define WHITE			15
//#define BLINK			128	// Useless, background uses high intensity colors.
