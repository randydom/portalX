{
  "RTC Image Playback"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcXImgPlayback;

interface

{$include rtcDefs.inc}

uses
  Classes,
  SysUtils,

  rtcTypes,
  rtcConn,
  rtcSyncObjs,
  rtcThrPool,

  rtcFastStrings,
  rtcInfo,

  rtcGateConst,
  rtcGateCli,

  rtcXBmpUtils,
  rtcXImgDecode,

  rtcXGateCIDs,
  rtcXGateRecv;

type
  { @Abstract(RTC Image Playback Link)
    Link this component to a TRtcHttpGateClient to handle Image Playback events. }
  {$IFDEF IDE_XE2up}
  [ComponentPlatformsAttribute(pidAll)]
  {$ENDIF}
  TRtcImagePlayback=class(TRtcGateReceiverLink)
  protected
    LastReceiveID:word;

    PaintJob: TRtcQuickJob;
    PreparePaint: TRtcQuickJob;

    ImgDecoder:TRtcImageDecoder;

    FLastMouseX,
    FLastMouseY:integer;

    FImageWidth,
    FImageHeight:integer;

    Bmp3Data:array of RtcByteArray;
    Bmp3Info:TRtcBitmapInfo;
    Bmp3Lock:TRtcCritSec;

    img_OK, // Image initialized
    img_MouseChg, // mouse position or image changed
    img_Waiting, // waiting for Bmp3Info to be copied to Bmp4
    img_Posting, // PreparePaint has been called or is executing
    img_Painting, // PaintJob has been called or is executing
    img_Drawing, // Repaint has been called or is executing
    img_Ready, // Have a complete image in Bmp4

    hadControl,
    inControl:boolean;

    procedure DoDataFilter(Client:TRtcHttpGateClient; Data:TRtcGateClientData; var Wanted:boolean);
    procedure DoDataReceived(Client:TRtcHttpGateClient; Data:TRtcGateClientData; var WantGUI, WantBackThread:boolean);
    procedure DoDataReceivedGUI(Client:TRtcHttpGateClient; Data:TRtcGateClientData);

    // @exclude
    procedure Call_OnDataReceived(Sender:TRtcConnection); override;

    procedure PreparePaintExecute(Data: TRtcValue);
    procedure PaintJobExecute(Data: TRtcValue);

    procedure DecodeFrame(frameID:word);
    procedure ClearFrame;

    procedure PostMouseUpdate;
    procedure PostScreenUpdate;
    procedure ImageRepaint;

    procedure ImageReset;
    procedure ImageDataStart;
    procedure ImageData(const data:RtcByteArray);
    procedure ImageDataMouse(const data:RtcByteArray);
    procedure ImageDataFrame(const data:RtcByteArray);

    procedure SetInControl(const Value: boolean);

    procedure SetControlAllowed(const Value: boolean); override;

  private
    FOnCursorOn: TNotifyEvent;
    FOnCursorOff: TNotifyEvent;

    FOnStartReceive: TNotifyEvent;

    FOnImageCreate: TNotifyEvent;
    FOnImageUpdate: TNotifyEvent;
    FOnImageRepaint: TNotifyEvent;

  protected
    procedure DoInputReset; override;
    procedure DoReceiveStart; override;
    procedure DoReceiveStop; override;

  protected
    procedure DoCursorOn; virtual;
    procedure DoCursorOff; virtual;

    procedure DoOnStartReceive; virtual;

    procedure DoImageCreate; virtual;
    procedure DoImageUpdate; virtual;
    procedure DoImageRepaint; virtual;

  public
    constructor Create(AOwner:TComponent); override;

    procedure MouseDown(MouseX,MouseY:integer; MouseButton:byte);
    procedure MouseMove(MouseX,MouseY:integer);
    procedure MouseUp(MouseX,MouseY:integer; MouseButton:byte);
    procedure MouseWheel(MouseWheelDelta:integer);

    procedure KeyDown(Key:word);
    procedure KeyUp(Key:word);

    property Image:TRtcBitmapInfo read Bmp3Info write Bmp3Info;
    property Decoder:TRtcImageDecoder read ImgDecoder;
    property MouseControl:boolean read inControl write SetInControl;

    property LastMouseX:integer read FLastMouseX;
    property LastMouseY:integer read FLastMouseY;

    property ImageWidth:integer read FImageWidth;
    property ImageHeight:integer read FImageHeight;

  published
    property OnImageCreate:TNotifyEvent read FOnImageCreate write FOnImageCreate;
    property OnImageUpdate:TNotifyEvent read FOnImageUpdate write FOnImageUpdate;
    property OnImageRepaint:TNotifyEvent read FOnImageRepaint write FOnImageRepaint;

    property OnCursorShow:TNotifyEvent read FOnCursorOn write FOnCursorOn;
    property OnCursorHide:TNotifyEvent read FOnCursorOff write FOnCursorOff;

    property OnStartReceive:TNotifyEvent read FOnStartReceive write FOnStartReceive;
  end;

implementation

{ TRtcImagePlayback }

constructor TRtcImagePlayback.Create(AOwner: TComponent);
  begin
  inherited;
  // IMPORTANT !!!
  cid_GroupInvite:=cid_ImageInvite; // needs to be assigned the Group Invitation ID !!!

  Bmp3Lock:=nil;
  FillChar(Bmp3Info,SizeOf(Bmp3Info),0);
  hadControl:=False;
  inControl:=False;
  FLastMouseX:=-1;
  FLastMouseY:=-1;
  end;

procedure TRtcImagePlayback.DoCursorOff;
  begin
  if assigned(FOnCursorOff) then
    FOnCursorOff(self);
  end;

procedure TRtcImagePlayback.DoCursorOn;
  begin
  if assigned(FOnCursorOn) then
    FOnCursorOn(self);
  end;

procedure TRtcImagePlayback.DoImageCreate;
  begin
  if assigned(FOnImageCreate) then
    FOnImageCreate(self);
  end;

procedure TRtcImagePlayback.DoImageRepaint;
  begin
  if assigned(FOnImageRepaint) then
    FOnImageRepaint(self);
  end;

procedure TRtcImagePlayback.DoImageUpdate;
  begin
  if assigned(FOnImageUpdate) then
    FOnImageUpdate(self);
  end;

procedure TRtcImagePlayback.DoOnStartReceive;
  begin
  if assigned(FOnStartReceive) then
    FOnStartReceive(self);
  end;

procedure TRtcImagePlayback.SetInControl(const Value: boolean);
  begin
  if Value then
    begin
    if ControlAllowed then
      inControl:=True;
    end
  else
    begin
    inControl:=False;
    hadControl:=False;
    DoCursorOn;
    end;
  end;

procedure TRtcImagePlayback.DecodeFrame(FrameID: word);
  var
    i:integer;
  begin
  Bmp3Lock.Acquire;
  try
    if length(Bmp3Data)>0 then
      begin
      for i := 0 to length(Bmp3Data)-1 do
        begin
        ImgDecoder.Decompress(Bmp3Data[i],Bmp3Info);
        SetLength(Bmp3Data[i],0);
        end;
      SetLength(Bmp3Data,0);
      end;
    if FrameID>0 then
      begin
      LastReceiveID:=frameID;
      img_Waiting:=True;
      end;
  finally
    Bmp3Lock.Release;
    end;
  end;

procedure TRtcImagePlayback.ClearFrame;
  var
    i:integer;
  begin
  Bmp3Lock.Acquire;
  try
    if length(Bmp3Data)>0 then
      begin
      for i := 0 to length(Bmp3Data)-1 do
        SetLength(Bmp3Data[i],0);
      SetLength(Bmp3Data,0);
      end;
  finally
    Bmp3Lock.Release;
    end;
  end;

procedure TRtcImagePlayback.ImageDataStart;
  begin
  Bmp3Lock.Acquire;
  try
    ImageReset;
    ClearFrame;
    ResetBitmapInfo(Bmp3Info);
  finally
    Bmp3Lock.Release;
    end;
  img_OK:=True;
  end;

procedure TRtcImagePlayback.ImageData(const data: RtcByteArray);
  begin
  Bmp3Lock.Acquire;
  try
    if img_Waiting then
      begin
      SetLength(Bmp3Data,length(Bmp3Data)+1);
      Bmp3Data[length(Bmp3Data)-1]:=data;
      end
    else
      begin
      DecodeFrame(0);
      ImgDecoder.Decompress(data,Bmp3Info);
      end;
  finally
    Bmp3Lock.Release;
    end;
  end;

procedure TRtcImagePlayback.ImageDataFrame(const data: RtcByteArray);
  begin
  if img_OK then
    begin
    DecodeFrame(Bytes2Word(data));
    PostScreenUpdate;
    end;
  end;

procedure TRtcImagePlayback.ImageDataMouse(const data: RtcByteArray);
  begin
  if img_OK then
    begin
    Bmp3Lock.Acquire;
    try
      if img_Waiting then
        begin
        SetLength(Bmp3Data,length(Bmp3Data)+1);
        Bmp3Data[length(Bmp3Data)-1]:=data;
        end
      else
        begin
        DecodeFrame(0);
        ImgDecoder.Decompress(data,Bmp3Info);
        img_MouseChg:=True;
        PostMouseUpdate;
        end;
    finally
      Bmp3Lock.Release;
      end;
    end;
  end;

procedure TRtcImagePlayback.ImageRepaint;
  var
    myControl:boolean;
  begin
  try
    if img_Waiting or img_MouseChg then
      begin
      if inControl then
        myControl:=ImgDecoder.Cursor.User=Client.MyUID
      else
        myControl:=False;

      if myControl<>hadControl then
        if myControl then
          begin
          hadControl:=True;
          DoCursorOff;
          end
        else
          begin
          inControl:=False;
          hadControl:=False;
          DoCursorOn;
          end;

      if img_Waiting then
        begin
        Bmp3Lock.Acquire;
        try
          if assigned(Bmp3Info.Data) then
            begin
            FImageWidth:=Bmp3Info.Width;
            FImageHeight:=Bmp3Info.Height;
            DoImageUpdate;
            LastConfirmID:=LastReceiveID;
            img_Drawing:=True;
            img_Ready:=True;
            img_Waiting:=False;
            end
          else
            begin
            FImageWidth:=0;
            FImageHeight:=0;
            end;
        finally
          Bmp3Lock.Release;
          end;
        end;

      img_MouseChg:=False;
      if img_Ready then DoImageRepaint;

      ConfirmLastReceived;
      img_Drawing:=False;
      end;
  finally
    img_Painting:=False;
    end;
  PostScreenUpdate;
  end;

procedure TRtcImagePlayback.ImageReset;
  begin
  Bmp3Lock.Acquire;
  try
    img_OK:=False;
    img_Posting:=False;
    img_Painting:=False;
    img_Drawing:=False;
    img_Waiting:=False;
    img_MouseChg:=False;
    img_Ready:=False;
    LastReceiveID:=0;
    LastConfirmID:=0;
    FImageWidth:=0;
    FImageHeight:=0;
    FLastMouseX:=-1;
    FLastMouseY:=-1;
  finally
    Bmp3Lock.Release;
    end;
  end;

procedure TRtcImagePlayback.KeyDown(Key: word);
  begin
  if img_Ready and ControlAllowed and (Client<>nil) and Client.Ready and (Key>0) then
    Client.SendBytes(HostUserID,HostGroupID,cid_ControlKeyDown,Word2Bytes(Key));
  end;

procedure TRtcImagePlayback.KeyUp(Key: word);
  begin
  if img_Ready and ControlAllowed and (Client<>nil) and Client.Ready and (Key>0) then
    Client.SendBytes(HostUserID,HostGroupID,cid_ControlKeyUp,Word2Bytes(Key));
  end;

procedure TRtcImagePlayback.MouseDown(MouseX, MouseY: integer; MouseButton: byte);
  var
    OutBytes:TRtcHugeByteArray;
  begin
  if img_Ready and ControlAllowed and (Client<>nil) and Client.Ready then
    begin
    MouseControl:=True;
    FLastMouseX:=MouseX;
    FLastMouseY:=MouseY;
    if MouseX<0 then MouseX:=0;
    if MouseY<0 then MouseY:=0;
    OutBytes:=TRtcHugeByteArray.Create;
    try
      OutBytes.AddEx(Word2Bytes(MouseX));
      OutBytes.AddEx(Word2Bytes(MouseY));
      OutBytes.AddEx(OneByte2Bytes(MouseButton));
      Client.SendBytes(HostUserID,HostGroupID,cid_ControlMouseDown,OutBytes.GetEx);
    finally
      FreeAndNil(OutBytes);
      end;
    DoImageRepaint;
    end;
  end;

procedure TRtcImagePlayback.MouseMove(MouseX, MouseY: integer);
  var
    OutBytes:TRtcHugeByteArray;
  begin
  if img_Ready and MouseControl and (Client<>nil) and Client.Ready then
    begin
    FLastMouseX:=MouseX;
    FLastMouseY:=MouseY;
    if MouseX<0 then MouseX:=0;
    if MouseY<0 then MouseY:=0;
    OutBytes:=TRtcHugeByteArray.Create;
    try
      OutBytes.AddEx(Word2Bytes(MouseX));
      OutBytes.AddEx(Word2Bytes(MouseY));
      Client.SendBytes(HostUserID,HostGroupID,cid_ControlMouseMove,OutBytes.GetEx);
    finally
      FreeAndNil(OutBytes);
      end;
    DoImageRepaint;
    end;
  end;

procedure TRtcImagePlayback.MouseUp(MouseX, MouseY: integer; MouseButton: byte);
  var
    OutBytes:TRtcHugeByteArray;
  begin
  if img_Ready and MouseControl and (Client<>nil) and Client.Ready then
    begin
    FLastMouseX:=MouseX;
    FLastMouseY:=MouseY;
    if MouseX<0 then MouseX:=0;
    if MouseY<0 then MouseY:=0;
    OutBytes:=TRtcHugeByteArray.Create;
    try
      OutBytes.AddEx(Word2Bytes(MouseX));
      OutBytes.AddEx(Word2Bytes(MouseY));
      OutBytes.AddEx(OneByte2Bytes(MouseButton));
      Client.SendBytes(HostUserID,HostGroupID,cid_ControlMouseUp,OutBytes.GetEx);
    finally
      FreeAndNil(OutBytes);
      end;
    DoImageRepaint;
    end;
  end;

procedure TRtcImagePlayback.MouseWheel(MouseWheelDelta: integer);
  begin
  if img_Ready and ControlAllowed and (Client<>nil) and Client.Ready then
    begin
    Client.SendBytes(HostUserID,HostGroupID,cid_ControlMouseWheel,Word2Bytes(32768 + MouseWheelDelta));
    DoImageRepaint;
    end;
  end;

procedure TRtcImagePlayback.PreparePaintExecute(Data: TRtcValue);
  begin
  if img_OK then
    begin
    img_Painting:=True;
    PaintJob.Post(nil);
    Sleep(15);
    img_Posting:=False;
    end;
  if img_OK then
    PostScreenUpdate;
  end;

procedure TRtcImagePlayback.PaintJobExecute(Data: TRtcValue);
  begin
  if img_OK then
    ImageRepaint
  else
    img_Painting:=False;
  end;

procedure TRtcImagePlayback.PostMouseUpdate;
  begin
  if img_OK and img_Ready and not (img_Painting or img_Drawing or img_Posting) then
    begin
    img_Posting:=True;
    PreparePaint.Post(nil);
    end;
  end;

procedure TRtcImagePlayback.PostScreenUpdate;
  begin
  if img_OK and img_Waiting and not (img_Painting or img_Drawing or img_Posting) then
    begin
    img_Posting:=True;
    PreparePaint.Post(nil);
    end;
  end;

procedure TRtcImagePlayback.SetControlAllowed(const Value: boolean);
  begin
  inherited;
  inControl:=False;
  hadControl:=False;
  DoCursorOn;
  end;

procedure TRtcImagePlayback.DoInputReset;
  begin
  ImageReset;
  end;

procedure TRtcImagePlayback.DoReceiveStop;
  begin
  if assigned(ImgDecoder) then
    begin
    PreparePaint.Stop;
    PaintJob.Stop;

    ImageReset;

    repeat
      Sleep(100);
      until img_Painting=False;

    RtcFreeAndNil(PreparePaint);
    RtcFreeAndNil(PaintJob);

    ClearFrame;
    RtcFreeAndNil(ImgDecoder);
    ReleaseBitmapInfo(Bmp3Info);
    RtcFreeAndNil(Bmp3Lock);
    end;
  end;

procedure TRtcImagePlayback.DoReceiveStart;
  begin
  if not assigned(ImgDecoder) then
    begin
    Bmp3Lock:=TRtcCritSec.Create;
    ImgDecoder:=TRtcImageDecoder.Create;

    DoImageCreate;

    ImageReset;

    PreparePaint:=TRtcQuickJob.Create(nil);
    PreparePaint.Serialized:=True;
    PreparePaint.OnExecute:=PreparePaintExecute;

    PaintJob:=TRtcQuickJob.Create(nil);
    PaintJob.Serialized:=True;
    PaintJob.AccessGUI:=True;
    PaintJob.OnExecute:=PaintJobExecute;
    end;
  end;

procedure TRtcImagePlayback.DoDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: boolean);
  begin
  case Data.CallID of
    cid_ImageStart:
      if Data.Footer then
        Wanted:=IsMyPackage(Data)
      else if Data.Header then
        Data.ToBuffer:=IsMyPackage(Data);

    cid_ImageMouse,
    cid_ImageData,
    cid_GroupConfirmSend:
      if Data.Footer then
        Wanted:=img_OK and IsMyPackage(Data)
      else if Data.Header then
        Data.ToBuffer:=img_OK and IsMyPackage(Data);
    end;
  end;

procedure TRtcImagePlayback.DoDataReceived(Client: TRtcHttpGateClient;  Data: TRtcGateClientData; var WantGUI, WantBackThread: boolean);
  begin
  case Data.CallID of
    cid_ImageData:        ImageData(Data.Content);
    cid_ImageMouse:       ImageDataMouse(Data.Content);
    cid_GroupConfirmSend: ImageDataFrame(Data.Content);

    cid_ImageStart:       WantGUI:=True;
    end;
  end;

procedure TRtcImagePlayback.DoDataReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
  begin
  if Data.CallID=cid_ImageStart then
    begin
    ImageDataStart;
    DoOnStartReceive;
    end;
  end;

procedure TRtcImagePlayback.Call_OnDataReceived(Sender: TRtcConnection);
  begin
  if Filter(DoDataFilter,Sender) then
    Call(DoDataReceived,DoDataReceivedGUI,Sender);

  inherited;
  end;

end.
