unit ScreenViewForm;

interface

uses
  Windows, Messages, SysUtils, Variants,
  Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls,

  rtcTypes,
  rtcThrPool,
  rtcInfo,

  rtcGateConst,
  rtcGateCli,

  rtcVImgPlayback;

const
  HiddenCursor:TCursor=crNone;
  VisibleCursor:TCursor=crHandPoint;

type
  TScreenViewFrm = class(TForm)
    sbMainBox: TScrollBox;
    pbScreenView: TPaintBox;
    pStartInfo: TPanel;

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pbScreenViewPaint(Sender: TObject);
    procedure pbScreenViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pStartInfoClick(Sender: TObject);
    procedure pbScreenViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbScreenViewMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DeactivateControl(Sender: TObject);
    procedure sbMainBoxMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);

  private
    { Private declarations }
  public
    { Public declarations }

    SCLink:TRtcImageVCLPlayback;
    WasActive:boolean;

    procedure SCLinkLogOut(Sender: TObject);
    procedure SCLinkDisconnect(Sender: TObject);
    procedure SCLinkHostOffLine(Sender: TObject);
    procedure SCLinkHostConnect(Sender: TObject);
    procedure SCLinkHostDisconnect(Sender: TObject);
    procedure SCLinkHostClosed(Sender: TObject);
    procedure SCLinkControlEnabled(Sender: TObject);
    procedure SCLinkControlDisabled(Sender: TObject);
    procedure SCLinkStartReceive(Sender: TObject);

    procedure SCLinkImageRepaint(Sender: TObject);

    procedure SCLinkCursorShow(Sender: TObject);
    procedure SCLinkCursorHide(Sender: TObject);
  end;

function NewScreenViewForm(Cli:TRtcHttpGateClient; UID,GID:TGateUID; const Key:RtcString):TScreenViewFrm;

implementation

{$R *.dfm}

function NewScreenViewForm(Cli:TRtcHttpGateClient; UID,GID:TGateUID; const Key:RtcString):TScreenViewFrm;
  begin
  if not Cli.Ready then
    raise ERtcGateClient.Create('No connection');

  Result:=TScreenViewFrm.Create(Application);
  Result.Caption:=IntToStr(Cli.MyUID)+': Screen from '+IntToStr(UID)+'/'+IntToStr(GID);
  Result.pStartInfo.Caption:='Waiting for the Host ...';
  Result.pStartInfo.Color:=clYellow;
  Result.pStartInfo.Font.Color:=clRed;
  Result.pStartInfo.Visible:=True;
  Result.Show;

  Result.SCLink.Client:=Cli;
  Result.SCLink.HostInviteAccept(UID,GID,Key);
  end;

procedure TScreenViewFrm.FormCreate(Sender: TObject);
  begin
  WasActive:=False;

  SCLink:=TRtcImageVCLPlayback.Create(nil);

  SCLink.OnImageRepaint:=SCLinkImageRepaint;

  SCLink.OnCursorShow:=SCLinkCursorShow;
  SCLink.OnCursorHide:=SCLinkCursorHide;

  SCLink.OnHostOffLine:=SCLinkHostOffLine;
  SCLink.OnHostConnect:=SCLinkHostConnect;
  SCLink.OnHostDisconnect:=SCLinkHostDisconnect;
  SCLink.OnHostClosed:=SCLinkHostClosed;
  SCLink.OnLogOut:=SCLinkLogOut;
  SCLink.OnDisconnect:=SCLinkDisconnect;
  SCLink.OnControlEnabled:=SCLinkControlEnabled;
  SCLink.OnControlDisabled:=SCLinkControlDisabled;
  SCLink.OnStartReceive:=SCLinkStartReceive;

  ClientWidth:=pbScreenView.Width;
  ClientHeight:=pbScreenView.Height;
  end;

procedure TScreenViewFrm.FormClose(Sender: TObject; var Action: TCloseAction);
  begin
  SCLink.Client:=nil;
  Action:=caFree;
  end;

procedure TScreenViewFrm.FormDestroy(Sender: TObject);
  begin
  RtcFreeAndNil(SCLink);
  end;

procedure TScreenViewFrm.SCLinkLogOut(Sender: TObject);
  begin
  Caption:=IntToStr(SCLink.Client.MyUID)+': Logged out ('+IntToStr(SCLink.HostUserID)+'/'+IntToStr(SCLink.HostGroupID)+')';
  pStartInfo.Caption:='Logged out.';
  pStartInfo.Color:=clRed;
  pStartInfo.Font.Color:=clYellow;
  pStartInfo.Visible:=True;
  end;

procedure TScreenViewFrm.SCLinkHostOffLine(Sender: TObject);
  begin
  Caption:=IntToStr(SCLink.Client.MyUID)+': Host is OFF-LINE ('+IntToStr(SCLink.HostUserID)+'/'+IntToStr(SCLink.HostGroupID)+')';
  pStartInfo.Caption:='Host is OFF-LINE';
  pStartInfo.Color:=clRed;
  pStartInfo.Font.Color:=clYellow;
  pStartInfo.Visible:=True;
  end;

procedure TScreenViewFrm.SCLinkHostConnect(Sender: TObject);
  begin
  Caption:=IntToStr(SCLink.Client.MyUID)+': Connected to '+IntToStr(SCLink.HostUserID)+'/'+IntToStr(SCLink.HostGroupID)+' as Viewer';
  pStartInfo.Caption:='Connected to Host';
  pStartInfo.Color:=clWhite;
  pStartInfo.Font.Color:=clBlack;
  pStartInfo.Visible:=True;
  end;

