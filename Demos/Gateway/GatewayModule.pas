unit GatewayModule;

interface

uses
  SysUtils, Classes,

  rtcTypes, rtcInfo, rtcLog,
  rtcConn, rtcGateSrv, rtcDataSrv;

type
  TGateModule = class(TDataModule)
    Gate: TRtcGateway;
    procedure GateBeforeUserLogin(Sender: TRtcConnection; UserID: Cardinal; var UserAuth,UserInfo: String; var SecondaryKey: String);
    procedure GateBeforeUserLogout(Sender: TRtcConnection; UserID: Cardinal; const UserAuth,UserInfo: String);
    procedure GateUserNotReady(Sender: TRtcConnection; UserID: Cardinal; const UserAuth,UserInfo: String);
    procedure GateUserReady(Sender: TRtcConnection; UserID: Cardinal; const UserAuth,UserInfo: String);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GateModule: TRtcGateway;

implementation

{$R *.dfm}

var
  GM:TGateModule=nil;

function GateModule: TRtcGateway;
  begin
  if not assigned(GM) then
    GM:=TGateModule.Create(nil);
  Result:=GM.Gate;
  end;

procedure TGateModule.GateBeforeUserLogin(Sender: TRtcConnection; UserID: Cardinal; var UserAuth,UserInfo: String; var SecondaryKey: String);
  begin
  Log('Before Log IN '+IntToStr(UserID)+': '+UserAuth+' / '+UserInfo);
  end;

procedure TGateModule.GateBeforeUserLogout(Sender: TRtcConnection; UserID: Cardinal; const UserAuth,UserInfo: String);
  begin
  Log('Before Log OUT '+IntToStr(UserID)+': '+UserAuth+' / '+UserInfo);
  end;

procedure TGateModule.GateUserNotReady(Sender: TRtcConnection; UserID: Cardinal; const UserAuth,UserInfo: String);
  begin
  Log('User NOT Ready '+IntToStr(UserID)+': '+UserAuth+' / '+UserInfo);
  Gate.RemoveUserFromChannel(UserID,'Master',False,True);
  end;

procedure TGateModule.GateUserReady(Sender: TRtcConnection; UserID: Cardinal; const UserAuth,UserInfo: String);
  begin
  Log('User Ready '+IntToStr(UserID)+': '+UserAuth+' / '+UserInfo);
  if UserAuth='Master' then
    Gate.AddListenerToChannel(UserID,'Master',255,False,True)
  else
    Gate.AddHostToChannel(UserID,'Master',0,False,True);
  end;

initialization
finalization
RtcFreeAndNil(GM);
end.
