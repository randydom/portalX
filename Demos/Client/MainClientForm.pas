unit MainClientForm;

{ Use the "GateCli" component to configure this Client to connect with your Gateway. }

interface

uses
  Windows, Messages, SysUtils, Variants,
  Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons,

  rtcInfo,
  rtcLog,
  rtcConn,
  rtcSyncObjs,

  rtcGateConst,
  rtcGateCli,

  rtcXGateCIDs,

  memStrList,

  ScreenHostForm,
  ScreenViewForm,
  rtcDataCli;

{$include rtcDeploy.inc}

var
  MyFileName:String='';

type
  TMsgType=(msg_Input,msg_Output,msg_Speed,msg_Error,msg_Status,msg_Group);

type
  TGateClientForm = class(TForm)
    MainPanel: TPanel;
    StatusUpdate: TTimer;
    InfoPanel: TPanel;
    l_Status1: TLabel;
    l_Status2: TLabel;
    Panel1: TPanel;
    lblRecvBufferSize: TLabel;
    lblSendBuffSize: TLabel;
    eYourID: TEdit;
    GateCli: TRtcHttpGateClient;
    Label1: TLabel;
    btnShowScreen: TButton;
    eUsers: TListBox;
    ScreenLink: TRtcGateClientLink;
    btnReset: TSpeedButton;
    btnCLR: TLabel;
    shInput: TShape;
    shOutput: TShape;
    Label2: TLabel;
    Label3: TLabel;
    procedure btnCLRClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure StatusUpdateTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure eUsersClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnShowScreenClick(Sender: TObject);
    procedure GateCliBeforeLogInGUI(Client: TRtcHttpGateClient;
      State: TRtcGateClientStateInfo);
    procedure GateCliAfterLoginFailGUI(Client: TRtcHttpGateClient;
      State: TRtcGateClientStateInfo);
    procedure GateCliAfterLogOutGUI(Client: TRtcHttpGateClient;
      State: TRtcGateClientStateInfo);
    procedure GateCliDataFilter(Client: TRtcHttpGateClient;
      Data: TRtcGateClientData; var Wanted: Boolean);
    procedure GateCliInfoFilter(Client: TRtcHttpGateClient;
      Data: TRtcGateClientData; var Wanted: Boolean);
    procedure GateCliReadyToSend(Client: TRtcHttpGateClient;
      State: TRtcGateClientStateInfo; var WantGUI,
      WantBackThread: Boolean);
    procedure GateCliStreamResetGUI(Client: TRtcHttpGateClient;
      State: TRtcGateClientStateInfo);
    procedure GateCliAfterLoggedInGUI(Client: TRtcHttpGateClient;
      State: TRtcGateClientStateInfo);
    procedure ScreenLinkDataFilter(Client: TRtcHttpGateClient;
      Data: TRtcGateClientData; var Wanted: Boolean);
    procedure GateCliInfoReceived(Client: TRtcHttpGateClient;
      Data: TRtcGateClientData; var WantGUI, WantBackThread: Boolean);
    procedure GateCliInfoReceivedGUI(Client: TRtcHttpGateClient;
      Data: TRtcGateClientData);
    procedure ScreenLinkDataReceivedGUI(Client: TRtcHttpGateClient;
      Data: TRtcGateClientData);

  public
    FCS:TRtcCritSec;
    sStatus1,sStatus2:String;

    FLoginStart:Cardinal;
    CntReset:integer;

    FScreenUsers:TStrList;

    NeedProviderChange:boolean;

    procedure PrintMsg(const s:String; t:TMsgType);
  end;

var
  GateClientForm: TGateClientForm;

implementation

{$R *.dfm}

function FillZero(const s:RtcString;len:integer):RtcString;
  begin
  Result:=s;
  while length(Result)<len do
    Result:='0'+Result;
  end;

