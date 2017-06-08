{
  "Screen Capture Link"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
}
unit rtcXScreenCapture;

interface

{$include rtcDefs.inc}

uses
  Classes,
  rtcTypes,
  rtcInfo,

  rtcXGateCIDs,

  rtcXImgEncode,

  rtcXScreenUtils,
{$IFDEF WINDOWS}
  rtcVScreenUtilsWin,
  rtcVWinStation,
{$ENDIF}
{$IFDEF MACOSX}
  rtcFScreenUtilsOSX,
{$ENDIF}

  rtcXImgCapture;

type
  { @Abstract(RTC Screen Capture Link)
    Link this component to a TRtcHttpGateClient to handle Screen Capture events. }
  {$IFDEF IDE_XE2up}
  [ComponentPlatformsAttribute(pidAll)]
  {$ENDIF}
  TRtcScreenCaptureLink = class(TRtcImageCaptureLink)
  private
    ParamsChanged1,
    ParamsChanged2,
    ParamsChanged3:boolean;

    //ParamsChanged1
    FMirrorDriver:boolean; // False

    //ParamsChanged2
    FWindowsAero:boolean; // True

    //ParamsChanged3
    FLayeredWindows:boolean; // True
    FAllMonitors:boolean; // False

    procedure SetMirrorDriver(const Value: boolean);
    procedure SetWindowsAero(const Value: boolean);
    procedure SetAllMonitors(const Value: boolean);
    procedure SetLayeredWindows(const Value: boolean);

  protected
    function CreateImageEncoder:TRtcImageEncoder; override;

    procedure ResetParamsChanged; override;
    procedure UpdateChangedParams; override;

    function CaptureMouseInitial:RtcByteArray; override;
    function CaptureMouseDelta:RtcByteArray; override;

    function CaptureImage:boolean; override;
    procedure CaptureImageFailCheck; override;

    procedure MouseControlExecute(Data:TRtcValue); override;

  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

  published
    property CaptureMirrorDriver:boolean read FMirrorDriver write SetMirrorDriver default False;
    property CaptureWindowsAero:boolean read FWindowsAero write SetWindowsAero default True;
    property CaptureLayeredWindows:boolean read FLayeredWindows write SetLayeredWindows default True;
    property CaptureAllMonitors:boolean read FAllMonitors write SetAllMonitors default False;
    end;

implementation

{ TRtcScreenCaptureLink }

constructor TRtcScreenCaptureLink.Create(AOwner: TComponent);
  begin
  inherited;
  FMirrorDriver:=False;
  FWindowsAero:=True;
  FLayeredWindows:=True;
  FAllMonitors:=False;
  end;

destructor TRtcScreenCaptureLink.Destroy;
  begin
  inherited;
{$IFDEF WINDOWS}
  if CurrentMirrorDriver then
    DisableMirrorDriver;
  if not CurrentAero then
    EnableAero;
{$ENDIF}
  end;

procedure TRtcScreenCaptureLink.SetMirrorDriver(const Value: boolean);
  begin
  FMirrorDriver := Value;
  ParamsChanged1 := True;
  end;

procedure TRtcScreenCaptureLink.SetWindowsAero(const Value: boolean);
  begin
  FWindowsAero := Value;
  ParamsChanged2 := True;
  end;

procedure TRtcScreenCaptureLink.SetAllMonitors(const Value: boolean);
  begin
  FAllMonitors := Value;
  ParamsChanged3:=True;
  end;

procedure TRtcScreenCaptureLink.SetLayeredWindows(const Value: boolean);
  begin
  FLayeredWindows := Value;
  ParamsChanged3:=True;
  end;

function TRtcScreenCaptureLink.CreateImageEncoder: TRtcImageEncoder;
  begin
{$IFDEF WINDOWS}
  Result:=TRtcImageEncoder.Create(GetScreenBitmapInfo);
{$ELSE}
  {$IFDEF MACOSX}
    Result:=TRtcImageEncoder.Create(GetScreenBitmapInfo);
  {$ELSE}
    {$Message Warn 'CreateImageEncoder: Unknown Bitmap Format'}
  {$ENDIF}
{$ENDIF}
  end;

