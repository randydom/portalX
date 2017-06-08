{
  "Windows Video Mirror Driver support (VCL)"
  - Copyright 2007-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}

unit rtcVMirrorDriver;

(* ** This unit acts like and "interface" between
  RTC Host and the DemoForge Mirage Video Driver ** *)

{$INCLUDE rtcDefs.inc}

interface

uses
  Windows, Classes,
  Registry, SysUtils,

  rtcXScreenUtils;

const
  MAX_SCREEN_WIDTH = 16384;
  MAX_SCREEN_HEIGHT = 8192;

  // Mirage driver for TightVNC feature this description String:
  VideoDriverString = 'Mirage Driver';
  VideoDriverName = 'dfmirage';
  VideoDriverRegKeyRoot =
    'SYSTEM\CurrentControlSet\Hardware Profiles\Current\System\CurrentControlSet\Services\';

  ESC_QVI_PROD_MIRAGE = 'MIRAGE';
  ESC_QVI_PROD_QUASAR = 'QUASAR';

  // Driver escapes
  MAP1 = 1030;
  UNMAP1 = 1031;
  TEST_DRIVER = 1050;
  TEST_MAPPED = 1051;
  QRY_VERINFO = 1026;

  // Misc
  MAXCHANGES_BUF = 20000;
  CLIP_LIMIT = 50;
  esc_qvi_prod_name_max = 16;
  DMF_PROTO_VER_CURRENT = $01020000;
  DMF_PROTO_VER_MINCOMPAT = $00090001;

  dmf_dfo_SCREEN_SCREEN = 11;
  dmf_dfo_BLIT = 12;
  dmf_dfo_SOLIDFILL = 13;
  dmf_dfo_BLEND = 14;
  dmf_dfo_TRANS = 15;
  dmf_dfo_PLG = 17;
  dmf_dfo_TEXTOUT = 18;

  dmf_dfo_Ptr_Engage = 48; // point is used with this record
  dmf_dfo_Ptr_Avert = 49;

  // Bitmap formats
  BMF_1BPP = 1;
  BMF_4BPP = 2;
  BMF_8BPP = 3;
  BMF_16BPP = 4;
  BMF_24BPP = 5;
  BMF_32BPP = 6;
  BMF_4RLE = 7;
  BMF_8RLE = 8;
  BMF_JPEG = 9;
  BMF_PNG = 10;

  // ChangeDisplaySettingsEx flags
  CDS_UPDATEREGISTRY = $00000001;
  CDS_TEST = $00000002;
  CDS_FULLSCREEN = $00000004;
  CDS_GLOBAL = $00000008;
  CDS_SET_PRIMARY = $00000010;
  CDS_RESET = $40000000;
  CDS_SETRECT = $20000000;
  CDS_NORESET = $10000000;

  // From WinUser.h
  ENUM_CURRENT_SETTINGS = cardinal(-1);
  ENUM_REGISTRY_SETTINGS = cardinal(-2);

