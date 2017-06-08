{
  "RTC Image Encoder"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcXImgEncode;

interface

{$include rtcDefs.inc}

uses
  Classes,
  SysUtils,

  rtcInfo,
  rtcTypes,
  rtcZLib,

  memXList,
  memItemList,
  rtcLog,

  rtcXJPEGConst,
  rtcXJPEGEncode,

  rtcXImgConst,
  rtcXCompressRLE,

  rtcXBmpUtils;

const
  IMG_BLOCK_X=8;
  IMG_BLOCK_Y=8;
  IMG_BLOCK_X_SHIFT=3; // divide: 3 bits
  IMG_BLOCK_Y_SHIFT=3; // divide: 3 bits
  IMG_BLOCK_X_MOD=7; // modulo: 3 bits
  IMG_BLOCK_Y_MOD=7; // module: 3 bits
  IMG_BLOCK_SIZE=IMG_BLOCK_X * IMG_BLOCK_Y;
  IMG_BLOCK_SIZE_SHIFT=IMG_BLOCK_X_SHIFT + IMG_BLOCK_Y_SHIFT;

  DIRT_MARK_MIN  =-4;
  DIRT_MARK_BAD  =-1;
  DIRT_MARK_OK   = 0;
  DIRT_MARK_GOOD = 1;
  DIRT_MARK_MOVE = 4;
  DIRT_MARK_MAX  =16;

  ScanPosX:array[0..IMG_BLOCK_SIZE-1] of shortint = (4,2,2,6,6,1,7,4,
                                       4,0,0,7,7,0,2,3,
                                       3,5,5,0,5,2,6,4,
                                       4,3,1,7,1,1,7,2,
                                       7,0,3,6,2,5,3,5,
                                       3,6,2,5,1,4,6,0,
                                       4,5,3,1,3,6,0,7,
                                       1,2,7,5,0,4,6,1);
  ScanPosY:array[0..IMG_BLOCK_SIZE-1] of shortint = (4,2,6,2,6,4,4,1,
                                       7,0,7,7,0,2,0,5,
                                       3,3,5,5,0,4,4,2,
                                       6,1,1,2,3,6,5,7,
                                       3,3,7,0,5,7,4,2,
                                       0,1,3,6,2,5,5,4,
                                       5,4,2,5,6,3,1,1,
                                       7,1,6,1,6,0,7,0);

type
  ShortIntArray = array of shortint;
  PColorBGR32 = ^colorbgr32;
  PColorRGB32 = ^colorrgb32;

  TRtcImageEncoder=class(TRtcJPEGEncoder)
  private
    FScanMoves,
    FLastFrame,
    FFirstFrame: boolean;
    FMotionComp: boolean;
    FColorComp: boolean;
    FColorReduce: integer;

    FLZWCompress: boolean;
    FRLECompress: boolean;
    FJPGCompress: boolean;
    FLastReduceColors,
    FLastColorComp: Cardinal;

    ImgTree:tItemSearchList;
    FMotionFullScan: boolean;
    FMotionVertScan: boolean;
    FMotionHorzScan: boolean;
    FMotionFullScanLimit: Cardinal;
    FMotionHorzScanLimit: Cardinal;
    FMotionVertScanLimit: Cardinal;
    FColorBitsB: integer;
    FColorBitsG: integer;
    FColorBitsR: integer;
    FColorDiffB: integer;
    FColorDiffG: integer;
    FColorDiffR: integer;
    FColorMask: LongWord;

    FRLEBuffer: RtcByteArray;

    LastMSX,LastMSY,
    LastJSX,LastJSY:integer;
    fromIDs,toIDs:array of integer;
    toColors:array of LongWord;
    changedIDs:array of byte;
    scanIDs:array of boolean;
    dirtMarks:ShortIntArray;

    ScanMoves:array[0..IMG_BLOCK_SIZE-1] of integer;

    procedure SetJPGCompress(const Value: boolean);
    procedure SetLZWCompress(const Value: boolean);
    procedure SetRLECompress(const Value: boolean);

    function ImageItemSimilar(left,right:integer):boolean;

    procedure SetBlockColor(left:integer; right:LongWord);
    function GetBlockColor(left:integer):LongWord;
    function GetBlockColorAvg(left:integer):LongWord;
    function SingleColorBlock(left:integer):boolean;

    function ImageItemCompare(left,right:integer):integer;

    function ImageItemEqual(left,right:integer):integer;
    function ImageItemChanged(left,right:integer):boolean;
    procedure ImageItemCopy(left,right:integer);

    function  CompensateMotion:RtcByteArray;
    procedure ClearImageSearchTree;

    procedure SetMotionComp(const Value: boolean);
    procedure SetColorComp(const Value: boolean);

    procedure SetMotionFullScan(const Value: boolean);
    procedure SetMotionHorzScan(const Value: boolean);
    procedure SetMotionVertScan(const Value: boolean);
    procedure SetMotionFullScanLimit(const Value: Cardinal);
    procedure SetMotionHorzScanLimit(const Value: Cardinal);
    procedure SetMotionVertScanLimit(const Value: Cardinal);
    procedure SetColorBitsB(const Value: integer);
    procedure SetColorBitsG(const Value: integer);
    procedure SetColorBitsR(const Value: integer);
    procedure SetColorReduce(const Value: integer);

  public
    OldBmpInfo,
    NewBmpInfo: TRtcBitmapInfo;

    constructor Create(const BmpInfo:TRtcBitmapInfo);
    destructor Destroy; override;

    procedure ReduceColors(var BmpInfo:TRtcBitmapInfo);

    function NeedRefresh: boolean;
    function BitmapChanged: boolean;

    procedure LastFrame;
    procedure FirstFrame;
    procedure FrameComplete;

    function CompressMOT: RtcByteArray;
    function CompressJPG: RtcByteArray;
    function CompressRLE: RtcByteArray;

    function CompressMouse(const MouseCursorInfo:RtcByteArray; LZW:boolean=False): RtcByteArray;

    property JPGCompress:boolean read FJPGCompress write SetJPGCompress default False;
    property RLECompress:boolean read FRLECompress write SetRLECompress default False;
    property LZWCompress:boolean read FLZWCompress write SetLZWCompress default False;

    property MotionComp:boolean read FMotionComp write SetMotionComp default False;
    property ColorComp:boolean read FColorComp write SetColorComp default False;

    property MotionHorzScan:boolean read FMotionHorzScan write SetMotionHorzScan default False;
    property MotionVertScan:boolean read FMotionVertScan write SetMotionVertScan default False;
    property MotionFullScan:boolean read FMotionFullScan write SetMotionFullScan default False;

    property MotionHorzScanLimit:Cardinal read FMotionHorzScanLimit write SetMotionHorzScanLimit default 0;
    property MotionVertScanLimit:Cardinal read FMotionVertScanLimit write SetMotionVertScanLimit default 0;
    property MotionFullScanLimit:Cardinal read FMotionFullScanLimit write SetMotionFullScanLimit default 0;

    property ColorBitsR:integer read FColorBitsR write SetColorBitsR default 8;
    property ColorBitsG:integer read FColorBitsG write SetColorBitsG default 8;
    property ColorBitsB:integer read FColorBitsB write SetColorBitsB default 8;

    property ColorReduce:integer read FColorReduce write SetColorReduce default 0;
    end;

implementation

const
  DEFAULT_COLOR_MASK = $FFFFFFFF;

{ TRtcImageEncoder }

constructor TRtcImageEncoder.Create(const BmpInfo:TRtcBitmapInfo);
  begin
  inherited Create;
  FFirstFrame:=False;
  FLastFrame:=False;
  FScanMoves:=False;

  FMotionComp:=False;
  FColorComp:=False;
  FColorReduce:=0;
  FMotionHorzScan:=False;
  FMotionVertScan:=False;
  FMotionFullScan:=False;

  FLastReduceColors:=0;
  FLastColorComp:=0;

  FColorBitsR:=8;
  FColorBitsG:=8;
  FColorBitsB:=8;
  FColorDiffR:=0;
  FColorDiffG:=0;
  FColorDiffB:=0;
  FColorMask:=DEFAULT_COLOR_MASK;

  FLZWCompress:=False;
  FRLECompress:=False;
  FJPGCompress:=False;
  ImgTree:=nil;

  FRLEBuffer:=nil;

  NewBmpInfo:=BmpInfo; // NewBitmapInfo(True);
  CopyBitmapInfo(NewBmpInfo,OldBmpInfo);
  end;

destructor TRtcImageEncoder.Destroy;
  begin
  SetLength(FRLEBuffer,0);
  ReleaseBitmapInfo(NewBmpInfo);
  ReleaseBitmapInfo(OldBmpInfo);
  ClearImageSearchTree;
  inherited;
  end;

procedure TRtcImageEncoder.ClearImageSearchTree;
  begin
  if assigned(ImgTree) then
    RtcFreeAndNil(ImgTree);

  SetLength(fromIDs,0);
  SetLength(toIDs,0);
  SetLength(toColors,0);
  SetLength(changedIDs,0);
  SetLength(scanIDs,0);
  SetLength(dirtMarks,0);
  FScanMoves:=False;
  end;

procedure TRtcImageEncoder.LastFrame;
  begin
  FLastFrame:=True;
  FLastReduceColors:=0;
  FLastColorComp:=0;
  end;

procedure TRtcImageEncoder.FirstFrame;
  begin
  FFirstFrame:=True;
  JPEG_Ready:=False;
  FLastReduceColors:=0;
  FLastColorComp:=0;
  ClearImageSearchTree;
  ResetBitmapInfo(NewBmpInfo);
  ResetBitmapInfo(OldBmpInfo);
  end;

procedure TRtcImageEncoder.FrameComplete;
  begin
  FLastFrame:=False;
  FFirstFrame:=False;
  end;

function TRtcImageEncoder.CompressMOT: RtcByteArray;
  var
    msize:longword;
    motStore, lzwStore3 :RtcByteArray;
    dif:integer;
  begin
  if not (FMotionComp or FColorComp or (FColorReduce>0)) then
    begin
    // Log('CompressMOT: ZERO 1','Host');
    SetLength(Result,0);
    Exit;
    end;

  if not assigned(OldBmpInfo.Data) then
    begin
    ResizeBitmapInfo(OldBmpInfo,NewBmpInfo.Width,NewBmpInfo.Height,True);
    JPEG_Ready:=False;
    ClearImageSearchTree;
    dif:=0;
    end
  else
    begin
    if (OldBmpInfo.Width<>NewBmpInfo.Width) or (OldBmpInfo.Height<>NewBmpInfo.Height) then
      ResizeBitmapInfo(OldBmpInfo,NewBmpInfo.Width,NewBmpInfo.Height,False);
    dif:=img_DIF;
    end;

  if (OldBmpInfo.Width<IMG_BLOCK_X) or (OldBmpInfo.Height<IMG_BLOCK_Y) then
    begin
    // Log('CompressMOT: ZERO 2','Host');
    SetLength(Result,0);
    end
  else
    begin
    motStore:=CompensateMotion;

    if length(motStore)=0 then
      begin
      // Log('CompressMOT: ZERO 3','Host');
      SetLength(Result,0);
      end
    else if FLZWCompress then // MOT + LZW compress
      begin
      lzwStore3:=ZCompress_Ex(motStore,zcFastest);
      SetLength(motStore,0);
      msize:=length(lzwStore3);

      SetLength(Result,msize+9);
      Result[0]:=dif + img_LZW + img_MOT;

      Result[1]:=(NewBmpInfo.Width shr 8) and $FF;
      Result[2]:=NewBmpInfo.Width and $FF;

      Result[3]:=(NewBmpInfo.Height shr 8) and $FF;
      Result[4]:=NewBmpInfo.Height and $FF;

      Result[5]:=(msize shr 24) and $FF;
      Result[6]:=(msize shr 16) and $FF;
      Result[7]:=(msize shr 8) and $FF;
      Result[8]:=msize and $FF;

      Move(lzwStore3[0],Result[9],msize);
      SetLength(lzwStore3,0);
      // Log('CompressMOT: OK 1','Host');
      end
    else // MOT compress
      begin
      msize:=length(motStore);

      SetLength(Result,msize+9);
      Result[0]:=dif + img_MOT;

      Result[1]:=(NewBmpInfo.Width shr 8) and $FF;
      Result[2]:=NewBmpInfo.Width and $FF;

      Result[3]:=(NewBmpInfo.Height shr 8) and $FF;
      Result[4]:=NewBmpInfo.Height and $FF;

      Result[5]:=(msize shr 24) and $FF;
      Result[6]:=(msize shr 16) and $FF;
      Result[7]:=(msize shr 8) and $FF;
      Result[8]:=msize and $FF;

      Move(motStore[0],Result[9],msize);
      SetLength(motStore,0);
      // Log('CompressMOT: OK 2','Host');
      end;
    end;
  end;

function TRtcImageEncoder.CompressJPG: RtcByteArray;
  var
    bsize:longword;
    headsize:integer;
    jpgStore, lzwstore :RtcByteArray;
    dif:integer;
  begin
  if not FJPGCompress then
    begin
    // Log('CompressJPG: ZERO 1','Host');
    SetLength(Result,0);
    Exit;
    end;

  if not assigned(OldBmpInfo.Data) then
    begin
    ResizeBitmapInfo(OldBmpInfo,NewBmpInfo.Width,NewBmpInfo.Height,True);
    JPEG_Ready:=False;
    ClearImageSearchTree;
    if FRLECompress then
      dif:=img_DIF
    else
      dif:=0;
    end
  else
    begin
    if (OldBmpInfo.Width<>NewBmpInfo.Width) or (OldBmpInfo.Height<>NewBmpInfo.Height) then
      ResizeBitmapInfo(OldBmpInfo,NewBmpInfo.Width,NewBmpInfo.Height,False);
    if (LastJSX<>OldBmpInfo.Width) or (LastJSY<>OldBmpInfo.Height) then
      JPEG_Ready:=False;
    dif:=img_DIF;
    end;
  LastJSX:=OldBmpInfo.Width;
  LastJSY:=OldBmpInfo.Height;
  if (OldBmpInfo.Width<IMG_BLOCK_X) or (OldBmpInfo.Height<IMG_BLOCK_Y) then
    begin
    SetLength(Result,0);
    // Log('CompressJPG: ZERO 2','Host');
    end
  else
    begin
    headsize:=0;

    if dif=0 then
      jpgStore:=MakeJPEG(NewBmpInfo,headsize)
    else
      jpgStore:=MakeJPEGDiff(OldBmpInfo,NewBmpInfo,headsize);

    if length(jpgStore)=0 then // No changes
      begin
      SetLength(Result,0);
      // Log('CompressJPG: ZERO 3','Host');
      end
    else if FLZWCompress then // JPG + LZW compress
      begin
      lzwStore:=ZCompress_Ex(jpgStore,zcFastest);
      SetLength(jpgStore,0);

      bsize:=length(lzwStore);

      SetLength(Result,11+bsize);
      Result[0]:=dif + img_JPG + img_LZW;

      Result[1]:=(NewBmpInfo.Width shr 8) and $FF;
      Result[2]:=NewBmpInfo.Width and $FF;

      Result[3]:=(NewBmpInfo.Height shr 8) and $FF;
      Result[4]:=NewBmpInfo.Height and $FF;

      Result[5]:=(headsize shr 8) and $FF;
      Result[6]:=headsize and $FF;

      Result[7]:=(bsize shr 24) and $FF;
      Result[8]:=(bsize shr 16) and $FF;
      Result[9]:=(bsize shr 8) and $FF;
      Result[10]:=bsize and $FF;

      Move(lzwStore[0],Result[11],bsize);

      SetLength(lzwStore,0);
      // Log('CompressJPG: OK 1','Host');
      end
    else // JPG compress
      begin
      bsize:=length(jpgStore);

      SetLength(Result,11+bsize);
      Result[0]:=dif + img_JPG;

      Result[1]:=(NewBmpInfo.Width shr 8) and $FF;
      Result[2]:=NewBmpInfo.Width and $FF;

      Result[3]:=(NewBmpInfo.Height shr 8) and $FF;
      Result[4]:=NewBmpInfo.Height and $FF;

      Result[5]:=(headsize shr 8) and $FF;
      Result[6]:=headsize and $FF;

      Result[7]:=(bsize shr 24) and $FF;
      Result[8]:=(bsize shr 16) and $FF;
      Result[9]:=(bsize shr 8) and $FF;
      Result[10]:=bsize and $FF;

      Move(jpgStore[0],Result[11],bsize);

      SetLength(jpgStore,0);
      // Log('CompressJPG: OK 2','Host');
      end;
    end;
  end;

function TRtcImageEncoder.CompressRLE: RtcByteArray;
  var
    bsize:integer;
    len:longword;
    lzwstore2 :RtcByteArray;
    dif:integer;
  begin
  if not FRLECompress then
    begin
    // Log('CompressRLE: ZERO 1','Host');
    SetLength(Result,0);
    Exit;
    end;

  if not assigned(OldBmpInfo.Data) then
    begin
    ResizeBitmapInfo(OldBmpInfo,NewBmpInfo.Width,NewBmpInfo.Height,True);
    JPEG_Ready:=False;
    ClearImageSearchTree;
    dif:=0;
    end
  else
    begin
    if (OldBmpInfo.Width<>NewBmpInfo.Width) or (OldBmpInfo.Height<>NewBmpInfo.Height) then
      ResizeBitmapInfo(OldBmpInfo,NewBmpInfo.Width,NewBmpInfo.Height,False);
    dif:=img_DIF;
    end;

  if (OldBmpInfo.Width<IMG_BLOCK_X) or (OldBmpInfo.Height<IMG_BLOCK_Y) then
    begin
    SetLength(Result,0);
    // Log('CompressRLE: ZERO 2','Host');
    end
  else
    begin
    bsize:=NewBmpInfo.Height*(NewBmpInfo.Width*3+4);
    if Length(FRLEBuffer)<>bsize then
      begin
      SetLength(FRLEBuffer,0);
      SetLength(FRLEBuffer,bsize);
      end;
    case NewBmpInfo.BuffType of
      btRGBA32: len :=
        RGBA32_Compress(OldBmpInfo.TopData,
                        NewBmpInfo.TopData,
                        Addr(FRLEBuffer[0]),
                        NewBmpInfo.Width,
                        NewBmpInfo.Height,
                        NewBmpInfo.Reverse);
      btBGRA32: len :=
        BGRA32_Compress(OldBmpInfo.TopData,
                        NewBmpInfo.TopData,
                        Addr(FRLEBuffer[0]),
                        NewBmpInfo.Width,
                        NewBmpInfo.Height,
                        NewBmpInfo.Reverse);
      else len := 0;
      end;

    if len=0 then // No changes
      begin
      SetLength(Result,0);
      // Log('CompressRLE: ZERO 3','Host');
      end
    else if FLZWCompress then // RLE + LZW compress
      begin
      lzwStore2:=ZCompress_Ex(FRLEBuffer,zcFastest,len);

      len:=length(lzwStore2);

      SetLength(Result,len+9);
      Result[0]:=dif + img_RLE + img_LZW;

      Result[1]:=(NewBmpInfo.Width shr 8) and $FF;
      Result[2]:=NewBmpInfo.Width and $FF;

      Result[3]:=(NewBmpInfo.Height shr 8) and $FF;
      Result[4]:=NewBmpInfo.Height and $FF;

      Result[5]:=(len shr 24) and $FF;
      Result[6]:=(len shr 16) and $FF;
      Result[7]:=(len shr 8) and $FF;
      Result[8]:=len and $FF;

      Move(lzwStore2[0],Result[9],len);

      SetLength(lzwStore2,0);
      // Log('CompressRLE: OK 1','Host');
      end
    else // RLE compress
      begin
      SetLength(Result,len+9);
      Result[0]:=dif + img_RLE;

      Result[1]:=(NewBmpInfo.Width shr 8) and $FF;
      Result[2]:=NewBmpInfo.Width and $FF;

      Result[3]:=(NewBmpInfo.Height shr 8) and $FF;
      Result[4]:=NewBmpInfo.Height and $FF;

      Result[5]:=(len shr 24) and $FF;
      Result[6]:=(len shr 16) and $FF;
      Result[7]:=(len shr 8) and $FF;
      Result[8]:=len and $FF;

      Move(FRLEBuffer[0],Result[9],len);

      // Log('CompressRLE: OK 2','Host');
      end;
    end;
  end;

procedure TRtcImageEncoder.SetJPGCompress(const Value: boolean);
  begin
  if FJPGCompress<>Value then
    begin
    FJPGCompress := Value;
    JPEG_Ready:=False;
    end;
  end;

procedure TRtcImageEncoder.SetLZWCompress(const Value: boolean);
  begin
  FLZWCompress := Value;
  end;

procedure TRtcImageEncoder.SetRLECompress(const Value: boolean);
  begin
  FRLECompress := Value;
  SkipHQ := Value;
  end;

procedure TRtcImageEncoder.SetMotionComp(const Value: boolean);
  begin
  FMotionComp := Value;
  end;

procedure TRtcImageEncoder.SetColorComp(const Value: boolean);
  begin
  FColorComp := Value;
  end;

procedure TRtcImageEncoder.SetMotionFullScan(const Value: boolean);
  begin
  FMotionFullScan := Value;
  end;

procedure TRtcImageEncoder.SetMotionHorzScan(const Value: boolean);
  begin
  FMotionHorzScan := Value;
  end;

procedure TRtcImageEncoder.SetMotionVertScan(const Value: boolean);
  begin
  FMotionVertScan := Value;
  end;

procedure TRtcImageEncoder.SetMotionFullScanLimit(const Value: Cardinal);
  begin
  FMotionFullScanLimit := Value;
  end;

procedure TRtcImageEncoder.SetMotionHorzScanLimit(const Value: Cardinal);
  begin
  FMotionHorzScanLimit := Value;
  end;

procedure TRtcImageEncoder.SetMotionVertScanLimit(const Value: Cardinal);
  begin
  FMotionVertScanLimit := Value;
  end;

function TRtcImageEncoder.CompensateMotion:RtcByteArray;
  var
    chgTotal, chgDirty, chgMoved, chgFound, chgDraft,
    chg, chgLeft, chgRight, chgColor:integer;

    DoMotionComp,
    DoReduceColors,
    DoColorComp,
    FullColorComp:boolean;

    newMarks:ShortIntArray;

    StartTime:LongWord;

    procedure AddAllToSearchTree;
      var
        nextLine,
        oldID, blockID,
        chg,x,y,mx,my:integer;
      begin
      imgTree.removeall;

      mx:=(NewBmpInfo.Width shr IMG_BLOCK_X_SHIFT) - 1;
      my:=(NewBmpInfo.Height shr IMG_BLOCK_Y_SHIFT) - 1;

      nextLine:=NewBmpInfo.Width*IMG_BLOCK_Y - (mx+1)*IMG_BLOCK_X;

      blockID:=-1; chg:=0;
      for y:=0 to my do
        begin
        for x:=0 to mx do
          begin
          if changedIDs[chg]=1 then
            begin
            oldID:=ImgTree.insert(blockID,chg+1);
            if oldID>0 then // Block already in the search list
              begin
              Dec(chgDirty);
              toIDs[chg]:=oldID-1; // store 1st found block ID
              changedIDs[chg]:=5; // block found on the new image
              end;
            end;
          Inc(chg);
          Dec(blockID, IMG_BLOCK_X);
          end;
        Dec(blockID, nextLine);
        end;
      end;

    procedure AddVertToSearchTree(meX:integer);
      var
        nextLine,
        oldID, blockID,
        chg,y,mx,my:integer;
      begin
      imgTree.removeall;

      mx:=(NewBmpInfo.Width  shr IMG_BLOCK_X_SHIFT) - 1;
      my:=(NewBmpInfo.Height shr IMG_BLOCK_Y_SHIFT) - 1;

      nextLine:=NewBmpInfo.Width*IMG_BLOCK_Y;

      blockID:=-1; chg:=0;
      Inc(chg,meX);
      Dec(blockID, meX*IMG_BLOCK_X);
      for y:=0 to my do
        begin
        if changedIDs[chg]=1 then
          begin
          oldID:=ImgTree.insert(blockID,chg+1);
          if oldID>0 then // Block already in the search list
            begin
            Dec(chgDirty);
            toIDs[chg]:=oldID-1; // store 1st found block ID
            changedIDs[chg]:=5; // block found on the new image
            end;
          end;
        Inc(chg,mx+1);
        Dec(blockID, nextLine);
        end;
      end;

    procedure AddHorzToSearchTree(y:integer);
      var
        nextLine,
        oldID, blockID,
        chg,x,mx:integer;
      begin
      imgTree.removeall;

      mx:=(NewBmpInfo.Width shr IMG_BLOCK_X_SHIFT) - 1;
      nextLine:=NewBmpInfo.Width*IMG_BLOCK_Y;

      blockID:=-1-y*nextLine;
      chg:=y*(mx+1);
      for x:=0 to mx do
        begin
        if changedIDs[chg]=1 then
          begin
          oldID:=ImgTree.insert(blockID,chg+1);
          if oldID>0 then // Block already in the search list
            begin
            Dec(chgDirty);
            toIDs[chg]:=oldID-1; // store 1st found block ID
            changedIDs[chg]:=5; // block found on the new image
            end;
          end;
        Inc(chg);
        Dec(blockID, IMG_BLOCK_X);
        end;
      end;

    procedure UpdateFullSearchTree;
      var
        blockID2,blockID,
        lineWid,x,y,mx,my,mz,i,
        sx1,sy1,sx2,sy2,
        maxX,maxY,
        x3,y3,y1,y2,x1,x2,
        oldID,nextLine,nextLineBlock,
        lastY,lastX,
        oX,oY:integer;
        nowCnt,
        nowHave,
        cntVert,
        cntHorz,
        cntFull,
        haveVert,
        haveHorz,
        haveFull:integer;
        haveOld,
        done:boolean;
        miX,maX,
        miY,maY,
        ceX,ceY,
        atX,atY,
        dirX,dirY,
        Count:integer;

      function QuickCheckLines(const oid,oblock,nid,nblock,x,y:integer):integer;
        var
          oi,ni,ob,nb,pi,pb,x0,y0,
          x1,x2,y1,y2,
          ox,oy,nx,ny,
          ax1,ax2,ay1,ay2:integer;
        begin
        Result:=0;
        oy:=oblock div nextLine;
        ox:=oblock - oy*nextLine;
        ny:=(-nblock) div nextLine;
        nx:=(-nblock) - ny*nextLine;

        if dirX>=0 then
          begin
          ax1:=x+1;
          ax2:=maX;
          if ox and IMG_BLOCK_X_MOD>0 then Dec(ax2);
          end
        else
          begin
          ax1:=miX;
          ax2:=x-1;
          if ox and IMG_BLOCK_X_MOD>0 then Inc(ax1);
          end;
        if dirY>=0 then
          begin
          ay1:=y+1;
          ay2:=maY;
          if oy and IMG_BLOCK_Y_MOD>0 then Dec(ay2);
          end
        else
          begin
          ay1:=miY;
          ay2:=y-1;
          if oy and IMG_BLOCK_Y_MOD>0 then Inc(ay1);
          end;

        if nx>ox then
          Dec(ax2,(nx-ox) shr IMG_BLOCK_X_SHIFT)
        else if nx<ox then
          Inc(ax1,(ox-nx) shr IMG_BLOCK_X_SHIFT);
        if ny>oy then
          Dec(ay2,(ny-oy) shr IMG_BLOCK_Y_SHIFT)
        else if ny<oy then
          Inc(ay1,(oy-ny) shr IMG_BLOCK_Y_SHIFT);

        if (ax1>ax2) or (ay1>ay2) then Exit;

        oi:=oid; ni:=nid;
        ob:=oblock; nb:=nblock;
        x1:=ax1;
        x2:=ax2;
        if ax2>x then
          begin
          x0:=ax1-x;
          Inc(oi,x0);
          Inc(ni,x0);
          Inc(ob,x0*IMG_BLOCK_X);
          Dec(nb,x0*IMG_BLOCK_X);
          for x0:=ax1 to ax2 do
            begin
            if scanIDs[oi] then
              if ImageItemChanged(ob,nb) then
                begin
                x2:=x0-1;
                Break;
                end
              else // if scanIDs[oi] then
                begin
                Inc(Result);
                scanIDs[oi]:=False;
                changedIDs[ni]:=2;
                fromIDs[ni]:=nb;
                toIDs[ni]:=ob;
                end;
            Inc(oi);
            Inc(ni);
            Inc(ob,IMG_BLOCK_X);
            Dec(nb,IMG_BLOCK_X);
            end;
          end
        else
          begin
          x0:=x-ax2;
          Dec(oi,x0);
          Dec(ni,x0);
          Dec(ob,x0*IMG_BLOCK_X);
          Inc(nb,x0*IMG_BLOCK_X);
          for x0:=ax2 downto ax1 do
            begin
            if scanIDs[oi] then
              if ImageItemChanged(ob,nb) then
                begin
                x1:=x0+1;
                Break;
                end
              else // if scanIDs[oi] then
                begin
                Inc(Result);
                scanIDs[oi]:=False;
                changedIDs[ni]:=2;
                fromIDs[ni]:=nb;
                toIDs[ni]:=ob;
                end;
            Dec(oi);
            Dec(ni);
            Dec(ob,IMG_BLOCK_X);
            Inc(nb,IMG_BLOCK_X);
            end;
          end;
        oi:=oid; ni:=nid;
        ob:=oblock; nb:=nblock;
        y1:=ay1;
        y2:=ay2;
        if ay2>y then
          begin
          y0:=ay1-y;
          Inc(oi,y0*lineWid);
          Inc(ni,y0*lineWid);
          Inc(ob,y0*nextLineBlock);
          Dec(nb,y0*nextLineBlock);
          for y0:=ay1 to ay2 do
            begin
            if scanIDs[oi] then
              if ImageItemChanged(ob,nb) then
                begin
                y2:=y0-1;
                Break;
                end
              else // if scanIDs[oi] then
                begin
                Inc(Result);
                scanIDs[oi]:=False;
                changedIDs[ni]:=2;
                fromIDs[ni]:=nb;
                toIDs[ni]:=ob;
                end;
            Inc(oi,lineWid);
            Inc(ni,lineWid);
            Inc(ob,nextLineBlock);
            Dec(nb,nextLineBlock);
            end;
          end
        else
          begin
          y0:=y-ay2;
          Dec(oi,y0*lineWid);
          Dec(ni,y0*lineWid);
          Dec(ob,y0*nextLineBlock);
          Inc(nb,y0*nextLineBlock);
          for y0:=ay2 downto ay1 do
            begin
            if scanIDs[oi] then
              if ImageItemChanged(ob,nb) then
                begin
                y1:=y0+1;
                Break;
                end
              else // if scanIDs[oi] then
                begin
                Inc(Result);
                scanIDs[oi]:=False;
                changedIDs[ni]:=2;
                fromIDs[ni]:=nb;
                toIDs[ni]:=ob;
                end;
            Dec(oi,lineWid);
            Dec(ni,lineWid);
            Dec(ob,nextLineBlock);
            Inc(nb,nextLineBlock);
            end;
          end;

        if y1=y then Inc(y1);
        if y2=y then Dec(y2);
        if x1=x then Inc(x1);
        if x2=x then Dec(x2);

        if (y2>=y1) and (x2>=x1) then
          begin
          oi:=oid; ni:=nid;
          ob:=oblock; nb:=nblock;

          pi:=lineWid-(x2-x1+1);
          pb:=nextLineBlock-(x2-x1+1)*IMG_BLOCK_X;

          if y1<y then
            begin
            y0:=y-y1;
            Dec(oi,lineWid*y0);
            Dec(ni,lineWid*y0);
            Dec(ob,nextLineBlock*y0);
            Inc(nb,nextLineBlock*y0);
            end
          else if y1>y then
            begin
            y0:=y1-y;
            Inc(oi,lineWid*y0);
            Inc(ni,lineWid*y0);
            Inc(ob,nextLineBlock*y0);
            Dec(nb,nextLineBlock*y0);
            end;

          if x1<x then
            begin
            x0:=x-x1;
            Dec(oi,x0);
            Dec(ni,x0);
            Dec(ob,IMG_BLOCK_X*x0);
            Inc(nb,IMG_BLOCK_X*x0);
            end
          else if x1>x then
            begin
            x0:=x1-x;
            Inc(oi,x0);
            Inc(ni,x0);
            Inc(ob,IMG_BLOCK_X*x0);
            Dec(nb,IMG_BLOCK_X*x0);
            end;

          for y0:=y1 to y2 do
            begin
            for x0:=x1 to x2 do
              begin
              if scanIDs[oi] then
                if not ImageItemChanged(ob,nb) then
                  begin
                  Inc(Result);
                  scanIDs[oi]:=False;
                  changedIDs[ni]:=2;
                  fromIDs[ni]:=nb;
                  toIDs[ni]:=ob;
                  end;
              Inc(oi);
              Inc(ni);
              Inc(ob,IMG_BLOCK_X);
              Dec(nb,IMG_BLOCK_X);
              end;
            Inc(oi,pi);
            Inc(ni,pi);
            Inc(ob,pb);
            Dec(nb,pb);
            end;
          end;
        end;

      procedure QuickScanVert(forReal:boolean);
        var
          nh,z,y0:integer;
        begin
        nowCnt:=0;
        nowHave:=0;
        oX:=-1;
        for z:=0 to mz do
          begin
          x:=atX+(z*mx div mz);
          y:=atY+(z*my div mz);
          i:=x + y*lineWid;
          if scanIDs[i] then
            begin
            if x<>oX then
              begin
              oX:=x;
              AddVertToSearchTree(x);
              end;
            if imgTree.Count>0 then
              begin
              Inc(nowCnt);
              x3:=x*IMG_BLOCK_X;
              y3:=y*IMG_BLOCK_Y;
              y1:=y3 - sy1; if y1<0 then y1:=0;
              y2:=y3 + sy2; if y2>maxY then y2:=maxY;
              blockID := 1 + x3 + y1*nextLine;
              for y0:=y1 to y2 do
                begin
                oldID:=ImgTree.search(blockID);
                if oldID>0 then
                  begin
                  Dec(oldID);
                  imgTree.remove(fromIDs[oldID]);
                  if changedIDs[oldID]=1 then
                    begin
                    Inc(nowHave);
                    if forReal then
                      begin
                      Inc(chgFound);
                      toIDs[oldID]:=blockID;
                      changedIDs[oldID]:=2;
                      scanIDs[i]:=False;
                      nh:=QuickCheckLines(i,blockID,oldID,fromIDs[oldID],x,y);
                      Inc(nowHave,nh);
                      Inc(nowCnt,nh);
                      Inc(chgFound,nh);
                      end;
                    Break;
                    end;
                  end;
                Inc(blockID,nextLine);
                end;
              end;
            end; // if
          end; // for z
        Inc(haveVert,nowHave);
        Inc(cntVert,nowCnt);
        end;

      procedure QuickScanHorz(forReal:boolean);
        var
          nh,z,x0:integer;
        begin
        nowCnt:=0;
        nowHave:=0;
        oY:=-1;
        for z:=0 to mz do
          begin
          x:=atX+(z*mx div mz);
          y:=atY+(z*my div mz);
          i:=x + y*lineWid;
          if scanIDs[i] then
            begin
            if oY<>y then
              begin
              oY:=y;
              AddHorzToSearchTree(y);
              end;
            if imgTree.Count>0 then
              begin
              Inc(nowCnt);
              y3:=y*IMG_BLOCK_Y;
              x3:=x*IMG_BLOCK_X;
              x1:=x3 - sx1; if x1<0 then x1:=0;
              x2:=x3 + sx2; if x2>maxX then x2:=maxX;
              blockID := 1 + x1 + y3*nextLine;
              for x0:=x1 to x2 do
                begin
                oldID:=ImgTree.search(blockID);
                if oldID>0 then
                  begin
                  Dec(oldID);
                  imgTree.remove(fromIDs[oldID]);
                  if changedIDs[oldID]=1 then
                    begin
                    Inc(nowHave);
                    if forReal then
                      begin
                      Inc(chgFound);
                      toIDs[oldID]:=blockID;
                      changedIDs[oldID]:=2;
                      scanIDs[i]:=False;
                      nh:=QuickCheckLines(i,blockID,oldID,fromIDs[oldID],x,y);
                      Inc(nowHave,nh);
                      Inc(nowCnt,nh);
                      Inc(chgFound,nh);
                      end;
                    Break;
                    end;
                  end;
                Inc(blockID);
                end;
              end; // if changed
            end; // if
          end; // for z
        Inc(haveHorz,nowHave);
        Inc(cntHorz,nowCnt);
        end;

      procedure QuickScanFull(forReal:boolean);
        var
          nh,z,x0,y0:integer;
        begin
        nowCnt:=0;
        nowHave:=0;
        for z:=0 to mz do
          begin
          x:=atX+(z*mx div mz);
          y:=atY+(z*my div mz);
          i:=x + y*lineWid;
          if scanIDs[i] then
            begin
            if imgTree.Count>0 then
              begin
              Inc(nowCnt);
              y3:=y*IMG_BLOCK_Y;
              x3:=x*IMG_BLOCK_X;
              x1:=x3 - sx1; if x1<0 then x1:=0;
              x2:=x3 + sx2; if x2>maxX then x2:=maxX;
              y1:=y3 - sy1; if y1<0 then y1:=0;
              y2:=y3 + sy2; if y2>maxY then y2:=maxY;
              blockID := 1 + x1 + y1*nextLine;
              done:=False;
              for y0:=y1 to y2 do
                begin
                blockID2:=blockID;
                for x0:=x1 to x2 do
                  begin
                  oldID:=ImgTree.search(blockID);
                  if oldID>0 then
                    begin
                    Dec(oldID);
                    imgTree.remove(fromIDs[oldID]);
                    if changedIDs[oldID]=1 then
                      begin
                      Inc(nowHave);
                      if forReal then
                        begin
                        Inc(chgFound);
                        toIDs[oldID]:=blockID;
                        changedIDs[oldID]:=2;
                        scanIDs[i]:=False;
                        nh:=QuickCheckLines(i,blockID,oldID,fromIDs[oldID],x,y);
                        Inc(nowHave,nh);
                        Inc(nowCnt,nh);
                        Inc(chgFound,nh);
                        end;
                      done:=True;
                      Break;
                      end;
                    end;
                  Inc(blockID);
                  end;
                if done then Break;
                blockID:=blockID2+nextLine;
                end;
              end; // if changed
            end; // if
          end; // for z
        Inc(haveFull,nowHave);
        Inc(cntFull,nowCnt);
        end;

      procedure ScanHorzVertNow;
        var
          z,x,y,x0,y0:integer;
        begin
        dirX:=0;
        dirY:=0;
        if haveVert=0 then
          mz:=my
        else if haveHorz=0 then
          mz:=mx
        else if mx>my then
          mz:=mx
        else
          mz:=my;
        LastX:=0;
        LastY:=0;
        haveOld:=False;
        for z:=0 to mz do
          begin
          // Scan Vertical
          if (haveVert>0) and (z<=mx) then
            begin
            x:=miX+z;
            AddVertToSearchTree(x);
            if imgTree.Count>0 then
              begin
              i:=x + miY*lineWid;
              x3:=x*IMG_BLOCK_X;
              for y:=miY to maY do
                begin
                if scanIDs[i] then
                  begin
                  y3:=y*IMG_BLOCK_Y;
                  y1:=y3 - sy1; if y1<0 then y1:=0;
                  y2:=y3 + sy2; if y2>maxY then y2:=maxY;
                  if haveOld and (lastY>=y1-y3) and (lastY<=y2-y3) then
                    begin
                    blockID:=1 + x3 + (y3+lastY)*nextLine;
                    oldID:=ImgTree.search(blockID);
                    if oldID>0 then
                      begin
                      Dec(oldID);
                      imgTree.remove(fromIDs[oldID]);
                      if changedIDs[oldID]=1 then
                        begin
                        Inc(chgFound);
                        toIDs[oldID]:=blockID;
                        changedIDs[oldID]:=2;
                        scanIDs[i]:=False;
                        Inc(chgFound, QuickCheckLines(i,blockID,oldID,fromIDs[oldID],x,y));
                        end
                      else
                        oldID:=-1;
                      end
                    else
                      oldID:=-1;
                    end
                  else
                    oldID:=-1;
                  if oldID<0 then
                    begin
                    blockID := 1 + x3 + y1*nextLine;
                    for y0:=y1 to y2 do
                      begin
                      oldID:=ImgTree.search(blockID);
                      if oldID>0 then
                        begin
                        Dec(oldID);
                        imgTree.remove(fromIDs[oldID]);
                        if changedIDs[oldID]=1 then
                          begin
                          Inc(chgFound);
                          toIDs[oldID]:=blockID;
                          changedIDs[oldID]:=2;
                          Inc(chgFound, QuickCheckLines(i,blockID,oldID,fromIDs[oldID],x,y) );
                          if FMotionVertScanLimit<1000 then
                            begin
                            haveOld:=True;
                            lastY:=y0-y3;
                            scanIDs[i]:=False;
                            Break;
                            end;
                          end;
                        end;
                      Inc(blockID,nextLine);
                      end;
                    end;
                  end;
                Inc(i,lineWid);
                end; // for y
              if FMotionVertScanLimit>0 then
                if GetTickTime-StartTime>FMotionVertScanLimit then
                  Break;
              end; // if
            end; // if z<=mx
          // Scan Horizontal
          if (haveHorz>0) and (z<=my) then
            begin
            y:=miY+z;
            AddHorzToSearchTree(y);
            if imgTree.Count>0 then
              begin
              i:=miX + y*lineWid;
              y3:=y*IMG_BLOCK_Y;
              for x:=miX to maX do
                begin
                if scanIDs[i] then
                  begin
                  x3:=x*IMG_BLOCK_X;
                  x1:=x3 - sx1; if x1<0 then x1:=0;
                  x2:=x3 + sx2; if x2>maxX then x2:=maxX;
                  if haveOld and
                    (lastX>=x1-x3) and (lastX<=x2-x3) then
                    begin
                    blockID := 1 + (lastX+x3) + y3*nextLine;
                    oldID:=ImgTree.search(blockID);
                    if oldID>0 then
                      begin
                      Dec(oldID);
                      imgTree.remove(fromIDs[oldID]);
                      if changedIDs[oldID]=1 then
                        begin
                        Inc(chgFound);
                        toIDs[oldID]:=blockID;
                        changedIDs[oldID]:=2;
                        scanIDs[i]:=False;
                        Inc(chgFound, QuickCheckLines(i,blockID,oldID,fromIDs[oldID],x,y) );
                        end
                      else
                        oldID:=-1;
                      end
                    else
                      oldID:=-1;
                    end
                  else
                    oldID:=-1;
                  if oldID<0 then
                    begin
                    blockID := 1 + x1 + y3*nextLine;
                    for x0:=x1 to x2 do
                      begin
                      oldID:=ImgTree.search(blockID);
                      if oldID>0 then
                        begin
                        Dec(oldID);
                        imgTree.remove(fromIDs[oldID]);
                        if changedIDs[oldID]=1 then
                          begin
                          Inc(chgFound);
                          toIDs[oldID]:=blockID;
                          changedIDs[oldID]:=2;
                          Inc(chgFound, QuickCheckLines(i,blockID,oldID,fromIDs[oldID],x,y) );
                          if FMotionHorzScanLimit<1000 then
                            begin
                            haveOld:=True;
                            lastX:=x0-x3;
                            scanIDs[i]:=False;
                            Break;
                            end;
                          end;
                        end;
                      Inc(blockID);
                      end;
                    end;
                  end; // if changed
                Inc(i);
                end; // for x
              if FMotionHorzScanLimit>0 then
                if GetTickTime-StartTime>FMotionHorzScanLimit then
                  Break;
              end; // if
            end; // if z<=my
          end; // for z
        end;

      procedure ScanFullNow;
        var
          x,y,x0,y0:integer;
        begin
        dirX:=0;
        dirY:=0;
        lastX:=0;
        lastY:=0;
        haveOld:=False;
        for y:=miY to maY do
          begin
          i:=miX + y*lineWid;
          y3:=y*IMG_BLOCK_Y;
          y1:=y3 - sy1; if y1<0 then y1:=0;
          y2:=y3 + sy2; if y2>maxY then y2:=maxY;
          for x:=miX to maX do
            begin
            if scanIDs[i] then
              begin
              x3:=x*IMG_BLOCK_X;
              x1:=x3 - sx1; if x1<0 then x1:=0;
              x2:=x3 + sx2; if x2>maxX then x2:=maxX;

              if haveOld and
                (lastY>=y1-y3) and (lastY<=y2-y3) and
                (lastX>=x1-x3) and (lastX<=x2-x3) then
                begin
                blockID := 1 + (lastX+x3) + (lastY+y3)*nextLine;
                oldID:=ImgTree.search(blockID);
                if oldID>0 then
                  begin
                  Dec(oldID);
                  if changedIDs[oldID]=1 then
                    begin
                    // found it, remove it?
                    imgTree.remove(fromIDs[oldID]);

                    Inc(chgFound);
                    toIDs[oldID]:=blockID;
                    changedIDs[oldID]:=2;
                    scanIDs[i]:=false;
                    Inc(chgFound, QuickCheckLines(i,blockID,oldID,fromIDs[oldID],x,y) );
                    end
                  else
                    oldID:=-1;
                  end
                else
                  oldID:=-1;
                end
              else
                oldID:=-1;
              if oldID<0 then
                begin
                blockID := 1 + x1 + y1*nextLine;
                done:=False;
                for y0:=y1 to y2 do
                  begin
                  blockID2:=blockID;
                  for x0:=x1 to x2 do
                    begin
                    oldID:=ImgTree.search(blockID);
                    if oldID>0 then
                      begin
                      Dec(oldID);
                      if changedIDs[oldID]=1 then
                        begin
                        // Found it, remove it?
                        imgTree.remove(fromIDs[oldID]);

                        Inc(chgFound);
                        toIDs[oldID]:=blockID;
                        changedIDs[oldID]:=2;
                        Inc(chgFound, QuickCheckLines(i,blockID,oldID,fromIDs[oldID],x,y) );

                        if FMotionFullScanLimit<1000 then
                          begin
                          haveOld:=True;
                          lastX:=x0-x3;
                          lastY:=y0-y3;
                          done:=True;
                          scanIDs[i]:=False;
                          Break;
                          end;
                        end;
                      end;
                    Inc(blockID);
                    end;
                  if done then Break;
                  blockID:=blockID2+nextLine;
                  end;
                end;
              end;
            Inc(i);
            end;
          if FMotionFullScanLimit>0 then
            if GetTickTime-StartTime>FMotionFullScanLimit then
              Break;
          end;
        end;

      procedure QuickAllVertScans(forReal:boolean);
        begin
        if forReal then
          begin
          // LeftTop /
          dirX:=1; dirY:=-1;
          mx:=ceX-miX; atX:=miX;
          my:=miY-ceY; atY:=ceY;
          if mx>-my then mz:=mx else mz:=-my;
          if mz>0 then QuickScanVert(forReal);

          // RightTop \
          dirX:=-1; dirY:=-1;
          mx:=ceX-maX; atX:=maX;
          my:=miY-ceY; atY:=ceY;
          if -mx>-my then mz:=-mx else mz:=-my;
          if mz>0 then QuickScanVert(forReal);

          // LeftBottom \
          dirX:=1; dirY:=1;
          mx:=ceX-miX; atX:=miX;
          my:=maY-ceY; atY:=ceY;
          if mx>my then mz:=mx else mz:=my;
          if mz>0 then QuickScanVert(forReal);

          // RightBottom /
          dirX:=-1; dirY:=1;
          mx:=ceX-maX; atX:=maX;
          my:=maY-ceY; atY:=ceY;
          if -mx>my then mz:=-mx else mz:=my;
          if mz>0 then QuickScanVert(forReal);

          // Vert line, left-side
          dirX:=-1; dirY:=0;
          mx:=0; atX:=ceX;
          my:=maY-miY; atY:=miY;
          mz:=my;
          if mz>0 then QuickScanVert(forReal);

          // Vert line, right-side
          dirX:=1; dirY:=0;
          mx:=0; atX:=ceX;
          my:=maY-miY; atY:=miY;
          mz:=my;
          if mz>0 then QuickScanVert(forReal);

          // Horz line, up-side
          dirX:=0; dirY:=-1;
          mx:=maX-miX; atX:=miX;
          my:=0; atY:=ceY;
          mz:=mx;
          if mz>0 then QuickScanVert(forReal);

          // Horz line, down-side
          dirX:=0; dirY:=1;
          mx:=maX-miX; atX:=miX;
          my:=0; atY:=ceY;
          mz:=mx;
          if mz>0 then QuickScanVert(forReal);
          end;

        // LeftTop box
        dirX:=1; dirY:=1;
        mx:=ceX-miX; atX:=miX;
        my:=ceY-miY; atY:=miY;
        if mx>my then mz:=mx else mz:=my;
        if mz>0 then QuickScanVert(forReal);

        // RightTop box
        dirX:=-1; dirY:=1;
        mx:=ceX-maX; atX:=maX;
        my:=ceY-miY; atY:=miY;
        if -mx>my then mz:=-mx else mz:=my;
        if mz>0 then QuickScanVert(forReal);

        // LeftBottom box
        dirX:=1; dirY:=-1;
        mx:=ceX-miX; atX:=miX;
        my:=ceY-maY; atY:=maY;
        if mx>-my then mz:=mx else mz:=-my;
        if mz>0 then QuickScanVert(forReal);

        // RightBottom box
        dirX:=-1;dirY:=-1;
        mx:=ceX-maX; atX:=maX;
        my:=ceY-maY; atY:=maY;
        if -mx>-my then mz:=-mx else mz:=-my;
        if mz>0 then QuickScanVert(forReal);
        end;

      procedure QuickAllHorzScans(forReal:boolean);
        begin
        if forReal then
          begin
          // LeftTop /
          dirX:=1; dirY:=-1;
          mx:=ceX-miX; atX:=miX;
          my:=miY-ceY; atY:=ceY;
          if mx>-my then mz:=mx else mz:=-my;
          if mz>0 then QuickScanHorz(forReal);

          // RightTop \
          dirX:=-1; dirY:=-1;
          mx:=ceX-maX; atX:=maX;
          my:=miY-ceY; atY:=ceY;
          if -mx>-my then mz:=-mx else mz:=-my;
          if mz>0 then QuickScanHorz(forReal);

          // LeftBottom \
          dirX:=1; dirY:=1;
          mx:=ceX-miX; atX:=miX;
          my:=maY-ceY; atY:=ceY;
          if mx>my then mz:=mx else mz:=my;
          if mz>0 then QuickScanHorz(forReal);

          // RightBottom /
          dirX:=-1; dirY:=1;
          mx:=ceX-maX; atX:=maX;
          my:=maY-ceY; atY:=ceY;
          if -mx>my then mz:=-mx else mz:=my;
          if mz>0 then QuickScanHorz(forReal);

          // Vert line, left-side
          dirX:=-1; dirY:=0;
          mx:=0; atX:=ceX;
          my:=maY-miY; atY:=miY;
          mz:=my;
          if mz>0 then QuickScanHorz(forReal);

          // Vert line, right-side
          dirX:=1; dirY:=0;
          mx:=0; atX:=ceX;
          my:=maY-miY; atY:=miY;
          mz:=my;
          if mz>0 then QuickScanHorz(forReal);

          // Horz line, up-side
          dirX:=0; dirY:=-1;
          mx:=maX-miX; atX:=miX;
          my:=0; atY:=ceY;
          mz:=mx;
          if mz>0 then QuickScanHorz(forReal);

          // Horz line, down-side
          dirX:=0; dirY:=1;
          mx:=maX-miX; atX:=miX;
          my:=0; atY:=ceY;
          mz:=mx;
          if mz>0 then QuickScanHorz(forReal);
          end;

        // LeftTop box
        dirX:=1; dirY:=1;
        mx:=ceX-miX; atX:=miX;
        my:=ceY-miY; atY:=miY;
        if mx>my then mz:=mx else mz:=my;
        if mz>0 then QuickScanHorz(forReal);

        // RightTop box
        dirX:=-1; dirY:=1;
        mx:=ceX-maX; atX:=maX;
        my:=ceY-miY; atY:=miY;
        if -mx>my then mz:=-mx else mz:=my;
        if mz>0 then QuickScanHorz(forReal);

        // LeftBottom box
        dirX:=1; dirY:=-1;
        mx:=ceX-miX; atX:=miX;
        my:=ceY-maY; atY:=maY;
        if mx>-my then mz:=mx else mz:=-my;
        if mz>0 then QuickScanHorz(forReal);

        // RightBottom box
        dirX:=-1;dirY:=-1;
        mx:=ceX-maX; atX:=maX;
        my:=ceY-maY; atY:=maY;
        if -mx>-my then mz:=-mx else mz:=-my;
        if mz>0 then QuickScanHorz(forReal);
        end;

      procedure QuickAllFullScans(forReal:boolean);
        begin
        if forReal then
          begin
          // LeftTop /
          dirX:=1; dirY:=-1;
          mx:=ceX-miX; atX:=miX;
          my:=miY-ceY; atY:=ceY;
          if mx>-my then mz:=mx else mz:=-my;
          if mz>0 then QuickScanFull(forReal);

          // RightTop \
          dirX:=-1; dirY:=-1;
          mx:=ceX-maX; atX:=maX;
          my:=miY-ceY; atY:=ceY;
          if -mx>-my then mz:=-mx else mz:=-my;
          if mz>0 then QuickScanFull(forReal);

          // LeftBottom \
          dirX:=1; dirY:=1;
          mx:=ceX-miX; atX:=miX;
          my:=maY-ceY; atY:=ceY;
          if mx>my then mz:=mx else mz:=my;
          if mz>0 then QuickScanFull(forReal);

          // RightBottom /
          dirX:=-1; dirY:=1;
          mx:=ceX-maX; atX:=maX;
          my:=maY-ceY; atY:=ceY;
          if -mx>my then mz:=-mx else mz:=my;
          if mz>0 then QuickScanFull(forReal);

          // Vert line, left-side
          dirX:=-1; dirY:=0;
          mx:=0; atX:=ceX;
          my:=maY-miY; atY:=miY;
          mz:=my;
          if mz>0 then QuickScanFull(forReal);

          // Vert line, right-side
          dirX:=1; dirY:=0;
          mx:=0; atX:=ceX;
          my:=maY-miY; atY:=miY;
          mz:=my;
          if mz>0 then QuickScanFull(forReal);

          // Horz line, up-side
          dirX:=0; dirY:=-1;
          mx:=maX-miX; atX:=miX;
          my:=0; atY:=ceY;
          mz:=mx;
          if mz>0 then QuickScanFull(forReal);

          // Horz line, down-side
          dirX:=0; dirY:=1;
          mx:=maX-miX; atX:=miX;
          my:=0; atY:=ceY;
          mz:=mx;
          if mz>0 then QuickScanFull(forReal);
          end;

        // LeftTop box
        dirX:=1; dirY:=1;
        mx:=ceX-miX; atX:=miX;
        my:=ceY-miY; atY:=miY;
        if mx>my then mz:=mx else mz:=my;
        if mz>0 then QuickScanFull(forReal);

        // RightTop box
        dirX:=-1; dirY:=1;
        mx:=ceX-maX; atX:=maX;
        my:=ceY-miY; atY:=miY;
        if -mx>my then mz:=-mx else mz:=my;
        if mz>0 then QuickScanFull(forReal);

        // LeftBottom box
        dirX:=1; dirY:=-1;
        mx:=ceX-miX; atX:=miX;
        my:=ceY-maY; atY:=maY;
        if mx>-my then mz:=mx else mz:=-my;
        if mz>0 then QuickScanFull(forReal);

        // RightBottom box
        dirX:=-1;dirY:=-1;
        mx:=ceX-maX; atX:=maX;
        my:=ceY-maY; atY:=maY;
        if -mx>-my then mz:=-mx else mz:=-my;
        if mz>0 then QuickScanFull(forReal);
        end;

      begin
      if (FMotionVertScanLimit>0) or
         (FMotionHorzScanLimit>0) or
         (FMotionFullScanLimit>0)  then
        StartTime:=GetTickTime;

      nextLine := OldBmpInfo.Width;
      nextLineBlock := nextLine * IMG_BLOCK_Y;

      mx:=NewBmpInfo.Width shr IMG_BLOCK_X_SHIFT - 1;
      my:=NewBmpInfo.Height shr IMG_BLOCK_Y_SHIFT - 1;

      sy1:=IMG_BLOCK_Y div 2; sy2:=sy1;
      if (sy2+sy1>=IMG_BLOCK_Y) then Dec(sy1);
      maxY:=OldBmpInfo.Height-IMG_BLOCK_Y;

      sx1:=IMG_BLOCK_X div 2; sx2:=sx1;
      if (sx2+sx1>=IMG_BLOCK_X) then Dec(sx1);
      maxX:=OldBmpInfo.Width-IMG_BLOCK_X;

      lineWid:=mx+1;
      haveOld:=False;

      lastY:=0;
      lastX:=0;

      miX:=mx;
      miY:=my;
      maX:=0;
      maY:=0;
      ceX:=0;
      ceY:=0;
      Count:=0;

      i:=0;
      for y:=0 to my do
        for x:=0 to mx do
          begin
          if scanIDs[i] then
            begin
            if x<miX then miX:=x;
            if x>maX then maX:=x;
            if y<miY then miY:=y;
            if y>maY then maY:=y;
            Inc(ceX,x);
            Inc(ceY,y);
            Inc(Count);
            end;
          Inc(i);
          end;
      if Count=0 then Exit;

      ceX:=ceX div Count;
      ceY:=ceY div Count;

      cntVert:=0;
      cntHorz:=0;
      cntFull:=0;
      haveVert:=0;
      haveHorz:=0;
      haveFull:=0;

      if FMotionVertScan then
        QuickAllVertScans(False);

      if FMotionHorzScan then
        QuickAllHorzScans(False);

      if FMotionFullScan then
        begin
        AddAllToSearchTree;
        QuickAllFullScans(False);
        end;

      if (haveFull<5) or
         (haveFull<=haveVert+haveHorz) or
         (haveFull<=cntFull div 4) then haveFull:=0; // <25% FULL found

      if (haveVert<5) or
         (haveVert<haveHorz) or
         (haveVert<=cntVert div 4) then haveVert:=0; // <25% VERT found

      if (haveHorz<5) or
         (haveHorz<haveVert) or
         (haveHorz<=cntHorz div 4) then haveHorz:=0; // <25% HORZ found

      mx:=maX-miX;
      my:=maY-miY;

      if (haveHorz>0) or (haveVert>0) then
        begin
        if haveVert>0 then
          QuickAllVertScans(True);
        if haveHorz>0 then
          QuickAllHorzScans(True);
        if (FMotionHorzScanLimit>0) or
           (FMotionVertScanLimit>0) then
          ScanHorzVertNow;
        if haveFull>0 then
          begin
          AddAllToSearchTree;
          QuickAllFullScans(True);
          if FMotionFullScanLimit>0 then
            ScanFullNow;
          end;
        end
      else if (haveFull>0) then
        begin
        QuickAllFullScans(True);
        if FMotionFullScanLimit>0 then
          ScanFullNow;
        end;

      ImgTree.removeall;
      end; // procedure

    procedure UpdateOldImage;
      var
        blockID,
        i,j:integer;
        OldColor:LongWord;
      begin
      if chgFound>0 then
        begin
        // Move blocks ...
        for i:=0 to length(changedIDs)-1 do
          begin
          case changedIDs[i] of
            2:
              begin
              dirtMarks[i]:=0;
              blockID:=fromIDs[i];
              if toIDs[i]<-blockID then
                Inc(chgRight)
              else
                Inc(chgLeft);
              // Old := New (moved)
              ImageItemCopy(-blockID,blockID);
              end;
            5:
              begin
              j:=toIDs[i];
              if changedIDs[j]=2 then
                begin
                dirtMarks[i]:=0;
                changedIDs[i]:=2;
                toIDs[i]:=toIDs[j];
                blockID:=fromIDs[i];
                if toIDs[i]<-blockID then
                  Inc(chgRight)
                else
                  Inc(chgLeft);
                // Old := New (moved)
                ImageItemCopy(-blockID,blockID);
                end;
              end;
            end;
          end;
        end;

      // Paint blocks ...
      for i:=0 to length(changedIDs)-1 do
        begin
        case changedIDs[i] of
          4:
            begin
            if dirtMarks[i]<DIRT_MARK_OK then
              begin
              dirtMarks[i]:=-dirtMarks[i];
              Inc(chgDraft);
              end
            else if dirtMarks[i]>DIRT_MARK_OK then
              begin
              Dec(dirtMarks[i]);
              Inc(chgDraft);
              end;
            dirtMarks[i]:=0;
            blockID:=fromIDs[i];
            // OLD := Block Color
            SetBlockColor(-blockID,toColors[i]);
            Inc(chgColor);
            end;
          1,5,3:
            begin
            blockID:=fromIDs[i];
            if DoReduceColors and (dirtMarks[i]>=DIRT_MARK_OK) and
               ImageItemSimilar(blockID,-blockID) then
              begin
              if FLastReduceColors=0 then
                FLastReduceColors:=GetTickTime;

              if dirtMarks[i]>DIRT_MARK_OK then
                begin
                Dec(dirtMarks[i]);
                Inc(chgDraft);
                end;

              // Skip update
              changedIDs[i]:=0;
              ImageItemCopy(blockID,-blockID);
              end
            else if FullColorComp then
              begin
              OldColor:=GetBlockColor(-blockID);
              toColors[i]:=GetBlockColorAvg(blockID);
              if (dirtMarks[i]<=DIRT_MARK_BAD) and (OldColor=toColors[i]) then
                begin // Old dirty, no visible changes
                if dirtMarks[i]<DIRT_MARK_BAD then
                  begin
                  Inc(dirtMarks[i]);
                  Inc(chgDraft);
                  end;
                // skip update
                changedIDs[i]:=0;
                ImageItemCopy(blockID,-blockID);
                end
              else
                begin
                if dirtMarks[i]>DIRT_MARK_BAD then
                  begin
                  dirtMarks[i]:=DIRT_MARK_BAD;
                  Inc(chgDraft);
                  end;
                changedIDs[i]:=4;
                SetBlockColor(blockID,toColors[i]);
                SetBlockColor(-blockID,toColors[i]);
                Inc(chgColor);
                end;
              end
            else
              begin
              OldColor:=GetBlockColor(-blockID);
              toColors[i]:=GetBlockColorAvg(blockID);
              if (dirtMarks[i]<=DIRT_MARK_BAD) and (OldColor=toColors[i]) then
                begin // Old dirty, no changes now -> update it
                dirtMarks[i]:=-dirtMarks[i];
                Inc(chgDraft);
                // update now
                changedIDs[i]:=0;
                end
              else if (dirtMarks[i]<=DIRT_MARK_MIN) or
                      (dirtMarks[i]>=DIRT_MARK_MOVE) then
                begin // Changed often -> don't use draft mode anymore until it stops changing
                dirtMarks[i]:=DIRT_MARK_MAX;
                Inc(chgDraft);
                // update now
                changedIDs[i]:=0;
                end
              else if DoColorComp and (ImageItemEqual(blockID,-blockID)<75) then
                begin // Less than 75% pixels equal, send draft block
                if dirtMarks[i]<DIRT_MARK_OK then
                  Dec(dirtMarks[i])
                else if dirtMarks[i]=DIRT_MARK_OK then
                  dirtMarks[i]:=DIRT_MARK_BAD
                else //  > DIRT_MARK_OK
                  dirtMarks[i]:=-dirtMarks[i];
                Inc(chgDraft);

                changedIDs[i]:=4;
                SetBlockColor(blockID,toColors[i]);
                SetBlockColor(-blockID,toColors[i]);
                Inc(chgColor);
                end
              else
                begin
                if dirtMarks[i]<DIRT_MARK_OK then
                  dirtMarks[i]:=-dirtMarks[i]
                else
                  Inc(dirtMarks[i]);
                Inc(chgDraft);
                // update now
                changedIDs[i]:=0;
                end;
              end;
            end;
          else
            begin
            if not FullColorComp then
              if dirtMarks[i]<>DIRT_MARK_OK then
                begin
                if dirtMarks[i]>DIRT_MARK_OK then
                  Dec(dirtMarks[i])
                else
                  dirtMarks[i]:=-dirtMarks[i];
                Inc(chgDraft);
                end;
            end;
          end;
        end;
      end;

    procedure ScanImage;
      var
        nextLine,
        blockID,
        x,y,mx,my:integer;
        scanCnt:integer;
      begin
      imgTree.removeall;

      mx:=NewBmpInfo.Width shr IMG_BLOCK_X_SHIFT - 1;
      my:=NewBmpInfo.Height shr IMG_BLOCK_Y_SHIFT - 1;

      nextLine:=NewBmpInfo.Width*IMG_BLOCK_Y - (mx+1)*IMG_BLOCK_X;

      chg:=0;
      chgDirty:=0;
      chgTotal:=0;
      chgLeft:=0;
      chgRight:=0;
      chgColor:=0;
      chgFound:=0;
      chgMoved:=0;
      scanCnt:=0;

      // First, scan the image and create a list of changed blocks ...
      blockID:=-1;

      if (IMG_BLOCK_X=1) and (IMG_BLOCK_Y=1) then
        begin
        if FColorComp then
          for y:=0 to my do
            begin
            for x:=0 to mx do
              begin
              if ImageItemChanged(blockID,-blockID) then // block changed
                begin
                fromIDs[chg]:=blockID;
                toColors[chg]:=GetBlockColor(blockID);
                changedIDs[chg]:=4;
                Inc(chgTotal);
                end;
              Inc(chg);
              Dec(blockID, IMG_BLOCK_X);
              end;
            Dec(blockID, nextLine);
            end;
        end
      else
        begin
        for y:=0 to my do
          begin
          for x:=0 to mx do
            begin
            if ImageItemChanged(blockID,-blockID) then // block changed
              begin
              if DoMotionComp then
                if (dirtMarks[chg]>=DIRT_MARK_OK) and
                   (dirtMarks[chg]<DIRT_MARK_MOVE) then
                  if not SingleColorBlock(-blockID) then
                    begin
                    Inc(scanCnt);
                    scanIDs[chg]:=true;

                    if x>0 then
                      if (dirtMarks[chg-1]>=DIRT_MARK_OK) and
                         (dirtMarks[chg-1]<DIRT_MARK_MOVE) then
                        scanIDs[chg-1]:=true;
                    if y>0 then
                      if (dirtMarks[chg-mx-1]>=DIRT_MARK_OK) and
                         (dirtMarks[chg-mx-1]<DIRT_MARK_MOVE) then
                        scanIDs[chg-mx-1]:=true;
                    if x<mx then
                      if (dirtMarks[chg+1]>=DIRT_MARK_OK) and
                         (dirtMarks[chg+1]<DIRT_MARK_MOVE) then
                        scanIDs[chg+1]:=true;
                    if y<my then
                      if (dirtMarks[chg+mx+1]>=DIRT_MARK_OK) and
                         (dirtMarks[chg+mx+1]<DIRT_MARK_MOVE) then
                        scanIDs[chg+mx+1]:=true;

                    if (x>0) and (y>0) then
                      if (dirtMarks[chg-mx-2]>=DIRT_MARK_OK) and
                         (dirtMarks[chg-mx-2]<DIRT_MARK_MOVE) then
                        scanIDs[chg-mx-2]:=true;
                    if (x<mx) and (y>0) then
                      if (dirtMarks[chg-mx]>=DIRT_MARK_OK) and
                         (dirtMarks[chg-mx]<DIRT_MARK_MOVE) then
                        scanIDs[chg-mx]:=true;
                    if (x>0) and (y<my) then
                      if (dirtMarks[chg+mx]>=DIRT_MARK_OK) and
                         (dirtMarks[chg+mx]<DIRT_MARK_MOVE) then
                        scanIDs[chg+mx]:=true;
                    if (x<mx) and (y<my) then
                      if (dirtMarks[chg+mx+2]>=DIRT_MARK_OK) and
                         (dirtMarks[chg+mx+2]<DIRT_MARK_MOVE) then
                        scanIDs[chg+mx+2]:=true;
                    end;
              if SingleColorBlock(blockID) then // new block is a Single Color Block
                begin
                fromIDs[chg]:=blockID;
                toColors[chg]:=GetBlockColor(blockID);
                changedIDs[chg]:=4;
                Inc(chgTotal);
                end
              else if DoMotionComp then // New block has more than 1 color
                begin
                fromIDs[chg]:=blockID;
                changedIDs[chg]:=1; // block not found yet
                Inc(chgMoved);
                Inc(chgDirty);
                Inc(chgTotal);
                end
              else
                begin
                fromIDs[chg]:=blockID;
                changedIDs[chg]:=3;
                Inc(chgTotal);
                end;
              end;
            Inc(chg);
            Dec(blockID, IMG_BLOCK_X);
            end;
          Dec(blockID, nextLine);
          end;
        end;

      if DoMotionComp and (scanCnt>0) and (chgDirty>0) then
        UpdateFullSearchTree;
      end;

    procedure CreateMotionList;
      var
        blockID,
        oldID,
        i:integer;

        myColor,
        myLastColor,
        toColorID:LongWord;

        myBlockLine,myBlockX,myBlockY,myBlockID:integer;

        xLeft,yLeft,
        xRight,yRight,
        xColor,yColor,

        lastColorID,lastLeftID,lastRightID,
        fromColorID,fromLeftID,fromRightID,
        toLeftID,toRightID,
        myLeft,myRight,
        // myLeftID,myRightID,
        myLastLeft,myLastRight:integer;

        colorBGR:colorBGR32;
        colorRGB:colorRGB32;

      begin
      SetLength(Result,10+(chgLeft+chgRight+chgColor)*6);

      i:=0;
      Result[i]:=IMG_BLOCK_X and $FF; Inc(i);
      Result[i]:=IMG_BLOCK_Y and $FF; Inc(i);

      // Result[i]:=(chgLeft shr 24) and $FF; Inc(i);
      Result[i]:=(chgLeft shr 16) and $FF; Inc(i);
      Result[i]:=(chgLeft shr 8) and $FF; Inc(i);
      Result[i]:=chgLeft and $FF; Inc(i);

      // Result[i]:=(chgRight shr 24) and $FF; Inc(i);
      Result[i]:=(chgRight shr 16) and $FF; Inc(i);
      Result[i]:=(chgRight shr 8) and $FF; Inc(i);
      Result[i]:=chgRight and $FF; Inc(i);

      lastLeftID:=0;
      lastRightID:=0;
      lastColorID:=0;

      myLastColor:=0;
      myLastLeft:=0;
      myLastRight:=0;

      myBlockLine:=(NewBmpInfo.Width shr IMG_BLOCK_X_SHIFT)+1;

      xLeft:=i;
      yLeft:=xLeft+chgLeft*3;
      xRight:=yLeft+chgLeft*3;
      yRight:=xRight+chgRight*3;
      xColor:=yRight+chgRight*3;
      yColor:=xColor+chgColor*3;

      // Encode Motion compensation blocks ...
      for i:=0 to chg-1 do
        begin
        if changedIDs[i]=4 then
          begin
          blockID:=-fromIDs[i]; // positive ID

          myBlockID:=blockID-1;
          myBlockY:=(myBlockID div NewBmpInfo.Width) shr IMG_BLOCK_Y_SHIFT;
          myBlockX:=(myBlockID mod NewBmpInfo.Width) shr IMG_BLOCK_X_SHIFT;
          myBlockID:=1 + myBlockX + myBlockY*myBlockLine;

          fromColorID:=myBlockID-lastColorID-1; // New block index (distance)
          lastColorID:=myBlockID;

          case NewBmpInfo.BuffType of
            btBGRA32:
              begin
              colorBGR:=colorBGR32(toColors[i]);
              myColor:=colorBGR.R;
              Inc(myColor, colorBGR.G shl 8);
              Inc(myColor, colorBGR.B shl 16);
              end;
            else
              begin
              colorRGB:=colorRGB32(toColors[i]);
              myColor:=colorRGB.R;
              Inc(myColor, colorRGB.G shl 8);
              Inc(myColor, colorRGB.B shl 16);
              end;
            end;
          toColorID:=myLastColor xor myColor;
          myLastColor:=myColor;

          // Result[xColor]:=(fromColorID shr 24) and $FF; Inc(xColor);
          Result[xColor]:=(fromColorID shr 16) and $FF; Inc(xColor);
          Result[xColor]:=(fromColorID shr 8) and $FF; Inc(xColor);
          Result[xColor]:=fromColorID and $FF; Inc(xColor);

          // Result[yColor]:=(toColorID shr 24) and $FF; Inc(yColor);
          Result[yColor]:=(toColorID shr 16) and $FF; Inc(yColor);
          Result[yColor]:=(toColorID shr 8) and $FF; Inc(yColor);
          Result[yColor]:=toColorID and $FF; Inc(yColor);

          Dec(chgColor);
          end
        else if changedIDs[i]=2 then
          begin
          blockID:=fromIDs[i]; // negative ID

          myBlockID:=-blockID-1;
          myBlockY:=(myBlockID div NewBmpInfo.Width) shr IMG_BLOCK_Y_SHIFT;
          myBlockX:=(myBlockID mod NewBmpInfo.Width) shr IMG_BLOCK_X_SHIFT;
          myBlockID:=1 + myBlockX + myBlockY*myBlockLine;

          oldID:=toIDs[i];
          if oldID<-blockID then // moved to the Right (positive)
            begin
            fromRightID:=myBlockID-lastRightID-1; // New block index (distance)
            lastRightID:=myBlockID;

            myRight:=-blockID-oldID-1; // move direction

            toRightID:=myLastRight xor myRight;
            myLastRight:=myRight;

            //Result[xRight]:=(fromRightID shr 24) and $FF; Inc(xRight);
            Result[xRight]:=(fromRightID shr 16) and $FF; Inc(xRight);
            Result[xRight]:=(fromRightID shr 8) and $FF; Inc(xRight);
            Result[xRight]:=fromRightID and $FF; Inc(xRight);

            //Result[yRight]:=(toRightID shr 24) and $FF; Inc(yRight);
            Result[yRight]:=(toRightID shr 16) and $FF; Inc(yRight);
            Result[yRight]:=(toRightID shr 8) and $FF; Inc(yRight);
            Result[yRight]:=toRightID and $FF; Inc(yRight);
            Dec(chgRight);
            end
          else
            begin
            fromLeftID:=myBlockID-lastLeftID-1;
            lastLeftID:=myBlockID;

            myLeft:=oldID+blockID-1; // move direction

            toLeftID:=myLastLeft xor myLeft;
            myLastLeft:=myLeft;

            //Result[xLeft]:=(fromLeftID shr 24) and $FF; Inc(xLeft);
            Result[xLeft]:=(fromLeftID shr 16) and $FF; Inc(xLeft);
            Result[xLeft]:=(fromLeftID shr 8) and $FF; Inc(xLeft);
            Result[xLeft]:=fromLeftID and $FF; Inc(xLeft);

            //Result[yLeft]:=(toLeftID shr 24) and $FF; Inc(yLeft);
            Result[yLeft]:=(toLeftID shr 16) and $FF; Inc(yLeft);
            Result[yLeft]:=(toLeftID shr 8) and $FF; Inc(yLeft);
            Result[yLeft]:=toLeftID and $FF; Inc(yLeft);
            Dec(chgLeft);
            end;
          end;
        end;
      end;

  procedure CalcScanMoves;
    var
      movX,movY,
      OldX,OldY,
      i,wid:integer;
    begin
    if FScanMoves then Exit;
    wid:=NewBmpInfo.PixelsToNextLine;
    OldX:=0;
    OldY:=0;
    for i:=0 to IMG_BLOCK_SIZE-1 do
      begin
      movX:=ScanPosX[i]-OldX;
      movY:=ScanPosY[i]-OldY;
      OldX:=ScanPosX[i];
      OldY:=ScanPosY[i];
      ScanMoves[i]:=movX+movY*wid;
      end;
    FScanMoves:=True;
    end;

  procedure UpdateSearchArrays;
    var
      ox,oy,mx,my,x,y:integer;
    begin
    if ( length(fromIDs)<>(NewBmpInfo.Height shr IMG_BLOCK_Y_SHIFT) *
                          (NewBmpInfo.Width shr IMG_BLOCK_X_SHIFT) ) or
        (LastMSX<>NewBmpInfo.Width) or
        (LastMSY<>NewBmpInfo.Height) or
        FFirstFrame then
      begin
      SetLength(fromIDs, (NewBmpInfo.Height shr IMG_BLOCK_Y_SHIFT) *
                         (NewBmpInfo.Width shr IMG_BLOCK_X_SHIFT));
      SetLength(toIDs,      length(fromIDs));
      SetLength(toColors,   length(fromIDs));
      SetLength(changedIDs, length(fromIDs));
      SetLength(scanIDs,    length(fromIDs));

      if length(dirtMarks)>0 then
        begin
        SetLength(newMarks,length(fromIDs));
        ox:=LastMSX shr IMG_BLOCK_X_SHIFT;
        oy:=LastMSY shr IMG_BLOCK_Y_SHIFT;
        mx:=NewBmpInfo.Width shr IMG_BLOCK_X_SHIFT;
        my:=NewBmpInfo.Height shr IMG_BLOCK_Y_SHIFT;
        for x:=0 to mx-1 do
          for y:=0 to my-1 do
            if (x>ox) or (y>oy) then
              newMarks[x+y*mx]:=0
            else
              newMarks[x+y*mx]:=dirtMarks[x+y*ox];
        // dirtMarks:=newMarks;
        SetLength(dirtMarks,length(newMarks));
        Move(newMarks[0],dirtMarks[0],length(dirtMarks));
        SetLength(newMarks,0);
        end
      else
        begin
        SetLength(dirtMarks,  length(fromIDs));
        FillChar(dirtMarks[0],length(dirtMarks),0);
        end;
      LastMSX:=NewBmpInfo.Width;
      LastMSY:=NewBmpInfo.Height;

      FScanMoves:=False;
      end;

    FillChar(scanIDs[0],length(scanIDs),0);
    FillChar(changedIDs[0],length(changedIDs),0);

    CalcScanMoves;
    end;

  begin
  SetLength(Result,0);

  if assigned(ImgTree) then
    ImgTree.removeall
  else
    begin
    ImgTree:=tItemSearchList.Create(OldBmpInfo.Width);

    ImgTree.SearchComparer:=ImageItemCompare;
    ImgTree.UpdateComparer:=ImageItemCompare;
    end;

  chgDraft:=0;

  UpdateSearchArrays;

  if FFirstFrame or (FMotionComp=False) then
    DoMotionComp:=False
  else
    DoMotionComp:=True;

  ScanImage;

  if FLastFrame or FFirstFrame or (FColorComp=False) then
    begin
    DoColorComp:=False;
    FLastColorComp:=0;
    end
  else if (chgTotal<=length(fromIDs) div 10) then // less than 10% screen changed
    begin
    DoColorComp:=False;
    FLastColorComp:=0;
    end
  else
    DoColorComp:=FColorComp;

  if FLastFrame or FFirstFrame or (FColorReduce=0) then
    begin
    DoReduceColors:=False;
    FLastReduceColors:=0;
    end
  else if FLastReduceColors=0 then
    DoReduceColors:=FColorReduce>0
  else if GetTickTime-FLastReduceColors>=5000 then
    begin
    FLastReduceColors:=0;
    DoReduceColors:=False;
    end
  else
    DoReduceColors:=FColorReduce>0;

  if (FRLECompress=False) and (FJPGCompress=False) then
    begin
    DoColorComp:=True;
    DoReduceColors:=FColorReduce>0;
    FullColorComp:=True;
    end
  else
    FullColorComp:=False;

  UpdateOldImage;

  if (chgLeft>0) or (chgRight>0) or (chgColor>0) then
    CreateMotionList;

  if chgDraft=0 then
    FLastColorComp:=0
  else if (chgDraft>0) and (FLastColorComp=0) then
    FLastColorComp:=GetTickTime;
  end;

function TRtcImageEncoder.ImageItemCompare(left, right: integer): integer;
  var
    leftP, rightP: PLongWord;
    movedPixels, i:integer;
  begin
  if right<0 then // Update & Search
    begin
    rightP:=PLongWord(NewBmpInfo.TopData);
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-right-1) mod NewBmpInfo.Width;
      Inc(rightP,movedPixels*2);
      Inc(rightP,right+1);
      end
    else
      Dec(rightP,right+1);
    end
  else
    begin
    Result:=1;
    Exit;
    end;
  if left<0 then // Update
    begin
    leftP:=PLongWord(NewBmpInfo.TopData);
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-left-1) mod NewBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Inc(leftP,left+1);
      end
    else
      Dec(leftP,left+1);
    end
  else if left>0 then // Search
    begin
    leftP:=PLongWord(OldBmpInfo.TopData);
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(left-1) mod OldBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Dec(leftP,left-1);
      end
    else
      Inc(leftP,left-1);
    end
  else
    begin
    Result:=-1;
    Exit;
    end;

  i:=0;
  repeat
    Inc(leftP,ScanMoves[i]);
    Inc(rightP,ScanMoves[i]);
    if leftP^<>rightP^ then
      begin
      if leftP^>rightP^ then
        begin
        Result:=1;
        Exit;
        end
      else if leftP^<rightP^ then
        begin
        Result:=-1;
        Exit;
        end;
      end;
    Inc(i);
    until i>63;
  Result:=0;
  end;

