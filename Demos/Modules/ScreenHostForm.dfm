object ScreenHostFrm: TScreenHostFrm
  Left = 684
  Top = 160
  AutoSize = True
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Screen Host'
  ClientHeight = 262
  ClientWidth = 588
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
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 16
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 268
    Height = 262
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 266
      Height = 57
      Align = alTop
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      object btnCFG: TSpeedButton
        Left = 216
        Top = 8
        Width = 45
        Height = 41
        Caption = 'CFG'
        OnClick = btnCFGClick
      end
      object btnAddUser: TBitBtn
        Left = 4
        Top = 4
        Width = 97
        Height = 49
        Hint = 'Invite a User to this CHAT Room'
        Caption = 'INVITE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = btnAddUserClick
      end
      object btnStart: TBitBtn
        Left = 102
        Top = 4
        Width = 111
        Height = 49
        Caption = 'START'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        WordWrap = True
        OnClick = btnStartClick
      end
    end
    object Panel1: TPanel
      Left = 1
      Top = 58
      Width = 266
      Height = 203
      Align = alClient
      TabOrder = 1
      object Panel4: TPanel
        Left = 1
        Top = 1
        Width = 132
        Height = 173
        Align = alLeft
        BevelOuter = bvLowered
        TabOrder = 0
        object Panel6: TPanel
          Left = 1
          Top = 1
          Width = 130
          Height = 32
          Align = alTop
          Caption = 'Viewers (only)'
          TabOrder = 0
        end
        object eUsers: TListBox
          Left = 1
          Top = 33
          Width = 130
          Height = 139
          Hint = 'Dbl-Click to Kick / Re-Invite User'
          TabStop = False
          Align = alClient
          DragMode = dmAutomatic
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = []
          ItemHeight = 18
          ParentFont = False
          TabOrder = 1
          OnDblClick = eUsersDblClick
          OnDragDrop = eUsersDragDrop
          OnDragOver = eUsersDragOver
        end
      end
      object Panel5: TPanel
        Left = 133
        Top = 1
        Width = 132
        Height = 173
        Align = alClient
        BevelOuter = bvLowered
        TabOrder = 1
        object Panel7: TPanel
          Left = 1
          Top = 1
          Width = 130
          Height = 32
          Align = alTop
          Caption = 'Users with Control'
          TabOrder = 0
        end
        object eControls: TListBox
          Left = 1
          Top = 33
          Width = 130
          Height = 139
          Hint = 'Dbl-Click to Kick / Re-Invite User'
          TabStop = False
          Align = alClient
          DragMode = dmAutomatic
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = []
          ItemHeight = 18
          ParentFont = False
          TabOrder = 1
          OnDblClick = eControlsDblClick
          OnDragDrop = eControlsDragDrop
          OnDragOver = eControlsDragOver
        end
      end
      object Panel8: TPanel
        Left = 1
        Top = 174
        Width = 264
        Height = 28
        Align = alBottom
        Caption = 'Move Users <- / -> with Drag && Drop'
        TabOrder = 2
      end
    end
  end
  object MainPanel: TPanel
    Left = 267
    Top = 0
    Width = 321
    Height = 262
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 1
    Visible = False
    object Label2: TLabel
      Left = 8
      Top = 76
      Width = 20
      Height = 16
      Caption = 'DQ'
    end
    object Label3: TLabel
      Left = 8
      Top = 108
      Width = 19
      Height = 16
      Caption = 'CQ'
    end
    object Label4: TLabel
      Left = 8
      Top = 44
      Width = 19
      Height = 16
      Caption = 'CR'
    end
    object Label5: TLabel
      Left = 176
      Top = 196
      Width = 43
      Height = 16
      Caption = 'Screen'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label1: TLabel
      Left = 176
      Top = 168
      Width = 41
      Height = 16
      Caption = 'Mouse'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label6: TLabel
      Left = 176
      Top = 228
      Width = 46
      Height = 16
      Caption = 'V.Buffer'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label7: TLabel
      Left = 176
      Top = 144
      Width = 114
      Height = 16
      Caption = 'Capture Frequency'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Bevel1: TBevel
      Left = 168
      Top = 136
      Width = 153
      Height = 5
      Shape = bsTopLine
    end
    object Bevel5: TBevel
      Left = 168
      Top = 30
      Width = 5
      Height = 231
      Shape = bsLeftLine
    end
    object Label8: TLabel
      Left = 8
      Top = 140
      Width = 20
      Height = 16
      Caption = 'HQ'
    end
    object Label9: TLabel
      Left = 8
      Top = 172
      Width = 9
      Height = 16
      Caption = 'V'
    end
    object Label10: TLabel
      Left = 8
      Top = 200
      Width = 10
      Height = 16
      Caption = 'H'
    end
    object Label11: TLabel
      Left = 8
      Top = 228
      Width = 21
      Height = 16
      Caption = 'Full'
    end
    object eQualityLum: TTrackBar
      Left = 28
      Top = 72
      Width = 137
      Height = 26
      Hint = 'Detail Quality'
      Max = 120
      PageSize = 10
      Frequency = 10
      Position = 80
      TabOrder = 0
      TabStop = False
      OnChange = eQualityLumChange
    end
    object xHQColor: TCheckBox
      Left = 112
      Top = 138
      Width = 45
      Height = 17
      Hint = 'High Quality Colors'
      TabStop = False
      Alignment = taLeftJustify
      Caption = 'HC'
      TabOrder = 1
      OnClick = xHQColorClick
    end
    object eHQDepth: TTrackBar
      Left = 32
      Top = 134
      Width = 81
      Height = 28
      Hint = 'Color HQ Mode'
      Max = 5
      PageSize = 1
      TabOrder = 2
      TabStop = False
      OnChange = eHQDepthChange
    end
    object eQualityCol: TTrackBar
      Left = 28
      Top = 104
      Width = 137
      Height = 26
      Hint = 'Color Quality'
      Max = 120
      PageSize = 10
      Frequency = 10
      Position = 60
      TabOrder = 3
      TabStop = False
      OnChange = eQualityColChange
    end
    object xAllMonitors: TCheckBox
      Left = 180
      Top = 40
      Width = 97
      Height = 17
      Hint = 'Show All Monitors'
      TabStop = False
      Caption = 'All Monitors'
      TabOrder = 4
      OnClick = xAllMonitorsClick
    end
    object xMirrorDriver: TCheckBox
      Left = 180
      Top = 112
      Width = 121
      Height = 17
      Hint = 'Enable Video Mirror Driver?'
      TabStop = False
      Caption = 'V. Mirror Driver'
      TabOrder = 5
      OnClick = xMirrorDriverClick
    end
    object xWinAero: TCheckBox
      Left = 180
      Top = 64
      Width = 129
      Height = 17
      Hint = 'Use Aero (Glass) Windows?'
      TabStop = False
      Caption = '"Aero" Windows'
      Checked = True
      State = cbChecked
      TabOrder = 6
      OnClick = xWinAeroClick
    end
    object eMotionVert: TTrackBar
      Left = 40
      Top = 170
      Width = 125
      Height = 26
      Hint = 'V-Motion Calc. Time Limit'
      Max = 11
      PageSize = 1
      Position = 1
      TabOrder = 7
      TabStop = False
      OnChange = eMotionVertChange
    end
    object eMotionHorz: TTrackBar
      Left = 40
      Top = 198
      Width = 125
      Height = 26
      Hint = 'H-Motion Calc. Time Limit'
      Max = 11
      PageSize = 10
      Position = 1
      TabOrder = 8
      TabStop = False
      OnChange = eMotionHorzChange
    end
    object eMotionFull: TTrackBar
      Left = 40
      Top = 224
      Width = 125
      Height = 26
      Hint = 'Full Motion Calc. Time Limit'
      Max = 11
      PageSize = 10
      Position = 1
      TabOrder = 9
      TabStop = False
      OnChange = eMotionFullChange
    end
    object eColorDepth: TTrackBar
      Left = 28
      Top = 40
      Width = 109
      Height = 26
      Hint = 'Color Depth'
      Max = 8
      Min = 1
      PageSize = 10
      Position = 5
      TabOrder = 10
      TabStop = False
      OnChange = eColorDepthChange
    end
    object xLayeredWindows: TCheckBox
      Left = 180
      Top = 88
      Width = 137
      Height = 17
      Hint = 'Capture Layered Windows?'
      Caption = 'Layered Windows'
      Checked = True
      State = cbChecked
      TabOrder = 12
      OnClick = xLayeredWindowsClick
    end
    object xColorReduce: TCheckBox
      Left = 144
      Top = 44
      Width = 17
      Height = 17
      Hint = 'Reduce Color depth?'
      Caption = 'xColorReduce'
      TabOrder = 13
      OnClick = xColorReduceClick
    end
    object SubPanel: TPanel
      Left = 0
      Top = 0
      Width = 320
      Height = 33
      TabOrder = 11
      object xMotionComp: TCheckBox
        Left = 8
        Top = 8
        Width = 73
        Height = 17
        Hint = 'Motion Compression'
        TabStop = False
        Caption = 'Motion'
        Checked = True
        State = cbChecked
        TabOrder = 0
        OnClick = xMotionCompClick
      end
      object xJPG: TCheckBox
        Left = 88
        Top = 8
        Width = 73
        Height = 16
        Hint = 'JPEG Compression'
        TabStop = False
        Caption = 'JPEG'
        Checked = True
        State = cbChecked
        TabOrder = 1
        OnClick = xJPGClick
      end
      object xRLE: TCheckBox
        Left = 172
        Top = 8
        Width = 65
        Height = 16
        Hint = 'RLE Compression'
        TabStop = False
        Caption = 'RLE'
        Checked = True
        State = cbChecked
        TabOrder = 2
        OnClick = xRLEClick
      end
      object xLZW: TCheckBox
        Left = 252
        Top = 8
        Width = 61
        Height = 17
        Hint = 'LZW Compression'
        TabStop = False
        Caption = 'LZW'
        Checked = True
        State = cbChecked
        TabOrder = 3
        OnClick = xLZWClick
      end
    end
    object cbFPS: TTrackBar
      Left = 224
      Top = 196
      Width = 93
      Height = 26
      Hint = 'Screen Frame Limit'
      Max = 13
      PageSize = 1
      Position = 11
      TabOrder = 14
      TabStop = False
      OnChange = cbFPSChange
    end
    object cbFPM: TTrackBar
      Left = 224
      Top = 168
      Width = 93
      Height = 26
      Hint = 'Mouse Frame Limit'
      Max = 13
      PageSize = 1
      Position = 11
      TabOrder = 15
      TabStop = False
      OnChange = cbFPMChange
    end
    object cbFPV: TTrackBar
      Left = 224
      Top = 224
      Width = 93
      Height = 26
      Hint = 'Video Streaming Buffer'
      Max = 13
      PageSize = 1
      Position = 11
      TabOrder = 16
      TabStop = False
      OnChange = cbFPVChange
    end
  end
end