type

  EMirrorDriver = class(Exception);

  // *********************************************************************
  // DONT TOUCH STRUCTURES/ SHOULD BE EXACTLY THE SAME IN kernel/app/video
  // *********************************************************************

  CHANGES_RECORD = packed record
    OpType: cardinal; // screen_to_screen, blit, newcache, oldcache
    rect, origrect: TRect;
    point: TPoint;
    color: cardinal; // number used in cache array
    refcolor: cardinal; // slot used to pass bitmap data
  end;

  PCHANGES_RECORD = ^CHANGES_RECORD;

  Esc_dmf_Qvi_IN = packed record
    cbSize: cardinal;
    app_actual_version: cardinal;
    display_minreq_version: cardinal;
    connect_options: cardinal; // reserved. must be 0.
  end;

  Esc_dmf_Qvi_OUT = packed record
    cbSize: cardinal;
    display_actual_version: cardinal;
    miniport_actual_version: cardinal;
    app_minreq_version: cardinal;
    display_buildno: cardinal;
    miniport_buildno: cardinal;
    // MIRAGE
    // QUASAR
    prod_name: array [0 .. esc_qvi_prod_name_max - 1] of AnsiChar;
  end;

  CHANGES_BUF = packed record
    counter: cardinal;
    pointrect: array [0 .. MAXCHANGES_BUF - 1] of CHANGES_RECORD;
  end;

  PCHANGES_BUF = ^CHANGES_BUF;

  GETCHANGESBUF = packed record
    buffer: PCHANGES_BUF;
    userbuffer: pointer;
  end;

  PGETCHANGESBUF = ^GETCHANGESBUF;

  TDriverCallParams = record // Internal structure, do not use
    DeviceModeFlags: longint;
    DeviceName, DeviceString: AnsiString;
    CDS2: boolean;
    AttachFirst: longint;
    AttachLast: longint;
    Ex: boolean;
    CheckExist: boolean;
    CheckActive: boolean;
    GetDriverDC: boolean;
    DC: HDC;
  end;

  // abstract base class for accumulator region
  TUpdateRegionBase = class(TObject)
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddRect(const Rn: TRect); virtual;
    procedure StartAdd; virtual;
  end;

  TRectUpdateRegion = class(TUpdateRegionBase)
  private
    FChanged: boolean;
    FLeft: integer;
    FTop: integer;
    FRight: integer;
    FBottom: integer;
    FRegion: TRect;

  public
    procedure AddRect(const Rn: TRect); override;
    procedure StartAdd; override;

    property Changed:boolean read FChanged;
    property Left:integer read FLeft write FLeft;
    property Right:integer read FRight write FRight;
    property Top:integer read FTop write FTop;
    property Bottom:integer read FBottom write FBottom;

    property Region:TRect read FRegion write FRegion;
  end;

  TVideoDriver = class(TObject)
  private
    bufdata: GETCHANGESBUF;
    gdc: HDC;
    fDriverConnected: boolean;
    m_bitsPerPixel: byte;
    m_bytesPerPixel: byte;
    m_bytesPerRow: longint;
    m_ReadPtr: cardinal;

    FMultiMon: boolean;

  public
    constructor Create;
    destructor Destroy; override;

    function ActivateMirrorDriver: boolean;
    function DeactivateMirrorDriver: boolean;

    function MapSharedBuffers: boolean;
    procedure UnMapSharedBuffers;

    function ExistMirrorDriver: boolean;
    function IsMirrorDriverActive: boolean;

    function TestDriver: boolean;
    function TestMapped: boolean;

    function CaptureRect(const rcSrc,rcDst: TRect; DstStride: longint; destbuff: pointer): boolean;

    function CaptureLine(x1, x2, y: longint; DstStride: longint;
      var destbuff: PAnsiChar): boolean;

    function UpdateIncremental(updRgn: TUpdateRegionBase): boolean;

    procedure FetchSeries(const first: PCHANGES_RECORD; last: PCHANGES_RECORD; updRgn: TUpdateRegionBase);

    // qryverinfo is supported since version 1.1 (build 68) on
    function QryVerInfo: boolean;
    function GetMirrorDC: HDC;

    property BytesPerPixel: byte read m_bytesPerPixel;
    property BitsPerPixel: byte read m_bitsPerPixel;

  private
    function DriverCall(var dcp: TDriverCallParams): boolean;

  public
    gDriverName: Ansistring;
    
    property IsDriverActive: boolean read fDriverConnected;

    property MultiMonitor: boolean read FMultiMon write FMultiMon;
  end;

  // From Windows.h
  DEVMODE_ = packed record
    dmDeviceName: array [0 .. CCHDEVICENAME - 1] of AnsiChar;
    dmSpecVersion: Word;
    dmDriverVersion: Word;
    dmSize: Word;
    dmDriverExtra: Word;
    dmFields: DWORD;

    { dmOrientation: SHORT;
      dmPaperSize: SHORT;
      dmPaperLength: SHORT;
      dmPaperWidth: SHORT;
      dmScale: SHORT;
      dmCopies: SHORT;
      dmDefaultSource: SHORT;
      dmPrintQuality: SHORT; }

    dmPosition: _POINTL;
    dmDisplayOrientation: DWORD;
    dmDisplayFixedOutput: DWORD;

    dmColor: SHORT;
    dmDuplex: SHORT;
    dmYResolution: SHORT;
    dmTTOption: SHORT;
    dmCollate: SHORT;
    dmFormName: array [0 .. CCHFORMNAME - 1] of AnsiChar;
    dmLogPixels: Word;
    dmBitsPerPel: DWORD;
    dmPelsWidth: DWORD;
    dmPelsHeight: DWORD;
    dmDisplayFlags: DWORD;
    dmDisplayFrequency: DWORD;
    dmICMMethod: DWORD;
    dmICMIntent: DWORD;
    dmMediaType: DWORD;
    dmDitherType: DWORD;
    dmICCManufacturer: DWORD;
    dmICCModel: DWORD;
    dmPanningWidth: DWORD;
    dmPanningHeight: DWORD;
  end;