function TRtcImageEncoder.ImageItemChanged(left, right: integer): boolean;
  var
    leftP, rightP: PLongWord;
    movedPixels, i:integer;
  begin
  if right<0 then
    begin
    rightP:=PLongWord(NewBmpInfo.TopData);
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-right-1) mod NewBmpInfo.Width;
      Inc(rightP,movedPixels*2);
      Inc(rightP,right+1);
      end
    else
      Dec(rightP,right+1);
    end
  else
    begin
    rightP:=PLongWord(OldBmpInfo.TopData);
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(right-1) mod OldBmpInfo.Width;
      Inc(rightP,movedPixels*2);
      Dec(rightP,right-1);
      end
    else
      Inc(rightP,right-1);
    end;
  if left>0 then
    begin
    leftP:=PLongWord(OldBmpInfo.TopData);
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(left-1) mod OldBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Dec(leftP,left-1);
      end
    else
      Inc(leftP,left-1);
    end
  else
    begin
    leftP:=PLongWord(NewBmpInfo.TopData);
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-left-1) mod NewBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Inc(leftP,left+1);
      end
    else
      Dec(leftP,left+1);
    end;

  i:=0;
  repeat
    Inc(leftP,ScanMoves[i]);
    Inc(rightP,ScanMoves[i]);
    if leftP^<>rightP^ then
      begin
      Result:=True;
      Exit;
      end;
    Inc(i);
    until i>63;
  Result:=False;
  end;