function Time2Str(v:TDateTime):RtcString;
  var
    hh,mm,ss,ms:word;
  begin
  DecodeTime(v, hh,mm,ss,ms);
  Result:=FillZero(Int2Str(hh),2)+':'+FillZero(Int2Str(mm),2)+':'+FillZero(Int2Str(ss),2);
  end;

function KSeparate(const s:String):String;
  var
    i,len:integer;
  begin
  Result:='';
  i:=0;len:=length(s);
  while i<len do
    begin
    Result:=s[len-i]+Result;
    Inc(i);
    if (i mod 3=0) and (i<len) then Result:='.'+Result;
    end;
  end;

procedure TGateClientForm.FormCreate(Sender: TObject);
  begin
  StartLog;

  NeedProviderChange:=False;

  FCS:=TRtcCritSec.Create;
  sStatus1:='';
  sStatus2:='';

  MyFileName:=AppFileName;

  FScreenUsers:=tStrList.Create(16);

  GateCli.AutoLogin:=True;
  end;

procedure TGateClientForm.FormDestroy(Sender: TObject);
  begin
  FreeAndNil(FScreenUsers);

  FreeAndNil(FCS);
  end;

procedure TGateClientForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  begin
  GateCli.AutoLogin:=False;
  CanClose:=True;
  end;

procedure TGateClientForm.btnCLRClick(Sender: TObject);
  begin
  CntReset:=0;
  btnCLR.Color:=clWhite;
  btnCLR.Font.Color:=clNavy;
  btnCLR.Caption:='CLR';
  end;

procedure TGateClientForm.StatusUpdateTimer(Sender: TObject);
  begin
  case GateCli.State.InputState of
    ins_Connecting: shInput.Brush.Color:=clYellow;
    ins_Closed:     shInput.Brush.Color:=clRed;
    ins_Prepare:    shInput.Brush.Color:=clBlue;
    ins_Start:      shInput.Brush.Color:=clGreen;
    ins_Recv:       shInput.Brush.Color:=clLime;
    ins_Idle:       shInput.Brush.Color:=clGreen;
    ins_Done:       shInput.Brush.Color:=clNavy;
    end;
  if GateCli.State.InputState=ins_Closed then
    shInput.Pen.Color:=shInput.Brush.Color
  else
    case GateCli.State.PingInCnt of
      0:shInput.Pen.Color:=clWhite;
      1:shInput.Pen.Color:=clGreen;
      2:shInput.Pen.Color:=clLime;
      3:shInput.Pen.Color:=clBlack;
      end;

  case GateCli.State.OutputState of
    outs_Connecting:  shOutput.Brush.Color:=clYellow;
    outs_Closed:      shOutput.Brush.Color:=clRed;
    outs_Prepare:     shOutput.Brush.Color:=clBlue;
    outs_Start:       shOutput.Brush.Color:=clGreen;
    outs_Send:        shOutput.Brush.Color:=clLime;
    outs_Idle:        shOutput.Brush.Color:=clGreen;
    outs_Done:        shOutput.Brush.Color:=clNavy;
    end;
  if GateCli.State.OutputState=outs_Closed then
    shOutput.Pen.Color:=shOutput.Brush.Color
  else
    case GateCli.State.PingOutCnt of
      0:shOutput.Pen.Color:=clWhite;
      1:shOutput.Pen.Color:=clGreen;
      2:shOutput.Pen.Color:=clLime;
      3:shOutput.Pen.Color:=clBlack;
      end;
  lblSendBuffSize.Caption:=KSeparate(Int2Str(GateCli.State.TotalSent div 1024))+'K';
  lblRecvBufferSize.Caption:=KSeparate(Int2Str(GateCli.State.TotalReceived div 1024))+'K';

  FCS.Acquire;
  try
    l_Status1.Caption:=sStatus1;
    l_Status2.Caption:=sStatus2;
  finally
    FCS.Release;
    end;
  end;

