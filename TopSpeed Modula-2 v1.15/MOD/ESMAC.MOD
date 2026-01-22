MODULE esmac;

IMPORT FindMeta;
IMPORT GrConst;
IMPORT GrProcs1;
IMPORT GrProcs2;
IMPORT GrPorts;
IMPORT GrFonts;

FROM GrProcs1 IMPORT AddPt,AlignPattern,BackColor,BackPattern,BorderColor,CenterRect,CharWidth,ClearText,ClipRect,
                     ClrInt,CopyBits,CursorBitmap,CursorMap,CursorStyle,DefineCursor,DefineDash,DefinePattern,DrawChar,
                     DrawString,DrawText,DupPt,DupRect,EqualPt,EqualRect,EraseArc,EraseOval,ErasePoly,EraseRect,
                     EraseRoundRect,EventQueue,FillArc,FillOval,FillPoly,FillRect,FillRoundRect,FrameArc,FrameOval,
                     FramePoly,FrameRect,FrameRoundRect,Gbl2LclPt,Gbl2LclRect,Gbl2VirPt,Gbl2VirRect,GetBMapField,
                     GetCmdLine,GetFontField,GetLPixel,GetPenState,GetPixel,GetPort,GetPortField,HardCopy,
                     HideCursor,HidePen,ImagePara,ImageSize,InceptRect,InitBitmap,InitGrafix,InitMouse,InitPort,
                     InitRowTable,InsetRect,InvertArc,InvertOval,InvertPoly,InvertRect,InvertRoundRect,KeyEvent,
                     Lcl2GblPt,Lcl2GblRect,Lcl2VirPt,Lcl2VirRect,LimitMouse,LineRel,LineTo,LoadFont,LoadPalette,
                     MapPoly,MapPt,MapRect,MarkerAngle,MarkerSize,MarkerType,MetaInstalled,MiterLimit,MoveCursor,
                     MovePortTo,MoveTo,OffsetPoly,OffsetRect,OvalPt;

FROM GrProcs2 IMPORT  PaintArc,PaintOval,PaintPoly,PaintRect,PaintRoundRect,PeekEvent,PenCap,PenColor,PenDash,PenJoin,
                     PenMode,PenNormal,PenOffset,PenPattern,PenSize,PolyLine,PolyMarker,PopGrafix,PortBitmap,PortOrigin,
                     PortSize,ProtectOff,ProtectPort,ProtectRect,Pt2Rect,PtInArc,PtInRect,PtInRoundRect,PtOnArc,
                     PtOnLine,PtOnOval,PtOnPoly,PtOnRect,PtOnRoundRect,PtToAngle,PushGrafix,QueryColors,QueryComm,
                     QueryCursor,QueryError,QueryGrafix,QueryPosn,QueryRes,QueryX,QueryY,RasterOp,ReadImage,
                     ReadMouse,ScaleMouse,ScalePt,ScreenRect,ScreenSize,ScrollRect,SetBitmap,SetDisplay,SetFont,
                     SetInt,SetLocal,SetOrigin,SetPalette,SetPenState,SetPixel,SetPort,SetPt,SetRect,SetVirtual,
                     ShiftRect,ShowCursor,ShowPen,StopEvent,StopMouse,StoreEvent,StringWidth,SubPt,SystemFont,
                     TextAlign,TextAngle,TextExtra,TextFace,TextMode,TextPath,TextScore,TextSize,TextSlant,TextSpace,
                     TextUnder,TextWidth,TrackCursor,UnionRect,Vir2GblPt,Vir2GblRect,Vir2LclPt,Vir2LclRect,VirtualRect,
                     WriteImage,XlateImage,XYInRect,XYOnLine,ZoomBits;

