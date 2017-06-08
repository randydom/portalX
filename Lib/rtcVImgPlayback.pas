{
  "RTC Image Playback (VCL)"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcVImgPlayback;

interface

{$include rtcDefs.inc}

uses
  Classes,

{$IFDEF IDE_XEup}
  System.Types,
  VCL.Graphics,
{$ELSE}
  Types,
  Graphics,
{$ENDIF}

  rtcTypes,

  rtcVBmpUtils,

  rtcXImgPlayback;

type
  {$IFDEF IDE_XE2up}
  [ComponentPlatformsAttribute(pidAll)]
  {$ENDIF}
  TRtcImageVCLPlayback=class(TRtcImagePlayback)
  private
    FBmp:TBitmap;

  protected
    procedure DoImageCreate; override;
    procedure DoImageUpdate; override;

    procedure DoReceiveStop; override;

  public
    constructor Create(AOwner:TComponent); override;

    procedure DrawBitmap(Canvas:TCanvas);

    property Bitmap:TBitmap read FBmp;
  end;

implementation

{ TRtcImagePlaybackFMX }

constructor TRtcImageVCLPlayback.Create(AOwner: TComponent);
  begin
  inherited;
  FBmp:=nil;
  end;

procedure TRtcImageVCLPlayback.DoImageCreate;
  begin
  Image:=NewBitmapInfo(False);
  inherited;
  end;

procedure TRtcImageVCLPlayback.DoImageUpdate;
  begin
  CopyInfoToBitmap(Image, FBmp);
  inherited;
  end;

procedure TRtcImageVCLPlayback.DoReceiveStop;
  begin
  inherited;
  RtcFreeAndNil(FBmp);
  end;

procedure TRtcImageVCLPlayback.DrawBitmap(Canvas: TCanvas);
  begin
  if assigned(Bitmap) then
    begin
    Canvas.Draw(0,0,Bitmap);
    PaintCursor(Decoder.Cursor, Canvas, Bitmap, LastMouseX, LastMouseY, MouseControl);
    end;
  end;

end.
