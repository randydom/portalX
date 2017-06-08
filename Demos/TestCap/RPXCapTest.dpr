program RPXCapTest;

uses
  Forms,
  TestCapture in 'TestCapture.pas' {Form1},
  rtcBlankOutForm in '..\Modules\rtcBlankOutForm.pas' {fmBlankoutForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
