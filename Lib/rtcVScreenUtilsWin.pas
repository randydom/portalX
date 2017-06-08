{
  "Windows Screen Utils (VCL)"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcVScreenUtilsWIN;

interface

{$include rtcDefs.inc}

uses
  Types, Windows, Messages,
  Classes, SysUtils,
  {$IFDEF IDE_XEUp}
    VCL.Graphics,
  {$ELSE}
    Graphics,
  {$ENDIF}

  Registry,

  rtcTypes, rtcInfo,
  rtcSyncObjs, rtcLog,

  rtcXJPEGConst,
  rtcXBmpUtils,
  rtcXScreenUtils,

  rtcVWinStation,
  rtcVMirrorDriver;

function GetScreenBitmapInfo:TRtcBitmapInfo;

function ScreenCapture(var Image: TRtcBitmapInfo; Forced:boolean):boolean;

function WindowCapture(DW:HWND; Region:TRect; var Image:TRtcBitmapInfo):boolean;

procedure MouseSetup;
procedure GrabMouse;

  // Returns mouse cursor data for the last captured Screen.
  // Use ONLY after "ScreenCapture", or "MouseSetup" + "GrabMouse":
function CaptureMouseCursorDelta: RtcByteArray;
function CaptureMouseCursor: RtcByteArray;

function GetScreenHeight: Integer;
function GetScreenWidth: Integer;

function GetDesktopTop: Integer;
function GetDesktopLeft: Integer;
function GetDesktopHeight: Integer;
function GetDesktopWidth: Integer;

function EnableMirrorDriver:boolean;
procedure DisableMirrorDriver;
function CurrentMirrorDriver:boolean;

procedure EnableAero;
procedure DisableAero;
function CurrentAero:boolean;

procedure ShowWallpaper;
function HideWallpaper: String;

procedure Control_MouseDown(const user: Cardinal; X, Y: integer; Button: TMouse_Button);
procedure Control_MouseUp(const user: Cardinal; X, Y: integer; Button: TMouse_Button);
procedure Control_MouseMove(const user: Cardinal; X, Y: integer);
procedure Control_MouseWheel(Wheel: integer);

procedure Control_KeyDown(key: word); // ; Shift: TShiftState);
procedure Control_KeyUp(key: word); // ; Shift: TShiftState);

procedure Control_SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);
procedure Control_ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);

procedure Control_KeyPress(const AText: RtcString; AKey: word);
procedure Control_KeyPressW(const AText: WideString; AKey: word);

function Control_CtrlAltDel(fromLauncher: boolean = False): boolean;

procedure Control_LWinKey(key: word);
procedure Control_RWinKey(key: word);
procedure Control_AltTab;
procedure Control_ShiftAltTab;
procedure Control_CtrlAltTab;
procedure Control_ShiftCtrlAltTab;
procedure Control_Win;
procedure Control_RWin;

procedure Control_ReleaseAllKeys;

function Control_checkKeyPress(Key: longint): RtcChar;

function Get_ComputerName: RtcString;
function Get_UserName: RtcString;

implementation

var
  mirror:TVideoDriver=nil;
  updates:TRectUpdateRegion;
  MouseCS:TRtcCritSec;
  MyProcessID:Cardinal;

function GetScreenBitmapInfo:TRtcBitmapInfo;
  begin
  FillChar(Result,SizeOf(Result),0);
  Result.Reverse:=True;
  Result.BuffType:=btBGRA32;
  Result.BytesPerPixel:=4;
  CompleteBitmapInfo(Result);
  end;

function EnableMirrorDriver:boolean;
  begin
{$IFNDEF WIN32}
  Result:=False;
  Exit;
{$ENDIF}
  if assigned(mirror) then
    Result:=True
  else
    begin
    try
      mirror:=TVideoDriver.Create;
      mirror.MultiMonitor:=True;
      if not mirror.ExistMirrorDriver then
        begin
        FreeAndNil(mirror);
        Result:=False;
        end
      else if not mirror.ActivateMirrorDriver then
        begin
        FreeAndNil(mirror);
        Result:=False;
        end
      else
        begin
        Sleep(1000);
        if not mirror.MapSharedBuffers then
          begin
          FreeAndNil(mirror);
          Result:=False;
          end
        else
          begin
          Result:=True;
          updates:=TRectUpdateRegion.Create;
          end;
        end;
    except
      FreeAndNil(mirror);
      Result:=False;
      end;
    end;
  end;

procedure DisableMirrorDriver;
  begin
  if assigned(mirror) then
    begin
    mirror.DeactivateMirrorDriver;
    FreeAndNil(mirror);
    FreeAndNil(updates);
    end;
  end;

function CurrentMirrorDriver:boolean;
  begin
  Result:=assigned(mirror);
  end;

function GetScreenHeight: Integer;
  begin
  Result := GetSystemMetrics(SM_CYSCREEN);
  end;

function GetScreenWidth: Integer;
  begin
  Result := GetSystemMetrics(SM_CXSCREEN);
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

function IsWinNT: boolean;
var
  OS: TOSVersionInfo;
begin
  ZeroMemory(@OS, SizeOf(OS));
  OS.dwOSVersionInfoSize := SizeOf(OS);
  GetVersionEx(OS);
  Result := OS.dwPlatformId = VER_PLATFORM_WIN32_NT;
end;

type
  TDwmEnableComposition = function(uCompositionAction: UINT): HRESULT; stdcall;
  TDwmIsCompositionEnabled = function(var pfEnabled: BOOL): HRESULT; stdcall;

const
  DWM_EC_DISABLECOMPOSITION = 0;
  DWM_EC_ENABLECOMPOSITION = 1;

var
  DwmEnableComposition: TDwmEnableComposition = nil;
  DwmIsCompositionEnabled: TDwmIsCompositionEnabled = nil;
  ChangedAero: boolean = False;
  OriginalAero: LongBool = True;

  DWMLibLoaded : boolean = False;
  DWMlibrary: THandle;

