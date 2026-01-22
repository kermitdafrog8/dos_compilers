IMPLEMENTATION MODULE Loader;
IMPORT SYSTEM,LoaderA;
FROM LoaderA          IMPORT MoveUp,MainName;

(*# data(const_in_code=>off) *)
(*# call(o_a_copy=>off,o_a_size=>off) *)
(*# call(seg_name=>null) *)
(*# data(near_ptr=>off,threshold=>0FFFFH) *)
(*#call(inline_max=>1000)*)
(*# call(near_call=>off,overlay=>on) *)

(* limits *)
CONST
  MaxName             = 80;          (* size of module name *)
  MaxSeg              = 255;         (* number of segments in a module *)
  MaxEntry            = 1000;        (* number of entry points in a module *)
  MaxModule           = 64;          (* number of modules *)
  MaxGate             = 2000;
  HeapSize            = 6000H;
  FileLimit           = 10; (* open file limit (temp file not included) *)
  TempLimit           = 8*100000H; (* 8 Megabytes *)
  TempPageShift       = 10;
  TempPageSize        = 1 << TempPageShift;
(*%T EMS*)
CONST EmsPageSize = 4000H DIV TempPageSize;
(*%E*)
CONST PanicSize = 8000H;

TYPE  SegKind = (StaticSeg, SwapSeg, MoveSeg, FixedSeg, SystemSeg);
TYPE  SegKindSet = SET OF SegKind;

(* tracing controls *)
CONST
  MemoryTrace     = FALSE;
  LoadTrace       = FALSE;
  ExitTrace       = FALSE;
  MemTraceSet     = SegKindSet{ StaticSeg, SwapSeg, MoveSeg, FixedSeg};
  UsageTrace      = FALSE;
  OutOfMemTrace   = FALSE;
  MoveTrace       = FALSE;
  Debuging        = FALSE;
  GraphUseTrace   = FALSE;
  TraceToFile     = FALSE;

(* emergency tracing *)
CONST
  LockTrace       = FALSE;
  FileTrace       = FALSE;
  CallTrace       = FALSE;
  EntryTableTrace = FALSE;
  RelocateTrace   = FALSE;

(* error messages *)

  ErrBase          = 8500;

  ErrOutOfMem      = 0;
  ErrTempFileLimit = 1;
  ErrLoad          = 2;
  ErrPoolLimit     = 3;
  ErrGateLimit     = 4;
  ErrTempDiskFull  = 5;
  ErrDiskFull      = 6;
  ErrTempCreate    = 7;
  ErrInternal      = 8;
  ErrNearHeap      = 9;
  ErrModuleLimit   = 10;
  ErrInvalidProcedure = 11;
  ErrMemoryCorruption = 12;
  ErrTooManyUnlocks   = 13;
  ErrCallChainInvalid = 14;
  ErrOpenFail         = 15;
  ErrNamedImport      = 16;
  ErrInvalidVUnfix    = 17;
  ErrInvalidVFix      = 18;
  ErrInvalidFree      = 19;



(*-----------------------------------------------------------------------*)
(* low level file handling *)
(*-----------------------------------------------------------------------*)
(*# save,call(same_ds=>off) *)
(*# call(near_call=>on) *)
(*# call(reg_param=>(bx, dx, cx), reg_saved=>(ds, di, si, st1, st2)) *)
PROCEDURE FileSeek(h:CARDINAL;pos:LONGCARD); IN LoaderA;
(*# call(reg_param=>(dx, ax, cx, bx), reg_saved=>(ds, di, si, st1, st2)) *)
PROCEDURE FileRead(a:ADDRESS;count:CARDINAL;h:CARDINAL); IN LoaderA;
PROCEDURE FileWrite(a:ADDRESS;count:CARDINAL;h:CARDINAL):CARDINAL; IN LoaderA;
(*# call(reg_param=>(bx), reg_saved=>(ds, di, si, st1, st2)) *)
PROCEDURE FileClose(h:CARDINAL); IN LoaderA;
(*# call(reg_param=>(ax,bx,cx,dx,si)) *)
PROCEDURE Exec(psp,ss,sp,cs,ip:CARDINAL); IN LoaderA;
(*# call(reg_param=>(dx, bx, ax), reg_saved=>(ds, di, si, st1, st2)) *)
PROCEDURE FileOpen(name:ARRAY OF CHAR;mode:BITSET):CARDINAL; IN LoaderA;
PROCEDURE DosExit; IN LoaderA;
PROCEDURE FileDelete(name:ARRAY OF CHAR); IN LoaderA;
PROCEDURE FileCreate(name:ARRAY OF CHAR):CARDINAL; IN LoaderA;
PROCEDURE FileCreateNew(VAR name : ARRAY OF CHAR):CARDINAL; IN LoaderA;
(*# call(reg_param=>(bx), reg_saved=>(ds, di, si, st1, st2)) *)
PROCEDURE FileSize(h:CARDINAL):LONGCARD; IN LoaderA;
(*# restore *)



  TYPE
    ModNum              = [1..MaxModule];
    SegNum              = CARDINAL;
    DoSegOp             = (Load,Swap,Discard);

TYPE HeapADDR = SHORTADDR;
CONST HeapAdr ::= Ofs;

(*# data(near_ptr=>on) *)

CONST FreeGate     = 0;
CONST DeletedGate  = 1;
CONST IndirectGate = 0E8H; (* call near *)
CONST DirectGate   = 0EAH; (* jump far *)

  TYPE
    GatePtr             = POINTER TO GateRec;
    GateRec             = RECORD
                            state      : SHORTCARD;
                            w1         : CARDINAL;
                            w2         : CARDINAL;
                            next_direct: GatePtr;
                          END; (*GateRec*)
  (* bits for Seghdr.flags *)
    SegAttr             = (IsData,Typ2,Typ3,IsIter,IsMove,IsPure,IsPreLoad,IsExRd,
                           HasReloc,Iop1,Iop2,Iop3,IsDiscard,Is32,IsHuge,DataActive);
    SegSet              = SET OF SegAttr;
    SegPtr              = POINTER TO SegRec;
    SegRec              = RECORD
                            no_op      : SHORTCARD; (* 090H return gates point here *)
                            jump_op    : SHORTCARD; (* 0E9H call gates point here *)
                            jump_disp  : CARDINAL;  (* jumps to GateHandler *)
                            seg_val    : CARDINAL;
                            direct_list: GatePtr;
                            fix_count  : CARDINAL;
                          (* last four fields are read straight from file *)
                            sector     : CARDINAL;
                            filebyte   : CARDINAL;
                            flags      : SegSet;
                            membyte    : CARDINAL;
                          END; (*SegRec*)
    ModStage            = (initial_stage,internal_stage,sub_module_stage,execute_stage);
    EntryRec            = RECORD
                            seg        : SHORTCARD;
                            ofs        : CARDINAL;
                          END; (*EntryRec*)
    Module = POINTER TO ModuleRec;
    ModuleRec           = RECORD
                            file       : CARDINAL;
                            seg_count  : CARDINAL;
                            log_sector_size : CARDINAL;
                            stage      : ModStage;
                            is_exe     : BOOLEAN;
                            name       : POINTER TO ARRAY[0..MaxName] OF CHAR;
                            seg_info   : POINTER TO ARRAY[1..MaxSeg] OF SegRec;
                            entry_table: POINTER TO ARRAY[1..MaxEntry] OF EntryRec;
                            module_table:POINTER TO ARRAY[1..MaxModule] OF SHORTCARD;
                          END; (*ModuleRec*)
(*# data(near_ptr=>off) *)
    LoadState           = RECORD
(*%T Debuging*)
                            trap_seg   : SegNum;   (* for debugging *)
                            trap_mod   : ModNum;   (* for debugging *)
                            trap_off   : CARDINAL; (* for debugging *)
                            trap_alloc : CARDINAL;
(*%E*)
(*%T MemoryTrace*)                     (* don't trace internal operations *)
                            internal   : BOOLEAN;
(*%E*)
                            psp        : CARDINAL;
                            stk        : CARDINAL;
                            module_count:CARDINAL;
                            abort      : ExitHandler;
                            OutOfMem   : MemHandler;
                            file_count : INTEGER;
                            near_alloc : CARDINAL;
                            start      : CARDINAL; (* start of memory *)
                            end        : CARDINAL; (* last para of normal (not ems) memory *)
                            freemem    : CARDINAL;
                            allockind  : SegKind;
                            panic_reserve:CARDINAL;
                            temp_file  : CARDINAL;
                            temp_reserve:LONGINT;
                            temp_ems   : CARDINAL; (* number of temp pages mapped into ems *)
                            temp_map   : ARRAY [0..TempLimit DIV (8*SIZE(BITSET)*TempPageSize)] OF BITSET;
(*%T ExitTrace *)
                            temp_max   : CARDINAL;
(*%E*)
(*%T MoveTrace *)
                            move_total : LONGCARD;
(*%E*)
                            ems_frame  : CARDINAL;
(*%T EMS*)
                            ems_present: BOOLEAN;
                            ems_count  : CARDINAL;
                            ems_temp_handle:CARDINAL;
                            ems_data_handle:CARDINAL;
(*%E*)
                            module_list: ARRAY ModNum OF Module;
                            delay      : ModNum;
                            gate_count : CARDINAL;
                            gate_table : ARRAY [1..MaxGate] OF GateRec;
(*%T VidSupport*)
                            vid_present: BOOLEAN;
                            vid_delayed: BOOLEAN;
                            vid_id1,
                            vid_id2    : CARDINAL;
(*%E*)
                            heap       : ARRAY [1..HeapSize] OF SHORTCARD;
                            Tick       : CARDINAL;
                          END; (*LoadState*)

TYPE A1 = SHORTCARD;
TYPE A2 = ARRAY [1..2] OF SHORTCARD;
TYPE A4 = ARRAY [1..4] OF SHORTCARD;
TYPE A6 = ARRAY [1..6] OF SHORTCARD;
TYPE A7 = ARRAY [1..7] OF SHORTCARD;
TYPE A8 = ARRAY [1..8] OF SHORTCARD;
TYPE A9 = ARRAY [1..9] OF SHORTCARD;
TYPE A12= ARRAY [1..12] OF SHORTCARD;
TYPE A13= ARRAY [1..13] OF SHORTCARD;



TYPE
   HandlerRec = RECORD
     b01,b02,b03,b04:SHORTCARD;
     OffsetShift:SHORTCARD;
     b11,b12,b13,b14,b15,b16,b17:SHORTCARD;
     PageDisp:CARDINAL;
     b21,b22,b23,b24:SHORTCARD;
     MemStart:CARDINAL;
     b25,b26,b27,b28:SHORTCARD;
     MemEnd:CARDINAL;
     b29,b30,b31,b32:SHORTCARD;
     EmsStart:CARDINAL;
     b33,b34,b35,b36:SHORTCARD;
     EmsEnd:CARDINAL;
     b37:A8;b38:CARDINAL; b39:A4; b40:CARDINAL; b41:A12;
     OffsetMask:BITSET;
     b42:SHORTCARD;
     BlankShift:SHORTCARD;
     b5:A13;
     QFix:ADDRESS;
     b61,b62,b63:SHORTCARD;
   END;

CONST
  MaxPage             = 1024;


TYPE
  WP                  = POINTER TO CARDINAL;
  ParaRec             = RECORD
                          Size       : CARDINAL;    (* Size in paragraphs of alloc    *)
                          Used       : CARDINAL;    (* Paragraphs currently in use    *)
                          Prev       : CARDINAL;    (* Previous ParaRec Segment       *)
                          Active     : BOOLEAN;
                          Kind       : SegKind;     (* Kind of segment                *)
                          Id1,Id2    : CARDINAL;
                          Lock       : CARDINAL;    (* Segment Locked in memory       *)
                          Tick       : CARDINAL;    (* LRU Tick Count                 *)
                        END; (*ParaRec*)
  T                   = POINTER TO ParaRec;

CONST H = (SIZE(ParaRec)+15) DIV 16; (* overhead in paragraphs *)


CONST loader_name = 'LOADER';

TYPE  t_loader_hdr = ARRAY [1..1] OF SegRec;
CONST loader_hdr = t_loader_hdr(
        SegRec(90H, 0E9H, 0, 0, GatePtr(0), 0, 0, 0, SegSet{IsPreLoad}, 0)
     );

    Entries             = 34;

TYPE  t_loader_entry = ARRAY [1..Entries] OF EntryRec;
(* N.B. this has to be consistent with loader.exp *)
CONST loader_entry = t_loader_entry (
        EntryRec(1,Ofs(LoadModule)),
        EntryRec(1,Ofs(UnLoadModule)),
        EntryRec(1,Ofs(GetProcAddr)),
        EntryRec(1,Ofs(ShrinkHeap)),
        EntryRec(1,Ofs(GrowHeap)),
        EntryRec(1,Ofs(UserFlush)),
        EntryRec(1,Ofs(InvalidProc)),
        EntryRec(1,Ofs(InvalidProc)),
        EntryRec(1,Ofs(AllocMem)),
        EntryRec(1,Ofs(ClearAllocMem)),
        EntryRec(1,Ofs(HugeAllocMem)),
        EntryRec(1,Ofs(FreeMem)),
        EntryRec(1,Ofs(SetExitHandler)),
        EntryRec(1,Ofs(SetMemHandler)),
        EntryRec(1,Ofs(InvalidProc)),
        EntryRec(1,Ofs(LoadSeg)),
        EntryRec(1,Ofs(UnloadSeg)),
        EntryRec(1,Ofs(Terminate)),
        EntryRec(1,Ofs(InvalidProc)),
        EntryRec(1,Ofs(RetGate)),
        EntryRec(1,Ofs(Avail)),
        EntryRec(1,Ofs(TotalAvail)),
        EntryRec(1,Ofs(SetEms)),
        EntryRec(1,Ofs(Getseg)),
        EntryRec(1,Ofs(ExpandMem)),
        EntryRec(1,Ofs(HugeExpandMem)),
        EntryRec(1,Ofs(HeapWalk)),
        EntryRec(1,Ofs(HeapCheck)),
        EntryRec(1,Ofs(GetOrdProcAddr)),
        EntryRec(1,Ofs(VAlloc)),
        EntryRec(1,Ofs(VUnfix)),
        EntryRec(1,Ofs(VFix)),
        EntryRec(1,Ofs(VUnfixAll)),
        EntryRec(1,Ofs(VFree))
     );

VAR g:LoadState;

CONST loader_module = ModuleRec (
        MAX(CARDINAL),
        2,
        0,
        execute_stage,
        FALSE, (* not exe *)
        HeapADDR(HeapAdr(loader_name)),
        HeapADDR(HeapAdr(loader_hdr)),
        HeapADDR(HeapAdr(loader_entry)),
        HeapADDR(0)
     );



(*-----------------------------------------------------------------------*)
(* inline functions *)
(*-----------------------------------------------------------------------*)
(*# save, call(inline=>on, same_ds=>off) *)
(*# call(reg_saved=>(bx,cx,dx,si,di,ds,es,st1,st2)) *)
INLINE PROCEDURE GetBP():CARDINAL = A2(89H, 0E8H); (* mov ax,bp *)
INLINE PROCEDURE GetSP():CARDINAL = A2(89H, 0E0H); (* mov ax,sp *)
INLINE PROCEDURE Int3() = A1(0CCH);
INLINE PROCEDURE Int66() = A2(0CDH,066H); (* used to enter symdeb *)
(*# call(reg_param=>(si,ax,di,es,cx), reg_saved=>(bx,dx,ds,st1,st2)) *)
INLINE PROCEDURE Move(fr,to : ADDRESS; count : CARDINAL)=
A12(1EH,8EH,0D8H,0D1H,0E9H,0F3H,0A5H,013H,0C9H,0F3H,0A4H,1FH);
(* push ds; mov ds,ax; shr cx,1; rep; movsw; adc cx,cx; rep; movsb; pop ds *)
(*# call(reg_param=>(di,es,cx,ax), reg_saved=>(bx,dx,si,ds,st1,st2)) *)
INLINE PROCEDURE Fill(a:ADDRESS;count:CARDINAL;w:CARDINAL) = A7(0D1H,0E9H,0F3H,0ABH,073H,001H,0AAH);
(*# call(reg_param=>(dx,si,ax)) *)
INLINE PROCEDURE GetCurDir (drive : SHORTCARD;VAR p : ARRAY OF CHAR) =
A8(1EH, 8EH,0D8H, 0B4H,47H, 0CDH,21H, 1FH);
(* push ds; mov ds,ax; mov ah,47H; int 21H; pop ds *)
(*# call(reg_return=>(ax)) *)
INLINE PROCEDURE GetCurDrive():SHORTCARD = A4(0B4H,19H, 0CDH,21H); (* mov ah, 19H; int 21H *)
(*%T EMS*)
(* Ems support *)
(*# call(reg_param=>(ax,bx,dx), reg_saved =>(si,di,ds,st1,st2)) *)
INLINE PROCEDURE EmsTest(ax:CARDINAL):CARDINAL = A2(0CDH,67H);
INLINE PROCEDURE EmsMap(ax:CARDINAL;bx:CARDINAL;dx:CARDINAL) = A2(0CDH,67H);
(*# call(reg_return=>(bx)) *)
INLINE PROCEDURE EmsGet(ax:CARDINAL):CARDINAL = A2(0CDH,67H);
(*# call(reg_return=>(dx)) *)
INLINE PROCEDURE EmsAlloc(ax:CARDINAL;bx:CARDINAL):CARDINAL = A2(0CDH,67H);
(*%E*)
(*# call(reg_param=>(dx,ax)) *)
INLINE PROCEDURE Out (p:CARDINAL;v:SHORTCARD)=SHORTCARD(0EEH);
INLINE PROCEDURE DI()=SHORTCARD(0FAH);
INLINE PROCEDURE EI()=SHORTCARD(0FBH);
(*# restore *)
INLINE PROCEDURE GetTick():CARDINAL;
BEGIN
  RETURN g.Tick;
END GetTick;
INLINE PROCEDURE IncTick():CARDINAL;
BEGIN
  INC(g.Tick);
  RETURN g.Tick;
END IncTick;



(* tracing *)

(*%T TraceToFile*) VAR output_file  : CARDINAL; (*%E*)
(*%F TraceToFile*) CONST output_file = 1; (*%E*)

PROCEDURE string(s: ARRAY OF CHAR);
VAR i:CARDINAL;
BEGIN
  i := 0;
  WHILE s[i]#0C DO
    INC(i);
  END;
  i := FileWrite(ADR(s), i, output_file);
END string;

PROCEDURE eol;
CONST CRLF = CHAR(13) + CHAR(10);
VAR i:CARDINAL;
    p:LONGCARD;
BEGIN
  i := FileWrite(ADR(CRLF), 2, output_file);
END eol;

PROCEDURE char(c: CHAR);
VAR i:CARDINAL;
BEGIN
  i := FileWrite(ADR(c), 1, output_file);
END char;

PROCEDURE hex(n: CARDINAL);
CONST dig = '0123456789ABCDEF';
VAR buf:ARRAY [0..3] OF CHAR;
    i:CARDINAL;
BEGIN
  FOR i := 0 TO 3 DO
    buf[3-i] := dig[n MOD 16];
    n := n DIV 16;
  END;
  i := FileWrite(ADR(buf), 4, output_file);
END hex;

PROCEDURE dec(n: CARDINAL);
VAR div:CARDINAL;
BEGIN
  div := n DIV 10;
  IF div#0 THEN
    dec(div);
  END;
  char('0' + CHAR(n MOD 10));
END dec;

(*%T GraphUseTrace*)
TYPE graphsegrec = RECORD
                     seg   : CARDINAL;
                     pos    : CARDINAL;
                     lasttick  : CARDINAL;
                   END;
VAR graphsegs : ARRAY[1..300] OF graphsegrec;
TYPE GTmode = (GTadd,GTdel,GTlru);
PROCEDURE GraphTrace(seg  : CARDINAL;
                     pos  : CARDINAL;
                     mode : GTmode);
VAR i,j,s,segm : CARDINAL;
    c : CHAR;

BEGIN
(*  IF NOT(4 IN BITSET([40H:17H T]^)) THEN RETURN END; *)
  hex([40H:6CH]^);
  char(' ');
  CASE mode OF
  |GTadd: char('¯');
  |GTdel: char('®');
  |GTlru: char(' ');
  END;
  IF mode=GTlru THEN string('flush ');hex(pos);
  ELSE
    char(' ');
    hex(seg);
    char(' ');hex([pos-1:0 T]^.Used);
  END;
  char(' ');
  j := HIGH(graphsegs);
  WHILE (j>0)AND(graphsegs[j].seg=0)DO DEC(j); END;
  IF j<HIGH(graphsegs) THEN INC(j); END;
  FOR i := 1 TO j DO
    s := graphsegs[i].seg;
    IF (s=0)OR((s=seg)AND(mode=GTadd)) THEN
      IF mode=GTadd THEN
        graphsegs[i].seg := seg;
        graphsegs[i].pos := pos;
        graphsegs[i].lasttick := [pos-1:0 T]^.Tick;
        c := '¸';
        mode := GTlru;
      ELSE
        c := ' ';
      END;
    ELSIF (s=seg)AND(mode=GTdel) THEN
      c := '¾';
      graphsegs[i].pos := 0;
    ELSE
      IF graphsegs[i].pos=0 THEN
        c := ' ';
      ELSE
        segm := SegPtr(HeapAdr(g.module_list[s DIV 256]^.seg_info^[s MOD 256]))^.seg_val;
        IF graphsegs[i].pos<>segm THEN
          graphsegs[i].pos := segm;
          c := 'Æ';
        ELSIF graphsegs[i].lasttick <> [graphsegs[i].pos-1:0 T]^.Tick THEN
          graphsegs[i].lasttick := [graphsegs[i].pos-1:0 T]^.Tick;
          c := 'Ã';
        ELSE
          c := '³';
        END;
      END;
    END;
    char(c);
  END;
  eol;
END GraphTrace;
(*%E*)


PROCEDURE DumpMemory; FORWARD;
PROCEDURE DumpSegName(seg:CARDINAL);FORWARD;

PROCEDURE release_panic; FORWARD;
(*#save,call(reg_param=>())*)
PROCEDURE abort(errno:SHORTCARD);
(*#restore*)

TYPE
  fp                = POINTER Seg(errno) TO RECORD
                                               bp,ip,cs: CARDINAL;
                                             END; (*fp*)
VAR
  bp                : fp;
  cs,i              : CARDINAL;
  res               : BOOLEAN;
BEGIN
(*%T TraceToFile*)
  DumpMemory;
(*%E*)
  release_panic;
(*%T CHECK*)
  eol;
  bp  := fp(GetBP());
  i := 0;
  LOOP
    IF (bp = fp(0))OR(i=10) THEN EXIT END;
    INC(i);
    hex(CARDINAL(bp));string('  ');hex(bp^.ip);string('  ');DumpSegName(bp^.cs);eol;
    IF (bp^.bp=0) THEN
      EXIT;
    ELSIF bp^.bp <= CARDINAL(bp) THEN
      EXIT
    END; (*IF*)
    bp := fp(bp^.bp);
  END;
(*%E*)
  g.abort(g.module_list[1]^.name^,ErrBase+CARDINAL(errno));
  Terminate;
  DosExit;
END abort;

PROCEDURE is_mem(seg:CARDINAL):BOOLEAN;
BEGIN
  RETURN ((seg >= g.start) & (seg < g.end))
(*%T EMS*)
         OR ((seg >= g.ems_frame) & (seg < g.ems_frame + 1000H))
(*%E*)
         ;
END is_mem;

PROCEDURE encode_temp(i:CARDINAL):CARDINAL;
BEGIN
  IF g.ems_frame < g.start THEN
    IF i >= g.ems_frame THEN
      INC(i, 1000H);
    END;
  END;
  IF i >= g.start THEN
    INC(i, g.end - g.start);
  END;
  IF g.ems_frame > g.start THEN
    IF i >= g.ems_frame THEN
      INC(i, 1000H);
    END;
  END;
  (*%T CHECK*) IF (i=0) OR is_mem(i) THEN abort(ErrTempFileLimit) END; (*%E*)
  RETURN i;
END encode_temp;

PROCEDURE decode_temp(i:CARDINAL):CARDINAL;
BEGIN
  IF g.ems_frame > g.start THEN
    IF i >= g.ems_frame THEN
      DEC(i,1000H);
    END;
  END;
  IF i >= g.start THEN
    DEC(i, g.end - g.start);
  END;
  IF g.ems_frame < g.start THEN
    IF i >= g.ems_frame THEN
      DEC(i, 1000H);
    END;
  END;
  RETURN i;
END decode_temp;

(*%T CHECK *)
PROCEDURE CheckAlloc(seg:CARDINAL;err : CARDINAL);
(* checks that block is a valid allocated segment *)
BEGIN
  DEC(seg, H);
  WITH [seg:0 T]^ DO
    IF (seg < g.start) OR
       (Kind > MAX(SegKind)) OR
       (Used > Size) OR
       (Prev + [Prev:0 T]^.Size # seg) OR
       ([seg+Size:0 T]^.Prev # seg) THEN
      IF err=0 THEN
        abort(ErrMemoryCorruption);
      ELSE
        abort(SHORTCARD(err));
      END;
    END; (*IF*)
  END; (*WITH*)
END CheckAlloc;

PROCEDURE CalcFreeMem():CARDINAL;
VAR
  res,p             : CARDINAL;
BEGIN
  res := 0;
  p := g.start;
  REPEAT
    WITH [p:0 T]^ DO
      INC(res,Size - Used);
      INC(p,Size);
    END; (*WITH*)
  UNTIL p = g.start;
  RETURN res;
END CalcFreeMem;

PROCEDURE CheckMem;
VAR
  p                 : CARDINAL;
BEGIN
  p := g.start;
  REPEAT
    CheckAlloc(p+H,0);
    INC(p,[p:0 T]^.Size);
  UNTIL p = g.start;
  IF CalcFreeMem() # g.freemem THEN
    abort(ErrInternal);
  END; (*IF*)
END CheckMem;

(*%E*)

(*%F CHECK*) INLINE (*%E*) PROCEDURE Locked(w:CARDINAL):BOOLEAN;
BEGIN
  RETURN ([w-H:0 T]^.Lock # 0);
END Locked;

PROCEDURE SwapMove(VAR seg:CARDINAL);
BEGIN
  IF is_mem(seg) THEN
(*%T CHECK*)
    CheckAlloc(seg,0);
(*%E*)
    WITH [seg-H:0 T]^ DO
(*%T CHECK*)
      IF Kind # MoveSeg THEN
        abort(ErrInternal);
      END;
(*%E*)
      Kind := SwapSeg;
      Tick := IncTick();
    END; (*WITH*)
  END; (*IF*)
END SwapMove;

PROCEDURE DumpLockedStatics;
VAR
  modnum:ModNum;
  segnum:SegNum;
  module:Module;
  segment:CARDINAL;
BEGIN
  string('Locked static segments '); eol;
  FOR modnum := 1 TO g.module_count DO
    module := g.module_list[modnum];
    string(module^.name^);
    string(' : ');
    FOR segnum := 1 TO module^.seg_count DO
      segment := module^.seg_info^[segnum].seg_val;
      IF is_mem(segment) THEN
        WITH [segment-H:0 T]^ DO
          IF Lock<>0 THEN
            dec(segnum);
            char('(');
            dec(Lock);
            char(')');
            char(' ');
          END
        END;
      END;
    END;
    eol;
  END;
END DumpLockedStatics;

PROCEDURE DumpSegKind(kind:SegKind);
BEGIN
  CASE kind OF
  | StaticSeg: string('sta');
  | SwapSeg:   string('swa');
  | MoveSeg:   string('mov');
  | FixedSeg:  string('fix');
  | SystemSeg:  string('sys');
  END;
END DumpSegKind;

PROCEDURE DumpSegName(seg:CARDINAL);
BEGIN
  WITH [seg-H:0 T]^ DO
    CASE Kind OF
    | StaticSeg:
      string(g.module_list[Id1]^.name^);
      char('.');
      hex(Id2);
    | SwapSeg:
      DumpSegName(Id2); char(':'); hex(Id1);
    | MoveSeg:
      DumpSegName(Id2); char(':'); hex(Id1);
    ELSE
      hex(seg);
    END;
  END;
END DumpSegName;

PROCEDURE DumpSeg(s:ARRAY OF CHAR;seg:CARDINAL);
BEGIN
  string(s);
  WITH [seg-H:0 T]^ DO
    hex(seg);
    (*string(' Size='); hex(Size);*)
    string(' Used='); hex(Used);
    (*string(' Prev='); hex(Prev);*)
    string(' Free='); hex(Size-Used);
    string(' Kind=');
    DumpSegKind(Kind);
    string(' Lock='); dec(Lock);
    string(' Name='); DumpSegName(seg);
    CASE Kind OF
    | MoveSeg, SwapSeg, StaticSeg: string(' Age='); dec(GetTick()-Tick);
    END;
    eol;
  END;
END DumpSeg;

PROCEDURE TraceSeg(s:ARRAY OF CHAR; seg:CARDINAL);
BEGIN
  hex(g.freemem);
  char(' ');
  hex(seg);
  char(' ');
  string(s);
  WITH [seg-H:0 T]^ DO
    string(' Size='); hex(Used);
    string(' Kind=');
    DumpSegKind(Kind);
    CASE Kind OF
    | MoveSeg, SwapSeg, StaticSeg: string(' Name='); DumpSegName(seg);
        IF GetTick()#Tick THEN
          string(' Age='); dec(GetTick()-Tick);
        END;
    END;
    eol;
  END;
END TraceSeg;

(* splits free space of block p, returning lower half                  *)
PROCEDURE SplitLow(size:CARDINAL; p:CARDINAL):CARDINAL;
VAR
  res               : CARDINAL;
  free              : CARDINAL;
BEGIN
  WITH [p:0 T]^ DO
    res  := p + Used;
    free := Size - Used;
    Size := Used;
  END; (*WITH*)
  WITH [res:0 T]^ DO
    IF p # res THEN
      Prev := p;
    END; (*IF*)
    Size := free;
    Used := size;
  END; (*WITH*)
  WITH [res+free:0 T]^ DO
    Prev := res;
  END; (*WITH*)
  DEC(g.freemem,size);
  RETURN res;
END SplitLow;

(* Trys to find a block with with free space >= size, begin search at  *)
(* s, end at e.                                                        *)
PROCEDURE Try(size:CARDINAL; s,e:CARDINAL):CARDINAL;
VAR
  p,res             : CARDINAL;
BEGIN
  IF size = 0 THEN
    RETURN 0;
  END; (*IF*)
  p := s;
  LOOP
    WITH [p:0 T]^ DO
      IF Size - Used >= size THEN
        RETURN p;
      END; (*IF*)
      INC(p,Size);
      IF p = e THEN
        RETURN 0;
      END; (*IF*)
    END; (*WITH*)
  END; (*LOOP*)
END Try;

(* An area is a sequence of blocks satisfying ~Locked except for the   *)
(* first block.                                                        *)

(* Returns size of possible free space in area starting at s..e,       *)
(* assuming blocks of size < req can be evacuated                      *)
PROCEDURE Poss(s,e:CARDINAL; req:CARDINAL):CARDINAL;
VAR
  res               : CARDINAL;
BEGIN
  WITH [s:0 T]^ DO
    IF Active THEN
      RETURN 0;
    END; (*IF*)
    res := Size - Used;
    INC(s,Size);
  END; (*WITH*)
  WHILE s # e DO
    WITH [s:0 T]^ DO
      INC(res,Size);
      IF Size >= req THEN
        DEC(res,Used);
      END; (*IF*)
      INC(s,Size);
    END; (*WITH*)
  END; (*WHILE*)
  RETURN res;
END Poss;

(* Returns amount of free space in area s..e.                          *)
PROCEDURE Got(s,e:CARDINAL):CARDINAL;
VAR
  res               : CARDINAL;
BEGIN
  res := 0;
  WHILE s # e DO
    WITH [s:0 T]^ DO
      INC(res,Size);
      DEC(res,Used);
      INC(s,Size);
    END; (*WITH*)
  END; (*WHILE*)
  RETURN res;
END Got;

PROCEDURE NextArea(r:CARDINAL):CARDINAL;
BEGIN
  INC(r,[r:0 T]^.Size);
  LOOP
    WITH [r:0 T]^ DO
      IF Lock<>0 THEN
        RETURN r;
      END; (*IF*)
      INC(r,Size);
    END; (*WITH*)
  END; (*LOOP*)
END NextArea;

(* Find area containing r                                              *)
PROCEDURE Find(r:CARDINAL):CARDINAL;
BEGIN
  WHILE [r:0 T]^.Lock=0 DO
    r := [r:0 T]^.Prev;
  END; (*WHILE*)
  RETURN r;
END Find;

(* Returns largest Poss(s,e,req) less than bound over all areas s..e   *)
PROCEDURE MaxPoss(req:CARDINAL; VAR sm,em:CARDINAL):CARDINAL;
VAR
  s,e               : CARDINAL;
  max,try           : CARDINAL;
BEGIN
  s := g.start;
  max := 0;
  REPEAT
    e := NextArea(s);                       (*<<<*)
    try := Poss(s,e,req);                   (*<<<*)
    IF (try > max) THEN
      sm := s;
      em := e;
      max := try;
    END; (*IF*)
    s := e;
  UNTIL s = g.start;
  RETURN max;
END MaxPoss;

CONST
(*%T DEBUG*)
Hide              = 10H;
(*%E*)
(*%F DEBUG*)
Hide              = 200H;
(*%E*)

(* Returns largest Got(s,e) over all areas s..e *)
PROCEDURE Avail():CARDINAL;
VAR
  s,e               : CARDINAL;
  max,try           : CARDINAL;
BEGIN
  g.allockind := FixedSeg;
  s := g.start;
  max := 0;
  REPEAT
    e := NextArea(s);                   (*<<<*)
    try := Got(s,e);                    (*<<<*)
    IF (try > max) THEN
      max := try;
    END; (*IF*)
    s := e;
  UNTIL s = g.start;
  IF max<Hide+2 THEN RETURN 0 END;
  RETURN max-Hide-2;
END Avail;

PROCEDURE MemPic;
VAR
  tmp:CARDINAL;
  used:CARDINAL;
  lock:BOOLEAN;
BEGIN
  string('MemPic=');
  tmp := g.start;
  used := 0;
  lock := FALSE;
  REPEAT
    WITH [tmp:0 T]^ DO
      IF Lock # 0 THEN
        lock := TRUE;
      END;
      INC(used, Used);
      IF Size > Used THEN
        IF lock THEN
          char('+');
        ELSE
          char('.');
        END;
        dec(used);
        char('_');
        dec(Size-Used);
        used := 0;
        lock := FALSE;
      END;
      tmp := tmp + Size;
    END;
  UNTIL tmp = g.start;
  eol;
END MemPic;

PROCEDURE MemStat;
VAR
  kind              : SegKind;
  ucount,tcount,
  usize,tsize       : ARRAY SegKind OF CARDINAL;
  dummy             : CARDINAL;
  tmp               : CARDINAL;

  TDummy            : T;
BEGIN
  FOR kind := MIN(SegKind) TO MAX(SegKind) DO
    tcount[kind] := 0;
    ucount[kind] := 0;
    tsize[kind] := 0;
    usize[kind] := 0;
  END; (*FOR*)
  tmp := g.start;
  REPEAT
    WITH [tmp:0 T]^ DO
TDummy := [tmp:0 T];
      INC(tsize[Kind],Used);
      INC(tcount[Kind]);
      IF Lock=0 THEN
        INC(usize[Kind],Used);
        INC(ucount[Kind]);
      END; (*IF*)
      INC(tmp,Size);
    END; (*WITH*)
  UNTIL tmp = g.start;
  dec(g.freemem);
  char('/');
  dec(MaxPoss(0FFFFH,dummy,dummy));
  FOR kind := MIN(SegKind) TO FixedSeg DO
    char(' ');
    IF (usize[kind] # 0) & (usize[kind] # tsize[kind]) THEN
      dec(tcount[kind]-ucount[kind]);
      char(':');
      dec(tsize[kind]-usize[kind]);
      char('/');
      dec(ucount[kind]);
      char(':');
      dec(usize[kind]);
    ELSE
      dec(tcount[kind]);
      char(':');
      dec(tsize[kind]);
    END; (*IF*)
  END; (*FOR*)
(*%T MoveTrace *)
  string(' M=');
  dec(CARDINAL(g.move_total DIV 400H));
  char('k');
(*%E*)
  eol;
  MemPic;
END MemStat;

PROCEDURE DumpMemory;
VAR tmp:CARDINAL;
BEGIN
  string('Memory dump'); eol;
  tmp := g.start;
  REPEAT
    WITH [tmp:0 T]^ DO
      DumpSeg('dump ', tmp+H);
      tmp := tmp + Size;
    END;
  UNTIL tmp = g.start;
  MemStat;
(*%T TraceToFile*)
  FileClose(output_file);
  output_file := 1;
(*%E*)
END DumpMemory;

PROCEDURE TotalAvail():CARDINAL;
VAR
  res,p             : CARDINAL;
BEGIN
(*%T CHECK*)
  IF g.freemem # CalcFreeMem() THEN
    abort(ErrInternal);
  END; (*IF*)
(*%E*)
  res := g.freemem;
  IF res > Hide THEN
    DEC(res,Hide);  (* keep 8k free to stop too much shuffling *)
  ELSE
    res := 0;
  END; (*IF*)
  RETURN res;
END TotalAvail;

PROCEDURE Free(seg:CARDINAL);
VAR
  prev,next         : CARDINAL;

  TDummy            : T;
BEGIN
  IF seg=0 THEN RETURN END;
(*%T CHECK*)
  CheckAlloc(seg,ErrInvalidFree);
(*%E*)
  DEC(seg);
  WITH [seg:0 T]^ DO
TDummy := [seg:0 T];
(*%T MemoryTrace*)
    IF (Kind IN MemTraceSet) & (~ g.internal) THEN
      TraceSeg('Free  ',seg+H);
(*         MemStat;*)
    END; (*IF*)
(*%E*)
    INC(g.freemem,Used);
    IF seg = g.start THEN
      Used := 1;
      Lock := 1;
      Kind := SystemSeg;
      DEC(g.freemem);
    ELSE
      next := seg + Size;
      prev := Prev;
      [next:0 T]^.Prev := prev;
      [prev:0 T]^.Size := next-prev;
    END; (*IF*)
  END; (*WITH*)
(*%T CHECK*)
  CheckMem;
(*%E*)
END Free;

PROCEDURE TempAlloc(count:CARDINAL):CARDINAL;
VAR
  i,j:CARDINAL;
  found:CARDINAL;
BEGIN
  i := 0;
  LOOP
    IF i > HIGH(g.temp_map) THEN
      abort(ErrTempFileLimit);
    END;
    IF g.temp_map[i] # BITSET{0..15} THEN
      EXIT;
    END;
    INC(i);
  END;
  (* search for count consecutive bits *)
  j := 0;
  found := 0;
  LOOP
    IF j IN g.temp_map[i] THEN
      found := 0;
    ELSE
      INC(found);
      IF found = count THEN
        EXIT;
      END;
    END;
    INC(j);
    IF j = 16 THEN
      j := 0;
      INC(i);
      IF i > HIGH(g.temp_map) THEN
        abort(ErrTempFileLimit);
      END;
    END;
  END;
  (* set the bits *)
  LOOP
    INCL(g.temp_map[i], j);
    DEC(found);
    IF found=0 THEN
      EXIT;
    END;
    IF j=0 THEN
      DEC(i);
      j := 15;
    ELSE
      DEC(j);
    END;
  END;
  i := 1 + j + i*16;
  (*%T ExitTrace *) IF i+CARDINAL(count)-1 > g.temp_max THEN g.temp_max := i+CARDINAL(count)-1; END; (*%E*)
  RETURN i;
END TempAlloc;

PROCEDURE TempFree(i:CARDINAL;count:CARDINAL);
VAR j:CARDINAL;
BEGIN
  DEC(i);
  j := i MOD 16;
  i := i DIV 16;
  REPEAT
    (*%T CHECK*) IF ~ (j IN g.temp_map[i]) THEN abort(ErrInternal) END; (*%E*)
    EXCL(g.temp_map[i], j);
    INC(j);
    IF j = 16 THEN
      j := 0;
      INC(i);
    END;
    DEC(count);
  UNTIL count = 0;
END TempFree;
  
  
PROCEDURE reserve_panic;
BEGIN
  IF g.panic_reserve = 0 THEN
    g.panic_reserve := TempAlloc(PanicSize DIV TempPageSize);
  END;
END reserve_panic;

PROCEDURE release_panic;
BEGIN
  IF g.panic_reserve # 0 THEN
    TempFree(g.panic_reserve, PanicSize DIV TempPageSize);
    g.panic_reserve := 0;
  END;
END release_panic;

PROCEDURE TempXfer(action:DoSegOp;VAR tpv:CARDINAL;seg,off:CARDINAL;count:CARDINAL);
VAR
(*%T EMS*)
  ems_page,ems_off,
(*%E*)
  p,amount,tp,
  temp_size         : CARDINAL;
BEGIN
  tp := tpv;
  IF action = Load THEN
    tpv := seg;
  ELSE
    tpv := 0;
  END; (*IF*)
  IF count = 0 THEN
    RETURN;
  END; (*IF*)
  temp_size := 1+((count-1) DIV TempPageSize);
  IF action = Swap THEN
    tp := TempAlloc(temp_size);
    tpv := encode_temp(tp);
  ELSIF (tp # 0) & ~ is_mem(tp) THEN
    tp := decode_temp(tp);
    TempFree(tp, temp_size);
  END; (*IF*)
  IF (action = Load) & (tp = 0) THEN
    Fill([seg:off],count,0);
  ELSIF action # Discard THEN
(*%T EMS*)
    LOOP
      IF tp <= g.temp_ems THEN
        amount := TempPageSize;
        IF amount > count THEN
          amount := count;
        END; (*IF*)
        ems_page := (tp-1) DIV EmsPageSize;
        ems_off  := ((tp-1) MOD EmsPageSize) * TempPageSize;
        IF seg+(off DIV 16) >= g.ems_frame+800H THEN
          p := 0;
        ELSE
          p := 3;
          INC(ems_off, 0C000H);
        END; (*IF*)
        EmsMap(4400H+p,ems_page,g.ems_temp_handle);
        IF action=Swap THEN
          Move([seg:off],[g.ems_frame:ems_off],amount);
        ELSE
          Move([g.ems_frame:ems_off],[seg:off],amount);
        END; (*IF*)
        EmsMap(4400H+p,p,g.ems_data_handle);
        DEC(count,amount);
        IF count = 0 THEN
          EXIT;
        END;
        INC(off,amount);
        INC(tp);
      ELSE
(*%E*)
        FileSeek(g.temp_file,LONGCARD(tp-g.temp_ems-1) * TempPageSize);
        IF action=Swap THEN
          IF FileWrite([seg:off],count,g.temp_file) # count THEN
            abort(ErrTempDiskFull);
          END; (*IF*)
        ELSE
          FileRead([seg:off],count,g.temp_file);
        END; (*IF*)
(*%T EMS*)
        EXIT;
      END; (*IF*)
    END; (*LOOP*)
(*%E*)
  END; (*IF*)
END TempXfer;

PROCEDURE Para(size:CARDINAL):CARDINAL;
BEGIN
  IF size = 0 THEN
    RETURN 0;
  ELSE
    RETURN 1 + ((size-1) DIV 16);
  END;
END Para;

PROCEDURE P;
BEGIN
  string('trap');
  eol;
END P;

PROCEDURE GetSeg(module:Module;segnum:SegNum):SegPtr;
BEGIN
  RETURN SegPtr(HeapAdr(module^.seg_info^[segnum]));
END GetSeg;

PROCEDURE SetIndirect(seghdr:SegPtr);
VAR
  gate              : GatePtr;
BEGIN
  gate := seghdr^.direct_list;
  seghdr^.direct_list := GatePtr(0);
  WHILE gate<>GatePtr(0) DO
    gate^.state := IndirectGate;
    gate^.w2 := gate^.w1;
    gate^.w1 := CARDINAL(seghdr) - CARDINAL(gate) - 2;
    gate := gate^.next_direct;
  END;
END SetIndirect;

PROCEDURE Gate(off:CARDINAL;seghdr:SegPtr;iscall:BOOLEAN):CARDINAL;
VAR
  disp:CARDINAL;
  hash:CARDINAL;
  gp,ff:GatePtr;
BEGIN
  disp := CARDINAL(seghdr)-3;
  IF iscall THEN
    INC(disp);
  END;
  hash := 1 + (disp + off) MOD MaxGate;
  gp := GatePtr(HeapAdr(g.gate_table[hash]));
  ff := GatePtr(0);
  LOOP
    CASE gp^.state OF
    | FreeGate :
      IF ff # GatePtr(0) THEN
        gp := ff;
      ELSE
        INC(g.gate_count);
        IF g.gate_count = MaxGate THEN
          abort(ErrGateLimit);
        END;
      END;
      gp^.state := IndirectGate;
      gp^.w2 := off;
      gp^.w1 := disp - CARDINAL(gp);
      EXIT;
    | DeletedGate :
      IF ff = GatePtr(0) THEN
        ff := gp;
      END;
    | IndirectGate :
      IF (gp^.w2 = off) & (gp^.w1 + CARDINAL(gp) = disp) THEN
        EXIT;
      END;
    | DirectGate :
      IF (gp^.w1 = off) & (gp^.w2 = seghdr^.seg_val) THEN
        EXIT;
      END;
    END;
    IF gp = GatePtr(HeapAdr(g.gate_table[MaxGate])) THEN
      gp := GatePtr(HeapAdr(g.gate_table[1]));
    ELSE
      INC(CARDINAL(gp),SIZE(gp^));
    END;
  END;
  RETURN CARDINAL(gp);
END Gate;

PROCEDURE RetGate(off, seg:CARDINAL):ADDRESS;
VAR
  modnum:ModNum;
  segnum:SegNum;
  seghdr:SegPtr;
BEGIN
  (*%T CHECK*) CheckAlloc(seg,0); (*%E*)
  WITH [seg-1:0 T]^ DO
    modnum := Id1;
    segnum := Id2;
  END;
  seghdr := GetSeg(g.module_list[modnum], segnum);
  RETURN [Seg(g) : Gate(off, seghdr, FALSE)];
END RetGate;
  
PROCEDURE Append(VAR s:ARRAY OF CHAR;e:ARRAY OF CHAR); (*String*)
VAR i,j:CARDINAL;
BEGIN
  i := 0;
  WHILE s[i]#0C DO
    INC(i);
  END;
  j := 0;
  LOOP
    s[i] := e[j];
    IF s[i] = 0C THEN
      EXIT;
    END;
    INC(i);
    INC(j);
  END;
END Append;
  
PROCEDURE PathOpen(tail:ARRAY OF CHAR):CARDINAL;
CONST pathname='PATH=';
VAR
  envptr : POINTER TO ARRAY [0..999] OF CHAR;
  envseg,i,j:CARDINAL;
  c:CHAR;
  file:CARDINAL;
  path:ARRAY [0..255] OF CHAR;
BEGIN
  file := FileOpen(tail, BITSET(0));  (* Try local *)
  IF file # MAX(CARDINAL) THEN RETURN file; END;
  envseg := [g.psp: 2CH]^;
  envptr := [envseg: 0];

  i := 0;
  j := 0;
  LOOP (* search for 'PATH=' *)
    c := pathname[j];
    IF c=0C THEN
      EXIT;
    END;
    IF c # envptr^[i] THEN
      j := 0;
      WHILE envptr^[i]#0C DO
        INC(i);
      END;
      INC(i);
      IF envptr^[i]=0C THEN
        EXIT;
      END;
    ELSE
      INC(j);
      INC(i);
    END;
  END;

  j := 0;
  LOOP
    c := envptr^[i];
    path[j] := c;
    IF (c = ';') OR (c=0C) THEN
      IF c#'\' THEN
        path[j]   := '\';
        INC(j);
      END;
      path[j] := 0C;
      Append(path,tail);
      file := FileOpen(path, BITSET(0));
      IF file # MAX(CARDINAL) THEN
        EXIT;
      END;
      IF c = 0C THEN
        EXIT;
      END;
      j := 0;
    ELSE
      INC(j);
    END;
    INC(i);
  END;
  RETURN file;
END PathOpen;
  
PROCEDURE ModuleRead(module:Module;pos:LONGCARD;a:ADDRESS;count:CARDINAL):BOOLEAN;
VAR
  modnum:ModNum;
  victim:Module;
  fullname:ARRAY [0..99] OF CHAR;
  file:CARDINAL;
BEGIN
  IF count=0 THEN
    RETURN FALSE;
  END;
  file := module^.file;
  modnum := 1;
  WHILE ((file = MAX(CARDINAL)) & (g.file_count >= FileLimit)) OR
        (g.file_count > FileLimit)
  DO
    (*%T CHECK*) IF modnum > g.module_count THEN abort(ErrInternal); END; (*%E*)
    victim := g.module_list[modnum];
    IF (victim^.file # MAX(CARDINAL)) & (victim^.file # file) THEN
      FileClose(victim^.file);
      IF FileTrace THEN
        string('Close file ');
        string(victim^.name^);
        eol;
      END;
      victim^.file := MAX(CARDINAL);
      DEC(g.file_count);
    END;
    INC(modnum);
  END;
  IF file = MAX(CARDINAL) THEN
    fullname[0] := 0C;
    Append(fullname, module^.name^);
    IF module^.is_exe THEN
      Append(fullname, '.exe');
    ELSE
      Append(fullname, '.dll');
    END;
    file := PathOpen(fullname);
    module^.file := file;
    IF FileTrace THEN
      string('Open file ');
      string(fullname);
      IF file = MAX(CARDINAL) THEN
        string(' - failed to open !!');
      END;
      eol;
    END;
    IF file = MAX(CARDINAL) THEN
      RETURN TRUE;
    END;
    INC(g.file_count);
  END;
  FileSeek(file, pos);
  FileRead(a, count, file);
  RETURN FALSE;
END ModuleRead;

(*%T VidSupport*)
(*# save, call(reg_param=>(ax,bx,cx,dx,si),
               reg_saved =>(ds,es,di,st1,st2), inline=>on) *)
PROCEDURE debug_int(data_ptr:ADDRESS;name_ptr:ADDRESS;action:CARDINAL) =
   A2(0CDH,063H);
(*# restore *)
  
TYPE VidAction = (VID_XX, VID_LOAD_MODULE, VID_LOAD_SEG, VID_UNLOAD_SEG);

PROCEDURE TellVid(modnum:ModNum;segnum:SegNum;action:VidAction);
TYPE
  StrPtr     = POINTER TO ARRAY[0..79] OF CHAR;
  SegListPtr = POINTER TO SegListRec;
  DllLoadPtr = POINTER TO DllLoadRec;
  SegListRec = RECORD
                 new_rlc        : CARDINAL;
                 module         : DllLoadPtr;
                 ext_deps       : SHORTADDR;
                 seg_val        : CARDINAL;
                 seg_size       : CARDINAL;
                 reloc_num      : CARDINAL;
                 type           : CARDINAL;
                 use_count      : SHORTCARD;
                 lru_count      : SHORTCARD;
                 status         : SHORTCARD;
                 seg_no         : SHORTCARD;
(*%T EMS*)
                 ems_page       : SHORTCARD;
                 ems_size       : SHORTCARD;
(*%E*)
                 ref_count      : CARDINAL;
                 swap_pos       : CARDINAL;
               END;
  
  
  DllLoadRec = RECORD
                 total_entries          : CARDINAL;
                 entries                : ADDRESS;
                 segs                   : SegListPtr;
                 total_segments         : CARDINAL;
                 status                 : SHORTCARD;
                 entry_point            : PROC;
                 module_no              : SHORTCARD;
               END;
  
VAR
  m:DllLoadRec;
  s:SegListRec;
  dp:ADDRESS;
  name:ARRAY [0..255] OF CHAR;
  module:Module;
BEGIN
  IF g.vid_present THEN
    module := g.module_list[modnum];
    m.total_segments := module^.seg_count;
    IF action = VID_LOAD_MODULE THEN
      dp := ADR(m);
    ELSE
      dp := ADR(s);
      s.module := ADR(m);
      s.seg_no := SHORTCARD(segnum);
      s.seg_val := module^.seg_info^[segnum].seg_val;
      s.seg_size := module^.seg_info^[segnum].membyte;
    END;
    name[0] := 0C;
    Append(name, module^.name^);
    IF module^.is_exe THEN
      Append(name, '.EXE');
    ELSE
      Append(name, '.DLL');
      (*Int66;*)
    END;
    debug_int(dp, ADR(name), CARDINAL(action));
  END;
END TellVid;
  
PROCEDURE TellVidMove;
BEGIN
  IF g.vid_delayed THEN
    g.vid_delayed := FALSE;
    TellVid(g.vid_id1,g.vid_id2,VID_LOAD_SEG);
  END;
END TellVidMove;

PROCEDURE FindVid;
VAR
  iv:POINTER TO ADDRESS;
  cp:POINTER TO ARRAY [0..0] OF CHAR;
BEGIN
  iv := [0:63H*4];
  cp := iv^;
  IF (cp^[-3]='V') & (cp^[-2]='I') & (cp^[-1]='D') THEN
    g.vid_present := TRUE;
  END;
END FindVid;
(*%E*)


PROCEDURE MakeSys(seg:CARDINAL); FORWARD;


PROCEDURE ReserveDisk(amount:LONGCARD):BOOLEAN;
VAR dummy:CHAR;
BEGIN
  INC(g.temp_reserve, amount);
  IF (g.temp_reserve > LONGINT(FileSize(g.temp_file))) THEN
    FileSeek(g.temp_file, g.temp_reserve + 1001H);
    dummy := 'x';
    IF FileWrite(ADR(dummy), 1, g.temp_file) # 1 THEN
      DEC(g.temp_reserve, amount);
      RETURN FALSE;
    END;
  END;
  RETURN TRUE;
END ReserveDisk;
  
PROCEDURE ReleaseDisk(amount:LONGCARD);
BEGIN
  DEC(g.temp_reserve, amount);
END ReleaseDisk;
  
PROCEDURE TempHandle():CARDINAL;
BEGIN
  RETURN g.temp_file;
END TempHandle;
  

(*# save,data(const_in_code=>on) *)
CONST TempFileName = '\tstemp00.$$$';
CONST FullTempFileName =
'A:\                                                                          ';
(*%T EMS*)
CONST EmsName = 'EMMXXXX0';
(*%E*)
(*# restore *)

PROCEDURE SetEms(on:BOOLEAN):BOOLEAN;
(*%T EMS*)
VAR
  ems:CARDINAL;
  i,p:CARDINAL;
  ems_page,ems_off:CARDINAL;
  avail:CARDINAL;
LABEL restore_data, return;
(*%E*)
BEGIN
(*%T EMS*)
  release_panic;
  IF (g.ems_temp_handle # 0) = on THEN
    GOTO return;
  END;
  IF on THEN
    IF g.ems_data_handle = 0 THEN
      IF ~ g.ems_present THEN
        GOTO return;
      END;
      avail := EmsGet(4200H); (* get number of free pages *)
      IF avail < 4 THEN
        GOTO return;
      END;
      g.ems_count := avail;
      g.ems_data_handle := EmsAlloc(4300H, 4); (* allocate free pages *)
      (* put 64K block in free memory chain*)
      FOR p := 0 TO 3 DO
        EmsMap(4400H+p, p, g.ems_data_handle);
      END;
      MakeSys(g.ems_frame + 1000H - 1);
      MakeSys(g.ems_frame);
      WITH [g.ems_frame:0 T]^ DO
        Used := 0;
        INC(g.freemem, Size);
      END;
    END;
    avail := EmsGet(4200H); (* get number of free pages *)
    IF avail = 0 THEN
      GOTO return;
    END;
    g.ems_temp_handle := EmsAlloc(4300H, avail); (* allocate free pages *)
    g.temp_ems := avail * EmsPageSize;
    ReleaseDisk(LONGINT(g.temp_ems)*TempPageSize);
  END;
  (* transfer pages from temp file to/from ems *)
  FOR i := 0 TO g.temp_ems-1 DO
    IF (i MOD 16) IN g.temp_map[i DIV 16] THEN
      ems_page := i DIV EmsPageSize;
      ems_off  := (i MOD EmsPageSize) * TempPageSize;
      EmsMap(4400H, ems_page, g.ems_temp_handle);
      FileSeek(g.temp_file, LONGCARD(i)*TempPageSize);
      IF on THEN
        FileRead([g.ems_frame:ems_off], TempPageSize, g.temp_file);
      ELSE
        IF FileWrite([g.ems_frame:ems_off], TempPageSize, g.temp_file) # TempPageSize THEN
          GOTO restore_data;
        END;
      END;
    END;
  END;
  IF ~ on THEN
    IF ~ ReserveDisk(LONGINT(g.temp_ems)*TempPageSize) THEN
      GOTO restore_data;
    END;
    EmsMap(4500H, 0, g.ems_temp_handle); (* free temp pages *)
    g.ems_temp_handle := 0;
    g.temp_ems := 0;
  END;
restore_data:
  EmsMap(4400H, 0, g.ems_data_handle); (* restore data page *)
return:
  reserve_panic;
  RETURN g.ems_temp_handle # 0;
(*%E*)
(*%F EMS*)
  RETURN FALSE;
(*%E*)
END SetEms;

PROCEDURE DoSeg(modnum:ModNum;segnum:SegNum;op:DoSegOp):CARDINAL; FORWARD;

PROCEDURE DoDelay;
VAR
  module            : Module;
  modnum            : ModNum;
  segnum            : SegNum;
  segment           : CARDINAL;
  gate              : GatePtr;
  seghdr            : SegPtr;
  seginfosize       : CARDINAL;
BEGIN
  IF g.delay # 0 THEN
    modnum  := g.delay;
    g.delay := 0;
    module  := g.module_list[modnum];
  (* swap out all segments *)
    FOR segnum := 1 TO module^.seg_count DO
      segment := DoSeg(modnum,segnum,Discard);
    END; (*FOR*)
  (* delete gates *)
    seginfosize := module^.seg_count * SIZE(SegRec);
    gate := GatePtr(HeapAdr(g.gate_table));
    LOOP
      IF gate^.state = IndirectGate THEN
        seghdr := SegPtr(gate^.w1 + CARDINAL(gate) + 3);
        IF CARDINAL(seghdr) - CARDINAL(module^.seg_info) < seginfosize THEN
          gate^.state := DeletedGate;
        END; (*IF*)
      END; (*IF*)
      IF gate = GatePtr(HeapAdr(g.gate_table[MaxGate])) THEN
        EXIT;
      END; (*IF*)
      INC(CARDINAL(gate),SIZE(GateRec));
    END; (*LOOP*)
  (* close file *)
    IF (module^.file # MAX(CARDINAL)) THEN
      FileClose(module^.file);
      IF FileTrace THEN
        string('Close file ');
        string(module^.name^);
        eol;
      END; (*IF*)
      module^.file := MAX(CARDINAL);
      DEC(g.file_count);
    END; (*IF*)
  (* free heap if last module *)
    IF modnum = g.module_count THEN
      DEC(g.module_count);
      Fill(ADR(module^),g.near_alloc - CARDINAL(module),0);
      g.near_alloc := CARDINAL(module);
    END; (*IF*)
  END; (*IF*)
END DoDelay;

PROCEDURE UnLoadModule(modnum:CARDINAL);
BEGIN
  IF g.delay # modnum THEN
    DoDelay;
  END;
  g.delay := modnum;
END UnLoadModule;



PROCEDURE GetOrdProcAddr (modnum:CARDINAL;entry:CARDINAL):ADDRESS;
VAR
  offset:CARDINAL;
  module:Module;
BEGIN
  module := g.module_list[modnum];
  offset := Gate(module^.entry_table^[entry].ofs,
                  GetSeg(module, SegNum(module^.entry_table^[entry].seg)), TRUE);
  RETURN [Seg(g) : offset];
END GetOrdProcAddr;

PROCEDURE New(size:CARDINAL):HeapADDR;
  (* Allocate bytes from Near Heap *)
VAR res:HeapADDR;
BEGIN
  res := SHORTADDR(g.near_alloc);
  INC(g.near_alloc,size);
  IF g.near_alloc > Ofs(g.heap[HeapSize]) THEN
    abort(ErrNearHeap);
  END; (*IF*)
  RETURN res;
END New;

PROCEDURE Length(s: ARRAY OF CHAR):CARDINAL; (*String*)
VAR i:CARDINAL;
BEGIN
  i := 0;
  WHILE s[i]#0C DO
    INC(i);
  END;
  RETURN i;
END Length;

PROCEDURE Compare(s1,s2:ARRAY OF CHAR):BOOLEAN; (*String*)
 VAR
  i                 : CARDINAL;
BEGIN
  i := 0;
  LOOP
    IF s1[i] # s2[i] THEN
      RETURN FALSE;
    END;
    IF s1[i] = 0C THEN
      RETURN TRUE;
    END;
    INC(i);
  END;
END Compare;


PROCEDURE GetNextFree(seg : CARDINAL;VAR fsize : CARDINAL) : CARDINAL;
(* Returns next area > seg that is not being used for anything *)
(* Used for spawn *)
VAR p:CARDINAL; fseg : CARDINAL;
BEGIN
  p := g.start;
  LOOP
    WITH [p:0 T]^ DO
      IF p+Used>seg THEN
        fseg := p+Used;
        fsize := Size-Used;
        IF (fsize>0) THEN
(*%T EMS*)
          IF (g.ems_data_handle = 0) OR
             (fseg<g.ems_frame) OR
             (fseg>g.ems_frame+1000H)
          THEN
            EXIT;
          END;
(*%E*)
(*%F EMS*)
          EXIT;
(*%E*)
        END;
      END;
      p := p+Size;
    END;
    IF p = g.start THEN
      fseg := 0;
      EXIT;
    END;
  END;
  RETURN fseg;
END GetNextFree;

(*%F CHECK*) INLINE (*%E*) PROCEDURE Lock(seg:CARDINAL);
BEGIN
  IF LockTrace THEN
    string('Lock '); hex(seg); eol;
  END;
(*%T CHECK*)
  CheckAlloc(seg,0);
(*%E*)
  INC([seg-H:0 T]^.Lock);
END Lock;

(*%F CHECK*) INLINE (*%E*) PROCEDURE UnLock(seg:CARDINAL);
BEGIN
  IF LockTrace THEN
    string('UnLock '); hex(seg); eol;
  END;
(*%T CHECK*)
  CheckAlloc(seg,0);
  IF [seg-H:0 T]^.Lock = 0 THEN abort(ErrTooManyUnlocks); END;
(*%E*)
  DEC([seg-H:0 T]^.Lock);
END UnLock;


PROCEDURE DoSwap(seg : CARDINAL);
(* Only called for StaticSeg and SwapSeg *)
VAR
  dummy             : CARDINAL;
  seghdr            : SegPtr;
BEGIN
  WITH [seg:0 T]^ DO
    IF Kind=StaticSeg THEN
(*%T CHECK*)
      seghdr := SegPtr(HeapAdr(g.module_list[Id1]^.seg_info^[Id2]));
      IF seghdr^.direct_list<>GatePtr(0) THEN
        abort(ErrInternal);
      END;
(*%E*)
      dummy := DoSeg(Id1,Id2,Swap);
    ELSIF Kind=SwapSeg THEN
      TempXfer(Swap,[Id2:Id1 WP]^,seg+1,0,([seg:0 T]^.Used-1)*16);
      Free(seg+1);
    ELSE
(*%T CHECK*)
      abort(ErrInternal);
(*%E*)
    END;
  END;
END DoSwap;


PROCEDURE IsActive(seghdr:SegPtr):BOOLEAN;
TYPE
  fp                = POINTER Seg(seghdr) TO RECORD
                                               bp,ip,cs: CARDINAL;
                                             END; (*fp*)
VAR
  bp                : fp;
  cs                : CARDINAL;
  res               : BOOLEAN;
BEGIN
  res := FALSE;
  cs  := seghdr^.seg_val;
  bp  := fp(GetBP());
  REPEAT
(*%T CHECK*)
    IF bp^.bp # 0 THEN
      CheckAlloc(bp^.cs,ErrCallChainInvalid);
    END; (*IF*)
(*%E*)
    IF bp^.cs = cs THEN
      bp^.ip := Gate(bp^.ip,seghdr,FALSE);
      bp^.cs := Seg(g);
      res := TRUE;
    END; (*IF*)
(*%T CHECK*)
    IF ((bp^.bp=0)AND(bp^.ip # 1234H)) OR
       ((bp^.bp<>0)AND(bp^.bp <= CARDINAL(bp))) THEN
        abort(ErrCallChainInvalid);
    END; (*IF*)
(*%E*)
    bp := fp(bp^.bp);
  UNTIL bp = fp(0);
  RETURN res;
END IsActive;

PROCEDURE MyCaller():CARDINAL;
VAR
  res               : BOOLEAN;
TYPE
  fp                = POINTER Seg(res) TO RECORD
                                               bp,ip,cs: CARDINAL;
                                          END; (*fp*)
VAR
  bp                : fp;
BEGIN
  res := FALSE;
  bp  := fp(GetBP());
  REPEAT
(*%T CHECK*)
    IF bp^.bp # 0 THEN
      CheckAlloc(bp^.cs,ErrCallChainInvalid);
    END; (*IF*)
    IF ((bp^.bp=0)AND(bp^.ip # 1234H)) OR
       ((bp^.bp<>0)AND(bp^.bp <= CARDINAL(bp))) THEN
        abort(ErrCallChainInvalid);
    END; (*IF*)
(*%E*)
    IF bp^.cs<>Seg(MyCaller) THEN
      RETURN bp^.cs;
    END;
    bp := fp(bp^.bp);
  UNTIL bp = fp(0);
  RETURN 0;
END MyCaller;


PROCEDURE RelocStatic(seghdr:SegPtr;new:CARDINAL);
TYPE
  fp                = POINTER Seg(seghdr) TO RECORD
                                               bp,ip,cs: CARDINAL;
                                             END; (*fp*)
VAR
  bp                : fp;
  cs                : CARDINAL;
  gate              : GatePtr;
BEGIN
  cs := seghdr^.seg_val;
  seghdr^.seg_val := new;
  gate := seghdr^.direct_list;
  WHILE gate # GatePtr(0) DO
    gate^.w2 := new;
    gate := gate^.next_direct;
  END; (*WHILE*)
  bp := fp(GetBP());
  REPEAT
    IF bp^.cs = cs THEN
      bp^.cs := new;
(*%T CHECK*)
    ELSIF bp^.bp # 0 THEN
      CheckAlloc(bp^.cs,ErrCallChainInvalid);
(*%E*)
    END; (*IF*)
(*%T CHECK*)
    IF ((bp^.bp=0)AND(bp^.ip # 1234H)) OR
       ((bp^.bp<>0)AND(bp^.bp <= CARDINAL(bp))) THEN
        abort(ErrCallChainInvalid);
    END; (*IF*)
(*%E*)
    bp := fp(bp^.bp);
  UNTIL bp = fp(0);
END RelocStatic;

PROCEDURE DoFlushAll;
VAR
  tmp               : CARDINAL;
  change            : BOOLEAN;
BEGIN
  REPEAT
    change := FALSE;
    tmp := g.start;
    REPEAT
      WITH [tmp:0 T]^ DO
        IF (Lock = 0) & (Kind # MoveSeg) THEN
          IF Kind=StaticSeg THEN
            SetIndirect(SegPtr(HeapAdr(g.module_list[Id1]^.seg_info^[Id2])));
          END;
          DoSwap(tmp);
          change := TRUE;
        END; (*IF*)
        INC(tmp,Size);
      END; (*WITH*)
    UNTIL tmp = g.start;
  UNTIL ~change;
END DoFlushAll;

PROCEDURE TinyFlush; FORWARD;

(* Should do long jump to reset point, Also OutOfDisk needs doing      *)
PROCEDURE OutOfMem(request:CARDINAL);
BEGIN
  IF OutOfMemTrace THEN
    string('Out of memory.');
    eol;
    DumpMemory;
    MemStat;
  END; (*IF*)
  IF ~g.OutOfMem(request) THEN
    abort(ErrOutOfMem);
  END; (*IF*)
END OutOfMem;

PROCEDURE FlushLRU(req:CARDINAL);
VAR
  tmp               : CARDINAL;
  lru               : CARDINAL;
  age,maxage        : CARDINAL;
  res               : BOOLEAN;
  i                 : CARDINAL;
  wants             : CARDINAL;
  ssize             : CARDINAL;
  seghdr            : SegPtr;
BEGIN
(*%T GraphUseTrace*)
  GraphTrace(0,req,GTlru);
(*%E*)
  wants := req+400H;
(*%T CHECK*)
  CheckMem;
(*%E*)
  TinyFlush;

  tmp := g.start;
  (* Mark all segments as indirect to help LRU *)
  REPEAT
    WITH [tmp:0 T]^ DO
      IF (Kind =StaticSeg) & (Lock=0) THEN
        seghdr := SegPtr(HeapAdr(g.module_list[Id1]^.seg_info^[Id2]));
        IF seghdr^.direct_list<>GatePtr(0) THEN
          SetIndirect(seghdr);
        END;
      END; (*IF*)
      INC(tmp,Size);
    END; (*WITH*)
  UNTIL tmp = g.start;
  [MyCaller()-H:0 T]^.Tick := IncTick();
  LOOP
    ssize := 0;
    maxage := 0;
    tmp := g.start;
    lru := 0;
    REPEAT
      WITH [tmp:0 T]^ DO
        IF (Kind # MoveSeg) & (Lock=0) THEN
          age := GetTick() - Tick;
          IF (age >= maxage) THEN
            lru := tmp;
            maxage := age;
          END; (*IF*)
        END; (*IF*)
        INC(tmp,Size);
      END; (*WITH*)
    UNTIL tmp = g.start;
    IF lru # 0 THEN
      WITH [lru:0 T]^ DO
        ssize := Used;
        DoSwap(lru);
(*%T UsageTrace*)
        string('Age=');
        dec(maxage);
        string('Req=');
        dec(req);
        char(' ');
        MemStat;
(*%E*)
        IF ssize>=wants THEN
          EXIT;
        END;
        DEC(wants,ssize);
      END; (*WITH*)
    ELSE
      IF ssize=0 THEN
        OutOfMem(req);
      END;
      EXIT;
    END; (*IF*)
  END; (*LOOP*)
END FlushLRU;



PROCEDURE Relocate(old,new:CARDINAL);
BEGIN
  IF RelocateTrace THEN
    string('Relocate ');
    hex(old+H);
    string(' to ');
    hex(new+H);
    eol;
  END; (*IF*)
  INC(new, H);
  WITH [old:0 T]^ DO
    CASE Kind OF
      StaticSeg     : (*%T VidSupport*)
                        TellVid(Id1,Id2,VID_UNLOAD_SEG);
                      (*%E*)
                      RelocStatic(SegPtr(HeapAdr(g.module_list[Id1]^.seg_info^[Id2])),new);
                      (*%T VidSupport*)
                        g.vid_delayed := TRUE;
                        g.vid_id1 := Id1;
                        g.vid_id2 := Id2;
                      (*%E*)                                          |
      MoveSeg,SwapSeg       : [Id2:Id1 WP]^ := new;                           |
    ELSE
      abort(ErrInternal);
    END; (*CASE*)
  END; (*WITH*)
END Relocate;

(* Used to move relocatable block, No overlap                          *)
PROCEDURE SimpleMove(old,new:CARDINAL);
CONST
  K                 = VSIZE(ParaRec.Prev);
VAR
  size              : CARDINAL;
BEGIN
  Relocate(old,new);
  size := [old:0 T]^.Used;
  Move([old:K],[new:K],size*16-K);
(*%T VidSupport*)
  TellVidMove;
(*%E*)
(*%T MemoryTrace*)
  g.internal := TRUE;
(*%E*)
  Free(old+H);
(*%T MemoryTrace*)
  g.internal := FALSE;
(*%E*)
(*%T CHECK*)
  CheckAlloc(new+H,0);
(*%E*)
END SimpleMove;

(* move segments in area (s..e) down *)
PROCEDURE Shuffle(s,e:CARDINAL);
VAR
  old,new,diff,size : CARDINAL;
BEGIN
  LOOP
    WITH [s:0 T]^ DO
      old := s + Size;
      IF old = e THEN
        EXIT;
      END; (*IF*)
      diff := Size - Used;
      new  := old  - diff;
      IF diff > 0 THEN
        size := [old:0 T]^.Used;
        Relocate(old,new);
(*%T MoveTrace *)
        INC(g.move_total,LONGCARD(size*16));
(*%E*)
        Move([old:0],[new:0],size*16);
(*%T VidSupport*)
        TellVidMove;
(*%E*)
        DEC(Size,diff);
        WITH [new:0 T]^ DO
          INC(Size,diff);
          [new+Size:0 T]^.Prev := new;
        END; (*WITH*)
(*%T CHECK*)
        CheckAlloc(new+H,0);
(*%E*)
      END; (*IF*)
      s := new;
    END; (*WITH*)
  END; (*LOOP*)
END Shuffle;

PROCEDURE Get(req:CARDINAL):CARDINAL; FORWARD;

(* Choose a block of size < max to evacuate. We choose largest up to   *)
(* aim, then smallest. Thus we search the range (res,max) until        *)
(* size(res) >= aim then we search the range (aim,size(res)).          *)
PROCEDURE Choose(s,e,aim,max:CARDINAL):CARDINAL;
VAR
  res,min,size,poss : CARDINAL;
BEGIN
  INC(s,[s:0 T]^.Size);
  min := 0;
  res := 0;
  poss := 0;
  WHILE s # e DO
    WITH [s:0 T]^ DO
      size := Used;
      IF size < max THEN
        INC(poss,size);
        IF size > min THEN
          res := s;
          IF size >= aim THEN
            min := aim;
            max := size;
          ELSE
            min := size;
          END; (*IF*)
        END; (*IF*)
      END; (*IF*)
      INC(s,Size);
    END; (*WITH*)
  END; (*WHILE*)
  IF poss < aim THEN
    res := 0;
  END; (*IF*)
  RETURN res;
END Choose;

(* In decreasing size, evacuate segs in area s satisfying Used < lim,  *)
(*   until free space for s..e >= need                                 *)
PROCEDURE Evac(s,e:CARDINAL;lim:CARDINAL;need:CARDINAL):BOOLEAN;
VAR
  got,old,new,poss  : CARDINAL;
  res               : BOOLEAN;
BEGIN
  got := Got(s,e);
  [s:0 T]^.Active := TRUE;
  LOOP
    IF got >= need THEN
      res := TRUE;
      EXIT;
    ELSE
      old := Choose(s,e,need-got,lim);
      IF old = 0 THEN
        res := FALSE;
        EXIT;
      END; (*IF*)
      WITH [old:0 T]^ DO
        lim := Used;
        new := Get(lim);
        IF new # 0 THEN
          new := SplitLow(lim,new);
          SimpleMove(old,new);
          INC(got,lim);
          INC(lim); (* others of same size are acceptable *)
        END; (*IF*)
      END; (*WITH*)
    END; (*IF*)
  END; (*LOOP*)
  [s:0 T]^.Active := FALSE;
  RETURN res;
END Evac;

PROCEDURE Get(req:CARDINAL):CARDINAL;
VAR
  max,s,e,res       : CARDINAL;
BEGIN
  max := MaxPoss(req,s,e);
  IF (max >= req) & Evac(s,e,req,req) THEN
    Shuffle(s, e);
    res := Try(req,s,e);
(*%T CHECK*)
    IF res = 0 THEN
      abort(ErrInternal);
    END; (*IF*)
(*%E*)
  ELSE
    res := 0;
  END; (*IF*)
  RETURN res;
END Get;

(* Moves relocatable segments in range (s..e) up, thus increasing      *)
(* s^.Size.                                                            *)
PROCEDURE ShuffleUp(s,e:CARDINAL);
VAR
  w,p,new,diff      : CARDINAL;
BEGIN
  w := [e:0 T]^.Prev;
  LOOP
    IF w = s THEN
      EXIT;
    END; (*IF*)
    WITH [w:0 T]^ DO
      p := Prev;
      diff := Size - Used;
      new := w + diff;
      IF (diff > 0) THEN
        Relocate(w,new);
        DEC(Size,diff);
        [e:0 T]^.Prev := new;
        INC([p:0 T]^.Size,diff);
(*%T MoveTrace *)
        INC(g.move_total,LONGCARD(Used*16));
(*%E*)
        MoveUp([w:0],[new:0],Used*16);
(*%T VidSupport*)
        TellVidMove;
(*%E*)
      END; (*IF*)
    END; (*WITH*)
    e := new;
    w := p;
  END; (*LOOP*)
(*%T CHECK*)
  CheckMem;
(*%E*)
END ShuffleUp;

PROCEDURE IAlloc(size:CARDINAL;id1,id2:CARDINAL;kind:SegKind;high:BOOLEAN):CARDINAL;
VAR
  s,e,sm,em,
  use,res           : CARDINAL;
BEGIN
(*%T CHECK*)
  CheckMem;
(*%E*)
  g.allockind := kind;
  INC(size,H);
  IF high THEN
    LOOP            (* decide area: last such that Poss(a) >= size *)
      sm := 0;
      s  := g.start;
      REPEAT
        e := NextArea(s);
        IF Poss(s,e,MAX(CARDINAL)) >= size THEN
          sm := s;
          em := e;
        END; (*IF*)
        s := e;
      UNTIL s = g.start;
      IF sm # 0 THEN
        IF (TotalAvail() >= size) & Evac(sm,em,MAX(CARDINAL),size) THEN
          Shuffle(sm,em);
          use := Try(size,sm,em);
(*%T CHECK*)
          IF use = 0 THEN
            abort(ErrInternal);
          END; (*IF*)
(*%E*)
          EXIT;
        END; (*IF*)
      END; (*IF*)
      FlushLRU(size);
    END; (*LOOP*)
    WITH [use:0 T]^ DO
      DEC(Size,size);
      res := use + Size;
    END; (*WITH*)
    WITH [res:0 T]^ DO
      Size := size;
      Used := size;
      IF res # use THEN
        Prev := use;
      END; (*IF*)
      [res+size:0 T]^.Prev := res;
    END; (*WITH*)
    DEC(g.freemem,size);
  ELSE
    LOOP
(*%T DEBUG*)
      use := 0;
(*%E*)
(*%F DEBUG*)
      use := Try(size,g.start,g.start);
(*%E*)
      IF (use = 0) & (TotalAvail() >= size) THEN
        use := Get(size);
      END; (*IF*)
      IF use # 0 THEN
        EXIT;
      END; (*IF*)
      FlushLRU(size);
    END; (*IF*)
    res := SplitLow(size,use);
  END; (*IF*)
  WITH [res:0 T]^ DO
    Id1 := id1;
    Id2 := id2;
    Kind := kind;
    Active := FALSE;
    Lock := 1;
    Tick := IncTick();
  END; (*WITH*)
  INC(res,H);
  DEC(size,H);
(*%T MemoryTrace*)
  IF (kind IN MemTraceSet) THEN
    TraceSeg('IAlloc',res);
  END; (*IF*)
(*%E*)
(*%T Debuging*)
  IF res = g.trap_alloc THEN
    P;
  END; (*IF*)
(*%E*)
(*%T CHECK*)
  CheckAlloc(res,0);
  CheckMem;
(*%E*)
  RETURN res;
END IAlloc;

PROCEDURE AllocFixed(size:CARDINAL):CARDINAL;
BEGIN
  RETURN IAlloc(size, 0, 0, FixedSeg, TRUE);
END AllocFixed;


PROCEDURE AllocMove(VAR seg:CARDINAL;size:CARDINAL);
VAR
  a:ADDRESS;
  res:CARDINAL;
BEGIN
  a := ADR(seg);
  res := IAlloc(size, Ofs(a^), Seg(a^), MoveSeg, FALSE);
  UnLock(res);
  seg := res;
END AllocMove;

PROCEDURE ReSize(VAR seg:CARDINAL;newsize:CARDINAL);
VAR
  old,use,s,e:CARDINAL;
  (*%T MemoryTrace*) easy:BOOLEAN; (*%E*)
BEGIN
  (*%T MemoryTrace*) easy := TRUE; (*%E*)
  g.allockind := MoveSeg;
  INC(newsize,H);
  LOOP
    old := seg-H;
    WITH [old:0 T]^ DO
      IF Size >= newsize THEN
        INC(g.freemem, Used);
        DEC(g.freemem, newsize);
        Used := newsize;
        EXIT;
      END;
      (*%T MemoryTrace*) easy := FALSE; (*%E*)
      use := Try(newsize, g.start, g.start);
      IF use = 0 THEN
        s := Find(old);
        e := NextArea(s);
        IF (newsize>1000H) &
           (TotalAvail()>newsize-Used) &
           Evac(s, e, Used, newsize-Used)
        THEN
          ShuffleUp(old, e);
          Shuffle(s, old+Size);
          (*%T CHECK*) IF [seg-H:0 T]^.Size < newsize THEN abort(ErrInternal); END; (*%E*)
        ELSE
          IF TotalAvail() >= newsize THEN
            use := Get(newsize);
          END;
          IF use = 0 THEN
            FlushLRU(newsize);
          END;
        END;
      END;
      IF use # 0 THEN
        use := SplitLow(newsize, use);
        SimpleMove(seg-H, use);
        EXIT;
      END;
    END;
  END;
  (*%T MemoryTrace*)
  IF (MoveSeg IN MemTraceSet) & (~easy) THEN
    TraceSeg('ReSize',seg);
  END;
  (*%E*)
END ReSize;

PROCEDURE LoadMove(VAR seg:CARDINAL;size:CARDINAL);
VAR
  tmp:CARDINAL;
BEGIN
  tmp := seg;
  IF ~ is_mem(tmp) THEN
    AllocMove(seg, size);
    TempXfer(Load, tmp, seg, 0, size*16);
  ELSE
    (*%T CHECK*) CheckAlloc(tmp,ErrInvalidVFix); (*%E*)
    WITH [tmp-H:0 T]^ DO
      (*%T CHECK*) IF (Kind # MoveSeg)
         & (Kind # SwapSeg)
            THEN abort(ErrInvalidVFix);
          END;
      (*%E*)
      Kind := MoveSeg;
    END;
  END;
END LoadMove;


PROCEDURE LoadCode(seghdr:SegPtr):CARDINAL;
VAR
  segment:CARDINAL;
  modnum:ModNum;
  module:Module;
  segnum:SegNum;
BEGIN
  segment := seghdr^.seg_val;
  IF ~ is_mem(segment) THEN
    modnum := 0;
    LOOP
      INC(modnum);
      (*%T CHECK*) IF modnum > g.module_count THEN abort(ErrInternal); END; (*%E*)
      module := g.module_list[modnum];
      segnum := 1+(CARDINAL(seghdr)-CARDINAL(module^.seg_info)) DIV SIZE(SegRec);
      IF segnum-1 < module^.seg_count THEN
        EXIT;
      END;
    END;
    segment := DoSeg(modnum, segnum, Load);
    UnLock(segment);
  ELSE
    [segment-H:0 T]^.Tick := IncTick();
  END;
  RETURN segment;
END LoadCode;

PROCEDURE CallTrap(sd:CARDINAL;gd:CARDINAL):CARDINAL;
VAR
  seghdr:SegPtr;
  gate:GatePtr;
  segment:CARDINAL;
BEGIN
  gate := GatePtr(gd);
  seghdr := SegPtr(sd);
  segment := LoadCode(seghdr);
  gate^.next_direct := seghdr^.direct_list;
  seghdr^.direct_list := gate;
  gate^.state := DirectGate;
  gate^.w1 := gate^.w2;
  gate^.w2 := segment;
  RETURN CARDINAL(gate);
END CallTrap;

PROCEDURE ReturnTrap(sd:CARDINAL):CARDINAL;
VAR
  seghdr            : SegPtr;
BEGIN
  seghdr := SegPtr(sd);
  RETURN LoadCode(seghdr);
END ReturnTrap;

PROCEDURE DoSeg(modnum:ModNum;segnum:SegNum;op:DoSegOp):CARDINAL;
CONST
  (* values for Fixup.lockind *)
  FixOfs  = 5;
  FixBase = 2;
  FixPtr  = 3;
VAR
  segment           : CARDINAL;
TYPE
  LocPtr            = POINTER segment TO RECORD
                                           lo,hi  : CARDINAL;
                                         END; (*LocPtr*)
  set               = SET OF [0..7];
  Fixup             = RECORD
                        lockind    : SHORTCARD;
                        flags      : SHORTCARD;
                        off        : CARDINAL;
                        CASE :SHORTCARD OF
                          0        : target_mod   : CARDINAL;
                                     target_ent   : CARDINAL;         |
                          1        : target_seg   : SegNum;
                                     target_off   : CARDINAL;         |
                        END; (*CASE*)
                      END; (*Fixup*)
VAR
  loc,next          : LocPtr;
  fixbuf            : POINTER TO ARRAY [1..999] OF Fixup;
  fix               : Fixup;
  fi                : CARDINAL;
  segsize           : CARDINAL;
  target_modnum     : ModNum;
  target_module     : Module;
  target_segment    : CARDINAL;
  target_attr       : SegSet;
  chain             : BOOLEAN;
  pos               : LONGCARD;
  fillcount         : CARDINAL;
  tempsize          : CARDINAL;
  gate              : GatePtr;
  target_seghdr     : SegPtr;
  module            : Module;
  seghdr            : SegPtr;
(*%T VidSupport*)
  vid_op            : VidAction;
(*%E*)
LABEL
  ordinal;

BEGIN
  module := g.module_list[modnum];
(*%T VidSupport*)
  IF op # Load THEN
    TellVid(modnum,segnum,VID_UNLOAD_SEG);
  END; (*IF*)
(*%E*)
  seghdr := SegPtr(HeapAdr(module^.seg_info^[segnum]));
(*%T CHECK*)
  IF (modnum > g.module_count)OR
     (segnum > module^.seg_count) THEN
     abort(ErrInternal);
  END; (*IF*)
(*%E*)
(*%T LoadTrace *)
(*%F MemoryTrace*)
 hex(g.freemem);
(*%E*)
(*%T MemoryTrace*)
 string('    ');
(*%E*)
 string('      ');
 CASE op OF
 |Load: string('Load: ');
 |Swap: string('Swap: ');
 |Discard:  string('Discard: ');
 END;
 string(g.module_list[modnum]^.name^);
 char('.');
 hex(segnum);
 string(' mem=');hex(seghdr^.membyte);
 string(' dsk=');hex(seghdr^.filebyte);
 string(' flags= ');
 IF IsData IN seghdr^.flags THEN string('Data ') END;
 IF IsIter IN seghdr^.flags THEN string('Iter ') END;
 IF IsMove IN seghdr^.flags THEN string('Move ') END;
 IF IsPure IN seghdr^.flags THEN string('Pure ') END;
 IF IsPreLoad IN seghdr^.flags THEN string('PreLoad ') END;
 IF IsExRd IN seghdr^.flags THEN string('ExRd ') END;
 IF HasReloc IN seghdr^.flags THEN string('HasReloc ') END;
 IF IsDiscard IN seghdr^.flags THEN string('Discard ') END;
 IF DataActive IN seghdr^.flags THEN string('DataActive ') END;
 eol;
(*%E*)
  IF seghdr^.membyte=1 THEN (* zero length segment *)
    IF op = Load THEN
      [Seg(DoSeg)-1:0 T]^.Lock := 7FFFH;
      RETURN Seg(DoSeg);
    END;
    RETURN 0;
  END;
  pos := LONGCARD(seghdr^.sector) << LONGCARD(module^.log_sector_size);
  segsize := Para(seghdr^.membyte);
  IF op = Load THEN
    seghdr^.fix_count := 0;
    IF (HasReloc IN seghdr^.flags) THEN
      IF ModuleRead(module,pos+LONGCARD(seghdr^.filebyte),
                    ADR(seghdr^.fix_count),2) THEN
(*%T CHECK*)
        abort(ErrOpenFail);
(*%E*)
      END; (*IF*)
    END;
    segment := IAlloc(segsize+Para(seghdr^.fix_count*SIZE(fix)),modnum,segnum,StaticSeg,
                      seghdr^.flags * SegSet{IsData,IsPreLoad} # SegSet{});
    IF ModuleRead(module,pos,[segment:0],seghdr^.filebyte) THEN
(*%T CHECK*)
        abort(ErrOpenFail);
(*%E*)
    END; (*IF*)
    fixbuf := [segment+segsize:0];
    IF seghdr^.fix_count>0 THEN (* read fixups *)
      IF ModuleRead(module,pos+LONGCARD(seghdr^.filebyte)+2,
                    fixbuf,seghdr^.fix_count*SIZE(fix)) THEN
(*%T CHECK*)
        abort(ErrOpenFail);
(*%E*)
      END; (*IF*)
    END;
(*%T GraphUseTrace*)
    IF seghdr^.flags*SegSet{IsData,IsPreLoad}=SegSet{} THEN
      GraphTrace(segnum+modnum*256,segment,GTadd);
    END;
(*%E*)
  ELSE
    segment := seghdr^.seg_val;
    fixbuf := [segment+segsize:0];
(*%T GraphUseTrace*)
    IF seghdr^.flags*SegSet{IsData,IsPreLoad}=SegSet{} THEN
      GraphTrace(segnum+modnum*256,segment,GTdel);
    END;
(*%E*)
    IF op = Swap THEN
      IF (~(IsData IN seghdr^.flags)) & IsActive(seghdr) THEN
        INCL(seghdr^.flags,DataActive);
      END; (*IF*)
      IF (SegSet{IsDiscard,IsExRd} * seghdr^.flags # SegSet{}) OR (modnum=g.delay) THEN
        op := Discard;
      END; (*IF*)
    END; (*IF*)
  END; (*IF*)
  fillcount := seghdr^.membyte-seghdr^.filebyte;
  IF ODD(fillcount) THEN
    DEC(fillcount)
  END; (*IF*)       (* OK as always an extra byte! *)
  TempXfer(op,seghdr^.seg_val,segment,seghdr^.filebyte,fillcount);
  IF is_mem(segment) & (op # Load) THEN
    SetIndirect(seghdr);
  END; (*IF*)
  IF (op = Swap) & (DataActive IN seghdr^.flags) THEN
    (* do nothing *)
  ELSIF seghdr^.fix_count=0 THEN
    (* do nothing *)
  ELSIF is_mem(segment) OR ((DataActive IN seghdr^.flags) & (op = Discard)) THEN
    fi := 0;
    WHILE fi<seghdr^.fix_count DO
      INC(fi);
      fix := fixbuf^[fi];
      chain := ~(2 IN set(fix.flags));
      fix.flags := fix.flags MOD 4;
      IF fix.flags = 0 THEN   (* internal fixup *)
        target_modnum := modnum;
        target_module := module;
        IF fix.target_seg = 0FFH THEN
          GOTO ordinal;
        END; (*IF*)
      ELSIF fix.flags = 1 THEN (* ordinal import *)
        target_modnum := ModNum(module^.module_table^[fix.target_mod]);
        target_module := g.module_list[target_modnum];
ordinal:
        fix.target_seg := CARDINAL(target_module^.entry_table^[fix.target_ent].seg);
        fix.target_off := target_module^.entry_table^[fix.target_ent].ofs;
      ELSE
(*%T CHECK*)
        abort(ErrNamedImport);   (* named import not supported *)
(*%E*)
      END; (*IF*)
      target_seghdr := GetSeg(target_module, fix.target_seg);
      target_attr := target_seghdr^.flags;
      IF op = Load THEN
        loc := LocPtr(fix.off);
        IF ~chain THEN
          INC(fix.target_off,loc^.lo);
        END; (*IF*)
        IF (fix.lockind = FixPtr) & (target_attr * SegSet{IsData,IsPreLoad} = SegSet{}) THEN
          fix.target_off := Gate(fix.target_off,target_seghdr,TRUE);
          target_segment := Seg(g);
        ELSE
          target_segment := target_seghdr^.seg_val;
          IF ~is_mem(target_segment) THEN
            target_segment := DoSeg(target_modnum,fix.target_seg,Load);
          ELSIF (~(IsPreLoad IN target_seghdr^.flags)) & ~(DataActive IN seghdr^.flags) THEN
            Lock(target_segment);
          END; (*IF*)
        END; (*IF*)
        IF fix.lockind = FixOfs THEN
          IF chain THEN
            REPEAT
              next := LocPtr(loc^.lo);
              loc^.lo := fix.target_off;
              loc := next;
            UNTIL loc = LocPtr(0FFFFH);
          ELSE
            loc^.lo := fix.target_off;
          END; (*IF*)
        ELSIF fix.lockind = FixBase THEN
          IF chain THEN
            REPEAT
              next := LocPtr(loc^.lo);
              loc^.lo := target_segment;
              loc := next;
            UNTIL loc = LocPtr(0FFFFH);
          ELSE
            loc^.lo := target_segment;
          END; (*IF*)
        ELSE
          IF chain THEN
            REPEAT
              next := LocPtr(loc^.lo);
              loc^.lo := fix.target_off;
              loc^.hi := target_segment;
              loc := next;
            UNTIL loc = LocPtr(0FFFFH);
          ELSE
            loc^.lo := fix.target_off;
            loc^.hi := target_segment;
          END; (*IF*)
        END; (*IF*)
      ELSE (* unloading *)
        IF (fix.lockind = FixPtr) & (target_attr * SegSet{IsData,IsPreLoad} = SegSet{}) THEN
          (* do nothing *)
        ELSIF IsPreLoad IN target_attr THEN
          (* do nothing *)
        ELSE
          target_segment := target_seghdr^.seg_val;
          IF is_mem(target_segment) THEN
            UnLock(target_segment);
          END; (*IF*)
        END; (*IF*)
      END; (*IF*)
    END; (*WHILE*)
    EXCL(seghdr^.flags,DataActive);
  END; (*IF*)
(*%T VidSupport*)
  IF op = Load THEN
    TellVid(modnum,segnum,VID_LOAD_SEG);
  END; (*IF*)
(*%E*)
  IF op = Load THEN
    RETURN segment;
  ELSE
    Free(segment);
    RETURN 0;
  END; (*IF*)
END DoSeg;


(* Virtual Segments - dynamically allocated segments that can be unlocked *)

PROCEDURE VAlloc(VAR addr : FarADDRESS; size : CARDINAL);
(* Allocates Virtual memory block of specified size (in bytes).
   returns result in addr.
   Block is initially fixed so VUnfix must be called before
   it can be swapped out.
   Address of addr is used as handle so only one variable must be used
   to hold pointer.
*)
VAR ptr : POINTER TO ARRAY[0..1] OF CARDINAL;
BEGIN
  ptr := ADR(addr);
  AllocMove(ptr^[1],Para(size));
  Lock(ptr^[1]);
  ptr^[0] := 0;
END VAlloc;

PROCEDURE VUnfix(VAR addr : FarADDRESS);
(*
   Unfixes memory allowing it to be moved or swapped to EMS or disk if
   memory runs low. The address should not be used to reference memory
   when unfixed.
*)
VAR ptr : POINTER TO ARRAY[0..1] OF CARDINAL;
BEGIN
  ptr := ADR(addr);
(*%T CHECK*)
  IF (ptr^[0]<>0)OR(~is_mem(ptr^[1]))OR([ptr^[1]-H:0 T]^.Kind<>MoveSeg) OR
     (NOT Locked(ptr^[1])) THEN
    abort(ErrInvalidVUnfix);
  END;
(*%E*)
  [ptr^[1]-H:0 T]^.Tick := IncTick(); (* LRU now, otherwise could get old while fixed *)
  UnLock(ptr^[1]);
  IF NOT Locked(ptr^[1]) THEN
    ptr^[0] := [ptr^[1]-H:0 T]^.Size-H;
    SwapMove(ptr^[1]);
  END;
END VUnfix;

PROCEDURE VFix(VAR addr : FarADDRESS);
(*
   Swaps block back into memory if necessary and
   fixes the address so it can be used.
   Calls to FixVSeg and UnfixVSeg may be nested.
*)
VAR ptr : POINTER TO ARRAY[0..1] OF CARDINAL;
BEGIN
  ptr := ADR(addr);
  IF ptr^[0]=0 THEN
(*%T CHECK*)
    IF (([ptr^[1]-H:0 T]^.Kind<>MoveSeg) AND ([ptr^[1]-H:0 T]^.Kind<>SwapSeg))OR
       ([ptr^[1]-H:0 T]^.Lock=0) THEN
      abort(ErrInvalidVFix);
    END;
(*%E*)
  ELSE
(*%T CHECK*)
    IF is_mem(ptr^[1]) AND ([ptr^[1]-H:0 T]^.Kind<>MoveSeg)
                   AND ([ptr^[1]-H:0 T]^.Kind<>SwapSeg) THEN
      abort(ErrInvalidVFix);
    END;
(*%E*)
    LoadMove(ptr^[1],ptr^[0]);
    ptr^[0] := 0;
  END;
  Lock(ptr^[1]);
END VFix;

PROCEDURE VFree(VAR addr : FarADDRESS);
(* frees virtual memory block
   can be called only when segment fixed
   addr is reset to NIL on exit
*)
VAR ptr : POINTER TO ARRAY[0..1] OF CARDINAL;
BEGIN
  VFix(addr);
  ptr := ADR(addr);
  WHILE Locked(ptr^[1]) DO
    UnLock(ptr^[1]);
  END;
  Free(ptr^[1]);
  addr := FarNIL;
END VFree;


PROCEDURE VUnfixAll();
(* Equivalent to calling VUnfix for all Virtual addresses allocated *)
VAR s : CARDINAL;
TYPE ap = POINTER TO ADDRESS;
BEGIN
  s := g.start;
  REPEAT
    IF [s:0 T]^.Kind=MoveSeg THEN
      WHILE Locked(s+H) DO
        VUnfix([[s:0 T]^.Id1:[s:0 T]^.Id2 ap]^); (* cannot upset loop *)
      END;
    END;
    INC(s,[s:0 T]^.Size);
  UNTIL s = g.start;
END VUnfixAll;



(* Tiny Allocation - (smaller overhead for upto 127 bytes) *)


CONST
  TinyMax = 16;
  TinyGranularity = 8;
  TinyMaxSize = TinyMax*TinyGranularity-1;
  TinyGranularityLog2 = 3;
VAR
  TinyFreeList : ARRAY[1..TinyMax] OF CARDINAL;

PROCEDURE TinyAlloc(size : CARDINAL):FarADDRESS;
(* only called for allocations of 1 to TinyMaxSize *)
VAR
    csize,i,seg : CARDINAL;
BEGIN
  csize := (size+(TinyGranularity-1))DIV TinyGranularity;
  seg := TinyFreeList[csize];
  IF seg=MAX(CARDINAL) THEN
    seg := AllocFixed(csize*TinyGranularity);
    IF seg=0 THEN RETURN FarNIL END;
    DEC(seg);
    [seg:0 T]^.Id1 := MAX(CARDINAL);
    [seg:0 T]^.Id2 := TinyFreeList[csize];
    TinyFreeList[csize] := seg;
  END;
(*%T CHECK*)
  IF ([seg:0 T]^.Id1=0) THEN
  END;
(*%E*)
  i := 0;
  WHILE NOT (i IN BITSET([seg:0 T]^.Id1)) DO INC(i) END;
  EXCL(BITSET([seg:0 T]^.Id1),i);
  IF [seg:0 T]^.Id1=0 THEN
    TinyFreeList[csize] := [seg:0 T]^.Id2;
  END;
  RETURN [seg+1:i*csize*TinyGranularity];
END TinyAlloc;

PROCEDURE TinyFree(p:FarADDRESS): BOOLEAN;
VAR
  seg,csize,i : CARDINAL;
BEGIN
  seg := Seg(p^)-1;
  WITH [seg:0 T]^ DO
    IF (Kind<>FixedSeg)OR(Id2=0) THEN RETURN FALSE END;
    csize := (Used-1)DIV TinyGranularity;
    i := CARDINAL(p)DIV(csize*TinyGranularity);
(*%T CHECK*)
    IF (csize=0)OR(csize>TinyMax)OR(i IN BITSET(Id1))OR
       (i*csize*TinyGranularity<>CARDINAL(p)) THEN
       abort(ErrInvalidFree);
    END;
    CheckAlloc(seg+1,ErrInvalidFree);
(*%E*)
    IF Id1=0 THEN
      Id2 := TinyFreeList[csize];
      TinyFreeList[csize] := seg;
    END;
    INCL(BITSET(Id1),i);
  END;
  RETURN TRUE;
END TinyFree;



PROCEDURE TinyFlush;
(* called occasionally to clean up tiny chains *)
VAR
  prev,ptr,next,i : CARDINAL;
BEGIN
  FOR i := 1 TO TinyMax DO
    prev := MAX(CARDINAL);
    ptr := TinyFreeList[i];
    WHILE ptr<>MAX(CARDINAL) DO
      WITH [ptr:0 T]^ DO
        next := Id2;
        IF Id1=MAX(CARDINAL) THEN
          IF prev=MAX(CARDINAL) THEN
            TinyFreeList[i] := next;
          ELSE
            [prev:0 T]^.Id2 := next;
          END;
          Id1 := 0;
          Id2 := 0;
          Free(ptr+1);
        ELSE
          prev := ptr;
        END;
      END;
      ptr := next;
    END;
  END;
END TinyFlush;

PROCEDURE TinyInit;
VAR i : CARDINAL;
BEGIN
  FOR i := 1 TO TinyMax DO
    TinyFreeList[i] := MAX(CARDINAL);
  END;
END TinyInit;

TYPE
  ExeHeader         = RECORD
                        magic1,magic2      : CHAR;
                        link_version       : SHORTCARD;
                        link_revision      : SHORTCARD;
                        entry_table_off    : CARDINAL;
                        entry_table_size   : CARDINAL;
                        crc                : LONGCARD;
                        flag               : CARDINAL;
                        dgroup             : CARDINAL;
                        small_heap_size    : CARDINAL;
                        small_stack_size   : CARDINAL;
                        ip,cs,sp,ss        : CARDINAL;
                        seg_count          : CARDINAL;
                        lib_count          : CARDINAL;
                        non_res_name_size  : CARDINAL;
                        seg_off            : CARDINAL;
                        resource_off       : CARDINAL;
                        res_name_off       : CARDINAL;
                        module_ref_off     : CARDINAL;
                        imp_name_off       : CARDINAL;
                        non_res_name_off   : LONGCARD;
                        mov_entry_count    : CARDINAL;
                        log_sector_size    : CARDINAL;
                        reserved           : ARRAY [0..11] OF SHORTCARD;
                      END; (*ExeHeader*)


TYPE InitProc = PROCEDURE():CARDINAL;

PROCEDURE InternalLoadModule(name:ARRAY OF CHAR;is_exe:BOOLEAN;stage:ModStage):CARDINAL;

VAR
  modnum            : ModNum;
  module            : Module;
  len               : CARDINAL;
  hpos              : LONGCARD;
  hdr               : ExeHeader;
  i                 : CARDINAL;
  libname           : ARRAY [0..255] OF CHAR;
  bundle            : RECORD
                        ne         : SHORTCARD;
                        si         : SHORTCARD;
                      END; (*bundle*)
  fs                : RECORD
                        flags      : SHORTCARD;
                        off        : CARDINAL;
                      END; (*fs*)
  fs6               : RECORD
                        flags      : SHORTCARD;
                        int3       : CARDINAL;
                        seg        : SHORTCARD;
                        off        : CARDINAL;
                      END; (*fs6*)
  eseg              : SHORTCARD;
  eoff              : CARDINAL;
  SecondPass        : BOOLEAN;
  epass             : SHORTCARD[0..1];
  done              : CARDINAL;
  ord               : CARDINAL;
  cs                : CARDINAL;
  p                 : InitProc;
  impnameoff        : CARDINAL;
  dummy             : CARDINAL;
  submod            : CARDINAL;
  substage          : ModStage;
  pss               : CARDINAL;
  buf_index         : CARDINAL;
  buffer            : ARRAY [0..511] OF SHORTCARD;

  PROCEDURE Read2(a:ADDRESS;count:CARDINAL);
  VAR
    avail           : CARDINAL;
  BEGIN
    LOOP
      avail := SIZE(buffer) - buf_index;
      IF avail > count THEN
        avail := count;
      END; (*IF*)
      Move(ADR(buffer[buf_index]),a,avail);
      INC(buf_index,avail);
      DEC(count,avail);
      IF count = 0 THEN
        EXIT;
      END; (*IF*)
      INC(CARDINAL(a),avail);
      FileRead(ADR(buffer),SIZE(buffer),module^.file);
      buf_index := 0;
    END; (*LOOP*)
  END Read2;

  PROCEDURE Seek2(pos:LONGCARD);
  BEGIN
    buf_index := SIZE(buffer);
    FileSeek(module^.file,pos);
  END Seek2;

  PROCEDURE Read(pos:LONGCARD;a:ADDRESS;count:CARDINAL):BOOLEAN;
  BEGIN
    buf_index := SIZE(buffer);
    RETURN ModuleRead(module,pos,a,count);
  END Read;

BEGIN
  modnum := 1;
  LOOP
    IF modnum > g.module_count THEN
      module := New(SIZE(module^));
      len := Length(name) + 1;
      module^.name := New(len);
      Append(module^.name^,name);
      IF modnum > MaxModule THEN
        abort(ErrModuleLimit);
      END; (*IF*)
      g.module_count := modnum; (* should be check for > MaxModule *)
      g.module_list[modnum] := module;
      module^.file := MAX(CARDINAL);
      module^.is_exe := is_exe;
(*%T GraphUseTrace*)
      string('Module ');hex(modnum);string(' = ');string(name);eol;
(*%E*)
      EXIT;
    END; (*IF*)
    module := g.module_list[modnum];
    IF Compare(module^.name^,name) & (module^.is_exe = is_exe) THEN
      EXIT;
    END; (*IF*)
    INC(modnum);
  END; (*LOOP*)
  IF module^.stage < stage THEN
    (* read header *)
    IF Read(3CH,ADR(hpos),SIZE(hpos)) OR Read(hpos,ADR(hdr),SIZE(hdr)) OR (hdr.magic1 # 'N') THEN
      RETURN 0;
    END; (*IF*)
    REPEAT
      INC(module^.stage);
      CASE module^.stage OF
        internal_stage (* verify header, build basic tables, allocate module table *)
                    :(* allocate module table *)
                      module^.module_table := New(hdr.lib_count * 2);
                     (* build segment table *)
                      module^.seg_count := hdr.seg_count;
                      module^.log_sector_size := hdr.log_sector_size;
                      module^.seg_info := New(hdr.seg_count * SIZE(SegRec));
                      Seek2(hpos + LONGCARD(hdr.seg_off));
                      buf_index := SIZE(buffer);
                      FOR i := 1 TO hdr.seg_count DO
                        WITH module^.seg_info^[i] DO
                          Read2(ADR(sector),8);
                          no_op := 90H;
                          jump_op := 0E9H;
                          jump_disp := CARDINAL(HeapAdr(LoaderA.GateHandler)) - CARDINAL(HeapAdr(jump_disp)) - 2;
                        END; (*WITH*)
                      END; (*FOR*)
                     (* build entry table *)
                      IF EntryTableTrace THEN
                        string('entry table for ');
                        string(module^.name^);
                        eol;
                      END; (*IF*)
                      FOR SecondPass := FALSE TO TRUE DO
                        Seek2(hpos + LONGCARD(hdr.entry_table_off));
                        ord := 0;
                        done := 0;
                        WHILE done < hdr.entry_table_size DO
                          Read2(ADR(bundle),2);
                          INC(done,2);
                          FOR i := 1 TO CARDINAL(bundle.ne) DO
                            INC(ord);
                            IF bundle.si = 255 THEN
                              Read2(ADR(fs6),SIZE(fs6));
                              INC(done,SIZE(fs6));
                              eseg := fs6.seg;
                              eoff := fs6.off;
                            ELSE
                              Read2(ADR(fs), SIZE(fs));
                              INC(done, SIZE(fs));
                              eseg := bundle.si;
                              eoff := fs.off;
                            END; (*IF*)
                            IF SecondPass THEN
                              module^.entry_table^[ord].seg := eseg;
                              module^.entry_table^[ord].ofs := eoff;
                              IF EntryTableTrace THEN
                                dec(ord);
                                char('=');
                                dec(CARDINAL(module^.entry_table^[ord].seg));
                                char(':');
                                hex(CARDINAL(module^.entry_table^[ord].ofs));
                                eol;
                              END; (*IF*)
                            END; (*IF*)
                          END; (*FOR*)
                        END; (*WHILE*)
                        IF ~SecondPass THEN
                          module^.entry_table := New(ord * SIZE(EntryRec));
                        END; (*IF*)
                      END; (*FOR*)                                    |
        sub_module_stage (* fill in module table, initialise sub-modules up to stage 2 *)
                    : FOR i := 1 TO hdr.lib_count DO
                        len := 0;
                        IF Read(hpos+LONGCARD(hdr.module_ref_off+(i-1)*2),ADR(impnameoff),SIZE(impnameoff)) OR Read(hpos+LONGCARD(hdr.imp_name_off+impnameoff),ADR(len),1) THEN
                          RETURN 0;
                        END; (*IF*)
                        Read2(ADR(libname),len);
                        libname[len] := 0C;
                        submod := InternalLoadModule(libname,FALSE,sub_module_stage);
                        IF submod = 0 THEN
                          RETURN 0;
                        END;(*IF*)
                        module^.module_table^[i] := SHORTCARD(submod);
                      END; (*FOR*)                                    |
        execute_stage    (* execute sub-module entry points *)
                    :
                      FOR i := 1 TO hdr.lib_count DO
                        submod := CARDINAL(module^.module_table^[i]);
                        IF InternalLoadModule(g.module_list[submod]^.name^,FALSE,execute_stage) = 0 THEN
                          RETURN 0;
                        END; (*IF*)
                      END; (*FOR*)
(*%T VidSupport*)
                      TellVid(modnum,0,VID_LOAD_MODULE);
(*%E*)
                     (* execute entry-point *)
                      cs := DoSeg(modnum,hdr.cs,Load);
(*                    UnLock(cs);  -- only if not packed *)
                      IF is_exe THEN
                        pss := DoSeg(modnum,hdr.ss,Load);
                        WITH [g.stk-1:0 T]^ DO
                          INC([Prev:0 T]^.Size,800H);
                          [g.stk-1+Size:0 T]^.Prev := Prev;
                          INC(g.freemem,800H);
                        END; (*WITH*)
                        Exec(g.psp,pss,hdr.sp,cs,hdr.ip);
                      ELSE
                        p := InitProc([cs:hdr.ip]);
                        dummy := p();
                      END; (*IF*)
      END; (*CASE*)
    UNTIL module^.stage = stage;
  END; (*IF*)
  RETURN modnum;
END InternalLoadModule;

PROCEDURE LoadModule  (name:ARRAY OF CHAR):CARDINAL;
VAR
  modnum:CARDINAL;
BEGIN
  IF (g.delay=0) OR Compare(g.module_list[g.delay]^.name^, name) THEN
    g.delay := 0;
  ELSE
    DoDelay;
  END;
  modnum := InternalLoadModule(name,FALSE,execute_stage);
  IF modnum = 0 THEN
    modnum := MAX(CARDINAL); (* external convention *)
  END;
  RETURN modnum;
END LoadModule;

PROCEDURE GetProcAddr (modnum:CARDINAL;entry: ARRAY OF CHAR):ADDRESS;
VAR s : SHORTCARD;
    str : ARRAY [0..255] OF CHAR;
    ord : CARDINAL;
    a :FarADDRESS;
    Nonres : BOOLEAN;
    module : Module;
    hpos : LONGCARD;
    hdr : ExeHeader;
    i : CARDINAL;
BEGIN
  module := g.module_list[modnum];
  IF ModuleRead(module,3CH,ADR(hpos),SIZE(hpos))OR
     ModuleRead(module,hpos,ADR(hdr),SIZE(hdr)) THEN
     RETURN FarNIL;
  END;
  FileSeek(module^.file,hpos+LONGCARD(hdr.res_name_off));
  ord := 0;
  Nonres := FALSE;
  LOOP
    FileRead(ADR(s),1,module^.file);
    IF s=0 THEN
       IF Nonres THEN
          EXIT;
       ELSE
          Nonres := TRUE;
          FileSeek(module^.file,hdr.non_res_name_off);
       END;
    ELSE
       FileRead(ADR(str),CARDINAL(s),module^.file);
       str[CARDINAL(s)]:= 0C;
       FileRead(ADR(ord),2,module^.file);
       i := 0;
       WHILE (str[i]=entry[i]) DO
         INC(i);
         IF (i=CARDINAL(s)) THEN
           IF (entry[i]=0C) THEN EXIT END;
           str[i] := 0C;
         END;
       END;
    END;
  END;
  IF ord=0 THEN RETURN FarNIL END;
  RETURN GetOrdProcAddr(modnum,ord);
END GetProcAddr;

PROCEDURE FlushAll;
BEGIN
  DoDelay;
  DoFlushAll;
END FlushAll;


PROCEDURE Terminate;
BEGIN
(*%T ExitTrace*)
  eol;
  IF TraceToFile THEN
    FlushAll;
    DumpMemory;
    eol;
  END; (*IF*)
  MemStat;
  string('Gate count   =  ');
  dec(g.gate_count);
  eol;
  string('Module count =  ');
  dec(g.module_count);
  eol;
(*%T EMS*)
  string('Ems pages    =  ');
  dec(g.ems_count);
  eol;
(*%E*)
  string('Heap used    =  ');
  hex(g.near_alloc-CARDINAL(Ofs(g.heap)));
  char('H');
  eol;
  string('Temp file  =  ');
  hex(g.temp_max*(TempPageSize DIV 256));
  string('00H');
  eol;
(*%E*)

  FileClose(g.temp_file);
  FileDelete(FullTempFileName);
(*%T EMS*)
  IF g.ems_data_handle # 0 THEN
    EmsMap(4500H,0,g.ems_data_handle); (* free pages *)
  END; (*IF*)
  IF g.ems_temp_handle # 0 THEN
    EmsMap(4500H,0,g.ems_temp_handle); (* free temp pages *)
  END; (*IF*)
(*%E*)
END Terminate;

PROCEDURE AllocMem(size:CARDINAL):FarADDRESS;
BEGIN
  IF size = 0 THEN
    RETURN FarNIL;
  END; (*IF*)
  IF size<=TinyMaxSize THEN
    RETURN TinyAlloc(size);
  END;
  RETURN [AllocFixed(Para(size)):0];
END AllocMem;

PROCEDURE FreeMem(ofs,seg:CARDINAL);
BEGIN
  IF NOT TinyFree([seg:ofs]) THEN
    Free(seg);
  END;
END FreeMem;

PROCEDURE ClearAllocMem(num,size:CARDINAL):FarADDRESS;
VAR
  res : FarADDRESS;
BEGIN
  size := num * size;
  IF size = 0 THEN
    RETURN FarNIL;
  END; (*IF*)
  IF size<=TinyMaxSize THEN
    res := TinyAlloc(size);
  ELSE
    res := [AllocFixed(Para(size)):0];
  END;
  IF res<>FarNIL THEN
    Fill(res,size,0);
  END;
  RETURN res;
END ClearAllocMem;

PROCEDURE HugeAllocMem(size:LONGCARD):FarADDRESS;
BEGIN
  RETURN [AllocFixed(CARDINAL((size+15) DIV 16)):0];
END HugeAllocMem;

PROCEDURE ExpandMem(Buffer:FarADDRESS;newsize:CARDINAL):FarADDRESS;
VAR
  seg,next          : CARDINAL;
BEGIN
  seg := Seg(Buffer^) - H;
  newsize := Para(newsize) + H;
  LOOP
    WITH [seg:0 T]^ DO
      IF Size >= newsize THEN
        INC(g.freemem,Used);
        DEC(g.freemem,newsize);
        Used := newsize;
        RETURN Buffer;
      ELSE
        next := seg + Size;
        IF [next:0 T]^.Used = 0 THEN
          INC(Size,[next:0 T]^.Size);
          next := seg + Size;
          [next:0 T]^.Prev := seg;
        ELSE
          RETURN FarNIL;
        END; (*IF*)
      END; (*IF*)
    END; (*WITH*)
  END; (*LOOP*)
END ExpandMem;

PROCEDURE HugeExpandMem(Buffer:FarADDRESS;newsize:LONGCARD):FarADDRESS;
VAR
  seg,next,NewCard  : CARDINAL;
BEGIN
  seg := Seg(Buffer^) - H;
  NewCard := CARDINAL((newsize + 15) DIV 16) + H;
  LOOP
    WITH [seg:0 T]^ DO
      IF Size >= NewCard THEN
        INC(g.freemem,Used);
        DEC(g.freemem,NewCard);
        Used := NewCard;
        RETURN Buffer;
      ELSE
        next := seg + Size;
        IF [next:0 T]^.Used = 0 THEN
          INC(Size,[next:0 T]^.Size);
          next := seg + Size;
          [next:0 T]^.Prev := seg;
        ELSE
          RETURN FarNIL;
        END; (*IF*)
      END; (*IF*)
    END; (*WITH*)
  END; (*LOOP*)
END HugeExpandMem;

PROCEDURE InvalidProc;
BEGIN
  abort(ErrInvalidProcedure);
END InvalidProc;


CONST
  HEAPOK              = 0;
  HEAPEMPTY           = -1;
  HEAPBADBEGIN        = -2;
  HEAPBADNODE         = -3;
  HEAPOVERFLOW        = -4;
  HEAPEND             = -5;
  HEAPBADPTR          = -6;

PROCEDURE HeapCheck(Val:CARDINAL;DoFill:BOOLEAN):INTEGER;
VAR
  TSeg              : CARDINAL;
BEGIN
  TSeg := g.start;
  REPEAT
    WITH [TSeg:0 T]^ DO
      IF Size = 0 THEN
        RETURN HEAPBADNODE;
      END; (*IF*)
      IF DoFill & (Used < Size) THEN
        Fill([TSeg+Used:0],(Size-Used)*16,Val);
      END; (*IF*)
      INC(TSeg,Size);
    END; (*WITH*)
  UNTIL TSeg = g.start;
  RETURN HEAPOK;
END HeapCheck;

PROCEDURE HeapWalk(VAR Entry:HeapInfo):INTEGER;
BEGIN
  WITH Entry DO
    IF pentry = FarNIL THEN
      pentry := [g.start:0];
    ELSE
      pentry := [Seg(pentry^) + T(pentry)^.Size:0];
    END; (*IF*)
    WITH T(pentry)^ DO
      IF Seg(pentry^) = g.start THEN
        RETURN HEAPEND;
      END; (*IF*)
      IF Size = 0 THEN
        RETURN HEAPBADNODE;
      ELSE
        size := Size * 16;
      END; (*IF*)
      useflag := Used > 0;
    END; (*WITH*)
  END; (*WITH*)
  RETURN HEAPOK;
END HeapWalk;

(*# save,call(reg_param=>(bx,ax),reg_saved=>(cx,dx,di,si,ds,st1,st2),inline=>on)*)
PROCEDURE DOSAllocMem(Para:CARDINAL):CARDINAL = A4(0B4H,048H,0CDH,021H);
PROCEDURE DOSResizeMem(Para,Seg:CARDINAL)     = A6(08EH,0C0H,0B4H,04AH,0CDH,021H);
PROCEDURE DOSFreeMem(Para:CARDINAL)           = A6(08EH,0C3H,0B4H,049H,0CDH,021H);
(*# call(reg_return=>(bx))*)
PROCEDURE DOSMemAvail():CARDINAL              = A7(0B4H,048H,0BBH,0FFH,0FFH,0CDH,021H);
(*# restore *)

VAR
AvailMem,AvailSeg   : CARDINAL;
HighMem,HighSeg     : CARDINAL;

PROCEDURE ShrinkHeap():CARDINAL;
BEGIN
  FlushAll;
  AvailMem := Avail();
  IF AvailMem>800H THEN DEC(AvailMem,800H); END; (* needed to reload caller *)
  AvailSeg := AllocFixed(AvailMem);
  DOSResizeMem((AvailSeg + AvailMem) - g.psp - 1,g.psp);
  HighMem  := DOSMemAvail();
  HighSeg  := DOSAllocMem(HighMem);
  DOSResizeMem(AvailSeg - g.psp,g.psp);
  RETURN 0;
END ShrinkHeap;

PROCEDURE GrowHeap;
BEGIN
  DOSFreeMem(HighSeg);
  DOSResizeMem((AvailSeg + AvailMem + HighMem) - g.psp,g.psp);
  Free(AvailSeg);
END GrowHeap;

PROCEDURE UserFlush;
BEGIN
  FlushAll;
END UserFlush;

PROCEDURE SetExitHandler(p:ExitHandler);
BEGIN
  g.abort := p;
  reserve_panic;
END SetExitHandler;

PROCEDURE SetMemHandler(p:MemHandler);
BEGIN
  g.OutOfMem := p;
END SetMemHandler;

PROCEDURE LoadSeg(segno:CARDINAL;ModName:ARRAY OF CHAR):SegReturn;
VAR
  modno             : CARDINAL;
BEGIN
  modno := 1;
  IF ModName[0] # 0C THEN
    LOOP
      IF Compare(g.module_list[modno]^.name^,ModName) THEN
        EXIT;
      END; (*IF*)
      INC(modno);
      IF modno > g.module_count THEN
        RETURN INVALID_MOD;
      END; (*IF*)
    END; (*LOOP*)
  END; (*IF*)
  WITH g.module_list[modno]^ DO
    IF segno > seg_count THEN
      RETURN INVALID_SEG;
    ELSIF seg_info^[segno].direct_list # GatePtr(0) THEN
      RETURN RESIDENT;
    ELSIF DoSeg(modno,segno,Load) # 0 THEN
      RETURN SUCCESS;
    ELSE
      RETURN FAIL;
    END; (*IF*)
  END; (*WITH*)
END LoadSeg;

PROCEDURE UnloadSeg(segno:CARDINAL;ModName:ARRAY OF CHAR):SegReturn;
VAR
  modno             : CARDINAL;
BEGIN
  modno := 1;
  IF ModName[0] # 0C THEN
    LOOP
      IF Compare(g.module_list[modno]^.name^,ModName) THEN
        EXIT;
      END; (*IF*)
      INC(modno);
      IF modno > g.module_count THEN
        RETURN INVALID_MOD;
      END; (*IF*)
    END; (*LOOP*)
  END; (*IF*)
  WITH g.module_list[modno]^ DO
    IF segno > seg_count THEN
      RETURN INVALID_SEG;
    ELSIF seg_info^[segno].direct_list = GatePtr(0) THEN
      RETURN UNLOADED;
    ELSIF DoSeg(modno,segno,Swap) = 0 THEN
      RETURN SUCCESS;
    ELSE
      RETURN FAIL;
    END; (*IF*)
  END; (*WITH*)
END UnloadSeg;

PROCEDURE Getseg(seg:CARDINAL):CARDINAL;
VAR
  i,j               : CARDINAL;
BEGIN
  FOR i := 1 TO g.module_count DO
    WITH g.module_list[i]^ DO
      FOR j := 1 TO seg_count DO
        WITH seg_info^[j] DO
          IF seg_val = seg THEN
            RETURN j;
          END; (*IF*)
        END; (*WITH*)
      END; (*FOR*)
    END; (*WITH*)
  END; (*FOR*)
  RETURN 0;
END Getseg;


(*# save, call(same_ds=>off) *)
PROCEDURE default_abort(name:ARRAY OF CHAR;errno:CARDINAL);
(*# restore *)
BEGIN
  eol;
(*%T CHECK*)
  string('Loader fatal error : ');
  dec(errno);
  string(', ');
(*%E*)
  CASE errno-ErrBase OF (* only startup errors should be possible *)
    ErrTempCreate   : string('Failed to create ');
                      string(FullTempFileName);                       |
    ErrLoad         : string('DLL load failed. Is your PATH set correctly?');|
    (* happens when ts.exe in local directory but path not set up *)
    ErrOutOfMem:      string('Out of memory');|
    ErrTempDiskFull:  string('Disk full on swap file');|
(*%T CHECK*)
    ErrTempFileLimit : string('ErrTempFileLimit'); |
    ErrPoolLimit     : string('ErrPoolLimit'); |
    ErrGateLimit     : string('ErrGateLimit'); |
    ErrDiskFull      : string('ErrDiskFull'); |
    ErrInternal      : string('ErrInternal'); |
    ErrNearHeap      : string('ErrNearHeap'); |
    ErrModuleLimit    : string('ErrModuleLimit'); |
    ErrInvalidProcedure : string('ErrInvalidProcedure'); |
    ErrMemoryCorruption : string('ErrMemoryCorruption'); |
    ErrTooManyUnlocks   : string('ErrTooManyUnlocks'); |
    ErrCallChainInvalid : string('ErrCallChainInvalid'); |
    ErrOpenFail         : string('ErrOpenFail'); |
    ErrNamedImport      : string('ErrNamedImport'); |
    ErrInvalidVUnfix    : string('ErrInvalidVUnfix'); |
    ErrInvalidVFix      : string('ErrInvalidVFix'); |
    ErrInvalidFree      : string('ErrInvalidFree'); |
  END;
(*%E*)
(*%F CHECK*)
  ELSE
    string('Overlay loader fatal error : ');
    dec(errno);
  END; (*CASE*)
(*%E*)
  eol;
END default_abort;

(*# save, call(same_ds=>off) *)
PROCEDURE default_MemHandler(Size:CARDINAL):BOOLEAN;
(*# restore *)
BEGIN
  RETURN FALSE;
END default_MemHandler;

PROCEDURE Init(psp:CARDINAL); FORWARD;

(* Note this proc is overwritten by memory initialisation !! *)
PROCEDURE GetFullTempFileName(s:ARRAY OF CHAR);
VAR
  drive             : SHORTCARD;
  p                 : ARRAY SHORTCARD OF CHAR;
BEGIN
  drive := GetCurDrive();
  GetCurDir(0,p);
  s[0] := CHR(drive + ORD('A'));
  IF p[0] = 0C THEN
    s[2] := 0C;
  ELSE
    s[3] := 0C;
    Append(s,p);
  END; (*IF*)
  Append(s,TempFileName);
END GetFullTempFileName;

PROCEDURE MakeSys(seg:CARDINAL);
VAR next,prev:CARDINAL;
BEGIN
  (* links seg into memory list, initialises it to be a free seg *)
  next := g.start;
  LOOP
    prev := [next:0 T]^.Prev;
    IF seg <= g.start THEN
      g.start := seg;
      EXIT;
    END;
    IF prev <= seg THEN
      EXIT;
    END;
    next := prev;
  END;
  WITH [next:0 T]^ DO
    Prev := seg;
  END;
  WITH [prev:0 T]^ DO
    Size := seg-prev;
    Used := seg-prev;
  END;
  WITH [seg:0 T]^ DO
    Size := next - seg;
    Used := next - seg;
    Prev := prev;
    Active := FALSE;
    Kind := SystemSeg;
    Id1 := 0;
    Id2 := 0;
    Lock := 1;
  END;
END MakeSys;

PROCEDURE Init(psp:CARDINAL);
VAR
  m                 : CARDINAL;
  code              : CARDINAL;
  cp                : POINTER TO ARRAY [0..255] OF CHAR;
  i                 : CARDINAL;
  drive             : SHORTCARD;
LABEL
  NoEms;
BEGIN
  Fill(ADR(g),SIZE(g),0);
  TinyInit;
(*%T TraceToFile*)
  output_file := FileCreate('otrace.txt');
(*%E*)
(*%T VidSupport*)
  FindVid;
(*%E*)
(*%T GraphUseTrace*)
  Fill(ADR(graphsegs),SIZE(graphsegs),0);
(*%E*)

  g.abort := default_abort;
  g.OutOfMem := default_MemHandler;
  g.near_alloc := CARDINAL(Ofs(g.heap));
  GetFullTempFileName(FullTempFileName);
(*#save,data(const_assign=>on)*)
  g.temp_file := FileCreateNew(FullTempFileName);
(*#restore*)
  IF g.temp_file = MAX(CARDINAL) THEN
    abort(ErrTempCreate);
    RETURN;
  END; (*IF*)
  g.psp := psp;
  code  := Seg(Main)  - H;
  g.stk := Seg(psp)   + 2;
  g.end := CARDINAL([g.psp:2]^) - H;
  g.start := code - 1;
  [g.start:0 T]^.Prev := g.start;
  MakeSys(code-1);
  MakeSys(code);
  MakeSys(g.stk-1);
  MakeSys(g.end);
  WITH [g.stk-1:0 T]^ DO
    Used := 0800H;
    INC(g.freemem,Size-Used);
  END; (*WITH*)
  [g.stk:0]^ := 0;
  WITH loader_module.seg_info^[1] DO
    membyte := Ofs(Init);
    jump_disp := CARDINAL(HeapAdr(LoaderA.GateHandler)) - CARDINAL(HeapAdr(jump_disp)) - 2;
    seg_val := code + H;
  END; (*WITH*)
  WITH [code:0 T]^ DO (* will overwrite program entry ! *)
    Kind := StaticSeg;
    Id1  := 1;
    Id2  := 1;
  END; (*WITH*)
  g.module_count := 1;
  g.module_list[1] := Module(HeapAdr(loader_module));
(*%T CHECK*)
  CheckMem;
(*%E*)
  reserve_panic;
(* get ems frame *)
  g.ems_frame := 0E000H; (* dummy value when no ems *)
(*%T EMS*)
  cp := [[0:19CH+2]^:0AH];
  FOR i := 0 TO 7 DO
    IF cp^[i] # EmsName[i] THEN
      GOTO NoEms;
    END; (*IF*)
  END; (*FOR*)
  IF EmsTest(4000H) = 0 THEN
    g.ems_frame := EmsGet(4100H); (* get frame *)
    g.ems_present := TRUE;
  END; (*IF*)
(*%E*)
NoEms:
  m := InternalLoadModule(MainName,TRUE,execute_stage);
(* returns only if error *)
  abort(ErrLoad);
END Init;

PROCEDURE Main(psp:CARDINAL);
BEGIN
  Init(psp);
END Main;

END Loader.

