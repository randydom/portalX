object Form1: TForm1
  Left = 496
  Top = 178
  Width = 613
  Height = 462
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  Caption = 'Desktop Capture Test'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnResize = FormResize
  PixelsPerInch = 120
  TextHeight = 16
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 595
    Height = 417
    HorzScrollBar.Style = ssHotTrack
    HorzScrollBar.Tracking = True
    VertScrollBar.Style = ssHotTrack
    VertScrollBar.Tracking = True
    Align = alClient
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    TabOrder = 1
    OnMouseMove = PaintBox1MouseMove
    object PaintBox1: TPaintBox
      Left = 0
      Top = 0
      Width = 505
      Height = 325
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      ParentShowHint = False
      ShowHint = False
      OnMouseDown = PaintBox1MouseDown
      OnMouseMove = PaintBox1MouseMove
      OnMouseUp = PaintBox1MouseUp
      OnPaint = PaintBox1Paint
    end
  end
  object MainPanel: TPanel
    Left = 0
    Top = 0
    Width = 489
    Height = 309
    ParentBackground = False
    TabOrder = 0
    object mot1Line4a: TLabel
      Left = 284
      Top = 166
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object mot1Line2a: TLabel
      Left = 146
      Top = 166
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img ms'
    end
    object mot1Line3a: TLabel
      Left = 200
      Top = 166
      Width = 51
      Height = 16
      Alignment = taRightJustify
      Caption = 'imgX ms'
    end
    object mot1LineKb: TLabel
      Left = 66
      Top = 166
      Width = 47
      Height = 16
      Alignment = taRightJustify
      Caption = 'img Kbit'
    end
    object mot1Line4: TLabel
      Left = 448
      Top = 166
      Width = 33
      Height = 16
      Alignment = taRightJustify
      Caption = '=FPS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object mot1Line4b: TLabel
      Left = 352
      Top = 166
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Bevel1: TBevel
      Left = 120
      Top = 140
      Width = 2
      Height = 117
      Shape = bsLeftLine
    end
    object Bevel2: TBevel
      Left = 256
      Top = 140
      Width = 2
      Height = 117
      Shape = bsLeftLine
    end
    object Bevel3: TBevel
      Left = 1
      Top = 139
      Width = 488
      Height = 2
    end
    object Label1: TLabel
      Left = 328
      Top = 58
      Width = 20
      Height = 16
      Caption = 'DQ'
    end
    object Label2: TLabel
      Left = 328
      Top = 86
      Width = 19
      Height = 16
      Caption = 'CQ'
    end
    object Bevel6: TBevel
      Left = 402
      Top = 140
      Width = 3
      Height = 117
      Shape = bsLeftLine
    end
    object Bevel7: TBevel
      Left = 172
      Top = 52
      Width = 5
      Height = 88
      Shape = bsLeftLine
    end
    object Bevel4: TBevel
      Left = 0
      Top = 256
      Width = 489
      Height = 5
      Shape = bsTopLine
    end
    object lblScreenInfo: TLabel
      Left = 415
      Top = 261
      Width = 67
      Height = 16
      Alignment = taRightJustify
      Caption = 'Screen Info'
    end
    object Label3: TLabel
      Left = 96
      Top = 58
      Width = 39
      Height = 16
      Caption = 'Colors'
    end
    object Bevel10: TBevel
      Left = 0
      Top = 228
      Width = 489
      Height = 5
      Shape = bsTopLine
    end
    object jpgLineKb: TLabel
      Left = 66
      Top = 186
      Width = 47
      Height = 16
      Alignment = taRightJustify
      Caption = 'img Kbit'
    end
    object jpgLine2a: TLabel
      Left = 146
      Top = 186
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img ms'
    end
    object jpgLine3a: TLabel
      Left = 200
      Top = 186
      Width = 51
      Height = 16
      Alignment = taRightJustify
      Caption = 'imgX ms'
    end
    object jpgLine4a: TLabel
      Left = 284
      Top = 186
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object jpgLine4b: TLabel
      Left = 352
      Top = 186
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object jpgLine4: TLabel
      Left = 448
      Top = 186
      Width = 33
      Height = 16
      Alignment = taRightJustify
      Caption = '=FPS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object rleLineKb: TLabel
      Left = 66
      Top = 206
      Width = 47
      Height = 16
      Alignment = taRightJustify
      Caption = 'img Kbit'
    end
    object rleLine2a: TLabel
      Left = 146
      Top = 206
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img ms'
    end
    object rleLine3a: TLabel
      Left = 200
      Top = 206
      Width = 51
      Height = 16
      Alignment = taRightJustify
      Caption = 'imgX ms'
    end
    object rleLine4a: TLabel
      Left = 284
      Top = 206
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object rleLine4b: TLabel
      Left = 352
      Top = 206
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object rleLine4: TLabel
      Left = 448
      Top = 206
      Width = 33
      Height = 16
      Alignment = taRightJustify
      Caption = '=FPS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object totLineKb: TLabel
      Left = 66
      Top = 234
      Width = 47
      Height = 16
      Alignment = taRightJustify
      Caption = 'img Kbit'
    end
    object totLine2a: TLabel
      Left = 146
      Top = 234
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img ms'
    end
    object totLine3a: TLabel
      Left = 200
      Top = 234
      Width = 51
      Height = 16
      Alignment = taRightJustify
      Caption = 'imgX ms'
    end
    object totLine4a: TLabel
      Left = 276
      Top = 234
      Width = 51
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object totLine4b: TLabel
      Left = 352
      Top = 234
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object totLine4: TLabel
      Left = 443
      Top = 234
      Width = 38
      Height = 16
      Alignment = taRightJustify
      Caption = '=FPS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Bevel11: TBevel
      Left = 0
      Top = 162
      Width = 489
      Height = 5
      Shape = bsTopLine
    end
    object capLine2a: TLabel
      Left = 146
      Top = 142
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img ms'
    end
    object capLine4a: TLabel
      Left = 284
      Top = 142
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object capLine4: TLabel
      Left = 448
      Top = 142
      Width = 33
      Height = 16
      Alignment = taRightJustify
      Caption = '=FPS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label4: TLabel
      Left = 7
      Top = 167
      Width = 11
      Height = 16
      Caption = 'M'
    end
    object Label5: TLabel
      Left = 7
      Top = 183
      Width = 7
      Height = 16
      Caption = 'J'
    end
    object Label6: TLabel
      Left = 7
      Top = 203
      Width = 10
      Height = 16
      Caption = 'R'
    end
    object Label7: TLabel
      Left = 7
      Top = 144
      Width = 9
      Height = 16
      Caption = 'C'
    end
    object Label8: TLabel
      Left = 4
      Top = 234
      Width = 14
      Height = 16
      Caption = '=>'
    end
    object capLineKb: TLabel
      Left = 66
      Top = 143
      Width = 47
      Height = 16
      Alignment = taRightJustify
      Caption = 'img Kbit'
    end
    object capLine3a: TLabel
      Left = 200
      Top = 142
      Width = 51
      Height = 16
      Alignment = taRightJustify
      Caption = 'imgX ms'
    end
    object capLine4b: TLabel
      Left = 352
      Top = 142
      Width = 43
      Height = 16
      Alignment = taRightJustify
      Caption = 'img fps'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Bevel5: TBevel
      Left = 320
      Top = 50
      Width = 5
      Height = 86
      Shape = bsLeftLine
    end
    object Label9: TLabel
      Left = 180
      Top = 60
      Width = 9
      Height = 16
      Caption = 'V'
    end
    object Label10: TLabel
      Left = 180
      Top = 88
      Width = 10
      Height = 16
      Caption = 'H'
    end
    object Label11: TLabel
      Left = 180
      Top = 116
      Width = 21
      Height = 16
      Caption = 'Full'
    end
    object Label12: TLabel
      Left = 328
      Top = 114
      Width = 20
      Height = 16
      Caption = 'HQ'
    end
    object eQualityLum: TTrackBar
      Left = 348
      Top = 54
      Width = 137
      Height = 26
      Max = 120
      PageSize = 10
      Frequency = 10
      Position = 80
      TabOrder = 0
      TabStop = False
    end
    object xLZW: TCheckBox
      Left = 8
      Top = 58
      Width = 53
      Height = 17
      TabStop = False
      Caption = 'LZW'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
    object xHQColor: TCheckBox
      Left = 432
      Top = 114
      Width = 47
      Height = 17
      TabStop = False
      Alignment = taLeftJustify
      Caption = 'HC'
      TabOrder = 2
    end
    object eHQDepth: TTrackBar
      Left = 348
      Top = 110
      Width = 83
      Height = 28
      Max = 5
      PageSize = 1
      TabOrder = 3
      TabStop = False
    end
    object eQualityCol: TTrackBar
      Left = 348
      Top = 82
      Width = 137
      Height = 26
      Max = 120
      PageSize = 10
      Frequency = 10
      Position = 60
      TabOrder = 4
      TabStop = False
    end
    object xAllMonitors: TCheckBox
      Left = 4
      Top = 264
      Width = 97
      Height = 17
      TabStop = False
      Caption = 'All Monitors'
      TabOrder = 5
    end
    object xBandwidth: TComboBox
      Left = 376
      Top = 281
      Width = 108
      Height = 24
      Style = csDropDownList
      ItemHeight = 16
      ItemIndex = 5
      TabOrder = 6
      Text = '1 MBits'
      Items.Strings = (
        '32 KBits'
        '64 KBits'
        '128 KBits'
        '256 KBits'
        '512 KBits'
        '1 MBits'
        '2 MBits'
        '4 MBIts'
        '8 MBits'
        '16 MBits'
        'Unlimited')
    end
    object xMirrorDriver: TCheckBox
      Left = 4
      Top = 288
      Width = 101
      Height = 17
      TabStop = False
      Caption = 'Mirror Driver'
      TabOrder = 7
      OnClick = xMirrorDriverClick
    end
    object xWinAero: TCheckBox
      Left = 116
      Top = 264
      Width = 121
      Height = 17
      TabStop = False
      Caption = '"Aero" Windows'
      Checked = True
      State = cbChecked
      TabOrder = 8
      OnClick = xWinAeroClick
    end
    object eMotionVert: TTrackBar
      Left = 204
      Top = 57
      Width = 113
      Height = 26
      Max = 11
      PageSize = 1
      Position = 1
      TabOrder = 9
      TabStop = False
    end
    object eMotionHorz: TTrackBar
      Left = 204
      Top = 85
      Width = 113
      Height = 26
      Max = 11
      PageSize = 10
      Position = 1
      TabOrder = 10
      TabStop = False
    end
    object eMotionFull: TTrackBar
      Left = 204
      Top = 109
      Width = 113
      Height = 26
      Max = 11
      PageSize = 10
      Position = 1
      TabOrder = 11
      TabStop = False
    end
    object eColorDepth: TTrackBar
      Left = 92
      Top = 78
      Width = 77
      Height = 26
      Max = 8
      Min = 1
      PageSize = 10
      Position = 5
      TabOrder = 12
      TabStop = False
    end
    object xMotionDebug: TCheckBox
      Left = 8
      Top = 78
      Width = 65
      Height = 17
      TabStop = False
      Caption = 'Debug'
      TabOrder = 14
    end
    object xSplitData: TCheckBox
      Left = 8
      Top = 98
      Width = 63
      Height = 17
      TabStop = False
      Caption = 'Split'
      TabOrder = 15
    end
    object xMaintenanceForm: TCheckBox
      Left = 256
      Top = 288
      Width = 105
      Height = 17
      Caption = 'Maintenance'
      TabOrder = 16
      OnClick = xMaintenanceFormClick
    end
    object xLayeredWindows: TCheckBox
      Left = 116
      Top = 288
      Width = 137
      Height = 17
      Caption = 'Layered Windows'
      Checked = True
      State = cbChecked
      TabOrder = 17
    end
    object xColorReduceReal: TCheckBox
      Left = 148
      Top = 58
      Width = 17
      Height = 17
      Caption = 'xColorReduceReal'
      TabOrder = 18
    end
    object SubPanel: TPanel
      Left = 0
      Top = 0
      Width = 489
      Height = 49
      TabOrder = 13
      object btnCapture: TSpeedButton
        Left = 420
        Top = 0
        Width = 69
        Height = 29
        Caption = 'START'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = CaptureClick
      end
      object totLine5: TLabel
        Left = 446
        Top = 31
        Width = 38
        Height = 16
        Alignment = taRightJustify
        Caption = '=FPS'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object xConfig: TCheckBox
        Left = 344
        Top = 4
        Width = 73
        Height = 17
        Caption = 'Config'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = xConfigClick
      end
      object xMotionComp1: TCheckBox
        Left = 4
        Top = 4
        Width = 49
        Height = 17
        TabStop = False
        Caption = 'MC'
        Checked = True
        State = cbChecked
        TabOrder = 1
      end
      object xColorComp: TCheckBox
        Left = 52
        Top = 4
        Width = 45
        Height = 17
        Caption = 'CC'
        TabOrder = 2
      end
      object xJPG: TCheckBox
        Left = 96
        Top = 4
        Width = 53
        Height = 16
        TabStop = False
        Caption = 'JPG'
        Checked = True
        State = cbChecked
        TabOrder = 3
      end
      object xRLE: TCheckBox
        Left = 152
        Top = 4
        Width = 53
        Height = 16
        TabStop = False
        Caption = 'RLE'
        Checked = True
        State = cbChecked
        TabOrder = 4
      end
      object eWindowCaption: TComboBox
        Left = 4
        Top = 23
        Width = 337
        Height = 24
        Style = csDropDownList
        ItemHeight = 16
        ItemIndex = 0
        TabOrder = 5
        TabStop = False
        Text = 'Desktop'
        OnDropDown = xWindowCaptureClick
        Items.Strings = (
          'Desktop')
      end
      object xCaptureFrame: TCheckBox
        Left = 344
        Top = 26
        Width = 65
        Height = 17
        Caption = 'Frame'
        TabOrder = 6
      end
      object xAutoHide: TCheckBox
        Left = 256
        Top = 4
        Width = 83
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Auto-Hide'
        TabOrder = 7
      end
    end
  end
  object CaptureTimer: TTimer
    Enabled = False
    Interval = 1
    OnTimer = CaptureTimerTimer
    Left = 48
    Top = 344
  end
  object PaintTimer: TTimer
    Enabled = False
    OnTimer = PaintTimerTimer
    Left = 76
    Top = 344
  end
  object UpdateTimer: TTimer
    Enabled = False
    Interval = 20
    OnTimer = UpdateTimerTimer
    Left = 104
    Top = 344
  end
end