function TRtcImageEncoder.ImageItemEqual(left, right: integer): integer;
  var
    leftP, rightP: PLongWord;
    leftStride, rightStride,
    movedPixels,
    x,y:integer;
  begin
  if right>0 then
    begin
    rightP:=PLongWord(OldBmpInfo.TopData);
    rightStride:=OldBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(right-1) mod OldBmpInfo.Width;
      Inc(rightP,movedPixels*2);
      Dec(rightP,right-1);
      end
    else
      Inc(rightP,right-1);
    end
  else
    begin
    rightP:=PLongWord(NewBmpInfo.TopData);
    rightStride:=NewBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-right-1) mod NewBmpInfo.Width;
      Inc(rightP,movedPixels*2);
      Inc(rightP,right+1);
      end
    else
      Dec(rightP,right+1);
    end;
  if left<0 then
    begin
    leftP:=PLongWord(NewBmpInfo.TopData);
    leftStride:=NewBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-left-1) mod NewBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Inc(leftP,left+1);
      end
    else
      Dec(leftP,left+1);
    end
  else
    begin
    leftP:=PLongWord(OldBmpInfo.TopData);
    leftStride:=OldBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(left-1) mod OldBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Dec(leftP,left-1);
      end
    else
      Inc(leftP,left-1);
    end;
  Result:=0;
  for y:=1 to IMG_BLOCK_Y do
    begin
    for x:=1 to IMG_BLOCK_X do
      begin
      if leftP^=rightP^ then
        Inc(Result);
      Inc(leftP);
      Inc(rightP);
      end;
    Inc(leftP,leftStride);
    Inc(rightP,rightStride);
    end;
  if Result>0 then
    Result:=(Result*100) shr IMG_BLOCK_SIZE_SHIFT;
  end;

