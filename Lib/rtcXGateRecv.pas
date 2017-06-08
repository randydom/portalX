{
  "RTC Gate Receiver Link"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcXGateRecv;

interface

{$include rtcDefs.inc}

uses
  Classes,
  SysUtils,

  rtcTypes,
  rtcConn,
  rtcInfo,
  rtcFastStrings,

  rtcGateConst,
  rtcGateCli,

  rtcXGateCIDs;

type
  { @Abstract(RTC Gate Receiver Link)
    Link this component to a TRtcHttpGateClient to handle Group Receive events. }
  {$IFDEF IDE_XE2up}
  [ComponentPlatformsAttribute(pidAll)]
  {$ENDIF}
  TRtcGateReceiverLink=class(TRtcAbsGateClientLink)
  private
    FOnHostConnect: TNotifyEvent;
    FOnHostDisconnect: TNotifyEvent;
    FOnHostOffLine: TNotifyEvent;
    FOnHostClosed: TNotifyEvent;

    FOnControlEnabled: TNotifyEvent;
    FOnControlDisabled: TNotifyEvent;

    FOnLogOut: TNotifyEvent;
    FOnDisconnect: TNotifyEvent;

  protected
    LastConfirmID:word;

    FHostUserID,
    FHostGroupID:TGateUID;
    FHostKey:RtcByteArray;

    FControlAllowed:boolean;

    StreamWasReset:boolean;

    procedure DoDataFilter(Client:TRtcHttpGateClient; Data:TRtcGateClientData; var Wanted:boolean);
    procedure DoDataReceivedGUI(Client:TRtcHttpGateClient; Data:TRtcGateClientData);

    procedure DoInfoFilter(Client:TRtcHttpGateClient; Data:TRtcGateClientData; var Wanted:boolean);
    procedure DoInfoReceivedGUI(Client:TRtcHttpGateClient; Data:TRtcGateClientData);

    // @exclude
    procedure Call_AfterLogOut(Sender:TRtcConnection); override;

    // @exclude
    procedure Call_OnDataReceived(Sender:TRtcConnection); override;
    // @exclude
    procedure Call_OnInfoReceived(Sender:TRtcConnection); override;
    // @exclude
    procedure Call_OnReadyToSend(Sender:TRtcConnection); override;

    // @exclude
    procedure Call_OnStreamReset(Sender:TRtcConnection); override;

    // @exclude
    procedure SetClient(const Value: TRtcHttpGateClient); override;

    function CompareKeys(const OrigKey,RecvKey:RtcByteArray):boolean;

    procedure SetControlAllowed(const Value: boolean); virtual;

    procedure ConfirmLastReceived;

    function IsMyPackage(Data:TRtcGateClientData):boolean;

  protected
    procedure DoOnHostConnect; virtual;
    procedure DoOnHostDisconnect; virtual;
    procedure DoOnHostOffLine; virtual;
    procedure DoOnHostClosed; virtual;

    procedure DoOnControlEnabled; virtual;
    procedure DoOnControlDisabled; virtual;

    procedure DoOnLogOut; virtual;
    procedure DoOnDisconnect; virtual;

  protected
    cid_GroupInvite:word; // needs to be assigned the Group Invitation ID !!!
    procedure DoInputReset; virtual;
    procedure DoReceiveStart; virtual;
    procedure DoReceiveStop; virtual;

  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

    procedure HostInviteAccept(UserID,GroupID:TGateUID; const Key:RtcString);

    property ControlAllowed:boolean read FControlAllowed write SetControlAllowed;

    property HostUserID:TGateUID read FHostUserID;
    property HostGroupID:TGateUID read FHostGroupID;

    property InviteCallID:word read cid_GroupInvite write cid_GroupInvite;

  published
    property OnLogOut:TNotifyEvent read FOnLogOut write FOnLogOut;
    property OnDisconnect:TNotifyEvent read FOnDisconnect write FOnDisconnect;

    property OnHostOffLine:TNotifyEvent read FOnHostOffLine write FOnHostOffLine;
    property OnHostConnect:TNotifyEvent read FOnHostConnect write FOnHostConnect;
    property OnHostDisconnect:TNotifyEvent read FOnHostDisconnect write FOnHostDisconnect;
    property OnHostClosed:TNotifyEvent read FOnHostClosed write FOnHostClosed;

    property OnControlEnabled:TNotifyEvent read FOnControlEnabled write FOnControlEnabled;
    property OnControlDisabled:TNotifyEvent read FOnControlDisabled write FOnControlDisabled;
  end;

implementation

{ TRtcGateReceiverLink }

constructor TRtcGateReceiverLink.Create(AOwner: TComponent);
  begin
  inherited;
  FControlAllowed:=False;
  end;

destructor TRtcGateReceiverLink.Destroy;
  begin
  Client:=nil;
  inherited;
  end;

function TRtcGateReceiverLink.CompareKeys(const OrigKey,RecvKey:RtcByteArray):boolean;
  var
    a:integer;
  begin
  if length(OrigKey)>length(RecvKey) then
    Result:=False
  else
    begin
    Result:=True;
    for a:=0 to length(OrigKey)-1 do
      if OrigKey[a]<>RecvKey[a] then
        begin
        Result:=False;
        Break;
        end;
    end;
  end;

procedure TRtcGateReceiverLink.DoOnControlDisabled;
  begin
  if assigned(FOnControlDisabled) then
    FOnControlDisabled(self);
  end;

procedure TRtcGateReceiverLink.DoOnControlEnabled;
  begin
  if assigned(FOnControlEnabled) then
    FOnControlEnabled(self);
  end;

procedure TRtcGateReceiverLink.DoOnDisconnect;
  begin
  if assigned(FOnDisconnect) then
    FOnDisconnect(self);
  end;

procedure TRtcGateReceiverLink.DoOnHostClosed;
  begin
  if assigned(FOnHostClosed) then
    FOnHostClosed(self);
  end;

procedure TRtcGateReceiverLink.DoOnHostConnect;
  begin
  if assigned(FOnHostConnect) then
    FOnHostConnect(self);
  end;

procedure TRtcGateReceiverLink.DoOnHostDisconnect;
  begin
  if assigned(FOnHostDisconnect) then
    FOnHostDisconnect(self);
  end;

procedure TRtcGateReceiverLink.DoOnHostOffLine;
  begin
  if assigned(FOnHostOffLine) then
    FOnHostOffLine(self);
  end;

procedure TRtcGateReceiverLink.DoOnLogOut;
  begin
  if assigned(FOnLogOut) then
    FOnLogOut(self);
  end;

procedure TRtcGateReceiverLink.ConfirmLastReceived;
  var
    toID:word;
  begin
  toID:=LastConfirmID;
  if toID>0 then
    begin
    Client.SendBytes(FHostUserID,FHostGroupID,cid_GroupConfirmRecv,Word2Bytes(toID));
    LastConfirmID:=0;
    end;
  end;

procedure TRtcGateReceiverLink.SetClient(const Value: TRtcHttpGateClient);
  begin
  if Value=Client then Exit;

  if assigned(Client) then
    begin
    DoReceiveStop;

    if assigned(Client) then
      if Client.Ready then
        if Groups.GetStatus(FHostUserID,FHostGroupID)>=10 then
          Client.RemUserFromGroup(FHostUserID,FHostGroupID,Client.MyUID);
    end;

  StreamWasReset:=False;

  inherited;
  end;

procedure TRtcGateReceiverLink.HostInviteAccept(UserID,GroupID:TGateUID; const Key:RtcString);
  begin
  if (UserID>0) and (GroupID>0) and (length(Key)>0) then
    if assigned(Client) and Client.Ready then
      begin
      if (FHostUserID>0) and (FHostGroupID>0) then
        begin
        DoReceiveStop;

        if assigned(Client) then
          if Client.Ready then
            if Groups.GetStatus(FHostUserID,FHostGroupID)>=10 then
              Client.RemUserFromGroup(FHostUserID,HostGroupID,Client.MyUID);

        Groups.ClearStatus(FHostUserID,FHostGroupID);
        end;

      FHostUserID:=UserID;
      FHostGroupID:=GroupID;
      FHostKey:=RtcStringToBytes(Key);

      DoReceiveStart;

      Groups.SetStatus(FHostUserID,FHostGroupID,5);

      Client.AddFriend(FHostUserID);
      Client.SendBytes(FHostUserID,FHostGroupID,cid_GroupAccept,FHostKey);
      end;
  end;

procedure TRtcGateReceiverLink.Call_AfterLogOut(Sender: TRtcConnection);
  begin
  if Client=nil then Exit;

  if assigned(Sender) then
    if not Sender.inMainThread then
      begin
      Sender.Sync(Call_AfterLogOut);
      Exit;
      end;

  Groups.ClearAllStates;

  DoOnLogOut;
  inherited;
  end;

procedure TRtcGateReceiverLink.DoDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: boolean);
  begin
  if (Client=nil) or (FHostUserID=0) or (FHostGroupID=0) or (Data.UserID<>FHostUserID) then Exit;

  if Data.CallID=cid_GroupInvite then
    begin
    if Data.Footer then
      Wanted:=Groups.GetMinStatus(Data.UserID)>0
    else if Data.Header then
      Data.ToBuffer:=Groups.GetMinStatus(Data.UserID)>0;
    end
  else
    begin
    case Data.CallID of
      cid_GroupClosed:
        if Data.Footer then
          Wanted:=(Groups.GetStatus(Data.UserID,Data.GroupID)>0)
        else if Data.Header then
          Data.ToBuffer:=(Groups.GetStatus(Data.UserID,Data.GroupID)>0);

      cid_GroupAllowControl:
        if Data.Footer then
          Wanted:=(Groups.GetStatus(Data.UserID,Data.ToGroupID)=10)
        else if Data.Header then
          Data.ToBuffer:=(Groups.GetStatus(Data.UserID,Data.ToGroupID)=10);

      cid_GroupDisallowControl:
        if Data.Footer then
          Wanted:=(Groups.GetStatus(Data.UserID,Data.ToGroupID)=20)
        else if Data.Header then
          Data.ToBuffer:=(Groups.GetStatus(Data.UserID,Data.ToGroupID)=20);
      end;
    end;
  end;

