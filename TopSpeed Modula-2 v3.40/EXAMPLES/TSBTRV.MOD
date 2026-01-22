(* Release 3.10 *)
(*-------------------------------------------------------------------------*
*                                                                          *
*  TopSpeed Modula-2 Interface for BTRIEVE - Supports TopSpeed Extender    *
*  Public Domain - May be used without restriction                         *
*                                                                          *
*--------------------------------------------------------------------------*)
IMPLEMENTATION MODULE TSBTRV;
IMPORT SYSTEM,Lib,Str;
(*%T _XTD*)
IMPORT TSXLIB;
(*%E*)

(****************************************************************************)


PROCEDURE BTRV1(fn : CARDINAL);
VAR
    NullControl    : FileControlBlock;
    NullBuffer     : LONGCARD;
    NullBufferSize : CARDINAL;
    NullKey        : KeyType;
BEGIN
    NullBufferSize := SIZE(NullBuffer);
    StatusCode := BTRV(fn,NullControl,NullBuffer,NullBufferSize,NullKey,0);
END BTRV1;

PROCEDURE BTRV2(fn : CARDINAL;VAR FileControl : FileControlBlock);
VAR
    NullBuffer     : LONGCARD;
    NullBufferSize : CARDINAL;
    NullKey        : KeyType;
BEGIN
    NullBufferSize := SIZE(NullBuffer);
    StatusCode := BTRV(fn,FileControl,NullBuffer,NullBufferSize,NullKey,0);
END BTRV2;

PROCEDURE BTRV3(fn : CARDINAL;VAR FileControl : FileControlBlock;Key : SHORTCARD);
VAR
    NullBuffer     : LONGCARD;
    NullBufferSize : CARDINAL;
    NullKey        : KeyType;
BEGIN
    NullBufferSize := SIZE(NullBuffer);
    StatusCode := BTRV(fn,FileControl,NullBuffer,NullBufferSize,NullKey,Key);
END BTRV3;

PROCEDURE BTRV4(fn : CARDINAL;VAR FileControl : FileControlBlock;
                VAR KeyBuffer : ARRAY OF BYTE; Key : SHORTCARD);
VAR
    NullBuffer     : LONGCARD;
    NullBufferSize : CARDINAL;
BEGIN
    NullBufferSize := SIZE(NullBuffer);
    StatusCode := BTRV(fn,FileControl,NullBuffer,NullBufferSize,KeyBuffer,Key);
END BTRV4;

(****************************************************************************)

PROCEDURE AbortTransaction;
BEGIN
    BTRV1(opAbortTrans);
END AbortTransaction;

(****************************************************************************)

PROCEDURE BeginTransaction;
BEGIN
    BTRV1(opBeginTrans);
END BeginTransaction;

(****************************************************************************)

PROCEDURE ClearOwner(VAR FileControl : FileControlBlock);
BEGIN
    BTRV2(opClearOwner,FileControl);
END ClearOwner;

(****************************************************************************)

PROCEDURE Close(VAR FileControl : FileControlBlock);
BEGIN
    BTRV2(opClose,FileControl);
END Close;

(****************************************************************************)

PROCEDURE Create(  VAR FileControl : FileControlBlock;
                   FileDescriptor : ARRAY OF BYTE;
                   DescriptorLength : CARDINAL;
                   FileName : ARRAY OF CHAR);
VAR
    KeyBuffer       : KeyType;
BEGIN
    Str.Copy(KeyBuffer,FileName);
    StatusCode := BTRV(opCreate,FileControl,FileDescriptor,DescriptorLength,KeyBuffer,0);
END Create;

(****************************************************************************)
PROCEDURE DeleteRec(VAR FileControl : FileControlBlock; KeyID : SHORTCARD);
BEGIN
    BTRV3(opDelete,FileControl,KeyID);
END DeleteRec;

(****************************************************************************)

PROCEDURE EndTransaction;
BEGIN
    BTRV1(opEndTrans);
END EndTransaction;

(****************************************************************************)

PROCEDURE Extend(VAR FileControl : FileControlBlock; FileName : ARRAY OF CHAR;
                   UseNow : BOOLEAN);
VAR
    KeyBuffer       : KeyType;
    KeyID           : SHORTCARD;