function TRtcImageEncoder.SingleColorBlock(left: integer): boolean;
  var
    right: LongWord;
    leftP: PLongWord;
    leftStride,
    movedPixels,
    x,y:integer;
  begin
  Result:=True;
  if left>0 then
    begin
    leftP:=PLongWord(OldBmpInfo.TopData);
    leftStride:=OldBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(left-1) mod OldBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Dec(leftP,left-1);
      end
    else
      Inc(leftP,left-1);
    end
  else if left<0 then
    begin
    leftP:=PLongWord(NewBmpInfo.TopData);
    leftStride:=NewBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-left-1) mod NewBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Inc(leftP,left+1);
      end
    else
      Dec(leftP,left+1);
    end
  else
    Exit;
  right:=leftP^;
  for y:=1 to IMG_BLOCK_Y do
    begin
    for x:=1 to IMG_BLOCK_X do
      begin
      if leftP^<>right then
        begin
        Result:=False;
        Exit;
        end;
      Inc(leftP);
      end;
    Inc(leftP,leftStride);
    end;
  end;

procedure TRtcImageEncoder.SetBlockColor(left:integer; right:LongWord);
  var
    leftP: PLongWord;
    leftStride,
    movedPixels,
    x,y:integer;
  begin
  if left>0 then
    begin
    leftP:=PLongWord(OldBmpInfo.TopData);
    leftStride:=OldBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(left-1) mod OldBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Dec(leftP,left-1);
      end
    else
      Inc(leftP,left-1);
    end
  else if left<0 then
    begin
    leftP:=PLongWord(NewBmpInfo.TopData);
    leftStride:=NewBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-left-1) mod NewBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Inc(leftP,left+1);
      end
    else
      Dec(leftP,left+1);
    end
  else
    Exit;
  for y:=1 to IMG_BLOCK_Y do
    begin
    for x:=1 to IMG_BLOCK_X do
      begin
      leftP^:=right;
      Inc(leftP);
      end;
    Inc(leftP,leftStride);
    end;
  end;

