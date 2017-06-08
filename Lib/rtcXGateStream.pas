{
  "RTC Gate Streamer Link"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcXGateStream;

interface

{$include rtcDefs.inc}

uses
  Classes,
  SysUtils,

  rtcTypes,
  rtcConn,

  rtcGateConst,
  rtcGateCli,

  rtcXGateCIDs;

type
  TRtcGMLinkUserStatusChange = procedure(Sender:TObject; UserID:TGateUID) of object;
  TRtcGMLinkUserStatus = (scu_Unknown, scu_OffLine, scu_Passive, scu_Invited, scu_Active);

  { @Abstract(RTC Gate Streamer Link)
    Link this component to a TRtcHttpGateClient to handle Group Streaming events. }
  {$IFDEF IDE_XE2up}
  [ComponentPlatformsAttribute(pidAll)]
  {$ENDIF}
  TRtcGateStreamerLink = class(TRtcAbsGateClientLink)
  private
    FOnSendingStart: TNotifyEvent;
    FOnSendingPause: TNotifyEvent;
    FOnSendingIdle: TNotifyEvent;
    FOnUserStatusChange: TRtcGMLinkUserStatusChange;

  protected
    InviteKey: RtcByteArray;

    StreamWasReset:boolean;

    LastPackRecv,
    LastPackSent:word;

    SendingFirst,
    SendingPaused,
    SendingStream:boolean;

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

    procedure DoDataFilter(Client:TRtcHttpGateClient; Data:TRtcGateClientData; var Wanted:boolean);
    procedure DoDataReceived(Client:TRtcHttpGateClient; Data:TRtcGateClientData; var WantGUI, WantBackThread:boolean);
    procedure DoDataReceivedGUI(Client:TRtcHttpGateClient; Data:TRtcGateClientData);

    procedure DoInfoFilter(Client:TRtcHttpGateClient; Data:TRtcGateClientData; var Wanted:boolean);
    procedure DoInfoReceivedGUI(Client:TRtcHttpGateClient; Data:TRtcGateClientData);

    procedure ConfirmPackSent;
    procedure UpdateLastPackRecv;
    function LastPackDiff:word;

    procedure AddAllDisabledUsers;
    procedure InviteAllDisabledUsers;

    function MakeRandomKey(GID:TGateUID; len:integer):RtcByteArray;
    function CompareKeys(const OrigKey,RecvKey:RtcByteArray):boolean;

    function IsMyPackage(Data:TRtcGateClientData):boolean;
    function IsControlPackage(Data:TRtcGateClientData):boolean;

  protected
    cid_GroupInvite:word; // needs to be assigned the Group Invitation ID !!!
    procedure DoSendStart; virtual; // initialize the sending process
    procedure DoSendNext; virtual; // ready to send the next package
    procedure DoSendStop; virtual; // stop the sending process

  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

    function UserInviteToGroup(UserID:TGateUID):boolean;
    function UserKickFromGroup(UserID:TGateUID):boolean;
    function UserEnableControl(UserID:TGateUID):boolean;
    function UserDisableControl(UserID:TGateUID):boolean;

    function IsUserInControl(UserID:TGateUID):boolean;
    function CheckUserStatus(UserID:TGateUID):TRtcGMLinkUserStatus;

    procedure UpdateUserStatus(UserID: TGateUID);

    function ConnectedUsers:integer;

    procedure StartMyGroup;
    procedure PauseSending;
    procedure ResumeSending;

    property NowSending:boolean read SendingStream;
    property NowPaused:boolean read SendingPaused;

    property InviteCallID:word read cid_GroupInvite write cid_GroupInvite;

  published
    property OnSendingPaused:TNotifyEvent read FOnSendingPause write FOnSendingPause;
    property OnSendingIdle:TNotifyEvent read FOnSendingIdle write FOnSendingIdle;
    property OnSendingActive:TNotifyEvent read FOnSendingStart write FOnSendingStart;
    property OnUserStatusChange:TRtcGMLinkUserStatusChange read FOnUserStatusChange write FOnUserStatusChange;
    end;

implementation

{ TRtcGateStreamerLink }

constructor TRtcGateStreamerLink.Create(AOwner: TComponent);
  begin
  inherited;
  SetLength(InviteKey,0);

  LastPackSent:=0;
  LastPackRecv:=0;
  SendingFirst:=True;
  SendingStream:=True;
  SendingPaused:=True;
  end;

destructor TRtcGateStreamerLink.Destroy;
  begin
  Client:=nil;

  inherited;
  end;

function TRtcGateStreamerLink.MakeRandomKey(GID:TGateUID; len:integer):RtcByteArray;
  var
    a:integer;
    b:byte;
  begin
  SetLength(Result,len+1);
  Result[0]:=GID;
  for a:=1 to length(Result)-1 do
    begin
    b:=random(255);
    Result[a]:=b;
    end;
  end;

function TRtcGateStreamerLink.CompareKeys(const OrigKey,RecvKey:RtcByteArray):boolean;
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

procedure TRtcGateStreamerLink.Call_AfterLogOut(Sender: TRtcConnection);
  begin
  if Client=nil then Exit;

  if not Sender.inMainThread then
    begin
    Sender.Sync(Call_AfterLogOut);
    Exit;
    end;

  LastPackSent:=0;
  LastPackRecv:=0;
  SendingFirst:=True;

  Groups.ClearAllStates;

  if SendingStream then
    begin
    SendingStream:=False;
    SendingPaused:=True;
    if assigned(FOnSendingPause) then
      FOnSendingPause(self);
    end;
  end;

procedure TRtcGateStreamerLink.DoDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: boolean);
  begin
  case Data.CallID of
    cid_GroupAccept:
        if Data.Footer then
          Wanted:=(Data.ToGroupID=MyGroupID) and (Groups.GetStatus(Data.UserID,0)=4)
        else if Data.Header then
          Data.ToBuffer:=(Data.ToGroupID=MyGroupID) and (Groups.GetStatus(Data.UserID,0)=4);
    cid_GroupConfirmRecv:
      if Data.Footer then
        Wanted:=IsMyPackage(Data) and (length(Data.Content)=2)
      else if Data.Header then
        Data.ToBuffer:=IsMyPackage(Data);
    end;
  end;