procedure TRtcGateReceiverLink.DoDataReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
  procedure ProcessInvite;
    begin
    if CompareKeys(FHostKey, Data.Content) then
      begin
      if Groups.GetStatus(Data.UserID, Data.ToGroupID)<10 then
        begin
        Groups.ClearStatus(FHostUserID,FHostGroupID);
        FHostUserID:=Data.UserID;
        FHostGroupID:=Data.ToGroupID;
        Groups.SetStatus(Data.UserID,FHostGroupID,5);

        ControlAllowed:=False;

        AddFriend(FHostUserID);
        SendBytes(FHostUserID,FHostGroupID,cid_GroupAccept,Data.Content);
        end;
      end;
    end;
  procedure ProcessClosed;
    begin
    DoInputReset;
    Groups.SetStatus(Data.UserID, Data.GroupID, 1);
    LeaveUsersGroup(Data.UserID, Data.GroupID);
    ControlAllowed:=False;
    DoOnHostClosed;
    end;
  procedure ProcessAllowControl;
    begin
    Groups.SetStatus(Data.UserID, Data.ToGroupID, 20);
    ControlAllowed:=True;
    DoOnControlEnabled;
    end;
  procedure ProcessDisallowControl;
    begin
    Groups.SetStatus(Data.UserID, Data.ToGroupID, 10);
    ControlAllowed:=False;
    DoOnControlDisabled;
    end;
  begin
  if (Client=nil) or (FHostUserID=0) or (FHostGroupID=0) or (Data.UserID<>FHostUserID) then Exit;

  if Data.CallID=cid_GroupInvite then
    ProcessInvite
  else case Data.CallID of
    cid_GroupClosed:          ProcessClosed;
    cid_GroupAllowControl:    ProcessAllowControl;
    cid_GroupDisallowControl: ProcessDisallowControl;
    end;
  end;