function TRtcImageEncoder.GetBlockColor(left: integer): LongWord;
  var
    leftP: PLongWord;
    movedPixels: integer;
  begin
  if left>0 then
    begin
    leftP:=PLongWord(OldBmpInfo.TopData);
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(left-1) mod OldBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Dec(leftP,left-1);
      end
    else
      Inc(leftP,left-1);
    Result:=leftP^;
    end
  else if left<0 then
    begin
    leftP:=PLongWord(NewBmpInfo.TopData);
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-left-1) mod NewBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Inc(leftP,left+1);
      end
    else
      Dec(leftP,left+1);
    Result:=leftP^;
    end
  else
    Result:=0;
  end;

function TRtcImageEncoder.GetBlockColorAvg(left:integer): LongWord;
  var
    leftP: PColorBGR32;
    leftStride,
    r,g,b:LongWord;
    movedPixels,
    x,y:integer;
  begin
  if left>0 then
    begin
    leftP:=PColorBGR32(OldBmpInfo.TopData);
    leftStride:=OldBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(left-1) mod OldBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Dec(leftP,left-1);
      end
    else
      Inc(leftP,left-1);
    end
  else if left<0 then
    begin
    leftP:=PColorBGR32(NewBmpInfo.TopData);
    leftStride:=NewBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-left-1) mod NewBmpInfo.Width;
      Inc(leftP,movedPixels*2);
      Inc(leftP,left+1);
      end
    else
      Dec(leftP,left+1);
    end
  else
    begin
    Result:=0;
    Exit;
    end;

  r:=0; g:=0; b:=0;
  for y:=1 to IMG_BLOCK_Y do
    begin
    for x:=1 to IMG_BLOCK_X do
      begin
      Inc(b,leftP^.B);
      Inc(g,leftP^.G);
      Inc(r,leftP^.R);
      Inc(leftP);
      end;
    Inc(leftP,leftStride);
    end;
  r:=r shr IMG_BLOCK_SIZE_SHIFT;
  g:=g shr IMG_BLOCK_SIZE_SHIFT;
  b:=b shr IMG_BLOCK_SIZE_SHIFT;

  Result:=$FF;
  Result:=(Result shl 8) or r;
  Result:=(Result shl 8) or g;
  Result:=(Result shl 8) or b;
  end;