procedure TRtcGateStreamerLink.DoDataReceived(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var WantGUI, WantBackThread: boolean);
  procedure ProcessPackOK;
    var
      lr:word;
    begin
    if LastPackSent>0 then
      begin
      lr:=Bytes2Word(Data.Content);
      Groups.SetStatus(Data.UserID,2,lr);
      UpdateLastPackRecv;
      end;
    end;
  begin
  case Data.CallID of
    cid_GroupAccept:        WantGUI:=True;
    cid_GroupConfirmRecv:   ProcessPackOK;
    end;
  end;

procedure TRtcGateStreamerLink.DoDataReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
  procedure ProcessAccept;
    begin
    // Invitation Key is correct?
    if CompareKeys(InviteKey, Data.Content) then
      begin
      SendingPaused:=True;

      Groups.SetStatus(Data.UserID,0,5);
      if Groups.GetStatus(Data.UserID,1)>0 then
        Groups.SetStatus(Data.UserID,1,5);
      Groups.ClearStatus(Data.UserID,2);

      UpdateLastPackRecv;
      UpdateUserStatus(Data.UserID);

      AddUserToGroup(Data.UserID);

      if SendingStream then
        if assigned(FOnSendingStart) then
          FOnSendingStart(self);

      SendingPaused:=False;
      if (Client<>nil) and
         (SendingPaused=False) and
         (SendingStream=True) then
        begin
        SendingFirst:=True;
        DoSendNext;
        end;
      end;
    end;
  begin
  case Data.CallID of
    cid_GroupAccept: ProcessAccept;
    end;
  end;

procedure TRtcGateStreamerLink.Call_OnDataReceived(Sender: TRtcConnection);
  begin
  if Filter(DoDataFilter,Sender) then
    Call(DoDataReceived,DoDataReceivedGUI,Sender);
  inherited;
  end;

procedure TRtcGateStreamerLink.DoInfoFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: boolean);
  begin
  case Data.Command of
    gc_UserOffline:
      Wanted:=Groups.GetMinStatus(Data.UserID)>0;
    gc_UserLeft:
      Wanted:=(Data.GroupID=MyGroupID) and (Groups.GetStatus(Data.UserID,0)>0);
    gc_UserJoined:
      Wanted:=(Data.GroupID=MyGroupID) and (Groups.GetStatus(Data.UserID,0)=5);
    end;
  end;

