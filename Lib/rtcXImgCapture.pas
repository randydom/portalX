{
  "Image Capture Link"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcXImgCapture;

interface

{$include rtcDefs.inc}

uses
  Classes,
  SysUtils,

  rtcTypes,
  rtcThrPool,
  rtcConn,
  rtcInfo,

  rtcGateConst,
  rtcGateCli,

  rtcXBmpUtils,
  rtcXImgEncode,

  rtcXGateCIDs,
  rtcXGateStream;

type
  { @Abstract(RTC Image Capture Link)
    Link this component to a TRtcHttpGateClient to handle Image Capture events. }
  TRtcImageCaptureLink = class(TRtcGateStreamerLink)
  private
    ParamsChangedImg,
    ParamsChangedVid:boolean;

    //ParamsChangedImg
    FMotionComp:boolean; // True
    FColorComp:boolean; // False
    FJPGCompress:boolean; // True
    FRLECompress:boolean; // True
    FLZWCompress:boolean; // True

    FMotionHorzScan:integer; // 1 (0 .. 11)
    FMotionVertScan:integer; // 1 (0 .. 11)
    FMotionFullScan:integer; // 1 (0 .. 11)

    FColorReduce:boolean; // False
    FColorDepth:byte; // 6 (1 .. 8)

    FJPEG_QLevelLum:integer; // 80 (0 .. 120)
    FJPEG_QLevelCol:integer; // 60 (0 .. 120)
    FJPEG_HQDepth:integer; // 0=disabled (0 .. 5)
    FJPEG_HQColor:boolean; // False

    //ParamsChangedVid
    FVideoBufferSize:integer; // 11 (0 .. 13)
    FScreenCaptureRate:integer; // 11 (0 .. 13)
    FMouseCaptureRate:integer; // 11 (0 .. 13)

    procedure SetColorComp(const Value: boolean);
    procedure SetMotionComp(const Value: boolean);
    procedure SetJPGCompress(const Value: boolean);
    procedure SetRLECompress(const Value: boolean);
    procedure SetLZWCompress(const Value: boolean);

    procedure SetColorDepth(const Value: byte);
    procedure SetColorReduce(const Value: boolean);
    procedure SetJPEG_HQColor(const Value: boolean);
    procedure SetJPEG_HQDepth(const Value: integer);
    procedure SetJPEG_QLevelCol(const Value: integer);
    procedure SetJPEG_QLevelLum(const Value: integer);

    procedure SetMotionFullScan(const Value: integer);
    procedure SetMotionHorzScan(const Value: integer);
    procedure SetMotionVertScan(const Value: integer);

    procedure SetVideoBufferSize(const Value: integer);
    procedure SetMouseCaptureRate(const Value: integer);
    procedure SetScreenCaptureRate(const Value: integer);

  protected
    ImgEncoder: TRtcImageEncoder;
    ScreenCap: TRtcQuickJob;
    ControlJob: TRtcQuickJob;

    InsideMyEvent:boolean;

    NextFullFrame,
    NextMouseFrame:LongWord;

    FrameTime,
    MouseTime,
    VideoTime:word;

    InitialCursor:boolean;

    CompStage:integer;

    // @exclude
    procedure Call_OnDataReceived(Sender:TRtcConnection); override;

    procedure DoDataFilter(Client:TRtcHttpGateClient; Data:TRtcGateClientData; var Wanted:boolean);
    procedure DoDataReceived(Client:TRtcHttpGateClient; Data:TRtcGateClientData; var WantGUI, WantBackThread:boolean);

    procedure ScreenCapExecute(Data:TRtcValue);
    procedure ControlJobExecute(Data:TRtcValue);

    procedure DoSendStart; override;
    procedure DoSendNext; override;
    procedure DoSendStop; override;

  protected
    function CreateImageEncoder:TRtcImageEncoder; virtual; abstract;
    function CaptureMouseInitial:RtcByteArray; virtual; abstract;
    function CaptureMouseDelta:RtcByteArray; virtual; abstract;
    function CaptureImage:boolean; virtual; abstract;

    procedure ResetParamsChanged; virtual;
    procedure UpdateChangedParams; virtual;
    procedure CaptureImageFailCheck; virtual;
    procedure MouseControlExecute(Data:TRtcValue); virtual;

  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

  published
    //ParamsChangedImg
    property ColorDepth:byte read FColorDepth write SetColorDepth default 6; // 1 .. 8
    property ColorReduce:boolean read FColorReduce write SetColorReduce default False;

    property CompressMotion:boolean read FMotionComp write SetMotionComp default True;
    property CompressDraft:boolean read FColorComp write SetColorComp default False;
    property CompressJPEG:boolean read FJPGCompress write SetJPGCompress default True;
    property CompressRLE:boolean read FRLECompress write SetRLECompress default True;
    property CompressLZW:boolean read FLZWCompress write SetLZWCompress default True;

    property GrabFrameBuffer:integer read FVideoBufferSize write SetVideoBufferSize default 11; // 0 .. 13
    property GrabMouseRate:integer read FMouseCaptureRate write SetMouseCaptureRate default 11; // 0 .. 13
    property GrabScreenRate:integer read FScreenCaptureRate write SetScreenCaptureRate default 11; // 0 .. 13

    property JPEGColorLevel:integer read FJPEG_QLevelCol write SetJPEG_QLevelCol default 60; // 0 .. 120
    property JPEGDetailLevel:integer read FJPEG_QLevelLum write SetJPEG_QLevelLum default 80; // 0 .. 120
    property JPEGHiQColor:boolean read FJPEG_HQColor write SetJPEG_HQColor default False;
    property JPEGHiQDepth:integer read FJPEG_HQDepth write SetJPEG_HQDepth default 0; // 0 .. 5

    property MotionHorzScan:integer read FMotionHorzScan write SetMotionHorzScan default 1; // 0 .. 11
    property MotionVertScan:integer read FMotionVertScan write SetMotionVertScan default 1; // 0 .. 11
    property MotionFullScan:integer read FMotionFullScan write SetMotionFullScan default 1; // 0 .. 11
    end;

implementation

{ TRtcImageCaptureLink }

procedure TRtcImageCaptureLink.DoSendStart;
  begin
  if ImgEncoder=nil then
    begin
    InsideMyEvent:=False;

    ImgEncoder:=CreateImageEncoder;

    ScreenCap:=TRtcQuickJob.Create(nil);
    ScreenCap.Serialized:=True;
    ScreenCap.OnExecute:=ScreenCapExecute;

    ControlJob:=TRtcQuickJob.Create(nil);
    ControlJob.Serialized:=True;
    ControlJob.OnExecute:=ControlJobExecute;

    ResetParamsChanged;
    end;
  end;

procedure TRtcImageCaptureLink.DoSendNext;
  begin
  if assigned(ScreenCap) then
    ScreenCap.Post(nil);
  end;

procedure TRtcImageCaptureLink.DoSendStop;
  begin
  if assigned(ImgEncoder) then
    begin
    ControlJob.Stop;
    ScreenCap.Stop;

    repeat Sleep(100);
      until InsideMyEvent=False;

    RtcFreeAndNil(ControlJob);
    RtcFreeAndNil(ScreenCap);
    RtcFreeAndNil(ImgEncoder);
    end;
  end;

constructor TRtcImageCaptureLink.Create(AOwner: TComponent);
  begin
  inherited;

  // IMPORTANT !!!
  cid_GroupInvite:=cid_ImageInvite;

  ResetParamsChanged;

  FMotionComp:=True;
  FColorComp:=False;
  FJPGCompress:=True;
  FRLECompress:=True;
  FLZWCompress:=True;

  FMotionHorzScan:=1;
  FMotionVertScan:=1;
  FMotionFullScan:=1;

  FColorReduce:=False;
  FColorDepth:=6;

  FJPEG_QLevelLum:=80;
  FJPEG_QLevelCol:=60;
  FJPEG_HQDepth:=0;
  FJPEG_HQColor:=False;

  FScreenCaptureRate:=11;
  FMouseCaptureRate:=11;
  FVideoBufferSize:=11;

  InsideMyEvent:=False;

  ImgEncoder:=nil;
  ScreenCap:=nil;
  ControlJob:=nil;
  end;

destructor TRtcImageCaptureLink.Destroy;
  begin
  inherited;
  end;

procedure TRtcImageCaptureLink.ScreenCapExecute(Data: TRtcValue);
  var
    newMouse:RtcByteArray;

    curStorage,
    motStorage,
    jpgStorage,
    rleStorage:RtcByteArray;

    btmp:TRtcBitmapInfo;

    have_img:boolean;

    gtt:LongWord;

  begin
  InsideMyEvent:=True;
  try
    if (Client=nil) or
       (SendingPaused=True) or
       (SendingStream=False) then Exit;

    if not Client.Ready then Exit;

    if SendingFirst then
      begin
      SendingFirst:=False;
      InitialCursor:=True;
      ResetParamsChanged;
      NextFullFrame:=0;
      NextMouseFrame:=0;
      CompStage:=0;
      end;

    if CompStage=0 then
      begin

      UpdateChangedParams;

      if (LastPackDiff>VideoTime) and not InitialCursor then // max Video Frames difference
        begin
        // Force a delay before next screen capture
        Sleep(5);
        if (Client<>nil) and
           (SendingPaused=False) and
           (SendingStream=True) then
          DoSendNext;
        Exit;
        end;

      gtt:=GetTickTime;

      if gtt>=NextMouseFrame then
        begin
        NextMouseFrame := gtt + MouseTime;
        if InitialCursor then
          newMouse:=CaptureMouseInitial
        else
          newMouse:=CaptureMouseDelta;

        if InitialCursor then
          begin
          InitialCursor:=False;
          NextFullFrame:=gtt;

          ImgEncoder.FirstFrame;

          Client.SendBytes(Client.MyUID,MyGroupID,cid_ImageStart);
          end;

        if length(newMouse)>0 then
          begin
          curStorage:=ImgEncoder.CompressMouse(newMouse);
          Client.SendBytes(Client.MyUID,MyGroupID,cid_ImageMouse,curStorage);

          SetLength(curStorage,0);
          SetLength(newMouse,0);

          if gtt<NextFullFrame then
            Exit; // wait for "ReadyToSend"
          end;
        end;

      if gtt<NextFullFrame then // Max Screen Frame difference
        begin
        // Force a delay before next screen capture
        Sleep(5);
        if (Client<>nil) and
           (SendingPaused=False) and
           (SendingStream=True) then
          DoSendNext;
        Exit;
        end
      else
        NextFullFrame:=gtt + FrameTime;

      // Capture the Screen

      have_img:=CaptureImage;
      if have_img then
        begin
        FillChar(btmp,SizeOf(btmp),0);
        btmp:=ImgEncoder.OldBmpInfo;
        ImgEncoder.OldBmpInfo:=ImgEncoder.NewBmpInfo;
        ImgEncoder.NewBmpInfo:=btmp;
        FillChar(btmp,SizeOf(btmp),0);

        ImgEncoder.ReduceColors(ImgEncoder.NewBmpInfo);
        if not ImgEncoder.BitmapChanged then
          begin
          CaptureImageFailCheck;
          if (Client<>nil) and
             (SendingPaused=False) and
             (SendingStream=True) then
            DoSendNext;
          Exit;
          end;
        end
      else
        begin
        CaptureImageFailCheck;
        if (Client<>nil) and
           (SendingPaused=False) and
           (SendingStream=True) then
          DoSendNext;
        Exit;
        end;

      Inc(CompStage);
      end;

    if CompStage=1 then
      begin
      // Motion compress ...
      motStorage:=ImgEncoder.CompressMOT;

      Inc(CompStage);
      if length(motStorage)>0 then
        begin
        Client.SendBytes(Client.MyUID,MyGroupID,cid_ImageData,motStorage);
        SetLength(motStorage,0);
        Exit;
        end;
      end;

    if CompStage=2 then
      begin
      // JPG compress ...
      jpgStorage:=ImgEncoder.CompressJPG;

      Inc(CompStage);
      if length(jpgStorage)>0 then
        begin
        Client.SendBytes(Client.MyUID,MyGroupID,cid_ImageData,jpgStorage);
        SetLength(jpgStorage,0);
        Exit;
        end;
      end;

    if CompStage=3 then
      begin
      // RLE compress ...
      rleStorage:=ImgEncoder.CompressRLE;

      Inc(CompStage);
      if length(rleStorage)>0 then
        begin
        Client.SendBytes(Client.MyUID,MyGroupID,cid_ImageData,rleStorage);
        SetLength(rleStorage,0);
        Exit;
        end;
      end;

    if CompStage=4 then
      begin
      CompStage:=0;
      ImgEncoder.FrameComplete;
      ConfirmPackSent;
      end;

  finally
    InsideMyEvent:=False;
    end;
  end;

procedure TRtcImageCaptureLink.ControlJobExecute(Data: TRtcValue);
  begin
  if Client=nil then Exit;

  MouseControlExecute(Data);
  end;

procedure TRtcImageCaptureLink.SetRLECompress(const Value: boolean);
  begin
  FRLECompress := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetColorComp(const Value: boolean);
  begin
  FColorComp := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetColorDepth(const Value: byte);
  begin
  FColorDepth := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetColorReduce(const Value: boolean);
  begin
  FColorReduce := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetJPEG_HQColor(const Value: boolean);
  begin
  FJPEG_HQColor := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetJPEG_HQDepth(const Value: integer);
  begin
  FJPEG_HQDepth := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetJPEG_QLevelCol(const Value: integer);
  begin
  FJPEG_QLevelCol := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetJPEG_QLevelLum(const Value: integer);
  begin
  FJPEG_QLevelLum := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetJPGCompress(const Value: boolean);
  begin
  FJPGCompress := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetLZWCompress(const Value: boolean);
  begin
  FLZWCompress := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetMotionComp(const Value: boolean);
  begin
  FMotionComp := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetMotionFullScan(const Value: integer);
  begin
  FMotionFullScan := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetMotionHorzScan(const Value: integer);
  begin
  FMotionHorzScan := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetMotionVertScan(const Value: integer);
  begin
  FMotionVertScan := Value;
  ParamsChangedImg:=True;
  end;

procedure TRtcImageCaptureLink.SetMouseCaptureRate(const Value: integer);
  begin
  FMouseCaptureRate := Value;
  ParamsChangedVid:=True;
  end;

procedure TRtcImageCaptureLink.SetScreenCaptureRate(const Value: integer);
  begin
  FScreenCaptureRate := Value;
  ParamsChangedVid:=True;
  end;

procedure TRtcImageCaptureLink.SetVideoBufferSize(const Value: integer);
  begin
  FVideoBufferSize := Value;
  ParamsChangedVid:=True;
  end;

procedure TRtcImageCaptureLink.ResetParamsChanged;
  begin
  ParamsChangedImg:=True;
  ParamsChangedVid:=True;
  end;

procedure TRtcImageCaptureLink.UpdateChangedParams;
  var
    HqLevelLum,HqLevelCol:word;
    HqDepth:byte;
  begin
  if ParamsChangedImg then
    begin
    ParamsChangedImg:=False;

    // Prepare Screen capture parameters
    ImgEncoder.MotionComp:=FMotionComp;
    ImgEncoder.ColorComp:=FColorComp;

    ImgEncoder.MotionHorzScan:= FMotionHorzScan>0;
    ImgEncoder.MotionVertScan:= FMotionVertScan>0;
    ImgEncoder.MotionFullScan:= FMotionFullScan>0;

    if FMotionHorzScan>0 then
      ImgEncoder.MotionHorzScanLimit:=(FMotionHorzScan-1)*100
    else
      ImgEncoder.MotionHorzScanLimit:=0;

    if FMotionVertScan>0 then
      ImgEncoder.MotionVertScanLimit:=(FMotionVertScan-1)*100
    else
      ImgEncoder.MotionVertScanLimit:=0;

    if FMotionFullScan>0 then
      ImgEncoder.MotionFullScanLimit:=(FMotionFullScan-1)*100
    else
      ImgEncoder.MotionFullScanLimit:=0;

    if FColorReduce then
      begin
      ImgEncoder.ColorBitsR:=FColorDepth;
      ImgEncoder.ColorBitsG:=FColorDepth;
      ImgEncoder.ColorBitsB:=FColorDepth;
      ImgEncoder.ColorReduce:=0;
      end
    else
      begin
      ImgEncoder.ColorBitsR:=8;
      ImgEncoder.ColorBitsG:=8;
      ImgEncoder.ColorBitsB:=8;
      ImgEncoder.ColorReduce:=(8-FColorDepth)*2;
      end;

    ImgEncoder.JPGCompress:=FJPGCompress;
    ImgEncoder.RLECompress:=FRLECompress;
    ImgEncoder.LZWCompress:=FLZWCompress;

    if ImgEncoder.JPGCompress then
      begin
      if FJPEG_HQDepth>0 then
        begin
        HqLevelLum:=FJPEG_QLevelLum;
        HqLevelCol:=FJPEG_QLevelCol;
        end
      else
        begin
        HqLevelLum:=0;
        HqLevelCol:=0;
        end;
      HqDepth:=255;
      case FJPEG_HQDepth of
        2:HqDepth:=240;
        3:HqDepth:=120;
        4:HqDepth:=80;
        5:HqDepth:=60;
        end;
      ImgEncoder.QLevelLum:=FJPEG_QLevelLum;
      ImgEncoder.QLevelCol:=FJPEG_QLevelCol;
      ImgEncoder.HQLevelLum:=HqLevelLum;
      ImgEncoder.HQLevelCol:=HqLevelCol;
      ImgEncoder.HQDepth:=HqDepth;
      ImgEncoder.HQColor:=FJPEG_HQColor;
      end;
    end;

  if ParamsChangedVid then
    begin
    ParamsChangedVid:=False;
    case FScreenCaptureRate of
      13: FrameTime:=14; // 60 FPS
      12: FrameTime:=30; // 30 FPS
      11: FrameTime:=46; // 21 FPS
      10: FrameTime:=62; // 16 FPS
      9: FrameTime:=78; // 13 FPS
      8: FrameTime:=94; // 10 FPS
      7: FrameTime:=110; // 9 FPS
      6: FrameTime:=125; // 8 FPS
      5: FrameTime:=158; // 6 FPS
      4: FrameTime:=190; // 5 FPS
      3: FrameTime:=238; // 4 FPS
      2: FrameTime:=318; // 3 FPS
      1: FrameTime:=500; // 2 FPS
      0: FrameTime:=1000; // 1 FPS
      end;

    case FMouseCaptureRate of
      13: MouseTime:=14; // 60 FPS
      12: MouseTime:=30; // 30 FPS
      11: MouseTime:=46; // 21 FPS
      10: MouseTime:=62; // 16 FPS
      9: MouseTime:=78; // 13 FPS
      8: MouseTime:=94; // 10 FPS
      7: MouseTime:=110; // 9 FPS
      6: MouseTime:=125; // 8 FPS
      5: MouseTime:=158; // 6 FPS
      4: MouseTime:=190; // 5 FPS
      3: MouseTime:=238; // 4 FPS
      2: MouseTime:=318; // 3 FPS
      1: MouseTime:=500; // 2 FPS
      0: MouseTime:=1000; // 1 FPS
      end;

    if FVideoBufferSize<13 then
      VideoTime:=FVideoBufferSize
    else
      VideoTime:=128;
    end;
  end;

procedure TRtcImageCaptureLink.CaptureImageFailCheck;
  begin
  //
  end;

procedure TRtcImageCaptureLink.MouseControlExecute(Data: TRtcValue);
  begin
  //
  end;

procedure TRtcImageCaptureLink.DoDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: boolean);
  begin
  case Data.CallID of
    cid_ControlMouseDown,
    cid_ControlMouseMove,
    cid_ControlMouseUp,
    cid_ControlMouseWheel,
    cid_ControlKeyDown,
    cid_ControlKeyUp:
      if Data.Footer then
        Wanted:=IsControlPackage(Data)
      else if Data.Header then
        Wanted:=IsControlPackage(Data);
    end;
  end;

