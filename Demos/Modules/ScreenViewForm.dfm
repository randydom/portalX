object ScreenViewFrm: TScreenViewFrm
  Left = 429
  Top = 248
  Width = 396
  Height = 147
  Caption = 'Screen Viewer'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  PrintScale = poNone
  OnActivate = DeactivateControl
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnDeactivate = DeactivateControl
  OnHide = DeactivateControl
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  OnMouseWheel = sbMainBoxMouseWheel
  OnResize = DeactivateControl
  PixelsPerInch = 120
  TextHeight = 16
  object sbMainBox: TScrollBox
    Left = 0
    Top = 0
    Width = 378
    Height = 102
    HorzScrollBar.Tracking = True
    VertScrollBar.Tracking = True
    Align = alClient
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    TabOrder = 0
    object pbScreenView: TPaintBox
      Left = 0
      Top = 0
      Width = 337
      Height = 61
      Cursor = crUpArrow
      OnMouseDown = pbScreenViewMouseDown
      OnMouseMove = pbScreenViewMouseMove
      OnMouseUp = pbScreenViewMouseUp
      OnPaint = pbScreenViewPaint
    end
    object pStartInfo: TPanel
      Left = 8
      Top = 8
      Width = 317
      Height = 41
      Caption = 'Waiting for Host ...'
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -20
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
      OnClick = pStartInfoClick
    end
  end
end
