object GateModule: TGateModule
  OldCreateOrder = False
  Left = 563
  Top = 146
  Height = 141
  Width = 267
  object Gate: TRtcGateway
    GateFileName = '/'
    BeforeUserLogin = GateBeforeUserLogin
    OnUserReady = GateUserReady
    OnUserNotReady = GateUserNotReady
    BeforeUserLogout = GateBeforeUserLogout
    Left = 40
    Top = 24
  end
end
