/*
 *  drivinit.h
 *
 *  Header file for printer driver initialization using ExtDeviceMode()
 *  and DeviceCapabilities().
 *
 */

/* size of a device name string */
#define CCHDEVICENAME 32

/* current version of specification */
#define DM_SPECVERSION 0x300

/* field selection bits */
#define DM_ORIENTATION	    0x0000001L
#define DM_PAPERSIZE	    0x0000002L
#define DM_PAPERLENGTH	    0x0000004L
#define DM_PAPERWIDTH	    0x0000008L
#define DM_SCALE	    0x0000010L
#define DM_COPIES	    0x0000100L
#define DM_DEFAULTSOURCE    0x0000200L
#define DM_PRINTQUALITY     0x0000400L
#define DM_COLOR	    0x0000800L
#define DM_DUPLEX	    0x0001000L

/* orientation selections */
#define DMORIENT_PORTRAIT   1
#define DMORIENT_LANDSCAPE  2

/* paper selections */
#define DMPAPER_FIRST	    DMPAPER_LETTER
#define DMPAPER_LETTER	    1		// Letter 8 1/2 x 11 in
#define DMPAPER_LETTERSMALL 2		// Letter Small 8 1/2 x 11 in
#define DMPAPER_TABLOID     3		// Tabloid 11 x 17 in
#define DMPAPER_LEDGER	    4		// Ledger 17 x 11 in
#define DMPAPER_LEGAL	    5		// Legal 8 1/2 x 14 in
#define DMPAPER_STATEMENT   6		// Statement 5 1/2 x 8 1/2 in
#define DMPAPER_EXECUTIVE   7		// Executive"7 1/2 x 10 in
#define DMPAPER_A3	    8		// A3 297 x 420 mm
#define DMPAPER_A4	    9		// A4 210 x 297 mm
#define DMPAPER_A4SMALL     10		// A4 Small 210 x 297 mm
#define DMPAPER_A5	    11		// A5 148 x 210 mm
#define DMPAPER_B4	    12		// B4 250 x 354
#define DMPAPER_B5	    13		// B5 182 x 257 mm
#define DMPAPER_FOLIO	    14		// Folio 8 1/2 x 13 in
#define DMPAPER_QUARTO	    15		// Quarto 215 x 275 mm
#define DMPAPER_10X14	    16		// 10x14 in
#define DMPAPER_11X17	    17		// 11x17 in
#define DMPAPER_NOTE	    18		// Note 8 1/2 x 11 in
#define DMPAPER_ENV_9	    19		// Envelope #9 3 7/8 x 8 7/8
#define DMPAPER_ENV_10	    20		// Envelope #10 4 1/8 x 9 1/2
#define DMPAPER_ENV_11	    21		// Envelope #11 4 1/2 x 10 3/8
#define DMPAPER_ENV_12	    22		// Envelope #12 4 \276 x 11
#define DMPAPER_ENV_14	    23		// Envelope #14 5 x 11 1/2
#define DMPAPER_CSHEET	    24		// C size sheet
#define DMPAPER_DSHEET	    25		// D size sheet
#define DMPAPER_ESHEET	    26		// E size sheet
#define DMPAPER_LAST	    DMPAPER_ESHEET

#define DMPAPER_USER	    256

/* bin selections */
#define DMBIN_FIRST	    DMBIN_UPPER
#define DMBIN_UPPER	    1
#define DMBIN_ONLYONE	    1
#define DMBIN_LOWER	    2
#define DMBIN_MIDDLE	    3
#define DMBIN_MANUAL	    4
#define DMBIN_ENVELOPE	    5
#define DMBIN_ENVMANUAL     6
#define DMBIN_AUTO	    7
#define DMBIN_TRACTOR	    8
#define DMBIN_SMALLFMT	    9
#define DMBIN_LARGEFMT	    10
#define DMBIN_LARGECAPACITY 11
#define DMBIN_CASSETTE      14
#define DMBIN_LAST	    DMBIN_CASSETTE

#define DMBIN_USER	    256     /* device specific bins start here */

/* print qualities */
#define DMRES_DRAFT	    (-1)
#define DMRES_LOW	    (-2)
#define DMRES_MEDIUM	    (-3)
#define DMRES_HIGH	    (-4)

/* color enable/disable for color printers */
#define DMCOLOR_MONOCHROME  1
#define DMCOLOR_COLOR	    2

/* duplex enable */
#define DMDUP_SIMPLEX	 1
#define DMDUP_VERTICAL	 2
#define DMDUP_HORIZONTAL 3

typedef struct _devicemode {
    char dmDeviceName[CCHDEVICENAME];
    WORD dmSpecVersion;
    WORD dmDriverVersion;
    WORD dmSize;
    WORD dmDriverExtra;
    DWORD dmFields;
    short dmOrientation;
    short dmPaperSize;
    short dmPaperLength;
    short dmPaperWidth;
    short dmScale;
    short dmCopies;
    short dmDefaultSource;
    short dmPrintQuality;
    short dmColor;
    short dmDuplex;
} DEVMODE;

typedef DEVMODE * PDEVMODE, NEAR * NPDEVMODE, FAR * LPDEVMODE;

/* mode selections for the device mode function */
#define DM_UPDATE	    1
#define DM_COPY 	    2
#define DM_PROMPT	    4
#define DM_MODIFY	    8

#define DM_IN_BUFFER	    DM_MODIFY
#define DM_IN_PROMPT	    DM_PROMPT
#define DM_OUT_BUFFER	    DM_COPY
#define DM_OUT_DEFAULT	    DM_UPDATE

/* device capabilities indices */
#define DC_FIELDS	    1
#define DC_PAPERS	    2
#define DC_PAPERSIZE	    3
#define DC_MINEXTENT	    4
#define DC_MAXEXTENT	    5
#define DC_BINS 	    6
#define DC_DUPLEX	    7
#define DC_SIZE 	    8
#define DC_EXTRA	    9
#define DC_VERSION	    10
#define DC_DRIVER	    11

/* export ordinal definitions */
#define PROC_EXTDEVICEMODE	MAKEINTRESOURCE(90)
#define PROC_DEVICECAPABILITIES MAKEINTRESOURCE(91)
#define PROC_OLDDEVICEMODE	MAKEINTRESOURCE(13)

/* define types of pointers to ExtDeviceMode() and DeviceCapabilities()
 * functions
 */
typedef WORD FAR PASCAL FNDEVMODE(HWND, HANDLE, LPDEVMODE, LPSTR, LPSTR,
    LPDEVMODE, LPSTR, WORD);

typedef FNDEVMODE FAR * LPFNDEVMODE;

typedef DWORD FAR PASCAL FNDEVCAPS(LPSTR, LPSTR, WORD, LPSTR, LPDEVMODE);

typedef FNDEVCAPS FAR * LPFNDEVCAPS;
