/*
 * structure used for the mathematics error-handling function, matherr
 */
struct exception {
	int type;	/* type of error */
	char *name;	/* name of the function that had the err */
	double arg1, arg2; /* arguments to the function that had the error */
	double retval;	/* value returned by the function having the error */
};

/*
 * type of errors: used in the integer "type" of structure "exception".
 */
#define DOMAIN    1	/* domain error */
#define SING      2	/* singularity */
#define OVERFLOW  3	/* overflow */
#define UNDERFLOW 4	/* underflow */
#define TLOSS	  5	/* total loss of significance */
#define PLOSS	  6	/* partial loss of significance */

extern int errno; /* error indicator */

extern int atoi(), matherr();
extern long atol(), strtol();
extern double atof(), exp(), log(), log10(), pow(), sqrt();
extern double floor(), ceil(), fmod(), fabs(), frexp(), ldexp(), modf();
extern double sinh(), cosh(), tanh(), sin(), cos(), tan(), asin(), acos();
extern double atan(), atan2();