implementation

{ TVideoDriver }

constructor TVideoDriver.Create;
begin
  inherited Create;
  fDriverConnected:=false;
end;

destructor TVideoDriver.Destroy;
begin
  UnMapSharedBuffers();
  DeactivateMirrorDriver();
  fDriverConnected := False;
  inherited Destroy;
end;

function TVideoDriver.ActivateMirrorDriver: boolean;
var
  dcp: TDriverCallParams;
begin
  gDriverName := 'DISPLAY';
  FillChar(dcp, sizeof(dcp), 0);
  dcp.DeviceModeFlags := DM_BITSPERPEL + DM_ORIENTATION + DM_POSITION +
    DM_PELSWIDTH + DM_PELSHEIGHT;
  dcp.DeviceName := VideoDriverName;
  dcp.DeviceString := VideoDriverString;
  dcp.AttachFirst := 1;
  dcp.AttachLast := 1;
  dcp.Ex := true;
  Result := DriverCall(dcp);

  // ASSERT(m_bytesPerPixel);
  // ASSERT(m_bytesPerRow);

  QryVerInfo;
end;

function TVideoDriver.DeactivateMirrorDriver: boolean;
var
  dcp: TDriverCallParams;
begin
  gDriverName := '';
  FillChar(dcp, sizeof(dcp), 0);
  dcp.DeviceModeFlags := DM_BITSPERPEL + DM_PELSWIDTH + DM_PELSHEIGHT +
    DM_POSITION;
  dcp.DeviceName := VideoDriverName;
  dcp.DeviceString := VideoDriverString;
  dcp.CDS2 := true;
  dcp.AttachFirst := 0;
  dcp.AttachLast := 0;
  dcp.Ex := true;
  Result := DriverCall(dcp);

  m_bytesPerPixel := 0;
  m_bytesPerRow := 0;
end;

function TVideoDriver.MapSharedBuffers:boolean;
begin
  gdc := CreateDCA(@gDriverName[1], nil { VideoDriverName } , nil, nil);
  if gdc <> 0 then
    fDriverConnected := ExtEscape(gdc, MAP1, 0, nil, sizeof(GETCHANGESBUF), @bufdata) > 0;
  // NOTE: not necessarily 0.
  // more correct way is as follows: get current bufdata.buffer->counter
  // and perform the initial full screen update
  m_ReadPtr := 0;

  Result := fDriverConnected;
end;

procedure TVideoDriver.UnMapSharedBuffers;
begin
  ExtEscape(gdc, UNMAP1, sizeof(GETCHANGESBUF), @bufdata, 0, nil);
  DeleteDC(gdc);
  fDriverConnected := False;
end;

function TVideoDriver.ExistMirrorDriver: boolean;
var
  dcp: TDriverCallParams;
begin
  FillChar(dcp, sizeof(dcp), 0);
  dcp.DeviceModeFlags := DM_BITSPERPEL + DM_PELSWIDTH + DM_PELSHEIGHT;
  dcp.DeviceName := VideoDriverName;
  dcp.DeviceString := VideoDriverString;
  dcp.CheckExist := true;
  Result := DriverCall(dcp);
end;

