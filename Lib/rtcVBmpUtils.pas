{
  "RTC Bitmap Utils (VCL)"
  - Copyright 2013-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcVBmpUtils;

interface

{$INCLUDE rtcDefs.inc}

uses
  SysUtils,

  {$IFDEF IDE_XEUp}
    System.Types,
    VCL.Graphics,
  {$ELSE}
    Types,
    Graphics,
  {$ENDIF}

  rtcTypes,
  rtcInfo,

  rtcXJPEGConst,
  rtcXBmpUtils;

type
  TRtcVCLMouseCursorData=class
  protected
    FCursorImage: TBitmap;
    FCursorMask: TBitmap;

  public
    constructor Create;
    destructor Destroy; override;
    end;

function NewBitmapInfo(FromScreen:boolean):TRtcBitmapInfo;

// Make an in-memory Bitmap from a TBitmap (copies all info and image)
procedure CopyBitmapToInfo(const SrcBmp:TBitmap; var DstBmp:TRtcBitmapInfo);

// Copy in-memory bitmap to a TBitmap
procedure CopyInfoToBitmap(const SrcBmp:TRtcBitmapInfo; var DstBmp:TBitmap);

// procedure PaintCursor(Cursor:TRtcMouseCursorInfo; const BmpCanvas:TCanvas; NowMouseX, NowMouseY:integer; inControl:boolean);
procedure PaintCursor(Cursor:TRtcMouseCursorInfo; const BmpCanvas:TCanvas; const BmpOrig:TBitmap; NowMouseX, NowMouseY:integer; inControl:boolean);

implementation

function BitmapIsReverse(const Image: TBitmap): boolean;
  begin
  With Image do
    if Height < 2 then
      Result := False
    else
      Result := RtcIntPtr(ScanLine[0]) > RtcIntPtr(ScanLine[1]);
  end;

function BitmapBytesPerLine(const Image: TBitmap): integer;
  begin
  With Image do
    begin
    if RtcIntPtr(ScanLine[0])>RtcIntPtr(ScanLine[1]) then
      Result := RtcIntPtr(ScanLine[0])-RtcIntPtr(ScanLine[1])
    else
      Result := RtcIntPtr(ScanLine[1])-RtcIntPtr(ScanLine[0]);
    end;
  end;

function BitmapDataPtr(const Image: TBitmap): pointer;
  begin
  With Image do
    begin
    if Height < 2 then
      Result := ScanLine[0]
    else if RtcIntPtr(ScanLine[0]) < RtcIntPtr(ScanLine[1]) then
      Result := ScanLine[0]
    Else
      Result := ScanLine[Height - 1];
    End;
  end;

function BitmapDataStride(const Image: TBitmap): integer;
  begin
  Result:=RtcIntPtr(Image.ScanLine[1])-RtcIntPtr(Image.ScanLine[0]);
  end;

function GetBitmapInfo(const Bmp:TBitmap; toRead,toWrite,FromScreen:boolean):TRtcBitmapInfo;
  begin
  FillChar(Result,SizeOf(Result),0);
  Result.Data:=BitmapDataPtr(Bmp);
  Result.Width:=Bmp.Width;
  Result.Height:=Bmp.Height;
  Result.Reverse:=BitmapIsReverse(Bmp);
  Result.BytesPerLine:=BitmapBytesPerLine(Bmp);
  case Bmp.PixelFormat of
    pf24bit:
      begin
      Result.BuffType:=btBGR24;
      Result.BytesPerPixel:=3;
      end;
    pf32bit:
      begin
      Result.BuffType:=btBGRA32;
      Result.BytesPerPixel:=4;
      end;
    else
      begin
      Result.BytesPerPixel:=Result.BytesPerLine div Result.Width;
      case Result.BytesPerPixel of
        4: Result.BuffType:=btBGRA32;
        3: Result.BuffType:=btBGR24;
        else raise Exception.Create('Unsupported Bitmap Pixel Format');
        end;
      end;
    end;
  CompleteBitmapInfo(Result);
  end;

function NewBitmapInfo(FromScreen:boolean):TRtcBitmapInfo;
  var
    Bmp:TBitmap;
  begin
  FillChar(Result,SizeOf(Result),0);
  Bmp:=TBitmap.Create;
  try
    Bmp.PixelFormat:=pf32bit;
    Bmp.Width:=8;
    Bmp.Height:=8;
    Result.Reverse:=BitmapIsReverse(Bmp);
    Result.BuffType:=btBGRA32;
    Result.BytesPerPixel:=4;
  finally
    RtcFreeAndNil(Bmp);
    end;
  CompleteBitmapInfo(Result);
  end;

function MakeBitmapInfo(Bmp:TBitmap):TRtcBitmapInfo;
  begin
  FillChar(Result,SizeOf(Result),0);
  Result.Reverse:=BitmapIsReverse(Bmp);
  Result.BuffType:=btBGRA32;
  Result.BytesPerPixel:=4;
  CompleteBitmapInfo(Result);
  end;

procedure CopyInfoToBitmap(const SrcBmp:TRtcBitmapInfo; var DstBmp:TBitmap);
  var
    dstInfo:TRtcBitmapInfo;
    y,wid:integer;
    srcData,dstData:PByte;
  begin
  if not assigned(DstBmp) then
    begin
    DstBmp:=TBitmap.Create;
    DstBmp.PixelFormat:=pf32bit;
    end;
  DstBmp.Width:=SrcBmp.Width;
  DstBmp.Height:=SrcBmp.Height;
  if assigned(SrcBmp.Data) then
    begin
    DstInfo:=GetBitmapInfo(DstBmp,False,True,False);
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
    end
  else
    raise Exception.Create('SrcBmp = NIL!');
  end;

// Make an in-memory Bitmap from a TBitmap (copies all info and image)
procedure CopyBitmapToInfo(const SrcBmp:TBitmap; var DstBmp:TRtcBitmapInfo);
  var
    SrcInfo:TRtcBitmapInfo;
  begin
  SrcInfo:=GetBitmapInfo(SrcBmp,True,False,False);
  CopyBitmapInfo(SrcInfo,DstBmp);
  end;

{ TRtcVCLMouseCursorInfo }

constructor TRtcVCLMouseCursorData.Create;
  begin
  inherited;
  FCursorImage:=nil;
  FCursorMask:=nil;
  end;

destructor TRtcVCLMouseCursorData.Destroy;
  begin
  FreeAndNil(FCursorImage);
  FreeAndNil(FCursorMask);
  inherited;
  end;

(*
procedure PaintCursor(Cursor:TRtcMouseCursorInfo; const BmpCanvas:TCanvas; NowMouseX, NowMouseY:integer; inControl:boolean);
  var
    cX,cY:integer;
    ImgData:PColorBGR32;
    Y: integer;
    cur:TRtcVCLMouseCursorData;
  begin
  Cursor.Lock;
  try
    if Cursor.Data=nil then
      Cursor.Data:=TRtcVCLMouseCursorData.Create;
    cur:=TRtcVCLMouseCursorData(Cursor.Data);

    if (length(Cursor.ImageData)>0) or
       (length(Cursor.MaskData)>0) then
      begin
      if assigned(cur.FCursorImage) then
        FreeAndNil(cur.FCursorImage);
      if assigned(cur.FCursorMask) then
        FreeAndNil(cur.FCursorMask);
      if length(Cursor.ImageData)>0 then
        begin
        cur.FCursorImage := TBitmap.Create;
        cur.FCursorImage.PixelFormat:=pf32bit;
        cur.FCursorImage.Width:=Cursor.ImageW;
        cur.FCursorImage.Height:=Cursor.ImageH;
        ImgData:=PColorBGR32(Addr(Cursor.ImageData[0]));
        for Y := 0 to cur.FCursorImage.Height - 1 do
          begin
          Move(ImgData^, cur.FCursorImage.ScanLine[Y]^, cur.FCursorImage.Width*4);
          Inc(ImgData,cur.FCursorImage.Width);
          end;
        Cursor.ClearImageData;
        end;
      if length(Cursor.MaskData)>0 then
        begin
        cur.FCursorMask := TBitmap.Create;
        cur.FCursorMask.PixelFormat:=pf32bit;
        cur.FCursorMask.Width:=Cursor.MaskW;
        cur.FCursorMask.Height:=Cursor.MaskH;
        ImgData:=PColorBGR32(Addr(Cursor.MaskData[0]));
        for Y := 0 to cur.FCursorMask.Height - 1 do
          begin
          Move(ImgData^, cur.FCursorMask.ScanLine[Y]^, cur.FCursorMask.Width*4);
          Inc(ImgData,cur.FCursorMask.Width);
          end;
        Cursor.ClearMaskData;
        end;
      end;

    if Cursor.Visible and (assigned(cur.FCursorImage) or assigned(cur.FCursorMask)) then
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

      if assigned(cur.FCursorMask) then
        begin
        if assigned(cur.FCursorImage) and (cur.FCursorMask.Height = cur.FCursorImage.Height) then
          begin
          BmpCanvas.CopyMode:=cmSrcAnd;
          BmpCanvas.CopyRect(Rect(cX, cY, cX+cur.FCursorMask.Width, cY+cur.FCursorMask.Height),
                             cur.FCursorMask.Canvas,
                             Rect(0, 0, cur.FCursorMask.Width, cur.FCursorMask.Height));
          end
        else if cur.FCursorMask.Height > 1 then
          begin
          BmpCanvas.CopyMode:=cmSrcAnd;
          BmpCanvas.CopyRect(Rect(cX,cY, cX+cur.FCursorMask.Width, cY+cur.FCursorMask.Height div 2),
                             cur.FCursorMask.Canvas,
                             Rect(0,0, cur.FCursorMask.Width, cur.FCursorMask.Height div 2));

          BmpCanvas.CopyMode:=cmSrcInvert;
          BmpCanvas.CopyRect(Rect(cX,cY, cX+cur.FCursorMask.Width,cY+cur.FCursorMask.Height div 2),
                              cur.FCursorMask.Canvas,
                              Rect(0,cur.FCursorMask.Height div 2, cur.FCursorMask.Width, cur.FCursorMask.Height));
          end;
        end;
      if assigned(cur.FCursorImage) then
        begin
        BmpCanvas.CopyMode:=cmSrcPaint;
        BmpCanvas.CopyRect(Rect(cX, cY, cX+cur.FCursorImage.Width, cY+cur.FCursorImage.Height),
                           cur.FCursorImage.Canvas,
                           Rect(0, 0, cur.FCursorImage.Width, cur.FCursorImage.Height));
        end;
      BmpCanvas.CopyMode:=cmSrcCopy;
      end;
  finally
    Cursor.UnLock;
    end;
  end;
*)

procedure PaintCursor(Cursor:TRtcMouseCursorInfo; const BmpCanvas:TCanvas; const BmpOrig:TBitmap; NowMouseX, NowMouseY:integer; inControl:boolean);
  var
    cX,cY,cW,cH:integer;

    ImgData:PColorBGR32;
    FMXData,
    FMXOrig:TBitmap;
    Alpha:Double;

    cur:TRtcVCLMouseCursorData;

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
          SrcData:=FMXOrig.Scanline[Y+cY];
          Inc(SrcData,cX);
          DstData:=FMXData.Scanline[Y];
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
          DstData:=FMXData.Scanline[Y];
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
          DstData:=FMXData.Scanline[Y];
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
        DstData:=FMXData.Scanline[Y];
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
        DstData:=FMXData.Scanline[Y];
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
  FMXData:=nil;
  FMXOrig:=nil;
  Cursor.Lock;
  try
    if Cursor.Data=nil then
      Cursor.Data:=TRtcVCLMouseCursorData.Create;
    cur:=TRtcVCLMouseCursorData(Cursor.Data);

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
          begin
          cur.FCursorMask := TBitmap.Create;
          cur.FCursorMask.PixelFormat:=pf32bit;
          end;
        cur.FCursorMask.Width:=cW;
        cur.FCursorMask.Height:=cH;

        FMXData:=cur.FCursorMask;
        FMXOrig:=BmpOrig;
        try
          PaintMask_BGR;
        finally
          FMXData:=nil;
          FMXOrig:=nil;
          end;
        end
      else if length(Cursor.ImageData)>0 then
        begin
        if not assigned(cur.FCursorMask) then
          cur.FCursorMask := TBitmap.Create;
        cur.FCursorMask.Width:=Cursor.ImageW;
        cur.FCursorMask.Height:=Cursor.ImageH;

        FMXData:=cur.FCursorMask;
        try
          PaintImg_BGR;
        finally
          FMXData:=nil;
          end;
        end
      else
        FreeAndNil(cur.FCursorMask);

      if assigned(cur.FCursorMask) then
        BmpCanvas.Draw(cX,cY,cur.FCursorMask);
      end;
  finally
    Cursor.UnLock;
    end;
  end;

end.
