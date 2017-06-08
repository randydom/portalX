unit rtcBlankOutForm;

{$INCLUDE rtcDefs.inc}

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  ExtCtrls,

  rtcTypes;

type
  TfmBlankoutForm = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Image1: TImage;
    Timer1: TTimer;
    procedure FormResize(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);

    procedure CreateParams(Var params: TCreateParams); override;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure RestoreScreen;

procedure BlankOutScreen(AllMonitors:boolean);

implementation

{$R *.dfm}

procedure TfmBlankOutForm.CreateParams(Var params: TCreateParams);
  begin
  inherited CreateParams( params );
  params.ExStyle := params.ExStyle or
                    WS_EX_APPWINDOW or
                    WS_EX_TRANSPARENT or
                    WS_EX_LAYERED or
                    WS_EX_NOPARENTNOTIFY or
                    WS_EX_NOINHERITLAYOUT or
                    WS_EX_NOACTIVATE;
  params.WndParent := GetDesktopWindow;
  end;

procedure TfmBlankoutForm.FormResize(Sender: TObject);
begin
  Panel1.Left := (ClientWidth - Panel1.Width) div 2;
  Panel1.Top := (ClientHeight - Panel1.Height) div 2;
end;

procedure TfmBlankoutForm.Timer1Timer(Sender: TObject);
begin
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
    SWP_NOACTIVATE);
  SetWindowPos(Handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
    SWP_NOACTIVATE);
end;

var
  fBlankoutForms  : TList = nil;

procedure RestoreScreen;
  var
    i: integer;
  begin
  if assigned(fBlankOutForms) then
    begin
    if fBlankoutForms.Count > 0 then
      begin
      for i := 0 to fBlankoutForms.Count - 1 do
        TObject(fBlankoutForms[i]).Free;
      fBlankoutForms.Clear;
      end;
    RtcFreeAndNil(fBlankOutForms);
    end;
  end;

procedure BlankOutScreen(AllMonitors:boolean);
  var
    hUser32                   : HMODULE;
    SetLayeredWindowAttributes: TSetLayeredWindowAttributes;
    rect                      : TRect;
    i                         : integer;
    ablnkform                 : TForm;
  begin
  if assigned(fBlankoutForms) then RestoreScreen;
  hUser32 := GetModuleHandle('USER32.DLL');
  if hUser32 <> 0 then
    begin
    @SetLayeredWindowAttributes := GetProcAddress(hUser32,'SetLayeredWindowAttributes');
    // If the import did not succeed, make sure our app can handle it!
    if @SetLayeredWindowAttributes <> nil then
      begin
      fBlankoutForms := TList.Create;
      for i := 0 to Screen.MonitorCount - 1 do
        begin
        if AllMonitors or ( (Screen.Monitors[i].Left=0) and (Screen.Monitors[i].Top=0) ) then
          begin
          ablnkform := TfmBlankoutForm.Create(nil);
          ablnkform.WindowState := wsNormal;
          ablnkform.FormStyle := fsNormal;
          ablnkform.HandleNeeded;
          ablnkform.ClientWidth:=1;
          ablnkform.ClientHeight:=1;
          ablnkform.Show;
          ablnkform.Hide;
          rect := Screen.Monitors[i].BoundsRect;
          ablnkform.BoundsRect := rect;

          fBlankoutForms.Add(ablnkform);
          ablnkform.Show;
          SetWindowPos(ablnkform.Handle, HWND_TOP, rect.Left, rect.Top,
                       ablnkform.Width, ablnkform.Height, 0);

          ablnkform.FormStyle:=fsStayOnTop;
          end;
        end;
      end;
    end;
  end;

procedure TfmBlankoutForm.FormCreate(Sender: TObject);
  begin
  SetWindowLong(Handle, GWL_EXSTYLE,
                GetWindowLong(Handle, GWL_EXSTYLE) or
                WS_EX_LAYERED or
                WS_EX_TRANSPARENT or
                WS_EX_TOPMOST);
  // The SetLayeredWindowAttributes function sets the opacity and
  // transparency color key of a layered window
  SetLayeredWindowAttributes(Handle, 0,
                             Trunc((255 / 100) * (100 - 0)),
                             LWA_ALPHA);
  end;

procedure TfmBlankoutForm.FormShow(Sender: TObject);
  begin
  FormCreate(nil);
  SetWindowPos(Handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
    SWP_NOACTIVATE);
  end;

initialization
finalization
RestoreScreen;
end.