function TVideoDriver.IsMirrorDriverActive: boolean;
var
  dcp: TDriverCallParams;
begin
  FillChar(dcp, sizeof(dcp), 0);
  dcp.DeviceModeFlags := DM_BITSPERPEL + DM_ORIENTATION + DM_POSITION +
    DM_PELSWIDTH + DM_PELSHEIGHT;
  dcp.DeviceName := VideoDriverName;
  dcp.DeviceString := VideoDriverString;
  dcp.CheckActive := true;
  Result := DriverCall(dcp);
end;

function BYTE0(x: cardinal): byte;
begin
  Result := ((x) and $FF);
end;

function BYTE1(x: cardinal): byte;
begin
  Result := (((x) shr 8) and $FF);
end;

function BYTE2(x: cardinal): byte;
begin
  Result := (((x) shr 16) and $FF);
end;

function BYTE3(x: cardinal): byte;
begin
  Result := (((x) shr 24) and $FF);
end;

function TVideoDriver.QryVerInfo: boolean;
var
  ldw: HWND;
  ldc: HDC;
  qin: Esc_dmf_Qvi_IN;
  qout: Esc_dmf_Qvi_OUT;
begin
  qin.cbSize := sizeof(qin);
  qin.app_actual_version := DMF_PROTO_VER_CURRENT;
  qin.display_minreq_version := DMF_PROTO_VER_MINCOMPAT;
  qin.connect_options := 0;
  qout.cbSize := sizeof(qout);

  ldw := GetDesktopWindow;
  try
    ldc := GetDC(ldw);
  except
    ldc := 0;
  end;
  if (ldw <> 0) and (ldc = 0) then
  begin
    ldw := 0;
    try
      ldc := GetDC(ldw);
    except
      ldc := 0;
    end;
    if ldc = 0 then
      raise Exception.Create('Can not lock on to Desktop Canvas');
  end;
  try
    Result := ExtEscape(ldc, QRY_VERINFO, sizeof(qin), @qin, sizeof(qout),
      @qout) > 0;
  finally
    ReleaseDC(ldw, ldc);
  end;

end;

function TVideoDriver.TestDriver: boolean;
begin
  gdc := CreateDCA(@gDriverName[1], nil { VideoDriverName } , nil, nil);
  fDriverConnected := ExtEscape(gdc, TEST_DRIVER, 0, nil, sizeof(GETCHANGESBUF), @bufdata) > 0;
  Result := fDriverConnected;
  // TODO: (if not filled in)
  // m_bytesPerPixel;
  // m_bytesPerRow;
end;

function TVideoDriver.TestMapped: boolean;
begin
  Result := False;
  if IsBadReadPtr(@bufdata, 1) then
    Exit;
  if bufdata.userbuffer = nil then
    Exit;
  if IsBadReadPtr(bufdata.userbuffer, 10) then
    Exit;
  Result := true;
end;

{ we probably should free the DC obtained from this function }

function TVideoDriver.GetMirrorDC: HDC;
var
  dcp: TDriverCallParams;
begin
  FillChar(dcp, sizeof(dcp), 0);
  dcp.DeviceModeFlags := DM_BITSPERPEL + DM_ORIENTATION + DM_POSITION +
    DM_PELSWIDTH + DM_PELSHEIGHT;
  dcp.DeviceName := VideoDriverName;
  dcp.DeviceString := VideoDriverString;
  dcp.GetDriverDC := true;
  if DriverCall(dcp) then
    Result := dcp.DC
  else
    Result := 0;
end;

function GetDesktopTop: Integer;
  begin
  Result := GetSystemMetrics(SM_YVIRTUALSCREEN);
  end;

function GetDesktopLeft: Integer;
  begin
  Result := GetSystemMetrics(SM_XVIRTUALSCREEN);
  end;

function GetDesktopHeight: Integer;
  begin
  Result := GetSystemMetrics(SM_CYVIRTUALSCREEN);
  end;

function GetDesktopWidth: Integer;
  begin
  Result := GetSystemMetrics(SM_CXVIRTUALSCREEN);
  end;

