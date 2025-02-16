/**
*
* This structure is used by the setjmp/longjmp functions to save the
* current environment on the 8086.
*
*/
struct JMP_BUF
	{
	int (*jmpret)();		/* return address */
	int jmpbp;		/* BP register */
	int jmpsp;		/* SP register */
	int jmpds;		/* DS register */
	int jmpes;		/* ES register */
	};

typedef struct JMP_BUF jmp_buf;