procedure TRtcGateStreamerLink.DoInfoReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
  begin
  case Data.Command of
    gc_UserOffline:
      begin
      if Groups.GetStatus(Data.UserID,0)>=4 then
        begin
        Groups.SetStatus(Data.UserID,0,4);
        if Groups.GetStatus(Data.UserID,1)>1 then
          Groups.SetStatus(Data.UserID,1,4);
        Groups.ClearStatus(Data.UserID,2);
        end
      else
        begin
        Groups.SetStatus(Data.UserID,0,1);
        if Groups.GetStatus(Data.UserID,1)>1 then
          Groups.SetStatus(Data.UserID,1,1);
        Groups.ClearStatus(Data.UserID,2);
        end;
      Groups.ClearStatus(Data.UserID,3); // offline

      UpdateLastPackRecv;
      UpdateUserStatus(Data.UserID);
      end;

    gc_UserLeft:
      begin
      if Groups.GetStatus(Data.UserID,0)>=4 then
        begin
        Groups.SetStatus(Data.UserID,0,4);
        if Groups.GetStatus(Data.UserID,1)>0 then
          Groups.SetStatus(Data.UserID,1,4);
        Groups.ClearStatus(Data.UserID,2);
        end
      else
        begin
        Groups.SetStatus(Data.UserID,0,1);
        if Groups.GetStatus(Data.UserID,1)>0 then
          Groups.SetStatus(Data.UserID,1,1);
        Groups.ClearStatus(Data.UserID,2);
        end;
      UpdateLastPackRecv;
      UpdateUserStatus(Data.UserID);

      if ConnectedUsers=0 then
        begin
        if SendingStream then
          begin
          SendingPaused:=True;
          if assigned(FOnSendingIdle) then
            FOnSendingIdle(self);
          end;
        end;
      end;

    gc_UserJoined:
      begin
      Groups.SetStatus(Data.UserID,0,10);
      Groups.ClearStatus(Data.UserID,2);
      Groups.SetStatus(Data.UserID,3,2); // online, active
      if Groups.GetStatus(Data.UserID,1)>0 then
        begin
        Groups.SetStatus(Data.UserID,1,10);
        SendBytes(Data.UserID,MyGroupID,cid_GroupAllowControl);
        end;

      UpdateLastPackRecv;
      UpdateUserStatus(Data.UserID);
      end;
    end;
  end;

procedure TRtcGateStreamerLink.Call_OnInfoReceived(Sender: TRtcConnection);
  begin
  if Filter(DoInfoFilter,Sender) then
    CallGUI(DoInfoReceivedGUI,Sender);
  inherited;
  end;

procedure TRtcGateStreamerLink.Call_OnReadyToSend(Sender: TRtcConnection);
  begin
  if (Client=nil) or (MyGroupID=0) then Exit;

  if StreamWasReset then
    begin
    StreamWasReset:=False;
    InviteAllDisabledUsers;
    end;

  if (Client<>nil) and
     (SendingPaused=False) and
     (SendingStream=True) then
    DoSendNext;
  end;

procedure TRtcGateStreamerLink.Call_OnStreamReset(Sender: TRtcConnection);
  var
    UID,GID,GST:TGateUID;
  begin
  if (Client=nil) or (MyGroupID=0) then Exit;

  if not Sender.inMainThread then
    begin
    Sender.Sync(Call_OnStreamReset);
    Exit;
    end;

  if SendingStream then
    begin
    SendingPaused:=True;
    if assigned(FOnSendingIdle) then
      FOnSendingIdle(self);
    end;

  StreamWasReset:=True;
  UID:=0; GID:=0;
  repeat
    GST:=Groups.GetNextStatus(UID,GID);
    if (GID=0) and (GST>=4) then
      begin
      Groups.SetStatus(UID,0,4);
      if Groups.GetStatus(UID,1)>4 then
        Groups.SetStatus(UID,1,4);
      Groups.ClearStatus(UID,2);

      UpdateUserStatus(UID);
      end;
    until GST=0;

  UpdateLastPackRecv;
  end;