function GetScreenHeight: Integer;
  begin
  Result := GetSystemMetrics(SM_CYSCREEN);
  end;

function GetScreenWidth: Integer;
  begin
  Result := GetSystemMetrics(SM_CXSCREEN);
  end;

function TVideoDriver.DriverCall(var dcp: TDriverCallParams): boolean;
  var
    hdeskInput, hdeskCurrent: HDESK;
    dm: DEVMODEA;
    pdm: PDEVMODE;

    dd: TDisplayDeviceA;
    devNum: longint;
    res: boolean;
    deviceNum: ansistring;
    KeyName: ansistring;
    hk: HKEY;
    dwVal: DWORD;
  begin
  Result := False;

  FillChar(dm, sizeof(dm), 0);
  dm.dmSize := sizeof(dm);
  dm.dmDriverExtra := 0;

  EnumDisplaySettingsA(nil, ENUM_CURRENT_SETTINGS, dm);

  DEVMODE_(dm).dmFields := dcp.DeviceModeFlags;

  if (dcp.AttachFirst = 0) and (dcp.AttachLast = 0) then // Deactivating
    begin
    DEVMODE_(dm).dmPosition.x := 0;
    DEVMODE_(dm).dmPosition.y := 0;
    DEVMODE_(dm).dmPelsWidth := 0;
    DEVMODE_(dm).dmPelsHeight := 0;
    end
  else
    begin
    if MultiMonitor then
      begin
      DEVMODE_(dm).dmPosition.x := GetDesktopLeft;
      DEVMODE_(dm).dmPosition.y := GetDesktopTop;
      DEVMODE_(dm).dmPelsWidth := GetDesktopWidth;
      DEVMODE_(dm).dmPelsHeight := GetDesktopHeight;
      end
    else
      begin
      DEVMODE_(dm).dmPosition.x := 0;
      DEVMODE_(dm).dmPosition.y := 0;
      DEVMODE_(dm).dmPelsWidth := GetScreenWidth;
      DEVMODE_(dm).dmPelsHeight := GetScreenHeight;
      end;
    end;

  dm.dmDeviceName[0] := #0;

  FillChar(dd, sizeof(dd), 0);
  dd.cb := sizeof(dd);
  devNum := 0;
  res := EnumDisplayDevicesA(nil, devNum, dd, 0);
  while res do
    begin
    if strcomp(dd.DeviceString, PAnsiChar(dcp.DeviceString)) = 0 then
      break;
    inc(devNum);
    res := EnumDisplayDevicesA(nil, devNum, dd, 0);
    end;

  if dcp.CheckExist then
    begin
    Result := res;
    Exit;
    end;

  if dcp.CheckActive then
    begin
    Result := (dd.StateFlags and DISPLAY_DEVICE_ATTACHED_TO_DESKTOP) <> 0;
    Exit;
    end;

  if dcp.GetDriverDC then
    begin
    if res then
      dcp.DC := CreateDCA(@gDriverName[1], nil { VideoDriverName } , nil, nil);
    Result := res;
    Exit;
    end;

  if not res then
    raise EMirrorDriver.Create(Format('No such driver found: %s', [String(dcp.DeviceString)]));

  m_bitsPerPixel := dm.dmBitsPerPel;
  m_bytesPerPixel := dm.dmBitsPerPel div 8;
  m_bytesPerRow := dm.dmPelsWidth * m_bytesPerPixel;

  deviceNum := 'DEVICE0';
  { Should we modify it to point to correct devNum ?? Probably no }

  KeyName := VideoDriverRegKeyRoot + dcp.DeviceName + '\' + deviceNum;
  (*
    if (RegCreateKey(HKEY_LOCAL_MACHINE,
    ("SYSTEM\\CurrentControlSet\\Hardware Profiles\\Current\\System\\CurrentControlSet\\Services\\dfmirage"),
    &hKeyProfileMirror) != ERROR_SUCCESS)

  *)
  if RegCreateKeyA(HKEY_LOCAL_MACHINE, PAnsiChar(KeyName), hk) <> ERROR_SUCCESS then
    raise EMirrorDriver.Create(Format('Error creating key HKLM\%s', [String(KeyName)]));

  try
    if dcp.AttachFirst = 1 then
      begin
      dwVal := 3; // Direct Access
      if (RegSetValueEx(hk, 'Cap.DfbBackingMode', 0, REG_DWORD, @dwVal, 4) <> ERROR_SUCCESS) then
        raise EMirrorDriver.Create('Error setting "Cap.DfbBackingMode" registry value');

      dwVal := 1;
      if (RegSetValueEx(hk, 'Order.BltCopyBits.Enabled', 0, REG_DWORD, @dwVal, 4) <> ERROR_SUCCESS) then
        raise EMirrorDriver.Create('Error setting "Order.BltSopyBits.Enabled" registry value');
      end
    else
      begin
      RegDeleteValue(hk, 'Cap.DfbBackingMode');
      RegDeleteValue(hk, 'Order.BltCopyBits.Enabled');
      end;

    if RegSetValueEx(hk, 'Attach.ToDesktop', 0, REG_DWORD, @dcp.AttachFirst, sizeof(longint)) <> ERROR_SUCCESS then
      raise EMirrorDriver.Create('Error setting "Attach.ToDesktop" registry value');

    StrPCopy(dm.dmDeviceName, dcp.DeviceName);

    hdeskCurrent := GetThreadDesktop(GetCurrentThreadId());
    if hdeskCurrent = 0 then
      Exit;

    hdeskInput := OpenInputDesktop(DF_ALLOWOTHERACCOUNTHOOK, False,
      DESKTOP_CREATEMENU or DESKTOP_CREATEWINDOW or DESKTOP_ENUMERATE or
      DESKTOP_HOOKCONTROL or DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS or
      DESKTOP_SWITCHDESKTOP or GENERIC_WRITE);
    if hdeskInput = 0 then
      Exit;
    SetThreadDesktop(hdeskInput);

    // We only support the 32-bit color mode
    dm.dmBitsPerPel := 32;

    // add 'Default.*' settings to the registry under above hKeyProfile\mirror\device
    if dcp.Ex then
      ChangeDisplaySettingsExA(dd.DeviceName, dm, 0, CDS_UPDATEREGISTRY, nil)
    else
      begin
      pdm := nil;
      ChangeDisplaySettings(pdm^, 0);
      end;

    if dcp.CDS2 then
      ChangeDisplaySettingsExA(dd.DeviceName, dm, 0, 0, nil);

    gDriverName := dd.DeviceName;
    // reset desktop
    SetThreadDesktop(hdeskCurrent);
    CloseDesktop(hdeskInput);

    if RegSetValueEx(hk, 'Attach.ToDesktop', 0, REG_DWORD, @dcp.AttachLast, sizeof(longint)) <> ERROR_SUCCESS then
      raise EMirrorDriver.Create('Error setting "Attach.ToDesktop" registry value');
  finally
    RegCloseKey(hk);
  end;

  Result := true;
  end;