BEGIN
    Str.Copy(KeyBuffer,FileName);
    IF UseNow THEN KeyID := 255 ELSE KeyID := 0; END;
    BTRV4(opExtend,FileControl,KeyBuffer,KeyID);
END Extend;

(****************************************************************************)

PROCEDURE FindEQ(VAR FileControl : FileControlBlock;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
  BTRV4(opGetEQ+opKeyOnly,FileControl,KeyBuffer,KeyID);
END FindEQ;

(****************************************************************************)

PROCEDURE FindGT(VAR FileControl : FileControlBlock;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
  BTRV4(opGetGT+opKeyOnly,FileControl,KeyBuffer,KeyID);
END FindGT;

(****************************************************************************)

PROCEDURE FindGE(VAR FileControl : FileControlBlock;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
  BTRV4(opGetGE+opKeyOnly,FileControl,KeyBuffer,KeyID);
END FindGE;

(****************************************************************************)

PROCEDURE FindLast(VAR FileControl : FileControlBlock;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
  BTRV4(opGetLast+opKeyOnly,FileControl,KeyBuffer,KeyID);
END FindLast;

(****************************************************************************)

PROCEDURE FindLT(VAR FileControl : FileControlBlock;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
  BTRV4(opGetLT+opKeyOnly,FileControl,KeyBuffer,KeyID);
END FindLT;

(****************************************************************************)

PROCEDURE FindLE(VAR FileControl : FileControlBlock;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
  BTRV4(opGetLE+opKeyOnly,FileControl,KeyBuffer,KeyID);
END FindLE;

(****************************************************************************)

PROCEDURE FindFirst(VAR FileControl : FileControlBlock;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
  BTRV4(opGetFirst+opKeyOnly,FileControl,KeyBuffer,KeyID);
END FindFirst;

(****************************************************************************)

PROCEDURE FindNext(VAR FileControl : FileControlBlock;
                   VAR KeyBuffer : ARRAY OF BYTE;
                   KeyID : SHORTCARD);
BEGIN
  BTRV4(opGetNext+opKeyOnly,FileControl,KeyBuffer,KeyID);
END FindNext;

(****************************************************************************)

PROCEDURE FindPrev(VAR FileControl : FileControlBlock;
                   VAR KeyBuffer : ARRAY OF BYTE;
                   KeyID : SHORTCARD);
BEGIN
  BTRV4(opGetPrev+opKeyOnly,FileControl,KeyBuffer,KeyID);
END FindPrev;

(****************************************************************************)

PROCEDURE GetDirect(VAR FileControl : FileControlBlock;
                    VAR DataBuffer : ARRAY OF BYTE;
                    VAR BufferLength : CARDINAL;
                    VAR KeyBuffer : ARRAY OF BYTE;
                    KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetDirect,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetDirect;

(****************************************************************************)

PROCEDURE GetDir(Drive : SHORTCARD; VAR DirName : ARRAY OF CHAR);
VAR
    NullControl    : FileControlBlock;
BEGIN
    BTRV4(opGetDir,NullControl,DirName,Drive);
END GetDir;

(****************************************************************************)

PROCEDURE GetEQ(VAR FileControl : FileControlBlock;
                VAR DataBuffer : ARRAY OF BYTE;
                VAR BufferLength : CARDINAL;
                VAR KeyBuffer : ARRAY OF BYTE;
                KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetEQ,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetEQ;

(****************************************************************************)

PROCEDURE GetGT(VAR FileControl : FileControlBlock;
                VAR DataBuffer : ARRAY OF BYTE;
                VAR BufferLength : CARDINAL;
                VAR KeyBuffer : ARRAY OF BYTE;
                KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetGT,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetGT;

(****************************************************************************)

PROCEDURE GetGE(VAR FileControl : FileControlBlock;
                VAR DataBuffer : ARRAY OF BYTE;
                VAR BufferLength : CARDINAL;
                VAR KeyBuffer : ARRAY OF BYTE;
                KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetGE,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetGE;

(****************************************************************************)

PROCEDURE GetLast(VAR FileControl : FileControlBlock;
                VAR DataBuffer : ARRAY OF BYTE;
                VAR BufferLength : CARDINAL;
                VAR KeyBuffer : ARRAY OF BYTE;
                KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetLast,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetLast;

(****************************************************************************)

PROCEDURE GetLT(VAR FileControl : FileControlBlock;
                VAR DataBuffer : ARRAY OF BYTE;
                VAR BufferLength : CARDINAL;
                VAR KeyBuffer : ARRAY OF BYTE;
                KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetLT,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetLT;

(****************************************************************************)

PROCEDURE GetLE(VAR FileControl : FileControlBlock;
                VAR DataBuffer : ARRAY OF BYTE;
                VAR BufferLength : CARDINAL;
                VAR KeyBuffer : ARRAY OF BYTE;
                KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetLE,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetLE;

(****************************************************************************)

PROCEDURE GetFirst(VAR FileControl : FileControlBlock;
                VAR DataBuffer : ARRAY OF BYTE;
                VAR BufferLength : CARDINAL;
                VAR KeyBuffer : ARRAY OF BYTE;
                KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetFirst,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetFirst;

(****************************************************************************)

PROCEDURE GetNext(VAR FileControl : FileControlBlock;
                  VAR DataBuffer : ARRAY OF BYTE;
                  VAR BufferLength : CARDINAL;
                  VAR KeyBuffer : ARRAY OF BYTE;
                  KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetNext,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetNext;

(****************************************************************************)

PROCEDURE GetPosition(VAR FileControl :FileControlBlock;
                      VAR pos : ARRAY OF BYTE);
VAR BufferSize : CARDINAL;
    NullKey : KeyType;
BEGIN
    BufferSize := SIZE(pos);
    StatusCode := BTRV(opGetPos,FileControl,pos,BufferSize,NullKey,0);
END GetPosition;

(****************************************************************************)

PROCEDURE GetPrev(VAR FileControl : FileControlBlock;
                  VAR DataBuffer : ARRAY OF BYTE;
                  VAR BufferLength : CARDINAL;
                  VAR KeyBuffer : ARRAY OF BYTE;
                  KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opGetPrev,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END GetPrev;

(****************************************************************************)

PROCEDURE Insert(VAR FileControl : FileControlBlock;
                 VAR DataBuffer : ARRAY OF BYTE;
                 VAR BufferLength : CARDINAL;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opInsert,FileControl,DataBuffer,BufferLength,KeyBuffer,KeyID);
END Insert;

(****************************************************************************)

PROCEDURE Open(VAR FileControl : FileControlBlock;
               FileName,OwnerName : ARRAY OF CHAR;
               OpenMode : SHORTCARD);
VAR
    DataBuffer      : ARRAY [0..7] OF CHAR;
    KeyBuffer       : KeyType;
    BufferLength    : CARDINAL;

BEGIN
    Str.Copy(KeyBuffer,FileName);
    Str.Copy(DataBuffer,OwnerName);
    DataBuffer[7] := 0C;
    BufferLength := Str.Length(DataBuffer) + 1;
    StatusCode := BTRV(opOpen,FileControl,DataBuffer,BufferLength,
                       KeyBuffer,OpenMode);
END Open;

(****************************************************************************)

PROCEDURE Reset;
BEGIN
    BTRV1(opReset);
END Reset;

(****************************************************************************)

PROCEDURE SetDirectory(DirName : ARRAY OF CHAR);
VAR
    KeyBuffer       : KeyType;
    NullControl     : FileControlBlock;
BEGIN
    Str.Copy(KeyBuffer,DirName);
    BTRV4(opSetDir,NullControl,KeyBuffer,0);
END SetDirectory;

(****************************************************************************)

PROCEDURE SetOwner(VAR FileControl : FileControlBlock;
                     OwnerName : ARRAY OF CHAR;
                     AccessMode : SHORTCARD);
VAR
    DataBuffer      : OwnerType;
    KeyBuffer       : KeyType;
    BufferLength    : CARDINAL;

BEGIN
    Str.Copy(DataBuffer,OwnerName);
    Str.Copy(KeyBuffer,OwnerName);
    DataBuffer[7] := 0C;
    BufferLength := Str.Length(DataBuffer) + 1;
    StatusCode := BTRV(opSetOwner,FileControl,DataBuffer,
                         BufferLength,KeyBuffer,AccessMode);
END SetOwner;

(****************************************************************************)

PROCEDURE Status(VAR FileControl : FileControlBlock;
                 VAR DataBuffer : ARRAY OF BYTE;
                 VAR BufferLength : CARDINAL;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opStat,FileControl,DataBuffer,BufferLength,KeyBuffer,0);
END Status;

(****************************************************************************)

PROCEDURE StepDirect(VAR FileControl : FileControlBlock;
                     VAR DataBuffer : ARRAY OF BYTE;
                     VAR BufferLength : CARDINAL);
VAR
    NullKey       : KeyType;
BEGIN
    StatusCode := BTRV(opStepDirect,FileControl,DataBuffer,
                         BufferLength,NullKey,0);
END StepDirect;

(****************************************************************************)

PROCEDURE Stop;
BEGIN
    BTRV1(opStop);
END Stop;

(****************************************************************************)

PROCEDURE Update(VAR FileControl : FileControlBlock;
                 VAR DataBuffer : ARRAY OF BYTE;
                 VAR BufferLength : CARDINAL;
                 VAR KeyBuffer : ARRAY OF BYTE;
                 KeyID : SHORTCARD);
BEGIN
    StatusCode := BTRV(opUpdate,FileControl,DataBuffer,BufferLength,KeyBuffer,0);
END Update;

(****************************************************************************)

PROCEDURE Version(VAR DataBuffer : ARRAY OF BYTE );
VAR
    NullControl    : FileControlBlock;
    BufferSize : CARDINAL;
    NullKey        : KeyType;
BEGIN
    BufferSize := SIZE(DataBuffer);
    StatusCode := BTRV(opVersion,NullControl,DataBuffer,BufferSize,NullKey,0);
END Version;

(****************************************************************************)
(* Low Level Btrieve Call                                                   *)
(****************************************************************************)

VAR
  ProcId: CARDINAL;  (* initialize to no process id *)
  Multi:  BOOLEAN;   (* set to true if BMulti is loaded *)
  VSet:   BOOLEAN;   (* set to true if we have checked for BMulti *)

(*%T _XTD*)

TYPE
  rADDRESS  = LONGCARD;

PROCEDURE RealAlloc(VAR handle : CARDINAL; size : CARDINAL; VAR src : ARRAY OF BYTE):rADDRESS;
(* Needed to copy to Real Memory (i.e. addressable from real mode) *)
VAR csize : CARDINAL;
BEGIN
  IF size=0 THEN handle:=0; RETURN 0 END;
  handle := TSXLIB.ALLOCLOWSEG(size);
  IF Seg(src)<>0 THEN (* copy in *)
    (* protect against buffers that are too short *)
    csize := TSXLIB.GETSEGLIMIT(Seg(src));
    IF (csize>=Ofs(src)) THEN
      DEC(csize,Ofs(src)-1);
      IF (csize=0)OR(csize>size) THEN csize := size END;
      Lib.FastMove(ADR(src),[handle:0],csize);
    END;
  ELSE
    Lib.Fill([handle:0],size,0);
  END;
  RETURN TSXLIB.MAKEREALADDR(handle,0);
END RealAlloc;

PROCEDURE RealFree(handle :CARDINAL; size : CARDINAL; VAR dst : ARRAY OF BYTE);
VAR csize : CARDINAL;
BEGIN
  IF handle=0 THEN RETURN END;
  IF Seg(dst)<>0 THEN (* copy out *)
    (* protect against buffers that are too short *)
    csize := TSXLIB.GETSEGLIMIT(Seg(dst));
    IF (csize>=Ofs(dst)) THEN
      DEC(csize,Ofs(dst)-1);
      IF (csize=0)OR(csize>size) THEN csize := size END;
      Lib.FastMove([handle:0],ADR(dst),csize);
    END;
  END;
  TSXLIB.FREESEG(handle);
END RealFree;

PROCEDURE BTRV ( op: CARDINAL;              (* Operation          *)
                 VAR pos: FileControlBlock; (* Position Block     *)
                 VAR data: ARRAY OF BYTE;   (* Data Buffer        *)
                 VAR datalen: CARDINAL;     (* Data Length        *)
                 VAR kbuf: ARRAY OF BYTE;   (* Key Buffer         *)
                 key: SHORTCARD             (* Key Number         *)

               ): StatusCodes ;             (* Btrieve error code *)

  CONST
    VarID         = 06176H; (* id for variable length records - 'va'*)
    BtrInt        = 07BH;
    Btr2Int       = 02FH;
    BtrOffset     = 00033H;
    MultiFunction = 0AB00H;

  TYPE
    rBtrParms = RECORD
                 UserBufAddr  : rADDRESS;      (* data buffer address *)
                 UserBufLen   : CARDINAL;      (* data buffer length *)
                 UserCurAddr  : rADDRESS;      (* currency block address *)
                 UserFCBAddr  : rADDRESS;      (* file control block address *)
                 UserFunction : CARDINAL;      (* Btrieve operation *)
                 UserKeyAddr  : rADDRESS;      (* key buffer address *)
                 UserKeyLength: SHORTCARD;     (* key buffer length *)
                 UserKeyNumber: SHORTCARD;     (* key number *)
                 UserStatAddr : rADDRESS;      (* return status address *)
                 xFaceID      : CARDINAL;      (* language interface id *)
               END;
  VAR
    Stat: CARDINAL;  (* Btrieve status code *)
    Params: rBtrParms; (* Btrieve parameter block *)
    r: SYSTEM.Registers;    (* register structure used on interrrupt call *)
    DataSel,PosSel,KeySel,StatSel,ParamSel : CARDINAL;
    rParams : rADDRESS;
BEGIN
  Lib.Fill(ADR(r),SIZE(r),0);
  r.AX:= 03500H + BtrInt;
  TSXLIB.REALINTR(ADR(r), 21H);  (* NB using Lib.Intr will return
                                            prot mode address *)
  IF r.BX # BtrOffset THEN (* make sure Btrieve is installed *)
    RETURN BtrieveAbsent
  END;
  IF NOT VSet THEN (* if we haven't checked for Multi-User version *)
    r.AX:= 03000H;
    Lib.Intr(r, 021H);
    IF r.AL >= 3 THEN (* DOS version >= 3.0 *)
      VSet:= TRUE;
      r.AX:= MultiFunction;
      Lib.Intr(r, Btr2Int);
      Multi:= r.AL = 4DH   (* ORD('M') *)
    ELSE
      Multi:= FALSE
    END
  END; (* make normal btrieve call *)
  IF datalen > HIGH(data)+1 THEN datalen:= HIGH(data)+1 END;
  WITH Params DO
    UserBufAddr := RealAlloc(DataSel,datalen,data); (* set data buffer address *)
    UserBufLen := datalen;                          (* set length *)
    UserFCBAddr := RealAlloc(PosSel,38+90,pos);     (* set FCB address*)
    UserCurAddr := UserFCBAddr+38;
    UserFunction := op;                             (* set Btrieve operation code *)
    UserKeyAddr := RealAlloc(KeySel,255,kbuf);      (* set key buffer address *)
    UserKeyLength := 255;
    UserKeyNumber := key;                           (* set key number *)
    UserStatAddr := RealAlloc(StatSel,SIZE(Stat),Stat);;
    xFaceID      := VarID;                          (* set language id *)
  END;
  rParams := RealAlloc(ParamSel,SIZE(Params),Params);
  r.DX := CARDINAL(rParams);
  r.DS := CARDINAL(rParams>>16);
  IF NOT Multi THEN  (* MultiUser version not installed *)
    TSXLIB.REALINTR(ADR(r), BtrInt); (* passing real addresses *)
  ELSE
    LOOP
      r.BX:= ProcId;
      IF r.BX # 0 THEN r.AX:= 2 ELSE r.AX:= 1 END;
      INC(r.AX, MultiFunction);
      Lib.Intr(r, Btr2Int);
      IF r.AL = 0 THEN EXIT END;
      r.AX:= 200H;
      TSXLIB.REALINTR(ADR(r), 07FH); (* passing real addresses *)
    END;
    IF ProcId = 0 THEN ProcId:= r.BX END
  END;
  RealFree(ParamSel,SIZE(Params),Params);
  RealFree(DataSel,datalen,data);
  RealFree(PosSel,38,pos);
  RealFree(KeySel,255,kbuf);
  RealFree(StatSel,SIZE(Stat),Stat);
  datalen:= Params.UserBufLen;
  RETURN StatusCodes(Stat);
END BTRV;

(*%E*)

(*%F _XTD*)


PROCEDURE BTRV ( op: CARDINAL;              (* Operation          *)
                 VAR pos: FileControlBlock; (* Position Block     *)
                 VAR data: ARRAY OF BYTE;   (* Data Buffer        *)
                 VAR datalen: CARDINAL;     (* Data Length        *)
                 VAR kbuf: ARRAY OF BYTE;   (* Key Buffer         *)
                 key: SHORTCARD             (* Key Number         *)
               ): StatusCodes ;             (* Btrieve error code *)
  CONST
    VarID         = 06176H; (* id for variable length records - 'va'*)
    BtrInt        = 07BH;
    Btr2Int       = 02FH;
    BtrOffset     = 00033H;
    MultiFunction = 0AB00H;

  TYPE
    BtrParms = RECORD
                 UserBufAddr  : ADDRESS;      (* data buffer address *)
                 UserBufLen   : CARDINAL;     (* data buffer length *)
                 UserCurAddr  : ADDRESS;      (* currency block address *)
                 UserFCBAddr  : ADDRESS;      (* file control block address *)
                 UserFunction : CARDINAL;     (* Btrieve operation *)
                 UserKeyAddr  : ADDRESS;      (* key buffer address *)
                 UserKeyLength: SHORTCARD;    (* key buffer length *)
                 UserKeyNumber: SHORTCARD;    (* key number *)
                 UserStatAddr : ADDRESS;      (* return status address *)
                 xFaceID      : CARDINAL;     (* language interface id *)
               END;
  VAR
    Stat: CARDINAL;  (* Btrieve status code *)
    XData: BtrParms; (* Btrieve parameter block *)
    r: SYSTEM.Registers;    (* register structure used on interrrupt call *)

BEGIN
  r.AX:= 03500H + BtrInt;
  Lib.Intr(r, 021H);
  IF r.BX # BtrOffset THEN (* make sure Btrieve is installed *)
    RETURN BtrieveAbsent
  END;
  IF NOT VSet THEN (* if we haven't checked for Multi-User version *)
    r.AX:= 03000H;
    Lib.Intr(r, 021H);
    IF r.AL >= 3 THEN (* DOS version >= 3.0 *)
      VSet:= TRUE;
      r.AX:= MultiFunction;
      Lib.Intr(r, Btr2Int);
      Multi:= r.AL = 4DH   (* ORD('M') *)
    ELSE
      Multi:= FALSE
    END
  END; (* make normal btrieve call *)
  IF datalen > HIGH(data)+1 THEN datalen:= HIGH(data)+1 END;
  WITH XData DO
    UserBufAddr  := ADR(data);        (* set data buffer address *)
    UserBufLen   := datalen;          (* set length *)
    UserFCBAddr  := ADR(pos);         (* set FCB address*)
    UserCurAddr  := ADR(pos[38]);
    UserFunction := op;               (* set Btrieve operation code *)
    UserKeyAddr  := ADR(kbuf);        (* set key buffer address *)
    UserKeyLength := 255;
    UserKeyNumber:= key;              (* set key number *)
    UserStatAddr := ADR(Stat);        (* set status address *)
    xFaceID      := VarID;            (* set language id *)
  END;
  r.DX:= SYSTEM.Ofs(XData);
  r.DS:= SYSTEM.Seg(XData);
  IF NOT Multi THEN  (* MultiUser version not installed *)
    Lib.Intr(r, BtrInt)
  ELSE
    LOOP
      r.BX:= ProcId;
      IF r.BX # 0 THEN r.AX:= 2 ELSE r.AX:= 1 END;
      INC(r.AX, MultiFunction);
      Lib.Intr(r, Btr2Int);
      IF r.AL = 0 THEN EXIT END;
      r.AX:= 200H;
      Lib.Intr(r, 07FH)
    END;
    IF ProcId = 0 THEN ProcId:= r.BX END
  END;
  datalen:= XData.UserBufLen;
  RETURN StatusCodes(Stat);
END BTRV;
(*%E*)

BEGIN
  VSet  := FALSE;
  Multi := FALSE;
  ProcId:= 0;
END TSBTRV.