FROM GrConst IMPORT

    Replace,
    Ovrlay,
    Invert,
    Erase,
    zREPz,
    zORz,
    zXORz,
    zNANDz,
    zNREPz,
    zNORz,
    zNXORz,
    zANDz,

    ATT ,               (* AT&T Std. Color & DEB Adaptors   *)
    ATT640x400 ,        (*   640x400 monochrome             *)
    DEB640x200 ,        (*   640x200 16-color               *)
    DEB640x400 ,        (*   640x400 16-color               *)
    CGA ,               (* IBM Color Graphics Adaptor (CGA) *)
    CGA320x200 ,        (*   320x200 4-color                *)
    CGA640x200 ,        (*   640x200 2-color                *)
    COR ,               (* Cornerstone                      *)
    COR1600x1280V ,     (*   Vista 1600 1600x1280 mono      *)
    COR1600x1280VA ,    (*Vista 1600 1600x1280 no em, 2 mon *)
    COR1600x1280DP ,    (*   DualPage   1600x1280 mono      *)
    COR1600x1280DPA ,   (*   DualPage 1600x1280, no JP1     *)
    EGA ,               (* IBM Enhanced Graphics Adaptor    *)
    EGAMono ,           (*   640x350 monochrome             *)
    EGA320x200 ,        (*   320x200 16-color               *)
    EGA640x200 ,        (*   640x200 16-color               *)
    EGA640x350 ,        (*   640x350 16-color (128k EGA)    *)
    MGA640x350 ,        (*   640x350 2-color                *)
    EGA640x480 ,        (*   640x480 16-color  (VGA)        *)
    MGA640x480 ,        (*   640x480 2-color   (MCGA)       *)
    VGA320x200 ,        (*   320x200 256-color (PS2 VGA)    *)
    EGA640x350S ,       (*   640x350 16-color (no bios-EGA) *)
    VGA640x350S ,       (*   640x350 16-color (no bios-VGA) *)
    VGA640x480S ,       (*   640x480 16-color (no bios-VGA) *)
    JRT320x200 ,        (*320x200 16-color IBM PCjr & Tandy 1000 EX *)
    EVA ,               (* Tseng Labs EVA/480               *)
    EVA640x480 ,        (*   640x480 16-color               *)
    EVR ,               (* Everex Graphics Edge Adaptor     *)
    EVR640x200 ,        (*   640x200 16-color               *)
    EVR640x400 ,        (*   640x400 4-color                *)
    GEN ,               (* Genoa SuperEGA HiRes             *)
    GEN800x600 ,        (*   800x600 16-color               *)
    GEN1024x768 ,       (* Genoa SuperVGA HiRes-10 16-color *)
    GEN640x350X ,       (*   640x350 256-color              *)
    GEN640x480X ,       (*   640x480 256-color              *)
    HER ,               (* Hercules/AST Monochrome Adaptor  *)
    HER720x348 ,        (*   720x348 monochrome             *)
    MDS ,               (* MDS Genius Graphics Display      *)
    MDS736x1008 ,       (*   736x1008 monochrome            *)
    NNR512x512 ,        (* Number Nine 512x485 256-color    *)
    NNR1024x768 ,       (*    2048x4 @ 1024x768x16          *)
    NSI ,               (* NSI Logic Smart EGA/Plus         *)
    NSI800x600 ,        (*   800x600 16-color               *)
    OCD800x600 ,        (* Orchid Designer VGA 800x600x16   *)
    OCD1024x768 ,       (*   1024x768 16 color              *)
    OCD640x350X ,       (*   640x480 256 color              *)
    OCD640x480X ,       (*   640x480 256 color              *)
    PAR ,               (* Paradise AutoSwitch EGA/480      *)
    PAR640x480 ,        (*   640x480 16-color               *)
    PAR800x600 ,        (*   800x600 16-color               *)
    SIG ,               (* Sigma Design                     *)
    SIG640x400 ,        (*   640x400 16-color, Color-400    *)
    SIG1664x1200 ,      (* Sigma LaserView 1664x1200 mono   *)
    STB ,               (* STB GraphicsPlus-II Adaptor      *)
    STB640x352 ,        (*   640x352 monochrome             *)
    STB320x200 ,        (*   320x200 16-color               *)
    STB640x200 ,        (*   640x200 4-color                *)
    STB640x400 ,        (*   640x400 monochrome             *)
    STB800x600 ,        (* STB VGA Extra/EM 800x600x16      *)
    STB1024x768 ,       (*   1024x768 16 color              *)
    STB640x350X ,       (*   640x350 256 color              *)
    STB640x480X ,       (*   640x480 256 color              *)
    TEC ,               (* Tecmar Graphics-Master Adaptor   *)
    TEC720x352 ,        (*   720x352 monochrome             *)
    TEC720x704 ,        (*   720x704 monochrome             *)
    TEC320x200 ,        (*   320x200 16-color               *)
    TEC640x200 ,        (*   640x200 16-color               *)
    TEC640x400 ,        (*   640x400 16-color               *)
    TOS ,               (* Toshiba 3100                     *)
    TOS640x400 ,        (*   640x400 monochrome             *)
    TTS ,               (* IBM 3270 PC                      *)
    TTS720x350 ,        (*   720x350 monochrome             *)
    TTS360x350 ,        (*   360x350 4-color                *)
    VGA ,               (* Video-7 VEGA Deluxe              *)
    VGA640x480 ,        (*   640x480 16-color               *)
    VGA752x410 ,        (*   752x410 16-color               *)
    VGA720x540 ,        (* V7 VGA  720x540 16-color         *)
    VGA800x600 ,        (*   800x600 16-color  (VGA)        *)
    VGA640x350X ,       (* V7 VRAM  640x350 256-color       *)
    VGA640x480X ,       (*   640x480 256-color              *)
    VGA1024x768x2 ,     (*   1024x768 2-color               *)
    WYS ,               (* Wyse WY-700 Graphics Display     *)
    WYS1280x800 ,       (*   1280x800 monochrome            *)
    WYS1280x400 ,       (*   1280x400 monochrome            *)
    WYS640x400 ,        (*   640x400 monochrome             *)
    MEC1120x750 ,       (* NEC PC 98XA monochrome           *)
    MEC640x400 ,        (* NEC PC 98VM monochrome           *)
    NEC1120x750 ,       (* NEC PC 98XA 16-color             *)
    NEC640x400 ,        (* NEC PC 98VM 16-color             *)

                        (* Defines for National Design Genesis-1024/1280 *)

    NDI640x480x4D ,     (* 640x480   16-color, digitl *)
    NDI640x480x4A ,     (* 640x480   16-color, analog *)
    NDI1024x768x4J ,    (* 1024x768  16-color, JVC    *)
    NDI1024x768x4M ,    (* 1024x768  16-color, Mitsu. *)
    NDI1280x1024x4J ,   (* 1280x1024 16-color, JVC    *)
    NDI960x720x4N ,     (* 960x720   16-color, NEC XL *)

                        (* Defines for Hewlett-Packard HP82328 IGC       *)

    HP1024x768x4 ,      (* 1024x768  16-color         *)

    CUSTLIN ,           (* User defined linear memory *)
    CUSTBS ,            (* User defined Bank select   *)
    CUSTEGA ,           (* User defined EGA Superset  *)

                        (* Mouse Definitions *)

    com1 ,              (* Mouse Systems mouse, COM1      *)
    com2 ,              (* Mouse Systems mouse, COM2      *)
    msMouse ,           (* Microsoft Bus Mouse            *)
    msCOM1 ,            (* Microsoft Serial Mouse, COM1   *)
    msCOM2 ,            (* Microsoft Serial Mouse, COM2   *)
    MsDriver ,          (* Microsoft Mouse driver         *)
    swRight ,
    swMiddle ,          (*   (not on 2 button mice)       *)
    swLeft ,
    swAll ,

    black ,             (* all bits OFF *)
    white ,             (* all bits ON  *)

    TextPg0 ,
    GrafPg0 ,
    GrafPg1 ,
    ScrnXmin ,
    ScrnYmin ,


    cNormal ,           (* TEXTFACE *)
    cBold ,
    cItalic ,
    cUnderline ,
    cStrikeout ,
    cMirrorX ,
    cMirrorY ,
    cProportional ,

    alignLeft ,         (* TEXTALIGN - Horizontal         *)
    alignCenter ,
    alignRight ,

    alignBaseline ,     (* TEXTALIGN - Vertical           *)
    alignBottom ,
    alignMiddle ,
    alignTop ,

    pathRight ,         (* TEXTPATH definitions           *)
    pathUp ,
    pathLeft ,
    pathDown ,

    capFlat ,           (* PENCAP definitions             *)
    capRound ,
    capSquare ,

    joinRound ,         (* PENJOIN definitions            *)
    joinBevel ,
    joinMiter ,

    POINT ,             (* "Point" structure type
                         RECORD
                          X: INTEGER; (* X coordinate *)
                          Y: INTEGER; (* Y coordinate *)
                         END;
                                                           *)

    COLRTABLE,          (*= ARRAY[0..15] OF LONGINT;       *)

    RECT  ,             (* "Rectangle" structure type
                        RECORD
                         xMin: INTEGER; (* minimum X *)
                         yMin: INTEGER; (* minimum Y *)
                         xMax: INTEGER; (* maximum X *)
                         yMax: INTEGER; (* maximum Y *)
                        END;
                                                        *)

    POLYHEAD ,          (* Polygon "header" structure
                        RECORD
                         polyBgn: CARDINAL; (* beginning index *)
                         polyEnd: CARDINAL; (* ending index    *)
                         polyRect: RECT;    (* boundry limits  *)
                        END;
                                                        *)

    EVENT ,             (* Event record structure
                        RECORD
                         ASCII: CHAR;             (* ASCII character code      *)
                         ScanCode: SYSTEM.BYTE;   (* Keyboard scan code        *)
                         State: CARDINAL;         (* Keyboard & mouse switches *)
                         CursorX: INTEGER;        (* Cursor X position         *)
                         CursorY: INTEGER;        (* Cursor Y position         *)
                         Time: INTEGER;           (* System time of event      *)
                        END;
                                                         *)

    CURRCD ,            (* Cursor Image definition
                        RECORD
                         curWidth: CARDINAL;                   (* must be 16        *)
                         curHeight: CARDINAL;                  (* must be 16        *)
                         curAlign: CARDINAL;                   (* must be 0         *)
                         curRowBytes: CARDINAL;                (* must be 2         *)
                         curBits: CHAR;                        (* must be 1         *)
                         curPlanes: CHAR;                      (* must be 1         *)
                         curData: ARRAY [1..32] OF SYSTEM.BYTE;(* cursor data bytes *)
                        END;
                                                          *)

    PATRCD ,            (* Pattern Image definition
                        RECORD
                         patWidth: CARDINAL;                      (* must be 8                *)
                         patHeight: CARDINAL;                     (* must be 8                *)
                         patAlign: CARDINAL;                      (* must be zero             *)
                         patRowBytes: CARDINAL;                   (* must be equal to patBits *)
                         patBits: SYSTEM.BYTE;                    (* value of 1,2,4 or 8      *)
                         patPlanes: SYSTEM.BYTE;                  (* value of 1 thru 32       *)
                         patData: ARRAY [1..32] OF SYSTEM.BYTE;   (* pattern data bytes       *)
                        END;
                                                        *)

    PENSTATE ,          (* Pen State record structure
                        RECORD
                         psBkColor: LONGINT;  (* Background color             *)
                         psPnColor: LONGINT;  (* Pen color                    *)
                         psPnLoc: POINT;      (* Pen location                 *)
                         psPnSize: POINT;     (* Pen size                     *)
                         psPnMode: CARDINAL;  (* Pen mode (rasterOp)          *)
                         psPnPat: CARDINAL;   (* Pen pattern index            *)
                         psPnCap: CARDINAL;   (* Pen end-cap style            *)
                         psPnJoin: CARDINAL;  (* Line join style              *)
                         psPnDash: CARDINAL;  (* Line dash style              *)
                         psPnOffset: CARDINAL;(* Dash starting offset         *)
                         psPnLevel: CARDINAL; (* Pen visibility level         *)
                        END;
                                              *)

    DIRREC ,            (* FILEQUERY - directory record
                        RECORD
                         reserved: ARRAY [1..21] OF CHAR;  (*    (DOS reserved) *)
                         fileAttr: SYSTEM.BYTE;            (* File attribute               *)
                         fileTime: CARDINAL;               (* File create time             *)
                         fileDate: CARDINAL;               (* File create date             *)
                         fileSize: LONGINT;                (* File size (bytes)            *)
                         fileName: ARRAY [1..14] OF CHAR;  (* "FILENAME.EXT\0"  *)
                        END;
                                                           *)

    IMAGEHEADER ,       (* Image Header record structure
                        RECORD
                         imWidth: CARDINAL;    (* Pixel width (X)              *)
                         imHeight: CARDINAL;   (* Pixel height (Y)             *)
                         imAlign: CARDINAL;    (* Image alignment              *)
                         imRowBytes: CARDINAL; (* Bytes per row                *)
                         imBits: SYSTEM.BYTE;  (* Bits per pixel               *)
                         imPlanes: SYSTEM.BYTE;(* Planes per pixel             *)
                                               (*   imData:     array [1..?] of byte;
                                               image data, variable length *)
                        END;
                                                              *)

    DASHRCD ,           (* DEFINEDASH data record
                        RECORD
                         nCnts: CARDINAL; (* number of active entries, 1-8*)
                         cnt1: CARDINAL;  (* distance ON,  1              *)
                         cnt2: CARDINAL;  (* distance OFF, 2              *)
                         cnt3: CARDINAL;  (* distance ON,  3              *)
                         cnt4: CARDINAL;  (* distance OFF, 4              *)
                         cnt5: CARDINAL;  (* distance ON,  5              *)
                         cnt6: CARDINAL;  (* distance OFF, 6              *)
                         cnt7: CARDINAL;  (* distance ON,  7              *)
                         cnt8: CARDINAL;  (* distance OFF, 8              *)
                        END;
                                                             *)

    MAPARRAY ,          (*ARRAY [0..7] OF CARDINAL;(* CursorMap data record *)
                        *)

                        (* Sample User Definable Types: *)

    CCBtype ,           (*
                         RECORD
                           (*User Definable Clock_Communication_Block*)
                          Timer: CARDINAL;
                          tX: INTEGER;
                          tY: INTEGER;
                          tSw: INTEGER;
                         END;
                         *)
    MCBtype ,            (*
                          RECORD
                            (*User Definable Mouse_Communication_Block*)
                           mX: INTEGER;
                           mY: INTEGER;
                           mSw: INTEGER;
                          END;
                          *)

    IMAGE ,             (* SYSTEM.BYTE;
                           (* "image" type equivalence      *)
                        *)

    IMAGEPTR ;          (* POINTER TO IMAGE;*)



