object GateForm: TGateForm
  Left = 593
  Top = 242
  Width = 241
  Height = 150
  AutoSize = True
  Caption = 'RPX Gate'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PrintScale = poNone
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 16
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 223
    Height = 105
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 4
      Width = 24
      Height = 16
      Caption = 'Port'
    end
    object shGateway: TShape
      Left = 148
      Top = 4
      Width = 69
      Height = 45
      Brush.Color = clRed
      Shape = stRoundRect
    end
    object lblStatus: TLabel
      Left = 4
      Top = 56
      Width = 78
      Height = 16
      Caption = 'Click START'
    end
    object lblConnect: TLabel
      Left = 92
      Top = 80
      Width = 16
      Height = 16
      Caption = '---'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 4
      Top = 80
      Width = 77
      Height = 16
      Caption = 'Connections:'
    end
    object ePort: TEdit
      Left = 8
      Top = 24
      Width = 61
      Height = 24
      TabOrder = 0
      Text = '80'
    end
    object btnStart: TButton
      Left = 76
      Top = 4
      Width = 69
      Height = 45
      Caption = 'START'
      TabOrder = 1
      OnClick = btnStartClick
    end
  end
  object Server: TRtcHttpServer
    MultiThreaded = True
    OnException = ServerException
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    OnListenStart = ServerListenStart
    OnListenStop = ServerListenStop
    OnListenError = ServerListenError
    FixupRequest.RemovePrefix = True
    OnRequestNotAccepted = ServerRequestNotAccepted
    MaxHeaderSize = 2048
    OnInvalidRequest = ServerInvalidRequest
    Left = 124
    Top = 52
  end
  object StatusTimer: TTimer
    Interval = 500
    OnTimer = StatusTimerTimer
    Left = 176
    Top = 52
  end
end