procedure TRtcGateStreamerLink.SetClient(const Value: TRtcHttpGateClient);
  begin
  if Value=Client then Exit;

  if assigned(Client) then
    begin
    SendingStream:=False;
    SendingPaused:=True;

    DoSendStop;

    if MyGroupID>0 then
      if assigned(Client) then
        begin
        if Client.Ready then
          begin
          AddAllDisabledUsers;
          SendToGroup(cid_GroupClosed);
          end;
        end;
    end;

  inherited;
  end;

procedure TRtcGateStreamerLink.StartMyGroup;
  begin
  if length(InviteKey)=0 then
    begin
    InviteKey:=MakeRandomKey(MyGroupID, 16);

    SendingStream:=True;
    SendingPaused:=True;

    DoSendStart;
    end;
  end;

procedure TRtcGateStreamerLink.UpdateLastPackRecv;
  var
    UID,GID,GST,Result:TGateUID;
    overflow:boolean;
  begin
  overflow:=LastPackSent<LastPackRecv;

  Result:=0;
  UID:=0; GID:=0;
  repeat
    GST:=Groups.GetNextStatus(UID,GID);
    if (GST>0) and (GID=2) then
      begin
      if Result=0 then
        Result:=GST
      else if overflow then
        begin
        if (GST>=LastPackSent) and (GST>Result) then
          Result:=GST;
        end
      else
        begin
        if (GST<=LastPackSent) and (GST<Result) then
          Result:=GST;
        end;
      end;
    until GST=0;

  if Result>0 then
    LastPackRecv:=Result;
  end;

procedure TRtcGateStreamerLink.UpdateUserStatus(UserID: TGateUID);
  begin
  if assigned(FOnUserStatusChange) then
    FOnUserStatusChange(self,UserID);
  end;

function TRtcGateStreamerLink.ConnectedUsers: integer;
  var
    UID,GID,GST:TGateUID;
  begin
  Result:=0;
  UID:=0; GID:=0;
  repeat
    GST:=Groups.GetNextStatus(UID,GID);
    if (GID=0) and (GST=10) then
      Inc(Result);
    until GST=0;
  end;

procedure TRtcGateStreamerLink.InviteAllDisabledUsers;
  var
    UID,GID,GST:TGateUID;
  begin
  if MyGroupID=0 then Exit;

  UID:=0; GID:=0;
  repeat
    GST:=Groups.GetNextStatus(UID,GID);
    if (GID=0) and (GST>=3) then
      UserInviteToGroup(UID);
    until GST=0;
  end;

procedure TRtcGateStreamerLink.AddAllDisabledUsers;
  var
    UID,GID,GST:TGateUID;
  begin
  if MyGroupID=0 then Exit;

  UID:=0; GID:=0;
  repeat
    GST:=Groups.GetNextStatus(UID,GID);
    if (GID=0) and (GST>0) and (GST<10) then
      AddUserToGroup(UID);
    until GST=0;
  end;

function TRtcGateStreamerLink.LastPackDiff:word;
  begin
  if LastPackSent>0 then
    begin
    if LastPackRecv<=LastPackSent then
      Result:=LastPackSent-LastPackRecv
    else // full synchronize on overflow
      Result:=65535;
    end
  else
    Result:=0;
  end;

function TRtcGateStreamerLink.UserInviteToGroup(UserID: TGateUID):boolean;
  begin
  Result:=False;
  if (Client=nil) or (UserID<MinUserID) or (UserID>MaxUserID) then Exit;
  if not Client.Ready then Exit;

  if Groups.GetStatus(UserID,0)<10 then
    begin
    StartMyGroup;

    Groups.SetStatus(UserID,0,4);
    if Groups.GetStatus(UserID,1)>0 then
      Groups.SetStatus(UserID,1,4);
    Groups.ClearStatus(UserID,2);
    Groups.SetStatus(UserID,3,1); // invited

    UpdateLastPackRecv;
    UpdateUserStatus(UserID);

    SendBytes(UserID,MyGroupID,cid_GroupInvite,InviteKey);
    PingUser(UserID);
    Result:=True;
    end;
  end;