procedure TGateClientForm.PrintMsg(const s: String; t:TMsgType);
  begin
  FCS.Acquire;
  try
    case t of
      msg_Input:
        sStatus1:=Time2Str(Now)+' '+s;
      msg_Output:
        sStatus2:=Time2Str(Now)+' '+s;
      msg_Group:
        sStatus1:=Time2Str(Now)+' '+s;
      msg_Status:
        begin
        sStatus1:=Time2Str(Now)+' '+s;
        sStatus2:='';
        end;
      msg_Error:
        sStatus2:=Time2Str(Now)+' '+s;
      end;
  finally
    FCS.Release;
    end;

(*
  case t of
    msg_Input:
      Log(s,IntToStr(GateCli.MyUID)+'_DATA');
    msg_Output:
      Log(s,IntToStr(GateCli.MyUID)+'_DATA');
    msg_Group:
      Log(s,IntToStr(GateCli.MyUID)+'_DATA');
    msg_Speed:
      Log(s,IntToStr(GateCli.MyUID)+'_CONN');
    msg_Status:
      if GateCli.MyUID>0 then
        Log(s,IntToStr(GateCli.MyUID)+'_CONN');
    msg_Error:
      if GateCli.MyUID>0 then
        Log(s,IntToStr(GateCli.MyUID)+'_CONN');
    end;
*)
  end;

procedure TGateClientForm.eUsersClick(Sender: TObject);
  var
    UID,Key:String;
    UserID,GroupID:TGateUID;
    i:integer;
  begin
  if GateCli.Ready then
    begin
    if (eUsers.Items.Count>0) and (eUsers.ItemIndex>=0) then
      begin
      UID:=Trim(eUsers.Items.Strings[eUsers.ItemIndex]);
      eUsers.Items.Delete(eUsers.ItemIndex);

      Key:=FScreenUsers.search(UID);
      if Key<>'' then
        begin
        FScreenUsers.remove(UID);
        i:=Pos('/',UID);
        UserID:=StrToInt(Copy(UID,1,i-1));
        GroupID:=StrToInt(Copy(UID,i+1,length(UID)-i));

        // Open a new Screen View Form
        NewScreenViewForm(GateCli,UserID,GroupID,Key);
        end;
      end;
    end;
  end;

procedure TGateClientForm.btnResetClick(Sender: TObject);
  begin
  NeedProviderChange:=True;
  GateCli.ResetStreams;
  end;

procedure TGateClientForm.btnShowScreenClick(Sender: TObject);
  begin
  if GateCli.Ready then
    GetScreenHostForm(GateCli);
  end;

procedure TGateClientForm.GateCliBeforeLogInGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  FLoginStart:=GetAppRunTime;

  CntReset:=0;
  btnCLR.Color:=clWhite;
  btnCLR.Font.Color:=clNavy;
  btnCLR.Caption:='CLR';

  shInput.Brush.Color:=clYellow;
  shInput.Pen.Color:=clWhite;
  shOutput.Brush.Color:=clYellow;
  shOutput.Pen.Color:=clWhite;
  PrintMsg('Logging in ...',msg_Status);

  StatusUpdate.Enabled:=True;
  end;

procedure TGateClientForm.GateCliAfterLoginFailGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  if Client.UseWinHTTP then // WinHTTP -> async WinSock
    begin
    btnReset.Caption:='AS';
    Client.UseBlocking:=False;
    Client.UseProxy:=False;
    Client.UseWinHTTP:=False;
    end
  else if Client.UseProxy then // WinInet -> WinHTTP
    begin
    btnReset.Caption:='HT';
    Client.UseWinHTTP:=True;
    end
  else if Client.UseBlocking then // blocking WinSock -> WinInet
    begin
    btnReset.Caption:='IE';
    Client.UseProxy:=True;
    end
  else // async WinSock -> blocking WinSock
    begin
    btnReset.Caption:='BS';
    Client.UseBlocking:=True;
    end;

  StatusUpdate.Enabled:=False;
  StatusUpdateTimer(nil);

  PrintMsg('Login attempt FAILED.',msg_Status);
  if State.LastError<>'' then
    PrintMsg(State.LastError, msg_Error);

  btnCLR.Color:=clRed;
  btnCLR.Font.Color:=clYellow;
  end;