procedure TScreenViewFrm.SCLinkHostDisconnect(Sender: TObject);
  begin
  Caption:=IntToStr(SCLink.Client.MyUID)+': Disconnected from '+IntToStr(SCLink.HostUserID)+'/'+IntToStr(SCLink.HostGroupID);
  pStartInfo.Caption:='Lost connection to Host';
  pStartInfo.Color:=clRed;
  pStartInfo.Font.Color:=clYellow;
  pStartInfo.Visible:=True;
  end;

procedure TScreenViewFrm.SCLinkHostClosed(Sender: TObject);
  begin
  Caption:=IntToStr(SCLink.Client.MyUID)+': Session Closed ('+IntToStr(SCLink.HostUserID)+'/'+IntToStr(SCLink.HostGroupID)+')';
  pStartInfo.Caption:='Host Session closed';
  pStartInfo.Color:=clRed;
  pStartInfo.Font.Color:=clYellow;
  pStartInfo.Visible:=True;
  end;

procedure TScreenViewFrm.SCLinkDisconnect(Sender: TObject);
  begin
  Caption:=IntToStr(SCLink.Client.MyUID)+': Disconnected from '+IntToStr(SCLink.HostUserID)+'/'+IntToStr(SCLink.HostGroupID);
  pStartInfo.Caption:='Disconnected from Gateway';
  pStartInfo.Color:=clRed;
  pStartInfo.Font.Color:=clYellow;
  pStartInfo.Visible:=True;
  end;

procedure TScreenViewFrm.SCLinkControlEnabled(Sender: TObject);
  begin
  Caption:=IntToStr(SCLink.Client.MyUID)+': Connected to ('+IntToStr(SCLink.HostUserID)+'/'+IntToStr(SCLink.HostGroupID)+') as Control';
  pStartInfo.Caption:='Control Enabled';
  pStartInfo.Font.Color:=clBlack;
  end;

procedure TScreenViewFrm.SCLinkControlDIsabled(Sender: TObject);
  begin
  Caption:=IntToStr(SCLink.Client.MyUID)+': Connected to ('+IntToStr(SCLink.HostUserID)+'/'+IntToStr(SCLink.HostGroupID)+') as Viewer';
  pStartInfo.Caption:='Control Disabled';
  pStartInfo.Font.Color:=clBlack;
  end;

procedure TScreenViewFrm.SCLinkStartReceive(Sender: TObject);
  begin
  pStartInfo.Caption:='Receiving image ...';
  pStartInfo.Font.Color:=clBlack;
  pStartInfo.Visible:=True;
  end;

procedure TScreenViewFrm.SCLinkImageRepaint(Sender: TObject);
  begin
  if ( (pbScreenView.Width<>SCLink.ImageWidth) or
       (pbScreenView.Height<>SCLink.ImageHeight) ) then
    begin
    WasActive:=False;
    pbScreenView.Width:=SCLink.ImageWidth;
    pbScreenView.Height:=SCLink.ImageHeight;
    end;

  if pStartInfo.Visible or not WasActive then
    begin
    pStartInfo.Visible:=false;
    if not WasActive then
      begin
      WasActive:=True;
      if WindowState=wsNormal then
        begin
        if pbScreenView.Width<Screen.Width then
          ClientWidth:=pbScreenView.Width
        else
          Width:=Screen.Width;
        if pbScreenView.Height<Screen.Height then
          ClientHeight:=pbScreenView.Height
        else
          Height:=Screen.Height;
        if (Left>0) and (Left+Width>Screen.Width) then
          Left:=Screen.Width-Width;
        if (Top>0) and (Top+Height>Screen.Height) then
          Top:=Screen.Height-Height;
        end;
      end;
    end;

  pbScreenViewPaint(pbScreenView);
  end;

procedure TScreenViewFrm.SCLinkCursorHide(Sender:TObject);
  begin
  pbScreenView.Cursor:=HiddenCursor;
  Screen.Cursor:=HiddenCursor;
  ShowCursor(False);
  Screen.Cursor:=crDefault;
  end;

procedure TScreenViewFrm.SCLinkCursorShow(Sender:TObject);
  begin
  pbScreenView.Cursor:=VisibleCursor;
  Screen.Cursor:=VisibleCursor;
  ShowCursor(True);
  Screen.Cursor:=crDefault;
  end;

procedure TScreenViewFrm.pbScreenViewPaint(Sender: TObject);
  begin
  SCLink.DrawBitmap(pbScreenView.Canvas);
  end;

procedure TScreenViewFrm.pStartInfoClick(Sender: TObject);
  begin
  pStartInfo.Visible:=False;
  end;

procedure TScreenViewFrm.pbScreenViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  begin
  SCLink.MouseDown(X,Y,Ord(Button));
  end;

procedure TScreenViewFrm.pbScreenViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  begin
  SCLink.MouseMove(X,Y);
  end;

procedure TScreenViewFrm.pbScreenViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  begin
  SCLink.MouseUp(X,Y,Ord(Button));
  end;

procedure TScreenViewFrm.DeactivateControl(Sender: TObject);
  begin
  SCLink.MouseControl:=False;
  end;

procedure TScreenViewFrm.sbMainBoxMouseWheel(Sender: TObject;
    Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  begin
  SCLink.MouseWheel(WheelDelta);
  Handled:=True;
  end;

procedure TScreenViewFrm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  begin
  SCLink.KeyDown(Key);
  Key:=0;
  end;

procedure TScreenViewFrm.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  begin
  if Key=VK_TAB then // We don't get KeyDown events for TAB
    SCLink.KeyDown(Key);
  SCLink.KeyUp(Key);
  Key:=0;
  end;

end.