procedure LoadDwmLibs;
begin
  if not DWMLibLoaded then
  begin
    DWMlibrary := LoadLibrary('DWMAPI.dll');
    if DWMlibrary <> 0 then
    begin
      DWMLibLoaded := True;
      DwmEnableComposition := GetProcAddress(DWMlibrary, 'DwmEnableComposition');
      DwmIsCompositionEnabled := GetProcAddress(DWMlibrary, 'DwmIsCompositionEnabled');
    end;
  end;
end;

procedure UnloadDwmLibs;
begin
  if DWMLibLoaded then
  begin
    DWMLibLoaded := False;
    @DwmEnableComposition := nil;
    @DwmIsCompositionEnabled := nil;
    FreeLibrary(DWMLibrary);
  end;
end;

function CurrentAero:boolean;
  var
    CurrAero: LongBool;
  begin
  Result:=False;
  LoadDWMLibs;
  if @DwmIsCompositionEnabled <> nil then
    begin
    DwmIsCompositionEnabled(CurrAero);
    Result:=CurrAero;
    end;
  end;

procedure EnableAero;
  begin
  if not CurrentAero then
    if @DwmEnableComposition <> nil then
      DwmEnableComposition(DWM_EC_ENABLECOMPOSITION);
  end;

procedure DisableAero;
  begin
  if CurrentAero then
    if @DwmEnableComposition <> nil then
      DwmEnableComposition(DWM_EC_DISABLECOMPOSITION);
  end;

type
  TBlockInputProc = function(fBlockInput: boolean): DWord; stdcall;
  TGetCursorInfo = function(var pci: TCursorInfo): BOOL; stdcall;

var
  User32Loaded: boolean = False; // User32 DLL loaded ?
  User32Handle: HInst; // User32 DLL handle

  BlockInputProc: TBlockInputProc = nil;
  GetCursorInfoProc: TGetCursorInfo = nil;

function GetOSVersionInfo(var Info: TOSVersionInfo): boolean;
begin
  FillChar(Info, sizeof(TOSVersionInfo), 0);
  Info.dwOSVersionInfoSize := sizeof(TOSVersionInfo);
  Result := GetVersionEx(Info);
  if (not Result) then
  begin
    FillChar(Info, sizeof(TOSVersionInfo), 0);
    Info.dwOSVersionInfoSize := sizeof(TOSVersionInfo);
    Result := GetVersionEx(Info);
    if (not Result) then
      Info.dwOSVersionInfoSize := 0;
  end;
end;

procedure LoadUser32;
var
  osi: TOSVersionInfo;
begin
  if not User32Loaded then
  begin
    User32Handle := LoadLibrary(user32);
    if User32Handle = 0 then
      Exit; // if loading fails, exit.

    User32Loaded := True;

    if GetOSVersionInfo(osi) then
    begin
      if osi.dwMajorVersion >= 5 then
      begin
        @BlockInputProc := GetProcAddress(User32Handle, 'BlockInput');
        @GetCursorInfoProc := GetProcAddress(User32Handle, 'GetCursorInfo');
      end;
    end;
  end;
end;

procedure UnLoadUser32;
begin
  if User32Loaded then
  begin
    @BlockInputProc := nil;
    @GetCursorInfoProc := nil;
    FreeLibrary(User32Handle);
    User32Loaded := False;
  end;
end;

function Block_UserInput(fBlockInput: boolean): DWord;
begin
  if not User32Loaded then
    LoadUser32;
  if @BlockInputProc <> nil then
    Result := BlockInputProc(fBlockInput)
  else
    Result := 0;
end;

function Get_CursorInfo(var pci: TCursorInfo): BOOL;
begin
  if not User32Loaded then
    LoadUser32;
  if @GetCursorInfoProc <> nil then
    Result := GetCursorInfoProc(pci)
  else
    Result := False;
end;

var
  FCaptureLeft,
  FCaptureTop:integer;

  FMouseX, FMouseY,
  FMouseIconW, FMouseIconH,
  FMouseIconMaskW, FMouseIconMaskH,
  FMouseHotX, FMouseHotY: integer;
  FMouseVisible: boolean;

  FMouseHandle: HICON;
  FMouseIcon: TBitmap = nil;
  FMouseIconMask: TBitmap = nil;

  FMouseIconData:RtcByteArray = nil;
  FMouseIconMaskData:RtcByteArray = nil;

  FMouseUser,
  FLastMouseUser: Cardinal;

  FLastMouseX, FLastMouseY: integer;
  FLastMouseSkip: boolean;

  FMouseInit: boolean;

  FMouseChangedShape: boolean;
  FMouseMoved: boolean;
  FMouseLastVisible: boolean;

procedure MouseSetup;
  begin
  FMouseChangedShape:=True;
  FMouseMoved:=True;
  FMouseHandle := INVALID_HANDLE_VALUE;
  FMouseInit := True;

  MouseCS.Acquire;
  try
    FLastMouseUser := 0;
    FLastMouseX := -1;
    FLastMouseY := -1;
    FLastMouseSkip := False;
  finally
    MouseCS.Release;
    end;

  FMouseUser := 0;
  FMouseX := -1;
  FMouseY := -1;
  RtcFreeAndNil(FMouseIcon);
  RtcFreeAndNil(FMouseIconMask);
  SetLength(FMouseIconData,0);
  SetLength(FMouseIconMaskData,0);
  end;

procedure GrabMouse;
var
  ci: TCursorInfo;
  icinfo: TIconInfo;
  pt: TPoint;
  ImgData:PColorBGR32;
  Y:integer;