procedure TGateClientForm.GateCliAfterLogOutGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  PrintMsg('Logged OUT.',msg_Status);
  if State.LastError<>'' then
    PrintMsg(State.LastError,msg_Error);

  StatusUpdate.Enabled:=False;

  if btnCLR.Caption<>'CLR' then
    begin
    btnCLR.Color:=clRed;
    btnCLR.Font.Color:=clYellow;
    end;

  StatusUpdateTimer(nil);
  end;

procedure TGateClientForm.GateCliDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: Boolean);
  begin
  if Data.Footer or not Data.ToBuffer then
    PrintMsg('<'+IntToStr(Length(Data.Content) div 1024)+'K id '+IntToStr(Data.UserID), msg_Input);
  end;

procedure TGateClientForm.GateCliReadyToSend(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo; var WantGUI, WantBackThread: Boolean);
  begin
  PrintMsg('Ready ('+FloatToStr((GetAppRunTime-FLoginStart)/RUN_TIMER_PRECISION)+' s).',msg_Output);
  FLoginStart:=GetAppRunTime;
  end;

procedure TGateClientForm.GateCliStreamResetGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  if NeedProviderChange then
    begin
    NeedProviderChange:=False;
    if Client.UseWinHTTP then // WinHTTP -> async WinSock
      begin
      btnReset.Caption:='AS';
      Client.UseBlocking:=False;
      Client.UseProxy:=False;
      Client.UseWinHTTP:=False;
      end
    else if Client.UseProxy then // WinInet -> WinHTTP
      begin
      btnReset.Caption:='HT';
      Client.UseWinHTTP:=True;
      end
    else if Client.UseBlocking then // blocking WinSock -> WinInet
      begin
      btnReset.Caption:='IE';
      Client.UseProxy:=True;
      end
    else // async WinSock -> blocking WinSock
      begin
      btnReset.Caption:='BS';
      Client.UseBlocking:=True;
      end;
    end;

  FLoginStart:=GetAppRunTime;

  Inc(CntReset);
  btnCLR.Color:=clYellow;
  btnCLR.Font.Color:=clRed;
  btnCLR.Caption:=IntToStr(CntReset);

  if Client.Active then
    PrintMsg('#LOST ('+FloatToStr(State.InputResetTime/RUN_TIMER_PRECISION)+'s / '+FloatToStr(State.OutputResetTime/RUN_TIMER_PRECISION)+'s)',msg_Status)
  else
    PrintMsg('#FAIL ('+FloatToStr(State.InputResetTime/RUN_TIMER_PRECISION)+'s / '+FloatToStr(State.OutputResetTime/RUN_TIMER_PRECISION)+'s)',msg_Status);
  if State.LastError<>'' then
    PrintMsg(State.LastError, msg_Error);

  eUsers.Clear;

  Client.Groups.ClearAllStates;
  FScreenUsers.removeall;
  end;

procedure TGateClientForm.GateCliAfterLoggedInGUI(Client: TRtcHttpGateClient; State: TRtcGateClientStateInfo);
  begin
  PrintMsg('Logged IN ('+FloatToStr((GetAppRunTime-FLoginStart)/RUN_TIMER_PRECISION)+' s).',msg_Status);

  eYourID.Text:=LWord2Str(State.MyUID);

  StatusUpdateTimer(nil);
  end;

procedure TGateClientForm.GateCliInfoFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: Boolean);
  begin
  case Data.Command of
    gc_UserOnline,
    gc_UserOffline,
    gc_UserJoined,
    gc_UserLeft,
    gc_JoinedUser,
    gc_LeftUser,
    gc_Error:       Wanted:=True;
    end;
  end;