FROM GrPorts IMPORT

    adsMem ,           (* POINTER TO SYSTEM.BYTE;
                        *)

    MAP ,              (* RECORD                                  (* "rowTable" Raster Line Pointers *)
                            rowTable: ARRAY [0..1280] OF adsMem;  (* Table of row pointers     *)
                          END;
                       *)

    rowtblPtr ,         (* POINTER TO MAP;*)

    BITMAP ,            (* "bitmap" Data Structure
                        RECORD
                         devClass: INTEGER;   (* Device class                  *)
                         devType: INTEGER;    (* Device type                   *)
                         devProcs: adsMem;    (* Ptr to device procedure list  *)
                         rowBytes: INTEGER;   (* Bytes per scan line           *)
                         pixWidth: INTEGER;   (* Pixels horizontal             *)
                         pixHeight: INTEGER;  (* Pixels vertical               *)
                         pixResX: INTEGER;    (* Pixels per inch horzontally   *)
                         pixResY: INTEGER;    (* Pixels per inch vertically    *)
                         pixBits: INTEGER;    (* Color bits per pixel          *)
                         pixPlanes: INTEGER;  (* Color planes per pixel        *)
                         mapTable: ARRAY [0..23] OF rowtblPtr;  (* Pointers to rowTable(s) *)
                         mapActive: INTEGER;  (* Active logical page           *)
                         mapPages: INTEGER;   (* Number of mapList entries,1-4 *)
                         mapList: ARRAY [0..3] OF INTEGER;      (* List of logical pages loaded *)
                         mapRsvd: ARRAY [0..5] OF INTEGER;      (*  (reserved for future use)   *)
                         mapSegment: CARDINAL;(* Map segment                   *)
                         mapHandle: CARDINAL; (* Map handle                    *)
                         mapManager: adsMem;  (* Pointer to paging manager     *)
                        END;
                                                        *)
    BITMAPPTR ,       (* POINTER TO BITMAP;*)


                        (* Bitmap Device Type (devType) Definitions   *)

    devSTD ,            (* Standard memory mapped bitmap    *)
    devEGA ,            (* IBM EGA/VGA display bitmap       *)
    devND1 ,            (* NDI Genesis-1024 bitmap          *)
    devND2 ,            (* NDI Genesis-1280 bitmap          *)
    devHP1 ,            (* Hewlett Packard1                 *)
    devEMS ,            (* EMS expanded memory bitmap       *)
    devWYS ,            (* Wyse 1280x800 display bitmap     *)
    devSIG ,            (* Sigma Design Color-400 bitmap    *)
    devLASVU ,          (* Sigma Design LaserView/plus      *)
    devVISTA ,          (* Cornerstone VISTA 1600           *)
    devREV512 ,         (* Number Nine Revolution 512x484   *)
    devDUALPG ,         (* Cornerstone DualPage System      *)
    devTSENG ,          (* Tseng labs Bank Select - STB/GENOA/ORCHID *)
    devREV2048 ,        (* #9 2048x4 Bank manager           *)

    cDevClass ,         (* "GetBMapField" index definitions *)
    cDevType ,
    cRowBytes ,
    cPixWidth ,
    cPixHeight ,
    cPixRsX ,
    cPixRsY ,
    cPixBits ,
    cPixPlanes ,
    cMapTable ,


    METAPORT ,          (* "metaPort" Data Structure
                        RECORD
                         portBMap: BITMAPPTR;        (*  Pointer to "bitmap" record     *)
                         portRect: GrConst.RECT;     (* 'Local' coordinate port bounds  *)
                         portOrgn: GrConst.POINT;    (* 'Global' origin of portRect     *)
                         portVirt: GrConst.RECT;     (* 'Virtual' port bounds           *)
                         portFlgs: INTEGER;          (*  Port Flags                     *)
                         portClip: GrConst.RECT;     (* 'Local' clipping rectangle      *)
                         portRgn: adsMem;            (*    (reserved)                   *)
                         bkPat: INTEGER;             (*  Background pattern index       *)
                         bkColor: LONGINT;           (*  Background color               *)
                         pnColor: LONGINT;           (*  Pen color                      *)
                         pnLoc: GrConst.POINT;       (*  Pen location                   *)
                         pnSize: GrConst.POINT;      (*  Pen size                       *)
                         pnMode: INTEGER;            (*  Pen mode (rasterOp)            *)
                         pnPat: INTEGER;             (*  Pen pattern index              *)
                         pnCap: INTEGER;             (*  Pen end-cap style              *)
                         pnJoin: INTEGER;            (*  Line join style                *)
                         pnDash: INTEGER;            (*  Line dash style                *)
                         pnOffset: INTEGER;          (*  Dash sequence offset           *)
                         pnLevel: INTEGER;           (*  Pen visibility level           *)
                         txFont: adsMem;             (*  Pointer to current font record *)
                         txFace: INTEGER;            (*  Text facing flags              *)
                         txMode: INTEGER;            (*  Text mode (rasterOp)           *)
                         txUnder: INTEGER;           (*  Text underline position        *)
                         txScore: INTEGER;           (*  Text underline scoring         *)
                         txPath: INTEGER;            (*  Text path                      *)
                         txAlign: GrConst.POINT;     (*  Text alignment                 *)
                         txAngle: INTEGER;           (*  Text angle (stroked)           *)
                         txSize: GrConst.POINT;      (*  Text size  (stroked)           *)
                         txSlant: INTEGER;           (*  Text slant (stroked)           *)
                         txExtra: INTEGER;           (*  Text justify bits              *)
                         txSpace: INTEGER;           (*  Space justify bits             *)
                         mkType: INTEGER;            (*  Marker type index              *)
                         mkSize: GrConst.POINT;      (* Marker size                    *)
                         mkAngle: INTEGER;           (*  Marker angle                   *)
                         spare: ARRAY [1..10] OF INTEGER;   (*    (spares)       *)
                        END;
                                                            *)

    METAPORTPTR ,       (* POINTER TO METAPORT;*)

    PUSHAREA ,          (* PUSHGRAFIX/POPGRAFIX savearea
                        RECORD
                         saveArea: ARRAY [1..64] OF CARDINAL;
                        END;
                                                            *)

    cportBMap ,          (* "GetPortField" Index Definitions *)
    cportRect ,
    cportOrgn ,
    cportVirt ,
    cportFlgs ,
    cportClip ,
    cportRgn ,
    cbkPat ,
    cbkColor ,
    cpnColor ,
    cpnLoc ,
    cpnSize ,
    cpnMode ,
    cpnPat ,
    cpnCap ,
    cpnJoin ,
    cpnDash ,
    cpnOffset ,
    cpnLevel ,
    ctxFont ,
    ctxFace ,
    ctxMode ,
    ctxUnder ,
    ctxScore ,
    ctxPath ,
    ctxAlign ,
    ctxAngle ,
    ctxSize ,
    ctxSlant ,
    ctxExtra ,
    ctxSpace ,
    cmkType ,
    cmkSize ,
    cmkAngle ,
    cspare ,

    cxmin ,
    cymin ,
    cxmax ,
    cymax ,
    cX ,
    cY ,
    cseg ,
    coff ;

BEGIN
 InitGrafix(-562);
 SetDisplay(GrafPg0);
 SetDisplay(TextPg0);
 ClearText;
END esmac.