procedure TRtcGateReceiverLink.Call_OnDataReceived(Sender: TRtcConnection);
  begin
  if Filter(DoDataFilter,Sender) then
    CallGUI(DoDataReceivedGUI,Sender);

  inherited;
  end;

procedure TRtcGateReceiverLink.DoInfoFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: boolean);
  begin
  if (Client=nil) or (FHostUserID=0) or (FHostGroupID=0) or (Data.UserID<>FHostUserID) then Exit;
  case Data.Command of
    gc_UserOffline:
      Wanted:=Groups.GetMinStatus(Data.UserID)>0;
    gc_JoinedUser:
      Wanted:=Groups.GetStatus(Data.UserID, Data.GroupID) in [5..9];
    gc_LeftUser:
      Wanted:=Groups.GetStatus(Data.UserID, Data.GroupID)>0;
    end;
  end;

procedure TRtcGateReceiverLink.DoInfoReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
  begin
  if (Client=nil) or (FHostUserID=0) or (FHostGroupID=0) or (Data.UserID<>FHostUserID) then Exit;
  case Data.Command of
    gc_UserOffline:
      begin
      DoInputReset;
      ControlAllowed:=False;
      Groups.SetStatus(Data.UserID,FHostGroupID,1);
      DoOnHostOffLine;
      end;
    gc_JoinedUser:
      begin
      DoInputReset;
      Groups.SetStatus(Data.UserID,Data.GroupID,10);
      ControlAllowed:=False;
      DoOnHostConnect;
      end;
    gc_LeftUser:
      begin
      DoInputReset;
      Groups.SetStatus(Data.UserID,Data.GroupID,1);
      ControlAllowed:=False;
      DoOnHostDisconnect;
      end;
    end;
  end;