function TVideoDriver.CaptureRect(const rcSrc, rcDst: TRect; DstStride: longint; destbuff: pointer): boolean;
  var
    srcbmoffset: longint;
    dstbmoffset: longint;
    srcbuffpos: ^byte;
    destbuffpos: ^byte;
    widthBytes: cardinal;
    y: longint;
  begin
  Result := False;

  if (fDriverConnected) then
    begin
    srcbmoffset := (m_bytesPerRow * rcSrc.Top) + (m_bytesPerPixel * rcSrc.Left);
    dstbmoffset := (DstStride * rcDst.Top) +     (m_bytesPerPixel * rcDst.Left);

    destbuffpos := destbuff;
    Inc(destbuffpos, dstbmoffset);

    srcbuffpos := bufdata.userbuffer;
    Inc(srcbuffpos, srcbmoffset);

    widthBytes := (rcSrc.right - rcSrc.Left) * m_bytesPerPixel;

    for y := rcSrc.Top to rcSrc.bottom - 1 do
      begin
      Move(srcbuffpos^, destbuffpos^, widthBytes);
      Inc(srcbuffpos, m_bytesPerRow);
      Inc(destbuffpos, DstStride);
      end;
    Result := true;
    end;
  end;

function TVideoDriver.CaptureLine(x1, x2, y: longint; DstStride: longint; var destbuff: PAnsiChar): boolean;
  var
    srcbmoffset: longint;
    dstbmoffset: longint;
    srcbuffpos: PAnsiChar;
    destbuffpos: PAnsiChar;
    widthBytes: cardinal;
  begin
  Result := False;
  if (fDriverConnected) then
    begin
    srcbmoffset := (m_bytesPerRow * y) + (m_bytesPerPixel * x1);
    dstbmoffset := (DstStride * y) + (m_bytesPerPixel * x1);

    destbuffpos := destbuff + dstbmoffset;
    srcbuffpos := PAnsiChar(bufdata.userbuffer) + srcbmoffset;

    widthBytes := (x2 - x1) * m_bytesPerPixel;

    Move(srcbuffpos^, destbuffpos^, widthBytes);

    Result := true;
    end;
  end;

