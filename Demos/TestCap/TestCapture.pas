unit TestCapture;

interface

{$include rtcDefs.inc}
{$include rtcDeploy.inc}

uses
  Windows, Messages, SysUtils, Variants, Dialogs,
  Classes, Graphics, Controls, Forms,
  ExtCtrls, ComCtrls, StdCtrls, Buttons,

  rtcTypes,
  rtcInfo,

  rtcXScreenUtils,
  rtcVScreenUtilsWin,

  rtcXBmpUtils,
  rtcXImgEncode,
  rtcXImgDecode,
  rtcXJPEGConst,

  rtcVBmpUtils,

  rtcBlankOutForm;

type
  TForm1 = class(TForm)
    MainPanel: TPanel;
    eQualityLum: TTrackBar;
    mot1Line4a: TLabel;
    mot1Line2a: TLabel;
    mot1Line3a: TLabel;
    mot1LineKb: TLabel;
    mot1Line4: TLabel;
    mot1Line4b: TLabel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Label1: TLabel;
    xLZW: TCheckBox;
    xHQColor: TCheckBox;
    eHQDepth: TTrackBar;
    eQualityCol: TTrackBar;
    Label2: TLabel;
    CaptureTimer: TTimer;
    Bevel6: TBevel;
    Bevel7: TBevel;
    Bevel4: TBevel;
    lblScreenInfo: TLabel;
    xAllMonitors: TCheckBox;
    PaintTimer: TTimer;
    xBandwidth: TComboBox;
    xMirrorDriver: TCheckBox;
    xWinAero: TCheckBox;
    eMotionVert: TTrackBar;
    eMotionHorz: TTrackBar;
    eMotionFull: TTrackBar;
    Label3: TLabel;
    Bevel10: TBevel;
    jpgLineKb: TLabel;
    jpgLine2a: TLabel;
    jpgLine3a: TLabel;
    jpgLine4a: TLabel;
    jpgLine4b: TLabel;
    jpgLine4: TLabel;
    rleLineKb: TLabel;
    rleLine2a: TLabel;
    rleLine3a: TLabel;
    rleLine4a: TLabel;
    rleLine4b: TLabel;
    rleLine4: TLabel;
    totLineKb: TLabel;
    totLine2a: TLabel;
    totLine3a: TLabel;
    totLine4a: TLabel;
    totLine4b: TLabel;
    totLine4: TLabel;
    Bevel11: TBevel;
    capLine2a: TLabel;
    capLine4a: TLabel;
    capLine4: TLabel;
    eColorDepth: TTrackBar;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    capLineKb: TLabel;
    capLine3a: TLabel;
    capLine4b: TLabel;
    SubPanel: TPanel;
    btnCapture: TSpeedButton;
    xConfig: TCheckBox;
    xMotionDebug: TCheckBox;
    totLine5: TLabel;
    UpdateTimer: TTimer;
    xSplitData: TCheckBox;
    xMaintenanceForm: TCheckBox;
    xLayeredWindows: TCheckBox;
    ScrollBox1: TScrollBox;
    PaintBox1: TPaintBox;
    xColorReduceReal: TCheckBox;
    xMotionComp1: TCheckBox;
    xColorComp: TCheckBox;
    xJPG: TCheckBox;
    xRLE: TCheckBox;
    Bevel5: TBevel;
    eWindowCaption: TComboBox;
    xCaptureFrame: TCheckBox;
    xAutoHide: TCheckBox;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    procedure CaptureClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure CaptureTimerTimer(Sender: TObject);
    procedure PaintTimerTimer(Sender: TObject);
    procedure xMirrorDriverClick(Sender: TObject);
    procedure xWinAeroClick(Sender: TObject);
    procedure xConfigClick(Sender: TObject);
    procedure UpdateTimerTimer(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure xMaintenanceFormClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure xWindowCaptureClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
    bmp4,bmp5:TBitmap;
    bmp3info:TRtcBitmapInfo;

    AutoRefresh:boolean;

    FrameTime,totTime,totTime2,totData:Cardinal;

    ImgEncoder:TRtcImageEncoder;
    ImgDecoder:TRtcImageDecoder;
    compStage:integer;

    OldParent:HWND;
    CaptureRectLeft,
    CaptureRectTop:integer;
    
    LDown,RDown,MDown:boolean;

    WinHdls:array of HWND;

    function GetCaptureWindow:HWND;
    procedure PostMouseMessage(Msg:Cardinal; MouseX, MouseY: integer);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.CaptureClick(Sender: TObject);
  var
    t0:cardinal;
    capTime1,capTime2,
    mot1Time,mot1Time2,mot1Data,
    mot2Time,mot2Time2,mot2Data,
    mot3Time,mot3Time2,mot3Data,
    jpgTime,jpgTime2,jpgData,
    rleTime,rleTime2,rleData,
    nowData,curData:Cardinal;

    newMouse:RtcByteArray;

    curStorage,
    mot1Storage,
    mot2Storage,
    mot3Storage,
    jpgStorage,
    rleStorage:RtcByteArray;

    HqLevelLum,HqLevelCol:word;
    HqDepth:byte;
    btmp:TRtcBitmapInfo;

    capFPS1,capFPS2,capFPS3,
    mot1FPS1,mot1FPS2,mot1FPS3,
    mot2FPS1,mot2FPS2,mot2FPS3,
    mot3FPS1,mot3FPS2,mot3FPS3,
    jpgFPS1,jpgFPS2,jpgFPS3,
    rleFPS1,rleFPS2,rleFPS3,
    totFPS1,totFPS2,totFPS3:double;

    have_img:boolean;
    CompChg:boolean;
    Delay:integer;

  function CalcFPS(dataSize:cardinal):double;
    begin
    if dataSize=0 then
      Result:=99.99
    else
      begin
      case xBandwidth.ItemIndex of
        0:Result:=round(12500000/32/dataSize)/100;
        1:Result:=round(12500000/16/dataSize)/100;
        2:Result:=round(12500000/8/dataSize)/100;
        3:Result:=round(12500000/4/dataSize)/100;
        4:Result:=round(12500000/2/dataSize)/100;
        5:Result:=round(12500000/dataSize)/100;
        6:Result:=round(12500000/dataSize*2)/100;
        7:Result:=round(12500000/dataSize*4)/100;
        8:Result:=round(12500000/dataSize*8)/100;
        9:Result:=round(12500000/dataSize*16)/100;
        else
          Result:=99.99;
        end;
      end;
    if Result>99.99 then Result:=99.99;
    end;

  function CaptureWindowTo(var bmp:TRtcBitmapInfo):boolean;
    var
      mpt:TPoint;
      rct:TRect;
      hdl:HWND;
      pwi:tagWINDOWINFO;
    begin
    hdl:=GetCaptureWindow;
    if IsWindow(hdl) then
      begin
      if xCaptureFrame.Checked then
        begin
        Windows.GetWindowInfo(hdl,pwi);
        CaptureRectLeft:=pwi.rcClient.Left;
        CaptureRectTop:=pwi.rcClient.Top;
        rct:=pwi.rcWindow;
        Dec(rct.Left, pwi.rcClient.Left);
        Dec(rct.Top, pwi.rcClient.Top);
        Dec(rct.Right, pwi.rcClient.Left);
        Dec(rct.Bottom, pwi.rcClient.Top);
        {
        Windows.GetWindowRect(hdl,rct);
        Dec(rct.Left,CaptureRectLeft);
        Dec(rct.Top,CaptureRectTop);
        Dec(rct.Right,CaptureRectLeft);
        Dec(rct.Bottom,CaptureRectTop);
        }
        Inc(CaptureRectLeft,rct.Left);
        Inc(CaptureRectTop,rct.Top);
        end
      else
        begin
        mpt.X:=0;
        mpt.Y:=0;
        Windows.ClientToScreen(hdl,mpt);
        CaptureRectLeft:=mpt.X;
        CaptureRectTop:=mpt.Y;

        Windows.GetClientRect(hdl,rct);
        rct.Right:=rct.Right-rct.Left;
        rct.Bottom:=rct.Bottom-rct.Top;
        rct.Left:=0;
        rct.Top:=0;
        end;

      Result:=WindowCapture(WinHdls[eWindowCaption.ItemIndex],rct,bmp);
      end
    else
      Result:=False;
    end;

  begin
  if assigned(Sender) then
    begin
    AutoRefresh:=not AutoRefresh;
    UpdateTimer.Enabled:=AutoRefresh;
    if AutoRefresh then
      btnCapture.Caption:='STOP'
    else
      begin
      btnCapture.Caption:='START';
      Exit;
      end;
    end;

  {if assigned(Sender) then
    begin
    CompStage:=0;

    FreeAndNil(bmp4);
    FreeAndNil(bmp5);
    ResetBitmapInfo(bmp3Info);
    FrameTime:=GetTickCount;

    ImgEncoder.FirstFrame;
    end;}

  nowData:=0;

  if CompStage=0 then
    begin
    totData:=0;
    totTime:=0;
    totTime2:=0;

    // Prepare Screen capture parameters

    ImgDecoder.MotionDebug:=xMotionDebug.Checked;

    ImgEncoder.MotionComp:=xMotionComp1.Checked;
    ImgEncoder.ColorComp:=xColorComp.Checked;

    ImgEncoder.MotionHorzScan:=eMotionHorz.Position>0;
    ImgEncoder.MotionVertScan:=eMotionVert.Position>0;
    ImgEncoder.MotionFullScan:=eMotionFull.Position>0;

    if eMotionHorz.Position>0 then
      ImgEncoder.MotionHorzScanLimit:=(eMotionHorz.Position-1)*100
    else
      ImgEncoder.MotionHorzScanLimit:=0;

    if eMotionVert.Position>0 then
      ImgEncoder.MotionVertScanLimit:=(eMotionVert.Position-1)*100
    else
      ImgEncoder.MotionVertScanLimit:=0;

    if eMotionFull.Position>0 then
      ImgEncoder.MotionFullScanLimit:=(eMotionFull.Position-1)*100
    else
      ImgEncoder.MotionFullScanLimit:=0;

    if xColorReduceReal.Checked then
      begin
      ImgEncoder.ColorBitsR:=eColorDepth.Position;
      ImgEncoder.ColorBitsG:=eColorDepth.Position;
      ImgEncoder.ColorBitsB:=eColorDepth.Position;
      ImgEncoder.ColorReduce:=0;
      end
    else
      begin
      ImgEncoder.ColorBitsR:=8;
      ImgEncoder.ColorBitsG:=8;
      ImgEncoder.ColorBitsB:=8;
      ImgEncoder.ColorReduce:=(8-eColorDepth.Position)*2;
      end;

    ImgEncoder.JPGCompress:=xJPG.Checked;
    ImgEncoder.RLECompress:=xRLE.Checked;
    ImgEncoder.LZWCompress:=xLZW.Checked;

    if ImgEncoder.JPGCompress then
      begin
      if eHQDepth.Position>0 then
        begin
        HqLevelLum:=eQualityLum.Position;
        HqLevelCol:=eQualityCol.Position;
        end
      else
        begin
        HqLevelLum:=0;
        HqLevelCol:=0;
        end;
      HqDepth:=255;
      case eHQDepth.Position of
        2:HqDepth:=240;
        3:HqDepth:=120;
        4:HqDepth:=80;
        5:HqDepth:=60;
        end;
      ImgEncoder.QLevelLum:=eQualityLum.Position;
      ImgEncoder.QLevelCol:=eQualityCol.Position;
      ImgEncoder.HQLevelLum:=HqLevelLum;
      ImgEncoder.HQLevelCol:=HqLevelCol;
      ImgEncoder.HQDepth:=HqDepth;
      ImgEncoder.HQColor:=xHQColor.Checked;
      end;

    RtcCaptureSettings.CompleteBitmap:=True;
    RtcCaptureSettings.LayeredWindows:=xLayeredWindows.Enabled and xLayeredWindows.Checked;
    RtcCaptureSettings.AllMonitors:=xAllMonitors.Checked;

    // Capture the Screen

    t0:=GetTickCount;
    capTime1:=t0;

    if (ImgEncoder.OldBmpInfo.Data=nil) or
       (ImgEncoder.NewBmpInfo.Data=nil) then
      begin
      ResetBitmapInfo(ImgEncoder.OldBmpInfo);
      if eWindowCaption.ItemIndex>0 then
        have_img:=CaptureWindowTo(ImgEncoder.NewBmpInfo)
      else
        begin
        have_img:=ScreenCapture(ImgEncoder.NewBmpInfo,ImgEncoder.NeedRefresh);
        CaptureRectLeft:=0;
        CaptureRectTop:=0;
        end;
      MouseSetup;
      GrabMouse;
      newMouse:=CaptureMouseCursor;
      end
    else
      begin
      if eWindowCaption.ItemIndex>0 then
        have_img:=CaptureWindowTo(ImgEncoder.OldBmpInfo)
      else
        begin
        have_img:=ScreenCapture(ImgEncoder.OldBmpInfo,ImgEncoder.NeedRefresh);
        CaptureRectLeft:=0;
        CaptureRectTop:=0;
        end;
      GrabMouse;
      newMouse:=CaptureMouseCursorDelta;
      if have_img then
        begin
        btmp:=ImgEncoder.OldBmpInfo;
        ImgEncoder.OldBmpInfo:=ImgEncoder.NewBmpInfo;
        ImgEncoder.NewBmpInfo:=btmp;
        end;
      end;

    if have_img then
      ImgEncoder.ReduceColors(ImgEncoder.NewBmpInfo);

    if length(newMouse)>0 then
      begin
      curStorage:=ImgEncoder.CompressMouse(newMouse);
      SetLength(newMouse,0);
      end
    else
      SetLength(curStorage,0);

    curData:=length(curStorage);

    t0:=GetTickCount;

    capTime1:=t0-capTime1;
    if capTime1<=0 then
      capFPS1:=99.99
    else
      capFPS1:=round(100000/capTime1)/100;
    capFPS2:=CalcFPS(curData);
    if capFPS1<capFPS2 then
      capFPS3:=capFPS1
    else
      capFPS3:=capFPS2;

    if curData>0 then
      begin
      t0:=GetTickCount;
      capTime2:=t0;
        ImgDecoder.Decompress(curStorage,bmp3Info);
      t0:=GetTickCount;
      capTime2:=t0-capTime2;
      end
    else
      capTime2:=0;

    Inc(totTime,capTime1);
    Inc(totData,curData);

    capLineKb.Caption:=IntToStr(curData div 125)+' Kbit';

    capLine2a.Caption:=IntToStr(capTime1)+' ms';
    capLine3a.Caption:=IntToStr(capTime2)+' ms';

    capLine4a.Caption:=Float2Str(capFPS1)+' /';
    capLine4b.Caption:=Float2Str(capFPS2)+' =';
    capLine4.Caption:=Float2Str(capFPS3)+' fps';

    if not have_img then
      begin
      PaintTimerTimer(nil);
      if AutoRefresh then
        begin
        CaptureTimer.Interval:=30;
        CaptureTimer.Enabled:=True;
        end;
      Exit;
      end
    else if not ImgEncoder.BitmapChanged then
      begin
      PaintTimerTimer(nil);
      if AutoRefresh then
        begin
        CaptureTimer.Interval:=30;
        CaptureTimer.Enabled:=True;
        end;
      Exit;
      end;

    lblScreenInfo.Caption:=IntToStr(ImgEncoder.NewBmpInfo.Width)+' * '+IntToStr(ImgEncoder.NewBmpInfo.Height);

    if xConfig.Checked then
      MainPanel.Update;

    if curData>0 then
      begin
      Inc(nowData,curData);
      if not xSplitData.Checked then
        Inc(CompStage);
      end
    else
      Inc(CompStage);
    end;

  if CompStage=1 then
    begin
    // Motion compress ...

    t0:=GetTickCount;

    mot1Time:=t0;
    mot1Storage:=ImgEncoder.CompressMOT;
    mot1Data:=length(mot1Storage);

    t0:=GetTickCount;

    mot1Time:=t0-mot1Time;
    if mot1Time<=0 then
      mot1FPS1:=99.99
    else
      mot1FPS1:=round(100000/mot1Time)/100;
    mot1FPS2:=CalcFPS(mot1Data);
    if mot1FPS1<mot1FPS2 then
      mot1FPS3:=mot1FPS1
    else
      mot1FPS3:=mot1FPS2;

    if mot1Data>0 then
      begin
      mot1Time2:=t0;
        ImgDecoder.Decompress(mot1Storage,bmp3Info);
      t0:=GetTickCount;
      mot1Time2:=t0-mot1Time2;
      end
    else
      mot1Time2:=0;

    mot1LineKb.Caption:=IntToStr(mot1Data div 125)+' Kbit';
    mot1Line2a.Caption:=IntToStr(mot1Time)+' ms';
    mot1Line3a.Caption:=IntToStr(mot1Time2)+' ms';
    mot1Line4a.Caption:=Float2Str(mot1FPS1)+' /';
    mot1Line4b.Caption:=Float2Str(mot1FPS2)+' =';
    mot1Line4.Caption:=Float2Str(mot1FPS3)+' fps';

    Inc(totData,mot1Data);
    Inc(totTime,mot1Time);
    Inc(totTime2,mot1Time2);

    if mot1Data>0 then
      begin
      Inc(nowData,mot1Data);
      if not xSplitData.Checked then
        Inc(CompStage);
      end
    else
      Inc(CompStage);
    end;

  if CompStage=2 then
    begin
    // JPG compress ...

    t0:=GetTickCount;

    jpgTime:=t0;
    jpgStorage:=ImgEncoder.CompressJPG;
    jpgData:=length(jpgStorage);

    t0:=GetTickCount;

    jpgTime:=t0-jpgTime;
    if jpgTime<=0 then
      jpgFPS1:=99.99
    else
      jpgFPS1:=round(100000/jpgTime)/100;
    jpgFPS2:=CalcFPS(jpgData);
    if jpgFPS1<jpgFPS2 then
      jpgFPS3:=jpgFPS1
    else
      jpgFPS3:=jpgFPS2;

    if jpgData>0 then
      begin
      jpgTime2:=t0;
        ImgDecoder.Decompress(jpgStorage,bmp3Info);
      t0:=GetTickCount;
      jpgTime2:=t0-jpgTime2;
      end
    else
      jpgTime2:=0;

    jpgLineKb.Caption:=IntToStr(jpgData div 125)+' Kbit';
    jpgLine2a.Caption:=IntToStr(jpgTime)+' ms';
    jpgLine3a.Caption:=IntToStr(jpgTime2)+' ms';
    jpgLine4a.Caption:=Float2Str(jpgFPS1)+' /';
    jpgLine4b.Caption:=Float2Str(jpgFPS2)+' =';
    jpgLine4.Caption:=Float2Str(jpgFPS3)+' fps';

    Inc(totData,jpgData);
    Inc(totTime,jpgTime);
    Inc(totTime2,jpgTime2);

    if jpgData>0 then
      begin
      Inc(nowData,jpgData);
      if not xSplitData.Checked then
        Inc(CompStage);
      end
    else
      Inc(CompStage);
    end;

  if CompStage=3 then
    begin
    // RLE compress ...

    t0:=GetTickCount;

    rleTime:=t0;
    rleStorage:=ImgEncoder.CompressRLE;
    rleData:=length(rleStorage);

    t0:=GetTickCount;

    rleTime:=t0-rleTime;
    if rleTime<=0 then
      rleFPS1:=99.99
    else
      rleFPS1:=round(100000/rleTime)/100;
    rleFPS2:=CalcFPS(rleData);
    if rleFPS1<rleFPS2 then
      rleFPS3:=rleFPS1
    else
      rleFPS3:=rleFPS2;

    if rleData>0 then
      begin
      rleTime2:=t0;
        ImgDecoder.Decompress(rleStorage,bmp3Info);
      t0:=GetTickCount;
      rleTime2:=t0-rleTime2;
      end
    else
      rleTime2:=0;

    rleLineKb.Caption:=IntToStr(rleData div 125)+' Kbit';
    rleLine2a.Caption:=IntToStr(rleTime)+' ms';
    rleLine3a.Caption:=IntToStr(rleTime2)+' ms';
    rleLine4a.Caption:=Float2Str(rleFPS1)+' /';
    rleLine4b.Caption:=Float2Str(rleFPS2)+' =';
    rleLine4.Caption:=Float2Str(rleFPS3)+' fps';

    if rleData>0 then
      Inc(nowData,rleData);

    // Calculate totals ...

    Inc(totData,rleData);
    Inc(totTime,rleTime);
    Inc(totTime2,rleTime2);

    if totTime<=0 then
      totFPS1:=99.99
    else
      totFPS1:=round(100000/totTime)/100;
    totFPS2:=CalcFPS(totData);
    if totFPS1<totFPS2 then
      totFPS3:=totFPS1
    else
      totFPS3:=totFPS2;

    totLineKb.Caption:=IntToStr(totData div 125)+' Kbit';
    totLine2a.Caption:=IntToStr(totTime)+' ms';
    totLine3a.Caption:=IntToStr(totTime2)+' ms';
    totLine4a.Caption:=Float2Str(totFPS1)+' /';
    totLine4b.Caption:=Float2Str(totFPS2)+' =';
    totLine4.Caption:=Float2Str(totFPS3)+' fps';
    end;

  Inc(CompStage);
  if CompStage>3 then
    CompStage:=0;

  // Clear Screen capture buffers

  SetLength(mot1Storage,0);
  SetLength(mot2Storage,0);
  SetLength(jpgStorage,0);
  SetLength(rleStorage,0);
  SetLength(curStorage,0);

  if nowData=0 then
    Delay:=1
  else
    begin
    case xBandwidth.ItemIndex of
      0:Delay:=8 * nowData div 32;
      1:Delay:=8 * nowData div 64;
      2:Delay:=8 * nowData div 128;
      3:Delay:=8 * nowData div 256;
      4:Delay:=8 * nowData div 512;
      5:Delay:=8 * nowData div 1000;
      6:Delay:=8 * nowData div 2000;
      7:Delay:=8 * nowData div 4000;
      8:Delay:=8 * nowData div 8000;
      9:Delay:=8 * nowData div 16000;
      else Delay:=1;
      end;
    end;

  // Trigger Repaint or next Screen capture

  if Delay<1 then Delay:=1;
  PaintTimer.Interval:=Delay;
  PaintTimer.Enabled:=True;
  end;

procedure TForm1.FormCreate(Sender: TObject);
  begin
{
  SetWindowLong(Handle, GWL_EXSTYLE,
                GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_LAYERED or
                WS_EX_TRANSPARENT or WS_EX_TOPMOST);
  SetLayeredWindowAttributes(Handle, 0,
            Trunc((255 / 100) * (100 - 0)), LWA_ALPHA);
}
  if not xConfig.Checked then
    begin
    MainPanel.ClientWidth:=SubPanel.Width;
    MainPanel.ClientHeight:=SubPanel.Height;
    end;
    
  ClientWidth:=MainPanel.Width;
  ClientHeight:=MainPanel.Height;

  AutoRefresh:=False;

  xWinAero.Checked:=CurrentAero;

  LDown:=False;
  RDown:=False;
  MDown:=False;
  
  bmp3Info:=NewBitmapInfo(True);
  bmp4:=nil;
  bmp5:=nil;
  FrameTime:=0;

  ImgEncoder:=TRtcImageEncoder.Create(NewBitmapInfo(True));

  ImgDecoder:=TRtcImageDecoder.Create;
  end;

(*function BitmapToJSONString(bmp:TBitmap):RtcString;
var
  myRecord:TRtcRecord;
  myStream:TStream;
begin
myRecord := TRtcRecord.Create;
try
  myStream := myRecord.newByteStream('Image');
  bmp.SaveToStream( myStream );
  Result := myRecord.toJSON;
finally
  myRecord.Free;
  end;
end;*)

procedure TForm1.FormDestroy(Sender: TObject);
  begin
  //if assigned(bmp1) then
  //  Write_File('test.txt',BitmapToJSONString(bmp1));

  FreeAndNil(bmp4);
  FreeAndNil(bmp5);

  ReleaseBitmapInfo(bmp3Info);
  FrameTime:=0;

  FreeAndNil(ImgEncoder);
  FreeAndNil(ImgDecoder);
  end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
  var
    NowMousePos:TPoint;
  begin
  if assigned(bmp4) then
    begin
    PaintBox1.Width:=bmp4.Width;
    PaintBox1.Height:=bmp4.Height;

    // Local paint
    GetCursorPos(NowMousePos);
    PaintBox1.Canvas.Draw(0,0,bmp4);
    PaintCursor(ImgDecoder.Cursor, PaintBox1.Canvas, bmp4, NowMousePos.X-CaptureRectLeft, NowMousePos.Y-CaptureRectTop,True);
    end
  else
    begin
    PaintBox1.Canvas.Brush.Color:=Color;
    PaintBox1.Canvas.FillRect(Rect(0,0,PaintBox1.Width,PaintBox1.Height));
    end;
  end;

procedure TForm1.CaptureTimerTimer(Sender: TObject);
  begin
  CaptureTimer.Enabled:=False;
  CaptureClick(nil);
  end;

(*
type
  TMyForcedMemLeak=class(TObject);

initialization
TMyForcedMemLeak.Create;
*)

procedure TForm1.PaintTimerTimer(Sender: TObject);
  var
    FramePS:double;
  begin
  PaintTimer.Enabled:=False;
  if (CompStage=0) or xSplitData.Checked then
    begin
    if assigned(bmp3Info.Data) then
      begin
      if CompStage=0 then
        begin
        if FrameTime>0 then
          begin
          FrameTime:=GetTickCount-FrameTime;
          if FrameTime>0 then
            begin
            FramePS:=round(100000/FrameTime)/100;
            totLine5.Caption:=Float2Str(FramePS)+' fps';
            end;
          end;
        FrameTime:=GetTickCount;
        end;

      CopyInfoToBitmap(bmp3Info,bmp4);

      PaintBox1Paint(nil);
      end;
    end;
  if (CompStage>0) or AutoRefresh then
    begin
    CaptureTimer.Interval:=1;
    CaptureTimer.Enabled:=True;
    end
  else
    UpdateTimer.Enabled:=False;
  end;

procedure TForm1.xMirrorDriverClick(Sender: TObject);
  begin
  if xMirrorDriver.Enabled then
    if xMirrorDriver.Checked then
      begin
      if not EnableMirrorDriver then
        xMirrorDriver.Checked:=False;
      end
    else
      DisableMirrorDriver;
  end;

procedure TForm1.xWinAeroClick(Sender: TObject);
  begin
  if xWinAero.Enabled then
    if xWinAero.Checked<>CurrentAero then
      if xWinAero.Checked then
        EnableAero
      else
        DisableAero;
  end;

procedure TForm1.xConfigClick(Sender: TObject);
  begin
  if not xConfig.Checked then
    begin
    MainPanel.ClientWidth:=SubPanel.Width;
    MainPanel.ClientHeight:=SubPanel.Height;
    end
  else
    begin
    MainPanel.ClientWidth:=xBandwidth.Left+xBandwidth.Width+5;
    MainPanel.ClientHeight:=xBandwidth.Top+xBandwidth.Height+5;
    end;
  if ClientWidth<MainPanel.Width then
    ClientWidth:=MainPanel.Width;
  if ClientHeight<MainPanel.Height then
    ClientHeight:=MainPanel.Height;
  FormResize(nil);
  end;

procedure TForm1.UpdateTimerTimer(Sender: TObject);
  begin
  PaintBox1Paint(nil);
  end;

function TForm1.GetCaptureWindow:HWND;
  begin
  if eWindowCaption.ItemIndex>0 then
    begin
    Result:=WinHdls[eWindowCaption.ItemIndex];
    if not IsWindowVisible(Result) then
      begin
      xWindowCaptureClick(nil);
      eWindowCaption.ItemIndex:=0;
      Result:=WinHdls[eWindowCaption.ItemIndex];
      end;
    end
  else
    Result := GetDesktopWindow;
  end;

procedure TForm1.PostMouseMessage(Msg:Cardinal; MouseX, MouseY: integer);
  var
    chdl,
    hdl:HWND;
    wpt,pt:TPoint;
    r:TRect;
  begin
  pt.X:=MouseX+CaptureRectLeft;
  pt.Y:=MouseY+CaptureRectTop;
  wpt:=pt;

  if eWindowCaption.ItemIndex>0 then
    begin
    hdl:=GetCaptureWindow;
    if IsWindow(hdl) then
      begin
      GetWindowRect(hdl,r);
      repeat
        pt.X:=wpt.X-r.Left;
        pt.Y:=wpt.Y-r.Top;
        chdl:=ChildWindowFromPointEx(hdl,pt,1+4);
        if not IsWindow(chdl) then
          Break
        else if chdl=hdl then
          Break
        else
          begin
          GetWindowRect(chdl,r);
          if (wpt.x>=r.left) and (wpt.x<=r.right) and
             (wpt.y>=r.top) and (wpt.y<=r.bottom) then
            hdl:=chdl
          else
            Break;
          end;
        until False;
      end;
    end
  else
    hdl:=WindowFromPoint(pt);

  if IsWindow(hdl) then
    begin
    pt:=wpt;
    Windows.ScreenToClient(hdl,pt);
    {GetWindowRect(hdl,r);
    pt.x:=wpt.X-r.left;
    pt.y:=wpt.Y-r.Top;}
    PostMessageA(hdl,msg,0,MakeLong(pt.X,pt.Y));
    end;
  end;

procedure TForm1.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  case Button of
    mbLeft:
      begin
      PostMouseMessage(WM_LBUTTONDOWN,X,Y);
      LDown:=True;
      end;
    mbRight:
      begin
      PostMouseMessage(WM_RBUTTONDOWN,X,Y);
      RDown:=True;
      end;
    mbMiddle:
      begin
      PostMouseMessage(WM_MBUTTONDOWN,X,Y);
      MDown:=True;
      end;
    end;
end;

procedure TForm1.PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  case Button of
    mbLeft:
      begin
      PostMouseMessage(WM_LBUTTONUP,X,Y);
      LDown:=False;
      end;
    mbRight:
      begin
      PostMouseMessage(WM_RBUTTONUP,X,Y);
      RDown:=False;
      end;
    mbMiddle:
      begin
      PostMouseMessage(WM_MBUTTONUP,X,Y);
      MDown:=False;
      end;
    end;
end;

procedure TForm1.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  var
    PX,PY:integer;
  begin
  if AutoRefresh then
    begin
    PX:=X-ScrollBox1.HorzScrollBar.Position;
    PY:=Y-ScrollBox1.VertScrollBar.Position;
    if xAutoHide.Checked and
      ( (PX<MainPanel.Left) or
        (PX>MainPanel.Left+MainPanel.Width) or
        (PY<0) or
        (PY>MainPanel.Top+MainPanel.Height) ) then
      begin
      if MainPanel.Visible then
        MainPanel.Hide;
      end
    else if not MainPanel.Visible then
      MainPanel.Show;
    end
  else if not MainPanel.Visible then
    MainPanel.Show;

  if LDown or RDown or MDown then
    PostMouseMessage(WM_MOUSEMOVE,X,Y);
  end;

procedure TForm1.xMaintenanceFormClick(Sender: TObject);
  begin
  if xMaintenanceForm.Checked then
    begin
    if (Left+ClientWidth>0) and (Top+ClientHeight>0) and (Left<GetScreenWidth) and (Top<GetScreenHeight) then
      begin
      xMaintenanceForm.Checked:=False;
      ShowMessage('Move the Main Form to your Secondary Monitor'#13#10+
                  'before you enable the "Maintenance" mode.');
      end
    else
      begin
      xWinAero.Enabled:=False;
      xLayeredWindows.Enabled:=False;
      xMirrorDriver.Enabled:=False;
      DisableMirrorDriver;
      DisableAero;
      BlankOutScreen(False);
      WindowState:=wsMaximized;
      if not AutoRefresh then
        btnCapture.Click;
      BringToFront;
      end;
    end
  else if not xWinAero.Enabled then
    begin
    xWinAero.Enabled:=True;
    xLayeredWindows.Enabled:=True;
    xMirrorDriver.Enabled:=True;
    if xWinAero.Checked then
      EnableAero;
    if xMirrorDriver.Checked then
      EnableMirrorDriver;
    RestoreScreen;
    end;
  end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
  begin
  if (Key=#27) and xMaintenanceForm.Checked then
    xMaintenanceForm.Checked:=False;
  end;

procedure TForm1.xWindowCaptureClick(Sender: TObject);
  var
    desk,mh,ch:HWND;
    capt:array[1..255] of Char;
    caps:String;
    clen,i:integer;
    r:TRect;
  begin
  eWindowCaption.Items.Clear;
  SetLength(WinHdls,0);
  desk:=GetDesktopWindow;

  SetLength(WinHdls,1);
  WinHdls[0]:=desk;
  eWindowCaption.Items.Add('Desktop');

  mh:=0;

  ch:=0;
  repeat
    ch:=FindWindowExA(mh,ch,nil,nil);
    if ch<>0 then
      begin
      if IsWindow(ch) and IsWindowVisible(ch) and (ch<>desk) and (ch<>handle) then
        begin
        Windows.GetClientRect(ch,r);
        if (r.Right-r.Left>0) and
           (r.Bottom-r.Top>0) then
          begin
          Windows.GetWindowRect(ch,r);
          SetLength(WinHdls,length(WinHdls)+1);
          WinHdls[length(WinHdls)-1]:=ch;

          clen:=GetWindowText(ch,@capt,254);
          caps:='';
          for i:=1 to clen do
            caps:=caps+capt[i];

          clen:=GetClassName(ch,@capt,254);
          caps:=caps+' | ';
          for i:=1 to clen do
            caps:=caps+capt[i];

          caps:=caps+' ('+IntToStr(r.Left)+','+IntToStr(r.Top)+
                    ')-('+IntToStr(r.Right)+','+IntToStr(r.Bottom)+')';
          eWindowCaption.Items.Add(caps);
          end;
        end;
      end;
    until ch=0;

{
  mh:=desk;

  ch:=0;
  repeat
    ch:=FindWindowExA(mh,ch,nil,nil);
    if ch<>0 then
      begin
      if IsWindowVisible(ch) and (ch<>Handle) then
        begin
        Windows.GetClientRect(ch,r);
        if (r.Right-r.Left>0) and
           (r.Bottom-r.Top>0) then
          begin
          Windows.GetWindowRect(ch,r);
          SetLength(WinHdls,length(WinHdls)+1);
          WinHdls[length(WinHdls)-1]:=ch;

          clen:=GetWindowText(ch,@capt,254);
          caps:='';
          for i:=1 to clen do
            caps:=caps+capt[i];

          clen:=GetClassName(ch,@capt,254);
          caps:=caps+' | ';
          for i:=1 to clen do
            caps:=caps+capt[i];

          caps:=caps+' ('+IntToStr(r.Left)+','+IntToStr(r.Top)+
                    ')-('+IntToStr(r.Right)+','+IntToStr(r.Bottom)+')';
          eWindowCaption.Items.Add(caps);
          end;
        end;
      end;
    until ch=0;
}
  end;

procedure TForm1.FormResize(Sender: TObject);
  begin
  MainPanel.Left:=ClientWidth-MainPanel.Width;
  end;

end.