procedure TRtcImageCaptureLink.DoDataReceived(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var WantGUI, WantBackThread: boolean);
  procedure ProcessKeyDown;
    var
      rec:TRtcRecord;
    begin
    if (length(Data.Content)<>2) then Exit;

    rec:=TRtcRecord.Create;
    rec.asInteger['C']:=cid_ControlKeyDown;
    rec.asInteger['K']:=Bytes2Word(Data.Content);
    rec.asCardinal['A']:=Data.UserID;
    ControlJob.Post(rec);
    end;
  procedure ProcessKeyUp;
    var
      rec:TRtcRecord;
    begin
    if (length(Data.Content)<>2) then Exit;

    rec:=TRtcRecord.Create;
    rec.asInteger['C']:=cid_ControlKeyUp;
    rec.asInteger['K']:=Bytes2Word(Data.Content);
    rec.asCardinal['A']:=Data.UserID;
    ControlJob.Post(rec);
    end;
  procedure ProcessMouseDown;
    var
      rec:TRtcRecord;
    begin
    if (length(Data.Content)<>5) then Exit;

    rec:=TRtcRecord.Create;
    rec.asInteger['C']:=cid_ControlMouseDown;
    rec.asInteger['X']:=Bytes2Word(Data.Content);
    rec.asInteger['Y']:=Bytes2Word(Data.Content,2);
    rec.asInteger['B']:=Bytes2OneByte(Data.Content,4);
    rec.asCardinal['A']:=Data.UserID;
    ControlJob.Post(rec);
    end;
  procedure ProcessMouseMove;
    var
      rec:TRtcRecord;
    begin
    if (length(Data.Content)<>4) then Exit;

    rec:=TRtcRecord.Create;
    rec.asInteger['C']:=cid_ControlMouseMove;
    rec.asInteger['X']:=Bytes2Word(Data.Content);
    rec.asInteger['Y']:=Bytes2Word(Data.Content,2);
    rec.asCardinal['A']:=Data.UserID;
    ControlJob.Post(rec);
    end;
  procedure ProcessMouseUp;
    var
      rec:TRtcRecord;
    begin
    if (length(Data.Content)<>5) then Exit;

    rec:=TRtcRecord.Create;
    rec.asInteger['C']:=cid_ControlMouseUp;
    rec.asInteger['X']:=Bytes2Word(Data.Content);
    rec.asInteger['Y']:=Bytes2Word(Data.Content,2);
    rec.asInteger['B']:=Bytes2OneByte(Data.Content,4);
    rec.asCardinal['A']:=Data.UserID;
    ControlJob.Post(rec);
    end;
  procedure ProcessMouseWheel;
    var
      rec:TRtcRecord;
    begin
    if (length(Data.Content)<>2) then Exit;

    rec:=TRtcRecord.Create;
    rec.asInteger['C']:=cid_ControlMouseWheel;
    rec.asInteger['W']:=Bytes2Word(Data.Content) - 32768;
    rec.asCardinal['A']:=Data.UserID;
    ControlJob.Post(rec);
    end;
  begin
  case Data.CallID of
    cid_ControlMouseDown:   ProcessMouseDown;
    cid_ControlMouseMove:   ProcessMouseMove;
    cid_ControlMouseUp:     ProcessMouseUp;
    cid_ControlMouseWheel:  ProcessMouseWheel;
    cid_ControlKeyDown:     ProcessKeyDown;
    cid_ControlKeyUp:       ProcessKeyUp;
    end;
  end;

procedure TRtcImageCaptureLink.Call_OnDataReceived(Sender: TRtcConnection);
  begin
  if Filter(DoDataFilter,Sender) then
    Call(DoDataReceived,Sender);
  inherited;
  end;

end.