procedure TRtcImageEncoder.ImageItemCopy(left, right: integer);
  var
    leftP, rightP: PLongWord;
    leftStride, rightStride,
    movedPixels,
    x,y:integer;
  begin
  if (left<>0) and (right<>0) then
    begin
    if left>0 then
      begin
      leftP:=PLongWord(OldBmpInfo.TopData);
      leftStride:=OldBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
      if OldBmpInfo.Reverse then
        begin
        movedPixels:=(left-1) mod OldBmpInfo.Width;
        Inc(leftP,movedPixels*2);
        Dec(leftP,left-1);
        end
      else
        Inc(leftP,left-1);
      end
    else
      begin
      leftP:=PLongWord(NewBmpInfo.TopData);
      leftStride:=NewBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
      if NewBmpInfo.Reverse then
        begin
        movedPixels:=(-left-1) mod NewBmpInfo.Width;
        Inc(leftP,movedPixels*2);
        Inc(leftP,left+1);
        end
      else
        Dec(leftP,left+1);
      end;
    if right>0 then
      begin
      rightP:=PLongWord(OldBmpInfo.TopData);
      rightStride:=OldBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
      if OldBmpInfo.Reverse then
        begin
        movedPixels:=(right-1) mod OldBmpInfo.Width;
        Inc(rightP,movedPixels*2);
        Dec(rightP,right-1);
        end
      else
        Inc(rightP,right-1);
      end
    else
      begin
      rightP:=PLongWord(NewBmpInfo.TopData);
      rightStride:=NewBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
      if NewBmpInfo.Reverse then
        begin
        movedPixels:=(-right-1) mod NewBmpInfo.Width;
        Inc(rightP,movedPixels*2);
        Inc(rightP,right+1);
        end
      else
        Dec(rightP,right+1);
      end;
    for y:=1 to IMG_BLOCK_Y do
      begin
      for x:=1 to IMG_BLOCK_X do
        begin
        leftP^:=rightP^;
        Inc(leftP);
        Inc(rightP);
        end;
      Inc(leftP,leftStride);
      Inc(rightP,rightStride);
      end;
    end;
  end;

