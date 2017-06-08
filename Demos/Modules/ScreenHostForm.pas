unit ScreenHostForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, ComCtrls, ExtCtrls,

  rtcInfo, rtcTypes,
  rtcGateCli, rtcGateConst,

  rtcXGateStream,
  rtcXImgCapture,
  rtcXScreenCapture;

type
  TScreenHostFrm = class(TForm)
    Panel2: TPanel;
    Panel3: TPanel;
    btnAddUser: TBitBtn;
    MainPanel: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Bevel5: TBevel;
    eQualityLum: TTrackBar;
    xHQColor: TCheckBox;
    eHQDepth: TTrackBar;
    eQualityCol: TTrackBar;
    xAllMonitors: TCheckBox;
    xMirrorDriver: TCheckBox;
    xWinAero: TCheckBox;
    eMotionVert: TTrackBar;
    eMotionHorz: TTrackBar;
    eMotionFull: TTrackBar;
    eColorDepth: TTrackBar;
    xLayeredWindows: TCheckBox;
    xColorReduce: TCheckBox;
    SubPanel: TPanel;
    xMotionComp: TCheckBox;
    xJPG: TCheckBox;
    xRLE: TCheckBox;
    xLZW: TCheckBox;
    Label5: TLabel;
    cbFPS: TTrackBar;
    Panel1: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    eUsers: TListBox;
    eControls: TListBox;
    btnStart: TBitBtn;
    cbFPM: TTrackBar;
    Label1: TLabel;
    cbFPV: TTrackBar;
    Label6: TLabel;
    Panel8: TPanel;
    btnCFG: TSpeedButton;
    Label7: TLabel;
    Bevel1: TBevel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAddUserClick(Sender: TObject);
    procedure eUsersDblClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure xWinAeroClick(Sender: TObject);
    procedure xMirrorDriverClick(Sender: TObject);
    procedure eControlsDblClick(Sender: TObject);
    procedure eControlsDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure eUsersDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure eControlsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure eUsersDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure btnCFGClick(Sender: TObject);
    procedure xAllMonitorsClick(Sender: TObject);
    procedure xLayeredWindowsClick(Sender: TObject);
    procedure xMotionCompClick(Sender: TObject);
    procedure xJPGClick(Sender: TObject);
    procedure xRLEClick(Sender: TObject);
    procedure xLZWClick(Sender: TObject);
    procedure eColorDepthChange(Sender: TObject);
    procedure xColorReduceClick(Sender: TObject);
    procedure eQualityLumChange(Sender: TObject);
    procedure eQualityColChange(Sender: TObject);
    procedure eHQDepthChange(Sender: TObject);
    procedure xHQColorClick(Sender: TObject);
    procedure eMotionVertChange(Sender: TObject);
    procedure eMotionHorzChange(Sender: TObject);
    procedure eMotionFullChange(Sender: TObject);
    procedure cbFPMChange(Sender: TObject);
    procedure cbFPSChange(Sender: TObject);
    procedure cbFPVChange(Sender: TObject);
  private
    { Private declarations }
  public
    SCLink:TRtcScreenCaptureLink;

    { Public declarations }
    procedure UpdateUserStatus(Sender:TObject; UserID:TGateUID);

    procedure SendingActive(Sender: TObject);
    procedure SendingIdle(Sender: TObject);
    procedure SendingPaused(Sender: TObject);
  end;

function GetScreenHostForm(Cli:TRtcHttpGateClient):TScreenHostFrm;

implementation

{$R *.dfm}

var
  ScreenHostFrm: TScreenHostFrm = nil;

function GetScreenHostForm(Cli:TRtcHttpGateClient):TScreenHostFrm;
  begin
  if assigned(ScreenHostFrm) then
    begin
    Result:=ScreenHostFrm;
    Result.WindowState:=wsNormal;
    Result.Position:=poScreenCenter;
    Result.BringToFront;
    end
  else
    begin
    Result:=TScreenHostFrm.Create(Application);
    Result.SCLink.Client:=Cli;
    Result.Caption:=IntToStr(Cli.MyUID)+': Screen Host';
    Result.Show;

    ScreenHostFrm:=Result;
    end;
  end;

procedure TScreenHostFrm.FormCreate(Sender: TObject);
  begin
  SCLink:=TRtcScreenCaptureLink.Create(self);
  SCLink.OnUserStatusChange:=UpdateUserStatus;
  SCLink.OnSendingPaused:=SendingPaused;
  SCLink.OnSendingIdle:=SendingIdle;
  SCLink.OnSendingActive:=SendingActive;

  btnStart.Caption:='Waiting'#13#10+'for Viewers';
  btnStart.Font.Color:=clMaroon;
  end;

procedure TScreenHostFrm.FormDestroy(Sender: TObject);
  begin
  RtcFreeAndNil(SCLink);
  ScreenHostFrm:=nil;
  end;

procedure TScreenHostFrm.FormClose(Sender: TObject; var Action: TCloseAction);
  begin
  SCLink.Client:=nil;
  Action:=caFree;
  end;