begin
  MouseCS.Acquire;
  try
    ci.cbSize := SizeOf(ci);
    if Get_CursorInfo(ci) then
    begin
      if ci.flags = CURSOR_SHOWING then
      begin
        FMouseVisible := True;
        if FMouseInit or
          (ci.ptScreenPos.X <> FMouseX) or
          (ci.ptScreenPos.Y <> FMouseY) then
        begin
          FMouseMoved := True;
          FMouseX := ci.ptScreenPos.X;
          FMouseY := ci.ptScreenPos.Y;

          if (FLastMouseUser <> 0) and
             (FMouseX >= FLastMouseX - 8) and (FMouseX <= FLastMouseX + 8) and
             (FMouseY >= FLastMouseY - 8) and (FMouseY <= FLastMouseY + 8) then
            FMouseUser := FLastMouseUser
          else
            begin
            FMouseUser := 0;
            FLastMouseX := -1;
            FLastMouseY := -1;
            FLastMouseSkip := False;
            end;
        end;
        if FMouseInit or (ci.hCursor <> FMouseHandle) then
        begin
          FMouseChangedShape := True;
          FMouseHandle := ci.hCursor;
          RtcFreeAndNil(FMouseIcon);
          RtcFreeAndNil(FMouseIconMask);
          SetLength(FMouseIconData,0);
          SetLength(FMouseIconMaskData,0);
          // send cursor image
          if GetIconInfo(ci.hCursor, icinfo) then
          begin
            FMouseHotX := icinfo.xHotspot;
            FMouseHotY := icinfo.yHotspot;

            if icinfo.hbmMask <> INVALID_HANDLE_VALUE then
            begin
              FMouseIconMask := TBitmap.Create;
              try
                FMouseIconMask.Handle := icinfo.hbmMask;
                FMouseIconMask.PixelFormat:=pf32bit;
                FMouseIconMaskW:=FMouseIconMask.Width;
                FMouseIconMaskH:=FMouseIconMask.Height;
                SetLength(FMouseIconMaskData,FMouseIconMaskW*FMouseIconMaskH*4);
                ImgData:=PColorBGR32(Addr(FMouseIconMaskData[0]));
                for Y := 0 to FMouseIconMask.Height - 1 do
                  begin
                  Move(FMouseIconMask.ScanLine[Y]^, ImgData^, FMouseIconMaskW*4);
                  Inc(ImgData,FMouseIconMaskW);
                  end;
              finally
                RtcFreeAndNil(FMouseIconMask);
                end;
            end;

            if icinfo.hbmColor <> INVALID_HANDLE_VALUE then
            begin
              FMouseIcon := TBitmap.Create;
              try
                FMouseIcon.Handle := icinfo.hbmColor;
                FMouseIcon.PixelFormat:=pf32bit;
                FMouseIconW:=FMouseIcon.Width;
                FMouseIconH:=FMouseIcon.Height;
                SetLength(FMouseIconData,FMouseIconW*FMouseIconH*4);
                ImgData:=PColorBGR32(Addr(FMouseIconData[0]));
                for Y := 0 to FMouseIcon.Height - 1 do
                  begin
                  Move(FMouseIcon.ScanLine[Y]^, ImgData^, FMouseIconW*4);
                  Inc(ImgData,FMouseIconW);
                  end;
              finally
                RtcFreeAndNil(FMouseIcon);
                end;
            end;
          end;
        end;
        FMouseInit := False;
      end
      else
        FMouseVisible := False;
    end
    else if GetCursorPos(pt) then
    begin
      FMouseVisible := True;
      if FMouseInit or (pt.X <> FMouseX) or (pt.Y <> FMouseY) then
      begin
        FMouseMoved := True;
        FMouseX := pt.X;
        FMouseY := pt.Y;
        if (FLastMouseUser <> 0) and
           (FMouseX >= FLastMouseX - 8) and (FMouseX <= FLastMouseX + 8) and
           (FMouseY >= FLastMouseY - 8) and (FMouseY <= FLastMouseY + 8) then
          FMouseUser := FLastMouseUser
        else
          begin
          FMouseUser := 0;
          FLastMouseX := -1;
          FLastMouseY := -1;
          FLastMouseSkip := False;
          end;
      end;
      FMouseInit := False;
    end
    else
      FMouseVisible := False;
  finally
    MouseCS.Release;
    end;
end;

var
  LastMirror: boolean;
  LastDW: HWND;
  LastDC: HDC;
  LastBMP: TBitmap;
  RTC_CAPTUREBLT: DWORD = $40000000;

function WindowCapture(DW:HWND; Region:TRect; var Image:TRtcBitmapInfo):boolean;
  var
    SDC: HDC;
    X, Y, NewWid, NewHig, Wid, Hig:integer;
    ImgData: PColorBGR32;

  function CaptureNow(toDC:HDC):boolean;
    begin
    if RtcCaptureSettings.LayeredWindows then
      Result:=BitBlt(toDC, 0, 0, Wid, Hig, SDC, X, Y, SRCCOPY or RTC_CAPTUREBLT)
    else
      Result:=BitBlt(toDC, 0, 0, Wid, Hig, SDC, X, Y, SRCCOPY);
    end;

  begin
  Result:=False;

  Wid := Region.Right-Region.Left;
  Hig := Region.Bottom-Region.Top;
  if (Wid=0) or (Hig=0) then Exit;

  NewWid:=((Wid+7) div 8) * 8;
  NewHig:=((Hig+7) div 8) * 8;

  SDC := GetDC(DW);
  if SDC <> 0 then
    begin
    X := Region.Left;
    Y := Region.Top;

    Wid := Region.Right-Region.Left;
    Hig := Region.Bottom-Region.Top;

    if (Image.Width<>NewWid) or (Image.Height<>NewHig) then
      ResizeBitmapInfo(Image,NewWid,NewHig,False);

    if not assigned(LastBMP) then
      begin
      LastBMP:=TBitmap.Create;
      LastBMP.PixelFormat:=pf32bit;
      end;

    if (LastBMP.Width<>Image.Width) or
       (LastBMP.Height<>Image.Height) then
      begin
      LastBmp.Width:=Image.Width;
      LastBmp.Height:=Image.Height;
      end;

    LastBMP.Canvas.Lock;
    try
      Result:=CaptureNow(LastBMP.Canvas.Handle);
      if Result then
        begin
        ImgData:=PColorBGR32(Image.TopData);
        for Y := 0 to LastBMP.Height - 1 do
          begin
          Move(LastBMP.ScanLine[Y]^, ImgData^, Image.BytesPerLine);
          Inc(ImgData,Image.PixelsToNextLine);
          end;
        end;
    finally
      LastBMP.Canvas.Unlock;
      end;

    ReleaseDC(DW, SDC);
    end;
  end;