function TRtcImageEncoder.ImageItemSimilar(left, right: integer):boolean;
  var
    leftP, rightP: PColorBGR32;
    leftX: PLongWord absolute leftP;
    rightX: PLongWord absolute rightP;

    leftStride, rightStride,
    lR,lG,lB,
    rR,rG,rB,
    dR,dG,dB,dC,
    movedPixels,
    x,y:integer;
  begin
  Result:=False;
  if (FColorReduce>0) and (left<>0) and (right<>0) then
    begin
    if left>0 then
      begin
      leftP:=PColorBGR32(OldBmpInfo.TopData);
      leftStride:=OldBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
      if OldBmpInfo.Reverse then
        begin
        movedPixels:=(left-1) mod OldBmpInfo.Width;
        Inc(leftP,movedPixels*2);
        Dec(leftP,left-1);
        end
      else
        Inc(leftP,left-1);
      end
    else
      begin
      leftP:=PColorBGR32(NewBmpInfo.TopData);
      leftStride:=NewBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
      if NewBmpInfo.Reverse then
        begin
        movedPixels:=(-left-1) mod NewBmpInfo.Width;
        Inc(leftP,movedPixels*2);
        Inc(leftP,left+1);
        end
      else
        Dec(leftP,left+1);
      end;
    if right>0 then
      begin
      rightP:=PColorBGR32(OldBmpInfo.TopData);
      rightStride:=OldBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
      if OldBmpInfo.Reverse then
        begin
        movedPixels:=(right-1) mod OldBmpInfo.Width;
        Inc(rightP,movedPixels*2);
        Dec(rightP,right-1);
        end
      else
        Inc(rightP,right-1);
      end
    else
      begin
      rightP:=PColorBGR32(NewBmpInfo.TopData);
      rightStride:=NewBmpInfo.PixelsToNextLine-IMG_BLOCK_X;
      if NewBmpInfo.Reverse then
        begin
        movedPixels:=(-right-1) mod NewBmpInfo.Width;
        Inc(rightP,movedPixels*2);
        Inc(rightP,right+1);
        end
      else
        Dec(rightP,right+1);
      end;
    Result:=False;
    for y:=1 to IMG_Block_Y do
      begin
      for x:=1 to IMG_Block_X do
        begin
        if leftX^<>rightX^ then
          begin
          lG:=leftP^.G;
          rG:=rightP^.G;
          if lG=rG then
            dG:=0
          else if lG>rG then
            dG:=lG-rG
          else
            dG:=rG-lG;

          if dG>FColorReduce then Exit;

          lR:=leftP^.R;
          rR:=rightP^.R;
          if lR=rR then
            dR:=0
          else if lR>rR then
            dR:=lR-rR
          else
            dR:=rR-lR;

          lB:=leftP^.B;
          rB:=rightP^.B;
          if lB=rB then
            dB:=0
          else if lB>rB then
            dB:=lB-rB
          else
            dB:=rB-lB;

          dC:=(dR*306 + dG*601 + dB*117) shr 10;

          if dC>FColorReduce then Exit;
          end;
        Inc(leftP);
        Inc(rightP);
        end;
      Inc(leftP,leftStride);
      Inc(rightP,rightStride);
      end;
    Result:=True;
    end;
  end;