procedure TRtcGateReceiverLink.Call_OnInfoReceived(Sender: TRtcConnection);
  begin
  if Filter(DoInfoFilter,Sender) then
    CallGUI(DoInfoReceivedGUI,Sender);
  inherited;
  end;

procedure TRtcGateReceiverLink.Call_OnStreamReset(Sender: TRtcConnection);
  begin
  if (Client=nil) or (FHostUserID=0) or (FHostGroupID=0) then Exit;

  if not Sender.inMainThread then
    begin
    Sender.Sync(Call_OnStreamReset);
    Exit;
    end;

  if Groups.GetStatus(FHostUserID,FHostGroupID)>0 then
    begin
    DoInputReset;

    StreamWasReset:=True;
    Groups.SetStatus(FHostUserID,FHostGroupID,1);

    ControlAllowed:=False;

    DoOnDisconnect;
    end;

  inherited;
  end;

procedure TRtcGateReceiverLink.Call_OnReadyToSend(Sender: TRtcConnection);
  begin
  if (Client=nil) or (FHostUserID=0) or (FHostGroupID=0) then Exit;

  if StreamWasReset then
    if Client.Ready then
      begin
      StreamWasReset:=False;
      Groups.SetStatus(FHostUserID,FHostGroupID,5);

      ControlAllowed:=False;

      Client.AddFriend(FHostUserID);
      Client.SendBytes(FHostUserID,FHostGroupID,cid_GroupAccept,FHostKey);
      end;

  inherited;
  end;

procedure TRtcGateReceiverLink.SetControlAllowed(const Value: boolean);
  begin
  FControlAllowed:=Value;
  end;

function TRtcGateReceiverLink.IsMyPackage(Data:TRtcGateClientData): boolean;
  begin
  Result := Groups.GetStatus(Data.UserID,Data.GroupID)>=10;
  end;

procedure TRtcGateReceiverLink.DoInputReset;
  begin
  // Input Stream was reset, initialize input stream data
  end;

procedure TRtcGateReceiverLink.DoReceiveStart;
  begin
  // prepare stream for receiving
  end;

procedure TRtcGateReceiverLink.DoReceiveStop;
  begin
  // stop and release receiving stream
  end;

end.