procedure TScreenHostFrm.btnAddUserClick(Sender: TObject);
  var
    UID:String;
  begin
  if not SCLink.Client.Ready then Exit;
  UID:='';
  if InputQuery('Invite User to View the Screen','Enter remote User ID',UID) then
    SCLink.UserInviteToGroup(Str2IntDef(Trim(UID),0));
  end;

procedure TScreenHostFrm.btnStartClick(Sender: TObject);
  begin
  if SCLink.NowSending then
    begin
    SCLink.PauseSending;
    btnStart.Caption:='START';
    btnStart.Font.Color:=clNavy;
    end
  else
    begin
    SCLink.ResumeSending;
    if SCLink.NowPaused then
      begin
      btnStart.Caption:='Waiting'#13#10+'for Viewers';
      btnStart.Font.Color:=clMaroon;
      end
    else
      begin
      btnStart.Caption:='Sending...';
      btnStart.Font.Color:=clRed;
      end;
    end;
  end;

procedure TScreenHostFrm.UpdateUserStatus(Sender:TObject; UserID: TGateUID);
  var
    inMiddle,
    inActive,
    inPassive:boolean;
    UID:RtcString;
    i:integer;
  begin
  UID:=IntToStr(UserID);

  inActive:=False;
  inPassive:=False;
  inMiddle:=False;
  if not SCLink.IsUserInControl(UserID) then
    case SCLink.CheckUserStatus(UserID) of
      scu_Active: inActive:=True;
      scu_Invited: inMiddle:=True;
      scu_Passive: inPassive:=True;
      end;

  i:=eUsers.Items.IndexOf('- '+UID);
  if (inPassive=True) and (i<0) then
    eUsers.Items.Add('- '+UID)
  else if (inPassive=False) and (i>=0) then
    eUsers.Items.Delete(i);

  i:=eUsers.Items.IndexOf('* '+UID);
  if (inMiddle=True) and (i<0) then
    eUsers.Items.Add('* '+UID)
  else if (inMiddle=False) and (i>=0) then
    eUsers.Items.Delete(i);

  i:=eUsers.Items.IndexOf(UID);
  if (inActive=True) and (i<0) then
    eUsers.Items.Add(UID)
  else if (inActive=False) and (i>=0) then
    eUsers.Items.Delete(i);

  inActive:=False;
  inPassive:=False;
  inMiddle:=False;
  if SCLink.IsUserInControl(UserID) then
    case SCLink.CheckUserStatus(UserID) of
      scu_Active: inActive:=True;
      scu_Invited: inMiddle:=True;
      scu_Passive: inPassive:=True;
      end;

  i:=eControls.Items.IndexOf('- '+UID);
  if (inPassive=True) and (i<0) then
    eControls.Items.Add('- '+UID)
  else if (inPassive=False) and (i>=0) then
    eControls.Items.Delete(i);

  i:=eControls.Items.IndexOf('* '+UID);
  if (inMiddle=True) and (i<0) then
    eControls.Items.Add('* '+UID)
  else if (inMiddle=False) and (i>=0) then
    eControls.Items.Delete(i);

  i:=eControls.Items.IndexOf(UID);
  if (inActive=True) and (i<0) then
    eControls.Items.Add(UID)
  else if (inActive=False) and (i>=0) then
    eControls.Items.Delete(i);
  end;

procedure TScreenHostFrm.eControlsDragOver(Sender, Source: TObject; X,Y: Integer; State: TDragState; var Accept: Boolean);
  begin
  if Source=eUsers then
    Accept:=True;
  end;

procedure TScreenHostFrm.eUsersDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
  begin
  if Source=eControls then
    Accept:=True;
  end;

procedure TScreenHostFrm.eControlsDragDrop(Sender, Source: TObject; X, Y: Integer);
  var
    UID:String;
    UserID:TGateUID;
  begin
  if Source<>eUsers then Exit;

  if (eUsers.Items.Count>0) and (eUsers.ItemIndex>=0) then
    begin
    UID:=Trim(eUsers.Items.Strings[eUsers.ItemIndex]);
    if Copy(UID,1,2)='* ' then Delete(UID,1,2);
    if Copy(UID,1,2)='- ' then Delete(UID,1,2);
    UserID:=StrToInt(UID);

    SCLink.UserEnableControl(UserID);
    end;
  end;

procedure TScreenHostFrm.eUsersDragDrop(Sender, Source: TObject; X, Y: Integer);
  var
    UID:String;
    UserID:TGateUID;
  begin
  if Source<>eControls then Exit;

  if (eControls.Items.Count>0) and (eControls.ItemIndex>=0) then
    begin
    UID:=Trim(eControls.Items.Strings[eControls.ItemIndex]);
    if Copy(UID,1,2)='* ' then Delete(UID,1,2);
    if Copy(UID,1,2)='- ' then Delete(UID,1,2);
    UserID:=StrToInt(UID);

    SCLink.UserDisableControl(UserID);
    end;
  end;

