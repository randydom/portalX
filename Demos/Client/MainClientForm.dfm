object GateClientForm: TGateClientForm
  Left = 571
  Top = 194
  Width = 344
  Height = 245
  Caption = 'RPX Client'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PrintScale = poNone
  ShowHint = True
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 16
  object MainPanel: TPanel
    Left = 0
    Top = 0
    Width = 326
    Height = 200
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    DesignSize = (
      326
      200)
    object Label1: TLabel
      Left = 4
      Top = 8
      Width = 28
      Height = 25
      Caption = 'ID:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 25
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object shInput: TShape
      Left = 5
      Top = 36
      Width = 22
      Height = 22
      Brush.Color = clRed
      Pen.Width = 5
    end
    object shOutput: TShape
      Left = 5
      Top = 64
      Width = 22
      Height = 22
      Brush.Color = clRed
      Pen.Width = 5
    end
    object InfoPanel: TPanel
      Left = 8
      Top = 148
      Width = 312
      Height = 45
      Anchors = [akLeft, akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      DesignSize = (
        312
        45)
      object l_Status1: TLabel
        Left = 4
        Top = 5
        Width = 70
        Height = 15
        Caption = 'Logged OUT'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object l_Status2: TLabel
        Left = 4
        Top = 25
        Width = 17
        Height = 15
        Caption = 'OK'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object btnReset: TSpeedButton
        Left = 265
        Top = 20
        Width = 42
        Height = 21
        Hint = 'Change connection provider'
        Anchors = [akTop, akRight]
        Caption = 'AS'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        OnClick = btnResetClick
      end
      object btnCLR: TLabel
        Left = 265
        Top = 4
        Width = 42
        Height = 17
        Alignment = taCenter
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = 'CLR'
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -10
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        Transparent = False
        Layout = tlCenter
        OnClick = btnCLRClick
      end
    end
    object Panel1: TPanel
      Left = 8
      Top = 100
      Width = 117
      Height = 45
      Anchors = [akLeft, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      object lblRecvBufferSize: TLabel
        Left = 94
        Top = 6
        Width = 15
        Height = 15
        Alignment = taRightJustify
        Caption = '0K'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object lblSendBuffSize: TLabel
        Left = 94
        Top = 26
        Width = 15
        Height = 15
        Alignment = taRightJustify
        Caption = '0K'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object Label2: TLabel
        Left = 6
        Top = 6
        Width = 7
        Height = 15
        Caption = '<'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object Label3: TLabel
        Left = 6
        Top = 26
        Width = 7
        Height = 15
        Caption = '>'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
    end
    object eYourID: TEdit
      Left = 38
      Top = 8
      Width = 87
      Height = 29
      TabStop = False
      BorderStyle = bsNone
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = 25
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      ReadOnly = True
      TabOrder = 4
      Text = '??????'
    end
    object btnShowScreen: TButton
      Left = 36
      Top = 36
      Width = 89
      Height = 49
      Caption = 'HOST'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 18
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      WordWrap = True
      OnClick = btnShowScreenClick
    end
    object eUsers: TListBox
      Left = 131
      Top = 8
      Width = 190
      Height = 137
      Anchors = [akLeft, akTop, akRight, akBottom]
      BevelKind = bkSoft
      BiDiMode = bdLeftToRight
      ExtendedSelect = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 20
      Font.Name = 'Arial'
      Font.Style = []
      ItemHeight = 19
      ParentBiDiMode = False
      ParentFont = False
      TabOrder = 1
      OnClick = eUsersClick
    end
  end
  object StatusUpdate: TTimer
    Enabled = False
    Interval = 250
    OnTimer = StatusUpdateTimer
    Left = 252
    Top = 16
  end
  object GateCli: TRtcHttpGateClient
    GateAddr = 'localhost'
    GatePort = '80'
    GateFileName = '/'
    OnDataFilter = GateCliDataFilter
    OnInfoFilter = GateCliInfoFilter
    OnInfoReceived = GateCliInfoReceived
    OnReadyToSend = GateCliReadyToSend
    BeforeLogInGUI = GateCliBeforeLogInGUI
    AfterLoggedInGUI = GateCliAfterLoggedInGUI
    AfterLoginFailGUI = GateCliAfterLoginFailGUI
    AfterLogOutGUI = GateCliAfterLogOutGUI
    OnInfoReceivedGUI = GateCliInfoReceivedGUI
    OnStreamResetGUI = GateCliStreamResetGUI
    Left = 160
    Top = 20
  end
  object ScreenLink: TRtcGateClientLink
    Client = GateCli
    OnDataFilter = ScreenLinkDataFilter
    OnDataReceivedGUI = ScreenLinkDataReceivedGUI
    Left = 160
    Top = 84
  end
end
