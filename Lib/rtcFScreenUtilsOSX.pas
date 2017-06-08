{
  "MacOSX Screen Utils (FMX)"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcFScreenUtilsOSX;

interface

{$include rtcDefs.inc}

uses
{$IFDEF IDE_XE6up}
  // FMX.Graphics,
{$ENDIF}
  FMX.Types,
  FMX.Platform,

  rtcXBmpUtils,
  rtcXScreenUtils,

  Macapi.CoreFoundation,
  Macapi.CocoaTypes,
  Macapi.CoreGraphics,
  Macapi.ImageIO;

function GetScreenBitmapInfo:TRtcBitmapInfo;

function ScreenCapture(var Image: TRtcBitmapInfo; Forced:boolean):boolean;

implementation

type
  TMySize=record
    Width,
    Height:integer;
    end;

function GetScreenSize: TMySize;
  var
    ScreenService: IFMXScreenService;
  begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXScreenService, IInterface(ScreenService)) then
    begin
    with ScreenService.GetScreenSize.Round do
      begin
      Result.Width := X;
      Result.Height := Y;
      end;
    end
  else
    begin
    Result.Width := 0;
    Result.Height := 0;
    end;
  end;

function GetScreenBitmapInfo:TRtcBitmapInfo;
  begin
  FillChar(Result,SizeOf(Result),0);
  Result.Reverse:=False;
  Result.BuffType:=btRGBA32;
  Result.BytesPerPixel:=4;
  CompleteBitmapInfo(Result);
  end;

function ScreenCapture(var Image: TRtcBitmapInfo; Forced:boolean):boolean;
var
  Screenshot: CGImageRef;
  Img:CFDataRef;
  myPtr:pointer;
  myLen:integer;
  // srect:CGRect;
  scrsize:TMySize;
begin
  Result:=False;

  ScreenShot := CGDisplayCreateImage(CGMainDisplayID);

  scrsize:=GetScreenSize;
  {srect.origin.x:=0;
  srect.origin.y:=0;
  srect.size.width:=scrsize.Width;
  srect.size.height:=scrsize.Height;
  ScreenShot := CGWindowListCreateImage(srect,
    kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);}

  if ScreenShot = nil then Exit;

  try
    Img:=CGDataProviderCopyData(CGImageGetDataProvider(ScreenShot));
    if Img=nil then Exit;

    try
      myPtr := CFDataGetBytePtr(Img);
      if myPtr=nil then Exit;

      myLen := CFDataGetLength(Img);

      if not assigned(Image.Data) or
         (Image.Width<>scrsize.Width) or
         (Image.Height<>scrsize.Height) then
        ResizeBitmapInfo(Image,scrsize.Width,scrsize.Height,False);

      if myLen<=Image.Width*Image.Height*Image.BytesPerPixel then
        Move(myPtr^, Image.Data^, myLen)
      else
        Move(myPtr^, Image.Data^, Image.Width * Image.Height * Image.BytesPerPixel);

      Result:=True;
    finally
      CFRelease(Img);
      end;
  finally
    CGImageRelease(ScreenShot);
    end;
  end;

end.