function ScreenCapture(var Image: TRtcBitmapInfo; Forced:boolean):boolean;
  var
    DW: HWND;
    ImgData: PColorBGR32;
    SDC: HDC;
    X, Y: integer;
    X1, Y1, X2, Y2: integer;
    NewWid, NewHig, Wid, Hig,
    borLeft, borTop: integer;
    initial, changed, switched: boolean;

  function PrepareDC:boolean;
    begin
    if LastDC<>0 then
      begin
      try
        ReleaseDC(LastDW,LastDC);
      except
        end;
      LastDW:=0;
      LastDC:=0;
      end;

    DW := GetDesktopWindow;
    try
      SDC := GetDC(DW);
    except
      SDC := 0;
      end;
    if (DW <> 0) and (SDC = 0) then
      begin
      DW := 0;
      try
        SDC := GetDC(DW);
      except
        SDC := 0;
        end;
      end;

    LastDC:=SDC;
    LastDW:=DW;

    Result:=LastDC<>0;
    end;

  function CaptureNow(toDC:HDC):boolean;
    begin
    if RtcCaptureSettings.LayeredWindows then
      Result:=BitBlt(toDC, 0, 0, Wid, Hig, SDC, X, Y, SRCCOPY or RTC_CAPTUREBLT)
    else
      Result:=BitBlt(toDC, 0, 0, Wid, Hig, SDC, X, Y, SRCCOPY);
    if not Result then
      begin
      SwitchToActiveDesktop(true);
      if PrepareDC then
        if RtcCaptureSettings.LayeredWindows then
          Result:=BitBlt(toDC, 0, 0, Wid, Hig, SDC, X, Y, SRCCOPY or RTC_CAPTUREBLT)
        else
          Result:=BitBlt(toDC, 0, 0, Wid, Hig, SDC, X, Y, SRCCOPY);
      end;
    end;

  begin
  Result:=False;

  switched:=SwitchToActiveDesktop(false);

  borLeft:=GetDesktopLeft;
  borTop:=GetDesktopTop;

  if RtcCaptureSettings.AllMonitors then
    begin
    Wid := GetDesktopWidth;
    Hig := GetDesktopHeight;
    X := borLeft;
    Y := borTop;
    end
  else
    begin
    Wid := GetScreenWidth;
    Hig := GetScreenHeight;
    X := 0;
    Y := 0;
    end;

  FCaptureLeft:=X;
  FCaptureTop:=Y;

  NewWid:=((Wid+7) div 8) * 8;
  NewHig:=((Hig+7) div 8) * 8;

  if (Image.Data=nil) or
     (Image.Width<>NewWid) or
     (Image.Height<>NewHig) then
    begin
    initial:=True;
    ResizeBitmapInfo(Image,NewWid,NewHig,False);
    end
  else
    initial:=False;

  if Forced then initial:=True;

  if assigned(mirror) then
    begin
    if not LastMirror then initial:=True;
    
    LastMirror:=True;
    Dec(X,borLeft);
    Dec(Y,borTop);

    updates.Region:=Rect(X,Y,X+Wid,Y+Hig);
    if mirror.UpdateIncremental(updates) then
      changed:=updates.changed
    else
      changed:=False;

    if initial then
      begin
      changed:=True;
      updates.Left:=X;
      updates.Top:=Y;
      updates.Right:=X+Wid;
      updates.Bottom:=Y+Hig;
      end;

    if changed then
      begin
      X1:=updates.Left-X;
      X2:=updates.Right-X;
      Y1:=updates.Top-Y;
      Y2:=updates.Bottom-Y;

      if X1<0 then X1:=0 else if X1>Wid then X1:=Wid;
      if Y1<0 then Y1:=0 else if Y1>Hig then Y1:=Hig;
      if X2<0 then X2:=0 else if X2>Wid then X2:=Wid;
      if Y2<0 then Y2:=0 else if Y2>Hig then Y2:=Hig;

      if (X2>X1) and (Y2>Y1) then
        begin
        if RtcCaptureSettings.CompleteBitmap then
          begin
          X1:=0;Y1:=0;
          X2:=Wid;Y2:=Hig;
          end;
        Result:=mirror.CaptureRect(Rect(X1+X,Y1+Y,X2+X,Y2+Y), Rect(X1,Y1,X2,Y2),
                                   Image.PixelsToNextLine*4, Image.TopData);
        end;
      end;
    end
  else
    begin
    LastMirror:=False;

    if (LastDC<>0) and not switched then
      SDC:=LastDC
    else if not PrepareDC then
      Exit;

    if not assigned(LastBMP) then
      begin
      LastBMP:=TBitmap.Create;
      LastBMP.PixelFormat:=pf32bit;
      end;

    if (LastBMP.Width<>Image.Width) or (LastBMP.Height<>Image.Height) then
      begin
      LastBMP.Width:=Image.Width;
      LastBMP.Height:=Image.Height;
      end;

    LastBMP.Canvas.Lock;
    try
      Result:=CaptureNow(LastBMP.Canvas.Handle);
      if Result then
        begin
        ImgData:=PColorBGR32(Image.TopData);
        for Y := 0 to LastBMP.Height - 1 do
          begin
          Move(LastBMP.ScanLine[Y]^, ImgData^, Image.BytesPerLine);
          Inc(ImgData,Image.PixelsToNextLine);
          end;
        end;
    finally
      LastBMP.Canvas.Unlock;
      end;
    end;
  end;

