program RPXClient;

{$include rtcDefs.inc}

uses
  FastMM4,
  Forms,
  MainClientForm in 'MainClientForm.pas' {GateClientForm},
  ScreenHostForm in '..\Modules\ScreenHostForm.pas' {ScreenHostFrm},
  ScreenViewForm in '..\Modules\ScreenViewForm.pas' {ScreenViewFrm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGateClientForm, GateClientForm);
  Application.Run;
end.