procedure TRtcScreenCaptureLink.ResetParamsChanged;
  begin
  inherited;

  ParamsChanged1:=True;
  ParamsChanged2:=True;
  ParamsChanged3:=True;
  end;

procedure TRtcScreenCaptureLink.UpdateChangedParams;
  begin
  inherited;

{$IFDEF WINDOWS}
  if ParamsChanged1 then
    begin
    ParamsChanged1:=False;
    if CurrentMirrorDriver<>FMirrorDriver then
      begin
      if FMirrorDriver then
        EnableMirrorDriver
      else
        DisableMirrorDriver;
      end;
    end;

  if ParamsChanged2 then
    begin
    ParamsChanged2:=False;
    if CurrentAero<>FWindowsAero then
      begin
      if FWindowsAero then
        EnableAero
      else
        DisableAero;
      end;
    end;
{$ENDIF}

  if ParamsChanged3 then
    begin
    ParamsChanged3:=False;
    RtcCaptureSettings.CompleteBitmap:=True;
    RtcCaptureSettings.LayeredWindows:=FLayeredWindows;
    RtcCaptureSettings.AllMonitors:=FAllMonitors;
    end;
  end;

function TRtcScreenCaptureLink.CaptureMouseInitial: RtcByteArray;
  begin
{$IFDEF WINDOWS}
  MouseSetup;
  GrabMouse;
  Result:=CaptureMouseCursor;
{$ELSE}
  Result:=nil;
{$ENDIF}
  end;

function TRtcScreenCaptureLink.CaptureMouseDelta: RtcByteArray;
  begin
{$IFDEF WINDOWS}
  GrabMouse;
  Result:=CaptureMouseCursorDelta;
{$ELSE}
  Result:=nil;
{$ENDIF}
  end;

function TRtcScreenCaptureLink.CaptureImage: boolean;
  begin
{$IFDEF WINDOWS}
  Result:=ScreenCapture(ImgEncoder.OldBmpInfo,ImgEncoder.NeedRefresh);
{$ELSE}
  {$IFDEF MACOSX}
    Result:=ScreenCapture(ImgEncoder.OldBmpInfo,ImgEncoder.NeedRefresh);
  {$ELSE}
    Result:=False;
  {$ENDIF}
{$ENDIF}
  end;

procedure TRtcScreenCaptureLink.CaptureImageFailCheck;
  begin
  inherited;
{$IFDEF WINDOWS}
  SwitchToActiveDesktop(true);
{$ENDIF}
  end;

procedure TRtcScreenCaptureLink.MouseControlExecute(Data: TRtcValue);
  begin
  inherited;

{$IFDEF WINDOWS}
  case Data.asRecord.asInteger['C'] of
    cid_ControlMouseDown:
      Control_MouseDown(Data.asRecord.asCardinal['A'],
                        Data.asRecord.asInteger['X'],
                        Data.asRecord.asInteger['Y'],
                        TMouse_Button(Data.asRecord.asInteger['B']));

    cid_ControlMouseMove:
      Control_MouseMove(Data.asRecord.asCardinal['A'],
                        Data.asRecord.asInteger['X'],
                        Data.asRecord.asInteger['Y']);

    cid_ControlMouseUp:
      Control_MouseUp(Data.asRecord.asCardinal['A'],
                      Data.asRecord.asInteger['X'],
                      Data.asRecord.asInteger['Y'],
                      TMouse_Button(Data.asRecord.asInteger['B']));

    cid_ControlMouseWheel:
      Control_MouseWheel(Data.asRecord.asInteger['W']);

    cid_ControlKeyDown:
      Control_KeyDown(Data.asRecord.asInteger['K']);

    cid_ControlKeyUp:
      Control_KeyUp(Data.asRecord.asInteger['K']);
    end;
{$ENDIF}
  end;

end.