function CaptureMouseCursorDelta: RtcByteArray;
  var
    rec:TRtcRecord;
  begin
  if FMouseMoved or FMouseChangedShape or (FMouseLastVisible <> FMouseVisible) then
    begin
    rec := TRtcRecord.Create;
    try
      if FMouseLastVisible <> FMouseVisible then
        rec.asBoolean['V'] := FMouseVisible;
      if FMouseMoved then
        begin
        rec.asInteger['X'] := FMouseX - FCaptureLeft;
        rec.asInteger['Y'] := FMouseY - FCaptureTop;
        if FMouseUser <> 0 then
          rec.asCardinal['A'] := FMouseUser;
        end;
      if FMouseChangedShape then
        begin
        rec.asInteger['HX'] := FMouseHotX;
        rec.asInteger['HY'] := FMouseHotY;
        if length(FMouseIconData)>0 then
          begin
          rec.asInteger['IW']:=FMouseIconW;
          rec.asInteger['IH']:=FMouseIconH;
          rec.asByteArray['I']:=FMouseIconData;
          SetLength(FMouseIconData,0);
          end;
        if length(FMouseIconMaskData)>0 then
          begin
          rec.asInteger['MW']:=FMouseIconMaskW;
          rec.asInteger['MH']:=FMouseIconMaskH;
          rec.asByteArray['M']:=FMouseIconMaskData;
          SetLength(FMouseIconMaskData,0);
          end;
        end;
      Result:=rec.toCodeEx;
    finally
      RtcFreeAndNil(rec);
      end;
    FMouseMoved := False;
    FMouseChangedShape := False;
    FMouseLastVisible := FMouseVisible;
    end
  else
    Result:=nil;
  end;

function CaptureMouseCursor: RtcByteArray;
  begin
  FMouseChangedShape := True;
  FMouseMoved := True;
  FMouseLastVisible := not FMouseVisible;
  Result := CaptureMouseCursorDelta;
  end;

procedure FreeMouseCursorStorage;
  begin
  FMouseHandle:=INVALID_HANDLE_VALUE;
  RtcFreeAndNil(FMouseIcon);
  RtcFreeAndNil(FMouseIconMask);
  SetLength(FMouseIconData,0);
  SetLength(FMouseIconMaskData,0);
  end;

function okToClick(X, Y: integer): boolean;
var
  P: TPoint;
  W: HWND;
  hit: integer;
  pid: Cardinal;
begin
  P.X := X;
  P.Y := Y;
  W := WindowFromPoint(P);
  if GetWindowThreadProcessId(W,pid)=0 then
    Result:=True
  else if pid<>MyProcessID then
    Result := True
  else
    begin
    hit := SendMessage(W, WM_NCHITTEST, 0, P.X + (P.Y shl 16));
    // XLog('X='+IntToStr(P.X)+', Y='+IntToStr(P.Y)+', H='+IntToStr(hit));
    Result := not(hit in [HTCLOSE, HTMAXBUTTON, HTMINBUTTON, HTTOP]);
    end;
end;

