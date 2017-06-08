program RPXGate;

uses
  {$IFNDEF IDE_2006up}FastMM4,{$ENDIF}
  Forms,
  GatewayModule in 'GatewayModule.pas' {GateModule: TDataModule},
  MainGateForm in 'MainGateForm.pas' {GateForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGateForm, GateForm);
  Application.Run;
end.