procedure TScreenHostFrm.eUsersDblClick(Sender: TObject);
  var
    UID:String;
    UserID:TGateUID;
  begin
  if (eUsers.Items.Count>0) and (eUsers.ItemIndex>=0) then
    begin
    UID:=Trim(eUsers.Items.Strings[eUsers.ItemIndex]);
    if Copy(UID,1,2)='* ' then Delete(UID,1,2);
    if Copy(UID,1,2)='- ' then Delete(UID,1,2);
    UserID:=StrToInt(UID);

    if not SCLink.UserInviteToGroup(UserID) then
      SCLink.UserKickFromGroup(UserID);
    end;
  end;

procedure TScreenHostFrm.eControlsDblClick(Sender: TObject);
  var
    UID:String;
    UserID:TGateUID;
  begin
  if (eControls.Items.Count>0) and (eControls.ItemIndex>=0) then
    begin
    UID:=Trim(eControls.Items.Strings[eControls.ItemIndex]);
    if Copy(UID,1,2)='* ' then Delete(UID,1,2);
    if Copy(UID,1,2)='- ' then Delete(UID,1,2);
    UserID:=StrToInt(UID);

    if not SCLink.UserInviteToGroup(UserID) then
      SCLink.UserKickFromGroup(UserID);
    end;
  end;

procedure TScreenHostFrm.btnCFGClick(Sender: TObject);
  begin
  MainPanel.Visible:=not MainPanel.Visible;
  end;

procedure TScreenHostFrm.xMirrorDriverClick(Sender: TObject);
  begin
  SCLink.CaptureMirrorDriver:=xMirrorDriver.Checked;
  end;

procedure TScreenHostFrm.xWinAeroClick(Sender: TObject);
  begin
  SCLink.CaptureWindowsAero:=xWinAero.Checked;
  end;

procedure TScreenHostFrm.xAllMonitorsClick(Sender: TObject);
  begin
  SCLink.CaptureAllMonitors:=xAllMonitors.Checked;
  end;

procedure TScreenHostFrm.xLayeredWindowsClick(Sender: TObject);
  begin
  SCLink.CaptureLayeredWindows:=xLayeredWindows.Checked;
  end;

procedure TScreenHostFrm.xMotionCompClick(Sender: TObject);
  begin
  SCLink.CompressMotion:=xMotionComp.Checked;
  end;

procedure TScreenHostFrm.xJPGClick(Sender: TObject);
  begin
  SCLink.CompressJPEG:=xJPG.Checked;
  end;

procedure TScreenHostFrm.xRLEClick(Sender: TObject);
  begin
  SCLink.CompressRLE:=xRLE.Checked;
  end;

procedure TScreenHostFrm.xLZWClick(Sender: TObject);
  begin
  SCLink.CompressLZW:=xLZW.Checked;
  end;

procedure TScreenHostFrm.eColorDepthChange(Sender: TObject);
  begin
  SCLink.ColorDepth:=eColorDepth.Position;
  end;

procedure TScreenHostFrm.xColorReduceClick(Sender: TObject);
  begin
  SCLink.ColorReduce:=xColorReduce.Checked;
  end;                                        

procedure TScreenHostFrm.eQualityLumChange(Sender: TObject);
  begin
  SCLink.JPEGDetailLevel:=eQualityLum.Position;
  end;

procedure TScreenHostFrm.eQualityColChange(Sender: TObject);
  begin
  SCLink.JPEGColorLevel:=eQualityCol.Position;
  end;

procedure TScreenHostFrm.eHQDepthChange(Sender: TObject);
  begin
  SCLink.JPEGHiQDepth:=eHQDepth.Position;
  end;

procedure TScreenHostFrm.xHQColorClick(Sender: TObject);
  begin
  SCLink.JPEGHiQColor:=xHQColor.Checked;
  end;

procedure TScreenHostFrm.eMotionVertChange(Sender: TObject);
  begin
  SCLink.MotionVertScan:=eMotionVert.Position;
  end;

procedure TScreenHostFrm.eMotionHorzChange(Sender: TObject);
  begin
  SCLink.MotionHorzScan:=eMotionHorz.Position;
  end;

procedure TScreenHostFrm.eMotionFullChange(Sender: TObject);
  begin
  SCLink.MotionFullScan:=eMotionFull.Position;
  end;

procedure TScreenHostFrm.cbFPMChange(Sender: TObject);
  begin
  SCLink.GrabMouseRate:=cbFPM.Position;
  end;

procedure TScreenHostFrm.cbFPSChange(Sender: TObject);
  begin
  SCLink.GrabScreenRate:=cbFPS.Position;
  end;

procedure TScreenHostFrm.cbFPVChange(Sender: TObject);
  begin
  SCLink.GrabFrameBuffer:=cbFPV.Position;
  end;

procedure TScreenHostFrm.SendingActive(Sender: TObject);
  begin
  btnStart.Font.Color:=clMaroon;
  btnStart.Caption:='Sending ...';
  end;

procedure TScreenHostFrm.SendingIdle(Sender: TObject);
  begin
  btnStart.Font.Color:=clNavy;
  btnStart.Caption:='Waiting'#13#10+'for Viewers';
  end;

procedure TScreenHostFrm.SendingPaused(Sender: TObject);
  begin
  btnStart.Font.Color:=clRed;
  btnStart.Caption:='Click'#13#10+'to START';
  end;

end.