{function okToUnClick(X, Y: integer): boolean;
var
  P: TPoint;
  R: TRect;
  W: HWND;
  hit: integer;
begin
  P.X := X;
  P.Y := Y;
  W := WindowFromPoint(P);
  hit := SendMessage(W, WM_NCHITTEST, 0, P.X + (P.Y shl 16));
  Result := not(hit in [HTCLOSE, HTMAXBUTTON, HTMINBUTTON]);
  if not Result then
    begin
    case hit of
      HTCLOSE:
        PostMessage(W, WM_SYSCOMMAND, SC_CLOSE, 0);
      HTMINBUTTON:
        PostMessage(W, WM_SYSCOMMAND, SC_MINIMIZE, 0);
      HTMAXBUTTON:
        begin
        GetWindowRect(W, R);
        if (R.Left=0) and
           (R.Top=0) and
           (R.Right=GetScreenWidth) and
           (R.Bottom=GetScreenHeight) then
          PostMessage(W, WM_SYSCOMMAND, SC_RESTORE, 0)
        else
          PostMessage(W, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
        end;
      end;
    end;
end;}

procedure Post_MouseDown(Button: TMouse_Button);
begin
  case Button of
    mb_Left:
      mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
    mb_Right:
      mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
    mb_Middle:
      mouse_event(MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, 0);
  end;
end;

procedure Post_MouseUp(Button: TMouse_Button);
begin
  case Button of
    mb_Left:
      mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    mb_Right:
      mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
    mb_Middle:
      mouse_event(MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0);
  end;
end;

procedure Post_MouseWheel(Wheel: integer);
begin
  mouse_event(MOUSEEVENTF_WHEEL, 0, 0, Wheel, 0);
end;

procedure Post_MouseMove(X, Y: integer);
begin
  if GetScreenWidth > 0 then
    begin
    X := round(X / (GetScreenWidth - 1) * 65535);
    Y := round(Y / (GetScreenHeight - 1) * 65535);
    mouse_event(MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE, X, Y, 0, 0);
    end
  else
    SetCursorPos(X, Y);
end;

procedure Control_MouseDown(const user: Cardinal; X, Y: integer; Button: TMouse_Button);
var LX,LY:integer;
begin
  if Button in [mb_Left, mb_Right] then
    if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
      case Button of
        mb_Left:
          Button := mb_Right;
        mb_Right:
          Button := mb_Left;
      end;

  MouseCS.Acquire;
  try
    FLastMouseUser := user;
    FLastMouseX := X + FCaptureLeft;
    FLastMouseY := Y + FCaptureTop;

    LX:=FLastMouseX;
    LY:=FLastMouseY;

    FLastMouseSkip:=False;
    SetCursorPos(FLastMouseX, FLastMouseY);
    Post_MouseMove(FLastMouseX, FLastMouseY);
  finally
    MouseCS.Release;
    end;

  if Button <> mb_Left then
    Post_MouseDown(Button)
  else if not okToClick(LX, LY) then
    FLastMouseSkip:=True
  else
    Post_MouseDown(Button);
end;

procedure Control_MouseUp(const user: Cardinal; X, Y: integer; Button: TMouse_Button);
begin
  if Button in [mb_Left, mb_Right] then
    if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
      case Button of
        mb_Left:
          Button := mb_Right;
        mb_Right:
          Button := mb_Left;
      end;

  MouseCS.Acquire;
  try
    FLastMouseUser := user;
    FLastMouseX := X + FCaptureLeft;
    FLastMouseY := Y + FCaptureTop;

    Post_MouseMove(FLastMouseX, FLastMouseY);
  finally
    MouseCS.Release;
    end;

  if Button <> mb_Left then
    begin
    FLastMouseSkip:=False;
    Post_MouseUp(Button);
    end
  else if FLastMouseSkip then
    begin
    FLastMouseSkip:=False;
    Post_MouseDown(Button);
    Post_MouseUp(Button);
    end
  else
    Post_MouseUp(Button);
end;

procedure Control_MouseMove(const user: Cardinal; X, Y: integer);
begin
  MouseCS.Acquire;
  try
    FLastMouseUser := user;
    FLastMouseX := X + FCaptureLeft;
    FLastMouseY := Y + FCaptureTop;

    Post_MouseMove(FLastMouseX, FLastMouseY);
  finally
    MouseCS.Release;
    end;
end;

procedure Control_MouseWheel(Wheel: integer);
begin
  Post_MouseWheel(Wheel);
end;

var
  FShiftDown:boolean=False;
  FCtrlDown:boolean=False;
  FAltDown:boolean=False;

procedure keybdevent(key: word; Down: boolean = True);
var
  vk: integer;
begin
  vk := MapVirtualKey(key, 0);
  if Down then
    keybd_event(key, vk, 0, 0)
  else
    keybd_event(key, vk, KEYEVENTF_KEYUP, 0);
end;

procedure Control_KeyDown(key: word); // ; Shift: TShiftState);
var
  numlock: boolean;
begin
  case key of
    VK_SHIFT:
      if FShiftDown then
        Exit
      else
        FShiftDown := True;
    VK_CONTROL:
      if FCtrlDown then
        Exit
      else
        FCtrlDown := True;
    VK_MENU:
      if FAltDown then
        Exit
      else
        FAltDown := True;
  end;

  if (Key >= $21) and (Key <= $2E) then
  begin
    numlock := (GetKeyState(VK_NUMLOCK) and 1 = 1);
    if numlock then
    begin
      keybdevent(VK_NUMLOCK);
      keybdevent(VK_NUMLOCK, False);
    end;
    keybd_event(key,MapVirtualKey(key, 0), KEYEVENTF_EXTENDEDKEY, 0) // have to be Exctended ScanCodes
  end
  else
  begin    
    numlock := False;
    keybdevent(Key);
  end; 

  if numlock then
  begin
    keybdevent(VK_NUMLOCK, False);
    keybdevent(VK_NUMLOCK);
  end;
end;

procedure Control_KeyUp(key: word); // ; Shift: TShiftState);
var
  numlock: boolean;
begin
  case key of
    VK_SHIFT:
      if not FShiftDown then
        Exit
      else
        FShiftDown := False;
    VK_CONTROL:
      if not FCtrlDown then
        Exit
      else
        FCtrlDown := False;
    VK_MENU:
      if not FAltDown then
        Exit
      else
        FAltDown := False;
  end;

  if (key >= $21) and (key <= $2E) then
  begin
    numlock := (GetKeyState(VK_NUMLOCK) and 1 = 1);
    if numlock then
    begin
      // turn NUM LOCK off
      keybdevent(VK_NUMLOCK);
      keybdevent(VK_NUMLOCK, False);
    end;
  end
  else
    numlock := False;

  keybdevent(key, False);

  if numlock then
  begin
    // turn NUM LOCK on
    keybdevent(VK_NUMLOCK);
    keybdevent(VK_NUMLOCK, False);
  end;
end;

procedure Control_SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);
begin
  if capslock then
  begin
    // turn CAPS LOCK off
    keybdevent(VK_CAPITAL);
    keybdevent(VK_CAPITAL, False);
  end;

  if lWithShift <> FShiftDown then
    keybdevent(VK_SHIFT, lWithShift);

  if lWithCtrl <> FCtrlDown then
    keybdevent(VK_CONTROL, lWithCtrl);

  if lWithAlt <> FAltDown then
    keybdevent(VK_MENU, lWithAlt);
end;

procedure Control_ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);
begin
  if lWithAlt <> FAltDown then
    keybdevent(VK_MENU, FAltDown);

  if lWithCtrl <> FCtrlDown then
    keybdevent(VK_CONTROL, FCtrlDown);

  if lWithShift <> FShiftDown then
    keybdevent(VK_SHIFT, FShiftDown);

  if capslock then
  begin
    // turn CAPS LOCK on
    keybdevent(VK_CAPITAL);
    keybdevent(VK_CAPITAL, False);
  end;
end;

procedure Control_KeyPress(const AText: RtcString; AKey: word);
var
  a: integer;
  lScanCode: Smallint;
  lWithAlt, lWithCtrl, lWithShift: boolean;
  capslock: boolean;
begin
  for a := 1 to length(AText) do
  begin
{$IFDEF RTC_BYTESTRING}
    lScanCode := VkKeyScanA(AText[a]);
{$ELSE}
    lScanCode := VkKeyScanW(AText[a]);
{$ENDIF}
    if lScanCode = -1 then
    begin
      if not(AKey in [VK_MENU, VK_SHIFT, VK_CONTROL, VK_CAPITAL, VK_NUMLOCK])
      then
      begin
        keybdevent(AKey);
        keybdevent(AKey, False);
      end;
    end
    else
    begin
      lWithShift := lScanCode and $100 <> 0;
      lWithCtrl := lScanCode and $200 <> 0;
      lWithAlt := lScanCode and $400 <> 0;

      lScanCode := lScanCode and $F8FF;
      // remove Shift, Ctrl and Alt from the scan code

      capslock := GetKeyState(VK_CAPITAL) > 0;

      Control_SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);

      keybdevent(lScanCode);
      keybdevent(lScanCode, False);

      Control_ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);
    end;
  end;
end;

procedure Control_KeyPressW(const AText: WideString; AKey: word);
var
  a: integer;
  lScanCode: Smallint;
  lWithAlt, lWithCtrl, lWithShift: boolean;
  capslock: boolean;
