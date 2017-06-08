{
  "RTC Image Playback (FMX)"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcFImgPlayback;

interface

{$include rtcDefs.inc}

uses
  Classes,
  System.Types,
{$IFDEF IDE_XE5up}
  FMX.Graphics,
{$ENDIF}
  FMX.Types,

  rtcTypes,

  rtcXImgPlayback,

  rtcFBmpUtils;

type
  {$IFDEF IDE_XE2up}
  [ComponentPlatformsAttribute(pidAll)]
  {$ENDIF}
  TRtcImageFMXPlayback=class(TRtcImagePlayback)
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

constructor TRtcImageFMXPlayback.Create(AOwner: TComponent);
  begin
  inherited;
  FBmp:=nil;
  end;

procedure TRtcImageFMXPlayback.DoImageCreate;
  begin
  Image:=NewBitmapInfo(False);
  inherited;
  end;

procedure TRtcImageFMXPlayback.DoImageUpdate;
  begin
  CopyInfoToBitmap(Image, FBmp);
  inherited;
  end;

function RectF(Left, Top, Right, Bottom: Single): TRectF;
  begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Bottom := Bottom;
  Result.Right := Right;
  end;

procedure TRtcImageFMXPlayback.DoReceiveStop;
  begin
  inherited;
  RtcFreeAndNil(FBmp);
  end;

procedure TRtcImageFMXPlayback.DrawBitmap(Canvas: TCanvas);
  begin
  if assigned(Bitmap) then
    begin
    Canvas.DrawBitmap(Bitmap,RectF(0,0,Bitmap.Width, Bitmap.Height),
                             RectF(0,0,Bitmap.Width, Bitmap.Height),1,True);
    PaintCursor(Decoder.Cursor, Canvas, Bitmap, LastMouseX, LastMouseY, MouseControl);
    end;
  end;

end.