procedure TGateClientForm.GateCliInfoReceived(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var WantGUI, WantBackThread: Boolean);
  begin
  case Data.Command of
    gc_Error:       PrintMsg('ERR #'+IntToStr(Data.ErrCode)+' from User '+IntToStr(Data.UserID),msg_Group);
    gc_UserOnline:  PrintMsg(IntToStr(Data.UserID)+' ON-Line',msg_Group);
    gc_UserOffline: PrintMsg(IntToStr(Data.UserID)+' OFF-Line',msg_Group);

    gc_UserJoined,
    gc_UserLeft,
    gc_JoinedUser,
    gc_LeftUser:    WantGUI:=True;
    end;
  end;

procedure TGateClientForm.GateCliInfoReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
  var
    s:String;
  begin
  case Data.Command of
    gc_UserJoined:  begin
                    S:=IntToStr(Data.UserID)+'/'+INtToStr(Data.GroupID);
                    PrintMsg('OUT +'+S,msg_Group);
                    end;
    gc_UserLeft:    begin
                    S:=IntToStr(Data.UserID)+'/'+IntToStr(Data.GroupID);
                    PrintMsg('OUT -'+S,msg_Group);
                    end;
    gc_JoinedUser:  begin
                    Client.Groups.SetStatus(Data.UserID,Data.GroupID,10);
                    S:=IntToStr(Data.UserID)+'/'+IntToStr(Data.GroupID);
                    PrintMsg('IN +'+S,msg_Group);
                    if FScreenUsers.search(S)<>'' then
                      begin
                      FScreenUsers.remove(S);
                      if eUsers.Items.IndexOf(S)>=0 then
                        eUsers.Items.Delete(eUsers.Items.IndexOf(S));
                      end;
                    end;
    gc_LeftUser:    begin
                    Client.Groups.ClearStatus(Data.UserID,Data.GroupID);
                    S:=IntToStr(Data.UserID)+'/'+IntToStr(Data.GroupID);
                    PrintMsg('IN -'+S,msg_Group);
                    end;
    end;
  end;

procedure TGateClientForm.ScreenLinkDataFilter(Client: TRtcHttpGateClient; Data: TRtcGateClientData; var Wanted: Boolean);
  begin
  if (Data.CallID=cid_ImageInvite) and (Data.ToGroupID>0) then
    begin
    if Data.Footer then
      Wanted:=(length(Data.Content)>0) and (Client.Groups.GetStatus(Data.UserID,Data.ToGroupID)=0)
    else if Data.Header then
      Data.ToBuffer:=True;
    end
  else if (Data.CallID=cid_GroupClosed) and (Data.GroupID>0) then
    begin
    if Data.Footer then
      Wanted:=True
    else if Data.Header then
      Data.ToBuffer:=True;
    end;
  end;

procedure TGateClientForm.ScreenLinkDataReceivedGUI(Client: TRtcHttpGateClient; Data: TRtcGateClientData);
  var
    UID:RtcString;
    i:integer;
  begin
  if (Data.CallID=cid_ImageInvite) and (Data.ToGroupID>0) then
    begin
    UID:=Int2Str(Data.UserID)+'/'+Int2Str(Data.ToGroupID);
    if FScreenUsers.search(UID)='' then
      begin
      // Add UserID+GroupID to Screen Users invitation list
      eUsers.Items.Add(UID);
      // Store Invitation Key for Screen with UserID+GroupID
      FScreenUsers.insert(UID,RtcBytesToString(Data.Content));
      if GetActiveWindow<>Handle then MessageBeep(0);
      end;
    end
  else if (Data.CallID=cid_GroupClosed) and (Data.GroupID>0) then
    begin
    UID:=Int2Str(Data.UserID)+'/'+Int2Str(Data.GroupID);
    if FScreenUsers.search(UID)<>'' then
      begin
      i:=eUsers.Items.IndexOf(UID);
      if i>=0 then
        eUsers.Items.Delete(i);
      FScreenUsers.remove(UID);
      end;
    end;
  end;

end.