function TVideoDriver.UpdateIncremental(updRgn: TUpdateRegionBase): boolean;
  var
    snapshot_counter: cardinal;
  begin
  Result := False;
  
  updRgn.StartAdd;

  if (fDriverConnected) then
    begin
    snapshot_counter := bufdata.buffer^.counter;

    if (m_ReadPtr <> snapshot_counter) then
      begin
      if (m_ReadPtr < snapshot_counter) then
        begin
        FetchSeries(@(bufdata.buffer^.pointrect[m_ReadPtr]),
          @(bufdata.buffer^.pointrect[snapshot_counter]), updRgn);
        end
      else
        begin
        FetchSeries(@(bufdata.buffer^.pointrect[m_ReadPtr]),
          @(bufdata.buffer^.pointrect[MAXCHANGES_BUF-1]), updRgn);

        FetchSeries(@(bufdata.buffer^.pointrect[0]),
          @(bufdata.buffer^.pointrect[snapshot_counter]), updRgn);
        end;
      m_ReadPtr := snapshot_counter;
      Result:=True;
      end;

    end;
  end;

procedure TVideoDriver.FetchSeries(const first: PCHANGES_RECORD;
                                         last: PCHANGES_RECORD;
                                         updRgn: TUpdateRegionBase);
  var
    i: PCHANGES_RECORD;
  begin
  i := first;
  while PAnsiChar(i) < PAnsiChar(last) do
    begin
    if (i^.OpType in [dmf_dfo_SCREEN_SCREEN .. dmf_dfo_TEXTOUT]) then
      updRgn.AddRect(i^.rect);
    i := PCHANGES_RECORD(PAnsiChar(pointer(i)) + sizeof(CHANGES_RECORD));
    end;
  end;

constructor TUpdateRegionBase.Create;
begin
  inherited Create;
end;

destructor TUpdateRegionBase.Destroy;
begin
  inherited Destroy;
end;

procedure TUpdateRegionBase.AddRect(const Rn: TRect);
begin
end;

procedure TUpdateRegionBase.StartAdd;
begin
end;

{ TRectUpdateRegion }

procedure TRectUpdateRegion.AddRect(const Rn: TRect);
  begin
  inherited;
  if (Rn.Left>FRegion.Right) or (Rn.Right<FRegion.Left) or
     (Rn.Top>FRegion.Bottom) or (Rn.Bottom<FRegion.Top) then Exit;
  if not FChanged then
    begin
    FChanged:=True;
    FLeft:=Rn.Left;
    FTop:=Rn.Top;
    FBottom:=Rn.Bottom;
    FRight:=Rn.Right;
    end
  else
    begin
    if Rn.Left<FLeft then FLeft:=Rn.Left;
    if Rn.Top<FTop then FTop:=Rn.Top;
    if Rn.Bottom>FBottom then FBottom:=Rn.Bottom;
    if Rn.Right>FRight then FRight:=Rn.Right;
    end;
  end;

procedure TRectUpdateRegion.StartAdd;
  begin
  inherited;
  FChanged:=False;
  end;

end.
