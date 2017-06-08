{
  "RTC Bitmap Utils (FMX)"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcFBmpUtils;

interface

{$INCLUDE rtcDefs.inc}

uses
  SysUtils,

  System.Types,
{$IFDEF IDE_XE5up}
  FMX.Graphics,
{$ENDIF}
{$IFNDEF IDE_XE6up}
  FMX.PixelFormats,
{$ENDIF}
  FMX.Types,

  rtcTypes,

  rtcXJPEGConst,
  rtcXBmpUtils;

type
  TRtcFMXMouseCursorData=class
  public
    FCursorMask: TBitmap;

    constructor Create;
    destructor Destroy; override;
    end;

function NewBitmapInfo(FromScreen:boolean):TRtcBitmapInfo;

// Make an in-memory Bitmap from a TBitmap (copies all info and image)
procedure CopyBitmapToInfo(const SrcBmp:TBitmap; var DstBmp:TRtcBitmapInfo);

// Copy in-memory bitmap to a TBitmap
procedure CopyInfoToBitmap(const SrcBmp:TRtcBitmapInfo; var DstBmp:TBitmap);

procedure PaintCursor(Cursor:TRtcMouseCursorInfo; const BmpCanvas:TCanvas; const BmpOrig:TBitmap; NowMouseX, NowMouseY:integer; inControl:boolean);

implementation

function BitmapIsReverse(const Image: TBitmap;var Data:TBitmapData): boolean;
  begin
  With Image do
    if Height < 2 then
      Result := False
    else
      begin
      if not assigned(Data.Data) then
        if not Map(TMapAccess.maReadWrite,data) then
          raise Exception.Create('Can not access Bitmap data');
      Result := RtcIntPtr(data.GetScanline(0))>RtcIntPtr(data.GetScanline(1));
      end;
  end;

function BitmapBytesPerLine(const Image: TBitmap;var Data:TBitmapData): integer;
  begin
  With Image do
    begin
    if not assigned(Data.Data) then
      if not Map(TMapAccess.maReadWrite,data) then
        raise Exception.Create('Can not access Bitmap data');
    Result:=data.Pitch;
    end;
  end;

function BitmapDataPtr(const Image: TBitmap; accMode:TMapAccess; var data:TBitmapData): pointer;
  begin
  With Image do
    begin
    if not assigned(Data.Data) then
      if not Map(accMode,data) then
        raise Exception.Create('Can not access Bitmap data');
    if Height < 2 then
      Result := data.GetScanline(0)
    else if RtcIntPtr(data.GetScanLine(0)) < RtcIntPtr(data.GetScanLine(1)) then
      Result := data.GetScanLine(0)
    Else
      Result := data.GetScanline(data.Height - 1);
    End;
  end;

function BitmapDataStride(const Image: TBitmap; var data:TBitmapData): integer;
  begin
  if not assigned(Data.Data) then
    if not Image.Map(TMapAccess.maReadWrite,data) then
      raise Exception.Create('Can not access Bitmap data');
  Result:=RtcIntPtr(data.GetScanline(1))-RtcIntPtr(data.GetScanline(0));
  end;

function GetBitmapInfo(const Bmp:TBitmap; toRead,toWrite,FromScreen:boolean; var FMXData:TBitmapData):TRtcBitmapInfo;
  begin
  FillChar(Result,SizeOf(Result),0);
  FillChar(FMXData,SizeOf(FMXData),0);
  if toWrite then
    begin
    if toRead then
      Result.Data:=BitmapDataPtr(Bmp,TMapAccess.maReadWrite, FMXData)
    else
      Result.Data:=BitmapDataPtr(Bmp,TMapAccess.maWrite, FMXData);
    end
  else
    Result.Data:=BitmapDataPtr(Bmp,TMapAccess.maRead, FMXData);
  Result.Width:=Bmp.Width;
  Result.Height:=Bmp.Height;
  Result.Reverse:=BitmapIsReverse(Bmp,FMXData);
  Result.BytesPerLine:=BitmapBytesPerLine(Bmp,FMXData);
  case Bmp.PixelFormat of
  {$IFDEF IDE_XE6up}
    TPixelFormat.BGR,
    TPixelFormat.BGRA:
      {$IFDEF MACOSX}
      if FromScreen then
        Result.BuffType:=btRGBA32
      else {$ENDIF}
        Result.BuffType:=btBGRA32;
    TPixelFormat.RGB,
    TPixelFormat.RGBA:
      {$IFDEF MACOSX}
      if FromScreen then
        Result.BuffType:=btBGRA32
      else {$ENDIF}
        Result.BuffType:=btRGBA32;
  {$ELSE}
    pfA8R8G8B8:
      {$IFDEF MACOSX}
      if FromScreen then
        Result.BuffType:=btRGBA32
      else {$ENDIF}
        Result.BuffType:=btBGRA32;
    pfA8B8G8R8:
      {$IFDEF MACOSX}
      if FromScreen then
        Result.BuffType:=btBGRA32
      else {$ENDIF}
        Result.BuffType:=btRGBA32;
  {$ENDIF}
    else raise Exception.Create('Unsupported Bitmap Pixel Format');
    end;
  Result.BytesPerPixel:=4;
  CompleteBitmapInfo(Result);
  end;

procedure PutBitmapInfo(const Bmp:TBitmap; var BmpInfo:TRtcBitmapInfo;var FMXData:TBitmapData);
  begin
  if assigned(FMXData.Data) then
    begin
    Bmp.Unmap(FMXData);
    FMXData.Data:=nil;
    end;
  end;

// Make an in-memory Bitmap from a TBitmap (copies all info and image)
procedure CopyBitmapToInfo(const SrcBmp:TBitmap; var DstBmp:TRtcBitmapInfo);
  var
    FMXData:TBitmapData;
    SrcInfo:TRtcBitmapInfo;
  begin
  SrcInfo:=GetBitmapInfo(SrcBmp,True,False,False,FMXData);
  try
    CopyBitmapInfo(SrcInfo,DstBmp);
  finally
    PutBitmapInfo(SrcBmp,SrcInfo,FMXData);
    end;
  end;

function MakeBitmapInfo(Bmp:TBitmap):TRtcBitmapInfo;
  var
    FMXData:TBitmapData;
  begin
  FillChar(Result,SizeOf(Result),0);
  FillChar(FMXData,SizeOf(FMXData),0);

    Result.Reverse:=BitmapIsReverse(Bmp,FMXData);
    case Bmp.PixelFormat of
    {$IFDEF IDE_XE6up}
      TPixelFormat.BGR,
      TPixelFormat.BGRA:
          Result.BuffType:=btBGRA32;
      TPixelFormat.RGB,
      TPixelFormat.RGBA:
          Result.BuffType:=btRGBA32;
    {$ELSE}
      pfA8R8G8B8:
          Result.BuffType:=btBGRA32;
      pfA8B8G8R8:
          Result.BuffType:=btRGBA32;
    {$ENDIF}
      else raise Exception.Create('Unsupported Bitmap Pixel Format');
      end;
    Result.BytesPerPixel:=4;
    if assigned(FMXData.Data) then
      begin
      Bmp.Unmap(FMXData);
      FMXData.Data:=nil;
      end;

  CompleteBitmapInfo(Result);
  end;

function NewBitmapInfo(FromScreen:boolean):TRtcBitmapInfo;
  var
    Bmp:TBitmap;
    FMXData:TBitmapData;
  begin
  FillChar(Result,SizeOf(Result),0);
  FillChar(FMXData,SizeOf(FMXData),0);

{$IFDEF IDE_XE6up}
  Bmp:=TBitmap.Create;
{$ELSE}
  Bmp:=TBitmap.Create(8,8);
{$ENDIF}
  try
    Bmp.Width:=8;
    Bmp.Height:=8;

    Result.Reverse:=BitmapIsReverse(Bmp,FMXData);
    case Bmp.PixelFormat of
    {$IFDEF IDE_XE6up}
      TPixelFormat.BGR,
      TPixelFormat.BGRA:
      {$IFDEF MACOSX}
        if FromScreen then
          Result.BuffType:=btRGBA32
        else
      {$ENDIF}
          Result.BuffType:=btBGRA32;
      TPixelFormat.RGB,
      TPixelFormat.RGBA:
      {$IFDEF MACOSX}
        if FromScreen then
          Result.BuffType:=btBGRA32
        else
      {$ENDIF}
          Result.BuffType:=btRGBA32;
    {$ELSE}
      pfA8R8G8B8:
      {$IFDEF MACOSX}
        if FromScreen then
          Result.BuffType:=btRGBA32
        else
      {$ENDIF}
          Result.BuffType:=btBGRA32;
      pfA8B8G8R8:
      {$IFDEF MACOSX}
        if FromScreen then
          Result.BuffType:=btBGRA32
        else
      {$ENDIF}
          Result.BuffType:=btRGBA32;
    {$ENDIF}
      else raise Exception.Create('Unsupported Bitmap Pixel Format');
      end;
    Result.BytesPerPixel:=4;
    if assigned(FMXData.Data) then
      begin
      Bmp.Unmap(FMXData);
      FMXData.Data:=nil;
      end;
  finally
    RtcFreeAndNil(Bmp);
    end;
  CompleteBitmapInfo(Result);
  end;

procedure CopyInfoToBitmap(const SrcBmp:TRtcBitmapInfo; var DstBmp:TBitmap);
  var
    dstInfo:TRtcBitmapInfo;
    FMXData:TBitmapData;
    y,wid:integer;
    srcData,dstData:PByte;
  begin
  FillChar(FMXData,SizeOf(FMXData),0);
  if not assigned(DstBmp) then
  {$IFDEF IDE_XE6up}
    DstBmp:=TBitmap.Create;
  {$ELSE}
    DstBmp:=TBitmap.Create(SrcBmp.Width,SrcBmp.Height);
  {$ENDIF}
  if (DstBmp.Width<>SrcBmp.Width) or
     (DstBmp.Height<>SrcBmp.Height) then
    DstBmp.SetSize(SrcBmp.Width,SrcBmp.Height);
  if assigned(SrcBmp.Data) then
    begin
    DstInfo:=GetBitmapInfo(DstBmp,False,True,False,FMXData);
    try
      if assigned(dstInfo.Data) then
        begin
        if SrcBmp.BytesTotal>0 then
          begin
          if SrcBmp.BytesTotal = dstInfo.BytesTotal then
            Move(SrcBmp.Data^,DstInfo.Data^,SrcBmp.BytesTotal)
          else if (SrcBmp.Width=DstBmp.Width) and (SrcBmp.Height=DstBmp.Height) then
            begin
            wid:=srcBmp.Width*SrcBmp.BytesPerPixel;
            srcData:=PByte(srcBmp.TopData);
            dstData:=PByte(dstInfo.TopData);
            for Y := 0 to SrcBmp.Height-1 do
              begin
              Move(srcData^,dstData^,wid);
              Inc(srcData,SrcBmp.NextLine);
              Inc(dstData,dstInfo.NextLine);
              end;
            end
          else
            raise Exception.Create('DstBmp? '+IntToStr(dstInfo.BytesTotal)+'<>'+IntToStr(SrcBmp.BytesTotal));
          end
        else
          raise Exception.Create('SrcBmp = 0?');
        end
      else
        raise Exception.Create('DstBmp = NIL!');
    finally
      PutBitmapInfo(DstBmp,DStInfo,FMXData);
      end;
    end
  else
    raise Exception.Create('SrcBmp = NIL!');
  end;

{ TRtcVCLMouseCursorInfo }

constructor TRtcFMXMouseCursorData.Create;
  begin
  inherited;
  FCursorMask:=nil;
  end;

destructor TRtcFMXMouseCursorData.Destroy;
  begin
  FreeAndNil(FCursorMask);
  inherited;
  end;

function RectF(x1,y1,x2,y2:integer):TRectF;
  begin
  Result.Left:=x1+0.5;
  Result.Top:=y1+0.5;
  Result.Right:=x2-0.5;
  Result.Bottom:=y2-0.5;
  end;

procedure PaintCursor(Cursor:TRtcMouseCursorInfo; const BmpCanvas:TCanvas; const BmpOrig:TBitmap; NowMouseX, NowMouseY:integer; inControl:boolean);
  var
    cX,cY,cW,cH:integer;

    ImgData:PColorBGR32;
    FMXData,
    FMXOrig:TBitmapData;
    Alpha:Double;

    cur:TRtcFMXMouseCursorData;

  procedure PaintMask_RGB;
    var
      SrcData,DstData:PColorRGB32;
      X,Y: integer;
    begin
    if (length(Cursor.MaskData)>0) then
      begin
      ImgData:=PColorBGR32(Addr(Cursor.MaskData[0]));
      // Apply "AND" mask
      for Y := 0 to cH - 1 do
        begin
        if ((Y+cY)>=0) and ((Y+cY)<FMXOrig.Height) then
          begin
          SrcData:=FMXOrig.GetScanline(Y+cY);
          Inc(SrcData,cX);
          DstData:=FMXData.GetScanline(Y);
          for X := 0 to cW-1 do
            begin
            if ((X+cX)>=0) and ((X+cX)<FMXOrig.Width) then
              begin
              DstData^.R:=SrcData^.R and ImgData^.R;
              DstData^.G:=SrcData^.G and ImgData^.G;
              DstData^.B:=SrcData^.B and ImgData^.B;
              DstData^.A:=255;
              end
            else
              begin
              DstData^.R:=0;
              DstData^.G:=0;
              DstData^.B:=0;
              DstData^.A:=0;
              end;
            Inc(DstData);
            Inc(SrcData);
            Inc(ImgData);
            end;
          end
        else
          begin
          DstData:=FMXData.GetScanline(Y);
          for X := 0 to cW-1 do
            begin
            DstData^.R:=0;
            DstData^.G:=0;
            DstData^.B:=0;
            DstData^.A:=0;
            Inc(DstData);
            Inc(ImgData);
            end;
          end;
        end;
      // Apply "INVERT" Mask
      if cH<Cursor.MaskH then
        for Y := 0 to cH - 1 do
          begin
          DstData:=FMXData.GetScanline(Y);
          for X := 0 to cW-1 do
            begin
            if DstData^.A>0 then
              begin
              DstData^.R:=DstData^.R xor ImgData^.R;
              DstData^.G:=DstData^.G xor ImgData^.G;
              DstData^.B:=DstData^.B xor ImgData^.B;
              end;
            Inc(DstData);
            Inc(ImgData);
            end;
          end;
      end;
    // Paint NORMAL image with Alpha
    if (length(Cursor.ImageData)>0) and (length(Cursor.ImageData)=cH*cW*4) then
      begin
      ImgData:=PColorBGR32(Addr(Cursor.ImageData[0]));
      for Y := 0 to cH - 1 do
        begin
        DstData:=FMXData.GetScanline(Y);
        for X := 0 to cW-1 do
          begin
          if (DstData^.A>0) and (ImgData^.A>0) then
            begin
            Alpha:=ImgData^.A/255;
            DstData^.R:=trunc((DstData^.R*(1-Alpha)) + (ImgData^.R*Alpha));
            DstData^.G:=trunc((DstData^.G*(1-Alpha)) + (ImgData^.G*Alpha));
            DstData^.B:=trunc((DstData^.B*(1-Alpha)) + (ImgData^.B*Alpha));
            end;
          Inc(DstData);
          Inc(ImgData);
          end;
        end;
      end;
    end;
  procedure PaintImg_RGB;
    var
      DstData:PColorRGB32;
      X,Y: integer;
    begin
    // Paint NORMAL image with Alpha
    if (length(Cursor.ImageData)>0) and (length(Cursor.ImageData)=cH*cW*4) then
      begin
      ImgData:=PColorBGR32(Addr(Cursor.ImageData[0]));
      for Y := 0 to cH - 1 do
        begin
        DstData:=FMXData.GetScanline(Y);
        for X := 0 to cW-1 do
          begin
          DstData^.R:=ImgData^.R;
          DstData^.G:=ImgData^.G;
          DstData^.B:=ImgData^.B;
          DstData^.A:=ImgData^.A;
          Inc(DstData);
          Inc(ImgData);
          end;
        end;
      end;
    end;

  procedure PaintMask_BGR;
    var
      SrcData,DstData:PColorBGR32;
      X,Y: integer;
    begin
    if (length(Cursor.MaskData)>0) then
      begin
      ImgData:=PColorBGR32(Addr(Cursor.MaskData[0]));
      // Apply "AND" mask
      for Y := 0 to cH - 1 do
        begin
        if ((Y+cY)>=0) and ((Y+cY)<FMXOrig.Height) then
          begin
          SrcData:=FMXOrig.GetScanline(Y+cY);
          Inc(SrcData,cX);
          DstData:=FMXData.GetScanline(Y);
          for X := 0 to cW-1 do
            begin
            if ((X+cX)>=0) and ((X+cX)<FMXOrig.Width) then
              begin
              DstData^.R:=SrcData^.R and ImgData^.R;
              DstData^.G:=SrcData^.G and ImgData^.G;
              DstData^.B:=SrcData^.B and ImgData^.B;
              DstData^.A:=255;
              end
            else
              begin
              DstData^.R:=0;
              DstData^.G:=0;
              DstData^.B:=0;
              DstData^.A:=0;
              end;
            Inc(DstData);
            Inc(SrcData);
            Inc(ImgData);
            end;
          end
        else
          begin
          DstData:=FMXData.GetScanline(Y);
          for X := 0 to cW-1 do
            begin
            DstData^.R:=0;
            DstData^.G:=0;
            DstData^.B:=0;
            DstData^.A:=0;
            Inc(DstData);
            Inc(ImgData);
            end;
          end;
        end;
      // Apply "INVERT" Mask
      if cH<Cursor.MaskH then
        for Y := 0 to cH - 1 do
          begin
          DstData:=FMXData.GetScanline(Y);
          for X := 0 to cW-1 do
            begin
            if DstData^.A>0 then
              begin
              DstData^.R:=DstData^.R xor ImgData^.R;
              DstData^.G:=DstData^.G xor ImgData^.G;
              DstData^.B:=DstData^.B xor ImgData^.B;
              end;
            Inc(DstData);
            Inc(ImgData);
            end;
          end;
      end;
    // Paint NORMAL image with Alpha
    if (length(Cursor.ImageData)>0) and (length(Cursor.ImageData)=cH*cW*4) then
      begin
      ImgData:=PColorBGR32(Addr(Cursor.ImageData[0]));
      for Y := 0 to cH - 1 do
        begin
        DstData:=FMXData.GetScanline(Y);
        for X := 0 to cW-1 do
          begin
          if (DstData^.A>0) and (ImgData^.A>0) then
            begin
            Alpha:=ImgData^.A/255;
            DstData^.R:=trunc((DstData^.R*(1-Alpha)) + (ImgData^.R*Alpha));
            DstData^.G:=trunc((DstData^.G*(1-Alpha)) + (ImgData^.G*Alpha));
            DstData^.B:=trunc((DstData^.B*(1-Alpha)) + (ImgData^.B*Alpha));
            end;
          Inc(DstData);
          Inc(ImgData);
          end;
        end;
      end;
    end;
  procedure PaintImg_BGR;
    var
      DstData:PColorBGR32;
      X,Y: integer;
    begin
    // Paint NORMAL image with Alpha
    if (length(Cursor.ImageData)>0) and (length(Cursor.ImageData)=cH*cW*4) then
      begin
      ImgData:=PColorBGR32(Addr(Cursor.ImageData[0]));
      for Y := 0 to cH - 1 do
        begin
        DstData:=FMXData.GetScanline(Y);
        for X := 0 to cW-1 do
          begin
          DstData^.R:=ImgData^.R;
          DstData^.G:=ImgData^.G;
          DstData^.B:=ImgData^.B;
          DstData^.A:=ImgData^.A;
          Inc(DstData);
          Inc(ImgData);
          end;
        end;
      end;
    end;

  begin
  FillChar(FMXData,SizeOf(FMXData),0);
  FillChar(FMXOrig,SizeOf(FMXOrig),0);
  Cursor.Lock;
  try
    if Cursor.Data=nil then
      Cursor.Data:=TRtcFMXMouseCursorData.Create;
    cur:=TRtcFMXMouseCursorData(Cursor.Data);

    if Cursor.Visible and ( (length(Cursor.ImageData)>0) or (length(Cursor.MaskData)>0) ) then
      begin
      if inControl then
        begin
        cX:=NowMouseX-Cursor.HotX;
        cY:=NowMouseY-Cursor.HotY;
        end
      else
        begin
        cX:=Cursor.X-Cursor.HotX;
        cY:=Cursor.Y-Cursor.HotY;
        end;

      cW:=Cursor.ImageW;
      cH:=Cursor.ImageH;

      if (length(Cursor.MaskData)>0) and (length(Cursor.MaskData)=Cursor.MaskW*Cursor.MaskH*4) then
        begin
        if (length(Cursor.ImageData)>0) and (Cursor.MaskH = Cursor.ImageH) then
          begin
          cW:=Cursor.MaskW;
          cH:=Cursor.MaskH;
          end
        else if Cursor.MaskH > 1 then
          begin
          cW:=Cursor.MaskW;
          cH:=Cursor.MaskH div 2;
          end;

        if not assigned(cur.FCursorMask) then
        {$IFDEF IDE_XE6up}
          cur.FCursorMask := TBitmap.Create;
        {$ELSE}
          cur.FCursorMask := TBitmap.Create(cW,cH);
        {$ENDIF}
        cur.FCursorMask.Width:=cW;
        cur.FCursorMask.Height:=cH;

      {$IFDEF IDE_XE6up}
        if cur.FCursorMask.Map(TMapAccess.Write,FMXData) then
          try
            if BmpOrig.Map(TMapAccess.Read,FMXOrig) then
              try
                if BmpOrig.PixelFormat=TPixelFormat.RGBA then
      {$ELSE}
        if cur.FCursorMask.Map(TMapAccess.maWrite,FMXData) then
          try
            if BmpOrig.Map(TMapAccess.maRead,FMXOrig) then
              try
                if BmpOrig.PixelFormat=pfA8B8G8R8 then
      {$ENDIF}
                  PaintMask_RGB
                else
                  PaintMask_BGR;
              finally
                BmpOrig.Unmap(FMXOrig);
                end;
          finally
            cur.FCursorMask.Unmap(FMXData);
            end;
        end
      else if length(Cursor.ImageData)>0 then
        begin
        if not assigned(cur.FCursorMask) then
        {$IFDEF IDE_XE6up}
          cur.FCursorMask := TBitmap.Create;
        {$ELSE}
          cur.FCursorMask := TBitmap.Create(Cursor.ImageW,Cursor.ImageH);
        {$ENDIF}
        cur.FCursorMask.Width:=Cursor.ImageW;
        cur.FCursorMask.Height:=Cursor.ImageH;

        {$IFDEF IDE_XE6up}
        if cur.FCursorMask.Map(TMapAccess.Write,FMXData) then
          try
            if BmpOrig.PixelFormat=TPixelFormat.RGBA then
        {$ELSE}
        if cur.FCursorMask.Map(TMapAccess.maWrite,FMXData) then
          try
            if BmpOrig.PixelFormat=pfA8B8G8R8 then
        {$ENDIF}
              PaintImg_RGB
            else
              PaintImg_BGR;
          finally
            cur.FCursorMask.Unmap(FMXData);
            end;
        end
      else
        FreeAndNil(cur.FCursorMask);

      if assigned(cur.FCursorMask) then
        begin
        BmpCanvas.DrawBitmap(cur.FCursorMask,
                             RectF(0, 0, cur.FCursorMask.Width, cur.FCursorMask.Height),
                             RectF(cX, cY, cX+cur.FCursorMask.Width, cY+cur.FCursorMask.Height),
                             1,True);
        end;
      end;
  finally
    Cursor.UnLock;
    end;
  end;

end.
