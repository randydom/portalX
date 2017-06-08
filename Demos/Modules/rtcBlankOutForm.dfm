object fmBlankoutForm: TfmBlankoutForm
  Left = 607
  Top = 160
  BorderStyle = bsNone
  Caption = 'fmBlankoutForm'
  ClientHeight = 575
  ClientWidth = 744
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 17
  object Panel1: TPanel
    Left = 15
    Top = 10
    Width = 671
    Height = 514
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object Label1: TLabel
      Left = 84
      Top = 418
      Width = 495
      Height = 36
      Caption = 'Administration work in progress.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -30
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 230
      Top = 464
      Width = 209
      Height = 36
      Caption = 'Please wait ...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -30
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Image1: TImage
      Left = 73
      Top = 21
      Width = 523
      Height = 377
    end
  end
  object Timer1: TTimer
    Interval = 500
    OnTimer = Timer1Timer
    Left = 28
    Top = 24
  end
end