procedure TRtcImageEncoder.SetColorBitsB(const Value: integer);
  begin
  if Value>8 then
    FColorBitsB:=8
  else if Value<1 then
    FColorBitsB:=1
  else
    FColorBitsB:=Value;
  FColorDiffB:=$FF shr FColorBitsB;
  FColorMask:=$FF000000;
  FColorMask:=FColorMask or (($FF shl (8-FColorBitsR)) and $FF shl 16);
  FColorMask:=FColorMask or (($FF shl (8-FColorBitsG)) and $FF shl 8);
  FColorMask:=FColorMask or (($FF shl (8-FColorBitsB)) and $FF);
  end;

procedure TRtcImageEncoder.SetColorBitsG(const Value: integer);
  begin
  if Value>8 then
    FColorBitsG:=8
  else if Value<1 then
    FColorBitsG:=1
  else
    FColorBitsG:=Value;
  FColorDiffG:=$FF shr FColorBitsG;
  FColorMask:=$FF000000;
  FColorMask:=FColorMask or (($FF shl (8-FColorBitsR)) and $FF shl 16);
  FColorMask:=FColorMask or (($FF shl (8-FColorBitsG)) and $FF shl 8);
  FColorMask:=FColorMask or (($FF shl (8-FColorBitsB)) and $FF);
  end;

procedure TRtcImageEncoder.SetColorBitsR(const Value: integer);
  begin
  if Value>8 then
    FColorBitsR:=8
  else if Value<1 then
    FColorBitsR:=1
  else
    FColorBitsR:=Value;
  FColorDiffR:=$FF shr FColorBitsR;
  FColorMask:=$FF000000;
  FColorMask:=FColorMask or (($FF shl (8-FColorBitsR)) and $FF shl 16);
  FColorMask:=FColorMask or (($FF shl (8-FColorBitsG)) and $FF shl 8);
  FColorMask:=FColorMask or (($FF shl (8-FColorBitsB)) and $FF);
  end;

procedure TRtcImageEncoder.ReduceColors(var BmpInfo: TRtcBitmapInfo);
  var
    i:longword;
    p:PLongWord;
  begin
  if (FColorMask=DEFAULT_COLOR_MASK) then Exit;

  p:=PLongWord(BmpInfo.Data);
  for i:=1 to BmpInfo.Width*BmpInfo.Height do
    begin
    p^:=p^ and FColorMask;
    Inc(p);
    end;
  end;

function TRtcImageEncoder.CompressMouse(const MouseCursorInfo: RtcByteArray; LZW:boolean=False): RtcByteArray;
  var
    tmp2:RtcByteArray;
    len:integer;
  begin
  SetLength(tmp2,0);
  SetLength(Result,0);
  if length(MouseCursorInfo)>0 then
    begin
    if FLZWCompress or LZW then
      begin
      tmp2:=ZCompress_Ex(MouseCursorInfo,zcFastest);
      len:=length(tmp2);
      LZW:=True;
      end
    else
      len:=length(MouseCursorInfo);

    SetLength(Result,5+len);
    if LZW then
      Result[0]:=img_CUR+img_LZW
    else
      Result[0]:=img_CUR;

    Result[1]:=(len shr 24) and $FF;
    Result[2]:=(len shr 16) and $FF;
    Result[3]:=(len shr 8) and $FF;
    Result[4]:=len and $FF;

    if LZW then
      Move(tmp2[0],Result[5],len)
    else
      Move(MouseCursorInfo[0],Result[5],len);

    SetLength(tmp2,0);
    end;
  end;

function TRtcImageEncoder.NeedRefresh: boolean;
  begin
  if FFirstFrame then
    Result:=True
  else if (FLastColorComp>0) then
    Result:=True
  else if (FLastReduceColors>0) and (GetTickTime-FLastReduceColors>=5000) then
    Result:=True
  else
    Result:=False;
  end;

function TRtcImageEncoder.BitmapChanged: boolean;
  begin
  if not assigned(NewBmpInfo.Data) then
    Result:=False
  else if not assigned(OldBmpInfo.Data) then
    Result:=True
  else if NeedRefresh then
    Result:=True // force refresh check
  else
    begin
    if (NewBmpInfo.Width<>OldBmpInfo.Width) then
      Result:=True
    else if (NewBmpInfo.Height<>OldBmpInfo.Height) then
      Result:=True
    else if CompareMem(OldBmpInfo.Data,NewBmpInfo.Data,NewBmpInfo.Width*NewBmpInfo.Height*4) then
      Result:=False
    else
      Result:=True;
    end;
  end;

procedure TRtcImageEncoder.SetColorReduce(const Value: integer);
  begin
  FColorReduce := Value;
  end;

end.
