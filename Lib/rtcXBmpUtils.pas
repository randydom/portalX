{
  "Bitmap Utils"
  - Copyright 2013-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcXBmpUtils;

interface

{$INCLUDE rtcDefs.inc}

uses
  SysUtils,

  rtcTypes,
  rtcSyncObjs,
  rtcInfo,

  rtcXJPEGConst;

type
  BufferType=(btBGR24,btBGRA32,
              btRGB24,btRGBA32);

  TRtcBitmapInfo=record
    Data:Pointer;
    TopData:^Byte;
    Width,Height:integer;
    Reverse:boolean;
    BuffType:BufferType;
    BytesTotal,
    BytesPerPixel,
    BytesPerLine,
    PixelsToNextLine,
    TopLine,
    NextLine:integer;
    end;

  TRtcCursorRect=record
    Left,Top,
    Right,Bottom:integer;
    end;

  TRtcMouseCursorInfo=class(TObject)
  protected
    FCS:TRtcCritSec;

    FCursorVisible: boolean;
    FCursorHotX: integer;
    FCursorHotY: integer;
    FCursorX: integer;
    FCursorY: integer;
    FCursorImageW: integer;
    FCursorImageH: integer;
    FCursorMaskW: integer;
    FCursorMaskH: integer;
    FCursorOldY: integer;
    FCursorOldX: integer;
    FCursorUser: cardinal;
    FCursorImageData: RtcByteArray;
    FCursorMaskData: RtcByteArray;
    FData: TObject;

    procedure RealUpdate(const rec:TRtcRecord);

  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Lock;
    procedure UnLock;

    procedure ClearImageData;
    procedure ClearMaskData;

    procedure Update(const MouseCursorData:RtcByteArray);

    function GetRect(NowMouseX, NowMouseY: integer; inControl: boolean): TRtcCursorRect;

    property Visible:boolean read FCursorVisible;
    property HotX:integer read FCursorHotX;
    property HotY:integer read FCursorHotY;
    property X:integer read FCursorX;
    property Y:integer read FCursorY;
    property ImageW:integer read FCursorImageW;
    property ImageH:integer read FCursorImageH;
    property MaskW:integer read FCursorMaskW;
    property MaskH:integer read FCursorMaskH;
    property OldX:integer read FCursorOldX;
    property OldY:integer read FCursorOldY;
    property User:cardinal read FCursorUser;
    property ImageData:RtcByteArray read FCursorImageData;
    property MaskData:RtcByteArray read FCursorMaskData;

    property Data:TObject read FData write FData;
    end;

// Map BitmapInfo for internal usage
function MapBitmapInfo(const OldBmp:TRtcBitmapInfo):TRtcBitmapInfo;
// Unmap BitmapInfo
procedure UnMapBitmapInfo(var NewBmp:TRtcBitmapInfo);

procedure CompleteBitmapInfo(var Result:TRtcBitmapInfo);
// Reset Bitmap Info image
procedure ResetBitmapInfo(var NewBmp:TRtcBitmapInfo);
// Make an exact duplicate of OldBmp, copying image contents
function DuplicateBitmapInfo(const OldBmp:TRtcBitmapInfo):TRtcBitmapInfo;
// Copy image with all info from OldBmp to Result
procedure CopyBitmapInfo(const OldBmp:TRtcBitmapInfo; var Result:TRtcBitmapInfo);
// Resize the memory occupied by the image
procedure ResizeBitmapInfo(var BmpInfo:TRtcBitmapInfo; SizeX,SizeY:integer; Clear:boolean);
// Release the memory occupied by the image copy created with DuplicateBitmapInfo
procedure ReleaseBitmapInfo(var NewBmp:TRtcBitmapInfo);

implementation

procedure CompleteBitmapInfo(var Result:TRtcBitmapInfo);
  begin
  if Result.Reverse then
    begin
    Result.TopLine:=Result.BytesPerLine*(Result.Height-1);
    Result.NextLine:=-Result.BytesPerLine;
    end
  else
    begin
    Result.TopLine:=0;
    Result.NextLine:=Result.BytesPerLine;
    end;

  Result.TopData:=Result.Data;
  if assigned(Result.TopData) then
    Inc(Result.TopData,Result.TopLine);

  Result.BytesTotal:=Result.BytesPerPixel*Result.Width;
  if Result.Height>1 then
    Inc(Result.BytesTotal,Result.BytesPerLine*(Result.Height-1));

  if Result.BytesPerPixel>0 then
    begin
    Result.PixelsToNextLine:=Result.BytesPerLine div Result.BytesPerPixel;
    if Result.Reverse then
      Result.PixelsToNextLine:=-Result.PixelsToNextLine;
    end
  else
    Result.PixelsToNextLine:=0;
  end;

function DuplicateBitmapInfo(const OldBmp:TRtcBitmapInfo):TRtcBitmapInfo;
  begin
  FillChar(Result, SizeOf(Result), 0);

  Result.Width:=OldBmp.Width;
  Result.Height:=OldBmp.Height;
  Result.Reverse:=OldBmp.Reverse;
  Result.BuffType:=OldBmp.BuffType;
  Result.BytesPerPixel:=OldBmp.BytesPerPixel;
  Result.BytesPerLine:=OldBmp.BytesPerLine;

  Result.TopLine:=OldBmp.TopLine;
  Result.NextLine:=OldBmp.NextLine;

  Result.BytesTotal:=Result.BytesPerPixel*Result.Width;
  if Result.Height>1 then
    Inc(Result.BytesTotal,Result.BytesPerLine*(Result.Height-1));

  if Result.BytesPerPixel>0 then
    begin
    Result.PixelsToNextLine:=Result.BytesPerLine div Result.BytesPerPixel;
    if Result.Reverse then
      Result.PixelsToNextLine:=-Result.PixelsToNextLine;
    end
  else
    Result.PixelsToNextLine:=0;

  Result.PixelsToNextLine:=Result.BytesPerLine div Result.BytesPerPixel;
  if Result.Reverse then
    Result.PixelsToNextLine:=-Result.PixelsToNextLine;

  if Result.BytesTotal>0 then
    begin
    GetMem(Result.Data, Result.BytesTotal);
    Move(OldBmp.Data^, Result.Data^, Result.BytesTotal);

    Result.TopData:=Result.Data;
    Inc(Result.TopData,Result.TopLine);
    end;
  end;

procedure CopyBitmapInfo(const OldBmp:TRtcBitmapInfo; var Result:TRtcBitmapInfo);
  begin
  if assigned(Result.Data) then
    begin
    if Result.BytesTotal<>OldBmp.BytesTotal then
      begin
      if OldBmp.BytesTotal>0 then
        ReallocMem(Result.Data,OldBmp.BytesTotal)
      else
        begin
        FreeMem(Result.Data);
        Result.Data:=nil;
        end;
      end;
    end
  else if OldBmp.BytesTotal>0 then
    GetMem(Result.Data,OldBmp.BytesTotal);

  Result.Width:=OldBmp.Width;
  Result.Height:=OldBmp.Height;
  Result.Reverse:=OldBmp.Reverse;
  Result.BuffType:=OldBmp.BuffType;
  Result.BytesPerPixel:=OldBmp.BytesPerPixel;
  Result.BytesPerLine:=OldBmp.BytesPerLine;

  Result.TopLine:=OldBmp.TopLine;
  Result.NextLine:=OldBmp.NextLine;
  Result.BytesTotal:=OldBmp.BytesTotal;
  Result.PixelsToNextLine:=OldBmp.PixelsToNextLine;

  if Result.BytesTotal>0 then
    begin
    Move(OldBmp.Data^, Result.Data^, Result.BytesTotal);

    Result.TopData:=Result.Data;
    Inc(Result.TopData,Result.TopLine);
    end;
  end;

procedure ReleaseBitmapInfo(var NewBmp:TRtcBitmapInfo);
  begin
  if assigned(NewBmp.Data) then
    begin
    FreeMem(NewBmp.Data);
    FillChar(NewBmp,SizeOf(NewBmp),0);
    end;
  end;

function MapBitmapInfo(const OldBmp:TRtcBitmapInfo):TRtcBitmapInfo;
  begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Data:=OldBmp.Data;
  Result.Width:=OldBmp.Width;
  Result.Height:=OldBmp.Height;
  Result.Reverse:=OldBmp.Reverse;
  Result.BuffType:=OldBmp.BuffType;
  Result.BytesPerPixel:=OldBmp.BytesPerPixel;
  Result.BytesPerLine:=OldBmp.BytesPerLine;
  Result.TopLine:=OldBmp.TopLine;
  Result.NextLine:=OldBmp.NextLine;
  Result.BytesTotal:=OldBmp.BytesTotal;

  Result.TopData:=OldBmp.TopData;
  Result.PixelsToNextLine:=OldBmp.PixelsToNextLine;
  end;

procedure UnMapBitmapInfo(var NewBmp:TRtcBitmapInfo);
  begin
  FillChar(NewBmp, SizeOf(NewBmp), 0);
  end;

procedure ClearBitmapInfo(var BmpInfo:TRtcBitmapInfo);
  var
    pix:LongWord;
    data:PLongWord;
    cnt,i:integer;
    crgb:colorRGB32;
    cbgr:colorBGR32;
  begin
  if not assigned(BmpInfo.Data) then Exit;
  if (BmpInfo.Width=0) or (BmpInfo.Height=0) then Exit;

  cnt:=BmpInfo.Width*BmpInfo.Height;
  crgb.R:=0;crgb.B:=0;crgb.G:=0;crgb.A:=255;
  cbgr.R:=0;cbgr.B:=0;cbgr.G:=0;cbgr.A:=255;
  case BmpInfo.BuffType of
    btBGRA32: pix:=LongWord(cbgr);
    btRGBA32: pix:=LongWord(crgb);
    else pix:=0;
    end;
  data:=PLongWord(BmpInfo.Data);
  for i := 1 to cnt do
    begin
    data^:=pix;
    Inc(data);
    end;
  end;

procedure ResizeBitmapInfo(var BmpInfo:TRtcBitmapInfo; SizeX,SizeY:integer; Clear:boolean);
  var
    OldData:pointer;
    Src,Dst:^Byte;
    OldSX,OldSY,
    SX,SY,BPL,BPLS,BPLD,Line:integer;
  begin
  if (SizeX<>BmpInfo.Width) or (SizeY<>BmpInfo.Height) then
    begin
    if (SizeX>0) and (SizeY>0) then
      begin
      OldData:=BmpInfo.Data;
      OldSX:=BmpInfo.Width;
      OldSY:=BmpInfo.Height;
      GetMem(BmpInfo.Data,SizeX*SizeY*BmpInfo.BytesPerPixel);
      BmpInfo.TopData:=BmpInfo.Data;
      BmpInfo.Width:=SizeX;
      BmpInfo.Height:=SizeY;
      ClearBitmapInfo(BmpInfo);
      if SizeX>OldSX then SX:=OldSX else SX:=SizeX;
      if SizeY>OldSY then SY:=OldSY else SY:=SizeY;
      if assigned(OldData) then
        begin
        if not Clear and (SX>0) and (SY>0) then
          begin
          Src:=OldData;
          Dst:=BmpInfo.Data;
          BPL :=BmpInfo.BytesPerPixel * SX;
          BPLS:=BmpInfo.BytesPerPixel * OldSX;
          BPLD:=BmpInfo.BytesPerPixel * SizeX;
          if BmpInfo.Reverse then
            begin
            Inc(Src,BPLS*(OldSY-1));
            Inc(Dst,BPLD*(SizeY-1));
            for Line:=1 to SY do
              begin
              Move(Src^,Dst^,BPL);
              Dec(Src,BPLS);
              Dec(Dst,BPLD);
              end;
            end
          else
            begin
            for Line:=1 to SY do
              begin
              Move(Src^,Dst^,BPL);
              Inc(Src,BPLS);
              Inc(Dst,BPLD);
              end;
            end;
          end;
        FreeMem(OldData);
        end;
      end
    else if assigned(BmpInfo.Data) then
      begin
      FreeMem(BmpInfo.Data);
      BmpInfo.Data:=nil;
      BmpInfo.TopData:=nil;
      BmpInfo.Width:=0;
      BmpInfo.Height:=0;
      end;

    BmpInfo.BytesPerLine:=BmpInfo.BytesPerPixel*BmpInfo.Width;
    CompleteBitmapInfo(BmpInfo);
    end
  else if Clear and assigned(BmpInfo.Data) and (BmpInfo.BytesTotal>0) then
    ClearBitmapInfo(BmpInfo);
  end;

procedure ResetBitmapInfo(var NewBmp:TRtcBitmapInfo);
  begin
  if assigned(NewBmp.Data) then
    begin
    FreeMem(NewBmp.Data);
    NewBmp.Data:=nil;
    NewBmp.TopData:=nil;
    NewBmp.Width:=0;
    NewBmp.Height:=0;
    NewBmp.BytesPerLine:=0;
    CompleteBitmapInfo(NewBmp);
    end;
  end;

{ TRtcMouseCursorInfo }

constructor TRtcMouseCursorInfo.Create;
  begin
  FCS:=TRtcCritSec.Create;
  FCursorVisible:=False;
  SetLength(FCursorImageData,0);
  SetLength(FCursorMaskData,0);
  FData:=nil;
  end;

destructor TRtcMouseCursorInfo.Destroy;
  begin
  SetLength(FCursorImageData,0);
  SetLength(FCursorMaskData,0);
  FreeAndNil(FCS);
  FreeAndNil(FData);
  inherited;
  end;

procedure TRtcMouseCursorInfo.Update(const MouseCursorData: RtcByteArray);
  var
    rec: TRtcRecord;
  begin
  if length(MouseCursorData)=0 then Exit;

  rec := TRtcRecord.FromCode(RtcBytesToString(MouseCursorData));
  FCS.Acquire;
  try
    RealUpdate(rec);
  finally
    FCS.Release;
    rec.Free;
    end;
  end;

procedure TRtcMouseCursorInfo.RealUpdate(const rec:TRtcRecord);
  begin
  if (rec.isType['X'] <> rtc_Null) or (rec.isType['Y'] <> rtc_Null) then
    begin
    if FCursorVisible then
      begin
      FCursorOldX := FCursorX;
      FCursorOldY := FCursorY;
      end
    else
      begin
      FCursorOldX := rec.asInteger['X'];
      FCursorOldY := rec.asInteger['Y'];
      end;
    FCursorX := rec.asInteger['X'];
    FCursorY := rec.asInteger['Y'];
    FCursorUser := rec.asCardinal['A'];
    end;
  if (rec.isType['V'] <> rtc_Null) and (rec.asBoolean['V'] <> FCursorVisible) then
    FCursorVisible := rec.asBoolean['V'];

  if rec.isType['HX'] <> rtc_Null then
    begin
    FCursorHotX := rec.asInteger['HX'];
    FCursorHotY := rec.asInteger['HY'];
    if rec.isType['IW']<>rtc_Null then
      begin
      FCursorImageW:=rec.asInteger['IW'];
      FCursorImageH:=rec.asInteger['IH'];
      end
    else
      begin
      FCursorImageW:=0;
      FCursorImageH:=0;
      end;
    if rec.isType['MW']<>rtc_Null then
      begin
      FCursorMaskW:=rec.asInteger['MW'];
      FCursorMaskH:=rec.asInteger['MH'];
      end
    else
      begin
      FCursorMaskW:=0;
      FCursorMaskH:=0;
      end;
    if (rec.isType['I']=rtc_ByteArray) or
       (rec.isType['M']=rtc_ByteArray) then
      begin
      SetLength(FCursorImageData,0);
      SetLength(FCursorMaskData,0);
      if rec.isType['I']=rtc_ByteArray then
        if (length(rec.asByteArray['I'])>0) and
           (length(rec.asByteArray['I'])=FCursorImageW*FCursorImageH*4) then
          FCursorImageData:=rec.asByteArray['I'];
      if rec.isType['M']=rtc_ByteArray then
        if (length(rec.asByteArray['M'])>0) and
           (length(rec.asByteArray['M'])=FCursorMaskW*FCursorMaskH*4) then
          FCursorMaskData:=rec.asByteArray['M'];
      end;
    end;
  end;

function TRtcMouseCursorInfo.GetRect(NowMouseX, NowMouseY: integer; inControl: boolean): TRtcCursorRect;
  var
    cX,cY:integer;
    cW,cH:integer;
  begin
  FCS.Acquire;
  try
    if FCursorVisible and ((FCursorImageW+FCursorImageH>0) or (FCursorMaskW+FCursorMaskH>0)) then
      begin
      if inControl then
        begin
        cX:=NowMouseX-FCursorHotX;
        cY:=NowMouseY-FCursorHotY;
        end
      else
        begin
        cX:=FCursorX-FCursorHotX;
        cY:=FCursorY-FCursorHotY;
        end;
      cW:=0;
      cH:=0;
      if (FCursorMaskH+FCursorMaskW>0) then
        begin
        if (FCursorImageH+FCursorImageW>0) and (FCursorMaskH = FCursorImageH) then
          begin
          cW:=FCursorMaskW;
          cH:=FCursorMaskH;
          end
        else if FCursorMaskH > 1 then
          begin
          cW:=FCursorMaskW;
          cH:=FCursorMaskH div 2;
          end;
        end;
      if (FCursorImageH+FCursorImageW>0) then
        begin
        if FCursorImageW>cW then cW:=FCursorImageW;
        if FCursorImageH>cH then cH:=FCursorImageH;
        end;
      end
    else
      begin
      cX:=0;cY:=0;
      cW:=0;cH:=0;
      end;
  finally
    FCS.Release;
    end;
  Result.Left:=cX;
  Result.Top:=cY;
  Result.Right:=cX+cW;
  Result.Bottom:=cY+cH;
  end;

procedure TRtcMouseCursorInfo.Lock;
  begin
  FCS.Acquire;
  end;

procedure TRtcMouseCursorInfo.UnLock;
  begin
  FCS.Release;
  end;

procedure TRtcMouseCursorInfo.ClearImageData;
  begin
  SetLength(FCursorImageData,0);
  end;

procedure TRtcMouseCursorInfo.ClearMaskData;
  begin
  SetLength(FCursorMaskData,0);
  end;

end.