function TRtcGateStreamerLink.UserKickFromGroup(UserID: TGateUID): boolean;
  begin
  Result:=False;
  if (Client=nil) or (MyGroupID=0) then Exit;

  if Groups.GetStatus(UserID,0)>=4 then
    begin
    Groups.SetStatus(UserID,0,1);
    if Groups.GetStatus(UserID,1)>=4 then
      Groups.SetStatus(UserID,1,1);
    Groups.ClearStatus(UserID,2);

    UpdateLastPackRecv;
    UpdateUserStatus(UserID);

    RemoveUserFromGroup(UserID);
    PingUser(UserID);
    Result:=True;
    end;
  end;

function TRtcGateStreamerLink.UserDisableControl(UserID: TGateUID): boolean;
  begin
  Result:=False;
  if (Client=nil) or (MyGroupID=0) then Exit;

  if Groups.GetStatus(UserID,1)>0 then
    begin
    Groups.ClearStatus(UserID,1);
    UpdateUserStatus(UserID);

    if Groups.GetStatus(UserID,0)>=5 then
      begin
      SendBytes(UserID,MyGroupID,cid_GroupDisallowControl);
      PingUser(UserID);
      end;
    Result:=True;
    end;
  end;

function TRtcGateStreamerLink.UserEnableControl(UserID: TGateUID): boolean;
  begin
  Result:=False;
  if (Client=nil) or (MyGroupID=0) then Exit;

  if (Groups.GetStatus(UserID,0)>0) and
     (Groups.GetStatus(UserID,1)=0) then
    begin
    Groups.SetStatus(UserID,1,Groups.GetStatus(UserID,0));

    UpdateLastPackRecv;
    UpdateUserStatus(UserID);

    if Groups.GetStatus(UserID,0)>=5 then
      begin
      SendBytes(UserID,MyGroupID,cid_GroupAllowControl);
      PingUser(UserID);
      end;
    Result:=True;
    end;
  end;

procedure TRtcGateStreamerLink.PauseSending;
  begin
  SendingStream:=False;
  SendingPaused:=False;
  end;

procedure TRtcGateStreamerLink.ResumeSending;
  begin
  SendingStream:=True;
  SendingPaused:=ConnectedUsers=0;
  if SendingPaused=False then
    if MyGroupID>0 then
      if assigned(Client) then
        DoSendNext;
  end;

function TRtcGateStreamerLink.IsUserInControl(UserID: TGateUID): boolean;
  begin
  Result := Groups.GetStatus(UserID,1)>0;
  end;

function TRtcGateStreamerLink.CheckUserStatus(UserID: TGateUID): TRtcGMLinkUserStatus;
  begin
  if Groups.GetStatus(UserID,3)=0 then
    begin
    if Groups.GetStatus(UserID,0)>0 then
      Result:=scu_OffLine
    else
      Result:=scu_Unknown;
    end
  else
    case Groups.GetStatus(UserID,0) of
      1..3: Result:=scu_Passive;
      4..9: Result:=scu_Invited;
      10:   Result:=scu_Active;
      else  Result:=scu_Unknown;
      end;
  end;

procedure TRtcGateStreamerLink.ConfirmPackSent;
  begin
  if Client=nil then Exit;

  if Client.Ready then
    begin
    if LastPackSent<64000 then
      Inc(LastPackSent)
    else
      LastPackSent:=1;
    SendToGroup(cid_GroupConfirmSend,Word2Bytes(LastPackSent));
    end;
  end;

function TRtcGateStreamerLink.IsControlPackage(Data:TRtcGateClientData): boolean;
  begin
  Result:=(Data.ToGroupID=MyGroupID) and
          (Groups.GetStatus(Data.UserID,1)>=5);
  end;

function TRtcGateStreamerLink.IsMyPackage(Data:TRtcGateClientData): boolean;
  begin
  Result:=(Data.ToGroupID=MyGroupID) and
          (Groups.GetStatus(Data.UserID,0)>=5);
  end;

procedure TRtcGateStreamerLink.DoSendStart;
  begin
  // Initialize Streaming components
  end;

procedure TRtcGateStreamerLink.DoSendNext;
  begin
  // Ready to Stream the Next Package
  end;

procedure TRtcGateStreamerLink.DoSendStop;
  begin
  // Deinitialize Streaming components
  end;

end.