begin
  for a := 1 to length(AText) do
  begin
    lScanCode := VkKeyScanW(AText[a]);

    if lScanCode = -1 then
    begin
      if not(AKey in [VK_MENU, VK_SHIFT, VK_CONTROL, VK_CAPITAL, VK_NUMLOCK])
      then
      begin
        keybdevent(AKey);
        keybdevent(AKey, False);
      end;
    end
    else
    begin
      lWithShift := lScanCode and $100 <> 0;
      lWithCtrl := lScanCode and $200 <> 0;
      lWithAlt := lScanCode and $400 <> 0;

      lScanCode := lScanCode and $F8FF;
      // remove Shift, Ctrl and Alt from the scan code

      capslock := GetKeyState(VK_CAPITAL) > 0;

      Control_SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);

      keybdevent(lScanCode);
      keybdevent(lScanCode, False);

      Control_ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);
    end;
  end;
end;

procedure Control_LWinKey(key: word);
begin
  Control_SetKeys(False, False, False, False);
  keybdevent(VK_LWIN);
  keybdevent(key);
  keybdevent(key, False);
  keybdevent(VK_LWIN, False);
  Control_ResetKeys(False, False, False, False);
end;

procedure Control_RWinKey(key: word);
begin
  Control_SetKeys(False, False, False, False);
  keybdevent(VK_RWIN);
  keybdevent(key);
  keybdevent(key, False);
  keybdevent(VK_RWIN, False);
  Control_ResetKeys(False, False, False, False);
end;

procedure Control_AltTab;
var
  capslock: boolean;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;
  Control_SetKeys(capslock, False, False, True);
  keybdevent(VK_TAB);
  keybdevent(VK_TAB, False);
  Control_ResetKeys(capslock, False, False, True);
end;

procedure Control_ShiftAltTab;
var
  capslock: boolean;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;
  Control_SetKeys(capslock, True, False, True);
  keybdevent(VK_TAB);
  keybdevent(VK_TAB, False);
  Control_ResetKeys(capslock, True, False, True);
end;

procedure Control_CtrlAltTab;
var
  capslock: boolean;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;
  Control_SetKeys(capslock, False, True, True);
  keybdevent(VK_TAB);
  keybdevent(VK_TAB, False);
  Control_ResetKeys(capslock, False, True, True);
end;

procedure Control_ShiftCtrlAltTab;
var
  capslock: boolean;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;
  Control_SetKeys(capslock, True, True, True);
  keybdevent(VK_TAB);
  keybdevent(VK_TAB, False);
  Control_ResetKeys(capslock, True, True, True);
end;

procedure Control_Win;
var
  capslock: boolean;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;
  Control_SetKeys(capslock, False, False, False);
  keybdevent(VK_LWIN);
  keybdevent(VK_LWIN, False);
  Control_ResetKeys(capslock, False, False, False);
end;

procedure Control_RWin;
var
  capslock: boolean;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;
  Control_SetKeys(capslock, False, False, False);
  keybdevent(VK_RWIN);
  keybdevent(VK_RWIN, False);
  Control_ResetKeys(capslock, False, False, False);
end;

(*
procedure Control_SpecialKey(const AKey: RtcString);
var
  capslock: boolean;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;

  if AKey = 'CAD' then
  begin
    // Ctrl+Alt+Del
    if UpperCase(Get_UserName) = 'SYSTEM' then
    begin
      XLog('Executing CtrlAltDel as SYSTEM user ...');
      SetKeys(capslock, False, False, False);
      if not Post_CtrlAltDel then
        begin
        XLog('CtrlAltDel execution failed as SYSTEM user');
        if rtcGetProcessID(AppFileName) > 0 then
          begin
          XLog('Sending CtrlAltDel request to Host Service ...');
          Write_File(ChangeFileExt(AppFileName, '.cad'), '');
          end;
        end
      else
        XLog('CtrlAltDel execution successful');
      ResetKeys(capslock, False, False, False);
    end
    else
    begin
      if rtcGetProcessID(AppFileName) > 0 then
        begin
        XLog('Sending CtrlAltDel request to Host Service ...');
        Write_File(ChangeFileExt(AppFileName, '.cad'), '');
        end
      else
        begin
        XLog('Emulating CtrlAltDel as "'+Get_UserName+'" user ...');
        SetKeys(capslock, False, True, True);
        keybdevent(VK_ESCAPE);
        keybdevent(VK_ESCAPE, False);
        ResetKeys(capslock, False, True, True);
        end;
    end;
  end
  else if AKey = 'COPY' then
  begin
    // Ctrl+C
    SetKeys(capslock, False, True, False);
    keybdevent(Ord('C'));
    keybdevent(Ord('C'), False);
    ResetKeys(capslock, False, True, False);
  end
  else if AKey = 'HDESK' then
  begin
    // Hide Wallpaper
    Hide_Wallpaper;
  end
  else if AKey = 'SDESK' then
  begin
    // Show Wallpaper
    Show_Wallpaper;
  end;
end;
*)

procedure Control_ReleaseAllKeys;
begin
  if FShiftDown then
    Control_KeyUp(VK_SHIFT); //, []);
  if FAltDown then
    Control_KeyUp(VK_MENU); // , []);
  if FCtrlDown then
    Control_KeyUp(VK_CONTROL); // , []);
end;

function Get_ComputerName: RtcString;
var
  buf: array [0 .. 256] of AnsiChar;
  len: DWord;
begin
  len := sizeof(buf);
  GetComputerNameA(@buf, len);
  Result := RtcString(PAnsiChar(@buf));
end;

function Get_UserName: RtcString;
var
  buf: array [0 .. 256] of AnsiChar;
  len: DWord;
begin
  len := sizeof(buf);
  GetUserNameA(@buf, len);
  Result := RtcString(PAnsiChar(@buf));
end;

type
  TSendCtrlAltDel = function(asUser: Bool; iSession: integer) : Cardinal; stdcall;

function Call_CAD:boolean;
var
  nr     : integer;
  sendcad: TSendCtrlAltDel;
  lib    : Cardinal;
begin
  Result:=False;
  lib := LoadLibrary('aw_sas32.dll');
  if lib <> 0 then 
  begin
    try
      @sendcad := GetProcAddress(lib, 'sendCtrlAltDel');
      if assigned(sendcad) then
      begin
        nr := sendcad(False, -1);
        if nr<>0 then
          XLog('SendCtrlAltDel execution failed, Error Code = ' + inttostr(nr))
        else
          begin
          XLog('SendCtrlAltDel executed OK using aw_sas32.dll');
          Result:=True;
          end;
      end
      else
        XLog('Loading sendCtrlAltDel from aw_sas32.dll failed');
    finally
      FreeLibrary(lib);
    end;
  end
  else
    XLog('Loading aw_sas32.dll failed, can not execute sendCtrlAltDel');
  end;

function Control_CtrlAltDel(fromLauncher: boolean = False): boolean;
var
  LogonDesktop, CurDesktop: HDESK;
  dummy: Cardinal;
  new_name: array [0 .. 256] of AnsiChar;
begin
  if (Win32MajorVersion >= 6 { vista\server 2k8 } ) then
    Result := Call_CAD
  else
    Result := false;

  if not Result then
  begin
    { dwSessionId := WTSGetActiveConsoleSessionId;
      myPID:= GetCurrentProcessId;
      winlogonSessId := 0;
      if (ProcessIdToSessionId(myPID, winlogonSessId) and (winlogonSessId = dwSessionId)) then }

    XLog('Executing CtrlAltDel through WinLogon ...');
    Result := False;
    LogonDesktop := OpenDesktopA('Winlogon', 0, False, DESKTOP_ALL);
    if (LogonDesktop <> 0) and
      (GetUserObjectInformationA(LogonDesktop, UOI_NAME, @new_name, 256, dummy))
    then
      try
        CurDesktop := GetThreadDesktop(GetCurrentThreadID);
        if (CurDesktop = LogonDesktop) or SetThreadDesktop(LogonDesktop) then
          try
            PostMessageA(HWND_BROADCAST, WM_HOTKEY, 0,
              MAKELONG(MOD_ALT or MOD_CONTROL, VK_DELETE));
            Result := True;
          finally
            if CurDesktop <> LogonDesktop then
              SetThreadDesktop(CurDesktop);
          end
        else
        begin
          PostMessageA(HWND_BROADCAST, WM_HOTKEY, 0,
            MAKELONG(MOD_ALT or MOD_CONTROL, VK_DELETE));
        end;
      finally
        CloseDesktop(LogonDesktop);
      end
    else
    begin
      PostMessageA(HWND_BROADCAST, WM_HOTKEY, 0,
        MAKELONG(MOD_ALT or MOD_CONTROL, VK_DELETE));
    end;
  end;
end;

var
  WallpaperVisible: boolean = True;

procedure ShowWallpaper;
var
  reg: TRegIniFile;
  Result: String;
begin
  Result := '';

  reg := TRegIniFile.Create('Control Panel\Desktop');
  Result := Trim(reg.ReadString('', 'Wallpaper', ''));
  reg.Free;

  if Result <> '' then
  begin
    WallpaperVisible := True;
    // Return the old value back to Registry.
    if Result <> '' then
    begin
      reg := TRegIniFile.Create('Control Panel\Desktop');
      try
        reg.WriteString('', 'Wallpaper', Result);
      finally
        reg.Free;
      end;
    end;

    //
    // let everyone know that we changed
    // a system parameter
    //
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PChar(Result),
      SPIF_UPDATEINIFILE + SPIF_SENDWININICHANGE);
  end;
end;

const
  SPI_GETDESKWALLPAPER = $0073;

function HideWallpaper: String;
var
  reg: TRegIniFile;
  aWall: PChar;
begin
  if WallpaperVisible then
  begin
    WallpaperVisible := False;
    //
    // change registry
    //
    // HKEY_CURRENT_USER
    // Control Panel\Desktop
    // TileWallpaper (REG_SZ)
    // Wallpaper (REG_SZ)
    //
    Result := '';

    GetMem(aWall, 32767);
    try
      SystemParametersInfo(SPI_GETDESKWALLPAPER, 32767, Pointer(aWall), 0);
      Result := strPas(aWall);
    finally
      FreeMem(aWall);
    end;

    //
    // let everyone know that we changed
    // a system parameter
    //
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PChar(''),
      SPIF_UPDATEINIFILE + SPIF_SENDWININICHANGE);

    // Return the old value back to Registry.
    if Result <> '' then
    begin
      reg := TRegIniFile.Create('Control Panel\Desktop');
      try
        reg.WriteString('', 'Wallpaper', Result);
      finally
        reg.Free;
      end;
    end;
  end;
end;

function Control_checkKeyPress(Key: longint): RtcChar;
var
  pc: array [1 .. 10] of RtcChar;
  ks: TKeyboardState;
begin
  FillChar(ks, SizeOf(ks), 0);
  GetKeyboardState(ks);
{$IFDEF RTC_BYTESTRING}
  if ToAscii(Key, MapVirtualKey(Key, 0), ks, @pc[1], 0) = 1 then
  begin
    Result := pc[1];
    if vkKeyScanA(Result) and $FF <> Key and $FF then
      Result := #0;
  end
{$ELSE}
  if ToUnicode(Key, MapVirtualKey(Key, 0), ks, pc[1], 10, 0) = 1 then
  begin
    Result := pc[1];
    if vkKeyScanW(Result) and $FF <> Key and $FF then
      Result := #0;
  end
{$ENDIF}
  else
    Result := #0;
end;

initialization
LastDC:=0;
LastDW:=0;
if not IsWinNT then
  RTC_CAPTUREBLT := 0;
MouseCS:=TRtcCritSec.Create;
MyProcessID:=GetCurrentProcessId;

finalization
Control_ReleaseAllKeys;
RtcFreeAndNil(LastBMP);
RtcFreeAndNil(MouseCS);
FreeMouseCursorStorage;
DisableMirrorDriver;
UnloadDwmLibs;
UnLoadUser32;
end.
